# 2.4.0 六章节奏回归

在 Windows 11 x64 上通过 Godot 4.7.2 的无界面模式，从标题开始以键盘命令和逐步行走执行六章，最后进入潮关。四条路线均到达结局，没有修改战斗气血、真气、敌人数据或存档历练。配置路线在每章开头使用当前已解锁的行装与武学，战斗按预告、破势窗口、敌我血量和真气选择出招。

| 路线 | 六章战斗数 | 行走时间估算 | 入魔之影、绝无神、末路雄霸回合数 | 对应三战单人最低气血比例 |
| --- | ---: | ---: | --- | --- |
| 标准主线，正门、石桥、泄火桥、合璧破盾 | 16 | 110.7 秒 | 3、5、5 | 83%、71%、52% |
| 标准，完成八条支线并选密行、护心镜和无名起手 | 16 | 165.3 秒 | 3、5、5 | 83%、71%、52% |
| 标准，逐章配装，竹径潜行、乘船、北侧石栈、破势拆盾 | 23 | 193.9 秒 | 2、4、7 | 100%、87%、36% |
| 轻松，巡卫警戒战、解缆后关闭动态效果、潮关水栅 | 22 | 124.6 秒 | 2、4、4 | 100%、84%、74% |

行走时间用脚本实际走过的距离除以正常步速，包含回归所走的复查路线。对话、观察、决策、动画和探索等待时间由人工操作速度决定，表中时间仅可用于同一脚本的回归比较。战斗数含六章内的教学、剧情和支线战，潮关单独验收。四次运行均使用单独的 QA 档。

- 重跑 `v2.3.0` 的标准主线确认「入魔之影」两回合结束。在相同主线和默认武学中，2.4.0 为三回合，六次出招，最低气血 83%。跑齐可选战并配装的标准路线仍能两回合获胜，轻松路线保持两回合。
- 标准配装路线实战触发 7 次截势、6 次守反、5 次乘隙。药品、装配、换装界面另有专项回归。自动路线熟悉敌人预告，四条脚本流程均未消耗金创药，真人首次游玩的耗药和通关时间待测。
- 已验证婚宴对话结束后出现正门和竹径两个目标。凤溪过桥与解缆并列，释放船缆后目标指向船家，船家抵达后指向登船点。剑池在两路分叉时标出泄火闸和北栈，开闸后标记转到桥面。两处实际步行点位通过可行走检查。魔池在药庐对话、击败心魔、劈开木栅和接应第二梦后更新主线标记。
- 两组支线选择在后续战斗中分别验证。口供降低纸探花开场架势，狱卒分支提供开场护持或降低火麟幻影的势，剑庐证词分支提供合击起手或削弱雄霸开场的势。正门查账、公开分粮和水栅留证两种潮关结案均通过。

## 复现命令

以下从仓库根目录运行，先按本机安装位置设置 `$godot`。

```powershell
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_240_pacing_standard --pacing --tidal
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_240_pacing_quests --pacing --quests --tidal
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_240_pacing_builds --pacing --build-route=mix --quests --alternate --rear-route=quiet --boat --ledge --miss-signal --poise-finish --tidal --tidal-sluice --all-encounters --standard
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_240_pacing_easy --pacing --all-encounters --rear-route=alert --bridge-then-boat --reduced-ferry --tidal --tidal-sluice --low-motion
```

在 `v2.3.0` 工作区运行 `& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_230_baseline_release --tidal` 可复跑公开版基线。

[2.3.0 基线](pacing-baseline-230.log) · [标准主线](pacing-standard.log) · [标准八条支线](pacing-quests.log) · [标准混合配装](pacing-builds.log) · [轻松与低动效](pacing-easy.log)
