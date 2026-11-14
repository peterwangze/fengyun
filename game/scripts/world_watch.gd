extends RefCounted

const TITLE := "天下会外哨"
const VISIT_LABEL := "回访天下会外哨"
const JOURNAL_TITLE := "外哨手记"
const ENTRY := "watch_lodge"
const PHASES := {"sealed":"师门封岗","occupied":"东瀛接管","witness":"旧岗作证"}

static func unlocked(slot: Dictionary) -> bool:
	var chapter: int = slot.get("chapter",0)
	var marks: Dictionary = slot.get("chronicle",{}).get("marks",{})
	return chapter >= 3 or (chapter == 2 and (marks.has("first_tyrant") or marks.has("invaded")
		or slot.get("journey",{}).get("done",{}).has("watch_done")))

static func phase(slot: Dictionary) -> String:
	if slot.chapter >= 4:
		return "witness"
	var marks: Dictionary = slot.get("chronicle",{}).get("marks",{})
	return "occupied" if slot.chapter >= 3 or marks.has("invaded") else "sealed"

static func music(current_phase: String, field: String) -> String:
	return "palace" if current_phase == "occupied" or field == "palace" else "hall"

const AREAS := {
	"watch_lodge":{"field":"returnhall","spawn":"spawn","title":"天下会外哨 · 旧岗院"},
	"watch_road":{"field":"outer_watch","spawn":"spawn","title":"天下会外哨 · 林道岗门"},
	"watch_palace_reception":{"field":"palace","spawn":"spawn","title":"无神绝宫 · 战后前庭"},
}

const QUESTS := [
	{"id":"watch_register","title":"两本换岗簿","evidence":["watch_witness","watch_transfer_log"],
		"description":"在旧岗院问范著，在林道中段岗门看接管簿。两处都能先查。",
		"locked":"等飞云堂外换旗，回旧岗院让范著核对两本簿子。",
		"ready":"回旧岗院西侧找范著，商议带人出面还是抄下换岗时刻。",
		"reward":"获盘缠和锻材。将人证或匿名副页交给绝宫前庭接应人。",
		"follow_up":"赴绝宫前庭交换岗簿。可在旧岗作证时回林道东岗查看留记。",
		"receipt":"watch_register_receipt","source":"quest:watch_register",
		"outcomes":["public","anonymous"],"delivery_phases":["occupied","witness"],"receipt_phases":["witness"]},
	{"id":"watch_relay","title":"封岗后的灯线","evidence":["watch_cut_rope","watch_signal_guard"],
		"description":"查旧岗院西角的断绳，夺回林道东侧灯轮。灯轮有巡山人扣守。",
		"locked":"换旗前不宜升灯，先收齐零件。飞云堂变故后找掌灯人装回去。",
		"ready":"回旧岗院的石灯台修灯线，由西坡给东岗打信号。",
		"reward":"获锻材，开放旧岗院与东岗之间的双向巡灯吊篮。",
		"follow_up":"旧岗作证时，走吊篮到林道东岗检查灯线交接。",
		"receipt":"watch_relay_receipt","source":"quest:watch_relay","outcomes":["done"],
		"delivery_phases":["occupied","witness"],"receipt_phases":["witness"]},
]

