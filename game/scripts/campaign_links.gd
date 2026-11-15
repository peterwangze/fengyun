extends RefCounted

const TASKS := {
	"testimony_handoff":{"origin":"testimony","title":"水路证词","from":"凤溪客栈","to":"绝宫外庭 · 北棚",
		"source":"先在凤溪查清缺角印模和船户口供。","point":"handoff_testimony","at":Vector2(491,173),"late_at":Vector2(461,172),
		"variants":{
			"signed":{"name":"请许成和外庭接应人辨印","sprite":"boatman_front",
				"lines":[["许成","秦爷把副本和我一起送来了。青带守卫换旗时有一刻不看狱门，我愿在这里指人。"],
					["外庭接应人","我去验这份署名，让他们换班时少一个人守阵。"]],
				"late":[["许成","至尊离开后我才到。官差已收副本，我留下辨认当初押药的人。"]],
				"result":"许成当面指认差役。及时交接会让天牢卫队首敌少一格势。"},
			"sealed":{"name":"请接应人用拓印验窄门","sprite":"guard",
				"lines":[["外庭接应人","秦爷把印样托我带来，船户姓名留在凤溪。右角缺口吻合，这道窄门是他们出入天牢的地方。"],
					["外庭接应人","沿门柱遮住侧面。我把这里的护肩交给走在前面的人。"]],
				"late":[["外庭接应人","密封拓印已归档。此案可以复核原印，船户仍可不留姓名。"]],
				"result":"接应人归档密封拓印。及时交接会让步惊云带护持迎战天牢卫队。"}}},
	"medicine_handoff":{"origin":"medicine","title":"渡口药单","from":"凤溪西岸","to":"生死门药庐 · 东侧药筐",
		"source":"在凤溪验药箱和停船簿，请老船工分派干药。","point":"handoff_medicine","at":Vector2(465,183),"area":"valley_clinic",
		"variants":{"done":{"name":"和药庐值守人核对凤溪药筐","sprite":"servant",
			"lines":[["药庐值守人","筐把上写着凤溪后渡十七号。停船簿背面也记十七号，两包干药都到齐了。"],
				["药庐值守人","这一份韧丝给你缝护具。这包护脉药留给断栈运药队，我在断栈给他们加一处可走的分药棚。"]],
			"result":"断栈获得补给并开放分药棚。药单留存可为凌云山药炉战提供护持。","drop":"handoff:medicine"}}},
	"charter_handoff":{"origin":"sword_charter","title":"炉契去向","from":"拜剑山庄剑庐","to":"天下会外哨 · 旧宅",
		"source":"核对剑庐接单簿和运铁道住户，定下后棚用途。","point":"handoff_charter","at":Vector2(445,183),"area":"watch_lodge",
		"variants":{
			"commission":{"name":"与孟砺交接外哨绞索订单","sprite":"servant",
				"lines":[["孟砺","于姑娘已经盖章，外哨两道绳由我们接手。吊起工具以后，旧宅到货台可以直接乘绞盘往返。"],
					["外哨杂役","这是验收的火纹铁。等你折返山庄，东坡也能用上修具台。"]],
				"result":"工匠留在外哨修绞索。旧宅与外哨货台可乘绞盘往返。","drop":"handoff:charter_commission"},
			"refuge":{"name":"为外哨的匠户验过安置名册","sprite":"maid",
				"lines":[["匠户","于姑娘说后棚留了铺，我来领孩子和没处落脚的匠户。我们从西边沿里巷走，不必过外哨大门。"],
					["外哨杂役","我已经搬开旧宅小门。下回去剑庐问药柜，张婆婆在那里帮忙。"]],
				"result":"匠户搬去剑庐避难棚。外哨旧宅开放西边安置小门。","drop":"handoff:charter_refuge"}}},
	"register_handoff":{"origin":"watch_register","title":"两本换岗簿","from":"天下会外哨旧岗院","to":"绝宫外庭 · 旧岗接应处",
		"source":"在外哨取得换岗记录和旧岗口供，再决定具名或隐名。","point":"handoff_register","at":Vector2(516,256),"late_at":Vector2(514,250),
		"variants":{
			"public":{"name":"请旧岗证人当面核验换岗簿","sprite":"guard",
				"lines":[["旧岗证人","我从天下会来，这本有我亲手盖过的号。你们盘查的人在外哨时根本没有这个印。"],
					["外庭接应人","册上的人跟我对号。无名先生，押队分神那一刻就动手。"]],
				"late":[["旧岗证人","我已经把名字写在外哨副本上，刚搬回来的杂役也能来认。"]],
				"result":"旧岗证人公开对号。及时交接会让天牢初战多一格合击。"},
			"anonymous":{"name":"从换岗副本抄下西闸间隙","sprite":"guide",
				"lines":[["外庭接应人","我只收抄件，不问是谁送的。西闸哨灯一灭，巡卫会背对南沟。"],
					["外庭接应人","过第一道闸后，去南边找低栏活门。认准挂灯，别上巡卫的石阶。"]],
				"late":[["外庭接应人","火后撤出的巡卫名单已对清。副本仍封口，送抄件的人可以照常回乡。"]],
				"result":"匿名者仍被保护。及时交接可从西闸南沟低栏绕过一次实战。"}}},
	"carry_handoff":{"origin":"valley_carry","title":"断栈药担","from":"生死门断栈","to":"绝宫外庭 · 药担接应处",
		"source":"问药庐的许槐，在断栈高路查药担铜钩，再决定先送什么。","point":"handoff_carry","at":Vector2(303,244),"late_at":Vector2(310,249),
		"variants":{
			"medicine":{"name":"请断栈护送员交付护脉散","sprite":"servant",
				"lines":[["断栈护送员","我绕栈下浅滩把药送到了。护脉散一包，给随身药囊。"],
					["断栈护送员","另一包留在茶房外的木匣。让无名先生开战前先服，能护住他一次。"]],
				"late":[["断栈护送员","药担已抬到外庭，剩下一包交你的药囊。其他的留给烧伤的人。"]],
				"result":"药囊得护脉散，及时交接会让无名带护持对付绝无神。","supply":"handoff:carry_medicine"},
			"breath":{"name":"听断栈护送员转达换气字条","sprite":"servant",
				"lines":[["断栈护送员","邪皇叫我记住，绝无神连出重拳时，第二口气要接在沉肩以后。"],
					["断栈护送员","别等他把拳抬到胸口。趁沉肩打断，金身开场就能少一格势。"]],
				"late":[["断栈护送员","换气字条送来晚了，留给外庭操练的弟子作记录。"]],
				"result":"换气口诀已送到。及时交接会削弱绝无神的起手架势。"}}},
}

