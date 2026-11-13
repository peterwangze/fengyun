extends RefCounted

const DATA := {
	"id":"dragon_waterway",
	"title":"绝宫引水渠 · 追脉",
	"chapter":5,
	"complete":"waterway_done",
	"arrival":["cavern","spawn"],
	"flags":["waterway_high","waterway_low"],
	"steps":[
		[{"id":"waterway_rubbing", "name":"对照残拓，接回聂风", "at":Vector2(251,220), "sprite":"wind",
			"objective":"在西岸近处对照残拓，追秦霜留下的记号。",
			"lines":[
				["步惊云","残拓上这道回弯对得上。绳结系得一长一短，是秦师兄叫我继续往上游找。"],
				["聂风","云师兄……绝心说再解一重封锁就用不着我了。秦师兄把我拖到岸上，自己往东追。"],
				["步惊云","认得我就站起来。上坡有人困在石堤，下边有人举火号。先问近路，或截他的口信。"]
			]}],
		[{"id":"waterway_worker", "name":"到高堤扶起守渠人", "at":Vector2(613,185), "sprite":"guide",
			"next":2,
			"objective":"可上高堤询问守渠人，或沿下渠截住举火的信使。",
			"lines":[
				["守渠人","那个戴护腕的年轻人替我拦了刀，又顺着石梯往东。别走水边，那里还留着暗桩。"],
				["步惊云","他往哪里去了？扶住我，先离开水边。"],
				["守渠人","石梯上去，东端有只歪灯。顺光的反方向走就能追上。"]
			]},
			{"id":"waterway_scout", "name":"沿下渠截住火信", "at":Vector2(712,281), "sprite":"shade",
				"foes":["invader","shade"], "next":3,
				"objective":"可上高堤询问守渠人，或沿下渠截住举火的信使。",
				"lines":[
					["追兵","二公子已去凌云窟。等龙脉到手，回渠口收掉这条路。"],
					["步惊云","他拿着绝心的口信，得先截住这支火号。"]
				]}],
		[{"id":"waterway_signal", "name":"循歪灯识别秦霜的记号", "at":Vector2(870,194), "prop":"signal",
			"flag":"waterway_high", "next":4,
			"objective":"去东边高堤的歪灯处，辨认秦霜的暗记。",
			"lines":[
				["步惊云","灯芯朝西，刀痕在东。秦师兄是在叫我别从正洞口往里闯。"],
				["步惊云","风师弟，你先贴墙稳住气息。我领你从侧面入洞。"]
			]}],
		[{"id":"waterway_order", "name":"查看被截下的火信", "at":Vector2(947,271), "prop":"signal",
			"flag":"waterway_low", "next":4,
			"objective":"到下渠挂索处查看被截下的火信。",
			"lines":[
				["步惊云","二公子的口信说守洞的人听见火号才换位。这回火号没有发出去。"],
				["步惊云","我从旧引水口追上去，趁他们还在看下渠。"]
			]}],
		[{"id":"waterway_blood", "name":"查看东山脚的带血布条", "at":Vector2(1221,191), "prop":"signal",
			"objective":"去东山脚看带血布条，确认聂风与秦霜的方向。",
			"lines":[
				["步惊云","这是秦师兄袖口的布。我们没追错，绝心已经往山口里走了。"],
				["聂风","刀声一近洞门就轻了。先找龙脉，等魔念压住，我和你去接秦师兄。"]
			]}],
		[{"id":"waterway_exit", "name":"进入凌云窟外洞", "at":Vector2(1425,218), "prop":"exit_open",
			"objective":"进东侧外洞，抢在绝心拿到龙脉之前。",
			"lines":[["步惊云","贴住石壁。你要是又听见刀声，就来抓住我的袖子。"]]}],
	],
}
