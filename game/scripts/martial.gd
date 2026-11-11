extends RefCounted

const Story = preload("res://scripts/story.gd")
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

static func pair_id(party: Array) -> String:
	if party.has("wind"):
		for partner in ["cloud","frost","dream"]:
			if party.has(partner):
				return "wind_" + partner
	if party.has("cloud") and party.has("sage"):
		return "cloud_sage"
	return ""
