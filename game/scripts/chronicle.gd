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
	"first_tyrant":["风云初合",["first_tyrant"],[["无名","雄霸堵住了正堂出口。你们轮流牵制，等合击蓄满，再一起打他的护气。"],["雄霸","我把孔慈许给秦霜，一场喜宴便让你们反目。今日你们倒敢并肩回来。"]]],
	"courier_guard":["截住雨夜暗探",["shade","blade"],[["信使","对面已经认出我了。我在门里等你们。"]]],
	"shift_guard":["拦下交班的守卫",["invader","blade"],[["狱卒","我走便门去开闩。你们挡住这两个就好。"]]],
	"stairs_guard":["截住山道追兵",["elite","claw"],[["步惊云","先往这边走，让他们以为石阶上还有人。"]]],
	"cavern_guard":["夺回龙脉",["beast","shade"],[["步惊云","绝心的人守住洞门了。聂风，别看刀上的血，看着我。咱们打出一条路，先拿龙脉。"]]],
	"prepare_guard":["守住药庐",["elite"],[["猪皇","水备齐，针也烧过了。替我们守住洞外，等第二梦叫你再进来。"]]]
}
const FLAGS := ["spar","kindness","orders","ferry_evidence","dream_intro","lesson","first_tyrant",
	"forge_rescue","forge_pursue","invaded","pool_intro","pool_gate","pool_escape","tea","fire_signal","evacuated",
	"relic","lost_relic","shatter_relic","prepare","blood_rite","dawn_lamp","courier_contact",
	"reunion_roll","reunion_aid","dawn_witness","dawn_courier"]
const DAWN_WITNESS := Vector2(111,240)
const DAWN_COURIER := Vector2(177,267)
const DAWN_REUNION := Vector2(225,195)

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
			["步惊云","我沿牢里那张图的水道追到凌云窟。风师弟，绝心把你丢在洞门口，他进去了。"],
			["聂风","我还认得你。刚到洞口，刀声就弱了。扶我一把，咱们得赶在他前头握住龙脉。"]]
	return []

func music_for_field() -> String:
	return g.field_key if g.field_key in ["inn","swordhall","dawn"] else g.stage.key

func ending() -> Array:
	if not has("dawn_lamp"):
		return []
	var home := "朝阳落到渡口，那盏灯还在桥栏上。"
	match side.state().get("lamps",""):
		"wait_boat", "done_boat": home = "渡工修好了从浅滩拖回的旧船。第一趟船过桥时，灯还亮着。"
		"wait_goods", "done_goods": home = "乡亲用救回来的冬粮煮了热粥。邻村的船载人过桥时，灯还亮着。"
	var ending_lines := [["尾声",home]]
	match reunion_plan():
		"roll":
			ending_lines.append(["尾声","渡口挂出第一张归人名册。潮关来的船工认出了同乡的名字，照着名册送来捎信。"])
		"aid":
			ending_lines.append(["尾声","粮棚留着两张空床和一锅粥。潮关来的渔户在此借宿，回去时也带上了给邻人的一袋米。"])
	ending_lines.append(["尾声","两个旅人沿着山路走远。路过的船看见桥上的光，就知道已经到家了。"])
	return ending_lines

func reunion_plan() -> String:
	if has("reunion_roll"):
		return "roll"
	return "aid" if has("reunion_aid") else ""

func ending_legacy() -> String:
	match reunion_plan():
		"roll": return "凤溪·渡口公示"
		"aid": return "凤溪·邻里接济"
	return ""

func dawn_witness_available() -> bool:
	return not g.slot.get("finished",false) and side.state().get("seals","") in ["done_guide","done_proof"]

func dawn_courier_available() -> bool:
	return not g.slot.get("finished",false) and side.state().get("courier","") in ["done_quiet","done_fight"]

func dawn_reunion_available() -> bool:
	return not g.slot.get("finished",false) and (dawn_witness_available() or dawn_courier_available() \
		or dawn_aid_available() or side.state().get("lamps","") in ["wait_boat","done_boat"])

