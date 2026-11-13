extends RefCounted

const Story = preload("res://scripts/story.gd")
const Equipment = preload("res://scripts/equipment.gd")
const SYNERGY_TIER := 2
const SYNERGY_ADVANCED_TIER := 4
const EXPLOIT_COST := 3
const SYNERGY_NAMES := {"interrupt":"截势", "retaliate":"守反", "exploit":"乘隙"}
const PROTECTION := ["cover", "counter", "shelter", "aid"]
const EXTRA := {
	"wind": [
		["护风步",7,"风",0,0,"单体 · 替同伴挡下一击","cover"],
		["回风腿",8,"风",28,2,"单体 · 命中后回气 6","breath"]],
	"cloud": [
		["翻云守势",7,"云",0,0,"自身 · 固守后反击","counter"],
		["断浪追斩",10,"锋",32,2,"单体 · 敌人破势时追斩","pursuit"]],
	"frost": [
		["寒衣护体",7,"寒",0,0,"我方全体 · 各挡下一击","shelter"],
		["冰魄裂拳",9,"寒",28,2,"单体 · 引爆霜印削势","shatter"]],
	"dream": [
		["护心针",7,"疗",18,0,"单体 · 小幅治疗与护持","aid"],
		["回雪清心",10,"疗",13,0,"我方全体 · 治疗与魔念 −4","cleanse"]],
	"sage": [
		["听剑式",7,"锋",0,0,"自身 · 招架反制","counter"],
		["归鞘纳气",8,"锋",26,2,"单体 · 命中后回气 6","breath"]]
}
const OPEN_AT := {
	"wind":[1,3], "cloud":[2,2], "frost":[1,1], "dream":[3,3], "sage":[4,4]
}
const QUEST_MOVES := {
	"cloud_2":"forgework", "dream_2":"remedy"
}
const NAMES := {"wind_frost":"风霜封渡","wind_dream":"风息回春","cloud_sage":"双剑开阵","wind_cloud":"风云合璧"}

static func options(id: String, sword: bool) -> Array:
	var base: Array = Story.HEROES[id].moves.duplicate(true)
	if id == "cloud" and not sword:
		base[1] = ["翻云掌",10,"云",24,1,"全体 · 破势 1"]
	base.append_array(EXTRA[id])
	return base

static func unlocked(slot: Dictionary, id: String, at: int) -> bool:
	if at < 2:
		return true
	var quest: String = QUEST_MOVES.get("%s_%d" % [id,at],"")
	if not quest.is_empty() and String(slot.chronicle.quests.get(quest,"")).begins_with("done_"):
		return true
	if at == 2 and int(slot.chapter) >= int(slot.chronicle.from_chapter):
		if id == "cloud" and slot.chapter == 2:
			return slot.chronicle.marks.get("lesson",false)
		if id == "dream" and slot.chapter == 3:
			return slot.cleared.has(0)
	return slot.chapter >= OPEN_AT[id][at-2]

static func prepared(slot: Dictionary, id: String) -> Array:
	var loadout: Array = slot.chronicle.loadout.get(id,[0,1])
	var valid := loadout.filter(func(at): return unlocked(slot,id,int(at)))
	return valid if valid.size() == 2 else [0,1]

static func slotted_moves(id: String, sword: bool, loadout: Array, chapter: int) -> Array:
	var catalog := options(id, sword)
	var moves := loadout.map(func(at): return catalog[int(at)])
	if chapter == 3 and id == "wind":
		moves[1] = ["魔刀狂斩", 11, "锋", 30, 2, "全体 · 魔念 +2"]
	if chapter == 3 and id == "dream":
		for move in moves:
			if move[0] == "回春诀":
				move[5] = "全体治疗 · 魔念 −3"
	return moves

static func synergies(slot: Dictionary, hero: String, rank: int) -> Dictionary:
	if rank < SYNERGY_TIER:
		return {}
	var advanced := rank >= SYNERGY_ADVANCED_TIER
	var gear := [Equipment.equipped(slot, hero, 0), Equipment.equipped(slot, hero, 1)]
	var moves := slotted_moves(hero, slot.campaign.sword, prepared(slot, hero), int(slot.chapter))
	var active := {}
	if gear[1] in ["qi_ring", "courier_badge"] and moves.any(interrupt_move):
		active.interrupt = 5 if advanced else 3
	if not gear[0].is_empty() and moves.any(protection_move):
		active.retaliate = 4 if advanced else 0
	if gear[1] == "ferry_knot" and moves.any(exploit_move):
		active.exploit = 12 if advanced else 8
	return active

static func interrupt_move(move: Array) -> bool:
	return move[3] > 0 and move[4] >= 2 and "单体" in move[5] and move[2] != "疗"

static func protection_move(move: Array) -> bool:
	return move.size() > 6 and move[6] in PROTECTION

static func exploit_move(move: Array) -> bool:
	return move[2] != "疗" and move[3] >= 30 and move[1] >= 9

static func synergy_text(slot: Dictionary, hero: String, rank: int) -> String:
	var active := synergies(slot, hero, rank)
	var names := PackedStringArray()
	for id in active:
		names.append(SYNERGY_NAMES[id])
	return " · ".join(names)

static func synergy_descriptions(slot: Dictionary, hero: String, rank: int) -> PackedStringArray:
	var active := synergies(slot, hero, rank)
	var descriptions := PackedStringArray()
	if active.has("interrupt"):
		descriptions.append("截势 · 武学破势回 %d 气，截断重招多回 2 气" % active.interrupt)
	if active.has("retaliate"):
		var recovery := "、回 %d 气" % active.retaliate if active.retaliate > 0 else ""
		descriptions.append("守反 · 接住一击造空门，合击 +1%s" % recovery)
	if active.has("exploit"):
		descriptions.append("乘隙 · 重招打空门，额外耗 3 气，威力 +%d" % active.exploit)
	return descriptions

static func pair_id(party: Array) -> String:
	if party.has("wind"):
		for partner in ["cloud","frost","dream"]:
			if party.has(partner):
				return "wind_" + partner
	if party.has("cloud") and party.has("sage"):
		return "cloud_sage"
	return ""
