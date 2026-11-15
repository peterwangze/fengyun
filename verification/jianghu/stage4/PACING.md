# 第四阶段主线与潮关验收

在 Windows 上用 Godot 4.7.2 跑四条新档路线，从第一章通过凤溪尾声、潮关原案及两条新增任务。用实际地图移动和游戏内输入完成各环节。下表的移动秒数按脚本走过的距离折算，含回访与往返验证，不含玩家阅读、判断、战斗及重试时间。

| 路线 | 主线 / 潮关原案战斗 | 覆核独立证据 | 后续处理 | 覆核 / 后续移动秒数 |
| --- | --- | --- | --- | ---: |
| [标准无消费](campaign-standard.log) | 19 / 2 | 装卸渠免费复写凭单 | 公开分粮 | 39.3 / 90.6 |
| [截势](campaign-interrupt.log) | 24 / 3 | 江杏的绝宫署名记录 | 州府会验 | 46.2 / 51.4 |
| [守反](campaign-retaliate.log) | 22 / 3 | 阿芦核验的粮票 | 公开分粮 | 47.6 / 87.6 |
| [乘隙](campaign-exploit.log) | 23 / 1 | 水栅船单和舟工指印 | 州府会验 | 41.5 / 51.4 |

标准路线可跳过阿芦的原案救援和之前的选做区域任务。从新档到潮关无消费。其十章移动 282.3 秒，与 [3.2 原案基线](baseline-v320-public.log)相同，雄霸仍为五回合，最低队员生命 38%。表中标准路线少一场可选救援战；新增区域和任务均由潮关旧案进度另行开放。

- 韩朔仍在时不能走渠东阶进粮仓。拿回粮账后，必须查验粮桩、独立凭证、公秤和封绳，才能回渡口覆核。覆核完成开新船路，往返均校验落点。凤溪和潮关的跨区船也验过双向、存档续行及回程位置。
- 公开路线跑到两户分粮、仓案实发簿、粮棚摊；州府路线跑到封卷、护卷过渠、收两张回执及随卷商柜。早期修船和药单影响实际航线或商铺。中途读档可按原渠岸继续，终局选择与已发回执均保留。
- [3.2 公开结案和州府结案旧存档](campaign-standard.log)从稳定版实跑保存点生成，原结案仍在，新增工作需要实际完成。州府旧档没有前期护卷支援，验证遭遇残党、败退到安全岸、重新交战和结案后救阿芦。银两与盐淬铁两项达到容量后仍能定案，无重复领取，也未动用主线经济。
- [七种证据来源](tide-provenance.log)逐一验证入档、重读、报酬、前置条件和伪造来源被拒绝。此前保住冬粮会改变备粮位置；修船改变实际渡行落点。
- [历史回归](legacy-regression.log)覆盖早期路线、任务回报、旧区域、手记和触屏操作。
- Windows 原生截势路线完成州府会验。最终候选修复潮关回访切图时的地图副标题异常。复测逐行检查 Godot 原生日志，并留有潮关手记、交接和州府货台的截图。首次真人阅读时长、首次迷路频率和实体手柄体验仍待实测。 [原生运行日志](campaign-native-interrupt.log) · [潮关手记](stage4-tide-journal.png) · [交接](stage4-relief-witness.png) · [州府货台](stage4-shop-witness.png)

## 复跑

在仓库根目录用 Godot Windows 控制台运行。每次执行使用单独的 `qa_` 存档名。

```powershell
& $godot --headless --path game --script res://tests/acceptance.gd -- --profile=qa_stage4_standard --pacing --tidal --endgame --forging --cultivation --stage2b --stage3 --stage4 --stage2b-skip
```

配装路线以 `--quests --counterplay --quest-carryover --build-route=interrupt` 代替 `--stage2b-skip`，截势再加 `--stage4-settlement=witness`。守反改用 `--build-route=retaliate`，乘隙改用 `--build-route=exploit --tidal-sluice`。`STAGE4` 含实际路径和任务摘录，`STAGE4_MIGRATION` 含旧档完成记录。

原生运行去掉 `--headless`，以 `--reports=` 指向已存在的截图目录。检查控制台中的 `SCRIPT ERROR`、`ERROR:` 及 `RESULT` 的失败数，覆盖仅在绘制地图时发生的问题。
