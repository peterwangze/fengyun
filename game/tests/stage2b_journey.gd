extends RefCounted

const HANDOFFS := ["testimony_handoff", "register_handoff", "carry_handoff", "medicine_handoff", "charter_handoff"]
const Items = preload("res://scripts/items.gd")

var a
var g: Node2D
var handoffs: Array[String] = []
var travelled := 0.0
var opened := 0
var origin := {}

func _init(acceptance: SceneTree) -> void:
	a = acceptance
	g = a.game

func investigate_fengxi() -> void:
	if not _open("fengxi"):
		return
	_points(["world_roster","world_lanes","world_crate","world_stencil","world_shore","world_inn","world_witness"])
	_check(not _has("world_seal"), "Fengxi investigation waits for the blockade before concluding")
	_leave()

func finish_fengxi() -> void:
	if not _open("fengxi"):
		return
	_points(["world_medicine","world_inn","world_seal"])
	_choose(int(a.build_route == "exploit"))
	_points(["world_shore"])
	_shortcut("world_shortcut", "shore", "lanes")
	_leave()

func complete_swordhall() -> void:
	if not _open("swordhall"):
		return
	_points(["world_sword_maker","world_sword_ledger","world_sword_road","world_sword_keeper"])
	if not await _fight("world_sword_cache"):
		return
	_points(["world_sword_workshop","world_sword_supply","world_sword_charter"])
	_choose(int(a.build_route == "retaliate"))
	_shortcut("world_sword_shortcut", "sword_workshop", "sword_road")
	_leave()

func investigate_watch() -> void:
	if not _open("outer_watch"):
		return
	_check(g.world.phase() == "sealed" and not _has("world_watch_register"), "outer watch is still in the sealed phase before the first Tyrant fight")
	_points(["world_watch_witness","world_watch_cut_rope","world_watch_road","world_watch_transfer_log"])
	if not await _fight("world_watch_signal_guard"):
		return
	_points(["world_watch_lodge"])
	_check(not _has("world_watch_register") and not _has("world_watch_shortcut"), "the sealed watch does not pretend the register or pulley is ready")
	_leave()

func watch_and_valley() -> void:
	if not _open("outer_watch"):
		return
	_check(g.world.phase() == "occupied", "the first chapter change replaces sealed posts with occupation")
	_cross_region_link("road_watch_fengxi", "road_fengxi_watch", "shore", "watch_lodge")
	await _handoff("handoff_charter", "charter_handoff")
	if g.slot.world.tasks.get("sword_charter","") == "commission":
		_shortcut("world_watch_charter_pass", "watch_lodge", "watch_road")
	else:
		_shortcut("world_watch_charter_refuge_pass", "watch_lodge", "watch_road")
		if a._do_point("world_watch_charter_refuge"):
			_check(g.mode == "shop" and g.shop_id == "sword_refuge", "received charter opens the shelter's own supply counter")
			a._key(KEY_ESCAPE)
	_points(["world_watch_relay","world_watch_register"])
	_choose(int(a.build_route != "interrupt"))
	_shortcut("world_watch_shortcut", "watch_lodge", "watch_road")
	_points(["world_watch_road"])
	_cross_region_link("road_watch_sword", "road_sword_watch", "sword_road", "watch_road")
	_points(["world_watch_lodge"])
	_cross_region_link("road_watch_valley", "road_valley_watch", "valley_clinic", "watch_lodge")
	if not a._do_point("road_watch_valley"):
		return
	_check(g.world.phase() == "trial", "first apothecary briefing unlocks the Valley trial visit")
	await _handoff("handoff_medicine", "medicine_handoff")
	_points(["world_valley_porter","world_valley_cot","world_valley_trestle","world_valley_carry_hook","world_valley_relief_runner"])
	_shortcut("world_valley_medicine_pass", "valley_trestle", "valley_trestle")
	_points(["world_valley_chain","world_valley_clinic"])
	_check(not _has("world_valley_carry") and not _has("world_valley_latch"), "Valley work needs to wait for withdrawal")
	_leave()

func finish_valley() -> void:
	if not _open("valley"):
		return
	_check(g.world.phase() == "withdrawal", "the ruined pool exits to the Valley withdrawal phase")
	_points(["world_valley_latch","world_valley_carry"])
	_choose(int(a.build_route == "exploit"))
	_shortcut("world_valley_shortcut", "valley_clinic", "valley_trestle")
	_leave()

