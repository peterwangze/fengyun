extends SceneTree

const Battle = preload("res://scripts/battle.gd")
const Economy = preload("res://scripts/economy.gd")
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
	_test_dragon_current()
	_test_final_tyrant()
	_test_tidal_formation()
	_test_manual_catalog()
	_test_new_gear()
	_test_new_manual_actions()
	_test_forged_loadouts()
	_test_cultivation()
	_test_masteries()
	_test_exclusive_gear_branches()
	_test_advancement_save_migration()
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
	var training := {}
	for id in party:
		prepared[id] = Martial.prepared(slot, id)
		gear[id] = Equipment.modifiers(slot, id)
		builds[id] = Martial.synergies(slot, id, rank)
		training[id] = Martial.training(slot, id, rank)
	return Battle.new(party, enemies, rank, 2, false, slot.chapter, slot.campaign.sword, prepared, true, gear, {}, builds, training)

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

func _late_battle(enemies: Array, easy: bool = false) -> RefCounted:
	var slot := _slot()
	slot.chapter = 5
	slot.merit = 24
	slot.campaign.sword = true
	slot.chronicle.loadout.cloud = [0, 3]
	Equipment.assign(slot, "cloud", 1, "ferry_knot")
	Equipment.assign(slot, "wind", 1, "courier_badge")
	if not easy:
		return _battle(slot, ["wind", "cloud"], enemies, 6)
	return Battle.new(["wind", "cloud"], enemies, 6, 2, true, 5, true, {}, true)

func _has_phase_event(battle: RefCounted, caption: String) -> bool:
	return battle.events.any(func(event: Dictionary): return event.get("phase_change", false) and event.text == caption)

func _test_dragon_current() -> void:
	var guarded := _late_battle(["dragon"])
	_check(guarded._pattern(guarded.foes[0]) == "dragon_draw" and "阻止逆流" in guarded.tactical_hint(guarded.presentation()),
		"the dragon telegraphs its charge before the counterplay window")
	var cavern := _late_battle(["beast", "shade"])
	_check(cavern._pattern(cavern.foes[0]) == "charge", "the earlier cavern encounter starts with a distinct pressure turn")
	guarded.act(3, 0)
	guarded.act(3, 0)
	_check(guarded.foes[0].flow and _has_phase_event(guarded, "龙息蓄起") and guarded.presentation().foe[0].phase_label == "龙息逆流",
		"the phase announcement and presentation track the armed reversal")
	guarded.act(3, 0)
	guarded.act(3, 0)
	_check(guarded.foes[0].opening == 1 and not guarded.foes[0].flow and _has_phase_event(guarded, "龙息散去"),
		"ordinary guards endure the reversal and expose an opening for the next round")
	guarded.act(0, 0)
	_check(guarded.act(2, 0) and "乘隙" in guarded.synergy_feedback, "the companion can exploit the protected dragon opening")
	var interrupt := _late_battle(["dragon"])
	interrupt.foes[0].poise = 2
	_check("截势回气 7" in interrupt.poise_preview(1, 0), "the forecast includes the affinity's extra return for stopping dragon breath")
	interrupt.act(1, 0)
	_check(interrupt.foes[0].broken and not interrupt.foes[0].flow and _has_phase_event(interrupt, "龙息中断"),
		"an actual break cancels the charge and emits the interruption cue")
	var easy := _late_battle(["dragon"], true)
	_check(easy._pattern(easy.foes[0]) == "charge" and easy.presentation().foe[0].phase_label.is_empty(),
		"story difficulty retains the familiar dragon behavior")

