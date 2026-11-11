extends RefCounted

const SideStories = preload("res://scripts/side_stories.gd")
const Martial = preload("res://scripts/martial.gd")
const ROOMS := {"inn":1,"swordhall":2,"returnhall":2,"apothecary":3,"tearoom":4,"cavern":5,"lodge":5,"dawn":5}
const SUBTITLE := {
	"inn":"凤溪 · 西岸客栈","swordhall":"拜剑山庄 · 剑庐","returnhall":"天下会 · 重返飞云堂",
	"apothecary":"生死门 · 药庐","tearoom":"无神绝宫 · 茶房侧廊","cavern":"凌云窟 · 龙脉洞口","dawn":"凤溪 · 雨过天明"
}
const SPECIALS := {
	"spar":["同门切磋",["spar_frost"],[["秦霜","两人轮流出手。普攻回气，来不及打断重击时先固守。"]]],
	"first_tyrant":["风云初合",["first_tyrant"],[["无名","你们一进一退，别把后背留给他。看准他回气时，再同出一招。"],["雄霸","倒要看看你们离了为师，能走几步。"]]],
	"courier_guard":["截住雨夜暗探",["shade","blade"],[["信使","对面已经认出我了。我在门里等你们。"]]],
	"shift_guard":["拦下交班的守卫",["invader","blade"],[["狱卒","我走便门去开闩。你们挡住这两个就好。"]]],
	"stairs_guard":["截住山道追兵",["elite","claw"],[["步惊云","先往这边走，让他们以为石阶上还有人。"]]],
	"cavern_guard":["夺回龙脉",["beast","shade"],[["步惊云","绝心的人守住洞门了。聂风，过去把龙脉带出来。"]]],
	"prepare_guard":["守住药庐",["elite"],[["猪皇","水备齐，针也烧过了。替我们守住洞外，等第二梦叫你再进来。"]]]
}
const FLAGS := ["spar","kindness","orders","ferry_evidence","dream_intro","lesson","first_tyrant",
	"forge_rescue","forge_pursue","invaded","pool_intro","pool_gate","pool_escape","tea","fire_signal","evacuated",
	"relic","lost_relic","shatter_relic","prepare","blood_rite","dawn_lamp"]

var g
var side: RefCounted
var options: Array = []
var question := ""
var choice_note := ""
var after_choice: Callable
var special := ""
var staged := false
var review := false
var martial_hero := 0
var martial_slot := 0

func martial_id() -> String:
	return g.stage.party[martial_hero]

func martial_items() -> Array:
	var id := martial_id()
	var result := []
	for at in 4:
		var move: Array = Martial.options(id,g.slot.campaign.sword)[at]
		result.append([move[0],Martial.unlocked(g.slot,id,at)])
	return result

func equip(at: int) -> void:
	var id := martial_id()
	var prepared: Array = Martial.prepared(g.slot,id)
	var other := 1 - martial_slot
	if prepared[other] == at:
		prepared[other] = prepared[martial_slot]
	prepared[martial_slot] = at
	state().loadout[id] = prepared
	g._commit()
	g.sfx("select")

func _init(game: Node2D) -> void:
	g = game
	side = SideStories.new(game)

func state() -> Dictionary:
	return g.slot.chronicle

func enabled() -> bool:
	return int(g.slot.chapter) >= int(state().from_chapter)

func has(flag: String) -> bool:
	return state().marks.get(flag,false)

func opening() -> Array:
	if enabled() and g.slot.chapter == 5:
		return [
			["步惊云","至尊给我指了路。绝心带聂风进了凌云窟，我来拦他。"],
			["聂风","魔刀……不。我记得你。洞里有一样东西能让我清醒，先过这道门。"]]
	return []

func music_for_field() -> String:
	return g.field_key if g.field_key in ["inn","swordhall","dawn"] else g.stage.key

func ending() -> Array:
	if not has("dawn_lamp"):
		return []
	return [
		["尾声","朝阳落到渡口，那盏灯还在桥栏上。"],
		["尾声","两个旅人沿着山路走远。路过的船看见桥上的光，就知道已经到家了。"]]

func entry() -> Array:
	if not enabled():
		return []
	var room: String = state().room
	if not room.is_empty():
		return [room,"spawn"]
	if g.slot.chapter == 5 and not g.slot.campaign.farewell:
		return ["cavern","spawn"]
	return []

