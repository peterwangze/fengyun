extends RefCounted

const Economy = preload("res://scripts/economy.gd")
const Save = preload("res://scripts/save.gd")
const REVIEW_REWARD := "quest:tide_review"
const LEGACY_FIXTURE := "res://tests/fixtures/stage4-v320-%s.json"

var a: SceneTree
var g: Node2D
var proof := "canal"
var proof_point := "world_tide_review_source_free"
var visited: Array[String] = []
var review_walk := 0.0
var relief_walk := 0.0

func _init(acceptance: SceneTree) -> void:
	a = acceptance
	g = a.game
	match a.build_route:
		"interrupt":
			proof = "jiang"
			proof_point = "world_tide_review_source_jiang"
		"retaliate":
			proof = "alu"
			proof_point = "world_tide_review_source_alu"
		"exploit":
			proof = "manifest"
			proof_point = "world_tide_review_source_manifest"

func settlement(default_route: String) -> String:
	for arg in OS.get_cmdline_user_args():
		if arg in ["--stage4-settlement=public","--stage4-settlement=witness"]:
			return arg.get_slice("=",1)
	return default_route

func check_before_briefing() -> void:
	_check(not _has("tide_visit"), "a new arrival still needs to speak to the dock master before revisiting")

func check_arrivals() -> void:
	if not a.build_route.is_empty() or not _enter_region():
		return
	_check(g.world.phase() == "arrivals" and not _has("world_tide_review") and not _has("world_tide_relief_roll"),
		"cross-checking the ledger and grain distribution cannot skip the original episode")
	_check(g.world.destinations().any(func(place: Dictionary): return place.id == "tide"),
		"Tidegate is an actual selectable seventh region")
	if _visit("world_tide_to_canal"):
		_check(_has("world_tide_canal_warehouse_shut") and not _has("world_tide_canal_to_fort"),
			"the new canal branch cannot bypass the chief")
		_visit("world_tide_canal_to_ford")
	await a._capture("stage4-tide-arrivals")
	_leave_region()

func before_settlement() -> bool:
	var start: float = a.total_distance
	var old_pos: Vector2
	if not _enter_region():
		return false
	_check(g.world.phase() == "records" and g.slot.afterstory.ledger, "an actual recovered ledger opens the records phase")
	_check(not _has("world_tide_relief_roll"), "distributing grain waits for an actual settlement")
	if not await _review(proof_point,proof):
		return false
	review_walk = float(a.total_distance) - start
	old_pos = _origin_position()
	if not _leave_region():
		return false
	_check(g.player.distance_to(old_pos) < 1.0, "reviewing restores the exact dock position")
	a._resume_afterstory()
	return _check(g.player.distance_to(old_pos) < 1.0 and _has("report"), "title restart restores the dock position and pending settlement")

func after_settlement(outcome: String) -> bool:
	var start: float = a.total_distance
	if not _enter_region():
		return false
	_check(g.world.phase() == outcome, "the settlement becomes the actual region phase")
	if a.build_route.is_empty() and not _cross_fengxi():
		return false
	if not _cross_review_ferry():
		return false
	if not await _relief(outcome):
		return false
	relief_walk = float(a.total_distance) - start
	if not _leave_region():
		return false
	var saved: Dictionary = g.storage.read()
	_check(saved.afterstory.resolution == outcome and saved.world.tasks.get("tide_relief", "") == outcome,
		"a finished follow-up keeps the underlying settlement")
	print("STAGE4 " + JSON.stringify({"build":a.build_route,"phase":outcome,"source":saved.world.get("tide_source", ""),
		"tasks":saved.world.tasks.keys().filter(func(id: String): return id.begins_with("tide_")),
		"review_walk_seconds":snappedf(review_walk / 101.0,0.1),
		"followup_walk_seconds":snappedf(relief_walk / 101.0,0.1),"visits":visited}))
	return true

func verify_fengxi_receipt(outcome: String) -> bool:
	if not _enter_region() or not _visit("road_tide_fengxi"):
		return false
	a._resume()
	if not _check(a._reach("homecoming_tide"), "Fengxi's receipt is accessible after the physical return and reload"):
		return false
	a._key(KEY_E)
	var word := "实发簿" if outcome == "public" else "州府"
	_check(g.mode == "dialogue" and g.lines[0][0] == "回航船工" and g.lines[0][1].contains(word),
		"the returning ship brings the actual receipt for " + outcome)
	await a._capture("homecoming-tide-" + outcome)
	a._drain_dialogue()
	print("HOMECOMING Tidegate receipt in Fengxi: " + outcome)
	return _visit("road_fengxi_tide") and _leave_region()

