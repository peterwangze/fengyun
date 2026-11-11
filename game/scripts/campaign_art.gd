extends RefCounted

const GOLD := Color("#e8c185")
const TEAL := Color("#75d6cb")
const RED := Color("#ef8d80")

var g

func _init(game: Node2D) -> void:
	g = game

func stage(units: Array, marks: Array[Dictionary]) -> void:
	var screen: RefCounted = g.screen
	var flags: Dictionary = g.slot.campaign
	match g.field_key:
		"village": _river(units)
		"forge":
			_prop("winch",g.position_of("winch"),1.0, Color.WHITE if not flags.forge_gate else Color(0.75,0.88,0.87))
			if not flags.forge_gate:
				_barrier(Vector2(319,194),Color("#ef9a65"))
			if g.slot.cleared.has(1) and not flags.sword:
				_draw_sword(g.position_of("sword"))
		"jail": _jail(units)
		"lodge":
			units.append(screen._unit("dream",g.position_of("bedside"),7,true))
			_prop("signal",g.position_of("lamp") + Vector2(57,61),0.55,Color("#dfba9d"))
		"peak":
			if g.slot.cleared.has(0) and not flags.altar:
				units.append(screen._unit("boss",g.position_of("altar") + Vector2(0,-13),0,true))
	for point in g.campaign.all_points():
		var label: String = point.name
		if g.mode == "field":
			var destination: Vector2 = point.pos
			if point.id in ["board","mooring","winch"]:
				screen._door_label(label,destination)
			marks.append({"point":destination - Vector2(0,29),"color":TEAL})
	if not g.campaign.scene.is_empty():
		_direct_scene(units)
		marks.clear()

func _prop(key: String, foot: Vector2, scale: float = 1.0, shade: Color = Color.WHITE) -> void:
	var texture: Texture2D = g.picture("field/props/" + key)
	var size := (texture.get_size() * scale).round()
	g.draw_texture_rect(texture,Rect2((foot - Vector2(size.x/2,size.y)).round(),size),false,shade)

func _river(units: Array) -> void:
	var screen: RefCounted = g.screen
	var flags: Dictionary = g.slot.campaign
	var waiting: bool = flags.crossing.is_empty()
	var boat: Vector2 = g.campaign.ferry_point() if g.mode == "ferry" else g.position_of("boat_east" if waiting else "boat_west")
	_prop("boat",boat,1.50)
	for key in ["board","west_spawn"]:
		var p: Vector2 = g.position_of(key)
		for i in 3:
			var step := 1.0 if key == "board" else -1.0
			screen._fill(Rect2(p.x - 6 - i * 7.0 * step,p.y-3,6,10),Color("#66534a"))
			screen._line(p + Vector2(-6 - i * 7.0 * step,-2),p + Vector2(-1 - i * 7.0 * step,-2),Color("#b18a63"))
	if waiting:
		_prop("signal",Vector2(390,192),0.85)
	if not g.slot.cleared.has(0):
		_barrier(Vector2(320,201),Color("#edaa70"))
	if g.mode == "ferry":
		units.clear()
		units.append_array([screen._unit("boatman_front",boat+Vector2(-29,-5)),
			screen._unit("wind_front",boat+Vector2(-3,-3)),
			screen._unit("frost_front",boat+Vector2(22,-4))])
		if g.settings.motion:
			for i in 5:
				var wash := boat + Vector2(19+i*9, 2+i*3)
				screen._line(wash,wash+Vector2(21,0),Color(0.51,0.74,0.78,0.39-i*0.055))

func _barrier(at: Vector2, shade: Color) -> void:
	var screen: RefCounted = g.screen
	for x in [-12,12]:
		screen._fill(Rect2(at.x+x-3,at.y-22,6,24),Color("#40313a"))
		screen._fill(Rect2(at.x+x-4,at.y-24,8,4),shade)
	screen._line(at+Vector2(-15,-9),at+Vector2(15,-9),shade,3)
	screen._line(at+Vector2(-15,-17),at+Vector2(15,-17),shade,2)

