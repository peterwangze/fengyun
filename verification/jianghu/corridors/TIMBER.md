# 木铁过青石

在拜剑山庄打炭匠里接常六的运料单。外哨开放后，可沿炭车道抵达青石转运集，白石沟也有双向车道。货棚、过磅秤和转向岔道各有实际交互。拿运料单过秤，在过磅案决定只装一批料。

| 走法 | 行程 | 终战前交付的影响 | 战后现场回访 |
| --- | --- | --- | --- |
| 楔木送竹井 | 从转运集南弯到竹井坳，在木料棚给喻木匠点四枚楔木。 | 竹井担架更早安稳，风云从一格合璧起手。 | 试挑担台，带竹井签过的料单回青石过磅案。 |
| 铁箍送东哨 | 从北坡到撤离石阶。先处理扣车的人，或凭已经实际交接的匿名换岗时刻从护车棚绕岗。到东哨点两对铁箍。 | 东哨用铁箍固定拒马，雄霸少一格初始势。 | 看搬运栏，取旧铁和卸料单亲自回青石销记。 |

北坡战败可返回安全车候位再试。两条货路都可折返，不改变换血、撤离和上祭台的原有要求。战后补完仍能收回单，终战援助按实际交手之前的交付记录结算。

[青石过磅案](qingshi-street.png) · [发车分支](qingshi-choice.png) · [战后返场](qingshi-final-ledger.png) · [美术原图和生成指令](../../../art-source/qingshi-relay/README.md)

专项验收用阶段测试档进入真实地图、选择分支并交付。两条抢在终战前交付的路线打过雄霸并核对实际开场数值。也跑过北坡实战战败再试、匿名换岗免战及旧结局档补交付。 [无界面 98 项](timber-headless.log) · [Windows 原生 101 项](timber-native.log)

```powershell
$godot = 'D:/AI/dev_toolchain/godot_tool_list/app/Godot_v4.7.2-stable_win64_console.exe'
& $godot --headless --path game --script res://tests/corridor_timber.gd -- --profile=qa_corridor_timber
```
