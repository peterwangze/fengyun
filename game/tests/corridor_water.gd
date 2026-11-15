extends "res://tests/acceptance.gd"

const Story = preload("res://scripts/story.gd")
const River = preload("res://scripts/corridor_river.gd")

func _run() -> void:
	if "--profile=qa_corridor_water" not in OS.get_cmdline_user_args():
		push_error("Run with -- --profile=qa_corridor_water")
		quit(1)
		return
	game = MAIN.instantiate()
	root.add_child(game)
	visual = DisplayServer.get_name() != "headless"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--reports="):
			report_dir = arg.trim_prefix("--reports=")
	for route in ["public","covered"]:
		await _timely(route)
	await _late_legacy()
	game.music.stop()
	game.effects.stop()
	await process_frame
	print("Elm Ferry corridor: %d failures" % failures)
	quit(1 if failures else 0)

func _timely(route: String) -> void:
	var early: Dictionary = game.storage.replay(1,false)
	early.cleared = [0,1]
	early.campaign.crossing = "bridge"
	if not _start(early):
		return
	if not await _prepare(route):
		return
	var outward := "world_river_" + route + "_to_palace"
	var lock := "world_river_" + route + "_closed"
	_check(_has(lock) and not _has(outward), "before the Palace chapter the selected mooring explicitly explains its gate")
	if not _do_point(lock):
		return
	_check(not _has("world_river_elm_to_tide") and not game.storage.read().world.tasks.has("river_clearance"),
		"the blocked boat cannot skip the Palace or invent a clearance")
	_resume()
	_check(game.slot.world.area == "elm_ford" and game.player.distance_to(Vector2(117,258)) < 1.0,
		"the local skiff checkpoint reloads at the actual Elm Ferry landing")
	var palace: Dictionary = game.storage.replay(4,false)
	palace.world.tasks = game.storage.read().world.tasks.duplicate(true)
	if not _start(palace):
		return
	game.world.from_main("fengxi")
	if not _do_point("world_river_shore_to_elm") or not await _palace_trip(route):
		return
	var final: Dictionary = game.storage.replay(5,false)
	final.cleared = [0]
	final.campaign.farewell = true
	final.campaign.altar = true
	final.chronicle.marks.blood_rite = true
	final.tonics = 9
	final.merit = 30
	final.world.tasks = game.storage.read().world.tasks.duplicate(true)
	if not _start(final) or not _check(_reach("fight",1), "the actual Tyrant encounter opens from the altar field"):
		return
	_key(KEY_E)
	_drain_dialogue()
	if not _check(game.mode == "battle", "the final encounter accepts the delivered water convoy"):
		return
	var cloud: Array = game.encounter.allies.filter(func(unit: Dictionary): return unit.id == "cloud")
	_check(game.encounter.bond == int(route == "public") and not cloud.is_empty() and cloud[0].ward == (route == "covered"),
		"the two transport choices open the boss with genuinely different aid")
	if not await _play_battle():
		return
	_key(KEY_ENTER)
	var won: Dictionary = game.storage.read()
	_check(won.world.corridor_finale.get("river", "") == route and game.world.corridor_ending().size() == 1,
		"actual victory stores the route and one matching conclusion")
	print("RIVER %s ferry and timely finale proven" % route)
	var old := _tide_fixture()
	won.finished = true
	won.afterstory = old.afterstory.duplicate(true)
	if not _start(won):
		return
	game.world.from_main("fengxi")
	if _do_point("world_river_shore_to_elm") and await _tide_trip(route):
		_check(game.storage.read().world.corridor_finale.river == route, "postgame receipt does not change the timely victory snapshot")

func _late_legacy() -> void:
	var legacy := _tide_fixture()
	if not _start(legacy) or not await _prepare("covered") or not await _palace_trip("covered"):
		return
	_check(game.storage.read().world.get("corridor_finale",{}).is_empty() and game.world.corridor_ending().is_empty(),
		"a real older completed Tide save can deliver late without retroactive boss aid or epilogue")
	if not _walk_points(["world_palace_quay_to_reeds","world_river_reeds_to_covered"]):
		return
	if await _tide_trip("covered"):
		_check(game.storage.read().world.get("corridor_finale",{}).is_empty(), "late receipts leave the old final scene unchanged")
		print("RIVER legacy covered delivery earns the Tide receipt with no fabricated finale")

