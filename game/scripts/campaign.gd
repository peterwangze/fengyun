extends RefCounted

const FERRY_SECONDS := 2.8
const REUNION := [
	["步惊云","你们过了河。西岸等船的人，都已经回家了吗？"],
	["秦霜","都送走了。这是封门令，追来的杀手用的也是这方印。师父要我们在喜堂里互相动手。"],
	["聂风","我在喜堂拦了你一掌。云师兄，那一掌我拦错了。"],
	["步惊云","我也有一掌欠着。西南山路还没封，先从那儿走。"]
]
const SWORD := [
	["步惊云","这柄剑来迟了一步。凤溪的人还等着我们，先用它替他们挡一挡。"],
	["聂风","东边有出口。我替你守着炉口，你把剑拔出来。"]
]
const POOL := [
	["第一邪皇","魔刀一出，魔念便涨。聂风固守能定息，第二梦的回春诀也能压住它。"],
	["第二梦","我在岸上。听得见我，就把刀放低一点。"]
]
const POOL_BREAK := [
	["第一邪皇","刀皇闯进来了！独孤梦为护住池门挨了一刀，快离开池边！"],
	["第二梦","聂风，睁眼！她的血已经流进池里。听着我的声音，把刀放低。"],
	["聂风","我听得见，可这把刀已收不住。你往后退，我从另一边走。"],
	["第二梦","我去追他。给云大哥捎个信，他和无名得先把至尊救出来。"]
]
const RESCUE := [
	["无名","锁开了。从侧梯出去，外头有人接应。您见过假诏上是谁的印吗？"],
	["至尊","是绝心动的手。他还搜走了我藏在牢里的旧水道图。我得活着回城，把假令当面拆穿。"],
	["步惊云","先送您过侧梯。我留下摸清茶房里的动静，再去破绝无神的金身。"]
]
const FAREWELL := [
	["第二梦","魔血换出来了。你现在听见的是雨，不是刀声。还记得凤溪桥上那盏灯吗？"],
	["聂风","天亮就走。我背着你去。"],
	["第二梦","等天亮，记得替我把灯点上。往后听见雨声，也别怕。"],
	["聂风","梦……我听得见了。你再叫我一声，好不好？"],
	["步惊云","我在门外。雄霸把人赶上祭台了。等你准备好，我陪你上山。"]
]
const ALTAR := [
	["雄霸","龙脉在我手里。你们若再往前一步，押上山的人就一起陪葬。"],
	["步惊云","喜堂那回我只顾着出掌。风师弟，这回你护住石阶，我来截他的招。"],
	["聂风","我看着你。合璧能破他的护气，两次破势也行。"]
]

var g
var scene := ""
var scene_started := 0.0
var ferry_time := 0.0
var boatman := Vector2.ZERO
var rescue_started := -10.0

func _init(game: Node2D) -> void:
	g = game

func state() -> Dictionary:
	return g.slot.campaign

func field_entry() -> Array:
	match int(g.slot.chapter):
		1: return ["village","west_spawn" if not state().crossing.is_empty() else "spawn"]
		4: return [state().palace_room,"spawn"]
		5: return ["peak" if state().farewell else "lodge","spawn"]
	return [g.stage.key,"spawn"]

func loaded() -> void:
	scene = ""
	ferry_time = 0
	rescue_started = -10
	if g.field_key == "village":
		boatman = g.position_of("guide")

func points() -> Array:
	match g.field_key:
		"village":
			if state().crossing.is_empty():
				return [_spot("mooring","解开船缆"),_spot("board","与船家登船")] if not state().rope else [_spot("board","与船家登船")]
			if g.slot.cleared.has(1) and not state().reunion and (not g.chronicle.enabled() or g.chronicle.has("dream_intro")):
				return [_spot("reunion","与步惊云会合")]
		"forge":
			if not state().forge_gate:
				return [_spot("winch","打开泄火闸")]
			return _sword_point()
		"pool":
			if not state().pool_trial:
				return [_spot("pool_trial","在池边试刀")]
		"palace":
			return [_spot("jail_door","下天牢")]
		"jail":
			return [_spot("jail_exit","回绝宫"),_spot("cell","解开牢门")] if not state().rescued else [_spot("jail_exit","回绝宫")]
		"lodge":
			return [_spot("bedside","走近第二梦")]
		"peak":
			if g.slot.cleared.has(0) and not state().altar:
				return [_spot("altar","登龙脉祭台")]
	return []

