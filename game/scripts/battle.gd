extends RefCounted

const Story = preload("res://scripts/story.gd")
const Martial = preload("res://scripts/martial.gd")
const Equipment = preload("res://scripts/equipment.gd")
const Items = preload("res://scripts/items.gd")
const FIRST_SUPPLY := 6
const INTENTS = {
	"strike": "快斩 · 单体", "charge": "蓄势 · 重击",
	"sweep": "横扫 · 全体", "brace": "架势 · 减伤", "signal":"预备鸣哨 · 召援",
	"rally":"擂鼓 · 护韩朔", "escape":"携印逃走 · 可破势打断",
	"kindle":"引火蓄刃 · 可打断", "fire_sweep":"火刃横扫 · 全体",
	"mind_sweep":"魔念横扫 · 伤血耗气", "armor_bash":"金身重击",
	"dragon_draw":"蓄龙息 · 可打断", "dragon_reflux":"龙息逆流 · 全体",
	"tyrant_palm":"归元掌", "tyrant_sweep":"气浪横扫 · 全体", "tidal_advance":"鼓令突进"
}
const ELITE_WINDUPS := ["kindle", "fire_sweep", "mind_sweep", "armor_bash",
	"dragon_draw", "dragon_reflux", "tyrant_palm", "tyrant_sweep", "tidal_advance"]
const STANDARD_ELITE_HP := {"duan":202, "beast":178, "demon":260, "godless":310}
const LATE_ELITES := ["dragon", "beast", "boss", "tidal_chief", "tidal_drum"]

var allies: Array[Dictionary] = []
var foes: Array[Dictionary] = []
var log: Array[String] = []
var events: Array[Dictionary] = []
var round_no := 1
var actor := 0
var bond := 0
var tonics := 0
var supplies := {}
var result := ""
var story_mode := false
var chapter_index := 0
var signal_state := ""
var corruption := 0
var shield_resolution := ""
var advanced := false
var pair := ""
var followup_used := false
var reinforcement_round := 2
var combo_uses := 0
var seal_chase := false
var escaped := false
var quest_aid_line := ""
var synergy_feedback := ""
var retaliation_used := false
var opening_used := false

func _init(party: Array, opponents: Array, rank: int, stock: int, easy: bool, chapter: int = 5,
	sword: Variant = null, prepared: Dictionary = {}, expanded: bool = false, gear: Dictionary = {},
	stock_items: Dictionary = {}, builds: Dictionary = {}) -> void:
	tonics = stock
	supplies = Items.clean(stock_items)
	story_mode = easy
	chapter_index = chapter
	advanced = expanded
	pair = Martial.pair_id(party)
	var sword_ready := chapter >= 3 if sword == null else bool(sword)
	for id in party:
		var unit: Dictionary = Story.HEROES[id].duplicate(true)
		var kit: Dictionary = gear.get(id, {})
		var stats := Equipment.attributes(id, rank, kit)
		unit["id"] = id
		unit["gear"] = kit
		unit["build"] = builds.get(id, {})
		unit["technique_bonus"] = (rank - 1) * 2
		unit["max_hp"] = stats.hp
		unit["max_qi"] = stats.qi
		unit["hp"] = unit.max_hp
		unit["qi"] = unit.max_qi
		unit["attack"] = stats.attack
		unit["guard"] = false
		unit["ward"] = false
		unit["ward_owner"] = -1
		unit["counter"] = false
		unit["protector"] = -1
		unit.moves = Martial.slotted_moves(id, sword_ready, prepared.get(id, [0, 1]), chapter)
		if id == "cloud" and not sword_ready:
			unit.title = "佩剑"
		if id == "wind" and chapter == 3:
			unit.title = "魔刀"
		allies.append(unit)
	for id in opponents:
		var info: Array = Story.FOES[id]
		var hp: int = info[1]
		if _has_elite_pattern(id):
			hp = STANDARD_ELITE_HP[id]
		elif id == "dragon" and _has_late_pattern(id):
			hp = 216
		foes.append({"id": id, "name": info[0], "hp": hp, "max_hp": hp,
			"attack": info[2], "poise": info[3], "max_poise": info[3], "weak": info[4],
			"sprite": info[5], "cycle": info[6], "phase": info[7], "broken": false,
			"awakened": false, "shield": false, "cracks": 0, "offset": foes.size(), "dormant":false,
			"frost":0,"resolve":false,"rallied":false,"kindle":false,"opening":0,
			"flow":false,"formation":false})
	if chapter == 1 and opponents == ["paper","claw"]:
		signal_state = "ready"
		foes[1].hp = 0
		foes[1].dormant = true
		if advanced:
			bond = 3
	_note("先观察敌人的招式，再决定如何出手。")

func apply_quest_aid(aid: Dictionary) -> void:
	if aid.is_empty():
		return
	for enemy in foes:
		if enemy.id == aid.get("foe", "") and enemy.hp > 0:
			enemy.poise = maxi(1, enemy.poise - int(aid.get("poise", 0)))
			break
	for i in allies.size():
		if allies[i].id == aid.get("ward", ""):
			_grant_ward(i)
			break
	bond = mini(4, bond + int(aid.get("bond", 0)))
	quest_aid_line = aid.get("line", "")
	if not quest_aid_line.is_empty():
		_note(quest_aid_line)

