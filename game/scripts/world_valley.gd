extends RefCounted

const TITLE := "生死门"
const VISIT_LABEL := "回访生死门"
const JOURNAL_TITLE := "生死门手记"
const ENTRY := "valley_clinic"
const PHASES := {"trial":"候试刀","withdrawal":"拔栅撤离","relief":"谷口救护"}

static func unlocked(slot: Dictionary) -> bool:
	var chapter: int = slot.get("chapter",0)
	var marks: Dictionary = slot.get("chronicle",{}).get("marks",{})
	return chapter >= 4 or (chapter == 3 and (marks.has("pool_intro") or marks.has("pool_gate")
		or slot.get("campaign",{}).get("pool_trial",false) or slot.get("cleared",[]).has(0)))

static func phase(slot: Dictionary) -> String:
	if slot.chapter >= 4:
		return "relief"
	var marks: Dictionary = slot.get("chronicle",{}).get("marks",{})
	return "withdrawal" if marks.has("pool_gate") or marks.has("pool_escape") or slot.cleared.has(1) else "trial"

static func music(current_phase: String, field: String) -> String:
	if current_phase == "withdrawal":
		return "blood"
	return "inn" if field == "apothecary" else "pool"

const AREAS := {
	"valley_clinic":{"field":"apothecary","spawn":"spawn","title":"生死门 · 谷口药庐"},
	"valley_trestle":{"field":"broken_trestle","spawn":"spawn","title":"生死门 · 断栈"},
}

const QUESTS := [
	{"id":"valley_carry","title":"断栈药担","evidence":["valley_porter","valley_carry_hook"],
		"description":"在药庐问挑药的许槐，去断栈高路找旧药担上的铜钩。两条线索都可先查。",
		"locked":"魔池一带开始撤人后，许槐才会挑药下谷，可先查清货和路。",
		"ready":"回药庐请许槐带护脉药或邪皇的换气字条去绝宫前庭。",
		"reward":"获盘缠和韧丝。药品护人，字条能在交手时拆金身。",
		"follow_up":"去绝宫前庭交接。谷口救护期间可向断栈东坡的背药人打听去向。",
		"receipt":"valley_carry_receipt","source":"quest:valley_carry","outcomes":["medicine","breath"],
		"delivery_phases":["withdrawal","relief"],"receipt_phases":["relief"]},
	{"id":"valley_latch","title":"给伤者让条干路","evidence":["valley_cot","valley_chain"],
		"description":"查看药庐担架磨痕，去断栈石阶核对旧升担架的铁链。",
		"locked":"可先查担架和链子。刀皇破门后，需要把撤离队绕开湿木板。",
		"ready":"回药庐找戚药师换担架扣，重新开通东坡的升担架。",
		"reward":"获护脉散和韧丝。药庐与断栈东坡之间开放双向升担架。",
		"follow_up":"谷口救护期间在断栈东坡看新担架的交班记。",
		"receipt":"valley_latch_receipt","source":"quest:valley_latch","supply":"quest:valley_latch","outcomes":["done"],
		"delivery_phases":["withdrawal","relief"],"receipt_phases":["relief"]},
]

