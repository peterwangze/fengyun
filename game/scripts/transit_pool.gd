extends RefCounted

const DATA := {
	"id":"broken_trestle","title":"生死门 · 谷口断栈","chapter":3,"complete":"trestle_done","arrival":["","chapter"],
	"flags":["trestle_carry","trestle_supply"],
	"steps":[
		[{"id":"trestle_bell","name":"在断栈旁接应邪皇","at":Vector2(245,237),"sprite":"guide",
			"lines":[["第一邪皇","独孤梦没能过池门。弟子已带她回药庐。剩下的伤者要下谷。告诉步惊云，绝无神收拳换气时金身会松。"],["第二梦","我们可以扶伤者过浅滩，也可上高栈取回药担。风，路上若听见刀声，就跟着我说话。"]]}],
		[{"id":"trestle_shoal","name":"在浅滩护送伤者","at":Vector2(582,268),"sprite":"servant","flag":"trestle_carry","next":2,
			"lines":[["聂风","扶着我，不用看水。我若握紧了刀，你就叫我的名字。"]]},
		 {"id":"trestle_herbs","name":"绕到高栈西端取回药担","at":Vector2(448,168),"prop":"chest","flag":"trestle_supply","next":2,
			"lines":[["第二梦","包扎的药和换气字条都在。放在我手上，省得你的手又去摸刀。"]]}],
		[{"id":"trestle_tracks","name":"查绝宫追骑留下的木牌","at":Vector2(1072,228),"prop":"signal",
			"lines":[["第二梦","木牌上说要活捉你。绝心懂你练过魔刀。先把伤者送到接应处，我替邪皇把信交给信使。"]]}],
		[{"id":"trestle_exit","name":"抵达谷口信道","at":Vector2(1446,221),"sprite":"servant",
			"lines":[["聂风","伤者交给你。我朝山口走，把追骑引离药担。别让他们知道云师兄要去开牢门。"],
				["信使","第二姑娘，追骑堵到了引水渠，我替你送信去绝宫。你沿山侧找聂大侠。"]]}],
	],
}