func _cross_fengxi() -> bool:
	var origin: Dictionary = g.slot.world["return"].duplicate(true)
	if not _visit("road_tide_fengxi"):
		return false
	_check(g.slot.world.area == "shore" and g.player.distance_to(Vector2(118,219)) < 1.0,
		"the new postgame ferry reaches the exact Fengxi shore landing")
	a._resume()
	_check(g.slot.world.area == "shore" and g.player.distance_to(Vector2(118,219)) < 1.0,
		"title continue preserves the Fengxi inter-region crossing")
	if not _visit("road_fengxi_tide"):
		return false
	return _check(g.slot.world.area == "tide_ford" and g.player.distance_to(Vector2(190,252)) < 1.0
		and g.slot.world["return"] == origin, "crossing back to Tidegate retains the original local return ticket")

func _review(source_point: String, source: String) -> bool:
	var start_account: Dictionary = g.slot.afterstory.duplicate(true)
	var main: Dictionary = _main_account()
	_check(not _has("world_tide_review"), "an original ledger alone cannot complete independent review")
	a._key(KEY_J)
	_check(g.mode == "world_journal" and g.menu_items().map(func(row: Array): return row[0]) == ["粮账覆核","归灯分粮"],
		"Tidegate exposes both tasks in its playable journal")
	await a._capture("stage4-tide-journal")
	a._key(KEY_ENTER)
	if a.build_route == "interrupt":
		if not _path(["world_tide_boat_to_canal","world_tide_boat_to_ford"]):
			return false
		_check(g.slot.world.area == "tide_ford", "earlier saved ferry supplies a physical round trip")
	if a.build_route == "retaliate" and _visit("world_tide_clinic"):
		_check(g.mode == "shop" and g.shop_id == "tide_clinic", "earlier medicine work opens the matching dock supply stall")
		a._key(KEY_ESCAPE)
	if not _path(["world_tide_to_canal","world_tide_review_mark"]):
		return false
	if source == "canal":
		if not _visit(source_point):
			return false
		_check(_tracked_point_ids() == ["world_tide_canal_to_fort"],
			"after free evidence, Tidegate tracking guides players to the open east staircase")
	elif _has(source_point) and not _visit(source_point):
		return false
	if not _visit("world_tide_canal_to_fort"):
		return false
	if _has(source_point) and not _visit(source_point):
		return false
	if not _visit("world_tide_review_count"):
		return false
	if _has("world_tide_review_seal") and not _visit("world_tide_review_seal"):
		return false
	if source == "canal":
		_check(_tracked_point_ids() == ["world_tide_fort_to_canal"],
			"after inspecting the warehouse, tracking identifies the multi-map return to the dock")
	if not _path(["world_tide_fort_to_canal","world_tide_canal_to_ford"]):
		return false
	if _has(source_point) and not _visit(source_point):
		return false
	if not _check(g.slot.world.get("tide_source", "") == source, "the actual source is saved with the evidence " + source):
		return false
	if not _visit("world_tide_review"):
		return false
	await a._capture("stage4-review-complete")
	var saved: Dictionary = g.storage.read()
	_check(saved.world.tasks.get("tide_review", "") == "done", "the verified stock and source complete the review")
	_check(saved.afterstory.material_claims.has(REVIEW_REWARD) and saved.afterstory.loot_claims.has(REVIEW_REWARD),
		"review materials and silver have permanent local claims")
	_check(saved.afterstory.silver == mini(Economy.SILVER_CAP, start_account.silver + 4)
		and saved.afterstory.materials.get("tidal_iron",0) == mini(Economy.MATERIAL_CAP,start_account.materials.get("tidal_iron",0) + 1),
		"review increments the local account within its caps")
	_check(_main_account() == main, "review cannot alter the main campaign economy")
	_check(not _has("world_tide_review"), "review cannot be handed in again")
	return true

func _cross_review_ferry() -> bool:
	if not _visit("world_tide_review_shortcut"):
		return false
	_check(g.slot.world.area == "tide_fort" and g.player.distance_to(Vector2(535,201)) < 1.0,
		"review opens a physical dock-to-fort boat landing")
	if _has("world_tide_review_receipt") and not _visit("world_tide_review_receipt"):
		return false
	_check(g.storage.read().world.tasks.get("tide_review_receipt",false), "review's archived receipt is read after settlement")
	if not _visit("world_tide_review_shortcut"):
		return false
	return _check(g.slot.world.area == "tide_ford" and g.player.distance_to(Vector2(546,187)) < 1.0,
		"the new boat also returns from the fort")

