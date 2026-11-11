extends Node2D

const Story = preload("res://scripts/story.gd")
const Battle = preload("res://scripts/battle.gd")
const Save = preload("res://scripts/save.gd")
const Screen = preload("res://scripts/screen.gd")
const FirstChapter = preload("res://scripts/first_chapter.gd")
const Campaign = preload("res://scripts/campaign.gd")
const Chronicle = preload("res://scripts/chronicle.gd")
const Martial = preload("res://scripts/martial.gd")
const Afterstory = preload("res://scripts/afterstory.gd")
const MobileControls = preload("res://scripts/mobile_controls.gd")
const FOLLOW_GAP := 32.0
const MENU_STICK_PRESS := 0.65
const MENU_STICK_RELEASE := 0.30

var screen: RefCounted
var first: RefCounted
var campaign: RefCounted
var chronicle: RefCounted
var afterstory: RefCounted
var storage: RefCounted
var music := AudioStreamPlayer.new()
var effects := AudioStreamPlayer.new()
var texture_cache := {}
var audio_cache := {}
var music_key := ""
var music_fade: Tween
var slot := {}
var settings := {}
var stage := {}
var map := {}
var field_key := ""
var walls: Array[Rect2] = []
var hazards: Array[PackedVector2Array] = []
var ground := PackedVector2Array()
var mode := "title"
var back_mode := "title"
var elapsed := 0.0
var player := Vector2.ZERO
var follower := Vector2.ZERO
var facing := 1
var field_direction := "side"
var moving := false
var follow_facing := 1
var follow_direction := "side"
var follow_moving := false
var trail: Array[Vector2] = []
var trail_length := 0.0
var walk_distance := 0.0
var follow_distance := 0.0
var selected := 0
var target := 0
var pending_action := -1
var active_battle := -1
var encounter: RefCounted
var effect_started := 0.0
var effect_duration := 0.0
var effect_before := {}
var result_cue := ""
var lines: Array = []
var line_index := 0
var after_talk: Callable
var toast := ""
var toast_time := 0.0
var debrief := ""
var battle_reward := 0
var chosen_easy := false
var using_joypad := false
var touch_controls: MobileControls
var active_pad := -1
var menu_sticks: Dictionary[int, Vector2] = {}
var held_menu_sticks: Dictionary[int, bool] = {}

func _ready() -> void:
	var suffix := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--profile="):
			var candidate := arg.get_slice("=",1)
			if candidate.is_valid_identifier():
				suffix = candidate
	storage = Save.new(suffix)
	settings = storage.get_settings()
	add_child(music)
	add_child(effects)
	music.volume_db = -9
	effects.volume_db = -7
	_apply_settings()
	slot = storage.read()
	first = FirstChapter.new(self)
	campaign = Campaign.new(self)
	chronicle = Chronicle.new(self)
	afterstory = Afterstory.new(self)
	screen = Screen.new(self)
	if OS.has_feature("android") or "--touch-controls" in OS.get_cmdline_user_args():
		touch_controls = MobileControls.new()
		get_window().go_back_requested.connect(cancel)
	Input.joy_connection_changed.connect(_joypad_connection_changed)
	selected = 1 if slot.is_empty() else 0
	_play_music("title")
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	if not result_cue.is_empty() and elapsed >= effect_started + effect_duration:
		_finish_result_audio()
	toast_time = maxf(0.0, toast_time - delta)
	if mode == "field":
		_update_walk(delta)
		if first.active():
			first.update(delta)
	elif mode == "ferry":
		campaign.update(delta)
	queue_redraw()

func _draw() -> void:
	if screen:
		screen.paint()
		if touch_ui():
			touch_controls.paint(self, _touch_mode())

func touch_ui() -> bool:
	return touch_controls != null and not using_joypad

func _notification(what: int) -> void:
	if touch_controls == null:
		return
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			touch_controls.release()
			menu_sticks.clear()
			held_menu_sticks.clear()

