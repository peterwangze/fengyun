extends RefCounted

const Chronicle = preload("res://scripts/chronicle.gd")
const SideStories = preload("res://scripts/side_stories.gd")
const Martial = preload("res://scripts/martial.gd")
const Equipment = preload("res://scripts/equipment.gd")
const Items = preload("res://scripts/items.gd")
const Afterstory = preload("res://scripts/afterstory.gd")
const FILE := "user://jianghu.json"
const SETTINGS := "user://settings.json"
const VERSION := 1
var path := FILE
var settings_path := SETTINGS

func _init(suffix: String = "") -> void:
	if not suffix.is_empty():
		path = "user://jianghu-%s.json" % suffix
		settings_path = "user://settings-%s.json" % suffix

func fresh(easy: bool) -> Dictionary:
	var slot := {"version":VERSION, "chapter":0, "tonics":3, "merit":0,
		"cleared":[], "chest":false, "finished":false, "intro_seen":false, "easy":easy,
		"hall":_initial_hall(), "gear":{}}
	slot["campaign"] = _initial_campaign(slot)
	slot["chronicle"] = _initial_chronicle(0)
	slot["supplies"] = Items.fresh()
	slot["supply_claims"] = {}
	return slot

func _initial_chronicle(from_chapter: int) -> Dictionary:
	return {"from_chapter":from_chapter,"room":"","marks":{},"quests":{},"loadout":{}}

func replay(chapter: int, easy: bool) -> Dictionary:
	var slot := fresh(easy)
	slot.chapter = chapter
	slot.merit = chapter * 4
	slot.tonics = 6
	slot.supplies = Items.fresh(chapter)
	slot.campaign = _initial_campaign(slot)
	return slot

func _initial_hall() -> Dictionary:
	return {"room":"hall","wedding":false,"staff":[],"alarm":false}

func _initial_campaign(slot: Dictionary) -> Dictionary:
	var chapter := int(slot.chapter)
	var cleared: Array = slot.cleared
	return {"rope":false,
		"crossing":"bridge" if chapter > 1 or (chapter == 1 and cleared.has(0)) else "",
		"reunion":chapter > 1, "forge_gate":chapter > 2 or (chapter == 2 and cleared.has(0)),
		"forge_route":"gate" if chapter > 2 or (chapter == 2 and cleared.has(1)) else "",
		"sword":chapter > 2, "pool_trial":chapter > 3 or (chapter == 3 and cleared.has(0)),
		"palace_room":"palace", "rescued":chapter > 4, "farewell":slot.finished,
		"altar":slot.finished}

func read() -> Dictionary:
	for candidate in [path, path + ".bak"]:
		var slot := _read_dictionary(candidate)
		if _valid(slot):
			slot.cleared = slot.cleared.map(func(flag): return int(flag))
			for key in ["chapter", "tonics", "merit", "version"]:
				slot[key] = int(slot[key])
			slot.intro_seen = slot.get("intro_seen", true)
			slot.hall = slot.get("hall", _initial_hall())
			slot.campaign = slot.get("campaign", _initial_campaign(slot))
			slot.chronicle = slot.get("chronicle",_initial_chronicle(slot.chapter + 1))
			slot.gear = Equipment.clean_loadouts(slot, slot.get("gear", {}))
			slot.supplies = Items.clean(slot.get("supplies", Items.fresh(int(slot.chapter))))
			slot.supply_claims = Items.clean_claims(slot.get("supply_claims", {}))
			return slot
	return {}

func write(slot: Dictionary) -> bool:
	return _valid(slot) and _replace(path, slot)

func get_settings() -> Dictionary:
	var data := _read_dictionary(settings_path)
	return {"mute": data.get("mute", false) == true, "motion": data.get("motion", true) == true,
		"full": data.get("full", false) == true}

func set_settings(data: Dictionary) -> void:
	_replace(settings_path, data)

func _read_dictionary(file: String) -> Dictionary:
	if not FileAccess.file_exists(file):
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(file))
	return data if data is Dictionary else {}

func _in_range(value: Variant, low: int, high: int) -> bool:
	return (value is float or value is int) and value >= low and value <= high and float(value) == floorf(value)

