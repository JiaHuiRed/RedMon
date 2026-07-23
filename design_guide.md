# RedMon 设计指南

> 精简版设计圣经，适用于精灵设计、生图、数据填写全流程。

---

## 1. 统一生图 Prompt 后缀

**所有精灵图生成时，在具体描述之后追加以下内容：**

**正面图后缀：**
```
Chinese mythology inspired original monster.
Pokemon GBA pixel art style, clean readable design.
Warm saturated color palette. No grey tones.
Dark brown outlines (not pure black).
Light source from upper-left, consistent three-layer shading.
Clear silhouette recognizable at small size.
Natural creature anatomy. No robotic or mechanical parts (unless Steel type).
Transparent background.
Front view facing forward. Centered full body.
512x512.
```

**背面图后缀：**
```
Chinese mythology inspired original monster.
Pokemon GBA pixel art style, clean readable design.
Warm saturated color palette. No grey tones.
Dark brown outlines (not pure black).
Light source from upper-left, consistent three-layer shading.
Clear silhouette recognizable at small size.
Natural creature anatomy. No robotic or mechanical parts (unless Steel type).
Transparent background.
Back view, body slightly turned to the right (3/4 back view). Centered full body.
512x512.
```

**规则：**
- 每次生图只生成一个视角，不再拼图
- 正面图：精灵面朝观众，全幅居中，用于敌方战斗显示
- 背面图：精灵背对观众、微向右转（3/4 背面），全幅居中，用于我方战斗显示
- 两个视角分两次生成，各 512×512（单图模型）；**豆包等一次出4图的模型例外**——把正背面写进同一条 prompt，末尾加"分别生成正视图和朝右侧方向的背面图（3/4背面）"，一次请求把两个视角都出全，避免另外两张配额被同款正面图占用
- **后缀逐字复制，不要意译/精简**——哪怕觉得啰嗦重复，也要把第1节的整段后缀原样贴上。漂移大多数时候是因为凭记忆改写后缀漏掉了某句约束（尤其是光源方向、描边颜色、构图居中这几句最容易被省略）
- **能垫图就垫图**：如果所用模型支持参考图（图生图/以图施法），优先上传已生成的同属性精灵图作为参考，文字prompt再准也不如给张参考图稳
- **威武程度按档次分级，不要每只都往霸气的方向写**——"参照中国神话"这句锚定很容易让模型（和我）无意识把每只精灵都设计得强大威猛。写具体描述时，按下表选用对应档次的气质词汇，凡/灵档要主动写"憨态/朴素/滑稽/丑萌/弱小"这类词，不要让几百只精灵个个都像最终boss：

| 档次 | 气质关键词（写进描述里） | 避免使用 |
|------|------------------------|---------|
| 凡 | 憨态、朴素、小巧、笨拙、谐趣、平平无奇 | 霸气、神威、君临 |
| 灵 | 精悍、敏捷、初具锋芒、略显自信 | 至高无上、神话尺度 |
| 玄 | 强悍、气场初显、身经百战 | （可少量使用玄档以上词汇） |
| 地 | 威猛、霸气、难以撼动 | — |
| 神 | 神威、煞气逼人、半神姿态 | — |
| 天 | 至高无上、神话尺度、君临天下 | — |

- **同一进化链中，只有最终形态才能用"霸气/神威/君临"级别的顶级词汇**，二段（中间形态）必须用低一档的词汇描述，哪怕它对应的档次（灵/玄）允许用更强词——目的是让二段和三段在气势上有明显台阶差，而不是看起来一样强

---

## 2. 属性命名字根表

设计精灵/技能名称时，优先使用对应属性的专属字根，让玩家一眼识别属性归属。

