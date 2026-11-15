extends "res://tests/jianghu_regions.gd"

const WATCH_PROFILE := "qa_watch_settlement"
const Economy = preload("res://scripts/economy.gd")

func _run() -> void:
	if "--profile=" + WATCH_PROFILE not in OS.get_cmdline_user_args():
		push_error("Run with -- --profile=" + WATCH_PROFILE)
		quit(1)
		return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--reports="):
			report_dir = arg.substr(10)
	game = Main.instantiate()
	root.add_child(game)
	await _branch("countermark")
	await _branch("covered")
	for suffix in ["", ".tmp", ".bak"]:
		var path: String = game.storage.path + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	print("Watch settlement: %d checks, %d failures; walked %.0f pixels" % [checks,failures,distance])
	quit(1 if failures else 0)

func _branch(outcome: String) -> void:
	var route_start := distance
	if not _phase(2,{}):
		return
	_check(game.world.phase() == "sealed", "first visit keeps the sect checkpoint closed")
	_check(_has("world_watch_road"), "the established lodge to original patrol path stays available")
	if not _visit("world_watch_to_market"):
		return
	_check(_point("world_watch_market_life").sprite == "maid", "sealed market has its own cook and food distribution")
	await _capture("watch-market-sealed-" + outcome)
	if not _visit("world_watch_pass_roster") or not _visit("world_watch_market_to_scree"):
		return
	_check(_has("world_watch_scree_main_closed") and not _has("world_watch_scree_to_east"),
		"the wilderness survey can start, while the ordinary east gate stays shut")
	if not _visit("world_watch_pass_track"):
		return
	await _capture("watch-scree-" + outcome)
	if not _visit("world_watch_scree_to_market") or not _visit("world_watch_market_to_dispatch"):
		return
	_check(not _has("world_watch_pass_order") and _point("world_watch_dispatch_notice").sprite == "servant",
		"sealed dispatch continues its original scheduling and accepts no new order")
	_check(_medicine_task().steps == 2 and not _medicine_task().can_deliver, "sealed evidence survives but does not unlock the petition")
	var prior_world: Dictionary = game.storage.read().world
	if not _phase(3,prior_world.tasks):
		return
	_check(game.world.phase() == "occupied", "chapter handoff opens the occupied phase")
	if not _visit("world_watch_to_market"):
		return
	_check(_point("world_watch_market_life").sprite == "guard", "occupation replaces the cook with box inspection")
	if not _visit("world_watch_market_to_dispatch"):
		return
	_check(_point("world_watch_dispatch_notice").sprite == "guard", "the occupied dispatch office checks substitute seals")
	await _capture("watch-dispatch-occupied-" + outcome)
	var inside: Vector2 = game.player
	game._title()
	game.menu_confirm(0)
	_check(game.slot.world.area == "watch_dispatch_house" and game.player.distance_to(inside) < 1,
		"reload preserves the building and actual landing")
	if not _visit("world_watch_pass_order"):
		return
	_check(game.mode == "choice", "shopkeeper route prompts a real choice")
	game.menu_confirm(int(outcome == "covered"))
	_check(game.storage.read().world.tasks.get("watch_medicine_pass","") == outcome
		and _medicine_task().complete and not _medicine_task().awaiting_receipt,
		"chosen procedure saves immediately and the follow-up waits for testimony")
	_check(not _has("world_watch_pass_order"), "another route cannot overwrite the order")
	var shop := "watch_courier_stock" if outcome == "countermark" else "watch_medic_stock"
	if outcome == "covered" and not _visit("world_watch_dispatch_to_market"):
		return
	if not _visit("world_watch_pass_shop"):
		return
	_check(game.mode == "shop" and game.shop_id == shop, "the chosen path opens its own finite supplies")
	var offer := Economy.offer(game.slot,game.slot,shop,0)
	game._buy_good(0)
	_check(Economy.offer(game.slot,game.slot,shop,0).remaining == offer.remaining - 1,
		"the open shop spends real stock")
	_key(KEY_ESCAPE)
	var gate := "world_watch_pass_dispatch" if outcome == "countermark" else "world_watch_pass_covered"
	var back_room := "watch_dispatch_house" if outcome == "countermark" else "watch_scree_road"
	if outcome == "covered" and not _visit("world_watch_market_to_scree"):
		return
	_check(not _has("world_watch_scree_to_east"), "occupied state still needs the actual authorized path")
	if not _visit(gate):
		return
	_check(game.slot.world.area == "watch_road" and game.passable(game.player), "the new route reaches the original patrol path")
	if not _visit(gate):
		return
	_check(game.slot.world.area == back_room and game.passable(game.player), "the same route supports a physical return")
	prior_world = game.storage.read().world
	if not _phase(4,prior_world.tasks):
		return
	_check(game.world.phase() == "witness" and _medicine_task().awaiting_receipt,
		"testimony opens each follow-up without erasing the chosen route")
	if not _visit("world_watch_to_market"):
		return
	_check(_point("world_watch_market_life").name.contains("共灶"), "witness phase has a civilian public kitchen")
	if not _visit("world_watch_market_to_scree"):
		return
	_check(_has("world_watch_scree_to_east"), "the witness phase also opens the ordinary east gate for everyone")
	if outcome == "countermark" and not _visit("world_watch_scree_to_east"):
		return
	if not _visit("world_watch_pass_followthrough"):
		return
	_check(game.storage.read().world.tasks.get("watch_pass_followthrough",false) and not _medicine_task().awaiting_receipt,
		"recipient confirmation completes the saved task")
	_check(game.world.leave() and not game.world.active(), "the optional visit returns to the original campaign")
	print("WATCH branch=%s distance=%.0f" % [outcome,distance - route_start])

func _medicine_task() -> Dictionary:
	return game.world.journal().filter(func(task: Dictionary): return task.id == "watch_medicine_pass").front()

func _phase(chapter: int, facts: Dictionary) -> bool:
	game.afterstory.reset()
	var fixture: Dictionary = game.storage.replay(chapter,false)
	fixture.intro_seen = true
	fixture.world.tasks = facts.duplicate(true)
	if chapter == 2:
		fixture.chronicle.marks.first_tyrant = true
	if not _check(game.storage.write(fixture), "isolated pre-existing checkpoint admits the next visit"):
		return false
	game._title()
	game.menu_confirm(0)
	game.world.from_main("outer_watch")
	return _check(game.world.active() and game.slot.world.area == "watch_lodge", "old lodge remains the regional entry")
