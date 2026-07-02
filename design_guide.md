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
| 水 | 渊、泽、澜、汐、溟、蛟 | 苍渊、蓝蛇、江蛟、覆海龙、玄溟 |
| 木 | 竹、森、藤、青、芽、檀 | 小竹熊、古檀灵、灵芽儿、草御剑 |
| 雷 | 霆、雷、电、震、啸 | 霆啸、粉粉丘 |
| 冰 | 霜、冰、凌、寒、冻 | 幼冰犬、霜铠犬、铠霜战狼 |
| 格 | 武、拳、斗、功、道 | 武道熊、功夫熊师 |
| 毒 | 毒、瘴、蛊、瘟、沼 | 瘴龙、毒沼王 |
| 土 | 岩、土、泥、砂、石 | 岩灵、岩傩神、泥蛙 |
| 风 | 翼、羽、风、翔、云 | 小雉鸡、坤鸡、大蝶 |
| 灵 | 灵、念、幻、梦、心 | 元英、智敏、古檀灵 |
| 虫 | 蛹、蚕、蛛、螳、蝶 | 绿肥虫、蛹甲、绿螳螂、天蚕铠 |
| 岩 | 岩、石、砾、磐 | 岩石巨人、小石蟹 |
| 鬼 | 幽、魂、魅、魇、傩 | 岩傩神、石面具 |
| 龙 | 龙、蛟、渊、鳞 | 苍渊、覆海龙、瘴龙 |
| 暗 | 冥、暗、影、夜、墨 | 影狐、幽狐 |
| 钢 | 铜、铁、铸、钧、铠、钺 | 铎狐、铠灵、铠霜战狼、钺霄 |
| 仙 | 仙、灵、华、瑞、祥 | 太一、绵绵羊、绒绒云 |
| 空 | （普通属性，不限制） | 吉他小猪、荒牛 |

### 双属性命名规则

双属性精灵命名时，优先用主属性字根 + 副属性字根拼接；若找不到自然组合，改用单一核心意象词涵盖两属性。

| 类型 | 规则 | 示例 |
|------|------|------|
| 主+副拼接 | 主属性字根开头，副属性字根结尾 | 岩傩神（岩主/鬼副）、铠霜战狼（钢主/冰副） |
| 核心意象 | 两属性融合为一个整体概念 | 苍渊（水/龙）、毒沼王（毒/水）、太一（仙/空） |

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

- 小蛛妖 → 盘丝妖后：变化过大（虫→人形），需加中间形态 ✓ 已修复
- 灰鱼苗 → 云锦鲤：鱼→龙鱼，变化合理 ✓
- 二段做得跟三段一样强大威猛：常见错误，通常是提示词没有按档次降级气质词汇（见第1节表格）。二段应该还带着"半成品/过渡期"的痕迹（比如铠甲没穿全、招式姿态还不熟练、体型没完全撑开），把"完全体"的气场留给三段

### 分支进化

分支进化的两个终态应该：
- 共享基础形态的核心特征
- 在属性/定位上明确分化（如小石蟹 → 铁甲战蟹(水/钢) / 幽毒海蟹(水/毒)）

---

## 4. 精灵必填设计档案

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

| 档次 | BST 范围 | 颜色 | 定位 | 示例 |
|------|---------|------|------|------|
| 凡 | <360 | 灰 | 基础形态/野生弱精灵 | 炎喵、泥蛙、绿肥虫 |
| 灵 | 360-449 | 蓝 | 普通进化型 | 烈火猫、沼蟾 |
| 玄 | 450-534 | 紫 | 强力终进化 | 焚焰狮、覆海龙 |
| 地 | 535-599 | 金 | 准神/伪神 | 蚩极、猿圣 |
| 神 | 600-669 | 橙红 | 幻兽/弱神兽 | 盘丝妖后、天蚕铠 |
| 天 | 670+ | 红 | 顶级神兽 | 苍渊(720)、太一(720) |

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

所有 JSON 读写必须使用以下模式，保持 CRLF 换行和 UTF-8 编码：

