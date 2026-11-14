extends RefCounted

const TITLE := "拜剑山庄"
const VISIT_LABEL := "回访拜剑山庄"
const JOURNAL_TITLE := "山庄手记"
const ENTRY := "sword_workshop"
const PHASES := {"seized":"封炉扣料","rekindled":"开炉复工","settled":"山庄安顿"}

static func unlocked(slot: Dictionary) -> bool:
	var chapter: int = slot.get("chapter",0)
	return chapter >= 3 or (chapter == 2 and (slot.get("campaign",{}).get("sword",false)
		or slot.get("cleared",[]).has(0) or slot.get("journey",{}).get("done",{}).has("pass_done")))

static func phase(slot: Dictionary) -> String:
	if slot.chapter >= 3:
		return "settled"
	return "rekindled" if slot.get("campaign",{}).get("sword",false) else "seized"

static func music(_current_phase: String, field: String) -> String:
	return "swordhall" if field == "swordhall" else "forge"

const AREAS := {
	"sword_workshop":{
		"field":"swordhall","spawn":"spawn","title":"拜剑山庄 · 剑庐作坊",
	},
	"sword_road":{
		"field":"lantern_pass","spawn":"spawn","title":"拜剑山庄 · 运铁山隘",
	},
}

const QUESTS := [
	{"id":"sword_supply","title":"山隘封铁","evidence":["sword_maker","sword_cache"],
		"description":"在剑庐问孟砺，在运铁道南坡找被扣的铁箱。两处都可先查。",
		"locked":"剑池封锁解除后，回剑庐把铁料交给孟砺。",
		"ready":"回剑庐炉边退还铁料，修好运铁绞索。",
		"reward":"火纹铁与韧丝各一份，开放双向运铁绞梯。",
		"follow_up":"山庄安顿后，可去运铁道东坡核对首批铁料。",
		"receipt":"sword_supply_receipt","source":"quest:sword_supply","outcomes":["done"],
		"delivery_phases":["rekindled","settled"],"receipt_phases":["settled"]},
	{"id":"sword_charter","title":"一间作坊，两份托付","evidence":["sword_ledger","sword_keeper"],
		"description":"看剑庐里的接单簿，和运铁道北坡的看门人谈谈。可先做任一件。",
		"locked":"剑池封锁解除后，和于楚楚商议后棚的用处。",
		"ready":"回剑庐找于楚楚，决定后棚继续接单还是收留匠户。",
		"reward":"工钱 4 两。安顿后开东坡修具台或避难棚药柜。",
		"follow_up":"山庄安顿后，去运铁道东坡看后棚交接回执。",
		"receipt":"sword_charter_receipt","source":"quest:sword_charter","outcomes":["commission","refuge"],
		"delivery_phases":["rekindled","settled"],"receipt_phases":["settled"]},
]

