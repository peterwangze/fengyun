# 《风云：山河劫》2.1 验收

环境为 Windows 11 x64、Godot 4.7.2 stable、OpenGL Compatibility。脚本和 Windows 窗口测试使用独立 QA 档。

| 范围 | 实测项目 | 证据 |
| --- | --- | --- |
| 标准主线与正门 | 从新档完成六章，尾声进入外篇。守卒战败阵可重试，药品恢复到战前。击败守卒开路，救人只发一次补给。鼓阵生效后由一击消耗，最终公开账簿 | [正门全流程](gate.log) |
| 轻松难度与水栅 | 走主线的竹径、渡船和北侧石栈，完成八条支线。外篇开绞盘绕过守卒，打断鼓手，跳过救援仍能交由州府清点 | [水栅全流程](sluice.log) |
| 低动效与续档 | 主线触警后撤离。低动效下可完成水栅结案。两条路线都验证房间续档、结案选择取消与恢复、主线历练和药品保存 | [低动效](reduced-motion.log) |
| 640×360 画面 | 查看盐汊渡口的交互点、粮仓两种敌人的预告和护阵反馈，以及结案回访状态 | [运行日志](visual.log) · [渡口](tidal-ford.png) · [粮仓战](tidal-chief.png) · [鼓阵](tidal-ward.png) · [结案](tidal-complete.png) |
| Windows 独立 EXE | 原生窗口使用键盘进入外篇，核对名册和封条，开启水栅，入仓触发韩朔战，并重启续档。另用已带回账簿的测试档实际选择并保存结案 | [Windows 结果](windows-result.json) · [战斗](25-windows-tidal-battle.png) · [结案](28-windows-tidal-complete.png) |

外篇两条路线已走完。真人首玩时长和实体手柄体验尚无新实测数据。[既有盲测与实体手柄安排](../playtest/README.md)

发布文件为 `Windows/Fengyun.exe`，产品版本 2.1.0.0，大小 144,765,760 字节。SHA-256 为 `4234a2d4a8fbacd839dd75251302a333330706375728723d072e84ea6839b75f`。[构建记录](build.json)

## 复跑

```powershell
$godot = 'D:/AI/dev_toolchain/godot_tool_list/app/Godot_v4.7.2-stable_win64_console.exe'
$reports = (Resolve-Path verification/tidal).Path
& $godot --headless --path game --editor --import --quiet
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_tidal_gate --tidal
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_tidal_sluice --tidal --tidal-sluice --quests --all-encounters --alternate --boat --ledge --poise-finish --miss-signal --rear-route=quiet
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_tidal_reduced_motion --tidal --tidal-sluice --low-motion --rear-route=alert
& $godot --resolution 640x360 --path game --script res://tests/acceptance.gd -- --profile=qa_tidal_visual --tidal "--reports=$reports"
& ./tools/verify-windows.ps1 -ReportDirectory $reports -LaterChapters -Tidal
```
