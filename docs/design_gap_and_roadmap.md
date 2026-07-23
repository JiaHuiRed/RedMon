# RedMon vs. Pokémon Essentials 设计差距调研与路线图

> 调研时间：2026-07-21 · 对照对象：`E:\AI\PokemonEssentials_Reference`（Pokémon Essentials v21.1 自定义 fangame 构建）
> 方法说明：该参考项目的战斗/进化等**逻辑代码**是编译态 `.rxdata`（不可读），本调研以其 **`PBS/*.txt` 纯文本设计数据**（species/moves/trainers/encounters 等的实际字段结构）+ Essentials 公开设计惯例为对照基准，逐项与 RedMon 现有 `data/*.json` 结构和 `scripts/` 实现代码比对。所有差距结论均已核对 RedMon 当前源码（非猜测）。

---

## 0. 已完成：素材迁移

| 内容 | 去向 | 说明 |
|---|---|---|
| 招式音效 71 个 + 招式动画音效 137 个 | `assets/audio/se/`、`assets/audio/se/anim/` | 直接可用（ogg），新增子目录 `se/anim/` 存放按招式播放的音效，**目前战斗代码尚未挂载调用**（见 P0-4） |
| 过场音乐 12 首 | `assets/audio/me/` | 直接可用（如 Forget move / Egg get / Machine get 等） |
| BGM | 未新增 | 已确认 RedMon 现有 10 首 ogg 与参考项目完全同名同源，**另有 33 首仅 MIDI 格式**（Godot 无法播放），已归档到 `assets/reference/pokemon_essentials/Audio_BGM_midi_unconverted/` 待后续转录（城镇/路线专属曲目，如 Cave/Route 1/Gym/Pokemon Center 等） |
| 精灵图鉴、NPC/训练家立绘、瓦片集、战斗背景、UI/窗口皮肤、招式动画序列帧等全部美术资源 | `assets/reference/pokemon_essentials/Graphics/`（原目录结构镜像） | **仅作参考/取材，未接入任何脚本**——像素风格与我们现有 AI 生成美术风格冲突，不直接用于战斗渲染；可作为补齐缺失精灵设计灵感来源 |
| PBS 设计数据全文本 | `assets/reference/pokemon_essentials/PBS/` | 本报告的数据来源，供后续设计新系统时查字段 |

授权说明见 `assets/reference/pokemon_essentials/README.md`：Essentials 官方仓库为 CC BY-NC-SA 4.0，本项目免费个人使用可接受，如未来商业化需重新评估。

---

## 1. 逐系统对比

### 1.1 战斗系统

| 维度 | RedMon 现状 | 参考设计 | 差距 |
|---|---|---|---|
| 技能 effect 覆盖率 | 260722-260723 分批补全（详见 design_guide.md 第9节效果表变更记录）：能力升降/7种异常状态/多段攻击/recoil/drain/替身/畏缩/寄生种子/再来一次/光墙/自爆/一击必杀/挺住/冤冤相报/三重状态/虚张声势/焕然一新/哈欠/硬撑/清醒/连续技(rampage/rollout/连斩)/无理取闹均已实装，`_apply_effect()`+`_execute_move()` 合计约45个effect key有真实逻辑 | 全部效果均有对应 FunctionCode 实现 | 仅剩天气(weather_sun/rain/sandstorm/hail)、束缚(bind)、蓄力(charge)、休息(recharge)、强制换场(force_switch)、守住(protect)、挑衅(taunt)、清除能力(clear_stats)、钉刺类场地(entry_hazard)、物理屏障(screen_physical)约10个仍是占位——覆盖率已从"26个纯展示"大幅收窄，这条差距基本快追平了，本节其余几行（特性/AI/招式flags/战斗音效）仍是当前真实差距，见下 |
| 特性(abilities) | ✅ **已完成（260723）**：约85个特性（immune_status/immune_type全量 + stat_boost_low_hp/on_switch_in/damage_reduce/damage_boost/contact_punish/stat_boost_passive/other 分类里不依赖天气/场地/持有道具/双打/招式flags的部分）已接入 `battle_scene.gd`，覆盖出场触发(威吓/下载)/换场触发(自然回复/再生力)/伤害修正(属性免疫吸收/HP过低加成/暴击相关)/接触反击/回合末(加速/蜕皮/恶梦/毒疗)/回合序(飞毛腿/恶作剧之心)等钩子。**遗留**：`weather`(21)+`field_terrain`(5) 两个分类整体阻塞于天气/场地系统不存在；"稀有专属"分类(~40个，多为常见机制组合)、`other`分类剩余部分、需要招式flags(拳系/咬类/切割类等)的特性未纳入本轮，是后续批次 | 特性是核心机制层（天气免疫、状态免疫、威力加成、进场效果等） | 核心接入已完成，剩余缺口收窄为"天气系统本身不存在"+"稀有专属特性的批量扩展"两块，不再是"完全脱节" |
| 招式 flags（接触/音系/拳系等） | 无此字段 | `moves.txt` 每个技能有 `Flags = Contact,Sound,Punch,...`，用于特性联动（静电/摩擦电碰接触反伤、悲鸣通过噪音免疫等） | 数据结构缺失，直接限制了特性系统能做到的深度 |
| AI | `_pick_enemy_move()` 纯随机（PP>0中随机选） | 基于效果期望值加权、优先超效、避免使用无效果技能 | 敌方/训练师对战几乎无策略性 |
| 战斗音效 | 15 条已挂载 SE，新增的 137 条招式音效未接入 | 每类招式动画有对应音效 | 音效素材已到位，缺代码挂载 |

