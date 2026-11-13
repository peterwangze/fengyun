extends SceneTree

const PALACE = preload("res://scripts/transit_palace.gd")
const TIDAL = preload("res://scripts/transit_tidal.gd")
const DRAGON = preload("res://scripts/transit_waterway.gd")
const TILES := [Vector2i(4,0),Vector2i(-4,0),Vector2i(0,4),Vector2i(0,-4)]

var extent := Rect2()
var ground := PackedVector2Array()
var walls: Array[Rect2] = []
var hazards: Array[PackedVector2Array] = []
var failures := 0

func _initialize() -> void:
	for data in [PALACE.DATA,TIDAL.DATA,DRAGON.DATA]:
		_check_layout(data)
	print("Waterway layouts: %d failures" % failures)
	quit(1 if failures else 0)

func _check_layout(data: Dictionary) -> void:
	var file := "res://assets/field/" + String(data.id) + ".json"
	var map = JSON.parse_string(FileAccess.get_file_as_string(file))
	if not _check(map is Dictionary,data.id + " has valid collision data"):
		return
	extent = Rect2(17,61,float(map.get("width",320))*2-34,254)
	ground = _polygon(map.ground)
	walls.clear()
	hazards.clear()
	for box in map.walls:
		walls.append(Rect2(box[0]*2,box[1]*2,box[2]*2,box[3]*2).grow(3))
	for loop in map.get("hazards",[]):
		hazards.append(_polygon(loop))
	var start := Vector2i(int(map.spawn[0])*2,int(map.spawn[1])*2)
	var route: Array[Vector2i] = [start]
	var visited := {start:true}
	var read_at := 0
	while read_at < route.size():
		var point := route[read_at]
		read_at += 1
		for delta: Vector2i in TILES:
			var next := point + delta
			if not visited.has(next) and _walkable(Vector2(next)):
				visited[next] = true
				route.append(next)
	_check(_walkable(Vector2(start)) and route.size() > 1,data.id + " has a usable entry and connected path")
	for step in data.steps:
		for spot in step:
			var dest: Vector2 = spot.at
			var reachable := route.any(func(tile: Vector2i): return Vector2(tile).distance_squared_to(dest) <= 25)
			_check(_walkable(dest) and reachable,"%s is reachable on foot" % spot.id)

func _polygon(coords: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for at in coords:
		result.append(Vector2(at[0],at[1])*2)
	return result

func _walkable(at: Vector2) -> bool:
	return extent.has_point(at) and Geometry2D.is_point_in_polygon(at,ground) \
		and not walls.any(func(wall: Rect2): return wall.has_point(at)) \
		and not hazards.any(func(hazard: PackedVector2Array): return Geometry2D.is_point_in_polygon(at,hazard))

func _check(ok: bool, note: String) -> bool:
	print(("PASS " if ok else "FAIL ") + note)
	if not ok:
		failures += 1
	return ok
