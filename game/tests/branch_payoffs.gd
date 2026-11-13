extends SceneTree

const Main = preload("res://main.tscn")
const SideStories = preload("res://scripts/side_stories.gd")
const Afterstory = preload("res://scripts/afterstory.gd")
const BODY_FONT = preload("res://assets/fonts/body.tres")
const PROFILE := "qa_branch_payoffs"

var game
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if "--profile=" + PROFILE not in OS.get_cmdline_user_args():
		push_error("Run with -- --profile=" + PROFILE)
		quit(1)
		return
	game = Main.instantiate()
	root.add_child(game)
	game.settings.motion = false
	_test_seals()
	_test_courier()
	_test_shift()
	_test_sword()
	_test_dawn()
	_test_tidegate_carryover()
	_test_journal_fit()
	for suffix in ["",".bak",".tmp"]:
		var file: String = game.storage.path + suffix
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(file)
	print("Quest branch payoffs: %d failures" % failures)
	quit(1 if failures else 0)

func _chapter(at: int, quests: Dictionary) -> void:
	game.afterstory.reset()
	game.slot = game.storage.replay(at,false)
	game.slot.chronicle.quests = quests.duplicate()
	game._enter_chapter(false)

func _test_seals() -> void:
	for step in ["","done_guide","done_proof"]:
		_chapter(1,{} if step.is_empty() else {"seals":step})
		game.slot.campaign.crossing = "bridge"
		game.slot.cleared = [0]
		game.chronicle.enter("inn")
		_visit("ferry_evidence")
		_check(("换哨" in game.lines[0][1]) == (step == "done_proof"), "Fengxi evidence responds to the testimony")
		_drain_dialogue()
		_visit("inn_exit")
		_visit("fight",1)
		_drain_dialogue()
		if not _check(game.mode == "battle", "Fengxi main fight opens with any quest outcome"):
			continue
		var poise: int = game.encounter.foes[0].poise
		_check(poise == 5 - int(step == "done_proof") and game.encounter.signal_state == "ready",
			"testimony opens one tactical gap while preserving the whistle attempt")
		if step == "done_proof":
			_retry()
			_check(game.encounter.foes[0].poise == poise and game.encounter.foes[0].max_poise == 5,
				"retry reapplies the same opening gap without changing maximum poise")

func _test_courier() -> void:
	for step in ["","done_quiet","done_fight"]:
		var quests := {} if step.is_empty() else {"courier":step}
		_chapter(3,quests)
		var journal: Dictionary = game.chronicle.side.journal_entry("courier")
		_check((journal.status == "待回访") == not step.is_empty(),
			"the journal offers a Palace follow-up only after helping the Fengxi courier")
		_chapter(4,quests)
		game.slot.cleared = [0]
		game.slot.campaign.rescued = true
		game.slot.chronicle.marks.tea = true
		game.chronicle.enter("tearoom")
		_check(game.chronicle.side.battle_aid("palace",1,"").is_empty(),
			"courier quest rewards remain earned, while combat aid requires the rendezvous")
		if not step.is_empty():
			journal = game.chronicle.side.journal_entry("courier")
			_check(journal.get("point") == SideStories.COURIER_CONTACT_POS and "破金身前" in journal.deadline
				and game.passable(journal.point), "the journal points to the reachable contact and gives the deadline")
			_visit("courier_contact")
			_check(("护脉散" if step == "done_quiet" else "收拳回阵") in game.lines[0][1],
				"the courier explains the specific tactical handoff")
			_drain_dialogue()
			game.slot = game.storage.read()
			game._enter_chapter(false)
			_check(game.chronicle.has("courier_contact") and not _has_point("courier_contact"),
				"reloading after the handoff removes the interaction and preserves the aid")
		_visit("palace_back")
		_visit("fight",1)
		_drain_dialogue()
		if not _check(game.mode == "battle", "Godless encounter opens with any courier outcome"):
			continue
		_check(game.encounter.allies[1].id == "sage" and game.encounter.allies[1].ward == (step == "done_quiet")
			and game.encounter.foes[0].poise == (4 if step == "done_fight" else 6),
			"quiet courier grants a ward to the heavy target, intercepting opens a poise gap")
		_retry()
		_check(game.encounter.allies[1].ward == (step == "done_quiet")
			and game.encounter.foes[0].poise == (4 if step == "done_fight" else 6), "retries reproduce exactly one courier aid")
		game.slot.chapter = 5
		game.stage = preload("res://scripts/story.gd").CHAPTERS[5]
		game.slot.cleared = [0,1]
		game.chronicle.enter("dawn")
		_visit("dawn_lamp")
		_check(game.lines.size() == (2 if step.is_empty() else 3)
			and (step.is_empty() or ("药师" if step == "done_quiet" else "州府") in game.lines[1][1]),
			"Fengxi lantern scene recalls the courier choice only when its later meeting took place")
		_drain_dialogue()
	_chapter(4,{"courier":"done_quiet"})
	game.slot.cleared = [0,1]
	game.chronicle.enter("tearoom")
	_check(not _has_point("courier_contact") and "时机已过" in game.chronicle.side.journal_entry("courier").payoff,
		"a courier handoff after the fight is hidden and the journal preserves the earned reward")

