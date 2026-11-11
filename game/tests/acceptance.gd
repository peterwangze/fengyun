extends SceneTree

const MAIN = preload("res://main.tscn")
const STEPS = [Vector2i(4,0),Vector2i(-4,0),Vector2i(0,4),Vector2i(0,-4)]
var game
var failures := 0
var wins := 0
var combo_count := 0
var saw_shield := false
var visual := false
var report_dir := ""
var captured_effects := {}
var rear_route := ""
var boat_route := false
var bridge_then_boat := false
var reduced_ferry := false
var forge_ledge := false
var signal_missed := false
var poise_finish := false
var quests := false
var alternate := false
var low_motion := false
var tidal := false
var tidal_sluice := false
var used_actions := {"tonics":0,"techniques":0,"guard":0,"combo":0}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	visual = DisplayServer.get_name() != "headless"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--reports="):
			report_dir = arg.substr(10)
		if arg.begins_with("--rear-route="):
			rear_route = arg.get_slice("=",1)
	game = MAIN.instantiate()
	root.add_child(game)
	var easy := "--all-encounters" in OS.get_cmdline_user_args()
	boat_route = "--boat" in OS.get_cmdline_user_args()
	bridge_then_boat = "--bridge-then-boat" in OS.get_cmdline_user_args()
	reduced_ferry = "--reduced-ferry" in OS.get_cmdline_user_args()
	forge_ledge = "--ledge" in OS.get_cmdline_user_args()
	signal_missed = "--miss-signal" in OS.get_cmdline_user_args()
	poise_finish = "--poise-finish" in OS.get_cmdline_user_args()
	quests = "--quests" in OS.get_cmdline_user_args()
	alternate = "--alternate" in OS.get_cmdline_user_args()
	low_motion = "--low-motion" in OS.get_cmdline_user_args()
	tidal = "--tidal" in OS.get_cmdline_user_args()
	tidal_sluice = "--tidal-sluice" in OS.get_cmdline_user_args()
	_check(game.storage.path.contains("qa"),"acceptance must use a separate QA save")
	if failures > 0:
		quit(1)
		return
	for path in [game.storage.path, game.storage.settings_path]:
		for suffix in ["",".bak",".tmp"]:
			if FileAccess.file_exists(path + suffix):
				DirAccess.remove_absolute(path + suffix)
	game._title()
	await _capture("01-title")
	_key(KEY_UP)
	_key(KEY_ENTER)
	_drain_dialogue()
	_check(game.chronicle.review and game.field_key == "village" and not FileAccess.file_exists(game.storage.path),
		"title opens a standalone Fengxi trial without creating a main save")
	game._title()
	_joy(JOY_BUTTON_A)
	_check(game.mode == "new","controller A opens new-game selection")
	_verify_joypad_menu()
	await _capture("controller-menu-synthetic")
	_joy(JOY_BUTTON_B)
	_check(game.mode == "title","controller B returns to title")
	_key(KEY_ENTER)
	_check(not game.using_joypad,"keyboard restores keyboard prompts")
	if easy:
		_joy(JOY_BUTTON_DPAD_DOWN)
	_key(KEY_ENTER)
	_check(game.mode == "dialogue" and game.slot.easy == easy,"mode selection and opening")
	_drain_dialogue()
	if failures > 0:
		quit(1)
		return
	_key(KEY_ESCAPE)
	_check(game.mode == "pause","Escape pauses field")
	_key(KEY_DOWN)
	_key(KEY_DOWN)
	_key(KEY_ENTER)
	_check(game.mode == "settings","pause settings open")
	var original: bool = game.settings.mute
	_key(KEY_ENTER)
	_check(game.storage.get_settings().mute != original,"mute toggle persists")
	_key(KEY_ENTER)
	_key(KEY_DOWN)
	var motion: bool = game.settings.motion
	_key(KEY_ENTER)
	_check(game.storage.get_settings().motion != motion,"reduced-motion setting persists")
	_key(KEY_ENTER)
	_key(KEY_ESCAPE)
	_key(KEY_ESCAPE)
	if low_motion:
		game.settings.motion = false
		game.storage.set_settings(game.settings)
	_key(KEY_J)
	_check(game.mode == "journal","journal opens")
	_key(KEY_ESCAPE)
	await _capture("02-first-field")
	for chapter in 6:
		_check(int(game.slot.chapter) == chapter and game.mode == "field","chapter %d opens" % (chapter+1))
		if chapter == 5:
			await _special("relic","cavern_guard")
			_do_point("lost_relic")
			_do_point("shatter_relic")
			await _special("prepare","prepare_guard")
			await _capture("2-cavern")
			_do_point("lodge")
			if _check(_reach("blood_rite"),"blood exchange reachable"):
				_key(KEY_E)
				_key(KEY_ENTER)
				await _capture("2-blood-rite")
				_drain_dialogue()
			if not await _scene_step("bedside","farewell","farewell"):
				quit(1)
				return
			_check(game.field_key == "peak","farewell leads to dragon terrace")
			if alternate:
				_alternate_loadout()
		_verify_map(chapter)
		if chapter == 0:
			_verify_orientation()
			await _special("spar","spar")
			if quests:
				await _side_step("seals")
		await _capture("field-%s" % game.stage.key)
		if chapter == 1:
			_check(not _reach("exit"),"village exit unreachable before crossing")
		elif chapter != 2:
			_check(_reach("exit"),"exit path %d" % (chapter+1))
			_key(KEY_E)
			_check(game.mode == "field" and game.toast_time > 0,"exit stays locked before combat")
		_check(_reach("guide"),"guide path %d" % (chapter+1))
		_key(KEY_E)
		_check(game.mode == "dialogue","NPC dialogue starts")
		_drain_dialogue()
		_check(_reach("shrine"),"shrine path %d" % (chapter+1))
		_key(KEY_E)
		_check(FileAccess.file_exists(game.storage.path),"shrine saves")
		_check(_reach("chest"),"chest path %d" % (chapter+1))
		_key(KEY_E)
		_check(game.slot.chest and game.storage.read().chest,"chest reward persists")
		var order := [0,2,1] if easy else [0,1]
		if chapter == 0 and not rear_route.is_empty():
			order.erase(1)
		if chapter == 1 and boat_route:
			if not await _take_ferry():
				quit(1)
				return
			order.erase(0)
		if chapter == 2 and easy:
			order = [0,1,2]
		if chapter == 3:
			_do_point("apothecary")
			_do_point("pool_intro")
			if quests:
				await _side_step("remedy")
				await _side_step("remedy")
				if alternate:
					await _side_step("remedy",1)
					await _side_step("remedy")
				await _side_step("remedy",0)
			await _capture("2-apothecary")
			_do_point("pool_back")
			if not await _scene_step("pool_trial","pool_trial","pool_trial"):
				quit(1)
				return
		for fight in order:
			if chapter == 0 and fight == 1 and not await _wedding_route(false):
				quit(1)
				return
			if chapter == 1 and fight != 0 and game.slot.campaign.crossing.is_empty():
				var crossed: bool = await _take_ferry() if bridge_then_boat else _cross_bridge()
				if not crossed:
					quit(1)
					return
			if chapter == 1 and fight != 0 and not game.chronicle.has("ferry_evidence"):
				await _ferry_evidence()
				_check(game.storage.read().chronicle.marks.get("ferry_evidence",false),"investigation persists")
			if chapter == 2 and fight == 1 and not await _cross_forge():
				quit(1)
				return
			if chapter == 4 and fight == 1:
				if not await _free_prisoner():
					quit(1)
					return
				_do_point("tearoom")
				_do_point("tea")
				if quests:
					await _side_step("shift",int(alternate))
					await _side_step("swordstory",int(alternate))
				_do_point("palace_back")
			if chapter == 5 and fight == 1 and not await _scene_step("altar","altar","altar"):
				quit(1)
				return
			if not _check(_reach("fight",fight),"fight reachable %d/%d" % [chapter+1,fight]):
				quit(1)
				return
			_key(KEY_E)
			_drain_dialogue()
			if not _check(game.mode == "battle","battle entry %d/%d" % [chapter+1,fight]):
				quit(1)
				return
			if chapter == 0 and fight == 0:
				await _capture("03-first-battle")
				_key(KEY_1)
				_check(game.pending_action == 0,"number shortcuts enter target mode")
				var first_target: int = game.target
				_joy_axis(JOY_AXIS_LEFT_X,0.8)
				_check(game.target != first_target and game.using_joypad,"left stick changes the battle target")
				_joy_axis(JOY_AXIS_LEFT_X,0.0)
				await _capture("controller-target-synthetic")
				_joy(JOY_BUTTON_B)
				_check(game.pending_action == -1,"controller B cancels target mode")
				_key(KEY_1)
				_key(KEY_ESCAPE)
				_check(game.pending_action == -1,"Escape cancels target mode")
				var stock: int = game.slot.tonics
				_key(KEY_5)
				_key(KEY_ENTER)
				await _capture_effect("heal")
				for action in 150:
					if game.mode != "battle":
						break
					_key(KEY_4)
				_check(game.mode == "defeat" and game.slot.tonics == stock,"defeat preserves pre-battle stock")
				_key(KEY_ENTER)
				_check(game.mode == "battle" and game.encounter.tonics == stock
					and game.encounter.round_no == 1,"retry restores encounter and medicine")
				await _tutorial_combat()
			if chapter == 5 and fight == 1:
				await _capture("04-final-battle")
			if chapter == 1 and fight == 1:
				await _signal_opening()
			if chapter == 3 and fight == 0:
				await _demon_opening()
			if chapter == 2 and fight == 2:
				_check(game.encounter.allies[0].moves[1][0] == "剑扫长空","claimed sword equips move in swordpool after reload")
			if not await _play_battle():
				quit(1)
				return
			wins += 1
			_check(game.storage.read().cleared.has(fight),"victory and reward reload")
			var qi_left: Array = game.encounter.allies.map(func(unit): return "%s %d/%d" % [unit.name,unit.qi,unit.max_qi])
			print("PASS chapter %d encounter %d rounds %d tonics %d qi %s" %
				[chapter+1,fight,game.encounter.round_no,game.slot.tonics,",".join(qi_left)])
			_key(KEY_ENTER)
			if chapter == 1 and fight == 0:
				_check(game.slot.campaign.crossing.is_empty(), "bridge battle does not register a landing")
			if chapter == 2 and fight == 1:
				if not await _scene_step("sword","sword","sword"):
					quit(1)
					return
				_resume()
				_check(game.slot.campaign.sword,"sword persists on continue")
			if chapter == 5 and fight == 1:
				_check(game.encounter.shield_resolution == ("poise" if poise_finish else "combo"),"final shield broken by selected tactic")
				print("PASS final shield " + game.encounter.shield_resolution)
		if chapter == 0 and not rear_route.is_empty():
			if not await _wedding_route(true) or not await _escape_garden():
				quit(1)
				return
			_drain_dialogue()
			continue
		if chapter == 1:
			_resume()
			_check(game.mode == "field" and game.slot.cleared.has(1) and game.player.x < 240,"continue restores west landing")
			_do_point("inn")
			if _check(_reach("dream_intro"),"Second Dream's first scene reachable"):
				_key(KEY_E)
				await _capture("2-inn")
				_drain_dialogue()
			_do_point("inn_exit")
			if not await _scene_step("reunion","reunion","reunion"):
				quit(1)
				return
		if chapter == 2:
			if quests:
				await _side_step("forgework")
				_do_point("forge_valve_locked")
				_check(game.slot.chronicle.quests.forgework == "sluice","jammed second valve preserves puzzle state")
				await _side_step("forgework")
				await _side_step("forgework")
			_do_point("exit")
			_do_point("lesson")
			if quests:
				await _side_step("forgework")
				await _side_step("swordstory")
				await _side_step("swordstory")
			await _capture("2-swordhall")
			_do_point("returnhall")
			await _special("first_tyrant","first_tyrant")
			_choose(int(alternate))
			_resume()
			_check(game.field_key == "returnhall" and game.chronicle.has("forge_pursue" if alternate else "forge_rescue"),
				"first tyrant and route choice persist on resume")
			_do_point("invaded")
			continue
		if chapter == 3:
			_do_point("pool_gate")
			_do_point("pool_escape")
		if chapter == 4:
			_do_point("tearoom")
			await _capture("2-tearoom-fire")
			_do_point("fire_signal")
			_do_point("evacuated")
			_do_point("palace_back")
		if chapter == 5 and quests:
			await _side_step("swordstory")
			await _side_step("stairs")
			await _side_step("stairs")
			await _side_step("stairs",int(alternate))
			if not alternate:
				await _side_step("stairs")
		_check(_reach("exit"),"exit reachable after battle")
		_key(KEY_E)
		if chapter == 5:
			await _capture("05-farewell")
		_drain_dialogue()
		if chapter == 5:
			_check(game.field_key == "dawn","chapter ends at playable Fengxi dawn")
			_resume()
			_check(game.field_key == "dawn","ending walk resumes on the west bank")
			if quests:
				await _side_step("lamps")
			_do_point("dawn_lamp")
			await _capture("2-dawn")
			_do_point("dawn_exit")
	if _check(game.mode == "ending" and game.storage.read().finished,"ending and completed save"):
		await _capture("06-ending")
		_key(KEY_ENTER)
		_key(KEY_ENTER)
		_check(game.mode == "dialogue","completed save can replay epilogue")
		_drain_dialogue()
		_check(game.mode == "ending","epilogue replay returns to ending screen")
	if quests:
		var q: Dictionary = game.storage.read().chronicle.quests
		_check(q.size() == 8 and q.values().all(func(value): return String(value).begins_with("done_")),
			"all eight quests finished and persisted")
		print("Quest outcomes: ",q)
	if tidal and game.mode == "ending":
		await _verify_afterstory()
	_verify_replay()
	_check(saw_shield and combo_count > 0,"boss shield and combo reached")
	_check(wins == (18 if easy else 12) - int(rear_route == "quiet") - int(boat_route),"all requested battles won")
	_verify_model()
	_verify_new_martial()
	_verify_backup()
	_verify_legacy()
	if failures == 0:
		print("PASS directions, synthetic controller inputs, 1.1/1.2/1.6 saves and backup recovery")
		if low_motion:
			print("PASS all battle results with reduced motion")
	print("Connected physical controllers: %s" % str(Input.get_connected_joypads()))
	game.music.stop()
	game.effects.stop()
	await process_frame
	print("RESULT wins=%d combos=%d failures=%d actions=%s" % [wins,combo_count,failures,str(used_actions)])
	quit(1 if failures else 0)

