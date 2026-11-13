extends SceneTree

const Battle = preload("res://scripts/battle.gd")
const Equipment = preload("res://scripts/equipment.gd")
const Martial = preload("res://scripts/martial.gd")
const Save = preload("res://scripts/save.gd")

var failures := 0

func _initialize() -> void:
	_test_unlocks()
	_test_interrupt()
	_test_guard()
	_test_exploit()
	_test_quest_aid()
	_test_fire_elites()
	_test_demon()
	_test_golden_armor()
	print("Builds: %d failures" % failures)
	quit(1 if failures else 0)

func _slot() -> Dictionary:
	var slot := Save.new().fresh(false)
	slot.chapter = 2
	slot.merit = 12
	slot.chronicle.marks.lesson = true
	slot.chronicle.quests = {"courier":"done_quiet", "forgework":"done_rack"}
	return slot

func _battle(slot: Dictionary, party: Array, enemies: Array, rank: int) -> RefCounted:
	var prepared := {}
	var gear := {}
	var builds := {}
	for id in party:
		prepared[id] = Martial.prepared(slot, id)
		gear[id] = Equipment.modifiers(slot, id)
		builds[id] = Martial.synergies(slot, id, rank)
	return Battle.new(party, enemies, rank, 2, false, slot.chapter, slot.campaign.sword, prepared, true, gear, {}, builds)

func _test_unlocks() -> void:
	var slot := _slot()
	Equipment.assign(slot, "wind", 0, "travel_coat")
	Equipment.assign(slot, "wind", 1, "qi_ring")
	_check(Martial.synergies(slot, "wind", 1).is_empty(), "rank one keeps ordinary techniques and gear")
	_check(Martial.synergies(slot, "wind", 2) == {"interrupt":3}, "rank two opens interrupt with an appropriate technique and accessory")
	slot.chronicle.loadout.wind = [2, 0]
	_check(Martial.synergies(slot, "wind", 4) == {"interrupt":5, "retaliate":4}, "rank four strengthens both active effects")
	Equipment.assign(slot, "cloud", 1, "qi_ring")
	_check(Martial.synergy_text(slot, "wind", 4) == "守反", "transferring the only ring changes both tactical previews")
	_check(Martial.synergy_text(slot, "cloud", 4) == "截势", "recipient immediately sees the new style")
	slot.chronicle.loadout.cloud = [2, 1]
	_check(Martial.synergies(slot, "cloud", 4).is_empty(), "unequipped technique cannot enable interrupt")
	slot.chapter = 3
	slot.chronicle.loadout.wind = [2, 0]
	Equipment.assign(slot, "wind", 1, "ferry_knot")
	_check(Martial.synergies(slot, "wind", 4) == {"retaliate":4, "exploit":12}, "temporary Devil Blade is counted as the equipped heavy skill")

func _test_interrupt() -> void:
	var slot := _slot()
	Equipment.assign(slot, "wind", 1, "courier_badge")
	var battle := _battle(slot, ["wind", "cloud"], ["shade", "claw"], 2)
	var before: int = battle.allies[0].qi
	_check("截势回气 3" in battle.poise_preview(1, 0), "selected target previews the qualifying Qi refund")
	_check("截势" in battle.detail(1) and battle.act(1, 0) and battle.foes[0].broken, "weakness technique breaks a live scout with the signal badge")
	_check(battle.allies[0].qi == before - 7 + 3 and battle.synergy_feedback == "截势 · 回气 3", "interrupt refunds Qi on the successful break")
	var failed := _battle(slot, ["wind", "cloud"], ["gate_guard"], 4)
	failed.foes[0].poise = 3
	failed.foes[0].resolve = true
	var failed_qi: int = failed.allies[0].qi
	_check(failed.act(1, 0) and failed.foes[0].poise == 1 and failed.allies[0].qi == failed_qi - 7,
		"foe resolve prevents both break and the interrupt refund")