| 属性 | 推荐字根 | 已有命名示例 |
|------|----------|-------------|
| 火 | 炎、焰、曜、赤、丹、焚、烈 | 炎喵、烈火猫、焚焰狮、炎凰、焱纹虎 |
| 水 | 渊、泽、澜、汐、溟、蛟 | 蓝蛇、覆海龙、玄溟 |
| 木 | 竹、森、藤、青、芽、檀 | 小竹熊、古檀灵、灵芽儿、草御剑 |
| 雷 | 霆、雷、电、震、啸 | 霆啸、粉粉丘 |
| 冰 | 霜、冰、凌、寒、冻 | 幼冰犬、霜铠犬、铠霜战狼 |
| 格 | 武、拳、斗、功、道 | 武道熊、功夫熊师 |
| 毒 | 毒、瘴、蛊、瘟、沼 | 瘴龙（木/毒）、毒沼王（土/毒） |
| 土 | 岩、土、泥、砂、石 | 泥蛙、荒牛、毒沼王 |
| 风 | 翼、羽、风、翔、云 | 小雉鸡、坤鸡、大蝶 |
| 灵 | 灵、念、幻、梦、心 | 元英、智敏、古檀灵 |
| 虫 | 蛹、蚕、蛛、螳、蝶 | 绿肥虫、蛹甲、绿螳螂、天蚕铠 |
| 岩 | 岩、石、砾、磐 | 岩石巨人、小石蟹、岩灵、岩傩神 |
| 鬼 | 幽、魂、魅、魇、傩 | 岩傩神、石面具、幽狐、影狐 |
| 龙 | 龙、蛟、渊、鳞 | 覆海龙、苍渊（龙/风） |
| 暗 | 冥、暗、影、夜、墨 | 小影、怪影 |
| 钢 | 铜、铁、铸、钧、铠、钺 | 铎狐、铠霜战狼、钺霄 |
| 仙 | 仙、灵、华、瑞、祥 | 太一、绵绵羊、绒绒云 |
| 空 | （普通属性，不限制） | 吉他小猪 |

> 260723 Red：这张表原来有7处示例精灵的实际属性跟所在分类行对不上（比如"苍渊"当年放在
> 水/龙行，但它现在实际是龙/风；"影狐幽狐"当年是暗系示例，现在是纯鬼系；"铠灵"现在是仙/空
> 不是钢）——这批精灵后续调整过属性但没人回来同步这张表，已按 `data/species.json` 实际
> type1/type2 重新核对替换。以后调整已上表精灵的属性时记得顺手回来改这里。

### 双属性命名规则

双属性精灵命名时，优先用主属性字根 + 副属性字根拼接；若找不到自然组合，改用单一核心意象词涵盖两属性。

| 类型 | 规则 | 示例 |
|------|------|------|
| 主+副拼接 | 主属性字根开头，副属性字根结尾 | 岩傩神（岩主/鬼副）、铠霜战狼（冰主/钢副，260723订正：原文写反了） |
| 核心意象 | 两属性融合为一个整体概念 | 覆海龙（水/龙）、毒沼王（土/毒，260723订正：原文错写成毒/水）、太一（仙/风，260723订正：原文错写成仙/空） |

---

## 3. 进化设计原则

### 三段进化规则（30/70 法则）

每次进化**保留 30% 核心特征**（让玩家认出血统），**变化 70%**（体现成长）。

| 保留的（30%） | 变化的（70%） |
|-------------|-------------|
| 核心配色（主色调不变） | 体型增大、比例变化 |
| 标志性部位（如尾巴形状、额纹） | 新增装饰/武器/铠甲 |
| 眼睛风格 | 姿态从四足→双足，或温顺→威猛 |

### 反例警示

- 蛛优优 → 盘丝妖后：变化过大（虫→人形），需加中间形态 ✓ 已修复（现为 蛛优优→蛛灵儿(Lv24)→盘丝妖后(Lv38) 三段；260723订正：一代形态原名"小蛛妖"已改名，示例同步更新）
- 灰鱼苗 → 云锦鲤：鱼→龙鱼，变化合理 ✓（经中间体"红鲤"(Lv31)过渡，非直接进化）
- 二段做得跟三段一样强大威猛：常见错误，通常是提示词没有按档次降级气质词汇（见第1节表格）。二段应该还带着"半成品/过渡期"的痕迹（比如铠甲没穿全、招式姿态还不熟练、体型没完全撑开），把"完全体"的气场留给三段

