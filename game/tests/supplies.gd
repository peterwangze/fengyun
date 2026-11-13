extends SceneTree

const Main = preload("res://main.tscn")
const Afterstory = preload("res://scripts/afterstory.gd")
const Battle = preload("res://scripts/battle.gd")
const Items = preload("res://scripts/items.gd")
const Save = preload("res://scripts/save.gd")

const STOCK := {"breath_pill":2, "guard_powder":2, "stagger_needle":2}
const QI := 6
const WARD := 7
const NEEDLE := 8
const PROFILE := "qa_supplies"

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if "--profile=" + PROFILE not in OS.get_cmdline_user_args():
		push_error("Run with -- --profile=" + PROFILE)
		quit(1)
		return
	_test_qi()
	_test_ward()
	_test_needle()
	_test_rewards()
	_test_game_flow()
	print("Supplies: %d failures" % failures)
	quit(1 if failures else 0)

func _battle(foes: Array = ["gate_guard"], chapter: int = 0, stock: Dictionary = STOCK) -> RefCounted:
	return Battle.new(["wind", "cloud"], foes, 1, 3, false, chapter, false, {}, true, {}, stock)

func _test_qi() -> void:
	var battle := _battle()
	_check(battle.bag_actions() == [4, QI, WARD, NEEDLE], "bag keeps tonic and the three field supplies in order")
	_check(not battle.available(QI) and not battle.act(QI, 0), "qi pill is unavailable at full qi")
	battle.allies[1].qi = 4
	var before: Dictionary = battle.presentation()
	var before_stock: Dictionary = battle.supplies.duplicate()
	_check(battle.available(QI) and not battle.act(QI, 0) and not battle.act(QI, 2), "qi pill rejects a full or out-of-range target")
	_check(battle.presentation() == before and battle.supplies == before_stock, "invalid targets do not consume stock or advance the turn")
	_check(battle.act(QI, 1) and battle.allies[1].qi == 22 and battle.supplies.breath_pill == 1 and battle.actor == 1,
		"qi pill restores 18 to a living ally and spends a turn")
	_check(STOCK.breath_pill == 2, "combat stock is isolated from its source dictionary")
	var clamped := _battle()
	clamped.allies[0].qi -= 4
	_check(clamped.act(QI, 0) and clamped.allies[0].qi == clamped.allies[0].max_qi, "qi pill caps recovery at maximum qi")

func _test_ward() -> void:
	var battle := _battle()
	battle.allies[0].hp = 0
	_check(not battle.act(WARD, 0) and battle.supplies.guard_powder == 2, "ward cannot be spent on a fallen ally")
	battle.allies[0].hp = battle.allies[0].max_hp
	_check(battle.act(WARD, 1) and battle.allies[1].ward and battle.supplies.guard_powder == 1, "ward protects the chosen ally")
	_check(not battle.act(WARD, 1) and battle.supplies.guard_powder == 1, "ward cannot be stacked or consumed twice")
	var hp: int = battle.allies[1].hp
	battle._hurt_ally(1, 20, 1, "blade", 0)
	_check(not battle.allies[1].ward and battle.allies[1].hp == hp - 9, "ward reduces one hit by 55 percent and is consumed")
	battle._hurt_ally(1, 20, 1, "blade", 0)
	_check(battle.allies[1].hp == hp - 29, "subsequent hits use their ordinary damage")

func _test_needle() -> void:
	var battle := _battle(["paper", "claw"], 1)
	var hp: int = battle.foes[0].hp
	_check(not battle.act(NEEDLE, 1) and battle.supplies.stagger_needle == 2, "needle cannot target dormant reinforcements")
	_check(battle.act(1, 0) and battle.foes[0].poise == 2, "wind technique leaves exactly two poise on the signaler")
	hp = battle.foes[0].hp
	_check(battle.act(NEEDLE, 0) and battle.foes[0].hp == hp and battle.signal_state == "blocked" and battle.foes[1].dormant,
		"needle interrupts the signal without dealing damage or waking reinforcements")
	var resolve := _battle(["boss"])
	resolve.foes[0].poise = 2
	resolve.foes[0].resolve = true
	_check(resolve.act(NEEDLE, 0) and resolve.foes[0].poise == 1 and not resolve.foes[0].broken, "needle respects boss resolve")
	_check(not resolve.act(NEEDLE, 0) and resolve.supplies.stagger_needle == 1, "needle cannot be wasted on resolve-protected last poise")
	var shield := _battle(["boss"])
	shield.foes[0].poise = 1
	shield.foes[0].shield = true
	shield.foes[0].cracks = 1
	_check(shield.act(NEEDLE, 0) and shield.shield_resolution == "poise" and not shield.foes[0].shield,
		"needle breaks the last shield crack through the ordinary break rule")

