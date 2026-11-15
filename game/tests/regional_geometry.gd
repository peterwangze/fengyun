extends SceneTree

const Game = preload("res://main.tscn")
const Regions = preload("res://scripts/world_journey.gd")
const DIRS = [Vector2i(4,0),Vector2i(0,4),Vector2i(-4,0),Vector2i(0,-4)]
var game
var paths := {}
var fields := {}
var failures := 0
var anchors := 0
var landings := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if "--profile=qa_regional_geometry" not in OS.get_cmdline_user_args():
		push_error("Run with -- --profile=qa_regional_geometry")
		quit(1)
		return
	game = Game.instantiate()
	root.add_child(game)
	game.slot = game.storage.fresh(false)
	game.slot.chapter = 5
	game.slot.finished = true
	var active_areas := []
	for region in Regions.REGIONS.values():
		for area in region.AREAS:
			var cfg: Dictionary = region.AREAS[area]
			var variants := {}
			for phase in region.PHASES:
				variants[phase] = cfg.get("phase_fields",{}).get(phase,cfg.field)
			fields[area] = variants
			for field in variants.values():
				if paths.has(field):
					continue
				game.slot.world.area = area
				game._load_field(field,cfg.spawn)
				if not game.passable(game.player):
					failures += 1
					printerr("FAIL %s has blocked spawn %s" % [field,game.player])
				paths[field] = _reachable(game.player)
				print("FIELD %s %s width=%d reachable_cells=%d spawn=%s" % [area,field,game.field_width(),paths[field].size(),game.player])
		for definition in region.QUESTS:
			print("QUEST %s %s steps=%d" % [region.TITLE,definition.id,definition.evidence.size()])
		active_areas.append_array(region.POINTS)
	active_areas.append_array(Regions.LINKS)
	for interaction in active_areas:
		var unique := {}
		for phase in fields[interaction.area]:
			var field: String = fields[interaction.area][phase]
			if phase not in interaction.get("phases",[phase]) or unique.has(field):
				continue
			unique[field] = true
			_check_anchor(interaction.id,interaction.area,field,interaction.at,8.0,false)
		if interaction.has("arrival"):
			var unique_dest := {}
			for field in fields[interaction.destination].values():
				if field in unique_dest:
					continue
				unique_dest[field] = true
				_check_anchor(interaction.id,interaction.destination,field,interaction.arrival,10.0,true)
	print("Regional geometry: %d fields, %d interaction anchors, %d explicit landings, %d failures" % [
		paths.size(),anchors,landings,failures])
	quit(1 if failures else 0)

func _check_anchor(id: String, area: String, field: String, at: Vector2, radius: float, arrival: bool) -> void:
	if arrival:
		landings += 1
	else:
		anchors += 1
	var problem := _probe(area,field,at,radius)
	if not problem.is_empty():
		failures += 1
		printerr("FAIL %s %s %s %s" % [id,field,at,problem])

func _reachable(start: Vector2) -> Dictionary:
	var initial := Vector2i(start)
	var reached := {initial:true}
	var frontier: Array[Vector2i] = [initial]
	var head := 0
	while head < frontier.size():
		var at := frontier[head]
		head += 1
		for dir in DIRS:
			var next: Vector2i = at + dir
			if next not in reached and game.passable(Vector2(next)):
				reached[next] = true
				frontier.append(next)
	return reached

func _probe(area: String, field: String, at: Vector2, radius: float) -> String:
	game.slot.world.area = area
	game._load_field(field)
	var graph: Dictionary = paths[field]
	var close := false
	for y in range(floori(at.y-radius),ceili(at.y+radius)):
		for x in range(floori(at.x-radius),ceili(at.x+radius)):
			if Vector2i(x,y) in graph and Vector2(x,y).distance_to(at) <= radius:
				close = true
				break
		if close:
			break
	if not close:
		return "no reachable floor within " + str(radius)
	if not game.passable(at):
		return "not directly passable"
	return ""
