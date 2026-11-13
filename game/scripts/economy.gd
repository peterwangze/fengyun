extends RefCounted

const Catalog = preload("res://scripts/market_catalog.gd")
const Equipment = preload("res://scripts/equipment.gd")
const Items = preload("res://scripts/items.gd")
const Martial = preload("res://scripts/martial.gd")
const Story = preload("res://scripts/story.gd")
const SHOPS = Catalog.SHOPS
const FORGES = Catalog.FORGES
const SILVER_CAP := 999
const START_SILVER := 4
const TIDE_SILVER := 9
const MATERIAL_CAP := 20

static func normalize(slot: Dictionary) -> void:
	_normalize_account(slot, START_SILVER + int(slot.chapter) * 5)
	slot.gear_grants = Equipment.clean_grants(slot.get("gear_grants"))
	slot.manual_grants = Martial.clean_grants(slot.get("manual_grants"))
	slot.gear_levels = Equipment.clean_levels(slot, slot.get("gear_levels"))
	if slot.has("afterstory"):
		normalize_tide(slot.afterstory)

static func normalize_tide(account: Dictionary) -> void:
	_normalize_account(account, TIDE_SILVER)

static func _normalize_account(account: Dictionary, starter: int) -> void:
	account.silver = _count(account.get("silver", starter), SILVER_CAP)
	var inventory := {}
	var stored_materials: Variant = account.get("materials")
	if stored_materials is Dictionary:
		for id in Catalog.MATERIALS:
			var amount := _count(stored_materials.get(id), MATERIAL_CAP)
			if amount > 0:
				inventory[id] = amount
	account.materials = inventory
	var purchases := {}
	var stored: Variant = account.get("shop_stock")
	if stored is Dictionary:
		for shop in SHOPS:
			if not stored.get(shop) is Dictionary:
				continue
			var counts := {}
			for good in SHOPS[shop].goods:
				var used := _count(stored[shop].get(good.id), _maximum_stock(good))
				if used > 0:
					counts[good.id] = used
			if not counts.is_empty():
				purchases[shop] = counts
	account.shop_stock = purchases
	var claimed := {}
	var claims: Variant = account.get("loot_claims")
	if claims is Dictionary:
		for source in claims:
			if source is String and claims[source] == true and _known_source(source):
				claimed[source] = true
	account.loot_claims = claimed
	var material_claims := {}
	var prior: Variant = account.get("material_claims")
	if prior is Dictionary:
		for source in prior:
			if prior[source] == true and Catalog.DROPS.get(source,{}).has("materials"):
				material_claims[source] = true
	account.material_claims = material_claims

static func _known_source(source: String) -> bool:
	return Catalog.DROPS.has(source) or source.begins_with("battle:") or source.begins_with("special:") or source.begins_with("tidal:")

static func _count(value: Variant, maximum: int) -> int:
	if (value is int or value is float) and is_finite(float(value)) and value == floorf(value):
		return int(clampf(value, 0, maximum))
	return 0

static func offer(slot: Dictionary, account: Dictionary, shop: String, index: int) -> Dictionary:
	var good: Dictionary = SHOPS[shop].goods[index]
	var id: String = good.id
	var stock: int = good.count
	var hint := ""
	for delivery in good.get("restock", []):
		if _arrived(slot,account,delivery.when):
			stock += delivery.count
		elif hint.is_empty():
			hint = delivery.get("hint", "剧情推进后到货")
	var remaining := maxi(0,stock - int(account.shop_stock.get(shop, {}).get(id, 0)))
	var name := "金创药"
	var detail := "治疗一名队友 58 点气血，可救起倒地者。"
	var limit := ""
	match good.kind:
		"gear":
			name = Equipment.CATALOG[id].name
			detail = Equipment.describe(id)
			if Equipment.unlocked(slot, id): limit = "已拥有"
		"manual":
			var manual: Dictionary = Martial.MANUALS[id]
			name = manual.move[0] + "秘籍"
			detail = "%s可学 · %s" % [Story.HEROES[manual.hero].name, manual.move[5]]
			if slot.manual_grants.has(id): limit = "已习得"
		"supply":
			name = Items.CATALOG[id].name
			detail = Items.CATALOG[id].detail
			if account.supplies.get(id, 0) >= Items.CAP: limit = "药囊已满"
		"material":
			name = Catalog.MATERIALS[id].name
			detail = Catalog.MATERIALS[id].source
			if account.materials.get(id,0) >= MATERIAL_CAP: limit = "材料已满"
		"tonic":
			if account.tonics >= (6 if shop == "tidegate" else 9): limit = "药囊已满"
	if remaining <= 0 and limit.is_empty(): limit = hint if not hint.is_empty() else "售罄"
	if account.silver < good.price and limit.is_empty(): limit = "银两不足"
	return {"name":name,"detail":detail,"remaining":remaining,"price":good.price,"limit":limit,"delivery":hint}

