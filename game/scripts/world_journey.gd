extends RefCounted

const Fengxi = preload("res://scripts/world_fengxi.gd")
const Swordhall = preload("res://scripts/world_swordhall.gd")
const Watch = preload("res://scripts/world_watch.gd")
const Valley = preload("res://scripts/world_valley.gd")
const Palace = preload("res://scripts/world_palace.gd")
const Mountain = preload("res://scripts/world_mountain.gd")
const Tide = preload("res://scripts/world_tide.gd")
const Economy = preload("res://scripts/economy.gd")
const CampaignLinks = preload("res://scripts/campaign_links.gd")
const REGIONS := {"fengxi":Fengxi,"swordhall":Swordhall,"outer_watch":Watch,"valley":Valley,
	"palace":Palace,"mountain":Mountain,"tide":Tide}
const TIDE_ROOMS := ["tidal_ford","tidal_fort"]
const PALACE_PROOFS := ["palace_river_decree","palace_dispatch_record"]
const RESCUES := ["mountain_west","mountain_medicine","mountain_rearguard"]
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
	{"id":"road_palace_watch","area":"palace_court","at":Vector2(575,277),"destination":"watch_lodge","arrival":Vector2(504,250),
		"name":"沿外庭驿道回天下会外哨"},
	{"id":"road_palace_mountain","area":"palace_west","at":Vector2(1466,223),"destination":"mountain_approach","arrival":Vector2(115,240),
		"name":"沿北槽进凌云山引水渠"},
	{"id":"road_mountain_palace","area":"mountain_approach","at":Vector2(84,251),"destination":"palace_west","arrival":Vector2(1388,264),
		"name":"回西闸北槽与绝宫外庭"},
	{"id":"road_mountain_fengxi","area":"mountain_steps","at":Vector2(113,275),"destination":"shore","arrival":Vector2(196,151),
		"name":"顺西坡灯路回凤溪","requires":["mountain_west"],"requires_lanterns":true},
	{"id":"road_fengxi_mountain","area":"shore","at":Vector2(202,182),"destination":"mountain_steps","arrival":Vector2(138,270),
		"name":"沿灯路回凌云山西坡","requires":["mountain_west"],"requires_lanterns":true},
	{"id":"road_ledger_steps","area":"mountain_cavern","at":Vector2(531,217),"destination":"mountain_steps","arrival":Vector2(1165,230),
		"name":"沿铁板记下的暗道绕去东阶","requires_quests":{"hidden_ledger":"done_trade"}},
	{"id":"road_ledger_cavern","area":"mountain_steps","at":Vector2(1188,258),"destination":"mountain_cavern","arrival":Vector2(507,205),
		"name":"循铁板暗道回龙脉洞口","requires_quests":{"hidden_ledger":"done_trade"}},
	{"id":"road_fengxi_tide","area":"shore","at":Vector2(94,195),"destination":"tide_ford","arrival":Vector2(190,252),
		"name":"从凤溪码头乘船去潮关","requires_lanterns":true},
	{"id":"road_tide_fengxi","area":"tide_ford","at":Vector2(155,275),"destination":"shore","arrival":Vector2(118,219),
		"name":"搭回船去凤溪"},
]
const MAIN_ROOMS := {"village":1,"inn":1,"forge":2,"swordhall":2,"returnhall":2,
	"pool":3,"apothecary":3,"palace":4,"jail":4,"tearoom":4,"cavern":5,"lodge":5,"peak":5,"dawn":5}

var g: Node2D
var tracked := ""
var battle_point := {}

func _init(game: Node2D) -> void:
	g = game

