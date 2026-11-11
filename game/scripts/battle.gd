extends RefCounted

const Story = preload("res://scripts/story.gd")
const Martial = preload("res://scripts/martial.gd")
const INTENTS = {
	"strike": "快斩 · 单体", "charge": "蓄势 · 重击",
	"sweep": "横扫 · 全体", "brace": "架势 · 减伤", "signal":"预备鸣哨 · 召援",
	"rally":"擂鼓 · 护韩朔"
}

var allies: Array[Dictionary] = []
var foes: Array[Dictionary] = []
var log: Array[String] = []
var events: Array[Dictionary] = []
var round_no := 1
var actor := 0
var bond := 0
var tonics := 0
var result := ""
var story_mode := false
var signal_state := ""
var corruption := 0
var shield_resolution := ""
var advanced := false
var pair := ""
var followup_used := false
var reinforcement_round := 2
var combo_uses := 0

func _init(party: Array, opponents: Array, rank: int, stock: int, easy: bool, chapter: int = 5,
	sword: Variant = null, prepared: Dictionary = {}, expanded: bool = false) -> void:
	tonics = stock
	story_mode = easy
	advanced = expanded
	pair = Martial.pair_id(party)
	var sword_ready := chapter >= 3 if sword == null else bool(sword)
	for id in party:
		var unit: Dictionary = Story.HEROES[id].duplicate(true)
		unit["id"] = id
		unit["max_hp"] = unit.hp + (rank - 1) * 8
		unit["max_qi"] = unit.qi + (rank - 1) * 2
		unit["hp"] = unit.max_hp
		unit["qi"] = unit.max_qi
		unit["attack"] += (rank - 1) * 2
		unit["guard"] = false
		unit["ward"] = false
		unit["counter"] = false
		unit["protector"] = -1
		var catalog := Martial.options(id,sword_ready)
		unit.moves = prepared.get(id,[0,1]).map(func(at): return catalog[int(at)])
		if id == "cloud" and not sword_ready:
			unit.title = "佩剑"
		if id == "wind" and chapter == 3:
			unit.title = "魔刀"
			unit.moves[1] = ["魔刀狂斩", 11, "锋", 30, 2, "全体 · 魔念 +2"]
		if id == "dream" and chapter == 3:
			for move in unit.moves:
				if move[0] == "回春诀":
					move[5] = "全体治疗 · 魔念 −3"
		allies.append(unit)
	for id in opponents:
		var info: Array = Story.FOES[id]
		foes.append({"id": id, "name": info[0], "hp": info[1], "max_hp": info[1],
			"attack": info[2], "poise": info[3], "max_poise": info[3], "weak": info[4],
			"sprite": info[5], "cycle": info[6], "phase": info[7], "broken": false,
			"awakened": false, "shield": false, "cracks": 0, "offset": foes.size(), "dormant":false,
			"frost":0,"resolve":false,"rallied":false})
	if chapter == 1 and opponents == ["paper","claw"]:
		signal_state = "ready"
		foes[1].hp = 0
		foes[1].dormant = true
		if advanced:
			bond = 3
	_note("先观察敌人的招式，再决定如何出手。")

func available(action: int) -> bool:
	if not result.is_empty() or actor >= allies.size() or action < 0 or action > 5:
		return false
	match action:
		1, 2:
			return allies[actor].qi >= allies[actor].moves[action - 1][1]
		4:
			return tonics > 0
		5:
			return bond >= 4 and allies[0].hp > 0 and allies[1].hp > 0
	return true

func label(action: int) -> String:
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
	match action:
		0: return "单体 · 回复 6 真气"
		1, 2:
			var move: Array = allies[actor].moves[action - 1]
			return "%d 气 · %s" % [move[1], move[5]]
		3: return "减伤 · 回气 9 · 魔念 −2" if allies[actor].title == "魔刀" else "减伤并回复 9 真气"
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
	if pattern in ["strike", "charge"]:
		var move := "重击" if pattern == "charge" else "快斩"
		return "%s › %s" % [move, allies[_threat_target(enemy)].name]
	return INTENTS[pattern]