func available(action: int) -> bool:
	if not result.is_empty() or actor >= allies.size() or action < 0 or action >= FIRST_SUPPLY + Items.ORDER.size():
		return false
	if action >= FIRST_SUPPLY:
		var units := allies if targets_ally(action) else foes
		return supplies.get(_supply(action), 0) > 0 and units.any(func(unit: Dictionary): return _supply_target(action, unit))
	match action:
		1, 2:
			if _move_kind(action) == "cover" and allies[1 - actor].hp <= 0:
				return false
			return allies[actor].qi >= allies[actor].moves[action - 1][1]
		4:
			return tonics > 0
		5:
			return bond >= 4 and allies[0].hp > 0 and allies[1].hp > 0
	return true

func label(action: int) -> String:
	if action >= FIRST_SUPPLY:
		var id := _supply(action)
		return "%s ×%d" % [Items.CATALOG[id].name, supplies.get(id, 0)]
	match action:
		0: return "普攻"
		1, 2: return str(allies[actor].moves[action - 1][0])
		3: return "固守"
		4: return "金创药 ×%d" % tonics
		5:
			if advanced and Martial.NAMES.has(pair):
				return Martial.NAMES[pair]
			return "风云合璧" if pair == "wind_cloud" and foes[0].id in ["boss","dragon"] else "并肩合击"
	return ""

func detail(action: int) -> String:
	if action >= FIRST_SUPPLY:
		return Items.CATALOG[_supply(action)].detail
	match action:
		0: return "单体 · 回复 6 真气"
		1, 2:
			var unit := allies[actor]
			var move: Array = unit.moves[action - 1]
			var description := "%d 气 · %s" % [move[1], move[5]]
			if unit.build.has("interrupt") and Martial.interrupt_move(move):
				return description + " · 截势"
			if unit.build.has("retaliate") and Martial.protection_move(move):
				return description + " · 守反"
			if unit.build.has("exploit") and Martial.exploit_move(move):
				return description + " · 乘隙另耗 %d 气" % Martial.EXPLOIT_COST
			return description
		3:
			var recovered := _guard_recovery(allies[actor])
			return "减伤 · 回气 %d · 魔念 −2" % recovered if allies[actor].title == "魔刀" else "减伤并回复 %d 真气" % recovered
		4: return "治疗队友 58 点 · 可救起倒地"
		5:
			if advanced:
				match pair:
					"wind_frost": return "消耗 4 格 · 群攻并推迟增援"
					"wind_dream": return "消耗 4 格 · 治疗并护住伤者"
					"cloud_sage": return "消耗 4 格 · 打开高护甲空门"
			return "消耗 4 格合璧 · 全体破势"
	return ""

func intent(enemy: Dictionary) -> String:
	if enemy.broken:
		return "破势 · 跳过行动"
	var pattern := _pattern(enemy)
	if enemy.id == "demon" and advanced and pattern == "sweep" and corruption >= 4:
		return "随魔念横扫 · 全体"
	if pattern in ["strike", "charge", "armor_bash", "tyrant_palm", "tidal_advance"]:
		var move: String = {"strike":"快斩", "charge":"重击"}.get(pattern, INTENTS[pattern])
		return "%s › %s" % [move, allies[_threat_target(enemy)].name]
	return INTENTS[pattern]

func tactical_hint(view: Dictionary) -> String:
	for i in foes.size():
		var enemy := foes[i]
		var shown: Dictionary = view.foe[i]
		if shown.hp <= 0:
			continue
		if _has_late_pattern(enemy.id):
			var late_hint := _late_tactical_hint(enemy.id, shown)
			if not late_hint.is_empty():
				return late_hint
		if not _has_elite_pattern(enemy.id):
			continue
		if shown.broken or shown.opening > 0:
			return "敌人露出空门。趁这回合用重招。"
		match enemy.id:
			"duan", "beast":
				if shown.kindle:
					return "火刃将扫全队。可破势打断，或固守、护持。"
				if "引火" in shown.intent:
					return "敌人正在引火。破势可阻止火刃成形。"
				return "下一次引火前，可用普攻或固守回气。"
			"demon":
				return "魔念过高。聂风固守或第二梦回春可压住横扫。" if view.corruption >= 4 else "魔念达四格会引来强横扫。留真气回春或固守。"
			"godless":
				return "被点名的人固守或受护持，接下重击便露空门。" if "金身重击" in shown.intent else "可破势或用双剑开阵打开金身。"
	return ""