func _test_final_tyrant() -> void:
	var combo := _late_battle(["boss"])
	var poise := _late_battle(["boss"])
	for battle in [combo, poise]:
		var boss: Dictionary = battle.foes[0]
		_check("归元掌 › 步惊云" == battle.intent(boss), "the opening palm explicitly names its target")
		boss.hp = boss.max_hp / 2 + 1
		battle.act(0, 0)
		_check(boss.shield and _has_phase_event(battle, "三分归元气"), "crossing half health visibly enters the shield phase")
	combo.bond = 4
	combo.act(5, 0)
	_check(not combo.foes[0].shield and combo.shield_resolution == "combo" and _has_phase_event(combo, "归元气破"),
		"the party combo breaks the shield directly and retains the ending resolution flag")
	var armored: Dictionary = poise.foes[0]
	armored.poise = 1
	poise.act(0, 0)
	_check(armored.shield and armored.cracks == 1, "one break leaves a visible crack in the shield")
	poise.act(3, 0)
	poise.act(3, 0)
	_check(armored.shield and armored.cracks == 1 and not armored.resolve, "the recovery round cannot count as a second break")
	armored.poise = 1
	poise.act(0, 0)
	_check(not armored.shield and armored.cracks == 2 and poise.shield_resolution == "poise" and _has_phase_event(poise, "归元气破"),
		"a later break clears the shield independently of the combo")
	var guarded := _late_battle(["boss"])
	guarded.act(0, 0)
	guarded.act(3, 0)
	_check(guarded.foes[0].opening == 1 and guarded.allies[1].hp < guarded.allies[1].max_hp,
		"taking the opening palm under guard creates a real damage window")

func _test_tidal_formation() -> void:
	var defended := _late_battle(["tidal_chief", "tidal_drum"])
	var stopped := _late_battle(["tidal_chief", "tidal_drum"])
	for battle in [defended, stopped]:
		battle.act(3, 0)
		battle.act(3, 0)
		_check(battle.foes[0].formation and _has_phase_event(battle, "鼓令成阵") and "鼓令突进 › 聂风" == battle.intent(battle.foes[0]),
			"the first drum order visibly primes a named next-round target")
	stopped.foes[1].poise = 1
	stopped.act(1, 1)
	_check(not stopped.foes[0].formation and not stopped.foes[0].rallied and _has_phase_event(stopped, "鼓令瓦解"),
		"breaking the drummer cancels the already armed formation and its damage shield")
	defended.act(3, 0)
	defended.act(3, 0)
	_check(defended.foes[0].opening == 1 and not defended.foes[0].formation and _has_phase_event(defended, "鼓令散去"),
		"protecting the marked ally answers the charge and creates a counterattack window")
	var chief := _late_battle(["tidal_chief", "tidal_drum"])
	chief.foes[0].poise = 1
	chief.act(0, 0)
	chief.act(3, 0)
	_check(not chief.foes[0].formation, "breaking the chief before the drummer acts prevents rally from arming")
	var kill := _late_battle(["tidal_chief", "tidal_drum"])
	kill.act(3, 0)
	kill.act(3, 0)
	kill.foes[1].hp = 1
	kill.act(0, 1)
	_check(not kill.foes[0].formation and kill.presentation().foe[0].phase_label == "韩朔独战", "defeating the drummer removes the coordination mechanic")

func _test_manual_catalog() -> void:
	var slot := _slot()
	var legacy_wind: Array = Martial.options("wind", false).slice(0, 4)
	_check(Martial.move_count("wind") == 5 and legacy_wind[0][0] == "风神腿" and legacy_wind[3][0] == "回风腿",
		"the fifth technique appends without changing old saved move indices")
	_check(not Martial.unlocked(slot, "wind", 4) and not Martial.unlocked(slot, "wind", 5) and not Martial.unlocked(slot, "unknown", 0),
		"old or invalid technique records cannot equip a learned-only move")
	slot.manual_grants = Martial.clean_grants({"crosswind":true, "moon_needle":false, "unknown":true})
	_check(slot.manual_grants == {"crosswind":true} and Martial.unlocked(slot, "wind", 4) and not Martial.unlocked(slot, "dream", 4),
		"manual validation learns only the named hero technique and drops unknown ids")
	slot.chronicle.loadout.wind = [4, 1]
	_check(Martial.prepared(slot, "wind") == [4, 1] and Martial.source("wind", 4) == "凤溪客栈截印",
		"the normal loadout and source lookup support the new technique")

