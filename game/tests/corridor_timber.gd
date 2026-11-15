extends SceneTree

const Main = preload("res://main.tscn")
const Martial = preload("res://scripts/martial.gd")
const Corridors = preload("res://scripts/world_corridors.gd")
const PROFILE := "qa_corridor_timber"
const DIRECTIONS := [Vector2i(4,0), Vector2i(-4,0), Vector2i(0,4), Vector2i(0,-4)]

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
			push_error("This QA slot is already in use: " + path)
			quit(2)
			return
		scratch.append(path)
	var order: Dictionary = _start_order()
	if not order.is_empty():
		await _branch(order,"brace",false)
		await _branch(order,"ring",false)
		await _branch(order,"ring",true)
	for path in scratch:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	game.free()
	game = null
	print("Timber convoy: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

func _start_order() -> Dictionary:
	_seed(2)
	if not _visit_all(["world_sword_hamlet","world_timber_order","world_timber_hamlet_hub_shut"]):
		return {}
	_check(_point("world_timber_hamlet_hub").is_empty() and not _point("world_sword_hamlet_return").is_empty(),
		"normal sword workshop return remains open before the Watch corridor")
	var saved: Dictionary = game.storage.read()
	_check(saved.world.tasks.get("timber_order",false) and Corridors.deliveries(saved).is_empty(),
		"early signed order persists as preparation alone")
	_seed(3,saved.world.tasks)
	if not _visit_all(["world_sword_hamlet","world_timber_hamlet_hub","world_timber_wheel","world_timber_choice"]):
		return {}
	game.menu_confirm(0)
	_check(_point("world_timber_hub_brace").is_empty() and not _point("world_timber_south_shut").is_empty(),
		"the chosen freight lane visibly waits for Lingyun access")
	if not _visit_all(["world_timber_hub_scree","world_timber_scree_hub"]):
		return {}
	_check(game.field_key == "watch_qingshi_hub" and game.picture("field/watch_qingshi_hub") != null,
		"the ordinary White Scree road reaches the unique relay map and texture in both directions")
	return saved.world.tasks

func _branch(early: Dictionary, branch: String, late: bool) -> void:
	var brace := branch == "brace"
	var expected: Dictionary = {} if late else {"timber":branch}
	print("ROUTE %s late=%s" % [branch,late])
	_seed(5,early,late)
	if not _visit_all(["world_sword_hamlet","world_timber_hamlet_hub","world_timber_wheel"]):
		return
	_check(game.field_key == "watch_qingshi_hub","the charcoal cart enters the relay street")
	if not _visit("world_timber_choice",false):
		return
	if brace:
		await _capture("qingshi-street")
	_key(KEY_E)
	if not _check(game.mode == "choice","relay clerk has two actual freight choices"):
		return
	if brace:
		await _capture("qingshi-choice")
	game.menu_confirm(0 if brace else 1)
	_check(Corridors.opening(game.slot).is_empty() and not game.slot.world.tasks.get("timber_clearance",false),
		"dispatch intent gives neither clearance nor boss aid")
	if not brace:
		if not _ring_gate(late):
			return
	if not _visit("world_timber_hub_" + branch):
		return
	_check(game.slot.world.area == ("mountain_foothill" if brace else "mountain_steps")
		and game.storage.read().world.tasks.get("timber_clearance",false),"the chosen outbound trip saves clearance and its actual landing")
	_check(Corridors.opening(game.slot).is_empty(),"riding the car still grants no support before the receiver checks its load")
	if not _visit("world_timber_" + branch + "_delivery"):
		return
	_check(game.storage.read().world.tasks.get("timber_delivery",false),"recipient physically checks the dispatched material")
	if not late:
		if not _fight_tyrant(branch):
			return
		game.chronicle.enter("dawn")
		game.chronicle._finish_dawn()
		game.world.from_main("mountain")
		if not _visit_all(["world_mountain_hearth","world_mountain_foothill" if brace else "world_mountain_steps"]):
			return
	_check(game.storage.read().world.corridor_finale == expected,"boss snapshot freezes timely deliveries and omits late ones")
	_check(not game.storage.read().world.tasks.get("timber_receipt",false),"actual postbattle visit is required before ledger closure")
	if not _visit_all(["world_timber_" + branch + "_revisit","world_timber_" + branch + "_hub"]):
		return
	if late:
		await _capture("qingshi-final-ledger")
	if not _visit("world_timber_hub_receipt"):
		return
	game._title()
	_key(KEY_ENTER)
	_check(game.slot.world.area == "watch_qingshi_hub" and game.slot.world.tasks.get("timber_receipt",false)
		and _point("world_timber_hub_receipt").is_empty(),"real postbattle return and ledger closure survive title Continue once")
	_check(game.slot.world.corridor_finale == expected,"late visits never rewrite the fight result")

func _ring_gate(late: bool) -> bool:
	_check(_point("world_timber_hub_ring").is_empty() and not _point("world_timber_north_blocked").is_empty(),
		"the northern gate waits for explicit safe passage")
	if late:
		return _visit("world_timber_ring_watch") and _check(game.mode == "field"
			and game.slot.world.tasks.get("timber_guard",false),"actually delivered anonymous records unlock the noncombat convoy path")
	_check(_point("world_timber_ring_watch").is_empty(),"without handoff there is no fictitious prior escort")
	if not _visit("world_timber_ring_fight") or not _check(game.mode == "battle","generic route starts a genuine optional two-foe encounter"):
		return false
	_play_battle(true)
	if not _check(game.mode == "defeat" and not game.slot.world.tasks.has("timber_guard"),"losing leaves gate locked and stores no passage"):
		return false
	game.menu_confirm(1)
	if not _check(game.passable(game.player) and game.slot.world.area == "watch_qingshi_hub","retreat returns to the relay safe bay"):
		return false
	if not _visit("world_timber_ring_fight"):
		return false
	_play_battle()
	if not _check(game.mode == "victory" and game.storage.read().world.tasks.get("timber_guard",false),"winning actual retry writes safe northern passage"):
		return false
	game.menu_confirm(0)
	return true

func _fight_tyrant(branch: String) -> bool:
	_check(not game.world.mountain_ready(),"filling either shipment leaves all original mountain rescues unmet")
	game.world.leave()
	game.slot.world.tasks.merge({"mountain_west":"done","mountain_west_roll":true,"mountain_west_reed":true,"mountain_west_luo":true})
	game.slot.campaign.farewell = true
	game.chronicle.enter("peak")
	game.player = game.position_of("altar")
	game.interact()
	_drain()
	game.player = game.position_of("fights",1)
	game.interact()
	_drain()
	if not _check(game.mode == "battle","actual final encounter starts having completed an independent west evacuation fixture"):
		return false
	var boss: Dictionary = game.encounter.foes[0]
	var brace := branch == "brace"
	_check(game.encounter.bond == int(brace) and boss.max_poise - boss.poise == int(not brace),
		"actual final battle applies precisely the chosen branch's opening support")
	_play_battle()
	if not _check(game.mode == "victory" and game.slot.cleared.has(1),"genuine boss battle reaches victory"):
		return false
	game.menu_confirm(0)
	return true

func _play_battle(defend_only := false) -> void:
	var battle: RefCounted = game.encounter
	for turn in 150:
		if game.mode != "battle":
			return
		var target: int = battle.living_foe()
		var enemy: Dictionary = battle.foes[target]
		var actor: Dictionary = battle.allies[battle.actor]
		var weak: int = battle.weakest_ally()
		var action := 0
		if defend_only:
			action = 3
		elif battle.available(5) and enemy.shield:
			action = 5
		elif battle.available(4) and battle.allies[weak].hp * 3 < battle.allies[weak].max_hp:
			action = 4
			target = weak
		else:
			var best := float(actor.attack)
			for candidate in [1,2]:
				var move: Array = actor.moves[candidate-1]
				if battle.available(candidate) and move[2] != "疗" and not Martial.protection_move(move):
					var score := float(move[3]) + 3.0 * float(move[4]) + (16.0 if move[2] == enemy.weak else 0.0)
					if score > best:
						best = score
						action = candidate
		game._battle_act(action,target)
		game._skip_battle_effect()

func _seed(chapter: int, earlier: Dictionary = {}, late := false) -> void:
	game.afterstory.reset()
	game.slot = game.storage.replay(chapter,true)
	game.slot.intro_seen = true
	game.slot.world.tasks = earlier.duplicate(true)
	if chapter == 2:
		game.slot.journey.done.pass_done = true
	if chapter == 5:
		game.slot.cleared = [0]
		game.slot.merit = 26
		game.slot.chronicle.room = "lodge"
		game.slot.chronicle.marks = {"shatter_relic":true,"prepare":true,"blood_rite":true}
	if late:
		game.slot.cleared = [0,1]
		game.slot.campaign.altar = true
		game.slot.campaign.farewell = true
		game.slot.chronicle.room = "dawn"
		game.slot.chronicle.marks.dawn_lamp = true
		game.slot.finished = true
		game.slot.world.tasks.merge({"watch_witness":true,"watch_transfer_log":true,"watch_register":"anonymous","register_handoff":true})
	_check(game._commit(),"save accepted corridor checkpoint for resource chapter %d" % chapter)
	game._enter_chapter(false)
	game.world.from_main("swordhall")

func _point(id: String) -> Dictionary:
	for point in game.field_points():
		if point.id == id:
			return point
	return {}

func _visit_all(ids: Array) -> bool:
	for id in ids:
		if not _visit(id):
			return false
	return true

func _visit(id: String, confirm := true) -> bool:
	var point := _point(id)
	if not _check(not point.is_empty() and _walk(point.pos) and game.nearest().get("id") == id,"walk and select " + id):
		return false
	if confirm:
		_key(KEY_E)
		_drain()
	return true

func _walk(target: Vector2) -> bool:
	var initial := Vector2i(game.player.round())
	var previous := {initial:initial}
	var frontier: Array[Vector2i] = [initial]
	var head := 0
	while head < frontier.size():
		var at := frontier[head]
		head += 1
		if Vector2(at).distance_to(target) <= 5.0:
			var path: Array[Vector2i] = []
			while at != initial:
				path.push_front(at)
				at = previous[at]
			for step in path:
				var move := Vector2(step) - Vector2(game.player)
				game.walk(move.normalized(),move.length()/101.0)
			return game.player.distance_to(target) <= 6.0
		for dir in DIRECTIONS:
			var next: Vector2i = at + dir
			if next not in previous and game.passable(Vector2(next)):
				previous[next] = at
				frontier.append(next)
	return false

func _drain() -> void:
	for line in 24:
		if game.mode != "dialogue":
			return
		_key(KEY_ENTER)
	_check(false,"dialogue closes within 24 input actions")

func _key(key: Key) -> void:
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
	_check(root.get_texture().get_image().save_png(report_directory.path_join(name + ".png")) == OK,"capture " + name)

func _check(condition: bool, caption: String) -> bool:
	checks += 1
	if not condition:
		failures += 1
	print(("PASS " if condition else "FAIL ") + caption)
	return condition
