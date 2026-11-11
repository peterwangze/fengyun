# Android 2.1.0 验收

验收对象为签名 APK `Fengyun-2.1.0-android.apk`，包名 `io.github.peterwangze.fengyun`，版本号 `20100`。APK 大小 113,802,670 字节。`apksigner` 验证 v2 与 v3 签名，`zipalign -c -P 16 4` 通过。Android 7.0 起可安装，包内含 ARM64、ARMv7 和 x86_64。[下载与校验](https://github.com/peterwangze/fengyun/releases/tag/v2.1.0-android)

SHA-256 `27dd6921f82d140e3af5e405e6e39b386f644ed20e6e0461b9b609f1bab57a23`

| 检查 | 实测结果 | 证据 |
| --- | --- | --- |
| APK 安装与启动 | Android 16 x86_64 模拟器上安装 APK，清空测试档后从标题开始新篇。横屏分别检查 2400 × 1080 和 1280 × 720 | [标题](01-title.png) · [宽屏探索](04-touch-field.png) · [16:9 探索](27-16x9-field.png) · [启动日志](launch.log) |
| 触屏探索 | 摇杆移动、互动、打开及关闭手记和武学。先从屏幕边缘滑出系统栏，再做 Android 返回手势，打开暂停 | [手记](05-touch-journal.png) · [武学](06-touch-martial.png) · [暂停](07-android-back-pause.png) · [移动与互动](16-touch-move.png) |
| 触屏战斗 | 从地图触发同门切磋，点按招式和目标，取消选招，跳过演出，战胜后返回地图 | [选招](18-touch-battle.png) · [选目标](19-touch-target.png) · [取消后](20-touch-cancel.png) · [演出](21-touch-battle-effect.png) · [胜利](23-spar-victory.png) |
| Android 手柄链路 | 以 `adb shell uinput -` 注册 USB 虚拟手柄。Android 识别 `GAMEPAD` 和 `JOYSTICK`，Godot 接收实际系统输入。检查左摇杆、十字键、X 手记、Y 武学、X 换栏、B 返回、Start 暂停、A 恢复。触屏后恢复虚拟控件 | [摇杆移动](09-pad-move.png) · [手柄武学](10-pad-martial.png) · [换栏](11-pad-slot.png) · [手柄暂停](12-pad-pause.png) · [恢复触屏](15-touch-resume.png) |
| 后台与存档 | 切磋胜利后返回桌面，再打开游戏恢复。强制停止进程并重新启动，从标题继续后保留切磋完成状态 | [后台恢复](25-background-return.png) · [重启续档](26-save-relaunch.png) |
| 脚本回归 | 双指事件独立、斜向拖动、切后台释放、切换界面释放、返回事件均通过。六章主线、八条支线及潮关外篇水栅路线回归零失败 | [触屏回归](touch-regression.log) · [剧情与战斗回归](game-regression.log) |

模拟器使用主机 GPU 加速。SwiftShader 软件模式出现 Godot OpenGL 着色器链接错误和黑屏。实体手机、实体 USB 或蓝牙手柄尚无本轮实测数据。[Godot 上游问题](https://github.com/godotengine/godot/issues/109550)

触屏回归可用 `godot --headless --path game --script res://tests/touch_controls.gd -- --touch-controls --profile=qa_touch_controls` 复跑。原生触屏坐标由 UI Automator 返回的 `SurfaceView` 边界与 640 × 360 游戏坐标换算。