const POINTS := [
	{"id":"world_valley_trestle","area":"valley_clinic","at":Vector2(562,219),
		"name":"出药庐东门到断栈","prop":"exit_open","destination":"valley_trestle"},
	{"id":"world_valley_clinic","area":"valley_trestle","at":Vector2(119,231),
		"name":"沿西坡石径回谷口药庐","prop":"exit_open","destination":"valley_clinic","arrival":Vector2(542,249)},
	{"id":"world_return","area":"valley_clinic","at":Vector2(318,294),
		"name":"离开药庐，回出发地","prop":"exit"},
	{"id":"world_valley_porter","area":"valley_clinic","at":Vector2(168,182),
		"name":"问许槐带什么过山","sprite":"servant","evidence":"valley_porter",
		"lines":[["许槐","我背药篓给池边的人换药，走夜路背不动两份。断栈东坡还有几只篓，也能递封信。"],
			["许槐","去高栈西端看那副旧担子。邪皇怕换气诀窍被偷，在铜钩背面刻了后半句。"]]},
	{"id":"world_valley_carry_hook","area":"valley_trestle","at":Vector2(448,167),
		"name":"查看高路药担铜钩","prop":"chest","evidence":"valley_carry_hook",
		"lines":[["药担铜钩","绝无神收拳绕肘时，金身从胸前换气。拳掌压住肘，刀剑直取空门。"],
			["旧药签","未浸水的护脉粉在许槐那儿。两件分开走时，只能先保一件过绝宫岗门。"]]},
	{"id":"world_valley_carry","area":"valley_clinic","at":Vector2(202,224),
		"name":"和许槐确定先送哪件","sprite":"servant","phases":["withdrawal","relief"],
		"requires":["valley_porter","valley_carry_hook"],"result":"valley_carry","excludes":"valley_carry",
		"choices":[["给绝宫接应人护脉药","medicine"],["带邪皇的换气字条过去","breath"]],
		"note":"药给前庭伤者和迎敌的人，字条提示金身的开场破绽。到绝宫前庭找接应人点收。"},
	{"id":"world_valley_cot","area":"valley_clinic","at":Vector2(388,275),
		"name":"检查南墙边的旧担架","prop":"chest","evidence":"valley_cot",
		"lines":[["旧担架","脚板被水泡得发白，侧绳是从外面磨开的。把担架托到高处，能避开涨水。"]]},
	{"id":"world_valley_chain","area":"valley_trestle","at":Vector2(961,252),
		"name":"查看断栈石阶外的升担铁链","prop":"winch","evidence":"valley_chain",
		"lines":[["坡上铁链","石阶从断栈直升药庐后坡。铁链完好，短的是挂担架的两个扣子。"]]},
	{"id":"world_valley_latch","area":"valley_clinic","at":Vector2(268,199),
		"name":"找戚药师换担架扣","sprite":"guide","phases":["withdrawal","relief"],
		"requires":["valley_cot","valley_chain"],"result":"valley_latch","excludes":"valley_latch",
		"lines":[["戚药师","换下来的扣子已经裂了。两头都扣紧，拉上去时就不用人下水托。"],
			["戚药师","东坡担架有一口空箱。给你留了护脉药和修护具的丝，出谷的人也用得上。"]]},
	{"id":"world_valley_shortcut","area":"valley_clinic","at":Vector2(416,218),
		"name":"乘升担架走药庐后坡","prop":"winch","destination":"valley_trestle","arrival":Vector2(1285,237),
		"requires":["valley_latch"]},
	{"id":"world_valley_shortcut","area":"valley_trestle","at":Vector2(1318,232),
		"name":"沿升担铁链直回谷口药庐","prop":"winch","destination":"valley_clinic","arrival":Vector2(434,244),
		"requires":["valley_latch"]},
	{"id":"world_valley_carry_receipt","area":"valley_trestle","at":Vector2(1229,257),
		"name":"问背药人护脉药的去处","sprite":"servant",
		"matches":{"valley_carry":"medicine"},"phases":["relief"],"evidence":"valley_carry_receipt",
		"lines":[["背药人","许槐用油布裹了药，能走到前庭。那边有人在门廊收药，山下的伤者也能跟着去。"]]},
	{"id":"world_valley_carry_receipt","area":"valley_trestle","at":Vector2(1229,257),
		"name":"问背药人换气字条的去处","sprite":"servant",
		"matches":{"valley_carry":"breath"},"phases":["relief"],"evidence":"valley_carry_receipt",
		"lines":[["背药人","许槐把字条夹进担绳里。送到前庭再解开，门里的人听不见邪皇怎么说。"]]},
	{"id":"world_valley_latch_receipt","area":"valley_trestle","at":Vector2(1406,221),
		"name":"看升担架的救护交班记","prop":"signal","requires":["valley_latch"],
		"phases":["relief"],"evidence":"valley_latch_receipt",
		"lines":[["东坡交班记","一班用升担架送出三名伤者，二班接住孩子和药篓。雨后泥深，旧浅滩只留空担走。"]]},
	{"id":"world_valley_relief_runner","area":"valley_trestle","at":Vector2(619,274),
		"name":"问护送队领到哪批药","sprite":"servant","requires":["medicine_handoff"],
		"lines":[["断栈护送人","药庐给我的纸签也画了一片叶子。给病人换完药，还剩一包防潮的护具料。要领路，跟我从浅滩上来。"]]},
	{"id":"world_valley_medicine_pass","area":"valley_trestle","at":Vector2(656,273),
		"name":"沿送药人的石阶避开湿桥","prop":"exit_open","destination":"valley_trestle","arrival":Vector2(1078,224),
		"requires":["medicine_handoff"]},
	{"id":"world_valley_medicine_pass","area":"valley_trestle","at":Vector2(1050,244),
		"name":"从石阶回送药人的浅滩据点","prop":"exit_open","destination":"valley_trestle","arrival":Vector2(671,270),
		"requires":["medicine_handoff"]},
	{"id":"world_valley_notice","area":"valley_clinic","at":Vector2(359,176),
		"name":"查药庐今日开锅时辰","prop":"signal","phases":["trial"],
		"lines":[["药庐用药牌","试刀前先来辨脉。池边的药封在右柜，山道挑药的人从东门进。"]]},
	{"id":"world_valley_notice","area":"valley_trestle","at":Vector2(291,219),
		"name":"接应灌木旁撤下的伤者","sprite":"guide","phases":["withdrawal"],
		"lines":[["驻谷弟子","刀皇砸了池门。别去摸裂掉的护栏，轻伤的沿石路走，抬不动的要找铁链。"]]},
	{"id":"world_valley_notice","area":"valley_clinic","at":Vector2(510,277),
		"name":"查看药庐新铺的担位","prop":"signal","phases":["relief"],
		"lines":[["救护木牌","药碗用好放在担架边，旧铜绳带去东坡交班。要去找断栈的人，从东门上谷。"]]},
	{"id":"world_valley_shop","area":"valley_clinic","at":Vector2(544,173),
		"name":"向药庐药师添补药品","sprite":"guide","shop":"medicine","phases":["relief"]},
]