static func initial() -> Dictionary:
	return {"area":"","entry":[],"return":{},"resume":{},"tasks":{},"legacy_aid":[],"finale":[],"tide_source":""}

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
	known["palace_fire_safe"] = [true]
	known["palace_fire_patrol"] = [true]
	known["dawn_relief_witnessed"] = [true]
	known["tide_late_alu"] = [true]
	if (facts.has("palace_fire_safe") or facts.has("palace_fire_patrol")) and slot.chapter < 4:
		return false
	if facts.has("dawn_relief_witnessed") and slot.chapter != 5:
		return false
	var finale: Variant = state.get("finale",[])
	if not finale is Array or not finale.all(func(key): return key in RESCUES and facts.has(key)):
		return false
	if not finale.is_empty() and (slot.chapter != 5 or not slot.cleared.any(func(flag): return int(flag) == 1)):
		return false
	for key in facts:
		if not known.has(key) or facts[key] not in known[key]:
			return false
	if not _valid_tide(slot,state,facts):
		return false
	var origin: Dictionary = state["return"]
	var entry: Variant = state.get("entry",[])
	var checkpoint: Variant = state.get("resume",{})
	if not entry is Array or (not entry.is_empty() and not _coordinates(entry,1536)) or not checkpoint is Dictionary:
		return false
	if not checkpoint.is_empty() and (not state.area.is_empty() or slot.finished or not unlocked(slot)
		or checkpoint.get("chapter") != slot.chapter or slot.get("journey",{}).get("active","") != ""
		or not _valid_origin(checkpoint,slot)):
		return false
	if state.area.is_empty():
		return origin.is_empty() and entry.is_empty() and (facts.is_empty() or unlocked(slot))
	var region_id := _region_for_area(state.area)
	if region_id.is_empty() or not region_unlocked(slot,region_id) or slot.get("journey",{}).get("active","") != "":
		return false
	if state.area == "watch_palace_reception" and slot.chapter < 5:
		return false
	if state.area == "mountain_altar" and not Mountain.altar_open(slot):
		return false
	if region_id == "tide" and not slot.has("afterstory"):
		return false
	return _valid_origin(origin,slot)

static func _valid_origin(origin: Dictionary, slot: Dictionary) -> bool:
	var room: Variant = origin.get("room")
	if room in TIDE_ROOMS:
		return slot.finished and slot.get("afterstory",{}).get("room","") == room and _coordinates(origin.get("at"),640)
	return MAIN_ROOMS.get(room,-1) == int(slot.chapter) and _coordinates(origin.get("at"),640)

static func _valid_tide(slot: Dictionary, state: Dictionary, facts: Dictionary) -> bool:
	var tide: Dictionary = slot.get("afterstory",{})
	var source: Variant = state.get("tide_source","")
	if not source is String or (facts.has("tide_review_source") != (source != "")):
		return false
	if source != "" and not _proof_available(slot,source):
		return false
	if (facts.has("tide_review_count") or facts.has("tide_review_seal")) and not tide.get("ledger",false):
		return false
	if facts.has("tide_late_alu") and (not tide.get("aid",false) or tide.get("resolution","").is_empty()):
		return false
	for id in ["tide_relief_roll","tide_relief_dispatch","tide_relief_arrival","tide_relief_west","tide_relief_east"]:
		if facts.has(id) and tide.get("resolution","").is_empty():
			return false
	if (facts.has("tide_relief_dispatch") and not facts.has("tide_relief_roll")
			or facts.has("tide_relief_arrival") and not facts.has("tide_relief_dispatch")
			or (facts.has("tide_relief_west") or facts.has("tide_relief_east")) and not facts.has("tide_relief_arrival")):
		return false
	return not facts.has("tide_relief") or facts.tide_relief == tide.get("resolution","")

static func _proof_available(slot: Dictionary, source: String) -> bool:
	var after: Dictionary = slot.get("afterstory",{})
	var facts: Dictionary = slot.world.tasks
	match source:
		"canal": return after.get("brief",false)
		"alu": return after.get("aid",false)
		"manifest": return after.get("canal_manifest",false)
		"worker": return after.get("canal_witness",false)
		"testimony": return facts.has("testimony_handoff") and facts.get("testimony","") == "signed"
		"jiang": return facts.has("palace_survival_receipt") and facts.get("palace_survival","") == "witness"
		"watch": return facts.has("register_handoff") and facts.get("watch_register","") == "public"
	return false

static func _tide_help(slot: Dictionary, key: String) -> bool:
	var quests: Dictionary = slot.chronicle.quests
	var facts: Dictionary = slot.world.tasks
	match key:
		"boat": return quests.get("lamps","") in ["wait_boat","done_boat"]
		"grain": return quests.get("lamps","") in ["wait_goods","done_goods"]
		"clinic": return facts.has("medicine_handoff") or facts.has("mountain_medicine") or facts.get("valley_carry","") == "medicine" and facts.has("carry_handoff")
		"convoy": return facts.has("register_handoff") or facts.has("mountain_rearguard")
	return false

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
	return not g.chronicle.review and g.slot.get("journey",{}).get("active","").is_empty() and unlocked(g.slot)

func uses_tide_account() -> bool:
	return active() and region() == "tide"

