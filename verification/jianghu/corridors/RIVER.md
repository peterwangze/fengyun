# 榆汊递船验收

| 路线 | 实际经过 | 决战开场 | 潮关复查 |
| --- | --- | --- | --- |
| 公开灯号 | 凤溪小驳 → 榆汊验船、挂灯 → 苇津公泊桩 → 药工点数 | 合击 +1 | 在仓案查具名卸货册 → 渡口签收具名回执 |
| 遮舱渡运 | 凤溪小驳 → 榆汊验船、扎布 → 芦岸低泊位 → 步行入苇津交封绳 | 步惊云获得护持 | 在装卸渠查封签 → 渡口签收不具名回执 |

用两份第二章阶段存档开始，逐段通过游戏输入走路和交互。选定船路后，绝宫开放前只能查看封埠说明。凤溪到榆汊的小驳可以实际往返，退出重读时落在正确的码头。绝宫开放后，两条路各自进入并沿原泊点返回。交箱前只有放行记录，交箱后才会给决战支援。两次实际战胜雄霸后核验各自尾声，再通过榆汊与潮关之间的船实际往返，查录并签收。此项使用分章阶段存档验证水路因果，发布验收中的从头开局另行记录。

从未经改写的 3.2 已通关存档补交遮舱船货，确认能领潮关回执，既有决战与尾声记录保持原样。凤溪回访的 295 项旧路线检查也全部通过。

```powershell
$godot = 'D:/AI/dev_toolchain/godot_tool_list/app/Godot_v4.7.2-stable_win64_console.exe'
& $godot --headless --path game --script res://tests/corridor_water.gd -- --profile=qa_corridor_water
& $godot --headless --path game --script res://tests/jianghu_network.gd -- --profile=qa_jianghu_network
```

查看 [无窗口日志](river-headless.log)、[Windows 图形日志](river-native.log) 和 [凤溪回归](fengxi-save-regression.log)。截图展示了 [榆汊西埠](river-elm-ford.png)、[择路菜单](river-choice.png)、[苇津明灯泊位](river-landing-public.png) 与 [芦岸遮舱泊位](river-landing-covered.png)。
