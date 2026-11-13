extends RefCounted

const DATA := {
	"id":"palace_sluice",
	"title":"绝宫 · 西闸水道",
	"chapter":4,
	"complete":"sluice_done",
	"arrival":["tearoom","spawn"],
	"steps":[
		[{"id":"palace_sluice_gate", "name":"抬起西闸铁梁", "at":Vector2(244,216), "prop":"winch",
			"objective":"沿西闸石岸走，找到升闸的绞盘。",
			"lines":[
				["步惊云","这道旧闸通向茶房墙后。至尊要我们经侧廊出去，先抬铁梁，看看巡卫往哪头走。"],
				["无名","闸板已经提起来了。前头只剩一条石道，沿这堵墙过去。"]
			]}],
		[{"id":"palace_sluice_guard", "name":"击退水道巡卫", "at":Vector2(778,232), "sprite":"guard",
			"objective":"走中段石道，截住东岸巡卫。",
			"foes":["invader","blade"], "lines":[
				["巡卫","茶房今日不许旁人进去。二公子吩咐，来找那张旧图的，一概留下。"],
				["无名","他守的是二公子的退路。云，把他拦在石道上。"]
			]}],
		[{"id":"palace_sluice_map", "name":"辨认木匣里的水道拓印", "at":Vector2(1132,202), "prop":"chest",
			"objective":"去东段墙边核对水道拓印。",
			"lines":[
				["步惊云","巡卫把旧图的残拓藏在木匣里。这道墨痕绕过茶房，出绝宫后还接着一条引水渠。"],
				["无名","先记下东梯。原图还在绝心手里，茶房的动静比这张残拓更要紧。"]
			]}],
		[{"id":"palace_sluice_exit", "name":"登东梯进入茶房侧廊", "at":Vector2(1418,240), "prop":"exit_open",
			"objective":"沿东端石梯进茶房，查探绝心。",
			"lines":[["步惊云","这级石阶上有水，刚有人从茶房下来。先听清他们在说什么。"]]}]
	],
}