func departure_label() -> String:
	return "回潮关余事" if g.slot.world["return"].get("room") in TIDE_ROOMS else "返回主线"

func fire_pending() -> bool:
	return g.slot.chapter == 4 and g.chronicle.has("fire_signal") and not g.chronicle.has("evacuated") and not g.chronicle.review

func can_leave() -> bool:
	return not (active() and fire_pending() and region() == "palace" and not g.slot.world.tasks.has("palace_fire_safe"))

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

func from_main(destination: String = "fengxi", area: String = "") -> void:
	if not available() or not region_unlocked(g.slot,destination) or not can_leave():
		return
	var touring := active()
	var previous: Dictionary = g.slot.duplicate(true)
	if not touring:
		var from_ending: bool = g.slot.finished and not g.afterstory.active
		var room: String = "dawn" if from_ending else g.field_key
		var position: Vector2 = Vector2(218,244) if from_ending else g.player
		g.slot.world["return"] = {"room":room,"at":[position.x,position.y]}
		g.slot.world.resume = {}
	g.slot.world.area = REGIONS[destination].ENTRY if area.is_empty() else area
	g.slot.world.entry = []
	if destination == "tide":
		g.afterstory.ensure_account()
	if not g._commit():
		g.slot = previous
		return
	g.afterstory.reset()
	_load()

func escape_fire() -> void:
	if g.chronicle.review:
		g.chronicle.beat("fire_signal",fire_lines())
		return
	g.chronicle.speak(fire_lines(),func():
		g.slot.chronicle.marks.fire_signal = true
		from_main("palace","palace_tea")
		if not active():
			g.slot.chronicle.marks.erase("fire_signal")
			g._return_to_field()
	)

func fire_lines() -> Array:
	return [
		["绝无神","这杯茶……绝心，你也要我的命？"],
		["绝心","雄霸等我拿到发令簿。等你一死，关内的兵听谁的，由我来定。"],
		["秦霜","主廊的火顶到梁上了。穿后院下西闸，从安全外庭会合。手里没有岗令或发令记录的，路上补齐再追。"],
	]

func mountain_gate_required() -> bool:
	return g.slot.chapter == 5 and g.chronicle.enabled() and not g.chronicle.review and not g.slot.campaign.farewell

func mountain_ready() -> bool:
	return Mountain.ready(g.slot)

func record_finale() -> void:
	g.slot.world.finale = RESCUES.filter(func(id): return g.slot.world.tasks.has(id))

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

func leave() -> bool:
	if not active() or not can_leave():
		return false
	var previous: Dictionary = g.slot.duplicate(true)
	var origin: Dictionary = previous.world["return"]
	if fire_pending() and origin.room == "tearoom":
		origin = {"room":"palace","at":[135,208]}
		g.slot.chronicle.room = ""
		g.slot.campaign.palace_room = "palace"
	g.slot.world.area = ""
	g.slot.world.entry = []
	g.slot.world["return"] = {}
	if origin.room in TIDE_ROOMS:
		g.slot.afterstory.at = origin.at
	if not g.slot.finished:
		origin.chapter = g.slot.chapter
		g.slot.world.resume = origin
	if not g._commit(true):
		g.slot = previous
		return false
	if origin.room in TIDE_ROOMS:
		g.afterstory.resume()
		return true
	if g.slot.finished:
		g._title()
		return true
	_restore_origin(origin)
	return true

func _restore_origin(origin: Dictionary) -> void:
	g._load_field(origin.room)
	var position := Vector2(origin.at[0],origin.at[1])
	if g.passable(position):
		g.player = position
		g._place_follower()
	g._return_to_field()

func points() -> Array:
	var facts: Dictionary = g.slot.world.tasks
	var area: String = g.slot.world.area
	var result: Array = []
	for point in _area_points(area,REGIONS[region()].POINTS + LINKS,phase()):
		var entry: Dictionary = point.duplicate()
		entry.pos = point.at
		if point.id.begins_with("road_"):
			entry.prop = "exit_open"
		entry["index"] = -1
		result.append(entry)
	result.append_array(CampaignLinks.receive_points(g.slot,g.field_key,g.slot.world.area))
	if region() == "palace" and g.slot.world.area == "palace_court" and fire_pending():
		var ready := PALACE_PROOFS.all(func(id): return facts.has(id))
		result.append({"id":"evacuated","name":"带齐岗令与发令记录，向至尊辞行" if ready else "问至尊还缺哪些证据",
			"pos":Vector2(191,268),"index":-1,"sprite":"frost","fire_finish":true})
	if g.slot.world.area in ["palace_cells","mountain_approach","mountain_cavern","mountain_steps","mountain_altar"]:
		result.append_array(g.chronicle.side.ledger_points())
	if g.slot.world.area == "shore" and g.field_key == "dawn":
		var stations := homecoming_points()
		if not stations.is_empty():
			result.append({"id":"world_dawn_relief","name":"到渡口核对山下归人","pos":Vector2(159,185),
				"index":-1,"sprite":"servant","read_finale":true})
			result.append_array(stations)
	return result

