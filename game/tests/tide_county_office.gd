extends "res://tests/jianghu_regions.gd"

const OFFICE_PROFILE := "qa_tide_county_office"
const Economy = preload("res://scripts/economy.gd")
const RELIEF_EVIDENCE := ["tide_relief_roll","tide_relief_dispatch","tide_relief_arrival","tide_relief_west","tide_relief_east"]

func _run() -> void:
	if "--profile=" + OFFICE_PROFILE not in OS.get_cmdline_user_args():
		push_error("Run with -- --profile=" + OFFICE_PROFILE)
		quit(1)
		return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--reports="):
			report_dir = arg.substr(10)
	game = Main.instantiate()
	root.add_child(game)
	await _test_county("public")
	await _test_county("witness")
	for suffix in ["", ".tmp", ".bak"]:
		var path: String = game.storage.path + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	print("County office: %d checks, %d failures; walked %.0f pixels" % [checks,failures,distance])
	quit(1 if failures else 0)

func _test_county(outcome: String) -> void:
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/stage4-v320-%s.json" % outcome))
	if not _check(game.storage.write(fixture), outcome + ": old completed save loads before the new quest"):
		return
	_open_tide()
	_check(game.world.destinations().size() == 7, "county office stays within the existing seven regions")
	if not _to_fort():
		return
	_check(not _has("world_tide_to_county"), "the existing relief receipt is required for the county road")
	var invalid: Dictionary = game.storage.read()
	invalid.world.area = "tide_county_office"
	_check(not game.storage.write(invalid), "an old save cannot open the county office prematurely")

	var facts: Dictionary = fixture.world.tasks
	for evidence in RELIEF_EVIDENCE:
		facts[evidence] = true
	facts.tide_relief = outcome
	facts.tide_relief_receipt = true
	fixture.afterstory.silver = 20
	if not _check(game.storage.write(fixture), "an authentic receipt-state fixture loads"):
		return
	_open_tide()
	if not _to_fort() or not _visit("world_tide_to_county"):
		return
	var office_entry: Vector2 = game.player
	_check(game.field_key == "tide_county_office" and game.passable(office_entry), "county road has a walkable office arrival")
	_check(not _has("world_tide_county_order") and not _has("world_tide_county_shortcut"), "desk and shortcut await the two facts")
	_resume_county()
	_check(game.field_key == "tide_county_office" and game.player.distance_to(office_entry) < 1.0,
		"reload restores county office and arrival")
	await _capture("county-" + outcome)

	var evidence_ids := ["world_tide_county_intake","world_tide_county_dispatch"]
	if outcome == "witness":
		evidence_ids.reverse()
	for id in evidence_ids:
		if not _visit(id):
			return
	_check(_county_task().steps == 2 and not _county_task().complete, "journal reflects both procedural details")
	var account: Dictionary = game.shop_account().duplicate(true)
	var total_silver: int = game.slot.silver
	if not _visit("world_tide_county_order"):
		return
	var saved: Dictionary = game.storage.read()
	_check(saved.world.tasks.get("tide_county_order","") == outcome, "original settlement determines the saved county order")
	_check(game.shop_account() == account and game.slot.silver == total_silver, "county order pays no items or currency")
	_check(_county_task().awaiting_receipt and not _has("world_tide_county_order"), "the order directs follow-through and cannot be reissued")
	invalid = saved.duplicate(true)
	invalid.world.tasks.tide_county_order = "witness" if outcome == "public" else "public"
	_check(not game.storage.write(invalid), "save validation rejects an order for the opposite settlement")
	await _capture("county-ordered-" + outcome)

	var shop := "tide_relief_public" if outcome == "public" else "tide_convoy"
	if not _visit("world_tide_county_supply"):
		return
	_check(game.mode == "shop" and game.shop_id == shop, "county opens the corresponding supply desk")
	var offer := Economy.offer(game.slot,game.shop_account(),shop,1)
	game._buy_good(1)
	var next_offer := Economy.offer(game.slot,game.shop_account(),shop,1)
	_check(next_offer.remaining == offer.remaining - 1 and game.slot.silver == total_silver,
		"county shelf uses actual Tidegate stock and silver")
	_key(KEY_ESCAPE)

	var destination := "tide_ford" if outcome == "public" else "tide_canal"
	if not _visit("world_tide_county_shortcut"):
		return
	_check(game.slot.world.area == destination, "new route follows the original settlement: " + destination)
	if not _visit("world_tide_county_followthrough"):
		return
	_check(game.storage.read().world.tasks.get("tide_county_followthrough",false) and not _county_task().awaiting_receipt,
		"seeing the dispatch in operation completes the procedural follow-up")
	if not _visit("world_tide_county_shortcut") or not _visit("world_tide_county_to_fort"):
		return
	_check(game.slot.world.area == "tide_fort", "both directions of the shortcut and the original warehouse return work")
	if not _visit("world_tide_fort_to_canal") or not _visit("world_tide_canal_to_ford") or not _visit("world_tide_shop"):
		return
	_check(game.mode == "shop" and game.shop_id == shop
		and Economy.offer(game.slot,game.shop_account(),shop,1).remaining == next_offer.remaining,
		"the original dock desk shares the same stock without refilling purchased items")
	_key(KEY_ESCAPE)
	_check(game.world.leave() and game.mode == "title", "settled visit can return to the title")

func _county_task() -> Dictionary:
	return game.world.journal().filter(func(task: Dictionary): return task.id == "tide_county_order").front()

func _open_tide() -> void:
	game._title()
	game.world.from_main("tide")

func _resume_county() -> void:
	game._title()
	game.menu_confirm(0)

func _to_fort() -> bool:
	return _visit("world_tide_to_canal") and _visit("world_tide_canal_to_fort")
