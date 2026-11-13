extends SceneTree

const MAIN = preload("res://main.tscn")
const Equipment = preload("res://scripts/equipment.gd")
const Martial = preload("res://scripts/martial.gd")
const TrailGuide = preload("res://scripts/trail_guide.gd")
const Battle = preload("res://scripts/battle.gd")
const Items = preload("res://scripts/items.gd")
const Economy = preload("res://scripts/economy.gd")
const STEPS = [Vector2i(4,0),Vector2i(-4,0),Vector2i(0,4),Vector2i(0,-4)]
const ROUTE_STYLES := {"interrupt":"截势", "retaliate":"守反", "exploit":"乘隙"}
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
var pacing := false
var build_route := ""
var path_length := 0.0
var chapter_battles: Array[Dictionary] = []
var build_triggers := {"截势":0,"守反":0,"乘隙":0}
var measured_encounter: RefCounted
var battle_metrics := {}
var counterplay := false
var quest_carryover := false
var tactical_counts := {"fire_blocked":0, "fire_guarded":0, "mind_suppressed":0, "armor_opened":0}
var endgame := false
var endgame_counts := {}
var endgame_build_counts := {}
var tidal_battles: Array[Dictionary] = []
var market_route := ""
var market_observations: Array[String] = []
var learned_casts := {}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	visual = DisplayServer.get_name() != "headless"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--reports="):
			report_dir = arg.substr(10)
		if arg.begins_with("--rear-route="):
			rear_route = arg.get_slice("=",1)
		if arg.begins_with("--build-route="):
			build_route = arg.get_slice("=",1)
		if arg.begins_with("--market-route="):
			market_route = arg.get_slice("=",1)
	game = MAIN.instantiate()
	root.add_child(game)
	var all_encounters := "--all-encounters" in OS.get_cmdline_user_args()
	var easy := all_encounters and "--standard" not in OS.get_cmdline_user_args()
	var gear_route := "--gear-route" in OS.get_cmdline_user_args()
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
	pacing = "--pacing" in OS.get_cmdline_user_args()
	counterplay = "--counterplay" in OS.get_cmdline_user_args()
	quest_carryover = "--quest-carryover" in OS.get_cmdline_user_args()
	endgame = "--endgame" in OS.get_cmdline_user_args()
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
		path_length = 0
		chapter_battles.clear()
		_check(int(game.slot.chapter) == chapter and game.mode == "field","chapter %d opens" % (chapter+1))
		if pacing:
			_check(not _main_targets().is_empty(), "chapter starts with a main marker %d" % (chapter + 1))
		if gear_route:
			_equip_route()
		elif not build_route.is_empty():
			_equip_playtest_build(chapter)
		if market_route == "training" and chapter == 5:
			_prepare_manual("wind", "crosswind", 1)
			_equip_owned("wind", "reed_mantle")
			_prepare_manual("cloud", "cloud_return", 0)
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
			if alternate and build_route.is_empty():
				_alternate_loadout()
		_verify_map(chapter)
		if chapter == 0:
			_verify_orientation()
			await _special("spar","spar")
			if quests:
				await _side_step("seals")
		await _capture("field-%s" % game.stage.key)
		if not pacing and chapter == 1:
			_check(not _reach("exit"),"village exit unreachable before crossing")
		elif not pacing and chapter != 2:
			_check(_reach("exit"),"exit path %d" % (chapter+1))
			_key(KEY_E)
			_check(game.mode == "field" and game.toast_time > 0,"exit stays locked before combat")
		if not pacing:
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
		var order := [0,2,1] if all_encounters else [0,1]
		if chapter == 0 and not rear_route.is_empty():
			order.erase(1)
		if chapter == 1 and boat_route:
			if not await _take_ferry():
				quit(1)
				return
			order.erase(0)
		if chapter == 2 and all_encounters:
			order = [0,1,2]
		if chapter == 3:
			_do_point("apothecary")
			_do_point("pool_intro")
			if pacing:
				_check_main(["pool_back"],"Medicine hut after receiving instructions")
			if quests:
				await _side_step("remedy")
				await _side_step("remedy")
				if alternate:
					await _side_step("remedy",1)
					await _side_step("remedy")
				await _side_step("remedy",0)
			if not market_route.is_empty():
				await _visit_medicine_market()
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
					if game.field_points().any(func(point: Dictionary): return point.id == "courier_contact"):
						_do_point("courier_contact")
						_check(game.storage.read().chronicle.marks.get("courier_contact", false), "courier handoff persists")
				_do_point("palace_back")
				if market_route == "training":
					_prepare_manual("sage", "sword_trace", 0)
			if chapter == 5 and fight == 1 and quests:
				await _side_step("swordstory")
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
			if quests and chapter == 5 and fight == 1:
				var aid_kind: String = game.slot.chronicle.quests.swordstory
				var boss: Dictionary = game.encounter.foes[0]
				var expected: bool = (boss.poise == boss.max_poise - 2) if aid_kind == "done_guard" else game.encounter.bond == 1
				_check(expected and not game.encounter.quest_aid_line.is_empty(), "final fight receives the chosen sword testimony payoff")
				print("AID final %s %s" % [aid_kind, game.encounter.quest_aid_line])
			if quests and chapter == 1 and fight == 1:
				var paper: Dictionary = game.encounter.foes[0]
				var proof: bool = game.slot.chronicle.quests.seals == "done_proof"
				_check(paper.poise == paper.max_poise - int(proof) and (not game.encounter.quest_aid_line.is_empty()) == proof,
					"seal proof changes the enemy's opening stance on the west bank")
				if proof:
					print("AID west bank " + game.encounter.quest_aid_line)
			if quests and chapter == 4 and fight == 1 and game.chronicle.has("courier_contact"):
				var godless: Dictionary = game.encounter.foes[0]
				var detained: bool = game.slot.chronicle.quests.courier == "done_fight"
				var aid_applied: bool = godless.poise == godless.max_poise - 2 if detained else game.encounter.allies[1].ward
				_check(aid_applied and not game.encounter.quest_aid_line.is_empty(), "courier follow-up changes the armor fight opening")
				print("AID palace " + game.encounter.quest_aid_line)
			if market_route == "training":
				await _verify_training_in_battle(chapter, fight)
			if chapter == 0 and fight == 0 and not pacing:
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
			if endgame and not game.slot.easy and chapter == 5 and fight == 0:
				await _exercise_dragon_opening()
			if chapter == 1 and fight == 1 and market_route != "training" and (not pacing or build_route.is_empty()):
				await _signal_opening()
			if chapter == 3 and fight == 0 and market_route != "training":
				await _demon_opening()
			if chapter == 3 and fight == 1 and counterplay and not game.slot.easy:
				await _exercise_corruption_warning()
			if chapter == 2 and fight == 2 and build_route != "exploit":
				_check(game.encounter.allies[0].moves[1][0] == "剑扫长空","claimed sword equips move in swordpool after reload")
			if not await _play_battle():
				quit(1)
				return
			wins += 1
			_check(game.storage.read().cleared.has(fight),"victory and reward reload")
			var qi_left: Array = game.encounter.allies.map(func(unit): return "%s %d/%d" % [unit.name,unit.qi,unit.max_qi])
			print("PASS chapter %d encounter %d rounds %d tonics %d qi %s" %
				[chapter+1,fight,game.encounter.round_no,game.slot.tonics,",".join(qi_left)])
			if market_route == "training" and chapter == 2 and fight == 1:
				await _capture_tactic("market-fixed-drop")
			_key(KEY_ENTER)
			if not market_route.is_empty():
				_verify_battle_loot(chapter, fight)
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
			_print_pacing(chapter)
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
			if not market_route.is_empty():
				await _visit_forge_market()
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
			_print_pacing(chapter)
			continue
		if chapter == 3:
			if pacing:
				_check_main(["pool_gate"],"Magic pool after the demon fight")
			_do_point("pool_gate")
			if pacing:
				_check_main(["pool_escape"],"Magic pool fence opened")
			_do_point("pool_escape")
			if pacing:
				_check_main(["exit"],"Magic pool farewell complete")
		if chapter == 4:
			_do_point("tearoom")
			await _capture("2-tearoom-fire")
			_do_point("fire_signal")
			_do_point("evacuated")
			_do_point("palace_back")
		if chapter == 5 and quests:
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
				if endgame:
					_do_point("dawn_witness")
					_do_point("dawn_courier")
			_do_point("dawn_lamp")
			if quests and endgame:
				_do_point("dawn_reunion")
				_choose(int(alternate))
				var legacy: String = "reunion_aid" if alternate else "reunion_roll"
				_check(game.storage.read().chronicle.marks.get(legacy, false), "Fengxi reunion choice is saved")
				print("REUNION %s" % game.chronicle.ending_legacy())
			await _capture("2-dawn")
			_do_point("dawn_exit")
		_print_pacing(chapter)
	if _check(game.mode == "ending" and game.storage.read().finished,"ending and completed save"):
		await _capture("06-ending")
		_key(KEY_ENTER)
		_key(KEY_ENTER)
		_check(game.mode == "dialogue","completed save can replay epilogue")
		_drain_dialogue()
		_check(game.mode == "ending","epilogue replay returns to ending screen")
	if quests:
		var completed_slot: Dictionary = game.storage.read()
		var q: Dictionary = completed_slot.chronicle.quests
		_check(q.size() == 8 and q.values().all(func(value): return String(value).begins_with("done_")),
			"all eight quests finished and persisted")
		print("Quest outcomes: ",q)
		_check(Equipment.owned(completed_slot).size() >= 10,"all original rewards available after clearing the campaign and quests")
	if counterplay and not easy:
		_check(tactical_counts.fire_blocked + tactical_counts.fire_guarded > 0, "played at least one response to Duan Lang")
		_check(tactical_counts.mind_suppressed > 0, "suppressed the magic blade to prevent the stronger sweep")
		_check(tactical_counts.armor_opened > 0, "opened Godless's armor by reacting to the heavy attack")
		print("TACTICS ", tactical_counts)
	if tidal and game.mode == "ending":
		await _verify_afterstory()
	if not build_route.is_empty():
		print("Build activations during real battles: ",build_triggers)
		if build_route == "mix":
			_check(build_triggers.values().all(func(count: int): return count > 0),"each equipped style activated during campaign combat")
		else:
			var primary: String = ROUTE_STYLES[build_route]
			_check(build_triggers[primary] > 0 and build_triggers.values().count(0) == 2,
				"only the selected build activated during campaign combat")
	if endgame and not easy:
		_verify_endgame_counts()
	if not market_route.is_empty():
		_check(market_observations.size() >= 9, "the market route exercises drop, purchase and settlement checks")
		if market_route == "training":
			_check(learned_casts.size() == Martial.MANUALS.size(), "every acquired manual is used in a real encounter")
		print("MARKET route=%s events=%s" % [market_route, market_observations])
		print("MANUAL_CASTS ",learned_casts)
	_verify_replay()
	_check(saw_shield and combo_count > 0,"boss shield and combo reached")
	_check(wins == (18 if all_encounters else 12) - int(rear_route == "quiet") - int(boat_route),"all requested battles won")
	_verify_model()
	_verify_new_martial()
	_verify_backup()
	_verify_legacy()
	if not market_route.is_empty():
		_verify_market_legacy()
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

