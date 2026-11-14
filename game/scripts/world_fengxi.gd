extends RefCounted

const TITLE := "凤溪渡口"
const VISIT_LABEL := "回访凤溪"
const JOURNAL_TITLE := "凤溪手记"
const ENTRY := "shore"
const PHASES := {"evidence":"戒严取证","blockade":"封渡换岗","reopened":"渡口复航"}

static func unlocked(slot: Dictionary) -> bool:
	var chapter: int = slot.get("chapter",0)
	return chapter >= 2 or (chapter == 1 and
		(slot.get("cleared",[]).has(1) or slot.get("journey",{}).get("done",{}).has("lanes_done")))

static func phase(slot: Dictionary) -> String:
	var chronicle: Dictionary = slot.get("chronicle",{})
	if slot.finished or chronicle.get("marks",{}).has("dawn_lamp") or chronicle.get("room","") == "dawn":
		return "reopened"
	return "blockade" if slot.chapter >= 2 else "evidence"

static func music(current_phase: String, field: String) -> String:
	return "dawn" if current_phase == "reopened" else ("inn" if field == "inn" else "village")

const AREAS := {
	"shore":{
		"field":"village","spawn":"west_spawn","phase_fields":{"reopened":"dawn"},
		"title":"凤溪 · 西岸渡口",
	},
	"inn":{"field":"inn","spawn":"spawn","title":"凤溪 · 西岸客栈"},
	"lanes":{"field":"fengxi_lanes","spawn":"spawn","title":"凤溪 · 渡口雨巷"},
}

const QUESTS := [
	{"id":"testimony","title":"水路证词","evidence":["stencil","witness"],
		"outcomes":["signed","sealed"],"delivery_phases":["blockade","reopened"],"receipt_phases":["reopened"],"source":"quest:fengxi_testimony",
		"description":"查雨巷货棚的印模，问西岸客栈里避风的船户。两头都能先去。",
		"locked":"封渡以后，回客栈交接两份证物。",
		"ready":"回西岸客栈，决定署名还是密封。",
		"reward":"水路印绳 · 克制时多削 1 格势，真气上限减 3。","follow_up":"复航后，去西岸查看证人或回客栈查收回执。","receipt":"testimony_receipt"},
	{"id":"medicine","title":"渡口药单","evidence":["crate","roster"],
		"outcomes":["done"],"delivery_phases":["blockade","reopened"],"receipt_phases":["reopened"],"source":"quest:fengxi_medicine",
		"description":"验雨巷药箱，核对西岸停船簿。两头都能先去。",
		"locked":"封渡以后，找西岸老船工分药。",
		"ready":"西岸船篷旁有老船工，可凭药单分药。",
		"reward":"草药护衣 · 加强治疗和护持减伤，气血上限减 8。另开后渡近路。","follow_up":"复航后，去雨巷东货棚核对领药回条。","receipt":"medicine_receipt"},
]