func _area_points(area: String, candidates: Array, current: String) -> Array:
	var facts: Dictionary = g.slot.world.tasks
	var available := []
	for point in candidates:
		if point.area != area or not _point_unlocked(point,facts,current):
			continue
		var requires: Array = point.get("requires",[])
		var matching: Dictionary = point.get("matches",{})
		var legacy_door: bool = point.id == "world_palace_side_door" and palace_legacy_side()
		if not requires.all(func(key): return facts.has(key) or (key == "palace_side" and legacy_door)):
			continue
		if not matching.keys().all(func(key): return facts.get(key) == matching[key]):
			continue
		if facts.has(point.get("excludes",point.get("evidence",""))):
			continue
		if point.has("destination") and not region_unlocked(g.slot,_region_for_area(point.destination)):
			continue
		available.append(point)
	return available

func _point_unlocked(point: Dictionary, facts: Dictionary, current: String) -> bool:
	var any_facts: Array = point.get("requires_any",[])
	var quests: Dictionary = point.get("requires_quests",{})
	var tide: Dictionary = point.get("requires_tide",{})
	var tide_state: Dictionary = g.slot.get("afterstory",{})
	return (
		(not point.has("phases") or current in point.phases)
		and g.slot.chapter >= point.get("min_chapter",0)
		and (not point.has("active_chapter") or g.slot.chapter == point.active_chapter)
		and not g.chronicle.has(point.get("before_mark",""))
		and point.get("marks",[]).all(func(id): return g.chronicle.has(id))
		and point.get("missing",[]).all(func(id): return not facts.has(id))
		and (any_facts.is_empty() or any_facts.any(func(id): return facts.has(id)))
		and quests.keys().all(func(id): return g.slot.chronicle.quests.get(id,"") == quests[id])
		and tide.keys().all(func(id): return tide_state.get(id,false if tide[id] is bool else "") == tide[id])
		and point.get("requires_help",[]).all(func(id): return _tide_help(g.slot,id))
		and point.get("missing_help",[]).all(func(id): return not _tide_help(g.slot,id))
		and (not point.has("proof") or _proof_available(g.slot,point.proof))
		and (not point.has("altar_open") or Mountain.altar_open(g.slot) == point.altar_open)
		and (not point.get("requires_lanterns",false) or Fengxi.phase(g.slot) == "reopened")
	)

func palace_legacy_side() -> bool:
	return String(g.chronicle.side.state().get("shift","")).begins_with("done_")

func main_region_points() -> Array:
	if g.chronicle.review:
		return []
	var result := []
	if g.slot.chapter == 4 and g.field_key in ["palace","jail","tearoom"]:
		var area: String = {"palace":"palace_court","jail":"palace_cells","tearoom":"palace_tea"}[g.field_key]
		var facts: Dictionary = g.slot.world.tasks
		for point in Palace.POINTS:
			if (point.area != area or point.has("destination") or point.id == "world_return"
					or not _point_unlocked(point,facts,Palace.phase(g.slot))
					or facts.has(point.get("excludes",point.get("evidence","")))):
				continue
			if (not point.get("requires",[]).all(func(id): return facts.has(id))
					or not point.get("matches",{}).keys().all(func(id): return facts.get(id) == point.matches[id])):
				continue
			var placed: Dictionary = point.duplicate()
			placed.merge({"pos":point.at,"index":-1,"regional":true})
			result.append(placed)
		if g.field_key == "palace" and not g.chronicle.has("evacuated"):
			result.append({"id":"world_palace_visit","name":"沿外庭踏查西闸和内院",
				"pos":Vector2(121,220),"index":-1,"sprite":"guide","region_entry":"palace"})
	return result

