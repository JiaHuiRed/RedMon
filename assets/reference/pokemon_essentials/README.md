# Pokémon Essentials 参考素材

来源：`E:\AI\PokemonEssentials_Reference`（Pokémon Essentials v21.1 引擎的一个自定义 fangame 构建）。

## 内容

- `Graphics/` — 原始美术资源镜像（精灵图鉴前/背/图标/脚印、NPC与训练家立绘、地图瓦片集、战斗背景、UI/窗口皮肤、招式动画序列帧等），保留原始目录结构与文件名，便于对照 `PBS/` 数据交叉查找。
- `PBS/` — 纯文本设计数据（species/moves/items/trainers/encounters/abilities 等），用于比对我们 `data/*.json` 的字段设计是否有缺失，不用于直接抄内容（我们是原创精灵/技能/世界观）。
- `Audio_BGM_midi_unconverted/` — 33 首仅有 MIDI 格式的 BGM（Godot 不能直接播放 MIDI），需要重新编曲/渲染为 ogg 才能使用，暂存于此等待后续处理。

## 用途与限制

**这批素材仅作参考/取材用途，不会被任何脚本直接引用。** 已经确认可直接播放的 BGM/SE/ME（ogg 格式）已经分别合并进 `assets/audio/bgm|se|me/`（含新增的 `se/anim/` 招式音效子目录）。

**`assets/npc_homage_reference/` 不在这里**：那批关都一代具名角色彩蛋素材曾一度被合并进本目录（`homage_shortlist/`），但发现 `scenes/青木村.tscn` 已经直接引用了其中 `battle_portraits/LEADER_Misty.png`（青木村头目战"小霞"用的就是这张），说明那不是纯参考素材，而是已经在用的候选池，所以移回了独立的 `assets/npc_homage_reference/`，不跟这批"确认不会被引用"的素材混在一起。

**授权提示**：Pokémon Essentials 官方仓库使用 CC BY-NC-SA 4.0（署名-非商业性使用-相同方式共享）协议，本参考素材未附带独立 LICENSE 文件，按同源处理。RedMon 是免费个人项目，仅限非商业参考/取材，不做二次分发。
