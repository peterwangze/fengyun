extends RefCounted

const Story = preload("res://scripts/story.gd")
const CATEGORIES := ["护具", "佩物"]
const CATALOG := {
	"travel_coat": {"kind":0,"name":"行旅布衣","source":"开篇自带","mods":{"hp":8,"attack":-2}},
	"scale_vest": {"kind":0,"name":"鳞纹背心","source":"达到境界 2","merit":4,"mods":{"hp":14,"qi":-4}},
	"witness_cape": {"kind":0,"name":"护证短披","source":"完成旧账新印","quest":"seals","mods":{"armor":2,"hp":-6}},
	"forge_apron": {"kind":0,"name":"剑庐护腕","source":"完成炉火借一更","quest":"forgework","mods":{"guard_qi":4,"attack":-2}},
	"palace_mail": {"kind":0,"name":"绝宫轻甲","source":"抵达无神绝宫","chapter":4,"mods":{"hp":18,"attack":-3}},
	"qi_ring": {"kind":1,"name":"纳气玉扣","source":"达到境界 2","merit":4,"mods":{"qi":6,"hp":-8}},
	"ferry_knot": {"kind":1,"name":"渡口缆结","source":"抵达剑池初鸣","chapter":2,"mods":{"broken_damage":6,"qi":-4}},
	"courier_badge": {"kind":1,"name":"信使铜牌","source":"完成雨夜押书","quest":"courier","mods":{"weakness_poise":1,"hp":-8}},
	"needle_case": {"kind":1,"name":"药庐针匣","source":"完成药庐三问","quest":"remedy","mods":{"heal":5,"attack":-2}},
	"peak_token": {"kind":1,"name":"石阶平安结","source":"完成石阶上的人","quest":"stairs","mods":{"armor":2,"qi":-4}},
}
const EFFECTS := {
	"hp":"气血", "qi":"真气", "attack":"攻击", "armor":"受击减伤",
	"guard_qi":"固守回气", "broken_damage":"对破势目标的武学伤害", "weakness_poise":"克制招式削势", "heal":"治疗武学",
}

static func unlocked(slot: Dictionary, id: String) -> bool:
	if slot.is_empty() or not CATALOG.has(id):
		return false
	var item: Dictionary = CATALOG[id]
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
			if id is String and unlocked(slot, id) and CATALOG[id].kind == kind and not used.has(id):
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
	if not id.is_empty() and (not unlocked(slot, id) or CATALOG[id].kind != kind):
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
			for effect in CATALOG[id].mods:
				total[effect] = total.get(effect, 0) + CATALOG[id].mods[effect]
	return total

static func attributes(hero: String, rank: int, mods: Dictionary) -> Dictionary:
	var base: Dictionary = Story.HEROES[hero]
	return {"hp":base.hp + (rank - 1) * 8 + mods.get("hp", 0),
		"qi":base.qi + (rank - 1) * 2 + mods.get("qi", 0),
		"attack":base.attack + (rank - 1) * 2 + mods.get("attack", 0)}

static func describe(id: String) -> String:
	var parts := PackedStringArray()
	var mods: Dictionary = CATALOG[id].mods
	for effect in mods:
		parts.append("%s %+d" % [EFFECTS[effect], mods[effect]])
	return "  ·  ".join(parts)
