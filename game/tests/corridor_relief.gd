extends "res://tests/acceptance.gd"

const PROFILE := "qa_corridor_relief"
const Relief = preload("res://scripts/corridor_relief.gd")

func _run() -> void:
	if "--profile=" + PROFILE not in OS.get_cmdline_user_args():
		push_error("Run with -- --profile=" + PROFILE)
		quit(1)
		return
	game = MAIN.instantiate()
	root.add_child(game)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--reports="):
			report_dir = arg.trim_prefix("--reports=")
	visual = not report_dir.is_empty() and DisplayServer.get_name() != "headless"
	await _relief("sluice", true)
	await _relief("litter", false)
	await _late_relief()
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(game.storage.path + suffix):
			DirAccess.remove_absolute(game.storage.path + suffix)
	print("North Sluice corridor: %d failures; walked %.0f px" % [failures,total_distance])
	quit(1 if failures else 0)

func _relief(route: String, retry: bool) -> void:
	var starting_distance := total_distance
	var early: Dictionary = game.storage.replay(3,false)
	early.chronicle.marks.pool_intro = true
	if not _load_slot(early):
		return
	game.world.from_main("valley")
	if not _do_point("world_relief_order"):
		return
	_check(_saved("relief_order") == true and not _has_relief_point("world_relief_order"),
		"the actual Valley order is stored once during the original narrative")
	_key(KEY_R)
	var rows: Array = game.world.corridor_journal()
	var journal_index := rows.find_custom(func(row: Dictionary): return row.id == "relief")
	if not _check(game.mode == "corridor_journal" and journal_index >= 0
		and rows[journal_index].next.begins_with("等") and rows[journal_index].track,
		"chapter-three order stays selectable while the West Sluice is still closed"):
		return
	_select_menu_row(journal_index)
	_check(game.mode == "field" and game.world.tracked == "relief",
		"tracking a waiting order closes the journal and keeps it tracked")

	var final_arc: Dictionary = game.storage.replay(5,false)
	final_arc.merit = 30
	final_arc.tonics = 9
	final_arc.cleared = [0]
	final_arc.campaign.altar = true
	final_arc.campaign.farewell = true
	final_arc.chronicle.marks.blood_rite = true
	final_arc.world.tasks.relief_order = _saved("relief_order")
	if not _load_slot(final_arc):
		return
	game.world.from_main("palace")
	if not _visit_relief(["world_palace_to_west","world_relief_rope","road_palace_mountain"]):
		return
	_check(not _has_relief_point("world_relief_route"),"west report alone cannot decide the crossing")
	if not _visit_relief(["world_relief_crossing","world_relief_route"]):
		return
	await _capture("relief-" + route + "-route")
	_choose(int(route == "litter"))
	_check(_saved("corridor_relief_route") == route and not _has_relief_point("road_relief_canal_refuge"),
		"the chosen procedure persists and its route needs the raid")
	if not _do_point("world_relief_raid") or not _check(game.mode == "battle","the crossing starts the promised real raid"):
		return
	var opponents: Array = game.encounter.foes.map(func(foe: Dictionary): return foe.id)
	var expected := ["invader","gate_guard"] if route == "sluice" else ["elite","shade"]
	_check(opponents == expected,"the two ways use different pursuers")
	if retry:
		var before: Dictionary = game.storage.read()
		_key(KEY_5)
		_key(KEY_ENTER)
		for turn in 160:
			if game.mode != "battle":
				break
			_key(KEY_4)
		if not _check(game.mode == "defeat","a stalled defense reaches defeat"):
			return
		_select_menu_row(1)
		_check(game.mode == "field" and game.player.distance_to(Vector2(788,221)) < 1.0
			and game.storage.read() == before,"retreat keeps the pre-raid checkpoint and undelivered medicine")
		if not _do_point("world_relief_raid"):
			return
	if not await _play_battle():
		return
	_key(KEY_ENTER)
	_check(_saved("corridor_relief_raid") == true and _saved("corridor_relief_handoff") == null,
		"winning clears only the raid; the player must take the medicine through")
	var way := ["road_mountain_palace","road_relief_west_ridge"] if route == "sluice" else ["road_relief_canal_refuge"]
	if not _visit_relief(way):
		return
	_check(_saved("relief_arrived") == true and game.passable(game.player),
		"the physical branch passage records safe arrival")
	await _capture("relief-" + route + "-arrival")
	if not _do_point("world_relief_handoff"):
		return
	_check(_saved("corridor_relief_handoff") == true and not _has_relief_point("world_relief_revisit"),
		"the recipient is visited before the task may give a post-ending report")
	_resume_checkpoint()
	_check(_saved("corridor_relief_route") == route and _saved("corridor_relief_handoff") == true
		and game.world.active(),"branch, delivery and exact regional checkpoint survive Continue")
	var reverse := ["road_relief_ridge_west"] if route == "sluice" else ["road_relief_refuge_canal","road_mountain_palace"]
	if not _visit_relief(reverse):
		return
	_check(game.slot.world.area == "palace_west","the chosen passage has a traversal back towards its start")
	if not _check(game.world.leave() and game.field_key == "peak","leaving the detour restores the original battle site"):
		return
	if not _check(_reach("fight",1),"walk to the genuine final boss"):
		return
	_key(KEY_E)
	_drain_dialogue()
	if not _check(game.mode == "battle","the final boss uses the normal campaign action"):
		return
	var wind: Dictionary = game.encounter.allies.filter(func(unit: Dictionary): return unit.id == "wind").front()
	_check(game.encounter.quest_aid_line.contains(Relief.TASK.variants[route].aid.line)
		and (game.encounter.bond >= 1 if route == "sluice" else wind.ward),
		"the actual final battle opens with the corresponding recorded player action")
	if not await _play_battle():
		return
	_key(KEY_ENTER)
	var ending: Dictionary = game.storage.read()
	_check(ending.world.corridor_finale.get("relief","") == route,
		"the win books the correct form of aid in the persisted finale snapshot")
	if not _visit_relief(["exit","dawn_lamp","dawn_exit"]):
		return
	if not _check(game.mode == "ending" and game.storage.read().finished,
			"the real Fengxi epilogue finishes and permits revisiting"):
		return
	_check(game.world.corridor_ending().any(func(row: Array): return row[1] == Relief.TASK.variants[route].ending),
		"the ending uses the same recorded outcome as the battle")
	game._title()
	game.world.from_main("palace")
	if not _do_point("world_palace_to_west"):
		return
	var onward := ["road_relief_west_ridge"] if route == "sluice" else ["road_palace_mountain","road_relief_canal_refuge"]
	if not _visit_relief(onward) or not _do_point("world_relief_revisit") or not _visit_relief(reverse):
		return
	if not _do_point("world_relief_receipt"):
		return
	_check(_saved("corridor_relief_receipt") == true and _has_relief_point("world_relief_register_closed")
		and not _has_relief_point("world_relief_receipt"),"the West Sluice accepts one ending receipt and retains its own local account")
	await _capture("relief-" + route + "-receipt")
	print("NORTH SLUICE route=%s foes=%s saved_at_victory=true receipt=true walked=%.0f" % [
		route,"/".join(opponents),total_distance - starting_distance])