func _resume() -> void:
	_key(KEY_ESCAPE)
	_key(KEY_UP)
	_key(KEY_ENTER)
	_check(game.mode == "title","pause returns to title")
	_key(KEY_ENTER)

func _verify_afterstory() -> void:
	var baseline: Dictionary = game.storage.read()
	_key(KEY_DOWN)
	_key(KEY_ENTER)
	_check(game.afterstory.active and game.field_key == "tidal_ford","credits open the Tidegate story")
	await _capture("tidal-ford")
	_do_point("brief")
	_do_point("seal")
	_check(not _reach("gate_entry"),"gate route requires both pieces of evidence")
	_do_point("register")
	_key(KEY_J)
	_check(game.mode == "journal","Tidegate journal opens")
	await _capture("tidal-journal")
	_key(KEY_ESCAPE)
	if tidal_sluice:
		_check(not _reach("sluice_entry"),"watergate entry requires the winch")
		_do_point("sluice")
		_do_point("sluice_entry")
	else:
		_do_point("gate_entry")
		_check(not game.passable(Vector2(320,205)),"gate line blocks reaching the chief")
		_do_point("return_ford")
		_check(game.field_key == "tidal_ford" and not _reach("sluice"),"return to the ford retains route")
		_do_point("gate_entry")
		await _capture("tidal-gate")
		_do_point("gate")
		if not _check(game.mode == "battle","enter gate encounter"):
			return
		_key(KEY_5)
		_key(KEY_ENTER)
		for turn in 180:
			if game.mode != "battle":
				break
			_key(KEY_4)
		_check(game.mode == "defeat" and game.afterstory.state().tonics == 3,"defeat leaves Tidegate checkpoint supply intact")
		_key(KEY_ENTER)
		_check(game.mode == "battle" and game.encounter.tonics == 3,"retry restores Tidegate supply")
		if not await _play_battle():
			return
		_key(KEY_ENTER)
		_check(game.passable(Vector2(320,205)),"winning the gate fight opens the yard")
	var selected_route := "sluice" if tidal_sluice else "gate"
	_resume_afterstory()
	_check(game.field_key == "tidal_fort" and game.afterstory.state().route == selected_route,
		"room and entry route survive reload")
	if not tidal_sluice:
		_do_point("aid")
		if not await _play_battle():
			return
		_key(KEY_ENTER)
		_check(game.afterstory.state().aid and game.afterstory.state().tonics == mini(6,game.encounter.tonics+2),
			"rescue saves the witness and grants one supply reward")
		_check(not _reach("aid"),"rescue and supply are single-use")
	_do_point("chief")
	if not _check(game.mode == "battle" and game.encounter.intent(game.encounter.foes[1]).contains("擂鼓"),
		"boss fight previews the drummer support action"):
		return
	await _capture("tidal-chief")
	if tidal_sluice:
		_key(KEY_2)
		_key(KEY_RIGHT)
		_key(KEY_ENTER)
		_key(KEY_2)
		_key(KEY_RIGHT)
		_key(KEY_ENTER)
		_check(not game.encounter.foes[0].rallied,"disabling the drummer prevents the ward")
	else:
		_key(KEY_4)
		_key(KEY_4)
		_check(game.encounter.foes[0].rallied,"uninterrupted drum casts the ward")
		if visual:
			await create_timer(0.79).timeout
		await _capture("tidal-ward")
		var hp: int = game.encounter.foes[0].hp
		_key(KEY_1)
		_key(KEY_ENTER)
		_check(not game.encounter.foes[0].rallied and hp-game.encounter.foes[0].hp < game.encounter.allies[0].attack,
			"drum ward reduces and is consumed by one hit")
	if not await _play_battle():
		return
	_key(KEY_ENTER)
	_resume_afterstory()
	_check(game.afterstory.state().chief and not game.afterstory.state().ledger,"boss result saves before taking the ledger")
	_do_point("ledger")
	_do_point("return_ford")
	_do_point("report")
	_key(KEY_ESCAPE)
	_check(game.mode == "field" and game.afterstory.state().resolution == "","cancelling the settlement leaves it open")
	_do_point("report")
	_choose(int(tidal_sluice))
	var settlement := "witness" if tidal_sluice else "public"
	_check(game.afterstory.state().resolution == settlement,"the selected settlement is saved")
	await _capture("tidal-complete")
	_resume_afterstory()
	var current: Dictionary = game.storage.read()
	_check(current.finished and current.afterstory.resolution == settlement and current.afterstory.aid == (not tidal_sluice),
		"finished Tidegate and rescue choice survive title reload")
	for key in ["chapter","cleared","campaign","merit","tonics","hall"]:
		_check(current[key] == baseline[key],"Tidegate preserves the main campaign's " + key)
	print("PASS Tidegate route=%s rescue=%s ending=%s" % [selected_route,str(current.afterstory.aid),settlement])

