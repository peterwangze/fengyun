extends RefCounted

const Catalog = preload("res://scripts/market_catalog.gd")
const Equipment = preload("res://scripts/equipment.gd")
const Items = preload("res://scripts/items.gd")
const Martial = preload("res://scripts/martial.gd")
const Story = preload("res://scripts/story.gd")
const SHOPS = Catalog.SHOPS
const SILVER_CAP := 999
const START_SILVER := 4
const TIDE_SILVER := 9

static func normalize(slot: Dictionary) -> void:
	_normalize_account(slot, START_SILVER + int(slot.chapter) * 5)
	slot.gear_grants = Equipment.clean_grants(slot.get("gear_grants"))
	slot.manual_grants = Martial.clean_grants(slot.get("manual_grants"))
	if slot.has("afterstory"):
		normalize_tide(slot.afterstory)

static func normalize_tide(account: Dictionary) -> void:
	_normalize_account(account, TIDE_SILVER)

static func _normalize_account(account: Dictionary, starter: int) -> void:
	account.silver = _count(account.get("silver", starter), SILVER_CAP)
	var purchases := {}
	var stored: Variant = account.get("shop_stock")
	if stored is Dictionary:
		for shop in SHOPS:
			if not stored.get(shop) is Dictionary:
				continue
			var counts := {}
			for good in SHOPS[shop].goods:
				var used := _count(stored[shop].get(good.id), good.count)
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

static func _known_source(source: String) -> bool:
	return Catalog.DROPS.has(source) or source.begins_with("battle:") or source.begins_with("special:") or source.begins_with("tidal:")

static func _count(value: Variant, maximum: int) -> int:
	if (value is int or value is float) and is_finite(float(value)) and value == floorf(value):
		return int(clampf(value, 0, maximum))
	return 0

static func offer(slot: Dictionary, account: Dictionary, shop: String, index: int) -> Dictionary:
	var good: Dictionary = SHOPS[shop].goods[index]
	var id: String = good.id
	var remaining: int = good.count - int(account.shop_stock.get(shop, {}).get(id, 0))
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
		"tonic":
			if account.tonics >= (6 if shop == "tidegate" else 9): limit = "药囊已满"
	if remaining <= 0 and limit.is_empty(): limit = "售罄"
	if account.silver < good.price and limit.is_empty(): limit = "银两不足"
	return {"name":name,"detail":detail,"remaining":remaining,"price":good.price,"limit":limit}

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
	account.silver -= good.price
	var purchases: Dictionary = account.shop_stock.get(shop, {})
	purchases[id] = int(purchases.get(id, 0)) + 1
	account.shop_stock[shop] = purchases
	return row.name

static func claim(slot: Dictionary, account: Dictionary, source: String, silver: int = 0) -> PackedStringArray:
	var gains := PackedStringArray()
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

static func source_note(source: String) -> String:
	return Catalog.DROPS.get(source, {}).get("line", "")

static func reconcile(slot: Dictionary) -> PackedStringArray:
	var gains := PackedStringArray()
	for quest in slot.chronicle.quests:
		if String(slot.chronicle.quests[quest]).begins_with("done_"):
			gains.append_array(claim(slot, slot, "quest:" + quest))
	if int(slot.chapter) == 1 and slot.campaign.crossing == "boat":
		gains.append_array(claim(slot, slot, "progress:ferry"))
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
