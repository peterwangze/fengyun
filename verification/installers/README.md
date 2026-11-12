# 2.1.1 双平台安装验收

两个安装包发布在同一个 GitHub Release，附 SHA-256 校验文件。[2.1.1 发布页](https://github.com/peterwangze/fengyun/releases/tag/v2.1.1)

| 平台 | 安装包 | 大小 | SHA-256 |
| --- | --- | ---: | --- |
| Android | `Fengyun-2.1.1-android.apk` | 113,802,670 字节 | `45f1db8b6a4d2a00bf807ee2cf469160bb8ac8729555000f3434a947e2f76cdf` |
| Windows x64 | `Fengyun-2.1.1-windows-x64-setup.exe` | 62,937,637 字节 | `6ac6744a8c71d043f96ae3b41d076d8e742f3b5432994745cc6c18f493cfb06c` |

Windows 实测环境为 Windows 11 x64，系统版本 26200。使用 Inno Setup 6.5.4 打包 Godot 4.7.2 的 Windows x64 导出。安装程序没有 Authenticode 代码签名。[安装脚本](../../Windows/Fengyun.iss)

| 检查 | 验收结果 |
| --- | --- |
| 安装 | 直接执行安装包，游戏安装到 `%LOCALAPPDATA%\Programs\Fengyun`。安装后的 EXE 与 Godot 导出文件的 SHA-256 一致，游玩说明与第三方许可随安装复制 |
| 启动入口 | 检查开始菜单与可选桌面快捷方式，确认指向安装目录里的游戏。Windows「已安装的应用」读取到 2.1.1 和卸载入口 |
| 安装后的游戏 | 启动安装目录的 EXE，执行键鼠开局、婚宴撤离、续档、后期章节和潮关外篇回归。[标题](07-windows-title.png) · [开篇战斗](08-windows-battle.png) · [潮关战斗](25-windows-tidal-battle.png) |
| 卸载 | 卸载器退出码为 0，移除了程序、快捷方式和卸载登记。卸载前后的存档 SHA-256 一致 |

[Windows 验收结果](windows-install-result.json) · [现有 Windows 回归脚本](../../tools/verify-windows.ps1)

Android 安装包与已验收的 2.1.1 APK 字节一致，并重新验证了 APK 签名。此前在 Android 16 模拟器上从 2.1.0 覆盖安装并继续原存档。[Android 安装与触屏验收](../android-touch/README.md)