func picture(path: String) -> Texture2D:
	if not texture_cache.has(path):
		var filename := "res://assets/%s.png" % path
		texture_cache[path] = load(filename) if ResourceLoader.exists(filename) else null
	return texture_cache[path]

func _audio(key: String) -> AudioStreamOggVorbis:
	if not audio_cache.has(key):
		var path := "res://assets/audio/%s.ogg" % key
		audio_cache[key] = load(path) if ResourceLoader.exists(path) else null
	return audio_cache[key]

func _play_music(key: String) -> void:
	if key == music_key:
		return
	var stream := _audio(key)
	if stream == null:
		return
	music_key = key
	if DisplayServer.get_name() == "headless":
		return
	stream.loop = true
	music.stream = stream
	if music_fade and music_fade.is_valid():
		music_fade.kill()
	music.volume_db = -21.0
	music.play()
	music_fade = create_tween()
	music_fade.tween_property(music,"volume_db",-9.0,0.36)

func sfx(key: String) -> void:
	if settings.mute or DisplayServer.get_name() == "headless":
		return
	var stream := _audio(key)
	if stream:
		effects.stream = stream
		effects.play()

func _apply_settings() -> void:
	AudioServer.set_bus_mute(0, settings.mute)
	if not OS.has_feature("android") and DisplayServer.get_name() != "headless":
		var wanted := Window.MODE_FULLSCREEN if settings.full else Window.MODE_WINDOWED
		if get_window().mode != wanted:
			get_window().mode = wanted

func menu_items() -> Array:
	match mode:
		"title":
			var resume := "继续旅程"
			if slot.get("finished", false):
				resume = "重看尾声"
			var items := [[resume, not slot.is_empty()], ["开启新篇", true], ["设置", true], ["退出游戏", true],
				["凤溪试玩" if slot.is_empty() else "章节回看", true]]
			if slot.get("finished",false):
				items.append([afterstory.title_item(),true])
			return items
		"new":
			return [["江湖 · 标准", true], ["说书 · 轻松", true], ["返回", true]]
		"overwrite":
			return [["开启并覆盖旧档", true], ["保留旧档", true]]
		"pause":
			return [["回到旅程", true], ["江湖手记", true], ["设置", true], ["准备武学",true],["回到标题", true]]
		"martial": return chronicle.martial_items()
		"choice": return chronicle.options.map(func(option): return [option[0],true])
		"review":
			var chapters := []
			for at in Story.CHAPTERS.size():
				chapters.append([Story.CHAPTERS[at].title,at <= slot.chapter])
			return chapters
		"settings":
			var items := [["声音  %s" % ("关" if settings.mute else "开"), true],
				["动态特效  %s" % ("开" if settings.motion else "关"), true]]
			if not OS.has_feature("android"):
				items.append(["窗口模式  %s" % ("全屏" if settings.full else "窗口"), true])
			items.append(["返回", true])
			return items
		"victory":
			return [["返回地图", true]]
		"defeat":
			return [["再战一场", true], ["返回地图", true]]
		"ending":
			if slot.finished and not chronicle.review:
				return [["回到标题",true],[afterstory.title_item(),true]]
			return [["回到标题", true]]
	return []

func _set_mode(next: String, choice: int = 0) -> void:
	if touch_controls:
		touch_controls.release()
	mode = next
	selected = 1 if mode == "title" and slot.is_empty() else choice
	screen.hot.clear()
	queue_redraw()

func _title() -> void:
	chronicle.review = false
	chronicle.special = ""
	afterstory.reset()
	slot = storage.read()
	_set_mode("title", 1 if slot.is_empty() else 0)
	_play_music("title")