func dawn_aid_available() -> bool:
	var quests: Dictionary = side.state()
	return quests.get("lamps","") in ["wait_goods","done_goods"] or quests.get("stairs","") in ["done_escort","done_decoy"]

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
			result.append(_point("apothecary",112,185,"返回生死门药庐" if has("pool_intro") else "进生死门药庐"))
			if has("pool_intro") and g.slot.cleared.has(1) and not has("pool_escape"):
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
			if side.courier_contact_available():
				var contact := _point("courier_contact",int(SideStories.COURIER_CONTACT_POS.x),
					int(SideStories.COURIER_CONTACT_POS.y),SideStories.COURIER_CONTACT_NAME,"servant")
				contact.optional = true
				result.append(contact)
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
			if dawn_witness_available():
				var witnessed: bool = side.state().get("seals","") == "done_guide"
				result.append(_dawn_point("dawn_witness",DAWN_WITNESS,"探望引路的证人" if witnessed else "查看证人的公示","maid"))
			if dawn_courier_available():
				var quiet: bool = side.state().get("courier","") == "done_quiet"
				result.append(_dawn_point("dawn_courier",DAWN_COURIER,"回访凤溪药棚" if quiet else "会见获释的船工",
					"servant" if quiet else "boatman_front"))
			if has("dawn_lamp"):
				result.append(_point("dawn_exit",423,201,"与步惊云离开"))
				if dawn_reunion_available():
					result.append(_dawn_point("dawn_reunion",DAWN_REUNION,"商议安置归人" if reunion_plan().is_empty()
						else "查看凤溪安置安排","guard" if reunion_plan() == "roll" else "boatman_front"))
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
		"swordhall": return "从无名身侧的路标返回天下会。" if has("lesson") else "先到北边，请无名指点合璧。"
		"returnhall":
			if not has("first_tyrant"): return "迎战雄霸，留意他的护气。"
			if not has("forge_rescue") and not has("forge_pursue"): return "回正堂与无名商议，决定先救人还是追查。"
			if has("invaded"): return "从东侧出口前往生死门。"
			return "去东侧哨门，查清换防的人。"
		"pool":
			if not has("pool_intro"): return "先到生死门药庐，找第二梦和独孤梦。"
			if g.slot.cleared.has(1) and not has("pool_escape"):
				return "去东北石阶接应第二梦。" if has("pool_gate") else "刀皇闯入，先去东岸切开木栅。"
		"apothecary": return "从南门返回魔池，去池边试刀。" if has("pool_intro") else "先问第二梦和独孤梦为何守在药庐。"
		"palace":
			if g.slot.campaign.rescued and not has("tea"): return "到茶房侧廊，听颜盈与绝心交谈。"
			if g.slot.cleared.has(1) and not has("evacuated"): return "绝宫起火，从茶房侧门撤离。"
		"tearoom":
			if g.slot.cleared.has(1):
				if not has("fire_signal"): return "去东侧查明火从何处烧起。"
				if has("evacuated"): return "沿南门回绝宫，从西侧离开。"
				return "从右侧便门护送至尊。" if String(side.state().get("shift","")).begins_with("done_") else "沿左侧廊道护送至尊，绕开大火。"
			return "回绝宫破金身。" if has("tea") else "到正中茶桌，听颜盈和绝心交谈。"
		"cavern":
			if not has("relic"): return "去洞门前击退守兽，夺取龙脉。"
			if not has("lost_relic"): return "去东侧接应秦霜。"
			if not has("shatter_relic"): return "赶回北侧洞门，追上雄霸。"
			return "去南边的小筑协助第二梦。" if has("prepare") else "去西边替第二梦守住药炉。"
		"lodge":
			if not has("blood_rite"): return "在药炉旁协助第二梦，随后与她告别。"
		"dawn":
			if not has("dawn_lamp"): return "去桥栏点灯，兑现和第二梦的约定。"
			return "可先在西岸安置归人，或沿石桥离开。" if dawn_reunion_available() and reunion_plan().is_empty() else "沿石桥向东，与步惊云离开。"
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
			var clue := "石桥那面旗和封门令都盖着缺角印。" if g.slot.campaign.crossing == "bridge" else "渡工认出了追兵旗上的缺角印。"
			var answer := "一边令我们拔刀，一边封门灭口。先回渡口截住持哨的人，我要让云师兄亲眼看这道令。"
			if side.state().get("seals","") == "done_proof":
				clue += "那份口供还记下了换哨的时刻，封门比婚宴还早。"
				answer = "照口供上的时辰抢先一步，持哨的人就来不及站稳。走，先把哨声截住。"
			beat("ferry_evidence",[
				["秦霜","两张调令合上了。" + clue],
				["聂风",answer]])
		"dream_intro":
			beat("dream_intro",[
				["第二梦","手松开。伤成这样，拿刀只会让血流得更快。先听我的声音，我给你包扎。"],
				["聂风","我记得你的声音。日后若能回来，我在这座桥给你点盏灯。"],
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
				["无名","你拿到了剑，雄霸的护气仍要两人合力破开。试一遍，排云掌压住对手，风神腿接上。"],
				["聂风","普攻和武学都能蓄合击。等蓄到四格，我会给你信号。"],
				["步惊云","喜堂那回我没等你。这回等信号。走，回天下会。"]])
		"returnhall": enter("returnhall")
		"hall_back": enter("swordhall")
		"leave_hall": g._next_chapter()
		"first_tyrant": begin_special("first_tyrant")
		"retreat_choice": _retreat_choice()
		"invaded":
			var first_clue := "伤者说绝心早就在等。雄霸才走，东瀛人便封了哨门。" if has("forge_rescue") else "血迹在哨门断了，靴印一直通到换旗处。东瀛人等雄霸败退才现身。"
			beat("invaded",[
				["秦霜",first_clue],
				["绝心","奉至尊诏令，天下会即刻交给无神绝宫。把印绶和名册留下，其余人让开。"],
				["无名","至尊的印不会盖在这道令上。云随我找真身，风去生死门问邪皇如何破绝无神的金身。"]])
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
				["第一邪皇","刀皇闯进来了！独孤梦挡在池门前，她的血流进池里了。"],
				["第二梦","聂风，往我这儿来。栅栏挡住了退路，对着木头出刀，别对着人！"],
				["聂风","开了。快沿石阶出去！"]])
			g.sfx("mechanism")
		"pool_escape":
			beat("pool_escape",[
				["聂风","我听得见你，却分不清眼前是谁。别跟着刀光走，我从另一条路下山。"],
				["第二梦","我沿山路去找他。给云大哥捎个信，请他立刻去绝宫和无名会合。"]])
		"tearoom": enter("tearoom")
		"palace_back": enter("palace","jail_return")
		"tea":
			beat("tea",[
				["颜盈","我按你说的把药倒进茶里了。绝心，你答应我，让风儿活着离开。"],
				["绝心","父亲只肯把位置留给绝天。等步惊云破了他的金身，我给他奉最后一盏茶。"],
				["步惊云","绝心等我们动手，好接手那道假诏。先回绝宫破金身，再赶到侧廊接至尊。"]])
		"courier_contact":
			if g.field_key != "tearoom" or not side.courier_contact_available():
				return false
			match side.state().get("courier",""):
				"done_quiet":
					beat("courier_contact",[["信使","那封信请来了药师。我带了一包护脉散，先给无名先生敷上，绝无神的头一拳就有人能接住。"]])
				"done_fight":
					beat("courier_contact",[["信使","凤溪问出的口令是「收拳回阵」。开打时你喊一声，绝无神会以为亲卫要换位，足够你抢个先手。"]])
		"fire_signal":
			var path := "狱卒给你留了便门，大家顺着近路撤！" if String(side.state().get("shift","")).begins_with("done_") else "沿左廊走，低头避烟！"
			beat("fire_signal",[
				["绝无神","这杯茶……绝心，你也要我的命？"],
				["绝心","你要我假扮至尊给你调兵。雄霸答应，等你一死，这道诏令就由我来发。"],
				["秦霜","火已经到了柱子。" + path + "我留在这里掩护。"]])
		"evacuated":
			var next := "他偷走的旧图就画着这条水道，尽头是凌云窟的龙脉。无名送我回城，你沿水道追。"
			match side.state().get("shift",""):
				"done_stealth":
					next = "旧图的水道通往凌云窟。那狱卒从便门出来时留了面护心镜，追上聂风时先给他戴上。"
				"done_fight":
					next = "旧图的水道通往凌云窟。狱卒说关在那里的守兽听铜哨。刚缴的哨子你带上，能引开它。"
			beat("evacuated",[
				["步惊云","绝心带着聂风从后门走了。秦师兄刚才跟上去，在水道入口给我留了个记号。"],
				["至尊",next]])
		"relic": begin_special("cavern_guard")
		"lost_relic":
			beat("lost_relic",[
				["第二梦","龙脉一松手，聂风就又听见刀声了。秦师兄，替我们守一会儿洞口。"],
				["秦霜","绝心还在暗处。风师弟，把龙脉给我，我引他现身。梦，你带风走。"],
				["绝心","秦霜，把手松开。拿到龙脉，我便用不着雄霸替我作主。"],
				["步惊云","秦师兄……他夺了龙脉，往北洞口去了。你们先按住伤口，我去追。"]])
		"shatter_relic":
			beat("shatter_relic",[
				["绝心","龙脉在手，我凭什么再听你的？"],
				["雄霸","我教给你的心法少了最后一段。你把气运到第三重试试，还能不能握得住它。"],
				["步惊云","雄霸砸碎了龙脉。聂风，听我说，别再去抓那把刀。"],
				["第二梦","猪皇，把药炉挪到避风处。龙脉只能压住魔血，我要把它换出来。"]])
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
			var river := "船家说它夜里也会亮。我们走吧。"
			match side.state().get("stairs",""):
				"done_escort": river = "从小径下山的人都坐上船了。船家说夜里也会留着这盏灯。"
				"done_decoy": river = "从岔口脱身的乡亲都到了。那位老伯给灯添了油，说要照到夜里。"
			var farewell := [["聂风","雨停了。桥栏还在，我把灯搁在这儿。"],["步惊云",river]]
			if has("courier_contact"):
				var news := "你们让我送去的那封信救了人。药师留下来，今后渡工伤了能找她。" \
					if side.state().get("courier","") == "done_quiet" else "我把当夜截到的口令和换岗时刻交给了至尊。州府正按它们找被私押的人。"
				farewell.insert(1,["信使",news])
			beat("dawn_lamp",farewell)
		"dawn_exit":
			if not warn_departure(_finish_dawn):
				_finish_dawn()
		"dawn_witness":
			if g.field_key != "dawn" or not dawn_witness_available():
				return false
			_dawn_witness()
		"dawn_courier":
			if g.field_key != "dawn" or not dawn_courier_available():
				return false
			_dawn_courier()
		"dawn_reunion":
			if g.field_key != "dawn" or not has("dawn_lamp") or not dawn_reunion_available():
				return false
			_dawn_reunion()
		_: return false
	return true