func _resume_afterstory() -> void:
	_key(KEY_ESCAPE)
	_key(KEY_UP)
	_key(KEY_ENTER)
	_check(game.mode == "title","Tidegate returns to title")
	_key(KEY_UP)
	_key(KEY_ENTER)
	_check(game.mode == "field" and game.afterstory.active,"title continues Tidegate")

func _do_point(point: String) -> bool:
	if not _check(_reach(point),"new point reachable: " + point + " in " + game.field_key):
		return false
	_key(KEY_E)
	_drain_dialogue()
	return true

func _choose(index: int) -> void:
	if not _check(game.mode == "choice","branch menu appears"):
		return
	if index == 1:
		_key(KEY_DOWN)
	_key(KEY_ENTER)
	_drain_dialogue()

func _special(point: String, id: String, trigger: bool = true) -> void:
	if trigger and not _do_point(point):
		return
	if not _check(game.mode == "battle" and game.chronicle.special == id,"encounter starts: " + id):
		return
	if await _play_battle():
		if id == "first_tyrant":
			_check(game.encounter.shield_resolution == "combo","first Tyrant duel requires a real combo")
		print("PASS added encounter ",id)
		_key(KEY_ENTER)
		_drain_dialogue()

func _side_step(key: String, choice: int = -1) -> void:
	if not _do_point("side_" + key):
		return
	if choice >= 0:
		_choose(choice)
	if game.mode == "battle":
		await _special("",game.chronicle.special,false)

