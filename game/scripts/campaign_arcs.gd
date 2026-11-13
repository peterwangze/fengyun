extends RefCounted

const ARCS := [
	{"id":"wedding","title":"天下会夜变","region":0},
	{"id":"fengxi","title":"凤溪风雨","region":1},
	{"id":"sword","title":"剑池初鸣","region":2},
	{"id":"return","title":"重返天下会","region":2,"requires":["lesson"],"room":"swordhall","marks":["lesson"],"campaign":{"sword":true},"cleared":[0,1]},
	{"id":"demon","title":"魔池照心","region":3},
	{"id":"palace","title":"无神绝宫","region":4},
	{"id":"dragon","title":"龙脉易手","region":5,"room":"cavern"},
	{"id":"blood","title":"雨夜换血","region":5,"requires":["shatter_relic"],"seen_at":["lodge"],"room":"cavern","marks":["relic","lost_relic","shatter_relic"]},
	{"id":"finale","title":"风云合璧","region":5,"campaign_event":"farewell","marks":["relic","lost_relic","shatter_relic","prepare","blood_rite"],"campaign":{"farewell":true}},
	{"id":"dawn","title":"凤溪灯明","region":5,"seen_at":["dawn"],"when_finished":true,"room":"dawn","marks":["relic","lost_relic","shatter_relic","prepare","blood_rite"],"campaign":{"farewell":true,"altar":true},"cleared":[0,1]},
]
const NUMBERS := ["壹","贰","叁","肆","伍","陆","柒","捌","玖","拾"]

static func index(slot: Dictionary) -> int:
	if slot.is_empty():
		return 0
	var region: int = slot.chapter
	var marks: Dictionary = slot.chronicle.marks
	var room: String = slot.chronicle.room
	var current := 0
	for at in ARCS.size():
		var arc: Dictionary = ARCS[at]
		if region < arc.region:
			break
		if region > arc.region:
			current = at
			continue
		var requirements: Array = arc.get("requires",[])
		if room in arc.get("seen_at",[]) or (arc.get("when_finished",false) and slot.finished):
			current = at
		elif arc.has("campaign_event"):
			if slot.campaign.get(arc.campaign_event,false):
				current = at
		elif not arc.has("when_finished") and requirements.all(func(mark): return marks.has(mark)):
			current = at
	return current

static func number(at: int) -> String:
	return NUMBERS[at] if at < NUMBERS.size() else str(at+1)

static func setup_review(slot: Dictionary, at: int) -> void:
	var arc: Dictionary = ARCS[at]
	slot.chronicle.room = arc.get("room","")
	slot.campaign.merge(arc.get("campaign",{}),true)
	slot.cleared.assign(arc.get("cleared",[]))
	for mark in arc.get("marks",[]):
		slot.chronicle.marks[mark] = true
