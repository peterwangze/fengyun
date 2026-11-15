extends RefCounted

var a
var g: Node2D
var extended: bool
var branch := "west"
var evidence := {}
var traversed: Array[String] = []
var route_distance := 0.0
var evacuation_battles: Array[String] = []
var old_fire_checkpoint := {}
var old_summit_checkpoint := {}

func _init(acceptance: SceneTree, region_quests: bool) -> void:
	a = acceptance
	g = a.game
	extended = region_quests
	if extended:
		branch = {"interrupt":"rearguard", "retaliate":"medicine", "exploit":"west"}.get(a.build_route,"west")
		for option in OS.get_cmdline_user_args():
			if option in ["--stage3-evacuation=medicine","--stage3-evacuation=rearguard"]:
				branch = option.get_slice("=",1)

func prepare_palace_fire() -> void:
	if not extended or a.build_route.is_empty() or not _open_region("palace"):
		return
	_check(g.world.phase() == "transfer", "the rescued Palace uses the transfer phase before the fire")
	if a.build_route == "retaliate":
		_path(["world_palace_to_cells","world_palace_side_hinge","world_palace_from_cells"])
	_path(["world_palace_to_main_corridor","world_palace_servant_plan","world_palace_ying_plan"])
	if a.build_route == "retaliate":
		_path(["world_palace_side_wedge","world_palace_side"])
	if a.build_route != "exploit":
		_visit("world_palace_dispatch_record")
		_path(["world_palace_to_laneway","world_palace_river_decree"])
	else:
		_visit("world_palace_from_main_corridor")
	await a._capture("stage3-palace-prefire")
	_leave_region()

func evacuate_palace() -> bool:
	if not _visit("tearoom"):
		return false
	if extended and a.stage2b_skip and branch == "west":
		old_fire_checkpoint = g.storage.read()
		old_fire_checkpoint.chronicle.marks.fire_signal = true
		old_fire_checkpoint.erase("world")
	await a._capture("2-tearoom-fire")
	if not _visit("fire_signal"):
		return false
	if not _check(g.world.active() and g.slot.world.area == "palace_tea" and g.world.phase() == "aftermath",
		"the fire puts players in the actual Palace aftermath without a mandatory optional task"):
		return false
	_check(not _has("world_palace_from_main_corridor"), "fire makes the old tea corridor unavailable")
	_check(not _has("evacuated"), "the court fallback is still ahead")
	a._key(KEY_ESCAPE)
	_check(g.menu_items().all(func(row: Array): return row[0] not in ["返回主线", "江湖行路"] or not row[1]),
		"a burning corridor prevents backtracking to an unsafe origin")
	a._key(KEY_ESCAPE)
	if extended and not a.build_route.is_empty() and _has("world_palace_survival"):
		if not _visit("world_palace_survival"):
			return false
		if _check(g.mode == "choice", "Palace preparation offers rescue and witness priorities"):
			await a._capture("stage3-palace-priority")
			a._choose(int(a.build_route != "retaliate"))
	elif not extended or a.build_route.is_empty():
		_check(not _has("world_palace_survival"), "skipping preparatory conversations does not unlock the voluntary rescue objective")
	if extended and not a.build_route.is_empty():
		_check(g.slot.world.tasks.get("palace_survival", "") == ("rescue" if a.build_route == "retaliate" else "witness"),
			"the chosen fire priority persists")
	await a._capture("stage3-palace-fire-escape")
	if extended and a.build_route == "retaliate":
		if not _visit("world_palace_side_door"):
			return false
		_check(g.slot.world.area == "palace_court", "the prepared side door is a usable fire escape")
		_path(["world_palace_side_door","world_palace_side_door"])
	else:
		if not _path(["world_palace_to_laneway"]):
			return false
		if _has("world_palace_river_decree") and not _visit("world_palace_river_decree"):
			return false
		if not _visit("world_palace_to_court"):
			return false
	a._resume()
	_check(g.world.active() and g.slot.world.area == "palace_court", "reloading during the fire restores the safe outer court")
	_check(not _has("world_palace_to_main_corridor"), "the blocked corridor stays blocked after reload")
	if extended and a.build_route.is_empty():
		if not _leave_region():
			return false
		_visit("exit")
		_check(g.field_key == "palace" and g.slot.chapter == 4 and not g.chronicle.has("evacuated"),
			"safe recall does not bypass the Palace evacuation gate")
		if not _visit("world_palace_visit"):
			return false
		_check(g.world.active() and g.slot.world.area == "palace_court", "main Palace can reenter the safe court")
	if extended and a.build_route == "retaliate" and _has("world_palace_side_receipt"):
		_visit("world_palace_side_receipt")
	if not g.slot.world.tasks.get("palace_dispatch_record", false):
		if _has("evacuated"):
			_visit("evacuated")
		_check(g.world.active() and not g.chronicle.has("evacuated"), "the main evacuation stays gated until the second record")
		if not _visit("world_palace_dispatch_record"):
			return false
	if _has("world_palace_survival_receipt"):
		_visit("world_palace_survival_receipt")
		var resident := "world_palace_survivor_rescue" if a.build_route == "retaliate" else "world_palace_survivor_witness"
		_check(_has(resident), "the chosen survivors take up different positions in the outer court")
	await a._capture("stage3-palace-records")
	if not _visit("evacuated"):
		return false
	var saved: Dictionary = g.storage.read()
	_check(saved.world.tasks.get("palace_dispatch_record", false) and saved.world.tasks.get("palace_river_decree", false),
		"the main evacuation saved both physical documents")
	_check(saved.chronicle.marks.get("evacuated", false), "main evacuation saves the cross-chapter unlock")
	return _check(not g.world.active() and g.field_key == "palace", "the safety route resumes the Palace main story")

