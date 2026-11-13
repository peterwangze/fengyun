extends RefCounted

const MATERIALS := {
	"ember_iron":{"name":"火纹铁","source":"剑池战斗、炉火借一更、山路残部"},
	"clear_silk":{"name":"韧丝","source":"客栈截印、药庐三问、路上药箱"},
	"tidal_iron":{"name":"盐淬铁","source":"潮关查名册、守卒和粮棚救援"},
}

const FORGES := {
	"swordhall":{"title":"剑庐锻台","note":"工匠能补强护具与佩物，也能替步惊云誊写回云卸劲。",
		"gear":["reed_mantle","forge_guard","tide_whistle","sword_tassel"],"manuals":["cloud_return"]},
	"apothecary":{"title":"药庐修具台","note":"药师用韧丝补药具，也能整修过渡时用的护衣。",
		"gear":["reed_mantle","apothecary_gourd"]},
	"palace":{"title":"天牢修具箱","note":"老匠取回了工具，可趁回茶房前把随身行装修好。",
		"gear":["reed_mantle","forge_guard","tide_whistle","sword_tassel","apothecary_gourd"],"manuals":["cloud_return"]},
	"peak":{"title":"凌云山临时锻台","note":"剑庐工匠带着工具来接人，决战前还能整修行装。",
		"gear":["reed_mantle","forge_guard","tide_whistle","sword_tassel","apothecary_gourd"],"manuals":["cloud_return"]},
	"tidegate":{"title":"盐汊打铁铺","note":"粮仓护衣须用潮关本地的盐淬铁。",
		"gear":["granary_vest"]},
}

const UPGRADE_COSTS := {
	"reed_mantle":[{"silver":6,"materials":{"clear_silk":1}},{"silver":11,"materials":{"clear_silk":2,"ember_iron":1}}],
	"forge_guard":[{"silver":8,"materials":{"ember_iron":1}},{"silver":14,"materials":{"ember_iron":2,"clear_silk":1}}],
	"tide_whistle":[{"silver":7,"materials":{"ember_iron":1}},{"silver":12,"materials":{"ember_iron":2}}],
	"sword_tassel":[{"silver":7,"materials":{"clear_silk":1}},{"silver":12,"materials":{"clear_silk":1,"ember_iron":2}}],
	"apothecary_gourd":[{"silver":7,"materials":{"clear_silk":1}},{"silver":12,"materials":{"clear_silk":2}}],
	"granary_vest":[{"silver":3,"materials":{"tidal_iron":1}},{"silver":6,"materials":{"tidal_iron":2}}],
}

const MANUAL_RECIPES := {
	"cloud_return":{"silver":8,"materials":{"ember_iron":2,"clear_silk":1}},
}

const SHOPS := {
	"inn":{
		"title":"凤溪行商", "note":"商队从西岸运来药品与挡雨的护衣。",
		"goods":[
			{"id":"tonic","kind":"tonic","price":4,"count":3,"restock":[{"when":"clear:1:1","count":1,"hint":"渡口解围后补货"}]},
			{"id":"breath_pill","kind":"supply","price":3,"count":2},
			{"id":"guard_powder","kind":"supply","price":4,"count":2},
			{"id":"stagger_needle","kind":"supply","price":5,"count":1},
			{"id":"reed_mantle","kind":"gear","price":13,"count":1},
			{"id":"clear_silk","kind":"material","price":5,"count":0,"restock":[{"when":"clear:1:1","count":2,"hint":"渡口解围后到货"}]},
		],
	},
	"forge":{
		"title":"剑庐工匠", "note":"工匠将护具和剑庐传下的招式抄本摆在台上。",
		"goods":[
			{"id":"tonic","kind":"tonic","price":4,"count":2},
			{"id":"breath_pill","kind":"supply","price":3,"count":2},
			{"id":"stagger_needle","kind":"supply","price":5,"count":2,"restock":[{"when":"quest:forgework","count":1,"hint":"修好剑架后补货"}]},
			{"id":"forge_guard","kind":"gear","price":16,"count":1},
			{"id":"cloud_return","kind":"manual","price":19,"count":1},
			{"id":"ember_iron","kind":"material","price":6,"count":1,"restock":[{"when":"quest:forgework","count":1,"hint":"修好剑架后补货"}]},
		],
	},
	"medicine":{
		"title":"生死门药师", "note":"入魔池前可备些护脉的药。药师手边还有一只药葫芦。",
		"goods":[
			{"id":"tonic","kind":"tonic","price":3,"count":3,"restock":[{"when":"clear:3:0","count":1,"hint":"击退魔池魔念后补货"}]},
			{"id":"breath_pill","kind":"supply","price":3,"count":3},
			{"id":"guard_powder","kind":"supply","price":4,"count":3},
			{"id":"apothecary_gourd","kind":"gear","price":17,"count":1},
			{"id":"clear_silk","kind":"material","price":5,"count":0,"restock":[{"when":"quest:remedy","count":2,"hint":"药庐三问结案后到货"}]},
		],
	},
	"tidegate":{
		"title":"盐汊杂货", "note":"陶伯托摊主留下粮仓护衣和一批药品。",
		"goods":[
			{"id":"tonic","kind":"tonic","price":4,"count":3},
			{"id":"breath_pill","kind":"supply","price":3,"count":2},
			{"id":"guard_powder","kind":"supply","price":4,"count":2,"restock":[{"when":"tide:aid","count":1,"hint":"救出阿芦后补货"}]},
			{"id":"stagger_needle","kind":"supply","price":5,"count":2},
			{"id":"granary_vest","kind":"gear","price":9,"count":1},
			{"id":"tidal_iron","kind":"material","price":3,"count":0,"restock":[{"when":"tide:register","count":1,"hint":"核对名册后到货"}]},
		],
	},
}

