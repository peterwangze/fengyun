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
	var chapter_hint: String = g.chronicle.objective()
	if not chapter_hint.is_empty():
		return chapter_hint
	return g.first.objective() if g.first.active() else g.campaign.objective()

static func main_point(g: Node2D, points: Array) -> Dictionary:
	for id in _next_ids(g):
		for point in points:
			var point_id: String = "fight%d" % point.index if point.id == "fight" else point.id
			if point_id == id:
				return point
	return {}

static func _next_ids(g: Node2D) -> Array:
	var c: RefCounted = g.chronicle
	var f: Dictionary = g.slot.campaign
	var won: Array = g.slot.cleared
	if g.afterstory.active:
		var a: Dictionary = g.afterstory.state()
		if a.resolution != "": return []
		if g.field_key == "tidal_fort": return ["gate", "chief", "ledger", "return_ford"]
		if not a.brief: return ["brief"]
		if not a.register or not a.seal: return ["register", "seal"]
		return ["report", "sluice_entry", "gate_entry"] if a.route != "" else []
	match g.field_key:
		"hall":
			if c.enabled() and not c.has("spar"): return ["spar"]
			if not won.has(0): return ["fight0"]
			if not g.slot.hall.wedding: return ["banquet_door"]
			return ["exit"] if won.has(1) else ["fight1"]
		"banquet":
			if g.slot.hall.wedding: return []
			return ["kindness", "ceremony"]
		"garden": return ["escape_door"]
		"village":
			if f.crossing.is_empty(): return ["board", "fight0"] if f.rope else []
			if c.enabled() and (not c.has("ferry_evidence") or (won.has(1) and not c.has("dream_intro"))): return ["inn"]
			return ["fight1", "reunion", "exit"]
		"inn": return ["ferry_evidence", "dream_intro", "inn_exit"]
		"forge":
			if f.sword: return ["exit"]
			if won.has(1): return ["sword"]
			if f.forge_gate or not f.forge_route.is_empty(): return ["fight0", "fight1"]
			return []
		"swordhall": return ["lesson", "returnhall"]
		"returnhall": return ["first_tyrant", "retreat_choice", "invaded", "leave_hall"]
		"pool":
			if c.enabled() and not c.has("pool_intro"): return ["apothecary"]
			if not f.pool_trial: return ["pool_trial"]
			if not won.has(1): return ["fight0", "fight1"]
			return ["pool_gate", "pool_escape", "exit"]
		"apothecary": return ["pool_intro", "pool_back"]
		"palace":
			if not f.rescued: return ["jail_door"] if won.has(0) else ["fight0"]
			if c.enabled() and (not c.has("tea") or won.has(1) and not c.has("evacuated")): return ["tearoom"]
			return ["fight1", "exit"]
		"jail": return ["cell", "jail_exit"]
		"tearoom": return ["tea", "fire_signal", "evacuated", "palace_back"]
		"cavern": return ["relic", "lost_relic", "shatter_relic", "prepare", "lodge"]
		"lodge": return ["blood_rite", "bedside"]
		"peak": return ["fight0", "altar", "fight1", "exit"]
		"dawn": return ["dawn_lamp", "dawn_exit"]
	return []
