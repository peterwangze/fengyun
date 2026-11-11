# 《风云：山河劫》2.0 验收

现行版本新增的潮关外篇与 Windows 实测见 [2.1 验收记录](tidal/README.md)。

2.0.1 的摇杆导航修复、Windows 复验与五人盲测、实体手柄待执行项目，见 [2.0.1 验收记录](playtest/README.md)。下列数据对应 2.0.0。

环境为 Windows 11 x64、Godot 4.7.2 stable、OpenGL Compatibility。测试使用独立 QA 存档。

| 流程 | 结果 | 记录 |
| --- | --- | --- |
| 标准主线 | 跳过八条支线，从同门切磋走到清晨点灯。正门、石桥路线完成 12 场原主线战和 4 场新增主线战。首次雄霸战实际用合璧破盾，祭台终战同样用合璧解盾 | [标准主线](chronicle/front.log) |
| 轻松难度与支线 | 完成 18 场原有主线及可选遭遇、4 场新增主线战，以及八条支线的第一组结果 | [全部原遭遇与八条支线](chronicle/quests.log) |
| 另一组选择与配招 | 竹径潜行、渡船、北侧石栈。完成八条支线的另一组选择，其中信使、狱卒和山道走交战分支。终战以换装后的两次破势解盾 | [另一组选择](chronicle/alternate.log) |
| 第一章触警和低动效 | 巡卫发现后仍从后门撤离。石桥战后改走船，低动效下上岸，历练仅发一次。全程开启低动效的标准路线与常规路线战斗结果一致 | [触警与渡船](chronicle/alert.log) · [低动效](chronicle/low-motion.log) |
| 640 × 360 实际窗口 | 检查场景通路、人物、手记入口、武学面板和战斗效果 | [窗口日志](chronicle/visual.log) · [凤溪客栈](chronicle/2-inn.png) · [武学](chronicle/2-martial.png) · [绝宫起火](chronicle/2-tearoom-fire.png) · [雨夜换血](chronicle/2-blood-rite.png) · [清晨凤溪](chronicle/2-dawn.png) |
| 武学与存档 | 验证四组专属合招，覆盖援兵延期、代挡、魔念压制、金身空门和终战双解。检查两套装配、机关次序、旧档接入、损坏档恢复、离章提醒与独立章节回看 | [回归脚本](../game/tests/acceptance.gd) |
| Windows 独立包 | 从临时目录启动，空档进入独立凤溪试玩，鼠标开局，键盘完成切磋、婚宴和竹径续档。另用独立章节档实测渡船、客栈取证、装配、天牢重启续档、祭台和尾声点灯 | [最终 EXE 结果](chronicle/windows-result.json) · [试玩](chronicle/19-windows-fengxi-trial.png) · [取证](chronicle/21-windows-inn-evidence.png) · [装配](chronicle/22-windows-martial.png) · [点灯](chronicle/23-windows-dawn.png) |

手柄映射经过模拟事件测试，Godot 与本机设备清单均未发现实体手柄。五人首次玩家盲测尚未进行，凤溪首次游玩时长、全篇时长和剧情理解率仍待实测。标题中的「凤溪试玩」可从空档进入。已有档的「章节回看」使用临时进度。

2.0.0 发布文件的产品版本为 2.0.0.0，大小 144,410,544 字节。SHA-256 为 `fee577363f53f321301719933b1ac8b5d9a3f32efdbd70fe0db10de170ee4cf3`。[构建记录](chronicle/build.json)

## 2.0 复跑