```python
# 读
with open(path, 'rb') as f:
    data = json.loads(f.read().decode('utf-8'))

# 写
with open(path, 'wb') as f:
    text = json.dumps(data, ensure_ascii=False, indent=2)
    f.write(text.replace('\n', '\r\n').encode('utf-8'))
```

Windows 控制台中文会乱码，**不要用 `print()` 输出中文再重定向**，改为直接写文件：
```python
with open('tools/_tmp.txt', 'w', encoding='utf-8') as f:
    f.write(result)
```

### 一次性脚本约定

临时脚本放 `tools/` 目录，命名以 `_` 开头（如 `tools/_fill_learnsets.py`），执行完毕验证后**立即删除**。

### Sprite 命名

```
{名字}front.png    # 正面立绘
{名字}back.png     # 背面立绘
{名字}walk_sheet.png  # 行走帧
{名字}throw.png    # 投掷帧
```

名字和后缀之间**无下划线**。代码路径：`"res://assets/sprites/%sfront.png" % species_id`

所有立绘统一 **512×512 PNG**，非正方形原图需**等比缩放后填充背景色补方**（不拉伸）。

### 注释格式

GDScript/Python 内的标记注释统一格式：`// YYMMDD Red xxx`（如 `// 260702 Red 光系克制`）。

### GDScript 场景约定

- 每个场景 `extends Node2D`，声明 `signal request_scene`
- 入口数据通过 `get_meta("scene_data", {})` 读取
- 场景切换由 `main.gd` 的 `switch_to(scene_name, data)` 统一管理
- Autoload：`GameState`（玩家数据/存档/输入映射）、`MonDB`（精灵/技能/道具/对话/训练师数据库）

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
  "abilities": ["猛火", "烈焰体"],   // [主特性, 隐藏特性]，需存在于 abilities.json
  "learnset": {"1": ["撞击"], "4": ["火花"], ...},  // 等级学习树
  "evolve_level": 16,                // 进化等级（无则不填）
  "evolves_into": "烈火猫",          // 进化目标（简单进化）
  "evolutions": [...],               // 分支进化列表
  "encounters": [...],               // 遭遇地点
  "design_origin": "...",            // 设计来源
  "desc": "...",                     // 图鉴描述
  "tier": "凡",                      // 档次
  "role": "物攻手"                   // 定位
}
```

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
  "effect_chance": 10,               // 效果触发概率%（0=必触发）
  "effect_value": 0,                 // 效果数值参数（反伤%/吸血%/回复%等）
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
| 攻击 | priority / high_crit / flinch / multi_hit / bind | 先制/暴击/畏缩/连击/束缚 | 畏缩✓ | |
| 节奏 | charge / recharge / self_destruct | 蓄力/休息/自爆 | | |
| 场控 | force_switch / protect / leech_seed / taunt / encore / clear_stats / entry_hazard | 各种 | | |
| 天气 | weather_sun / weather_rain / weather_sandstorm / weather_hail | 天气 | | |
| 屏障 | screen_physical / screen_special | 物理/特殊减伤 | | |

> 注：目前战斗代码 `_apply_effect()` 仅实现了 `lower_atk/lower_acc/lower_spd/raise_def/raise_sp_atk` 和五种异常状态，其余均为占位，待逐步接入。

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

### trainers.json 格式

训练师的地图布局（位置/朝向/视野）在各 scene `.gd` 文件中以 const 定义，
游戏数据（名字/队伍/奖金/对话）在 `data/trainers.json` 中，运行时通过 trainer id 关联。

---

## 10. 属性体系

### 19种属性

空、火、水、木、虫、土、风、仙、灵、龙、格、雷、冰、毒、岩、鬼、暗、钢、光

### 属性克制表（攻→防，1.5x为克制，0.6x为抵抗，0.0为免疫）

完整克制表定义在 `scripts/autoload/mon_db.gd` 的 `_type_chart` 和 `tools/mon_editor.py` 的 `TYPE_CHART` 中，两处必须同步。

光系关键：
- 光克(1.5x)：鬼、虫、冰、木、暗
- 光被克(1.5x)：土、钢、暗
- 光打不好使(0.6x)：火、钢、光、水
- 光↔暗互爆（双向1.5x）
