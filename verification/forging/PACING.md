# 2.8.0 锻造与六章回归

用 Windows 11 x64 上的 Godot 4.7.2 从新档走完六章和潮关。2.7.0 使用独立解包的发布标签。两版均运行标准无采购、三种单一打法、五本秘籍路线和轻松低动效路线。2.8.0 的三个专项路线在正常地图上向商人购买、在锻台确认配方，并在战斗中使用强化行装。

| 路线 | 六章战斗数 | 2.7.0 回合 | 2.8.0 回合 | 2.8.0 最低气血 |
| --- | ---: | --- | --- | --- |
| 标准无采购、无配装 | 16 | 3、5、5 | 3、5、5 | 90%、38%、61% |
| 截势，渡口铜哨 +2 | 16 | 4、5、5 | 4、5、5 | 90%、40%、62% |
| 守反，回锋护臂 +2、仓卫厚甲 +2 | 16 | 5、5、8 | 6、5、7 | 80%、38%、60% |
| 乘隙，火麟剑穗 +2 | 16 | 5、4、5 | 5、5、5 | 73%、43%、67% |
| 五本秘籍和商店行装 | 17 | 4、6、7 | 4、6、7 | 62%、2%、33% |
| 轻松、低动效、潮关水栅 | 22 | 2、4、3 | 2、4、3 | 87%、74%、73% |

三列依次为龙脉戾影、末路雄霸、潮关夺账。六章战斗数含教学、剧情和支线战，潮关另计。两版同名专项路线沿用相同的自动选招策略，2.8.0 同时更换了行装和部分武学，因此回合差也反映了配装取舍。真人首次游玩节奏、实体手柄与手机尚无本轮数据。日志中的 `walk_seconds` 为脚本行走距离按默认步速换算。

- 剑池两场主线战发放火纹铁。「炉火借一更」和「药庐三问」结案提供强化原料。标准路线用自然获得的银两和材料，在剑庐锻台强化一次，并在临时锻台升到 +2。守反路线也用材料誊写了回云卸劲。每次强化的实际扣款和材料数均与配方一致，检查了未取得、重复誊写和满级拒绝。
- 凤溪首次访问没有韧丝，击败天池杀手后到货两份。买一份并两次重开窗口，库存均保持一份。剑庐、药庐和潮关的到货条件也按完成任务、核对名册或救人验证。潮关依次从名册、正门和救援取得本地盐淬铁，强化不影响主线银两与原料。
- 终局三场战斗读到了强化数值。渡口铜哨使截势基础回气达到 6，回锋护臂的反击修正为 +14，火麟剑穗的破势目标武学伤害修正为 +14。潮关仓卫厚甲的重击减伤为 12。三种打法均在潮关触发各自的效果。
- 旧经济存档迁移补发已完成事件的原料，保留原银两。迁移后反复读取不会重复发放。五本秘籍的原有取得、装配和出招路径也通过。
- 另在 Windows 的 Godot 图形窗口以 1280 × 720 跑完守反路线，检查锻台配方、抄本、强化状态和结局。临时锻台曾因第六项遮住底栏，修复后以同分辨率复验六项配方与底栏均完整可见。

## 复现命令

在仓库根目录执行，将 `$godot` 设置为 Godot 4.7.2 的本机路径。2.7.0 基线在公开标签独立目录使用该版原有验收脚本，省略 `--forging`。

```powershell
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_280_forging_standard --pacing --tidal --endgame --forging
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_280_forging_interrupt --pacing --tidal --endgame --quests --counterplay --quest-carryover --build-route=interrupt --forging
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_280_forging_retaliate --pacing --tidal --endgame --quests --counterplay --quest-carryover --build-route=retaliate --forging
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_280_forging_exploit --pacing --tidal --endgame --quests --counterplay --quest-carryover --build-route=exploit --forging
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_280_forging_training --pacing --tidal --endgame --quests --counterplay --quest-carryover --market-route=training
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_280_forging_easy --pacing --all-encounters --rear-route=alert --bridge-then-boat --reduced-ferry --tidal --tidal-sluice --low-motion --endgame --forging
```

[2.7.0 标准基线](pacing-270-standard.log) · [2.8.0 标准](pacing-280-standard.log) · [截势](pacing-280-interrupt.log) · [守反](pacing-280-retaliate.log) · [乘隙](pacing-280-exploit.log) · [原有秘籍路线](pacing-280-training.log) · [轻松](pacing-280-easy.log)

[图形回归](rendered-campaign.log) · [剑庐强化](forge-swordhall-forge_guard-1.png) · [誊写秘籍](forge-swordhall-cloud_return-1.png) · [临时锻台排版复验](forge-peak-forge_guard-2.png) · [潮关强化](forge-tidegate-granary_vest-2.png) · [主线结局](06-ending.png)
