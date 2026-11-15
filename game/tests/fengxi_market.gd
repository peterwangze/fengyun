extends SceneTree

const Main = preload("res://main.tscn")
const PROFILE := "qa_fengxi_market"
const DIRECTIONS := [Vector2i(4,0),Vector2i(-4,0),Vector2i(0,4),Vector2i(0,-4)]

var game
var checks := 0
var failures := 0
var report_directory := ""

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var profiles := Array(OS.get_cmdline_user_args()).filter(func(arg): return arg.begins_with("--profile="))
	if profiles != ["--profile=" + PROFILE]:
		push_error("Run with -- --profile=" + PROFILE)
		quit(2)
		return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--reports="):
			report_directory = arg.substr(10)
	game = Main.instantiate()
	root.add_child(game)
	var scratch: Array[String] = []
	for suffix in ["", ".tmp", ".bak"]:
		var path: String = game.storage.path + suffix
		if FileAccess.file_exists(path):
			push_error("This test slot is already in use: " + path)
			quit(2)
			return
		scratch.append(path)
	await _exercise_market()
	for path in scratch:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	game.free()
	game = null
	print("Fengxi market: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

func _exercise_market() -> void:
	_start_at_main(1)
	if not _enter_market("evidence"):
		return
	_check(_has("world_market_drygate") and not _has("road_shore_postroad"),"inspection phase shows the gatekeeper instead of an open road")
	if not _visit("world_market_drygate") or not _visit("world_market_sacks"):
		return
	if not _visit("world_market_guild"):
		return
	_check(game.field_key == "fengxi_guild" and game.picture("field/fengxi_guild") != null,"grain hall door loads the dedicated interior and texture")
	_check(not _has("world_market_supplies"),"supply counter is closed before reweighing")
	if not _visit("world_market_scale"):
		return
	_check(not _has("world_market_tally"),"both clues can be collected before embargo, but reweighing awaits the recount")
	_reload()
	var record: Dictionary = game.storage.read()
	var facts: Dictionary = record.world.tasks
	_check(game.field_key == "fengxi_guild" and facts.get("fengxi_scale_mark",false)
		and facts.get("fengxi_sack_owner",false),"continue restores both proofs and the indoor regional checkpoint")
	await _capture("fengxi-grainhall-evidence")
	if not _visit("world_guild_market") or not _visit("world_market_shore"):
		return
	_check(game.world.leave() and game.field_key == "village","leaving the market network restores the campaign field")

	_start_at_main(2,record)
	if not _enter_market("blockade"):
		return
	_check(not _has("world_market_drygate") and _has("road_shore_postroad"),"embargo switches the east gate to the actual post road")
	_check(_point("world_market_notice").get("name","").contains("封渡"),"food relief worker reflects the embargo")
	await _capture("fengxi-market-blockade")
	_walk_to(_point("world_market_guild").pos)
	await _capture("fengxi-market-grainhall-door")
	if not _visit("world_market_guild"):
		return
	var silver: int = game.slot.silver
	var silk: int = game.slot.materials.get("clear_silk",0)
	if not _visit("world_market_tally"):
		return
	_check(game.slot.world.tasks.get("fengxi_scales","") == "done" and game.slot.loot_claims.get("quest:fengxi_scales",false)
		and game.slot.silver == silver + 3 and game.slot.materials.get("clear_silk",0) == silk + 1,
		"reweighing grants the published materials and silver exactly once")
	if not _visit("world_market_supplies"):
		return
	_check(game.mode == "shop" and game.shop_id == "fengxi_relief","the restored supply counter opens its own ordinary shop")
	await _capture("fengxi-grainhall-supplies")
	_press(KEY_ENTER)
	_check(game.slot.silver == silver and game.slot.shop_stock.fengxi_relief.tonic == 1,"buying one tonic saves the new counter's independent stock")
	_press(KEY_ESCAPE)
	_reload()
	_check(_has("world_market_supplies") and not _has("world_market_tally"),"reload preserves service and prevents a duplicate reward")
	if not _visit("world_guild_market"):
		return
	_check(_point("world_market_notice").get("name","").contains("重新起火"),"recount changes live market dialogue before boats return")
	_check(not _has("world_market_scale_receipt"),"reopened phase receipt is absent during embargo")
	record = game.storage.read()
	_check(game.world.leave(),"market network always provides a safe return")

	_start_at_main(5,record)
	if not _enter_market("reopened"):
		return
	if not _visit("world_market_scale_receipt"):
		return
	_check(game.storage.read().world.tasks.get("fengxi_scale_receipt",false),"visiting the reopened soup shelter records the return of residents' rice")
	_check(not _has("world_market_scale_receipt") and _has("world_market_notice"),"the public soup kitchen stays after its one-time receipt")
	await _capture("fengxi-market-reopened")

func _start_at_main(chapter: int, existing: Dictionary = {}) -> void:
	game.afterstory.reset()
	game.slot = game.storage.replay(chapter,false)
	game.slot.intro_seen = true
	game.slot.journey.done.lanes_done = true
	if chapter == 1:
		game.slot.cleared = [0]
		game.slot.campaign.crossing = "bridge"
		game.slot.chronicle.marks.ferry_evidence = true
	if chapter == 5:
		game.slot.finished = true
		game.slot.campaign.farewell = true
		game.slot.campaign.altar = true
		game.slot.cleared = [0,1]
		game.slot.chronicle.room = "dawn"
		game.slot.chronicle.marks.dawn_lamp = true
	for key in ["silver","materials","loot_claims","material_claims","shop_stock","tonics"]:
		if existing.has(key):
			game.slot[key] = existing[key]
	if not existing.is_empty():
		game.slot.world.tasks = existing.world.tasks
	_check(game._commit(),"save phase fixture for resource chapter %d" % chapter)
	game._enter_chapter(false)

func _enter_market(phase: String) -> bool:
	game.world.from_main("fengxi")
	return _check(game.slot.world.area == "shore" and game.world.phase() == phase,"regional entry loads the %s shore" % phase) \
		and _visit("world_fengxi_market") \
		and _check(game.field_key == "fengxi_market" and game.picture("field/fengxi_market") != null,"shore stairs load the 1,104 pixel market field and texture")

func _point(id: String) -> Dictionary:
	for point in game.field_points():
		if point.id == id:
			return point
	return {}

func _has(id: String) -> bool:
	return not _point(id).is_empty()

func _visit(id: String) -> bool:
	var point := _point(id)
	if not _check(not point.is_empty() and _walk_to(point.pos) and game.nearest().get("id") == id,"ordinary movement selects " + id):
		return false
	_press(KEY_E)
	_drain()
	return true

func _walk_to(destination: Vector2) -> bool:
	var start := Vector2i(game.player.round())
	var previous := {start:start}
	var frontier: Array[Vector2i] = [start]
	var head := 0
	while head < frontier.size():
		var at := frontier[head]
		head += 1
		if Vector2(at).distance_to(destination) <= 5.0:
			var path: Array[Vector2i] = []
			while at != start:
				path.push_front(at)
				at = previous[at]
			for step in path:
				var delta := Vector2(step) - Vector2(game.player)
				game.walk(delta.normalized(),delta.length()/101.0)
			return game.player.distance_to(destination) <= 6.0
		for dir in DIRECTIONS:
			var next: Vector2i = at + dir
			if next not in previous and game.passable(Vector2(next)):
				previous[next] = at
				frontier.append(next)
	return false

func _reload() -> void:
	game._title()
	_press(KEY_ENTER)
	_drain()

func _drain() -> void:
	for step in 16:
		if game.mode != "dialogue":
			return
		_press(KEY_ENTER)
	_check(false,"dialogue does not stall")

func _press(key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.pressed = true
	game._unhandled_input(event)

func _capture(name: String) -> void:
	if report_directory.is_empty() or DisplayServer.get_name() == "headless":
		return
	await process_frame
	game.queue_redraw()
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	_check(image.save_png(report_directory.path_join(name + ".png")) == OK,"capture " + name)

func _check(condition: bool, caption: String) -> bool:
	checks += 1
	if not condition:
		failures += 1
	print(("PASS " if condition else "FAIL ") + caption)
	return condition
