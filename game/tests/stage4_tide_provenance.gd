extends SceneTree

const Main = preload("res://main.tscn")
const Afterstory = preload("res://scripts/afterstory.gd")
const PROFILE := "qa_stage4_tide_provenance"
const CASES := [
	["canal","world_tide_review_source_free","tide_canal"],
	["alu","world_tide_review_source_alu","tide_fort"],
	["manifest","world_tide_review_source_manifest","tide_fort"],
	["worker","world_tide_review_source_worker","tide_ford"],
	["testimony","world_tide_review_source_fengxi","tide_ford"],
	["jiang","world_tide_review_source_jiang","tide_ford"],
	["watch","world_tide_review_source_watch","tide_ford"],
]

var game
var checks := 0
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := Array(OS.get_cmdline_user_args())
	if args.filter(func(arg): return arg.begins_with("--profile=")) != ["--profile=" + PROFILE]:
		printerr("Run with -- --profile="+PROFILE)
		quit(2)
		return
	game = Main.instantiate()
	root.add_child(game)
	for definition in CASES:
		assert_proof(definition[0],definition[1],definition[2])
	assert_grain_and_boat()
	for suffix in ["", ".tmp", ".bak"]:
		var file: String = game.storage.path + suffix
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(file)
	print("Stage4 Tidegate provenance and early aid: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

func assert_proof(proof: String, id: String, area: String) -> void:
	prepare()
	var altered: Dictionary = game.slot.duplicate(true)
	if proof != "canal":
		altered.world.tide_source = proof
		altered.world.tasks.tide_review_source = true
		check(not game.storage.write(altered),"reject forged " + proof + " before earning evidence")
	match proof:
		"alu": game.slot.afterstory.aid = true
		"manifest": game.slot.afterstory.canal_manifest = true
		"worker":
			game.slot.afterstory.route = "gate"
			game.slot.afterstory.gate = true
			game.slot.afterstory.canal_witness = true
		"testimony":
			game.slot.world.tasks.merge({"stencil":true,"witness":true,"testimony":"signed","testimony_handoff":true})
		"jiang":
			game.slot.world.tasks.merge({"palace_servant_plan":true,"palace_ying_plan":true,
				"palace_survival":"witness","palace_survival_receipt":true})
		"watch":
			game.slot.world.tasks.merge({"watch_witness":true,"watch_transfer_log":true,
				"watch_register":"public","register_handoff":true})
	if not check(game.storage.write(game.slot),"write representative 3.2-compatible " + proof + " starting save"):
		return
	game._title()
	game._enter_chapter(false)
	game.world.from_main("tide")
	if not check(game.world.active() and game.world.phase() == "public","settled legacy save can revisit Tidegate"):
		return
	if area != "tide_ford":
		if not visit("world_tide_to_canal"):
			return
		if area == "tide_fort" and not visit("world_tide_canal_to_fort"):
			return
	if not visit(id):
		return
	var before: Dictionary = game.storage.read()
	check(before.world.tide_source == proof and before.world.tasks.tide_review_source,
		"normal interaction persists provenance " + proof)
	game._title()
	game._enter_chapter(false)
	check(game.world.active() and game.slot.world.area == area and game.slot.world.tide_source == proof,
		"reload restores the region and its selected witness: " + proof)
	check(not point(id).has("evidence"),"used source cannot be taken again")
	if area == "tide_fort" and not visit("world_tide_fort_to_canal"):
		return
	if area != "tide_ford" and not visit("world_tide_canal_to_ford"):
		return
	check(CASES.all(func(other): return point(other[1]).is_empty()),"other available source NPCs cannot overwrite chosen evidence")
	if not path(["world_tide_to_canal","world_tide_review_mark","world_tide_canal_to_fort",
		"world_tide_review_count","world_tide_review_seal","world_tide_fort_to_canal","world_tide_canal_to_ford"]):
		return
	var purse: Dictionary = game.storage.read()
	if not visit("world_tide_review"):
		return
	var awarded: Dictionary = game.storage.read()
	check(awarded.world.tasks.tide_review == "done" and awarded.afterstory.silver == purse.afterstory.silver + 4,
		"any valid proof completes review and rewards exactly four local silver: " + proof)
	check(awarded.silver == purse.silver and awarded.materials == purse.materials,
		"review does not add to the main-story account")
	if path(["world_tide_review_shortcut","world_tide_review_receipt","world_tide_review_shortcut"]):
		check(game.storage.read().world.tasks.tide_review_receipt and game.slot.world.area == "tide_ford",
			"review opens the two-way ferry and leaves a permanent stamp")

func assert_grain_and_boat() -> void:
	prepare()
	game.slot.chronicle.quests.lamps = "done_goods"
	game._enter_chapter(false)
	game.world.from_main("tide")
	if path(["world_tide_relief_roll","world_tide_relief_dispatch"]):
		check(game.slot.world.area == "tide_ford" and game.storage.read().world.tasks.tide_relief_dispatch,
			"saved Fengxi grain changes public dispatch to Ford and saves a warehouse leg")
	prepare()
	game.slot.chronicle.quests.lamps = "done_boat"
	game._enter_chapter(false)
	game.world.from_main("tide")
	if visit("world_tide_boat_to_canal"):
		check(game.slot.world.area == "tide_canal" and game.player == Vector2(1190,224),
			"saved Fengxi boat carries the party to the east unloading platform")
		if visit("world_tide_boat_to_ford"):
			check(game.slot.world.area == "tide_ford" and game.player == Vector2(553,221),"the same boat runs both ways")

func prepare() -> void:
	game.afterstory.reset()
	game.slot = game.storage.replay(5,true)
	game.slot.finished = true
	game.slot.cleared = [0,1]
	game.slot.campaign.farewell = true
	game.slot.campaign.altar = true
	game.slot.chronicle.room = "dawn"
	game.slot.world.erase("tide_source")
	game.slot.afterstory = Afterstory.initial()
	game.slot.afterstory.merge({"route":"sluice","brief":true,"register":true,"seal":true,"sluice":true,
		"chief":true,"ledger":true,"resolution":"public"},true)
	game._commit()

func path(ids: Array) -> bool:
	for id in ids:
		if not visit(id):
			return false
	return true

func point(id: String) -> Dictionary:
	for spot in game.field_points():
		if spot.id == id:
			return spot
	return {}

func visit(id: String) -> bool:
	var spot := point(id)
	if not check(not spot.is_empty() and game.passable(spot.pos),"actual point on walkable ground: " + id):
		return false
	game.player = spot.pos
	game.interact()
	for i in 30:
		if game.mode != "dialogue":
			break
		game._confirm()
	return check(game.mode == "field","interaction returns to field: " + id)

func check(condition: bool, label: String) -> bool:
	checks += 1
	if not condition:
		failures += 1
	print(("PASS " if condition else "FAIL ") + label)
	return condition
