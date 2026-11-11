extends RefCounted

const TITLE_FONT = preload("res://assets/fonts/display.tres")
const UI_FONT = preload("res://assets/fonts/body.tres")
const BEAT_GAP := 0.30
const IMPACT := 0.13
const PALETTE := {
	"blade": Color("#f9dfaf"), "wind": Color("#97e6dc"), "cloud": Color("#ff9b76"),
	"frost": Color("#a6cafa"), "heal": Color("#96deb4"), "guard": Color("#e7c185"),
	"break": Color("#ffd37c"), "combo": Color("#ffe6ab"), "dark": Color("#dda5f7")
}

var g

func _init(game: Node2D) -> void:
	g = game

func active() -> bool:
	return g.elapsed < g.effect_started + g.effect_duration

func hud() -> Dictionary:
	if not g.settings.motion or not active():
		return g.encounter.presentation()
	var view: Dictionary = g.effect_before.duplicate(true)
	for event in g.encounter.events:
		var stats: Dictionary = event.get("stats",{})
		if not stats.is_empty() and _time(event) >= (0.0 if event.kind == "cast" else IMPACT):
			view[event.side][event.index].merge(stats,true)
		if event.has("corruption") and _time(event) >= IMPACT:
			view.corruption = event.corruption
	return view

func point(index: int, ally: bool) -> Vector2:
	if ally:
		return Vector2(100 + 123 * index, 192 + 7 * index)
	if g.encounter.foes.size() == 1:
		return Vector2(486, 190)
	return Vector2(407 + 140 * index, 188 + 6 * index)

func falling(index: int, ally: bool) -> bool:
	if not g.settings.motion or not active():
		return false
	var side := "ally" if ally else "foe"
	var events: Array = g.encounter.events
	for i in range(events.size() - 1, -1, -1):
		var event: Dictionary = events[i]
		if event.kind == "damage" and event.side == side and event.index == index:
			return _time(event) < 0.32
	return false

func pose(index: int, ally: bool, rest_frame: int) -> Dictionary:
	var offset := Vector2.ZERO
	var frame := rest_frame
	var art := ""
	if not g.settings.motion or not active():
		return {"offset":offset,"frame":frame,"art":art}
	var side := "ally" if ally else "foe"
	for event in g.encounter.events:
		var t := _time(event)
		if ally and event.kind == "cast" and event.text == "风云合璧" and t >= 0.0 and t < 0.42:
			art = g.encounter.allies[index].id + "_combo"
			offset += Vector2(24.0 * sin(PI * t / 0.42),0)
		if event.side != side or event.index != index:
			continue
		if t < 0:
			continue
		var direction := 1.0 if ally else -1.0
		if event.kind in ["cast","stance"] and t < 0.28:
			if ally:
				match event.text:
					"风神腿","回风腿":
						art = "kick_ready" if t < IMPACT else "kick_hit"
						offset.y -= 13 * sin(PI * t / 0.28)
					"排云掌","翻云守势": art = "palm_ready" if t < IMPACT else "palm_hit"
					"回春诀","护心针","回雪清心": art = "dream_cast"
					"天霜拳","冰魄裂拳","寒衣护体": art = "frost_ready"
			if event.style in ["guard","heal"]:
				frame = 5
			else:
				var thrust := sin(t / 0.28 * PI)
				offset += Vector2(direction * 23.0 * thrust, -3.5 * thrust)
				frame = 4 if t > 0.07 else 5
		elif event.kind == "damage" and t >= IMPACT and t < IMPACT + 0.20:
			var force := sin((t - IMPACT) / 0.20 * PI)
			offset += Vector2(-direction * 10.0 * force, 0)
			art = ""
			frame = 5 if event.style == "guard" else 6
	return {"offset":offset.round(),"frame":frame,"art":art}

func _time(event: Dictionary) -> float:
	var first: Dictionary = g.encounter.events[0]
	var combo_wait := 0.19 if first.style == "combo" and event.beat > 0 else 0.0
	return g.elapsed - g.effect_started - event.beat * BEAT_GAP - combo_wait