func _ferry_evidence() -> void:
	_do_point("inn")
	_do_point("ferry_evidence")
	if quests:
		await _side_step("lamps")
	_do_point("inn_exit")
	if quests:
		await _side_step("lamps")
		await _side_step("courier")
		await _side_step("courier")
		_do_point("inn")
		await _side_step("lamps",int(alternate))
		await _side_step("courier",int(alternate))
		_do_point("inn_exit")
	_verify_martial()
	if visual:
		_key(KEY_K)
		await _capture("2-martial")
		_key(KEY_ESCAPE)

func _verify_martial() -> void:
	_key(KEY_K)
	_check(game.mode == "martial","K opens martial preparation")
	_joy_axis(JOY_AXIS_LEFT_X,0.8)
	_joy(JOY_BUTTON_X)
	_check(game.chronicle.martial_hero == 1 and game.chronicle.martial_slot == 1,
		"left stick switches martial hero and X switches the loadout slot")
	_joy_axis(JOY_AXIS_LEFT_X,0.0)
	_joy_axis(JOY_AXIS_LEFT_X,-0.8)
	_joy_axis(JOY_AXIS_LEFT_X,0.0)
	_joy(JOY_BUTTON_X)
	_key(KEY_DOWN)
	_key(KEY_DOWN)
	_key(KEY_ENTER)
	_check(int(game.storage.read().chronicle.loadout.wind[0]) == 2,"new martial arts persist")
	_key(KEY_UP)
	_key(KEY_UP)
	_key(KEY_ENTER)
	_check(int(game.storage.read().chronicle.loadout.wind[0]) == 0,"base move can be reequipped")
	_key(KEY_ESCAPE)

func _alternate_loadout() -> void:
	_key(KEY_K)
	_key(KEY_TAB)
	for at in 3:
		_key(KEY_DOWN)
	_key(KEY_ENTER)
	_key(KEY_RIGHT)
	for at in 3:
		_key(KEY_DOWN)
	_key(KEY_ENTER)
	_key(KEY_ESCAPE)
	var wind: Array = game.slot.chronicle.loadout.wind
	var cloud: Array = game.slot.chronicle.loadout.cloud
	_check(int(wind[0]) == 0 and int(wind[1]) == 3 and int(cloud[0]) == 0 and int(cloud[1]) == 3,
		"terminal fights use an alternate loadout: %s" % str(game.slot.chronicle.loadout))

func _verify_replay() -> void:
	var snapshot := FileAccess.get_file_as_string(game.storage.path)
	game._title()
	_key(KEY_UP)
	_key(KEY_UP)
	_key(KEY_ENTER)
	_check(game.mode == "review","title opens chapter review")
	_key(KEY_DOWN)
	_key(KEY_ENTER)
	_drain_dialogue()
	_check(game.chronicle.review and game.slot.chapter == 1 and game.field_key == "village","chapter review opens independently")
	_check(FileAccess.get_file_as_string(game.storage.path) == snapshot,"review does not change main slot")
	game.slot.chronicle.quests.courier = "watch"
	game._next_chapter()
	_check(game.mode == "choice","departure warns about open chapter-limited quests")
	_choose(0)
	_check(game.mode == "field" and game.slot.chapter == 1,"cancelled departure leaves the chapter playable")
	game._next_chapter()
	_choose(1)
	_check(game.mode == "title" and FileAccess.get_file_as_string(game.storage.path) == snapshot,
		"confirming departure ends chapter review without changing the main slot")

func _scene_step(point: String, scene: String, flag: String) -> bool:
	if not _check(_reach(point),point + " interaction reachable"):
		return false
	_key(KEY_E)
	if not _check(game.mode == "dialogue" and game.campaign.scene == scene,"opens " + scene):
		return false
	await _capture("scene-" + scene)
	_drain_dialogue()
	return _check(game.storage.read().campaign.get(flag) == true,flag + " persists")