### 分支进化

分支进化的两个终态应该：
- 共享基础形态的核心特征
- 在属性/定位上明确分化（如小石蟹 → 铁甲战蟹(水/钢) / 幽毒海蟹(水/毒)）

---

## 4. 精灵必填设计档案

> 260723 Red：标题写"必填"，但实测全部444只精灵里 `design_origin` 只填了81只（18%）、`role`
> 只填了6只（1.4%），远不是真的强制字段——`desc`/`tier` 倒是444/444全填了。这两个字段目前
> 更接近"建议补充"，历史欠账较大，暂不追认成强制要求，如果要真正强制请单独排期批量回填。

在 species.json 中，每只精灵除了种族值/技能池等游戏数据外，应包含：

```json
{
  "design_origin": "三星堆青铜面具 + 傩戏面具",
  "desc": "古老祭祀面具被灵气唤醒...",
  "tier": "凡",
  "role": "物盾"
}
```

| 字段 | 说明 | 示例 |
|------|------|------|
| `design_origin` | 文化/神话来源，2-3 个关键词 | "孙悟空 + 灵猴" |
| `desc` | 图鉴描述，1-2 句 | "密林深处的霸主..." |
| `tier` | 档次（凡/灵/玄/地/神/天） | 根据 BST 自动计算，编辑器可 override |
| `role` | 定位（物攻手/特攻手/...） | 编辑器 ⚡推荐 可自动填 |

---

## 5. 档次体系（BST 对应）

> 260723 Red：此前这张表写的是 凡/灵/玄/地/神/天（地<神）+ 阈值 360/450/535/600/670，
> 但实际数值和地/神顺序早在 260728 就调整过（地>神），两个编辑器（`tools/editor/src/tabs/species.js`
> `TIERS` 常量 + `mon_editor.py` `_suggest_tier_role()`）用的一直是下表这套，只是文档没同步更新。
> 用新阈值核对全部 444 只精灵，只有 2 只边界值有出入（七七 BST406/玄，坤鸡 BST423/灵，均在阈值
> 附近个位数差距，按"编辑器可 override"的既定规则视为设计者手动调整，不算数据错误）。

| 档次 | BST 范围 | 颜色 | 定位 | 示例 |
|------|---------|------|------|------|
| 凡 | <300 | 灰 | 基础形态/野生弱精灵 | 小雉鸡、绿肥虫、蛹甲 |
| 灵 | 300-409 | 蓝 | 普通进化型 | 小竹熊、炎喵、蓝蛇 |
| 玄 | 410-529 | 紫 | 强力终进化 | 武道熊、烈火猫、江蛟 |
| 神 | 530-639 | 橙红 | 幻兽/弱神兽 | 功夫熊师、焚焰狮、覆海龙 |
| 地 | 640-719 | 金 | 准神/伪神 | 超梦、火德、雷德 |
| 天 | 720+ | 红 | 顶级神兽 | 阳煌(720)、太一(780)、苍渊(780) |

---

## 6. 画风统一备忘

### 当前资产来源

| 来源 | 数量 | 画风特征 |
|------|------|---------|
| 豆包（免费） | 多数 | 像素风偏日系，质量参差 |
| Gemini（免费） | 少量 | 细节较多，偏插画 |
| GPT Image 2 | 5张/天 | 质量最高，风格可控 |

### 画风差异应对

- **短期**：接受差异，优先填满图鉴，保证每只都有 front/back
- **长期**：用统一后缀 Prompt（第1节）逐步替换画风偏差最大的精灵
- **优先替换**：天品/神品神兽（门面精灵必须高质量）
- **GPT Image 2 用途优先级**：神兽 > 标题画面 > 战斗背景 > 普通精灵