func draw() -> void:
	if not active():
		return
	var motion: bool = g.settings.motion
	var stacked := {}
	var fractures := {}
	for event in g.encounter.events:
		var t := _time(event)
		if t < 0 or t > 0.82:
			continue
		var ally: bool = event.side == "ally"
		var base := point(event.index, ally)
		var color: Color = PALETTE[event.style]
		if event.kind == "cast" and event.style == "combo":
			_combo(t, event.text, motion)
			continue
		if event.kind in ["cast","stance"]:
			if motion and event.text == "擂鼓":
				_burst(base-Vector2(0,24),color,clampf(t/0.28,0.0,1.0),9,28)
			elif motion and event.style == "guard":
				_ring(base - Vector2(0, 30), 22 + 22 * t, color, maxf(0.0, 0.57 - t))
				if g.encounter.advanced and t >= IMPACT and t < 0.45:
					_texture("guard",base-Vector2(0,31),61,0.92-t)
			continue
		if event.kind == "recover" or t < IMPACT:
			continue
		var phase := clampf((t - IMPACT) / 0.49, 0.0, 1.0)
		if phase >= 1.0:
			continue
		var slot: String = event.side + str(event.index)
		if event.kind == "break":
			if fractures.has(slot):
				continue
			fractures[slot] = true
		var alpha := clampf((1.0 - phase) * 2.0, 0.0, 1.0)
		var center := base - Vector2(0, 38)
		if motion:
			match event.style:
				"guard": _ring(center, 24 + 15 * phase, color, alpha * 0.68)
				"combo":
					_burst(center, color, phase, 14, 43)
				_:
					var span := 92.0 if event.style in ["blade","wind","dark"] else 78.0
					_texture(event.style, center + Vector2(-13.0 if ally else 13.0, 1), span * (0.69 + 0.55 * phase),
						minf(1.0, phase * 8.0 + 0.24) * alpha, ally)
					_burst(center, color, phase, 11 if event.kind == "break" else 7, 32)
		var row: int = stacked.get(slot, 0)
		stacked[slot] = row + 1
		var rise := phase * 9.0 if motion else 0.0
		var pos := Vector2(base.x + (20 if ally else -20), base.y - 37.0 - row * 21.0 - rise)
		var caption_color := Color("#ffb89e") if ally and event.kind == "damage" else color
		caption_color.a = alpha if motion else 1.0
		_caption(event.text, pos, 15 if event.kind == "break" else 19, caption_color, UI_FONT)

func _combo(t: float, title: String, motion: bool) -> void:
	var reveal: bool = g.encounter.combo_uses == 1
	var phase := clampf(t / (0.74 if reveal else 0.48), 0.0, 1.0)
	if phase >= 1.0:
		return
	var opacity := clampf((1.0 - phase) * 2.2, 0.0, 1.0)
	if motion:
		var center := Vector2(300 + 84 * phase, 146)
		var style: String = {"wind_frost":"frost","wind_dream":"heal","cloud_sage":"blade"}.get(g.encounter.pair,"combo")
		_texture(style,center,(165 if reveal else 118)+42*phase,opacity,false,0.56)
		_burst(center, PALETTE.combo, phase, 22, 72)
		if g.encounter.advanced and reveal and g.encounter.pair == "wind_cloud" and t < 0.23:
			for i in g.encounter.allies.size():
				var portrait: Texture2D = g.picture("portraits/" + g.encounter.allies[i].id)
				if portrait:
					g.draw_texture_rect(portrait,Rect2(111+i*335,55,83,87),false,Color(1,1,1,0.86))
	_caption(title, Vector2(319,106), 24, Color(1,0.89,0.66,opacity if motion else 1.0), TITLE_FONT)

func _texture(key: String, at: Vector2, span: float, alpha: float, flip: bool = false, squash: float = 1.0) -> void:
	var texture: Texture2D = g.picture("vfx/chronicle_" + key) if g.encounter.advanced else null
	if not texture:
		texture = g.picture("vfx/" + key)
	if not texture:
		return
	var size := texture.get_size() * (span / maxf(texture.get_width(), texture.get_height()))
	size = (size * Vector2(1,squash)).snapped(Vector2(2,2))
	var box := Rect2((at - size / 2.0).snapped(Vector2(2,2)), size)
	if flip:
		box.size.x = -box.size.x
	g.draw_texture_rect(texture, box, false, Color(1,1,1,alpha))

func _burst(at: Vector2, color: Color, phase: float, count: int, reach: float) -> void:
	for i in count:
		var angle := i * 2.39996
		var travel := (0.12 + phase) * reach * (0.56 + float(i % 5) / 7.0)
		var pos := (at + Vector2(cos(angle),sin(angle) * 0.63) * travel + Vector2(0,phase * phase * 10.0))
		color.a = (1.0 - phase) * (0.55 + 0.17 * (i % 3))
		var length := 4.0 if i % 3 == 0 and phase < 0.4 else 2.0
		g.draw_rect(Rect2(pos.snapped(Vector2(2,2)), Vector2(length,2)), color)

func _ring(at: Vector2, radius: float, color: Color, alpha: float) -> void:
	color.a = alpha
	var points := PackedVector2Array()
	for i in range(13):
		var angle := TAU * i / 12
		var p := at + Vector2(cos(angle),sin(angle) * 0.8) * radius
		points.append(p.snapped(Vector2(2,2)))
	g.draw_polyline(points, color, 2, false)

func _caption(value: String, at: Vector2, size: int, color: Color, font: Font) -> void:
	var x := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x / 2.0
	var pos := Vector2(roundf(at.x - x), roundf(at.y))
	g.draw_string_outline(font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 4, Color(0.04,0.06,0.12,color.a))
	g.draw_string(font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

