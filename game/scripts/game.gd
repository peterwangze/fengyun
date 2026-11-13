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
const Equipment = preload("res://scripts/equipment.gd")
const Economy = preload("res://scripts/economy.gd")
const Items = preload("res://scripts/items.gd")
const TrailGuide = preload("res://scripts/trail_guide.gd")
const Transit = preload("res://scripts/transit.gd")
const Arcs = preload("res://scripts/campaign_arcs.gd")
const FOLLOW_GAP := 32.0
const MENU_STICK_PRESS := 0.65
const MENU_STICK_RELEASE := 0.30

var screen: RefCounted
var first: RefCounted
var campaign: RefCounted
var chronicle: RefCounted
var afterstory: RefCounted
var transit: Transit
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
var review_arc := -1
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
var bag_open := false
var bag_index := 0
var journal_index := 0
var tracked_quest := ""
var active_battle := -1
var seal_chase := false
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
var gear_hero := 0
var gear_kind := 0
var gear_message := ""
var known_gear: Array[String] = []
var gear_rewards: Array[String] = []
var gear_guide := false
var gear_page := 0
var shop_id := ""
var forge_id := ""
var forge_branches := false
var pending_recipe := -1
var cultivation_message := ""
var shop_message := ""
var battle_loot := PackedStringArray()
var battle_loot_note := ""
var known_rank := 1
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
	transit = Transit.new(self)
	_reset_gear_rewards()
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
		if toast_time == 0.0 and not gear_rewards.is_empty():
			_notice(gear_rewards.pop_front())
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
			touch_controls.paint_back(self, _touch_mode())

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
			return [["回到旅程", true], ["江湖手记", true], ["设置", true], ["准备武学",true],
				["行装与境界", true], ["回到标题", true]]
		"martial": return chronicle.martial_items()
		"cultivation":
			var stances: Array = Martial.CULTIVATION[chronicle.martial_id()]
			var result := stances.map(func(stance): return [stance.name,rank() >= Martial.CULTIVATION_RANK])
			result.append(["清除心法",slot.cultivation.has(chronicle.martial_id())])
			return result
		"gear":
			var items := [["卸下", true]]
			for id in Equipment.options(gear_kind).slice(1):
				items.append([Equipment.CATALOG[id].name, Equipment.unlocked(slot,id) and Equipment.can_wear(slot,stage.party[gear_hero],id)])
			return items
		"shop":
			var items := []
			for i in Economy.SHOPS[shop_id].goods.size():
				var row := Economy.offer(slot, shop_account(), shop_id, i)
				items.append([row.name, row.limit.is_empty()])
			items.append(["离开",true])
			return items
		"forge":
			var items := []
			for i in Economy.forge_count(forge_id,forge_branches):
				var row := Economy.forge_offer(slot, shop_account(), forge_id, i,forge_branches)
				items.append([row.name, row.limit.is_empty()])
			items.append(["离开",true])
			return items
		"forge_confirm": return [["返回配方",true],["确认改制",true]]
		"choice": return chronicle.options.map(func(option): return [option[0],true])
		"review":
			var chapters := []
			for at in Arcs.ARCS.size():
				chapters.append([Arcs.ARCS[at].title,at <= arc_index()])
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
	seal_chase = false
	transit.battle = ""
	chronicle.review = false
	chronicle.special = ""
	afterstory.reset()
	slot = storage.read()
	_reset_gear_rewards()
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
					_show_journal()
				2:
					back_mode = "pause"
					_set_mode("settings")
				3: _open_martial("pause")
				4: _open_gear("pause")
				5: _title()
		"martial": chronicle.equip(index)
		"cultivation": _choose_cultivation(index)
		"gear": _equip_gear(index)
		"shop": _buy_good(index)
		"forge": _forge_item(index)
		"forge_confirm":
			var recipe := pending_recipe
			_set_mode("forge",recipe)
			if index == 1:
				_apply_recipe(recipe)
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
			transit.battle = ""
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
				transit.battle = ""
				_return_to_field()
		"ending":
			if index == 1:
				afterstory.resume()
			else:
				_title()

func _new_game(easy: bool) -> void:
	slot = storage.fresh(easy)
	_reset_gear_rewards()
	_commit()
	_enter_chapter(true)

