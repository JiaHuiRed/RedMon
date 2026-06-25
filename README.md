# 🐉 RedMon — 红灵

> 一款中国风像素精灵 RPG，基于 Godot 4 构建。

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![Godot 4.7](https://img.shields.io/badge/Godot-4.7-blue.svg)](https://godotengine.org/)
[![Version](https://img.shields.io/badge/version-v0.0.11-green.svg)](./CHANGELOG.md)

---

## 🌏 游戏简介

**红灵**（RedMon）是一款致敬宝可梦火红/叶绿的中国风像素 RPG。

玩家扮演来自华灵大陆起始草原的训练师，从元教授处获得第一只精灵，开始探索、捕捉、对战的旅途。

---

## ✨ 核心特性

- 🐾 **御三家选择** — 炎喵（火）、蓝蛇（水）、小竹熊（木），由元教授赠予
- ⚔️ **回合制战斗** — 火红风格 UI，速度先攻，4 技能选择，含背包/换宠/逃跑
- 🗺️ **大地图探索** — 45×30 瓷砖地图，草丛随机遇敌（15%/4步）
- 🧪 **18 属性克制** — 完整宝可梦第六世代属性表，汉化为中文属性名
- 📊 **种族值系统** — 6 维属性（HP/攻击/防御/特攻/特防/速度），含 IV 个体值
- 💫 **状态异常** — 烧伤、中毒、麻痹、睡眠、冰冻，含回合效果
- 📈 **经验与升级** — 3 种成长速度（快速/中速/缓慢），升级自动习得技能
- 🌀 **进化系统** — 升级触发进化，支持进化链（绿肥虫 Lv7 → 蛹甲）
- 🎯 **捕捉系统** — 精灵球投掷，基于 HP、状态、种族捕获率的概率公式
- 🎒 **道具背包** — 精灵球、回复药、强效回复药，战斗中可使用
- 👥 **多精灵队伍** — 最多 6 只，战斗中可切换，被击倒后强制换场
- ✏️ **可视化编辑器** — 内置 tkinter 编辑工具，可视化修改精灵与技能数据

---

## 🐾 精灵图鉴

游戏目前包含 **24 只精灵**（持续扩充中），覆盖火、水、木、虫、土、空、风、仙、灵、龙、格、电 12 种属性。

> 完整数据见 `data/species.json`，可通过 `tools/mon_editor.py` 可视化浏览和编辑。

### 初始御三家

| 名称 | 属性 | 特点 | 进化路线 |
|------|------|------|----------|
| 炎喵 | 🔥 火 | 物攻型，速度快，身怀火焰之力 | 炎喵 Lv16 → 烈火猫 Lv36 → 焚焰狮 |
| 蓝蛇 | 💧 水 | 防御型，通体蔚蓝的小水蛇 | 蓝蛇 Lv16 → 江蛟 Lv36 → 覆海龙 |
| 小竹熊 | 🌿 木 | 物攻型，以竹叶为食的竹林小熊 | 小竹熊 Lv15 → 武道熊 Lv35 → 功夫熊师 |

---

## 🛠 编辑器

项目附带可视化编辑器 `tools/mon_editor.py`（tkinter），支持：

- **精灵编辑**：种族值条形图、属性/性别/体型/描述、进化链、技能表
- **技能管理**：技能库增删改
- **数据持久化**：直接读写 `data/species.json` / `data/moves.json`
- **一键打包**：`tools/build_editor.bat` 可编译为独立 exe

---

## 🛠️ 技术栈

| 项目 | 说明 |
|------|------|
| 引擎 | Godot 4.7 |
| 语言 | GDScript 4 |
| 分辨率 | 720×480（放大至 1440×960），pixel_snap 开启 |
| 渲染 | 像素风，NEAREST 采样 |
| 字体 | Microsoft YaHei / 微软雅黑（系统字体） |
| 数据 | JSON（species / moves / items） |
| 素材 | 256×256 PNG（通过 Git LFS 管理） |

---

## 📁 项目结构

```
RPG_Demo/
├── assets/
│   └── sprites/          # 精灵素材（PNG，LFS 管理）
├── data/
│   ├── species.json      # 精灵种族数据（24 只）
│   ├── moves.json        # 技能数据（26 个）
│   └── items.json        # 道具数据
├── scenes/
│   └── main.tscn         # 主场景（场景管理器）
├── scripts/
│   ├── autoload/
│   │   ├── game_state.gd # 全局玩家状态
│   │   └── mon_db.gd     # 精灵/技能数据库 + 公式
│   └── scenes/
│       ├── main.gd           # 场景切换管理
│       ├── starter_scene.gd  # 御三家选择
│       ├── world_scene.gd    # 大地图
│       └── battle_scene.gd   # 战斗系统
├── tools/
│   ├── mon_editor.py     # 可视化编辑器
│   └── build_editor.bat  # 编辑器打包脚本
├── README.md
├── CHANGELOG.md
└── project.godot
```

---

## 🚀 运行方法

1. 安装 [Godot 4.7](https://godotengine.org/download/)
2. 克隆本仓库：
   ```bash
   git clone <repo-url>
   ```
3. 在 Godot 中打开 `RPG_Demo/project.godot`
4. 点击运行（F5）

### 运行编辑器

```bash
python -X utf8 tools/mon_editor.py
```

### 添加自定义精灵图片

将 PNG 文件放入 `assets/sprites/`，命名格式：
- `{精灵名}_front.png` — 敌方（正面）
- `{精灵名}_back.png` — 我方（背面）

例：`炎喵_front.png`，`炎喵_back.png`

---

## 📊 属性克制表（18属性）

```
空 火 水 木 雷 冰 格 毒 土 风 灵 虫 岩 鬼 龙 暗 钢 仙
```

完整克制关系见 `scripts/autoload/mon_db.gd`（type_chart 字典）。

---

## 📝 开发计划

- [ ] 地图扩展（多地图 + 传送点）
- [ ] NPC 训练师对战
- [ ] 道馆系统（道馆主 + 徽章）
- [ ] 存档/读档
- [ ] 音效与背景音乐
- [ ] 更多精灵与技能

---

## 📄 许可证

本项目基于 [MIT License](./LICENSE) 开源。

---

*华灵大陆·起始草原，你的旅途从这里开始。*