func _exit() -> bool:
	if not g.campaign.can_exit():
		return false
	match g.field_key:
		"village":
			g._talk([["步惊云","无名来信，断浪带火麟剑闯进了拜剑山庄。先取绝世好剑，再回天下会接人。"],
				["聂风","我陪你去。秦师兄，劳你留在渡口收好这道令。船家，桥上的灯别收。"]],g._next_chapter)
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

func _dawn_point(id: String, pos: Vector2, label: String, sprite: String) -> Dictionary:
	return {"id":id,"name":label,"pos":pos,"index":-1,"sprite":sprite,"optional":true}

func _dawn_witness() -> void:
	var dialogue := [["证人","你们带我从竹径下了山。现在我替同乡守着渡口，失散的人来了就有地方落脚。"]]
	if side.state().get("seals","") == "done_proof":
		dialogue = [["证人","那份口供已经贴在渡口。两家人认出了封门令上的印，来认领当晚被带走的人。"]]
	beat("dawn_witness",dialogue)

func _dawn_courier() -> void:
	var dialogue := [["信使","你们送来的药师留下了。几户渡工正轮流给药棚送水，夜里也有人照看伤者。"]]
	if side.state().get("courier","") == "done_fight":
		dialogue = [["船工","信使记下你们问出的口令。州府照他的线索搜了船屋，我今早头一回用自己的名字领粮。"]]
	beat("dawn_courier",dialogue)

