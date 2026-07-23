# RedMon vs. hg-engine 设计对比与优先级

> 调研时间：2026-07-23 · 对照对象：`E:\AI\hg-engine-main`（BluRosie/hg-engine，英文版 HeartGold 的引擎级重制，C + ARM 汇编实现的**真实战斗机制代码**，不是文本设计数据）
> 与 [design_gap_and_roadmap.md](design_gap_and_roadmap.md)（对照 PokemonEssentials_Reference）互补：那份看的是"设计数据字段"，这份看的是"战斗机制怎么真正跑起来"，能验证哪些差距被低估、也能发现新的机制类别。
> 方法：直接阅读 hg-engine 的 `src/battle/`、`src/individual/`、`include/*.h` 源码（非猜测），逐项与 RedMon 现有 `data/*.json` + `scripts/` 实现比对。

---

## 0. 结论先行

- **特性 / 招式 flag / AI 三项被两份报告同时列为差距**，但 hg-engine 的代码证实这三者的耦合深度比预想的更高——特性系统贯穿换场/命中前/命中后/场地判定四个阶段的钩子，不是一张"参数表"。
- hg-engine 有几类 RedMon 完全没设想过的系统：**场地(Terrain)、战斗内动态形态转换、更细的训练师数据结构、暗雷捕获**。
- 也有一类"体积大但对原创 IP 没什么实质收益"的机制：**进化触发全量扩展、逐物种硬编码的形态转换**——这些是 hg-engine 为了兼容任天堂官方 700+ 历史物种的怪异遗留规则堆出来的边角复杂度。RedMon 是原创 444 物种，没有历史包袱，可以选择性抄，不必照单全收（这条也是本次调研的用户判断，已采纳）。

---

## 1. 核心价值项（宝可梦味 + 提升可玩深度，建议按此优先级推进）

### P0

**1. ✅ 特性接入战斗（已完成，260723）**
证据：`ability.c`(1292行) 之外，`SwitchInAbilityCheck.c`(1145行)/`MoveHitDefenderAbilityCheck.c`(392行)/`CheckDefenderItemEffectOnHit.c`(215行) 分别是换场/命中前/命中后三个独立阶段的特性钩子，这份调研当时用来论证"特性系统需要按阶段钩子设计，不能靠 effect 粗分类驱动逻辑"。
落地结果：`battle_scene.gd` 新增 `_trigger_switch_in_ability`/`_trigger_switch_out_ability`/`_apply_ability_damage_mod`/`_apply_ability_contact_punish`/`_apply_ability_end_of_turn` 五个按特性名字精确匹配的钩子函数，接进出场/换场/伤害计算/回合末四个阶段，覆盖约85个特性（immune_status/immune_type全量 + 其余分类中不依赖天气/场地/持有道具/双打/招式flags的部分）。`weather`(21)+`field_terrain`(5) 两个分类整体跳过（天气/场地系统本身不存在），"稀有专属"分类(~40个，多为已实现机制的组合)留作后续批次，复用同一套表成本很低。

**2. 招式 flags 体系**（原 P1，建议提到 P0，因为它是特性的地基）
证据：`move_data.h` 的 `FLAG_CONTACT`/`FLAG_PROTECT`/`FLAG_MAGIC_COAT`/`FLAG_SNATCH`/`FLAG_MIRROR_MOVE`，加上 `other_battle_calculators.c` 里 `IsContactBeingMade`/`IsPowderMove`/`IsMoveWindMove` 等消费函数。
为什么提优先级：特性里"接触反伤"类效果的判定入口就是"这次攻击算不算接触"——没有 flag 体系，每个特性都要单独抄一遍招式列表，flags 是复用地基，晚做等于让后面每个特性多返工一次。

**3. 训练师精灵数据结构补完**（原 P0，建议扩大范围）
证据：`TrainerPokemonData` 支持独立 EV/IV、性格、异色锁定、开局状态（初始 HP 损耗/异常状态）、球皮肤、昵称。RedMon `npcs.json` 的 `moves`/`item` 字段目前都是死数据（见 design_gap_and_roadmap.md 1.3 节）。
建议：落地时不只是让 `moves`/`item` 生效，一并把"性格"和"开局特化状态"设计进结构——这两个是 [[project_boss_fight_taxonomy]] 里最省成本的杠杆，一只特殊性格/开局残血的 boss 比单纯堆等级更有记忆点。

### P1

**4. AI 人格 flags**（挑 3-4 个关键 flag，不必照抄全部）
证据：`trainer_data.h` 定义了 `F_PRIORITIZE_SUPER_EFFECTIVE`/`F_EXPERT_ATTACKS`/`F_RISKY_ATTACKS`/`F_USE_WEATHER`/`F_PRIORITIZE_HEALING` 等 14 种可组合 flag。
建议：不需要全量实现。"优先超效" + "避免使用无效果技能" + "残血优先回复" 三个就足够覆盖"没有策略性→有基础策略性"的体验跃升，这正是 design_gap_and_roadmap.md 里 AI 那条 P0 本来的意图，hg-engine 只是提供了"以后想细化，往哪个方向细化"的参照，不必现在一次做全。

**5. 天气占位效果补完 → 场地(Terrain)系统**
证据：`TERRAIN_ELECTRIC_TERRAIN`/`GRASSY`/`MISTY`/`PSYCHIC_TERRAIN`，是与天气平行的独立联动层，不是天气的子集。
建议：天气本身（design_gap doc 里还有约10个占位效果之一）要先做实，场地排在天气之后——属于"做完会加分但不做也不影响完整体验"的 P1/P2 边界项。