---

## 7. 场景/建筑美术 Prompt 规范（室内/室外贴图）

场景类素材最容易漂移的地方是**视角**——不加约束时，文生图模型默认会往"斜45度/等距(isometric)"的方向跑，而不是 GBA 那种俯视摊平构图。必须显式写禁止词。

### 统一视角锚定（所有场景类必加，不可省略）

```
Pixel art game background, 16-bit SNES/GBA JRPG style.
Reference the classic Pokemon FireRed/LeafGreen top-down interior/exterior perspective:
flat orthographic top-down floor + walls collapsed flat at the top of the frame
(like an unfolded box with the back wall folded down).
NOT isometric. NOT 3/4 oblique angle. NOT perspective with vanishing point.
Clean flat color blocks, simple pixel shading, no depth blur.
No characters in the scene.
```

中文版（豆包等国产模型用中文效果更好时替换）：
```
像素风JRPG游戏背景美术，16-bit GBA画风。
参考《精灵宝可梦：火红/叶绿》室内外的经典俯视视角——
纯俯视地板 + 墙壁像被展开摊平贴在画面上方（类似把纸盒剪开摊平俯拍的效果）。
禁止等距(isometric)视角，禁止3/4斜侧视角，禁止透视灭点和景深虚化。
色块干净，简单像素阴影，无人物。
```

### 规则

- **禁止词句不能删**（"NOT isometric / NOT 3/4 oblique"这句）——只写"top-down"经常还是会漂到斜视角，必须同时给正反两面约束
- **建筑外观和室内贴图分开生成**，不要一张图里同时画内外
- **同一场景多张图**（同一栋建筑的不同楼层/房间）写在同一条 prompt 里，末尾加一句"两张图使用相同色彩基调与像素颗粒度"，靠这句话约束批量出图（豆包等支持一次出多图的模型）风格统一
- **新建筑要接现有色板**：生成村庄/小镇内的新建筑时，在 prompt 里注明"参考已有建筑的木质屋顶/暖色调"（对照 `assets/backgrounds/buildings/` 里已有素材的配色），避免新建筑颜色体系跳脱
- 尺寸统一按具体用途指定（背景贴图通常 960×640 或按场景 viewport 裁切目标）

---

## 8. 代码与数据规范

### 文件读写（Python 工具脚本）

所有 JSON 读写必须使用以下模式，保持 **LF** 换行和 UTF-8 编码：

```python
# 读
with open(path, 'rb') as f:
    data = json.loads(f.read().decode('utf-8'))

# 写
with open(path, 'wb') as f:
    text = json.dumps(data, ensure_ascii=False, indent=2)
    f.write(text.encode('utf-8'))
```

> 260722 Red：这里原来写的是"保持 CRLF"，跟仓库实际存储（`data/*.json` 在 git 里全部是 LF，
> `core.autocrlf=true` 会在 commit 时自动把 CRLF 转回 LF）对不上——工具一旦真按旧指示写了
> CRLF，工作区就会跟 HEAD 不一致，`git status` 就会显示"已修改"但 `git diff` 是空的，纯噪声。
> `.gitattributes` 已经把 `data/*.json` 钉死成 `eol=lf`，工具老老实实写 LF 就行，不用再手动转换。

Windows 控制台中文会乱码，**不要用 `print()` 输出中文再重定向**，改为直接写文件：
```python
with open('tools/_tmp.txt', 'w', encoding='utf-8') as f:
    f.write(result)
```

### 一次性脚本约定

临时脚本放 `tools/` 目录，命名以 `_` 开头（如 `tools/_fill_learnsets.py`），执行完毕验证后**立即删除**。

### Sprite 命名

