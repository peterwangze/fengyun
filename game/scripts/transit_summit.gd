extends RefCounted

const DATA := {
	"id":"summit_steps","title":"凌云山 · 避险石道","chapter":5,"complete":"summit_done","arrival":["peak","spawn"],
	"flags":["summit_aid","summit_guard","summit_west_slope","summit_safe_rear"],
	"steps":[
		[{"id":"summit_roster","name":"在石道口清点下山的人","at":Vector2(240,226),"sprite":"servant",
			"lines":[["聂风","小筑的人已从药炉往下走。我们先确定石阶上的人能退，才去找雄霸。"],["山民","可沿背坡清开石阶，也可去吊桥引走盯梢。若西坡或东哨的人来接，你们就跟他们走近路。"]]}],
		[{"id":"summit_escort","name":"清出背坡的石阶","at":Vector2(625,180),"prop":"winch","flag":"summit_aid",
			"lines":[["步惊云","先把栏木系好，孩子从里侧过。走到第二盏灯下再放手。"]]},
		{"id":"summit_decoy","name":"在吊桥前拦住残部","at":Vector2(788,268),"sprite":"shade","foes":["claw","blade"],"flag":"summit_guard",
			"lines":[["聂风","下面有回声，喊得响些。他们看见我们，就顾不上背坡。"]]},
		{"id":"summit_west_slope","name":"由安置过住户的西坡石阶上山","at":Vector2(500,246),"sprite":"guide",
			"requires_world":{"mountain_west":"done"},"flag":"summit_west_slope",
			"lines":[["西坡山民","两户人都点了名。前面那段石道让给你们，从这里绕开吊桥。"]]},
		{"id":"summit_safe_rear","name":"跟最后一队走清出的石阶","at":Vector2(914,207),"prop":"exit_open",
			"requires_world":{"mountain_rearguard":"done"},"flag":"summit_safe_rear",
			"lines":[["传令弟子","追兵已经离开，山阶这会儿空着。照秦师兄留的记号直走。"]]}],
		[{"id":"summit_handoff","name":"将下山路线交给引路人","at":Vector2(1140,230),"sprite":"guide",
			"lines":[["步惊云","走到小木桥就不要回头。祭台只剩我与风师弟上去。"],["聂风","替我在渡口留盏灯。我答应过人要回去。"]]}],
		[{"id":"summit_exit","name":"沿山脊登上龙脉台","at":Vector2(1450,215),"prop":"exit_open"}],
	],
}