func _start_review(chapter: int, easy: bool) -> void:
	var arc: Dictionary = Arcs.ARCS[chapter]
	slot = storage.replay(arc.region,easy)
	Arcs.setup_review(slot,chapter)
	_reset_gear_rewards()
	chronicle.review = true
	review_arc = chapter
	_enter_chapter(not arc.has("room") and arc.id != "finale")
	if arc.id == "sword":
		transit.enter("lantern_pass")
	elif arc.id == "dragon":
		transit.enter("dragon_waterway")
	elif arc.id == "blood":
		transit.enter("dragon_ridge")
	elif arc.id == "finale":
		transit.enter("summit_steps")

func arc_index() -> int:
	return Arcs.index(slot)

func rank() -> int:
	if afterstory.active:
		return 6
	return 1 + int(slot.get("merit", 0) / 4.0)

func _enter_chapter(intro: bool) -> void:
	stage = Story.CHAPTERS[int(slot.chapter)]
	first.reset_scene()
	if transit.resume():
		return
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

func _commit() -> bool:
	var supplies := Items.reconcile_quests(slot, slot.supplies, slot.supply_claims)
	if afterstory.active and not afterstory.state().has("material_claims"):
		Economy.normalize_tide(afterstory.state())
	var finds := Economy.reconcile(slot)
	if not chronicle.review and not storage.write(slot):
		_notice("存档写入失败。请确认本机存储空间。")
		return false
	for item in supplies:
		gear_rewards.append("获得 · " + item)
	for find in finds:
		gear_rewards.append("获得 · " + find)
	var current_rank := rank()
	if not afterstory.active:
		if known_rank < Martial.SYNERGY_TIER and current_rank >= Martial.SYNERGY_TIER:
			gear_rewards.append("境界 2 · 行装与武学现可搭配")
		elif known_rank < Martial.SYNERGY_ADVANCED_TIER and current_rank >= Martial.SYNERGY_ADVANCED_TIER:
			gear_rewards.append("境界 4 · 武学与行装搭配强化")
		known_rank = current_rank
	var available := Equipment.owned(slot)
	for id in available:
		if id not in known_gear and not slot.gear_grants.has(id):
			gear_rewards.append("获得 · " + Equipment.CATALOG[id].name)
	known_gear = available
	return true

func _review_finished() -> bool:
	if not chronicle.review or arc_index() <= review_arc:
		return false
	_title()
	return true

func _reset_gear_rewards() -> void:
	known_gear = Equipment.owned(slot)
	known_rank = rank()
	gear_rewards.clear()
	tracked_quest = ""

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
	if not Rect2(17,61,field_width()-34,254).has_point(point):
		return false
	if not Geometry2D.is_point_in_polygon(point, ground):
		return false
	for box in walls:
		if box.grow(3).has_point(point):
			return false
	for polygon in hazards:
		if Geometry2D.is_point_in_polygon(point, polygon):
			return false
	if transit.active():
		return true
	if afterstory.active:
		return not afterstory.blocked(point)
	if not first.active() and campaign.blocked(point):
		return false
	return true

func field_width() -> int:
	return int(map.get("width",320)) * 2

func field_offset() -> float:
	return roundf(clampf(player.x - 320.0,0.0,field_width()-640.0))

func _held(first: Key, second: Key) -> bool:
	return Input.is_physical_key_pressed(first) or Input.is_physical_key_pressed(second)

func field_points() -> Array:
	if transit.active():
		return transit.points()
	var points: Array
	if afterstory.active:
		points = afterstory.points()
	else:
		points = first.points() if first.active() else campaign.all_points()
		points.append_array(chronicle.points())
		var source := "cache:" + field_key
		if TrailGuide.CACHES.has(field_key) and not slot.supply_claims.has(source):
			var cache: Dictionary = TrailGuide.CACHES[field_key]
			points.append({"id":"cache","pos":cache.pos,"name":cache.name,"index":-1})
		if field_key == "inn" and chronicle.has("ferry_evidence") and not slot.supply_claims.has("hunt:inn"):
			points.append({"id":"seal_chase","pos":Vector2(446,233),"name":"查看后窗的密探","index":-1})
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
	return points