func _late_tactical_hint(id: String, shown: Dictionary) -> String:
	if shown.shield:
		return "合璧可破护气，也可分两回合各破势一次。"
	if shown.broken or shown.opening > 0:
		return "敌人露出空门。趁这回合用重招。"
	match id:
		"dragon", "beast":
			if shown.flow:
				return "龙息将扫全队。破势可打断，或护住一人制造空门。"
			if "蓄龙息" in shown.intent:
				return "龙息尚未成形。现在破势可阻止逆流。"
			return "趁它尚未蓄息，削势或回气。"
		"boss":
			if "归元掌" in shown.intent:
				return "接住点名掌击便露空门。用固守、护持或代挡。"
			if "气浪" in shown.intent:
				return "气浪扫向全队。可破势打断，或一起防守。"
		"tidal_chief":
			if shown.formation:
				return "鼓令催阵。破势韩朔或鼓手，或护住突进目标。"
			return "破势鼓手可止擂鼓，击倒他可拆掉鼓阵。"
	return ""

func _has_elite_pattern(id: String) -> bool:
	return advanced and not story_mode and STANDARD_ELITE_HP.has(id) and (id != "beast" or chapter_index == 2)

func _has_late_pattern(id: String) -> bool:
	return advanced and not story_mode and chapter_index == 5 and id in LATE_ELITES

func _tidal_drum_index() -> int:
	for i in foes.size():
		if foes[i].id == "tidal_drum" and foes[i].hp > 0:
			return i
	return -1

func _threat_target(enemy: Dictionary) -> int:
	var target := (round_no + int(enemy.offset)) % allies.size()
	return target if allies[target].hp > 0 else 1 - target

func _pattern(enemy: Dictionary) -> String:
	if seal_chase and enemy.id == "shade" and round_no >= 2:
		return "escape"
	if enemy.id == "paper" and signal_state == "ready":
		return "signal"
	if enemy.id == "tidal_drum":
		if _has_late_pattern(enemy.id) and foes[0].id == "tidal_chief" and foes[0].broken:
			return "strike"
		return "rally" if foes[0].id == "tidal_chief" and foes[0].hp > 0 and round_no % 2 == 1 else "strike"
	if _has_late_pattern(enemy.id):
		match enemy.id:
			"dragon", "beast":
				if enemy.flow:
					return "dragon_reflux"
				return "dragon_draw" if (round_no % 2 == 1) == (enemy.id == "dragon") else "charge"
			"boss":
				if not enemy.awakened:
					return "tyrant_palm" if round_no % 2 else "brace"
				if enemy.shield:
					return "charge" if round_no % 2 else "sweep"
				return "tyrant_palm" if round_no % 2 else "tyrant_sweep"
			"tidal_chief":
				if enemy.formation:
					return "tidal_advance"
	if _has_elite_pattern(enemy.id):
		match enemy.id:
			"duan", "beast":
				if enemy.kindle:
					return "fire_sweep"
				return "kindle" if (round_no % 2 == 1) == (enemy.id == "duan") else "charge"
			"demon":
				return "mind_sweep" if corruption >= 4 else ("charge" if round_no % 2 else "brace")
			"godless":
				return ["armor_bash", "brace", "sweep"][(round_no - 1) % 3]
	if advanced:
		match enemy.id:
			"duan": return "charge" if round_no % 2 else "sweep"
			"demon": return "sweep" if corruption >= 4 else ("charge" if round_no % 2 else "brace")
			"godless": return ["charge","brace","sweep"][(round_no - 1) % 3]
	var cycle: Array = enemy.cycle
	return cycle[(round_no - 1 + enemy.offset) % cycle.size()]

func living_foe() -> int:
	for i in foes.size():
		if foes[i].hp > 0:
			return i
	return -1

func weakest_ally(alive_only: bool = false) -> int:
	if alive_only:
		if allies[0].hp == 0:
			return 1
		if allies[1].hp == 0:
			return 0
	return 0 if allies[0].hp < allies[1].hp else 1

func presentation() -> Dictionary:
	var ally_stats: Array = []
	var foe_stats: Array = []
	for unit in allies:
		ally_stats.append({"hp":unit.hp,"qi":unit.qi,"ward":unit.ward,"protector":unit.protector})
	for enemy in foes:
		var stats := _foe_stats(enemy)
		stats["intent"] = intent(enemy)
		foe_stats.append(stats)
	return {"ally":ally_stats,"foe":foe_stats,"round":round_no,"actor":actor,"bond":bond,"corruption":corruption}

func _foe_stats(enemy: Dictionary) -> Dictionary:
	return {"hp":enemy.hp,"poise":enemy.poise,"broken":enemy.broken,"shield":enemy.shield,
		"cracks":enemy.cracks,"dormant":enemy.dormant,"frost":enemy.frost,"rallied":enemy.rallied,
		"kindle":enemy.kindle,"opening":enemy.opening,"flow":enemy.flow,"formation":enemy.formation,
		"awakened":enemy.awakened,"phase_label":_phase_label(enemy)}

