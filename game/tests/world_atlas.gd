extends SceneTree

const GAME = preload("res://main.tscn")
const ATLAS = preload("res://scripts/world_atlas.gd")
const JOURNEY = preload("res://scripts/world_journey.gd")
const PROFILE := "qa_world_atlas"

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
	_check_registry()
	_check_early_play()
	await _check_settled_play()
	for suffix in ["",".tmp",".bak"]:
		var path: String = game.storage.path + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	print("World atlas: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

func _check_registry() -> void:
	_check(ATLAS.REGIONS.keys() == JOURNEY.REGIONS.keys(),"the atlas lists all seven existing regions in travel order")
	for id in JOURNEY.REGIONS:
		var locations: Dictionary = JOURNEY.REGIONS[id].AREAS
		for area in locations:
			if area == "watch_palace_reception":
				continue
			_check(ATLAS.PLACES.has(area),"the atlas describes " + area)
			_check(FileAccess.file_exists("res://assets/field/" + locations[area].field + ".json"),"the atlas location has real geometry " + area)

func _check_early_play() -> void:
	game.slot = game.storage.replay(2,false)
	game.slot.intro_seen = true
	game._commit()
	game._enter_chapter(false)
	var initial: Vector2 = game.player
	var disk: Dictionary = game.storage.read()
	_key(KEY_M)
	_check(game.mode == "world_map" and game.world.destinations().size() == 1,"an early player can view the atlas with only one region open")
	if game.mode != "world_map":
		return
	_key(KEY_TAB)
	_check(game.mode == "world_places" and game.atlas_region() == "fengxi","the atlas opens the selected region's locations")
	var ids: Array = game.world.atlas_place_ids("fengxi")
	_check(ids.has("market") and ids.has("fengxi_weighhouse") and ids.has("fengxi_postroad"),"the town, grain building and wild road are listed under Fengxi")
	_check(not game.world.atlas_route_open("fengxi","swordhall"),"Fengxi to Swordhall does not bypass the Swordhall story unlock")
	_key(KEY_ESCAPE)
	_key(KEY_ESCAPE)
	_check(game.mode == "field" and game.player == initial and game.storage.read() == disk,"closing the atlas restores the player's exact location and save")

func _check_settled_play() -> void:
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/stage4-v320-public.json"))
	_check(game.storage.write(fixture),"a previous release save is still accepted")
	game._title()
	game.menu_confirm(6)
	_check(game.mode == "world_map" and game.world.destinations().size() == 7,"completed title opens the travel atlas")
	if game.mode != "world_map":
		return
	_check(game.world.atlas_route_open("fengxi","swordhall") and game.world.atlas_route_open("fengxi","tide"),"real land and boat connections appear after story gates")
	_check(not game.world.atlas_place("tide","tide_county_office").open,"an outgoing road alone does not unlock the county office")
	await _capture("world-atlas")
	game.selected = 0
	var event := InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_X
	event.pressed = true
	game._unhandled_input(event)
	_check(game.mode == "world_places","controller X opens the focused region directory")
	if game.mode != "world_places":
		return
	var places: Array = game.world.atlas_place_ids("fengxi")
	game.click("atlas_place_row",places.find("market"))
	_check(places[game.selected] == "market","a location tap inspects the street without travelling")
	await _capture("fengxi-directory")
	_key(KEY_ENTER)
	_check(game.world.active() and game.slot.world.area == "shore","confirmation travels to the region entrance and respects interior thresholds")
	game.world.tracked = "postroad_relay"
	_check(game.world.trackable_points().map(func(point: Dictionary): return point.id) == ["world_fengxi_market"],
		"tracking the postroad quest navigates through the market from the dock")

func _key(key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = true
	game._unhandled_input(event)

func _capture(name: String) -> void:
	if reports.is_empty() or DisplayServer.get_name() == "headless":
		return
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	_check(image.save_png(reports.path_join(name + ".png")) == OK,"captured " + name)

func _check(value: bool, message: String) -> void:
	checks += 1
	if value:
		print("PASS " + message)
	else:
		failures += 1
		printerr("FAIL " + message)