func main_handoff_points() -> Array:
	return [] if g.chronicle.review or g.field_key != "palace" else CampaignLinks.receive_points(g.slot,g.field_key)

func handle(point: Dictionary) -> void:
	if point.id.begins_with("side_"):
		g.chronicle.side.handle(point.id)
	elif point.get("read_finale",false):
		read_finale()
	elif point.has("homecoming"):
		g._talk(finale_rows(point.homecoming),g._return_to_field)
	elif point.get("fire_finish",false):
		_finish_fire(point)
	elif point.get("tide_main",false):
		_enter_tide_story()
	elif point.id == "world_return":
		leave()
	elif point.has("destination"):
		var previous: Dictionary = g.slot.duplicate(true)
		g.slot.world.area = point.destination
		if _region_for_area(point.destination) == "tide":
			g.afterstory.ensure_account()
		if fire_pending() and point.destination == "palace_court":
			g.slot.world.tasks.palace_fire_safe = true
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

func _enter_tide_story() -> void:
	var previous: Dictionary = g.slot.duplicate(true)
	var origin: Dictionary = g.slot.world["return"]
	g.slot.world.area = ""
	g.slot.world.entry = []
	g.slot.world["return"] = {}
	if origin.room in TIDE_ROOMS:
		g.slot.afterstory.at = origin.at
	if not g._commit(true):
		g.slot = previous
		return
	g.afterstory.resume()

func _finish_fire(_point: Dictionary) -> void:
	var missing: Array = PALACE_PROOFS.filter(func(id): return not g.slot.world.tasks.has(id))
	if not missing.is_empty():
		var needed := PackedStringArray()
		if "palace_river_decree" in missing:
			needed.append("西闸巡逻簿上的水道岗令")
		if "palace_dispatch_record" in missing:
			needed.append("外庭轮值官的发令记录")
		g._talk([["至尊","外庭已安全。去核对" + "和".join(needed) + "，我就在这里等你。"]],g._return_to_field)
		return
	var pursuit := "我随无名回城，把伪诏与证据一起交出去。你沿北引水渠追到凌云窟。"
	match g.chronicle.side.state().get("shift",""):
		"done_stealth":
			pursuit += " 狱卒留下的护心镜，记得给聂风戴上。"
		"done_fight":
			pursuit += " 狱卒说守兽听得见铜哨，你带上缴来的那只。"
	g.chronicle.speak([
		["步惊云","西闸岗令和发令记录都写着北引水渠。绝心带走聂风，秦师兄在渠口留了记号。"],
		["至尊",pursuit],
	],func():
		var before: Dictionary = g.slot.duplicate(true)
		g.slot.chronicle.marks.evacuated = true
		g.slot.world.tasks.palace_fire_safe = true
		g.slot.world.tasks.palace_evidence = "done"
		g.slot.world["return"] = {"room":"palace","at":[135,208]}
		g.slot.chronicle.room = ""
		g.slot.campaign.palace_room = "palace"
		if not leave():
			g.slot = before
			g._return_to_field()
	)

func _finish_point(point: Dictionary) -> void:
	if not point.get("evidence","").is_empty():
		_apply_fact(point.evidence,true,false,point.get("proof",""))
	elif point.has("result"):
		_apply_fact(point.result,point.get("result_value","done"))
	g._return_to_field()

func _result(chosen: String, point: Dictionary) -> void:
	_apply_fact(point.result,chosen)
	g._return_to_field()

func _apply_fact(key: String, value: Variant, persist_combat: bool = false, proof: String = "") -> bool:
	var before: Dictionary = g.slot.duplicate(true)
	var prior_rewards: int = g.gear_rewards.size()
	g.slot.world.tasks[key] = value
	if not proof.is_empty():
		g.slot.world.tide_source = proof
	var account: Dictionary = g.shop_account()
	if persist_combat:
		account.tonics = g.encounter.tonics
		account.supplies = g.encounter.supplies
		if uses_tide_account() and battle_point.get("battle_tide_flag","") == "aid":
			account.aid = true
			account.tonics = mini(6,account.tonics + 2)
			for reward in Economy.claim(g.slot,account,"tidal:aid",4):
				g.gear_rewards.append("获得 · " + reward)
	var rewards := PackedStringArray()
	var linked := CampaignLinks.reward(g.slot,key)
	if not linked.is_empty():
		if linked.has("drop"):
			rewards = Economy.claim(g.slot,g.slot,linked.drop)
		if linked.has("supply"):
			g._reward_supply(linked.supply)
	else:
		var data: Script = Palace if not active() and g.slot.chapter == 4 else REGIONS[region()]
		for definition in data.QUESTS:
			if key == definition.id:
				var source: String = definition.get("source_by_outcome",{}).get(value,definition.get("source",""))
				if not source.is_empty():
					rewards = Economy.claim(g.slot,account,source)
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