```powershell
$godot = 'D:/AI/dev_toolchain/godot_tool_list/app/Godot_v4.7.2-stable_win64_console.exe'
$reports = (New-Item -ItemType Directory -Force verification/chronicle).FullName
& $godot --headless --path game --editor --import --quiet
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_expansion_front
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_expansion_quests --quests --all-encounters
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_expansion_alternate --quests --alternate --boat --ledge --poise-finish --miss-signal --rear-route=quiet
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_expansion_alert --rear-route=alert --bridge-then-boat --reduced-ferry
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_expansion_low --low-motion
& $godot --resolution 640x360 --path game --script res://tests/acceptance.gd -- --profile=qa_expansion_visual --quests --alternate --boat --ledge --miss-signal --poise-finish "--reports=$reports"
& ./tools/verify-windows.ps1 -ReportDirectory $reports -LaterChapters -Expansion
```

## 1.6 历史验收

环境为 Windows 11 家庭版 x64（26200）、Godot 4.7.2 stable、OpenGL Compatibility。测试使用独立 QA 存档。

| 流程 | 实测结果 | 记录 |
| --- | --- | --- |
| 标准难度六章 | 12 场战斗通关。正门撤离、石桥渡河、打断鸣哨、泄火主桥、合璧破盾 | [正门与石桥](evolution/front.log) |
| 轻松难度六章 | 完成全部 18 场战斗，包含 6 场可选战 | [全遭遇](evolution/all.log) |
| 竹径与改走渡船 | 未触警撤离。打过桥头后改搭渡船，折返与重读档未重复发放历练。关闭动态特效后直接上岸，剑池走北侧石栈 | [竹径潜行与路线切换](evolution/quiet.log) |
| 竹径触警 | 警戒保存，击败巡卫后由竹径后门撤离 | [触警](evolution/alert.log) |
| 640 × 360 窗口 | 正门撤离后直接走渡船。漏断鸣哨后次轮出现一名援兵。北侧石栈可达剑炉，终战用两次破势破盾，消耗两剂金创药通关 | [窗口日志](evolution/visual.log) · [渡船](evolution/ferry-crossing.png) · [终战](evolution/04-final-battle.png) |
| 战斗与存档 | 检查取剑后的招式、魔念反噬、固守和回春诀压制、败阵重试、1.1 与 1.2 存档、损坏主档后备份恢复 | [回归脚本](../game/tests/acceptance.gd) |
| 独立 EXE | 从临时工作目录启动。实测鼠标开局、键盘首战、婚宴、两次疏散和竹径续档。用独立章节存档实测解缆登船与落地、天牢救援及重启续档、雨夜送别和祭台演出 | [Windows 运行结果](evolution/windows-result.json) · [西岸续档](evolution/13-windows-west-checkpoint.png) · [天牢续档](evolution/15-windows-jail-continue.png) · [雨夜送别](evolution/16-windows-farewell.png) |

战斗日志逐场记录回合数、剩余金创药和两位队员的真气，并汇总使用的武学、固守和合击次数。A、B、方向键和 Y 已通过 Godot 输入事件测试。本机未发现实体手柄。规划中的五位首次玩家盲测尚未进行，凤溪首次完成用时和独立完成比例暂无实测数据。

当时导出文件的产品版本为 1.6.0.0，共 143,170,192 字节。SHA-256 为 `b3735faa65c0191e962b1a4985ea9a4c2b9e3d4da080b8b3f6fec8b7e5dadf53`。

### 1.6 历史测试命令

```powershell
$godot = 'D:/AI/dev_toolchain/godot_tool_list/app/Godot_v4.7.2-stable_win64_console.exe'
$reports = (New-Item -ItemType Directory -Force verification/evolution).FullName
& $godot --headless --path game --editor --import --quiet
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_evo_front
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_evo_all --all-encounters
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_evo_quiet --rear-route=quiet --bridge-then-boat --ledge --reduced-ferry
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_evo_alert --rear-route=alert
& $godot --resolution 640x360 --path game --script res://tests/acceptance.gd -- --profile=qa_evo_visual --boat --ledge --miss-signal --poise-finish "--reports=$reports"
& ./tools/verify-windows.ps1 -ReportDirectory $reports -LaterChapters
```

1.2 的截图和日志保留在 [chapter-one](chapter-one/windows-result.json)，1.1 的证据保留在 `art-update/`。
