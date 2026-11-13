extends SceneTree

const Afterstory = preload("res://scripts/afterstory.gd")
const Economy = preload("res://scripts/economy.gd")
const Equipment = preload("res://scripts/equipment.gd")
const Save = preload("res://scripts/save.gd")

var failures := 0

func _initialize() -> void:
	var storage := Save.new("qa_forge_migration_%d" % OS.get_process_id())
	var old := _completed_slot(storage)
	_check(storage.write(old), "pre-economy completed Tidegate file is accepted")
	var migrated := storage.read()
	var account: Dictionary = migrated.afterstory
	_check(account.silver == 28 and account.materials == {"tidal_iron":4},
		"legacy gate, rescue, chief and register reconstruct enough local resources to use the forge")
	_check(account.loot_claims == {"tidal:gate":true,"tidal:aid":true,"tidal:chief":true},
		"only documented completed battles are credited")
	_check(not Economy.buy(migrated, account, "tidegate", 4).is_empty() and not Economy.reinforce(migrated, account, "tidegate", 0).is_empty()
		and not Economy.reinforce(migrated, account, "tidegate", 0).is_empty(), "migrated player can buy and reinforce the armor to +2")
	_check(storage.write(migrated), "the upgraded migrated file saves")
	var restored := storage.read()
	_check(Equipment.level(restored, "granary_vest") == 2 and restored.afterstory.silver == 10 and restored.afterstory.materials == {"tidal_iron":1},
		"reinforcement and actual costs survive reload without replenishing spent resources")
	_check(restored.silver == old.silver and restored.materials.is_empty(), "legacy recovery and Tidegate purchases leave the main wallet alone")
	var economy_old := _completed_slot(storage)
	economy_old.afterstory.silver = 1
	economy_old.afterstory.loot_claims = {"tidal:gate":true,"tidal:aid":true,"tidal:chief":true}
	_check(storage.write(economy_old), "pre-forge economy file is accepted")
	var economy_migrated: Dictionary = storage.read().afterstory
	_check(economy_migrated.silver == 1 and economy_migrated.materials == {"tidal_iron":4},
		"2.7 paid-out silver remains spent while newly introduced materials are recovered")
	for suffix in ["", ".bak", ".tmp"]:
		var file: String = storage.path + suffix
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(file)
	print("Forge migration: %d failures" % failures)
	quit(1 if failures else 0)

func _completed_slot(storage: RefCounted) -> Dictionary:
	var slot: Dictionary = storage.fresh(false)
	slot.chapter = 5
	slot.merit = 24
	slot.cleared = [0, 1]
	slot.finished = true
	slot.afterstory = Afterstory.initial()
	slot.afterstory.merge({"route":"gate","brief":true,"register":true,"seal":true,"gate":true,"aid":true,"chief":true,
		"ledger":true,"resolution":"public"}, true)
	return slot

func _check(passed: bool, description: String) -> void:
	print(("PASS " if passed else "FAIL ") + description)
	if not passed:
		failures += 1