```
{名字}front.png    # 正面立绘（战斗精灵：assets/sprites/；角色立绘：assets/npc/，260723订正见下）
{名字}back.png     # 背面立绘
{名字}walk_sheet.png  # 行走帧，260723订正：实际都放在 assets/npc/（如"男主walk_sheet.png"），
                      # 不是战斗精灵所在的 assets/sprites/，两类素材目录不一样
{名字}throw.png    # 投掷帧——260723 Red 核实：全代码库无引用，assets/下也没有任何文件用这个
                    # 后缀，目前是纯占位规格，从未真正落地
```

名字和后缀之间**无下划线**。代码路径：`"res://assets/sprites/%sfront.png" % species_id`

所有立绘统一 **512×512 PNG**，非正方形原图需**等比缩放后填充背景色补方**（不拉伸）。

### 注释格式

GDScript/Python 内的标记注释统一格式：`# YYMMDD Red xxx`（如 `# 260702 Red 光系克制`；260723订正：
GDScript和Python一样只认 `#` 号注释，不支持 `//`，这里原来写错了，实测全代码库242处标记注释
也确实全部用的是 `#`，不是文档原先写的 `//`）。

### GDScript 场景约定

- 每个场景 `extends Node2D`，声明 `signal request_scene`
- 入口数据通过 `get_meta("scene_data", {})` 读取
- 场景切换由 `main.gd` 的 `switch_to(scene_name, data)` 统一管理
- Autoload（`project.godot` `[autoload]` 段，260723订正：原来只列了2个，实际6个游戏相关单例）：
  `GameState`（玩家数据/存档/输入映射）、`MonDB`（精灵/技能/道具/对话/训练师数据库）、
  `EncounterDB`（遇敌表）、`AudioManager`（BGM/SE/ME）、`DialogManager`（对话框单例）、
  `ScriptEngine`（事件脚本引擎，注：目前是从未被调用的半成品，见代码注释）

---

## 9. 数据架构规范

### species.json 字段说明

```json
{
  "id": 1,                           // 图鉴编号
  "name": "炎喵",                    // 显示名
  "type1": "火", "type2": "",        // 主/副属性（19种：空/火/水/木/虫/土/风/仙/灵/龙/格/雷/冰/毒/岩/鬼/暗/钢/光）
  "base": {"hp":45, "atk":52, ...},  // 种族值
  "growth_rate": "中速",              // 经验曲线
  "exp_yield": 64,                   // 击败给予经验基础值
  "catch_rate": 45,                  // 捕获率 (1-255)
  "gender_ratio": 87.5,              // 雄性比例 (0=全雌, 100=全雄, -1=无性别)
  "height": "0.3", "weight": "4.5",  // 260723补文档：全部444只精灵都有这两个字段，此前漏写
  "abilities": ["猛火", "烈焰体"],   // [主特性, 隐藏特性]，需存在于 abilities.json
  "learnset": {"1": ["撞击"], "4": ["火花"], ...},  // 等级学习树
  "evolve_level": 16,                // 进化等级（旧版兼容字段，无则不填）
  "evolves_into": "烈火猫",          // 进化目标（旧版兼容字段，简单进化）
  "evolutions": [...],               // 新版分支进化列表（含道具门槛，唯一权威来源，见下方进化规则说明）
  "encounters": [...],               // 260723：遗留字段，实际遇敌表已迁移到 encounters.json 按map_id索引，
                                      // 这个字段和读取它的 MonDB.get_encounters() 都是未清理的死数据
  "design_origin": "...",            // 设计来源（建议填，非强制，见第4节）
  "desc": "...",                     // 图鉴描述
  "tier": "凡",                      // 档次
  "role": "物攻手"                   // 定位（建议填，非强制，见第4节）
}
```

> 260723 Red：`get_available_evolutions()`（`mon_db.gd`）以 `evolutions` 数组为准，`evolves_into`/
> `evolve_level` 只在数组里没有满足等级的分支时才当兜底用，且**不检查道具**——两套字段都填的精灵
> 如果后续只改了 `evolutions` 忘了同步旧字段，会出现道具门槛被绕过的真实bug（已发生过一次，宋皇/
> 卡琳娜两只精灵260723修复）。新增/修改进化配置时两套字段务必保持等级一致。