func menu_confirm(index: int) -> void:
	var items := menu_items()
	if index < 0 or index >= items.size() or not items[index][1]:
		return
	sfx("confirm")
	match mode:
		"title":
			match index:
				0:
					if slot.finished:
						_show_ending()
					else:
						_enter_chapter(not slot.intro_seen)
				1: _set_mode("new")
				2:
					back_mode = "title"
					_set_mode("settings")
				3: get_tree().quit()
				4:
					if slot.is_empty():
						_start_review(1,false)
					else:
						_set_mode("review")
				5: afterstory.resume()
		"new":
			if index == 2:
				_title()
			elif not slot.is_empty():
				chosen_easy = index == 1
				_set_mode("overwrite", 1)
			else:
				_new_game(index == 1)
		"overwrite":
			if index == 0:
				_new_game(chosen_easy)
			else:
				_set_mode("new")
		"pause":
			match index:
				0: _set_mode("field")
				1:
					back_mode = "pause"
					_set_mode("journal")
				2:
					back_mode = "pause"
					_set_mode("settings")
				3: _open_martial("pause")
				4: _title()
		"martial": chronicle.equip(index)
		"choice": chronicle.select_choice(index)
		"review":
			_start_review(index,slot.easy)
		"settings":
			if index == items.size() - 1:
				_set_mode(back_mode)
				return
			var key: String = ["mute","motion","full"][index]
			settings[key] = not settings[key]
			storage.set_settings(settings)
			_apply_settings()
		"victory":
			_finish_result_audio()
			if chronicle.special.is_empty():
				_return_to_field()
			else:
				chronicle.leave_special()
		"defeat":
			_finish_result_audio()
			if index == 0:
				_start_battle()
			else:
				chronicle.special = ""
				_return_to_field()
		"ending":
			if index == 1:
				afterstory.resume()
			else:
				_title()

func _new_game(easy: bool) -> void:
	slot = storage.fresh(easy)
	_commit()
	_enter_chapter(true)

func _start_review(chapter: int, easy: bool) -> void:
	slot = storage.replay(chapter,easy)
	chronicle.review = true
	_enter_chapter(true)

func rank() -> int:
	if afterstory.active:
		return 6
	return 1 + int(slot.get("merit", 0) / 4.0)

func _enter_chapter(intro: bool) -> void:
	stage = Story.CHAPTERS[int(slot.chapter)]
	first.reset_scene()
	var entry: Array = chronicle.entry()
	if entry.is_empty():
		entry = [slot.hall.room,"spawn"] if first.active() else campaign.field_entry()
	_load_field(entry[0],entry[1])
	_set_mode("field")
	_play_music(chronicle.music_for_field())
	if intro:
		var opening: Array = chronicle.opening()
		_talk(stage.opening if opening.is_empty() else opening,_finish_intro)

func _load_field(key: String, arrival: String = "spawn") -> void:
	field_key = key
	toast_time = 0
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/field/%s.json" % key))
	map = data
	ground = _polygon(map.ground)
	walls.clear()
	for box in map.walls:
		walls.append(Rect2(box[0] * 2, box[1] * 2, box[2] * 2, box[3] * 2))
	hazards.clear()
	for shape in map.get("hazards", []):
		hazards.append(_polygon(shape))
	player = position_of(arrival)
	facing = -1 if map.has("fights") and position_of("fights").x < player.x else 1
	follow_facing = facing
	field_direction = "side"
	follow_direction = "side"
	_place_follower()
	moving = false
	follow_moving = false
	walk_distance = 0.0
	follow_distance = 0.0
	campaign.loaded()

func _finish_intro() -> void:
	slot.intro_seen = true
	_commit()
	_return_to_field()

func _commit() -> void:
	if chronicle.review:
		return
	if not storage.write(slot):
		_notice("存档写入失败。请确认本机存储空间。")

func position_of(key: String, index: int = 0) -> Vector2:
	var cell: Array = map.fights[index] if key == "fights" else map[key]
	return Vector2(float(cell[0]), float(cell[1])) * 2.0

func _polygon(points: Array) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	for point in points:
		polygon.append(Vector2(point[0], point[1]) * 2.0)
	return polygon

