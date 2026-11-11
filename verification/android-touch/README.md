# Android 2.1.1 触屏验收

原探索界面的固定摇杆会挡住步惊云，右侧按钮靠近人物和互动标记。新版采用触点摇杆，按住拖动才在人物图层下绘制半透明摇杆。菜单和临近目标的互动动作放进底栏，手记与武学从菜单进入。参考《星露谷物语》的隐形摇杆和《泰拉瑞亚》的移动控件分区。[星露谷物语安卓说明](https://www.stardewvalley.net/android-version-coming-soon/) · [泰拉瑞亚官方 Wiki](https://terraria.wiki.gg/wiki/Settings)

| 项目 | 结果 | 证据 |
| --- | --- | --- |
| 覆盖安装与前后对照 | 使用相同签名从 2.1.0 覆盖到 2.1.1，直接读取旧存档。1280 × 720 的同一位置，松手时场景人物和标记全部可见。2400 × 1080 也完成了续档和输入检查 | [2.1.0](01-before.png) · [2.1.1](02-after.png) · [宽屏](15-wide-field.png) |
| 摇杆与互动 | 左下拖动显示半透明摇杆，松手消失。靠近守门执事时底栏显示目标，点按后进入对白。空互动栏及原右侧位置无响应 | [拖动时](07-floating-stick.png) · [松手且靠近目标](08-nearby-action.png) · [对白](09-interaction-dialogue.png) |
| 底栏菜单 | 从底栏打开菜单、手记和武学，使用底栏返回 | [菜单](04-bottom-menu.png) · [手记](05-journal.png) · [武学](06-martial.png) |
| 战斗 | 从新底栏进入守门执事战，点按招式和目标，取消选招并跳过演出 | [选招](10-battle.png) · [目标](11-select-target.png) · [跳过演出后](14-battle-skip.png) |
| 手柄切换 | Android 识别 `uinput` 虚拟 USB 手柄。Start 打开暂停，A 恢复，左摇杆移动。首次触屏即可恢复触屏布局并打开底栏菜单 | [手柄移动](17-pad-field.png) · [首次触屏](18-touch-after-pad.png) · [识别日志](gamepad.log) |
| 游戏逻辑回归 | 浮动触点、死区、双指、后台释放、菜单、近距离互动均通过。六章、八条支线及潮关外篇水栅路线回归零失败 | [触屏日志](touch-regression.log) · [流程日志](game-regression.log) |

实测使用 Android 16 x86_64 模拟器和主机 GPU 加速。实体手机和实体手柄尚未实测。底栏菜单及互动的点击区域在两种测试分辨率下均约高 51 dp。[Android 触控目标指南](https://developer.android.com/guide/topics/ui/accessibility/views/apps-views#large-controls)

APK 版本号 `20101`，大小 113,802,670 字节。APK v2/v3 签名与 16 KiB ZIP 对齐检查通过。SHA-256 为 `45f1db8b6a4d2a00bf807ee2cf469160bb8ac8729555000f3434a947e2f76cdf`。[发布页与校验文件](https://github.com/peterwangze/fengyun/releases/tag/v2.1.1-android)
