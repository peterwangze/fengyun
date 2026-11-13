extends RefCounted

const Equipment = preload("res://scripts/equipment.gd")
const Items = preload("res://scripts/items.gd")

const COURIER_CONTACT_POS := Vector2(208,209)
const COURIER_CONTACT_NAME := "与凤溪信使会合"
const TASKS := {
	"seals": {
		"title":"旧账新印",
		"steps":{
			"start":["hall",142,222,"查看押粮清单","","押粮簿中有两班守卫，盖章却出自同一只手。先问送饭的仆役。","witness"],
			"witness":["banquet",190,177,"询问送饭仆役","servant","我亲眼看见执事在宴前换了印。柜底还有一张旧单。","proof"],
			"proof":["banquet",430,189,"查看柜下旧单","","旧单的印缺一角，和刚换过的那张不同。","decision"],
			"decision":["banquet",248,247,"安置证人","maid","撤离的路你们熟。要我带路，还是留下把口供写全？",[
				["先带证人走","done_guide"],["留下写完口供","done_proof"]]]}},
	"lamps": {
		"title":"一盏灯，两条船",
		"steps":{
			"start":["inn",182,202,"向渡工问灯","boatman_front","三短一长是渡客求救。西岸浅滩还亮着一盏，去看看。","shore"],
			"shore":["village",144,265,"辨认浅滩灯号","","浅滩有人招手。缆绳够拖人，还能救起船或那箱过冬的货。","decision"],
			"decision":["inn",198,251,"决定渡口救援","boatman_front","我已经把人抬回来了。水还在涨，我们现在只能拖回一样东西。",[
				["先把船拖回来","wait_boat"],["先救过冬的货","wait_goods"]]],
			"wait_boat":["dawn",208,254,"回访修好的船","boatman_front","船肋换好了。多亏你留住船身，眼下每天都能开两趟。","done_boat"],
			"wait_goods":["dawn",208,254,"探望渡口新人","boatman_front","乡亲有粮过冬。丢掉的船暂时由邻村渡工补上，我能歇几天。","done_goods"]}},
	"courier": {
		"title":"雨夜押书",
		"steps":{
			"start":["village",76,233,"查看雨中脚印","","脚尖都向北，路牌却指向南。新钉的那块路牌是假的。","watch"],
			"watch":["village",174,155,"听竹林的哨声","","两急一缓从河边传来。沿背风墙走可以避开巡哨。","decision"],
			"decision":["inn",431,210,"接应信使","servant","沿背风墙走，我能先把求援信送给药师。正门探子知道绝宫的操练口令，截住他就能问出来。",[
				["沿背风墙护送","done_quiet"],["截住正门探子","fight"]]]}},
	"forgework": {
		"title":"炉火借一更",
		"steps":{
			"start":["forge",153,169,"询问熔沟工匠","guide","主渠水压太高。先开旁槽放掉压力，再去拉第二道闸。","sluice"],
			"sluice":["forge",187,132,"打开泄压旁槽","","水面往下落了一尺，第二道闸的铜柄已经能动。","gate"],
			"gate":["forge",228,239,"放下第二道闸","","熔沟的火退开了。工匠把修好的剑架送往剑庐。","rack"],
			"rack":["swordhall",431,209,"检查修好的剑架","guide","试试用掌心卸力，接着翻腕还手。这是剑庄守门人的路数。","done_rack"]}},
	"swordstory": {
		"title":"一柄未开锋的剑",
		"steps":{
			"start":["swordhall",182,231,"询问于楚楚","chuchu","剑没有开锋，断口却被反复锉过。屋里那本修剑簿也许记了缘由。","ledger"],
			"ledger":["swordhall",459,258,"核对修剑簿","","守剑人故意挫断旧剑，瞒过盘查，好让工匠有机会从炉后逃走。","wait_palace"],
			"wait_palace":["tearoom",164,248,"安置无锋旧剑","chuchu","我从炉后带出了旧剑。无名能认出它的来处，城中守军也会认这枚标记。",[
				["交无名保管","wait_sage"],["交守军引路","wait_guard"]]],
			"wait_sage":["peak",178,240,"听无名讲解雄霸的起手","sage","那柄旧剑上的刻痕记的是天下会的起手次序。雄霸抬手换气时，你们两人一起踏进半步，能先攒一格合击。","done_sage"],
			"wait_guard":["peak",178,240,"与引路的守军会合","guard","见剑认人。先走这条小径，我把困在山腰的人领下去。等你们对上雄霸，我从侧坡放响箭，分他的神。","done_guard"]}},
	"remedy": {
		"title":"药庐三问",
		"steps":{
			"start":["apothecary",175,192,"询问药庐病人","servant","我一使劲就喘，药也吃了好些。桌上放着药渣，先生说先看那个。","sample"],
			"sample":["apothecary",468,206,"辨认温凉药渣","","手心发热，药渣却全是温补药。先护住心脉，再缓解燥热。","decision"],
			"decision":["apothecary",178,251,"请第二梦校验药方","dream","你会先稳心脉，还是先强行压住热气？",[
				["先护住心脉","done_aid"],["先强压热气","recheck"]]]}},
	"shift": {
		"title":"换岗的灯",
		"steps":{
			"start":["jail",148,248,"读狱门值更簿","","末班狱卒被关在侧廊。两盏灯都向内，才是换岗信号。","lamp"],
			"lamp":["jail",427,220,"拨转换岗灯","","灯罩转向内侧。右侧守卫正在交班，可以从茶房绕过去。","decision"],
			"decision":["tearoom",482,253,"接应被关的狱卒","guard","门外还有人。我知道侧廊便门的栓在哪里，你们打算怎么带我走？",[
				["趁换岗潜行","done_stealth"],["迎面引开守卫","fight"]]]}},
	"stairs": {
		"title":"石阶上的人",
		"steps":{
			"start":["peak",151,192,"安抚受困村民","servant","石阶被堵住了，有几个老人走不快。右侧裂石后有藏身处。","trail"],
			"trail":["peak",398,230,"寻找撤离小径","","小径能通山脚。可先藏好村民，或由另一人把追兵引开。","decision"],
			"decision":["peak",431,258,"安排村民下山","maid","我会带他们下山。等你招呼，我们再一起过石阶。",[
				["守住小径接应","escort"],["把追兵引到岔口","fight"]]],
			"escort":["peak",468,201,"接应下山的村民","servant","最后一个人到了。把石缝里的灯带上吧，船家在山下等我们。","done_escort"]}}
}

