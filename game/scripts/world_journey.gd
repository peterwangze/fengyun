extends RefCounted

const Fengxi = preload("res://scripts/world_fengxi.gd")
const Swordhall = preload("res://scripts/world_swordhall.gd")
const Watch = preload("res://scripts/world_watch.gd")
const Valley = preload("res://scripts/world_valley.gd")
const Economy = preload("res://scripts/economy.gd")
const CampaignLinks = preload("res://scripts/campaign_links.gd")
const REGIONS := {"fengxi":Fengxi,"swordhall":Swordhall,"outer_watch":Watch,"valley":Valley}
const LINKS := [
	{"id":"road_fengxi_watch","area":"shore","at":Vector2(221,148),"destination":"watch_lodge","arrival":Vector2(107,192),
		"name":"沿凤溪陆路往天下会外哨"},
	{"id":"road_watch_fengxi","area":"watch_lodge","at":Vector2(83,177),"destination":"shore","arrival":Vector2(195,150),
		"name":"走西侧驿道到凤溪渡口"},
	{"id":"road_sword_watch","area":"sword_road","at":Vector2(1450,229),"destination":"watch_road","arrival":Vector2(208,235),
		"name":"沿工匠炉道去外哨林道"},
	{"id":"road_watch_sword","area":"watch_road","at":Vector2(182,252),"destination":"sword_road","arrival":Vector2(1428,230),
		"name":"沿运铁炉道往拜剑山庄"},
	{"id":"road_watch_valley","area":"watch_lodge","at":Vector2(574,216),"destination":"valley_clinic","arrival":Vector2(117,244),
		"name":"顺药商石路前往生死门"},
	{"id":"road_valley_watch","area":"valley_clinic","at":Vector2(86,237),"destination":"watch_lodge","arrival":Vector2(542,234),
		"name":"沿谷口石路去外哨旧岗院"},
]
const MAIN_ROOMS := {"village":1,"inn":1,"forge":2,"swordhall":2,"returnhall":2,
	"pool":3,"apothecary":3,"palace":4,"jail":4,"tearoom":4,"cavern":5,"lodge":5,"peak":5,"dawn":5}

var g: Node2D
var tracked := ""
var battle_point := {}

func _init(game: Node2D) -> void:
	g = game

static func initial() -> Dictionary:
	return {"area":"","entry":[],"return":{},"resume":{},"tasks":{},"legacy_aid":[]}

static func migrate(slot: Dictionary) -> void:
	var state: Dictionary = slot.world
	if not state.has("legacy_aid"):
		state.legacy_aid = ["testimony","medicine"].filter(func(key): return state.tasks.has(key))

static func unlocked(slot: Dictionary) -> bool:
	return REGIONS.values().any(func(data): return data.unlocked(slot))

static func region_unlocked(slot: Dictionary, id: String) -> bool:
	return REGIONS.has(id) and REGIONS[id].unlocked(slot)

static func _region_for_area(area: String) -> String:
	for id in REGIONS:
		if REGIONS[id].AREAS.has(area):
			return id
	return ""

static func valid(slot: Dictionary) -> bool:
	var state: Variant = slot.get("world")
	if not state is Dictionary or not state.get("area") is String or not state.get("return") is Dictionary or not state.get("tasks") is Dictionary:
		return false
	var facts: Dictionary = state.tasks
	var known := {}
	for key in REGIONS:
		for definition in REGIONS[key].QUESTS:
			for fact in definition.evidence:
				known[fact] = [true]
			known[definition.receipt] = [true]
			known[definition.id] = definition.outcomes
			if not _valid_quest(slot,key,definition,facts):
				return false
	for key in CampaignLinks.TASKS:
		var task: Dictionary = CampaignLinks.TASKS[key]
		known[key] = [true]
		var first_chapter := 2 if key == "charter_handoff" else (3 if key == "medicine_handoff" else 4)
		if facts.has(key) and (not task.variants.has(facts.get(task.origin,"")) or slot.chapter < first_chapter):
			return false
	var legacy: Variant = state.get("legacy_aid",[])
	if not legacy is Array or legacy.size() > 2 or not legacy.all(func(key): return key in ["testimony","medicine"] and facts.has(key)):
		return false
	for key in facts:
		if not known.has(key) or facts[key] not in known[key]:
			return false
	var origin: Dictionary = state["return"]
	var entry: Variant = state.get("entry",[])
	var checkpoint: Variant = state.get("resume",{})
	if not entry is Array or (not entry.is_empty() and not _coordinates(entry,1536)) or not checkpoint is Dictionary:
		return false
	if not checkpoint.is_empty() and (not state.area.is_empty() or slot.finished or not unlocked(slot)
		or checkpoint.get("chapter") != slot.chapter or slot.get("journey",{}).get("active","") != ""
		or not _valid_origin(checkpoint,int(slot.chapter))):
		return false
	if state.area.is_empty():
		return origin.is_empty() and entry.is_empty() and (facts.is_empty() or unlocked(slot))
	var region_id := _region_for_area(state.area)
	if region_id.is_empty() or not region_unlocked(slot,region_id) or slot.get("journey",{}).get("active","") != "":
		return false
	if state.area == "watch_palace_reception" and slot.chapter < 5:
		return false
	return _valid_origin(origin,int(slot.chapter))

