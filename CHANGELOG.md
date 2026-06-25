# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---
 
 ### [0.0.11] - 2026-06-25
 
 #### Changed
 - **README 全面重写**：删除固定精灵图鉴列表（现 24 只持续扩充中），改为概述 + 御三家表；新增编辑器工具说明；项目结构同步更新
 - **精灵种族值平衡调整**：炎喵/烈火猫/焚焰狮/小竹熊/武道熊/功夫熊师 6 只精灵的种族值与进化等级重新分配，使御三家路线更符合物攻/特攻定位
 
 ---
 

### [0.0.10] - 2026-06-25

#### Added
- **新精灵 6 只**：绿螳螂、蓝焰螳螂、赤金螳螂、元英、智敏、舒华 — `data/species.json` 占位
- **蛹甲素材图**：绿叶挂茧风格像素画，`assets/sprites/`
- **覆海龙背面图**：`assets/sprites/覆海龙_back.png`（此前缺失）
- **Git LFS 支持**：`.gitattributes` 追踪 `assets/sprites/*.png`，大图推送不再超时

#### Fixed
- **`tools/mon_editor.py`**：`_mon_save` 中 `STAT_LABELS` 列表拆包反了导致 KeyError 崩溃
- **`tools/mon_editor.py`**：种族值标签 width=4 过窄，"HP（体力）"等中文标签被截断
- **`tools/mon_editor.py`**：种族值每行右端的硬编码 "0" 标签已移除，避免误解
- **`tools/mon_editor.py`**：PyInstaller 打包后路径解析错误（缺 `sys.frozen` 判断导致找 `Temp/` 下数据）

#### Changed
- **`tools/mon_editor.py`**：保存按钮从底部移到右上角（编号旁），操作更方便
- **`tools/mon_editor.py`**：性别比选择器旁增加 ♂♀ 标识符号
- **精灵素材全部重压缩**：3MB → 650KB（78.5% 缩减），统一缩放至 256×256，NEAREST 采样保持像素风
- **`assets/sprites/`**：所有非 96×96 的大图（384×384/288×384）统一为 256×256

---

### [0.0.9] - 2026-06-25

#### Added
- 720p 分辨率升级：视口 720×480，窗口 1440×960，所有 UI 布局按 1.5 倍放大
- 大地图扩展：45×30 瓷砖地图（原 30×20），新增草丛、第二池塘、更多花朵与路径
- 精灵图库扩充：新增进化形态与角色精灵（烈火猫/焚焰狮/江蛟/覆海龙/武道熊/功夫熊师等）

#### Changed
- 御三家选择界面：卡片区 110×148 → 160×210，精灵图 64×64 → 96×96，教授精灵 120×180
- 战斗界面适配 720p：战场区/消息框/菜单栏尺寸与位置全面调整
- 所有精灵图统一为 96×96 RGBA PNG 格式（NEAREST 采样保持像素风锐利边缘）

#### Fixed
- `battle_scene.gd`：`_refresh_bag_panel()` 第 428/435/437 行混用空格缩进，Godot 4.x 解析失败导致遇敌闪退
- `tools/check_js.py`：硬编码旧项目路径 `D:/AI/Game/RPG_Demo/tools/mon_editor.py`
- `tools/import_mons.py`：进化字段非"无"且无匹配时未清除旧数据；捕获率正则 `\S+` 误吞尾部注释
- `tools/mon_editor.py`：字典键 `\u53d8\u5214`（变刺）错字改为 `\u53d8\u5316`（变化）

---

### [0.0.8] - 2026-06-24

#### Added
- 捕捉系统：精灵球投掷，基于 HP / 状态异常 / 种族捕获率 / 球加成的概率公式
- 道具背包（背包面板）：战斗中可使用精灵球、回复药、强效回复药
- 多精灵队伍支持（最多 6 只），战斗中可手动切换上场精灵
- 切换精灵给予对方免费攻击一次（主动换场扣费机制）
- 被击倒后强制换场逻辑（无免费攻击）
- 战斗胜利后正确分配经验值给上场精灵
- items.json 道具数据文件（含 category / heal_amount / ball_bonus 字段）

