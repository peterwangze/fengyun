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
const FENGXI_CONTACT := Vector2(412,240)
const TIDEGATE_SHOP := Vector2(474,268)
const TIDEGATE_FORGE := Vector2(514,259)
const DRY_STORE_HINT := Vector2(77,222)
const DRY_STORE := Vector2(119,273)

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
	if not value.get("fengxi_contact",false) is bool or (value.get("fengxi_contact",false) and not value.brief):
		return false
	var dry_hint: Variant = value.get("dry_store_hint",false)
	var dry_store: Variant = value.get("dry_store",false)
	if not dry_hint is bool or not dry_store is bool:
		return false
	if (dry_hint and not value.register) or (dry_store and not dry_hint):
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

func battle_aid() -> Dictionary:
	var flags := state()
	if battle == "chief":
		if flags.get("fengxi_contact",false) and g.chronicle.reunion_plan() == "roll":
			return {"foe":"tidal_drum","poise":2,"line":"名册帮船工认出鼓手，他开战少 2 格势。"}
		if flags.get("canal_witness",false):
			return {"foe":"tidal_drum","poise":1,"line":"卸粮人指出鼓手的起手信号，他开场少 1 格势。"}
		if flags.get("canal_manifest",false):
			return {"ward":"wind","line":"船工借出扛粮护甲，聂风开场获得护持。"}
	return {}

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
	if not g.transit.resume():
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
			result = [_spot("brief","与陶伯交谈","boatman_front"),_spot("memory","探望渡口人","maid")]
			_add_workbench(result)
			_add_fengxi_contact(result)
			_add_dry_store(result)
			return result
		result.append(_spot("brief","向陶伯问粮票" if not flags.brief else "和陶伯说话","boatman_front"))
		if not flags.brief:
			return result
		_add_workbench(result)
		_add_fengxi_contact(result)
		_add_dry_store(result)
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

func _add_workbench(points: Array) -> void:
	points.append({"id":"shop_tidegate","name":"查看盐汊杂货","pos":TIDEGATE_SHOP,"sprite":"guide","optional":true})
	points.append({"id":"craft_tidegate","name":"使用盐汊锻台","pos":TIDEGATE_FORGE,"sprite":"guard","optional":true})

func _add_fengxi_contact(points: Array) -> void:
	match g.chronicle.reunion_plan():
		"roll":
			points.append({"id":"fengxi_contact","name":"查看归人册的回信","pos":FENGXI_CONTACT,"sprite":"guard","optional":true})
		"aid":
			points.append({"id":"fengxi_contact","name":"探望凤溪渔户","pos":FENGXI_CONTACT,"sprite":"servant","optional":true})

func _add_dry_store(points: Array) -> void:
	var flags := state()
	if not flags.register or flags.get("dry_store",false):
		return
	if flags.get("dry_store_hint",false):
		points.append({"id":"dry_store","name":"查看背潮旧匣","pos":DRY_STORE,"sprite":"","optional":true})
	else:
		points.append({"id":"dry_store_hint","name":"翻看木棚修闸簿","pos":DRY_STORE_HINT,"sprite":"","optional":true})

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
		"shop_tidegate":
			g._open_shop("tidegate")
		"craft_tidegate":
			g._open_forge("tidegate")
		"register":
			g._talk([["聂风","阿芦名下二十户都没领粮。账台下还压着块盐淬铁，带去锻台能用。"]],_mark.bind("register"))
		"dry_store_hint":
			g._talk([["修闸簿","旧零件收在西南背潮的板箱里。听见两短一长，待长响过后拨扣，顶潮便掀不开箱底。"]],
				_mark.bind("dry_store_hint"))
		"dry_store":
			g.chronicle.choose("背潮旧匣的铜扣",
				[["两声短响后拨","short"],["长响过后拨","long"],["等到下一次涨潮","wait"]],
				_unlock_dry_store,"铜扣连着潮簧，刻槽是「短、短、长」。修闸簿记了拨扣时机。")
		"seal":
			g._talk([["步惊云","箱上盖的是废了的旧关印。粮进了仓，账却还在韩朔手里。"]],_mark.bind("seal"))
		"sluice":
			g.sfx("mechanism")
			_mark("sluice")
			g._notice("水栅已抬起。沿东侧石路前进。")
		"gate_entry","sluice_entry":
			if flags.route == "":
				flags.route = "gate" if id == "gate_entry" else "sluice"
			if g.transit.available("tidal_canal") and not flags.gate and not flags.chief:
				g.transit.enter("tidal_canal")
			else:
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
		"fengxi_contact":
			_meet_fengxi_contact()