const RESULT := {
	"done_guide":"证人带路。竹径巡哨的视线缩短。","done_proof":"秦霜带走口供。凤溪纸探花开战少 1 格势。",
	"wait_boat":"船拖上岸。尾声可回访，潮关可请渡工开水栅。","wait_goods":"冬粮抢回。尾声可回访，潮关可获乡亲补给。",
	"done_boat":"渡口恢复两班船。","done_goods":"邻村渡工来接班。",
	"done_quiet":"求援信已送给药师。","done_fight":"截击成功，取得绝宫操练口令。",
	"done_rack":"剑架修复，习得翻云守势。","wait_palace":"找到断剑缘由，绝宫再见于楚楚。",
	"wait_sage":"无名会把情报送到凌云山。","wait_guard":"守军会在凌云山接应。",
	"done_sage":"风云练过起手。雄霸决战开场多 1 格合击。","done_guard":"守军疏散山腰百姓，决战开场削雄霸 2 格势。",
	"done_aid":"药方可用，习得护心针。","done_stealth":"便门已开。狱卒给聂风留了一次护持。",
	"done_escort":"村民沿小径平安下山。","done_decoy":"追兵离开，村民已经下山。"
}

const ROOMS := {
	"hall":[0,"飞云堂庭院"], "banquet":[0,"天下会喜堂"],
	"village":[1,"凤溪西岸"], "inn":[1,"凤溪西岸客栈"],
	"forge":[2,"拜剑山庄剑池"], "swordhall":[2,"拜剑山庄剑庐"],
	"apothecary":[3,"生死门药庐"], "jail":[4,"绝宫天牢"], "tearoom":[4,"绝宫茶房侧廊"],
	"peak":[5,"凌云山石阶"], "dawn":[5,"清晨凤溪"],
}
const CHAPTERS := ["第一章", "第二章", "第三章", "第四章", "第五章", "第六章"]
const DECISIONS := {
	"seals":"带证人走可缩短竹径守卫视线。留口供给秦霜，能让纸探花开场少 1 格势。",
	"lamps":"拖船能复航，潮关有渡工开水栅。救粮能保住冬粮，潮关可获乡亲补给。",
	"courier":"护送可免战，求援信能换药护持。截探子须交手，口令能削绝无神的势。",
	"swordstory":"无名可教合击起手。守军能开小径，并用响箭削雄霸的势。需在凌云山会合。",
	"remedy":"结合脉象和温补药渣，判断哪件事更紧急。",
	"shift":"两路都开便门。潜行保住护心镜，交手可夺铜哨，均可用于凌云窟。",
	"stairs":"守住小径需等到最后一人下山。把追兵引开要打一场。",
}
const CONSEQUENCES := {
	"seals":"缩短竹径巡哨视线，或让纸探花开局少 1 格势",
	"lamps":"改变凤溪尾声。潮关可提早开水栅或获补给。",
	"courier":"绝宫茶房会合，决战金身时可得护持或削敌 2 格势。",
	"forgework":"学会翻云守势，固守后可反击",
	"swordstory":"决战可多 1 格合击，或开近路并削雄霸 2 格势",
	"remedy":"学会护心针，可治疗并护持队友",
	"shift":"打开撤离便门。龙脉战可护持聂风或削守兽 2 格势",
	"stairs":"村民在尾声回到凤溪",
}