const POINTS := [
	{"id":"world_watch_road","area":"watch_lodge","at":Vector2(565,158),
		"name":"从院东门走林道","prop":"exit_open","destination":"watch_road"},
	{"id":"world_watch_lodge","area":"watch_road","at":Vector2(119,229),
		"name":"进西岗门回旧岗院","prop":"exit_open","destination":"watch_lodge","arrival":Vector2(534,182)},
	{"id":"world_return","area":"watch_lodge","at":Vector2(72,267),
		"name":"离开外哨，回出发地","prop":"exit"},
	{"id":"world_watch_to_reception","area":"watch_lodge","at":Vector2(533,268),
		"name":"沿开禁后的驿道往绝宫前庭","prop":"exit_open","destination":"watch_palace_reception",
		"min_chapter":5},
	{"id":"world_watch_from_reception","area":"watch_palace_reception","at":Vector2(545,281),
		"name":"沿山外驿道回旧岗院","prop":"exit_open","destination":"watch_lodge","arrival":Vector2(504,250)},
	{"id":"world_watch_reception_notice","area":"watch_palace_reception","at":Vector2(451,218),
		"name":"读绝宫前庭新立的案牌","prop":"signal",
		"lines":[["案牌","火后内院仍在清理，外庭每日有人收证据、安置归户。证人和药工可从山外驿道安全出入。"]]},
	{"id":"world_watch_witness","area":"watch_lodge","at":Vector2(210,204),
		"name":"问旧门录事范著","sprite":"servant","evidence":"watch_witness",
		"lines":[["范著","原簿每逢换岗画一道月牙。新来的人抄得出名字，抄不出那道月牙。"],
			["范著","我把旧簿夹进了药篓，接管簿还在林道中段岗门。两本合起来，才知道人被换去哪里。"]]},
	{"id":"world_watch_transfer_log","area":"watch_road","at":Vector2(565,192),
		"name":"查林道岗门的接管簿","prop":"chest","evidence":"watch_transfer_log",
		"lines":[["接管簿","第四班名单盖着至尊印，同一刻又盖在后半夜的领灯账上。交班要等第二声空梆。"],
			["旧簿夹条","人证可以对名册。若来不了，抄下两页不同的时刻，照空梆停灯的间隙过岗。"]]},
	{"id":"world_watch_register","area":"watch_lodge","at":Vector2(177,238),
		"name":"和范著定下如何送两本簿子","sprite":"servant","phases":["occupied","witness"],
		"requires":["watch_witness","watch_transfer_log"],"result":"watch_register","excludes":"watch_register",
		"choices":[["请范著到绝宫前庭当面作证","public"],["把名字抹去，只送换岗时刻","anonymous"]],
		"note":"署名可请卫队核验，匿名可照两声空梆走巡逻空档。两路都要赴绝宫前庭交接。"},
	{"id":"world_watch_cut_rope","area":"watch_lodge","at":Vector2(114,214),
		"name":"查看旧岗院西角的断绳","prop":"winch","evidence":"watch_cut_rope",
		"lines":[["旧灯架","吊篮绳从内侧割断，铜轮也不见了。石台上有人用炭写下：东岗巡山人拿去抵饷。"]]},
	{"id":"world_watch_signal_guard","area":"watch_road","at":Vector2(1120,231),
		"name":"向封岗执事夺回灯轮","sprite":"guard","foes":["guard","blade"],"evidence":"watch_signal_guard",
		"phases":["sealed"],
		"lines":[["封岗执事","帮主议事，各岗都熄灯。铜轮要扣到他发话。"],
			["巡山刀客","谁还想把人往东送，得先过我这关。"]]},
	{"id":"world_watch_signal_guard","area":"watch_road","at":Vector2(1120,231),
		"name":"向东岗巡山人夺回灯轮","sprite":"guard","foes":["invader","shade"],"evidence":"watch_signal_guard",
		"phases":["occupied","witness"],
		"lines":[["巡山人","这盏灯一升，西边的人就知道怎么避开我们。谁也不许碰铜轮！"],
			["灯架","铜轮卡在东岗侧面。拔出销子前，得先让挡路的两人退开。"]]},
	{"id":"world_watch_relay","area":"watch_lodge","at":Vector2(326,228),
		"name":"和掌灯人接好巡灯绳","sprite":"guide","phases":["occupied","witness"],
		"requires":["watch_cut_rope","watch_signal_guard"],"result":"watch_relay","excludes":"watch_relay",
		"lines":[["掌灯人","轮子接上了，先向东打一记长灯。以后灯台上的吊篮能直通东岗。"],
			["掌灯人","封岗后许多人靠这盏灯认路。余下的锻料你拿去，林道边上少不了修护具。"]]},
	{"id":"world_watch_shortcut","area":"watch_lodge","at":Vector2(316,181),
		"name":"乘巡灯吊篮直达东岗","prop":"winch","destination":"watch_road","arrival":Vector2(1328,250),
		"requires":["watch_relay"]},
	{"id":"world_watch_shortcut","area":"watch_road","at":Vector2(1369,255),
		"name":"乘巡灯吊篮回旧岗院","prop":"winch","destination":"watch_lodge","arrival":Vector2(345,194),
		"requires":["watch_relay"]},
	{"id":"world_watch_register_receipt","area":"watch_road","at":Vector2(1242,249),
		"name":"看东岗留下的人证副条","prop":"signal","matches":{"watch_register":"public"},
		"phases":["witness"],"evidence":"watch_register_receipt",
		"lines":[["东岗留记","范著去绝宫前庭找接应人。作证的事只写他一个名字，旧账上押作人质的家属已经经西门转移。"]]},
	{"id":"world_watch_register_receipt","area":"watch_road","at":Vector2(1242,249),
		"name":"看东岗留下的空梆副条","prop":"signal","matches":{"watch_register":"anonymous"},
		"phases":["witness"],"evidence":"watch_register_receipt",
		"lines":[["东岗留记","姓名已刮去，范著留在本地。去绝宫认第二声空梆的时刻和白灯之间的间隔。"]]},
	{"id":"world_watch_register_anonymous_witness","area":"watch_lodge","at":Vector2(210,204),
		"name":"问留在旧岗的范著近况","sprite":"servant","matches":{"watch_register":"anonymous"},
		"lines":[["范著","只把换岗的时刻带走就够了。我留这儿给认不出路的人引路，他们不必知道是谁抄的。"]]},
	{"id":"world_watch_relay_receipt","area":"watch_road","at":Vector2(1443,219),
		"name":"检查两路巡灯能否互通","sprite":"guide","requires":["watch_relay"],
		"phases":["witness"],"evidence":"watch_relay_receipt",
		"lines":[["新掌灯人","西边看得清，东边也看得清。追兵断过几次灯线，这回绕在石栏背面，他们摸黑碰不到。"]]},
	{"id":"world_watch_charter_pass","area":"watch_lodge","at":Vector2(479,239),
		"name":"走剑庐工匠修好的西岗卷轮","prop":"winch","destination":"watch_road","arrival":Vector2(599,216),
		"requires":["charter_handoff"],"matches":{"sword_charter":"commission"}},
	{"id":"world_watch_charter_pass","area":"watch_road","at":Vector2(630,204),
		"name":"用西岗卷轮回旧岗院","prop":"winch","destination":"watch_lodge","arrival":Vector2(505,219),
		"requires":["charter_handoff"],"matches":{"sword_charter":"commission"}},
	{"id":"world_watch_charter_worker","area":"watch_road","at":Vector2(698,253),
		"name":"问剑庐工头卷轮为何能用","sprite":"servant",
		"requires":["charter_handoff"],"matches":{"sword_charter":"commission"},
		"lines":[["剑庐工头","于姑娘准我们来修。灯轮送东岗那条是你们的，西岗这扇卷轮修好后，过中岗也能避开大门。"]]},
	{"id":"world_watch_charter_refuge","area":"watch_lodge","at":Vector2(401,250),
		"name":"向借宿匠户换途中补给","sprite":"servant","shop":"sword_refuge",
		"requires":["charter_handoff"],"matches":{"sword_charter":"refuge"}},
	{"id":"world_watch_charter_refuge_pass","area":"watch_lodge","at":Vector2(128,281),
		"name":"从西院小门上匠户的接应坡","prop":"exit_open","destination":"watch_road","arrival":Vector2(358,262),
		"requires":["charter_handoff"],"matches":{"sword_charter":"refuge"}},
	{"id":"world_watch_charter_refuge_pass","area":"watch_road","at":Vector2(327,249),
		"name":"领匠户从接应坡下到西院","prop":"exit_open","destination":"watch_lodge","arrival":Vector2(150,268),
		"requires":["charter_handoff"],"matches":{"sword_charter":"refuge"}},
	{"id":"world_watch_charter_evacuee","area":"watch_road","at":Vector2(383,222),
		"name":"问待送匠户何时出发","sprite":"guide",
		"requires":["charter_handoff"],"matches":{"sword_charter":"refuge"},
		"lines":[["外哨匠户","剑庐肯腾铺，旧院才同意打开西边小门。就走这道接应坡，进院能取包袱换药，再往剑庐去。"]]},
	{"id":"world_watch_notice","area":"watch_lodge","at":Vector2(257,170),
		"name":"看师门封岗牌","prop":"signal","phases":["sealed"],
		"lines":[["封岗牌","飞云堂议事，所有旧岗熄灯候命。认得路的走林道。"]]},
	{"id":"world_watch_notice","area":"watch_road","at":Vector2(982,239),
		"name":"看东瀛刀手留下的白旗令","prop":"signal","phases":["occupied"],
		"lines":[["白旗令","废师门号灯，令旧录事携簿自首。院口守人现已撤去，沿西门仍可出入。"]]},
	{"id":"world_watch_notice","area":"watch_road","at":Vector2(914,218),
		"name":"问旧岗为何重新挂灯","sprite":"servant","phases":["witness"],
		"lines":[["旧岗人","城里开始核对上个月的点名。我们轮流守这条路，让想走的人知道还可以回来。"]]},
]