static func _maximum_stock(good: Dictionary) -> int:
	var total: int = good.count
	for delivery in good.get("restock", []):
		total += delivery.count
	return total

static func _arrived(slot: Dictionary, account: Dictionary, when: String) -> bool:
	var parts := when.split(":")
	match parts[0]:
		"mark": return slot.chronicle.marks.get(parts[1],false)
		"quest": return String(slot.chronicle.quests.get(parts[1],"")).begins_with("done_")
		"tide": return account.get(parts[1],false)
		"chapter": return int(slot.chapter) >= int(parts[1])
		"clear":
			return int(slot.chapter) > int(parts[1]) or (int(slot.chapter) == int(parts[1]) and slot.cleared.has(int(parts[2])))
	return false

static func buy(slot: Dictionary, account: Dictionary, shop: String, index: int) -> String:
	var row := offer(slot, account, shop, index)
	if not row.limit.is_empty():
		return ""
	var good: Dictionary = SHOPS[shop].goods[index]
	var id: String = good.id
	match good.kind:
		"tonic": account.tonics += 1
		"supply": account.supplies[id] = int(account.supplies.get(id, 0)) + 1
		"gear": slot.gear_grants[id] = true
		"manual": slot.manual_grants[id] = true
		"material": account.materials[id] = int(account.materials.get(id,0)) + 1
	account.silver -= good.price
	var purchases: Dictionary = account.shop_stock.get(shop, {})
	purchases[id] = int(purchases.get(id, 0)) + 1
	account.shop_stock[shop] = purchases
	return row.name

static func claim(slot: Dictionary, account: Dictionary, source: String, silver: int = 0) -> PackedStringArray:
	var gains := claim_materials(account,source)
	if account.loot_claims.has(source):
		return gains
	var drop: Dictionary = Catalog.DROPS.get(source, {})
	if drop.is_empty() and silver == 0:
		return gains
	account.loot_claims[source] = true
	var before: int = account.silver
	account.silver = mini(SILVER_CAP, before + silver + int(drop.get("silver", 0)))
	if account.silver > before:
		gains.append("银两 +%d" % (account.silver - before))
	var gear: String = drop.get("gear", "")
	if not gear.is_empty() and not slot.gear_grants.has(gear):
		slot.gear_grants[gear] = true
		gains.append(Equipment.CATALOG[gear].name)
	var manual: String = drop.get("manual", "")
	if not manual.is_empty() and not slot.manual_grants.has(manual):
		slot.manual_grants[manual] = true
		gains.append(Martial.MANUALS[manual].move[0] + "秘籍")
	return gains

static func claim_materials(account: Dictionary, source: String) -> PackedStringArray:
	var gains := PackedStringArray()
	var materials: Dictionary = Catalog.DROPS.get(source,{}).get("materials",{})
	if materials.is_empty() or account.material_claims.has(source):
		return gains
	account.material_claims[source] = true
	for id in materials:
		var before: int = account.materials.get(id,0)
		var after := mini(MATERIAL_CAP,before + int(materials[id]))
		if after > before:
			account.materials[id] = after
			gains.append("%s ×%d" % [Catalog.MATERIALS[id].name,after-before])
	return gains

static func source_note(source: String) -> String:
	return Catalog.DROPS.get(source, {}).get("line", "")

static func reconcile(slot: Dictionary) -> PackedStringArray:
	var gains := PackedStringArray()
	for quest in slot.chronicle.quests:
		if String(slot.chronicle.quests[quest]).begins_with("done_"):
			gains.append_array(claim(slot, slot, "quest:" + quest))
	if int(slot.chapter) == 1 and slot.campaign.crossing == "boat":
		gains.append_array(claim(slot, slot, "progress:ferry"))
	if slot.has("afterstory") and slot.afterstory.has("material_claims"):
		var account: Dictionary = slot.afterstory
		for flag in ["register","seal","gate","aid","chief"]:
			if account.get(flag,false):
				gains.append_array(claim_materials(account, "tidal:" + flag))
	return gains