var g

func _init(game: Node2D) -> void:
	g = game

func state() -> Dictionary:
	return g.slot.chronicle.quests

func courier_contact_available() -> bool:
	return int(g.slot.chapter) == 4 and g.chronicle.enabled() and not g.slot.cleared.has(1) \
		and not g.chronicle.has("courier_contact") and state().get("courier","") in ["done_quiet","done_fight"]

func battle_aid(room: String, encounter_index: int, special_id: String) -> Dictionary:
	var quests := state()
	if special_id == "cavern_guard" and room == "cavern":
		match quests.get("shift",""):
			"done_stealth":
				return {"ward":"wind","line":"狱卒的护心镜让聂风获得一次护持。"}
			"done_fight":
				return {"foe":"beast","poise":2,"line":"铜哨引开守兽视线，火麟幻影开场少 2 格势。"}
	if not special_id.is_empty() or encounter_index != 1:
		return {}
	match room:
		"village":
			if quests.get("seals","") == "done_proof":
				return {"foe":"paper","poise":1,"line":"秦霜凭口供预判换哨，纸探花开场少 1 格势。"}
		"palace":
			if g.chronicle.has("courier_contact"):
				match quests.get("courier",""):
					"done_quiet":
						return {"ward":"sage","line":"信使带来的护脉散护住无名，可挡下一次重击。"}
					"done_fight":
						return {"foe":"godless","poise":2,"line":"步惊云喊出操练口令，绝无神开场少 2 格势。"}
		"peak":
			match quests.get("swordstory",""):
				"done_sage":
					return {"bond":1,"line":"无名教的起手已用上，风云开场多 1 格合击。"}
				"done_guard":
					return {"foe":"boss","poise":2,"line":"侧坡响箭引雄霸分神，他开场少 2 格势。"}
	return {}

func points() -> Array:
	var result := []
	for id in TASKS:
		var task: Dictionary = TASKS[id]
		var step: String = state().get(id,"start")
		var node: Array = task.steps.get(step,[])
		if node.is_empty() or not _reachable(node[0]):
			continue
		if node[0] == g.field_key:
			result.append({"id":"side_"+id,"name":_action(id,step,node),"pos":Vector2(node[1],node[2]),"index":-1,
				"sprite":node[4],"optional":true})
		if id == "forgework" and step == "sluice" and g.field_key == "forge":
			result.append({"id":"forge_valve_locked","name":"试拉第二道闸","pos":Vector2(228,239),"index":-1,
				"sprite":"","optional":true})
	return result

