extends SceneTree

const Main = preload("res://main.tscn")
const Mountain = preload("res://scripts/world_mountain.gd")
const Martial = preload("res://scripts/martial.gd")
const PROFILE := "qa_stage3_mountain_late"
var game
var checks := 0
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := Array(OS.get_cmdline_user_args())
	var profiles := args.filter(func(arg): return arg.begins_with("--profile="))
	if profiles != ["--profile=" + PROFILE]:
		printerr("Run with -- --profile=" + PROFILE)
		quit(2)
		return
	game = Main.instantiate()
	root.add_child(game)
	case_after_boss()
	case_all_before_boss()
	for suffix in ["", ".tmp", ".bak"]:
		var file: String = game.storage.path + suffix
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(file)
	print("Stage3 Mountain supplemental: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

func case_after_boss() -> void:
	setup(false)
	check(not Mountain.altar_open(game.slot),"fresh fracture begins with the altar locked")
	if not west():
		return
	check(Mountain.ready(game.slot) and not Mountain.altar_open(game.slot),"west marking alone does not skip the blood rite")
	game.world.leave()
	game.slot.chronicle.marks.blood_rite = true
	game._commit()
	check(Mountain.altar_open(game.slot),"blood rite plus west settlement opens the altar")
	if not fight_tyrant(false):
		return
	check(game.storage.read().world.finale == ["mountain_west"],"real victory writes only the pre-battle west result")
	game.chronicle.enter("dawn")
	game.world.from_main("mountain")
	check(game.world.phase() == "lanterns","mountain reopens footsteps after the final battle")
	if not medicine(true):
		return
	if not visit("world_mountain_hearth") or not visit("world_mountain_cavern") or not rearguard(true):
		return
	var saved: Dictionary = game.storage.read()
	check(Mountain.EVACUATIONS.all(func(id): return saved.world.tasks.get(id,"") == "done"),"both routes gain persistent late results in lanterns phase")
	check(saved.world.finale == ["mountain_west"],"late completion leaves the actual boss snapshot unchanged")
	check(game.world.finale_rows().filter(func(row): return row[0] == "渡口补录").size() == 2,
		"the Dawn report identifies late medicine and rearguard as two separate supplemental records")
	check(visit("world_mountain_rearguard_receipt") and game.storage.read().world.tasks.has("mountain_rearguard_receipt"),
		"a late follow-up receipt saves without duplication")

func case_all_before_boss() -> void:
	setup(true)
	check(not Mountain.altar_open(game.slot),"the blood rite alone does not open the altar")
	if not medicine(false):
		return
	check(Mountain.altar_open(game.slot),"medicine alone can also open the altar after blood rite")
	if not visit("world_mountain_hearth") or not visit("world_mountain_cavern") or not rearguard(false):
		return
	if not visit("world_mountain_hearth") or not visit("world_mountain_cavern") or not west():
		return
	game.world.leave()
	var facts: Dictionary = game.storage.read().world.tasks
	check(Mountain.EVACUATIONS.all(func(id): return facts.get(id,"") == "done"),"all three rescue results coexist before the final battle")
	if not fight_tyrant(true):
		return
	var saved: Dictionary = game.storage.read()
	check(saved.world.finale == Mountain.EVACUATIONS,"actual boss win freezes all three pre-battle rescues")
	check(game.world.finale_rows().filter(func(row): return row[0] == "渡口补录").is_empty(),"no pre-battle rescue is mislabeled as a late entry")

func setup(blood: bool) -> void:
	game.slot = game.storage.replay(5,true)
	game.slot.cleared = [0]
	game.slot.intro_seen = true
	game.slot.merit = 28
	game.slot.chronicle.marks = {"shatter_relic":true,"prepare":true}
	if blood:
		game.slot.chronicle.marks.blood_rite = true
	game.slot.chronicle.room = "lodge"
	game.slot.world.tasks = {"crate":true,"roster":true,"medicine":"done","medicine_handoff":true,
		"watch_witness":true,"watch_transfer_log":true,"watch_register":"anonymous","register_handoff":true}
	game._enter_chapter(false)
	game.world.from_main("mountain")
	check(game.world.active() and game.slot.world.area == "mountain_cavern" and game.world.phase() == "fractured",
		"fixture starts in playable fractured mountain")

func west() -> bool:
	return path(["world_mountain_hearth","world_mountain_steps","world_mountain_west_roll",
		"world_mountain_west_reed","world_mountain_west_luo","world_mountain_hearth","world_mountain_west_settle"])

func medicine(late: bool) -> bool:
	if not path(["world_mountain_hearth","world_mountain_medicine_custodian","world_mountain_medicine_pack"]):
		return false
	var expected := "接运" if late else "黄旗走石梁"
	if not check(string_for("world_mountain_medicine_escort").contains(expected),"the medicine route has the correct precursor and stage"):
		return false
	return path(["world_mountain_medicine_escort","world_mountain_lodge","world_mountain_medicine_confirm"])

func rearguard(late: bool) -> bool:
	if not path(["world_mountain_rearguard_dispatch","world_mountain_hearth","world_mountain_steps","world_mountain_rearguard_marks"]):
		return false
	var expected := "遗下的路障" if late else "换班簿误导"
	if not check(string_for("world_mountain_rearguard_chase").contains(expected),"the rearguard route has the correct precursor and stage"):
		return false
	return path(["world_mountain_rearguard_chase","world_mountain_rearguard_confirm"])

func string_for(id: String) -> String:
	for spot in game.field_points():
		if spot.id == id:
			return spot.name
	return ""

func path(ids: Array) -> bool:
	for id in ids:
		if not visit(id):
			return false
	return true

func visit(id: String) -> bool:
	for spot in game.field_points():
		if spot.id == id:
			if not check(game.passable(spot.pos),"walkable point " + id):
				return false
			game.player = spot.pos
			game.interact()
			drain()
			return check(game.mode == "field","interaction commits " + id)
	return check(false,"missing interaction " + id)

func drain() -> void:
	for i in 40:
		if game.mode != "dialogue":
			return
		game._confirm()

func fight_tyrant(expect_ward: bool) -> bool:
	game.slot.campaign.farewell = true
	game.chronicle.enter("peak")
	game.player = game.position_of("altar")
	game.interact()
	drain()
	if not check(game.slot.campaign.altar,"actual altar interaction becomes available after evacuation"):
		return false
	game.player = game.position_of("fights",1)
	game.interact()
	drain()
	if not check(game.mode == "battle","actual final fight starts"):
		return false
	var battle: RefCounted = game.encounter
	var wind: Dictionary = battle.allies.filter(func(unit: Dictionary): return unit.id == "wind").front()
	check(wind.ward == expect_ward,"the final battle aid follows the medicine result")
	for turn in 90:
		if game.mode != "battle":
			break
		var target: int = battle.living_foe()
		var enemy: Dictionary = battle.foes[target]
		var acting: Dictionary = battle.allies[battle.actor]
		var wounded: int = battle.weakest_ally()
		var action := 0
		if battle.available(5) and enemy.shield:
			action = 5
		elif battle.available(4) and battle.allies[wounded].hp * 3 < battle.allies[wounded].max_hp:
			action = 4
			target = wounded
		else:
			var best := float(acting.attack)
			for candidate in [1,2]:
				var move: Array = acting.moves[candidate-1]
				if battle.available(candidate) and move[2] != "疗" and not Martial.protection_move(move):
					var score := float(move[3]) + 3.0 * float(move[4]) + (16.0 if move[2] == enemy.weak else 0.0)
					if score > best:
						best = score
						action = candidate
		game._battle_act(action,target)
		game._skip_battle_effect()
	if not check(game.mode == "victory" and game.slot.cleared.has(1),"boss was beaten with genuine battle actions"):
		return false
	game.menu_confirm(0)
	return true

func check(condition: bool, label: String) -> bool:
	checks += 1
	if not condition:
		failures += 1
	print(("PASS " if condition else "FAIL ") + label)
	return condition