func _update_walk(delta: float) -> void:
	var direction := Vector2(
		float(_held(KEY_D, KEY_RIGHT)) - float(_held(KEY_A, KEY_LEFT)),
		float(_held(KEY_S, KEY_DOWN)) - float(_held(KEY_W, KEY_UP)))
	if direction == Vector2.ZERO and touch_ui():
		direction = touch_controls.direction
	var pads := Input.get_connected_joypads()
	if direction == Vector2.ZERO and not pads.is_empty():
		var device := active_pad if pads.has(active_pad) else pads[0]
		var stick := Vector2(Input.get_joy_axis(device, JOY_AXIS_LEFT_X), Input.get_joy_axis(device, JOY_AXIS_LEFT_Y))
		if stick.length() > 0.25:
			direction = stick.limit_length()
		else:
			direction = Vector2(float(Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_RIGHT))
				- float(Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_LEFT)),
				float(Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_DOWN))
				- float(Input.is_joy_button_pressed(device, JOY_BUTTON_DPAD_UP)))
		if direction != Vector2.ZERO:
			_use_joypad(device)
	walk(direction, delta)

func walk(direction: Vector2, delta: float) -> void:
	if mode != "field":
		return
	direction = direction.limit_length()
	var velocity := direction * (148.0 if Input.is_physical_key_pressed(KEY_SHIFT) else 101.0) * delta
	var previous := player
	var next := player + Vector2(velocity.x, 0)
	if passable(next):
		player = next
	next = player + Vector2(0, velocity.y)
	if passable(next):
		player = next
	moving = previous.distance_squared_to(player) > 0.005
	if moving and absf(direction.x) > 0.05:
		facing = 1 if direction.x > 0 else -1
	follow_moving = false
	if moving:
		var step := player - previous
		field_direction = _walk_orientation(step)
		var traveled := step.length()
		walk_distance += traveled
		_follow_path(traveled)
	if not first.active():
		campaign.update(delta)

func _follow_path(traveled: float) -> void:
	trail.append(player)
	trail_length += traveled
	while trail.size() > 2:
		var first_length := trail[0].distance_to(trail[1])
		if trail_length - first_length < FOLLOW_GAP:
			break
		trail_length -= first_length
		trail.pop_front()
	if trail_length < FOLLOW_GAP:
		return
	var before := follower
	var span := trail[0].distance_to(trail[1])
	follower = trail[0].lerp(trail[1], clampf((trail_length - FOLLOW_GAP) / span, 0.0, 1.0))
	var step := follower - before
	follow_moving = step.length_squared() > 0.01
	if follow_moving:
		follow_direction = _walk_orientation(step)
	follow_distance += step.length()
	if absf(step.x) > 0.12:
		follow_facing = 1 if step.x > 0 else -1

func _walk_orientation(step: Vector2) -> String:
	if absf(step.y) > absf(step.x) * 1.05:
		return "back" if step.y < 0 else "front"
	return "side"

func _place_follower() -> void:
	follower = player
	for offset in [Vector2(-30 * facing,10), Vector2(-28 * facing,-14),
			Vector2(25 * facing,19), Vector2(27 * facing,-16), Vector2(0,-32)]:
		if passable(player + offset) and passable(player + offset / 2):
			follower += offset
			break
	trail = [player]
	trail_length = follower.distance_to(player)
	if trail_length > 0:
		trail.push_front(follower)

func passable(point: Vector2) -> bool:
	if not Rect2(17, 61, 606, 254).has_point(point):
		return false
	if not Geometry2D.is_point_in_polygon(point, ground):
		return false
	for box in walls:
		if box.grow(3).has_point(point):
			return false
	for polygon in hazards:
		if Geometry2D.is_point_in_polygon(point, polygon):
			return false
	if afterstory.active:
		return not afterstory.blocked(point)
	if not first.active() and campaign.blocked(point):
		return false
	return true

func _held(first: Key, second: Key) -> bool:
	return Input.is_physical_key_pressed(first) or Input.is_physical_key_pressed(second)

