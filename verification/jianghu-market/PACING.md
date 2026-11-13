# 六章与潮关的 2.7.0 市集回归

在 Windows 11 x64 用 Godot 4.7.2 从新档走完六章和潮关。脚本通过游戏输入走地图、与店主交谈、装配武学与行装并逐回合选招。两条采购路线完成八条支线，使用不同的凤溪过河方式，都取得秦霜拳谱。2.6.0 基线从公开标签单独导入运行。

| 路线 | 六章战斗数 | 终局三战回合数 | 对应单人最低气血 | 采购与资源使用 |
| --- | ---: | --- | --- | --- |
| 2.6.0 标准基线 | 16 | 3、5、5 | 90%、38%、61% | 默认武学与行装 |
| 2.7.0 标准主线 | 16 | 3、5、5 | 90%、38%、61% | 无采购、无配装 |
| 2.7.0 补给路线 | 15 | 4、5、5 | 90%、38%、61% | 走渡船，银两用于聚气丸、护脉散、破势针 |
| 2.7.0 秘籍和行装路线 | 17 | 4、6、7 | 62%、2%、33% | 走石桥及客栈截印，买三件行装与一本秘籍，终战用一剂金创药 |
| 2.7.0 轻松路线 | 22 | 2、4、3 | 87%、74%、73% | 无采购，使用低动效，和 2.6.0 基线一致 |

终局三战依次为龙脉戾影、末路雄霸、潮关夺账。六章战斗数含教学和支线战，潮关另计。装备与武学路线刻意安排出招验证，回合数同时反映操作策略。脚本通过既定线路完成任务，日志的 `walk_seconds` 只衡量路线行走距离，真人通关时间仍需测量。

- 经四处商人实际交易验证购买扣款、有限库存、已拥有判定、售罄后拒绝再次扣款。潮关使用独立银两，主线账户保持原余额。
- 秘籍路线在真实战斗中逐一成功施放逆风截脉、霜锁渡门、回云卸劲、针渡清脉和寻隙剑。保存后读取仍能装备其第五招。断浪、天牢卫队、天池杀手与客栈截印的固定掉落均已落档。任务结束后可直接装配其秘籍。
- 补给路线买空凤溪行商的两份聚气丸，重开窗口后第三次购买仍被拒绝。两条路线都验证旧通关档的主线与潮关银两初始化、已过主线的唯一掉落补发，以及迁移重复读档后余额不变。
- 另在 Windows 以 1280 × 720 实际渲染走完秘籍路线，核对四处商店、战利品和实战武学。首次玩家能否独立理解买法、配装和各章节奏仍待真人验证。

## 复现命令

从仓库根目录执行，将 `$godot` 设置为本机 Godot 4.7.2 路径。2.6.0 基线使用该标签原有的验收脚本和相同的标准或轻松参数。

```powershell
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_270_market_standard --pacing --tidal --endgame
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_270_market_budget --pacing --tidal --endgame --quests --counterplay --quest-carryover --market-route=budget --boat
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_270_market_training --pacing --tidal --endgame --quests --counterplay --quest-carryover --market-route=training
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_270_market_easy --pacing --all-encounters --rear-route=alert --bridge-then-boat --reduced-ferry --tidal --tidal-sluice --low-motion --endgame
```

[2.6.0 标准基线](pacing-260-base.log) · [2.6.0 轻松基线](pacing-260-easy.log) · [2.7.0 标准](pacing-270-standard.log) · [补给](pacing-270-budget.log) · [秘籍和行装](pacing-270-training.log) · [轻松](pacing-270-easy.log)

[实际渲染日志](rendered-campaign.log) · [凤溪行商](market-inn.png) · [剑庐工匠](market-forge.png) · [生死门药师](market-medicine.png) · [盐汊杂货](market-tidegate.png) · [断浪固定掉落](market-fixed-drop.png) · [第五招装配](market-fifth-move.png) · [装配后的实战](market-frost-and-wind-manuals.png)
