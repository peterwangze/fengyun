extends RefCounted

const Items = preload("res://scripts/items.gd")

const STAGE := {"num":"外","title":"潮关余事","party":["wind","cloud"]}
const ENCOUNTERS := {
	"gate":["潮关守卒",["tidal_guard","tidal_runner"],[
		["守卒","开门？韩把总没发话，连一袋糠也不能出去。"],
		["聂风","我来请他看一张粮票。让开。"]]],
	"aid":["粮棚截押",["tidal_runner","tidal_runner"],[
		["阿芦","我替几户人领粮。领不到粮，他们还要抓我去抵账！"],
		["步惊云","靠到门边。我们先让他们放人。"]]],
	"chief":["潮关夺账",["tidal_chief","tidal_drum"],[
		["韩朔","没了天下会的印，守关的人拿什么吃饭？"],
		["聂风","守关的饭可以商量。岸上这些人的粮，你得一笔笔还。"],
		["步惊云","先听鼓声。鼓手在给他布防。"]]]
}
const FLAGS := ["brief","register","seal","sluice","gate","aid","chief","ledger"]

var g
var active := false
var battle := ""

func _init(game: Node2D) -> void:
	g = game

static func initial() -> Dictionary:
	return {"room":"tidal_ford","route":"","tonics":3,"supplies":Items.fresh(2),"brief":false,
		"register":false,"seal":false,"sluice":false,"gate":false,"aid":false,
		"chief":false,"ledger":false,"resolution":""}

static func valid(value: Variant) -> bool:
	if not value is Dictionary or value.get("room") not in ["tidal_ford","tidal_fort"]:
		return false
	if value.get("route") not in ["","gate","sluice"] or value.get("resolution") not in ["","public","witness"]:
		return false
	var tonics: Variant = value.get("tonics")
	if not (tonics is int or tonics is float) or tonics < 0 or tonics > 6 or floorf(tonics) != tonics:
		return false
	for flag in FLAGS:
		if not value.get(flag) is bool:
			return false
	if (value.register or value.seal) and not value.brief:
		return false
	if (value.sluice or value.route != "") and not (value.register and value.seal):
		return false
	if value.route == "sluice" and not value.sluice:
		return false
	if value.gate and value.route != "gate":
		return false
	if (value.room == "tidal_fort" or value.chief or value.aid) and value.route == "":
		return false
	if (value.chief or value.aid) and value.route == "gate" and not value.gate:
		return false
	if value.ledger and not value.chief:
		return false
	return value.resolution == "" or (value.ledger and value.room == "tidal_ford")

func state() -> Dictionary:
	return g.slot.afterstory

func _fengxi_aid() -> String:
	match g.slot.chronicle.quests.get("lamps",""):
		"wait_boat", "done_boat": return "boat"
		"wait_goods", "done_goods": return "grain"
	return ""

func title_item() -> String:
	var saved: Dictionary = g.slot.get("afterstory",{})
	if saved.is_empty():
		return "潮关余事"
	return "回访盐汊渡口" if saved.resolution != "" else "继续潮关余事"

func resume() -> void:
	if g.chronicle.review or not g.slot.get("finished",false):
		return
	active = true
	battle = ""
	g.stage = STAGE
	if not g.slot.has("afterstory"):
		g.slot["afterstory"] = initial()
	state().supplies = Items.clean(state().get("supplies", Items.fresh(2)))
	var opened := _open_crew_sluice()
	_enter(state().room)
	if opened:
		g._notice("凤溪渡工已抬起水栅。")

func reset() -> void:
	active = false
	battle = ""

func _enter(room: String) -> void:
	state().room = room
	var arrival := "east" if room == "tidal_fort" and state().route == "sluice" else "spawn"
	g._load_field(room,arrival)
	g._commit()
	g._return_to_field()

func subtitle() -> String:
	return "盐汊渡口 · 黄昏" if g.field_key == "tidal_ford" else "潮关粮仓 · 内院"

func objective() -> String:
	var flags := state()
	if flags.resolution != "":
		return "余事已结，可在渡口回访。"
	if g.field_key == "tidal_ford":
		if not flags.brief: return "向陶伯问清粮票的来路。"
		if not flags.register and not flags.seal: return "查明领粮名册与粮箱封条。"
		if not flags.register: return "去西侧粮棚核对领粮名册。"
		if not flags.seal: return "去东侧验看粮箱封条。"
		if flags.ledger: return "带账簿回渡口，和陶伯商量如何交代。"
		if flags.route != "": return "回粮仓继续追查账簿。"
		return "可走正门，或从已打开的水栅进仓。" if flags.sluice else "走正门问责，或开东侧水栅绕行。"
	if flags.route == "gate" and not flags.gate: return "先过正门守卒这一关。"
	if not flags.chief: return "找韩朔拿回账簿。西侧粮棚还有被扣的人。"
	if not flags.ledger: return "查收粮仓案桌上的账簿。"
	return "把账簿带回渡口。"

