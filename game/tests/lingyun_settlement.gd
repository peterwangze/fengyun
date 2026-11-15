extends SceneTree

const Main = preload("res://main.tscn")
const Mountain = preload("res://scripts/world_mountain.gd")
const PROFILE := "qa_lingyun_settlement"
const DIRECTIONS := [Vector2i(4,0),Vector2i(-4,0),Vector2i(0,4),Vector2i(0,-4)]

var game
var checks := 0
var failures := 0
var report_directory := ""

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := Array(OS.get_cmdline_user_args())
	if args.filter(func(arg): return arg.begins_with("--profile=")) != ["--profile=" + PROFILE]:
		push_error("Run with -- --profile=" + PROFILE)
		quit(2)
		return
	for arg in args:
		if arg.begins_with("--reports="):
			report_directory = arg.substr(10)
	game = Main.instantiate()
	root.add_child(game)
	var scratch: Array[String] = []
	for suffix in ["", ".tmp", ".bak"]:
		var path: String = game.storage.path + suffix
		if FileAccess.file_exists(path):
			push_error("QA slot is already in use: " + path)
			quit(2)
			return
		scratch.append(path)
	var proofs: Dictionary = await _approach()
	if not proofs.is_empty():
		var bridge: Dictionary = await _fractured(proofs,"bridge")
		if not bridge.is_empty():
			await _lanterns(bridge,"bridge")
		var shelter: Dictionary = await _fractured(proofs,"shelter")
		if not shelter.is_empty():
			await _lanterns(shelter,"shelter")
		await _late_choice(proofs)
	for path in scratch:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	game.free()
	game = null
	print("Lingyun settlement: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

func _approach() -> Dictionary:
	_start("approach")
	if not _visit_all(["world_mountain_hearth","world_mountain_foothill","world_foothill_well"]):
		return {}
	_check(game.field_key == "lingyun_foothill" and game.picture("field/lingyun_foothill") != null,"new settlement uses its own outdoor map")
	_check(_name("world_foothill_well").contains("往哪条道"),"the working well introduces the paths before the fracture")
	await _capture("lingyun-foothill-well")
	if not _visit_all(["world_foothill_refuge","world_refuge_beam"]):
		return {}
	_check(game.field_key == "lingyun_refuge" and game.picture("field/lingyun_refuge") != null,"the settlement door leads into a distinct functional room")
	_check(_point("world_refuge_patient").is_empty() and _point("world_refuge_counter").is_empty(),"no displaced residents or stocked cabinet before the fracture")
	await _capture("lingyun-refuge-approach")
	if not _visit_all(["world_refuge_foothill","world_foothill_ridge"]) or not _visit("world_ridge_beam",false):
		return {}
	await _capture("lingyun-feizhan-crossing")
	_press(KEY_E)
	_drain()
	if not _visit("world_ridge_gate"):
		return {}
	_check(game.field_key == "lingyun_feizhan" and game.picture("field/lingyun_feizhan") != null,"walk the real ledge from settlement to the ridge gate")
	_check(_point("world_ridge_steps_bridge").is_empty() and _point("world_ridge_steps_shelter").is_empty(),"both shortcuts are closed in the initial story phase")
	_check(_task().steps == 2 and not _task().can_deliver,"two proofs are trackable before the branch becomes actionable")
	_reload()
	var saved: Dictionary = game.storage.read()
	_check(saved.world.tasks.get("mountain_beam_frame",false) and saved.world.tasks.get("mountain_beam_ridge",false)
		and game.field_key == "lingyun_feizhan","both proofs and the new ridge area survive title Continue")
	return saved

func _fractured(proofs: Dictionary, choice: String) -> Dictionary:
	_start("fractured",proofs)
	if not _visit_all(["world_mountain_hearth","world_mountain_foothill","world_foothill_refuge","world_refuge_patient"]):
		return {}
	_check(_name("world_refuge_patient").contains("躲进"),"after the fracture families use the refuge beds")
	_press(KEY_J)
	var rows: Array = game.world.journal()
	var row: int = rows.find_custom(func(task): return task.id == "mountain_beam")
	_check(game.mode == "world_journal" and rows.size() >= 5 and row >= 0,"five journal entries include the distinct optional task")
	if row >= 0:
		game.selected = row
		if choice == "bridge":
			await _capture("lingyun-journal")
		_press(KEY_ENTER)
		var marks: Array = game.world.trackable_points()
		_check(game.world.tracked == "mountain_beam" and marks.any(func(point): return point.id == "world_refuge_beam_choice"),"journal leads to the actual carpenter rather than the altar")
	if not _decide(choice):
		return {}
	var bridge := choice == "bridge"
	_check(_point("world_refuge_counter").is_empty() == bridge,"the pharmacy opens only when the shelter is shored up")
	if not bridge:
		if not _visit("world_refuge_counter"):
			return {}
		_check(game.mode == "shop" and game.shop_id == "mountain_refuge","the refuge cabinet is a genuine inventory service")
		await _capture("lingyun-refuge-cabinet")
		_press(KEY_ENTER)
		_check(game.slot.shop_stock.get("mountain_refuge",{}).get("tonic",0) == 1,"purchase decrements the cabinet's finite stock")
		_press(KEY_ESCAPE)
	_reload()
	_check(game.field_key == "lingyun_refuge" and game.slot.world.tasks.get("mountain_beam") == choice
		and _point("world_refuge_beam_choice").is_empty(),"reload keeps " + choice + " and prevents a second choice or payment")
	if not _visit_all(["world_refuge_foothill","world_foothill_ridge"]):
		return {}
	_check(not Mountain.ready(game.slot) and not Mountain.altar_open(game.slot),"the construction choice supplies no main rescue or altar access")
	if bridge:
		if not _visit("world_ridge_steps_bridge",false):
			return {}
		await _capture("lingyun-feizhan-east")
		_press(KEY_E)
		_check(game.slot.world.area == "mountain_steps" and _point("world_mountain_altar").is_empty(),"bridge lands at ordinary stone stairs while the existing altar stays closed")
		if not _visit("world_steps_ridge_bridge"):
			return {}
		_check(game.slot.world.area == "mountain_ridge_route","bridge is a real two-way link")
	else:
		_check(_point("world_ridge_steps_bridge").is_empty() and _point("world_ridge_steps_shelter").is_empty(),"shelter path remains sealed before battle")
		if not _visit_all(["world_ridge_gate","world_ridge_foothill","world_foothill_hearth","world_mountain_steps"]):
			return {}
		_check(game.slot.world.area == "mountain_steps" and _point("world_mountain_altar").is_empty(),"shelter has a safe old route to the same steps")
	_check(_point("world_steps_beam_receipt").is_empty(),"no construction receipt before the final battle outcome")
	return game.storage.read()

func _lanterns(prior: Dictionary, choice: String) -> void:
	_start("lanterns",prior)
	if not _visit_all(["world_mountain_hearth","world_mountain_foothill"]):
		return
	_check(_name("world_foothill_well").contains("重新挑水"),"the working well returns during lanterns")
	if not _visit("world_foothill_ridge"):
		return
	var suffix := "bridge" if choice == "bridge" else "shelter"
	if not _visit("world_ridge_steps_" + suffix):
		return
	_check(_name("world_steps_beam_receipt").contains("飞栈" if choice == "bridge" else "避险屋"),"the stone-step delivery reflects the branch actually taken")
	_check(_task().awaiting_receipt,"journal marks the pending construction follow-up")
	if not _visit("world_steps_beam_receipt"):
		return
	_check(game.storage.read().world.tasks.get("mountain_beam_receipt",false) and not _task().awaiting_receipt,
		"hands-on receipt is persisted only after the late interaction")
	_check(_point("world_steps_beam_receipt").is_empty(),"the late receipt is one-time")
	_check(game.storage.read().world.finale == ["mountain_west"],"the completed boss's frozen rescue record survives the construction handoff")
	_check(_visit("world_steps_ridge_" + suffix) and game.slot.world.area == "mountain_ridge_route","late route can be traversed back from the stone steps")
	if choice == "shelter":
		await _capture("lingyun-feizhan-lanterns")

func _late_choice(proofs: Dictionary) -> void:
	_start("lanterns",proofs)
	if not _visit_all(["world_mountain_hearth","world_mountain_foothill","world_foothill_refuge"]):
		return
	_check(_decide("shelter") and game.storage.read().world.finale == ["mountain_west"],"late optional construction is possible without changing the boss result")

func _decide(choice: String) -> bool:
	var silver: int = game.slot.silver
	var previous_silk: int = game.slot.materials.get("clear_silk",0)
	if not _visit("world_refuge_beam_choice") or not _check(game.mode == "choice","carpenter offers an explicit building choice"):
		return false
	var index := 0 if choice == "bridge" else 1
	game.menu_confirm(index)
	return _check(game.slot.world.tasks.get("mountain_beam") == choice and game.slot.silver == silver + 3
		and game.slot.materials.get("clear_silk",0) == previous_silk + 1,"correct branch and once-only modest repair pay")

func _start(phase: String, prior: Dictionary = {}) -> void:
	game.afterstory.reset()
	game.slot = game.storage.replay(5,false)
	game.slot.intro_seen = true
	if not prior.is_empty():
		game.slot.world.tasks = prior.world.tasks.duplicate(true)
		for key in ["silver","materials","loot_claims","material_claims","shop_stock","tonics"]:
			game.slot[key] = prior[key] if not prior[key] is Dictionary else prior[key].duplicate(true)
	if phase != "approach":
		game.slot.cleared = [0]
		game.slot.chronicle.room = "lodge"
		game.slot.chronicle.marks = {"shatter_relic":true,"prepare":true,"blood_rite":true}
	if phase == "lanterns":
		game.slot.finished = true
		game.slot.cleared = [0,1]
		game.slot.campaign.farewell = true
		game.slot.campaign.altar = true
		game.slot.chronicle.room = "dawn"
		game.slot.chronicle.marks.dawn_lamp = true
		game.slot.world.tasks.merge({"mountain_west":"done","mountain_west_roll":true,"mountain_west_reed":true,"mountain_west_luo":true})
		game.slot.world.finale = ["mountain_west"]
	_check(game._commit(),"write valid %s stage fixture" % phase)
	game._enter_chapter(false)
	game.world.from_main("mountain")
	_check(game.slot.world.area == "mountain_cavern" and game.world.phase() == phase,"normal Mountain visit enters the %s phase" % phase)

func _task() -> Dictionary:
	for task in game.world.journal():
		if task.id == "mountain_beam":
			return task
	return {}

func _point(id: String) -> Dictionary:
	for point in game.field_points():
		if point.id == id:
			return point
	return {}

func _name(id: String) -> String:
	return _point(id).get("name","")

func _visit_all(ids: Array) -> bool:
	for id in ids:
		if not _visit(id):
			return false
	return true

func _visit(id: String, confirm := true) -> bool:
	var point := _point(id)
	if not _check(not point.is_empty() and _walk_to(point.pos) and game.nearest().get("id") == id,"walk and select " + id):
		return false
	if confirm:
		_press(KEY_E)
		_drain()
	return true

func _walk_to(destination: Vector2) -> bool:
	var start := Vector2i(game.player.round())
	var previous := {start:start}
	var queue: Array[Vector2i] = [start]
	var head := 0
	while head < queue.size():
		var at := queue[head]
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
		for direction in DIRECTIONS:
			var next: Vector2i = at + direction
			if next not in previous and game.passable(Vector2(next)):
				previous[next] = at
				queue.append(next)
	return false

func _reload() -> void:
	game._title()
	_press(KEY_ENTER)
	_drain()

func _drain() -> void:
	for i in 16:
		if game.mode != "dialogue":
			return
		_press(KEY_ENTER)
	_check(false,"dialogue did not close")

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
	var picture := root.get_texture().get_image()
	_check(picture.save_png(report_directory.path_join(name + ".png")) == OK,"capture " + name)

func _check(condition: bool, description: String) -> bool:
	checks += 1
	if not condition:
		failures += 1
	print(("PASS " if condition else "FAIL ") + description)
	return condition
