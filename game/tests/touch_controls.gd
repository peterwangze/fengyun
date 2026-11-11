extends SceneTree

const Main = preload("res://main.tscn")

var game: Node2D
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if "--touch-controls" not in OS.get_cmdline_user_args() or "--profile=qa_touch_controls" not in OS.get_cmdline_user_args():
		push_error("Run with -- --touch-controls --profile=qa_touch_controls")
		quit(1)
		return
	game = Main.instantiate()
	root.add_child(game)
	game._new_game(true)
	game._finish_intro()
	var origin := Vector2(192, 225)
	_touch(0, origin, true)
	_check(game.touch_controls.origin == origin and game.touch_controls.direction == Vector2.ZERO, "touch sets the stick origin without moving")
	_drag(0, origin + Vector2(3, -2))
	_check(game.touch_controls.direction == Vector2.ZERO, "small drags stay inside the dead zone")
	_drag(0, origin + Vector2(30, -20))
	var direction: Vector2 = game.touch_controls.direction
	_check(direction.x > 0 and direction.y < 0 and is_equal_approx(direction.length(), 1.0), "floating stick supports full-speed diagonal dragging")
	_touch(1, Vector2(420, 337), true)
	_touch(1, Vector2(420, 337), false)
	_check(game.mode == "field" and game.touch_controls.direction == direction, "empty action area does not activate or drop movement")
	_touch(0, origin, false)
	_check(game.touch_controls.direction == Vector2.ZERO, "stick stops on release")
	_touch(0, Vector2(48, 308), true)
	_drag(0, Vector2(80, 308))
	_check(game.touch_controls.direction.x > 0, "movement starts near the bottom-left edge")
	game.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	_check(game.touch_controls.direction == Vector2.ZERO, "backgrounding releases held movement")
	_touch(0, origin, true)
	_drag(0, origin + Vector2(30, 0))
	_touch(1, Vector2(580, 337), true)
	_check(game.mode == "pause" and game.touch_controls.direction == Vector2.ZERO, "bottom menu opens with the other finger and clears movement")
	game.menu_confirm(1)
	root.go_back_requested.emit()
	_check(game.mode == "pause", "Android back returns from the journal to the menu")
	_touch(0, Vector2(580, 337), true)
	_check(game.mode == "field", "bottom back button resumes exploration")
	root.go_back_requested.emit()
	_check(game.mode == "pause", "Android back pauses exploration")
	game.cancel()
	game.player = Vector2(98, 258)
	_check(game.nearest().get("id") == "spar", "player has a nearby interaction")
	_touch(1, Vector2(560, 284), true)
	_check(game.mode == "field", "old action position does not trigger a nearby interaction")
	_touch(1, Vector2(420, 337), true)
	_check(game.mode == "dialogue", "bottom action triggers the nearby interaction")
	print("Touch controls: %d failures" % failures)
	quit(1 if failures else 0)

func _touch(index: int, position: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = game.get_global_transform_with_canvas() * position
	event.pressed = pressed
	game._unhandled_input(event)

func _drag(index: int, position: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = game.get_global_transform_with_canvas() * position
	game._unhandled_input(event)

func _check(passed: bool, description: String) -> void:
	print(("PASS " if passed else "FAIL ") + description)
	if not passed:
		failures += 1