func _equip_route() -> void:
	var first: String = game.stage.party[0]
	var second: String = game.stage.party[1]
	var coat := "forge_apron" if Equipment.unlocked(game.slot,"forge_apron") else "travel_coat"
	_check(Equipment.assign(game.slot,first,0,coat),"equip the first party member")
	if Equipment.unlocked(game.slot,"scale_vest"):
		_check(Equipment.assign(game.slot,second,0,"scale_vest"),"equip the second party member")
	if Equipment.unlocked(game.slot,"courier_badge"):
		_check(Equipment.assign(game.slot,first,1,"courier_badge"),"equip stagger specialization")
	if Equipment.unlocked(game.slot,"qi_ring"):
		_check(Equipment.assign(game.slot,second,1,"qi_ring"),"equip the second member for sustained techniques")
	game._commit()
	print("Route loadout chapter %d: %s %s, %s %s" % [game.slot.chapter + 1, first, game.slot.gear[first], second, game.slot.gear.get(second,[])])

func _equip_playtest_build(chapter: int) -> void:
	if game.rank() < Martial.SYNERGY_TIER:
		return
	if ROUTE_STYLES.has(build_route):
		_equip_primary_build(chapter)
	else:
		_equip_mixed_build(chapter)
	game._commit()
	var detail: Array = game.stage.party.map(func(hero: String): return "%s %s" % [hero, Martial.synergy_text(game.slot, hero, game.rank())])
	print("Build loadout chapter %d: %s" % [chapter + 1, detail])

