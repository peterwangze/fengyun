extends SceneTree

const Main = preload("res://main.tscn")
const Trail = preload("res://scripts/trail_guide.gd")
var game
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if "--profile=qa_route" not in OS.get_cmdline_user_args():
		push_error("Run with -- --profile=qa_route")
		quit(1)
		return
	game = Main.instantiate()
	if not game.has_method("_new_game"):
		push_error("Game scene failed to load")
		quit(1)
		return
	root.add_child(game)
	game._new_game(false)
	_drain_dialogue()
	_test_guides()
	_test_garden_cache()
	_test_inn()
	for suffix in ["", ".bak", ".tmp"]:
		var file: String = game.storage.path + suffix
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(file)
	print("Route and exploration: %d failures" % failures)
	quit(1 if failures else 0)

func _test_guides() -> void:
	_check(Trail.main_point(game,game.field_points()).get("id") == "spar", "main marker guides first-time players to Qin Shuang")
	game._open_journal()
	game._navigate(0,1)
	game._confirm()
	_check(game.tracked_quest == "seals" and game.chronicle.side.journal_entry(game.tracked_quest).get("point") == Vector2(142,222), "journal tracking identifies the selected nearby side quest")
	game._open_journal()
	game._navigate(0,-1)
	game._confirm()
	_check(game.tracked_quest.is_empty(), "tracking main clears the previous side marker")
	_visit("spar")
	for i in 6:
		if game.mode != "battle":
			break
		game._battle_act(1,0)
	if game.mode == "victory":
		game.menu_confirm(0)
	var target: Dictionary = Trail.main_point(game,game.field_points())
	_check(game.chronicle.has("spar") and target.get("id") == "fight" and target.get("index") == 0, "winning the practice duel moves the main marker to the gate guard")

func _test_garden_cache() -> void:
	game.slot.cleared = [0]
	game.slot.hall.wedding = true
	game.slot.hall.room = "banquet"
	game._enter_chapter(false)
	_visit("garden_door")
	_check(game.field_key == "garden", "back gate leads to the bamboo path")
	_assert_cache("garden", "stagger_needle", 1)

func _test_inn() -> void:
	game.slot = game.storage.replay(1,false)
	game._enter_chapter(false)
	_check(_point("inn").is_empty() and _point("seal_chase").is_empty(), "the inn and its optional encounter wait until crossing the river")
	game.slot.campaign.crossing = "boat"
	game._load_field("village","west_spawn")
	_visit("inn")
	_check(game.field_key == "inn" and _point("seal_chase").is_empty(), "seal chase waits for investigation at the inn")
	_assert_cache("inn", "breath_pill", 1)
	_visit("ferry_evidence")
	_check(game.chronicle.has("ferry_evidence"), "investigating the ferry orders unlocks the optional encounter")
	var before: Dictionary = game.storage.read()
	_visit("seal_chase")
	_check(game.mode == "battle" and game.encounter.seal_chase and game.battle_info()[0] == "客栈截印", "interacting at the inn window starts the real seal chase")
	if game.mode != "battle":
		return
	game._battle_act(3,0)
	game._battle_act(3,0)
	_check(game.encounter.round_no == 2 and game.encounter.intent(game.encounter.foes[0]).begins_with("携印逃走"), "second round warns that the spy will flee")
	game._battle_act(3,0)
	game._battle_act(3,0)
	_check(game.mode == "defeat" and game.encounter.escaped and not game.storage.read().supply_claims.has("hunt:inn"), "a free second-round action lets the spy escape without rewards")
	if game.mode != "defeat":
		return
	game.menu_confirm(0)
	_check(game.mode == "battle" and game.encounter.round_no == 1 and not game.encounter.escaped, "retry restores the original encounter")
	game._battle_act(3,0)
	game._battle_act(0,0)
	game._battle_act(1,0)
	game._battle_act(0,1)
	_check(game.encounter.round_no == 3 and not game.encounter.escaped and game.mode == "battle", "chipping away at the stance then using a weakness hit delays escape")
	for i in 6:
		if game.mode != "battle":
			break
		game._battle_act(1,game.encounter.living_foe())
	_check(game.mode == "victory", "focus the spy, then defeat the remaining swordsman")
	if game.mode != "victory":
		return
	var after: Dictionary = game.storage.read()
	_check(after.supply_claims.has("hunt:inn") and after.supplies.stagger_needle == before.supplies.stagger_needle + 2, "victory grants the one-time needle reward")
	_check(after.chapter == before.chapter and after.merit == before.merit and after.cleared == before.cleared and after.campaign == before.campaign and after.chronicle.marks == before.chronicle.marks, "optional win leaves main progression unchanged")
	game.menu_confirm(0)
	_reload()
	_check(_point("seal_chase").is_empty() and game.slot.supplies.stagger_needle == after.supplies.stagger_needle, "the won encounter cannot be repeated after reload")

func _assert_cache(room: String, item: String, amount: int) -> void:
	var cache := _point("cache")
	_check(not cache.is_empty() and game.passable(cache.pos), "cache is on walkable ground in " + room)
	if cache.is_empty():
		return
	var before: int = game.slot.supplies[item]
	_visit("cache")
	_check(game.slot.supply_claims.has("cache:" + room) and game.slot.supplies[item] == before + amount, "interacting claims supplies in " + room)
	_reload()
	_check(_point("cache").is_empty() and game.slot.supplies[item] == before + amount, "cache is one-time and persists in " + room)

func _reload() -> void:
	game._title()
	game.menu_confirm(0)
	_drain_dialogue()

func _point(id: String) -> Dictionary:
	for spot in game.field_points():
		if spot.id == id:
			return spot
	return {}

func _visit(id: String) -> void:
	var spot := _point(id)
	if spot.is_empty():
		_check(false, "interaction is available at " + id)
		return
	game.player = spot.pos
	if game.nearest().get("id") != id:
		_check(false, "interaction is selected at " + id)
		return
	game.interact()
	_drain_dialogue()

func _drain_dialogue() -> void:
	for i in 20:
		if game.mode != "dialogue":
			return
		game._confirm()

func _check(condition: bool, description: String) -> void:
	print(("PASS " if condition else "FAIL ") + description)
	if not condition:
		failures += 1
