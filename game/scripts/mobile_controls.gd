extends RefCounted

const FONT = preload("res://assets/fonts/body.tres")
const FOOTER_TOP := 315.0
const MOVE_ZONE := Rect2(20, 166, 284, FOOTER_TOP - 166.0)
const STICK_RADIUS := 26.0
const STICK_TRAVEL := 23.0
const DEAD_ZONE := 7.0
const ACTION := Rect2(314, FOOTER_TOP, 210, 45)
const MENU := Rect2(534, FOOTER_TOP, 94, 45)
const BACK_MODES := ["new", "overwrite", "pause", "settings", "journal", "martial", "choice", "review", "ferry"]
const GOLD := Color("#e8c185")
const CREAM := Color("#f2e9d9")
const DIM := Color("#b0b4cb")

var finger := -1
var origin := Vector2.ZERO
var direction := Vector2.ZERO

func release() -> void:
	finger = -1
	direction = Vector2.ZERO

func drag(index: int, position: Vector2) -> void:
	if index == finger:
		var offset := position - origin
		var strength := clampf((offset.length() - DEAD_ZONE) / (STICK_TRAVEL - DEAD_ZONE), 0.0, 1.0)
		direction = offset.normalized() * strength

func press(mode: String, index: int, position: Vector2) -> String:
	if mode == "field":
		if MOVE_ZONE.has_point(position):
			if finger == -1:
				finger = index
				origin = position
			return "stick"
		if ACTION.has_point(position):
			return "confirm"
	if (mode == "field" or mode in BACK_MODES) and MENU.has_point(position):
		return "cancel"
	return ""

func paint_stick(canvas: Node2D) -> void:
	if finger < 0:
		return
	canvas.draw_circle(origin, STICK_RADIUS, Color("#11182a33"), true, -1.0, true)
	canvas.draw_arc(origin, STICK_RADIUS, 0.0, TAU, 40, Color("#e8c185a8"), 1.0, true)
	canvas.draw_circle(origin + direction * STICK_TRAVEL, 8.0, Color("#f2e9d999"), true, -1.0, true)

func paint_footer(canvas: Node2D, interaction: String) -> void:
	canvas.draw_string(FONT, Vector2(134, 343), "左下拖动移动", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, DIM)
	if not interaction.is_empty():
		_button(canvas, ACTION, interaction, true)
	_button(canvas, MENU, "菜单")

func paint_back(canvas: Node2D, mode: String) -> void:
	if mode in BACK_MODES:
		_button(canvas, MENU, "返回")

func _button(canvas: Node2D, target: Rect2, label: String, primary: bool = false) -> void:
	var box := target.grow_individual(0.0, -5.0, 0.0, -5.0)
	var color := GOLD if primary else CREAM
	canvas.draw_rect(box, Color("#373246") if primary else Color("#1e2639"))
	canvas.draw_rect(box, GOLD if primary else Color("#62677e"), false, 1.0)
	canvas.draw_string(FONT, Vector2(box.position.x, 343), label, HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 15, color)
