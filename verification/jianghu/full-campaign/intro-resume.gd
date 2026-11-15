extends SceneTree

const Main = preload("res://main.tscn")
const PROFILE := "qa_story_handoff"

var game
var checks := 0
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var options := Array(OS.get_cmdline_user_args()).filter(func(arg): return arg.begins_with("--profile="))
	if options != ["--profile=" + PROFILE]:
		push_error("Use --profile=" + PROFILE)
		quit(2)
		return
	game = Main.instantiate()
	root.add_child(game)
	var scratch: Array[String] = []
	for suffix in ["", ".tmp", ".bak"]:
		var file: String = game.storage.path + suffix
		if FileAccess.file_exists(file):
			push_error("QA slot is already in use: " + file)
			quit(2)
			return
		scratch.append(file)
	inspect(1,"lantern_pass","pass_cart","凤溪的凭条")
	inspect(4,"dragon_waterway","waterway_rubbing","西闸岗令",true)
	inspect(4,"dragon_waterway","waterway_rubbing","至尊说旧图")
	for file in scratch:
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(file)
	print("NARRATIVE RESUME %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

func inspect(chapter: int, room: String, first_goal: String, premise: String, has_proof := false) -> void:
	print("INTRO %s (%s)" % [room,premise])
	game._title()
	game.slot = game.storage.replay(chapter,false)
	game.slot.intro_seen = true
	if has_proof:
		game.slot.world.tasks.palace_river_decree = true
		game.slot.world.tasks.palace_dispatch_record = true
	game._enter_chapter(false)
	game._next_chapter(true)
	var started: Dictionary = game.storage.read()
	if not check(game.mode == "dialogue" and not started.intro_seen and started.journey.active == room and started.journey.step == 0,
		"initial scene handoff is saved as unread inside " + room):
		return
	var original: Array = game.lines.duplicate(true)
	var entry: Vector2 = game.player
	check(String(original[0][1]).contains(premise),"handoff gives its source or recoverable older lead")
	game._confirm()
	check(not game.storage.read().intro_seen,"skipping from one line to the next keeps the scene unread")
	game._title()
	game.menu_confirm(0)
	if not check(game.mode == "dialogue" and game.field_key == room and game.lines == original and game.player == entry,
		"title Continue restores the unread intro at %s %s" % [room,entry]):
		return
	drain()
	check(game.mode == "field" and game.storage.read().intro_seen,"reading the handoff records that it has been seen")
	game._title()
	game.menu_confirm(0)
	check(game.mode == "field" and game.field_key == room and game.player == entry,
		"ordinary resume cannot play an intro already finished and keeps the same entry position")
	var goal: Dictionary = game.transit.points().front()
	if not check(goal.id == first_goal and game.passable(goal.pos),"first stated goal is present on walkable terrain"):
		return
	game.player = goal.pos
	game.interact()
	drain()
	var milestone: Dictionary = game.storage.read()
	check(milestone.journey.step == 1 and milestone.journey.at == first_goal,"interaction records the correct position and next step")
	milestone.erase("intro_seen")
	check(game.storage.write(milestone),"previous-schema checkpoint can omit the introduction field")
	game._title()
	game.menu_confirm(0)
	check(game.mode == "field" and game.player == goal.pos and game.slot.journey.step == 1,
		"legacy checkpoint restores %s %s without repeating narration" % [first_goal,goal.pos])

func drain() -> void:
	for step in 20:
		if game.mode != "dialogue":
			return
		game._confirm()

func check(condition: bool, label: String) -> bool:
	checks += 1
	if not condition:
		failures += 1
	print(("PASS " if condition else "FAIL ") + label)
	return condition
