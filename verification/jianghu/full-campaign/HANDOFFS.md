# 十章主线接续验收

按[战役扩充设计](../../../CAMPAIGN_EXPANSION.md)核对上一章发生的事、玩家下一步为何行动、地图上的实际去向。章节编号采用游戏标题的十章顺序。自动化走图经常规移动和交互推进，读档专项另用可重跑的入口夹具核验存档坐标及剧情状态。

| 接续 | 章末动机与接手者 | 实走途经的剧情标记 |
| --- | --- | --- |
| 壹 天下会夜变 → 贰 凤溪风雨 | 封令在婚宴之前写好。秦霜从西岸收货人手里找另一半，聂风由东岸找渡工，步惊云由山路绕到西岸。三短一长确认接应。 | 喜堂逃生后下山 → `escape_orders` → `escape_lantern` → `escape_river` → 渡口渡河和雨巷调查 |
| 贰 凤溪风雨 → 叁 剑池初鸣 | 凭条的炉印来自拜剑山庄，押运人另盖新印掩饰运铁。无名来信指明断浪的去向。秦霜留在西岸护住人证，聂风和步惊云走西南山口。 | `lanes_bill` → `lanes_exit` → 西岸身分核验、纸探花和重聚 → `lantern_pass` 的 `pass_cart` → 山庄外门 |
| 叁 剑池初鸣 → 肆 重返天下会 | 拿到绝世好剑以后，无名仍要风云学会合璧才能破雄霸护气。外哨还扣着当晚证人，剑庐的下一站是外哨。 | 剑池取剑 → `lesson` → `watch_signal` → `watch_list` → 岗门救人或绕旧路 → `watch_exit` → 飞云堂 |
| 肆 重返天下会 → 伍 魔池照心 | 无名辨出无凭牌的伪诏抄件。他和步惊云去找至尊，聂风走东山门向邪皇问破金身的方法。 | 初战雄霸 → `invaded` → `leave_hall` → 生死门药庐 → 魔池两战及 `pool_gate` |
| 伍 魔池照心 → 陆 无神绝宫 | 独孤梦死于魔池变故，第二梦与聂风同往断栈护人。聂风主动引开追骑，信使把破金身的消息带去绝宫。到绝宫时对白根据断栈护人或保药变更。 | `pool_escape` → `trestle_bell` → 浅滩护人或高栈取药 → `trestle_tracks` → `trestle_exit` → 进绝宫救至尊 |
| 陆 无神绝宫 → 柒 龙脉易手 | 至尊说明失窃印信及旧水道图。西闸东梯到茶房，听完密谈再回前庭。火后核对岗令与发令记录，见到至尊后循北引水渠追绝心。旧档保留至尊口述的去向。 | `palace_sluice_map` → `palace_sluice_exit` → 茶房/绝宫正战 → 火后安全撤退及两证 → `dragon_waterway` 的 `waterway_rubbing` → `waterway_blood` |
| 柒 龙脉易手 → 捌 雨夜换血 | 绝心逼聂风开北洞，秦霜留下血布。夺回龙脉后，雄霸毁去能压制魔刀的龙脉。第二梦提出换血，西坡避风处准备药炉。 | `waterway_exit` → `cavern_guard` → 东侧接秦霜追绝心 → `shatter_relic` → `ridge_lantern` → `ridge_stove` → 小筑 |
| 捌 雨夜换血 → 玖 风云合璧 | 第二梦承受倒流的魔血，聂风恢复后在小筑向她告别。雄霸扣押了撤离者，换血与任一撤离完成后才能上祭台。 | `prepare_guard` → `blood_rite` → 西坡、药炉或石阶任一路线 → 小筑告别 → `summit_roster` → 石阶或吊桥 → `summit_exit` |
| 玖 风云合璧 → 拾 凤溪灯明 | 龙脉戾影平息，击败雄霸后，风云把百姓送到下山接应处，沿水路回凤溪。聂风去桥栏履行第二梦的点灯约定。 | 祭台 → 两场终战 → 山路出口对话 → `dawn_lamp` → 西岸安置与东桥结局 |
| 拾 凤溪灯明 → 潮关 | 成局后从标题前往潮关。旧案开仓后仍能复核、安置并返回凤溪核对船工回执。 | 潮关渡口 → 引水渠 → 粮仓 → 本地回执 → 凤溪东埠 |

从新档运行[战役验收脚本](../../../game/tests/acceptance.gd)覆盖表中的标准路径。专项[入口读档日志](intro-resume.log)另覆盖山隘和引水渠。对话中途退出后从原入口坐标续读，读完后持久记录。经过首个目标后，去掉旧档可以缺失的 `intro_seen` 仍恢复到原来的交互坐标。第七章分别测试带两份绝宫证据和仅带旧案线索两种存档。

在仓库根目录复跑入口专项。脚本只接受指定测试档，若该测试档已存在则退出。

```powershell
$godot = 'D:/AI/dev_toolchain/godot_tool_list/app/Godot_v4.7.2-stable_win64_console.exe'
$script = (Resolve-Path 'verification/jianghu/full-campaign/intro-resume.gd').Path
& $godot --headless --path game --script $script -- --profile=qa_story_handoff
```