const POINTS := [
	{"id":"world_inn","area":"shore","at":Vector2(98,174),"name":"进西岸客栈",
		"prop":"exit_open","destination":"inn"},
	{"id":"world_lanes","area":"shore","at":Vector2(174,220),"name":"沿石堤进渡口雨巷",
		"prop":"exit_open","destination":"lanes"},
	{"id":"world_shore","area":"inn","at":Vector2(319,286),"name":"回西岸渡口",
		"prop":"exit_open","destination":"shore"},
	{"id":"world_shore","area":"lanes","at":Vector2(116,232),"name":"沿石堤回西岸渡口",
		"prop":"exit_open","destination":"shore"},
	{"id":"world_return","area":"inn","at":Vector2(114,238),"name":"回出发地，继续主线",
		"prop":"exit"},
	{"id":"world_stencil","area":"lanes","at":Vector2(552,190),"name":"比对货棚的缺角印模",
		"prop":"chest","evidence":"stencil","excludes":"stencil",
		"lines":[["船户留下的纸条","旧印是左角磕损。这只木模缺的是右角，还沾着漆。拿它压在清纸上，便能看清两枚印怎么不同。"]]},
	{"id":"world_witness","area":"inn","at":Vector2(238,225),"name":"向避风的船户核对印信",
		"sprite":"boatman_front","evidence":"witness","excludes":"witness",
		"lines":[["船户","我叫许成。那晚我把药箱送到棚下，亲眼见他们换掉押箱的号牌。新印一压下去，右角露白。带我去验印可以，得先安顿好孩子。"]]},
	{"id":"world_seal","area":"inn","at":Vector2(379,197),"name":"交接水路证词",
		"prop":"signal","phases":["blockade","reopened"],"requires":["stencil","witness"],
		"excludes":"testimony","result":"testimony","choices":[["署上许成姓名","signed"],["密封姓名，留印样","sealed"]],
		"note":"署名请许成辨认差役。封名可护住家人，由验印人凭拓印查窄门。"},
	{"id":"world_crate","area":"lanes","at":Vector2(1233,263),"name":"从货棚药箱验药",
		"prop":"chest","evidence":"crate","excludes":"crate",
		"lines":[["第二梦的签条","开过封的药里混了雨水。隔板下面还有两包扎紧的草药，照停船簿背面的记号找领药人。"]]},
	{"id":"world_roster","area":"shore","at":Vector2(101,260),"name":"核对西岸停船簿",
		"prop":"signal","evidence":"roster","excludes":"roster",
		"lines":[["停船簿","画叶子的那两户，一户在后渡等药，一户已移到谷口药庐。西岸老船工认得名册，配齐药再请他行船。"]]},
	{"id":"world_medicine","area":"shore","at":Vector2(146,281),"name":"请老船工照药单分派",
		"sprite":"boatman_front","phases":["blockade","reopened"],"requires":["crate","roster"],
		"excludes":"medicine","result":"medicine",
		"lines":[["老船工","两包都没湿。一包给后渡的陈嫂，一包沿旧渡送药庐。我把西岸后渡的铜钩交你，从这边能直接到雨巷东货棚。"],
			["老船工","第二姑娘缝的草药护衣也在我这儿。她托我交给肯把干药送到病人手上的人。"]]},
	{"id":"world_testimony_receipt","area":"shore","at":Vector2(139,188),"name":"在复航处见到许成",
		"sprite":"boatman_front","phases":["reopened"],"matches":{"testimony":"signed"},
		"evidence":"testimony_receipt",
		"lines":[["许成","如今渡口开了，我连名带船都回西岸了。等哪户人说自己从没领到官粮，可以直接找我作证。"]]},
	{"id":"world_testimony_receipt","area":"inn","at":Vector2(378,197),"name":"查收验印人的密封回执",
		"prop":"chest","phases":["reopened"],"matches":{"testimony":"sealed"},"evidence":"testimony_receipt",
		"lines":[["回执","验印人确认两枚印信不同。船户姓名未载入公簿，拓印原件已退回客栈。"]]},
	{"id":"world_medicine_receipt","area":"lanes","at":Vector2(1261,233),"name":"在东货棚核对两份领药回条",
		"prop":"signal","phases":["reopened"],"requires":["medicine"],"evidence":"medicine_receipt",
		"lines":[["领药回条","后渡陈嫂领到一包，谷口药庐领到一包。下次从凤溪往山上送药，可沿后渡交班。"],
			["送药人","剩下的药包留在渡口柜上。以后就照这个单子备药。"]]},
	{"id":"world_shortcut","area":"shore","at":Vector2(187,282),"name":"放下后渡踏板，直去东货棚",
		"prop":"boat","destination":"lanes","arrival":Vector2(1310,253),"requires":["medicine"]},
	{"id":"world_shortcut","area":"lanes","at":Vector2(1340,266),"name":"搭后渡小船回西岸",
		"prop":"boat","destination":"shore","arrival":Vector2(170,269),"requires":["medicine"]},
	{"id":"world_watch","area":"shore","at":Vector2(208,183),"name":"看西岸查验牌",
		"prop":"signal","phases":["evidence"],
		"lines":[["查验牌","渡船还可停岸。过西岸的货单要由值守验印，持封门令的货单单独扣查。客栈照常供补给。"]]},
	{"id":"world_watch","area":"shore","at":Vector2(230,254),"name":"询问封渡换岗的巡卫",
		"sprite":"guard","phases":["blockade"],
		"lines":[["巡卫","自鸣哨起，正埠不再开船，客栈停卖补给。岸上的人可以去客栈过夜，雨巷也还走得通。"]]},
	{"id":"world_watch","area":"shore","at":Vector2(64,219),"name":"查看正埠复航的绞缆架",
		"prop":"winch","phases":["reopened"],
		"lines":[["渡工","封渡的绳已撤了，孩子和药担先上船。客栈也把后仓的货摆出来了。"]]},
	{"id":"world_shop","area":"inn","at":Vector2(548,246),"name":"向凤溪行商购买补给",
		"sprite":"servant","shop":"inn","phases":["evidence","reopened"]},
	{"id":"world_shop","area":"inn","at":Vector2(548,246),"name":"询问停卖的凤溪行商",
		"sprite":"servant","closed":true,"phases":["blockade"],
		"lines":[["凤溪行商","巡卫换岗后封了货架。店里有空铺可以避雨，补给要等渡口开了才能卖。"]]},
	{"id":"world_lane_returned","area":"lanes","at":Vector2(1109,245),"name":"看雨巷复运的货牌",
		"prop":"signal","phases":["reopened"],
		"lines":[["新挂的货牌","药箱放上层，米粮靠背墙。正埠复航，请先让领药的病家过。"]]},
]