func nearest() -> Dictionary:
	var points: Array
	if afterstory.active:
		points = afterstory.points()
	else:
		points = first.points() if first.active() else campaign.all_points()
		points.append_array(chronicle.points())
	if map.has("fights"):
		points.append_array([
			{"id":"shrine","pos":position_of("shrine"),"name":"石灯 · 存档","index":-1},
			{"id":"exit","pos":position_of("exit"),"name":"东侧山门" if first.active() else "离开此地","index":-1}])
		if field_key != "village" or not slot.campaign.rope or not slot.campaign.crossing.is_empty() or not campaign.ferry_ready():
			points.append({"id":"guide","pos":guide_point(),"name":stage.guide,"index":-1})
		if not slot.chest:
			points.append({"id":"chest","pos":position_of("chest"),"name":"开启药箱","index":-1})
		for i in 3:
			if visible_encounter(i):
				points.append({"id":"fight","pos":position_of("fights",i),"name":stage.battles[i][0],"index":i})
	var best := {}
	var limit := 35.0
	for spot in points:
		var distance := player.distance_to(spot.pos)
		if distance < limit:
			limit = distance
			best = spot
	return best

func interact() -> void:
	var spot := nearest()
	if spot.is_empty():
		return
	sfx("confirm")
	if afterstory.active:
		afterstory.handle(spot.id)
		return
	if chronicle.handle(spot.id):
		return
	if first.active() and first.handle(spot.id):
		return
	if not first.active() and campaign.handle(spot.id):
		return
	match spot.id:
		"guide": _talk(stage.hint, _return_to_field)
		"shrine":
			toast_time = 0
			_commit()
			if toast_time <= 0:
				_notice("已于石灯存档。")
		"chest":
			slot.chest = true
			var amount := mini(2, 9 - int(slot.tonics))
			slot.tonics += amount
			_notice("得到金创药 ×%d。" % amount if amount > 0 else "药囊已满。")
			_commit()
		"fight":
			if spot.index == 1 and not slot.cleared.has(0):
				_notice("先击退前路的第一队敌人。")
				return
			_approach_battle(spot.index)
		"exit":
			if not slot.cleared.has(1):
				_notice("完成两场主线战斗后，才能离开。")
			else:
				_talk(stage.closing, _next_chapter)

func guide_point() -> Vector2:
	if field_key == "village":
		return campaign.boatman if slot.campaign.crossing.is_empty() else position_of("west_spawn") + Vector2(15,-21)
	return position_of("guide")

func _notice(message: String) -> void:
	toast = message
	toast_time = 3.8

func _talk(dialogue: Array, callback: Callable) -> void:
	toast_time = 0
	lines = dialogue
	line_index = 0
	after_talk = callback
	_set_mode("dialogue")

func _advance_talk() -> void:
	sfx("select")
	line_index += 1
	if first.wedding_playing:
		first.line_started = elapsed
		if line_index == 3:
			sfx("clang")
	if not campaign.scene.is_empty():
		campaign.scene_started = elapsed
	if line_index >= lines.size():
		var callback := after_talk
		after_talk = Callable()
		callback.call()

func _next_chapter(confirmed: bool = false) -> void:
	if slot.chapter < 5 and not confirmed and chronicle.warn_departure(_next_chapter.bind(true)):
		return
	if chronicle.review and slot.chapter < 5:
		_title()
		return
	if int(slot.chapter) == Story.CHAPTERS.size() - 1:
		if field_key == "peak" and not confirmed and chronicle.warn_departure(_next_chapter.bind(true),"lamps"):
			return
		if chronicle.finish_chapter():
			return
		slot.finished = true
		_commit()
		_show_ending()
		return
	slot.chapter += 1
	slot.chronicle.room = ""
	slot.chest = false
	slot.intro_seen = false
	slot.cleared = []
	slot.tonics = mini(9, int(slot.tonics) + 1)
	_commit()
	_enter_chapter(true)

func _show_ending() -> void:
	_play_music("ending")
	var ending: Array = chronicle.ending()
	_talk(Story.ENDING if ending.is_empty() else ending,func(): _set_mode("ending"))