func points() -> Array:
	if not enabled():
		return []
	var result: Array = side.points()
	match g.field_key:
		"hall":
			if not has("spar"):
				result.append(_point("spar",98,258,"与秦霜切磋","frost"))
		"banquet":
			if not g.slot.hall.wedding and not has("kindness"):
				result.append(_point("kindness",198,195,"随孔慈照看仆役","kongci"))
		"village":
			if not g.slot.campaign.crossing.is_empty():
				result.append(_point("inn",97,167,"进西岸客栈"))
		"inn":
			result.append(_point("inn_exit",320,289,"回到西岸"))
			if not has("ferry_evidence"):
				result.append(_point("ferry_evidence",315,185,"核对秦霜的调令","frost"))
			elif g.slot.cleared.has(1) and not has("dream_intro"):
				result.append(_point("dream_intro",332,216,"听第二梦的灯下约定","dream"))
		"swordhall":
			result.append(_point("forge_back",321,293,"返回剑池"))
			if not has("lesson"):
				result.append(_point("lesson",318,155,"请无名指点合璧","sage"))
			else:
				result.append(_point("returnhall",293,191,"返回天下会"))
		"returnhall":
			result.append(_point("hall_back",151,268,"返回剑庐"))
			if not has("first_tyrant"):
				result.append(_point("first_tyrant",304,180,"迎战雄霸","boss"))
			elif not has("forge_rescue") and not has("forge_pursue"):
				result.append(_point("retreat_choice",304,180,"决定如何接应","sage"))
			elif not has("invaded"):
				result.append(_point("invaded",458,213,"查验新来的哨卫","juexin"))
			else:
				result.append(_point("leave_hall",482,259,"前往生死门"))
		"pool":
			if not has("pool_intro"):
				result.append(_point("apothecary",112,185,"进生死门药庐"))
			elif g.slot.cleared.has(1) and not has("pool_escape"):
				if not has("pool_gate"):
					result.append(_point("pool_gate",422,184,"以刀气切断木栅"))
				else:
					result.append(_point("pool_escape",484,140,"护送第二梦离开魔池","dream"))
		"apothecary":
			result.append(_point("pool_back",320,289,"回到魔池"))
			if not has("pool_intro"):
				result.append(_point("pool_intro",320,163,"听两位姑娘说来意","dream"))
		"palace":
			if g.slot.cleared.has(0):
				result.append(_point("tearoom",448,192,"进入茶房侧廊"))
		"tearoom":
			result.append(_point("palace_back",320,289,"返回绝宫"))
			if g.slot.campaign.rescued and not has("tea"):
				result.append(_point("tea",320,174,"听颜盈和绝心的交谈","juexin"))
			if g.slot.cleared.has(1) and not has("evacuated"):
				if not has("fire_signal"):
					result.append(_point("fire_signal",414,178,"查看绝无神和绝心","godless"))
				elif String(side.state().get("shift","")).begins_with("done_"):
					result.append(_point("evacuated",538,222,"从狱卒打开的便门撤离","frost"))
				else:
					result.append(_point("evacuated",117,271,"绕开火势，带至尊走左廊","frost"))
		"cavern":
			if not has("relic"):
				result.append(_point("relic",319,161,"夺取龙脉","beast"))
			elif not has("lost_relic"):
				result.append(_point("lost_relic",455,221,"护住秦霜","frost"))
			elif not has("shatter_relic"):
				result.append(_point("shatter_relic",320,167,"追到洞口阻止雄霸","boss"))
			elif not has("prepare"):
				result.append(_point("prepare",176,220,"守住换血药炉","zhu"))
			else:
				result.append(_point("lodge",320,283,"去雨夜小筑"))
		"lodge":
			if not has("blood_rite"):
				result.append(_point("blood_rite",311,226,"按第二梦的指示准备换血","zhu"))
		"peak":
			if side.state().get("swordstory","") == "done_guard":
				result.append(_point("mountain_path",202,263,"走守军留下的小径"))
		"dawn":
			if has("dawn_lamp"):
				result.append(_point("dawn_exit",423,201,"与步惊云离开"))
			else:
				result.append(_point("dawn_lamp",298,201,"点亮桥栏的灯"))
	return result

