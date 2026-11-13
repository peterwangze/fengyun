extends RefCounted

const Story = preload("res://scripts/story.gd")
const CATEGORIES := ["护具", "佩物"]
const MAX_FORGE_LEVEL := 2
const FORGE_BONUSES := {
	"reed_mantle":[{"sweep_armor":2}, {"sweep_armor":2}],
	"forge_guard":[{"counter_power":3}, {"counter_power":3}],
	"granary_vest":[{"heavy_armor":2}, {"heavy_armor":2}],
	"tide_whistle":[{"qi":2}, {"interrupt_qi":1}],
	"sword_tassel":[{"broken_damage":2}, {"broken_damage":3}],
	"apothecary_gourd":[{"heal":2}, {"ward_armor":2}],
}
const BRANCHES := {
	"wind_break":{"item":"tide_whistle","hero":"wind","name":"断潮风哨","mods":{"weakness_poise":1,"qi":-4}},
	"wind_breath":{"item":"tide_whistle","hero":"wind","name":"听潮风哨","mods":{"interrupt_qi":2,"attack":-2}},
	"cloud_returning":{"item":"forge_guard","hero":"cloud","name":"回澜铁臂","mods":{"counter_power":4,"hp":-8}},
	"cloud_bastion":{"item":"forge_guard","hero":"cloud","name":"镇浪铁臂","mods":{"heavy_armor":4,"counter_power":-2}},
	"cloud_edge":{"item":"sword_tassel","hero":"cloud","name":"锁隙剑穗","mods":{"broken_damage":5,"qi":-4}},
	"cloud_balance":{"item":"sword_tassel","hero":"cloud","name":"藏锋剑穗","mods":{"qi":5,"broken_damage":-3}},
	"tidal_bank":{"item":"granary_vest","hero":"wind","name":"护堤风衣","mods":{"sweep_armor":5,"heavy_armor":-3}},
	"tidal_watch":{"item":"granary_vest","hero":"cloud","name":"镇仓铁衣","mods":{"heavy_armor":3,"guard_qi":2,"hp":-8}},
}
const CATALOG := {
	"travel_coat": {"kind":0,"name":"行旅布衣","source":"开篇自带","mods":{"hp":8,"attack":-2}},
	"scale_vest": {"kind":0,"name":"鳞纹背心","source":"达到境界 2","merit":4,"mods":{"hp":14,"qi":-4}},
	"witness_cape": {"kind":0,"name":"护证短披","source":"完成旧账新印","quest":"seals","mods":{"armor":3,"hp":-8}},
	"forge_apron": {"kind":0,"name":"剑庐护腕","source":"完成炉火借一更","quest":"forgework","mods":{"guard_qi":4,"attack":-2}},
	"palace_mail": {"kind":0,"name":"绝宫轻甲","source":"抵达无神绝宫","chapter":4,"mods":{"armor":2,"hp":6,"attack":-3}},
	"reed_mantle": {"kind":0,"name":"芦蓑披肩","source":"凤溪客栈商贩","grant":true,"mods":{"sweep_armor":6,"hp":-8}},
	"forge_guard": {"kind":0,"name":"回锋护臂","source":"剑庐工匠","grant":true,"mods":{"counter_power":8,"attack":-3}},
	"granary_vest": {"kind":0,"name":"仓卫厚甲","source":"盐汊渡口粮商","grant":true,"mods":{"heavy_armor":8,"qi":-6}},
	"qi_ring": {"kind":1,"name":"纳气玉扣","source":"达到境界 2","merit":4,"mods":{"qi":6,"hp":-8}},
	"ferry_knot": {"kind":1,"name":"渡口缆结","source":"抵达剑池初鸣","chapter":2,"mods":{"broken_damage":6,"qi":-4}},
	"courier_badge": {"kind":1,"name":"信使铜牌","source":"完成雨夜押书","quest":"courier","mods":{"weakness_poise":1,"hp":-8}},
	"needle_case": {"kind":1,"name":"药庐针匣","source":"完成药庐三问","quest":"remedy","mods":{"heal":8,"attack":-2}},
	"peak_token": {"kind":1,"name":"石阶平安结","source":"完成石阶上的人","quest":"stairs","mods":{"armor":2,"qi":-4}},
	"tide_whistle": {"kind":1,"name":"渡口铜哨","source":"击退凤溪天池杀手","grant":true,"style":"interrupt","mods":{"qi":4,"attack":-2}},
	"sword_tassel": {"kind":1,"name":"火麟剑穗","source":"剑池击退断浪","grant":true,"style":"exploit","mods":{"broken_damage":9,"qi":-7}},
	"apothecary_gourd": {"kind":1,"name":"清息药葫","source":"生死门药庐","grant":true,"mods":{"heal":5,"ward_armor":4,"qi":-5}},
}
const EFFECTS := {
	"hp":"气血", "qi":"真气", "attack":"攻击", "armor":"受击减伤",
	"guard_qi":"固守回气", "broken_damage":"对破势目标的武学伤害", "weakness_poise":"克制招式削势", "heal":"治疗武学",
	"sweep_armor":"横扫减伤", "counter_power":"反击威力", "heavy_armor":"重击减伤", "ward_armor":"护持额外减伤",
	"interrupt_qi":"截势回气",
}