func blocked(point: Vector2) -> bool:
	return g.field_key == "tidal_fort" and state().route == "gate" and not state().gate and point.y < 213.0

func _spot(id: String, label: String, sprite: String = "", optional: bool = false) -> Dictionary:
	return {"id":id,"name":label,"pos":g.position_of(id),"sprite":sprite,"optional":optional}

func points() -> Array:
	var flags := state()
	var result := []
	if g.field_key == "tidal_ford":
		if flags.resolution != "":
			return [_spot("brief","与陶伯交谈","boatman_front"),_spot("memory","探望渡口人","maid")]
		result.append(_spot("brief","向陶伯问粮票" if not flags.brief else "和陶伯说话","boatman_front"))
		if not flags.brief:
			return result
		if not flags.register: result.append(_spot("register","核对领粮名册"))
		if not flags.seal: result.append(_spot("seal","查看旧印封条"))
		if flags.register and flags.seal:
			if flags.route in ["","gate"]: result.append(_spot("gate_entry","走潮关正门"))
			if flags.route == "" and not flags.sluice: result.append(_spot("sluice","松开水栅绞盘"))
			if flags.sluice and flags.route in ["","sluice"]: result.append(_spot("sluice_entry","从水栅侧道进粮仓"))
		if flags.ledger: result.append(_spot("report","交还账簿","maid"))
		return result
	result.append(_spot("return_ford","返回盐汊渡口"))
	if flags.route == "gate" and not flags.gate:
		result.append(_spot("gate","与守卒交涉","tidal_guard"))
		return result
	if not flags.aid: result.append(_spot("aid","解救被扣的阿芦","servant",true))
	if not flags.chief:
		result.append(_spot("chief","质问韩朔","tidal_chief"))
	elif not flags.ledger:
		result.append(_spot("ledger","收回粮仓账簿"))
	return result

func handle(id: String) -> void:
	var flags := state()
	match id:
		"brief":
			if flags.resolution != "":
				var line := "账贴出去后，来领粮的终于敢报自己的名字。" if flags.resolution == "public" else "衙门的人带着回执来的。今天开仓，一户一户照簿发。"
				g._talk([["陶伯",line]],g._return_to_field)
			elif flags.brief:
				g._talk([["陶伯","领粮名册在西棚。东边那只封箱是谁的印，你们看过就知道。"]],g._return_to_field)
			else:
				var introduction := "借来的船送来三十袋粮，出关的人却说账上没有。"
				match _fengxi_aid():
					"boat": introduction = "你们拖回凤溪那条船，如今能跑潮关了。渡工就在东边，证据查齐后他替你们抬水栅。"
					"grain": introduction = "凤溪乡亲靠你们救下的冬粮熬过了冬天。这次他们托我带来金创药和护脉散，先收下吧。"
				g._talk([["陶伯",introduction],["陶伯","没粮的人在岸上等。你们去看看名册，再验一验封箱。"],
					["步惊云","先把扣粮的人和印找出来。"]],_brief)
		"register":
			g._talk([["聂风","名册上签收的是阿芦。她那一栏写着二十户，一户还没划掉。"]],_mark.bind("register"))
		"seal":
			g._talk([["步惊云","箱上盖的是废了的旧关印。粮进了仓，账却还在韩朔手里。"]],_mark.bind("seal"))
		"sluice":
			g.sfx("mechanism")
			_mark("sluice")
			g._notice("水栅已抬起。沿东侧石路前进。")
		"gate_entry","sluice_entry":
			if flags.route == "":
				flags.route = "gate" if id == "gate_entry" else "sluice"
			_enter("tidal_fort")
		"return_ford": _enter("tidal_ford")
		"gate","aid","chief":
			battle = id
			g._talk(ENCOUNTERS[battle][2],g._start_battle)
		"ledger":
			g._talk([["步惊云","旧关印下还有新账。仓里每少一袋，岸上便有一户要拿劳力抵。"],
				["聂风","把账带回渡口，先让该领粮的人自己说。"]],_mark.bind("ledger"))
		"report":
			var note := "两种做法会改变渡口接下来如何分粮。"
			if _fengxi_aid() == "boat":
				note = "凤溪船能把粮送上游。公开账簿可沿河分粮，交州府则先运原账。"
			elif _fengxi_aid() == "grain":
				note = "凤溪乡亲会垫出周转粮。公开账簿可当场发粮，交州府则用它撑过清点。"
			if not flags.aid:
				note += " 阿芦仍可救。"
			g.chronicle.choose("粮账该如何交代",
				[["公开账簿，按名册开仓","public"],["留存证词，交由州府清点","witness"]],
				_resolve,note)
		"memory":
			if flags.aid:
				g._talk([["阿芦","我当时只想给家里带袋米。现在每个来领粮的人都能看见自己的名字。"]],g._return_to_field)
			else:
				g._talk([["渡口乡亲","今年总算有粮了。给我们递信的阿芦，还在等粮仓那头的回音。"]],g._return_to_field)