### 1.2 进化系统（v0.27.6 刚整改完成，仅指出新增方向，非否定已有工作）

`data/species.json` 的 `evolutions` 字段只支持 `{into, level, item}`（等级/道具两种触发）。参考数据 `PBS/pokemon.txt` 实际使用的触发方式：

```
Evolutions = RAICHU,Item,THUNDERSTONE
Evolutions = CROBAT,Happiness,                          # 亲密度
Evolutions = ALAKAZAM,Trade,                             # 交换
Evolutions = STEELIX,TradeItem,METALCOAT                 # 携带特定道具交换
Evolutions = MAGNEZONE,Item,THUNDERSTONE,MAGNEZONE,LocationFlag,Magnetic   # 特定地点
Evolutions = LICKILICKY,HasMove,ROLLOUT                   # 学会特定技能
Evolutions = SYLVEON,HappinessMoveType,FAIRY,ESPEON,HappinessDay,,UMBREON,HappinessNight   # 亲密度+时间/技能类型分支
Evolutions = SIRFETCHD,None,                              # 战斗内特殊条件（无自动触发）
```

**差距**：RedMon 完全没有亲密度、交换、学会技能、地点、昼夜相关的进化触发。这不只是"少两种判断分支"——亲密度机制天然能反哺一个当前完全没有的玩法钩子（喂养/抚摸/长期携带出战的养成感），地点/昼夜触发能反哺地图内容设计的意义。

### 1.3 训练师战斗数据

`data/npcs.json` 里每只训练师精灵的 schema **已经包含** `moves: []` 和 `item: ""` 字段——但代码审计确认 `battle_scene.gd:188` 构建敌方队伍时只传 `species/level/ivs` 给 `MonDB.create_mon()`，`create_mon()`（`mon_db.gd:272`）内部永远自动按等级推导技能、从不读取 `moves`/`item` 覆盖值。**这两个字段目前是死数据**，任何策划配置的自定义招式/held item 都不会生效。参考数据里训练师精灵还支持 `Nickname`/`AbilityIndex`/`Gender`/`Shiny`/`Ball` 等个性化字段，用于制造"记忆点"（如个别 BOSS 用异色精灵、特定球种）。

### 1.4 遭遇（野外相遇）系统

`data/encounters.json` 目前每张地图只有一张统一权重表（29 张地图里仅 2 张有数据）。参考数据 `PBS/encounters.txt` 的结构：按 **方法分组**（`Land` / `LandNight` / `Water` / `OldRod` / `GoodRod` / `SuperRod` / `PokeRadar`），同一张地图昼夜/钓鱼道具等级不同则物种池和权重完全不同。

**差距**：(a) 内容覆盖率是最大瓶颈（27/29 地图无遇敌数据，见 1.7）；(b) 结构上没有昼夜分层、没有钓鱼玩法的分级设计空间。

### 1.5 NPC AI / 视野

`MonDB.is_in_sight()` 是单方向直线判定（从 NPC 沿一个方向走 N 格，目标恰好落在这条线上才算被发现），无锥形视野、无遮挡判断、不支持斜向。参考游戏引擎标准做法是锥形/矩形视野 + 障碍物遮挡射线检测。当前实现在直线开阔地图能用，但一旦地图出现墙体/障碍物分割视线，会出现"隔墙看见玩家"的问题。