static func _valid_origin(origin: Dictionary, chapter: int) -> bool:
	return MAIN_ROOMS.get(origin.get("room"),-1) == chapter and _coordinates(origin.get("at"),640)

static func _valid_quest(slot: Dictionary, region: String, definition: Dictionary, facts: Dictionary) -> bool:
	var complete := facts.has(definition.id)
	var receipt := facts.has(definition.receipt)
	if not complete and not receipt and not definition.evidence.any(func(key): return facts.has(key)):
		return true
	if not region_unlocked(slot,region):
		return false
	var current: String = REGIONS[region].phase(slot)
	if complete and (not definition.evidence.all(func(key): return facts.has(key)) or current not in definition.delivery_phases):
		return false
	# Builds with the earlier Fengxi slice permitted receipts throughout resource chapter 5.
	var old_receipt := region == "fengxi" and int(slot.chapter) == 5
	return not receipt or (complete and (current in definition.receipt_phases or old_receipt))

static func _coordinates(at: Variant, width: int) -> bool:
	if not at is Array or at.size() != 2:
		return false
	var limits := [width,360]
	for axis in 2:
		var position: Variant = at[axis]
		if (not position is float and not position is int) or not is_finite(float(position)) or position < 0 or position >= limits[axis]:
			return false
	return true

func active() -> bool:
	return not g.afterstory.active and not g.slot.get("world",{}).get("area","").is_empty()

func available() -> bool:
	return not g.chronicle.review and not g.afterstory.active and g.slot.get("journey",{}).get("active","").is_empty() and unlocked(g.slot)

func destinations() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id in REGIONS:
		if region_unlocked(g.slot,id):
			result.append({"id":id,"title":REGIONS[id].TITLE,"visit_label":REGIONS[id].VISIT_LABEL})
	return result

func region() -> String:
	return _region_for_area(g.slot.world.area) if active() else "fengxi"

func phase() -> String:
	return REGIONS[region()].phase(g.slot)

func phase_label() -> String:
	return REGIONS[region()].PHASES[phase()]

func title() -> String:
	return REGIONS[region()].AREAS[g.slot.world.area].title

func journal_title() -> String:
	return REGIONS[region()].JOURNAL_TITLE

func music() -> String:
	return REGIONS[region()].music(phase(),g.field_key)

func from_main(destination: String = "fengxi") -> void:
	if not available() or not REGIONS.has(destination) or not region_unlocked(g.slot,destination):
		return
	var touring := active()
	var previous: Dictionary = g.slot.duplicate(true)
	if not touring:
		var room: String = "dawn" if g.slot.finished else g.field_key
		var position: Vector2 = Vector2(218,244) if g.slot.finished else g.player
		g.slot.world["return"] = {"room":room,"at":[position.x,position.y]}
		g.slot.world.resume = {}
	g.slot.world.area = REGIONS[destination].ENTRY
	g.slot.world.entry = []
	if not g._commit():
		g.slot = previous
		return
	_load()

func resume() -> bool:
	if not active():
		return false
	_load()
	return true

func resume_main() -> bool:
	var checkpoint: Dictionary = g.slot.world.get("resume",{})
	if checkpoint.is_empty():
		return false
	_restore_origin(checkpoint)
	return true

func clear_old_checkpoint() -> void:
	var state: Dictionary = g.slot.get("world",{})
	var checkpoint: Dictionary = state.get("resume",{})
	if not checkpoint.is_empty() and (g.slot.finished or checkpoint.chapter != g.slot.chapter
		or checkpoint.room != g.field_key or not g.slot.get("journey",{}).get("active","").is_empty()):
		state.resume = {}