func _test_shift() -> void:
	for step in ["","done_stealth","done_fight"]:
		var quests := {} if step.is_empty() else {"shift":step}
		_chapter(4,quests)
		game.slot.cleared = [0,1]
		game.slot.campaign.rescued = true
		game.slot.chronicle.marks.tea = true
		game.chronicle.enter("tearoom")
		_visit("fire_signal")
		_drain_dialogue()
		_visit("evacuated")
		var evacuation: String = game.lines[1][1]
		_check(("护心镜" in evacuation) == (step == "done_stealth") and ("铜哨" in evacuation) == (step == "done_fight"),
			"Palace evacuation explains the chosen branch's later aid")
		_drain_dialogue()
		_chapter(5,quests)
		game._commit()
		game.slot = game.storage.read()
		game._enter_chapter(false)
		_visit("relic")
		_drain_dialogue()
		var ward: bool = game.encounter.allies[0].ward
		var poise: int = game.encounter.foes[0].poise
		_check(ward == (step == "done_stealth") and poise == (3 if step == "done_fight" else 5),
			"the chosen or skipped branch changes the actual cavern battle after reopening the save")
		var stock: Dictionary = game.slot.supplies.duplicate()
		_retry()
		_check(game.encounter.allies[0].ward == ward and game.encounter.foes[0].poise == poise and game.slot.supplies == stock,
			"cavern retry preserves branch aid and inventory")

func _test_sword() -> void:
	for step in ["","wait_sage","wait_guard"]:
		_chapter(5,{} if step.is_empty() else {"swordstory":step})
		game.slot.campaign.farewell = true
		game.slot.cleared = [0]
		game._enter_chapter(false)
		var expected := {"wait_sage":"done_sage","wait_guard":"done_guard"}
		if not step.is_empty():
			_check(game.chronicle.side.battle_aid("peak",1,"").is_empty(), "a promise requires a mountain handoff to grant combat aid")
			_check("决战前" in game.chronicle.side.journal_entry("swordstory").deadline, "journal explains the deadline for final-battle aid")
			_visit("side_swordstory")
			_drain_dialogue()
			_check(game.storage.read().chronicle.quests.get("swordstory") == expected[step], "mountain handoff persists before the duel")
		if step == "wait_guard":
			_visit("mountain_path")
			_check(game.player == game.position_of("altar"), "the guard route opens a traversable short path")
		_visit("altar")
		_check(("侧坡" in game.lines[0][1]) == (step == "wait_guard") and ("无名" in game.lines[1][1]) == (step == "wait_sage"),
			"the altar scene reflects who took the old sword")
		_drain_dialogue()
		_visit("fight",1)
		_drain_dialogue()
		_check(game.encounter.bond == int(step == "wait_sage") and game.encounter.foes[0].poise == (5 if step == "wait_guard" else 7),
			"the old-sword routes support two distinct final-battle openings")
	_chapter(5,{"swordstory":"wait_sage"})
	game.slot.campaign.farewell = true
	game.slot.campaign.altar = true
	game.slot.cleared = [0,1]
	game._enter_chapter(false)
	var entry: Dictionary = game.chronicle.side.journal_entry("swordstory")
	_check("决战已结束" in entry.payoff and entry.get("point") != null, "late handoff stays available and describes the resolved duel")
	_visit("side_swordstory")
	_check("雄霸已倒" in game.lines[0][1], "late handoff uses dialogue that acknowledges victory")
	_drain_dialogue()
	_check(game.chronicle.side.journal_entry("swordstory").status == "已完成", "late handoff can still settle the quest")

func _test_dawn() -> void:
	for pair in [["wait_boat","done_escort","旧船","小径"],["wait_goods","done_decoy","冬粮","添了油"]]:
		_chapter(5,{"lamps":pair[0],"stairs":pair[1]})
		game.slot.cleared = [0,1]
		game.slot.campaign.farewell = true
		game.slot.campaign.altar = true
		game.chronicle.enter("dawn")
		_visit("dawn_lamp")
		_check(pair[3] in game.lines[1][1], "mountain rescue changes the farewell before the player leaves Fengxi")
		_drain_dialogue()
		_check(pair[2] in game.chronicle.ending()[0][1], "Fengxi ending reflects the river choice without requiring the optional revisit")
		_visit("dawn_exit")
		_check(game.mode == "choice","unvisited river follow-up warns before ending")
		game.menu_confirm(1)
		_drain_dialogue()
		var saved: Dictionary = game.storage.read()
		_check(saved.finished and saved.chronicle.quests.lamps == pair[0] and pair[2] in game.chronicle.ending()[0][1],
			"finishing without the optional revisit still records the chosen ending")