func _test_new_gear() -> void:
	var slot := _slot()
	_check(Equipment.options(0).size() == 9 and Equipment.options(1).size() == 9 and not Equipment.unlocked(slot, "reed_mantle"),
		"the equipment list exposes all sixteen items and keeps unearned pieces locked")
	slot.gear_grants = Equipment.clean_grants({"reed_mantle":true, "tide_whistle":true, "sword_tassel":true,
		"granary_vest":true, "apothecary_gourd":true, "travel_coat":true, "forge_guard":false, "unknown":true})
	_check(slot.gear_grants.size() == 5 and not Equipment.unlocked(slot, "forge_guard"), "only valid newly owned pieces become entitlements")
	Equipment.assign(slot, "wind", 0, "reed_mantle")
	Equipment.assign(slot, "wind", 1, "tide_whistle")
	Equipment.assign(slot, "cloud", 0, "granary_vest")
	Equipment.assign(slot, "cloud", 1, "sword_tassel")
	slot.chronicle.loadout.cloud = [0, 3]
	_check(Martial.synergies(slot, "wind", 4).has("interrupt") and Martial.synergies(slot, "cloud", 4).has("exploit"),
		"the acquired accessories work as alternatives in the existing style system")
	var armor := _battle(slot, ["wind", "cloud"], ["gate_guard"], 4)
	var before_wind: int = armor.allies[0].hp
	var before_cloud: int = armor.allies[1].hp
	armor._hurt_ally(0, 20, 0, "dark", 0, "sweep")
	armor._hurt_ally(1, 20, 0, "dark", 0, "sweep")
	_check(armor.allies[0].hp == before_wind - 14 and armor.allies[1].hp == before_cloud - 20,
		"reed mantle protects against sweeps and heavy-only armor does not")
	armor._hurt_ally(1, 20, 0, "cloud", 0, "tyrant_palm")
	_check(armor.allies[1].hp == before_cloud - 32, "warehouse vest protects against a targeted heavy technique")
	Equipment.assign(slot, "wind", 1, "apothecary_gourd")
	var warded := _battle(slot, ["wind", "cloud"], ["gate_guard"], 4)
	warded.apply_quest_aid({"ward":"wind"})
	var before_ward: int = warded.allies[0].hp
	warded._hurt_ally(0, 20, 0, "blade", 0)
	warded._hurt_ally(0, 20, 0, "blade", 0)
	_check(warded.allies[0].hp == before_ward - 5 - 20, "gourd only boosts absorption while a ward is consumed")

