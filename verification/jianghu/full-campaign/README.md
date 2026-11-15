# 3.3.1 全战役验收

以公开版 3.3.0 和[修订战役设计](../../../CAMPAIGN_EXPANSION.md)为基线。复跑从正常标题新建存档，经十章、潮关原案及战后任务，再实走回凤溪。旧档检查使用发行包生成的测试存档及前一阶段保留的分支存档。

## 对照 SFC《时空之轮》

| 验收维度 | SFC 参照 | 《风云》本次验证 |
| --- | --- | --- |
| 主线动机和走法 | 从千年祭的意外追到中世纪，后来取得时空之门和飞船，终局有不同入口。 | 十章目标由敌人、证物与队伍交接。山庄入口与外哨换防有分岔，绝宫撤退和凌云山撤离有实际路线选择，主线仍以雄霸为共同决战终点。 |
| 回到旧地点有什么事可做 | 菲奥娜线包含沙漠战斗、伙伴暂离，后来回森林重聚。末段有多条可独立远征的任务。 | 七区以势力更替和灾后善后开放人物、通路和店铺。部分支线战可因证据或救援绕过。现有回访主要复用战役地形，独立远征与回访分量仍比 SFC 参照紧凑。 |
| 选择怎样兑现 | 彩虹贝壳经历寻路、首领、法庭举证与装备制作。 | 证词、炉契、换岗和药担都有接收对象。可改变战斗开场、捷径或货源。凤溪以现场人物交代去向，潮关结案后还可回凤溪查对应回执。 |

对标以 1995 年版的玩法结构为准。回访区域数、脚本行走时间、章节标题和真人首玩时长采用各自的口径。 [SFC 美版说明书](https://www.retrogames.cz/manualy/SNES/Chrono_Trigger_-_SNES_-_Manual.pdf) · [1995 年 Nintendo Player’s Guide](https://archive.org/details/Nintendo_Players_Guide_SNES_Chrono_Trigger_1995) · [Square Enix 作品页](https://www.jp.square-enix.com/chronotrigger/jp/about.html)

## 已修复的问题

- 补齐夜逃、运铁凭条、回山协调、聂风失散、绝宫西闸和终战后搬送百姓的动机与去向。第三章、七章入口存档刚落地时退出，读档可补放此前尚未播完的交接，已经播完的交接保持进度。
- 区域手记追踪先标当前场景可做的事。线索、交付或回执在同区域的另一张地图时，已开的正确出口会接续标记。剧情门槛尚未满足的出口保持原判定。
- 凌云山救援直接解锁凤溪安置。只做西坡的无采购路线也能立归人册，认真和潮关的船工对话可在韩朔战让鼓手少两格势。药炉接应的进度也可作为留下铺粮照看伤者的条件。
- 凤溪可到验印桌、药棚和桥东分别查证词、伤者和工匠。通关后同样可回访。潮关真正发出回执后，凤溪东埠才出现回航船工。公开分粮复核两户实发记录，交州府查留底船章。旧档保留结案和真实救援来源。

## 复测范围

| 新档路线 | 十章记录的战斗 / 潮关原案 | 主要进度与回到凤溪的结果 |
| --- | ---: | --- |
| [无采购](campaign-standard.log) | 19 / 2 | 西坡安置、立归人册、鼓手少两格势、免费凭单覆核，公开分粮后带回实发簿。 |
| [截势](campaign-interrupt.log) | 24 / 3 | 石阶断后，江杏记录成为覆核证据，州府会验后带回船章副联。 |
| [守反](campaign-retaliate.log) | 25 / 3 | 药炉撤离使聂风带护持迎战雄霸；邻里接济获得补给，冬粮使两户从潮关渡口直接备粮，阿芦证词归档后带回实发簿。 |
| [乘隙](campaign-exploit.log) | 23 / 1 | 西坡安置、从水栅进入潮关，指印船单作副证，护卷交州府并带回船章副联。 |

每条路线都读回两项潮关回执，实际乘回船到凤溪，重开存档后在东埠查自己那一案的结果。截势还在 Windows 原生窗口完整跑过。 [原生日志](campaign-native-interrupt.log) · [凤溪验印桌](homecoming_evidence.png) · [药棚](homecoming_care.png) · [回航副联](homecoming-tide-witness.png)

七区有 22 个常规可达地点、22 种区域状态和 7 个可选战斗入口。23 份实际场景的 250 个互动点和 73 个显式落点通过地形检查。不同剧情落点、互斥分支和复用场景按区域报告统计。 [地点与任务盘点](REGIONS.md) · [十章交接表](HANDOFFS.md) · [旧系统回归](regressions.log)

移动统计只表示脚本在关卡里走过的距离。设计的 12–16 小时主线、18–23 小时含较多选做，以及五人首次盲测仍是待验证指标。四条回归涵盖主要选择和两种结案，所有支线条件的排列仍可参考各自的专项证据。

## 发行包验证

- Windows 11 原生安装，Android 16 用独立模拟器触屏。两端都从公开版 3.3.0 覆盖安装、保留存档并重新进入首章和潮关。使用同一旧档走到凤溪药棚点位，3.3.1 显示西坡山民介绍获救的两户。 [Windows 结果](windows-331-result.json) · [Android 结果](android-331.log) · [旧版同位置](android-3.3.0-homecoming-same-point.png) · [新版触屏交谈](android-331-homecoming-care.png)
- [安装包 SHA-256](SHA256SUMS.txt) · [GitHub 3.3.1 Release](https://github.com/peterwangze/fengyun/releases/tag/v3.3.1)

## 复跑

在根目录使用此前配置的 Godot 控制台。`--profile` 为各次运行选用独立的 `qa_` 存档。

```powershell
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_full_campaign_standard --pacing --tidal --endgame --forging --cultivation --stage2b --stage3 --stage4 --full-campaign --stage2b-skip
```

配装路线用 `--quests --counterplay --quest-carryover --build-route=interrupt --stage4-settlement=witness` 代替 `--stage2b-skip`。守反用 `--build-route=retaliate --alternate`，乘隙用 `--build-route=exploit --tidal-sluice`。后两条各自省略截势的 `--stage4-settlement=witness`。原生截图需在去掉 `--headless` 后设置 `--reports=` 目录。输出中的 `ARCS`、`STAGE3`、`STAGE4`、`TIDAL` 与 `HOMECOMING` 记录实际走法。
