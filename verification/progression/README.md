# 2.4.0 玩法与安装验收

| 检查 | 实际覆盖 | 证据 |
| --- | --- | --- |
| 六章节奏 | 四条从标题走到尾声的输入回归，覆盖两种难度、两组支线选择、主线两类终战破盾和潮关两路。另以 Windows Godot 图形窗口重跑标准八支线路线。 | [四条路线与复现命令](PACING.md) · [图形窗口日志](rendered.log) · [婚宴分岔标记](wedding-guidance.png) |
| 武学与行装 | 截势回气、守反积合击、乘隙追加威力、境界 2 和 4、佩物取舍与选敌预览。逐章配装路线触发 7 次截势、6 次守反、5 次乘隙。 | [搭配专项](builds.log) · [行装回归](equipment.log) |
| 支线后果 | 45 项验证覆盖口供、绝宫换岗、旧剑交接，检查读档、重试、错过交接后的补完和两种尾声回应。 | [支线专项](branch-payoffs.log) |
| Windows | 在 Windows 11 x64 从 2.3.0 覆盖安装，用键盘、鼠标操作安装目录中的游戏，检查打法页、婚宴、后半程和潮关。卸载保留存档。 | [打法页](34-windows-build-guide.png) · [安装结果](windows-install-result.json) |
| Android | Android 16 模拟器覆盖安装 2.3.0，保留原签名证书和旧档。使用宿主 GPU，从标题读档后以触屏进入行装、打开打法说明并返回地图。 | [旧档地图](01-android-continue.png) · [打法页](03-android-build-guide.png) · [运行日志](android.log) |

真人首次通关时长、实体 Android 手机和实体手柄仍待验证。Windows 安装程序未签名。

切换到 SwiftShader 软件渲染时，Android 模拟器遇到 CanvasShaderGLES3 片元 uniform 上限错误并黑屏。恢复宿主 GPU 后通过画面与触控复测。[Godot 上游问题](https://github.com/godotengine/godot/issues/109550)