func _test_new_manual_actions() -> void:
	var slot := _slot()
	slot.manual_grants = {"crosswind":true, "cloud_return":true, "frost_gate":true, "moon_needle":true, "sword_trace":true}
	for id in ["wind", "cloud", "frost", "dream", "sage"]:
		slot.chronicle.loadout[id] = [4, 0]
	var wind := _battle(slot, ["wind", "cloud"], ["duan"], 4)
	_check("势 6 → 3" == wind.poise_preview(1, 0) and wind.act(1, 0) and wind.foes[0].poise == 3,
		"Crosswind's windup bonus is identical in preview and execution")
	var chill := _battle(slot, ["frost", "wind"], ["claw"], 4)
	chill.foes[0].poise = 3
	_check(chill.act(1, 0) and chill.foes[0].broken and chill.allies[1].ward and not chill.allies[0].ward,
		"Frost Gate wards its companion only on an actual live-enemy break")
	var cloud := _battle(slot, ["wind", "cloud"], ["gate_guard"], 4)
	slot.gear_grants = {"forge_guard":true}
	Equipment.assign(slot, "cloud", 0, "forge_guard")
	var braced := _battle(slot, ["wind", "cloud"], ["gate_guard"], 4)
	for battle in [cloud, braced]:
		battle.act(3, 0)
		battle.act(1, 0)
	_check(braced.foes[0].poise == 2 and cloud.foes[0].poise == 2 and braced.foes[0].hp < cloud.foes[0].hp,
		"counter manual deals three poise and the forge gear independently raises counter damage")
	slot.chapter = 3
	var healer := _battle(slot, ["dream", "wind"], ["demon"], 4)
	healer.allies[1].hp -= 40
	healer.allies[1].qi = 5
	healer.corruption = 4
	_check(healer.targets_ally(1) and healer.act(1, 1) and healer.allies[1].hp == healer.allies[1].max_hp - 14
		and healer.allies[1].qi == 11 and healer.corruption == 2,
		"Needle Transfer targets a partner, healing and restoring Qi while lowering corruption")
	slot.chapter = 4
	var sword := _battle(slot, ["sage", "cloud"], ["godless"], 4)
	var plain := Battle.new(["sage", "cloud"], ["godless"], 4, 2, false, 4, true, {}, true)
	sword.act(1, 0)
	plain.act(1, 0)
	_check(sword.foes[0].hp < plain.foes[0].hp and sword.foes[0].poise > plain.foes[0].poise,
		"Sword Trace increases damage through armor in exchange for weaker break pressure")

func _test_forged_loadouts() -> void:
	var slot := _slot()
	slot.gear_grants = {"reed_mantle":true, "tide_whistle":true, "sword_tassel":true, "forge_guard":true}
	Equipment.assign(slot, "wind", 0, "reed_mantle")
	Equipment.assign(slot, "wind", 1, "tide_whistle")
	Equipment.assign(slot, "cloud", 0, "forge_guard")
	Equipment.assign(slot, "cloud", 1, "sword_tassel")
	slot.chronicle.loadout.cloud = [2, 3]
	var stock := _battle(slot, ["wind", "cloud"], ["gate_guard"], 4)
	_check(Equipment.level(slot, "tide_whistle") == 0 and Equipment.modifiers(slot,"wind").qi == 4,
		"old gear without a forge record retains original stats")
	slot.gear_levels = Equipment.clean_levels(slot, {"reed_mantle":2.0, "tide_whistle":2, "sword_tassel":9,
		"forge_guard":1, "granary_vest":2, "travel_coat":2, "unknown":2})
	_check(slot.gear_levels == {"reed_mantle":2, "tide_whistle":2, "sword_tassel":2, "forge_guard":1},
		"normalization limits levels to forgeable owned items and clamps the maximum")
	_check(Equipment.clean_levels(slot, {"tide_whistle":1.25, "reed_mantle":true}).is_empty(),
		"malformed level values do not unlock tiers")
	_check(Equipment.display_name(slot,"tide_whistle") == "渡口铜哨 +2" and "截势回气 +1" in Equipment.describe("tide_whistle", 2)
		and Equipment.upgrade_description("tide_whistle", 1) == "真气 +2",
		"the name, current modifiers and exact next gain can be shown separately")
	var forged := _battle(slot, ["wind", "cloud"], ["gate_guard"], 4)
	_check(forged.allies[0].max_qi == stock.allies[0].max_qi + 2 and forged.allies[0].build.interrupt == 6,
		"the forged whistle adds base Qi then enhances the equipped interrupt build")
	for encounter in [stock, forged]:
		encounter.foes[0].hp = 280
		encounter.foes[0].max_hp = 280
		encounter.foes[0].poise = 1
		encounter.act(1, 0)
	_check(forged.synergy_feedback == "截势 · 回气 6" and stock.synergy_feedback == "截势 · 回气 5",
		"the combat action receives exactly the forged interrupt refund")
	for encounter in [stock, forged]:
		encounter.act(2, 0)
	_check(forged.foes[0].hp < stock.foes[0].hp and forged.allies[1].build.exploit == stock.allies[1].build.exploit,
		"the sword tassel improves broken-target damage without increasing the build bonus")
	var protected := _battle(slot, ["wind", "cloud"], ["gate_guard"], 4)
	var before: int = protected.allies[0].hp
	protected._hurt_ally(0, 20, 0, "dark", 0, "sweep")
	protected._hurt_ally(0, 20, 0, "blade", 0, "strike")
	_check(protected.allies[0].hp == before - 10 - 20,
		"reinforced mantle helps against a sweep without weakening ordinary attacks")
	Equipment.assign(slot, "cloud", 1, "tide_whistle")
	_check(Equipment.level(slot, "tide_whistle") == 2 and Equipment.modifiers(slot,"cloud").interrupt_qi == 1
		and not Equipment.modifiers(slot,"wind").has("interrupt_qi"), "reinforcement follows the unique item when transferred")