func _relief(outcome: String, expect_ambush: bool = false) -> bool:
	_check(not _has("world_tide_relief_confirm"), "a changed flag alone cannot complete distribution")
	var start_account: Dictionary = g.slot.afterstory.duplicate(true)
	var main: Dictionary = _main_account()
	if outcome == "public" and not _visit("world_tide_relief_roll"):
		return false
	var saved_grain: bool = g.slot.chronicle.quests.get("lamps", "") in ["wait_goods", "done_goods"]
	if outcome == "public" and saved_grain:
		if not _visit("world_tide_relief_dispatch") or not _visit("world_tide_to_canal"):
			return false
		print("STAGE4 Fengxi grain prepared both sacks at the dock")
	else:
		if not _path(["world_tide_to_canal","world_tide_canal_to_fort"]):
			return false
		if outcome == "witness" and not _visit("world_tide_relief_roll"):
			return false
		if not _path(["world_tide_relief_dispatch","world_tide_fort_to_canal"]):
			return false
	var entry: Vector2 = g.player
	a._resume()
	_check(g.world.active() and g.slot.world.area == "tide_canal" and g.player.distance_to(entry) < 1.0,
		"mid-delivery reload restores the actual canal area and landing")
	if not _visit("world_tide_relief_arrival"):
		return false
	if not _check((g.mode == "battle") == expect_ambush, "escort ambush is gated by independent review or an early handoff"):
		return false
	if expect_ambush:
		if not _ambush_retry():
			return false
		if not await a._play_battle():
			return false
		a._key(KEY_ENTER)
		a._drain_dialogue()
		_check(not _has("world_tide_relief_arrival"), "the escorted witnesses cannot be farmed")
	if outcome == "witness" and not _visit("world_tide_relief_west"):
		return false
	if not _visit("world_tide_canal_to_ford"):
		return false
	if not _check(not _has("world_tide_relief_confirm"), "leaving the canal with missing households still blocks handover"):
		return false
	if outcome == "public" and not _visit("world_tide_relief_west"):
		return false
	if not _visit("world_tide_relief_east"):
		return false
	await a._capture("stage4-relief-" + outcome)
	if not _visit("world_tide_relief_confirm"):
		return false
	var save: Dictionary = g.storage.read()
	var expected_iron := 1 if outcome == "public" else 2
	var source := "quest:tide_relief_" + outcome
	_check(save.world.tasks.get("tide_relief", "") == outcome, "branch-specific relief is persisted")
	_check(save.afterstory.material_claims.has(source) and save.afterstory.loot_claims.has(source),
		"distribution creates one claim for the chosen settlement")
	_check(save.afterstory.silver == mini(Economy.SILVER_CAP,start_account.silver + 4)
		and save.afterstory.materials.get("tidal_iron",0) == mini(Economy.MATERIAL_CAP,start_account.materials.get("tidal_iron",0) + expected_iron),
		"distribution pays the branch reward once into the local account")
	_check(_main_account() == main, "distribution does not alter the main campaign ledger")
	_check(not _has("world_tide_relief_confirm"), "no repeat relief reward")
	if outcome == "public" and not _path(["world_tide_to_canal","world_tide_canal_to_fort"]):
		return false
	if not _visit("world_tide_relief_receipt"):
		return false
	_check(g.storage.read().world.tasks.get("tide_relief_receipt",false), "the branch-specific receipt survives readback")
	if outcome == "public" and not _path(["world_tide_fort_to_canal","world_tide_canal_to_ford"]):
		return false
	if not _visit("world_tide_shop"):
		return false
	var expected_shop := "tide_relief_public" if outcome == "public" else "tide_convoy"
	_check(g.mode == "shop" and g.shop_id == expected_shop, "the two settlements change the actual service inventory")
	await a._capture("stage4-shop-" + outcome)
	a._key(KEY_ESCAPE)
	var settled: Dictionary = g.storage.read().afterstory
	_check(settled.silver == save.afterstory.silver and settled.materials == save.afterstory.materials,
		"revisiting the issued receipt cannot duplicate the reward")
	return true

func _ambush_retry() -> bool:
	var before: Dictionary = g.slot.afterstory.duplicate(true)
	for action in 180:
		if g.mode != "battle":
			break
		a._key(KEY_4)
	if not _check(g.mode == "defeat", "the retired court path still has a real combat failure"):
		return false
	a._select_menu_row(1)
	_check(g.mode == "field" and g.player.distance_to(Vector2(950,242)) < 1.0,
		"returning from the loss retreats to the safe bank")
	_check(g.slot.afterstory == before and not g.slot.world.tasks.has("tide_relief_arrival"),
		"an escape does not spend local supplies or falsely complete the escort")
	return _visit("world_tide_relief_arrival") and _check(g.mode == "battle", "the unsupported route can be retried")