static func unlocked(slot: Dictionary, id: String) -> bool:
	if slot.is_empty() or not CATALOG.has(id):
		return false
	var item: Dictionary = CATALOG[id]
	if item.get("grant", false):
		return slot.get("gear_grants", {}).get(id, false) == true
	if item.has("quest"):
		return String(slot.chronicle.quests.get(item.quest, "")).begins_with("done_")
	return slot.merit >= item.get("merit", 0) and slot.chapter >= item.get("chapter", 0)

static func owned(slot: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	for id in CATALOG:
		if unlocked(slot, id):
			ids.append(id)
	return ids

static func options(kind: int) -> Array[String]:
	var ids: Array[String] = [""]
	for id in CATALOG:
		if CATALOG[id].kind == kind:
			ids.append(id)
	return ids

static func clean_grants(value: Variant) -> Dictionary:
	var grants := {}
	if value is Dictionary:
		for id in CATALOG:
			if CATALOG[id].get("grant", false) and value.get(id, false) == true:
				grants[id] = true
	return grants

static func style(id: String) -> String:
	return CATALOG.get(id, {}).get("style", "")

static func forgeable(id: String) -> bool:
	return FORGE_BONUSES.has(id)

static func level(slot: Dictionary, id: String) -> int:
	var levels: Variant = slot.get("gear_levels")
	return _stored_level(levels.get(id)) if forgeable(id) and levels is Dictionary else 0

static func clean_levels(slot: Dictionary, value: Variant) -> Dictionary:
	var clean := {}
	if value is Dictionary:
		for id in FORGE_BONUSES:
			var stored := _stored_level(value.get(id))
			if stored > 0 and unlocked(slot, id):
				clean[id] = stored
	return clean

static func _stored_level(value: Variant) -> int:
	if (value is int or value is float) and is_finite(float(value)) and value == floorf(value):
		return int(clampf(value, 0, MAX_FORGE_LEVEL))
	return 0

static func branch(slot: Dictionary, id: String) -> String:
	return slot.get("gear_branches",{}).get(id,"")

static func clean_branches(slot: Dictionary, value: Variant) -> Dictionary:
	var clean := {}
	if value is Dictionary:
		for id in FORGE_BONUSES:
			var chosen: Variant = value.get(id)
			if chosen is String and BRANCHES.has(chosen) and BRANCHES[chosen].item == id and level(slot,id) == MAX_FORGE_LEVEL and unlocked(slot,id):
				clean[id] = chosen
	return clean

static func can_wear(slot: Dictionary, hero: String, id: String) -> bool:
	var chosen := branch(slot,id)
	return chosen.is_empty() or BRANCHES[chosen].hero == hero

static func display_name(slot: Dictionary, id: String) -> String:
	var chosen := branch(slot,id)
	var name: String = CATALOG[id].name if chosen.is_empty() else BRANCHES[chosen].name
	var current := level(slot, id)
	return "%s +%d" % [name, current] if current > 0 else name

static func clean_loadouts(slot: Dictionary, stored: Variant) -> Dictionary:
	var clean := {}
	if not stored is Dictionary:
		return clean
	var used := []
	for hero in Story.HEROES:
		var items: Variant = stored.get(hero)
		if not items is Array or items.size() != CATEGORIES.size():
			continue
		var loadout := ["", ""]
		for kind in CATEGORIES.size():
			var id: Variant = items[kind]
			if id is String and unlocked(slot, id) and CATALOG[id].kind == kind and can_wear(slot,hero,id) and not used.has(id):
				loadout[kind] = id
				used.append(id)
		clean[hero] = loadout
	return clean

static func equipped(slot: Dictionary, hero: String, kind: int) -> String:
	return slot.gear.get(hero, ["", ""])[kind]

static func owner(slot: Dictionary, id: String) -> String:
	if not id.is_empty():
		for hero in slot.gear:
			if id in slot.gear[hero]:
				return hero
	return ""

static func assign(slot: Dictionary, hero: String, kind: int, id: String) -> bool:
	if not Story.HEROES.has(hero) or kind < 0 or kind >= CATEGORIES.size():
		return false
	if not id.is_empty() and (not unlocked(slot, id) or CATALOG[id].kind != kind or not can_wear(slot,hero,id)):
		return false
	var holder := owner(slot, id)
	if not holder.is_empty():
		slot.gear[holder][kind] = ""
	if not slot.gear.has(hero):
		slot.gear[hero] = ["", ""]
	slot.gear[hero][kind] = id
	return true

static func modifiers(slot: Dictionary, hero: String) -> Dictionary:
	var total := {}
	for id in slot.gear.get(hero, []):
		if not id.is_empty():
			_merge_mods(total, equipped_modifiers(slot,hero,id))
	return total

static func equipped_modifiers(slot: Dictionary, hero: String, id: String) -> Dictionary:
	return _owned_modifiers(slot,id) if can_wear(slot,hero,id) else {}

static func _owned_modifiers(slot: Dictionary, id: String) -> Dictionary:
	var mods := item_modifiers(id,level(slot,id))
	var chosen := branch(slot,id)
	if not chosen.is_empty():
		_merge_mods(mods,BRANCHES[chosen].mods)
	return mods

static func describe_owned(slot: Dictionary, id: String) -> String:
	return _describe_mods(_owned_modifiers(slot,id))

static func branch_description(recipe: String) -> String:
	return _describe_mods(BRANCHES[recipe].mods)

static func item_modifiers(id: String, at_level: int = 0) -> Dictionary:
	var mods: Dictionary = CATALOG[id].mods.duplicate()
	if forgeable(id):
		for index in clampi(at_level, 0, MAX_FORGE_LEVEL):
			_merge_mods(mods, FORGE_BONUSES[id][index])
	return mods

static func _merge_mods(total: Dictionary, mods: Dictionary) -> void:
	for effect in mods:
		total[effect] = total.get(effect, 0) + mods[effect]

static func attributes(hero: String, rank: int, mods: Dictionary) -> Dictionary:
	var base: Dictionary = Story.HEROES[hero]
	return {"hp":base.hp + (rank - 1) * 8 + mods.get("hp", 0),
		"qi":base.qi + (rank - 1) * 2 + mods.get("qi", 0),
		"attack":base.attack + (rank - 1) * 2 + mods.get("attack", 0)}

static func describe(id: String, at_level: int = 0) -> String:
	return _describe_mods(item_modifiers(id, at_level))

static func upgrade_description(id: String, next_level: int) -> String:
	if not forgeable(id) or next_level < 1 or next_level > MAX_FORGE_LEVEL:
		return ""
	return _describe_mods(FORGE_BONUSES[id][next_level - 1])

static func _describe_mods(mods: Dictionary) -> String:
	var parts := PackedStringArray()
	for effect in mods:
		parts.append("%s %+d" % [EFFECTS[effect], mods[effect]])
	return "  ·  ".join(parts)

static func quest_reward(quest: String) -> String:
	for id in CATALOG:
		if CATALOG[id].get("quest", "") == quest:
			return CATALOG[id].name
	return ""