func deliver_palace() -> void:
	for pair in [["handoff_testimony","testimony_handoff"],["handoff_register","register_handoff"],["handoff_carry","carry_handoff"]]:
		if a.build_route == "retaliate" and pair[1] == "testimony_handoff":
			continue
		await _handoff(pair[0], pair[1])
	if _open("outer_watch"):
		_check(g.world.phase() == "witness", "the palace stage exposes the Watch's witnesses and receipts")
		_points(["world_watch_shortcut","world_watch_register_receipt","world_watch_relay_receipt","world_watch_shortcut"])
		_leave()
	if _open("valley"):
		_check(g.world.phase() == "relief", "announcing the palace march opens Valley relief")
		_points(["world_valley_shortcut","world_valley_carry_receipt","world_valley_latch_receipt","world_valley_shortcut"])
		_leave()

func late_reception() -> void:
	if a.build_route != "retaliate" or not _open("outer_watch"):
		return
	_points(["world_watch_to_reception", "world_watch_reception_notice"])
	_check(g.slot.world.area == "watch_palace_reception", "the fire changes which Palace entrance remains open")
	await _handoff("handoff_testimony", "testimony_handoff")
	_points(["world_watch_from_reception"])
	_leave()

func verify_palace_battle(fight: int) -> void:
	var facts: Dictionary = g.slot.world.tasks
	var battle: RefCounted = g.encounter
	if fight == 0:
		var guard: Dictionary = battle.foes[0]
		var cloud: Dictionary = battle.allies[0]
		var testimony: String = facts.get("testimony","")
		if a.build_route == "retaliate":
			_check(not facts.has("testimony_handoff") and not cloud.ward and guard.poise == guard.max_poise,
				"local testimony alone yields no early effect on a new save")
		elif testimony == "signed":
			_check(guard.poise == guard.max_poise - 1, "signed Fengxi testimony lowers the Palace guard's poise")
		elif testimony == "sealed":
			_check(cloud.ward, "sealed Fengxi testimony protects Cloud against the Palace guard")
		if facts.get("watch_register","") == "public":
			_check(battle.bond == 1, "the public register supplies one opening combo charge")
	elif fight == 1 and facts.get("valley_carry","") == "medicine":
		_check(battle.allies[1].ward and battle.allies[0].ward, "delivered medicine protects Cloud when Sage already has a ward")
	elif fight == 1 and facts.get("valley_carry","") == "breath":
		var godless: Dictionary = battle.foes[0]
		var expected := 2 if g.chronicle.has("trestle_carry") else 1
		_check(godless.poise == godless.max_poise - expected, "delivered breathing notes stack with the rescued trestle witness")

func finish() -> void:
	var actual: Dictionary = g.storage.read().world.tasks
	var saved := HANDOFFS.filter(func(id): return actual.get(id,false))
	if a.stage2b_skip:
		_check(saved.is_empty() and actual.is_empty(), "the fresh no-purchase route clears the game without regional tasks")
	else:
		_check(saved == HANDOFFS, "one fresh campaign delivers all five cross-region handoffs")
		_check(_destination_ids().size() == 4 and opened >= 6, "all four revisit regions unlock organically")
	_verify_saved_routes()
	print("STAGE2B " + JSON.stringify({"build":a.build_route, "skip":a.stage2b_skip, "handoffs":handoffs,
		"world_tasks":actual, "destinations":_destination_ids(), "world_walk_seconds":snappedf(travelled/101.0,0.1)}))

func _verify_saved_routes() -> void:
	var saved: Dictionary = g.storage.read()
	var expected := {
		"pass_furnace_opened":a.build_route in ["retaliate","exploit"],
		"pass_evidence":a.build_route == "interrupt",
		"pass_help":a.build_route.is_empty(),
		"watch_old_road_done":a.build_route in ["interrupt","exploit"],
		"watch_freed":a.build_route in ["","retaliate"],
		"palace_sluice_patrol_gap":a.build_route in ["retaliate","exploit"],
	}
	for flag in expected:
		_check(saved.chronicle.marks.get(flag,false) == expected[flag], "ending save preserves the chosen route outcome " + flag)
	for milestone in ["pass_done","watch_done","sluice_done"]:
		_check(saved.journey.done.get(milestone,false), "ending save has the shared destination checkpoint " + milestone)
	print("SAVED_ROUTES " + JSON.stringify(expected))