const DROPS := {
	"battle:village:0":{"manual":"frost_gate","line":"秦霜从石桥守卫手中收回了拳谱。"},
	"progress:ferry":{"manual":"frost_gate","line":"渡工把藏在船底的拳谱交还秦霜。"},
	"battle:village:1":{"gear":"tide_whistle","line":"纸探花的铜哨落在了渡口。"},
	"hunt:inn":{"manual":"crosswind","materials":{"clear_silk":1},"line":"密探怀中的抄本和封印用的韧丝落在后窗。"},
	"battle:forge:0":{"materials":{"ember_iron":1},"line":"执剑人把淬过的铁料留在了炉边。"},
	"battle:forge:1":{"gear":"sword_tassel","materials":{"ember_iron":2},"line":"断浪没能带走剑穗和炉边的铁料。"},
	"battle:forge:2":{"materials":{"ember_iron":2},"line":"炉火幻影散去，露出两块火纹铁。"},
	"quest:remedy":{"manual":"moon_needle","silver":4,"materials":{"clear_silk":2},"line":"第二梦给你针法抄本和缝护具用的韧丝。"},
	"battle:palace:0":{"manual":"sword_trace","materials":{"ember_iron":1},"line":"无名取回被卫队没收的剑谱和铁料。"},
	"battle:palace:2":{"materials":{"ember_iron":2,"clear_silk":1},"line":"拦路的东瀛人把修甲材料留在廊下。"},
	"battle:peak:0":{"materials":{"ember_iron":1},"line":"戾影散去，露出祭台原有的铁钉。"},
	"battle:peak:2":{"materials":{"ember_iron":2,"clear_silk":1},"line":"天池残部的火纹铁与韧丝掉在石阶上。"},
	"quest:seals":{"silver":4},
	"quest:courier":{"silver":4},
	"quest:forgework":{"silver":5,"materials":{"ember_iron":1,"clear_silk":1}},
	"quest:lamps":{"silver":4},
	"quest:swordstory":{"silver":5},
	"quest:shift":{"silver":4,"materials":{"clear_silk":1}},
	"quest:stairs":{"silver":5,"materials":{"clear_silk":1}},
	"chest:hall":{"silver":4,"materials":{"clear_silk":1}},
	"chest:village":{"silver":4},
	"chest:forge":{"silver":4},
	"chest:pool":{"silver":4,"materials":{"clear_silk":1}},
	"chest:palace":{"silver":5},
	"chest:peak":{"silver":5,"materials":{"ember_iron":1,"clear_silk":1}},
	"tidal:register":{"materials":{"tidal_iron":1},"line":"粮棚账台下面放着一块盐淬铁。"},
	"tidal:gate":{"materials":{"tidal_iron":1},"line":"正门守卒落下了一块盐淬铁。"},
	"tidal:aid":{"silver":5,"materials":{"tidal_iron":2},"line":"阿芦把粮棚夹层的盐淬铁和盘缠交给了你。"},
}
