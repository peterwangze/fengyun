extends "res://tests/acceptance.gd"

const Story = preload("res://scripts/story.gd")

func _run() -> void:
	if "--profile=qa_palace_layers" not in OS.get_cmdline_user_args():
		push_error("Run with -- --profile=qa_palace_layers")
		quit(1)
		return
	game = MAIN.instantiate()
	root.add_child(game)
	visual = DisplayServer.get_name() != "headless"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--reports="):
			report_dir = arg.trim_prefix("--reports=")
	await _test_public()
	await _test_sealed()
	_test_unprepared_fire()
	game.music.stop()
	game.effects.stop()
	await process_frame
	print("Palace layered route: %d failures" % failures)
	quit(1 if failures else 0)

func _test_public() -> void:
	var slot: Dictionary = game.storage.replay(4,false)
	slot.supplies.guard_powder = 0
	if not _start(slot) or not _do_point("world_palace_visit") or not _do_point("world_palace_to_quay"):
		return
	_check(game.world.phase() == "edict" and game.player.distance_to(Vector2(112,253)) < 1.0,
		"the new settlement opens under the false edict with its exact west landing")
	_check(_point_name("world_palace_quay_notice").contains("不发粮"), "the edict changes the ferry notice")
	await _capture("palace-quay-edict")
	if not _walk_points(["world_palace_quay_to_store","world_palace_mooring_seal","world_palace_store_to_quay",
		"world_palace_mooring_roster","world_palace_quay_to_store"]):
		return
	_check(not _has("world_palace_mooring_choice"), "either evidence order works while the false edict still blocks filing")
	var transfer: Dictionary = game.storage.read()
	transfer.campaign.rescued = true
	transfer.cleared = [0]
	if not _continue(transfer):
		return
	_check(game.world.active() and game.slot.world.area == "palace_storehouse" and game.world.phase() == "transfer",
		"the same interior reloads in the new prisoner-transfer phase")
	if not _do_point("world_palace_mooring_choice") or not _check(game.mode == "choice", "the public plan is an actual menu option"):
		return
	await _capture("palace-quay-choice")
	_choose(0)
	_check(game.storage.read().world.tasks.palace_mooring == "ration" and not _has("world_palace_sealed_to_reeds"),
		"public filing records its choice without unlocking the sealed route")
	if not _do_point("world_palace_store_to_quay"):
		return
	_check(_point_name("world_palace_quay_notice").contains("证人") and not _has("world_palace_quay_supply"),
		"the public stall stays shut while witnesses are moving")
	var after_fire: Dictionary = game.storage.read()
	after_fire.chronicle.marks.fire_signal = true
	after_fire.chronicle.marks.evacuated = true
	after_fire.cleared = [0,1]
	if not _continue(after_fire):
		return
	_check(game.world.phase() == "aftermath" and _point_name("world_palace_quay_notice").contains("着火后"),
		"the live dock changes in aftermath and still has a receipt to complete")
	_check(not _has("world_palace_quay_supply"), "making a choice does not pretend the families have been fed")
	if not _do_point("world_palace_mooring_receipt_ration"):
		return
	_check(_has("world_palace_mooring_public_neighbors") and not _has("world_palace_mooring_receipt_ration"),
		"weighing the grain exposes the recipient and consumes the one-time receipt")
	var before: Dictionary = game.storage.read()
	if not _do_point("world_palace_quay_supply") or not _check(game.mode == "shop" and game.shop_id == "palace_quay", "the quay stall opens with its own shop stock"):
		return
	await _capture("palace-quay-public-stock")
	_select_menu_row(1)
	_key(KEY_ESCAPE)
	var bought: Dictionary = game.storage.read()
	_check(bought.supplies.guard_powder == before.supplies.guard_powder + 1 and bought.silver == before.silver - 3
		and bought.shop_stock.palace_quay.guard_powder == 1, "buying public stock spends local prices and persists consumption")
	print("PALACE public edict evidence → transfer order → actual aftermath weighing and independent stall")