func objective() -> String:
	if not enabled():
		return ""
	match g.field_key:
		"hall":
			if not has("spar"): return "在庭院与秦霜切磋。"
		"banquet":
			if not g.slot.hall.wedding and not has("kindness"): return "先去见孔慈，再走到喜堂中央。"
		"village":
			if not g.slot.campaign.crossing.is_empty():
				if not has("ferry_evidence"): return "进西岸客栈，找秦霜核对调令。"
				if g.slot.cleared.has(1) and not has("dream_intro"): return "回客栈，请第二梦看看聂风的伤。"
		"inn":
			if not has("ferry_evidence"): return "向秦霜出示调令，辨认天下会的印。"
			if not g.slot.cleared.has(1): return "回西岸阻止鸣哨，保住渡口。"
			if not has("dream_intro"): return "去灯下，请第二梦看伤。"
			return "回西岸南面，与步惊云会合。"
		"forge":
			if g.slot.campaign.sword: return "从东侧出口前往剑庐。"
		"swordhall": return "请无名指点，再返回天下会。"
		"returnhall": return "迎战雄霸，查清接管哨卫的人。"
		"pool":
			if not has("pool_intro"): return "先到生死门药庐，找第二梦和独孤梦。"
			if g.slot.cleared.has(1) and not has("pool_escape"): return "刀皇闯入，去东岸接应第二梦。"
		"apothecary": return "听清两人的来意，再去魔池。"
		"palace":
			if g.slot.campaign.rescued and not has("tea"): return "到茶房侧廊，听颜盈与绝心交谈。"
			if g.slot.cleared.has(1) and not has("evacuated"): return "绝宫起火，从茶房侧门撤离。"
		"tearoom": return "走侧廊，留意颜盈、绝心和秦霜。"
		"cavern": return "夺龙脉，追绝心，再为第二梦守住药炉。"
		"lodge":
			if not has("blood_rite"): return "在药炉旁协助第二梦，随后与她告别。"
		"dawn": return "沿石桥向东，与步惊云离开。" if has("dawn_lamp") else "去桥栏点灯，兑现和第二梦的约定。"
	return ""

func encounter_open(index: int) -> bool:
	if not enabled():
		return true
	match g.field_key:
		"hall": return has("spar")
		"village": return index == 0 or has("ferry_evidence")
		"pool": return has("pool_intro")
		"palace": return index != 1 or has("tea")
	return true