func _unlock_dry_store(option: String) -> void:
	var flags := state()
	if option != "long":
		g._return_to_field()
		if option == "short":
			g._notice("扣扭不动。长响过后再拨一次。")
		return
	if not flags.get("dry_store_hint",false) or flags.get("dry_store",false):
		g._return_to_field()
		return
	g.sfx("mechanism")
	g._talk([["聂风","夹层里有一枚潮纹扣，还有件被油布裹住的仓卫厚甲。取去打铁铺就能配扣。"]],
		_mark.bind("dry_store"))

func _meet_fengxi_contact() -> void:
	var plan: String = g.chronicle.reunion_plan()
	var flags := state()
	if flags.resolution != "":
		var ending: Array
		if plan == "roll":
			ending = [["船工","这张潮关领粮单会跟归人册一起送上游，两村失散的人能在同一处互相留信。"]] \
				if flags.resolution == "public" else [["船工","州府的回执抄在归人册后头了。去城里找人的船有了凭据。"]]
		else:
			ending = [["渔户","首批粮已经分出去。我们在这里也留一口热锅，给刚靠岸的人。"]] \
				if flags.resolution == "public" else [["渔户","州府清点时粮没断。昨晚第一户已经把借粮还给了凤溪粮棚。"]]
		g._talk(ending,g._return_to_field)
	elif plan == "roll":
		var text := "我在归人册上认出了敲鼓的同乡。进粮仓时喊他名字，他会乱一拍，足够你们截住鼓阵。"
		if flags.chief:
			text = "打鼓的同乡刚把名字写进册子。他说愿跟船回村，先向领不到粮的人道个歉。"
		elif flags.get("fengxi_contact",false):
			text = "进粮仓时喊「蒋六」。他只会犹豫一瞬，等他重新举槌就晚了。"
		g._talk([["船工",text]],_finish_fengxi_contact)
	elif plan == "aid":
		var text := "在凤溪借宿那晚，我们得了一锅粥。这是船上多带的两包药，跟韩朔交手前收着。"
		if flags.get("fengxi_contact",false):
			text = "这船的药已经给你们了。我守在这里，回头给等粮的人腾个地方。"
		g._talk([["渔户",text]],_finish_fengxi_contact)

func _finish_fengxi_contact() -> void:
	var flags := state()
	if flags.get("fengxi_contact",false):
		g._return_to_field()
		return
	flags.fengxi_contact = true
	if g.chronicle.reunion_plan() == "aid":
		_give_fengxi_medicine()
	else:
		g._commit()
		g._return_to_field()
		if not flags.chief:
			g._notice("归人册线索 · 鼓手开场少 2 格势。")

func _brief() -> void:
	if state().brief:
		return
	if _fengxi_aid() != "grain":
		_mark("brief")
		return
	_give_fengxi_medicine("brief")

func _give_fengxi_medicine(flag: String = "") -> void:
	var flags := state()
	var medicine := PackedStringArray()
	if flags.tonics < 6:
		flags.tonics += 1
		medicine.append("金创药")
	if flags.supplies.guard_powder < Items.CAP:
		flags.supplies.guard_powder += 1
		medicine.append("护脉散")
	if flag.is_empty():
		g._commit()
		g._return_to_field()
	else:
		_mark(flag)
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
	if flag.get("canal_witness",false):
		var testimony := "那三十袋是我亲手卸的。我在公示的账旁守着，有人问，我当面作证。" if resolution == "public" \
			else "我随送账的人一道去州府。在岸上卸过几袋，我一袋一袋说清楚。"
		scene.append(["卸粮人",testimony])
	elif flag.get("canal_manifest",false):
		var manifest := "船单贴在原账旁，让等粮的人看清每只船该交几袋。" if resolution == "public" \
			else "船单有舟工的指印，和原账一并交州府。拿回执就能按船号复核实数。"
		scene.append(["陶伯",manifest])
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
	match g.chronicle.reunion_plan():
		"roll": entries.append(["渡口归人册","已查看船工回信" if f.get("fengxi_contact",false) else "盐汊渡口可访归人册"])
		"aid": entries.append(["凤溪粮棚","已获渔户接济" if f.get("fengxi_contact",false) else "盐汊渡口可探望渔户"])
	if f.register:
		var dry_store := "渡口西棚可查修闸簿"
		if f.get("dry_store",false):
			dry_store = "已取出潮纹扣 · 可到锻台淬炼厚甲"
		elif f.get("dry_store_hint",false):
			dry_store = "西南旧匣 · 长响过后拨扣"
		entries.append(["背潮旧匣",dry_store])
	return entries