func trace_mountain_wall() -> void:
	if _visit("side_hidden_ledger"):
		_check(g.storage.read().chronicle.quests.get("hidden_ledger", "") == "seeking",
			"the prison rubbing compares against the actual waterway en route to the mountain")
		await a._capture("stage3-tracing-wall")

func verify_ledger_path() -> void:
	if not extended or not _open_region("mountain"):
		return
	var trade: bool = g.slot.chronicle.quests.get("hidden_ledger", "") == "done_trade"
	_check(_has("road_ledger_steps") == trade, "only the mapped iron plate opens the cave-to-steps shortcut")
	if trade and _visit("road_ledger_steps"):
		_check(g.slot.world.area == "mountain_steps" and g.player.distance_to(Vector2(1165,230)) < 1.0,
			"the shortcut reaches the actual eastern stairs")
		a._resume()
		_check(g.slot.world.area == "mountain_steps" and g.player.distance_to(Vector2(1165,230)) < 1.0,
			"reloading keeps the shortcut landing")
		_visit("road_ledger_cavern")
		_check(g.slot.world.area == "mountain_cavern" and g.player.distance_to(Vector2(507,205)) < 1.0,
			"the secret route also traverses uphill")
	_leave_region()

func prepare_mountain() -> bool:
	_check(not g.world.mountain_ready() and not g.slot.campaign.farewell,
		"the altar road still needs a chosen evacuation after the blood rite")
	var start: float = a.total_distance
	if a.build_route.is_empty() and branch == "west":
		if not _visit("mountain_preparations") or not _check(g.world.active() and g.slot.world.area == "mountain_lodge",
			"the bedside guide sends a new player directly to the lodge evacuation region"):
			return false
	elif not _open_region("mountain"):
		return false
	var phases: Array = ["fractured", "lanterns"]
	_check(g.world.phase() in phases, "the broken Dragon Vein unlocks regional evacuation")
	var before: Dictionary = g.slot.duplicate(true)
	match branch:
		"west":
			_prepare_west()
		"medicine":
			await _prepare_medicine()
		"rearguard":
			await _prepare_rearguard()
	route_distance = a.total_distance - start
	var saved: Dictionary = g.storage.read()
	var key := "mountain_" + branch
	_check(saved.world.tasks.get(key, "") == "done", "the chosen evacuation persists before climbing")
	_check(saved.silver == before.silver, "all evacuations can be undertaken without paying silver")
	if branch == "west":
		_check(saved.tonics == before.tonics and saved.supplies == before.supplies,
			"the western settlement needs no consumables")
	await a._capture("stage3-mountain-" + branch)
	if not _leave_region():
		return false
	_check(g.field_key == "lodge" and _has("bedside"), "completing a free evacuation restores a usable altar approach")
	return g.field_key == "lodge"

