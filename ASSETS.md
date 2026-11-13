# 素材与出处

| 交付位置 | 来源 | 处理或使用说明 |
| --- | --- | --- |
| `game/assets/paintings/title.png`、`village.png` | 本机 Qwen Turbo / ComfyUI，工具链 `image_gen_tool_list/generate.py` | 标题及尾声的备用底图。原图、提示词、种子和任务记录在 `art-source/` |
| `game/assets/paintings/ending.png` | 内置 GPT 图像生成工具 | 尾声雨渡插画，裁切并量化为 112 色。工具接口未提供可核验的模型版本。提示词及原图见 `art-source/ending.json` 与 `art-source/ending.png` |
| `game/assets/field/`、`game/assets/arenas/` | 内置 GPT 图像生成工具，参考尾声和初版地图构图 | 本地 Pillow 裁切、调色及限色。根据六张地图重新标注行走、桥面、障碍及互动点；战场使用同章地图取景 |
| `game/assets/actors/` | 内置 GPT 图像生成工具，两张透明角色原画图集 | 本地工具按单角色裁切、限色、固定脚点，逐帧制作行走、出招、格挡、受击及倒地 |
| `game/assets/vfx/` | 内置 GPT 图像生成工具，透明特效原画图集 | 本地工具拆出 8 类效果，校验透明通道并限色。Godot 控制时间、镜像、位移、粒子和淡出 |
| `game/assets/field/props/`、`game/assets/icon.png` | 项目原创，通过 Pillow 绘制 | 石灯、药箱、门标及 Windows 图标。初版地图与精灵保留作构图参考 |
| `game/assets/audio/` | 项目原创旋律和提示音 | `tools/score.py` 合成，FFmpeg 编码为 Ogg Vorbis |
| `game/assets/fonts/NotoSansSC.ttf` | [Google Fonts 上游](https://github.com/google/fonts/tree/main/ofl/notosanssc) | SIL OFL 1.1。字体文件保持原样，游戏选用 420 字重 |
| `game/assets/fonts/NotoSerifSC.ttf` | [Google Fonts 上游](https://github.com/google/fonts/tree/main/ofl/notoserifsc) | SIL OFL 1.1。字体文件保持原样，游戏选用 550 字重 |
| `Windows/Fengyun.exe` 的引擎部分 | [Godot 4.7.2 官方发布](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable) | 使用本机标准版 Godot 和匹配的 Windows x64 模板。MIT 许可和第三方归属收录于 `Windows/Licenses/` |
| Windows 安装向导 | [Inno Setup 6.5.4](https://github.com/jrsoftware/issrc/releases/tag/is-6_5_4) · [简体中文翻译](https://github.com/kira-96/Inno-Setup-Chinese-Simplified-Translation/tree/6.5.0%2B) | 安装器图标由项目的 `game/assets/icon.png` 转换。安装器许可见 [InnoSetup-LICENSE.txt](Windows/Licenses/InnoSetup-LICENSE.txt) |
| Android APK 的引擎部分 | [Godot 4.7.2 官方发布](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable) | 使用匹配的 Android Release 模板。引擎、依赖和字体许可见 [第三方许可](Windows/Licenses) |

《风云》人物、设定与改编依据归各自权利人。本作是同人改编。《时空之轮》作为视觉参照。内置艺术素材未使用电视剧画面、演员照片、漫画图稿或原声。

1.1 使用内置 GPT 图像生成工具。原图与完整提示词在 [美术更新提示词](art-source/art-update/prompts.json)，人工校准参数在 [场景坐标](art-source/art-update/layout.json)，游戏资源由 [本地加工脚本](tools/art_pass.py) 生成。

1.2 用同一工具参考 1.1 的天下会庭院、角色精灵及尾声插画，补绘正堂、竹径和四位婚宴人物。本地脚本生成探索底图、巡卫战斗取景、前景竹叶遮挡和角色帧。见 [第一章提示词与原图索引](art-source/chapter-one/prompts.json) 和 [第一章地图坐标](art-source/chapter-one/layout.json)。

1.3 至 1.6 补绘渡船和船家、天牢及至尊、雨夜小筑、五位队员的正背面行走和风神腿、排云掌、风云合璧等八张招式姿势。六张 GPT 图像原图和完整提示词保存在 `art-source/evolution/`。本地 Pillow 统一 56 × 56 帧格与脚点，处理透明边、色数、四帧步态、北侧石栈、前景遮挡和道具。新音效包括船行、机关和哨声，由本地脚本合成并用 FFmpeg 编码。[图像提示词与原图索引](art-source/evolution/prompts.json) · [地图校准数据](art-source/evolution/layout.json)

2.0 用内置 GPT 图像生成工具制作西岸客栈、剑庐、药庐、茶房侧廊、凌云窟、清晨凤溪、新人物、肖像、火场道具及八种武学效果。十张原图与完整提示词保存在 `art-source/chronicle/`。本地 Pillow 生成 320 × 180 场景、56 × 56 角色帧及透明前景。原有曲调经 `tools/score.py` 衍生出客栈、剑庐、换血、终战和清晨凤溪五首循环。五种新增武学起手音也由本地合成，并与配乐一同用 FFmpeg 编码。[2.0 图像提示词](art-source/chronicle/prompts.json) · [地图校准数据](art-source/chronicle/layout.json) · [本地加工脚本](tools/chronicle_art.py)

2.1 使用内置 GPT 图像生成工具制作盐汊渡口、潮关粮仓，以及韩朔和鼓手的透明原图。三张原图保存在 `art-source/tidal/`。本地脚本生成 320 × 180 探索图、战场取景、透明前景以及统一脚点的 56 × 56 角色帧。[2.1 图像提示词](art-source/tidal/prompts.json) · [地图校准数据](art-source/tidal/layout.json)

3.0.0 使用内置 GPT 图像生成工具补绘 [战役设计](CAMPAIGN.md) 中的十张宽地图。提示指定 16 位俯斜视角、横向连续地形和按剧情配置的地标。下山驿道为火把巡卫与断梁，雨巷为斗笠货棚与车辙，剑池山隘为上坡工人和下坡哨道，西闸为绞盘、潮槽及茶房东梯。原型图稿经审查后与正式路线对齐。[本地像素处理](tools/transit_art.py) 将画面缩放到 768 × 180 并限制到 176 色，地形参数保存在同名 JSON。Godot 在战斗时取当前区域图块。工具接口未提供可核验的图像模型版本。

宽地图提示的共同要求是保持 3∶1 横向画幅、固定俯斜视角、清晰低起伏的脚点、横向连通的中下部通路。画面保留高处远景和低处边界，省去人物、界面和文字。每张图的剧情与构图重点如下，生成任务均使用原有场景作风格参考。

| 输出 PNG（`game/assets/field/`） | 画面重点 |
| --- | --- |
| `courtyard_road` | 夜间山门、断梁、上下坡分岔与出山火把 |
| `fengxi_lanes` | 西岸雨巷、栈桥、遮雨卸货处、接应哨灯 |
| `lantern_pass` | 山庄铁车、上坡松台、低处炭栈和炉烟 |
| `outer_watch` | 旧哨换旗、林路证物与守卫笼门 |
| `broken_trestle` | 谷口响钟、木断栈、干燥高台与石浅滩 |
| `palace_sluice` | 湿石闸渠、巡卫侧台、残拓和茶房东梯 |
| `dragon_waterway` | 引水渠石岸、高堤扶绳、低处旧闸和凌云窟 |
| `dragon_ridge` | 风雨断脉、残灯、阴坡和可护药炉的石台 |
| `summit_steps` | 背坡避险石阶、诱敌吊桥和祭台入口 |
| `tidal_canal` | 卸粮棚、潮沟船单、绞盘和粮仓石阶 |

