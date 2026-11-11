extends RefCounted

const WEDDING := [
	["雄霸","今日孔慈嫁给秦霜。云儿，你若要带她走，先问你风师弟肯不肯让路。"],
	["步惊云","我只问孔慈。你若愿意留下，我转身就走。"],
	["孔慈","你们都是我想护住的人。求你们，别在这里拔剑。"],
	["秦霜","云师弟，收掌！孔慈……孔慈！"],
	["聂风","秦师兄，你先照看孔慈。云师兄，仆役还困在堂里。"]
]
const REAR_FIGHT := ["竹径巡卫", ["blade","guard"], [
	["巡卫","有人闯后门！堵住竹径，别让他们下山。"],
	["聂风","云师兄，解决这一队就走。"]
]]
const WARN_TIME := 0.70
const STAFF := ["maid","servant"]

var g
var wedding_playing := false
var line_started := 0.0
var patrol_clock := 0.0
var alert := 0.0
var retreat: Dictionary = {}

func _init(game: Node2D) -> void:
	g = game

func reset_scene() -> void:
	wedding_playing = false
	retreat.clear()
	patrol_clock = 0.0
	alert = 0.0

func active() -> bool:
	return g.slot.get("chapter", -1) == 0

func state() -> Dictionary:
	return g.slot.hall

func cleared_gate() -> bool:
	return g.slot.cleared.has(0)

func courtyard_fight(index: int) -> bool:
	return not g.slot.cleared.has(index) and (index != 1 or state().wedding)

func spot(id: String, label: String) -> Dictionary:
	return {"id":id,"name":label,"pos":g.position_of(id),"index":-1}

func points() -> Array:
	match g.field_key:
		"hall":
			return [spot("banquet_door","正堂 · 婚宴")]
		"banquet":
			var choices := [spot("court_door","飞云堂正门" if state().wedding else "返回庭院"),
				spot("garden_door","竹径后门")]
			if state().wedding:
				for member in STAFF:
					if not state().staff.has(member):
						choices.append(spot(member,"疏散侍女" if member == "maid" else "疏散仆役"))
			else:
				choices.append(spot("ceremony","走近喜堂"))
			return choices
		"garden":
			return [spot("return_door","返回喜堂"), spot("escape_door","后门 · 下山")]
	return []

func objective() -> String:
	match g.field_key:
		"hall":
			if not cleared_gate(): return "击退守门执事，进入正堂。"
			if not state().wedding: return "从庭院北侧进入正堂，去见孔慈。"
			if g.slot.cleared.has(1): return "从东侧山门离开天下会。"
			return "击退东侧伏兵，或返回喜堂改走竹径。"
		"banquet":
			if not state().wedding: return "沿红毯走到喜堂中央。"
			return "可先疏散仆役，再从正门或竹径撤离。"
		"garden":
			if state().alarm and not g.slot.cleared.has(1): return "巡卫已戒备。到后门迎战，或返回喜堂。"
			return "避开巡卫视线，从竹径尽头的后门下山。"
	return ""

func subtitle() -> String:
	match g.field_key:
		"banquet": return "天下会 · 正堂"
		"garden": return "天下会 · 竹径"
	return "天下会 · 飞云堂庭院"

func handle(id: String) -> bool:
	match id:
		"banquet_door":
			if cleared_gate():
				_change_room("banquet", "spawn")
			else:
				g._notice("守门执事拦在前面。先击退他。")
		"ceremony":
			wedding_playing = true
			line_started = g.elapsed
			g._talk(WEDDING, _finish_wedding)
		"court_door": _change_room("hall", "banquet_return")
		"garden_door":
			if state().wedding:
				_change_room("garden", "spawn")
			else:
				g._notice("喜堂还未散席，后门拴着。")
		"return_door": _change_room("banquet", "garden_return")
		"maid", "servant": _evacuate(id)
		"escape_door":
			if state().alarm and not g.slot.cleared.has(1):
				_confront_patrol()
			else:
				_leave(true)
		"exit":
			if state().wedding and g.slot.cleared.has(1):
				_leave(false)
			elif state().wedding:
				g._notice("东门被伏兵把守。也可从喜堂改走竹径。")
			else:
				g._notice("山门落了锁。先从北面进入正堂。")
		"guide":
			if state().wedding:
				g._talk([["文丑丑","正门有人把守。若不愿硬闯，喜堂东侧的竹径也能下山。"]], g._return_to_field)
			else:
				g._talk(g.stage.hint, g._return_to_field)
		_: return false
	return true

