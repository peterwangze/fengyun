extends RefCounted

const Corridors = preload("res://scripts/world_corridors.gd")

var a: SceneTree
var g: Node2D
var routes: Dictionary
var late_river: bool

func _init(acceptance: SceneTree) -> void:
	a = acceptance
	g = a.game
	routes = {
		"interrupt":{"river":"public","timber":"brace","relief":"sluice"},
		"retaliate":{"river":"covered","timber":"ring","relief":"litter"},
		"exploit":{"river":"covered","timber":"ring","relief":"sluice"},
	}.get(a.build_route, {})
	late_river = a.build_route == "exploit"

func prepare(chapter: int) -> bool:
	if routes.is_empty():
		return true
	match chapter:
		2:
			if not _region("fengxi") or not _path(["world_river_manifest","world_river_shore_to_elm",
					"world_river_inspection","world_river_route"]):
				return false
			a._choose(int(routes.river == "covered"))
			if not a._do_point("world_river_prepare_" + routes.river) or not _leave():
				return false
			if not _region("swordhall") or not _path(["world_sword_hamlet","world_timber_order"]):
				return false
			return _leave()
		3:
			if not _region("swordhall") or not _path(["world_sword_hamlet","world_timber_hamlet_hub",
					"world_timber_wheel","world_timber_choice"]):
				return false
			a._choose(int(routes.timber == "ring"))
			return _leave()
	return true

func valley_visit() -> bool:
	if routes.is_empty():
		return true
	if not _region("valley") or not a._do_point("world_relief_order"):
		return false
	a._key(KEY_R)
	if not a._check(g.mode == "corridor_journal", "R opens the three journeys from the field"):
		return false
	var rows: Array = g.world.corridor_journal()
	var relief := rows.find_custom(func(row: Dictionary): return row.id == "relief")
	if not a._check(rows.size() == 3 and relief >= 0, "all three journeys coexist in the same save"):
		return false
	a._select_menu_row(relief)
	var facts: Dictionary = g.storage.read().world.tasks
	return a._check(g.mode == "field" and g.world.tracked == "relief" and facts.get("river_route") == routes.river
		and facts.get("timber_route") == routes.timber and facts.get("relief_order") == true,
		"parallel choices survive travel and the chosen journal entry returns to the field") and _leave()

func before_finale() -> bool:
	if routes.is_empty():
		return true
	if not late_river and (not _deliver_river() or not _leave()):
		return false
	if not _region("swordhall") or not _path(["world_sword_hamlet","world_timber_hamlet_hub"]):
		return false
	if routes.timber == "ring":
		if _has("world_timber_ring_watch"):
			if not a._do_point("world_timber_ring_watch"):
				return false
		elif not await _battle("world_timber_ring_fight"):
			return false
	if not _path(["world_timber_hub_" + routes.timber,"world_timber_" + routes.timber + "_delivery"]) or not _leave():
		return false
	if not _region("palace") or not _path(["world_palace_to_west","world_relief_rope","road_palace_mountain",
			"world_relief_crossing","world_relief_route"]):
		return false
	a._choose(int(routes.relief == "litter"))
	if not await _battle("world_relief_raid"):
		return false
	if not _path(_relief_inbound(true) + ["world_relief_handoff"]) or not _leave():
		return false
	var slot: Dictionary = g.storage.read()
	return a._check(g.field_key == "lodge" and Corridors.deliveries(slot) == _timely()
		and slot.world.corridor_finale.is_empty(), "handed-off aid is ready and the main ascent resumes from the lodge")

func finale_opening() -> void:
	var aids: Array = Corridors.opening(g.slot)
	var bond: int = (0 if g.slot.chronicle.quests.get("swordstory") == "done_guard" else int(a.quests))
	var boss: Dictionary = g.encounter.foes[0]
	var poise: int = boss.max_poise - (2 if g.slot.chronicle.quests.get("swordstory") == "done_guard" else 0)
	for aid in aids:
		bond += int(aid.get("bond", 0))
		poise -= int(aid.get("poise", 0))
		var unit: String = aid.get("ward", "")
		if not unit.is_empty():
			a._check(g.encounter.allies.any(func(ally: Dictionary): return ally.id == unit and ally.ward),
				"the recruited escort actually shields " + unit)
		a._check(g.encounter.quest_aid_line.contains(aid.line), "each timely contribution is surfaced in the battle")
	if not aids.is_empty():
		a._check(g.encounter.bond == mini(4, bond) and boss.poise == maxi(1, poise),
			"the final encounter receives the concrete bond and stance changes")
	print("CORRIDORS opening=",_timely()," bond=",g.encounter.bond," poise=",boss.poise," notes=",g.encounter.quest_aid_line)