func _test_guard() -> void:
	var slot := _slot()
	Equipment.assign(slot, "cloud", 0, "forge_apron")
	slot.chronicle.loadout.cloud = [2, 0]
	var battle := _battle(slot, ["cloud", "wind"], ["blade", "claw", "gate_guard"], 4)
	var before: int = battle.allies[0].qi
	_check(battle.act(1, 0) and battle.act(3, 0), "set counter while the other fighter guards")
	_check(battle.bond == 2 and battle.allies[0].qi == before - 7 + 4 and "守反" in battle.synergy_feedback,
		"counter stance takes the forecast hit and gains one bond and 4 Qi despite multiple enemies")
	var missed := _battle(slot, ["cloud", "wind"], ["claw"], 4)
	_check(missed.act(1, 0) and missed.act(3, 0) and missed.bond == 1 and missed.synergy_feedback.is_empty(),
		"counter stance aimed at the wrong fighter has no affinity payoff")
	Equipment.assign(slot, "wind", 0, "travel_coat")
	slot.chronicle.loadout.wind = [2, 0]
	var cover := _battle(slot, ["wind", "cloud"], ["gate_guard"], 4)
	_check(not cover.valid_target(1, 0) and not cover.act(1, 0) and cover.act(1, 1) and cover.act(3, 0),
		"cover selects a teammate and reads the forecast instead of allowing self-target")
	_check(cover.allies[1].hp == cover.allies[1].max_hp and cover.bond == 2 and "守反" in cover.synergy_feedback,
		"cover takes the blow and grants the equipped defender's affinity")
	var protection := _battle(slot, ["wind", "cloud"], ["gate_guard"], 4)
	protection.apply_quest_aid({"ward":"cloud", "line":"药庐备了护持"})
	_check(protection.act(3, 0) and protection.act(3, 0) and protection.bond == 0 and protection.synergy_feedback.is_empty(),
		"an external ward and basic guard cannot trigger the prepared-technique reward")

func _test_exploit() -> void:
	var slot := _slot()
	Equipment.assign(slot, "wind", 1, "ferry_knot")
	var linked := _battle(slot, ["cloud", "wind"], ["gate_guard"], 4)
	var baseline := Battle.new(["cloud", "wind"], ["gate_guard"], 4, 2, false, 2, null, {}, true,
		{"wind":Equipment.modifiers(slot, "wind")})
	for battle in [linked, baseline]:
		battle.foes[0].poise = 2
		battle.foes[0].hp = 200
		battle.foes[0].max_hp = 200
		battle.act(1, 0)
		if battle == linked:
			_check("乘隙 +12" in battle.poise_preview(2, 0), "target preview shows the available follow-through and resource cost")
		battle.act(2, 0)
	_check(linked.foes[0].hp < baseline.foes[0].hp and linked.synergy_feedback == "乘隙 · 重招威力 +12",
		"partner opens a gap and the heavy technique exploits it")
	_check(linked.allies[1].qi == baseline.allies[1].qi - Martial.EXPLOIT_COST,
		"follow-through spends only the stated extra Qi")
	var strained := _battle(slot, ["wind", "cloud"], ["gate_guard"], 4)
	strained.foes[0].opening = 1
	strained.allies[0].qi = 11
	_check("另需 3 气" in strained.poise_preview(2, 0) and strained.act(2, 0) and strained.allies[0].qi == 0
		and strained.synergy_feedback.is_empty(), "a heavy strike can still be cast at its base cost without the affinity bonus")
	var unbroken := _battle(slot, ["wind", "cloud"], ["gate_guard"], 4)
	unbroken.foes[0].poise = 1
	_check(unbroken.act(2, 0) and unbroken.foes[0].broken and unbroken.synergy_feedback.is_empty(),
		"heavy strike does not get the payoff from a break it opens itself")

func _test_quest_aid() -> void:
	var battle := _battle(_slot(), ["cloud", "wind"], ["gate_guard", "claw"], 4)
	battle.apply_quest_aid({"foe":"claw", "poise":9, "ward":"wind", "bond":9, "line":"信使指出敌人的薄弱处。"})
	_check(battle.foes[0].poise == 5 and battle.foes[1].poise == 1 and not battle.foes[1].broken,
		"quest intelligence weakens just the named living enemy without an automatic break")
	_check(battle.bond == 4 and battle.allies[1].ward and battle.quest_aid_line in battle.log,
		"quest aid applies opening protection and capped bond with visible feedback")