func _equip_mixed_build(chapter: int) -> void:
	match chapter:
		1:
			_equip_for_route("wind", [0, 2], "travel_coat", "qi_ring")
			_equip_for_route("frost", [0, 2], "scale_vest", "")
		2:
			_equip_for_route("cloud", [0, 1], "travel_coat", "qi_ring")
			_equip_for_route("wind", [1, 0], "scale_vest", "ferry_knot")
		3:
			_equip_for_route("wind", [0, 1], "scale_vest", "qi_ring")
			_equip_for_route("dream", [0, 1], "travel_coat", "ferry_knot")
		4:
			_equip_for_route("cloud", [0, 3], "scale_vest", "ferry_knot")
			_equip_for_route("sage", [0, 2], "travel_coat", "qi_ring")
		5:
			_equip_for_route("cloud", [0, 3], "scale_vest", "ferry_knot")
			_equip_for_route("wind", [0, 3], "travel_coat", "qi_ring")

func _equip_primary_build(chapter: int) -> void:
	var party: Array = game.stage.party
	var first: String = party[0]
	var second: String = party[1]
	match build_route:
		"interrupt":
			var badge := "courier_badge" if Equipment.unlocked(game.slot, "courier_badge") else ""
			_equip_for_route(first, [0, 1], "travel_coat", "qi_ring")
			_equip_for_route(second, [0, 1], "scale_vest", badge)
		"retaliate":
			var opener: Array = [0, 2] if first != "cloud" or Martial.unlocked(game.slot, first, 2) else [0, 1]
			var responder: Array = [0, 2] if Martial.unlocked(game.slot, second, 2) else [0, 1]
			_equip_for_route(first, opener, "travel_coat", "")
			_equip_for_route(second, responder, "scale_vest", "")
		"exploit":
			if chapter < 2:
				return
			var user: String = {2:"wind", 3:"dream", 4:"cloud", 5:"cloud"}[chapter]
			_equip_for_route(first, [0, 3] if first == "cloud" else [0, 1], "travel_coat", "ferry_knot" if user == first else "")
			var followup: Array = [1, 0] if second == "wind" else ([0, 3] if second == "cloud" else [0, 1])
			_equip_for_route(second, followup, "scale_vest", "ferry_knot" if user == second else "")

func _equip_for_route(hero: String, moves: Array, armor: String, accessory: String) -> void:
	_check(moves.all(func(at: int): return Martial.unlocked(game.slot, hero, at)), "route martial arts are available for " + hero)
	game.slot.chronicle.loadout[hero] = moves
	_check(Equipment.assign(game.slot, hero, 0, armor), "route armor is available for " + hero)
	_check(Equipment.assign(game.slot, hero, 1, accessory), "route accessory is available for " + hero)

func _main_targets() -> Array:
	return TrailGuide.main_points(game, game.field_points()).map(func(point: Dictionary):
		return "fight%d" % point.index if point.id == "fight" else point.id)

func _check_main(expected: Array, label: String) -> void:
	var markers := TrailGuide.main_points(game, game.field_points())
	var actual: Array = []
	for marker in markers:
		actual.append("fight%d" % marker.index if marker.id == "fight" else marker.id)
		_check(not String(marker.name).is_empty(), label + " marker also has a journal label")
		if marker.get("ground_marker", false):
			_check(game.passable(marker.pos),label + " marker lies on walkable terrain")
	_check(actual == expected, "%s main markers %s (expected %s)" % [label,actual,expected])
	if pacing:
		print("GUIDE %s %s" % [label, str(actual)])

func _print_pacing(chapter: int) -> void:
	if not pacing:
		return
	print("PACING " + JSON.stringify({"chapter":chapter + 1,"walk_seconds":snappedf(path_length / 101.0, 0.1),
		"rank_after":game.rank(),"tonics_after":game.slot.tonics,"encounters":chapter_battles}))

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
	var opening_tonics: int = game.afterstory.state().tonics
	var opening_powder: int = game.afterstory.state().supplies.guard_powder
	_do_point("brief")
	if quest_carryover and quests and alternate:
		_check(game.afterstory.state().tonics == opening_tonics + 1 and game.afterstory.state().supplies.guard_powder == opening_powder + 1,
			"preserving the grain sends medicine on Tidegate's first briefing")
		print("AID Tidegate grain +1 tonic and +1 ward powder")
	if endgame and quests:
		var before_tonics: int = game.afterstory.state().tonics
		var before_powder: int = game.afterstory.state().supplies.guard_powder
		_do_point("fengxi_contact")
		var received: int = int(alternate)
		_check(game.storage.read().afterstory.fengxi_contact and game.afterstory.state().tonics == before_tonics + received
			and game.afterstory.state().supplies.guard_powder == before_powder + received,
			"Tidegate contact consumes the stored reunion choice exactly once")
		_do_point("fengxi_contact")
		_check(game.afterstory.state().tonics == before_tonics + received and game.afterstory.state().supplies.guard_powder == before_powder + received,
			"contact remains revisitable without repeating the benefit")
		print("AID Tidegate reunion %s" % ("supplies" if alternate else "opening poise"))
	if not market_route.is_empty():
		await _visit_tidegate_market(baseline)
	_do_point("seal")
	_check(not _reach("gate_entry"),"gate route requires both pieces of evidence")
	_do_point("register")
	if quest_carryover and quests and not alternate:
		_check(game.afterstory.state().sluice and game.storage.read().afterstory.sluice,
			"saving the ferry opens Tidegate's waterway after both clues")
		print("AID Tidegate boat opened the waterway")
	_key(KEY_J)
	_check(game.mode == "journal","Tidegate journal opens")
	await _capture("tidal-journal")
	_key(KEY_ESCAPE)
	if tidal_sluice:
		if not game.afterstory.state().sluice:
			_check(not _reach("sluice_entry"),"watergate entry requires the winch or help from Fengxi")
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
		var initial_tonics: int = game.afterstory.state().tonics
		_key(KEY_5)
		_key(KEY_ENTER)
		for turn in 180:
			if game.mode != "battle":
				break
			_key(KEY_4)
		_check(game.mode == "defeat" and game.afterstory.state().tonics == initial_tonics,"defeat leaves Tidegate checkpoint supply intact")
		_key(KEY_ENTER)
		_check(game.mode == "battle" and game.encounter.tonics == initial_tonics,"retry restores Tidegate supply")
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
	if endgame and quests and not alternate:
		var drum: Dictionary = game.encounter.foes[1]
		_check(drum.poise == drum.max_poise - 2, "public reunion roll makes the tidegate drummer start two poise lower")
	await _capture("tidal-chief")
	if endgame and not game.slot.easy:
		await _exercise_tidal_formation()
	elif tidal_sluice:
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
	if pacing:
		print("TIDAL " + JSON.stringify({"route":selected_route, "ending":settlement, "encounters":tidal_battles}))

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
	if quests and id == "cavern_guard":
		var shift: String = game.slot.chronicle.quests.shift
		var beast: Dictionary = game.encounter.foes[0]
		var wind: Dictionary = game.encounter.allies.filter(func(unit: Dictionary): return unit.id == "wind").front()
		var expected: bool = beast.poise == beast.max_poise - 2 if shift == "done_fight" else wind.ward
		_check(expected and not game.encounter.quest_aid_line.is_empty(), "jailer choice carries into the Dragon Cave fight")
		print("AID cave %s %s" % [shift, game.encounter.quest_aid_line])
	if market_route == "training" and id == "first_tyrant":
		_cast_learned("cloud_return", 0)
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
	if not market_route.is_empty():
		await _visit_inn_market()
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
	if market_route == "training":
		_prepare_manual("wind", "crosswind", 0)
	if visual:
		_key(KEY_K)
		await _capture("2-martial")
		_key(KEY_ESCAPE)

