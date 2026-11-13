# 3.0.0 十章战役通关验收

在 Windows 上用 Godot 4.7.2，从新档走完十章，再完成潮关结案。八条路线均无失败断言或引擎错误。脚本通过游戏输入移动、触发地图互动、配装和选招。2.8.0 基线使用公开标签的独立目录。

| 路线 | 2.8.0 主线战斗 | 3.0.0 主线战斗 | 潮关战斗 | 2.8.0 / 3.0.0 主线步行 |
| --- | ---: | ---: | ---: | ---: |
| 标准，跳过支线、无配装及采购 | 16 | 19 | 3 | 112.5 / 246.1 秒 |
| 标准，选择新增地图上的战斗路线，跳过支线、无配装及采购 | — | 24 | 3 | — / 246.9 秒 |
| 截势，渡口铜哨改制 | 16 | 23 | 3 | 187.4 / 331.5 秒 |
| 守反，回锋护臂与仓卫厚甲改制 | 16 | 21 | 3 | 188.3 / 332.0 秒 |
| 乘隙，火麟剑穗改制 | 16 | 25 | 3 | 187.4 / 334.2 秒 |
| 五本秘籍与商店行装 | 17 | 20 | 3 | 179.3 / 313.0 秒 |
| 轻松、低动效、竹径撤离、渡船、潮关水栅 | 22 | 25 | 1 | 127.4 / 261.0 秒 |

主线战斗计数包含切磋、章内剧情和该路线实际选择的可选战斗。最短脚本步行按默认速度换算，包含任务路线中的往返，省略对话阅读、犹豫和战斗时间。标准无采购路线十章各自的步行依次为 37.2、35.3、27.0、20.4、24.5、39.2、18.4、20.2、21.5、2.3 秒，战斗数为 3、3、2、2、2、3、1、1、2、0。第二章雨巷因多处取证占 16.0 秒，其余八张新主线地图各耗 14.1–14.8 秒。潮关新增装卸渠，正门和水栅分别耗 14.6、14.9 秒。五人首玩时长、剧情理解、实体手柄和实体手机本轮无数据。

| 路线 | 龙脉戾影 | 雄霸 | 潮关夺账 |
| --- | --- | --- | --- |
| 两条标准无配装路线 | 3 回合 / 90% | 5 回合 / 38% | 5 回合 / 61% |
| 截势 | 3 回合 / 61% | 5 回合 / 74% | 5 回合 / 62% |
| 守反 | 6 回合 / 80% | 5 回合 / 74% | 7 回合 / 63% |
| 乘隙 | 5 回合 / 73% | 5 回合 / 45% | 5 回合 / 67% |
| 五本秘籍 | 4 回合 / 62% | 6 回合 / 2% | 7 回合 / 33% |
| 轻松 | 2 回合 / 87% | 4 回合 / 74% | 3 回合 / 73% |

表中气血是战中单名角色最低气血比例。五本秘籍路线的自动选招在雄霸战中使用了一次金创药，最低气血为 2%。三条专项路线在真实战斗中分别触发 15 次截势、20 次守反和 6 次乘隙，并在潮关再次触发各自的效果。五门秘籍均通过实战施放验证。标准无配装路线改走五个战斗分岔后，仍能用基础武学通关。

- 九处主线新地图和潮关装卸渠均检测了地图入口、主目标标记、前置目标、实时碰撞与出口。读档回到完成的地标，分支只写入所选结果。雨巷败阵与重试保留战前药品和最后检查点。十章回看打开各自入口，剑池初鸣、龙脉易手、雨夜换血与风云合璧的章末回到标题，主档内容保持一致。
- 山庄山隘救人使步惊云获得护持，截探子使第一名剑池试炼对手少一格势。凌云窟前走高堤使聂风带护持入战，截火号使洞口密探少两格势。潮关正门获得证人，能削鼓手一格势，受凤溪证人册更强效果覆盖时保留其原收益。水栅读取船单并使聂风带护持入战。两份证据各自在实际结案对白回收。
- 三条专项路线购买或取得材料、强化至 +2、完成专属改制并到晚期战斗核对数值。专属改制验证取消、准确扣款、互斥与存档。壁刻遗图两路分别交回拓印或利用暗道削弱残部。潮关西棚试错与正确开启后，重复互动和读档均无额外奖励。
- 另跑一条标准截势路线，改为查证口供、救冬粮、截暗探、正面接应狱卒和引开山道追兵。离开凤溪、绝宫与凌云山时分别确认所选结果。潮关由水栅进仓，保留船单并交州府清点。
- 在 Windows 的 1280 × 720 Godot 窗口以守反路线重跑十章和潮关，零失败。检查各地图地标、脚点、滚动指引、心法和改制菜单。断栈高路的地标改到画面中的干燥平台，深水增加碰撞后再次跑通两条分岔。[图形回归](rendered-campaign.log) · [断栈高路](transit-broken_trestle-checkpoint.png) · [装卸渠](transit-tidal_canal-checkpoint.png) · [心法](cultivation-cloud.png) · [专属改制](forge-branch-cloud_returning.png)

## 复现

在仓库根目录把 $godot 设置为本机 Godot 4.7.2 控制台程序路径。2.8.0 对照在独立的 2.8.0 发布标签目录运行同名路线，去掉 --cultivation。

~~~powershell
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_300_standard --pacing --tidal --endgame --forging --cultivation
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_300_variants --pacing --tidal --endgame --forging --cultivation --alternate-transit
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_300_interrupt --pacing --tidal --endgame --quests --counterplay --quest-carryover --build-route=interrupt --forging --cultivation
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_300_retaliate --pacing --tidal --endgame --quests --counterplay --quest-carryover --build-route=retaliate --forging --cultivation
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_300_exploit --pacing --tidal --endgame --quests --counterplay --quest-carryover --build-route=exploit --forging --cultivation
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_300_training --pacing --tidal --endgame --quests --counterplay --quest-carryover --market-route=training
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_300_easy --pacing --all-encounters --rear-route=alert --bridge-then-boat --reduced-ferry --tidal --tidal-sluice --low-motion --endgame --forging --cultivation
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_300_alt_treaty --pacing --tidal --tidal-sluice --endgame --quests --counterplay --quest-carryover --alternate --alternate-transit --build-route=interrupt --forging --cultivation
~~~

[2.8.0 标准](../forging/pacing-280-standard.log) · [3.0.0 标准](pacing-300-standard.log) · [标准战斗分岔](pacing-300-variants.log) · [截势](pacing-300-interrupt.log) · [守反](pacing-300-retaliate.log) · [乘隙](pacing-300-exploit.log) · [秘籍采购](pacing-300-training.log) · [轻松](pacing-300-easy.log) · [另一组支线结果](pacing-300-alternate-quests.log)