func _phase_label(enemy: Dictionary) -> String:
	if not _has_late_pattern(enemy.id):
		return ""
	match enemy.id:
		"dragon", "beast": return "龙息逆流" if enemy.flow else "龙脉蓄势"
		"boss":
			if enemy.shield:
				return "三分归元气"
			return "归元气已破" if enemy.awakened else "雄霸试掌"
		"tidal_chief":
			if enemy.formation:
				return "鼓令成阵"
			return "韩朔独战" if _tidal_drum_index() < 0 else "韩朔与鼓手"
	return ""

func act(action: int, target: int) -> bool:
	if not available(action):
		return false
	if action in [0,1,2] and not _automatic(action) and not targets_ally(action):
		if target < 0 or target >= foes.size() or foes[target].hp <= 0:
			return false
	if targets_ally(action):
		if not valid_target(action, target):
			return false
	if action >= FIRST_SUPPLY and not valid_target(action, target):
		return false
	events.clear()
	synergy_feedback = ""
	opening_used = false
	var unit := allies[actor]
	var action_name := label(action)
	_note("%s施展%s。" % [unit.name, action_name])
	var style := "blade"
	match action:
		1, 2:
			var move: Array = unit.moves[action - 1]
			style = {"风":"wind","云":"cloud","寒":"frost","疗":"heal","锋":"blade"}[move[2]]
			if action_name == "魔刀狂斩":
				style = "dark"
			elif _move_kind(action) in ["cover","counter","shelter"]:
				style = "guard"
		3: style = "guard"
		4: style = "heal"
		5: style = "combo"
		_: style = "break" if action >= FIRST_SUPPLY and not targets_ally(action) else "heal"
	_effect("cast", "ally", actor, 0, style, action_name)
	match action:
		0:
			unit.qi = mini(unit.max_qi, unit.qi + 6)
			_hit_foe(target, unit.attack, 1, "", style)
			bond = mini(4, bond + 1)
		1, 2:
			var move: Array = unit.moves[action - 1]
			unit.qi -= move[1]
			var power: int = move[3] + unit.technique_bonus
			_apply_move(unit,move,power,target,action,style)
			if style == "dark" and corruption == 6:
				var recoil := mini(18, int(unit.hp) - 1)
				unit.hp -= recoil
				corruption = 3
				_effect("damage","ally",actor,0,"dark","反噬 −%d" % recoil)
				_note("魔念失控，聂风被自己的刀气反噬。")
			bond = mini(4, bond + 1)
		3:
			unit.guard = true
			unit.qi = mini(unit.max_qi, unit.qi + _guard_recovery(unit))
			if unit.title == "魔刀":
				corruption = maxi(0,corruption - 2)
		4:
			tonics -= 1
			_heal(target, 58)
		5:
			bond = 0
			combo_uses += 1
			_apply_combo(unit)
		_: _use_supply(action, target)
	events[0]["stats"] = {"qi":unit.qi}
	events[0]["corruption"] = corruption
	if living_foe() < 0:
		result = "victory"
		return true
	if actor == 0 and allies[1].hp > 0:
		actor = 1
	else:
		_enemy_turn()
	return true

func _guard_recovery(unit: Dictionary) -> int:
	return 9 + int(unit.gear.get("guard_qi", 0))

func _automatic(action: int) -> bool:
	return action in [1,2] and ("全体" in allies[actor].moves[action - 1][5] or _move_kind(action) == "counter")

func targets_ally(action: int) -> bool:
	if action >= FIRST_SUPPLY:
		return Items.CATALOG[_supply(action)].target == "ally"
	return action == 4 or _move_kind(action) in ["cover","aid"]

func valid_target(action: int, target: int) -> bool:
	var friendly := targets_ally(action)
	var units := allies if friendly else foes
	if target < 0 or target >= units.size():
		return false
	if action >= FIRST_SUPPLY:
		return _supply_target(action, units[target])
	if _move_kind(action) == "cover" and target == actor:
		return false
	return action == 4 or units[target].hp > 0

func poise_preview(action: int, at: int) -> String:
	if targets_ally(action) or not valid_target(action, at):
		return ""
	var enemy := foes[at]
	var unit := allies[actor]
	var move: Array = unit.moves[action - 1] if action in [1, 2] else []
	if (enemy.broken or enemy.opening > 0) and not move.is_empty() and unit.build.has("exploit") and Martial.exploit_move(move):
		if unit.qi - move[1] >= Martial.EXPLOIT_COST:
			return "有空门 · 乘隙 +%d（另耗 %d 气）" % [unit.build.exploit, Martial.EXPLOIT_COST]
		return "有空门 · 乘隙另需 %d 气" % Martial.EXPLOIT_COST
	if enemy.broken:
		return "已破势 · 此回合跳过行动"
	var amount := 1
	if action >= FIRST_SUPPLY:
		amount = Items.CATALOG[_supply(action)].amount
	elif not move.is_empty():
		amount = move[4]
		if _move_kind(action) == "shatter":
			amount += enemy.frost
		if move[2] == enemy.weak:
			amount += 1 + int(unit.gear.get("weakness_poise", 0))
	var next := maxi(int(enemy.resolve), enemy.poise - amount)
	if next == 0 and not move.is_empty() and unit.build.has("interrupt") and Martial.interrupt_move(move):
		return "破势打断 · 截势回气 %d" % _interrupt_recovery(unit, enemy)
	return "可破势 · 打断本回合" if next == 0 else "势 %d → %d" % [enemy.poise, next]