func _dawn_reunion() -> void:
	var plan := reunion_plan()
	if not plan.is_empty():
		var notice := "名册已经挂好。邻村来问，就让他们照着找人。" if plan == "roll" else "粮棚今晚留灯。先到的人歇脚，明早再去接下一批。"
		g._talk([["渡工",notice]],g._return_to_field)
		return
	var choices := [["立渡口归人册","reunion_roll"]]
	var note := "公开登记来往人名，让失散家人能在渡口寻访。"
	if dawn_aid_available():
		choices.append(["在粮棚留铺留粮","reunion_aid"])
		note = "归人册让各村公开寻亲。粮棚留铺留粮，让无处安身的人先过夜。"
	choices.append(["稍后再议",""])
	choose("凤溪如何安置归人",choices,_settle_dawn,note)

func _settle_dawn(flag: String) -> void:
	if flag.is_empty():
		g._return_to_field()
		return
	var outcome := [["渡工","我把名册挂在船埠。家人找不到人的，写下名字和来处，我让过往船工带给沿岸各村。"]]
	if flag == "reunion_aid":
		outcome = [["渡工","乡亲把空粮棚扫出来了。我今晚守灯，带着孩子的先进屋，明早给他们煮粥。"]]
	beat(flag,outcome)

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
	var dialogue: Array = SPECIALS[id][2]
	if id == "cavern_guard":
		match side.state().get("shift",""):
			"done_stealth":
				dialogue = [["步惊云","绝心的人守住了洞门。先戴上狱卒留下的护心镜。等守兽扑过来，我来截它的路。"]]
			"done_fight":
				dialogue = [["步惊云","绝心的人守住了洞门。风师弟，我吹铜哨引守兽回头，你趁它分神攻过去。"]]
	g._talk(dialogue,g._start_battle)

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