func _test_cultivation() -> void:
	var slot := _slot()
	slot.chapter = 5
	slot.campaign.sword = true
	slot.chronicle.loadout.cloud = [2, 1]
	slot.chronicle.loadout.frost = [2, 3]
	slot.chronicle.loadout.sage = [0, 2]
	slot.chronicle.loadout.wind = [0, 2]
	slot.cultivation = Martial.clean_cultivation({"wind":"wind_seek", "cloud":"wind_cover", "unknown":"unknown"})
	_check(slot.cultivation == {"wind":"wind_seek"} and Martial.cultivation_choice(slot,"wind",2).is_empty(),
		"stance validation rejects another hero's style and rank two cannot use cultivation")
	var seek := _battle(slot,["wind","cloud"],["dragon"],3)
	var seek_qi: int = seek.allies[0].qi
	seek.act(1,0)
	_check(seek.allies[0].qi == seek_qi - 5 and "逐风 · 回气 2" in seek.log, "Wind's Seeking stance rewards a wind attack against a telegraph")
	slot.cultivation = {"wind":"wind_cover", "cloud":"cloud_counter"}
	var cover := _battle(slot,["wind","cloud"],["gate_guard"],3)
	var cover_qi: int = cover.allies[0].qi
	cover.act(2,1)
	cover.act(3,0)
	_check(cover.allies[0].qi == cover_qi - 4 and "护风 · 回气 3" in cover.log, "Wind's Cover stance recovers Qi for actually redirecting a hit")
	var cloud := _battle(slot,["wind","cloud"],["gate_guard"],3)
	cloud.act(3,0)
	cloud.act(1,0)
	_check(cloud.foes[0].poise == 3 and "凝云 · 反击削势 +1" in cloud.log, "Cloud's counter stance increases retaliatory poise loss")
	slot.cultivation = {"cloud":"cloud_pursuit"}
	var pursuit := _battle(slot,["cloud","wind"],["gate_guard"],3)
	pursuit.foes[0].opening = 1
	pursuit.act(2,0)
	_check("追云 · 空门武学威力 +5" in pursuit.log, "switching Cloud to Pursuit adds damage to a real opening")
	slot.cultivation = {"frost":"frost_shelter"}
	var shelter := _battle(slot,["frost","wind"],["gate_guard"],3)
	var guarded_hp: int = shelter.allies[1].hp
	shelter.act(1,0)
	shelter._hurt_ally(1,20,1,"cloud",0)
	_check(guarded_hp - shelter.allies[1].hp == 7, "Frost's Shelter stance strengthens his ward on an ally")
	slot.cultivation = {"frost":"frost_shatter"}
	var shatter := _battle(slot,["frost","wind"],["gate_guard"],3)
	shatter.foes[0].frost = 1
	_check(shatter.poise_preview(2,0) == "势 5 → 1" and shatter.act(2,0) and shatter.foes[0].poise == 1,
		"Frost's Shatter stance forecasts and deals an extra poise only with a consumed mark")
	slot.cultivation = {"dream":"dream_breath"}
	var breath := _battle(slot,["dream","wind"],["gate_guard"],3)
	breath.allies[0].qi = 22
	breath.allies[1].qi = 10
	breath.act(1,0)
	_check(breath.allies[0].qi == 14 and breath.allies[1].qi == 12, "Dream's Breathing stance supports the partner's Qi without refunding her own cast")
	slot.cultivation = {"dream":"dream_heal"}
	var healer := _battle(slot,["dream","wind"],["gate_guard"],3)
	healer.allies[1].hp = 20
	healer.act(1,0)
	_check(healer.allies[1].hp == 70 and "温针 · 危急队友治疗 +4" in healer.log, "Dream's Warm Needle gives an actual extra four HP to a critical ally")
	slot.cultivation = {"sage":"sage_cut"}
	var sage := _battle(slot,["sage","cloud"],["dragon"],3)
	_check(sage.poise_preview(1,0) == "势 5 → 2" and sage.act(1,0) and sage.foes[0].poise == 2,
		"Sage's Sword Heart adds one poise only against a telegraphed move")
	slot.cultivation = {"sage":"sage_counter"}
	var counter := _battle(slot,["cloud","sage"],["gate_guard"],3)
	counter.act(3,0)
	counter.act(2,0)
	_check("听锋 · 反击威力 +6" in counter.log and counter.foes[0].hp == counter.foes[0].max_hp - 41,
		"Sage's Listening Edge increases counter damage by six")