func _supply(action: int) -> String:
	return Items.ORDER[action - FIRST_SUPPLY]

func _supply_target(action: int, unit: Dictionary) -> bool:
	return Items.can_target(_supply(action), unit)

func bag_actions() -> Array[int]:
	var actions: Array[int] = [4]
	for i in Items.ORDER.size():
		actions.append(FIRST_SUPPLY + i)
	return actions

func _use_supply(action: int, target: int) -> void:
	var id := _supply(action)
	var amount: int = Items.CATALOG[id].amount
	supplies[id] -= 1
	match id:
		"breath_pill":
			var unit := allies[target]
			var gain := mini(amount, unit.max_qi - unit.qi)
			unit.qi += gain
			_ally_state(target, "回气 +%d" % gain)
			events.back().stats.qi = unit.qi
		"guard_powder":
			_grant_ward(target)
			_ally_state(target, "护持")
		"stagger_needle":
			var before: int = foes[target].poise
			_reduce_poise(target, amount, 0)
			_effect("stance", "foe", target, 0, "break", "削势 %d" % (before - foes[target].poise))

func _move_kind(action: int) -> String:
	if action not in [1,2]:
		return ""
	var move: Array = allies[actor].moves[action - 1]
	return move[6] if move.size() > 6 else ""

func _apply_move(unit: Dictionary, move: Array, power: int, target: int, action: int, style: String) -> void:
	var kind := _move_kind(action)
	match kind:
		"cover":
			allies[target].protector = actor
			unit.guard = true
			_ally_state(target,"护风")
		"counter":
			unit.guard = true
			unit.counter = true
			_ally_state(actor,"蓄势反击")
		"shelter":
			for i in allies.size():
				if allies[i].hp > 0:
					_grant_ward(i, actor)
					_ally_state(i,"护持")
		"aid":
			_heal(target,power + int(unit.gear.get("heal", 0)))
			_grant_ward(target, actor)
			_ally_state(target,"护持")
		_:
			if style == "dark":
				power += 12 + corruption
				corruption = mini(6,corruption + 2)
			if move[2] == "疗":
				corruption = maxi(0,corruption - (4 if kind == "cleanse" else 3))
				for i in allies.size():
					if allies[i].hp > 0:
						_heal(i,power + int(unit.gear.get("heal", 0)))
				return
			if _automatic(action):
				for i in foes.size():
					if foes[i].hp > 0:
						_technique_hit(unit,move,i,power,kind,style)
			else:
				_technique_hit(unit,move,target,power,kind,style)
			if kind == "breath":
				unit.qi = mini(unit.max_qi,unit.qi+6)

func _technique_hit(unit: Dictionary, move: Array, at: int, power: int, kind: String, style: String) -> void:
	var enemy := foes[at]
	var poise: int = move[4]
	if kind == "shatter":
		poise += enemy.frost
		enemy.frost = 0
	elif advanced and unit.id == "frost":
		enemy.frost = mini(2,enemy.frost+1)
	var has_opening: bool = enemy.broken or enemy.opening > 0
	var pursuit: bool = has_opening and (kind == "pursuit" or (advanced and enemy.frost == 2 and unit.id == "wind"))
	if has_opening:
		power += int(unit.gear.get("broken_damage", 0))
		if not opening_used and unit.build.has("exploit") and Martial.exploit_move(move) and unit.qi >= Martial.EXPLOIT_COST:
			opening_used = true
			unit.qi -= Martial.EXPLOIT_COST
			power += int(unit.build.exploit)
			_announce_synergy("乘隙 · 重招威力 +%d" % unit.build.exploit)
	if move[2] == enemy.weak:
		poise += int(unit.gear.get("weakness_poise", 0))
	var already_broken: bool = enemy.broken
	var interrupt_recovery := _interrupt_recovery(unit, enemy)
	_hit_foe(at,power,poise,move[2],style)
	if not already_broken and enemy.broken and unit.build.has("interrupt") and Martial.interrupt_move(move):
		var recovered := _restore_qi(unit, interrupt_recovery)
		if recovered > 0:
			_announce_synergy("截势 · 回气 %d" % recovered)
	if pursuit and not followup_used and enemy.hp > 0:
		followup_used = true
		enemy.frost = 0
		_hit_foe(at,14,0,"",style)
		_note("抓住破势空当追击。")

func _interrupt_recovery(unit: Dictionary, enemy: Dictionary) -> int:
	var recovery: int = unit.build.get("interrupt", 0)
	return recovery + 2 if _pattern(enemy) in ELITE_WINDUPS else recovery