func _visit_inn_market() -> void:
	_check(game.storage.read().get("manual_grants", {}).has("frost_gate"), "Fengxi crossing unlocks Frost's manual on either route")
	_check_grant("manual_grants", "frost_gate", "progress:ferry" if boat_route else "battle:village:0")
	if market_route == "training":
		if _do_point("seal_chase") and _check(game.mode == "battle", "investigating the inn opens the optional seal fight"):
			if await _play_battle():
				_key(KEY_ENTER)
				_check_grant("manual_grants", "crosswind", "hunt:inn")
				_check(not game.field_points().any(func(point: Dictionary): return point.id == "seal_chase"), "seal chase reward cannot be farmed")
		await _buy_at("inn", "reed_mantle")
		_equip_owned("wind", "reed_mantle")
		_prepare_manual("frost", "frost_gate", 0)
	else:
		await _buy_at("inn", "breath_pill")
		var source: Dictionary = Economy.SHOPS.inn.goods.filter(func(row: Dictionary): return row.id == "breath_pill").front()
		for extra in range(1, source.count):
			await _buy_at("inn", "breath_pill")
		_verify_sold_out("inn", "breath_pill")

func _visit_forge_market() -> void:
	if market_route == "training":
		await _buy_at("forge", "cloud_return")
		_prepare_manual("cloud", "cloud_return", 0)
		_equip_owned("cloud", "sword_tassel")
		_key(KEY_K)
		for move in range(Martial.MANUAL_INDEX):
			_key(KEY_DOWN)
		await _capture_tactic("market-fifth-move")
		_key(KEY_ESCAPE)
	else:
		await _buy_at("forge", "stagger_needle")

func _visit_medicine_market() -> void:
	if quests:
		_check_grant("manual_grants", "moon_needle", "quest:remedy")
	if market_route == "training":
		await _buy_at("medicine", "apothecary_gourd")
		_equip_owned("dream", "apothecary_gourd")
		_prepare_manual("dream", "moon_needle", 1)
	else:
		await _buy_at("medicine", "guard_powder")

func _visit_tidegate_market(baseline: Dictionary) -> void:
	await _buy_at("tidegate", "granary_vest" if market_route == "training" else "guard_powder")
	_check(game.storage.read().get("silver",0) == baseline.get("silver",0), "buying at Tidegate uses its separate silver")
	if market_route == "training":
		_equip_owned("cloud", "granary_vest")

func _verify_battle_loot(chapter: int, fight: int) -> void:
	match [chapter, fight]:
		[1, 1]:
			_check_grant("gear_grants", "tide_whistle", "battle:village:1")
		[2, 1]:
			_check_grant("gear_grants", "sword_tassel", "battle:forge:1")
		[4, 0]:
			_check_grant("manual_grants", "sword_trace", "battle:palace:0")

func _check_grant(section: String, id: String, claim: String) -> void:
	var saved: Dictionary = game.storage.read()
	_check(saved.get(section, {}).has(id) and saved.get("loot_claims", {}).has(claim), "fixed reward persists " + id)
	market_observations.append(id)

func _prepare_manual(hero: String, id: String, slot: int) -> void:
	if not _check(game.slot.get("manual_grants", {}).has(id) and Martial.unlocked(game.slot, hero, 4), "learned manual is selectable " + id):
		return
	_key(KEY_K)
	_check(game.mode == "martial", "manual is prepared using the normal martial screen")
	if game.stage.party[0] != hero:
		_key(KEY_RIGHT)
	if slot == 1:
		_key(KEY_TAB)
	game.menu_confirm(4)
	_check(int(game.storage.read().chronicle.loadout.get(hero, [0, 1])[slot]) == 4, "prepared manual persists " + id)
	_key(KEY_ESCAPE)

func _equip_owned(hero: String, id: String) -> void:
	if not _check(Equipment.unlocked(game.slot, id), "new equipment is available " + id):
		return
	_key(KEY_I)
	if game.stage.party[0] != hero:
		_key(KEY_RIGHT)
	var kind: int = Equipment.CATALOG[id].kind
	if kind == 1:
		_key(KEY_TAB)
	game.menu_confirm(Equipment.options(kind).find(id))
	_check(Equipment.equipped(game.storage.read(), hero, kind) == id, "new equipment persists " + id)
	_key(KEY_ESCAPE)