func _change_room(key: String, arrival: String) -> void:
	state().room = key
	reset_scene()
	g._load_field(key, arrival)
	g._return_to_field()
	g._commit()

func _finish_wedding() -> void:
	wedding_playing = false
	state().wedding = true
	g._commit()
	g._return_to_field()
	g.sfx("lose")
	g._notice("可以先疏散堂内两人，再选择撤离路线。")

func _evacuate(id: String) -> void:
	if state().staff.has(id):
		return
	retreat[id] = g.elapsed
	state().staff.append(id)
	if state().staff.size() == STAFF.size():
		g.slot.tonics = mini(9, int(g.slot.tonics) + 1)
		g._notice("仆役已撤离。竹径的灯已熄灭，得到补给。")
	else:
		g._notice("已引导一人沿侧廊离开。")
	g._commit()

func _leave(rear: bool) -> void:
	var line := "沿竹径下山。别回头，他们还在找我们。" if rear else "东门开了。师兄，趁他们还没封住山路。"
	var closing := [["聂风",line],["步惊云","我还会回来，问他今夜这一掌。"]]
	closing.append_array(g.chronicle.on_first_departure())
	g._talk(closing,g._next_chapter)

func _confront_patrol() -> void:
	if g.slot.cleared.has(1) or g.mode != "field":
		return
	state().alarm = true
	alert = 0
	g._commit()
	g._approach_battle(1)

func patrol_visible() -> bool:
	return g.field_key == "garden" and not g.slot.cleared.has(1)

func patrol() -> Dictionary:
	var path: Array = g.map.patrol
	var a := Vector2(path[0][0],path[0][1]) * 2
	var b := Vector2(path[1][0],path[1][1]) * 2
	var cycle := fposmod(patrol_clock, 9.0)
	var fraction := cycle / 4.5
	return {"point":a.lerp(b, pingpong(fraction,1.0)), "facing":1 if cycle < 4.5 else -1}

func sight() -> PackedVector2Array:
	var guard := patrol()
	var foot: Vector2 = guard.point
	var led: bool = g.chronicle.side.state().get("seals","") == "done_guide"
	var reach := 100.0 if led else (114.0 if state().staff.size() == STAFF.size() else 151.0)
	var ahead := float(guard.facing) * reach
	return PackedVector2Array([foot, foot + Vector2(ahead,-38), foot + Vector2(ahead,38)])

func update(delta: float) -> void:
	if not patrol_visible() or state().alarm:
		return
	patrol_clock += delta
	var in_sight := Geometry2D.is_point_in_polygon(g.player,sight()) and not _obscured(patrol().point,g.player)
	alert = clampf(alert + (delta if in_sight else -2.0 * delta), 0, WARN_TIME)
	if alert >= WARN_TIME:
		_confront_patrol()

func _obscured(start: Vector2, end: Vector2) -> bool:
	for area in g.walls:
		var a: Vector2 = area.position
		var c: Vector2 = area.end
		var b := Vector2(c.x,a.y)
		var d := Vector2(a.x,c.y)
		for edge in [[a,b],[b,c],[c,d],[d,a]]:
			if Geometry2D.segment_intersects_segment(start,end,edge[0],edge[1]) != null:
				return true
	return false