func handle(id: String) -> bool:
	if id == "forge_valve_locked":
		g.sfx("mechanism")
		g._notice("铜柄卡死。先打开泄压旁槽。")
		return true
	if not id.begins_with("side_"):
		return false
	var key := id.trim_prefix("side_")
	var task: Dictionary = TASKS[key]
	var step: String = state().get(key,"start")
	var node: Array = task.steps[step]
	var speaker: String = "手记" if node[4].is_empty() else String(node[3]).substr(0,8)
	var dialogue: String = node[5]
	if key == "swordstory" and _duel_finished():
		match step:
			"wait_sage": dialogue = "旧剑的刻痕是天下会的起手次序。如今雄霸已倒，留下这柄剑，也好记得这门武艺还能用来救人。"
			"wait_guard": dialogue = "见剑认人。我已沿侧坡把落单的人接下山。下回有人拿这柄剑来，我还认得路。"
	g.chronicle.speak([[speaker,dialogue]],func():
		if node[6] is Array:
			g.chronicle.choose(task.title,node[6],func(outcome): _finish(key,outcome),DECISIONS[key])
		else:
			_finish(key,node[6]))
	return true

func _finish(key: String, outcome: String) -> void:
	match outcome:
		"fight":
			var battles := {"courier":"courier_guard","shift":"shift_guard","stairs":"stairs_guard"}
			g.chronicle.begin_special(battles[key])
		"recheck":
			g.chronicle.speak([["第二梦","温药已经伤了心脉。再看一次药渣，然后来找我。"]],func(): finish(key,"sample"))
		_:
			finish(key,outcome)

func finish(key: String, step: String) -> void:
	if String(state().get(key,"")).begins_with("done_"):
		g._return_to_field()
		return
	state()[key] = step
	g._commit()
	g._return_to_field()
	g._notice(_result_line(key,step))

func note(key: String) -> String:
	return journal_entry(key).status

func journal_entry(key: String) -> Dictionary:
	var task: Dictionary = TASKS[key]
	var step: String = state().get(key,"start")
	var reward := Items.reward_label("quest:" + key)
	var item := Equipment.quest_reward(key)
	if not item.is_empty():
		reward = item + "、" + reward
	var entry := {"status":"已完成", "action":"", "place":"", "deadline":"", "payoff":CONSEQUENCES[key], "reward":reward}
	if step.begins_with("done_"):
		entry.action = _result_line(key,step)
		entry.payoff = _settled_payoff(key,step)
		if key == "courier" and not g.slot.finished and not g.chronicle.has("courier_contact") \
			and (int(g.slot.chapter) < 4 or courier_contact_available()):
			entry.status = "待回访"
			entry.action = COURIER_CONTACT_NAME
			entry.place = "第五章 · 绝宫茶房侧廊" if int(g.slot.chapter) < 4 else "绝宫茶房侧廊"
			entry.deadline = "破金身前"
			if g.field_key == "tearoom":
				entry.point = COURIER_CONTACT_POS
		return entry
	var node: Array = task.steps[step]
	var room: String = node[0]
	var chapter: int = ROOMS[room][0]
	entry.action = _action(key,step,node)
	entry.place = ROOMS[room][1]
	entry.deadline = _deadline(room)
	if key == "swordstory" and step in ["wait_sage","wait_guard"]:
		entry.payoff = ("无名教合击起手，雄霸战开场多 1 格合击" if step == "wait_sage"
			else "守军开小径，雄霸战开场少 2 格势")
		entry.deadline = "决战前会合可获支援"
		if _duel_finished():
			entry.deadline = "从凌云山下山前"
			entry.payoff = "决战已结束，仍可赴约交代旧剑的下落。"
	if _missed(room):
		entry.status = "已错过"
		entry.deadline = "可在章节回看中重访"
		return entry
	if int(g.slot.chapter) < chapter:
		entry.status = "后续章节" if step == "start" else "待回访"
		entry.place = CHAPTERS[chapter] + " · " + String(entry.place)
		if g.chronicle.review:
			entry.deadline = "正式旅程才能跨章回访"
		return entry
	if room == "dawn" and g.field_key != "dawn":
		entry.status = "待回访"
		return entry
	if step == "start":
		entry.status = "可接取"
	elif node[6] is Array:
		entry.status = "待抉择"
	elif String(node[6]).begins_with("done_"):
		entry.status = "待交付"
	else:
		entry.status = "进行中"
	if _behind_crossing(room):
		entry.place += "（需先过河）"
	elif room == g.field_key and _reachable(room):
		entry.point = Vector2(node[1],node[2])
	return entry