func handle(id: String) -> bool:
	if side.handle(id):
		return true
	if not enabled():
		return false
	match id:
		"spar":
			begin_special("spar")
		"kindness":
			beat("kindness",[
				["孔慈","她今夜守西门。那些守卫凶，把这个灯交给她，等她看见亮处就知道往哪儿走。"],
				["步惊云","我会把她带出去。你也跟我们一起走。"],
				["孔慈","等秦霜回来。我答应他，有些话要当面说清楚。"]])
		"ceremony":
			if not has("kindness"):
				g._notice("孔慈还在正堂西侧，先去见她。")
				return true
			return false
		"inn": enter("inn")
		"inn_exit": enter("village","west_spawn")
		"ferry_evidence":
			var clue := "石桥上取到的旗，和封门令是同一枚印。" if g.slot.campaign.crossing == "bridge" else "渡工见过那面旗，印的位置与封门令相合。"
			if side.state().get("seals","") == "done_proof":
				clue += "你留下的口供也写明了换印的时辰。"
			beat("ferry_evidence",[
				["秦霜","我带来的半张调令与这张合上了。" + clue],
				["聂风","有人想让我们互相猜忌。先守住客栈外的渡口，等云师兄过来。"]])
		"dream_intro":
			beat("dream_intro",[
				["第二梦","灯靠左一点。我替你把伤口包上，先听声音，别勉强睁眼。"],
				["聂风","日后若能回来，我在这座桥给你点盏灯。"],
				["第二梦","好。雨停的时候，我也想看看这条河。"]])
		"reunion":
			if not has("dream_intro"):
				g._notice("先回西岸客栈，找第二梦处理伤势。")
				return true
			return false
		"bedside":
			if not has("blood_rite"):
				g._notice("猪皇正在药炉旁等你。")
				return true
			return false
		"exit":
			return _exit()
		"forge_back": enter("forge","sword")
		"lesson":
			beat("lesson",[
				["无名","此剑握在手里，回头却还得靠身后的人。排云掌压住对手，风神腿才有空隙。"],
				["聂风","我先替你断他的招。记得等我。"],
				["步惊云","四息蓄满，一起出手。"]])
		"returnhall": enter("returnhall")
		"hall_back": enter("swordhall")
		"leave_hall": g._next_chapter()
		"first_tyrant": begin_special("first_tyrant")
		"retreat_choice": _retreat_choice()
		"invaded":
			beat("invaded",[
				["秦霜","雄霸不在正堂，天下会的旗已经被换了。接管岗哨的人叫绝心。"],
				["绝心","从今往后，牌匾归无神绝宫。谁敢替旧主说话，先去牢里坐一坐。"],
				["无名","至尊未必还在位上。云随我查真伪，风去生死门问邪皇如何破金身。"]])
		"apothecary": enter("apothecary")
		"pool_back": enter("pool")
		"pool_intro":
			beat("pool_intro",[
				["独孤梦","我替师父照料池门。聂风，往里走时记住脚下这道红线。"],
				["第二梦","我是第二刀皇的女儿。若我父亲来找邪皇比刀，我在岸上拦着。你听见我喊就退回来。"],
				["聂风","绝无神的金身挡在城里人前面。我来试一刀，也要能自己收刀。"]])
		"pool_trial":
			if not has("pool_intro"):
				g._notice("先去西边药庐见两位姑娘。")
				return true
			return false
		"pool_gate":
			beat("pool_gate",[
				["第一邪皇","刀皇闯进来了！独孤梦挡在池门前，已经受了重伤。"],
				["第二梦","聂风，往我这儿来。用刀气切断栅栏，别再往池里走！"],
				["聂风","开了。快沿石阶出去！"]])
			g.sfx("mechanism")
		"pool_escape":
			beat("pool_escape",[
				["聂风","听得见你，我却已经收不住刀。别跟上来。"],
				["第二梦","我去追他。云大哥，你去找无名，牢里还有人在等。"]])
		"tearoom": enter("tearoom")
		"palace_back": enter("palace","jail_return")
		"tea":
			beat("tea",[
				["颜盈","我按你说的把药倒进茶里了。绝心，你答应我，让风儿活着离开。"],
				["绝心","父亲眼里只有绝天。今夜他若不倒，连你儿子也走不了。"],
				["步惊云","至尊说夺位的印也是绝心盖的。等无名引开金身，我们从这里接人。"]])
		"fire_signal":
			var path := "狱卒给你留了便门，大家顺着近路撤！" if String(side.state().get("shift","")).begins_with("done_") else "沿左廊走，低头避烟！"
			beat("fire_signal",[
				["绝无神","这杯茶……绝心，你也要我的命？"],
				["绝心","你想借我的手夺位，雄霸也想借我的手送你上路。"],
				["秦霜","火已经到了柱子。" + path + "我留在这里掩护。"]])
		"evacuated":
			beat("evacuated",[
				["步惊云","那是聂风！绝心把他带走了！"],
				["至尊","先带大家出去。失窃的旧图指向凌云窟，雄霸要的是龙脉。"]])
		"relic": begin_special("cavern_guard")
		"lost_relic":
			beat("lost_relic",[
				["第二梦","龙脉在手，聂风的魔念才稍微平下去。秦师兄，看住洞口。"],
				["秦霜","绝心盯着龙脉。我跟他谈，你先带聂风走。"],
				["绝心","交出龙脉。雄霸许我的东西，我可以亲自去拿。"],
				["步惊云","秦师兄！……他带龙脉走了，伤口是他留下的。"]])
		"shatter_relic":
			beat("shatter_relic",[
				["绝心","龙脉在手，我凭什么再听你的？"],
				["雄霸","你身上的三元归一，运到第三重就会逆行。你没机会了。"],
				["步惊云","他砸碎了龙脉。聂风，撑住！"],
				["第二梦","猪皇，把药炉挪到避风处。我知道还有一个法子。"]])
		"prepare": begin_special("prepare_guard")
		"lodge": enter("lodge")
		"blood_rite":
			g._play_music("blood")
			beat("blood_rite",[
				["猪皇","针水已经温了。云，把灯移近一些。"],
				["第二梦","帮我扶住他。我自己来。聂风，听见雨声就睁眼。"],
				["步惊云","灯在你手边。你说要我做什么，我就做什么。"],
				["猪皇","风的脉回来了……丫头？你听得见我吗？"]])
		"mountain_path":
			g._load_field("peak","altar")
			g._notice("已走过守军留下的小径。")
		"dawn_lamp":
			beat("dawn_lamp",[
				["聂风","雨停了。桥栏还在，我把灯搁在这儿。"],
				["步惊云","船家说它夜里也会亮。我们走吧。"]])
		"dawn_exit":
			if not warn_departure(_finish_dawn):
				_finish_dawn()
		_: return false
	return true

