extends RefCounted

var a
var g

func _init(acceptance) -> void:
	a = acceptance
	g = a.game

func verify(settlement: String) -> bool:
	var origin: Vector2 = g.player
	match a.build_route:
		"interrupt", "retaliate":
			if not _three_districts(a.build_route == "retaliate"):
				return false
		"exploit":
			if not _two_support_routes():
				return false
		_:
			return _check(g.slot.world.tasks.keys().all(func(id): return id not in ["watch_medicine_pass", "palace_mooring", "mountain_beam", "sword_charcoal", "valley_herbs"]),
				"no-purchase main campaign completes without the optional district tasks")
	if not _check(g.world.leave() and g.afterstory.active and g.player.distance_to(origin) < 1.0,
		"leave the districts at the original Tidegate position"):
		return false
	return _check(g.storage.read().afterstory.resolution == settlement,"district choices preserve the original Tidegate settlement")

func _three_districts(covered: bool) -> bool:
	if not _travel("outer_watch") or not _path(["world_watch_to_market","world_watch_pass_roster","world_watch_market_to_scree",
		"world_watch_pass_track","world_watch_scree_to_market","world_watch_market_to_dispatch","world_watch_pass_order"]):
		return false
	a._choose(int(covered))
	if covered and not _path(["world_watch_dispatch_to_market","world_watch_market_to_scree"]):
		return false
	if not covered and not _path(["world_watch_pass_dispatch","world_watch_pass_followthrough"]):
		return false
	if covered and not _path(["world_watch_pass_covered","world_watch_pass_covered","world_watch_pass_followthrough"]):
		return false
	if not _travel("palace") or not _path(["world_palace_to_quay","world_palace_mooring_roster","world_palace_quay_to_store",
		"world_palace_mooring_seal","world_palace_mooring_choice"]):
		return false
	a._choose(0 if covered else 1)
	if not a._do_point("world_palace_store_to_quay"):
		return false
	if covered:
		if not a._do_point("world_palace_mooring_receipt_ration"):
			return false
	elif not _path(["world_palace_quay_to_reeds","world_palace_mooring_receipt_sealed","world_palace_sealed_to_store"]):
		return false
	if not _travel("mountain") or not _path(["world_mountain_hearth","world_mountain_foothill","world_foothill_refuge",
		"world_refuge_beam","world_refuge_foothill","world_foothill_ridge","world_ridge_beam","world_ridge_foothill",
		"world_foothill_refuge","world_refuge_beam_choice"]):
		return false
	a._choose(int(covered))
	if not _path(["world_refuge_foothill","world_foothill_ridge","world_ridge_steps_shelter" if covered else "world_ridge_steps_bridge",
		"world_steps_beam_receipt"]):
		return false
	if not _travel("fengxi") or not _path(["homecoming_evidence","homecoming_care","homecoming_work"]):
		return false
	var facts: Dictionary = g.storage.read().world.tasks
	var records: Array = g.world.finale_rows().map(func(row: Array): return row[0])
	print("DISTRICTS Watch=%s Palace=%s Lingyun=%s" % [facts.get("watch_medicine_pass"),facts.get("palace_mooring"),facts.get("mountain_beam")])
	return _check(["岗下驿户","苇津渡工","竹井木匠"].all(func(name): return name in records),
		"all three district receipts reach their actual Fengxi homecoming sites")

func _two_support_routes() -> bool:
	if not _travel("swordhall") or not _path(["world_sword_hamlet","world_sword_charcoal_mark","world_sword_charcoal_sample",
		"world_sword_hamlet_return","world_sword_charcoal_turnin","world_sword_hamlet","world_sword_charcoal_receipt",
		"world_sword_hamlet_to_road","world_sword_road_to_hamlet"]):
		return false
	if not _travel("valley") or not _path(["world_valley_to_herbs","world_valley_herb_stone","world_valley_herb_tag",
		"world_herbs_to_valley","world_valley_herb_report","world_valley_to_herbs","world_herbs_to_trestle",
		"world_trestle_to_herbs","world_valley_herb_followthrough"]):
		return false
	var facts: Dictionary = g.storage.read().world.tasks
	return _check(facts.has("sword_charcoal_receipt") and facts.has("valley_herbs_receipt"),"both workshop support routes reach actual postgame receipts")

func _travel(id: String) -> bool:
	a._key(KEY_M)
	if not _check(g.mode == "world_map","normal atlas opens for " + id):
		return false
	var row: int = g.world.destinations().find_custom(func(region: Dictionary): return region.id == id)
	a._select_menu_row(row)
	return _check(g.world.active() and g.world.region() == id,"enter " + id + " via the atlas")

func _path(ids: Array) -> bool:
	for id in ids:
		if not a._do_point(id):
			return false
	return true

func _check(value: bool, message: String) -> bool:
	return a._check(value,"DISTRICTS " + message)