func _return_to_field() -> void:
	_set_mode("field")
	if afterstory.active:
		_play_music("village" if field_key == "tidal_ford" else "palace")
		return
	_play_music(chronicle.music_for_field())

func visible_encounter(index: int) -> bool:
	if not chronicle.encounter_open(index):
		return false
	return first.courtyard_fight(index) if first.active() else campaign.can_show_fight(index)

func battle_info() -> Array:
	if afterstory.active:
		return Afterstory.ENCOUNTERS[afterstory.battle]
	if not chronicle.special.is_empty():
		return Chronicle.SPECIALS[chronicle.special]
	if field_key == "garden" and active_battle == 1:
		return FirstChapter.REAR_FIGHT
	return stage.battles[active_battle]

func _approach_battle(index: int) -> void:
	chronicle.special = ""
	active_battle = index
	_talk(battle_info()[2], _start_battle)

func _start_battle() -> void:
	toast_time = 0
	var prepared := {}
	for id in stage.party:
		prepared[id] = Martial.prepared(slot,id)
	var stock: int = afterstory.state().tonics if afterstory.active else slot.tonics
	encounter = Battle.new(stage.party, battle_info()[1], rank(),
		stock, slot.easy, int(slot.chapter), slot.campaign.sword,prepared,afterstory.active or chronicle.enabled())
	pending_action = -1
	effect_duration = 0.0
	target = 0
	_set_mode("battle")
	var boss: bool = afterstory.battle == "chief" if afterstory.active else active_battle == 1 or chronicle.special == "first_tyrant"
	var final_boss: bool = not afterstory.active and boss and slot.chapter == 5 and chronicle.enabled()
	_play_music("peak_final" if final_boss else ("boss" if boss else "battle"))

func battle_choose(action: int) -> void:
	if not encounter.available(action):
		_notice("当前招式尚不可用。")
		return
	_skip_battle_effect()
	selected = action
	if action in [3,5] or encounter._automatic(action):
		_battle_act(action, 0)
		return
	pending_action = action
	target = encounter.weakest_ally(action != 4) if encounter.targets_ally(action) else encounter.living_foe()
	sfx("select")

func _battle_act(action: int, at: int) -> void:
	var before: Dictionary = encounter.presentation()
	if not encounter.act(action, at):
		return
	effect_before = before
	pending_action = -1
	effect_started = elapsed
	var last_beat := int(encounter.events.back().beat)
	effect_duration = 0.66 + 0.30 * last_beat + (0.19 if action == 5 else 0.0)
	var cue: String = ["clang","clang","clang","guard","heal","combo"][action]
	if encounter.advanced and action in [1,2]:
		cue = {"wind":"cast_wind","cloud":"cast_cloud","frost":"cast_frost","blade":"cast_blade",
			"dark":"cast_dark","heal":"heal","guard":"guard"}.get(encounter.events[0].style,"clang")
	if action in [0, 1, 2] and encounter.events.any(func(event: Dictionary): return event.kind == "break"):
		cue = "break"
	if encounter.events.any(func(event: Dictionary): return event.kind == "arrival"):
		cue = "signal"
	sfx(cue)
	if encounter.result == "victory":
		if afterstory.active:
			debrief = afterstory.won(encounter.tonics)
			result_cue = "win"
			_set_mode("victory")
			return
		if not chronicle.special.is_empty():
			chronicle.on_special_won()
			debrief = "武学切磋完成。" if chronicle.special == "spar" else "可继续调查眼前的事。"
			result_cue = "win"
			_set_mode("victory")
			return
		battle_reward = 0 if field_key == "village" and active_battle == 0 else (3 if active_battle == 2 else 2)
		var old_rank := rank()
		slot.merit += battle_reward
		slot.tonics = mini(9, encounter.tonics + (1 if active_battle == 2 else 0))
		slot.cleared.append(active_battle)
		debrief = "石桥已清。抵达西岸时结算历练。" if battle_reward == 0 else "获得 %d 点历练%s" % [
			battle_reward, "  ·  境界提升至 %d" % rank() if rank() > old_rank else ""]
		if active_battle == 2:
			debrief += "  ·  金创药补给"
		_commit()
		result_cue = "win"
		_set_mode("victory")
	elif encounter.result == "defeat":
		debrief = "重试将恢复至本场开战前的状态。"
		result_cue = "lose"
		_set_mode("defeat")

