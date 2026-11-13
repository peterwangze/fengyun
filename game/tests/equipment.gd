extends SceneTree

const Main = preload("res://main.tscn")
const Battle = preload("res://scripts/battle.gd")
const Equipment = preload("res://scripts/equipment.gd")
const Save = preload("res://scripts/save.gd")
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if "--profile=qa_equipment" not in OS.get_cmdline_user_args():
		push_error("Run with -- --profile=qa_equipment")
		quit(1)
		return
	var game := Main.instantiate()
	root.add_child(game)
	game._new_game(false)
	game._finish_intro()
	game.cancel()
	game.menu_confirm(4)
	_check(game.mode == "gear" and game.menu_items()[1][1] and not game.menu_items()[2][1], "pause opens loadout and shows acquisition conditions")
	game.menu_confirm(1)
	_check(Equipment.equipped(game.storage.read(), "cloud", 0) == "travel_coat", "wearing equipment saves it immediately")
	game._navigate(1, 0)
	game.menu_confirm(1)
	var slot: Dictionary = game.storage.read()
	_check(Equipment.owner(slot, "travel_coat") == "wind" and Equipment.equipped(slot,"cloud",0) == "", "transferring the only copy clears the previous wearer")
	game.menu_confirm(0)
	_check(Equipment.modifiers(game.storage.read(), "wind").is_empty(), "unequip removes modifiers and persists")
	game.slot.merit = 4
	game._commit()
	_check("获得 · 鳞纹背心" in game.gear_rewards and "获得 · 纳气玉扣" in game.gear_rewards,
		"reaching the first rank threshold unlocks both items")
	_check("境界 2 · 行装与武学现可搭配" in game.gear_rewards, "rank two announces the first build tier")
	var pending_rewards: Array = game.gear_rewards.duplicate()
	game._commit()
	_check(game.gear_rewards == pending_rewards, "repeated saves do not grant the reward or rank notice again")
	game.slot.chronicle.quests.courier = "done_quiet"
	game.slot.chronicle.quests.forgework = "done_rack"
	game._commit()
	_check("获得 · 信使铜牌" in game.gear_rewards and "获得 · 剑庐护腕" in game.gear_rewards,
		"completed side tasks grant their equipment")
	_check(not Equipment.assign(game.slot,"wind",0,"courier_badge") and not Equipment.assign(game.slot,"wind",0,"palace_mail"), "wrong slots and locked items are rejected")
	_check(Equipment.assign(game.slot,"wind",0,"forge_apron") and Equipment.assign(game.slot,"wind",1,"courier_badge"), "equip one item in each slot")
	var modifiers := Equipment.modifiers(game.slot,"wind")
	var baseline := Battle.new(["wind","cloud"],["gate_guard"],2,3,false)
	var equipped := Battle.new(["wind","cloud"],["gate_guard"],2,3,false,5,null,{},false,{"wind":modifiers})
	_check(equipped.allies[0].max_hp == baseline.allies[0].max_hp - 8, "weakness loadout charges its HP tradeoff")
	baseline.act(1,0)
	equipped.act(1,0)
	_check(equipped.foes[0].poise == baseline.foes[0].poise - 1 and equipped.foes[0].hp == baseline.foes[0].hp, "weakness gear adds poise damage without buffing skill power")
	var guard := Battle.new(["wind","cloud"],["gate_guard"],2,3,false,5,null,{},false,{"wind":modifiers})
	guard.allies[0].qi = 0
	_check("13" in guard.detail(3), "battle forecast reflects the guard recovery bonus")
	guard.act(3,0)
	_check(guard.allies[0].qi == 13, "gear changes the value of a guard turn")
	_test_other_effects(modifiers)
	game.cancel()
	game.cancel()
	var pad := InputEventJoypadButton.new()
	pad.pressed = true
	pad.button_index = JOY_BUTTON_LEFT_SHOULDER
	game._unhandled_input(pad)
	pad.button_index = JOY_BUTTON_X
	game._unhandled_input(pad)
	_check(game.mode == "gear" and game.gear_kind == 1, "gamepad opens equipment and changes slots")
	_test_migration()
	print("Equipment: %d failures" % failures)
	quit(1 if failures else 0)

func _test_other_effects(modifiers: Dictionary) -> void:
	var scout := Battle.new(["wind","cloud"],["shade"],2,3,false,5,null,{},false,{"wind":modifiers})
	scout.act(1,0)
	_check(scout.foes[0].broken and scout.foes[0].hp > 0, "courier equipment enables a one-action stagger on a live scout")
	var hunter := Battle.new(["wind","cloud"],["gate_guard"],2,3,false,5,null,{},false,{"wind":{"broken_damage":6,"armor":2}})
	var plain := Battle.new(["wind","cloud"],["gate_guard"],2,3,false)
	hunter.foes[0].broken = true
	plain.foes[0].broken = true
	hunter.act(1,0)
	plain.act(1,0)
	_check(hunter.foes[0].hp < plain.foes[0].hp, "pursuit item deals extra technique damage to a staggered foe")
	hunter._hurt_ally(0, 20, 1, "blade", 0)
	_check(hunter.allies[0].hp == hunter.allies[0].max_hp - 18, "armor reduces damage on the wearer")
	var healer := Battle.new(["dream","wind"],["gate_guard"],2,3,false,5,null,{},false,{"dream":{"heal":5}})
	healer.allies[1].hp = 1
	healer.act(1,0)
	_check(healer.allies[1].hp == 50, "healing gear boosts a technique cast on the team")

func _test_migration() -> void:
	var save := Save.new("qa_equipment_legacy")
	var old := save.fresh(false)
	old.erase("gear")
	_check(save.write(old) and save.read().gear.is_empty(), "older save loads with empty equipment slots")
	old.gear = {"wind":["travel_coat", "unknown"],"cloud":["travel_coat", "qi_ring"]}
	_check(save.write(old), "fixture contains recoverable equipment data")
	var restored := save.read()
	_check(Equipment.owner(restored,"travel_coat") in ["wind","cloud"] and Equipment.equipped(restored,"wind",1) == "" and Equipment.equipped(restored,"cloud",1) == "", "invalid items and locked items are discarded without dropping campaign progress")
	_check(Equipment.equipped(restored,"wind",0).is_empty() != Equipment.equipped(restored,"cloud",0).is_empty(), "duplicate copies in a save normalize to one wearer")

func _check(passed: bool, description: String) -> void:
	print(("PASS " if passed else "FAIL ") + description)
	if not passed:
		failures += 1
