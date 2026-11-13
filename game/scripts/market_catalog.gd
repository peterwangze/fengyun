extends RefCounted

const SHOPS := {
	"inn":{
		"title":"凤溪行商", "note":"商队从西岸运来药品与挡雨的护衣。",
		"goods":[
			{"id":"tonic","kind":"tonic","price":4,"count":3},
			{"id":"breath_pill","kind":"supply","price":3,"count":2},
			{"id":"guard_powder","kind":"supply","price":4,"count":2},
			{"id":"stagger_needle","kind":"supply","price":5,"count":1},
			{"id":"reed_mantle","kind":"gear","price":13,"count":1},
		],
	},
	"forge":{
		"title":"剑庐工匠", "note":"工匠将护具和剑庐传下的招式抄本摆在台上。",
		"goods":[
			{"id":"tonic","kind":"tonic","price":4,"count":2},
			{"id":"breath_pill","kind":"supply","price":3,"count":2},
			{"id":"stagger_needle","kind":"supply","price":5,"count":2},
			{"id":"forge_guard","kind":"gear","price":16,"count":1},
			{"id":"cloud_return","kind":"manual","price":19,"count":1},
		],
	},
	"medicine":{
		"title":"生死门药师", "note":"入魔池前可备些护脉的药。药师手边还有一只药葫芦。",
		"goods":[
			{"id":"tonic","kind":"tonic","price":3,"count":3},
			{"id":"breath_pill","kind":"supply","price":3,"count":3},
			{"id":"guard_powder","kind":"supply","price":4,"count":3},
			{"id":"apothecary_gourd","kind":"gear","price":17,"count":1},
		],
	},
	"tidegate":{
		"title":"盐汊杂货", "note":"陶伯托摊主留下粮仓护衣和一批药品。",
		"goods":[
			{"id":"tonic","kind":"tonic","price":4,"count":3},
			{"id":"breath_pill","kind":"supply","price":3,"count":2},
			{"id":"guard_powder","kind":"supply","price":4,"count":2},
			{"id":"stagger_needle","kind":"supply","price":5,"count":2},
			{"id":"granary_vest","kind":"gear","price":9,"count":1},
		],
	},
}

const DROPS := {
	"battle:village:0":{"manual":"frost_gate","line":"秦霜从石桥守卫手中收回了拳谱。"},
	"progress:ferry":{"manual":"frost_gate","line":"渡工把藏在船底的拳谱交还秦霜。"},
	"battle:village:1":{"gear":"tide_whistle","line":"纸探花的铜哨落在了渡口。"},
	"hunt:inn":{"manual":"crosswind","line":"密探怀中的腿法抄本落在后窗。"},
	"battle:forge:1":{"gear":"sword_tassel","line":"断浪离开剑炉，没能带走剑穗。"},
	"quest:remedy":{"manual":"moon_needle","silver":4,"line":"第二梦把护脉针法誊给了你。"},
	"battle:palace:0":{"manual":"sword_trace","line":"无名取回被卫队没收的剑谱。"},
	"quest:seals":{"silver":4},
	"quest:courier":{"silver":4},
	"quest:forgework":{"silver":5},
	"quest:lamps":{"silver":4},
	"quest:swordstory":{"silver":5},
	"quest:shift":{"silver":4},
	"quest:stairs":{"silver":5},
	"chest:hall":{"silver":4},
	"chest:village":{"silver":4},
	"chest:forge":{"silver":4},
	"chest:pool":{"silver":4},
	"chest:palace":{"silver":5},
	"chest:peak":{"silver":5},
}
