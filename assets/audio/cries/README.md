# 精灵叫声素材库（待手动分配）

来源：`E:\AI\PokemonEssentials_Reference`（Pokemon Essentials 参考项目），共 655 个原始叫声，
按 `PBS/pokemon.txt` 的 `Shape`（体形）+ `Height`（身高）+ `Flags`（传说/幻兽/究极异兽）分类存放，
文件名保留原宝可梦内部名（如 `CRYOGONAL.ogg`），方便对照原设定挑选。

## 目录结构

先按"身形气质"分大类，再按身高分体型档：迷你(<0.4m) / 小型(0.4-1.0m) / 中型(1.0-2.0m) / 大型(2.0-4.0m) / 巨型(>=4.0m)

- `传说幻兽/` — Flags 含 Legendary/Mythical/UltraBeast 的，不管体形先归到这里
- `兽类_四足/` — Quadruped
- `类人_双足/` — Bipedal / BipedalTail
- `飞禽/` — Winged / MultiWinged
- `虫类/` — Insectoid
- `水生鱼类/` — Finned
- `蛇龙_长条/` — Serpentine
- `简体_头身/` — Head / HeadArms / HeadLegs / HeadBase（body 简单、以头为主）
- `多肢_异形/` — Multiped / MultiBody

## 使用方式

**不要按图鉴编号 1:1 硬套**——这些叫声对应的是宝可梦原设计，我们的精灵是重新设计的原创造型，
编号不代表气质匹配。挑选时按"体型+气质"从对应文件夹里试听，选感觉贴近的那个，
再复制/改名放进 `assets/audio/se/` 或按 `audio_manager.gd` 的 SE 加载规则接入代码
（建议按精灵中文名或 species id 命名，避免直接用这里的英文原名，防止和原版強关联）。

分配完的精灵可以从这里删掉对应文件，方便追踪剩余进度。