func _load() -> void:
	var area: Dictionary = REGIONS[region()].AREAS[g.slot.world.area]
	var field: String = area.get("phase_fields",{}).get(phase(),area.field)
	g._load_field(field,area.spawn)
	var entry: Array = g.slot.world.get("entry",[])
	if not entry.is_empty():
		var arrival := Vector2(entry[0],entry[1])
		if g.passable(arrival):
			g.player = arrival
			g._place_follower()
	g._return_to_field()

func leave() -> void:
	if not active():
		return
	var previous: Dictionary = g.slot.duplicate(true)
	var origin: Dictionary = previous.world["return"]
	g.slot.world.area = ""
	g.slot.world.entry = []
	g.slot.world["return"] = {}
	if not g.slot.finished:
		origin.chapter = g.slot.chapter
		g.slot.world.resume = origin
	if not g._commit(true):
		g.slot = previous
		return
	if g.slot.finished:
		g._title()
		return
	_restore_origin(origin)

func _restore_origin(origin: Dictionary) -> void:
	g._load_field(origin.room)
	var position := Vector2(origin.at[0],origin.at[1])
	if g.passable(position):
		g.player = position
		g._place_follower()
	g._return_to_field()

func points() -> Array:
	var facts: Dictionary = g.slot.world.tasks
	var current := phase()
	var result := []
	var candidates: Array = REGIONS[region()].POINTS + LINKS
	for point in candidates:
		var required: Array = point.get("requires",[])
		var match_facts: Dictionary = point.get("matches",{})
		if point.area != g.slot.world.area or (point.has("phases") and current not in point.phases) or g.slot.chapter < point.get("min_chapter",0):
			continue
		if not required.all(func(key): return facts.has(key)) or not match_facts.keys().all(func(key): return facts.get(key) == match_facts[key]):
			continue
		if facts.has(point.get("excludes",point.get("evidence",""))):
			continue
		var entry: Dictionary = point.duplicate()
		if point.has("destination") and not region_unlocked(g.slot,_region_for_area(point.destination)):
			continue
		entry.pos = point.at
		if point.id.begins_with("road_"):
			entry.prop = "exit_open"
		entry["index"] = -1
		result.append(entry)
	result.append_array(CampaignLinks.receive_points(g.slot,g.field_key,g.slot.world.area))
	return result

func main_handoff_points() -> Array:
	return [] if g.chronicle.review or g.field_key != "palace" else CampaignLinks.receive_points(g.slot,g.field_key)

func handle(point: Dictionary) -> void:
	if point.id == "world_return":
		leave()
	elif point.has("destination"):
		var previous: Dictionary = g.slot.duplicate(true)
		g.slot.world.area = point.destination
		var arrival: Vector2 = point.get("arrival",Vector2.ZERO)
		g.slot.world.entry = [] if arrival == Vector2.ZERO else [arrival.x,arrival.y]
		if g._commit():
			_load()
		else:
			g.slot = previous
	elif point.has("shop"):
		g._open_shop(point.shop)
	elif point.has("forge"):
		g._open_forge(point.forge)
	elif point.has("foes"):
		battle_point = point
		g.active_battle = -1
		g._talk(point.lines,g._start_battle)
	elif point.has("choices"):
		g.chronicle.choose(point.name,point.choices,_result.bind(point),point.get("note",""))
	elif point.has("lines"):
		g._talk(point.lines,_finish_point.bind(point))

func _finish_point(point: Dictionary) -> void:
	if not point.get("evidence","").is_empty():
		_apply_fact(point.evidence,true)
	elif point.has("result"):
		_apply_fact(point.result,"done")
	g._return_to_field()

func _result(chosen: String, point: Dictionary) -> void:
	_apply_fact(point.result,chosen)
	g._return_to_field()

func _apply_fact(key: String, value: Variant, persist_combat: bool = false) -> bool:
	var before: Dictionary = g.slot.duplicate(true)
	var prior_rewards: int = g.gear_rewards.size()
	g.slot.world.tasks[key] = value
	if persist_combat:
		g.slot.tonics = g.encounter.tonics
		g.slot.supplies = g.encounter.supplies
	var rewards := PackedStringArray()
	var linked := CampaignLinks.reward(g.slot,key)
	if not linked.is_empty():
		if linked.has("drop"):
			rewards = Economy.claim(g.slot,g.slot,linked.drop)
		if linked.has("supply"):
			g._reward_supply(linked.supply)
	else:
		for definition in REGIONS[region()].QUESTS:
			if key == definition.id:
				rewards = Economy.claim(g.slot,g.slot,definition.source)
				if definition.has("supply"):
					g._reward_supply(definition.supply)
	if not g._commit():
		g.slot = before
		g.gear_rewards.resize(prior_rewards)
		g._notice("存档失败，请重新确认这一处线索。")
		return false
	for item in rewards:
		g.gear_rewards.append("获得 · " + item)
	return true

