extends RefCounted

const Timber = preload("res://scripts/corridor_timber.gd")
const River = preload("res://scripts/corridor_river.gd")
const Relief = preload("res://scripts/corridor_relief.gd")
const TASKS := {"timber":Timber.TASK,"river":River.TASK,"relief":Relief.TASK}
const POINTS := Timber.POINTS + River.POINTS + Relief.POINTS
const LABELS := ["可接洽","待议走法","途中交接","待点收","战后回访","待收回单","已收回单"]

static func register(known: Dictionary, slot: Dictionary) -> bool:
	var facts: Dictionary = slot.world.tasks
	for task in TASKS.values():
		for i in task.stages.size():
			var id: String = task.stages[i]
			known[id] = task.variants.keys() if i == 1 else [true]
			if not facts.has(id):
				continue
			if slot.chapter < task.start_chapter or (i > 0 and not facts.has(task.stages[i - 1])):
				return false
			if i >= 3 and slot.chapter < task.delivery_chapter:
				return false
			if i >= 4 and not slot.finished:
				return false
			if not task.get("stage_needs",{}).get(id,[]).all(func(required): return facts.has(required)):
				return false
		for id in task.get("extra",{}):
			known[id] = [true]
			if facts.has(id) and (slot.chapter < task.start_chapter or not task.extra[id].all(func(previous): return facts.has(previous))):
				return false
	return _valid_finale(slot,facts)

static func _valid_finale(slot: Dictionary, facts: Dictionary) -> bool:
	var snapshot: Variant = slot.world.get("corridor_finale",{})
	if not snapshot is Dictionary:
		return false
	if not snapshot.is_empty() and (slot.chapter != 5 or not slot.cleared.any(func(index): return int(index) == 1)):
		return false
	for id in snapshot:
		var task: Dictionary = TASKS.get(id,{})
		if task.is_empty() or not task.variants.has(snapshot[id]):
			return false
		if not facts.has(task.stages[3]) or facts.get(task.stages[1]) != snapshot[id]:
			return false
	return true

static func deliveries(slot: Dictionary) -> Dictionary:
	var result := {}
	var facts: Dictionary = slot.world.tasks
	for id in TASKS:
		var task: Dictionary = TASKS[id]
		if facts.has(task.stages[3]) and task.variants.has(facts.get(task.stages[1])):
			result[id] = facts[task.stages[1]]
	return result

static func opening(slot: Dictionary) -> Array:
	var result := []
	var arrived := deliveries(slot)
	for id in arrived:
		result.append(TASKS[id].variants[arrived[id]].aid)
	return result

static func ending(slot: Dictionary) -> Array:
	var result := []
	var snapshot: Dictionary = slot.world.get("corridor_finale",{})
	for id in TASKS:
		if snapshot.has(id):
			result.append(["尾声",TASKS[id].variants[snapshot[id]].ending])
	return result

static func stage(task: Dictionary, facts: Dictionary) -> int:
	for index in task.stages.size():
		if not facts.has(task.stages[index]):
			return index
	return task.stages.size()

static func goal(task: Dictionary, slot: Dictionary) -> String:
	var index := stage(task,slot.world.tasks)
	if index == task.stages.size() or (index >= 4 and not slot.finished):
		return ""
	return task.stages[index]