func _prepare_west() -> void:
	if g.slot.world.area == "mountain_cavern" and not _visit("world_mountain_hearth"):
		return
	if not _visit("world_mountain_steps"):
		return
	_check(_has("world_mountain_altar_shut") and not _has("world_mountain_altar"), "the regional stone steps start barred")
	if not _path(["world_mountain_west_roll","world_mountain_west_reed","world_mountain_west_luo",
		"world_mountain_hearth","world_mountain_west_settle"]):
		return
	_check(not _has("world_mountain_west_settle"), "west settlement cannot award its reward twice")
	if extended and not a.build_route.is_empty() and _visit("world_mountain_steps"):
		if _visit("world_mountain_west_shortcut"):
			_check(g.slot.world.area == "mountain_altar", "the west settlement opens a real shortcut to the altar perimeter")
			_visit("world_mountain_west_shortcut")

func _prepare_medicine() -> void:
	if not _path(["world_mountain_hearth","world_mountain_medicine_custodian","world_mountain_medicine_pack"]):
		return
	if not await _evacuation_encounter("world_mountain_medicine_escort", "medicine_handoff"):
		return
	_path(["world_mountain_lodge","world_mountain_medicine_confirm"])
	_check(not _has("world_mountain_medicine_confirm"), "the lodge uses one-time medicine delivery")

func _prepare_rearguard() -> void:
	if not _path(["world_mountain_rearguard_dispatch","world_mountain_hearth","world_mountain_steps","world_mountain_rearguard_marks"]):
		return
	if not await _evacuation_encounter("world_mountain_rearguard_chase", "register_handoff"):
		return
	_visit("world_mountain_rearguard_confirm")
	_check(not _has("world_mountain_rearguard_confirm"), "the eastern vanguard settles once")

func _evacuation_encounter(id: String, handoff: String) -> bool:
	var bypass: bool = g.slot.world.tasks.get(handoff,false)
	if not _visit(id):
		return false
	if bypass:
		return _check(g.mode == "field", "completed " + handoff + " provides a safe physical route")
	if not _check(g.mode == "battle" and g.world.battle_point.get("id","") == id,
		"the evacuation has a repeatable battle when no prior handoff provides a bypass"):
		return false
	if not await a._play_battle():
		return false
	evacuation_battles.append(id)
	a._key(KEY_ENTER)
	a._drain_dialogue()
	return _check(not _has(id), "the evacuation battle does not reappear after a win")

func verify_tyrant_aid() -> void:
	var battle: RefCounted = g.encounter
	var wind: Array = battle.allies.filter(func(unit: Dictionary): return unit.id == "wind")
	var wind_ward: bool = not wind.is_empty() and wind[0].ward
	_check(wind_ward == (branch == "medicine"), "only medicine evacuation wards Wind in these three routes")
	_check(g.chronicle.has("summit_west_slope") == (branch == "west"), "the settlement opens the corresponding west approach")
	_check(g.chronicle.has("summit_safe_rear") == (branch == "rearguard"), "the rearguard opens the corresponding safe ascent")
	evidence.opening = {"bond":battle.bond, "foe_poise":battle.foes[0].poise,"wind_ward":wind_ward,
		"aid":battle.quest_aid_line}
	if extended and a.stage2b_skip and branch == "west":
		old_summit_checkpoint = g.storage.read()
		old_summit_checkpoint.erase("world")

func dawn_return() -> void:
	var key := "mountain_" + branch
	_check(g.slot.world.finale == [key], "only rescues finished before the boss are snapshotted into the finale")
	var speaker: String = {"west":"西坡山民","medicine":"受伤樵夫","rearguard":"外哨传令弟子"}[branch]
	_check(g.world.finale_rows().any(func(line: Array): return line[0] == speaker),
		"the live reunion identifies the people from this evacuation")
	if _visit("dawn_stage3"):
		_check(g.storage.read().world.tasks.get("dawn_relief_witnessed",false), "Fengxi keeps the reunion checkpoint")
		await a._capture("stage3-fengxi-return")