### moves.json 字段说明

```json
{
  "name": "火花",
  "type": "火",                      // 19种属性之一
  "category": "特殊",                // 物理/特殊/变化
  "power": 40,                       // 威力（变化技能为0）
  "accuracy": 100,                   // 命中率（0=必中）
  "max_pp": 25,                      // 最大PP
  "effect": "inflict_burn",          // 效果key（见下表）
  "effect_chance": 10,               // 效果触发概率%（0=必触发，secondary_status也复用这个字段）
  "effect_value": 0,                 // 效果数值参数（反伤%/吸血%/回复%等）
  "secondary_status": "",            // 主effect被recoil/drain/multi_hit/high_crit等占用时，
                                      // 额外再挂一个独立几率状态用这个（如双针=multi_hit_2+
                                      // secondary_status:inflict_poison；闪焰冲锋=recoil+
                                      // secondary_status:inflict_burn），机制和值域跟effect相同
  "description": "..."               // 技能描述
}
```

### 技能效果 effect 可选值

| 分类 | effect key | 中文标签 | 需要chance | 需要value |
|------|-----------|---------|-----------|-----------|
| 异常 | inflict_burn / inflict_poison / inflict_paralysis / inflict_sleep / inflict_freeze | 灼伤/中毒/麻痹/催眠/冰冻 | ✓ | |
| 异常 | inflict_confusion / inflict_toxic | 混乱/剧毒（递增） | ✓ | |
| 降能力 | lower_atk / lower_def / lower_sp_atk / lower_sp_def / lower_spd / lower_acc | 降X | ✓ | |
| 升能力 | raise_atk / raise_def / raise_sp_atk / raise_sp_def / raise_spd / raise_acc | 升X | ✓ | |
| 回复 | heal_self | 自我回复 | | ✓(%HP) |
| 吸血 | drain | 吸血 | | ✓(%伤害) |
| 反伤 | recoil | 反伤 | | ✓(%伤害) |
| 替身 | substitute | 替身 | | ✓(%HP) |
| 攻击 | priority / high_crit / flinch / multi_hit / multi_hit_2 / bind | 先制/暴击/畏缩/连击(2~5次)/连击(固定2次)/束缚 | 畏缩✓ | |
| 节奏 | charge / recharge | 蓄力/休息 | | |
| 场控 | force_switch / protect / leech_seed / taunt / encore / clear_stats / entry_hazard | 各种 | | |
| 天气 | weather_sun / weather_rain / weather_sandstorm / weather_hail | 天气 | | |
| 屏障 | screen_physical / screen_special | 物理/特殊减伤 | | |

