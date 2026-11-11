# 2.0.1 首次游玩与实体手柄验收

## 本轮结果

| 项目 | 状态 | 证据 |
| --- | --- | --- |
| 五人首次游玩 | 尚未开始，0/5。当前无法安排首次玩家 | [记录表](player-form.md) |
| 实体手柄 | 尚未执行。本机 Godot 无已连接设备，XInput 四个槽均返回 1167，WinMM 无响应手柄 | [设备检测](controller-devices.json) · [实测清单](controller-checklist.md) |
| 左摇杆导航 | 2.0 可用摇杆移动角色，摇杆拨动时菜单焦点停在原位。2.0.1 在菜单、武学和战斗目标界面接入左摇杆，覆盖低幅偏移、保持拨住、回中和断开重连后的处理 | [修复前模拟复现](controller-before.log) · [修复后模拟回归](controller-after.log) |
| 操作提示 | 模拟手柄输入后，确认、取消和快进提示切换为 A、B 和 Y。键盘输入切回键盘提示 | [640×360 菜单](controller-menu-synthetic.png) · [战斗目标](controller-target-synthetic.png) |
| 六章复测 | 标准、轻松全遭遇、两套任务选择与终战破盾方式通过。另测触警后撤离、渡船折返和低动效 | [标准](controller-after.log) · [轻松全遭遇](all-encounters.log) · [备选路线](alternate.log) · [触警与渡船](alert.log) · [低动效](low-motion.log) |
| Windows 独立包 | 从临时目录启动，经系统键鼠输入完成独立凤溪试玩、开篇、客栈取证、装配、续档及尾声点灯 | [构建记录](build.json) · [最终 EXE 实测](windows-result.json) |
| 盲测启动器 | 自动启动三个 Windows 窗口并正常退出。重复打开同一编号使用原档位，另一个编号使用独立档位。每次退出生成独立日志和运行记录 | [启动器验证](launcher-smoke.json) |

界面截图与手柄行为回归使用注入的 Godot 输入事件。首玩时长、剧情理解率、玩家卡点和实体手柄手感暂无实际观测。

Windows 发布文件为 `Windows/Fengyun.exe`，产品版本 2.0.1.0，大小 144,412,432 字节。SHA-256 为 `5b45a765e43c4e271c37c831ef13bf7ce14e9bce614ade2622e17efe4ea9f103`。

## 五人首次游玩

1. 给五位从未玩过本作的玩家分配 P01 至 P05。用同一 EXE 和同一测试范围。全篇组从「开启新篇」开始。若只做凤溪试做，五人均从空档标题进入「凤溪试玩」，只统计凤溪结果。试玩在一个场次完成。全篇可分段，以相同参数重开本次存档。
2. 给玩家的统一说明为「请像平时一样游玩，需要时可以看游戏里的目标和手记。」记录从玩家首次取得控制开始的有效分钟数。暂停和休息另记。观察者记录路线、主动求助、错误操作和反复经过的场景，并保留玩家原话。
3. 发生停滞时记录屏幕目标、玩家想做什么、采取的操作、停留秒数和恢复方式。玩家请求帮助时先记下原话与时间。若给出提示，记录提示内容，方便区分独立完成和提示后完成。
4. 在离开凤溪及通关后按记录表提问，先记口述再评分。未到达的段落单列。凤溪验收目标是至少 4/5 位玩家能独立过河、理解西岸鸣哨会引来援兵，并说明去拜剑山庄取剑的动机。全篇目标是至少 4/5 位玩家能讲明绝无神如何夺权、第二梦为何换血、雄霸如何回归。
5. 给每个问题编号，标注版本、触发步骤和是否阻断。修复后用 `Retest` 轮次重做同一路径，记录是否复现和是否引入新卡点。复测者的用时和口述单独保留。若需重新衡量首次理解率，由未接触修复前流程的玩家测试。

从项目根目录启动单个测试。分别为 P01 至 P05 执行。每个编号、轮次和范围独立存档。首次运行时生成待填写的记录表。每次退出记下 EXE 版本、SHA-256、进程时间、退出码和 Godot 日志。有效游玩时间由观察者记入记录表。

```powershell
& ./tools/start-playtest.ps1 -Participant P01 -Round First -Scenario Campaign
& ./tools/start-playtest.ps1 -Participant P02 -Round First -Scenario Campaign
# 同样启动 P03 至 P05。只测凤溪时，五位均把 Campaign 改为 Fengxi。
# 修复后复测原卡点时把 First 改为 Retest。
```

记录输出到 `verification/playtest/sessions/`。如需续玩同一轮，使用相同参数与相同构建。配套存档与平时双击 EXE 的存档独立。

## 实体手柄

按 [实测清单](controller-checklist.md) 记录型号和接线方式，完成摇杆与方向键导航、探索、暂停、武学、选目标、渡船、拔插和键鼠切换。每项记录原步骤及实际结果。有故障时用同一设备复测修复版。

## 复跑模拟回归和 Windows 键鼠验收

```powershell
$godot = 'D:/AI/dev_toolchain/godot_tool_list/app/Godot_v4.7.2-stable_win64_console.exe'
$reports = (Resolve-Path verification/playtest).Path
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_playtest_controller_after
& $godot --resolution 640x360 --path game --script res://tests/acceptance.gd -- --profile=qa_playtest_visual --boat --ledge --miss-signal --poise-finish "--reports=$reports"
& ./tools/verify-windows.ps1 -ReportDirectory $reports -LaterChapters -Expansion
```
