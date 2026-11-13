extends RefCounted

const ROADS := {
	"courtyard_road":preload("res://scripts/transit_escape.gd"),
	"fengxi_lanes":preload("res://scripts/transit_fengxi.gd"),
	"lantern_pass":preload("res://scripts/transit_pass.gd"),
	"outer_watch":preload("res://scripts/transit_watch.gd"),
	"broken_trestle":preload("res://scripts/transit_pool.gd"),
	"palace_sluice":preload("res://scripts/transit_palace.gd"),
	"dragon_waterway":preload("res://scripts/transit_waterway.gd"),
	"dragon_ridge":preload("res://scripts/transit_ridge.gd"),
	"summit_steps":preload("res://scripts/transit_summit.gd"),
	"tidal_canal":preload("res://scripts/transit_tidal.gd"),
}

var g: Node2D
var battle := ""

func _init(game: Node2D) -> void:
	g = game

static func initial() -> Dictionary:
	return {"active":"","step":0,"at":"","done":{}}

static func valid(slot: Dictionary) -> bool:
	var journey: Variant = slot.get("journey")
	if not journey is Dictionary or not journey.get("done") is Dictionary:
		return false
	var active_room: Variant = journey.get("active")
	var at: Variant = journey.get("at")
	var step: Variant = journey.get("step")
	if not active_room is String or not at is String or (not step is int and not step is float) or step != floorf(step):
		return false
	for key in journey.done:
		if journey.done[key] != true or not ROADS.values().any(func(road): return road.DATA.complete == key):
			return false
	if active_room.is_empty():
		return at.is_empty() and step == 0
	if not ROADS.has(active_room):
		return false
	var route: Dictionary = ROADS[active_room].DATA
	if route.chapter == -1:
		if not slot.finished or slot.get("afterstory",{}).get("route","") not in ["gate","sluice"]:
			return false
	elif route.chapter != slot.chapter:
		return false
	if step < 0 or step >= route.steps.size() or journey.done.has(route.complete):
		return false
	if step == 0:
		return at.is_empty()
	for i in route.steps.size():
		for point in route.steps[i]:
			if point.id == at:
				return int(point.get("next",i+1)) == int(step)
	return false

static func is_story_flag(id: String) -> bool:
	return ROADS.values().any(func(road): return id in road.DATA.get("flags",[]))

func available(room: String) -> bool:
	return g.slot.has("journey") and not g.slot.journey.done.has(ROADS[room].DATA.complete)

func active() -> bool:
	return ROADS.has(g.field_key) and g.slot.get("journey",{}).get("active","") == g.field_key

func enter(room: String) -> void:
	g.slot.journey.active = room
	g.slot.journey.step = 0
	g.slot.journey.at = ""
	battle = ""
	g._load_field(room)
	g._commit()
	g._return_to_field()

func resume() -> bool:
	var room: String = g.slot.get("journey",{}).get("active","")
	if room.is_empty() or g.afterstory.active != (ROADS[room].DATA.chapter == -1):
		return false
	battle = ""
	g._load_field(room)
	var at: String = g.slot.journey.at
	if not at.is_empty():
		for step in data().steps:
			for point in step:
				if point.id == at:
					g.player = point.at
					g._place_follower()
	g._return_to_field()
	return true

func data() -> Dictionary:
	return ROADS[g.field_key].DATA

func _step() -> Array:
	return data().steps[int(g.slot.journey.step)]

func points() -> Array:
	var marks: Dictionary = g.afterstory.state() if g.afterstory.active else g.slot.chronicle.marks
	var result := []
	for point in _step():
		var requirements: Dictionary = point.get("requires",{})
		if requirements.keys().all(func(key): return marks.get(key) == requirements[key]):
			var entry: Dictionary = point.duplicate()
			entry["pos"] = point.at
			result.append(entry)
	return result

func objective() -> String:
	var targets := points()
	return targets[0].get("objective",targets[0].name) if not targets.is_empty() else ""

func battle_aid(index: int, special: String) -> Dictionary:
	var marks: Dictionary = g.slot.chronicle.marks
	if special == "first_tyrant" and marks.has("watch_freed"):
		return {"bond":1,"line":"岗门的仆役留灯为号，风云预先蓄起一格合击。"}
	if special == "prepare_guard":
		if marks.has("ridge_guide"):
			return {"ward":"cloud","line":"山民留下护肩，步惊云获得一次护持。"}
		if marks.has("ridge_safe"):
			return {"foe":"elite","poise":1,"line":"失去接应的追兵少一格势。"}
	if index < 0:
		return {}
	match g.field_key:
		"village":
			if index == 1 and marks.has("escape_carrier"):
				return {"ward":"frost","line":"下山时获救的仆役捎来护具，秦霜获得护持。"}
			if index == 1 and marks.has("escape_decoy"):
				return {"foe":"paper","poise":1,"line":"灯号仍在误导追兵，纸探花开场少一格势。"}
		"forge":
			if index == 0 and marks.has("pass_help"):
				return {"ward":"cloud","line":"运铁工的皮衣提供护持。"}
			if index == 0 and marks.has("pass_evidence"):
				return {"foe":"smith","poise":1,"line":"凭押运口令引敌松阵。"}
		"palace":
			if index == 1 and marks.has("trestle_carry"):
				return {"foe":"godless","poise":1,"line":"伤者托信使传到金身换气的时机。"}
			if index == 1 and marks.has("trestle_supply"):
				return {"ward":"sage","line":"断栈带出的药担帮无名预先护脉。"}
		"peak":
			if index == 2 and marks.has("summit_aid"):
				return {"ward":"wind","line":"成功下山的村民托人送来护具。"}
			if index == 2 and marks.has("summit_guard"):
				return {"foe":"elite","poise":1,"line":"吊桥的接应已断，残部开场少一格势。"}
	return {}

func encounter() -> Array:
	for step in data().steps:
		for point in step:
			if point.id == battle:
				return [point.name,point.foes,point.get("lines",[])]
	return []

func handle(point: Dictionary) -> void:
	if point.has("foes"):
		battle = point.id
		g.active_battle = -1
		g._talk(point.lines,g._start_battle)
	elif point.has("lines"):
		g._talk(point.lines,_advance.bind(point))
	else:
		_advance(point)

func won() -> void:
	var account: Dictionary = g.afterstory.state() if g.afterstory.active else g.slot
	account.tonics = g.encounter.tonics
	account.supplies = g.encounter.supplies
	for point in _step():
		if point.id == battle:
			g._record_battle_loot(account,"special:" + battle,3)
			_advance(point,false)
			return

func _advance(point: Dictionary, return_to_field: bool = true) -> void:
	var route := data()
	if point.has("flag"):
		var marks: Dictionary = g.afterstory.state() if g.afterstory.active else g.slot.chronicle.marks
		marks[point.flag] = true
	var next_step: int = point.get("next",int(g.slot.journey.step) + 1)
	if next_step < route.steps.size():
		g.slot.journey.step = next_step
		g.slot.journey.at = point.id
		g._commit()
		if return_to_field:
			g._return_to_field()
		return
	g.slot.journey.done[route.complete] = true
	g.slot.journey.active = ""
	g.slot.journey.step = 0
	g.slot.journey.at = ""
	if route.arrival[1] == "chapter":
		g._next_chapter(true)
	elif g.afterstory.active:
		g.afterstory._enter(route.arrival[0])
	else:
		g.chronicle.enter(route.arrival[0],route.arrival[1])
