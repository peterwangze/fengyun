extends RefCounted

const CACHES := {
	"garden": {"pos":Vector2(488,258),"name":"查看竹旁的旧行囊"},
	"inn": {"pos":Vector2(516,251),"name":"翻看客栈药匣"},
}
const SEAL_CHASE := ["客栈截印", ["shade","blade"], [
	["秦霜","那人用木模仿刻缺角印。后窗直通河岸，刀客一拦，他就会带假印逃走。"],
	["聂风","先拦住密探。第二回合起，他能出手就会逃。破势能让我们多争取一回合。"],
]]

static func objective(g: Node2D) -> String:
	if g.afterstory.active:
		return g.afterstory.objective()
	var field: String = g.field_key
	var f: Dictionary = g.slot.campaign
	var won: Array = g.slot.cleared
	if field == "village" and f.crossing.is_empty():
		var bridge := "过石桥" if won.has(0) else "打石桥守卫"
		if not f.rope: return "%s，或到东边船埠解缆。" % bridge
		if not g.campaign.ferry_ready(): return "%s，或靠近船家护送登船。" % bridge
		return "%s，或去旧船埠登船。" % bridge
	if field == "forge":
		if not won.has(0): return "先击退西岸剑徒，再穿过剑池。"
		if f.forge_route.is_empty():
			return "走泄火主桥，或从北侧石栈绕行。" if f.forge_gate else "开泄火闸过桥，或绕北侧石栈。"
		if not won.has(1): return "去东岸击败断浪，取绝世好剑。"
	if field == "apothecary" and g.chronicle.has("pool_intro"):
		return "从药庐南门回魔池。" if f.pool_trial else "从药庐南门回魔池，到池边试刀。"
	if field == "pool" and won.has(1) and g.chronicle.enabled():
		if not g.chronicle.has("pool_gate"): return "到东岸木栅前，用刀气开路。"
		if not g.chronicle.has("pool_escape"): return "穿过木栅，在东岸接应第二梦。"
		return "从魔池东侧山路前往无神绝宫。"
	var chapter_hint: String = g.chronicle.objective()
	if not chapter_hint.is_empty():
		return chapter_hint
	return g.first.objective() if g.first.active() else g.campaign.objective()

static func main_point(g: Node2D, points: Array) -> Dictionary:
	var candidates := main_points(g, points)
	return candidates.front() if not candidates.is_empty() else {}

static func main_points(g: Node2D, points: Array) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	var paths := _walking_targets(g)
	for id in _next_ids(g):
		if paths.has(id):
			candidates.append(paths[id])
			continue
		for point in points:
			var point_id: String = "fight%d" % point.index if point.id == "fight" else point.id
			if point_id == id:
				candidates.append(point)
				break
	return candidates

static func _walking_targets(g: Node2D) -> Dictionary:
	match g.field_key:
		"village":
			return {"stone_bridge":_route("stone_bridge", "走石桥到西岸", Vector2(320,200)),
				"escort_boatman":_route("escort_boatman", "靠近船家并护送", g.campaign.boatman, false)}
		"forge":
			return {"sluice_bridge":_route("sluice_bridge", "走泄火主桥", Vector2(320,193)),
				"north_ledge":_route("north_ledge", "沿北侧石栈绕行", Vector2(320,114))}
	return {}

static func _route(id: String, name: String, pos: Vector2, ground_marker: bool = true) -> Dictionary:
	return {"id":id,"name":name,"pos":pos,"ground_marker":ground_marker}

static func _next_ids(g: Node2D) -> Array:
	var c: RefCounted = g.chronicle
	var f: Dictionary = g.slot.campaign
	var won: Array = g.slot.cleared
	if g.afterstory.active:
		var a: Dictionary = g.afterstory.state()
		if a.resolution != "": return []
		if g.field_key == "tidal_fort":
			if a.route == "gate" and not a.gate: return ["gate"]
			if not a.chief: return ["chief"]
			return ["return_ford"] if a.ledger else ["ledger"]
		if not a.brief: return ["brief"]
		if not a.register or not a.seal: return ["register", "seal"]
		if a.ledger: return ["report"]
		if a.route != "": return ["sluice_entry"] if a.route == "sluice" else ["gate_entry"]
		return ["gate_entry", "sluice_entry" if a.sluice else "sluice"]
	match g.field_key:
		"hall":
			if c.enabled() and not c.has("spar"): return ["spar"]
			if not won.has(0): return ["fight0"]
			if not g.slot.hall.wedding: return ["banquet_door"]
			return ["exit"] if won.has(1) else ["fight1", "banquet_door"]
		"banquet":
			if g.slot.hall.wedding: return ["court_door", "garden_door"]
			return ["kindness"] if c.enabled() and not c.has("kindness") else ["ceremony"]
		"garden": return ["escape_door"]
		"village":
			if f.crossing.is_empty():
				var ferry := "mooring" if not f.rope else ("board" if g.campaign.ferry_ready() else "escort_boatman")
				return ["stone_bridge" if won.has(0) else "fight0", ferry]
			if c.enabled() and (not c.has("ferry_evidence") or (won.has(1) and not c.has("dream_intro"))): return ["inn"]
			if not won.has(1): return ["fight1"]
			return ["exit"] if f.reunion else ["reunion"]
		"inn":
			if not c.has("ferry_evidence"): return ["ferry_evidence"]
			return ["dream_intro"] if won.has(1) and not c.has("dream_intro") else ["inn_exit"]
		"forge":
			if f.sword: return ["exit"]
			if won.has(1): return ["sword"]
			if not won.has(0): return ["fight0"]
			if f.forge_route.is_empty(): return ["sluice_bridge" if f.forge_gate else "winch", "north_ledge"]
			return ["fight1"]
		"swordhall": return ["returnhall"] if c.has("lesson") else ["lesson"]
		"returnhall": return ["first_tyrant", "retreat_choice", "invaded", "leave_hall"]
		"pool":
			if c.enabled() and not c.has("pool_intro"): return ["apothecary"]
			if not f.pool_trial: return ["pool_trial"]
			if not won.has(0): return ["fight0"]
			if not won.has(1): return ["fight1"]
			if not c.enabled() or c.has("pool_escape"): return ["exit"]
			return ["pool_escape"] if c.has("pool_gate") else ["pool_gate"]
		"apothecary": return ["pool_back"] if c.has("pool_intro") else ["pool_intro"]
		"palace":
			if not f.rescued: return ["jail_door"] if won.has(0) else ["fight0"]
			if c.enabled() and (not c.has("tea") or won.has(1) and not c.has("evacuated")): return ["tearoom"]
			return ["exit"] if won.has(1) else ["fight1"]
		"jail": return ["jail_exit"] if f.rescued else ["cell"]
		"tearoom":
			if f.rescued and not c.has("tea"): return ["tea"]
			if won.has(1) and not c.has("evacuated"): return ["evacuated"] if c.has("fire_signal") else ["fire_signal"]
			return ["palace_back"]
		"cavern": return ["relic", "lost_relic", "shatter_relic", "prepare", "lodge"]
		"lodge": return ["blood_rite"] if c.enabled() and not c.has("blood_rite") else ["bedside"]
		"peak":
			if not won.has(0): return ["fight0"]
			if not f.altar: return ["altar"]
			return ["exit"] if won.has(1) else ["fight1"]
		"dawn": return ["dawn_exit"] if c.has("dawn_lamp") else ["dawn_lamp"]
	return []