func verify_legacy() -> void:
	if not a.tidal or not a.build_route.is_empty():
		return
	var previous_storage: RefCounted = g.storage
	for outcome in ["public","witness"]:
		var path: String = LEGACY_FIXTURE % outcome
		var fixture: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not _check(fixture is Dictionary, "v3.2 fixture exists for " + outcome):
			continue
		if outcome == "witness":
			fixture.afterstory.silver = Economy.SILVER_CAP
			fixture.afterstory.materials.tidal_iron = Economy.MATERIAL_CAP
		g.storage = Save.new(previous_storage.path.get_file().get_basename() + "_legacy_" + outcome)
		if not _check(g.storage.write(fixture), "v3.2 completed " + outcome + " save is accepted"):
			continue
		g._title()
		if outcome == "public" and not _title_region():
			continue
		a._select_menu_row(5)
		_check(g.afterstory.active and g.slot.afterstory.resolution == outcome,
			"existing " + outcome + " save enters the old dock without a reset")
		_check(not g.slot.world.tasks.has("tide_review") and not g.slot.world.tasks.has("tide_relief"),
			"legacy settling does not fabricate the new playable objectives")
		if not _enter_region():
			continue
		_check(g.world.phase() == outcome, "legacy save has the correct phase")
		if outcome == "witness" and not await _relief(outcome,true):
			continue
		if not await _review("world_tide_review_source_free","canal"):
			continue
		if outcome == "public" and not await _relief(outcome):
			continue
		if outcome == "witness" and not await _rescue_late_alu():
			continue
		print("STAGE4_MIGRATION " + outcome + " review and distribution followed actual legacy progress")
	g.storage = previous_storage

func _rescue_late_alu() -> bool:
	if not _cross_review_ferry() or not _visit("world_tide_review_shortcut"):
		return false
	if not _visit("world_tide_late_alu") or not _check(g.mode == "battle", "after both conclusions the missed hostage can still be rescued"):
		return false
	if not await a._play_battle():
		return false
	a._key(KEY_ENTER)
	a._drain_dialogue()
	var save: Dictionary = g.storage.read()
	_check(save.afterstory.aid and save.world.tasks.get("tide_late_alu",false),
		"the late rescue saves the freed resident and its own proof atomically")
	_check(not _has("world_tide_late_alu"), "the late hostage battle cannot be repeated")
	if not _path(["world_tide_review_shortcut","world_tide_rescued_alu"]):
		return false
	return _check(g.slot.afterstory.resolution == "witness", "freeing Alu does not alter the previous magistrate decision")

func _title_region() -> bool:
	a._select_menu_row(6)
	if not _check(g.mode == "world_map", "the seventh region is reachable from the normal title menu"):
		return false
	var destinations: Array = g.world.destinations()
	var pick := destinations.find_custom(func(place: Dictionary): return place.id == "tide")
	if not _check(destinations.size() == 7 and pick >= 0, "the picker retains all prior regions and adds Tidegate"):
		return false
	a._select_menu_row(pick)
	if not _check(g.world.active() and g.slot.world.area == "tide_ford", "the new entry appears on the actual resolved dock"):
		return false
	a._key(KEY_ESCAPE)
	var recall: int = g.menu_items().find_custom(func(row: Array): return row[0] == "返回主线" and row[1])
	if not _check(recall >= 0, "title-origin visits can be recalled"):
		return false
	a._select_menu_row(recall)
	return _check(g.mode == "title" and not g.world.active(), "a title-origin trip returns to the title")

func _enter_region() -> bool:
	return _visit("tide_visit") and _check(g.world.active() and g.world.region() == "tide", "entered the Tidegate revisit from a physical point")

func _origin_position() -> Vector2:
	var at: Array = g.slot.world["return"].at
	return Vector2(at[0],at[1])

func _leave_region() -> bool:
	a._key(KEY_ESCAPE)
	var index: int = g.menu_items().find_custom(func(row: Array): return String(row[0]).begins_with("回潮关余事") and row[1])
	if not _check(index >= 0, "a stable local field allows recall"):
		return false
	a._select_menu_row(index)
	a._drain_dialogue()
	return _check(g.afterstory.active and not g.world.active() and g.field_key == "tidal_ford", "recall returns to the dock continuation")

func _main_account() -> Dictionary:
	return {"silver":g.slot.silver,"materials":g.slot.materials.duplicate(true),"tonics":g.slot.tonics,
		"cleared":g.slot.cleared.duplicate(),"chapter":g.slot.chapter}

func _path(ids: Array) -> bool:
	for id in ids:
		if not _visit(id):
			return false
	return true

func _visit(id: String) -> bool:
	if not a._do_point(id):
		return false
	visited.append(id)
	return true

func _has(id: String) -> bool:
	return g.field_points().any(func(point: Dictionary): return point.id == id)

func _tracked_point_ids() -> Array:
	return g.world.trackable_points().map(func(point: Dictionary): return point.id)

func _check(value: bool, message: String) -> bool:
	return a._check(value, "STAGE4 " + message)