func finish() -> void:
	var save: Dictionary = g.storage.read()
	var facts: Dictionary = save.world.tasks
	if extended and a.stage2b_skip:
		_check(save.shop_stock.is_empty() and save.gear_levels.is_empty()
			and save.get("afterstory",{}).get("shop_stock",{}).is_empty(),
			"the completed no-purchase run never bought or forged anything in either account")
	var scoped := {}
	for key in facts:
		if key.begins_with("mountain_") or key.begins_with("palace_"):
			scoped[key] = facts[key]
	for alternative in ["west", "medicine", "rearguard"]:
		_check((facts.get("mountain_" + alternative, "") == "done") == (alternative == branch),
			"ending save honours only the chosen mountain preparation " + alternative)
	_check(facts.get("palace_river_decree", false) and facts.get("palace_dispatch_record", false),
		"the two free Palace records survive to the end")
	print("STAGE3 " + JSON.stringify({"build":a.build_route,"branch":branch,"facts":scoped,"travel":traversed,
		"opening":evidence,"evacuation_battles":evacuation_battles,"evacuation_walk_seconds":snappedf(route_distance/101.0,0.1)}))

func verify_migrated_checkpoints() -> void:
	if old_fire_checkpoint.is_empty() or old_summit_checkpoint.is_empty():
		return
	if _check(g.storage.write(old_fire_checkpoint), "the legacy fire checkpoint remains valid"):
		g._title()
		a._key(KEY_ENTER)
		a._drain_dialogue()
		_check(g.world.active() and g.slot.world.area == "palace_tea" and g.world.fire_pending(),
			"upgrading a save between the old fire and evacuation opens the new escape")
		_check(_has("world_palace_to_laneway") and not _has("world_palace_from_main_corridor"),
			"the migrated burning corridor has a viable fallback")
	if _check(g.storage.write(old_summit_checkpoint), "the legacy summit checkpoint remains valid"):
		g._title()
		a._key(KEY_ENTER)
		_check(g.mode == "field" and g.field_key == "peak" and g.slot.campaign.farewell
			and not g.world.mountain_gate_required() and not g.world.mountain_ready(),
			"upgrading a save past the farewell keeps existing summit progress")
	print("STAGE3_MIGRATION existing fire and summit checkpoints exercised")

func _open_region(id: String) -> bool:
	a._key(KEY_ESCAPE)
	var row: int = g.menu_items().find_custom(func(item: Array): return item[0] == "江湖行路" and item[1])
	if not _check(row >= 0, "the normal pause menu offers " + id):
		return false
	a._select_menu_row(row)
	if not _check(g.mode == "world_map", "the map picker opens"):
		return false
	var destinations: Array = g.world.destinations()
	row = destinations.find_custom(func(place: Dictionary): return place.id == id)
	if not _check(row >= 0, "the map picker lists " + id):
		return false
	a._select_menu_row(row)
	a._drain_dialogue()
	return _check(g.world.active() and g.world.region() == id and g.mode == "field", "arrived at " + id)

func _leave_region() -> bool:
	a._key(KEY_ESCAPE)
	var row: int = g.menu_items().find_custom(func(item: Array): return item[0] == "返回主线" and item[1])
	if not _check(row >= 0, "leaving an explored region returns to the true campaign"):
		return false
	a._select_menu_row(row)
	a._drain_dialogue()
	return _check(not g.world.active() and g.mode == "field", "regional checkout preserves a playable main field")

func _path(ids: Array) -> bool:
	for id in ids:
		if not _visit(id):
			return false
	return true

func _visit(id: String) -> bool:
	if not a._do_point(id):
		return false
	traversed.append(id)
	return true

func _has(id: String) -> bool:
	return g.field_points().any(func(point: Dictionary): return point.id == id)

func _check(value: bool, message: String) -> bool:
	return a._check(value, "STAGE3 " + message)
