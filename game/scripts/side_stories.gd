extends RefCounted

const TASKS := {
	"seals": {
		"title":"旧账新印","chapters":[0],"summary":"核对押粮清单与封门口供。",
		"steps":{
			"start":["hall",142,222,"查看押粮清单","","押粮簿中有两班守卫，盖章却出自同一只手。先问送饭的仆役。","witness"],
			"witness":["banquet",190,177,"询问送饭仆役","servant","我亲眼看见执事在宴前换了印。柜底还有一张旧单。","proof"],
			"proof":["banquet",430,189,"查看柜下旧单","","旧单的印缺一角，和刚换过的那张不同。","decision"],
			"decision":["banquet",248,247,"安置证人","maid","撤离的路你们熟。要我带路，还是留下把口供写全？",[
				["先带证人走","done_guide"],["留下写完口供","done_proof"]]]}},
	"lamps": {
		"title":"一盏灯，两条船","chapters":[1,5],"summary":"循船灯救援渡客，日后回访凤溪。",
		"steps":{
			"start":["inn",182,202,"向渡工问灯","boatman_front","三短一长是渡客求救。西岸浅滩还亮着一盏，去看看。","shore"],
			"shore":["village",144,265,"辨认浅滩灯号","","浅滩有人招手。缆绳够拖人，还能救起船或那箱过冬的货。","decision"],
			"decision":["inn",198,251,"决定渡口救援","boatman_front","我已经把人抬回来了。水还在涨，我们现在只能拖回一样东西。",[
				["先把船拖回来","wait_boat"],["先救过冬的货","wait_goods"]]],
			"wait_boat":["dawn",208,254,"回访修好的船","boatman_front","船肋换好了。多亏你留住船身，眼下每天都能开两趟。","done_boat"],
			"wait_goods":["dawn",208,254,"探望渡口新人","boatman_front","乡亲有粮过冬。丢掉的船暂时由邻村渡工补上，我能歇几天。","done_goods"]}},
	"courier": {
		"title":"雨夜押书","chapters":[1],"summary":"分辨真假路标，护送信使。",
		"steps":{
			"start":["village",76,233,"查看雨中脚印","","脚尖都向北，路牌却指向南。新钉的那块路牌是假的。","watch"],
			"watch":["village",174,155,"听竹林的哨声","","两急一缓从河边传来。沿背风墙走可以避开巡哨。","decision"],
			"decision":["inn",431,210,"接应信使","servant","沿背风墙可把信送出去。正门那名探子认识我，但现在截住他能问出口令。",[
				["沿背风墙护送","done_quiet"],["截住正门探子","fight"]]]}},
	"forgework": {
		"title":"炉火借一更","chapters":[2],"summary":"先引旁槽，再开主闸。",
		"steps":{
			"start":["forge",153,169,"询问熔沟工匠","guide","主渠水压太高。先开旁槽放掉压力，再去拉第二道闸。","sluice"],
			"sluice":["forge",187,132,"打开泄压旁槽","","水面往下落了一尺，第二道闸的铜柄已经能动。","gate"],
			"gate":["forge",228,239,"放下第二道闸","","熔沟的火退开了。工匠把修好的剑架送往剑庐。","rack"],
			"rack":["swordhall",431,209,"检查修好的剑架","guide","试试用掌心卸力，接着翻腕还手。这是剑庄守门人的路数。","done_rack"]}},
	"swordstory": {
		"title":"一柄未开锋的剑","chapters":[2,4,5],"summary":"查明旧剑折断的缘由，决定由谁保管。",
		"steps":{
			"start":["swordhall",182,231,"询问于楚楚","chuchu","剑没有开锋，断口却被反复锉过。屋里那本修剑簿也许记了缘由。","ledger"],
			"ledger":["swordhall",459,258,"核对修剑簿","","守剑人故意挫断旧剑，瞒过盘查，好让工匠有机会从炉后逃走。","wait_palace"],
			"wait_palace":["tearoom",164,248,"安置无锋旧剑","chuchu","我从炉后带出了旧剑。无名能认出它的来处，城中守军也会认这枚标记。",[
				["交无名保管","wait_sage"],["交守军引路","wait_guard"]]],
			"wait_sage":["peak",178,240,"收下无名留下的信","sage","那柄旧剑送到了。雄霸护体时仍要换气。被点中的人守住，余下一人找空隙。","done_sage"],
			"wait_guard":["peak",178,240,"与引路的守军会合","guard","见剑认人。我给受困者留了条小路，你们从石阶上去。","done_guard"]}},
	"remedy": {
		"title":"药庐三问","chapters":[3],"summary":"看脉象、问病史、试护持。",
		"steps":{
			"start":["apothecary",175,192,"询问药庐病人","servant","我一使劲就喘，药也吃了好些。桌上放着药渣，先生说先看那个。","sample"],
			"sample":["apothecary",468,206,"辨认温凉药渣","","手心发热，药渣却全是温补药。先护住心脉，再缓解燥热。","decision"],
			"decision":["apothecary",178,251,"请第二梦校验药方","dream","你会先稳心脉，还是先强行压住热气？",[
				["先护住心脉","done_aid"],["先强压热气","recheck"]]]}},
	"shift": {
		"title":"换岗的灯","chapters":[4],"summary":"借换岗暗号，救出知道侧门的狱卒。",
		"steps":{
			"start":["jail",148,248,"读狱门值更簿","","末班狱卒被关在侧廊。两盏灯都向内，才是换岗信号。","lamp"],
			"lamp":["jail",427,220,"拨转换岗灯","","灯罩转向内侧。右侧守卫正在交班，可以从茶房绕过去。","decision"],
			"decision":["tearoom",482,253,"接应被关的狱卒","guard","门外还有人。我知道侧廊便门的栓在哪里，你们打算怎么带我走？",[
				["趁换岗潜行","done_stealth"],["迎面引开守卫","fight"]]]}},
	"stairs": {
		"title":"石阶上的人","chapters":[5],"summary":"从山道送走受困者。",
		"steps":{
			"start":["peak",151,192,"安抚受困村民","servant","石阶被堵住了，有几个老人走不快。右侧裂石后有藏身处。","trail"],
			"trail":["peak",398,230,"寻找撤离小径","","小径能通山脚。可先藏好村民，或由另一人把追兵引开。","decision"],
			"decision":["peak",431,258,"安排村民下山","maid","我会带他们下山。等你招呼，我们再一起过石阶。",[
				["守住小径接应","escort"],["把追兵引到岔口","fight"]]],
			"escort":["peak",468,201,"接应下山的村民","servant","最后一个人到了。把石缝里的灯带上吧，船家在山下等我们。","done_escort"]}}
}