func nearest() -> Dictionary:
	var best := {}
	var limit := 35.0
	for spot in field_points():
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
	if transit.active():
		transit.handle(spot)
		return
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
		"seal_chase":
			seal_chase = true
			_talk(TrailGuide.SEAL_CHASE[2], _start_battle)
		"cache":
			_reward_supply("cache:" + field_key)
			_commit()
			_notice("已找到藏起的补给。")
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
			_reward_supply("chest:" + field_key)
			var finds := Economy.claim(slot, slot, "chest:" + field_key)
			_commit()
			for find in finds:
				gear_rewards.append("药箱 · " + find)
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
	var connector: String = {0:"courtyard_road",3:"broken_trestle"}.get(int(slot.chapter),"")
	if not connector.is_empty() and transit.available(connector):
		transit.enter(connector)
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
	var approach: String = {2:"lantern_pass",5:"dragon_waterway"}.get(int(slot.chapter),"")
	if not approach.is_empty() and transit.available(approach):
		stage = Story.CHAPTERS[int(slot.chapter)]
		transit.enter(approach)
		var opening: Array = chronicle.opening()
		_talk(stage.opening if opening.is_empty() else opening,_finish_intro)
		return
	_commit()
	_enter_chapter(true)

func _show_ending() -> void:
	_play_music("ending")
	var ending: Array = chronicle.ending()
	_talk(Story.ENDING if ending.is_empty() else ending,func(): _set_mode("ending"))

func _return_to_field() -> void:
	seal_chase = false
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
	if not transit.battle.is_empty() and transit.active():
		return transit.encounter()
	if seal_chase:
		return TrailGuide.SEAL_CHASE
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
	battle_loot.clear()
	battle_loot_note = ""
	var prepared := {}
	var gear := {}
	var builds := {}
	var training := {}
	for id in stage.party:
		prepared[id] = Martial.prepared(slot,id)
		gear[id] = Equipment.modifiers(slot,id)
		builds[id] = Martial.synergies(slot,id,rank())
		training[id] = Martial.training(slot,id,rank())
	var stock: int = afterstory.state().tonics if afterstory.active else slot.tonics
	var supplies: Dictionary = afterstory.state().get("supplies", Items.fresh(2)) if afterstory.active else slot.supplies
	encounter = Battle.new(stage.party, battle_info()[1], rank(),
		stock, slot.easy, int(slot.chapter), slot.campaign.sword,prepared,afterstory.active or chronicle.enabled(),gear,supplies,builds,training)
	encounter.seal_chase = seal_chase
	if afterstory.active:
		encounter.apply_quest_aid(afterstory.battle_aid())
	elif not seal_chase and chronicle.enabled():
		encounter.apply_quest_aid(chronicle.side.battle_aid(field_key,active_battle,chronicle.special))
		encounter.apply_quest_aid(transit.battle_aid(active_battle,chronicle.special))
	pending_action = -1
	bag_open = false
	bag_index = 0
	effect_duration = 0.0
	target = 0
	_set_mode("battle")
	var boss: bool = afterstory.battle == "chief" if afterstory.active else not seal_chase and (active_battle == 1 or chronicle.special == "first_tyrant")
	var final_boss: bool = not afterstory.active and boss and slot.chapter == 5 and chronicle.enabled()
	_play_music("peak_final" if final_boss else ("boss" if boss else "battle"))

func battle_choose(action: int) -> void:
	if not encounter.available(action):
		_notice("当前招式尚不可用。")
		return
	_skip_battle_effect()
	selected = 4 if action >= Battle.FIRST_SUPPLY else action
	if action in [3,5] or encounter._automatic(action):
		_battle_act(action, 0)
		return
	pending_action = action
	target = encounter.weakest_ally(action != 4) if encounter.targets_ally(action) else encounter.living_foe()
	if not encounter.valid_target(action, target):
		_navigate(1, 0)
	sfx("select")

func _open_bag() -> void:
	_skip_battle_effect()
	bag_open = true
	bag_index = 0
	selected = 4
	screen.hot.clear()

func _pick_supply(index: int) -> void:
	var action: int = encounter.bag_actions()[index]
	if encounter.available(action):
		bag_open = false
		battle_choose(action)