func all_points() -> Array:
	var result := points()
	if g.field_key == "forge" and not state().forge_gate:
		result.append_array(_sword_point())
	return result

func _sword_point() -> Array:
	return [_spot("sword","取绝世好剑")] if g.slot.cleared.has(1) and not state().sword else []

func _spot(id: String, label: String) -> Dictionary:
	return {"id":id,"name":label,"pos":g.position_of(id),"index":-1}

func objective() -> String:
	match g.field_key:
		"village":
			if state().crossing.is_empty():
				return "护送船家到登船处，或从石桥过河。" if state().rope else "石桥迎战，或到旧船埠解缆过河。"
			if not g.slot.cleared.has(1):
				return "守住西岸，打断天池杀手的信号。"
			return "从西南山路离开凤溪。" if state().reunion else "沿西岸往南，与步惊云会合。"
		"forge":
			if state().forge_route.is_empty():
				return "开闸过石桥，或沿北侧石栈绕行。"
			if g.slot.cleared.has(1):
				return "携剑从东侧出口离开。" if state().sword else "到剑炉前取剑。"
		"pool":
			if g.slot.cleared.has(1):
				return "前往出口，与第二梦会合。"
			return "先到岸边试刀，听第二梦指引。" if not state().pool_trial else "魔刀积累魔念。固守与回春诀可压制。"
		"palace":
			if g.slot.cleared.has(1) and state().rescued:
				return "至尊已脱险，从西侧离开绝宫。"
			if state().rescued:
				return "抓住破势空当，击破不灭金身。"
			return "从侧庭下天牢，救出至尊。" if g.slot.cleared.has(0) else "击退天牢卫队，打开入口。"
		"jail": return "沿牢道回绝宫。" if state().rescued else "走到中央牢门，救出至尊。"
		"lodge": return "到灯下陪第二梦走完最后一程。"
		"peak":
			if g.slot.cleared.has(1) and state().altar:
				return "沿东侧石阶下山。"
			return "登上祭台，再与雄霸决战。" if g.slot.cleared.has(0) and not state().altar else g.stage.objective
	return g.stage.objective

func subtitle() -> String:
	if g.field_key == "jail": return "无神绝宫 · 天牢"
	if g.field_key == "lodge": return "凌云山 · 雨夜小筑"
	return g.stage.place

func can_show_fight(index: int) -> bool:
	if g.slot.cleared.has(index):
		return false
	match g.field_key:
		"village":
			return index == 0 or not state().crossing.is_empty()
		"forge":
			return index != 1 or not state().forge_route.is_empty()
		"pool":
			return state().pool_trial or index == 2
		"palace":
			return index != 1 or state().rescued
		"peak":
			return index != 1 or state().altar
	return true

func can_exit() -> bool:
	if not g.slot.cleared.has(1):
		return false
	match g.field_key:
		"village": return state().reunion
		"forge": return state().sword
		"palace": return state().rescued
		"peak": return state().altar
	return true

func blocked(point: Vector2) -> bool:
	if g.field_key == "village" and not g.slot.cleared.has(0):
		return Rect2(310,190,20,23).has_point(point)
	if g.field_key == "forge" and not state().forge_gate:
		return Rect2(306,177,24,31).has_point(point)
	return false