func _valid(slot: Dictionary) -> bool:
	if slot.get("version") != VERSION or not _in_range(slot.get("chapter"), 0, 5):
		return false
	if not _in_range(slot.get("tonics"), 0, 9) or not _in_range(slot.get("merit"), 0, 42):
		return false
	var flags: Variant = slot.get("cleared")
	if not flags is Array or flags.size() > 3:
		return false
	var seen := []
	for flag in flags:
		if not _in_range(flag, 0, 2) or seen.has(int(flag)):
			return false
		seen.append(int(flag))
	if seen.has(1) and not seen.has(0):
		return false
	if not slot.get("finished") is bool or not slot.get("easy") is bool or not slot.get("chest") is bool:
		return false
	if slot.has("hall") and not _valid_hall(slot.hall, slot.chapter == 0, seen.has(0)):
		return false
	if slot.has("campaign") and not _valid_campaign(slot.campaign, int(slot.chapter), seen):
		return false
	if slot.has("chronicle") and not _valid_chronicle(slot.chronicle,int(slot.chapter)):
		return false
	if slot.has("afterstory") and (not slot.finished or not Afterstory.valid(slot.afterstory)):
		return false
	return not slot.finished or (slot.chapter == 5 and seen.has(0) and seen.has(1))

func _valid_chronicle(value: Variant, chapter: int) -> bool:
	if not value is Dictionary or not _in_range(value.get("from_chapter"),0,6):
		return false
	var room: Variant = value.get("room")
	if not room is String or (room != "" and Chronicle.ROOMS.get(room,-1) != chapter):
		return false
	for section in ["marks","quests","loadout"]:
		if not value.get(section) is Dictionary:
			return false
	for flag in value.marks:
		if not Chronicle.FLAGS.has(flag) or value.marks[flag] != true:
			return false
	var public_roll: bool = value.marks.has("reunion_roll")
	var neighbor_aid: bool = value.marks.has("reunion_aid")
	if (public_roll or neighbor_aid) and (chapter != 5 or not value.marks.has("dawn_lamp") or (public_roll and neighbor_aid)):
		return false
	for quest in value.quests:
		if not SideStories.valid_state(quest,value.quests[quest]):
			return false
	for hero in value.loadout:
		var moves: Variant = value.loadout[hero]
		if not Martial.EXTRA.has(hero) or not moves is Array or moves.size() != 2:
			return false
		if not _in_range(moves[0],0,3) or not _in_range(moves[1],0,3) or moves[0] == moves[1]:
			return false
	return true

func _valid_hall(value: Variant, first_chapter: bool, gate_cleared: bool) -> bool:
	if not value is Dictionary or value.get("room") not in ["hall","banquet","garden"]:
		return false
	if not value.get("wedding") is bool or not value.get("alarm") is bool:
		return false
	var staff: Variant = value.get("staff")
	if not staff is Array or staff.size() > 2:
		return false
	var unique := []
	for person in staff:
		if person not in ["maid","servant"] or unique.has(person):
			return false
		unique.append(person)
	if not value.wedding and (value.room == "garden" or value.alarm or not staff.is_empty()):
		return false
	return not first_chapter or gate_cleared or (value.room == "hall" and not value.wedding)

func _valid_campaign(value: Variant, chapter: int, cleared: Array) -> bool:
	if not value is Dictionary:
		return false
	for key in ["rope","reunion","forge_gate","sword","pool_trial","rescued","farewell","altar"]:
		if not value.get(key) is bool:
			return false
	if value.get("crossing") not in ["","bridge","boat"] or value.get("forge_route") not in ["","gate","ledge"]:
		return false
	if value.get("palace_room") not in ["palace","jail"]:
		return false
	if value.palace_room == "jail" and (chapter != 4 or not cleared.has(0)):
		return false
	return not value.reunion or not value.crossing.is_empty()

func _replace(file: String, data: Dictionary) -> bool:
	var temp := file + ".tmp"
	var backup := file + ".bak"
	var handle := FileAccess.open(temp, FileAccess.WRITE)
	if handle == null:
		return false
	handle.store_string(JSON.stringify(data))
	handle.flush()
	var written := handle.get_error() == OK
	handle.close()
	if not written:
		return false
	if FileAccess.file_exists(file):
		if file == path and not _valid(_read_dictionary(file)):
			if DirAccess.remove_absolute(file) != OK:
				return false
		else:
			if FileAccess.file_exists(backup) and DirAccess.remove_absolute(backup) != OK:
				return false
			if DirAccess.rename_absolute(file, backup) != OK:
				return false
	if DirAccess.rename_absolute(temp, file) != OK:
		if FileAccess.file_exists(backup):
			DirAccess.rename_absolute(backup, file)
		return false
	return true

