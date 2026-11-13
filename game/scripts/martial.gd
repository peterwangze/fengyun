extends RefCounted

const Story = preload("res://scripts/story.gd")
const Equipment = preload("res://scripts/equipment.gd")
const SYNERGY_TIER := 2
const SYNERGY_ADVANCED_TIER := 4
const CULTIVATION_RANK := 3
const EXPLOIT_COST := 3
const SYNERGY_NAMES := {"interrupt":"截势", "retaliate":"守反", "exploit":"乘隙"}
const PROTECTION := ["cover", "counter", "counter_poise", "shelter", "aid"]
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
const MANUALS := {
	"crosswind":{"hero":"wind", "source":"凤溪客栈截印", "move":["逆风截脉", 9, "风", 24, 2, "单体 · 削 2 势，敌蓄重招时额外削 1", "windup_break"]},
	"cloud_return":{"hero":"cloud", "source":"剑庐购入或拓印", "move":["回云卸劲", 9, "云", 0, 0, "自身 · 固守，接招后反击削 3 势", "counter_poise"]},
	"frost_gate":{"hero":"frost", "source":"凤溪石桥或渡船过河", "move":["霜锁渡门", 9, "寒", 22, 2, "单体 · 削 2 势，破势则给同伴护持", "frost_ward"]},
	"moon_needle":{"hero":"dream", "source":"完成药庐三问", "move":["针渡清脉", 10, "疗", 20, 0, "单体 · 治疗、回 6 气，魔念 −2", "needle_transfer"]},
	"sword_trace":{"hero":"sage", "source":"击退天牢卫队", "move":["寻隙剑", 10, "锋", 32, 1, "单体 · 对未破金身部分穿甲", "armor_pierce"]},
}
const MANUAL_INDEX := 4
const HERO_MANUALS := {"wind":"crosswind", "cloud":"cloud_return", "frost":"frost_gate", "dream":"moon_needle", "sage":"sword_trace"}
const CULTIVATION := {
	"wind":[{"id":"wind_seek","name":"逐风","detail":"以风系武学迎击重招时回 2 气。"},
		{"id":"wind_cover","name":"护风","detail":"成功代挡回 3 气，每回合一次。"}],
	"cloud":[{"id":"cloud_counter","name":"凝云","detail":"反击多削 1 格势。"},
		{"id":"cloud_pursuit","name":"追云","detail":"武学打空门威力 +5，每次出招一次。"}],
	"frost":[{"id":"frost_shelter","name":"寒衣","detail":"自身武学施加的护持额外减伤 2 点。"},
		{"id":"frost_shatter","name":"裂霜","detail":"引爆霜印时再削 1 格势。"}],
	"dream":[{"id":"dream_breath","name":"调息","detail":"医疗武学给另一名队员额外回复 2 气。"},
		{"id":"dream_heal","name":"温针","detail":"医疗武学用于半血以下的队员时多治 4 点。"}],
	"sage":[{"id":"sage_cut","name":"剑心","detail":"单体武学迎击重招时多削 1 格势。"},
		{"id":"sage_counter","name":"听锋","detail":"反击威力 +6。"}],
}
const MASTERY := {
	"wind":{"source":"壁刻遗图 · 留印研步","detail":"单体 · 迎重招额外削 2 格势"},
	"cloud":{"source":"炉火借一更","detail":"固守 · 反击削 3 势并回 3 气"},
	"frost":{"source":"雨夜押书","detail":"单体 · 破势后两人均获护持"},
	"dream":{"source":"药庐三问","detail":"单体 · 治疗、回 9 气，魔念 −2"},
	"sage":{"source":"换岗的灯","detail":"单体 · 保留 82% 威力穿金身"},
}
const NAMES := {"wind_frost":"风霜封渡","wind_dream":"风息回春","cloud_sage":"双剑开阵","wind_cloud":"风云合璧"}

static func options(id: String, sword: bool) -> Array:
	var base: Array = Story.HEROES[id].moves.duplicate(true)
	if id == "cloud" and not sword:
		base[1] = ["翻云掌",10,"云",24,1,"全体 · 破势 1"]
	base.append_array(EXTRA[id])
	base.append(MANUALS[HERO_MANUALS[id]].move.duplicate())
	return base