func _apply_combo(unit: Dictionary) -> void:
	if advanced and pair == "wind_dream":
		corruption = 0
		var hurt := weakest_ally()
		for i in allies.size():
			_heal(i,30)
		_grant_ward(hurt)
		_ally_state(hurt,"护持")
		return
	if advanced and pair == "wind_frost" and signal_state in ["ready","called"] and foes[1].dormant:
		reinforcement_round = maxi(reinforcement_round,round_no+2)
		_note("风霜封住河道，援兵迟一回合抵达。")
	for i in foes.size():
		if foes[i].hp <= 0:
			continue
		if foes[i].shield:
			foes[i].shield = false
			shield_resolution = "combo"
			if _has_late_pattern(foes[i].id):
				_phase_change(i, 0, "cloud", "归元气破")
			else:
				_effect("break","foe",i,0,"break","护气已破")
		if advanced and pair == "cloud_sage" and foes[i].phase == "armor":
			foes[i].poise = 1
			foes[i].resolve = false
		var stagger := 2 if advanced and pair == "wind_frost" and signal_state == "ready" else 4
		_hit_foe(i,52+unit.attack,stagger,"合","combo")

func _ally_state(index: int, label: String, beat: int = 0) -> void:
	_effect("stance","ally",index,beat,"guard",label)

func _grant_ward(index: int, source: int = -1) -> void:
	if not allies[index].ward or source >= 0:
		allies[index].ward_owner = source
	allies[index].ward = true

func _restore_qi(unit: Dictionary, amount: int) -> int:
	var recovered := mini(amount, int(unit.max_qi - unit.qi))
	unit.qi += recovered
	return recovered

func _announce_synergy(message: String) -> void:
	synergy_feedback = message
	_note(message)

func _effect(kind: String, side: String, index: int, beat: int, style: String, caption: String = "") -> void:
	var event := {"kind":kind, "side":side, "index":index, "beat":beat, "style":style, "text":caption}
	if kind in ["damage","heal","stance","recover","arrival"]:
		event["stats"] = {"hp":allies[index].hp,"ward":allies[index].ward,
			"protector":allies[index].protector} if side == "ally" else _foe_stats(foes[index])
	events.append(event)

func _phase_change(index: int, beat: int, style: String, caption: String) -> void:
	_effect("stance", "foe", index, beat, style, caption)
	events.back().phase_change = true

func _collapse_formation(beat: int) -> void:
	if foes[0].id != "tidal_chief" or not foes[0].formation:
		return
	foes[0].formation = false
	foes[0].rallied = false
	_phase_change(0, beat, "guard", "鼓令瓦解")
	_note("鼓令被截断，韩朔无法依阵突进。")

func _on_drummer_falls(beat: int) -> void:
	if foes[0].id != "tidal_chief" or foes[0].hp <= 0:
		return
	if foes[0].formation:
		_collapse_formation(beat)
	else:
		_phase_change(0, beat, "guard", "韩朔独战")

func _hit_foe(index: int, base: int, break_power: int, element: String, style: String, beat: int = 0) -> void:
	var enemy := foes[index]
	var weak: bool = element == enemy.weak
	var damage := float(base)
	if weak:
		damage *= 1.28
		break_power += 1
	if story_mode:
		damage *= 1.20
	if enemy.broken:
		damage *= 1.38
	elif enemy.opening > 0:
		damage *= 1.15
	elif enemy.phase == "armor":
		damage *= 0.40
	elif _pattern(enemy) == "mind_sweep":
		damage *= 0.78
	elif _pattern(enemy) == "brace":
		damage *= 0.75
	if enemy.shield:
		damage *= 0.36
	if enemy.rallied:
		damage *= 0.45
		enemy.rallied = false
		_note("鼓阵抵消了这一击的部分伤害。")
	_reduce_poise(index, break_power, beat)
	var points := maxi(1, roundi(damage))
	var previous_hp: int = enemy.hp
	var first_clash: bool = enemy.id == "first_tyrant"
	var must_awaken: bool = first_clash or (enemy.id == "boss" and _has_late_pattern(enemy.id))
	enemy.hp = maxi(1 if enemy.shield or (must_awaken and not enemy.awakened) else 0, enemy.hp - points)
	_effect("damage", "foe", index, beat, style, "%d%s" % [previous_hp - enemy.hp, " 克" if weak else ""])
	if enemy.hp <= 0 and enemy.id == "tidal_drum" and _has_late_pattern(enemy.id):
		_on_drummer_falls(beat)
	if enemy.hp <= 0 or enemy.awakened or enemy.hp * 2 > enemy.max_hp:
		return
	enemy.awakened = true
	if enemy.phase == "fury":
		enemy.attack += 5
		_note("%s攻势转急。" % enemy.name)
		if first_clash:
			enemy.shield = true
			_effect("stance","foe",index,beat,"guard","三分归元气")
			_note("雄霸护住要害。无名示意二人合璧。")
	elif enemy.phase == "tyrant":
		enemy.shield = true
		enemy.attack += 6
		enemy.cycle = ["charge","strike","sweep"] if advanced else ["charge","sweep"]
		if _has_late_pattern(enemy.id):
			_phase_change(index, beat, "guard", "三分归元气")
			_note("雄霸护住要害。合璧可破，或分两回合各破势一次。")
		else:
			_effect("stance","foe",index,beat,"guard","三分归元气" if advanced else "龙脉护气")
			_note("雄霸以护气挡住要害，合璧可破！")