func _handoff(id: String, fact: String) -> void:
	if not _check(_has(id), "handoff is available at the actual destination " + id):
		return
	if fact in ["medicine_handoff", "register_handoff"]:
		await _verify_handoff_journal(fact, id)
	var start: Dictionary = g.storage.read()
	var location: String = g.field_key
	if not a._do_point(id):
		return
	var after: Dictionary = g.storage.read()
	_check(after.world.tasks.get(fact,false), "destination saves the cross-region handoff " + fact)
	_verify_handoff_reward(fact, start, after)
	handoffs.append(fact)
	await a._capture("stage2b-" + id)
	a._resume()
	_check(g.field_key == location and g.storage.read().world.tasks.get(fact,false), "restart restores the destination and its completed handoff")
	if _has(id):
		var before_review := _reward_snapshot(g.storage.read())
		a._do_point(id)
		_check(_reward_snapshot(g.storage.read()) == before_review, "reviewing the handoff cannot repeat its payout " + id)
	print("HANDOFF %s map=%s silver_delta=%d" % [fact,location,after.silver-start.silver])

func _verify_handoff_journal(fact: String, point_id: String) -> void:
	a._key(KEY_J)
	var parent: String = g.mode
	_check(parent == ("world_journal" if g.world.active() else "journal"), "J first opens its regional or standard journal")
	a._key(KEY_TAB)
	if not _check(g.mode == "handoff_journal" and g.menu_items().size() == HANDOFFS.size(), "Tab opens the five cross-region deliveries"):
		return
	var entries: Array = g.world.handoff_journal()
	var row := entries.find_custom(func(item: Dictionary): return item.id == fact)
	if not _check(row >= 0 and entries[row].state == "待交接" and not entries[row].to.is_empty(), "journal identifies the real destination before the handoff"):
		return
	await a._capture("stage2b-handoff-journal-" + fact)
	a._key(KEY_TAB)
	_check(g.mode == parent, "Tab can return to the original journal")
	a._key(KEY_TAB)
	a._select_menu_row(row)
	_check(g.mode == "field" and g.world.tracked == fact, "selecting the journal entry tracks the correct handoff")
	var markers: Array = g.world.trackable_points() if g.world.active() else g.world.main_handoff_points()
	_check(markers.any(func(item: Dictionary): return item.id == point_id and item.evidence == g.world.tracked),
		"the tracked entry matches a real nearby marker")

func _verify_handoff_reward(fact: String, before: Dictionary, after: Dictionary) -> void:
	match fact:
		"medicine_handoff":
			_check(after.materials.get("clear_silk",0) == before.materials.get("clear_silk",0) + 1,
				"Valley delivery gives one actual clear silk from the inspected medicine basket")
		"charter_handoff":
			if after.world.tasks.sword_charter == "commission":
				_check(after.materials.get("ember_iron",0) == before.materials.get("ember_iron",0) + 1,
					"commission gives iron after completing the handoff")
			else:
				_check(after.silver == before.silver + 3, "refuge gives three silver after completing the handoff")
		"carry_handoff":
			var powder: int = before.supplies.guard_powder
			var medicine: bool = after.world.tasks.valley_carry == "medicine"
			_check(after.supplies.guard_powder == mini(Items.CAP, powder + int(medicine)),
				"only the physical medicine load grants a guard-powder dose")

func _open(id: String) -> bool:
	var opened_at: Vector2 = g.player
	var room: String = g.field_key
	var saved: Dictionary = g.storage.read()
	a._key(KEY_ESCAPE)
	var row: int = g.menu_items().find_custom(func(item: Array): return item[0] in ["回访凤溪","江湖行路"] and item[1])
	if not _check(row >= 0, "normal pause offers a revisit before " + id):
		return false
	a._select_menu_row(row)
	if g.mode == "world_map":
		var index := _destination_ids().find(id)
		if not _check(index >= 0, "normal itinerary permits destination " + id):
			return false
		a._select_menu_row(index)
	if _check(g.world.active() and g.world.region() == id and g.mode == "field", "arrived at authored region " + id):
		opened += 1
		origin = {"room":room,"position":opened_at,"distance":a.total_distance,
			"chapter":saved.chapter,"cleared":saved.cleared,"journey":saved.journey}
		return true
	return false