func handle(id: String) -> bool:
	match id:
		"guide":
			if g.field_key != "village" or state().crossing.is_empty():
				return false
			var hint := "杀手堵在西岸北头。领头人举哨时，用克制武学打散他的势。"
			if g.slot.cleared.has(1):
				hint = "大家都到家了。沿西岸往南走，步惊云就在岸边等你们。"
			if state().reunion:
				hint = "渡口的灯会留着。往西走，山路能到拜剑山庄。"
			g._talk([["船家",hint]],g._return_to_field)
		"mooring":
			state().rope = true
			g._commit()
			g._notice("已解缆。靠近船家，护他走到青色登船标记。")
		"board":
			if not state().rope:
				g._notice("先去东侧旧船埠解缆。")
			elif not ferry_ready():
				g._notice("船家还在赶来。靠近他，再一起走到登船处。")
			else:
				g.sfx("ferry")
				if g.settings.motion:
					ferry_time = 0
					g._set_mode("ferry")
				else:
					finish_ferry()
		"reunion": _play("reunion", REUNION, func(): _set_flag("reunion"))
		"winch":
			state().forge_gate = true
			g._commit()
			g.sfx("mechanism")
			g._notice("炉火已导开，主桥可通行。")
		"sword": _play("sword", SWORD, func(): _set_flag("sword"))
		"pool_trial": _play("pool_trial", POOL, func(): _set_flag("pool_trial"))
		"jail_door":
			if not g.slot.cleared.has(0):
				g._notice("天牢门还被卫队封住。")
			else:
				_change_palace("jail","spawn")
		"jail_exit": _change_palace("palace","jail_return")
		"cell": _play("rescue", RESCUE, _rescue)
		"bedside": _play("farewell", FAREWELL, _leave_lodge)
		"altar":
			var speech := ALTAR
			if g.chronicle.enabled():
				speech = [
					["雄霸","龙脉碎了，我还有三分归元气。石阶上这些人能不能下山，仍由我说了算。"],
					["步惊云","喜堂那回我只顾着出掌。风师弟，这回你护住石阶，我来截他的招。"],
					["聂风","我看着你。他护气一变就会换目标，合璧能破开，两次破势也行。"]]
			_play("altar",speech,func(): _set_flag("altar"))
		"exit":
			if not can_exit():
				g._notice("先完成本章目标，再从这里离开。")
			elif g.field_key == "pool":
				_play("pool_break",POOL_BREAK,g._next_chapter)
			else:
				g._talk(g.stage.closing,g._next_chapter)
		_: return false
	return true

func _play(key: String, lines: Array, finish: Callable) -> void:
	scene = key
	scene_started = g.elapsed
	g._talk(lines,func():
		scene = ""
		finish.call())
	if key in ["farewell","reunion"]:
		g._play_music("blood" if key == "farewell" and g.chronicle.enabled() else "ending")

func _set_flag(key: String) -> void:
	state()[key] = true
	g._commit()
	g._return_to_field()
	g.sfx("confirm")

func _rescue() -> void:
	_set_flag("rescued")
	rescue_started = g.elapsed
	g._notice("至尊已获救。回绝宫挑战绝无神。")

func _change_palace(room: String, at: String) -> void:
	state().palace_room = room
	g._load_field(room,at)
	g._commit()
	g._return_to_field()

func _leave_lodge() -> void:
	state().farewell = true
	g.slot.chronicle.room = ""
	g._load_field("peak")
	g._commit()
	g._return_to_field()

func ferry_ready() -> bool:
	return boatman.distance_to(g.position_of("board")) < 5.0

func ferry_point() -> Vector2:
	var start: Vector2 = g.position_of("boat_east")
	var end: Vector2 = g.position_of("boat_west")
	return start.lerp(end, smoothstep(0.0,FERRY_SECONDS,ferry_time))

func abort_ferry() -> void:
	if ferry_time < 0.55:
		ferry_time = 0
		g._return_to_field()

func finish_ferry() -> void:
	g._load_field("village","west_spawn")
	_arrived("boat")
	g._return_to_field()

func _arrived(route: String) -> void:
	if not state().crossing.is_empty():
		return
	state().crossing = route
	if not g.slot.cleared.has(0):
		g.slot.cleared.append(0)
	g.slot.merit += 2
	g._commit()
	g._notice("已抵达西岸，获得 2 点历练。")

func update(delta: float) -> void:
	if g.mode == "ferry":
		ferry_time += delta
		if ferry_time >= FERRY_SECONDS:
			finish_ferry()
		return
	if g.field_key == "village" and state().crossing.is_empty():
		if state().rope and g.player.distance_to(boatman) < 84.0:
			var next: Vector2 = boatman.move_toward(g.position_of("board"),62.0 * delta)
			if g.passable(next):
				boatman = next
		if g.slot.cleared.has(0) and g.player.x < 226:
			_arrived("bridge")
	elif g.field_key == "forge" and state().forge_route.is_empty() and g.player.x > 379:
		state().forge_route = "ledge" if g.player.y < 142 else "gate"
		g._commit()
		g._notice("已从%s通过。" % ("北侧石栈" if state().forge_route == "ledge" else "泄火主桥"))