### P2（长线，值得做但不急）

**6. 地图事件脚本层重新设计**
证据：`script_commands.c`(317行) 是成熟的"指令+参数"范式，覆盖对话/warp/give item 等常见地图事件类型。
建议：不是抄代码（ARM 汇编绑定，语言都不通），是抄"设计范式"——为 `script_engine.gd`（已知半成品死代码，design_gap doc 1.6 节）重新设计事件层时，可以参考它的指令粒度划分。

---

## 2. 锦上添花项（低成本可选，性价比不错但非核心）

**7. 暗雷捕获（critical capture）**：抓得越多幸运加成越高，正反馈彩蛋，几十行代码。

**8. Quick Claw 类道具优先级插队**：前提是 RedMon 目前**没有"持有道具在战斗中生效"这个概念**——`items.json` 现有分类只有 回复/技能机/捕捉/滋补/进化 五类，没有"战斗held item"分类；`npcs.json` 虽有 `item` 字段但当前是死数据。做这个之前得先决定要不要开"持有道具"这个口子，建议和第 3 项（训练师道具生效）一起讨论范围，不要当成孤立小功能顺手做。

**9. EV/IV 查看器 UI**：核实后发现 RedMon **其实已经有完整的努力值系统**（`items.json` 里"滋补"类道具 `train_stat`/`train_amount` 字段 + `main.gd:599-609` 的 `training` 字典，126/项 256/总 的养成上限逻辑都已实现），但目前**没有任何界面能让玩家看到自己精灵的个体值/努力值数字**——玩家能喂道具训练，却看不到练成了多少。这是一个真实存在、范围很小的 UI 空白，比想象中更值得做。

**10. 等级上限系统**：对故事节奏控制有用（章节 4+ 设计中可以用来防止练度超前打崩剧情节奏），是否需要取决于要不要做这件事，非必需。

---

## 3. 建议跳过/不值得做的（落后或繁琐，收益与工作量不成正比）

**11. 进化触发方式全量扩展**（地点触发/性格分支/队伍协同/暴击计数/受伤总量/攻防对比等十几种）
*用户已定性"挺麻烦的"，认同这个判断。* 这些触发方式的复杂度根源是"兼容 700+ 官方物种的历史遗留怪规则"（某洛托姆需要特定地点、某谜拟丘需要队伍里有恶属性）。RedMon 是原创 444 物种，设计新精灵的进化条件完全可以自己定规则，不需要被这些历史包袱式的分类束缚。现有等级/道具 + 已规划的亲密度三种够用，最多加"学会特定技能"作为第四种——这个反而是原创设计里最好用的一条（"练到会某招才进化"是很直觉的钩子）。地点/性格分支/队伍协同/暴击计数这几种建议直接放弃。

**12. 逐物种硬编码的战斗内动态形态转换**（Castform/Darmanitan/Zygarde/Giratina 等）
这类机制的本质是"每个特例精灵单独写一段 if-else"——`BattleFormChangeCheck.c`(357行) 里塞了 10 个物种的专属判断，不是可复用系统。除非 RedMon 想设计 1-2 只"天气变身"或"愤怒模式"的原创精灵（这本身是值得做的话题，但应该单独立项讨论，不要顺着"抄 hg-engine" 的框架去做），否则不建议投入。

**13. 战斗结束消耗品自动恢复 / 驱虫喷雾自动续订**
纯 QoL 选择题，不代表"设计成熟度"差距，见仁见智，随时可以加，不需要现在决策。

---

## 4. 汇总优先级表（合并两份调研文档）

| 优先级 | 事项 | 来源 |
|---|---|---|
| ✅已完成 | 特性接入战斗（按阶段钩子设计，约85个特性，见1.1节） | Essentials + hg-engine 加深 |
| P0 | 招式 flags 体系（为特性铺路，提前做） | hg-engine 提升优先级 |
| P0 | 训练师技能/道具/性格/开局状态生效 | Essentials + hg-engine 扩大范围 |
| P1 | AI 人格 flags（3-4 个关键 flag，不求全） | Essentials + hg-engine 参照 |
| P1 | 进化触发只加"学会特定技能"一种（亲密度已规划） | Essentials，hg-engine 佐证"够用即可" |
| P1 | 屏障/protect/taunt 基础版 | Essentials |
| P1 | 天气占位效果补完 | Essentials |
| P2 | 场地(Terrain)系统 | hg-engine 新增 |
| P2 | 昼夜循环 + NPC 日程 | Essentials |
| P2 | 地图事件脚本层重新设计 | Essentials + hg-engine 范式参照 |
| 锦上添花 | EV/IV 查看器 UI | hg-engine 新增，范围很小 |
| 锦上添花 | 暗雷捕获 / 等级上限 | hg-engine 新增，可选 |
| 锦上添花 | 持有道具系统（含 Quick Claw） | hg-engine 新增，需先决定是否开这个口子 |
| 不建议 | 进化触发全量扩展（地点/性格分支/队伍协同/暴击计数等） | hg-engine，用户已定性繁琐，不采纳 |
| 不建议 | 逐物种硬编码形态转换 | hg-engine，除非单独立项做原创变身精灵 |

---

## 5. 下一步

分类判断已经做完，剩下是"先做哪个"的问题。P0 三项建议合并成一次实现（特性/flags/训练师数据三者本来就要互相配合，单独拆开做会互相返工）；P1/P2/锦上添花按时间预算挑着推进即可，不建议跳过的几项就不用再纳入排期讨论了。