func _reduce_poise(index: int, points: int, beat: int) -> void:
	var enemy := foes[index]
	if enemy.broken:
		return
	enemy.poise = maxi(1 if enemy.resolve else 0, enemy.poise - points)
	if enemy.poise > 0:
		return
	if _has_elite_pattern(enemy.id) and enemy.id in ["duan", "beast"]:
		if enemy.kindle or _pattern(enemy) == "kindle":
			_note("%s引火被打断，火刃未能横扫。" % enemy.name)
		enemy.kindle = false
	if _has_late_pattern(enemy.id):
		if enemy.id in ["dragon", "beast"] and (enemy.flow or _pattern(enemy) == "dragon_draw"):
			enemy.flow = false
			_phase_change(index, beat, "dark", "龙息中断")
			_note("龙息被打散，逆流未能成形。")
		elif enemy.id in ["tidal_chief", "tidal_drum"]:
			_collapse_formation(beat)
	enemy.broken = true
	if enemy.id == "paper" and signal_state == "ready":
		signal_state = "blocked"
		_note("哨声被打断，援兵没有发现渡口。")
	_effect("break", "foe", index, beat, "break", "破势")
	_note("%s被破势！" % enemy.name)
	if enemy.shield and enemy.id != "first_tyrant":
		enemy.cracks += 1
		if enemy.cracks >= 2:
			enemy.shield = false
			shield_resolution = "poise"
			if _has_late_pattern(enemy.id):
				_phase_change(index, beat, "cloud", "归元气破")
			_note("护气散尽。")

func _heal(index: int, points: int) -> void:
	var unit := allies[index]
	var restored := mini(points, int(unit.max_hp - unit.hp))
	unit.hp += restored
	_effect("heal", "ally", index, 0, "heal", "+%d" % restored)

func _enemy_turn() -> void:
	var beat := 0
	var chief_interrupted: bool = foes[0].id == "tidal_chief" and foes[0].broken
	for index in foes.size():
		var enemy := foes[index]
		if enemy.hp <= 0:
			continue
		if enemy.broken:
			enemy.broken = false
			enemy.poise = enemy.max_poise
			enemy.resolve = advanced and enemy.id in ["duan","demon","godless","boss","first_tyrant"]
			beat += 1
			_effect("recover", "foe", index, beat, "break")
			_note("%s气息散乱，未能出手。" % enemy.name)
			continue
		var attack := _pattern(enemy)
		if attack == "rally" and chief_interrupted and _has_late_pattern(enemy.id):
			attack = "strike"
		enemy.resolve = false
		beat += 1
		if attack == "escape":
			escaped = true
			_effect("stance","foe",index,beat,"guard","脱逃")
			_note("密探带走了假印。")
			result = "defeat"
			return
		if attack == "rally":
			foes[0].rallied = true
			_effect("cast","foe",index,beat,"guard","擂鼓")
			if _has_late_pattern(enemy.id):
				foes[0].formation = true
				_phase_change(0, beat, "guard", "鼓令成阵")
				_note("鼓令成阵。韩朔下回合将点名突进。")
			else:
				_effect("stance","foe",0,beat,"guard","鼓阵")
				_note("鼓阵已起，韩朔下一次受击减伤。")
			continue
		if attack == "signal":
			signal_state = "called"
			_effect("stance","foe",index,beat,"guard","鸣哨")
			_note("纸探花吹响暗哨，援兵将在次轮赶到。")
			continue
		if attack == "kindle":
			enemy.kindle = true
			_effect("stance", "foe", index, beat, "blade", "火刃蓄成")
			_note("%s引火蓄刃，下回合将横扫全队。" % enemy.name)
			continue
		if attack == "dragon_draw":
			enemy.flow = true
			_phase_change(index, beat, "dark", "龙息蓄起")
			_note("龙息蓄起。下回合逆流将席卷全队。")
			continue
		if attack == "brace":
			enemy.poise = mini(enemy.max_poise, enemy.poise + 2)
			_effect("stance", "foe", index, beat, "guard")
			_note("%s稳住架势。" % enemy.name)
			continue
		var target := _threat_target(enemy)
		var style: String = {"sweep":"dark", "charge":"cloud", "strike":"blade", "fire_sweep":"blade",
			"mind_sweep":"dark", "armor_bash":"cloud", "dragon_reflux":"dark", "tyrant_palm":"cloud",
			"tyrant_sweep":"cloud", "tidal_advance":"blade"}[attack]
		_effect("cast", "foe", index, beat, style)
		_note("%s · %s" % [enemy.name, INTENTS[attack]])
		match attack:
			"sweep":
				for i in allies.size():
					_hurt_ally(i, roundi(enemy.attack * 0.78), beat, style,index)
			"fire_sweep", "mind_sweep":
				for i in allies.size():
					_hurt_ally(i, roundi(enemy.attack * 1.22), beat, style, index, attack)
				enemy.kindle = false
			"armor_bash":
				_hurt_ally(target, roundi(enemy.attack * 1.48), beat, style, index, attack)
			"dragon_reflux", "tyrant_sweep":
				for i in allies.size():
					_hurt_ally(i, roundi(enemy.attack * 1.06), beat, style, index, attack)
				if attack == "dragon_reflux":
					enemy.flow = false
					_phase_change(index, beat, "dark", "龙息散去")
			"tyrant_palm", "tidal_advance":
				_hurt_ally(target, roundi(enemy.attack * 1.48), beat, style, index, attack)
				if attack == "tidal_advance":
					enemy.formation = false
					enemy.rallied = false
					_phase_change(index, beat, "guard", "鼓令散去")
			"charge":
				_hurt_ally(target, roundi(enemy.attack * 1.56), beat, style,index)
			_:
				_hurt_ally(target, enemy.attack, beat, style,index)
		if allies[0].hp == 0 and allies[1].hp == 0:
			result = "defeat"
			return
	for unit in allies:
		unit.guard = false
		unit.counter = false
	for enemy in foes:
		enemy.opening = maxi(0, enemy.opening - 1)
	round_no += 1
	followup_used = false
	retaliation_used = false
	if signal_state == "called" and foes[1].dormant and round_no >= reinforcement_round:
		foes[1].dormant = false
		foes[1].hp = foes[1].max_hp
		_effect("arrival","foe",1,beat + 1,"dark","援兵")
	if living_foe() < 0:
		result = "victory"
	actor = 0 if allies[0].hp > 0 else 1

