extends RefCounted

const DATA := {
	"id":"summit_steps","title":"凌云山 · 避险石道","chapter":5,"complete":"summit_done","arrival":["peak","spawn"],
	"flags":["summit_aid","summit_guard"],
	"steps":[
		[{"id":"summit_roster","name":"在石道口清点下山的人","at":Vector2(240,226),"sprite":"servant",
			"lines":[["聂风","小筑的人已经走了，没到山下的还有谁？"],["山民","上面的侧阶能绕到背坡，但有人敢走正面的吊桥，就能把盯梢的人引过去。"]]}],
		[{"id":"summit_escort","name":"清出背坡的石阶","at":Vector2(625,180),"prop":"winch","flag":"summit_aid",
			"lines":[["步惊云","先把栏木系好，孩子从里侧过。走到第二盏灯下再放手。"]]},
		 {"id":"summit_decoy","name":"在吊桥前拦住残部","at":Vector2(788,268),"sprite":"shade","foes":["claw","blade"],"flag":"summit_guard",
			"lines":[["聂风","下面有回声，喊得响些。他们看见我们，就顾不上背坡。"]]}],
		[{"id":"summit_handoff","name":"将下山路线交给引路人","at":Vector2(1140,230),"sprite":"guide",
			"lines":[["步惊云","走到小木桥就不要回头。祭台只剩我与风师弟上去。"],["聂风","替我在渡口留盏灯。我答应过人要回去。"]]}],
		[{"id":"summit_exit","name":"沿山脊登上龙脉台","at":Vector2(1450,215),"prop":"exit_open"}],
	],
}