> 注：目前战斗代码 `_apply_effect()` 已实现全部升/降能力（含混乱 `inflict_confusion`）+ 七种异常状态（含剧毒 `inflict_toxic`，每回合递增1/16伤害）；`_execute_move()` 另外单独实现了 `multi_hit`/`multi_hit_2` 多段攻击（260722，此前11个技能只按单段威力结算，是纯数据×代码两头都缺的真bug，不是占位）。
>
> 260722 Red 又接入了5个：`flinch`（畏缩，先手方命中后手方本回合无法行动，用完即清）、`substitute`（替身，消耗25%当前HP，之后伤害先扣替身HP、多余不穿透，替身在时几乎所有"作用于对手"的效果都会被挡下）、`leech_seed`（寄生种子，回合末按被种者1/8最大HP吸血给对方）、`encore`（再来一次，锁定对方接下来3回合必须使用其上一招，直到PP耗尽提前解除）、`screen_special`（光之壁，5回合内使对方特殊攻击伤害减半，1v1单挑简化为直接作用于施放者自己）。
>
> 其余（束缚 `bind`/蓄力 `charge`/休息 `recharge`/强制换场 `force_switch`/守住 `protect`/挑衅 `taunt`/清除能力 `clear_stats`/钉刺类 `entry_hazard`/天气 `weather_*`/物理屏障 `screen_physical`）仍是占位，待逐步接入（260723订正：这行原来还写着"自爆 self_destruct"，但下面一条已经说明它实现了，是没删干净的自相矛盾，这里删掉）。
>
> 260722 Red 参考Pokemon Essentials原版逻辑又接入4个（新技能名单独列在effect表外，不占用上面枚举的分类位）：`rampage`（大闹一番/花瓣舞/逆鳞，命中后锁定2~3回合强制重复同一招且不消耗PP，锁定结束后对自己上混乱；中途换场/晕厥会随`_reset_transient_battle_state`清空，不会跨场次残留）、`rollout`（滚动，同款锁定机制但持续5回合、不上混乱，改为每回合伤害翻倍，30→60→120→240→480）、`fury_cutter`（连续切/连斩共用，不锁定选招，只要连续两回合点的是同一招就翻倍，封顶4倍，中途换别的招式会自动清零，靠比对`last_move_id`实现，不需要额外计时）、`torment`（无理取闹，标记对方不能连续用上一招；AI侧直接从候选列表里过滤掉，玩家侧因为UI没有禁用按钮那层，简化成选中后判定失败、不执行但仍耗PP）。另外"临别礼物"改名`破釜沉舟`并重新设计为`reckless_debuff`：消耗自身50%最大HP，随机大幅降低对手一项能力（-2级），弃用了原版"自我昏厥"设定。
>
> 260723 Red `self_destruct`（大爆炸/玉石俱碎）已实现并从占位表移除：命中造成伤害后攻击者HP直接归零，未命中时也照样自爆（原版规则，Explosion系无论命中与否都会让使用者昏厥）。烧伤描述用词也统一了——早期扫描效果空白技能时只搜了"烧伤"，漏掉了同义词"灼伤"（16处描述用的是"灼伤"，代码里status字段/战斗消息却只认"烧伤"），已经全部改成和实际状态名一致的"烧伤"，顺带把被漏检的11个烧伤技能effect也补上了。
>
> 260723 Red 又接入3个新key（同样单独列，不在上面表格分类内）：`ohko`（一击昏厥，地裂/绝对零度/角钻，命中直接让对方HP归零，不做等级差修正的命中率二次计算，会被替身挡下）、`endure`（挺住，本回合内若受到的伤害本该致命就改成留1HP，只生效一次，回合末无论有没有触发都清零；未实现原版"连续使出容易失败"的递减成功率）、`revenge`（冤冤相报，本回合若后出手则伤害翻倍，靠`_execute_move()`新增的`acted_second`参数判断，只在`_on_move_pressed`里真正的"后手"两个调用点传true）。
>
> 260723 Red 之前列出的6个"真实缺口"全部补上了：`tri_status`（三重攻击，命中后随机三选一麻痹/烧伤/冰冻，20%触发）、`swagger`（虚张声势，混乱对方+提升对方攻击2级——之前只接了混乱那一半，"提升对方"用了专属key而不是让raise_atk变成可以作用于defender，避免影响其他raise_*技能的方向语义）、`cure_self_status`（焕然一新，只清中毒/麻痹/烧伤/剧毒，不动睡眠/冰冻/混乱，对应原版Refresh的真实范围）、`yawn`（哈欠，命中后不立即睡眠，靠新增的`yawn_turns`倒数，下一回合结束时才真正睡着，中间正常行动）、`facade`（硬撑，自身带异常状态时伤害翻倍，纯粹是_execute_move()里的伤害修正，不经过_apply_effect）、`wake_up_slap`（清醒，对方麻痹时伤害翻倍+命中后治愈其麻痹，判定和治愈分别在伤害计算前/伤害结算后两处，靠`defender_was_paralyzed`这个局部变量串起来）。
>
> 260723 Red `secondary_status`字段（另一位协作者加的，用于双针这类"主effect被multi_hit占用后还想再挂一个几率状态"的技能）原本只在`_execute_move()`的多段攻击分支里生效，扩展到了单段伤害分支——现在任何主效果是recoil/drain/high_crit等"占用了effect字段"的单段技能也能用它挂一个独立的额外状态，闪焰冲锋（反伤+有时烧伤）借此补上了之前因为单字段限制丢掉的烧伤几率。注意：这套机制只能挂`_apply_effect()`认识的状态/属性变化类效果，像十字毒刃/毒尾丢掉的"容易击中要害"(high_crit)属于伤害计算层面的东西，不是`_apply_effect`能表达的，`secondary_status`帮不上，仍然是有意的取舍未解决。