const RESULT := {
	"done_guide":"证人给竹径留下记号。","done_proof":"押粮旧单和口供已保存。",
	"wait_boat":"船拖上岸。尾声可回访。","wait_goods":"冬粮抢回。尾声可回访。",
	"done_boat":"渡口恢复两班船。","done_goods":"邻村渡工来接班。",
	"done_quiet":"信件已经送出。","done_fight":"截击成功，获得口令。",
	"done_rack":"剑架修复，习得翻云守势。","wait_palace":"找到断剑缘由，绝宫再见于楚楚。",
	"wait_sage":"无名会把情报送到凌云山。","wait_guard":"守军会在凌云山接应。",
	"done_sage":"无名留下破护体的手札。","done_guard":"守军指明撤离小径。",
	"done_aid":"药方可用，习得护心针。","done_stealth":"狱卒打开侧廊便门。",
	"done_escort":"村民沿小径平安下山。","done_decoy":"追兵离开，村民已经下山。"
}

var g

func _init(game: Node2D) -> void:
	g = game

func state() -> Dictionary:
	return g.slot.chronicle.quests

func points() -> Array:
	var result := []
	for id in TASKS:
		var task: Dictionary = TASKS[id]
		if int(g.slot.chapter) not in task.chapters:
			continue
		var step: String = state().get(id,"start")
		var node: Array = task.steps.get(step,[])
		if not node.is_empty() and node[0] == g.field_key:
			result.append({"id":"side_"+id,"name":node[3],"pos":Vector2(node[1],node[2]),"index":-1,
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
	g.chronicle.speak([[speaker,node[5]]],func():
		if node[6] is Array:
			g.chronicle.choose(task.title,node[6],func(outcome): _finish(key,outcome))
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
	g._notice(RESULT.get(step,"已更新《江湖手记》。"))

func note(key: String) -> String:
	var task: Dictionary = TASKS[key]
	var step: String = state().get(key,"start")
	if RESULT.has(step):
		return RESULT[step]
	if int(g.slot.chapter) > int(task.chapters.back()):
		return "已离章。可在章节回看中重访。"
	return task.summary if step == "start" else "下一步 · " + String(task.steps[step][3])

func expiring(allowed_at_destination: String = "") -> Array[String]:
	var result: Array[String] = []
	for key in state():
		var task: Dictionary = TASKS[key]
		if int(g.slot.chapter) != int(task.chapters.back()):
			continue
		if key == allowed_at_destination:
			continue
		if not String(state()[key]).begins_with("done_"):
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
