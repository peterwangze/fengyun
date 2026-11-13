# 六章与潮关的 2.5.0 战斗回归

在 Windows 11 x64 用 Godot 4.7.2 从标题开始，逐章走图、选招、结案。2.4.0 基线来自独立解包的公开标签，复用同一套行走和战斗策略。脚本按预告、气血和架势选择招式，并用当前已解锁的行装与武学。回归期间不修改战斗气血、真气、敌人数值或存档历练。以下各路线均完成六章与潮关。

| 路线 | 六章战斗数 | 2.4.0 回合数 | 2.5.0 回合数 | 2.5.0 单人最低气血 |
| --- | ---: | --- | --- | --- |
| 标准主线，默认装备和武学，固定策略 | 16 | 2、3、5、5 | 3、4、5、5 | 100%、73%、72%、52% |
| 标准主线，按新预告验证应对 | 16 | — | 3、5、5、5 | 100%、55%、73%、52% |
| 标准截势，八条支线 | 16 | 2、3、5、5 | 3、5、5、5 | 100%、57%、73%、53% |
| 标准守反，八条支线 | 16 | 3、3、7、7 | 4、5、4、7 | 88%、60%、91%、26% |
| 标准乘隙，八条支线 | 16 | 2、3、5、4 | 2、5、4、5 | 100%、60%、89%、56% |
| 标准混合配装，八条支线、北栈与破势终战 | 23 | — | 3、5、3、7 | 100%、64%、92%、36% |
| 轻松、巡卫警戒战、低动效、水栅 | 22 | 2、2、4、4 | 2、2、4、4 | 81%、100%、84%、74% |

回合数和气血四列依次对应断浪、入魔之影、绝无神、雄霸。默认装备固定策略的两版对照沿用同一决策。其余标准路线在 2.5.0 主动验证应对窗口，刻意攒高魔念再压制，该部分回合和气血不可直接归因于数值调整。六章计数包含教学、剧情和支线战，潮关另计。日志里的 `walk_seconds` 是脚本行走距离按默认步速换算，未计入真人的阅读、决策与探索时间。

- 截势路线用纳气玉扣与单体削势招式，实战触发 8 次截势。守反路线用护具与护招，实战触发 15 次守反，主动接住断浪火刃，也在雄霸战使用 1 剂金创药。乘隙路线用渡口缆结和重招，实战触发 5 次乘隙。三条路线各自只触发对应流派。混合配装共触发截势 5 次、守反 5 次、乘隙 8 次。
- 所有带应对检查的标准路线都阻止过一次火刃，实际看到魔念横扫预告后用固守或回春压下魔念，也通过固守或护持接住金身重击、打开空门。守反路线额外让一次火刃落在受保护的队友身上。标准无装备默认策略仍能通关，轻松的四场关键战节奏与 2.4.0 一致。
- 实走茶房信使回访，分别验证凤溪密行的护脉散给无名护持，截人审出的口令削绝无神开场 2 格势。通关后，两种凤溪选择分别兑现为自动开启潮关水栅、发放独立金创药和护脉散。两种终战拆盾方式与两种潮关结案均通过。
- Windows 的实际渲染路线从开局走完守反配装、八条支线与潮关。记录使用 1280 × 720、OpenGL Compatibility 和 RTX 5060 Laptop GPU。核对画面上的火刃预告、点名重击、信使援手以及接招后的空门。真人盲测、实体手柄和实体 Android 手机需要另行采集。

## 复现命令

在仓库根目录执行，先按本机安装位置设置 `$godot`。基线在 `v2.4.0` 的独立目录中临时复制本版 `game/tests/acceptance.gd`，运行相同命令时去掉 `--counterplay` 和 `--quest-carryover`。

```powershell
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_250_combat_base_control --pacing --tidal
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_250_combat_base --pacing --tidal --counterplay
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_250_combat_interrupt --pacing --build-route=interrupt --quests --tidal --counterplay --quest-carryover
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_250_combat_retaliate --pacing --build-route=retaliate --quests --tidal --counterplay --quest-carryover
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_250_combat_exploit --pacing --build-route=exploit --quests --tidal --counterplay --quest-carryover
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_250_combat_branches_alt --pacing --build-route=mix --quests --alternate --rear-route=quiet --boat --ledge --miss-signal --poise-finish --tidal --tidal-sluice --all-encounters --standard --counterplay --quest-carryover
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_250_combat_easy --pacing --all-encounters --rear-route=alert --bridge-then-boat --reduced-ferry --tidal --tidal-sluice --low-motion
```

[2.4.0 主线基线](pacing-240-base.log) · [2.5.0 固定策略](pacing-250-base-control.log) · [标准应对](pacing-250-base.log) · [截势](pacing-250-interrupt.log) · [守反](pacing-250-retaliate.log) · [乘隙](pacing-250-exploit.log) · [混合配装与支线](pacing-250-branches-alt.log) · [轻松](pacing-250-easy.log) · [实际渲染日志](rendered-campaign.log)

[火刃预告](duan-fire-sweep.png) · [金身重击与信使援手](godless-heavy-attack.png) · [金身空门](godless-armor-opening.png) · [结局](06-ending.png)