func _battle_act(action: int, at: int) -> void:
	var before: Dictionary = encounter.presentation()
	if not encounter.act(action, at):
		return
	effect_before = before
	pending_action = -1
	effect_started = elapsed
	var last_beat := int(encounter.events.back().beat)
	effect_duration = 0.66 + 0.30 * last_beat + (0.19 if action == 5 else 0.0)
	var cue := "heal" if action >= Battle.FIRST_SUPPLY else ["clang","clang","clang","guard","heal","combo"][action] as String
	if encounter.advanced and action in [1,2]:
		cue = {"wind":"cast_wind","cloud":"cast_cloud","frost":"cast_frost","blade":"cast_blade",
			"dark":"cast_dark","heal":"heal","guard":"guard"}.get(encounter.events[0].style,"clang")
	if encounter.events.any(func(event: Dictionary): return event.kind == "break"):
		cue = "break"
	if encounter.events.any(func(event: Dictionary): return event.kind == "arrival"):
		cue = "signal"
	sfx(cue)
	if encounter.result == "victory":
		if not transit.battle.is_empty() and transit.active():
			transit.won()
			debrief = "路已打通，往下一处地标走。"
			result_cue = "win"
			_set_mode("victory")
			return
		if afterstory.active:
			afterstory.state().supplies = encounter.supplies
			_record_battle_loot(afterstory.state(), "tidal:" + afterstory.battle, 6 if afterstory.battle == "chief" else 4)
			debrief = afterstory.won(encounter.tonics)
			result_cue = "win"
			_set_mode("victory")
			return
		slot.supplies = encounter.supplies
		if seal_chase:
			slot.tonics = encounter.tonics
			_reward_supply("hunt:inn")
			_record_battle_loot(slot, "hunt:inn", 3)
			_commit()
			debrief = "截下仿造的缺角印。秦霜把它和调令一起留作证据。"
			result_cue = "win"
			_set_mode("victory")
			return
		if not chronicle.special.is_empty():
			_record_battle_loot(slot, "special:" + chronicle.special, 3 if chronicle.special == "spar" else 5)
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
			_reward_supply("hunt:" + field_key)
		_record_battle_loot(slot, "battle:%s:%d" % [field_key,active_battle], 3 if active_battle == 2 else (6 if active_battle == 1 else 5))
		_commit()
		result_cue = "win"
		_set_mode("victory")
	elif encounter.result == "defeat":
		debrief = "密探带着假印逃走。可以重试，或先回渡口。" if encounter.escaped else "重试将恢复至本场开战前的状态。"
		result_cue = "lose"
		_set_mode("defeat")

func _record_battle_loot(account: Dictionary, source: String, silver: int) -> void:
	battle_loot = Economy.claim(slot, account, source, silver)
	battle_loot_note = Economy.source_note(source) if battle_loot.size() > 1 else ""

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
			elif bag_open:
				bag_open = false
		"gear":
			if gear_guide:
				_toggle_gear_guide()
			else:
				_set_mode(back_mode)
		"shop", "forge": _return_to_field()
		"forge_confirm": _set_mode("forge",pending_recipe)
		"cultivation": _set_mode("martial")
		"settings", "journal", "martial": _set_mode(back_mode)
		"review": _title()
		"choice": chronicle.cancel_choice()
		"new": _title()
		"overwrite": _set_mode("new")
		"ending": _title()

func _confirm() -> void:
	if mode == "gear" and gear_guide:
		_toggle_gear_guide()
		return
	match mode:
		"field": interact()
		"ferry": campaign.finish_ferry()
		"dialogue": _advance_talk()
		"journal":
			if not afterstory.active:
				var id := journal_quest_id()
				if can_track_quest(id):
					tracked_quest = id
			cancel()
		"battle":
			if pending_action >= 0:
				_battle_act(pending_action, target)
			elif bag_open:
				_pick_supply(bag_index)
			elif selected == 4:
				_open_bag()
			else:
				battle_choose(selected)
		_: menu_confirm(selected)