func _draw_sword(at: Vector2) -> void:
	var screen: RefCounted = g.screen
	screen._line(at+Vector2(-10,3),at+Vector2(7,-26),Color("#202438"),7)
	screen._line(at+Vector2(-8,0),at+Vector2(7,-24),Color("#b9d2df"),3)
	screen._line(at+Vector2(-8,-8),at+Vector2(3,-3),GOLD,3)
	screen._diamond(at-Vector2(0,29),4,GOLD)

func _jail(units: Array) -> void:
	var screen: RefCounted = g.screen
	var spot: Vector2 = g.position_of("prisoner")
	var exit: Vector2 = g.position_of("jail_exit")
	screen._map_prop(exit,"exit_open")
	if not g.slot.campaign.rescued:
		units.append(screen._unit("prisoner",spot,0,true))
		if g.campaign.scene != "rescue":
			for i in 7:
				screen._line(spot+Vector2(-33+i*11,-51),spot+Vector2(-33+i*11,4),Color("#263347"),3)
	elif g.settings.motion and g.elapsed - g.campaign.rescue_started < 1.4:
		var t := clampf((g.elapsed - g.campaign.rescue_started) / 1.4,0.0,1.0)
		var foot := spot.lerp(exit,t)
		units.append(screen._unit("prisoner",foot,floori(t * 12) % 4,true))

func _direct_scene(units: Array) -> void:
	var screen: RefCounted = g.screen
	var scene: String = g.campaign.scene
	var tick := 1.0 if not g.settings.motion else clampf((g.elapsed - g.campaign.scene_started)/0.46,0.0,1.0)
	var key: String = {"reunion":"reunion","sword":"sword","pool_trial":"pool_trial","pool_break":"exit",
		"rescue":"cell","farewell":"bedside","altar":"altar"}[scene]
	var p: Vector2 = g.position_of(key)
	units.clear()
	match scene:
		"reunion":
			units.append_array([screen._unit("wind",p+Vector2(45,-18),0,true),
				screen._unit("frost_front",p+Vector2(0,-15)),
				screen._unit("cloud",p+Vector2(-22-25*tick,-20))])
		"sword":
			units.append_array([screen._unit("cloud",p+Vector2(-29,8),4 if g.line_index == 0 else 0),
				screen._unit("wind",p+Vector2(32,15),0,true)])
			_draw_sword(p + Vector2(0,-16*tick))
		"pool_trial","pool_break":
			units.append_array([screen._unit("wind",p+Vector2(-18,16),4 if g.line_index == 0 else 6),
				screen._unit("dream",p+Vector2(35-18*tick,12),0,true),screen._unit("sage",p+Vector2(12,-8))])
			if g.settings.motion:
				screen._picture("vfx/dark",Rect2(p-Vector2(38,52),Vector2(71,53)),Color(1,0.83,0.98,(1.0-tick)*0.70))
		"rescue":
			units.append_array([screen._unit("sage",p+Vector2(-30,16)),
				screen._unit("cloud",p+Vector2(30,14),0,true),screen._unit("prisoner",p+Vector2(0,-12+14*tick))])
		"farewell":
			if g.line_index >= 3:
				screen._fill(Rect2(0,52,640,270),Color("#10162d70"))
			var grieving: bool = g.line_index >= 3
			units.append_array([screen._unit("wind" if grieving else "wind_front",p+Vector2(-28,13),5 if grieving else 0),
				screen._unit("dream",p+Vector2(7,-6),7,true),screen._unit("cloud",p+Vector2(94,18),0,true)])
		"altar":
			units.append_array([screen._unit("boss",p+Vector2(0,-5),5),
				screen._unit("wind",p+Vector2(-40,34)),screen._unit("cloud",p+Vector2(38,29),0,true)])
			if g.settings.motion:
				screen._diamond(p-Vector2(0,52),6.0+5.0*tick,Color(0.97,0.74,0.35,0.64-0.20*tick))