func _take_ferry() -> bool:
	var merit: int = game.slot.merit
	if not _check(_reach("mooring"),"old dock reached"):
		return false
	_key(KEY_E)
	_check(game.slot.campaign.rope,"rope released")
	_resume()
	_check(game.slot.campaign.rope and game.slot.campaign.crossing.is_empty(),"mid-ferry setup resumes on east bank")
	_go_to(game.position_of("guide") + Vector2(-25,3))
	for i in 40:
		game.walk(Vector2.ZERO,0.04)
	if not _check(_reach("board") and game.campaign.ferry_ready(),"escort ferryman to dock"):
		printerr("Board diagnostics player=%s boatman=%s target=%s nearest=%s follower=%s" %
			[game.player,game.campaign.boatman,game.position_of("board"),game.nearest(),game.follower])
		return false
	_key(KEY_E)
	_check(game.mode == "ferry","board starts crossing")
	_key(KEY_ESCAPE)
	_check(game.mode == "field" and game.slot.campaign.crossing.is_empty(),"early turn back leaves reward unclaimed")
	if reduced_ferry:
		game.settings.motion = false
		_key(KEY_E)
		_check(game.mode == "field","reduced-motion ferry lands immediately")
		game.settings.motion = true
	else:
		_key(KEY_E)
		if visual:
			await create_timer(0.72).timeout
			await _capture("ferry-crossing")
		_key(KEY_ENTER)
	_check(game.slot.merit == merit + 2 and game.slot.campaign.crossing == "boat","boat route grants one landing reward")
	_resume()
	_check(game.slot.merit == merit + 2 and game.slot.campaign.crossing == "boat","ferry reload does not repeat reward")
	print("PASS ferry turn back, land and reload%s" % (" with reduced motion" if reduced_ferry else ""))
	return _check(game.player.x < 240,"ferry lands on west bank")

func _cross_bridge() -> bool:
	var merit: int = game.slot.merit
	if not _check(game.slot.cleared.has(0) and game.passable(Vector2(320,200)),"win unlocks bridge"):
		return false
	var reached := _go_to(game.position_of("west_spawn"))
	_check(game.slot.merit == merit + 2 and game.slot.campaign.crossing == "bridge","bridge landing grants two merit")
	_check(_go_to(Vector2(403,204)) and _go_to(game.position_of("west_spawn")) and game.slot.merit == merit+2,
		"crossing back and forth cannot repeat reward")
	return _check(reached,"west bank reached by stone bridge")

func _cross_forge() -> bool:
	if not forge_ledge:
		if not _check(_reach("winch"),"reach sluice winch"):
			return false
		_key(KEY_E)
		_check(game.slot.campaign.forge_gate and game.passable(Vector2(320,192)),"opened sluice clears bridge")
		if not _go_to(Vector2(318,193)):
			return false
	var at := Vector2(392,114 if forge_ledge else 191)
	if not _check(_go_to(at),"reach east forge from selected route"):
		return false
	await _capture("forge-route")
	return _check(game.slot.campaign.forge_route == ("ledge" if forge_ledge else "gate"),"forge records physical crossing")

func _free_prisoner() -> bool:
	if not _check(_reach("jail_door"),"palace jail door accessible after guard"):
		return false
	_key(KEY_E)
	if not _check(game.field_key == "jail","enter prison"):
		return false
	if quests:
		await _side_step("shift")
		await _side_step("shift")
	if not await _scene_step("cell","rescue","rescued"):
		return false
	_resume()
	_check(game.field_key == "jail" and game.slot.campaign.rescued,"prison room and rescue survive reload")
	if not _check(_reach("jail_exit"),"reach the side stair"):
		return false
	_key(KEY_E)
	return _check(game.field_key == "palace","return to the palace")

func _signal_opening() -> void:
	var b: RefCounted = game.encounter
	_check(b.foes[1].dormant and b.intent(b.foes[0]).contains("鸣哨"),"first turn signals forecast")
	await _capture("signal-warning")
	if signal_missed:
		_key(KEY_4)
		_key(KEY_4)
		used_actions.guard += 2
		_check(b.signal_state == "called" and not b.foes[1].dormant and b.round_no == 2,"missed signal spawns one next-round enemy")
	else:
		_key(KEY_2)
		_key(KEY_ENTER)
		used_actions.techniques += 2
		_key(KEY_2)
		_key(KEY_ENTER)
		_check(b.signal_state == "blocked" and b.foes[1].dormant,"wind and frost block reinforcement")
	print("PASS signal " + b.signal_state)

func _demon_opening() -> void:
	_key(KEY_3)
	_check(game.encounter.corruption == 2,"magic blade adds two corruption")
	await _capture_effect("dark")
	_key(KEY_2)
	_check(game.encounter.corruption == 0,"Second Dream suppresses corruption")
	used_actions.techniques += 2

func _tutorial_combat() -> void:
	var before: int = game.encounter.foes[0].hp
	var wind_hp: int = game.encounter.allies[1].hp
	_check(game.encounter.intent(game.encounter.foes[0]).contains("聂风"),"first heavy attack telegraphs its target")
	_key(KEY_2)
	_key(KEY_ENTER)
	used_actions.techniques += 2
	if low_motion:
		_check(game.encounter.foes[0].hp < before and game.screen.combat_art.hud().foe[0].hp == game.encounter.foes[0].hp,
			"reduced motion shows final HP immediately")
	else:
		_check(game.encounter.foes[0].hp < before and game.screen.combat_art.hud().foe[0].hp == before,
			"HP stays at the previous value during windup")
		await create_timer(0.19).timeout
		_check(game.screen.combat_art.hud().foe[0].hp == game.encounter.foes[0].hp,
			"HP updates at impact")
	_key(KEY_SPACE)
	_check(not game.screen.combat_art.active() and game.encounter.actor == 1,"Space skips animation without issuing a command")
	_key(KEY_2)
	_key(KEY_ENTER)
	_check(game.encounter.allies[1].hp == wind_hp and
		game.encounter.events.any(func(event): return event.kind == "break"),"palm and wind weakness interrupt the heavy attack")
	await _capture_effect("lesson-break")
	_joy(JOY_BUTTON_Y)
	_check(not game.screen.combat_art.active(),"controller Y skips effects")