### 学习树(learnset)设计规则

进化链的学习树遵循以下继承规则：
- **Lv4 和 Lv7 技能全链共享**（所有进化阶段完全相同）
- **进化后 Lv1**：继承前一阶段的 Lv1 + 所有非4/7级的技能（折叠进Lv1）
- **每个阶段新增3个技能**，按等级间距分配：
  - 最终形态：`进化等级 + 5 / +13 / +20`
  - 中间形态：`进化等级 + gap×0.15 / ×0.45 / ×0.75`（gap = 下次进化等级 - 本次进化等级）
- 技能威力应随等级递增（低级学弱技能，高级学强技能）
- 优先选用与精灵 type1/type2 匹配的技能

### abilities.json 格式

```json
{
  "猛火": {
    "name": "猛火",
    "desc": "HP低于1/3时，火属性技能威力提升50%。",
    "effect": "stat_boost_low_hp"    // 效果标识（英文key，编辑器显示中文）
  }
}
```

### 训练师数据格式

> 260723 Red：这节原来写的是"独立的 data/trainers.json"，但这个文件**不存在**——`data/` 目录下
> 实际只有 natures/npcs/maps/abilities/items/encounters/dialogs/species/moves 九个json。训练师
> 数据实际嵌在 `npcs.json` 每条NPC记录的 `"trainer"` 子对象里，运行时由 `mon_db.gd` 的
> `_build_trainers_from_npcs()` 动态从 npcs.json 拼出 `trainers` 字典（供战斗代码按id查询），
> 不是从独立文件加载。

训练师的地图布局（位置/朝向/视野）在各 scene `.gd` 文件中以 const 定义。
战斗数据（队伍/奖金/对话）在 `data/npcs.json` 对应NPC条目的 `trainer` 字段里（示例取自"shenhe"记录）：

```json
{
  "shenhe": {
    "trainer": {
      "trainer_id": "shenhe", "class": "神秘少女",
      "reward": 1600, "iv_tier": 2,
      "dialog_before": "...", "dialog_win": "...", "dialog_lose": "...",
      "dialog_player_lose": "...", "dialog_after": "...",
      "team": [{"species": "小雉鸡", "level": 14, "moves": [], "item": ""}, ...]
    }
  }
}
```

---

## 10. 属性体系

### 19种属性

空、火、水、木、虫、土、风、仙、灵、龙、格、雷、冰、毒、岩、鬼、暗、钢、光

### 属性克制表（攻→防，1.5x为克制，0.6x为抵抗，0.0为免疫）

完整克制表定义在 `scripts/autoload/mon_db.gd` 的 `_type_chart` 和 `tools/mon_editor.py` 的 `TYPE_CHART` 中，两处必须同步。

光系关键（260723订正，逐条核对 `_type_chart` 后修正）：
- 光克(1.5x)：鬼、虫、冰、暗
- 光免疫(0.0x)：木（原表漏了这条，误把木归进1.5x克制那行）
- 光打不好使(0.6x)：火、钢、光、水
- 光被克(1.5x)：暗（原表多写了土、钢——这两个属性的攻击表里根本没有"光"这个键，实际按1.0倍无克制结算）
- 光↔暗互爆（双向1.5x）
