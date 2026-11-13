# 六章与潮关的 2.6.0 终局回归

在 Windows 11 x64 用 Godot 4.7.2 从新档走完六章与潮关。每条标准配置路线只装备已解锁行装和武学，脚本通过正常按键下达招式并处理剧情。2.5.0 来自独立解包的公开标签，使用相同路线与通用出招策略。2.6.0 在新增首领阶段安排了明确的试探回合和反制，故各路线的回合差同时反映机制和策略。

| 路线 | 2.5.0 回合 | 2.6.0 回合 | 2.6.0 单人最低气血 | 终局反制 |
| --- | --- | --- | --- | --- |
| 标准主线，无配装 | 3、5、5 | 3、5、5 | 90%、38%、61% | 打断逆流与鼓令，合璧破盾 |
| 标准截势，八条支线 | 3、5、5 | 4、5、5 | 90%、40%、62% | 破势断龙息和鼓令，截势在两处战斗回气 |
| 标准守反，八条支线 | 4、7、6 | 5、5、8 | 85%、43%、36% | 护住逆流和突进目标，靠空门与合击反攻 |
| 标准乘隙，八条支线 | 3、5、6 | 5、4、5 | 73%、43%、67% | 留真气追击龙脉、雄霸和韩朔的空门 |
| 标准混合，八条支线和可选战 | 3、7、4 | 5、6、6 | 75%、83%、52% | 保留真气，分两次破势拆盾，潮关获邻里药品 |
| 轻松、竹径警戒、低动效、水栅 | 2、4、3 | 2、4、3 | 87%、74%、73% | 原有战术通关，回合数与 2.5.0 一致 |

三列数值按「龙脉戾影」、「末路雄霸」、「潮关夺账」排列。2.6.0 末三战未使用金创药。守反在潮关保守接招、胜利较慢，最低气血为 36%。标准无装备仍可使用武学破势和固守通关。三条独立打法都在潮关触发本流派。截势路线在龙脉戾影、雄霸与潮关分别回气 1、2、3 次，守反路线在龙脉与潮关分别触发 1、5 次，乘隙路线在三处各触发 1 次。

两组支线各完成八条任务。凤溪归人册路线读档后仍能在潮关向船工问出鼓手身份，鼓手开场少 2 格势。另一条路线兑现为一次潮关补给。二次回访不重复发药。合璧与两次破势均可拆雄霸护气，两条结案路线正常结束。另用实际 Windows 图形运行走完标准守反路线，检查 1280 × 720 上的阶段说明、空门和尾声结局标签。尚无真人首次游玩、实体手柄或 Android 真机的节奏数据。`walk_seconds` 是脚本路线按默认步速折算，未计入真人探索、阅读和决策时间。

## 复现

设置 `$godot` 指向 Godot 4.7.2，从仓库根目录执行。基线在独立的 `v2.5.0` 目录中临时复制本版 `game/tests/acceptance.gd`，去掉各命令中的 `--endgame` 后运行。

```powershell
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_260_endgame_base --pacing --tidal --endgame
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_260_endgame_interrupt --pacing --build-route=interrupt --quests --tidal --counterplay --quest-carryover --endgame
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_260_endgame_retaliate --pacing --build-route=retaliate --quests --tidal --counterplay --quest-carryover --endgame
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_260_endgame_exploit --pacing --build-route=exploit --quests --tidal --counterplay --quest-carryover --endgame
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_260_endgame_branches_alt --pacing --build-route=mix --quests --alternate --rear-route=quiet --boat --ledge --miss-signal --poise-finish --tidal --tidal-sluice --all-encounters --standard --counterplay --quest-carryover --endgame
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_260_endgame_easy --pacing --all-encounters --rear-route=alert --bridge-then-boat --reduced-ferry --tidal --tidal-sluice --low-motion --endgame
```

[2.5.0 主线基线](pacing-250-base.log) · [2.6.0 标准主线](pacing-260-base.log) · [截势](pacing-260-interrupt.log) · [守反](pacing-260-retaliate.log) · [乘隙](pacing-260-exploit.log) · [混合配装](pacing-260-branches-alt.log) · [轻松](pacing-260-easy.log) · [实际图形回归](rendered-campaign.log)

[龙息逆流](dragon-reflux.png) · [龙脉空门](dragon-opened.png) · [三分归元气](tyrant-shield.png) · [归元气已破](tyrant-shield-broken.png) · [潮关鼓令](tidal-formation.png) · [鼓令空门](tidal-opened.png) · [尾声渡口公示](06-ending.png)