func _wedding_route(rear: bool) -> bool:
	if not _check(_reach("banquet_door"),"wedding hall accessible after tutorial"):
		return false
	_key(KEY_E)
	if not _check(game.field_key == "banquet" and game.storage.read().hall.room == "banquet","enter hall and checkpoint"):
		return false
	_check(_reach("garden_door"),"find rear door before ceremony")
	_key(KEY_E)
	_check(game.field_key == "banquet","rear route locked until ceremony")
	_do_point("kindness")
	if quests:
		await _side_step("seals")
		await _side_step("seals")
		await _side_step("seals",int(alternate))
	if not _check(_reach("ceremony"),"ceremony accessible from hall"):
		return false
	_key(KEY_E)
	_check(game.first.wedding_playing,"wedding starts on the map")
	await _capture("wedding-opening")
	for i in 3:
		_key(KEY_ENTER)
	if visual:
		await create_timer(0.32).timeout
		await _capture("wedding-strike")
	_drain_dialogue()
	_check(game.slot.hall.wedding,"wedding completion saved")
	var stock: int = game.slot.tonics
	for person in ["maid","servant"]:
		if not _check(_reach(person),"staff member can be reached: " + person):
			return false
		_key(KEY_E)
	_check(game.slot.hall.staff.size() == 2 and game.slot.tonics == mini(9,stock+1),"both evacuations reward supply once")
	_key(KEY_ESCAPE)
	_key(KEY_UP)
	_key(KEY_ENTER)
	_key(KEY_ENTER)
	_check(game.field_key == "banquet" and game.slot.hall.wedding and game.slot.hall.staff.size() == 2,
		"continue restores post-wedding room and both evacuations")
	print("PASS wedding, both evacuations, and room reload")
	await _capture("wedding-aftermath")
	if not _check(_reach("garden_door" if rear else "court_door"),"chosen route is reachable"):
		return false
	_key(KEY_E)
	return _check(game.field_key == ("garden" if rear else "hall"),"chosen route leads to correct room")

func _escape_garden() -> bool:
	await _capture("garden-entry")
	if rear_route == "alert":
		_walk_waypoints([[88,119],[91,91],[165,85]],false)
		game.first.patrol_clock = 0
		game.first.update(0.72)
		if not _check(game.mode == "dialogue" and game.storage.read().hall.alarm,"guard detects player in sight and saves alarm"):
			return false
		_drain_dialogue()
		await _capture("garden-guard-battle")
		if not await _play_battle():
			return false
		wins += 1
		print("PASS rear patrol spotted and defeated")
		_key(KEY_ENTER)
		if not _check(_reach("escape_door"),"rear gate reachable after guard battle"):
			return false
	else:
		var safe := [[60,145],[96,150],[135,153],[216,153],[247,146],[275,126],
			[300,112],[302,94],[302,70],[297,56],[294,46]]
		if not _check(_walk_waypoints(safe,true), "normal-speed route stays outside patrol warning"):
			return false
		_check(not game.slot.hall.alarm and not game.slot.cleared.has(1),"quiet escape skips the second fight")
		_check(game.nearest().get("id") == "escape_door","quiet route arrives at the rear gate")
		await _capture("garden-rear-gate")
		print("PASS quiet rear escape without a second fight")
	_key(KEY_E)
	return _check(game.mode == "dialogue","rear gate starts departure scene")

func _walk_waypoints(points: Array, patrol: bool) -> bool:
	for cell in points:
		var goal := Vector2(cell[0],cell[1]) * 2.0
		for step in 260:
			var shift := goal - Vector2(game.player)
			if shift.length() < 1.5:
				break
			var dt := minf(0.03,shift.length() / 101.0)
			game.walk(shift.normalized(),dt)
			if patrol:
				game.first.update(dt)
			if game.mode != "field":
				return false
		if game.player.distance_to(goal) >= 2.0:
			printerr("Unreachable waypoint %s from %s" % [goal,game.player])
			return false
	return true

func _check(value: bool, label: String) -> bool:
	if not value:
		failures += 1
		printerr("FAIL " + label)
	return value

func _capture(filename: String) -> void:
	if not visual or report_dir.is_empty():
		return
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	_check(image.save_png(report_dir.path_join(filename + ".png")) == OK, "write screenshot " + filename)

func _capture_effect(style: String) -> void:
	if not visual or report_dir.is_empty() or captured_effects.has(style):
		return
	captured_effects[style] = true
	await create_timer(0.23).timeout
	await _capture("fx-" + style)

func _verify_map(chapter: int) -> void:
	_check(game.passable(game.follower) and game.player.distance_to(game.follower) >= 28.0,
		"companion starts on a separate walkable point on " + game.stage.key)
	for key in ["spawn","guide","shrine","chest","exit"]:
		_check(game.passable(game.position_of(key)), "%s has walkable feet on %s" % [key,game.stage.key])
	for i in 3:
		_check(game.passable(game.position_of("fights",i)), "enemy %d has walkable feet on %s" % [i,game.stage.key])
	if chapter in [1,2,3]:
		var bridge_y: float = {1:100.0,2:96.0,3:92.0}[chapter]
		_check(game.passable(Vector2(320,bridge_y * 2.0)) == (chapter == 3), "bridge deck is initially gated where expected")
		_check(not game.passable(Vector2(320,(bridge_y+20)*2.0)), "channel blocks walking on " + game.stage.key)

