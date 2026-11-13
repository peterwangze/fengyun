extends RefCounted

const ORDER := ["breath_pill", "guard_powder", "stagger_needle"]
const CAP := 5
const CATALOG := {
	"breath_pill": {
		"name":"聚气丸", "target":"ally", "amount":18,
		"detail":"为一名仍可行动的队友回复 18 真气。",
		"source":"开篇、药箱与支线",
	},
	"guard_powder": {
		"name":"护脉散", "target":"ally", "amount":55,
		"detail":"为一名队友护持一次，下次受击额外减伤 55%。",
		"source":"探索暗格、药箱与支线",
	},
	"stagger_needle": {
		"name":"破势针", "target":"foe", "amount":2,
		"detail":"削去敌人 2 格势，可打断蓄势、鸣哨或擂鼓。",
		"source":"探索暗格、可选战与支线",
	},
}

const REWARDS := {
	"chest:hall":{"guard_powder":1},
	"chest:village":{"breath_pill":1},
	"chest:forge":{"stagger_needle":1},
	"chest:pool":{"guard_powder":1},
	"chest:palace":{"guard_powder":1,"breath_pill":1},
	"chest:peak":{"stagger_needle":1,"breath_pill":1},
	"cache:garden":{"guard_powder":1,"stagger_needle":1},
	"cache:inn":{"breath_pill":1,"guard_powder":1},
	"hunt:inn":{"stagger_needle":2},
	"hunt:hall":{"breath_pill":1},
	"hunt:village":{"stagger_needle":1},
	"hunt:forge":{"stagger_needle":1},
	"hunt:pool":{"breath_pill":1},
	"hunt:palace":{"guard_powder":1},
	"hunt:peak":{"stagger_needle":1,"guard_powder":1},
	"quest:seals":{"guard_powder":1},
	"quest:lamps_rescue":{"breath_pill":1},
	"quest:lamps":{"guard_powder":1},
	"quest:courier":{"stagger_needle":1},
	"quest:forgework":{"guard_powder":1,"stagger_needle":1},
	"quest:swordstory_ledger":{"stagger_needle":1},
	"quest:swordstory":{"guard_powder":1,"stagger_needle":1},
	"quest:remedy":{"guard_powder":2},
	"quest:shift":{"guard_powder":1,"stagger_needle":1},
	"quest:stairs":{"breath_pill":1,"guard_powder":1},
}

static func fresh(chapter: int = 0) -> Dictionary:
	return {"breath_pill":1, "guard_powder":int(chapter >= 1), "stagger_needle":int(chapter >= 2)}

static func clean(stock: Variant) -> Dictionary:
	var valid := {}
	for id in ORDER:
		var count: Variant = stock.get(id, 0) if stock is Dictionary else 0
		valid[id] = 0
		if (count is int or count is float) and is_finite(float(count)) and count == floorf(count):
			valid[id] = int(clampf(count, 0, CAP))
	return valid

static func clean_claims(claims: Variant) -> Dictionary:
	var valid := {}
	if claims is Dictionary:
		for source in REWARDS:
			var claimed: Variant = claims.get(source, false)
			if claimed is bool and claimed:
				valid[source] = true
	return valid

static func reward(stock: Dictionary, source: String) -> Array[String]:
	var received: Array[String] = []
	var contents: Dictionary = REWARDS.get(source, {})
	for id in contents:
		var before: int = stock.get(id, 0)
		var after := mini(CAP, before + int(contents[id]))
		if after > before:
			stock[id] = after
			received.append(_label(id, after - before))
	return received

static func reward_label(source: String) -> String:
	var contents: Dictionary = REWARDS.get(source, {})
	var names: Array[String] = []
	for id in contents:
		names.append(_label(id, contents[id]))
	return "、".join(names)

static func reconcile_quests(slot: Dictionary, stock: Dictionary, claims: Dictionary) -> Array[String]:
	var received: Array[String] = []
	var quests: Dictionary = slot.get("chronicle", {}).get("quests", {})
	for key in quests:
		var step := String(quests[key])
		if key == "lamps" and step in ["wait_boat", "wait_goods", "done_boat", "done_goods"]:
			received.append_array(_claim(stock, claims, "quest:lamps_rescue"))
		if key == "swordstory" and step in ["wait_palace", "wait_sage", "wait_guard", "done_sage", "done_guard"]:
			received.append_array(_claim(stock, claims, "quest:swordstory_ledger"))
		if step.begins_with("done_"):
			received.append_array(_claim(stock, claims, "quest:" + String(key)))
	return received

static func can_target(id: String, unit: Dictionary) -> bool:
	if unit.hp <= 0:
		return false
	match id:
		"breath_pill": return unit.qi < unit.max_qi
		"guard_powder": return not unit.ward
		"stagger_needle": return not unit.broken and unit.poise > int(unit.resolve)
	return false

static func _claim(stock: Dictionary, claims: Dictionary, source: String) -> Array[String]:
	if claims.has(source) or not REWARDS.has(source):
		return []
	claims[source] = true
	return reward(stock, source)

static func _label(id: String, count: int) -> String:
	return "%s ×%d" % [CATALOG[id].name, count]
