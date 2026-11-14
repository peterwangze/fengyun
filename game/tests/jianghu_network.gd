extends SceneTree

const Main = preload("res://main.tscn")
const Equipment = preload("res://scripts/equipment.gd")
const PROFILE := "qa_jianghu_network"
const DIRECTIONS := [Vector2i(4,0), Vector2i(-4,0), Vector2i(0,4), Vector2i(0,-4)]

var game
var checks := 0
var failures := 0
var report_dir := ""
var walking_pixels := 0.0
var dialogue_inputs := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if "--profile=" + PROFILE not in OS.get_cmdline_user_args():
		push_error("Run with -- --profile=" + PROFILE)
		quit(1)
		return
	game = Main.instantiate()
	root.add_child(game)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--reports="):
			report_dir = arg.substr(10)
	await _test_unlock()
	await _test_task_loop(false)
	await _test_task_loop(true)
	_test_old_save()
	_test_finished_save()
	for suffix in ["", ".tmp", ".bak"]:
		var path: String = game.storage.path + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	print("Fengxi revisit: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func _test_unlock() -> void:
	game._new_game(false)
	_drain_dialogue()
	_key(KEY_ESCAPE)
	_check(_revisit_row() < 0, "a new campaign cannot revisit an unvisited Fengxi")
	_key(KEY_ESCAPE)

	_start_chapter(1)
	game.slot.cleared = [0]
	game.slot.campaign.crossing = "bridge"
	game.slot.chronicle.marks.ferry_evidence = true
	game.transit.enter("fengxi_lanes")
	var data: Dictionary = game.transit.data()
	var previous: Dictionary = data.steps[data.steps.size() - 2][0]
	game.slot.journey.step = data.steps.size() - 1
	game.slot.journey.at = previous.id
	game._commit()
	_key(KEY_ESCAPE)
	_check(_revisit_row() < 0, "Fengxi revisit stays locked while the rain-lane checkpoint is active")
	_key(KEY_ESCAPE)
	if not _visit("lanes_exit"):
		return
	_check(game.field_key == "village" and game.storage.read().journey.done.lanes_done,
		"normal rain-lane exit saves the investigation that unlocks revisits")
	var main := _main_snapshot(game.storage.read())
	if not _open_revisit():
		return
	_check(game.field_key == "dawn" or game.field_key == "village", "first revisit enters an actual shore map")
	_check(game.world.phase() == "evidence", "the first revisit takes place during the evidence phase")
	_check(String(_point("world_watch").get("name", "")).contains("查验牌"), "the evidence phase shows the inspection board")
	await _capture("fengxi-evidence-shore")
	_visit("world_inn")
	await _verify_journal_tracking()
	if _visit("world_shop"):
		_check(game.mode == "shop", "the witness-phase merchant still opens the existing shop")
		_key(KEY_ESCAPE)
	_visit("world_witness")
	_visit("world_shore")
	_visit("world_lanes")
	_visit("world_stencil")
	_visit("world_crate")
	_visit("world_shore")
	_visit("world_roster")
	_check(not _has_point("world_medicine"), "having both medicine clues in the evidence phase does not close the task")
	_visit("world_inn")
	_check(not _has_point("world_seal"), "having both testimony clues in the evidence phase does not force the choice")
	_reload()
	_check(game.world.active() and game.world.phase() == "evidence", "the active early revisit survives game restart")
	if not _visit("world_return"):
		return
	_check(not game.world.active() and game.field_key == "village" and _main_snapshot(game.storage.read()) == main,
		"return from the early revisit preserves the unplayed Fengxi boss and main checkpoint")
	var tasks: Dictionary = game.storage.read().world.tasks.duplicate(true)
	game.slot.cleared = [0,1]
	_visit("inn")
	_visit("dream_intro")
	_visit("inn_exit")
	_visit("reunion")
	if not _visit("exit"):
		return
	_check(game.slot.chapter == 2 and game.storage.read().world.tasks == tasks,
		"normal chapter transition carries both unfinished investigations into the blockade")
	for point in ["pass_cart","pass_worker","pass_rope","pass_gate","pass_exit"]:
		if not _visit(point):
			return
	if _open_revisit():
		_check(game.world.phase() == "blockade" and _has_point("world_medicine"), "the blockade unlocks the early medicine follow-up")
		_visit("world_inn")
		_check(_has_point("world_seal"), "the same saved witness evidence unlocks testimony in the blockade")

func _test_task_loop(reverse: bool) -> void:
	_start_chapter(2)
	game.slot.journey.done.lanes_done = true
	game.slot.journey.done.pass_done = true
	game.slot.cleared = [0]
	_check(game._commit(), "forge fixture saves an opened world and one cleared encounter")
	var rendezvous := Vector2(210,205)
	_check(_walk_to(rendezvous), "walk away from the forge entrance before departing")
	var origin: Vector2 = game.player
	var before := _main_snapshot(game.storage.read())
	if not _open_revisit():
		return
	_check(game.world.phase() == "blockade", "chapter three unlocks blockade services in the same area")
	_check(String(_point("world_watch").get("name", "")).contains("巡卫"), "the blockade replaces the board with a guard to question")
	var opening: Dictionary = game.storage.read()
	var before_walk := walking_pixels
	var before_lines := dialogue_inputs

	if reverse:
		_visit("world_roster")
		_visit("world_lanes")
		_visit("world_crate")
		_visit("world_stencil")
		_visit("world_shore")
		_visit("world_medicine")
		_visit("world_inn")
		_visit("world_witness")
	else:
		_visit("world_inn")
		_visit("world_witness")
		_visit("world_shore")
		_visit("world_lanes")
		_visit("world_stencil")
		_visit("world_crate")
		_visit("world_shore")
		_visit("world_roster")
		_visit("world_inn")

	var surveyed: Dictionary = game.storage.read().world.tasks
	_check(surveyed.get("testimony", "") == "" and surveyed.get("medicine", "") == ("done" if reverse else ""),
		"medicine can conclude before testimony or wait until afterward")
	_reload()
	_check(game.world.active() and game.slot.world.area == "inn" and _has_point("world_seal"),
		"both testimony clues and the inn checkpoint survive reload")
	_visit("world_shop")
	_check(game.mode == "field", "the same merchant explains the blockade without opening the shop")
	if not _visit("world_seal"):
		return
	if not _check(game.mode == "choice", "the gathered testimony offers two real outcomes"):
		return
	if not reverse:
		await _capture("fengxi-testimony-choice")
	game.menu_confirm(int(reverse))
	_drain_dialogue()
	var testimony := "sealed" if reverse else "signed"
	var sealed: Dictionary = game.storage.read()
	_check(sealed.world.tasks.testimony == testimony, "testimony picks " + testimony)
	_check(sealed.gear_grants.get("frost_seal_cord", false) and sealed.loot_claims.get("quest:fengxi_testimony", false),
		"testimony grants one usable Frost seal cord through its unique reward")
	_check(not _has_point("world_seal"), "resolved testimony cannot be paid or chosen a second time")
	_visit("world_shore")
	if not reverse and not _visit("world_medicine"):
		return
	var paid: Dictionary = game.storage.read()
	_check(paid.world.tasks.medicine == "done", "the medicine task persists alongside independent testimony")
	_check(paid.gear_grants.get("dream_herb_wrap", false) and paid.loot_claims.get("quest:fengxi_medicine", false),
		"medicine grants one usable Dream herb wrap through its unique reward")
	_check(paid.silver == opening.silver, "collecting testimony and delivering medicine leaves the main purse intact")
	if _check(_has_point("world_shortcut"), "sending medicine opens a new local shortcut"):
		if not report_dir.is_empty() and DisplayServer.get_name() != "headless":
			await create_timer(0.4).timeout
		_visit("world_shortcut")
		_check(game.slot.world.area == "lanes", "the new shortcut goes from the shore to the lanes")
		var eastern_dock: Vector2 = game.player
		_check(eastern_dock.x > 1200.0, "the shortcut physically reaches the eastern warehouse beyond the main path")
		_reload()
		_check(game.slot.world.area == "lanes" and game.player.distance_to(eastern_dock) < 1.0, "restart restores the actual shortcut arrival")
		if not reverse:
			await _capture("fengxi-shortcut-arrival")
		_visit("world_shortcut")
		_check(game.slot.world.area == "shore", "the new shortcut can return to the shore")
	_reload()
	_check(not _has_point("world_medicine"), "the completed medicine task is still unavailable after reload")
	_visit("world_inn")
	_check(not _has_point("world_seal"), "the chosen testimony remains spent after reload")
	var again: Dictionary = game.storage.read()
	_check(again.silver == paid.silver and again.supplies == paid.supplies and again.materials == paid.materials
		and again.loot_claims == paid.loot_claims and again.gear_grants == paid.gear_grants,
		"repeat travel and reloading cannot duplicate rewards")
	if not (_leave_from_pause() if reverse else _visit("world_return")):
		return
	var restored: Dictionary = game.storage.read()
	_check(not game.world.active() and game.field_key == "forge" and game.player.distance_to(origin) < 1.0
		and _main_snapshot(restored) == before,
		"the same save resumes the exact interrupted route without resetting its checkpoint")
	_check(restored.world.tasks.testimony == testimony and restored.world.tasks.medicine == "done",
		"turning back to main keeps both optional quest results")
	_check(restored.world.area.is_empty() and restored.world["return"].is_empty(), "leaving a revisit clears the return ticket")
	_check(_has_point("winch") and not game.slot.cleared.has(1), "the resumed main journey can still cross the forge and fight Duan Lang")
	if not reverse:
		await _capture("fengxi-return-to-forge")
	_verify_reward_equipment(restored)
	_verify_later_battles(restored, testimony)
	var settlement_walk := walking_pixels - before_walk
	var settlement_lines := dialogue_inputs - before_lines
	print("FENGXI_BUDGET order=%s optional_walk_seconds=%.1f optional_dialogue_inputs=%d" %
		[testimony,settlement_walk / 101.0,settlement_lines])
	var before_receipt_walk := walking_pixels
	var before_receipt_lines := dialogue_inputs
	await _verify_reopened_receipts(restored, reverse)
	print("FENGXI_RECEIPTS order=%s optional_walk_seconds=%.1f optional_dialogue_inputs=%d" %
		[testimony,(walking_pixels - before_receipt_walk) / 101.0,dialogue_inputs - before_receipt_lines])

func _test_old_save() -> void:
	_start_chapter(3)
	game.slot.erase("world")
	game.slot.silver = 27
	game.slot.materials = {"clear_silk":2}
	var previous: Dictionary = game.slot.duplicate(true)
	_check(game.storage.write(previous), "a pre-expansion midgame save still writes")
	_reload()
	_check(game.field_key == "pool" and not game.world.active() and game.slot.silver == 27
		and game.slot.materials.get("clear_silk",0) == 2, "old save keeps the main room, silver and materials")
	if not _open_revisit():
		return
	var migrated: Dictionary = game.storage.read()
	_check(game.world.phase() == "blockade" and migrated.world.tasks.is_empty() and migrated.silver == 27,
		"legacy unlock infers the current stage without gifting choices or resources")
	_visit("world_inn")
	_visit("world_return")
	_check(game.field_key == "pool" and not game.world.active(), "old save restores its original checkpoint after a revisit")

func _test_finished_save() -> void:
	_start_chapter(5)
	game.slot.erase("world")
	game.slot.cleared = [0,1]
	game.slot.campaign.farewell = true
	game.slot.campaign.altar = true
	game.slot.finished = true
	if not game.storage.write(game.slot):
		_check(false, "the older completed save can be written without region data")
		return
	game._title()
	var row := _revisit_row()
	if not _check(row >= 0, "an already completed pre-expansion save can revisit Fengxi"):
		return
	_enter_fengxi(row)
	_check(game.world.active() and game.world.phase() == "reopened", "the finished save sees the reopened river")
	_check(String(_point("world_watch").get("name", "")).contains("复航"), "reopened Fengxi makes the operating dock visible")
	_visit("world_inn")
	if _visit("world_shop"):
		_check(game.mode == "shop", "the former blockade shop opens after the river is reopened")
		_key(KEY_ESCAPE)
	_reload()
	_check(game.world.active() and game.slot.world.area == "inn", "continue reloads post-ending exploration before the ending screen")
	_visit("world_return")
	_check(game.mode == "title" and not game.world.active() and game.storage.read().finished,
		"leaving a post-ending revisit preserves completion and goes back to the title")

func _verify_journal_tracking() -> void:
	_key(KEY_J)
	var tasks: Array = game.world.journal().map(func(task: Dictionary): return task.id)
	_check(game.mode == "world_journal" and tasks.has("testimony") and tasks.has("medicine"), "the regional journal lists both parallel tasks")
	await _capture("fengxi-journal-parallel-tasks")
	_key(KEY_ENTER)
	var markers: Array = game.world.trackable_points()
	_check(game.mode == "field" and markers.size() == 1 and markers[0].id == "world_witness", "tracking marks the clue in the current inn")

func _capture(name: String) -> void:
	if report_dir.is_empty() or DisplayServer.get_name() == "headless":
		return
	await process_frame
	await RenderingServer.frame_post_draw
	var frame := root.get_texture().get_image()
	_check(frame.save_png(report_dir.path_join(name + ".png")) == OK, "screenshot saved " + name)

func _verify_reward_equipment(saved: Dictionary) -> void:
	var slot := saved.duplicate(true)
	_check(Equipment.assign(slot, "frost", 1, "frost_seal_cord"), "the earned seal cord can actually be equipped")
	_check(Equipment.assign(slot, "dream", 0, "dream_herb_wrap"), "the earned herb wrap can actually be equipped")
	var frost := Equipment.modifiers(slot, "frost")
	var dream := Equipment.modifiers(slot, "dream")
	_check(frost.weakness_poise == 1 and frost.qi == -3, "the equipped seal cord increases weakness poise at a Qi cost")
	_check(dream.heal == 4 and dream.ward_armor == 2 and dream.hp == -8, "the equipped herb wrap trades health for medicine and ward strength")

func _verify_later_battles(saved: Dictionary, testimony: String) -> void:
	game.afterstory.reset()
	game.slot = game.storage.replay(4,false)
	game.slot.world.tasks = saved.world.tasks.duplicate(true)
	game.slot.world.erase("legacy_aid")
	_check(game.storage.write(game.slot), "the pre-Stage2B testimony file can be saved")
	game.slot = game.storage.read()
	_check("testimony" in game.slot.world.legacy_aid and not game.slot.world.tasks.has("testimony_handoff"),
		"migration retains old aid without fabricating a testimony delivery")
	game._enter_chapter(false)
	if not _visit("fight", 0) or not _check(game.mode == "battle", "testimony pays off in the actual palace guard fight"):
		return
	var guard: Dictionary = game.encounter.foes[0]
	var cloud: Dictionary = game.encounter.allies[0]
	_check(guard.id == "invader" and guard.poise == guard.max_poise - int(testimony == "signed")
		and cloud.id == "cloud" and cloud.ward == (testimony == "sealed"), "Palace opening reflects the saved testimony choice")
	game.slot = game.storage.replay(5,false)
	game.slot.world.tasks = saved.world.tasks.duplicate(true)
	game.slot.world.erase("legacy_aid")
	game.slot.chronicle.marks.merge({"relic":true,"lost_relic":true,"shatter_relic":true})
	game.slot.journey.done.ridge_done = true
	_check(game.storage.write(game.slot), "the pre-Stage2B medicine file can be saved")
	game.slot = game.storage.read()
	_check("medicine" in game.slot.world.legacy_aid and not game.slot.world.tasks.has("medicine_handoff"),
		"migration retains old aid without inventing a medicine delivery")
	game._enter_chapter(false)
	if not _visit("prepare") or not _check(game.mode == "battle", "medicine pays off in the actual stove-defense fight"):
		return
	var wind: Dictionary = game.encounter.allies[0]
	_check(wind.id == "wind" and wind.ward and game.encounter.quest_aid_line.contains("凤溪药单"),
		"a delivered medicine list wards Wind at the stove without a conflicting route ward")

func _verify_reopened_receipts(saved: Dictionary, reverse: bool) -> void:
	_start_chapter(5)
	game.slot.world.tasks = saved.world.tasks.duplicate(true)
	game.slot.cleared = [0,1]
	game.slot.campaign.farewell = true
	game.slot.campaign.altar = true
	game.slot.finished = true
	_check(game._commit(), "final chapter fixture keeps the completed investigation history")
	game._title()
	_enter_fengxi(_revisit_row())
	if not _check(game.world.active() and game.world.phase() == "reopened", "completed tasks return after navigation to reopened Fengxi"):
		return
	if reverse:
		_check(not _has_point("world_testimony_receipt"), "a sealed witness is not publicly named on the shore")
		_visit("world_inn")
	var receipt: String = "密封回执" if reverse else "许成"
	_check(String(_point("world_testimony_receipt").get("name", "")).contains(receipt), "the proper branch shows a different testimony follow-up")
	_key(KEY_J)
	_key(KEY_ENTER)
	var markers: Array = game.world.trackable_points()
	_check(markers.size() == 1 and markers[0].id == "world_testimony_receipt", "the journal can track the follow-up in its current area")
	var inventory: Dictionary = game.storage.read()
	_visit("world_testimony_receipt")
	_check(game.storage.read().world.tasks.get("testimony_receipt", false), "reading testimony follow-up records one final task fact")
	_check(not _has_point("world_testimony_receipt"), "a recorded testimony receipt disappears from the map")
	if reverse:
		_visit("world_shore")
	_visit("world_shortcut")
	if not _visit("world_medicine_receipt", -1, false):
		return
	if not reverse:
		await _capture("fengxi-reopened-receipts")
	_drain_dialogue()
	_check(game.storage.read().world.tasks.get("medicine_receipt", false), "the two successful medicine deliveries are confirmed in the east warehouse")
	_reload()
	_check(not _has_point("world_medicine_receipt"), "confirmed medicine receipts do not reappear after saving")
	_check(game.world.journal().all(func(task): return task.complete and not task.awaiting_receipt), "both regional journal cards are now complete")
	var stored: Dictionary = game.storage.read()
	_check(stored.loot_claims == inventory.loot_claims and stored.silver == inventory.silver, "following up does not pay either task reward again")
	game._title()
	var tidegate: Array = game.menu_items()[5]
	_check(not tidegate[1], "Tidegate cannot replace an unfinished post-ending revisit")

func _start_chapter(chapter: int) -> void:
	game.afterstory.reset()
	game.slot = game.storage.replay(chapter,false)
	game.slot.intro_seen = true
	game._commit()
	game._enter_chapter(false)

func _main_snapshot(value: Dictionary) -> Dictionary:
	var keys := ["chapter", "finished", "cleared", "hall", "campaign", "chronicle", "journey", "merit", "intro_seen"]
	var result := {}
	for key in keys:
		result[key] = value.get(key)
	return result.duplicate(true)

func _open_revisit() -> bool:
	_key(KEY_ESCAPE)
	var row := _revisit_row()
	if not _check(game.mode == "pause" and row >= 0, "pause exposes the current save's Fengxi revisit"):
		return false
	_enter_fengxi(row)
	return _check(game.mode == "field" and game.world.active(), "pause selection opens the same-save visit")

func _revisit_row() -> int:
	return game.menu_items().find_custom(func(row: Array): return row[0] in ["回访凤溪", "江湖行路"] and row[1])

func _enter_fengxi(row: int) -> void:
	if row < 0:
		return
	var steps := posmod(row - int(game.selected), game.menu_items().size())
	for i in steps:
		_key(KEY_DOWN)
	_key(KEY_ENTER)
	if game.mode == "world_map":
		var selection: int = game.world.destinations().find_custom(func(place: Dictionary): return place.id == "fengxi")
		if selection >= 0:
			game.menu_confirm(selection)
	_drain_dialogue()

func _leave_from_pause() -> bool:
	_key(KEY_ESCAPE)
	var row: int = game.menu_items().find_custom(func(item: Array): return "返回主线" in String(item[0]) and item[1])
	if not _check(game.mode == "pause" and row >= 0, "the regional pause menu offers a return to main"):
		return false
	for i in row:
		_key(KEY_DOWN)
	_key(KEY_ENTER)
	return _check(game.mode == "field" and not game.world.active(), "return action resumes the current main game")

func _reload() -> void:
	if game.mode == "field":
		_key(KEY_ESCAPE)
		for i in 5:
			_key(KEY_DOWN)
		_key(KEY_ENTER)
	else:
		game._title()
	_check(game.mode == "title", "restart returns to the title through the replayable save")
	_key(KEY_ENTER)
	_drain_dialogue()

func _has_point(id: String) -> bool:
	return not _point(id).is_empty()

func _point(id: String, index: int = -1) -> Dictionary:
	for spot in game.field_points():
		if spot.id == id and (index < 0 or spot.get("index", -1) == index):
			return spot
	return {}

func _visit(id: String, index: int = -1, onward: bool = true) -> bool:
	var spot := _point(id, index)
	if not _check(not spot.is_empty() and _walk_to(spot.pos), "ordinary collision route reaches " + id):
		return false
	if not _check(game.nearest().get("id") == id, "interaction priority selects " + id):
		return false
	_key(KEY_E)
	if onward:
		_drain_dialogue()
	return true

func _walk_to(destination: Vector2) -> bool:
	var start := Vector2i(game.player.round())
	var from := {start:start}
	var search: Array[Vector2i] = [start]
	var index := 0
	while index < search.size():
		var node := search[index]
		index += 1
		if Vector2(node).distance_to(destination) < 7.0:
			var path: Array[Vector2i] = []
			while node != start:
				path.push_front(node)
				node = from[node]
			for step in path:
				var delta := Vector2(step) - Vector2(game.player)
				game.walk(delta.normalized(), delta.length() / 101.0)
				walking_pixels += delta.length()
			return game.player.distance_to(destination) < 8.0
		for direction in DIRECTIONS:
			var next: Vector2i = node + direction
			if not from.has(next) and game.passable(Vector2(next)):
				from[next] = node
				search.append(next)
	return false

func _key(key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.pressed = true
	game._unhandled_input(event)

func _drain_dialogue() -> void:
	for i in 24:
		if game.mode != "dialogue":
			return
		_key(KEY_ENTER)
		dialogue_inputs += 1
	_check(false, "dialogue finishes within 24 input steps")

func _check(value: bool, caption: String) -> bool:
	checks += 1
	print(("PASS " if value else "FAIL ") + caption)
	if not value:
		failures += 1
	return value
