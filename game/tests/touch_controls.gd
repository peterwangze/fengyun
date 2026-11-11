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
	_touch(0, Vector2(72, 260), true)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = game.get_global_transform_with_canvas() * Vector2(102, 240)
	game._unhandled_input(drag)
	var direction: Vector2 = game.touch_controls.direction
	_check(direction.x > 0 and direction.y < 0, "virtual stick supports diagonal dragging")
	_touch(1, Vector2(560, 284), true)
	_touch(1, Vector2(560, 284), false)
	_check(game.touch_controls.direction == direction, "second finger releases without dropping movement")
	_touch(0, Vector2(102, 240), false)
	_check(game.touch_controls.direction == Vector2.ZERO, "stick stops on release")
	_touch(0, Vector2(103, 260), true)
	game.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	_check(game.touch_controls.direction == Vector2.ZERO, "backgrounding releases held movement")
	_touch(0, Vector2(103, 260), true)
	_touch(1, Vector2(484, 227), true)
	_check(game.mode == "journal" and game.touch_controls.direction == Vector2.ZERO, "opening a panel releases held movement")
	root.go_back_requested.emit()
	_check(game.mode == "field", "Android back closes an open panel")
	root.go_back_requested.emit()
	_check(game.mode == "pause", "Android back pauses exploration")
	print("Touch controls: %d failures" % failures)
	quit(1 if failures else 0)

func _touch(index: int, position: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = game.get_global_transform_with_canvas() * position
	event.pressed = pressed
	game._unhandled_input(event)

func _check(passed: bool, description: String) -> void:
	print(("PASS " if passed else "FAIL ") + description)
	if not passed:
		failures += 1
