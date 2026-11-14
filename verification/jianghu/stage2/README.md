# 第二阶段回访与主线验收

四份标准难度新档在 Windows 的 Godot 4.7.2 中从序章走完十章，再完成潮关结案。前三项成长路线以常规步行、互动、菜单和选招完成区域活动。标准无采购路线跳过这些活动，并确认主线可独立推进。一条截势路线另用 1280 × 720 桌面窗口运行。

| 新档路线 | 十章遭遇 | 潮关遭遇 | 脚本步行，主线内合计 | 其中区域回访 | 五项交接 |
| --- | ---: | ---: | ---: | ---: | --- |
| [标准无采购、跳过回访](standard.log) | 19 | 3 | 246.0 秒 | 0 秒 | 0 项 |
| [截势](interrupt.log) | 24 | 3 | 501.3 秒 | 159.8 秒 | 全部 |
| [守反](retaliate.log) | 22 | 3 | 513.0 秒 | 174.7 秒 | 全部 |
| [乘隙](exploit.log) | 24 | 3 | 504.8 秒 | 159.8 秒 | 全部 |

十章遭遇包含该路线实际打过的任选区域战。脚本按默认步速折算路线，复验捷径、续档和切换造成的折返也计入，回访步行包含在主线内合计。对话阅读、战斗和思考的时间另计，当前数据无法确认 4–6 小时的首玩设计目标。

- 凤溪、拜剑山庄、天下会外哨与生死门在同一新档依次开放。三对区域出口均往返实走，并抵达对应落点。通过区域出口、双向捷径及重启后仍保留原来的主线房间、坐标、章节、已清遭遇和路程记录。 [四区地形及连通性专项](geometry.log)
- 常规山隘、摘下探子令牌和炉道分别走通。炉道提供聂风初战护持。外哨分别走岗门救证人与避哨的旧宅路，进错时机保留检查点。西闸的普通流程实战一次，匿名抄件流程可亲自穿过南沟格栅，避开该战。
- 取得线索、在目的地交接、重启、重查记录和实际后效均通过。炉契接单使外哨卷轮开放，避难方案开启另一条路和药柜。渡口药单在药庐换得韧丝并开放断栈台阶。及时提交署名证词或密封样本，分别削低天牢卫队的势、给步惊云护持。具名换岗簿提供开局合击，匿名本可绕西闸。断栈护脉药和换气字条分别在绝无神战中保护队员或削势。
- 守反路线将凤溪证词留到火后，沿外哨驿道前往战后前庭补交。同档的天牢初战没有预领援助，最终保有交接记录。旧阶段存档迁移独立核对，保留已经取得的援助也不会虚构交接或重复领物。 [凤溪旧档 290 项](legacy-network.log) · [山庄旧档及回访 283 项](legacy-regions.log)
- [Windows 图形全程](native.log)已检查 [区域回访中的交接手记](stage2b-handoff-journal-medicine_handoff.png)、[绝宫交接手记](stage2b-handoff-journal-register_handoff.png)、[断栈药担实物](stage2b-handoff_carry.png)、[外哨路](transit-outer_watch-checkpoint.png)、[主线结局](06-ending.png)和[潮关结案](tidal-complete.png)。

## 3.1.0 双平台安装包

- Windows 11 x64 实装从 3.0.0 升级，检查卸载登记、开始菜单和桌面快捷方式，确认安装后的可执行文件与 Godot 导出一致。键鼠进入外哨、查看当地手记和交接页、切到生死门、回药庐并重启续档。卸载保留现有存档。 [安装验收](windows-stage2b-result.json) · [四地选择](windows-stage2b-region-picker.png)
- Android 16 x86_64 独立模拟器以同一签名覆盖 3.0.0，核对测试主档和备份的字节。触屏依次选择四地，以虚拟摇杆抵达外哨证人，完成对话后取得证据，再回药庐并重启续档。APK 签名和 16 KB ZIP 对齐通过。 [安装验收](android-stage2b.log) · [外哨对话](android-stage2b-watch-witness.png) · [跨区交接页](android-stage2b-handoffs.png)
- 两个平台的 [SHA-256](SHA256SUMS.txt) 对应正式版安装包。实体 Android 手机与实体手柄本次未实测。

## 源码复现

在项目根目录把 $godot 设置为 Godot 4.7.2 控制台程序的路径。

~~~powershell
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_stage2b_standard --pacing --tidal --endgame --forging --cultivation --stage2b --stage2b-skip
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_stage2b_interrupt --pacing --tidal --endgame --forging --cultivation --stage2b --quests --counterplay --quest-carryover --build-route=interrupt
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_stage2b_retaliate --pacing --tidal --endgame --forging --cultivation --stage2b --quests --counterplay --quest-carryover --build-route=retaliate
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_stage2b_exploit --pacing --tidal --endgame --forging --cultivation --stage2b --quests --counterplay --quest-carryover --build-route=exploit
~~~