func _prepare(route: String) -> bool:
	game.world.from_main("fengxi")
	if not _walk_points(["world_river_manifest","world_river_shore_to_elm"]):
		return false
	_check(game.field_key == "elm_ford" and game.field_width() == 1408 and game.player.distance_to(Vector2(117,258)) < 1.0,
		"the ordinary skiff boards into a distinct, wide inhabited location")
	if not _do_point("world_river_elm_to_shore"):
		return false
	_check(game.slot.world.area == "shore" and game.player.distance_to(Vector2(100,280)) < 1.0,
		"the local skiff returns from Elm Ferry to the actual Fengxi landing")
	if not _do_point("world_river_shore_to_elm"):
		return false
	await _capture("river-elm-ford")
	if not _walk_points(["world_river_inspection","world_river_route"]):
		return false
	if not _check(game.mode == "choice", "the shipment offers an actual choice after checking the load"):
		return false
	await _capture("river-choice")
	_choose(int(route == "covered"))
	var selected: Dictionary = game.storage.read()
	if not _check(selected.world.tasks.get("river_route","") == route and not _has("world_river_" + route + "_to_palace"),
			"the prepared berth is required in addition to declaring the choice; saved facts %s" % [selected.world.tasks]):
		return false
	return _do_point("world_river_prepare_" + route)

func _palace_trip(route: String) -> bool:
	var outward := "world_river_" + route + "_to_palace"
	var return_point := "world_river_palace_to_public" if route == "public" else "world_river_reeds_to_covered"
	var destination := "palace_quay" if route == "public" else "palace_reedpath"
	var landing := Vector2(221,273) if route == "public" else Vector2(1106,278)
	if not _do_point(outward):
		return false
	_check(game.slot.world.area == destination and game.player.distance_to(landing) < 1.0,
		"the prepared boat uses the exact branch-only landing")
	var after: Dictionary = game.storage.read()
	_check(after.world.tasks.get("river_clearance",false) and not after.world.tasks.has("river_handoff"),
		"actual travel records clearance while unloading still requires a person")
	await _capture("river-landing-" + route)
	if not _walk_points([return_point,outward]):
		return false
	if route == "covered":
		_check(not _has("world_river_handoff"), "the concealed party must traverse the physical reeds to the quay")
		if not _do_point("world_palace_reeds_to_quay"):
			return false
	if not _do_point("world_river_handoff"):
		return false
	return _check(game.storage.read().world.tasks.get("river_handoff", false) and not _has("world_river_handoff"),
		"handing off the cargo is persisted once")

func _tide_trip(route: String) -> bool:
	if not _do_point("world_river_elm_to_tide"):
		return false
	_check(game.slot.world.area == "tide_ford" and game.player.distance_to(Vector2(203,278)) < 1.0,
		"the actual second ferry reaches Tidegate's dock")
	if not _do_point("world_river_tide_to_elm"):
		return false
	_check(game.slot.world.area == "elm_ford" and game.player.distance_to(Vector2(1311,259)) < 1.0,
		"the Tide boat also returns to Elm Ferry")
	if not _walk_points(["world_river_elm_to_tide","world_tide_to_canal"]):
		return false
	if route == "public":
		if not _walk_points(["world_tide_canal_to_fort","world_river_revisit_public","world_tide_fort_to_canal"]):
			return false
	elif not _do_point("world_river_revisit_covered"):
		return false
	if not _walk_points(["world_tide_canal_to_ford","world_river_tide_receipt"]):
		return false
	_check(game.storage.read().world.tasks.get("river_tide_receipt",false) and not _has("world_river_tide_receipt"),
		"postgame Tide review and receipt survive without repeating")
	print("RIVER %s Tide archive and two-way Elm return verified" % route)
	return true

func _start(slot: Dictionary) -> bool:
	slot.intro_seen = true
	if not _check(game.storage.write(slot), "fixture writes normally before chapter %d, facts %s" % [slot.chapter,slot.get("world",{}).get("tasks",{})]):
		return false
	game._title()
	if slot.finished:
		game.stage = Story.CHAPTERS[int(slot.chapter)]
	else:
		_key(KEY_ENTER)
		_drain_dialogue()
	return true

func _tide_fixture() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/stage4-v320-witness.json"))

func _walk_points(ids: Array) -> bool:
	for point in ids:
		if not _do_point(point):
			return false
	return true

func _has(id: String) -> bool:
	return game.field_points().any(func(point: Dictionary): return point.id == id)
