# 凌云山的竹井坳与飞栈坡

沿避风药炉山道下到竹井坳。守井人指路，穿聚落石街可进避险屋，沿东阶上飞栈坡。聚落、屋内和山道分别有独立美术与碰撞。飞栈上有吊桥、修缮木棚和接撤离石阶的东口。

| 阶段 | 场内变化和可做的事 |
| --- | --- |
| 入山查脉 | 竹井有人打水，喻木匠备木料。可查看备用樟梁、走飞栈检查旧榫，巡坡人守着东口。 |
| 断脉撤离 | 薛箩带孩子躲入避险屋。查齐两处后选择梁的去向。修飞栈可立即往返石阶，撑住避险屋可开启有独立库存的平价药柜。 |
| 灯路开放 | 竹井恢复打水，借住人带旧席回屋晾晒。修栈路线继续通行。撑屋路线启用检修石径。两路均可在撤离石阶找运料人核对各自的交接。 |

龙脉、换血及祭台沿用原有通路和开启条件。竹井工程单另发三两银与一份韧丝。旧三条撤离援助仍由西坡、药炉、石阶实际完成的救援决定，存档中的决战救援记录在通关后保持原样。

[竹井坳](lingyun-foothill-well.png) · [避险屋](lingyun-refuge-approach.png) · [飞栈渡峡](lingyun-feizhan-crossing.png) · [五条凌云山手记](lingyun-journal.png) · [药柜](lingyun-refuge-cabinet.png)

凌云山专项验收用三个阶段的测试档，经 Godot 常规移动和交互分别完成两条分支。也复测祭台门槛、主线安全路、战后再接支线和回执只记录一次。 [无界面检查](lingyun-headless.log) · [Windows 原生检查](lingyun-native.log) · [原图与生成指令](../../../art-source/lingyun/README.md)

```powershell
$godot = 'D:/AI/dev_toolchain/godot_tool_list/app/Godot_v4.7.2-stable_win64_console.exe'
& $godot --headless --path game --script res://tests/lingyun_settlement.gd -- --profile=qa_lingyun_settlement
```