func _verify_training_in_battle(chapter: int, fight: int) -> void:
	match [chapter, fight]:
		[1, 1]:
			await _capture_tactic("market-frost-and-wind-manuals")
			_cast_learned("crosswind", 0)
			_cast_learned("frost_gate", 0)
		[3, 0]:
			_perform_action(2, 0)
			_cast_learned("moon_needle", 0)
		[4, 1]:
			_perform_action(1, 0)
			_cast_learned("sword_trace", 0)
			if game.encounter.foes[0].opening > 0:
				tactical_counts.armor_opened += 1

func _cast_learned(id: String, wanted: int) -> void:
	var battle: RefCounted = game.encounter
	var label: String = Martial.MANUALS[id].move[0]
	var action := 0
	for candidate in [1, 2]:
		if battle.label(candidate) == label:
			action = candidate
	if not _check(action > 0 and battle.available(action), "learned technique appears in its battle slot " + id):
		return
	_perform_action(action, wanted)
	if _check(not battle.events.is_empty() and battle.events[0].text == label, "learned technique executes " + id):
		learned_casts[id] = learned_casts.get(id, 0) + 1

func _buy_at(shop: String, id: String) -> void:
	if not _do_point("shop_" + shop) or not _check(game.mode == "shop" and game.shop_id == shop, "merchant is reachable " + shop):
		return
	var goods: Array = Economy.SHOPS[shop].goods
	var index := goods.find_custom(func(row: Dictionary): return row.id == id)
	if not _check(index >= 0, "merchant stocks " + id):
		_key(KEY_ESCAPE)
		return
	var account: Dictionary = game.afterstory.state() if game.afterstory.active else game.slot
	var before := Economy.offer(game.slot, account, shop, index)
	var money: int = account.silver
	var old_supply: int = account.supplies.get(id,0)
	if _check(before.limit.is_empty(), "purchase is affordable and has space %s (%s)" % [id,before.limit]):
		game.menu_confirm(index)
		var saved: Dictionary = game.storage.read()
		var saved_account: Dictionary = saved.afterstory if game.afterstory.active else saved
		var after := Economy.offer(saved, saved_account, shop, index)
		_check(saved_account.silver == money - before.price and after.remaining == before.remaining - 1, "purchase debits silver and finite stock once " + id)
		match goods[index].kind:
			"gear":
				_check(saved.gear_grants.has(id), "purchase grants equipment " + id)
			"manual":
				_check(saved.manual_grants.has(id), "purchase grants manual " + id)
			"supply":
				_check(saved_account.supplies[id] == old_supply + 1, "purchase increments bag " + id)
		if goods[index].kind in ["gear", "manual"]:
			game.menu_confirm(index)
			var repeated: Dictionary = game.storage.read()
			var repeated_account: Dictionary = repeated.afterstory if game.afterstory.active else repeated
			_check(repeated_account.silver == saved_account.silver, "one-time purchase cannot charge twice " + id)
		market_observations.append(shop + ":" + id)
		await _capture_tactic("market-" + shop)
	_key(KEY_ESCAPE)
	_check(game.mode == "field", "merchant closes back to the map")

func _verify_sold_out(shop: String, id: String) -> void:
	if not _do_point("shop_" + shop):
		return
	var goods: Array = Economy.SHOPS[shop].goods
	var index := goods.find_custom(func(row: Dictionary): return row.id == id)
	var silver: int = game.slot.silver
	_check(Economy.offer(game.slot, game.slot, shop, index).limit == "售罄", "reopening the shop preserves exhausted stock")
	game.menu_confirm(index)
	_check(game.storage.read().silver == silver, "sold-out purchase cannot debit the save")
	_key(KEY_ESCAPE)
	market_observations.append(shop + ":sold_out")

func _verify_market_legacy() -> void:
	var current: Dictionary = game.storage.read()
	for key in ["silver", "shop_stock", "loot_claims", "gear_grants", "manual_grants"]:
		current.erase(key)
	if current.has("afterstory"):
		for key in ["silver", "shop_stock", "loot_claims"]:
			current.afterstory.erase(key)
	_check(game.storage.write(current), "pre-economy completed slot can be loaded")
	var migrated: Dictionary = game.storage.read()
	_check(migrated.silver == Economy.START_SILVER + int(migrated.chapter) * 5
		and migrated.afterstory.silver == Economy.TIDE_SILVER and migrated.shop_stock.is_empty(), "older slot gets separate wallets and fresh shop stock")
	_check(migrated.manual_grants.has("sword_trace") and migrated.manual_grants.has("frost_gate")
		and migrated.gear_grants.has("sword_tassel") and migrated.gear_grants.has("tide_whistle"), "completed unique victories recover their drops on migration")
	_check(game.storage.write(migrated) and game.storage.read().silver == migrated.silver, "migration does not repeat rewards")
	print("MARKET_MIGRATION passed")

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
	if pacing:
		_check_main(["stone_bridge" if game.slot.cleared.has(0) else "fight0", "mooring"],"Fengxi approach")
	if not _check(_reach("mooring"),"old dock reached"):
		return false
	_key(KEY_E)
	_check(game.slot.campaign.rope,"rope released")
	if pacing:
		_check_main(["stone_bridge" if game.slot.cleared.has(0) else "fight0", "escort_boatman"],"Fengxi rope released")
	_resume()
	_check(game.slot.campaign.rope and game.slot.campaign.crossing.is_empty(),"mid-ferry setup resumes on east bank")
	_go_to(game.position_of("guide") + Vector2(-25,3))
	for i in 40:
		game.walk(Vector2.ZERO,0.04)
	if not _check(_reach("board") and game.campaign.ferry_ready(),"escort ferryman to dock"):
		printerr("Board diagnostics player=%s boatman=%s target=%s nearest=%s follower=%s" %
			[game.player,game.campaign.boatman,game.position_of("board"),game.nearest(),game.follower])
		return false
	if pacing:
		_check_main(["stone_bridge" if game.slot.cleared.has(0) else "fight0", "board"],"Fengxi boarding ready")
	var original_motion: bool = game.settings.motion
	game.settings.motion = true
	_key(KEY_E)
	_check(game.mode == "ferry","board starts crossing")
	_key(KEY_ESCAPE)
	_check(game.mode == "field" and game.slot.campaign.crossing.is_empty(),"early turn back leaves reward unclaimed")
	if reduced_ferry:
		game.settings.motion = false
		_key(KEY_E)
		_check(game.mode == "field","reduced-motion ferry lands immediately")
	else:
		_key(KEY_E)
		if visual:
			await create_timer(0.72).timeout
			await _capture("ferry-crossing")
		_key(KEY_ENTER)
	game.settings.motion = original_motion
	_check(game.slot.merit == merit + 2 and game.slot.campaign.crossing == "boat","boat route grants one landing reward")
	_resume()
	_check(game.slot.merit == merit + 2 and game.slot.campaign.crossing == "boat","ferry reload does not repeat reward")
	print("PASS ferry turn back, land and reload%s" % (" with reduced motion" if reduced_ferry else ""))
	return _check(game.player.x < 240,"ferry lands on west bank")

