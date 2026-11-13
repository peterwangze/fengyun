extends RefCounted

const DATA := {
	"id":"broken_trestle","title":"生死门 · 谷口断栈","chapter":3,"complete":"trestle_done","arrival":["","chapter"],
	"flags":["trestle_carry","trestle_supply"],
	"steps":[
		[{"id":"trestle_bell","name":"在断栈旁接应邪皇","at":Vector2(245,237),"sprite":"guide",
			"lines":[["第一邪皇","小梦的伤拖不得。聂风，你先扶住她。云若先到绝宫，让他等金身换气那一刻。"],["第二梦","我可以带伤者过下滩。山崖还有药担，取了再走也来得及。"]]}],
		[{"id":"trestle_shoal","name":"在浅滩护送伤者","at":Vector2(582,268),"sprite":"servant","flag":"trestle_carry","next":2,
			"lines":[["聂风","扶着我，不用看水。我若握紧了刀，你就叫我的名字。"]]},
		 {"id":"trestle_herbs","name":"绕到高栈西端取回药担","at":Vector2(448,168),"prop":"chest","flag":"trestle_supply","next":2,
			"lines":[["第二梦","包扎的药和换气字条都在。放在我手上，省得你的手又去摸刀。"]]}],
		[{"id":"trestle_tracks","name":"查绝宫追骑留下的木牌","at":Vector2(1072,228),"prop":"signal",
			"lines":[["第二梦","他们用假诏说谷里的人叛了朝廷，真要的是聂风。你走山侧，我送邪皇的话给无名。"]]}],
		[{"id":"trestle_exit","name":"抵达谷口信道","at":Vector2(1446,221),"sprite":"servant",
			"lines":[["信使","我遇到步大侠就转告他换气的事。第二姑娘，聂大侠去了引水渠，那边也有绝心的人。"]]}],
	],
}
