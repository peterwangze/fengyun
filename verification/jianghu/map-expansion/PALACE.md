# 无神绝宫扩展验收

从绝宫外庭下到苇津渡埠，可进平秤公所，也可走芦岸巡径到西闸。三处都能沿原路返回。芦堤提供一条绕行选择，原有茶房撤离路线依然可用。三张场景使用独立的 ImageGen 像素背景，正门、岸梯、公秤案与步行区域按画面布置。 [美术来源](../../../art-source/palace-layers/README.md)

「苇津两份账」在伪诏阶段可查欠粮簿和封仓副联。押证阶段开放选择。火后，公开路线到渡埠复秤发粮，让两户在场签收，另开独立补给摊。封证路线到芦岸接送船户，回单留下后开放平秤公所侧扇。较老的通关档可用火后仍留存的抄本开始任务。芦岸押单队可选择交战，败退可从干燥堤岸重试，公所仍提供免费的副联。

分章存档测试中实际走过渡埠、公所、西闸和芦径，覆盖公开分粮与购买护脉散、封证回访与双向暗门、旧档火后取证、败退恢复药品与重试，以及空手走完原火场撤离。Windows 原生运行通过，画面可辨认渡埠入口和芦棚。 [功能日志](palace-headless.log) · [Windows 原生运行](palace-native.log) · [旧诏下的渡埠](palace-quay-edict.png) · [公所选择](palace-quay-choice.png) · [放粮后的补给摊](palace-quay-public-stock.png) · [芦岸接送](palace-reed-witness.png)

```powershell
& $godot --headless --path game --script res://tests/palace_layers.gd -- --profile=qa_palace_layers
```