func abandon_battle() -> void:
	if battle_point.has("safe_retreat"):
		var position: Vector2 = battle_point.safe_retreat
		if g.passable(position):
			g.player = position
			g._place_follower()
	battle_point.clear()

func journal() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var facts: Dictionary = g.slot.world.tasks
	for definition in REGIONS[region()].QUESTS:
		var task: Dictionary = definition.duplicate()
		task.steps = task.evidence.filter(func(key): return facts.has(key)).size()
		task.complete = facts.has(task.id)
		task.can_deliver = phase() in task.delivery_phases
		task.awaiting_receipt = task.complete and phase() in task.receipt_phases and not facts.has(task.receipt)
		task.expired = task.id == "palace_survival" and not task.complete and phase() == "aftermath" and (
			task.steps < task.evidence.size() or g.slot.chapter >= 5 or g.chronicle.has("evacuated"))
		result.append(task)
	if region() in ["palace","mountain"]:
		var ledger: Dictionary = g.chronicle.side.journal_entry("hidden_ledger")
		var completed: bool = ledger.status == "已完成"
		var quest_state: String = g.slot.chronicle.quests.get("hidden_ledger","")
		var step: int = {"seeking_route":1,"seeking":2,"decision":3}.get(quest_state,4 if completed else 0)
		result.append({"id":"hidden_ledger","title":"壁刻遗图","steps":step,"evidence":[1,2,3,4],
			"description":ledger.place + " · " + ledger.action,
			"follow_up":"回凤溪点验归人时，可核对民籍的处置。",
			"reward":ledger.reward,"complete":completed,"awaiting_receipt":completed and not facts.has("dawn_relief_witnessed"),
			"can_deliver":false,"ready":"","locked":""})
	return result

func homecoming_points() -> Array:
	var result := []
	var groups := _finale_groups()
	var stations := [
		["evidence",Vector2(202,180),"到验印桌核对带回的证词","guard"],
		["care",Vector2(204,266),"到西岸药棚探望撤下山的人","servant"],
		["work",Vector2(451,177),"到桥东问工匠接下来留在哪里","guide"],
		["tide",Vector2(524,271),"在东埠查看潮关回船带来的回执","boatman_front"],
	]
	for station in stations:
		var id: String = station[0]
		if not groups[id].is_empty():
			result.append({"id":"homecoming_" + id,"pos":station[1],"name":station[2],"sprite":station[3],
				"index":-1,"optional":true,"regional":true,"homecoming":id})
	return result

func finale_rows(topic: String = "") -> Array:
	var groups := _finale_groups()
	return groups.get(topic,[]) if not topic.is_empty() else groups.care + groups.evidence + groups.work + groups.tide