func _test_journal_fit() -> void:
	var fits := true
	for note in SideStories.DECISIONS.values():
		fits = fits and _line_count(note,300,14) <= 2
	_check(fits,"quest choice notes fit in the choice panel")
	fits = true
	for chapter in 6:
		_chapter(chapter,{})
		for key in SideStories.TASKS:
			for step in [""] + SideStories.TASKS[key].steps.keys() + SideStories.RESULT.keys():
				if step != "" and not SideStories.valid_state(key,step):
					continue
				game.slot.chronicle.quests = {} if step == "" else {key:step}
				var entry: Dictionary = game.chronicle.side.journal_entry(key)
				var place: String = entry.place + ("  ·  " + entry.deadline if not entry.deadline.is_empty() else "")
				fits = fits and _line_count(entry.action,257,14) <= 2 and _line_count(entry.payoff,257,12) <= 2
				fits = fits and (entry.place.is_empty() or _line_count(place,257,11) <= 1)
	_check(fits,"branch result, follow-up and deadline text fit the journal")

func _test_tidegate_carryover() -> void:
	for step: String in ["","wait_boat","done_boat","wait_goods","done_goods"]:
		_chapter(5,{} if step.is_empty() else {"lamps":step})
		game.slot.finished = true
		game.slot.cleared = [0,1]
		var boat := step.ends_with("boat")
		var grain := step.ends_with("goods")
		game.afterstory.resume()
		var main_stock: Dictionary = game.slot.supplies.duplicate()
		_visit("brief")
		_check(("抬水栅" in game.lines[0][1]) == boat and ("护脉散" in game.lines[0][1]) == grain,
			"Tidegate introduces Fengxi support from either selected outcome and skips it on a neutral save")
		_drain_dialogue()
		var before: Dictionary = game.afterstory.state().duplicate(true)
		_check(before.brief and before.tonics == 3 + int(grain) and before.supplies.guard_powder == 1 + int(grain)
			and game.slot.supplies == main_stock, "the grain branch adds one tonic and powder to the Tidegate bag only")
		game.slot = game.storage.read()
		game.afterstory.resume()
		_visit("brief")
		_drain_dialogue()
		_check(game.afterstory.state().supplies == before.supplies and game.afterstory.state().tonics == before.tonics,
			"revisiting and reloading the briefing cannot duplicate the reward")
		for point in (["seal","register"] if step.begins_with("done_") else ["register","seal"]):
			_visit(point)
			_drain_dialogue()
			if not (game.afterstory.state().register and game.afterstory.state().seal):
				_check(not game.afterstory.state().sluice, "one piece of evidence cannot open the watergate")
		var flags: Dictionary = game.afterstory.state()
		_check(flags.sluice == boat and _has_point("gate_entry") and _has_point("sluice_entry") == boat,
			"crew opens the watergate after both pieces of evidence without removing the main gate route")
		if not boat:
			_visit("sluice")
			_check(flags.sluice and _has_point("sluice_entry"), "players without the crew can open the watergate normally")
		for resolution in ["public","witness"]:
			flags.merge({"route":"sluice","aid":true,"chief":true,"ledger":true,"resolution":""},true)
			_visit("report")
			game.menu_confirm(int(resolution == "witness"))
			_check(("凤溪的船" in game.lines[1][1]) == boat and ("凤溪乡亲" in game.lines[1][1]) == grain,
				"each Tidegate settlement uses the matching regional aid in the distribution plan")
			_drain_dialogue()
			_check(game.storage.read().afterstory.resolution == resolution, "the selected settlement persists with its original resolution ID")
	_chapter(5,{"lamps":"wait_boat"})
	game.slot.finished = true
	game.slot.cleared = [0,1]
	game.slot.afterstory = Afterstory.initial()
	game.slot.afterstory.merge({"brief":true,"register":true,"seal":true},true)
	game.afterstory.resume()
	_check(game.storage.read().afterstory.sluice and game.afterstory.state().route == "",
		"older boat saves get crew aid only when the evidence is complete and the route is undecided")

func _line_count(value: String, width: float, size: int) -> int:
	var line := ""
	var lines := 1
	for character in value:
		if BODY_FONT.get_string_size(line + character,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x > width:
			lines += 1
			line = ""
		line += character
	return lines

func _retry() -> void:
	game._set_mode("defeat")
	game.menu_confirm(0)

func _visit(id: String, index: int = -1) -> void:
	for spot in game.field_points():
		if spot.id == id and (index < 0 or spot.index == index):
			game.player = spot.pos
			var nearest: Dictionary = game.nearest()
			if nearest.get("id") == id and (index < 0 or nearest.get("index") == index):
				game.interact()
				return
			break
	_check(false, "interaction is available at " + id)

func _has_point(id: String) -> bool:
	return game.field_points().any(func(spot): return spot.id == id)

func _drain_dialogue() -> void:
	for i in 12:
		if game.mode != "dialogue":
			return
		game._confirm()

func _check(condition: bool, description: String) -> bool:
	print(("PASS " if condition else "FAIL ") + description)
	if not condition:
		failures += 1
	return condition
