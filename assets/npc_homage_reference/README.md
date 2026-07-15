# 关都具名角色素材（致敬彩蛋参考库）

来源：`E:\AI\PokemonEssentials_Reference`（Pokemon Essentials v21.1 官方起始模板自带素材）。
这是模板里唯一带专属立绘的一整套角色——关都一代 8 道馆主 + 4 天王 + 冠军 + 坂木(火箭队老大身份)
+ 劲敌两阶段 + 初代主角红 + 通用教授，共 58 个文件。核实过整个项目（图+文本，含 Gen5~8 备份），
没有城都/丰缘/神奥等后续世代的具名角色素材——这个模板本身就只做了关都这一套演示内容。

## 目录结构

- `battle_portraits/` — 对战立绘（`LEADER_*`/`ELITEFOUR_*`/`CHAMPION`/`ROCKETBOSS`/`RIVAL1`/`RIVAL2`/`POKEMONTRAINER_Red[_back]`/`PROFESSOR`）
- `overworld_sprites/` — 地图行走图（`trainer_LEADER_*`/`trainer_ELITEFOUR_*`/`trainer_CHAMPION`），对应角色出现在地图上待你搭话/挑战时用
- `battle_backgrounds/` — 冠军战专属战斗背景（`champion1`/`champion2`，含 base/bg/message 分层）
- `vs_transitions/` — 对战开场 "VS xxx" 横幅特效（`hgss_vs_*`/`hgss_vsBar_*`/`vsE4_*`/`vsE4Bar_*`）

## 定位：参考/占位素材，不是最终成品

这批是**别人游戏里实际角色的脸**，跟叫声、天气特效那种"通用素材"不一样——直接原样放进正式版本，
玩家一眼就能认出这是小刚/小霞本人，跟"用我们新精灵重塑童年回忆"的彩蛋思路是两码事。
现阶段（项目早期，这批角色也不会一次性全部登场）先当**占位图 + 设计参考**用没问题：
先用这批图把彩蛋NPC的触发位置、VS横幅流程、冠军战背景这些系统跑通，
等具体到哪个角色要真正做成彩蛋时，再换成我们自己重新设计的立绘（性格、队伍已经用原创精灵做了归属，
参考 `docs/npc_roster.md` 末尾的头目战筛选建议）。

## 待补：后续世代

这个模板本身没有城都/丰缘/神奥/统一/卡洛斯/阿罗拉/伽勒尔的具名角色素材，网上搜索结果见对话记录，
如果要扩展到关都以外，需要额外下载对应的社区素材包。
