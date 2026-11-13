extends SceneTree

const Pass = preload("res://scripts/transit_pass.gd")
const Escape = preload("res://scripts/transit_escape.gd")
const Lanes = preload("res://scripts/transit_fengxi.gd")
const STEP := 4
const DIRECTIONS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var polygon := PackedVector2Array()
var walls: Array[Rect2] = []
var failures := 0

func _initialize() -> void:
	_verify_map(Pass.DATA, [["pass_cart", "pass_worker", "pass_rope", "pass_gate", "pass_exit"],
			["pass_cart", "pass_scouts", "pass_stencil", "pass_gate", "pass_exit"]], ["forge", "spawn"], ["pass_scouts"])
	_verify_map(Escape.DATA, [["escape_orders", "escape_wounded", "escape_haul", "escape_lantern", "escape_river"],
			["escape_orders", "escape_false_tracks", "escape_patrol", "escape_lantern", "escape_river"]], ["", "chapter"], ["escape_patrol"])
	_verify_map(Lanes.DATA, [["lanes_child", "lanes_witness", "lanes_tracks", "lanes_relay", "lanes_bill", "lanes_exit"]],
			["village", "west_spawn"], ["lanes_relay"])
	print("Early transit zones: %d failures" % failures)
	quit(1 if failures else 0)

func _verify_map(data: Dictionary, paths: Array, arrival: Array, fights: Array) -> void:
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/field/%s.json" % data.id))
	polygon.clear()
	walls.clear()
	for p in layout.ground:
		polygon.append(Vector2(p[0] * 2, p[1] * 2))
	for box in layout.walls:
		walls.append(Rect2(box[0] * 2, box[1] * 2, box[2] * 2, box[3] * 2).grow(3))
	_check(layout.width == 768 and data.arrival == arrival, data.id + " is 768 px wide and connects to the next story location")
	var steps: Array = data.steps
	var spawn := Vector2i(layout.spawn[0] * 2, layout.spawn[1] * 2)
	var points := {}
	var point_steps := {}
	var enemies := []
	var flags := []
	for step in steps.size():
		for point in steps[step]:
			_check(not points.has(point.id) and _passable(point.at), point.id + " is unique and placed on the trail")
			points[point.id] = point.at
			var next: int = point.get("next", step + 1)
			_check(next > step and next <= steps.size(), point.id + " has a reachable successor index")
			point_steps[point.id] = [step, next]
			if not point.get("foes", []).is_empty():
				enemies.append(point.id)
			if point.has("flag"):
				flags.append(point.flag)
	_check(flags == data.get("flags", []), data.id + " records each authored branch outcome once")
	_check(enemies == fights, data.id + " only starts the designated confrontations")
	for path in paths:
		var last := spawn
		var distance := 0
		var expected_step := 0
		for id in path:
			_check(point_steps[id][0] == expected_step, id + " follows the prior interaction state")
			expected_step = point_steps[id][1]
			var result := _walk(last, points[id])
			_check(not result.is_empty(), id + " can be reached in order with normal collisions")
			if not result.is_empty():
				last = result.point
				distance += result.distance
		_check(expected_step == steps.size() and distance >= 1280,
			String(path[1]) + " reaches the terminal step through more than two viewport widths")
		print("WALK %s %d world pixels" % [path[1], distance])

func _walk(origin: Vector2i, target: Vector2) -> Dictionary:
	var discovered := {origin: 0}
	var queue: Array[Vector2i] = [origin]
	var cursor := 0
	while cursor < queue.size():
		var point := queue[cursor]
		cursor += 1
		if Vector2(point).distance_to(target) < 9:
			return {"point": point, "distance": discovered[point]}
		for direction in DIRECTIONS:
			var next: Vector2i = point + direction * STEP
			if not discovered.has(next) and _passable(Vector2(next)):
				discovered[next] = discovered[point] + STEP
				queue.append(next)
	return {}

func _passable(point: Vector2) -> bool:
	if not Geometry2D.is_point_in_polygon(point, polygon):
		return false
	for wall in walls:
		if wall.has_point(point):
			return false
	return true

func _check(passed: bool, description: String) -> void:
	print(("PASS " if passed else "FAIL ") + description)
	if not passed:
		failures += 1