func _threat_target(enemy: Dictionary) -> int:
	var target := (round_no + int(enemy.offset)) % allies.size()
	return target if allies[target].hp > 0 else 1 - target

func _pattern(enemy: Dictionary) -> String:
	if enemy.id == "paper" and signal_state == "ready":
		return "signal"
	if enemy.id == "tidal_drum":
		return "rally" if foes[0].id == "tidal_chief" and foes[0].hp > 0 and round_no % 2 == 1 else "strike"
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
		"cracks":enemy.cracks,"dormant":enemy.dormant,"frost":enemy.frost,"rallied":enemy.rallied}

func act(action: int, target: int) -> bool:
	if not available(action):
		return false
	if action in [0,1,2] and not _automatic(action) and not targets_ally(action):
		if target < 0 or target >= foes.size() or foes[target].hp <= 0:
			return false
	if targets_ally(action):
		if target < 0 or target >= allies.size() or (action != 4 and allies[target].hp == 0):
			return false
	events.clear()
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
	_effect("cast", "ally", actor, 0, style, action_name)
	match action:
		0:
			unit.qi = mini(unit.max_qi, unit.qi + 6)
			_hit_foe(target, unit.attack, 1, "", style)
			bond = mini(4, bond + 1)
		1, 2:
			var move: Array = unit.moves[action - 1]
			unit.qi -= move[1]
			var power: int = move[3] + int((unit.max_hp - Story.HEROES[unit.id].hp) / 4.0)
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
			unit.qi = mini(unit.max_qi, unit.qi + 9)
			if unit.title == "魔刀":
				corruption = maxi(0,corruption - 2)
		4:
			tonics -= 1
			_heal(target, 58)
		5:
			bond = 0
			combo_uses += 1
			_apply_combo(unit)
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

func _automatic(action: int) -> bool:
	return action in [1,2] and ("全体" in allies[actor].moves[action - 1][5] or _move_kind(action) == "counter")

func targets_ally(action: int) -> bool:
	return action == 4 or _move_kind(action) in ["cover","aid"]

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
					allies[i].ward = true
					_ally_state(i,"护持")
		"aid":
			_heal(target,power)
			allies[target].ward = true
			_ally_state(target,"护持")
		_:
			if style == "dark":
				power += 12 + corruption
				corruption = mini(6,corruption + 2)
			if move[2] == "疗":
				corruption = maxi(0,corruption - (4 if kind == "cleanse" else 3))
				for i in allies.size():
					if allies[i].hp > 0:
						_heal(i,power)
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
	var pursuit: bool = enemy.broken and (kind == "pursuit" or (advanced and enemy.frost == 2 and unit.id == "wind"))
	_hit_foe(at,power,poise,move[2],style)
	if pursuit and not followup_used and enemy.hp > 0:
		followup_used = true
		enemy.frost = 0
		_hit_foe(at,14,0,"",style)
		_note("抓住破势空当追击。")

func _apply_combo(unit: Dictionary) -> void:
	if advanced and pair == "wind_dream":
		corruption = 0
		var hurt := weakest_ally()
		for i in allies.size():
			_heal(i,30)
		allies[hurt].ward = true
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
			_effect("break","foe",i,0,"break","护气已破")
		if advanced and pair == "cloud_sage" and foes[i].phase == "armor":
			foes[i].poise = 1
			foes[i].resolve = false
		var stagger := 2 if advanced and pair == "wind_frost" and signal_state == "ready" else 4
		_hit_foe(i,52+unit.attack,stagger,"合","combo")

func _ally_state(index: int, label: String, beat: int = 0) -> void:
	_effect("stance","ally",index,beat,"guard",label)

