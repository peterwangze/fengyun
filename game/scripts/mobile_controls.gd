extends RefCounted

const FONT = preload("res://assets/fonts/body.tres")
const STICK_CENTER := Vector2(72, 260)
const STICK_RADIUS := 43.0
const STICK_TRAVEL := 28.0
const CONTROLS := [
	[Rect2(520, 256, 98, 53), "互动", "confirm"],
	[Rect2(460, 207, 48, 40), "手记", "journal"],
	[Rect2(515, 207, 48, 40), "武学", "martial"],
	[Rect2(570, 207, 48, 40), "暂停", "cancel"],
]
const BACK := Rect2(552, 304, 70, 43)
const BACK_MODES := ["new", "overwrite", "pause", "settings", "journal", "martial", "choice", "review", "ferry"]
const FILL := Color("#11182ad9")
const BORDER := Color("#e8c185cc")
const INK := Color("#f2e9d9")

var finger := -1
var direction := Vector2.ZERO

func release() -> void:
	finger = -1
	direction = Vector2.ZERO

func drag(index: int, position: Vector2) -> void:
	if index == finger:
		var offset := position - STICK_CENTER
		direction = (offset / STICK_TRAVEL).limit_length() if offset.length() >= 8.0 else Vector2.ZERO

func press(mode: String, index: int, position: Vector2) -> String:
	if mode == "field":
		if position.distance_to(STICK_CENTER) <= STICK_RADIUS:
			if finger == -1:
				finger = index
				drag(index, position)
			return "stick"
		for control in CONTROLS:
			if control[0].has_point(position):
				return control[2]
	elif mode in BACK_MODES and BACK.has_point(position):
		return "cancel"
	return ""

func paint(canvas: Node2D, mode: String) -> void:
	if mode == "field":
		canvas.draw_circle(STICK_CENTER, STICK_RADIUS, FILL, true, -1.0, true)
		canvas.draw_arc(STICK_CENTER, STICK_RADIUS, 0.0, TAU, 48, BORDER, 1.4, true)
		for axis in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
			var tip: Vector2 = STICK_CENTER + axis * 36.0
			var base: Vector2 = tip - axis * 5.0
			var side: Vector2 = axis.orthogonal() * 3.0
			canvas.draw_colored_polygon(PackedVector2Array([tip, base + side, base - side]), BORDER)
		canvas.draw_circle(STICK_CENTER + direction * STICK_TRAVEL, 12.0, BORDER if finger >= 0 else Color("#aeb5c7b3"), true, -1.0, true)
		for control in CONTROLS:
			_button(canvas, control[0], control[1])
	elif mode in BACK_MODES:
		_button(canvas, BACK, "返回")

func _button(canvas: Node2D, box: Rect2, label: String) -> void:
	canvas.draw_rect(box, FILL)
	canvas.draw_rect(box, BORDER, false, 1.0)
	var size := 16 if box.size.x >= 70.0 else 13
	var baseline := Vector2(box.position.x, roundf(box.get_center().y + (FONT.get_ascent(size) - FONT.get_descent(size)) / 2.0))
	canvas.draw_string(FONT, baseline, label, HORIZONTAL_ALIGNMENT_CENTER, box.size.x, size, INK)
