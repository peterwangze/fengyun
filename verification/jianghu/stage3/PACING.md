# 第三阶段主线验收

Windows 上用 Godot 4.7.2 从新建存档跑完十章、凤溪尾声及潮关。战斗使用各路线固定的操作策略。区域互动经过实际地图移动，并验证相应按钮、门、对话、战斗和存档。移动耗时按自动化路径位移和游戏移动速度换算，包含测试所走的回程与重访，未计阅读、思考和战斗操作时间。

| 路线 | 十章移动秒数 | 主线及途中战斗 | 潮关战斗 | 雄霸回合 / 最低队员生命 | 凌云山撤离 |
| --- | ---: | ---: | ---: | --- | --- |
| [3.1 同策略基线](baseline-3.1-standard.log) | 246.0 | 19 | 3 | 5 / 38% | 无 |
| [标准，无消费](campaign-standard.log) | 282.3 | 19 | 3 | 5 / 38% | 西坡，17.0 秒移动 |
| [截势](campaign-interrupt.log) | 555.0 | 24 | 3 | 5 / 74% | 石阶断后，20.2 秒；名册提供绕行 |
| [守反](campaign-retaliate.log) | 562.8 | 22 | 3 | 5 / 75% | 护药，18.5 秒；药单提供绕行 |
| [乘隙](campaign-exploit.log) | 560.6 | 23 | 3 | 5 / 45% | 西坡，20.4 秒；往返试走祭台近路 |
| [无消费，护药](campaign-medicine-fallback.log) | 284.6 | 20 | 3 | 5 / 38% | 无药单时护药遇敌 |
| [无消费，石阶断后](campaign-rearguard-fallback.log) | 286.3 | 20 | 3 | 5 / 38% | 无名册时石阶遇敌 |
| [轻松，全战斗，潮关侧道](campaign-easy.log) | 293.6 | 25 | 1 | 4 / 74% | 西坡，无消费 |

标准路线与 3.1 的战斗次数、雄霸用时及最低生命一致。绝宫章移动由 39.2 秒增至 56.9 秒，雨夜换血章由 20.2 秒增至 36.6 秒。三条配装还包含前两阶段的支线重访、交接和锻造，表中总移动量同时受这些选项影响。

- 无消费路线漏做两项准备，起火后仍可走西闸补齐岗令与原始发令记录。读档返回安全外庭；提前返回主线后可重入，缺记录时无法出章。三条构筑分别覆盖火前取证、火后补证、救伤者、保见证人及支开侧门。潮关结算只在保全证人且完成外庭签收时读到江杏的记录。
- 西坡安置开出祭台近路，护药让聂风对雄霸开场带护持，石阶断后清除额外追兵。壁刻遗图实际沿天牢、引水渠、凌云山三地追查；拓印与记下暗道分别验证，暗道还可双向通行并在落点读档。
- 另测[旧火场与旧峰顶存档](campaign-standard.log)及[决战前完成三条撤离、决战后补登](mountain-late.log)。旧火场接入西闸退路，已经走到峰顶的存档能继续。决战后完成的救援会进入凤溪补录，保留决战时已记录的支援。

[原生守反运行](campaign-native-retaliate.log)从标题实走至潮关，留下[火场取舍](stage3-palace-priority.png)、[外庭记录](stage3-palace-records.png)、[雨夜小筑交药](stage3-mountain-medicine.png)及[凤溪点验归人](stage3-fengxi-return.png)画面。测试采用脚本定向输入，首次游玩的阅读节奏、主线总用时和实体手柄体验仍需人测。

## 复跑

在仓库根目录调用 Godot 的 Windows 控制台，并为每次执行使用不同的 `qa_` 存档名。标准路线命令如下。

```powershell
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_stage3_standard --pacing --tidal --endgame --forging --cultivation --stage2b --stage3 --stage2b-skip
```

构筑路线用 `--quests --counterplay --quest-carryover --build-route=interrupt` 代替 `--stage2b-skip`，另跑 `retaliate` 和 `exploit`。无消费备用路线保留 `--stage2b-skip`，再分别传 `--stage3-evacuation=medicine` 或 `--stage3-evacuation=rearguard`。轻松组加 `--all-encounters --tidal-sluice`。日志中 `ARCS` 列出移动和战斗，`STAGE3` 列出存档旗标和阶段选择。