func _effect(kind: String, side: String, index: int, beat: int, style: String, caption: String = "") -> void:
	var event := {"kind":kind, "side":side, "index":index, "beat":beat, "style":style, "text":caption}
	if kind in ["damage","heal","stance","recover","arrival"]:
		event["stats"] = {"hp":allies[index].hp,"ward":allies[index].ward,
			"protector":allies[index].protector} if side == "ally" else _foe_stats(foes[index])
	events.append(event)

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
	elif enemy.phase == "armor":
		damage *= 0.40
	elif _pattern(enemy) == "brace":
		damage *= 0.75
	if enemy.shield:
		damage *= 0.36
	if enemy.rallied:
		damage *= 0.45
		enemy.rallied = false
		_note("鼓阵抵消了这一击的部分伤害。")
	if not enemy.broken:
		enemy.poise = maxi(1 if enemy.resolve else 0, enemy.poise - break_power)
		if enemy.poise == 0:
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
					_note("护气散尽。")
	var points := maxi(1, roundi(damage))
	var previous_hp: int = enemy.hp
	var first_clash: bool = enemy.id == "first_tyrant"
	enemy.hp = maxi(1 if enemy.shield or (first_clash and not enemy.awakened) else 0, enemy.hp - points)
	_effect("damage", "foe", index, beat, style, "%d%s" % [previous_hp - enemy.hp, " 克" if weak else ""])
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
		_effect("stance","foe",index,beat,"guard","三分归元气" if advanced else "龙脉护气")
		_note("雄霸以护气挡住要害，合璧可破！")

func _heal(index: int, points: int) -> void:
	var unit := allies[index]
	var restored := mini(points, int(unit.max_hp - unit.hp))
	unit.hp += restored
	_effect("heal", "ally", index, 0, "heal", "+%d" % restored)

func _enemy_turn() -> void:
	var beat := 0
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
		enemy.resolve = false
		beat += 1
		if attack == "rally":
			foes[0].rallied = true
			_effect("cast","foe",index,beat,"guard","擂鼓")
			_effect("stance","foe",0,beat,"guard","鼓阵")
			_note("鼓阵已起，韩朔下一次受击减伤。")
			continue
		if attack == "signal":
			signal_state = "called"
			_effect("stance","foe",index,beat,"guard","鸣哨")
			_note("纸探花吹响暗哨，援兵将在次轮赶到。")
			continue
		if attack == "brace":
			enemy.poise = mini(enemy.max_poise, enemy.poise + 2)
			_effect("stance", "foe", index, beat, "guard")
			_note("%s稳住架势。" % enemy.name)
			continue
		var target := _threat_target(enemy)
		var style: String = {"sweep":"dark","charge":"cloud","strike":"blade"}[attack]
		_effect("cast", "foe", index, beat, style)
		_note("%s · %s" % [enemy.name, INTENTS[attack]])
		match attack:
			"sweep":
				for i in allies.size():
					_hurt_ally(i, roundi(enemy.attack * 0.78), beat, style,index)
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
	round_no += 1
	followup_used = false
	if signal_state == "called" and foes[1].dormant and round_no >= reinforcement_round:
		foes[1].dormant = false
		foes[1].hp = foes[1].max_hp
		_effect("arrival","foe",1,beat + 1,"dark","援兵")
	if living_foe() < 0:
		result = "victory"
	actor = 0 if allies[0].hp > 0 else 1

func _hurt_ally(index: int, points: int, beat: int, style: String, source: int) -> void:
	var unit := allies[index]
	if unit.hp <= 0:
		return
	if unit.protector >= 0:
		var protector: int = unit.protector
		unit.protector = -1
		if protector != index and allies[protector].hp > 0:
			_ally_state(index,"代挡",beat)
			index = protector
			unit = allies[index]
	var factor := (0.66 if story_mode else 1.0) * (0.34 if unit.guard else 1.0)
	if unit.ward:
		factor *= 0.45
		unit.ward = false
	var damage := maxi(1, roundi(points * factor))
	unit.hp = maxi(0, unit.hp - damage)
	_effect("damage", "ally", index, beat, "guard" if unit.guard else style, "−%d" % damage)
	if unit.hp == 0:
		_note("%s倒下。金创药可救起。" % unit.name)
	elif unit.counter and foes[source].hp > 0:
		unit.counter = false
		_hit_foe(source,unit.attack+13,1,"","blade",beat)

func _note(message: String) -> void:
	log.append(message)
	if log.size() > 10:
		log.pop_front()