func _key(key: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = key
	event.pressed = true
	game._unhandled_input(event)

func _joy(button: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	game._unhandled_input(event)

func _joy_axis(axis: JoyAxis, value: float, device: int = 0) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	event.device = device
	game._unhandled_input(event)

func _verify_joypad_menu() -> void:
	_joy_axis(JOY_AXIS_LEFT_Y,0.22)
	_check(game.selected == 0,"small stick drift leaves menu selection unchanged")
	_joy_axis(JOY_AXIS_LEFT_Y,0.8)
	_check(game.selected == 1 and game.using_joypad,"left stick advances the new-game menu")
	_joy_axis(JOY_AXIS_LEFT_Y,0.98)
	_joy_axis(JOY_AXIS_LEFT_Y,0.60)
	_joy_axis(JOY_AXIS_LEFT_Y,0.78)
	_check(game.selected == 1,"a held stick does not repeat menu navigation")
	_joy_axis(JOY_AXIS_LEFT_Y,0.20)
	_joy_axis(JOY_AXIS_LEFT_Y,-0.8)
	_check(game.selected == 0,"returning to center allows the next menu step")
	_joy_axis(JOY_AXIS_LEFT_Y,0.0)
	_joy_axis(JOY_AXIS_RIGHT_Y,0.8)
	_check(game.selected == 0,"right stick does not select menu items")
	_joy_axis(JOY_AXIS_LEFT_Y,0.8,1)
	game._joypad_connection_changed(1,false)
	_joy_axis(JOY_AXIS_LEFT_Y,-0.8,1)
	_check(game.selected == 0,"disconnecting clears the stick latch for the next connection")
	_joy_axis(JOY_AXIS_LEFT_Y,0.0,1)
	print("PASS injected joypad menu navigation, drift rejection and reconnect latch")

func _verify_orientation() -> void:
	for entry in [[Vector2.UP,"back"],[Vector2.DOWN,"front"],[Vector2.RIGHT,"side"],[Vector2.LEFT,"side"]]:
		game.walk(entry[0],0.08)
		_check(game.field_direction == entry[1],"walk uses " + entry[1] + " sprite")

func _drain_dialogue() -> void:
	var limit := 15
	while game.mode == "dialogue" and limit > 0:
		_key(KEY_ENTER)
		limit -= 1
	_check(limit > 0,"dialogue completes")

func _reach(kind: String, index: int = -1) -> bool:
	var points: Array = game.afterstory.points() if game.afterstory.active else game.chronicle.points()
	for point in points:
		if point.id == kind:
			return _go_to(point.pos,9.0) and game.nearest().get("id") == kind and game.passable(game.follower)
	if game.afterstory.active:
		return false
	if kind != "guide" and kind != "fight" and not game.map.has(kind):
		return false
	var marker: Vector2 = game.guide_point() if kind == "guide" else game.position_of("fights" if kind == "fight" else kind,index)
	if not _go_to(marker,13.0):
		return false
	var spot: Dictionary = game.nearest()
	return spot.get("id") == kind and spot.get("index") == index and game.passable(game.follower)

func _go_to(marker: Vector2, radius: float = 5.0) -> bool:
	var initial := Vector2i(game.player.round())
	var visited := {initial:initial}
	var frontier: Array[Vector2i] = [initial]
	var cursor := 0
	var end := initial
	var found := false
	while cursor < frontier.size():
		var node := frontier[cursor]
		cursor += 1
		if Vector2(node).distance_to(marker) < radius:
			end = node
			found = true
			break
		for step in STEPS:
			var next: Vector2i = node + step
			if not visited.has(next) and game.passable(Vector2(next)):
				visited[next] = node
				frontier.append(next)
	if not found:
		return false
	var route: Array[Vector2i] = []
	while end != initial:
		route.append(end)
		end = visited[end]
	route.reverse()
	for node in route:
		var change := Vector2(node) - Vector2(game.player)
		game.walk(change.normalized(),change.length()/101.0)
	return game.player.distance_to(marker) < radius + 1

func _play_battle() -> bool:
	var b: RefCounted = game.encounter
	for turn in 140:
		if game.mode != "battle":
			break
		var action := 0
		var foe_index: int = b.living_foe()
		for i in b.foes.size():
			if b.foes[i].hp > 0 and b.foes[i].hp < b.foes[foe_index].hp:
				foe_index = i
		var enemy: Dictionary = b.foes[foe_index]
		var self_unit: Dictionary = b.allies[b.actor]
		var heal_index: int = b.weakest_ally()
		var wounded: Dictionary = b.allies[heal_index]
		saw_shield = saw_shield or (enemy.id == "boss" and enemy.shield)
		if b.available(5) and (enemy.id != "boss" or (not poise_finish and enemy.shield)):
			action = 5
			combo_count += 1
		elif b.available(4) and wounded.hp < 42:
			action = 4
		elif self_unit.id == "dream" and b.available(1) and wounded.hp < 63:
			action = 1
		else:
			var best := float(self_unit.attack)
			for candidate in [1,2]:
				var move: Array = self_unit.moves[candidate - 1]
				if not b.available(candidate) or move[2] == "疗":
					continue
				var score := float(move[3]) + 3.0*float(move[4])
				if move[2] == enemy.weak:
					score += 16.0
				if enemy.hp < self_unit.attack and enemy.phase != "armor" and not enemy.shield:
					score -= 22
				if b._automatic(candidate) and b.foes.size() == 2 and b.foes[1-foe_index].hp > 0:
					score += 20
				if score > best:
					action = candidate
					best = score
		_key(KEY_1 + action)
		match action:
			1,2: used_actions.techniques += 1
			3: used_actions.guard += 1
			4: used_actions.tonics += 1
			5: used_actions.combo += 1
		if game.pending_action >= 0:
			var wanted := heal_index if action == 4 else foe_index
			if game.target != wanted:
				_key(KEY_RIGHT)
			_key(KEY_ENTER)
		if visual and not b.events.is_empty():
			var style: String = b.events[0].style
			await _capture_effect("combo-" + b.pair if style == "combo" else style)
	if game.mode != "victory":
		printerr("Battle %s failed, remaining foes %s, allies %s" % [str(game.active_battle),
			str(b.foes.map(func(e): return e.hp)),str(b.allies.map(func(e): return e.hp))])
		return _check(false,"battle must resolve as victory")
	return true

func _verify_model() -> void:
	var Battle = preload("res://scripts/battle.gd")
	var direct = Battle.new(["cloud","wind"],["gate_guard"],1,3,false,0)
	var defended = Battle.new(["cloud","wind"],["gate_guard"],1,3,false,0)
	direct.act(0,0)
	direct.act(0,0)
	defended.act(0,0)
	defended.act(3,0)
	_check(defended.allies[1].hp > direct.allies[1].hp, "guard mitigates the opening heavy attack")
	var b = Battle.new(["cloud","wind"],["godless"],1,2,false,4)
	for turn in 60:
		if b.result != "":
			break
		b.act(3,0)
	_check(b.result == "defeat","guard-only strategy reaches defeat")
	_check(not b.act(0,0),"finished battle rejects more actions")
	var heal = Battle.new(["wind","dream"],["demon"],1,2,false,3)
	heal.allies[1].hp = 0
	_check(heal.act(4,1) and heal.allies[1].hp == 58 and heal.tonics == 1,"medicine revives fallen teammate")
	var armor = Battle.new(["cloud","sage"],["godless"],1,2,false,4)
	armor.act(1,0)
	armor.act(1,0)
	armor.act(1,0)
	_check(armor.foes[0].broken or armor.foes[0].hp < armor.foes[0].max_hp,"armor takes damage through poise combat")
	var demon = Battle.new(["wind","dream"],["demon"],6,2,false,3)
	demon.foes[0].hp = 1000
	demon.foes[0].attack = 0
	demon.act(2,0)
	demon.act(3,0)
	demon.act(3,0)
	_check(demon.corruption == 0,"Wind's guard clears two corruption")
	demon.act(3,0)
	for attack in 3:
		demon.allies[0].qi = demon.allies[0].max_qi
		demon.act(2,0)
		if attack < 2:
			demon.act(3,0)
	_check(demon.corruption == 3 and demon.events.any(func(event): return event.get("text","").begins_with("反噬")),
		"third unmitigated blade use recoils and resets corruption")

func _verify_new_martial() -> void:
	var Battle = preload("res://scripts/battle.gd")
	var frost = Battle.new(["wind","frost"],["paper","claw"],1,3,false,1,false,{},true)
	frost.act(0,0)
	_check(frost.label(5) == "风霜封渡" and frost.act(5,0),"Fengxi duo has a distinct combo")
	_check(frost.signal_state == "called" and frost.foes[1].dormant and frost.round_no == 2,"combo delays a called reinforcement")
	frost.act(3,0)
	frost.act(3,0)
	_check(not frost.foes[1].dormant and frost.round_no == 3,"delayed reinforcement still arrives")
	var cover = Battle.new(["wind","cloud"],["gate_guard"],1,3,false,0,false,{"wind":[2,1]},true)
	var hp: int = cover.allies[1].hp
	_check(cover.targets_ally(1) and cover.act(1,1),"a defensive technique can target a partner")
	cover.act(0,0)
	_check(cover.allies[1].hp == hp and cover.allies[0].hp < cover.allies[0].max_hp,"cover redirects the foretold attack")
	var dream = Battle.new(["wind","dream"],["demon"],1,3,false,3,false,{},true)
	dream.allies[0].hp -= 35
	dream.corruption = 4
	dream.bond = 4
	_check(dream.label(5) == "风息回春" and dream.act(5,0) and dream.corruption == 0
		and dream.allies[0].ward,"Second Dream combo suppresses corruption and wards the ally")
	var sage = Battle.new(["cloud","sage"],["godless"],1,3,false,4,true,{},true)
	sage.bond = 4
	_check(sage.label(5) == "双剑开阵" and sage.act(5,0) and sage.foes[0].broken,"double-sword combo opens gold armor")
	print("PASS partner combos, delayed reinforcement and ally-targeted protection")

func _verify_backup() -> void:
	var path: String = game.storage.path
	_check(game.storage.write(game.slot),"ensure completed backup exists")
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file == null:
		_check(false,"open QA save to corrupt")
		return
	file.store_string("{}")
	file.close()
	_check(game.storage.read().finished,"invalid primary save falls back to backup")

func _verify_legacy() -> void:
	var previous := {"version":1,"chapter":0,"tonics":3,"merit":2,
		"cleared":[0],"chest":false,"finished":false,"intro_seen":true,"easy":false}
	_check(game.storage.write(previous),"previous-version slot format remains valid")
	game._title()
	_key(KEY_ENTER)
	_check(game.field_key == "hall" and game.slot.hall.room == "hall" and game.slot.cleared.has(0),
		"previous-version save resumes in courtyard and preserves progress")
	previous.chapter = 1
	previous.merit = 6
	previous.hall = {"room":"garden","wedding":true,"staff":["maid","servant"],"alarm":false}
	_check(game.storage.write(previous),"1.2 slot with a cleared bridge remains valid")
	game._title()
	_key(KEY_ENTER)
	_check(game.field_key == "village" and game.slot.campaign.crossing == "bridge" and game.player.x < 240
		and game.slot.merit == 6,"1.2 village save resumes west with its prior reward")
	previous.chapter = 2
	previous.cleared = [0,1]
	previous.merit = 10
	_check(game.storage.write(previous),"1.2 forge slot with both victories remains valid")
	game._title()
	_key(KEY_ENTER)
	_check(game.field_key == "forge" and game.slot.campaign.forge_gate and not game.slot.campaign.sword
		and _reach("sword"),"1.2 forge save can reach the new sword scene")
	previous.chapter = 5
	previous.merit = 24
	_check(game.storage.write(previous),"1.2 final chapter slot remains valid")
	game._title()
	_key(KEY_ENTER)
	_check(game.field_key == "lodge" and game.slot.campaign.sword and _reach("bedside"),
		"1.2 late save preserves sword and resumes at new farewell")
	previous.chapter = 4
	previous.cleared = [0]
	previous.campaign = game.storage._initial_campaign(previous)
	previous.campaign.palace_room = "jail"
	_check(game.storage.write(previous),"1.6 save retains jail checkpoint")
	game._title()
	_key(KEY_ENTER)
	_check(game.field_key == "jail" and not game.chronicle.enabled() and game.slot.chronicle.from_chapter == 5
		and game.slot.campaign.sword,"1.6 jail resumes safely and expansion starts in following chapter")
	if tidal:
		previous.chapter = 5
		previous.finished = true
		previous.cleared = [0,1]
		previous.campaign = game.storage._initial_campaign(previous)
		_check(game.storage.write(previous),"old completed slot without Tidegate remains valid")
		game._title()
		_key(KEY_UP)
		_key(KEY_ENTER)
		_check(game.afterstory.active and game.field_key == "tidal_ford" and game.storage.read().afterstory.tonics == 3,
			"old completed slot can enter Tidegate with its own supplies")

