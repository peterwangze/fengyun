extends SceneTree

const Main = preload("res://main.tscn")
const PROFILE := "qa_jianghu_regions"
const DIRECTIONS := [Vector2i(4,0), Vector2i(-4,0), Vector2i(0,4), Vector2i(0,-4)]

var game
var checks := 0
var failures := 0
var report_dir := ""
var distance := 0.0
var dialogue_inputs := 0
var locations: Dictionary = {}

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if "--profile=" + PROFILE not in OS.get_cmdline_user_args():
		push_error("Run with -- --profile=" + PROFILE)
		quit(1)
		return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--reports="):
			report_dir = arg.substr(10)
	game = Main.instantiate()
	root.add_child(game)
	await _test_swordhall(false)
	await _test_swordhall(true)
	_test_legacy()
	_test_legacy_late()
	for suffix in ["", ".tmp", ".bak"]:
		var path: String = game.storage.path + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	print("ROUTE walking_pixels=%d dialogue_inputs=%d locations=%s" % [roundi(distance), dialogue_inputs, str(locations)])
	print("Jianghu regions: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func _test_swordhall(reverse: bool) -> void:
	game.afterstory.reset()
	game.slot = game.storage.replay(2,false)
	game.slot.intro_seen = true
	game.slot.journey.done.lanes_done = true
	var route_start := distance
	var dialogue_start := dialogue_inputs
	game._enter_chapter(false)
	game.transit.enter("lantern_pass")
	_check(_destination_ids() == ["fengxi"], "the first entry to the mountain pass does not unlock the workshop yet")
	_key(KEY_ESCAPE)
	_check(_row("回访凤溪") < 0 and _row("江湖行路") < 0, "main transit checkpoints cannot be displaced by travel")
	_key(KEY_ESCAPE)
	for id in ["pass_cart","pass_worker","pass_rope","pass_gate","pass_exit"]:
		if not _visit(id):
			return
	_check(game.field_key == "forge" and _destination_ids() == ["fengxi","swordhall"], "leaving the pass unlocks the workshop without claiming Sword Pool victories")
	if not _walk_to(Vector2(188,211)):
		_check(false, "forge checkpoint is walkable before leaving for Jianghu")
		return
	var origin: Vector2 = game.player
	var progress := _main_progress(game.storage.read())
	if not await _open_world_with_capture("剑", not reverse) or not _check(game.slot.world.area == "sword_workshop" and game.world.phase() == "seized", "seized Swordhall opens a real workshop"):
		return
	if not reverse:
		await _capture("swordhall-seized")
	_check(not _has("world_sword_supply") and not _has("world_sword_charter"), "seized Swordhall leaves the forge decisions pending")
	_check(not _has("world_sword_shortcut"), "seized workshop has not yet repaired the winch")
	if reverse:
		_visit("world_sword_road")
		_visit("world_sword_keeper")
		_win_cache(false)
		_visit("world_sword_workshop")
		_visit("world_sword_ledger")
		_visit("world_sword_maker")
	else:
		_visit("world_sword_maker")
		_visit("world_sword_ledger")
		_visit("world_sword_road")
		_win_cache(true)
		_visit("world_sword_keeper")
		_visit("world_sword_workshop")
	var found: Dictionary = game.storage.read().world.tasks
	_check(["sword_maker","sword_cache","sword_ledger","sword_keeper"].all(func(id): return found.get(id, false)),
		"both pairs of evidence are saved independent of order")
	_check(not _has("world_sword_supply") and not _has("world_sword_charter"), "even with evidence, the seized forge has not yet rekindled")
	if not _select_world("凤溪"):
		return
	_check(game.slot.world.area == "shore" and game.storage.read().world.tasks == found, "changing destination preserves both task chains")
	_restart()
	_check(game.world.active() and game.slot.world.area == "shore", "title continue restores the selected second region")
	if not _select_world("剑") or not _visit("world_return"):
		return
	_check(_main_progress(game.storage.read()) == progress and game.player.distance_to(origin) < 1.0,
		"two regional visits return to the original main forge coordinate and progress")
	_check(game.storage.read().world.tasks == found, "both unfinished quests survive returning to the main route")
	_restart()
	_check(not game.world.active() and game.field_key == "forge" and game.player.distance_to(origin) < 1.0,
		"after returning, title continue restores the original main coordinate")

	_advance_main("rekindled")
	if not _open_world("剑"):
		return
	_check(game.world.phase() == "rekindled" and _has("world_sword_supply") and _has("world_sword_charter"),
		"clearing the sword milestone unlocks both pending workshop conclusions")
	if reverse:
		_visit("world_sword_supply")
		if not await _charter(true):
			return
	else:
		if not await _charter(false):
			return
		_visit("world_sword_supply")
	var closed: Dictionary = game.storage.read()
	var charter := "refuge" if reverse else "commission"
	_check(closed.world.tasks.get("sword_supply") == "done" and closed.world.tasks.get("sword_charter") == charter,
		"forge supply and charter can resolve in either order")
	_check(closed.materials.get("ember_iron",0) == 1 and closed.materials.get("clear_silk",0) == 1
		and closed.loot_claims.get("quest:sword_supply",false) and closed.loot_claims.get("quest:sword_charter",false),
		"regional resolutions grant the promised smithing materials and store distinct claim IDs")
	_check(not _has("world_sword_supply") and not _has("world_sword_charter"), "resolved workshop tasks do not reappear for duplicate payout")
	_check(not _has("world_sword_supply_receipt") and not _has("world_sword_charter_receipt"), "the receipt actions wait for a settled region")
	await _verify_shortcut(reverse)
	_check(_bag(game.storage.read()) == _bag(closed), "the shortcut and a reload cannot repeat workshop rewards")
	if not _visit("world_return"):
		return
	if not _visit("exit"):
		return
	_check(game.field_key == "swordhall" and game.storage.read().world.get("resume",{}).is_empty(),
		"the real exit to the sword hall clears the previous forge resume point")
	_restart()
	_check(game.field_key == "swordhall", "continue cannot revive the stale forge exit after another room is saved")

	_advance_main("settled")
	if not _open_world("剑"):
		return
	_check(game.world.phase() == "settled", "a later campaign joins the settled workshop phase")
	await _verify_receipts(reverse, charter)
	print("BUDGET swordhall order=%s walk_seconds=%.1f dialogue_inputs=%d" %
		[charter,(distance-route_start)/101.0,dialogue_inputs-dialogue_start])

func _charter(reverse: bool) -> bool:
	if not _visit("world_sword_charter"):
		return false
	if not _check(game.mode == "choice", "the forge charter offers two choices"):
		return false
	if not reverse:
		await _capture("swordhall-charter")
	if reverse:
		_key(KEY_DOWN)
	_key(KEY_ENTER)
	_drain()
	return _check(game.mode == "field", "settling the charter returns to the actual workshop")

func _verify_shortcut(reverse: bool) -> void:
	var baseline := distance
	if not _visit("world_sword_road"):
		return
	var west: Vector2 = game.player
	if not _visit("world_sword_shortcut"):
		return
	var ordinary_walk := distance - baseline
	_check(game.slot.world.area == "sword_workshop" and ordinary_walk > 800.0,
		"the standard road entrance still requires a substantial walk to its east shortcut")
	baseline = distance
	if not _visit("world_sword_shortcut"):
		return
	var east: Vector2 = game.player
	_check(game.slot.world.area == "sword_road" and east.x - west.x > 700.0, "the unlocked shortcut lands on the eastern side of the same road")
	_check(distance - baseline < ordinary_walk / 2.0, "the unlocked shortcut avoids most of the road walk")
	_restart()
	_check(game.slot.world.area == "sword_road" and game.player.distance_to(east) < 1.0, "reloading preserves the exact shortcut arrival")
	if not reverse:
		await _capture("swordhall-shortcut")
	_visit("world_sword_shortcut")
	_check(game.slot.world.area == "sword_workshop", "the physical shortcut works both ways")
	var shortcut_walk := distance - baseline
	print("WALK swordhall normal=%.1fpx shortcut_both_ends=%.1fpx shortcut_landing=(%.1f,%.1f)" % [ordinary_walk,shortcut_walk,east.x,east.y])

func _verify_receipts(reverse: bool, charter: String) -> void:
	_check(game.storage.read().world.tasks.sword_charter == charter, "the chosen charter survives a later regional milestone")
	var before := _bag(game.storage.read())
	for evidence in ["sword_supply_receipt","sword_charter_receipt"]:
		var id: String = "world_" + evidence
		if not _has(id) and _has("world_sword_road"):
			_visit("world_sword_road")
		if not _has(id) and _has("world_sword_workshop"):
			_visit("world_sword_workshop")
		if not _visit(id):
			continue
		_check(game.storage.read().world.tasks.get(evidence, false), "settled region saves " + evidence)
		_check(not _has(id), "settled follow-up cannot be repeatedly recorded " + evidence)
	_check(_bag(game.storage.read()) == before, "checking receipts does not duplicate rewards")
	if reverse:
		_check(not _has("world_sword_commission_forge") and _visit("world_sword_refuge_shop"), "the refuge exposes its own medicine cabinet")
		_check(game.mode == "shop" and game.shop_id == "sword_refuge", "the shelter branch opens a functioning shop")
	else:
		_check(not _has("world_sword_refuge_shop") and _visit("world_sword_commission_forge"), "the commission exposes the eastern repair bench")
		_check(game.mode == "forge" and game.forge_id == "swordhall", "the commission branch opens a functioning forge")
	_key(KEY_ESCAPE)
	if not reverse:
		await _capture("swordhall-settled")

func _advance_main(milestone: String) -> void:
	if milestone == "rekindled":
		game.slot.cleared = [0,1]
		game.slot.campaign.forge_gate = true
		game.slot.campaign.forge_route = "gate"
		game.slot.campaign.sword = true
	else:
		game.slot.chapter = 3
		game.slot.cleared = []
		game.slot.chronicle.room = ""
	_check(game._commit(), "milestone fixture preserves regional facts for " + milestone)
	game._enter_chapter(false)

func _test_legacy() -> void:
	for earned in [false,true]:
		game.afterstory.reset()
		game.slot = game.storage.replay(2,false)
		game.slot.intro_seen = true
		game.slot.erase("world")
		game.slot.erase("journey")
		game.slot.silver = 37
		if earned:
			game.slot.cleared = [0]
		_check(game.storage.write(game.slot), "a pre-region Swordhall slot writes with original funds")
		_restart()
		_check(game.slot.silver == 37 and game.slot.world.tasks.is_empty() and not game.world.active(),
			"migration leaves rewards and funds unchanged")
		_check(_destination_ids().has("swordhall") == earned, "legacy region unlock requires actual sword progress")
		if earned:
			_check(_open_world("剑") and game.world.phase() == "seized", "legacy visited Swordhall can select the new region")

func _test_legacy_late() -> void:
	game.afterstory.reset()
	game.slot = game.storage.replay(5,false)
	game.slot.intro_seen = true
	game.slot.erase("world")
	game.slot.erase("journey")
	game.slot.erase("chronicle")
	_check(game.storage.write(game.slot), "a late older slot without story or region schema stays readable")
	_restart()
	_check(game.slot.chapter == 5 and not game.chronicle.enabled() and not game.slot.finished, "old late slot remains on its original chapter")
	if _open_world("凤溪"):
		_check(game.world.phase() == "blockade", "arriving in the final resource chapter alone does not reopen Fengxi")

	game.slot = game.storage.replay(4,false)
	game.slot.chronicle.from_chapter = 5
	game.slot.world.tasks = {"stencil":true,"witness":true,"testimony":"signed"}
	game.slot.world.erase("legacy_aid")
	_check(game.storage.write(game.slot), "pre-handoff save writes with earned Fengxi testimony")
	game.slot = game.storage.read()
	_check("testimony" in game.slot.world.legacy_aid and not game.slot.world.tasks.has("testimony_handoff"),
		"legacy aid keeps its evidence and leaves a fresh delivery available")
	game._enter_chapter(false)
	_check(not game.chronicle.enabled(), "legacy Palace fixture disables its expanded chronicle")
	if _visit("fight", 0) and _check(game.mode == "battle", "legacy Palace still starts its ordinary battle"):
		var guard: Dictionary = game.encounter.foes[0]
		_check(guard.poise == guard.max_poise - 1 and game.encounter.quest_aid_line.contains("凤溪证人"),
			"earned testimony still affects the legacy encounter")

	game.slot = game.storage.replay(5,false)
	game.slot.intro_seen = true
	game.slot.finished = true
	game.slot.cleared = [0,1]
	game.slot.campaign.farewell = true
	game.slot.campaign.altar = true
	game.afterstory.reset()
	_check(game._commit(), "finished save starts Tidegate without an existing world visit")
	game._title()
	var tidal_row := _row("潮关余事")
	if not _check(tidal_row >= 0, "completed title exposes Tidegate"):
		return
	_choose(tidal_row)
	for id in ["brief","register","seal","gate_entry","canal_tally"]:
		if not _visit(id):
			return
	_check(game.field_key == "tidal_canal", "Tidegate checkpoint is at the active canal crossing")
	game._title()
	_check(_row("江湖行路") < 0 and _row("回访凤溪") < 0 and _row("潮关余事") >= 0,
		"title protects the active Tidegate checkpoint by leaving Jianghu unavailable")

func _open_world(target: String) -> bool:
	return _select_world(target)

func _open_world_with_capture(target: String, capture: bool) -> bool:
	if not _open_chooser():
		return false
	if capture:
		await _capture("jianghu-region-chooser")
	return _enter_destination(target)

func _select_world(target: String) -> bool:
	return _open_chooser() and _enter_destination(target)

func _open_chooser() -> bool:
	_key(KEY_ESCAPE)
	var row := _row("江湖行路")
	if not _check(game.mode == "pause" and row >= 0, "pause opens a multi-region chooser"):
		return false
	_choose(row)
	return _check(game.mode == "world_map", "multi-region chooser becomes visible")

func _enter_destination(target: String) -> bool:
	var row := _row(target)
	if not _check(row >= 0, "region appears in chooser " + target):
		return false
	_choose(row)
	_drain()
	return _check(game.world.active() and game.mode == "field", "choosing a region enters its playable map")

func _restart() -> void:
	if game.mode == "field":
		_key(KEY_ESCAPE)
		var row := _row("回到标题")
		if not _check(row >= 0, "pause offers title navigation"):
			return
		_choose(row)
	else:
		game._title()
	_check(game.mode == "title", "mid-visit restart reaches title")
	_key(KEY_ENTER)
	_drain()

func _destination_ids() -> Array:
	return game.world.destinations().map(func(row): return row.id)

func _row(label: String) -> int:
	return game.menu_items().find_custom(func(row: Array): return label in String(row[0]) and row[1])

func _choose(row: int) -> void:
	var steps := posmod(row - int(game.selected), game.menu_items().size())
	for i in steps:
		_key(KEY_DOWN)
	_key(KEY_ENTER)

func _main_progress(slot: Dictionary) -> Array:
	return [slot.chapter,slot.cleared,slot.campaign,slot.chronicle,slot.journey]

func _bag(slot: Dictionary) -> Array:
	return [slot.silver,slot.tonics,slot.gear_grants,slot.materials,slot.loot_claims]

func _win_cache(test_retry: bool) -> void:
	if not _visit("world_sword_cache"):
		return
	if not _check(game.mode == "battle", "recovering supplies leads to an actual optional fight"):
		return
	if test_retry:
		var before: Dictionary = game.storage.read()
		for move in 120:
			if game.mode != "battle":
				break
			_key(KEY_4)
		if not _check(game.mode == "defeat" and game.storage.read().world == before.world
			and _bag(game.storage.read()) == _bag(before), "the optional defeat cannot spend persistent resources or mark quest progress"):
			return
		_key(KEY_ENTER)
		if not _check(game.mode == "battle" and game.encounter.round_no == 1
			and game.battle_info()[0].contains("三钉铁匣"), "retry returns to the same regional optional encounter"):
			return
	var battle: RefCounted = game.encounter
	for move in 50:
		if game.mode != "battle":
			break
		var action := 0
		var target: int = battle.living_foe()
		var most_damaged: Dictionary = battle.allies[battle.weakest_ally()]
		if battle.available(5):
			action = 5
		elif battle.available(4) and most_damaged.hp * 3 < most_damaged.max_hp:
			action = 4
			target = battle.weakest_ally()
		elif battle.available(1):
			action = 1
		game.battle_choose(action)
		if game.pending_action >= 0:
			game.target = target
			_key(KEY_ENTER)
	if not _check(game.mode == "victory", "optional supplies can be recovered with practical combat commands"):
		return
	print("BATTLE sword cache rounds=%d" % battle.round_no)
	_key(KEY_ENTER)
	_drain()
	_check(game.storage.read().world.tasks.get("sword_cache", false) and not _has("world_sword_cache"),
		"battle victory commits the evidence and removes the repeatable encounter")

func _has(id: String) -> bool:
	return not _point(id).is_empty()

func _point(id: String, index: int = -1) -> Dictionary:
	for spot in game.field_points():
		if spot.id == id and (index < 0 or spot.get("index",-1) == index):
			return spot
	return {}

func _visit(id: String, index: int = -1) -> bool:
	var spot := _point(id,index)
	if not _check(not spot.is_empty() and _walk_to(spot.pos), "walk to " + id + " on " + game.field_key):
		return false
	if not _check(game.nearest().get("id") == id, "interact with " + id):
		return false
	_key(KEY_E)
	_drain()
	return true

func _walk_to(destination: Vector2) -> bool:
	var start := Vector2i(game.player.round())
	var previous := {start:start}
	var frontier: Array[Vector2i] = [start]
	var cursor := 0
	while cursor < frontier.size():
		var node := frontier[cursor]
		cursor += 1
		if Vector2(node).distance_to(destination) < 7.0:
			var path: Array[Vector2i] = []
			while node != start:
				path.push_front(node)
				node = previous[node]
			for step in path:
				var prior: Vector2 = game.player
				var delta := Vector2(step) - prior
				game.walk(delta.normalized(),delta.length()/101.0)
				distance += prior.distance_to(game.player)
			locations[game.field_key] = true
			return game.player.distance_to(destination) < 8.0
		for direction in DIRECTIONS:
			var next: Vector2i = node + direction
			if not previous.has(next) and game.passable(Vector2(next)):
				previous[next] = node
				frontier.append(next)
	return false

func _drain() -> void:
	for i in 30:
		if game.mode != "dialogue":
			return
		_key(KEY_ENTER)
		dialogue_inputs += 1
	_check(false, "dialogue ends normally")

func _capture(name: String) -> void:
	if report_dir.is_empty() or DisplayServer.get_name() == "headless":
		return
	await process_frame
	await RenderingServer.frame_post_draw
	var frame := root.get_texture().get_image()
	_check(frame.save_png(report_dir.path_join(name + ".png")) == OK, "capture " + name)

func _key(key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.pressed = true
	game._unhandled_input(event)

func _check(value: bool, description: String) -> bool:
	checks += 1
	if not value:
		failures += 1
	print(("PASS " if value else "FAIL ") + description)
	return value
