extends "res://tests/acceptance.gd"

const Story = preload("res://scripts/story.gd")

func _run() -> void:
	if "--profile=qa_fengxi_postroad" not in OS.get_cmdline_user_args():
		push_error("Run with -- --profile=qa_fengxi_postroad")
		quit(1)
		return
	game = MAIN.instantiate()
	root.add_child(game)
	visual = DisplayServer.get_name() != "headless"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--reports="):
			report_dir = arg.trim_prefix("--reports=")
	if _enter_market(1):
		_check(not _has("road_shore_postroad"), "the optional bypass is absent before the mountains unlock")
	if _enter_market(2,{},false):
		await _test_closed_gate()
	if _enter_market(2):
		await _test_open_road()
		if game.slot.world.area == "fengxi_postroad":
			await _test_southern_fight()
	if _enter_market(2):
		await _test_northern_track()
		if game.storage.read().world.tasks.get("postroad_relay", "") == "done":
			await _test_reopened()
	print("Fengxi postroad: %d failures" % failures)
	quit(1 if failures else 0)

func _enter_market(chapter: int, resume_slot: Dictionary = {}, sword_open: bool = true) -> bool:
	game.afterstory.reset()
	var slot: Dictionary = game.storage.replay(chapter,false) if resume_slot.is_empty() else resume_slot
	if chapter == 1:
		slot.cleared = [0,1]
	if chapter == 2 and sword_open:
		slot.cleared = [0]
		slot.campaign.crossing = "bridge"
	slot.world.area = ""
	slot.world.entry = []
	slot.world.resume = {}
	slot.world["return"] = {}
	if not _check(game.storage.write(slot), "chapter %d postroad fixture is a valid save" % (chapter+1)):
		return false
	game._title()
	if slot.finished:
		game.stage = Story.CHAPTERS[chapter]
	else:
		game._enter_chapter(false)
	game.world.from_main("fengxi")
	if not _do_point("world_fengxi_market"):
		return false
	return _check(game.world.active() and game.slot.world.area == "market", "the original market map is active")

func _test_closed_gate() -> void:
	if not _do_point("road_shore_postroad"):
		return
	_check(not _has("road_postroad_sword") and _has("postroad_east_shut"), "the unopened Swordhall road leaves an explicit closed gate")
	if not _do_point("postroad_east_shut"):
		return
	_check(game.slot.world.area == "fengxi_postroad" and _has("road_postroad_shore"),
		"speaking to the guard keeps the market return open")
	print("POSTROAD locked east gate keeps a usable western return")
	await _capture("postroad-locked-gate")

func _test_open_road() -> void:
	if not _do_point("road_shore_postroad"):
		return
	_check(game.field_key == "fengxi_postroad" and game.field_width() == 1536
		and game.player.distance_to(Vector2(102,252)) < 1.0,"the market gate enters a wide map at its exact west landing")
	_check(_has("postroad_sign") and not _has("postroad_relay"), "sealed waterway signs show an optional investigation")
	_check(not _has("postroad_east_shut"), "an opened Swordhall route replaces the closed gate")
	await _capture("postroad-west")
	var before := total_distance
	if not _do_point("road_postroad_sword"):
		return
	var distance := total_distance-before
	_check(distance >= 1300.0 and game.slot.world.area == "sword_road" and game.player.distance_to(Vector2(127,239)) < 1.0,
		"unchallenged west-to-east travel traverses the map and lands on the Swordhall road")
	_check(game.slot.world.tasks.is_empty(), "mere travel does not fabricate an investigation result")
	_do_point("road_sword_postroad")
	_check(game.slot.world.area == "fengxi_postroad" and game.player.distance_to(Vector2(1417,243)) < 1.0,
		"the actual Swordhall passage returns to the east postroad landing")
	_resume()
	_check(game.slot.world.area == "fengxi_postroad" and game.player.distance_to(Vector2(1417,243)) < 1.0,
		"continuing from title preserves the remote regional landing")
	print("POSTROAD direct crossing world_pixels=%.0f" % distance)

func _test_southern_fight() -> void:
	if not _do_point("postroad_cart"):
		return
	_check(_has("postroad_ridge") and _has("postroad_wardens"), "investigation has alternative fight and exploration choices")
	var before: Dictionary = game.storage.read()
	if not _do_point("postroad_wardens") or not _check(game.mode == "battle", "the south detour opens a real battle"):
		return
	_key(KEY_5)
	_key(KEY_ENTER)
	_check(game.encounter.tonics == before.tonics - 1, "the optional battle attempts to spend a real tonic")
	for action in 180:
		if game.mode != "battle":
			break
		_key(KEY_4)
	if not _check(game.mode == "defeat", "losing is recoverable"):
		return
	_select_menu_row(1)
	_check(game.mode == "field" and game.player.distance_to(Vector2(773,249)) < 1.0,
		"retreat places the party on the safe main path")
	_check(game.storage.read() == before and not game.slot.world.tasks.has("postroad_trace"),
		"retreat preserves saved medicine and progress")
	if not _do_point("postroad_wardens") or not await _play_battle():
		return
	_key(KEY_ENTER)
	_check(not _has("postroad_wardens") and not _has("postroad_ridge"), "win records the result once")
	_do_point("postroad_relay")
	_check(game.storage.read().world.tasks.get("postroad_relay", "") == "done", "a fight can resolve the missing wagon")
	print("POSTROAD south encounter defeated after safe retreat and retry")

func _test_northern_track() -> void:
	if not _do_point("road_shore_postroad") or not _do_point("postroad_cart"):
		return
	var before: Dictionary = game.storage.read()
	if visual and _reach("postroad_ridge"):
		await _capture("postroad-north-fork")
	if not _do_point("postroad_ridge") or not _do_point("postroad_relay"):
		return
	var after: Dictionary = game.storage.read()
	_check(after.world.tasks.get("postroad_relay", "") == "done" and before.tonics == after.tonics
		and before.supplies == after.supplies and before.silver == after.silver,
		"tracing the northern prints opens the road with no combat or purchase")
	await _capture("postroad-helped")
	if not _do_point("postroad_causeway_west"):
		return
	_check(game.player.distance_to(Vector2(466,242)) < 1.0,"the return shortcut really moves the party west")
	if not _do_point("postroad_causeway_east"):
		return
	_check(game.player.distance_to(Vector2(1174,248)) < 1.0,"the foothold passage also works eastbound")
	if not _do_point("road_postroad_shore"):
		return
	_check(game.slot.world.area == "market" and game.player.distance_to(Vector2(1006,251)) < 1.0,
		"the western stair rejoins the market's physical east gate")
	print("POSTROAD northern evidence, no supplies spent, two-way causeway unlocked")

func _test_reopened() -> void:
	var completed: Dictionary = game.storage.read()
	completed.chapter = 5
	completed.finished = true
	completed.cleared = [0,1]
	completed.campaign = game.storage._initial_campaign(completed)
	if not _enter_market(5,completed) or not _do_point("road_shore_postroad"):
		return
	_check(game.world.phase() == "reopened" and _has("postroad_receipt"), "returning after the ending unlocks the physical receipt")
	if _do_point("postroad_receipt"):
		_check(game.storage.read().world.tasks.get("postroad_receipt",false) and not _has("postroad_receipt"),
			"receipt is saved and cannot repeat")
		print("POSTROAD reopened receipt recorded")
	await _capture("postroad-reopened")

func _has(id: String) -> bool:
	return game.field_points().any(func(point: Dictionary): return point.id == id)