func _late_relief() -> void:
	var previous: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://tests/fixtures/stage4-v320-public.json"))
	if not _load_slot(previous):
		return
	game._title()
	game.world.from_main("valley")
	if not _do_point("world_relief_order"):
		return
	game.world.from_main("palace")
	if not _visit_relief(["world_palace_to_west","world_relief_rope","road_palace_mountain",
			"world_relief_crossing","world_relief_route"]):
		return
	_choose(1)
	if not _do_point("world_relief_raid") or not await _play_battle():
		return
	_key(KEY_ENTER)
	if not _visit_relief(["road_relief_canal_refuge","world_relief_handoff","world_relief_revisit",
			"road_relief_refuge_canal","road_mountain_palace","world_relief_receipt"]):
		return
	_check(_saved("corridor_relief_receipt") == true and game.world.corridor_ending().is_empty(),
		"an actual pre-corridor completed save permits late relief without rewriting its historical finale")
	print("NORTH SLUICE legacy finish: actual battle, receipt and original ending preserved")

func _load_slot(slot: Dictionary) -> bool:
	slot.intro_seen = true
	if not _check(game.storage.write(slot),"write concrete route fixture via normal save validation"):
		return false
	_resume_checkpoint()
	return true

func _resume_checkpoint() -> void:
	game._title()
	_key(KEY_ENTER)
	_drain_dialogue()

func _visit_relief(ids: Array) -> bool:
	for id in ids:
		if not _do_point(id):
			return false
	return true

func _has_relief_point(id: String) -> bool:
	return game.field_points().any(func(point: Dictionary): return point.id == id)

func _saved(key: String) -> Variant:
	return game.storage.read().get("world",{}).get("tasks",{}).get(key)