func _navigate(dx: int, dy: int) -> void:
	if mode == "gear" and gear_guide:
		return
	if mode == "journal" and not afterstory.active and dy != 0:
		journal_index = posmod(journal_index + dy, chronicle.side.journal_ids().size() + 1)
		return
	if mode == "gear" and dx != 0:
		_select_gear_tab(posmod(gear_hero + dx, stage.party.size()), gear_kind)
		return
	if mode in ["gear", "shop", "forge"] and dy != 0:
		selected = posmod(selected + dy, menu_items().size())
		if mode == "gear":
			gear_page = selected / 6
		else:
			shop_message = ""
		sfx("select")
		return
	if mode in ["martial","cultivation"] and dx != 0:
		chronicle.martial_hero = posmod(chronicle.martial_hero + dx,stage.party.size())
		selected = 0
		cultivation_message = ""
		return
	if mode == "battle":
		if pending_action >= 0:
			var step := dx if dx != 0 else dy
			var friendly: bool = encounter.targets_ally(pending_action)
			var list: Array = encounter.allies if friendly else encounter.foes
			for n in range(1, list.size() + 1):
				var next := posmod(target + step * n, list.size())
				if encounter.valid_target(pending_action, next):
					target = next
					break
		elif bag_open:
			bag_index = posmod(bag_index + (dy * 2 if dy != 0 else dx), encounter.bag_actions().size())
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
		"shop_row", "forge_row":
			selected = index
			shop_message = ""
		"menu":
			selected = index
			menu_confirm(index)
		"action":
			if mode == "battle":
				if pending_action == index:
					_battle_act(pending_action, target)
				elif index == 4:
					_open_bag()
				else:
					battle_choose(index)
		"supply":
			if mode == "battle" and bag_open:
				bag_index = index
				_pick_supply(index)
		"foe", "ally":
			if mode == "battle" and pending_action >= 0 and ((kind == "ally") == encounter.targets_ally(pending_action)):
				_battle_act(pending_action, index)
		"pick_target":
			if mode == "battle" and pending_action >= 0 and encounter.valid_target(pending_action,index):
				target = index
				sfx("select")
		"martial_slot": chronicle.martial_slot = index
		"martial_hero":
			chronicle.martial_hero = index
			selected = 0
			cultivation_message = ""
		"cultivation": _open_cultivation()
		"forge_branches": _toggle_forge_branches()
		"gear_kind": _select_gear_tab(gear_hero, index)
		"gear_hero": _select_gear_tab(index, gear_kind)
		"gear_guide": _toggle_gear_guide()
		"gear_scroll":
			var last := (Equipment.options(gear_kind).size() - 1) / 6
			gear_page = clampi(gear_page + index,0,last)
		"journal_row": journal_index = index
		"journal_track": _confirm()
		"confirm": _confirm()
		"cancel": cancel()
		"skip": _skip_battle_effect()

func _open_shop(id: String) -> void:
	shop_id = id
	shop_message = ""
	_set_mode("shop")

func _open_forge(id: String) -> void:
	forge_id = id
	forge_branches = false
	shop_message = ""
	_set_mode("forge")

func _toggle_forge_branches() -> void:
	if Economy.forge_count(forge_id,true) > 0:
		forge_branches = not forge_branches
		shop_message = ""
		_set_mode("forge")

func shop_account() -> Dictionary:
	return afterstory.state() if afterstory.active else slot

func _buy_good(index: int) -> void:
	if index == Economy.SHOPS[shop_id].goods.size():
		_return_to_field()
		return
	var previous := slot.duplicate(true)
	var bought := Economy.buy(slot, shop_account(), shop_id, index)
	if bought.is_empty():
		return
	if not _commit():
		slot = previous
		shop_message = "存档失败，已撤销交易。"
		return
	shop_message = "已购入 %s。" % bought

func _forge_item(index: int) -> void:
	if index == Economy.forge_count(forge_id,forge_branches):
		_return_to_field()
		return
	if forge_branches:
		pending_recipe = index
		_set_mode("forge_confirm")
		return
	_apply_recipe(index)

func _apply_recipe(index: int) -> void:
	var previous := slot.duplicate(true)
	var result := Economy.reinforce(slot,shop_account(),forge_id,index,forge_branches)
	if result.is_empty():
		return
	if not _commit():
		slot = previous
		shop_message = "存档失败，已撤销锻造。"
		return
	shop_message = result

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
				elif mode == "gear" and not gear_guide:
					_select_gear_tab(gear_hero, 1 - gear_kind)
				elif mode == "field":
					_open_journal()
			JOY_BUTTON_LEFT_SHOULDER:
				if mode == "field":
					_open_gear("field")
			JOY_BUTTON_RIGHT_SHOULDER:
				if mode == "gear":
					_toggle_gear_guide()
				elif mode == "martial":
					_open_cultivation()
				elif mode == "forge":
					_toggle_forge_branches()
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
		KEY_I:
			if mode == "field":
				_open_gear("field")
			elif mode == "gear":
				cancel()
		KEY_G:
			if mode == "gear":
				_toggle_gear_guide()
			elif mode == "martial":
				_open_cultivation()
		KEY_TAB:
			if mode == "martial":
				chronicle.martial_slot = 1 - chronicle.martial_slot
			elif mode == "gear" and not gear_guide:
				_select_gear_tab(gear_hero, 1 - gear_kind)
			elif mode == "forge":
				_toggle_forge_branches()
		KEY_B:
			if mode == "battle" and pending_action < 0:
				if bag_open:
					cancel()
				else:
					_open_bag()
		KEY_UP, KEY_W: _navigate(0, -1)
		KEY_DOWN, KEY_S: _navigate(0, 1)
		KEY_LEFT, KEY_A: _navigate(-1, 0)
		KEY_RIGHT, KEY_D: _navigate(1, 0)
		_:
			if mode == "battle" and not bag_open and key >= KEY_1 and key <= KEY_6:
				battle_choose(key - KEY_1)

