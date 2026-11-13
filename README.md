# 风云：山河劫

简体中文单机武侠 RPG，支持 Android 和 Windows。采用 Godot 4.7.2 和 GDScript。当前为 2.7.0，包含六章、潮关外篇、境界成长、战利品和江湖商铺。

## 开始游戏

**Android** 打开 APK 安装。系统提示时，允许当前浏览器或文件管理器安装该 APK。要求 Android 7.0 或以上及 OpenGL ES 3.0，支持 ARM64、ARMv7 和 x86_64。安装后横屏离线游玩。[下载 Android 2.7.0 APK](https://github.com/peterwangze/fengyun/releases/download/v2.7.0/Fengyun-2.7.0-android.apk)

**Windows 10/11 x64** 双击安装程序，完成后从开始菜单打开「风云：山河劫」。默认安装到当前用户目录，无需管理员权限。可在 Windows「已安装的应用」中卸载，存档保留。[下载 Windows 2.7.0 安装程序](https://github.com/peterwangze/fengyun/releases/download/v2.7.0/Fengyun-2.7.0-windows-x64-setup.exe)

[双平台发布说明和 SHA-256 校验](https://github.com/peterwangze/fengyun/releases/tag/v2.7.0) · [第三方许可](Windows/Licenses)

启动后选择「开启新篇」。初次启动也可从标题选择「凤溪试玩」。已有存档可从「章节回看」重玩已到达的章节，回看使用独立的临时进度。

这是一部六章的同人改编，从天下会同门切磋、婚宴决裂，写到绝无神夺权和龙脉易手，最后由风云重上祭台、回凤溪点灯收束。主线取自 2002 年电视剧《风云》，原作漫画为马荣成作品。走正门和石桥会经历 16 场主线战。另有八条支线，部分选择会触发可选战。对白、美术与配乐按游戏场景重新制作。[电视剧分集梗概](https://watch.plex.tv/zh/show/wind-and-cloud-conquer-the-world-2002/season/1) · [爱奇艺《风云必胜》](https://www.iqiyi.com/a_1acbd8hdkmp.html)

六章通关后，可从尾声或标题进入原创外篇「潮关余事」。在盐汊渡口找线索，从正门或水栅进入潮关粮仓，选择是否先解救被扣的证人，再决定如何交还账簿。外篇使用独立补给，随通关档记录进度。旧通关档可直接进入。

- **凤溪**可走石桥或解缆渡河。西岸客栈可核对调令、接应信使和认识第二梦。留意天池杀手的鸣哨预告。
- **剑池与魔池**可走泄火主桥或北侧石栈。取剑后随无名试招，再回天下会迎战雄霸。聂风在魔池用固守或第二梦的回春诀压住魔念。
- **绝宫与终战**可从天牢救出至尊，经茶房侧廊撤离。凌云窟、雨夜换血和送别先后发生。雄霸终战的三分归元气可用风云合璧或两次破势打散。

| Android 操作 | 触屏 | 手柄 |
| --- | --- | --- |
| 行走 | 在地图左下按住并拖动，松手即停。摇杆随触点出现 | 左摇杆或十字键 |
| 调查、对话、确认 | 靠近目标后点底栏出现的动作按钮，也可直接点对白框或菜单选项 | A 确认，左摇杆或十字键选择 |
| 战斗 | 点按招式，选择目标并查看预览，再点「确认出招」。可取消选招或跳过演出 | 方向选择，A 确认，B 取消，Y 跳过演出 |
| 手记、武学 | 从底栏「菜单」进入，可点队员及栏位装配 | 探索时 X 打开手记，Y 打开武学。武学里左右换人，X 换栏位 |
| 行装与境界 | 从底栏「菜单」进入，点队员、栏位、物品或「打法」 | 探索时 LB 打开行装。左右换人，X 换栏位，A 装备，RB 查看打法 |
| 暂停、返回 | 底栏「菜单」、「返回」或系统返回键 | Start 暂停，B 返回 |

在 Android 系统连接 USB 或蓝牙手柄，使用手柄后界面切换为手柄提示。再次触屏可恢复触屏布局。手柄按键名称以 Xbox 布局表示。

| Windows 操作 | 输入 |
| --- | --- |
| 行走 | WASD / 方向键，Shift 加速 |
| 调查、对话、确认 | E / Enter / 空格 / Z |
| 菜单与战斗选目标 | 方向键 / WASD，Enter 确认。按钮、敌人与队友状态卡支持鼠标点击 |
| 战斗招式 | 1–6 选招。B 打开药囊，5 快捷选择金创药。单体招式和药品需再选目标。播放战斗演出时，空格快进 |
| 暂停或取消 | Esc / X |
| 江湖手记 | J |
| 准备武学 | K。左右换人，Tab 换栏位，Enter 装配。暂停菜单也可进入 |
| 行装与境界 | I。左右换人，Tab 切换护具和佩物，Enter 装备，G 查看打法。暂停菜单也可进入 |
| 全屏切换 | F11 |

Windows 手柄映射与 Android 一致。屏幕提示随键鼠和手柄输入切换。Windows 窗口默认 1280 × 720，最小 640 × 360。

### 战斗与存档

- 上方显示敌人下一招和克制属性。武学削减势条，破势让敌人跳过一次行动。
- 普攻和固守回复真气。五名队员各有五门武学候选，可准备两门。积满四格且两人都站立时可发动专属合招。金创药能救起倒地的队友。
- 选中单体攻击时会预览敌人的势条变化。药囊里的聚气丸回真气，护脉散抵挡下一次受击，破势针可打断敌人。核对凤溪调令后可在客栈后窗拦截密探，他从第二回合起会尝试逃走。
- 青色「主」标记当前主线目标。江湖手记可查看八条支线的下一步、位置、期限和报酬，选择「追踪此事」后在当前场景标出「支」。
- 主线每累计四点历练提高一重境界。「行装与境界」显示当前属性与下次提升所需历练。护具和佩物各一栏，同一件可在队员间转交。行装来自开篇、境界、主线地点和支线，面板显示未取得行装的来源。
- 境界 2 开启搭配，境界 4 强化效果。截势打断首领重招时多回真气；守反接住攻击时可以制造空门并积攒合击；乘隙用重招打空门时追加消耗 3 真气来提高威力。武学页标出每招适用的打法，选敌时可预览收益与代价。
- 标准难度中，断浪蓄火后横扫全队；入魔之影会随魔念增强并吸走真气；被绝无神点名的队员可以固守或接受护持，接下金身重击便能打开空门。
- 标准难度的龙脉逆流可以打断，也可以护住队友来造空门。雄霸的护气可用合璧或两次破势拆开，护气散后留意点名掌击和全体气浪。潮关的鼓令可从韩朔或鼓手任一侧打断。
- 支线后果会延伸到后续章节。「旧账新印」可改变凤溪鸣哨战，「换岗的灯」改变龙脉战开场，「一柄未开锋的剑」的交接可影响终战或打开山路。渡口运送和石阶救援会在尾声得到回应。
- 完成「雨夜押书」后，可在绝宫茶房找到信使接应。凤溪保船或保粮的选择会延续到潮关，改变进粮仓的通路或开场补给，并在分粮时得到回应。
- 凤溪尾声可回访证人、药棚或获释船工。点灯后可以商议安置归人，早先保粮或帮助山民会解锁粮棚接济。安置决定会显示在结局，并在潮关渡口带来对应的联系人。
- 战斗、药箱和完成支线可获得银两，特定遭遇会掉落独有行装或秘籍。和凤溪行商、剑庐工匠、生死门药师、盐汊杂货商交谈可以交易。各店分别记录余货，潮关独立结算银两和补给。
- 行装现有八件护具和八件佩物。芦蓑披肩减轻横扫伤害，回锋护臂强化反击，仓卫厚甲更能抵挡重击。渡口铜哨和火麟剑穗可分别用于截势和乘隙。武学页会显示秘籍取得地点。
- 第一章完成婚宴与撤离目标后可以走正门或竹径。后续章节按上方目标解锁路线、剧情和出口。金色标记表示可选战或支线。手记记录进度，离开章节前会提示进行中的限章任务。
- 胜利、开箱、石灯、武学装配和关键剧情会写入存档。继续旅程从最近的章节安全点恢复。旧版存档保留进度，新增历史场景可从章节回看体验。败阵可原地重试。
- 标准与轻松两种难度在开档时选择。声音与动态特效可在设置中切换，Windows 另有窗口模式。
- 存档路径为 `%APPDATA%/Godot/app_userdata/风云：山河劫/jianghu.json`，同目录保留上一份备份。

## 工程与复现

| 路径 | 用途 |
| --- | --- |
| `game/project.godot` | Godot 工程入口 |
| `game/scripts/story.gd` | 章节、对白、人物、敌人和战斗配置 |
| `game/scripts/game.gd`、`game/scripts/first_chapter.gd` | 主流程、第一章演出和巡逻路线、输入、碰撞和音频 |
| `game/scripts/campaign.gd`、`game/scripts/campaign_art.gd` | 凤溪至终战的路线、章节状态和场景演出 |
| `game/scripts/chronicle.gd`、`game/scripts/side_stories.gd`、`game/scripts/martial.gd` | 扩展主线、八条支线和武学配置 |
| `game/scripts/afterstory.gd` | 潮关调查、两条路线与结案状态 |
| `game/scripts/battle.gd`、`game/scripts/equipment.gd` | 双人战斗、敌方行动、行装效果与获取条件 |
| `game/scripts/screen.gd`、`game/scripts/combat_art.gd`、`game/scripts/mobile_controls.gd` | 界面、地图、战斗动效与触屏控件 |
| `game/scripts/save.gd` | 存档、设置和备份恢复 |
| `tools/` | 地图、精灵与战斗特效加工、配乐合成、Windows 验证 |
| `art-source/` | 场景原图及生成提示词、参数记录 |
| `verification/` | 实际运行截图和测试结果 |

用 Godot 4.7.2 打开 `game/project.godot`，按 F6 运行当前主场景或 F5 运行项目。导出需要匹配的 Godot 模板。工程包含游戏运行所需资源。

从原始插画重新加工素材时，用带 Pillow 的 Python 依次运行 `tools/art_pass.py` 和 `tools/chronicle_art.py`。地图碰撞和战斗取景参数在 `art-source/` 各阶段的 `layout.json`。配乐和提示音可用 `tools/score.py` 与 FFmpeg 重新合成。

从本目录执行：

```powershell
$godot = 'D:/AI/dev_toolchain/godot_tool_list/app/Godot_v4.7.2-stable_win64_console.exe'
& $godot --headless --path game --editor --import --quiet
& $godot --headless --path game --export-release 'Windows Desktop' (Join-Path $PWD 'Windows/Fengyun.exe')
```

Windows 安装程序使用 Inno Setup 6.5.4 构建。完成 Windows 导出后，用已安装的 `ISCC.exe` 编译 `Windows/Fengyun.iss`，生成 `Windows/Fengyun-2.7.0-windows-x64-setup.exe`。[Inno Setup](https://jrsoftware.org/isinfo.php)

Android 使用 `Android` 导出预设。安装 OpenJDK 17、Android SDK 和匹配的 Godot 4.7.2 Android 模板，并在编辑器的 Android 设置里填入 JDK 和 SDK 路径。发布导出从环境变量 `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`、`GODOT_ANDROID_KEYSTORE_RELEASE_USER` 与 `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD` 读取签名配置。覆盖安装时需保持相同包名和签名证书。[Godot Android 导出文档](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html)

```powershell
New-Item -ItemType Directory -Force Android
& $godot --headless --path game --export-release 'Android' (Join-Path $PWD 'Android/Fengyun-2.7.0-android.apk')
```

查看 [玩法与叙事调研](DESIGN.md)、[素材记录](ASSETS.md)、[2.7.0 验收](verification/jianghu-market/README.md) 与 [Android 触屏验收](verification/android-touch/README.md)。