func _finale_groups() -> Dictionary:
	var facts: Dictionary = g.slot.world.tasks
	var relief: Array = g.slot.world.get("finale",[])
	if relief.is_empty() and not g.slot.cleared.has(1) and not g.slot.finished:
		relief = RESCUES.filter(func(id): return facts.has(id))
	var groups := {"evidence":[],"care":[],"work":[],"tide":[]}
	if "mountain_west" in relief:
		groups.care.append(["西坡山民","芦家和罗家都下了山。我们把侧坡石道留给上祭台的人，没再让他们踏过碎石。"])
	if "mountain_medicine" in relief:
		groups.care.append(["受伤樵夫","小筑替我绑好腿板，许槐的药到了，晚来的人也有床。赴决战的那包交给聂少侠。"])
	if "mountain_rearguard" in relief:
		groups.care.append(["外哨传令弟子","最后一队也过了石阶。秦师兄留下的那块木牌，我放在渡口让他们认领。"])
	if facts.get("palace_survival") == "rescue":
		groups.care.append(["茶房杂役","西闸水浅，那晚你把我们从烟里带到了外庭。今天我们来凤溪接亲眷。"])
	if facts.get("palace_survival") == "witness":
		groups.evidence.append(["外庭录事","茶房亲历者交来署名记录。我们把副本留在凤溪，来领人的可以查当夜的名册。"])
	if facts.has("testimony_handoff"):
		groups.evidence.append(["渡口验印人","许成留下了姓名，等没领到粮的人来找他。" if facts.testimony == "signed" else "那份拓印能复核，船户姓名留在密封纸里。"])
	if facts.has("medicine_handoff"):
		groups.care.append(["药棚值守人","凤溪后渡的药单还在。生死门带来的伤者就按那张单子领药。"])
	if facts.has("charter_handoff"):
		groups.work.append(["搬绳工匠","于姑娘接了外哨的单，修好的绞索也送到了这里。" if facts.sword_charter == "commission" else "剑庐腾出的铺先给了失散的匠户。张婆婆仍在照看后来的人。"])
	if facts.has("register_handoff"):
		groups.evidence.append(["旧岗录事","来客可以按范著留下的实名点查。" if facts.watch_register == "public" else "旧岗的匿名副页已验过。我们只记时间，没有记谁给的。"])
	if facts.has("carry_handoff"):
		groups.care.append(["许槐","绝宫腾出的护脉药我送到了药棚。" if facts.valley_carry == "medicine" else "邪皇的换气字条交还了。后来学拳的人也能照着抄。"])
	var ledger: String = g.slot.chronicle.quests.get("hidden_ledger","")
	if ledger.begins_with("done_"):
		groups.work.append(["领簿山民","倒灯拓片认得出每一户，归来的人能对上姓名。" if ledger == "done_defend" else "我们照铁板暗道越过封锁。薄铁板已送到渡口供人核对。"])
	for id in RESCUES:
		if facts.has(id) and id not in relief and g.slot.cleared.has(1):
			var label: String = {"mountain_west":"西坡住户","mountain_medicine":"药炉伤者","mountain_rearguard":"石阶最后一队"}[id]
			groups.care.append(["渡口补录","决战之后，%s来报平安。" % label])
	match facts.get("tide_relief", "") if facts.has("tide_relief_receipt") else "":
		"public":
			groups.tide.append(["回航船工","潮关把实发簿抄了一联给凤溪。柳家二升，薛家四升。复称的票角都在，下一趟照这个数目来对。"])
		"witness":
			groups.tide.append(["回航船工","封卷和人证已到州府。这是给凤溪的船章副联。原账留在州府，三日的粮在潮关照发。"])
	return groups

func read_finale() -> void:
	var rows := finale_rows()
	if rows.is_empty():
		return
	g._talk(rows,func():
		_apply_fact("dawn_relief_witnessed",true)
		g._return_to_field()
	)

func trackable_points() -> Array:
	if tracked.is_empty():
		return []
	if tracked == "hidden_ledger":
		return points().filter(func(point): return point.id == "side_hidden_ledger" or point.id == "world_dawn_relief")
	if CampaignLinks.TASKS.has(tracked):
		var id: String = CampaignLinks.TASKS[tracked].point
		return points().filter(func(point): return point.id == id)
	for task in journal():
		if task.id == tracked and (not task.complete or task.awaiting_receipt):
			var evidence: Array = [task.receipt] if task.complete else task.evidence
			var matches := func(point: Dictionary):
				return point.get("evidence","") in evidence or point.get("result","") == task.id
			return _next_task_points(matches)
	return []

func _next_task_points(matches: Callable) -> Array:
	var here: Array = points()
	var local := here.filter(matches)
	if not local.is_empty():
		return local
	var current: String = g.slot.world.area
	var phase_id := phase()
	var data: Script = REGIONS[region()]
	var visited := {current:true}
	var frontier := []
	for point in here:
		var next: String = point.get("destination","")
		if data.AREAS.has(next) and not visited.has(next):
			visited[next] = true
			frontier.append({"area":next,"first":point})
	while not frontier.is_empty():
		var exits := []
		var following := []
		for step in frontier:
			var available := _area_points(step.area,data.POINTS,phase_id)
			if available.any(matches):
				if not exits.has(step.first):
					exits.append(step.first)
				continue
			for point in available:
				var next: String = point.get("destination","")
				if data.AREAS.has(next) and not visited.has(next):
					visited[next] = true
					following.append({"area":next,"first":step.first})
		if not exits.is_empty():
			return exits
		frontier = following
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
	if g.field_key == "peak" and index == 1 and facts.has("mountain_medicine"):
		return {"ward":"wind","line":"药炉伤者把护脉药交给聂风，他带护持迎战雄霸。"}
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
