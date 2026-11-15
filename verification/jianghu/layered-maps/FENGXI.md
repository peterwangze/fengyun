# 凤溪街市与粮行

西岸石阶通集市，沿石街可见西棚、丰义粮行和东门。粮行从正门进出，屋里能沿空地到秤台和补给柜。东门在戒严取证时有人值守，封渡换岗后石塘驿道通车。原西岸客栈、雨巷与渡口主线入口仍使用原地点。

「一杆秤，两本账」在戒严时即可调查粮行秤砣和东棚曹嫂的红线。封渡后交给吴师傅复秤，领取三两银和一份韧丝，补给柜开售金创药、护脉散和韧丝。完成后，封渡中的西棚重新煮粥。复航后到西棚确认四户退粮并写下回单。

[街市到粮行的门槛](fengxi-market-grainhall-door.png) · [粮行室内](fengxi-grainhall-evidence.png) · [补给柜](fengxi-grainhall-supplies.png) · [复航后西棚](fengxi-market-reopened.png)

Godot 验收使用三个阶段的测试档走过地图和门槛，检查对话、付款、库存、读档、旧主线返回及一次性回单。这里使用阶段夹具验证单区，开局到通关的记录见战役回归日志。 [无界面 40 项](fengxi-market-headless.log) · [Windows 原生画面 45 项](fengxi-market-native.log) · [图像生成指令与原图](../../../art-source/fengxi-market/README.md)

```powershell
$godot = 'D:/AI/dev_toolchain/godot_tool_list/app/Godot_v4.7.2-stable_win64_console.exe'
& $godot --headless --path game --script res://tests/fengxi_market.gd -- --profile=qa_fengxi_market
```