func _test_rewards() -> void:
	var stock := Items.clean({"breath_pill":-1, "guard_powder":9, "stagger_needle":2.5, "unknown":1})
	_check(stock == {"breath_pill":0, "guard_powder":5, "stagger_needle":0}, "malformed stock is sanitized and stacks are capped")
	_check(Items.clean_claims({"cache:garden":true, "cache:inn":"yes", "unknown":true}) == {"cache:garden":true}, "malformed claims are sanitized")
	var quests := {"chronicle":{"quests":{"lamps":"wait_goods", "swordstory":"wait_palace", "courier":"done_quiet"}}}
	var claims := {}
	_check(Items.reconcile_quests(quests, stock, claims).size() == 3 and stock.stagger_needle == 2 and stock.breath_pill == 1,
		"quest milestones and resolved routes grant their intended supplies")
	_check(Items.reconcile_quests(quests, stock, claims).is_empty(), "repeated quest reconciliation grants no duplicates")
	_check(Items.reward(stock, "cache:garden") == ["破势针 ×1"], "a full stack does not block the other discovery reward")

func _test_game_flow() -> void:
	var game := Main.instantiate()
	root.add_child(game)
	if not _check(game.has_method("_new_game"), "main scene loads the game script"):
		return
	game._new_game(false)
	game._finish_intro()
	game.player = game.position_of("chest")
	game.interact()
	game.interact()
	var saved_chest: Dictionary = game.storage.read()
	_check(saved_chest.supplies.guard_powder == 1 and saved_chest.supply_claims.get("chest:hall", false),
		"opening an exploration chest gives one persisted supply reward")
	game.slot.supplies = STOCK.duplicate()
	game._commit()
	game.active_battle = 0
	game._start_battle()
	game.encounter.allies[1].qi = 0
	game.click("action", 4)
	_check(game.bag_open and game.pending_action == -1, "battle action opens the bag without spending a turn")
	game.click("supply", 1)
	_check(not game.bag_open and game.pending_action == QI and game.target == 1, "bag skips a full-qi target")
	game.cancel()
	_check(game.pending_action == -1 and game.encounter.supplies == STOCK, "canceling item targeting keeps stock")
	game.click("action", 4)
	game.click("supply", 1)
	game._confirm()
	_check(game.encounter.supplies.breath_pill == 1 and game.storage.read().supplies.breath_pill == 2,
		"using a supply does not spend it from the save before victory")
	game.encounter.allies[0].hp = 1
	game.encounter.allies[1].hp = 1
	game._battle_act(0, 0)
	_check(game.mode == "defeat", "both low-health allies fall to the opening encounter")
	game.menu_confirm(0)
	_check(game.mode == "battle" and game.encounter.supplies == STOCK, "retry restores pre-battle supplies")
	game.encounter.allies[0].qi = 0
	game._battle_act(QI, 0)
	game.encounter.foes[0].hp = 1
	game.encounter.foes[1].hp = 0
	game._battle_act(0, 0)
	_check(game.mode == "victory" and game.storage.read().supplies.breath_pill == 1, "victory commits exactly the supplies spent")
	var legacy := Save.new(PROFILE + "_legacy")
	var old := legacy.fresh(false)
	old.erase("supplies")
	old.erase("supply_claims")
	_check(legacy.write(old) and legacy.read().supplies == Items.fresh() and legacy.read().supply_claims.is_empty(), "old saves receive starting supplies")
	_test_afterstory(game)

func _test_afterstory(game: Node2D) -> void:
	game.slot.chapter = 5
	game.slot.cleared = [0, 1]
	game.slot.finished = true
	game.slot.afterstory = Afterstory.initial()
	game.slot.afterstory.erase("supplies")
	game.slot.afterstory.merge({"brief":true, "register":true, "seal":true, "route":"gate", "room":"tidal_fort"}, true)
	game.afterstory.resume()
	_check(game.slot.afterstory.supplies == Items.fresh(2), "old Tidegate checkpoint receives independent starting supplies")
	game.afterstory.battle = "gate"
	game._start_battle()
	game.encounter.allies[0].qi = 0
	game._battle_act(QI, 0)
	game.encounter.foes[0].hp = 1
	game.encounter.foes[1].hp = 0
	game._battle_act(0, 0)
	var saved: Dictionary = game.storage.read()
	_check(saved.afterstory.gate and saved.afterstory.supplies.breath_pill == 0 and saved.supplies.breath_pill == 1,
		"Tidegate victory spends only its own supply stock")

func _check(ok: bool, label: String) -> bool:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1
	return ok