### 1.6 日常/剧情/事件系统

- **无昼夜循环**：全代码库搜索不到任何时间相关变量。
- **无 NPC 日程**：NPC 可见性只是绑定剧情 flag 的二元开关，不随时间变化。
- **通用事件脚本层已写好但完全未使用**：`scripts/autoload/script_engine.gd` 定义了 `dialog/battle/wild_battle/warp/set_flag/give_item/heal/shop` 的通用解释器，但全仓库零处调用；其 `set_flag` 命令写入 `GameState.flags[key]`，而 `GameState` 根本没有声明 `flags` 字典——**这段代码如果被调用会直接报错**，说明是从未跑通过的半成品。
- **剧情实际上全部硬编码**在各 `xxx_scene.gd` 里（对话字符串、flag 判断、场景跳转全部内联），`dialogs.json` 只覆盖开场流程，不是真正的剧情数据层。
- 参考项目的剧情/事件虽然也是二进制地图内嵌事件（不可读取细节），但引擎本身提供了成熟的"地图事件+公共事件+条件分支"标准范式，这正是 RedMon 缺失的"生产力工具"，直接影响后续章节的开发效率。

### 1.7 内容广度（地图/道馆/剧情进度）

- `data/maps.json` 定义 29 个概念地图，仅 3 个（青木村/华灵草原/碧溪镇）+ 对应室内场景真正建成。
- 8 个道馆里只有 1 个（翠竹馆）有完整场景+首领队伍；四天王+冠军均只有立绘/头衔，无 `team` 数据。
- `docs/story_design.md`（剧情总源文档）标注章节 1-3 已实装，章节 4+ 均为"设计阶段"。

这是纯内容产能问题，不是系统设计问题——参考项目作为一款完整发布的 fangame，地图/剧情内容量级是 RedMon 的数量级差距，符合"参考项目开发时间更长"的预期，不代表系统设计缺陷。

### 1.8 捕捉、精灵数据规模——已具竞争力的部分（无需现在动）

- 精灵种族数 444（参考项目约 700 含形态/性别变体，但 RedMon 是原创内容，规模已经充分）；技能 872 条；战斗立绘覆盖 97%（432/444）；鸣叫音效 1313 个（比参考项目 655 个还多）。
- 捕捉机制（BST 推导捕获率 + 状态加成 + 球种倍率 + 野生精灵隐藏 tier 分层）设计完整度不输参考项目的经典捕获率公式，且额外做了 boss/彩蛋奖励联动，是 RedMon 相对更有特色的系统。
- **结论：素材/数值规模不是短板，战斗深度和系统联动是短板。**

---

## 2. 优先级目标清单

### P0 —— 低成本、高体验回报，建议优先落地

1. ✅ **已完成（260723）**：特性接入战斗——约85个特性（immune_status/immune_type全量 + 其余分类里不依赖天气/场地/持有道具/双打/招式flags的部分）接进了 `battle_scene.gd` 的出场/伤害计算/回合结算流程，详见 1.1 节。天气/场地依赖的 46 个特性、"稀有专属"分类的批量扩展留作后续批次。
2. **训练师技能覆盖生效**：`create_mon()` 增加可选的 `forced_moves`/`forced_item` 参数，`battle_scene.gd:188` 传入 `slot["moves"]`/`slot["item"]`（数据字段已存在，只是没接线）。
3. ✅ **已完成（260722）**：`lower_def/lower_sp_atk/lower_sp_def/raise_atk` 补齐；`inflict_confusion` 新增独立 `confused_turns` 字段（可与烧伤/中毒等主状态共存，33%概率打自己，2~5回合），`MonDB.calc_confusion_damage()` 复用伤害内核公式。顺带把「摇尾巴→lower_def」「摇晃舞→inflict_confusion」两个描述与effect字段长期不一致的技能修正为可用状态，验证了新效果链路。~~**遗留**：全库还有十几个技能描述写着"有时会使对手混乱/降低XX"但 `effect` 字段是空字符串~~——**260723已closed**：另一轮专项审计把这批"描述承诺效果但effect字段是空字符串"的技能全部扫描并修复了（~144个moves.json数据bug + 20个battle_scene.gd新effect key），不再是遗留项。
7. ✅ **已完成（260723）**：技能effect系统收尾——新增10个战斗机制（`ohko`一击必杀/`endure`挺住/`revenge`冤冤相报/`self_destruct`自爆/`tri_status`三重状态/`swagger`虚张声势/`cure_self_status`焕然一新/`yawn`哈欠/`facade`硬撑/`wake_up_slap`清醒），`secondary_status`字段从只支持多段攻击扩展到单段技能也能用，烧伤描述用词统一（灼伤→烧伤，16处不一致+11个漏挂效果的技能）。至此 P0-3/P0-6 遗留的效果覆盖缺口基本清零，仅剩天气/束缚/蓄力/场地控制类约10个effect仍是占位（不在本轮P0范围内，见1.1节表格）。
4. **招式音效挂载**：新入库的 137 条招式动画音效接到 `_execute_move()`，按 `effect`/`type` 做一个简单映射表。
5. **AI 从纯随机升级为基础加权**：优先选克制招式、其次避免抵抗招式，最后再随机——不需要复杂算法，几十行代码即可显著提升对战体验。
6. ✅ **已完成（260722，用户实测发现）**：多段攻击机制补齐。原本11个技能（种子机关枪/乱击/乱抓/冰锥/尖刺加农炮/岩石爆击/猛推/连环巴掌/连续拳/飞弹针/双重攻击）描述都写着连续攻击2~5次（双重攻击固定2次），但 `moves.json` 的 `effect` 字段是空的，`_execute_move()` 也完全没有多段判定——是数据+代码两头都缺的真bug，只按单段威力结算，威力因此被腰斩。新增 `multi_hit`（2~5次，35/35/15/15%分布）与 `multi_hit_2`（固定2次）两个effect key，每次独立算伤害/暴击，中途目标倒下提前结束；11个技能已补上effect字段。