static func recover_unique_drops(slot: Dictionary) -> void:
	var chapter: int = slot.chapter
	if chapter > 1 or (chapter == 1 and (not slot.campaign.crossing.is_empty() or slot.cleared.has(0))):
		var source := "progress:ferry" if slot.campaign.crossing == "boat" else "battle:village:0"
		claim(slot, slot, source)
	if chapter > 1 or (chapter == 1 and slot.cleared.has(1)):
		claim(slot, slot, "battle:village:1")
	if chapter > 2 or (chapter == 2 and slot.cleared.has(1)):
		claim(slot, slot, "battle:forge:1")
	if chapter > 4 or (chapter == 4 and slot.cleared.has(0)):
		claim(slot, slot, "battle:palace:0")
	if slot.supply_claims.has("hunt:inn"):
		claim(slot, slot, "hunt:inn")

static func recover_materials(slot: Dictionary) -> void:
	for source in slot.loot_claims:
		claim_materials(slot,source)
	if slot.has("afterstory"):
		for source in slot.afterstory.loot_claims:
			claim_materials(slot.afterstory,source)
	reconcile(slot)

static func recover_tidal_loot(slot: Dictionary) -> void:
	var account: Dictionary = slot.afterstory
	for battle in ["gate", "aid", "chief"]:
		if account[battle]:
			claim(slot, account, "tidal:" + battle, 6 if battle == "chief" else 4)

static func forge_offer(slot: Dictionary, account: Dictionary, site: String, index: int) -> Dictionary:
	var forge: Dictionary = FORGES[site]
	var is_manual: bool = index >= forge.gear.size()
	var id: String = forge.manuals[index-forge.gear.size()] if is_manual else forge.gear[index]
	var name: String
	var detail: String
	var limit := ""
	var cost: Dictionary = {}
	if is_manual:
		var manual: Dictionary = Martial.MANUALS[id]
		name = manual.move[0] + "抄本"
		detail = "习得 · " + manual.move[5]
		cost = Catalog.MANUAL_RECIPES[id]
		if slot.manual_grants.has(id): limit = "已习得"
	else:
		var level := Equipment.level(slot,id)
		var next := level + 1
		name = Equipment.display_name(slot,id)
		if level >= Equipment.MAX_FORGE_LEVEL:
			detail = Equipment.describe(id,level)
			limit = "已强化至顶"
		else:
			detail = "+%d 后 · %s" % [next,Equipment.upgrade_description(id,next)]
			cost = Catalog.UPGRADE_COSTS[id][level]
			if not Equipment.unlocked(slot,id): limit = "尚未取得 · " + Equipment.CATALOG[id].source
			elif cost.has("when") and not _arrived(slot,account,cost.when): limit = cost.get("hint", "剧情推进后可强化")
	var materials: Dictionary = cost.get("materials",{})
	var price: int = cost.get("silver",0)
	if limit.is_empty() and account.silver < price:
		limit = "银两不足"
	if limit.is_empty():
		for material in materials:
			if account.materials.get(material,0) < materials[material]:
				limit = "材料不足"
				break
	return {"id":id,"manual":is_manual,"name":name,"detail":detail,"materials":materials,"price":price,"limit":limit}

static func forge_count(site: String) -> int:
	return FORGES[site].gear.size() + FORGES[site].get("manuals",[]).size()

static func reinforce(slot: Dictionary, account: Dictionary, site: String, index: int) -> String:
	var row := forge_offer(slot,account,site,index)
	if not row.limit.is_empty():
		return ""
	account.silver -= row.price
	for material in row.materials:
		account.materials[material] -= row.materials[material]
	if row.manual:
		slot.manual_grants[row.id] = true
		return "习得 · " + Martial.MANUALS[row.id].move[0]
	slot.gear_levels[row.id] = Equipment.level(slot,row.id) + 1
	return "强化完成 · " + Equipment.display_name(slot,row.id)

static func material_label(inventory: Dictionary) -> String:
	var parts := PackedStringArray()
	for id in inventory:
		var amount: int = inventory[id]
		if amount > 0:
			parts.append("%s ×%d" % [Catalog.MATERIALS[id].name,amount])
	return "  ·  ".join(parts)

static func material_budget(cost: Dictionary, available: Dictionary) -> String:
	var parts := PackedStringArray()
	for id in cost:
		parts.append("%s %d/%d" % [Catalog.MATERIALS[id].name,available.get(id,0),cost[id]])
	return "  ·  ".join(parts)