func _result_line(key: String, step: String) -> String:
	if key == "shift" and step == "done_fight":
		return "便门已开。夺来的铜哨能引开守兽。"
	if key == "swordstory" and _duel_finished():
		if step == "done_sage": return "无名收妥旧剑。"
		if step == "done_guard": return "守军已接应落单的百姓。"
	return RESULT.get(step,"已更新《江湖手记》。")

func _settled_payoff(key: String, step: String) -> String:
	match key:
		"seals": return "竹径撤离时可利用这条路。" if step == "done_guide" else "纸探花更容易被破势，能提前打断鸣哨。"
		"lamps":
			return "潮关查齐两件证据，渡工会抬起水栅。" if step == "done_boat" else "潮关陶伯会转交乡亲备好的补给。"
		"courier":
			if g.chronicle.has("courier_contact"):
				return "无名迎战绝无神时自带一次护持。" if step == "done_quiet" else "绝无神开场少 2 格势。"
			if int(g.slot.chapter) > 4 or (int(g.slot.chapter) == 4 and g.slot.cleared.has(1)):
				return "支援时机已过，原先的任务回报已入手。"
			return "绝宫可请药师给无名一次护持。" if step == "done_quiet" else "绝宫可利用口令削绝无神 2 格势。"
		"shift": return "夺龙脉时，聂风可抵消部分首次受击。" if step == "done_stealth" else "夺龙脉时，火麟幻影开场少 2 格势。"
		"swordstory":
			if _duel_finished():
				return "凌云山的约定已完成。"
			return "多一格合击可更早使用风云合璧。" if step == "done_sage" else "可走山腰小径，守军会先带一批村民下山。"
	return CONSEQUENCES[key]

func _duel_finished() -> bool:
	return int(g.slot.chapter) == 5 and g.slot.cleared.has(1)

func _action(key: String, step: String, node: Array) -> String:
	if key == "swordstory" and step == "wait_sage" and _duel_finished():
		return "与无名交代旧剑去向"
	return node[3]

func _behind_crossing(room: String) -> bool:
	return room in ["village","inn"] and g.slot.campaign.crossing.is_empty()

func _reachable(room: String) -> bool:
	return int(g.slot.chapter) == int(ROOMS[room][0]) and not _missed(room) and not _behind_crossing(room)

func _missed(room: String) -> bool:
	var chapter: int = ROOMS[room][0]
	return g.slot.finished or int(g.slot.chapter) > chapter or (int(g.slot.chapter) == chapter and (
		int(g.slot.chronicle.from_chapter) > chapter or (g.field_key == "dawn" and room == "peak")))

func _deadline(room: String) -> String:
	match room:
		"peak": return "从凌云山下山前"
		"dawn": return "与步惊云离开前"
	return CHAPTERS[ROOMS[room][0]] + "结束前"

func expiring(allowed_at_destination: String = "") -> Array[String]:
	var result: Array[String] = []
	for key in state():
		var task: Dictionary = TASKS[key]
		var node: Array = task.steps.get(state()[key],[])
		if node.is_empty() or key == allowed_at_destination:
			continue
		var room: String = node[0]
		if int(g.slot.chapter) == int(ROOMS[room][0]) and not _missed(room):
			result.append(task.title)
	return result

static func valid_state(key: String, step: Variant) -> bool:
	if not TASKS.has(key) or not step is String:
		return false
	if TASKS[key].steps.has(step):
		return step != "start"
	var steps: Dictionary = TASKS[key].steps
	for data in steps.values():
		var next: Variant = data[6]
		if next is Array and next.any(func(choice): return choice[1] == step):
			return step.begins_with("done_")
		if next is String and next == step:
			return step.begins_with("done_")
	return (step == "done_fight" and key in ["courier","shift"]) or (step == "done_decoy" and key == "stairs")