### P1 —— 中等工作量，系统性补强

6. **进化触发方式扩展**：亲密度(Happiness)、学会特定技能(HasMove)、地点(LocationFlag) 三种优先，交换(Trade)涉及联机暂不适用单机项目。亲密度需要先给 `GameState`/mon 实例加一个亲密度数值养成维度。
7. **招式 flags 字段**：`moves.json` 加 `flags: [接触,音系,拳系,...]`，为后续特性联动打基础。
8. **遭遇表结构升级**：至少拆出"白天/夜晚"两层（为将来的昼夜循环预留数据结构），暂不急着做钓鱼分级（钓鱼玩法本身还不存在）。
9. **屏障/场地类效果**：`screen_physical/screen_special`、`protect` 基础版——双打没有，但单挑对战里这两个效果的策略价值最高。

### P2 —— 长线系统工程

10. **昼夜循环 + NPC 日程**：时间驱动的 NPC 出没/遇敌表切换，是"世界有在呼吸"的体验分水岭，但涉及全局时间系统 + 存档兼容 + 美术光照变化，工作量较大。
11. **剧情/事件数据层**：不建议直接复活现在半成品的 `script_engine.gd`（连 `GameState.flags` 都没声明，等于要重写），而是评估要不要设计一套更贴合当前 `GameState` 具名 flag 风格的轻量事件配置层，把散落在各 scene 里的硬编码对话/分支收敛，为章节4+ 的开发提速。
12. **地图/道馆内容管线**：29 个地图目前 3 个建成、8 道馆 1 个完工，这是最大的"完成度"缺口，但属于内容产出而非系统设计问题，需要单独按章节排期，不适合和上面的系统性修复混在一起估工。
13. **BGM 分区扩展**：33 首待转录 MIDI（已归档），覆盖城镇/路线专属主题，可作为内容管线的配套项一起排期。

---

## 3. 明确不建议做的事

- **不要**把 `assets/reference/pokemon_essentials/Graphics/` 里的像素风精灵/瓦片直接接入游戏渲染——美术风格会与现有 AI 生成美术风格冲突造成不一致观感，仅作缺口设计灵感/取材参考。
- **不要**直接复活 `script_engine.gd` 现状代码（引用了不存在的 `GameState.flags`，跑起来必报错），如果要做通用事件层需要重新设计而非"打开开关"。
- 内容广度差距（地图/道馆数量）**不是系统设计缺陷**，不应该和上面的系统性问题用同一优先级排期——两者性质不同，一个是"地基强度"问题，一个是"施工进度"问题。

---

## 4. 下一步

以上 P0/P1/P2 分类是按"成本/体验回报比"排的，但具体先做哪几项、要不要跳过某些，需要你确认后我再动手实现。P0 五项加起来预计是可以在一次会话内验证完成的规模；P1/P2 建议拆成独立的后续任务分别推进。