func _test_fire_elites() -> void:
	var slot := _slot()
	var hold := _battle(slot, ["cloud", "wind"], ["duan"], 3)
	_check("引火" in hold.intent(hold.foes[0]) and "破势" in hold.tactical_hint(hold.presentation()),
		"Duan telegraphs the charge and explains how to stop it")
	hold.act(3, 0)
	hold.act(3, 0)
	_check(hold.foes[0].kindle and hold._pattern(hold.foes[0]) == "fire_sweep", "allowing the charge arms the next round's sweep")
	var control := _battle(slot, ["cloud", "wind"], ["duan"], 3)
	control.act(3, 0)
	control.act(3, 0)
	hold.act(3, 0)
	hold.act(3, 0)
	control.act(0, 0)
	control.act(0, 0)
	_check(hold.allies[0].hp > control.allies[0].hp and hold.allies[1].hp > control.allies[1].hp
		and not hold.foes[0].kindle, "ordinary guard softens the fire sweep for both fighters and the charge expires")
	Equipment.assign(slot, "wind", 1, "courier_badge")
	var breaker := _battle(slot, ["cloud", "wind"], ["duan"], 3)
	breaker.foes[0].poise = 4
	breaker.act(1, 0)
	var qi: int = breaker.allies[1].qi
	_check("截势回气 5" in breaker.poise_preview(1, 0), "interrupt style previews the extra Qi for stopping a boss windup")
	breaker.act(1, 0)
	_check(not breaker.foes[0].kindle and breaker.allies[1].qi == qi - 7 + 5 and "断浪引火被打断，火刃未能横扫。" in breaker.log,
		"breaking the windup prevents the sweep and awards the stated Qi")
	var elite := _battle(slot, ["cloud", "wind"], ["beast"], 3)
	_check(elite._pattern(elite.foes[0]) == "charge", "optional forge elite pressures immediately before it can light its weapon")
	elite.act(3, 0)
	elite.act(3, 0)
	_check(elite._pattern(elite.foes[0]) == "kindle", "the forge beast shares the charge-up system on an offset turn")
	var cavern := Battle.new(["cloud", "wind"], ["beast"], 5, 0, false, 5, true, {}, true)
	var easy := Battle.new(["cloud", "wind"], ["duan"], 3, 0, true, 2, false, {}, true)
	_check(cavern._pattern(cavern.foes[0]) != "kindle" and easy._pattern(easy.foes[0]) != "kindle",
		"cavern reuse and story difficulty keep their original behavior")

func _test_demon() -> void:
	var slot := _slot()
	slot.chapter = 3
	var pressured := _battle(slot, ["wind", "dream"], ["demon"], 4)
	var relieved := _battle(slot, ["wind", "dream"], ["demon"], 4)
	for battle in [pressured, relieved]:
		battle.corruption = 2
		battle.act(2, 0)
	_check("耗气" in pressured.intent(pressured.foes[0]) and "回春" in pressured.tactical_hint(pressured.presentation()),
		"building four corruption telegraphs a Qi-draining sweep before the partner acts")
	var qi: int = pressured.allies[0].qi
	pressured.act(0, 0)
	relieved.act(1, 0)
	_check(pressured.allies[0].qi == qi - 4 and relieved.allies[0].qi == qi and relieved.corruption == 1,
		"a reckless attack loses Qi while Dream's healing suppresses the special sweep")
	var guarded := _battle(slot, ["wind", "dream"], ["demon"], 4)
	guarded.corruption = 4
	guarded.act(3, 0)
	_check(guarded.corruption == 2 and guarded._pattern(guarded.foes[0]) != "mind_sweep", "Wind can also suppress the sweep by guarding")

func _test_golden_armor() -> void:
	var slot := _slot()
	slot.chapter = 4
	slot.campaign.sword = true
	var defended := _battle(slot, ["cloud", "sage"], ["godless"], 5)
	var reckless := _battle(slot, ["cloud", "sage"], ["godless"], 5)
	for battle in [defended, reckless]:
		battle.act(0, 0)
	_check("金身重击 › 无名" == defended.intent(defended.foes[0]), "the golden armor attack names its intended target")
	defended.act(3, 0)
	reckless.act(0, 0)
	_check(defended.foes[0].opening == 1 and reckless.foes[0].opening == 0,
		"guarding with the named target creates an armor gap on the next round")
	var guarded_before: int = defended.foes[0].hp
	var normal_before: int = reckless.foes[0].hp
	defended.act(1, 0)
	reckless.act(1, 0)
	_check(guarded_before - defended.foes[0].hp > normal_before - reckless.foes[0].hp,
		"the gap bypasses armor without relying on the equipped synergy or the combo")
	defended.act(3, 0)
	_check(defended.foes[0].opening == 0, "the guarded opening expires after its follow-through round")
	Equipment.assign(slot, "cloud", 1, "ferry_knot")
	Equipment.assign(slot, "sage", 0, "travel_coat")
	slot.chronicle.loadout.cloud = [0, 3]
	slot.chronicle.loadout.sage = [2, 0]
	var linked := _battle(slot, ["cloud", "sage"], ["claw"], 5)
	linked.act(0, 0)
	linked.act(1, 0)
	_check(linked.foes[0].opening == 1 and "守反" in linked.synergy_feedback, "equipped counter creates a follow-through opening on an ordinary foe")
	_check(linked.act(2, 0) and "乘隙" in linked.synergy_feedback, "the next partner exploits the opening from a defensive build")

func _check(passed: bool, description: String) -> void:
	print(("PASS " if passed else "FAIL ") + description)
	if not passed:
		failures += 1