static func move_count(id: String) -> int:
	return MANUAL_INDEX + 1 if HERO_MANUALS.has(id) else 0

static func source(id: String, at: int) -> String:
	if at == MANUAL_INDEX and HERO_MANUALS.has(id):
		return MANUALS[HERO_MANUALS[id]].source
	return "随修行或任务解锁"

static func clean_grants(value: Variant) -> Dictionary:
	var grants := {}
	if value is Dictionary:
		for id in MANUALS:
			if value.get(id, false) == true:
				grants[id] = true
	return grants

static func clean_cultivation(value: Variant) -> Dictionary:
	var clean := {}
	if value is Dictionary:
		for hero in CULTIVATION:
			var choice: Variant = value.get(hero)
			for stance in CULTIVATION[hero]:
				if choice == stance.id:
					clean[hero] = choice
	return clean

static func clean_insights(value: Variant) -> Dictionary:
	var clean := {}
	if value is Dictionary:
		for hero in MASTERY:
			if value.get(hero) == true:
				clean[hero] = true
	return clean

static func cultivation_choice(slot: Dictionary, hero: String, rank: int) -> Dictionary:
	if rank < CULTIVATION_RANK:
		return {}
	var id: String = slot.get("cultivation", {}).get(hero, "")
	for stance in CULTIVATION.get(hero, []):
		if id == stance.id:
			return stance
	return {}

static func mastered(slot: Dictionary, hero: String) -> bool:
	return slot.get("insights", {}).get(hero, false) == true and unlocked(slot, hero, MANUAL_INDEX)

static func mastery_source(hero: String) -> String:
	return MASTERY.get(hero, {}).get("source", "")

static func training(slot: Dictionary, hero: String, rank: int) -> Dictionary:
	return {"stance":cultivation_choice(slot, hero, rank), "mastered":mastered(slot, hero)}

static func move_for(slot: Dictionary, hero: String, index: int) -> Array:
	var move: Array = options(hero, slot.campaign.sword)[index]
	if index == MANUAL_INDEX and mastered(slot, hero):
		_apply_mastery(hero, move)
	return move

static func _apply_mastery(hero: String, move: Array) -> void:
	move[5] = MASTERY[hero].detail
	move.append(true)

static func unlocked(slot: Dictionary, id: String, at: int) -> bool:
	if at < 0 or at >= move_count(id):
		return false
	if at == MANUAL_INDEX:
		return slot.get("manual_grants", {}).get(HERO_MANUALS[id], false) == true
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

static func slotted_moves(id: String, sword: bool, loadout: Array, chapter: int, mastering: bool = false) -> Array:
	var catalog := options(id, sword)
	if mastering:
		_apply_mastery(id, catalog[MANUAL_INDEX])
	var moves := loadout.map(func(at): return catalog[int(at)])
	if chapter == 3 and id == "wind":
		moves[1] = ["魔刀狂斩", 11, "锋", 30, 2, "全体 · 魔念 +2"]
	if chapter == 3 and id == "dream":
		for move in moves:
			if move[0] == "回春诀":
				move[5] = "全体治疗 · 魔念 −3"
	return moves

static func enhanced(move: Array) -> bool:
	return move.size() > 7 and move[7] == true

static func synergies(slot: Dictionary, hero: String, rank: int) -> Dictionary:
	if rank < SYNERGY_TIER:
		return {}
	var advanced := rank >= SYNERGY_ADVANCED_TIER
	var gear := [Equipment.equipped(slot, hero, 0), Equipment.equipped(slot, hero, 1)]
	var moves := slotted_moves(hero, slot.campaign.sword, prepared(slot, hero), int(slot.chapter))
	var active := {}
	if (gear[1] in ["qi_ring", "courier_badge"] or Equipment.style(gear[1]) == "interrupt") and moves.any(interrupt_move):
		var accessory := Equipment.equipped_modifiers(slot, hero, gear[1])
		active.interrupt = (5 if advanced else 3) + int(accessory.get("interrupt_qi", 0))
	if not gear[0].is_empty() and moves.any(protection_move):
		active.retaliate = 4 if advanced else 0
	if (gear[1] == "ferry_knot" or Equipment.style(gear[1]) == "exploit") and moves.any(exploit_move):
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
