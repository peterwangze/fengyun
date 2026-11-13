extends RefCounted

const DATA := {
	"id":"outer_watch","title":"天下会 · 外哨","chapter":2,"complete":"watch_done","arrival":["returnhall","spawn"],
	"flags":["watch_freed"],
	"steps":[
		[{"id":"watch_signal","name":"在旧岗回三短一长","at":Vector2(241,235),"prop":"signal",
			"lines":[["步惊云","岗楼没挂本门牌。风师弟，按凤溪约好的灯号敲窗。"],["旧岗仆役","我认得。白旗便是新来的亲卫，押着两人下去改口供。"]]}],
		[{"id":"watch_list","name":"从林道取回换岗单","at":Vector2(567,188),"prop":"chest",
			"lines":[["聂风","换岗单上有接管的时刻。雄霸还在飞云堂，外面的人已排好了班。"]]}],
		[{"id":"watch_guard","name":"从岗门救出两名证人","at":Vector2(875,251),"sprite":"guard","foes":["guard","blade"],"flag":"watch_freed",
			"lines":[["执事","过了岗楼就得按新令办。你们别问谁签的。"],["步惊云","先放人。让签令的人自己来解释。"]]}],
		[{"id":"watch_exit","name":"沿旧门返回飞云堂","at":Vector2(1442,219),"prop":"exit_open",
			"lines":[["旧岗仆役","屋里是帮主亲自守着。外面留给我，我带这两个人从林道回去。"]]}],
	],
}