func _test_masteries() -> void:
	var slot := _slot()
	slot.chapter = 5
	slot.campaign.sword = true
	slot.insights = Martial.clean_insights({"wind":true,"cloud":true,"frost":true,"dream":true,"sage":true,"unknown":true})
	_check(slot.insights.size() == 5 and not Martial.mastered(slot,"wind"), "insight waits for the base manual and invalid hero receipts are dropped")
	slot.manual_grants = {"crosswind":true,"cloud_return":true,"frost_gate":true,"moon_needle":true,"sword_trace":true}
	for hero in slot.insights:
		slot.chronicle.loadout[hero] = [4,0]
	_check(Martial.enhanced(Martial.move_for(slot,"wind",4)) and Martial.mastery_source("wind").begins_with("壁刻遗图"),
		"mastered description and source are available before equipping")
	var wind := _battle(slot,["wind","cloud"],["dragon"],4)
	_check("精修" in wind.label(1) and wind.poise_preview(1,0) == "势 5 → 1" and wind.act(1,0) and wind.foes[0].poise == 1,
		"mastered Crosswind forecasts and deals two extra poise against a windup")
	var cloud := _battle(slot,["wind","cloud"],["gate_guard"],4)
	cloud.act(3,0)
	var cloud_qi: int = cloud.allies[1].qi
	cloud.act(1,0)
	_check(cloud.allies[1].qi == cloud_qi - 6, "mastered Cloud Return refunds three Qi on a successful counter")
	var frost := _battle(slot,["frost","wind"],["claw"],4)
	frost.foes[0].poise = 1
	frost.act(1,0)
	_check(frost.allies[0].ward and frost.allies[1].ward, "mastered Frost Gate protects both fighters after a live break")
	var dream := _battle(slot,["dream","wind"],["demon"],4)
	dream.allies[1].qi = 2
	dream.act(1,1)
	_check(dream.allies[1].qi == 11, "mastered Needle Transfer restores nine Qi")
	var sage := _battle(slot,["sage","cloud"],["godless"],4)
	sage.act(1,0)
	_check(sage.foes[0].hp == sage.foes[0].max_hp - 31, "mastered Sword Trace uses its published 82% armor factor")

