extends RefCounted

const Story = preload("res://scripts/story.gd")
const CombatArt = preload("res://scripts/combat_art.gd")
const CampaignArt = preload("res://scripts/campaign_art.gd")
const Chronicle = preload("res://scripts/chronicle.gd")
const Martial = preload("res://scripts/martial.gd")
const SideStories = preload("res://scripts/side_stories.gd")
const Equipment = preload("res://scripts/equipment.gd")
const SANS = preload("res://assets/fonts/body.tres")
const SERIF = preload("res://assets/fonts/display.tres")
const GOLD := Color("#e8c185")
const CREAM := Color("#f2e9d9")
const DIM := Color("#b0b4cb")
const FAINT := Color("#727a96")
const TEAL := Color("#75d6cb")
const RED := Color("#ef8d80")
const INK := Color("#13192a")
const LINE := Color("#414762")
const FULL := Rect2(0, 0, 640, 360)
const ENEMY_MARK := Color("#ec927e")

var g
var combat_art: RefCounted
var campaign_art: RefCounted
var hot: Array[Dictionary] = []

func _init(game: Node2D) -> void:
	g = game
	combat_art = CombatArt.new(game)
	campaign_art = CampaignArt.new(game)

func hit(position: Vector2) -> Dictionary:
	for i in range(hot.size() - 1, -1, -1):
		if hot[i].box.has_point(position):
			return hot[i]
	return {}

func _hit(box: Rect2, kind: String, index: int = 0) -> void:
	hot.append({"box":box, "kind":kind, "index":index})

func _fill(box: Rect2, color: Color) -> void:
	g.draw_rect(box, color)

func _stroke(box: Rect2, color: Color, width: float = 1.0) -> void:
	g.draw_rect(box, color, false, width)

func _line(a: Vector2, b: Vector2, color: Color, width: float = 1.0) -> void:
	g.draw_line(a, b, color, width, false)