func _test_sealed() -> void:
	var old: Dictionary = game.storage.replay(5,false)
	old.cleared = [0,1]
	old.finished = true
	old.campaign.farewell = true
	old.campaign.altar = true
	old.erase("world")
	if not _start(old):
		return
	game.world.from_main("palace")
	if not _walk_points(["world_palace_to_quay","world_palace_mooring_roster","world_palace_quay_to_store"]):
		return
	_check(_point_name("world_palace_mooring_seal").contains("火场"), "an older ended save gets the free aftermath proof copy")
	var before_proof: Dictionary = game.storage.read()
	if not _do_point("world_palace_mooring_seal"):
		return
	_check(game.storage.read().world.tasks.get("palace_mooring_seal",false) and _has("world_palace_mooring_choice"),
		"the fire fallback is usable without a battle or prior proof")
	if not _continue(before_proof):
		return
	if not _walk_points(["world_palace_store_to_quay","world_palace_quay_to_reeds"]):
		return
	_check(game.player.distance_to(Vector2(98,282)) < 1.0, "the riverside reeds have a safe exact waypoint")
	if not await _ambush_retry():
		return
	if not _walk_points(["world_palace_reeds_to_west","world_palace_west_to_reeds"]):
		return
	_check(game.player.distance_to(Vector2(1387,252)) < 1.0, "the alternate outside trail really connects the existing west sluice")
	if not _walk_points(["world_palace_reeds_to_quay","world_palace_quay_to_store","world_palace_mooring_choice"]):
		return
	_choose(1)
	_check(game.storage.read().world.tasks.palace_mooring == "sealed" and not _has("world_palace_sealed_to_reeds"),
		"private filing is stored without marking an escort as complete")
	if not _walk_points(["world_palace_store_to_quay","world_palace_quay_to_reeds"]):
		return
	if visual and _reach("world_palace_mooring_receipt_sealed"):
		await _capture("palace-reed-witness")
	if not _walk_points(["world_palace_mooring_receipt_sealed","world_palace_sealed_to_store"]):
		return
	_check(game.player.distance_to(Vector2(519,240)) < 1.0 and _has("world_palace_mooring_sealed_contact"),
		"the sealed witness opens the actual concealed entrance and private contact")
	_resume()
	_check(game.player.distance_to(Vector2(519,240)) < 1.0, "the newly opened passage survives title restart")
	if not _walk_points(["world_palace_sealed_to_reeds","world_palace_reeds_to_quay"]):
		return
	_check(not _has("world_palace_quay_supply") and game.player.distance_to(Vector2(999,253)) < 1.0,
		"the sealed path is two-way and leaves the public stall shut")
	print("PALACE old credits → aftermath evidence, real failed/retried ambush → protected witness and reversible quiet passage")

func _ambush_retry() -> bool:
	var before: Dictionary = game.storage.read()
	if not _do_point("world_palace_mooring_reed_ambush") or not _check(game.mode == "battle", "the optional outlying encounter starts real combat"):
		return false
	_key(KEY_5)
	_key(KEY_ENTER)
	_check(game.encounter.tonics == before.tonics - 1, "the failed attempt actually spends a potion")
	for action in 170:
		if game.mode != "battle":
			break
		_key(KEY_4)
	if not _check(game.mode == "defeat", "reed patrol loss remains recoverable"):
		return false
	_select_menu_row(1)
	_check(game.mode == "field" and game.player.distance_to(Vector2(664,280)) < 1.0
		and game.storage.read() == before, "retreat lands on a safe bank and does not spend the potion")
	if not _do_point("world_palace_mooring_reed_ambush") or not await _play_battle():
		return false
	_key(KEY_ENTER)
	return _check(game.storage.read().world.tasks.get("palace_mooring_seal",false) and not _has("world_palace_mooring_reed_ambush"),
		"winning the patrol verifies the same evidence once")

func _test_unprepared_fire() -> void:
	var slot: Dictionary = game.storage.replay(4,false)
	slot.cleared = [0,1]
	slot.campaign.rescued = true
	slot.chronicle.room = "tearoom"
	slot.chronicle.marks.tea = true
	if not _start(slot) or not _do_point("fire_signal"):
		return
	if not _walk_points(["world_palace_to_laneway","world_palace_river_decree","world_palace_to_court",
		"world_palace_dispatch_record","evacuated"]):
		return
	_check(game.chronicle.has("evacuated") and not game.world.active() and not game.slot.world.tasks.has("palace_mooring"),
		"the unchanged free fire escape never requires the added faction choice")
	print("PALACE original unprepared main fire escape cleared without the new quest")

func _start(slot: Dictionary) -> bool:
	slot.intro_seen = true
	if not _check(game.storage.write(slot), "the Palace test fixture writes through normal storage"):
		return false
	game._title()
	if slot.finished:
		game.stage = Story.CHAPTERS[int(slot.chapter)]
	else:
		_key(KEY_ENTER)
		_drain_dialogue()
	return true

func _continue(slot: Dictionary) -> bool:
	if not _check(game.storage.write(slot), "phase checkpoint writes without changing the region"):
		return false
	game._title()
	_key(KEY_ENTER)
	return true

func _walk_points(ids: Array) -> bool:
	for id in ids:
		if not _do_point(id):
			return false
	return true

func _point_name(id: String) -> String:
	var matches: Array = game.field_points().filter(func(point: Dictionary): return point.id == id)
	return "" if matches.is_empty() else matches[0].name

func _has(id: String) -> bool:
	return not _point_name(id).is_empty()