func _cross_bridge() -> bool:
	var merit: int = game.slot.merit
	if not _check(game.slot.cleared.has(0) and game.passable(Vector2(320,200)),"win unlocks bridge"):
		return false
	if pacing:
		_check_main(["stone_bridge", "mooring"],"Fengxi bridge unlocked")
	var reached := _go_to(game.position_of("west_spawn"))
	_check(game.slot.merit == merit + 2 and game.slot.campaign.crossing == "bridge","bridge landing grants two merit")
	_check(_go_to(Vector2(403,204)) and _go_to(game.position_of("west_spawn")) and game.slot.merit == merit+2,
		"crossing back and forth cannot repeat reward")
	return _check(reached,"west bank reached by stone bridge")

func _cross_forge() -> bool:
	if pacing:
		_check_main(["winch", "north_ledge"],"Forge crossings available")
	if not forge_ledge:
		if not _check(_reach("winch"),"reach sluice winch"):
			return false
		_key(KEY_E)
		_check(game.slot.campaign.forge_gate and game.passable(Vector2(320,192)),"opened sluice clears bridge")
		if pacing:
			_check_main(["sluice_bridge", "north_ledge"],"Forge sluice opened")
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

func _exercise_corruption_warning() -> void:
	var battle: RefCounted = game.encounter
	_key(KEY_3)
	_key(KEY_4)
	_key(KEY_3)
	used_actions.techniques += 2
	used_actions.guard += 1
	if battle.foes[0].broken:
		_key(KEY_4)
		used_actions.guard += 1
	_check(battle.corruption == 4 and battle.intent(battle.foes[0]).contains("魔念横扫"),
		"using the magic blade twice makes the stronger sweep visible before the enemy acts")
	await _capture_tactic("demon-mind-sweep")
	if battle.actor == 0:
		_key(KEY_4)
		used_actions.guard += 1
	else:
		_key(KEY_2)
		used_actions.techniques += 1
	_check(battle.corruption < 4 and battle._pattern(battle.foes[0]) != "mind_sweep",
		"guard or healing suppresses the visible sweep before the enemy acts")
	tactical_counts.mind_suppressed += 1

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
	if pacing:
		_check_main(["ceremony"],"Banquet after speaking to Kong Ci")
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
	if pacing:
		_check_main(["court_door", "garden_door"],"Wedding escape routes")
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
			var prior: Vector2 = game.player
			game.walk(shift.normalized(),dt)
			path_length += prior.distance_to(game.player)
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

func _capture_tactic(name: String) -> void:
	if not visual or report_dir.is_empty() or captured_effects.has(name):
		return
	captured_effects[name] = true
	await create_timer(1.4).timeout
	await _capture(name)

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
	var battle: RefCounted = game.encounter if pacing and game.mode == "battle" else null
	if battle == null:
		game._unhandled_input(event)
		return
	if measured_encounter != battle:
		measured_encounter = battle
		battle_metrics = {"actions":0,"lowest_hp_pct":100,"tonics_start":battle.tonics,
			"supplies_start":battle.supplies.duplicate()}
	var before := [battle.round_no, battle.actor, battle.result]
	game._unhandled_input(event)
	if before != [battle.round_no, battle.actor, battle.result]:
		battle_metrics.actions += 1
		for effect in battle.events:
			if effect.kind == "damage" and effect.side == "ally":
				var pct := roundi(100.0 * effect.stats.hp / battle.allies[effect.index].max_hp)
				battle_metrics.lowest_hp_pct = mini(battle_metrics.lowest_hp_pct, pct)

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
	var points: Array = game.field_points()
	for point in points:
		if point.id == kind and (index < 0 or point.get("index", -1) == index):
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
		var prior: Vector2 = game.player
		game.walk(change.normalized(),change.length()/101.0)
		path_length += prior.distance_to(game.player)
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
		var selection := _build_action(b, self_unit, enemy, foe_index) if not build_route.is_empty() else {}
		var tactical := _boss_response(b, enemy, foe_index, selection) if counterplay and not b.story_mode else {}
		if not tactical.is_empty():
			selection = tactical
		saw_shield = saw_shield or (enemy.id == "boss" and enemy.shield)
		if b.available(5) and (enemy.id != "boss" or (not poise_finish and enemy.shield)):
			action = 5
			combo_count += 1
		elif b.available(4) and (wounded.hp < 42 if not pacing else wounded.hp * 3 < wounded.max_hp):
			action = 4
		elif not selection.is_empty():
			action = selection.action
		elif self_unit.id == "dream" and b.available(1) and self_unit.moves[0][0] == "回春诀" and wounded.hp < 63:
			action = 1
		else:
			var best := float(self_unit.attack)
			for candidate in [1,2]:
				var move: Array = self_unit.moves[candidate - 1]
				if not b.available(candidate) or move[2] == "疗" or Martial.protection_move(move):
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
		var foe_before := {"opening": enemy.get("opening", 0), "pattern": b._pattern(enemy)}
		if endgame and not b.story_mode and enemy.id == "boss" and enemy.shield:
			await _capture_tactic("tyrant-shield")
		if counterplay and not b.story_mode:
			if foe_before.pattern == "fire_sweep" and tactical_counts.fire_blocked + tactical_counts.fire_guarded == 0:
				await _capture_tactic("duan-fire-sweep")
			if foe_before.pattern == "armor_bash" and tactical_counts.armor_opened == 0:
				await _capture_tactic("godless-heavy-attack")
		var acting: int = b.actor
		var wanted: int = heal_index if action == 4 else (selection.target if selection.get("action") == action else foe_index)
		_perform_action(action, wanted)
		if endgame and not b.story_mode and enemy.id == "boss" and _battle_phase(b, "归元气破"):
			_record_tactic("tyrant_transition")
			await _capture_tactic("tyrant-shield-broken")
		if endgame and not b.story_mode and foe_before.pattern == "tyrant_palm" and enemy.get("opening", 0) > foe_before.opening:
			_record_tactic("tyrant_palm_opened")
		if counterplay and not b.story_mode:
			if foe_before.pattern in ["kindle", "fire_sweep"] and b.events.any(func(event: Dictionary):
				return event.kind == "break" and event.side == "foe" and event.index == foe_index):
				tactical_counts.fire_blocked += 1
			if foe_before.pattern == "fire_sweep" and b.events.any(func(event: Dictionary):
				return event.kind == "damage" and event.side == "ally" and event.style == "guard"):
				tactical_counts.fire_guarded += 1
			if enemy.id == "godless" and enemy.get("opening", 0) > foe_before.opening and foe_before.pattern == "armor_bash":
				tactical_counts.armor_opened += 1
				await _capture_tactic("godless-armor-opening")
			if tactical.get("action") == action:
				print("RESPONSE %s %s %s" % [enemy.id, foe_before.pattern, b.allies[acting].name])
		if visual and not b.events.is_empty():
			var style: String = b.events[0].style
			await _capture_effect("combo-" + b.pair if style == "combo" else style)
	if game.mode != "victory":
		printerr("Battle %s failed, remaining foes %s, allies %s" % [str(game.active_battle),
			str(b.foes.map(func(e): return e.hp)),str(b.allies.map(func(e): return e.hp))])
		return _check(false,"battle must resolve as victory")
	if pacing:
		battle_metrics.merge({"fight":game.battle_info()[0],"rounds":b.round_no,
			"tonics_used":battle_metrics.tonics_start - b.tonics,
			"supplies_used":battle_metrics.supplies_start.keys().filter(func(id: String):
				return battle_metrics.supplies_start[id] > b.supplies[id]),
			"qi_left":b.allies.map(func(unit: Dictionary): return int(unit.qi))})
		if game.afterstory.active:
			tidal_battles.append(battle_metrics)
		else:
			chapter_battles.append(battle_metrics)
	return true