func _brief() -> void:
	if state().brief:
		return
	if _fengxi_aid() != "grain":
		_mark("brief")
		return
	var flags := state()
	var medicine := PackedStringArray()
	if flags.tonics < 6:
		flags.tonics += 1
		medicine.append("金创药")
	if flags.supplies.guard_powder < Items.CAP:
		flags.supplies.guard_powder += 1
		medicine.append("护脉散")
	_mark("brief")
	g._notice("收到凤溪补给 · " + "、".join(medicine) if not medicine.is_empty() else "药囊已满，陶伯收回药品。")

func _open_crew_sluice() -> bool:
	var flags := state()
	if _fengxi_aid() != "boat" or not flags.register or not flags.seal or flags.sluice or not flags.route.is_empty():
		return false
	flags.sluice = true
	return true

func _mark(flag: String) -> void:
	state()[flag] = true
	var opened := _open_crew_sluice()
	g._commit()
	g._return_to_field()
	if opened:
		g.sfx("mechanism")
		g._notice("凤溪渡工已抬起水栅，可走侧道。")

func won(remaining: int) -> String:
	var flags := state()
	flags[battle] = true
	flags.tonics = mini(6,remaining + (2 if battle == "aid" else 0))
	g._commit()
	var notice: String = {"gate":"正门已通。","aid":"阿芦脱困。得到两剂补给。","chief":"韩朔退开，案桌上的账簿可以取走。"}.get(battle,"")
	return notice

func _resolve(resolution: String) -> void:
	var flag := state()
	var scene: Array
	if resolution == "public":
		scene = [["陶伯","我会把账贴在渡口，照名册给各家称粮。谁觉得数不对，当场对。"],
			["聂风","把每次称过的数也记上。后来的人一看就明白。"]]
	else:
		scene = [["陶伯","抄一份留在村里，原账随证词送州府。先给等在岸上的人留足三日粮。"],
			["步惊云","让送账的人带回执。仓门往后开不开，由领粮的人一起看着。"]]
	match _fengxi_aid():
		"boat":
			scene[1][1] = ("凤溪的船先把粮分送上游，名单和实发的数一起贴在船头。" if resolution == "public"
				else "凤溪的船送原账去州府。回程记得带回执，上游人就知道仓门何时开。")
		"grain":
			scene[1][1] = ("凤溪乡亲先垫两袋粮，今天就能让等在岸上的人按册领粮。" if resolution == "public"
				else "凤溪乡亲会先借粮给最缺粮的几户，等州府按回执补足。")
	if flag.aid:
		scene.append(["阿芦","我愿意作证。我认得每一张被他们换过的粮票。"])
	g._talk(scene,func():
		state().resolution = resolution
		g._commit()
		g._return_to_field()
		g._notice("潮关余事已结。"))

func journal() -> Array:
	var f := state()
	var route: String = {"":"尚未选路","gate":"由正门入仓","sluice":"从水栅侧道入仓"}.get(f.route,"")
	var end: String = {"":"尚未决定","public":"公开账簿，按名册开仓","witness":"留存证词，交州府清点"}.get(f.resolution,"")
	var entries := [
		["领粮名册","已核对" if f.register else "未查"],
		["粮箱封条","已核对" if f.seal else "未查"],
		["入仓路线",route],
		["粮棚救援","阿芦已脱困" if f.aid else "尚未救出阿芦"],
		["粮仓账簿","已带回" if f.ledger else "尚未取回"],
		["渡口交代",end]
	]
	match _fengxi_aid():
		"boat": entries.append(["凤溪渡工","水栅已开" if f.sluice else "查齐证据后帮忙抬水栅"])
		"grain": entries.append(["凤溪乡亲","陶伯已交接药品" if f.brief else "陶伯处有药品"])
	return entries