func encounter() -> Array:
	return [battle_point.name,battle_point.foes,battle_point.lines]

func won() -> bool:
	return _apply_fact(battle_point.evidence,true,true)

func journal() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var facts: Dictionary = g.slot.world.tasks
	for definition in REGIONS[region()].QUESTS:
		var task: Dictionary = definition.duplicate()
		task.steps = task.evidence.filter(func(key): return facts.has(key)).size()
		task.complete = facts.has(task.id)
		task.can_deliver = phase() in task.delivery_phases
		task.awaiting_receipt = task.complete and phase() in task.receipt_phases and not facts.has(task.receipt)
		result.append(task)
	return result

func trackable_points() -> Array:
	if CampaignLinks.TASKS.has(tracked):
		var id: String = CampaignLinks.TASKS[tracked].point
		return points().filter(func(point): return point.id == id)
	for task in journal():
		if task.id == tracked and (not task.complete or task.awaiting_receipt):
			return points().filter(func(point): return point.get("evidence","") in (task.evidence if not task.complete else [task.receipt]) or point.get("result","") == task.id)
	return []

func handoff_journal() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var facts: Dictionary = g.slot.world.tasks
	for id in CampaignLinks.TASKS:
		var task: Dictionary = CampaignLinks.TASKS[id]
		var branch: Dictionary = task.variants.get(facts.get(task.origin,""),{})
		var destination: String = task.to
		var regional: String = task.get("area","")
		var destination_open: bool = g.slot.chapter >= 4 if regional.is_empty() else region_unlocked(g.slot,_region_for_area(regional))
		if regional.is_empty() and g.slot.chapter >= 5:
			destination = "外哨旧岗院沿驿道至绝宫前庭"
		var state := "查线索"
		var action: String = task.source
		if not branch.is_empty():
			if facts.has(id):
				state = "已交接"
				action = branch.result
			else:
				state = "待交接" if destination_open else "待启程"
				action = branch.name if destination_open else "主线开放目的地后，可前往交接。"
		result.append({"id":id,"title":task.title,"from":task.from,"to":destination,"state":state,"action":action})
	return result

func battle_aid(index: int, special: String) -> Dictionary:
	var facts: Dictionary = g.slot.world.tasks
	if g.field_key == "palace" and index == 0:
		var aid := {}
		var lines := PackedStringArray()
		if facts.has("testimony_handoff") or "testimony" in g.slot.world.get("legacy_aid",[]):
			match facts.get("testimony",""):
				"signed":
					aid.merge({"foe":"invader","poise":1})
					lines.append("凤溪证人指明换旗，首敌少一格势。")
				"sealed":
					aid.ward = "cloud"
					lines.append("凤溪密封证词指明窄门，步惊云获得护持。")
		if facts.has("register_handoff") and facts.get("watch_register") == "public":
			aid.bond = 1
			lines.append("外哨证人核过名册，合击多一格。")
		if not aid.is_empty():
			aid.line = " ".join(lines)
		return aid
	if g.field_key == "palace" and index == 1 and facts.has("carry_handoff"):
		match facts.get("valley_carry"):
			"medicine":
				if g.chronicle.has("trestle_supply") or (g.chronicle.has("courier_contact") and g.chronicle.side.state().get("courier") == "done_quiet"):
					return {"ward":"cloud","line":"断栈护送员留下另一份护脉散，步惊云也获得护持。"}
				return {"ward":"sage","line":"断栈护脉散护住无名，可挡一次重击。"}
			"breath":
				return {"foe":"godless","poise":1,"line":"断栈换气字条揭出金身发劲的空当，绝无神少一格势。"}
	if special == "prepare_guard" and (facts.has("medicine_handoff") or "medicine" in g.slot.world.get("legacy_aid",[])) and not g.chronicle.has("ridge_guide"):
		return {"ward":"wind","line":"凤溪药单备齐护脉药，聂风开场获得护持。"}
	return {}