func _test_exclusive_gear_branches() -> void:
	var slot := _slot()
	slot.gear_grants = {"tide_whistle":true}
	slot.gear_levels = {"tide_whistle":2}
	slot.materials = {"star_steel":1}
	slot.silver = 22
	_check(Equipment.assign(slot,"cloud",1,"tide_whistle") and Equipment.modifiers(slot,"cloud").qi == 6,
		"older +2 equipment retains original modifiers and can still be shared")
	var alternate := slot.duplicate(true)
	_check(Economy.reinforce(slot,slot,"peak",0,true).ends_with("断潮风哨") and Equipment.owner(slot,"tide_whistle").is_empty(),
		"choosing the Wind-only branch automatically removes the previous incompatible wearer")
	_check(not Equipment.assign(slot,"cloud",1,"tide_whistle") and Equipment.assign(slot,"wind",1,"tide_whistle")
		and Equipment.modifiers(slot,"wind").weakness_poise == 1, "exclusive combat modifiers only apply when the named hero equips the crafted form")
	_check(slot.silver == 12 and slot.materials.star_steel == 0 and Economy.reinforce(slot,slot,"peak",1,true).is_empty()
		and Economy.reinforce(slot,slot,"peak",0,true).is_empty() and slot.silver == 12 and slot.materials.star_steel == 0,
		"repeat crafting and choosing the alternate branch spend no resources")
	_check(Economy.reinforce(alternate,alternate,"peak",1,true).ends_with("听潮风哨") and Equipment.assign(alternate,"wind",1,"tide_whistle")
		and Martial.synergies(alternate,"wind",4).interrupt == 8 and not Equipment.modifiers(alternate,"wind").has("weakness_poise"),
		"the other branch is independently craftable and trades the poise modifier for extra interrupt Qi")
	_check(Economy.forge_offer(alternate,alternate,"peak",0,true).limit == "已选另一式", "the choice is exclusive in either direction")
	var storage := Save.new("qa_growth_branch_%d" % OS.get_process_id())
	_check(storage.write(alternate), "exclusive branch save writes successfully")
	var restored := storage.read()
	_check(Equipment.branch(restored,"tide_whistle") == "wind_breath" and Equipment.owner(restored,"tide_whistle") == "wind"
		and restored.silver == 12 and not restored.materials.has("star_steel"), "reload preserves chosen branch and paid resource balances")
	_remove_fixture(storage)

func _test_advancement_save_migration() -> void:
	var storage := Save.new("qa_growth_migration_%d" % OS.get_process_id())
	var old := _slot()
	old.chapter = 5
	old.gear_grants = {"tide_whistle":true}
	old.gear_levels = {"tide_whistle":2}
	Equipment.assign(old,"cloud",1,"tide_whistle")
	old.silver = 19
	old.materials = {"ember_iron":2,"clear_silk":1}
	old.loot_claims = {"battle:palace:2":true,"battle:peak:2":true,"quest:forgework":true,"quest:courier":true}
	old.material_claims = {"battle:palace:2":true,"battle:peak:2":true,"quest:forgework":true}
	for future in ["insights", "cultivation", "gear_branches"]:
		old.erase(future)
	_check(storage.write(old), "older earned-elite checkpoint can be written for migration")
	var upgraded := storage.read()
	_check(upgraded.materials == {"ember_iron":2,"clear_silk":1,"star_steel":2} and upgraded.silver == 19,
		"new rare materials are recovered from recorded sources without refunding spent old materials or silver")
	_check(upgraded.insights == {"frost":true,"cloud":true} and not Martial.mastered(upgraded,"cloud")
		and Equipment.level(upgraded,"tide_whistle") == 2 and Equipment.owner(upgraded,"tide_whistle") == "cloud",
		"migration restores only earned insights and keeps a portable legacy +2 item")
	_check(storage.write(upgraded) and storage.read().materials == upgraded.materials, "saving migrated account makes rare material recovery idempotent")
	_remove_fixture(storage)

func _remove_fixture(storage: RefCounted) -> void:
	for suffix in ["", ".bak", ".tmp"]:
		var file: String = storage.path + suffix
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(file)

func _check(passed: bool, description: String) -> void:
	print(("PASS " if passed else "FAIL ") + description)
	if not passed:
		failures += 1