func _hurt_ally(index: int, points: int, beat: int, style: String, source: int, attack: String = "") -> void:
	var unit := allies[index]
	if unit.hp <= 0:
		return
	var defending_ally := -1
	var redirected := false
	if unit.protector >= 0:
		var protector: int = unit.protector
		unit.protector = -1
		if protector != index and allies[protector].hp > 0:
			_ally_state(index,"代挡",beat)
			index = protector
			unit = allies[index]
			defending_ally = index
			redirected = true
	if unit.counter:
		defending_ally = index
	var guarded: bool = unit.guard or redirected
	var protected: bool = guarded or unit.ward
	var factor := (0.66 if story_mode else 1.0) * (0.34 if guarded else 1.0)
	var ward_owner := -1
	if unit.ward:
		factor *= 0.45
		unit.ward = false
		ward_owner = int(unit.ward_owner)
		unit.ward_owner = -1
	var damage := maxi(1, roundi(points * factor) - int(unit.gear.get("armor", 0)))
	unit.hp = maxi(0, unit.hp - damage)
	_effect("damage", "ally", index, beat, "guard" if guarded else style, "−%d" % damage)
	if unit.hp == 0:
		_note("%s倒下。金创药可救起。" % unit.name)
		return
	if attack == "armor_bash" and protected:
		_open_guard_gap(source, beat)
		_note("重击被接住，绝无神的金身露出空门。")
	if protected and attack in ["dragon_reflux", "tyrant_palm", "tidal_advance"] and _open_guard_gap(source, beat):
		_note("护住了这一击，%s露出空门。" % foes[source].name)
	if attack == "mind_sweep" and not protected:
		var drained := mini(4, int(unit.qi))
		if drained > 0:
			unit.qi -= drained
			_effect("stance", "ally", index, beat, "dark", "真气 −%d" % drained)
			events.back().stats.qi = unit.qi
			_note("魔念横扫夺走%s %d 点真气。" % [unit.name, drained])
	_trigger_retaliation(defending_ally, source, beat)
	_trigger_retaliation(ward_owner, source, beat)
	if unit.counter and foes[source].hp > 0:
		unit.counter = false
		_hit_foe(source,unit.attack+13,1,"","blade",beat)

func _open_guard_gap(source: int, beat: int) -> bool:
	var foe := foes[source]
	if foe.hp <= 0 or foe.opening == 2:
		return false
	foe.opening = 2
	_effect("stance", "foe", source, beat, "break", "空门")
	return true

func _trigger_retaliation(index: int, source: int, beat: int) -> void:
	if index < 0 or retaliation_used:
		return
	var defender := allies[index]
	if defender.hp <= 0 or not defender.build.has("retaliate"):
		return
	var recovered := _restore_qi(defender, int(defender.build.retaliate))
	var gained := mini(1, 4 - bond)
	var opened := _open_guard_gap(source, beat)
	retaliation_used = true
	bond += gained
	var reward := PackedStringArray()
	if gained > 0:
		reward.append("合击 +1")
	if recovered > 0:
		reward.append("回气 %d" % recovered)
	if opened:
		reward.append("露空门")
	if reward.is_empty():
		return
	var message := "守反 · " + " · ".join(reward)
	_ally_state(index, message, beat)
	events.back().stats.qi = defender.qi
	_announce_synergy(message)

func _note(message: String) -> void:
	log.append(message)
	if log.size() > 10:
		log.pop_front()