func _reward_supply(source: String) -> void:
	if slot.supply_claims.has(source) or not Items.REWARDS.has(source):
		return
	slot.supply_claims[source] = true
	for item in Items.reward(slot.supplies, source):
		gear_rewards.append("获得 · " + item)

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
		_:
			if mode == "field":
				return
			var hit: Dictionary = screen.hit(position_on_canvas)
			if not hit.is_empty():
				click(hit.kind, hit.index)

func _touch_mode() -> String:
	return "" if mode == "ferry" and campaign.ferry_time >= 0.55 else mode

func _open_journal() -> void:
	if mode == "field":
		back_mode = "field"
		_show_journal()
	elif mode == "journal":
		cancel()

func _show_journal() -> void:
	journal_index = chronicle.side.journal_ids().find(tracked_quest) + 1
	_set_mode("journal")

func journal_quest_id() -> String:
	return "" if journal_index == 0 else chronicle.side.journal_ids()[journal_index - 1]

func can_track_quest(id: String) -> bool:
	return id.is_empty() or chronicle.side.journal_entry(id).status not in ["已完成", "已错过", "后续章节"]

func _open_martial(parent_mode: String) -> void:
	back_mode = parent_mode
	chronicle.martial_hero = 0
	chronicle.martial_slot = 0
	_set_mode("martial")

func _open_cultivation() -> void:
	cultivation_message = ""
	var hero: String = chronicle.martial_id()
	var active := Martial.cultivation_choice(slot,hero,rank())
	var stances: Array = Martial.CULTIVATION[hero]
	_set_mode("cultivation",1 if not active.is_empty() and active.id == stances[1].id else 0)

func _choose_cultivation(index: int) -> void:
	var hero: String = chronicle.martial_id()
	var stances: Array = Martial.CULTIVATION[hero]
	var previous: Dictionary = slot.cultivation.duplicate()
	if index == stances.size():
		slot.cultivation.erase(hero)
	else:
		slot.cultivation[hero] = stances[index].id
	if not _commit():
		slot.cultivation = previous
		cultivation_message = "存档失败，已恢复原心法。"
		return
	cultivation_message = "已卸下心法" if index == stances.size() else "已运转 · " + stances[index].name

func _open_gear(parent_mode: String) -> void:
	back_mode = parent_mode
	gear_guide = false
	_set_mode("gear")
	_select_gear_tab(0, 0)

func _toggle_gear_guide() -> void:
	gear_guide = not gear_guide
	screen.hot.clear()

func _select_gear_tab(hero: int, kind: int) -> void:
	gear_hero = hero
	gear_kind = kind
	gear_message = ""
	selected = Equipment.options(kind).find(Equipment.equipped(slot, stage.party[hero], kind))
	gear_page = maxi(0,selected) / 6

func _equip_gear(index: int) -> void:
	var hero: String = stage.party[gear_hero]
	var item := Equipment.options(gear_kind)[index]
	var previous: Dictionary = slot.gear.duplicate(true)
	if Equipment.equipped(slot, hero, gear_kind) == item or not Equipment.assign(slot, hero, gear_kind, item):
		return
	if not _commit():
		slot.gear = previous
		gear_message = "存档失败，已恢复原行装。"
		return
	gear_message = "已卸下%s" % Equipment.CATEGORIES[gear_kind] if item.is_empty() else "已装备%s" % Equipment.CATALOG[item].name