func _finish_result_audio() -> void:
	if not result_cue.is_empty():
		sfx(result_cue)
		result_cue = ""

func _skip_battle_effect() -> void:
	effect_duration = 0.0
	_finish_result_audio()

func cancel() -> void:
	match mode:
		"field": _set_mode("pause")
		"ferry": campaign.abort_ferry()
		"pause": _set_mode("field")
		"battle":
			if pending_action >= 0:
				pending_action = -1
		"settings", "journal", "martial": _set_mode(back_mode)
		"review": _title()
		"choice": chronicle.cancel_choice()
		"new": _title()
		"overwrite": _set_mode("new")
		"ending": _title()

func _confirm() -> void:
	match mode:
		"field": interact()
		"ferry": campaign.finish_ferry()
		"dialogue": _advance_talk()
		"journal": cancel()
		"battle":
			if pending_action >= 0:
				_battle_act(pending_action, target)
			else:
				battle_choose(selected)
		_: menu_confirm(selected)

func _navigate(dx: int, dy: int) -> void:
	if mode == "martial" and dx != 0:
		chronicle.martial_hero = posmod(chronicle.martial_hero + dx,stage.party.size())
		selected = 0
		return
	if mode == "battle":
		if pending_action >= 0:
			var step := dx if dx != 0 else dy
			var friendly: bool = encounter.targets_ally(pending_action)
			var list: Array = encounter.allies if friendly else encounter.foes
			for n in range(1, list.size() + 1):
				var next := posmod(target + step * n, list.size())
				if (friendly and pending_action == 4) or list[next].hp > 0:
					target = next
					break
		else:
			selected = posmod(selected + (dy * 3 if dy != 0 else dx), 6)
		sfx("select")
		return
	var items := menu_items()
	if not items.is_empty() and dy != 0:
		for n in range(1, items.size() + 1):
			var next := posmod(selected + dy * n, items.size())
			if items[next][1]:
				selected = next
				sfx("select")
				break

func click(kind: String, index: int) -> void:
	match kind:
		"menu":
			selected = index
			menu_confirm(index)
		"action":
			if mode == "battle":
				if pending_action == index:
					_battle_act(pending_action, target)
				else:
					battle_choose(index)
		"foe", "ally":
			if mode == "battle" and pending_action >= 0 and ((kind == "ally") == encounter.targets_ally(pending_action)):
				_battle_act(pending_action, index)
		"martial_slot": chronicle.martial_slot = index
		"martial_hero":
			chronicle.martial_hero = index
			selected = 0
		"confirm": _confirm()
		"cancel": cancel()
		"skip": _skip_battle_effect()

func _use_joypad(device: int) -> void:
	if touch_controls and not using_joypad:
		touch_controls.release()
	using_joypad = true
	active_pad = device

func _joypad_connection_changed(device: int, connected: bool) -> void:
	if not connected:
		menu_sticks.erase(device)
		held_menu_sticks.erase(device)
		if active_pad == device:
			active_pad = -1
		if Input.get_connected_joypads().is_empty():
			using_joypad = false

func _joypad_menu_motion(event: InputEventJoypadMotion) -> void:
	if event.axis not in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y]:
		return
	var stick: Vector2 = menu_sticks.get(event.device, Vector2.ZERO)
	stick[event.axis] = event.axis_value
	menu_sticks[event.device] = stick
	var magnitude := maxf(absf(stick.x), absf(stick.y))
	if magnitude <= MENU_STICK_RELEASE:
		held_menu_sticks.erase(event.device)
	elif magnitude >= MENU_STICK_PRESS and not held_menu_sticks.has(event.device):
		held_menu_sticks[event.device] = true
		_use_joypad(event.device)
		if absf(stick.x) >= absf(stick.y):
			_navigate(1 if stick.x > 0 else -1, 0)
		else:
			_navigate(0, 1 if stick.y > 0 else -1)