func ending() -> void:
	var expected := _timely()
	var report: Array = g.world.corridor_ending()
	a._check(g.storage.read().world.corridor_finale == expected and report.size() == expected.size(),
		"the real final victory seals only timely deliveries")
	for id in expected:
		var line: String = Corridors.TASKS[id].variants[expected[id]].ending
		a._check(report.any(func(row: Array): return row[1] == line) and g.lines.any(func(row: Array): return row[1] == line),
			"the selected journey outcome appears in the actual ending dialogue")

func after_tide() -> bool:
	if routes.is_empty():
		return a._check(g.storage.read().world.corridor_finale.is_empty(), "no-purchase route may skip all three journeys")
	if late_river and (not _deliver_river() or not _leave()):
		return false
	if not a._do_point("tide_visit") or not _path(["world_river_tide_to_elm","world_river_elm_to_tide","world_tide_to_canal"]):
		return false
	var archive := ["world_tide_canal_to_fort","world_river_revisit_public","world_tide_fort_to_canal"] if routes.river == "public" \
		else ["world_river_revisit_covered"]
	if not _path(archive + ["world_tide_canal_to_ford","world_river_tide_receipt"]) or not _leave():
		return false
	if not _region("swordhall") or not _path(["world_sword_hamlet","world_timber_hamlet_hub",
			"world_timber_hub_" + routes.timber,"world_timber_" + routes.timber + "_revisit",
			"world_timber_" + routes.timber + "_hub","world_timber_hub_receipt"]) or not _leave():
		return false
	var return_road := ["road_relief_ridge_west"] if routes.relief == "sluice" else ["road_relief_refuge_canal","road_mountain_palace"]
	if not _region("palace") or not _path(["world_palace_to_west"] + _relief_inbound(false)
			+ ["world_relief_revisit"] + return_road + ["world_relief_receipt"]) or not _leave():
		return false
	var slot: Dictionary = g.storage.read()
	var receipts := ["river_tide_receipt","timber_receipt","corridor_relief_receipt"]
	print("CORRIDORS revisited=", routes," ending=",slot.world.corridor_finale," Tide=",slot.afterstory.resolution)
	return a._check(receipts.all(func(id: String): return slot.world.tasks.get(id) == true)
		and slot.world.corridor_finale == _timely() and not slot.afterstory.resolution.is_empty(),
		"all three signed receipts and the Tidegate settlement persist, with no late revision to the finale")

func _timely() -> Dictionary:
	var result := routes.duplicate()
	if late_river:
		result.erase("river")
	return result

func _deliver_river() -> bool:
	if not _region("fengxi"):
		return false
	a._key(KEY_R)
	var rows: Array = g.world.corridor_journal()
	a._select_menu_row(rows.find_custom(func(row: Dictionary): return row.id == "river"))
	var canoe := "world_river_" + String(routes.river) + "_to_palace"
	if not _tracks("world_river_shore_to_elm") or not a._do_point("world_river_shore_to_elm"):
		return false
	if not _tracks(canoe) or not a._do_point(canoe):
		return false
	if routes.river == "covered":
		if not _tracks("world_palace_reeds_to_quay") or not a._do_point("world_palace_reeds_to_quay"):
			return false
	return a._do_point("world_river_handoff")

func _tracks(id: String) -> bool:
	return a._check(g.world.trackable_points().any(func(point: Dictionary): return point.id == id),
		"the journal points to the next usable crossing: " + id)

func _relief_inbound(from_canal: bool) -> Array:
	if routes.relief == "sluice":
		return ["road_mountain_palace","road_relief_west_ridge"] if from_canal else ["road_relief_west_ridge"]
	return ["road_relief_canal_refuge"] if from_canal else ["road_palace_mountain","road_relief_canal_refuge"]

func _battle(id: String) -> bool:
	if not a._do_point(id) or not a._check(g.mode == "battle", "the selected road has a playable battle"):
		return false
	if not await a._play_battle():
		return false
	a._key(KEY_ENTER)
	return a._check(g.mode == "field", "victory returns to the selected road")

func _region(id: String) -> bool:
	a._key(KEY_M)
	if not a._check(g.mode == "world_map", "atlas opens to begin a journey"):
		return false
	var region: Array = g.world.destinations()
	var index := region.find_custom(func(row: Dictionary): return row.id == id)
	if not a._check(index >= 0, "the campaign unlocks region " + id):
		return false
	a._select_menu_row(index)
	return a._check(g.world.active() and g.world.region() == id, "atlas enters " + id)

func _leave() -> bool:
	return a._check(g.world.leave() and not g.world.active(), "recall restores the prior main or Tidegate scene")

func _has(id: String) -> bool:
	return g.field_points().any(func(point: Dictionary): return point.id == id)

func _path(ids: Array) -> bool:
	for id in ids:
		if not a._do_point(id):
			return false
	return true