func _exit() -> bool:
	if not g.campaign.can_exit():
		return false
	match g.field_key:
		"village":
			g._talk([["步惊云","无名来信说断浪带着火麟剑到了拜剑山庄。我去取绝世好剑。"],
				["聂风","我与你一道走。船家，桥上的灯有劳你照看。"]],g._next_chapter)
		"forge":
			enter("swordhall")
		"pool":
			if has("pool_escape"):
				g._next_chapter()
			else:
				g._notice("先去东岸接应第二梦。")
		"palace":
			if has("evacuated"):
				g._next_chapter()
			else:
				g._notice("先去茶房侧廊救人。")
		_: return false
	return true

func finish_chapter() -> bool:
	if not enabled():
		return false
	if g.field_key == "peak":
		enter("dawn")
		return true
	return false

func on_first_departure() -> Array:
	if not enabled():
		return []
	state().marks.orders = true
	return [["秦霜","这是我从封门执事手中拿到的半张调令。我去取另一半。风师弟，凤溪见。"],
		["步惊云","我从山路绕到西岸。看见三短一长的灯号再露面。"]]

func _point(id: String, x: int, y: int, label: String, sprite: String = "") -> Dictionary:
	return {"id":id,"name":label,"pos":Vector2(x,y),"index":-1,"sprite":sprite,"optional":false}

func speak(lines: Array, finish: Callable) -> void:
	staged = true
	g._talk(lines,func():
		staged = false
		finish.call())

func beat(flag: String, lines: Array) -> void:
	speak(lines,func():
		state().marks[flag] = true
		g._commit()
		g._return_to_field()
		if flag == "invaded":
			g._next_chapter())

func choose(title: String, list: Array, finish: Callable, note: String = "") -> void:
	question = title
	choice_note = note
	options = list
	after_choice = finish
	g._set_mode("choice")

func select_choice(index: int) -> void:
	var result: String = options[index][1]
	var finish := after_choice
	after_choice = Callable()
	options = []
	finish.call(result)

func cancel_choice() -> void:
	after_choice = Callable()
	options = []
	g._return_to_field()

func warn_departure(finish: Callable, allowed_at_destination: String = "") -> bool:
	var expiring: Array[String] = side.expiring(allowed_at_destination)
	if expiring.is_empty():
		return false
	choose("仍有支线进行中",[["留下继续","stay"],["离开此章","leave"]],_answer_departure.bind(finish),
		"本章结束后将关闭 " + "、".join(expiring))
	return true

func _answer_departure(answer: String, finish: Callable) -> void:
	if answer == "leave":
		finish.call()
	else:
		g._return_to_field()

func _finish_dawn() -> void:
	g.slot.finished = true
	state().room = ""
	g._commit()
	g._show_ending()

func field_party() -> Array:
	if enabled() and g.field_key == "lodge" and not has("blood_rite"):
		return ["cloud","wind"]
	return g.stage.party

func enter(room: String, arrival: String = "spawn") -> void:
	state().room = room if ROOMS.has(room) else ""
	g._load_field(room,arrival)
	g._commit()
	g._return_to_field()

func begin_special(id: String) -> void:
	special = id
	g.active_battle = -1
	g._talk(SPECIALS[id][2],g._start_battle)

func on_special_won() -> void:
	g.slot.tonics = g.encounter.tonics
	match special:
		"spar": state().marks.spar = true
		"first_tyrant": state().marks.first_tyrant = true
		"courier_guard": side.state().courier = "done_fight"
		"shift_guard": side.state().shift = "done_fight"
		"stairs_guard": side.state().stairs = "done_decoy"
		"cavern_guard": state().marks.relic = true
		"prepare_guard": state().marks.prepare = true
	g._commit()

func leave_special() -> void:
	var id := special
	special = ""
	g._return_to_field()
	match id:
		"first_tyrant":
			if not has("forge_rescue") and not has("forge_pursue"):
				_retreat_choice()
		"cavern_guard":
			speak([["聂风","龙脉在这里。握住它时，脑子里那道声音轻了。"],
				["第二梦","先别松手。绝心知道它能帮你，也知道雄霸会为它回来。"]],g._return_to_field)
		"prepare_guard":
			speak([["第二梦","把针递给我。等药水凉一点，你们扶聂风进去。"],
				["猪皇","丫头，换了血，人能回来。你知道自己会怎么样？"],
				["第二梦","我知道。让风醒了以后来小筑找我。"]],g._return_to_field)

func _retreat_choice() -> void:
	choose("雄霸败退", [["先把伤者送走","forge_rescue"],["沿血迹查退路","forge_pursue"]],func(flag):
		beat(flag,[["步惊云","" + ("伤者已经交给无名。他说绝心昨夜就在哨门附近等。" if flag == "forge_rescue" else "血迹过了哨门就断了。门里换了一批东瀛的靴印。")]]))
