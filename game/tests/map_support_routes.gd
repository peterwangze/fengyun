extends SceneTree

const GAME = preload("res://main.tscn")
const ECONOMY = preload("res://scripts/economy.gd")
const PROFILE := "qa_map_support_routes"

var game
var checks := 0
var failures := 0
var reports := ""

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if "--profile=" + PROFILE not in OS.get_cmdline_user_args():
		printerr("Run with -- --profile=" + PROFILE)
		quit(2)
		return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--reports="):
			reports = arg.substr(10)
	game = GAME.instantiate()
	root.add_child(game)
	var legacy: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/stage4-v320-public.json"))
	if _check(game.storage.write(legacy),"an earlier completed campaign loads"):
		await _sword()
		await _valley()
		_check(game.storage.read().afterstory.resolution == "public","the optional loops leave the legacy Tidegate choice intact")
	for suffix in ["",".tmp",".bak"]:
		var path: String = game.storage.path + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	root.remove_child(game)
	game.free()
	await process_frame
	print("Map support routes: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

func _sword() -> void:
	if not _open_region("swordhall") or not _visit("world_sword_hamlet"):
		return
	_check(_has("world_sword_hamlet_gate_shut") and not _has("world_sword_hamlet_to_road"),"the charcoal track clearly indicates its gate")
	await _capture("sword-charcoal-hamlet")
	if not _path(["world_sword_charcoal_sample","world_sword_charcoal_mark","world_sword_hamlet_return","world_sword_charcoal_turnin"]):
		return
	_check(game.storage.read().world.tasks.get("sword_charcoal","") == "done","the workshop verifies material before opening the road")
	_check(game.storage.read().material_claims.has("quest:sword_charcoal"),"the iron reward enters the claim ledger once")
	if not _path(["world_sword_hamlet","world_sword_hamlet_to_road","world_sword_road_to_hamlet"]):
		return
	_check(game.slot.world.area == "sword_charcoal_hamlet" and game.player.distance_to(Vector2(555,239)) < 1,"the new link works both ways")
	_visit("world_sword_charcoal_receipt")
	game._title()
	game.menu_confirm(0)
	_check(game.slot.world.area == "sword_charcoal_hamlet" and not _has("world_sword_charcoal_receipt"),"continue restores the hamlet without reissuing a receipt")
	game.world.leave()

func _valley() -> void:
	if not _open_region("valley") or not _visit("world_valley_to_herbs"):
		return
	var before: Dictionary = ECONOMY.offer(game.slot,game.slot,"medicine",2)
	_check(_has("world_herbs_east_shut") and not _has("world_herbs_to_trestle"),"wet branches block the new route before the clinic hears the report")
	if not _path(["world_valley_herb_stone","world_valley_herb_tag"]):
		return
	await _capture("valley-herb-slope")
	if not _path(["world_herbs_to_valley","world_valley_herb_report"]):
		return
	var after: Dictionary = ECONOMY.offer(game.slot,game.slot,"medicine",2)
	_check(after.remaining == before.remaining + 1,"actual dry herbs restock one dose in the existing pharmacy")
	if not _path(["world_valley_to_herbs","world_herbs_to_trestle","world_trestle_to_herbs","world_valley_herb_followthrough"]):
		return
	_check(game.storage.read().world.tasks.has("valley_herbs_receipt"),"two-way back slope and later delivery receipt persist")
	game.world.leave()

func _open_region(id: String) -> bool:
	game._title()
	game.menu_confirm(6)
	if not _check(game.mode == "world_map","open regional atlas from normal title"):
		return false
	var index: int = game.world.destinations().find_custom(func(place: Dictionary): return place.id == id)
	game.menu_confirm(index)
	return _check(game.world.active() and game.world.region() == id,"travel to " + id + " through the atlas")

func _has(id: String) -> bool:
	return game.field_points().any(func(point: Dictionary): return point.id == id)

func _path(ids: Array) -> bool:
	for id in ids:
		if not _visit(id):
			return false
	return true

func _visit(id: String) -> bool:
	var matching: Array = game.field_points().filter(func(point: Dictionary): return point.id == id)
	if not _check(matching.size() == 1,"exact interaction " + id):
		return false
	var at: Vector2 = matching[0].pos
	if not _check(game.passable(at),"traversable anchor " + id):
		return false
	game.player = at
	game._place_follower()
	game.interact()
	while game.mode == "dialogue":
		game._confirm()
	return _check(game.mode == "field","completed " + id)

func _capture(name: String) -> void:
	if reports.is_empty() or DisplayServer.get_name() == "headless":
		return
	await process_frame
	await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png(reports.path_join(name + ".png")) == OK,"captured " + name)

func _check(value: bool, message: String) -> bool:
	checks += 1
	if value:
		print("PASS " + message)
	else:
		failures += 1
		printerr("FAIL " + message)
	return value