func _verify_endgame_counts() -> void:
	print("ENDGAME tactics ", endgame_counts)
	print("ENDGAME build activations ", endgame_build_counts)
	if build_route == "interrupt" or build_route.is_empty():
		_check(endgame_counts.get("dragon_stopped", 0) > 0, "dragon draw interrupted by a real player command")
		_check(endgame_counts.get("formation_cancelled", 0) > 0, "the formed Tidegate attack can be broken")
	else:
		_check(endgame_counts.get("dragon_opened", 0) > 0, "defending dragon reflux exposes an opening")
		_check(endgame_counts.get("formation_opened", 0) > 0, "defending the coordinated assault exposes an opening")
	_check(endgame_counts.get("tyrant_transition", 0) > 0, "Tyrant exposes a new attack once his shield falls")
	if ROUTE_STYLES.has(build_route):
		var primary: String = ROUTE_STYLES[build_route]
		_check(endgame_build_counts.get("tidal_" + primary, 0) > 0, "the exclusive build also activates in the Tidegate story")

func _record_tactic(key: String) -> void:
	endgame_counts[key] = endgame_counts.get(key, 0) + 1

func _record_build_trigger(battle: RefCounted, style_name: String) -> void:
	if not build_triggers.has(style_name):
		return
	build_triggers[style_name] += 1
	if game.afterstory.active or (game.field_key == "peak" and battle.foes[0].id in ["dragon", "boss"]):
		var region := "tidal" if game.afterstory.active else battle.foes[0].id as String
		var trigger_key := region + "_" + style_name
		endgame_build_counts[trigger_key] = endgame_build_counts.get(trigger_key, 0) + 1

func _battle_phase(battle: RefCounted, label: String) -> bool:
	return battle.events.any(func(event: Dictionary): return event.get("phase_change", false) and event.text == label)

func _exercise_dragon_opening() -> void:
	var battle: RefCounted = game.encounter
	var enemy: Dictionary = battle.foes[0]
	_check(battle._pattern(enemy) == "dragon_draw" and battle.intent(enemy).contains("龙息"), "dragon draw is advertised on its own panel")
	await _capture_tactic("dragon-draw")
	if build_route in ["retaliate", "exploit", "mix"]:
		_perform_action(3, 0)
		_perform_action(3, 1)
		_check(enemy.get("flow", false) and battle._pattern(enemy) == "dragon_reflux", "uninterrupted breath queues the stronger reflux")
		await _capture_tactic("dragon-reflux")
		_defend_late_attack(battle, 0, 1)
		_check(enemy.get("opening", 0) > 0, "a defended reflux creates a dragon opening")
		if enemy.get("opening", 0) > 0:
			_record_tactic("dragon_opened")
		await _capture_tactic("dragon-opened")
	else:
		var first_action: int = 2 if battle.available(2) and Martial.interrupt_move(battle.allies[battle.actor].moves[1]) else 1
		_perform_action(first_action, 0)
		var action: int = 2 if battle.available(2) and battle.poise_preview(2, 0).begins_with("可破势") else 1
		if not battle.poise_preview(action, 0).begins_with("可破势") and battle.available(Battle.FIRST_SUPPLY + 2):
			action = Battle.FIRST_SUPPLY + 2
		_perform_action(action, 0)
		var stopped := _battle_phase(battle, "龙息中断")
		if not stopped and battle.result == "":
			_check(enemy.get("flow", false) and battle._pattern(enemy) == "dragon_reflux", "unspent breath prepares the reflux before the break")
			_perform_action(1, 0)
			stopped = _battle_phase(battle, "龙息中断")
		_check(stopped and not enemy.get("flow", false), "interrupting dragon draw prevents reflux")
		if stopped:
			_record_tactic("dragon_stopped")
		await _capture_tactic("dragon-stopped")

