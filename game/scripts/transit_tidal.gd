extends RefCounted

const DATA := {
	"id":"tidal_canal",
	"title":"潮关 · 装卸渠",
	"chapter":-1,
	"complete":"canal_done",
	"arrival":["tidal_fort","spawn"],
	"flags":["canal_witness","canal_manifest"],
	"steps":[
		[{"id":"canal_tally", "name":"核对石岸号牌", "at":Vector2(248,212), "prop":"signal",
			"objective":"去西岸的装卸台，看粮船是怎么入仓的。",
			"lines":[
				["聂风","这是给装卸队看的记号。岸上挂空牌，门里却还留着同一批粮船的号。"],
				["步惊云","按咱们选的路去找亲眼见过的人。来船和入仓要能对上。"]
			]}],
		[{"id":"canal_witness", "name":"向正门卸粮人问实数", "at":Vector2(596,221), "sprite":"servant",
			"requires":{"route":"gate"}, "flag":"canal_witness", "next":2,
			"objective":"沿北侧石道请卸粮人核对入仓实数。",
			"lines":[
				["卸粮人","我搬了整整三十袋。正门守卒让我只报一半，剩下的记成过路费。"],
				["步惊云","等我们取到账，你愿意当着领粮的人把这数再说一遍？"],
				["卸粮人","可以。那鼓手总先左手落槌，看到他抬肘就有机会拦下。"]
			]},
			{"id":"canal_manifest", "name":"捞起水栅边的船单", "at":Vector2(843,273), "prop":"chest",
				"requires":{"route":"sluice"}, "flag":"canal_manifest", "next":2,
				"objective":"沿南侧木栈找漂到河边的运输凭条。",
				"lines":[
					["聂风","船单写着三十袋，背后还有舟工按的指印。到岸以后，实数少不了。"],
					["船工","拿好船单，再借这件扛粮护甲。护住走在前面的人，别碰坏那几张纸。"]
				]}],
		[{"id":"canal_gatehouse", "name":"查看粮仓岸梯与回缆", "at":Vector2(1133,217), "prop":"winch",
			"objective":"绕过卸货浅水，确认东段岸梯和返程回缆。",
			"lines":[
				["步惊云","这一头的回缆没割断。开门之后，账和人都能从这里带回渡口。"],
				["聂风","先按咱们进门的路走。粮仓里的账才记了谁扣下冬粮。"]
			]}],
		[{"id":"canal_exit", "name":"抵达潮关粮仓", "at":Vector2(1418,221), "prop":"exit_open",
			"objective":"登东端台阶入仓。",
			"lines":[["聂风","仓墙后头还有人。找准回去的路，再把账带出来。"]]}],
	],
}
