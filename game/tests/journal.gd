extends SceneTree

const Main = preload("res://main.tscn")
var game
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if "--profile=qa_journal" not in OS.get_cmdline_user_args():
		push_error("Run with -- --profile=qa_journal")
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
	_test_seals()
	_test_deadlines()
	_test_apothecary()
	for suffix in ["", ".bak", ".tmp"]:
		var file: String = game.storage.path + suffix
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(file)
	print("Quest journal: %d failures" % failures)
	quit(1 if failures else 0)

func _test_seals() -> void:
	var side: RefCounted = game.chronicle.side
	var entry: Dictionary = side.journal_entry("seals")
	_check(entry.status == "可接取" and entry.place == "飞云堂庭院" and entry.get("point") == Vector2(142,222), "chapter-one quest identifies its nearby start")
	_check(entry.reward == "护证短披、护脉散 ×1", "journal lists the equipment and medicine reward")
	_check(side.journal_entry("courier").status == "后续章节", "future quest is shown as unavailable")
	_visit("side_seals", entry.get("point", Vector2.ZERO))
	entry = side.journal_entry("seals")
	_check(entry.status == "进行中" and entry.place == "天下会喜堂" and not entry.has("point"), "quest hands off from the courtyard to the wedding hall")
	game.slot.cleared = [0]
	_visit("banquet_door", game.position_of("banquet_door"))
	for expected in ["查看柜下旧单", "安置证人"]:
		_visit("side_seals", side.journal_entry("seals").get("point", Vector2.ZERO))
		_check(side.journal_entry("seals").action == expected, "journal updates to " + expected)
	_visit("side_seals", side.journal_entry("seals").get("point", Vector2.ZERO))
	_check(game.mode == "choice" and "竹径守卫" in game.chronicle.choice_note and "秦霜" in game.chronicle.choice_note, "choice explains two different main-story consequences")
	game.menu_confirm(1)
	var saved: Dictionary = game.storage.read()
	entry = side.journal_entry("seals")
	_check(entry.status == "已完成" and not entry.has("point") and saved.chronicle.quests.get("seals") == "done_proof", "quest completion and the branch persist")
	_check(saved.get("supplies", {}).get("guard_powder") == 1 and side.expiring().is_empty(), "completed quest grants a reward and clears the departure warning")

func _test_deadlines() -> void:
	var side: RefCounted = game.chronicle.side
	game.slot = game.storage.replay(1, false)
	game._enter_chapter(false)
	_check(not side.journal_entry("courier").has("point") and not _has_point("side_courier"), "west-bank quest marker waits until crossing")
	game.slot.campaign.crossing = "boat"
	_check(side.journal_entry("courier").get("point") == Vector2(76,233) and _has_point("side_courier"), "west-bank quest marker appears after crossing")
	game.slot.chronicle.quests.lamps = "shore"
	_check("一盏灯，两条船" in side.expiring(), "leaving Fengxi warns about unfinished river rescue")
	game.slot.chronicle.quests.lamps = "wait_boat"
	_check(side.journal_entry("lamps").status == "待回访" and side.expiring().is_empty(), "planned reunion remains available in the finale")
	game.slot.chapter = 2
	game.slot.chronicle.quests.swordstory = "ledger"
	_check("一柄未开锋的剑" in side.expiring(), "leaving the forge warns about the unexamined ledger")
	game.slot.chronicle.quests.swordstory = "wait_palace"
	game.slot.chapter = 4
	game.field_key = "tearoom"
	_check(side.journal_entry("swordstory").get("point") == Vector2(164,248) and "一柄未开锋的剑" in side.expiring(), "Palace handoff can be located and missed")
	game.slot.chapter = 5
	game.field_key = "peak"
	_check(side.journal_entry("swordstory").status == "已错过", "missed Palace handoff cannot appear actionable at the peak")
	game.slot.chronicle.quests.swordstory = "wait_guard"
	game.slot.chronicle.quests.stairs = "escort"
	_check("一柄未开锋的剑" in side.expiring("lamps") and "一盏灯，两条船" not in side.expiring("lamps"), "mountain departure warns while preserving Fengxi follow-up")
	game.field_key = "dawn"
	_check(side.journal_entry("stairs").status == "已错过" and side.journal_entry("lamps").get("point") == Vector2(208,254), "dawn expires the mountain and activates the river follow-up")
	_check(side.expiring() == ["一盏灯，两条船"], "the final departure lists only the available river follow-up")

func _test_apothecary() -> void:
	game.slot = game.storage.replay(3, false)
	game._enter_chapter(false)
	_visit("apothecary",Vector2(112,185))
	_visit("pool_intro",Vector2(320,163))
	_visit("pool_back",Vector2(320,289))
	_visit("apothecary",Vector2(112,185))
	_check(game.field_key == "apothecary" and game.chronicle.side.journal_entry("remedy").has("point"), "optional remedy remains reachable after the main-story briefing")

func _has_point(id: String) -> bool:
	return game.chronicle.side.points().any(func(spot): return spot.id == id)

func _visit(id: String, point: Vector2) -> void:
	game.player = point
	if game.nearest().get("id") != id:
		_check(false, "interaction is available at " + id)
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