static func receive_points(slot: Dictionary, room: String, area: String = "") -> Array:
	var facts: Dictionary = slot.world.tasks
	var result := []
	for key in TASKS:
		var task: Dictionary = TASKS[key]
		var regional: String = task.get("area","")
		if regional != "":
			if regional != area:
				continue
		elif not ((room == "palace" and area.is_empty() and slot.chapter == 4) or area in ["watch_palace_reception","palace_court"]):
			continue
		var branch: Dictionary = task.variants.get(facts.get(task.origin,""),{})
		if branch.is_empty():
			continue
		var received := facts.has(key)
		var after_departure: bool = area == "watch_palace_reception" or (area == "palace_court" and slot.chapter >= 5)
		var position: Vector2 = task.get("late_at",task.at) if after_departure else task.at
		var late: bool = after_departure or (slot.chapter == 4 and room == "palace"
			and (slot.cleared.has(1) if key == "carry_handoff" else slot.cleared.has(0)))
		var lines: Array = branch.get("late",branch.lines) if late else branch.lines
		if received:
			lines = [["交接记档",branch.result]]
		result.append({"id":task.point,"pos":position,"index":-1,"sprite":branch.sprite,
			"handoff":true,"name":("查看 · " + task.title) if received else branch.name,
			"lines":lines,"evidence":"" if received else key})
	return result

static func reward(slot: Dictionary, key: String) -> Dictionary:
	var task: Dictionary = TASKS.get(key,{})
	return task.variants[slot.world.tasks[task.origin]] if not task.is_empty() else {}