func _unhandled_input(event: InputEvent) -> void:
	if touch_controls and event is InputEventScreenTouch:
		_touch(event)
		return
	if touch_controls and event is InputEventScreenDrag:
		touch_controls.drag(event.index, get_global_transform_with_canvas().affine_inverse() * event.position)
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		using_joypad = false
		var hit: Dictionary = screen.hit(get_global_transform_with_canvas().affine_inverse() * event.position)
		if not hit.is_empty():
			click(hit.kind, hit.index)
		return
	if event is InputEventJoypadMotion:
		_joypad_menu_motion(event)
		return
	if event is InputEventJoypadButton and event.pressed:
		_use_joypad(event.device)
		match event.button_index:
			JOY_BUTTON_A: _confirm()
			JOY_BUTTON_B, JOY_BUTTON_START: cancel()
			JOY_BUTTON_DPAD_UP: _navigate(0, -1)
			JOY_BUTTON_DPAD_DOWN: _navigate(0, 1)
			JOY_BUTTON_DPAD_LEFT: _navigate(-1, 0)
			JOY_BUTTON_DPAD_RIGHT: _navigate(1, 0)
			JOY_BUTTON_Y:
				if mode == "field":
					_open_martial("field")
				else:
					_skip_battle_effect()
			JOY_BUTTON_X:
				if mode == "martial":
					chronicle.martial_slot = 1 - chronicle.martial_slot
				elif mode == "field":
					_open_journal()
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	using_joypad = false
	var key: Key = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	match key:
		KEY_SPACE:
			if mode in ["battle","victory","defeat"] and effect_duration > 0 and elapsed < effect_started + effect_duration:
				_skip_battle_effect()
			else:
				_confirm()
		KEY_ENTER, KEY_KP_ENTER, KEY_E, KEY_Z: _confirm()
		KEY_ESCAPE, KEY_BACKSPACE, KEY_X: cancel()
		KEY_F11:
			if not OS.has_feature("android"):
				settings.full = not settings.full
				storage.set_settings(settings)
				_apply_settings()
		KEY_J:
			_open_journal()
		KEY_K:
			if mode == "field":
				_open_martial("field")
			elif mode == "martial":
				cancel()
		KEY_TAB:
			if mode == "martial":
				chronicle.martial_slot = 1 - chronicle.martial_slot
		KEY_UP, KEY_W: _navigate(0, -1)
		KEY_DOWN, KEY_S: _navigate(0, 1)
		KEY_LEFT, KEY_A: _navigate(-1, 0)
		KEY_RIGHT, KEY_D: _navigate(1, 0)
		_:
			if mode == "battle" and key >= KEY_1 and key <= KEY_6:
				battle_choose(key - KEY_1)

func _touch(event: InputEventScreenTouch) -> void:
	if event.canceled or not event.pressed:
		if event.index == touch_controls.finger:
			touch_controls.release()
		return
	using_joypad = false
	var position_on_canvas := get_global_transform_with_canvas().affine_inverse() * event.position
	match touch_controls.press(_touch_mode(), event.index, position_on_canvas):
		"stick": return
		"confirm": _confirm()
		"cancel": cancel()
		"journal": _open_journal()
		"martial": _open_martial("field")
		_:
			var hit: Dictionary = screen.hit(position_on_canvas)
			if not hit.is_empty():
				click(hit.kind, hit.index)

func _touch_mode() -> String:
	return "" if mode == "ferry" and campaign.ferry_time >= 0.55 else mode

func _open_journal() -> void:
	if mode == "field":
		back_mode = "field"
		_set_mode("journal")
	elif mode == "journal":
		cancel()

func _open_martial(parent_mode: String) -> void:
	back_mode = parent_mode
	chronicle.martial_hero = 0
	chronicle.martial_slot = 0
	_set_mode("martial")