func _text(value: String, x: float, y: float, size: int = 16, color: Color = CREAM, font: Font = SANS) -> void:
	g.draw_string(font, Vector2(roundf(x), roundf(y)), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _right(value: String, x: float, y: float, size: int = 14, color: Color = DIM) -> void:
	_text(value, x - SANS.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x, y, size, color)

func _center(value: String, x: float, y: float, size: int = 16, color: Color = CREAM, font: Font = SANS) -> void:
	_text(value, x - font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x / 2, y, size, color, font)

func _paragraph(value: String, x: float, y: float, width: float, size: int, color: Color, leading: int = 23) -> void:
	var row := ""
	var baseline := y
	for ch in value:
		if ch == "\n" or SANS.get_string_size(row + ch, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width:
			_text(row, x, baseline, size, color)
			baseline += leading
			row = ""
		if ch != "\n":
			row += ch
	_text(row, x, baseline, size, color)

func _panel(box: Rect2, strong: bool = false) -> void:
	_fill(box, Color("#111728f7"))
	_stroke(box, GOLD if strong else LINE)
	_line(box.position + Vector2(3, 3), box.position + Vector2(22, 3), GOLD)
	_line(box.end - Vector2(22, 3), box.end - Vector2(3, 3), GOLD)
	_line(box.position + Vector2(3, 3), box.position + Vector2(3, 10), GOLD)
	_line(box.end - Vector2(3, 10), box.end - Vector2(3, 3), GOLD)

func _picture(path: String, box: Rect2 = FULL, shade: Color = Color.WHITE) -> void:
	var texture: Texture2D = g.picture(path)
	if texture:
		g.draw_texture_rect(texture, box, false, shade)
	else:
		_fill(box, INK)

func _fade(top: float, height: float, alpha: float, reverse: bool = false) -> void:
	var dark := Color(0.03, 0.04, 0.085, alpha)
	var clear := Color(0.03, 0.04, 0.085, 0.0)
	var start := dark if reverse else clear
	var end := clear if reverse else dark
	g.draw_polygon(PackedVector2Array([Vector2(0,top),Vector2(640,top),
		Vector2(640,top+height),Vector2(0,top+height)]), PackedColorArray([start,start,end,end]))

func _button(label: String, box: Rect2, index: int, enabled: bool = true) -> void:
	var focus: bool = index == g.selected and enabled
	var hover: bool = box.has_point(g.get_global_mouse_position()) and enabled
	_fill(box, Color("#353141") if focus or hover else Color("#141b2ce8"))
	_stroke(box, GOLD if focus or hover else LINE)
	if focus:
		_fill(Rect2(box.position + Vector2(0, 1), Vector2(3, box.size.y - 2)), GOLD)
	_text(label, box.position.x + 12, box.position.y + box.size.y / 2 + 6, 16, CREAM if enabled else FAINT)
	if enabled:
		_hit(box,"menu",index)

func _menu(origin: Vector2, width: int = 203, row_height: int = 31, gap: int = 5) -> void:
	var items: Array = g.menu_items()
	for i in items.size():
		_button(items[i][0], Rect2(origin + Vector2(0, i * (row_height + gap)), Vector2(width,row_height)), i, items[i][1])

func _sprite(key: String, foot: Vector2, scale: float = 1.0, frame: int = 0, flip: bool = false, color: Color = Color.WHITE) -> void:
	var texture: Texture2D = g.picture("actors/" + key)
	if not texture:
		return
	var cell := float(texture.get_height())
	var size := Vector2(cell,cell) * scale
	var dest := Rect2((foot - Vector2(size.x / 2, size.y - 2 * scale)).round(), size)
	if flip:
		dest.size.x = -dest.size.x
	var atlas_frame := posmod(frame, maxi(1, int(texture.get_width() / cell)))
	g.draw_texture_rect_region(texture, dest, Rect2(atlas_frame * cell, 0, cell, cell), color)

func _shadow(pos: Vector2, width: float) -> void:
	_fill(Rect2(pos.x - width / 2 + 3,pos.y - 5,width - 6,7),Color("#09111f82"))
	_fill(Rect2(pos.x - width / 2,pos.y - 3,width,3),Color("#09111f8e"))

func _walk_frame(walking: bool, distance: float) -> int:
	return posmod(floori(distance / 6.0), 4) if walking else 0

func _diamond(pos: Vector2, radius: float, color: Color) -> void:
	var shape := PackedVector2Array([pos + Vector2(0,-radius),pos + Vector2(radius,0),
		pos + Vector2(0,radius),pos + Vector2(-radius,0)])
	g.draw_colored_polygon(shape, color)

func _dots(kind: String, strength: float) -> void:
	if not g.settings.motion:
		return
	for i in 36:
		var time: float = g.elapsed
		var x := int(fposmod(float(i * 179) + time * (11.0 + float(i % 7)), 644))
		var direction := 37.0 if kind == "rain" else -13.0
		var y := int(fposmod(float(i * 73) + time * direction, 263)) + 42
		var color := Color(0.96,0.72,0.41, strength * (0.4 + float(i%4) / 6.0))
		if kind == "rain":
			color = Color(0.69,0.80,0.92,strength)
			_line(Vector2(x,y),Vector2(x-4,y+10),color)
		else:
			_fill(Rect2(x, y, 1+i%2,1+i%2),color)

func paint() -> void:
	hot.clear()
	match g.mode:
		"title", "new", "overwrite":
			_title()
		"settings":
			if g.back_mode == "title":
				_title(false)
			else:
				_field(false)
			_modal("设置", "调整本机的显示与声音。")
		"field": _field()
		"ferry": _field(false)
		"dialogue":
			if g.music_key == "ending" and g.campaign.scene.is_empty():
				_picture(_ending_path())
				_fade(78, 280, 0.7)
			else:
				_field(false)
			_dialogue()
		"battle", "victory", "defeat":
			_battle()
		"pause":
			_field(false)
			_modal("旅途暂歇", "进度在战斗胜利、开箱和换章时自动保存。")
		"choice":
			_field(false)
			_modal(g.chronicle.question,g.chronicle.choice_note)
		"martial":
			_field(false)
			_martial()
		"gear":
			_field(false)
			_gear()
		"review":
			_title(false)
			_fill(FULL,Color("#0b1120dd"))
			_panel(Rect2(147,25,346,312),true)
			_center("章节回看",320,62,26,CREAM,SERIF)
			_center("从选中章节开头体验，回看使用独立记录。",320,85,13,DIM)
			_menu(Vector2(177,98),286,29,5)
			if not g.touch_ui():
				_center("Esc / B 返回标题",320,320,12,DIM)
		"journal":
			_field(false)
			_journal()
		"ending": _ending()
	if g.toast_time > 0 and g.mode in ["field","battle","dialogue"]:
		var yy := 290 if g.mode == "field" else 171
		if g.mode == "field" and g.touch_ui():
			yy = 283
		_fill(Rect2(163, yy, 314, 28), Color("#0a1020ef"))
		_stroke(Rect2(163, yy, 314, 28), GOLD)
		_center(g.toast, 320, yy + 20, 14, CREAM)

func _title(with_menu: bool = true) -> void:
	_picture("paintings/title")
	_dots("dust",0.24)
	_fade(317, 43, 0.72)
	_line(Vector2(48,46),Vector2(76,46),GOLD)
	_text("江 湖 纪 行", 86, 51, 14, GOLD)
	_text("风云", 42, 130, 83, CREAM, SERIF)
	_fill(Rect2(216, 74, 32, 35), Color("#944b4d"))
	_stroke(Rect2(219, 77, 26, 29), Color("#d88d79"))
	_center("劫", 232, 100, 21, CREAM, SERIF)
	_text("山 河 劫", 49, 162, 23, GOLD, SERIF)
	if not with_menu:
		return
	match g.mode:
		"title":
			if g.slot.get("finished",false):
				_menu(Vector2(48,181),190,24,3)
			else:
				_menu(Vector2(48,188),190,29,5)
			if not g.slot.is_empty():
				var chapter: Dictionary = Story.CHAPTERS[int(g.slot.chapter)]
				var status: String = "已通关" if g.slot.finished else "第%s章 · %s" % [chapter.num, chapter.title]
				_text(status, 255, 210, 14, DIM)
		"new": _modal("开启新篇", "标准难度完整保留战斗强度。轻松难度提高我方伤害，降低所受伤害。")
		"overwrite": _modal("覆盖旧档？", "开始新篇会覆盖当前自动存档。")
	var hint: String = "左摇杆 / 方向键  选择     A  确认     B  返回" if g.using_joypad else "方向键 / WASD  移动     Enter / E  确认     Esc  返回"
	if g.touch_ui():
		hint = "点按选项   ·   支持外接手柄" if g.mode == "title" else ""
	_text(hint,251,347,12,DIM)

func _modal(title: String, note: String) -> void:
	_fill(FULL, Color("#080d1bb5"))
	if g.mode == "pause":
		_panel(Rect2(142,23,356,309),true)
		_center(title,320,67,29,CREAM,SERIF)
		_paragraph(note,170,94,300,14,DIM,19)
		_menu(Vector2(174,126),292,29,4)
	else:
		_panel(Rect2(142,43,356,275),true)
		_center(title,320,88,29,CREAM,SERIF)
		_paragraph(note,170,116,300,14,DIM,19)
		_menu(Vector2(174,157),292,30,6)

func _field(interactive: bool = true) -> void:
	_picture("field/" + ("hall" if g.field_key == "returnhall" else String(g.field_key)))
	_field_atmosphere()
	var party: Array = g.chronicle.field_party()
	var units := [_traveler(party[1],g.follower,g.follow_direction,g.follow_facing,_walk_frame(g.follow_moving,g.follow_distance)),
		_traveler(party[0],g.player,g.field_direction,g.facing,_walk_frame(g.moving,g.walk_distance))]
	var marks: Array[Dictionary] = []
	if g.afterstory.active:
		_afterstory_field(units,marks)
	else:
		if g.map.has("fights"):
			_regular_field(units, marks)
		if g.first.active():
			_first_field(units, marks)
		else:
			campaign_art.stage(units,marks)
		_chronicle_field(units,marks)
	var touch_field: bool = interactive and g.touch_ui()
	if touch_field:
		g.touch_controls.paint_stick(g)
	_draw_field_actors(units)
	if g.field_key in ["garden","village","lodge","inn","apothecary","tearoom","cavern","tidal_ford","tidal_fort"]:
		_picture("field/%s_canopy" % g.field_key)
	if g.first.wedding_playing:
		_wedding_impact()
	for mark in marks:
		_marker(mark.point, mark.color, mark.get("symbol",""))
	_fill(Rect2(0,0,640,52),Color("#12192bf8"))
	_line(Vector2(0,51),Vector2(640,51),LINE)
	_fill(Rect2(19,13,31,29),Color("#352c3b"))
	_stroke(Rect2(19,13,31,29),GOLD)
	_center(g.stage.num,34,34,17,GOLD,SERIF)
	_text(g.stage.title,62,28,20,CREAM,SERIF)
	var place: String = g.afterstory.subtitle() if g.afterstory.active else Chronicle.SUBTITLE.get(
		g.field_key,g.first.subtitle() if g.first.active() else g.campaign.subtitle())
	_text(place,63,45,12,DIM)
	var main_count: int = int(g.slot.cleared.has(0)) + int(g.slot.cleared.has(1))
	var status := "主线进度  %d / 2" % main_count
	if g.first.active():
		status = "疏散  %d / 2" % g.slot.hall.staff.size() if g.slot.hall.wedding else "婚宴"
	if g.afterstory.active:
		status = "已结案" if g.afterstory.state().resolution != "" else "粮账待查"
	_right("%s    ·    境界  %d" % [status,g.rank()],620,24,13,GOLD)
	var objective: String = g.afterstory.objective() if g.afterstory.active else g.chronicle.objective()
	if objective.is_empty():
		objective = g.first.objective() if g.first.active() else g.campaign.objective()
	_right(objective,620,43,13,DIM)
	var footer_top: float = g.touch_controls.FOOTER_TOP if touch_field else 321.0
	_fill(Rect2(0,footer_top,640,360-footer_top),Color("#12192b") if touch_field else Color("#12192bf8"))
	_line(Vector2(0,footer_top),Vector2(640,footer_top),LINE)
	var medicine: int = g.afterstory.state().tonics if g.afterstory.active else g.slot.tonics
	_text("金创药  ×%d" % medicine,20,345,14,TEAL)
	if touch_field:
		g.touch_controls.paint_footer(g, g.nearest().get("name", ""))
		return
	var interact_key: String = "A" if g.using_joypad else "E"
	if g.mode == "ferry":
		var skip_key: String = "A" if g.using_joypad else "Enter"
		_center("渡船驶向西岸   ·   点按此处抵达" if g.touch_ui() else "渡船驶向西岸   ·   %s  直接抵达" % skip_key,320,345,14,GOLD)
		if not g.touch_ui() and g.campaign.ferry_time < 0.55:
			_right("B  返回船埠" if g.using_joypad else "Esc  返回船埠",619,345,13,DIM)
		_hit(Rect2(192,324,258,32),"confirm")
	elif not g.touch_ui():
		_right("X  手记   Y  武学   Start  暂停" if g.using_joypad else "J  手记   K  武学   Esc  暂停",619,345,11,DIM)
	if interactive:
		var spot: Dictionary = g.nearest()
		if spot.is_empty():
			_center("靠近人物、敌人或物品，按 %s 互动" % interact_key,321,345,14,DIM)
		else:
			_fill(Rect2(201,329,239,24),Color("#333047"))
			_center(interact_key + "   " + spot.name,320,346,14,GOLD)
			_hit(Rect2(201,325,239,31),"confirm")

func _afterstory_field(units: Array, marks: Array[Dictionary]) -> void:
	var flags: Dictionary = g.afterstory.state()
	if g.field_key == "tidal_ford" and flags.brief and not flags.sluice and flags.resolution == "":
		var gate: Vector2 = g.position_of("sluice_entry")
		_fill(Rect2(gate.x-22,gate.y-17,44,7),Color("#71544d"))
		_line(gate+Vector2(-22,-17),gate+Vector2(22,-17),GOLD,2)
	if g.field_key == "tidal_fort" and not flags.chief and (flags.route == "sluice" or flags.gate):
		units.append(_unit("tidal_drum",g.position_of("chief")+Vector2(75,-3),0,true))
	if g.field_key == "tidal_fort" and flags.route == "gate" and not flags.gate:
		for x in range(40,604,29):
			_fill(Rect2(x,193,5,21),Color("#8f6b52"))
			_fill(Rect2(x-1,192,7,3),GOLD)
		_line(Vector2(38,202),Vector2(604,202),Color("#755440"),3)
		_line(Vector2(38,209),Vector2(604,209),Color("#755440"),3)
	for spot in g.afterstory.points():
		var p: Vector2 = spot.pos
		if not spot.sprite.is_empty():
			units.append(_unit(spot.sprite,p,0,true))
		match spot.id:
			"seal","ledger": _map_prop(p,"chest")
			"sluice": campaign_art._prop("winch",p,0.8)
		if g.mode == "field":
			if spot.id in ["gate_entry","sluice_entry","return_ford"]:
				_door_label(spot.name,p)
			var marker := p - Vector2(0,52 if not spot.sprite.is_empty() else 30)
			marks.append({"point":marker,"color":GOLD if spot.optional else TEAL,
				"symbol":"·" if spot.optional else ""})

func _chronicle_field(units: Array, marks: Array[Dictionary]) -> void:
	if not g.chronicle.enabled():
		return
	if g.field_key == "apothecary" and not g.chronicle.has("pool_intro"):
		units.append(_unit("dugu",Vector2(384,173),0,true))
	if g.field_key == "tearoom" and not g.chronicle.has("evacuated"):
		units.append(_unit("yan",Vector2(376,174),0,true))
	if g.field_key == "lodge" and not g.chronicle.has("blood_rite"):
		_fill(Rect2(0,52,640,269),Color("#24142e32"))
		var warmth := 0.69 + 0.10 * sin(g.elapsed*3) if g.settings.motion else 0.75
		campaign_art._prop("signal",Vector2(276,211),0.61,Color(1,0.83,0.63,warmth))
	if g.field_key == "tearoom" and g.slot.cleared.has(1):
		_fill(Rect2(0,52,640,270),Color("#691d2260"))
		for p in [Vector2(77,181),Vector2(536,174),Vector2(574,228)]:
			var phase := 0.7 + 0.3 * sin(g.elapsed * 5 + p.x) if g.settings.motion else 0.85
			_picture("field/props/fire",Rect2(p-Vector2(25,40),Vector2(50,45)),Color(1,0.92,0.78,phase))
	if g.field_key == "dawn":
		campaign_art._prop("signal",Vector2(298,201),0.82,Color.WHITE if g.chronicle.has("dawn_lamp") else Color("#828b91"))
		var rescue: String = g.chronicle.side.state().get("lamps","")
		if rescue.ends_with("boat"):
			campaign_art._prop("boat",Vector2(230,244),1.35)
		if rescue.ends_with("goods"):
			units.append(_unit("boatman_front",Vector2(231,265),0,true))
		if String(g.chronicle.side.state().get("stairs","")).begins_with("done_"):
			units.append(_unit("maid",Vector2(170,182),0))
			units.append(_unit("servant",Vector2(149,205),0))
	for spot in g.chronicle.points():
		var p: Vector2 = spot.pos
		if not spot.sprite.is_empty() and not (g.field_key == "banquet" and spot.id == "kindness"):
			units.append(_unit(spot.sprite,p+Vector2(0,-5),0,true))
		if g.mode == "field":
			var mark := p - Vector2(0,36 if spot.sprite.is_empty() else 53)
			marks.append({"point":mark,"color":GOLD if spot.optional else TEAL,"symbol":"·" if spot.optional else ""})

func _regular_field(units: Array, marks: Array[Dictionary]) -> void:
	var guide: Vector2 = g.guide_point()
	_map_prop(g.position_of("shrine"),"shrine")
	_map_prop(g.position_of("chest"),"empty" if g.slot.chest else "chest")
	var open: bool = (g.slot.cleared.has(1) and g.slot.hall.wedding) if g.first.active() else g.campaign.can_exit()
	_map_prop(g.position_of("exit"),"exit_open" if open else "exit")
	var guide_art: String = "boatman_front" if g.field_key == "village" else g.stage.guide_sprite
	var escort: bool = g.field_key == "village" and g.slot.campaign.rope and g.slot.campaign.crossing.is_empty() and not g.campaign.ferry_ready()
	units.append(_unit(guide_art, guide, int(g.elapsed*8) % 4 if escort and g.settings.motion else 0))
	marks.append({"point":guide - Vector2(0,56),"color":TEAL})
	for i in 3:
		if g.visible_encounter(i):
			var id: String = g.stage.battles[i][1][0]
			var pos: Vector2 = g.position_of("fights",i)
			units.append(_unit(Story.FOES[id][5],pos,0,true))
			marks.append({"point":pos - Vector2(0,56),"color":GOLD if i == 2 else ENEMY_MARK,"symbol":"·" if i == 2 else "!"})

func _first_field(units: Array, marks: Array[Dictionary]) -> void:
	match g.field_key:
		"hall":
			_map_prop(g.position_of("banquet_door"),"exit_open" if g.first.cleared_gate() else "exit")
		"banquet":
			if g.slot.hall.wedding or (g.first.wedding_playing and g.line_index >= 3):
				_fill(Rect2(0,52,640,269),Color("#10162556"))
			_map_prop(g.position_of("court_door"),"exit_open")
			_map_prop(g.position_of("garden_door"),"exit_open" if g.slot.hall.wedding else "exit")
			if g.slot.hall.wedding:
				_door_label("正门 · 伏兵",g.position_of("court_door"))
				_door_label("竹径 · 巡卫",g.position_of("garden_door"))
			_wedding_cast(units,marks)
		"garden":
			var helped: bool = g.slot.hall.staff.size() == 2
			if helped:
				_fill(Rect2(0,52,640,269),Color("#111c302b"))
			_map_prop(g.position_of("return_door"),"exit_open")
			var alarm: bool = g.slot.hall.alarm and not g.slot.cleared.has(1)
			_map_prop(g.position_of("escape_door"),"exit" if alarm else "exit_open")
			if g.first.patrol_visible():
				_patrol_art(units,marks)

func _patrol_art(units: Array, marks: Array[Dictionary]) -> void:
	var guard: Dictionary = g.first.patrol()
	var at: Vector2 = guard.point
	var alarm: bool = g.slot.hall.alarm
	var warning: float = g.first.alert / 0.70
	units.append(_unit("guard",at,0 if alarm or not g.settings.motion else int(g.first.patrol_clock * 8) % 4,guard.facing < 0))
	if not alarm:
		var cone: PackedVector2Array = g.first.sight()
		var color := Color("#e2ac64") if warning == 0 else ENEMY_MARK
		color.a = 0.16 + warning * 0.20
		g.draw_colored_polygon(cone,color)
		var rim := PackedVector2Array([cone[0],cone[1],cone[2],cone[0]])
		color.a += 0.14
		g.draw_polyline(rim,color,1.0,false)
	if warning > 0 or alarm:
		marks.append({"point":at - Vector2(0,56),"color":ENEMY_MARK,"symbol":"!"})
	if warning > 0:
		_bar(Rect2(at.x-22,at.y-42,44,4),warning,1.0,RED)

func _door_label(label: String, at: Vector2) -> void:
	_fill(Rect2(at.x-40,at.y+5,80,18),Color("#111828dc"))
	_center(label,at.x,at.y+18,12,TEAL)

func _wedding_cast(units: Array, marks: Array[Dictionary]) -> void:
	var bride: Vector2 = g.position_of("bride")
	var groom: Vector2 = g.position_of("groom")
	var master: Vector2 = g.position_of("master")
	var ceremony: Vector2 = g.position_of("ceremony")
	var played: bool = g.slot.hall.wedding
	if g.first.wedding_playing:
		var beat: int = g.line_index
		var t := 1.0 if not g.settings.motion else clampf((g.elapsed - g.first.line_started) / 0.39,0.0,1.0)
		var down := beat >= 3 and t > 0.64 or beat >= 4
		var fallen := ceremony + Vector2(4,-2)
		bride = bride if beat < 3 else bride.lerp(fallen, t if beat == 3 else 1.0)
		var charge := sin(t * PI) if beat == 3 else 0.0
		units.clear()
		units.append_array([_unit("boss",master),
			_unit("groom",groom.lerp(ceremony + Vector2(-42,-12),float(beat >= 3)),5 if beat >= 3 else 0),
			_unit("kongci",bride,7 if down else 0,true),
			_unit("cloud",ceremony + Vector2(-32 + 12 * charge,24 if beat == 0 else 12),4 if beat == 3 and not down else (5 if beat >= 3 else 0)),
			_unit("wind",ceremony + Vector2(42,19),5 if beat == 3 else 0,true)])
	elif played:
		units.append_array([_unit("groom",ceremony + Vector2(-36,-12),5),_unit("kongci",ceremony + Vector2(4,-2),7,true)])
	else:
		units.append_array([_unit("boss",master),_unit("groom",groom),_unit("kongci",bride,0,true)])
		marks.append({"point":ceremony + Vector2(0,8),"color":GOLD,"symbol":"·"})
	for member in ["maid","servant"]:
		var at: Vector2 = g.position_of(member)
		if not g.slot.hall.staff.has(member):
			units.append(_unit(member,at,0,member == "servant"))
			if played:
				marks.append({"point":at - Vector2(0,54),"color":TEAL})
		elif g.first.retreat.has(member) and g.settings.motion:
			var t := clampf((g.elapsed - g.first.retreat[member]) / 0.90,0.0,1.0)
			if t < 1:
				var door: Vector2 = g.position_of("court_door" if member == "maid" else "garden_door")
				units.append(_unit(member,at.lerp(door,t),int(t * 10) % 4,door.x < at.x))

func _wedding_impact() -> void:
	if g.line_index != 3 or not g.settings.motion:
		return
	var phase: float = (g.elapsed - g.first.line_started - 0.15) / 0.42
	if phase >= 0.0 and phase < 1.0:
		var p: Vector2 = g.position_of("ceremony")
		_picture("vfx/cloud",Rect2(p - Vector2(42,67),Vector2(84,52)),Color(1,0.78,0.60,(1.0-phase)*0.82))

func _unit(key: String, at: Vector2, frame: int = 0, flip: bool = false) -> Dictionary:
	return {"key":key,"point":at,"frame":frame,"flip":flip}

func _traveler(key: String, at: Vector2, direction: String, side: int, frame: int) -> Dictionary:
	if direction != "side":
		return _unit(key + "_" + direction,at,frame)
	return _unit(key,at,frame,side < 0)

func _draw_field_actors(units: Array) -> void:
	units.sort_custom(func(a: Dictionary, b: Dictionary): return a.point.y < b.point.y)
	for unit in units:
		_shadow(unit.point, 26)
		_sprite(unit.key, unit.point, 1.0, unit.frame, unit.flip)

func _marker(at: Vector2, color: Color, symbol: String) -> void:
	var radius := 6.5 if symbol.is_empty() else 8.5
	_diamond(at,radius,INK)
	_diamond(at,radius - 2.0,color)
	if not symbol.is_empty():
		_center(symbol,at.x,at.y + 4,11,INK)

func _map_prop(at: Vector2, kind: String) -> void:
	_picture("field/props/" + kind, Rect2(at - Vector2(14,29),Vector2(28,32)))
	if kind == "shrine":
		_diamond(at - Vector2(0,34),4,TEAL)

func _field_atmosphere() -> void:
	if not g.settings.motion:
		return
	var weather: String = g.map.weather
	var time: float = g.elapsed
	if weather == "rain":
		_dots("rain", 0.25)
	else:
		var fall := 12.0 if weather == "petals" else -18.0
		var color := Color("#e3a2a8") if weather == "petals" else (GOLD if weather == "embers" else Color("#b8a6e0"))
		for i in 24:
			var x := fposmod(i * 179.0 + time * 14.0 + 9 * sin(time + i), 640.0)
			var y := 59.0 + fposmod(i * 71.0 + time * fall, 254.0)
			color.a = 0.22 + 0.16 * sin(time * 1.9 + i * 1.1)
			_fill(Rect2(Vector2(x,y).snapped(Vector2(2,2)),Vector2(4 if i % 5 == 0 else 2,2)), color)
	for light in g.map.lights:
		if (g.field_key == "banquet" and (g.slot.hall.wedding or (g.first.wedding_playing and g.line_index >= 3))) or (
				g.field_key == "garden" and g.slot.hall.staff.size() == 2):
			break
		var p := Vector2(light[0],light[1]) * 2.0
		var glint := 0.16 + 0.1 * sin(time * 5.0 + p.x * 0.17)
		_diamond(p, 4, Color(1.0,0.74,0.42,glint))

func _dialogue() -> void:
	var row: Array = g.lines[g.line_index]
	var box := Rect2(34,239,572,101)
	_fill(Rect2(0,206,640,154),Color("#0c112548"))
	var portrait: String = {"聂风":"wind","步惊云":"cloud","第二梦":"dream","雄霸":"boss"}.get(row[0],"")
	if not portrait.is_empty() and (g.chronicle.staged or g.campaign.scene in ["farewell","altar"]):
		_picture("portraits/"+portrait,Rect2(511,145,91,94))
	_panel(box,true)
	_fill(Rect2(49,228,126,24), Color("#28243a"))
	_text(row[0],60,246,16,GOLD,SERIF)
	_paragraph(row[1],57,275,526,17,CREAM,24)
	var advance: String = "点按" if g.touch_ui() else ("A" if g.using_joypad else "Enter")
	_right("%d / %d   ·   %s  继续" % [g.line_index+1,g.lines.size(),advance],583,326,12,DIM)
	_hit(box,"confirm")

func _journal() -> void:
	_fill(FULL,Color("#0b1120ce"))
	_panel(Rect2(43,23,554,314),true)
	_text("江湖手记",67,70,29,CREAM,SERIF)
	if g.afterstory.active:
		_text("潮关余事",69,106,15,GOLD)
		_line(Vector2(68,116),Vector2(573,116),LINE)
		var row := 144
		for entry in g.afterstory.journal():
			_text(entry[0],70,row,15,CREAM)
			_text(entry[1],215,row,14,DIM)
			row += 26
		_journal_back()
		return
	_text("主线",69,100,15,GOLD)
	_text("支线",270,100,15,GOLD)
	_line(Vector2(68,110),Vector2(573,110),LINE)
	for i in Story.CHAPTERS.size():
		var chapter: Dictionary = Story.CHAPTERS[i]
		var status := "已过" if i < g.slot.chapter else ("当前" if i == g.slot.chapter else "待访")
		_text("%s  %s" % [chapter.num,chapter.title],69,136+i*24,14,CREAM if i <= g.slot.chapter else FAINT)
		_right(status,223,136+i*24,12,GOLD if i == g.slot.chapter else DIM)
	var y := 131
	for id in SideStories.TASKS:
		_text(SideStories.TASKS[id].title,270,y,12,CREAM)
		_text(g.chronicle.side.note(id),380,y,11,DIM)
		y += 23
	_journal_back()

func _journal_back() -> void:
	if not g.touch_ui():
		_text("B  返回" if g.using_joypad else "Esc / J  返回",68,313,13,DIM)
		_hit(Rect2(61,292,129,26),"cancel")

func _martial() -> void:
	_fill(FULL,Color("#0b1120ce"))
	_panel(Rect2(70,26,500,305),true)
	_text("准备武学",91,67,26,CREAM,SERIF)
	for i in g.stage.party.size():
		var hero: Dictionary = Story.HEROES[g.stage.party[i]]
		var tab := Rect2(343+94*i,41,89,30)
		_fill(tab,Color("#373248") if g.chronicle.martial_hero == i else INK)
		_stroke(tab,GOLD if g.chronicle.martial_hero == i else LINE)
		_center(hero.name,tab.get_center().x,61,14,CREAM)
		_hit(tab,"martial_hero",i)
	var id: String = g.chronicle.martial_id()
	var learned := Martial.options(id,g.slot.campaign.sword)
	var equipped := Martial.prepared(g.slot,id)
	for i in 2:
		var box := Rect2(91 + i*229,84,219,30)
		_fill(box,Color("#303b4b"))
		_stroke(box,GOLD if g.chronicle.martial_slot == i else LINE)
		var prefix := "栏位 %d" % (i+1) if g.touch_ui() or g.using_joypad else "键 %d" % (i+2)
		_text("%s   %s" % [prefix,learned[int(equipped[i])][0]],box.position.x+9,105,14,CREAM)
		_hit(box,"martial_slot",i)
	for i in 4:
		var box := Rect2(91,127+i*36,152,29)
		var ready := Martial.unlocked(g.slot,id,i)
		_button(learned[i][0],box,i,ready)
		_text("%d 气 · %s" % [learned[i][1],learned[i][5]] if ready else "随修行或任务解锁",
			257,box.position.y+20,13,CREAM if ready else FAINT)
	if g.slot.chapter == 3 and id == "wind":
		_text("魔池试炼会把栏位 2 暂时换成魔刀狂斩。",91,285,12,GOLD)
	var hint: String = "← → 换人   X 换栏位   A 装配   B 返回" if g.using_joypad else "← → 换人   Tab 换栏位   Enter 装配   Esc 返回"
	if g.touch_ui():
		hint = "点按队员和栏位，再点按武学装配"
	else:
		_hit(Rect2(486,290,70,29),"cancel")
	_text(hint,91,312,12,DIM)

func _gear() -> void:
	_fill(FULL,Color("#0b1120ce"))
	_panel(Rect2(58,23,524,309),true)
	_text("行装与境界",80,64,26,CREAM,SERIF)
	for i in g.stage.party.size():
		var hero_name: String = Story.HEROES[g.stage.party[i]].name
		_gear_tab(Rect2(344 + 107*i,38,101,31),hero_name,g.gear_hero == i,"gear_hero",i)
	var hero: String = g.stage.party[g.gear_hero]
	var rank: int = g.rank()
	var stats := Equipment.attributes(hero, rank, Equipment.modifiers(g.slot, hero))
	var progress := "历练 %d / %d" % [g.slot.merit, rank * 4]
	if g.afterstory.active or g.slot.finished:
		progress = "历练 %d" % g.slot.merit
	_text("境界 %d    ·    %s" % [rank, progress],81,87,13,GOLD)
	_right("气血 %d    真气 %d    攻击 %d" % [stats.hp, stats.qi, stats.attack],550,87,13,TEAL)
	for kind in Equipment.CATEGORIES.size():
		var id := Equipment.equipped(g.slot, hero, kind)
		var item_name: String = "未装配" if id.is_empty() else Equipment.CATALOG[id].name
		_gear_tab(Rect2(81 + kind*238,96,231,31),"%s · %s" % [Equipment.CATEGORIES[kind],item_name],g.gear_kind == kind,"gear_kind",kind)
	var ids := Equipment.options(g.gear_kind)
	for i in ids.size():
		var item := ids[i]
		var ready := item.is_empty() or Equipment.unlocked(g.slot,item)
		var box := Rect2(81,134+i*27,150,25)
		_button("卸下" if item.is_empty() else Equipment.CATALOG[item].name,box,i,ready)
		if item.is_empty():
			_text("恢复此栏基础属性",244,box.position.y+17,12,DIM)
		elif ready:
			_text(Equipment.describe(item),244,box.position.y+17,12,CREAM)
			var holder := Equipment.owner(g.slot,item)
			if not holder.is_empty():
				_right("已装备" if holder == hero else "转交自%s" % Story.HEROES[holder].name,551,box.position.y+17,11,GOLD)
		else:
			_text(Equipment.CATALOG[item].source,244,box.position.y+17,12,DIM)
	var hint := "点按队员、栏位和行装" if g.touch_ui() else (
		"← → 换人   X 换栏位   A 装备   B 返回" if g.using_joypad else "← → 换人   Tab 换栏位   Enter 装备   Esc 返回")
	_text(g.gear_message if not g.gear_message.is_empty() else hint,81,317,12,GOLD if not g.gear_message.is_empty() else DIM)

func _gear_tab(box: Rect2, label: String, active: bool, kind: String, index: int) -> void:
	_fill(box,Color("#353141") if active else INK)
	_stroke(box,GOLD if active else LINE)
	_center(label,box.get_center().x,box.get_center().y+5,14,CREAM)
	_hit(box,kind,index)

func _battle() -> void:
	var battle: RefCounted = g.encounter
	var view: Dictionary = combat_art.hud()
	_picture("arenas/" + ("hall" if g.field_key == "returnhall" else String(g.field_key)), Rect2(0,0,640,208))
	_fade(0,118,0.83,true)
	_fade(116,90,0.48)
	_dots("dust",0.16)
	_text(g.battle_info()[0],22,32,24,CREAM,SERIF)
	_text("回合 %02d" % view.round,23,54,13,GOLD)
	var combat_status: String = "境界 6    ·    合击" if g.afterstory.active else "历练  %d    ·    合击" % g.slot.merit
	_right(combat_status,544,29,13,DIM)
	for i in 4:
		_diamond(Vector2(558+i*17,24),5.5,GOLD if i < battle.bond else FAINT)
	for i in battle.allies.size():
		_battle_actor(i,true,view.ally[i],i == battle.actor and not combat_art.active())
	for i in battle.foes.size():
		if not view.foe[i].dormant:
			_battle_actor(i,false,view.foe[i],false)
	combat_art.draw()
	for i in battle.foes.size():
		if not view.foe[i].dormant:
			_battle_enemy_hud(i,view.foe[i])
	if battle.foes[0].id == "gate_guard":
		_first_fight_tip(view)
	_special_battle_tip(view)
	_fill(Rect2(0,206,640,154),Color("#101625"))
	_line(Vector2(0,206),Vector2(640,206),LINE)
	_battle_status(0,view.ally[0],battle.actor == 0)
	_battle_status(1,view.ally[1],battle.actor == 1)
	var description: String
	if g.pending_action >= 0:
		description = "选择队友" if battle.targets_ally(g.pending_action) else "选择敌人"
		if not g.touch_ui():
			description += ("   ·   摇杆或方向键切换 / A 确定 / B 取消" if g.using_joypad
				else "   ·   方向键切换 / Enter 确定 / Esc 取消")
	elif g.mode == "battle":
		if combat_art.active() and g.settings.motion:
			description = "" if g.touch_ui() else ("Y  跳过演出" if g.using_joypad else "空格  跳过演出")
		else:
			description = battle.detail(g.selected)
	else:
		description = ""
	_text(description,22,270,13,GOLD)
	if g.pending_action < 0 and g.mode == "battle":
		_right(battle.log[-1],618,270,12,DIM)
	if g.touch_ui() and g.settings.motion and combat_art.active():
		_touch_battle_button(Rect2(462,289,156,49),"跳过演出","skip")
	elif g.touch_ui() and g.pending_action >= 0:
		_battle_touch_targets(battle)
	else:
		for i in 6:
			_battle_action(i)
	if g.mode != "battle" and (not g.settings.motion or not combat_art.active()):
		hot.clear()
		_fill(FULL,Color("#080e20b2"))
		_panel(Rect2(147,87,346,183),true)
		_center("战胜" if g.mode == "victory" else "败阵",320,137,36,CREAM,SERIF)
		_center(g.debrief,320,163,14,DIM)
		_menu(Vector2(196,182),248,31,5)

func _battle_touch_targets(battle: RefCounted) -> void:
	var friendly: bool = battle.targets_ally(g.pending_action)
	var units: Array = battle.allies if friendly else battle.foes
	for i in units.size():
		var unit: Dictionary = units[i]
		if not unit.get("dormant", false) and (unit.hp > 0 or g.pending_action == 4):
			var box := Rect2(21 + (i % 2) * 202, 278 + floori(i / 2.0) * 38, 196, 34)
			_touch_battle_button(box, unit.name, "ally" if friendly else "foe", i)
	_touch_battle_button(Rect2(425,278,196,72),"取消选招","cancel")

func _touch_battle_button(box: Rect2, label: String, kind: String, index: int = 0) -> void:
	_fill(box, Color("#1c2437"))
	_stroke(box, GOLD if kind != "cancel" else LINE)
	_center(label,box.get_center().x,box.get_center().y + 6,16,CREAM)
	_hit(box,kind,index)

func _first_fight_tip(view: Dictionary) -> void:
	if view.round != 1 or view.foe[0].hp <= 0:
		return
	var tip := "步惊云用排云掌削 2 格势。"
	if view.foe[0].broken:
		tip = "执事已破势，跳过这次重击。"
	elif view.actor == 1:
		tip = "风神腿克制执事，可削 3 格势。" if view.foe[0].poise <= 3 else "聂风可固守，减轻这次重击。"
	_fill(Rect2(22,59,214,33),Color("#111a2beb"))
	_line(Vector2(22,59),Vector2(236,59),GOLD)
	_text("执事蓄势  ›  聂风",30,72,12,GOLD)
	_text(tip,30,86,11,CREAM)

func _special_battle_tip(view: Dictionary) -> void:
	var tip := ""
	match g.encounter.foes[0].id:
		"paper":
			match g.encounter.signal_state:
				"ready": tip = "鸣哨前破势，援兵便来不了"
				"blocked": tip = "哨声已截断"
				"called": tip = "援兵受风霜阻隔" if view.foe[1].dormant and g.encounter.reinforcement_round > 2 else "暗哨已响，援兵入场"
		"first_tyrant":
			if view.foe[0].shield: tip = "三分归元气 · 普攻或武学蓄满四格，再施展合璧"
		"godless": tip = "先破势，金身消散时出重招"
		"tidal_chief":
			tip = "鼓阵护身 · 下一击伤害降低" if view.foe[0].rallied else ("可击倒或破势打断鼓手" if view.foe[1].hp > 0 else "")
		"boss":
			if view.foe[0].shield:
				tip = "%s  %d / 2 破势  ·  合璧可破" % ["三分归元气" if g.encounter.advanced else "龙脉护气",view.foe[0].cracks]
	if int(g.slot.chapter) == 3:
		tip = "魔念  %d / 6  ·  固守与回春诀可压制" % view.corruption
	if not tip.is_empty():
		_fill(Rect2(22,63,272,23),Color("#111a2beb"))
		_text(tip,30,79,12,RED if view.corruption >= 4 else GOLD)

func _battle_actor(index: int, ally: bool, stats: Dictionary, current: bool) -> void:
	var battle: RefCounted = g.encounter
	var unit: Dictionary = battle.allies[index] if ally else battle.foes[index]
	var p: Vector2 = combat_art.point(index,ally)
	var active: bool = current and g.mode == "battle"
	var is_target: bool = g.mode == "battle" and g.pending_action >= 0 and index == g.target and (battle.targets_ally(g.pending_action) == ally)
	var visible_alive: bool = stats.hp > 0 or combat_art.falling(index, ally)
	var color := Color.WHITE if visible_alive else Color(0.55,0.58,0.71,0.33)
	if is_target:
		var y := p.y + 3
		_line(Vector2(p.x-25,y),Vector2(p.x-11,y),GOLD,2)
		_line(Vector2(p.x+11,y),Vector2(p.x+25,y),GOLD,2)
	var frame := 0 if visible_alive else 7
	if visible_alive and g.settings.motion:
		frame = 2 if fposmod(g.elapsed + index * 0.18, 1.45) >= 0.86 else 0
	var pose: Dictionary = combat_art.pose(index,ally,frame)
	var rendered: Vector2 = p + pose.offset
	_shadow(Vector2(rendered.x,p.y), 64)
	if not ally and (stats.shield or stats.rallied):
		var glow := 0.47 + (0.11 * sin(g.elapsed * 4.0) if g.settings.motion else 0.0)
		_line(p + Vector2(-38,0),p + Vector2(38,0),Color(0.94,0.70,0.33,glow),2)
	var art: String = pose.art if not pose.art.is_empty() else (unit.id if ally else unit.sprite)
	_sprite(art,rendered,2.0,0 if not pose.art.is_empty() else pose.frame,not ally,color)
	if active:
		_diamond(p + Vector2(0,2),6,TEAL)

func _battle_enemy_hud(index: int, stats: Dictionary) -> void:
	var battle: RefCounted = g.encounter
	var unit: Dictionary = battle.foes[index]
	var p: Vector2 = combat_art.point(index,false)
	const WIDTH := 124
	var x := p.x - WIDTH / 2.0
	var y := 40.0 if battle.foes.size() == 1 else 44.0
	_fill(Rect2(x-4,y-2,WIDTH+8,52),Color("#0e1426e8"))
	_center(unit.name,p.x,y+12,16,CREAM,SERIF)
	_bar(Rect2(x,y+18,WIDTH,5),stats.hp,unit.max_hp,RED)
	for i in int(unit.max_poise):
		_fill(Rect2(x + i*8,y+27,6,4),GOLD if i < stats.poise else Color("#42425a"))
	_right("弱" + unit.weak,x+WIDTH,y+32,11,TEAL)
	var note: String = "退场" if stats.hp <= 0 else ("破势 · 跳过行动" if stats.broken else stats.intent)
	if stats.shield:
		note = "护气 · " + note
	elif stats.rallied and stats.hp > 0:
		note = "鼓阵 · " + note
	elif stats.frost > 0 and stats.hp > 0:
		note = "霜印 %d · " % stats.frost + note
	elif unit.phase == "armor" and not stats.broken and stats.hp > 0:
		note = "金身 · " + note
	_center(note,p.x,y+45,10 if note.length() > 13 else 11,GOLD if stats.broken or stats.shield else DIM)
	if unit.hp > 0:
		_hit(Rect2(p.x-60,y-3,120,206-y),"foe",index)

func _bar(box: Rect2, amount: float, maximum: float, color: Color) -> void:
	_fill(box,Color("#30374e"))
	if amount > 0:
		_fill(Rect2(box.position,Vector2(roundf(box.size.x * clampf(amount/maximum,0,1)),box.size.y)),color)

func _battle_status(index: int, stats: Dictionary, current: bool) -> void:
	var battle: RefCounted = g.encounter
	var unit: Dictionary = battle.allies[index]
	var box := Rect2(21 + index*302,213,296,39)
	var focus: bool = current and g.mode == "battle"
	var chosen: bool = battle.targets_ally(g.pending_action) and g.target == index
	_fill(box,Color("#232941"))
	_stroke(box,GOLD if chosen else (TEAL if focus else LINE))
	_text(unit.name,box.position.x+10,box.position.y+18,16,Color(unit.color),SERIF)
	var status: String = unit.title if stats.hp > 0 else "已倒地"
	if stats.hp > 0 and (stats.ward or stats.protector >= 0):
		status = "护持" if stats.ward else "有人代挡"
	_text(status,box.position.x+10,box.position.y+33,11,DIM)
	var xx := box.position.x+88
	_text("血",xx,box.position.y+16,11,DIM)
	_text("气",xx,box.position.y+32,11,DIM)
	_bar(Rect2(xx+19,box.position.y+10,103,6),stats.hp,unit.max_hp,TEAL)
	_bar(Rect2(xx+19,box.position.y+26,103,6),stats.qi,unit.max_qi,Color("#93a9e7"))
	_right("%d / %d" % [stats.hp,unit.max_hp],box.end.x-10,box.position.y+17,12,CREAM)
	_right("%d / %d" % [stats.qi,unit.max_qi],box.end.x-10,box.position.y+33,12,DIM)
	_hit(box,"ally",index)

func _battle_action(index: int) -> void:
	var battle: RefCounted = g.encounter
	var box := Rect2(21 + (index%3)*202,278 + floori(index / 3.0)*(38 if g.touch_ui() else 34),196,34 if g.touch_ui() else 29)
	var enabled: bool = battle.available(index)
	var focus: bool = (index == g.selected or box.has_point(g.get_global_mouse_position())) and enabled
	_fill(box,Color("#393343") if focus else Color("#1c2437"))
	_stroke(box,GOLD if focus else LINE)
	if not g.touch_ui():
		_text(str(index+1),box.position.x+9,box.position.y+20,13,GOLD if enabled else FAINT)
	_text(battle.label(index),box.position.x+(12 if g.touch_ui() else 31),box.get_center().y+6,16,CREAM if enabled else FAINT)
	if enabled:
		_hit(box,"action",index)

func _ending_path() -> String:
	return "paintings/ending" if g.picture("paintings/ending") != null else "paintings/village"

func _ending() -> void:
	_picture(_ending_path())
	_fade(229,131,0.66)
	_fill(Rect2(0,0,319,360),Color("#090d2148"))
	_text("尾 声",46,70,15,GOLD)
	_text("凤溪灯火",43,130,51,CREAM,SERIF)
	var closing: String = "天光落在渡口。那盏灯还在桥上。" if g.chronicle.has("dawn_lamp") else "他将一盏灯放在桥栏上，待雨轻了，才随同伴走进山里。"
	_paragraph(closing,48,177,243,18,CREAM,26)
	_text("六章旅程已毕   ·   历练 %d" % g.slot.merit,48,245,15,GOLD)
	_menu(Vector2(48,262),197,29,4)
	_text("改编自电视剧《风云》   原作漫画：马荣成",48,344,12,DIM)