---

### [0.0.7] - 2026-06-24

#### Added
- 进化系统：`check_evolution()` 检测进化条件，`evolve()` 原地修改精灵字典
- 绿毛虫 Lv7 进化为蛹甲（species.json 含 evolves_into / evolve_level 字段）
- 战斗胜利后自动检测进化并播放进化提示消息
- 升级时自动学习对应等级技能（learnset 字段）

---

### [0.0.6] - 2026-06-24

#### Added
- 经验值系统：`exp_for_level()` 支持快速 / 中速 / 缓慢三种成长速度
- `gain_exp()` 函数：累计经验，自动触发升级
- `level_up()` 函数：升级重算全属性，保留 HP 差值
- 战斗胜利后经验分配，战斗 UI 显示升级消息

---

### [0.0.5] - 2026-06-24

#### Added
- 5 种状态异常：烧伤（每回合 1/16 HP）、中毒（1/8 HP）、麻痹（25% 跳过 + 速度减半）、睡眠（随机 1-3 回合）、冰冻（20% 概率解冻）
- 状态标签显示（战斗 UI 精灵名旁显示彩色 `[烧]`/`[毒]`/`[麻]`/`[眠]`/`[冰]`）
- `_check_status_block()`：回合开始状态判定
- `_apply_end_of_turn_damage()`：回合结束持续伤害
- 烧伤导致物理攻击降低 50%

---

### [0.0.4] - 2026-06-24

#### Added
- 完整 18 属性克制表（Gen 6 标准，汉化为中文属性名）
- 属性：空 / 火 / 水 / 木 / 雷 / 冰 / 格 / 毒 / 土 / 风 / 灵 / 虫 / 岩 / 鬼 / 龙 / 暗 / 钢 / 仙
- 效果拔群 ×1.5，效果一般 ×0.6，无效 ×0.0
- 本系加成（STAB）×1.2
- 击中要害 5% 概率 ×1.3 倍伤害
- 物理/特殊分类（category 字段）
- 属性色彩字典（type_colors），用于 UI 着色

#### Changed
- 灵属性对暗属性由免疫改为正常伤害（×1.0）
- 虫属性对仙属性由效果一般改为效果拔群（×1.5）

---

### [0.0.3] - 2026-06-24

#### Added
- JSON 数据系统：species.json（精灵种族）、moves.json（技能）
- 7 种精灵：焰狐、水蛟、竹灵、绿毛虫、蛹甲、石偶、野鼠灵
- 19 个技能，含物理/特殊/变化分类及附加效果（effect / effect_chance）
- `MonDB.create_mon()`：含 IV 个体值（0-31）的精灵创建函数
- 属性计算公式：HP = `⌊(3×种族值 + IV) × Lv / 100⌋ + Lv + 10`
- `MonDB.calc_damage()`：完整伤害公式

---

### [0.0.2] - 2026-06-24

#### Added
- 战斗场景（battle_scene.gd）：火红风格 480×320 布局（场地/消息框/菜单栏）
- 御三家选择场景（starter_scene.gd）：元教授 + 3 张选择卡片
- 大地图场景（world_scene.gd）：30×20 瓷砖，WASD 移动，草丛遇敌（15% / 4步）
- 野生精灵遭遇表：绿毛虫 50%，野鼠灵 35%，石偶 15%，等级 Lv2-5
- 回合制战斗框架：速度先攻，4 技能选择，攻击/逃跑菜单
- 程序化精灵绘制（无素材时使用几何图形占位）
- PNG 热替换支持：放置 `{名称}_front/back.png` 自动加载

---

### [0.0.1] - 2026-06-24

#### Added
- 项目初始化，Godot 4.7，分辨率 480×320（放大至 960×640），pixel_snap 开启
- Autoload 架构：`GameState`（玩家全局状态）、`MonDB`（数据库）
- 场景管理器（main.gd）：通过 `request_scene` 信号切换场景
- 全局中文字体支持：Microsoft YaHei，挂载至根节点 Window Theme
- 玩家初始状态：500 金币，精灵球 ×5，回复药 ×3