func _exercise_tidal_formation() -> void:
	var battle: RefCounted = game.encounter
	var chief: Dictionary = battle.foes[0]
	_perform_action(3, 0)
	_perform_action(3, 1)
	_check(chief.get("formation", false) and battle._pattern(chief) == "tidal_advance", "the drum advertises and creates a coordinated assault")
	await _capture_tactic("tidal-formation")
	if build_route in ["retaliate", "exploit", "mix"]:
		_defend_late_attack(battle, 0, battle._threat_target(chief))
		_check(chief.get("opening", 0) > 0, "defending the coordinated assault opens the commander")
		if chief.get("opening", 0) > 0:
			_record_tactic("formation_opened")
		await _capture_tactic("tidal-opened")
	else:
		_perform_action(1, 1)
		var action: int = 1
		if not battle.poise_preview(action, 1).begins_with("可破势") and battle.available(Battle.FIRST_SUPPLY + 2):
			action = Battle.FIRST_SUPPLY + 2
		var stopped := _battle_phase(battle, "鼓令瓦解")
		if battle.result == "" and chief.get("formation", false):
			_perform_action(action, 1)
			stopped = _battle_phase(battle, "鼓令瓦解")
		_check(stopped and not chief.get("formation", false), "breaking the drum cancels the prepared attack")
		if stopped:
			_record_tactic("formation_cancelled")
		await _capture_tactic("tidal-cancelled")

func _defend_late_attack(battle: RefCounted, foe: int, protected: int) -> void:
	for turn in 2:
		var chosen := 3 if battle.actor == protected else 0
		if build_route in ["retaliate", "mix"]:
			var unit: Dictionary = battle.allies[battle.actor]
			for action in [1, 2]:
				if not battle.available(action) or not Martial.protection_move(unit.moves[action - 1]):
					continue
				var kind: String = unit.moves[action - 1][6]
				if kind == "counter" and battle.actor == protected or kind == "cover" and battle.actor != protected:
					chosen = action
					break
		_perform_action(chosen, protected if chosen in [1, 2] else foe)
		if battle.result != "":
			break

func _perform_action(action: int, wanted: int) -> void:
	var battle: RefCounted = game.encounter
	if action >= Battle.FIRST_SUPPLY:
		_key(KEY_B)
		for next in range(action - Battle.FIRST_SUPPLY + 1):
			_key(KEY_RIGHT)
		_key(KEY_ENTER)
	else:
		_key(KEY_1 + action)
	if game.pending_action >= 0:
		if game.target != wanted:
			_key(KEY_RIGHT)
		_key(KEY_ENTER)
	match action:
		1,2: used_actions.techniques += 1
		3: used_actions.guard += 1
		4: used_actions.tonics += 1
		5: used_actions.combo += 1
	if not build_route.is_empty() and not battle.synergy_feedback.is_empty():
		_record_build_trigger(battle, battle.synergy_feedback.get_slice(" ", 0))

func _boss_response(b: RefCounted, enemy: Dictionary, foe_index: int, build_selection: Dictionary) -> Dictionary:
	if enemy.broken:
		return {}
	var pattern: String = b._pattern(enemy)
	var actor: Dictionary = b.allies[b.actor]
	if pattern == "kindle" and b.round_no == 1 and build_route == "retaliate":
		return {"action":3,"target":b.actor}
	if pattern == "fire_sweep" and build_route == "retaliate":
		if not build_selection.is_empty() and build_selection.action in [1, 2] and Martial.protection_move(actor.moves[build_selection.action - 1]):
			return build_selection
		return {"action":3,"target":b.actor}
	if pattern == "armor_bash" and not actor.ward and not actor.guard:
		var target: int = b._threat_target(enemy)
		if b.actor == target:
			if not build_selection.is_empty() and build_selection.action in [1, 2] and Martial.protection_move(actor.moves[build_selection.action - 1]):
				return build_selection
			if b.round_no == 1 or build_route == "retaliate":
				return {"action":3,"target":target}
	if pattern in ["kindle", "fire_sweep"] and build_selection.is_empty():
		for action in [1, 2]:
			if b.available(action) and b.poise_preview(action, foe_index).begins_with("可破势"):
				return {"action":action,"target":foe_index}
		var needle := Battle.FIRST_SUPPLY + 2
		if b.available(needle) and b.poise_preview(needle, foe_index).begins_with("可破势"):
			return {"action":needle,"target":foe_index}
	return {}

func _build_action(b: RefCounted, unit: Dictionary, enemy: Dictionary, foe_index: int) -> Dictionary:
	for candidate in [1, 2]:
		if not b.available(candidate):
			continue
		var move: Array = unit.moves[candidate - 1]
		if unit.build.has("exploit") and Martial.exploit_move(move):
			for at in b.foes.size():
				if b.foes[at].hp > 0 and (b.foes[at].broken or b.foes[at].get("opening", 0) > 0):
					return {"action":candidate,"target":at}
		if unit.build.has("interrupt") and Martial.interrupt_move(move):
			for at in b.foes.size():
				if b.poise_preview(candidate, at).begins_with("可破势"):
					return {"action":candidate,"target":at}
	if b.bond < 4 and unit.build.has("retaliate") and enemy.hp > unit.attack:
		for candidate in [1, 2]:
			var move: Array = unit.moves[candidate - 1]
			if not b.available(candidate) or not Martial.protection_move(move):
				continue
			var defender: int = b.actor if move[6] == "counter" else 1 - b.actor
			for threat in b.foes:
				if threat.hp <= 0 or threat.broken:
					continue
				var pattern: String = b._pattern(threat)
				if pattern in ["sweep", "fire_sweep", "mind_sweep"] or (pattern in ["strike", "charge", "armor_bash"] and (move[6] == "shelter" or b._threat_target(threat) == defender)):
					return {"action":candidate,"target":defender}
	for candidate in [1, 2]:
		var move: Array = unit.moves[candidate - 1]
		if not b.available(candidate) or not Martial.interrupt_move(move):
			continue
		var other: Dictionary = b.allies[1 - b.actor]
		if b.actor == 0 and other.build.has("exploit") and b.poise_preview(candidate, foe_index).begins_with("可破势"):
			return {"action":candidate,"target":foe_index}
	return {}

func _verify_model() -> void:
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