const POINTS := [
	{"id":"world_sword_road","area":"sword_workshop","at":Vector2(552,274),
		"name":"从剑庐下到运铁道","prop":"exit_open","destination":"sword_road"},
	{"id":"world_sword_workshop","area":"sword_road","at":Vector2(121,224),
		"name":"沿西侧石阶回剑庐","prop":"exit_open","destination":"sword_workshop"},
	{"id":"world_return","area":"sword_workshop","at":Vector2(89,276),
		"name":"回出发地，继续主线","prop":"exit"},
	{"id":"world_sword_maker","area":"sword_workshop","at":Vector2(143,193),
		"name":"问学徒孟砺铁车为何没有回来","sprite":"servant","evidence":"sword_maker",
		"lines":[["孟砺","车轴虽断了，车下那匣铁料还有用。左边封扣打了三颗钉，里头才是我们的铁。"],
			["孟砺","要是匣子还在南坡，就帮我带回来。我缺这块铁修绞索，车进不了庄，山上的伤腿工人也下不来。"]]},
	{"id":"world_sword_cache","area":"sword_road","at":Vector2(745,273),
		"name":"夺回南坡的三钉铁匣","sprite":"smith","foes":["smith","blade"],"evidence":"sword_cache",
		"lines":[["剑池执剑人","断浪让我们守着这批铁。剑池那边旗换了也不算，谁开匣我就找谁。"],
			["南坡铁车","车下铁匣的左边封扣打着三颗钉。两名执剑人堵住了车道。"]]},
	{"id":"world_sword_supply","area":"sword_workshop","at":Vector2(188,246),
		"name":"把铁料交给孟砺修绞索","sprite":"servant","phases":["rekindled","settled"],
		"requires":["sword_maker","sword_cache"],"result":"sword_supply","excludes":"sword_supply",
		"lines":[["孟砺","我用好铁铸了新棘齿。绞梯又能载人载货了，剑庐这一头直通东坡。"],
			["孟砺","箱底那块火纹铁和缠缆绳的韧丝你带着。要修护具，拿到锻台就能用。"]]},
	{"id":"world_sword_ledger","area":"sword_workshop","at":Vector2(289,172),
		"name":"翻看没结清的修具接单簿","prop":"chest","evidence":"sword_ledger",
		"lines":[["接单簿","三户的镰和锄还没打磨。后棚能架修具台，但山腰的三家匠户这几日也没有住处。"]]},
	{"id":"world_sword_keeper","area":"sword_road","at":Vector2(438,178),
		"name":"问北坡看门人谁还没下山","sprite":"guide","evidence":"sword_keeper",
		"lines":[["看门人","张婆婆要等两个孩子到齐才肯下山。余下两户倒是到了石棚，只等雨停。"],
			["看门人","剑庐肯腾后棚，我们就领他们来借住。若棚里还要开工，就把门板锯好，我先替他们挡两夜雨。"]]},
	{"id":"world_sword_charter","area":"sword_workshop","at":Vector2(397,176),
		"name":"与于楚楚定下后棚用途","sprite":"chuchu","phases":["rekindled","settled"],
		"requires":["sword_ledger","sword_keeper"],"result":"sword_charter","excludes":"sword_charter",
		"choices":[["架台接单，托工匠送修具","commission"],["移开炉台，给匠户留铺","refuge"]],
		"note":"接单会开东坡修具台。留铺会开避难棚药柜，看门人另寻修具处。"},
	{"id":"world_sword_shortcut","area":"sword_workshop","at":Vector2(219,203),
		"name":"乘运铁绞梯直上东坡","prop":"winch","destination":"sword_road","arrival":Vector2(1315,183),
		"requires":["sword_supply"]},
	{"id":"world_sword_shortcut","area":"sword_road","at":Vector2(1344,188),
		"name":"乘运铁绞梯回剑庐","prop":"winch","destination":"sword_workshop","arrival":Vector2(237,221),
		"requires":["sword_supply"]},
	{"id":"world_sword_supply_receipt","area":"sword_road","at":Vector2(1186,239),
		"name":"在东坡查看首批复运铁料","prop":"chest","requires":["sword_supply"],
		"phases":["settled"],"evidence":"sword_supply_receipt",
		"lines":[["运铁工","第一筐已经送到了。绞索试过，把载几人、载多少铁都刻在木牌上了。"],
			["运铁工","今天先让脚伤的工人下山。往后哪节索松了，他们也知道该怎么换。"]]},
	{"id":"world_sword_charter_receipt","area":"sword_road","at":Vector2(1260,242),
		"name":"查东坡修具订单","prop":"signal","matches":{"sword_charter":"commission"},
		"phases":["settled"],"evidence":"sword_charter_receipt",
		"lines":[["于楚楚","第一家的锄刃已经送回去了。接单的工钱先付给上山搭棚的人，张婆婆那间临时铺也加了门板。"],
			["于楚楚","东坡这张台留给赶路的人。铁料够就能在这儿修，不必把钝家伙背回剑庐。"]]},
	{"id":"world_sword_charter_receipt","area":"sword_road","at":Vector2(1260,242),
		"name":"去东坡看看匠户的新铺位","sprite":"chuchu","matches":{"sword_charter":"refuge"},
		"phases":["settled"],"evidence":"sword_charter_receipt",
		"lines":[["于楚楚","张婆婆一家搬到了内屋。把炉旁的三张旧桌拆开，正好够搭几张铺。"],
			["于楚楚","药师替他们看过伤，剩下的药可以在棚门口买。欠修的农具，等匠户有空就在家里磨。"]]},
	{"id":"world_sword_commission_forge","area":"sword_road","at":Vector2(1266,197),
		"name":"在东坡用修具台","sprite":"guide","forge":"swordhall",
		"phases":["settled"],"matches":{"sword_charter":"commission"}},
	{"id":"world_sword_refuge_shop","area":"sword_road","at":Vector2(1266,197),
		"name":"到避难棚药柜添补给","sprite":"servant","shop":"sword_refuge",
		"phases":["settled"],"matches":{"sword_charter":"refuge"}},
	{"id":"world_sword_post","area":"sword_road","at":Vector2(257,250),
		"name":"看封炉的白灰牌","prop":"signal","phases":["seized"],
		"lines":[["白灰牌","炉口归剑池的人看守。北坡绕开扣料岗，南坡还扣着一匣铁。剑庐此时只留人歇脚。"]]},
	{"id":"world_sword_post","area":"sword_road","at":Vector2(936,240),
		"name":"查看复炉的运货旗","prop":"signal","phases":["rekindled"],
		"lines":[["运货旗","断浪已经走了，修具台可以生火。三钉匣的铁要先交孟砺，后棚要用来做什么听于楚楚安排。"]]},
	{"id":"world_sword_post","area":"sword_road","at":Vector2(1421,199),
		"name":"查看山庄安顿后的值守牌","prop":"signal","phases":["settled"],
		"lines":[["值守牌","修具、点货和借铺都在东坡登记。没安顿的匠户可先去西坡剑庐找于楚楚。"]]},
]