func _leave() -> void:
	travelled += a.total_distance - origin.distance
	a._key(KEY_ESCAPE)
	var row: int = g.menu_items().find_custom(func(item: Array): return "返回主线" in item[0] and item[1])
	if not _check(row >= 0, "pause offers the return to the same main game"):
		return
	a._select_menu_row(row)
	var saved: Dictionary = g.storage.read()
	_check(g.field_key == origin.room and g.player.distance_to(origin.position) < 1.0 and saved.chapter == origin.chapter
		and saved.cleared == origin.cleared and saved.journey == origin.journey,
		"regional exploration preserves original checkpoint, main fights and journey")

func _points(ids: Array) -> void:
	for id in ids:
		if not a._do_point(id):
			return

func _choose(at: int) -> void:
	if _check(g.mode == "choice", "a regional decision opens its two options"):
		a._choose(at)

func _fight(id: String) -> bool:
	if not a._do_point(id):
		return false
	if not _check(g.mode == "battle" and g.world.battle_point.get("id","") == id, "the optional authored battle opens " + id):
		return false
	if not await a._play_battle():
		return false
	a._key(KEY_ENTER)
	a._drain_dialogue()
	_check(not _has(id), "the won regional encounter does not reappear " + id)
	return true

func _shortcut(id: String, from: String, to: String) -> void:
	if not _check(g.slot.world.area == from and _has(id), "the repaired route opens from " + from) or not _use_shortcut(id):
		return
	var landing: Vector2 = g.player
	_check(g.slot.world.area == to, "the repaired route reaches " + to)
	a._resume()
	_check(g.slot.world.area == to and g.player.distance_to(landing) < 1.0, "the repaired route saves its far landing")
	if _use_shortcut(id):
		if from == to:
			_check(g.slot.world.area == from and g.player.distance_to(landing) > 180.0, "the same-area route crosses back to its other end")
		else:
			_check(g.slot.world.area == from, "the repaired route is reversible")

func _use_shortcut(id: String) -> bool:
	var points: Array = g.field_points().filter(func(point: Dictionary): return point.id == id)
	if not _check(not points.is_empty(), "both ends expose a usable shortcut"):
		return false
	points.sort_custom(func(first: Dictionary, second: Dictionary): return g.player.distance_to(first.pos) < g.player.distance_to(second.pos))
	if not _check(a._go_to(points[0].pos, 9.0) and g.nearest().get("id") == id, "the nearest end of the shortcut is reachable on foot"):
		return false
	a._key(KEY_E)
	a._drain_dialogue()
	return true

func _cross_region_link(outbound: String, inbound: String, destination: String, source: String) -> void:
	var ticket: Dictionary = g.storage.read().world["return"].duplicate(true)
	if not _cross_endpoint(outbound):
		return
	_check(g.slot.world.area == destination, "the physical junction reaches " + destination)
	a._resume()
	_check(g.slot.world.area == destination and g.slot.world["return"] == ticket,
		"crossing the regional road and restarting preserves the main-game return ticket")
	if _cross_endpoint(inbound):
		_check(g.slot.world.area == source and g.slot.world["return"] == ticket, "the physical connection is reversible in the same save")

func _cross_endpoint(id: String) -> bool:
	var points: Array = g.field_points().filter(func(point: Dictionary): return point.id == id)
	if not _check(points.size() == 1 and g.passable(points[0].pos), "the exact regional entrance stands on walkable ground " + id):
		return false
	var landing: Vector2 = points[0].arrival
	if not a._do_point(id):
		return false
	var exact := _check(g.passable(landing) and g.player.distance_to(landing) < 1.0,
		"walking through the portal reaches its exact landing, without a fallback spawn " + id)
	if exact:
		print("PORTAL %s landing=(%.0f,%.0f)" % [id,landing.x,landing.y])
	return exact

func _has(id: String) -> bool:
	return g.field_points().any(func(point: Dictionary): return point.id == id)

func _destination_ids() -> Array:
	return g.world.destinations().map(func(place: Dictionary): return place.id)

func _reward_snapshot(slot: Dictionary) -> Array:
	return [slot.silver,slot.materials,slot.tonics,slot.supplies,slot.loot_claims,slot.material_claims]

func _check(value: bool, label: String) -> bool:
	return a._check(value, "STAGE2B " + label)
