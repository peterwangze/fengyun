extends RefCounted

const DATA := {
	"id":"dragon_ridge","title":"凌云山 · 断脉山道","chapter":5,"complete":"ridge_done","arrival":["cavern","medicine_path"],
	"flags":["ridge_guide","ridge_safe"],
	"steps":[
		[{"id":"ridge_lantern","name":"在残灯处停下药担","at":Vector2(258,231),"prop":"signal",
			"lines":[["第二梦","龙脉压得住魔血，龙脉碎了，就得把血换出来。风的气一乱，你们就叫我。"],["猪皇","针和水不能再沾泥。上面有人能带路，下面那条路近，却有追兵。"]]}],
		[{"id":"ridge_high","name":"从高坡请山民引道","at":Vector2(715,175),"sprite":"guide","flag":"ridge_guide",
			"lines":[["山民","早先秦大侠救过我。我背一头药担，沿北面的避风石壁走。"],["步惊云","上面会吹熄火。把灯罩拢严，再走。"]]},
		 {"id":"ridge_low","name":"截住追到药炉旁的两人","at":Vector2(848,265),"sprite":"shade","foes":["elite","blade"],"flag":"ridge_safe",
			"lines":[["追兵","山下也封了。把人留下，自己走。"],["步惊云","让第二梦先过。等她放下药担，我再跟上。"]]}],
		[{"id":"ridge_stove","name":"在避风石台备水","at":Vector2(1122,212),"prop":"fire",
			"lines":[["第二梦","把水温到手能浸进去。等我开口时再递针。余下的，我自己来。"]]}],
		[{"id":"ridge_exit","name":"从北坡回药炉守卫处","at":Vector2(1455,220),"prop":"exit_open",
			"lines":[["猪皇","那头直通药炉的侧口。我的火不会灭，云，看着外面就好。"]]}],
	],
}
