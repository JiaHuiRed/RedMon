# 🐉 RedMon — 红灵

> 一款中国风像素精灵 RPG，基于 Godot 4 构建。

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)
[![Godot 4.7](https://img.shields.io/badge/Godot-4.7-blue.svg)](https://godotengine.org/)
[![Version](https://img.shields.io/badge/version-v0.0.9-green.svg)](./CHANGELOG.md)

---

## 🌏 游戏简介

**红灵**（RedMon）是一款致敬宝可梦火红/叶绿的中国风像素 RPG。

玩家扮演来自华灵大陆起始草原的训练师，从元教授处获得第一只精灵，开始探索、捕捉、对战的旅途。

---

## ✨ 核心特性

- 🐾 **御三家选择** — 焰狐（火）、水蛟（水）、竹灵（木），由元教授赠予
- ⚔️ **回合制战斗** — 火红风格 UI，速度先攻，4 技能选择
- 🗺️ **大地图探索** — 30×20 瓷砖地图，草丛随机遇敌（15%/4步）
- 🧪 **18 属性克制** — 完整宝可梦第六世代属性表，汉化为中文属性名
- 📊 **种族值系统** — 6 维属性（HP/攻击/防御/特攻/特防/速度），含 IV 个体值
- 💫 **状态异常** — 烧伤、中毒、麻痹、睡眠、冰冻，含回合效果
- 📈 **经验与升级** — 3 种成长速度，升级自动习得技能
- 🌀 **进化系统** — 升级触发进化（绿毛虫 Lv7 → 蛹甲）
- 🎯 **捕捉系统** — 精灵球投掷，基于 HP、状态、种族捕获率的概率公式
- 🎒 **道具背包** — 精灵球、回复药、强效回复药，战斗中可使用
- 👥 **多精灵队伍** — 最多 6 只，战斗中可切换，被击倒后强制换场

---

## 🐾 精灵图鉴

| 名称 | 属性 | 特点 |
|------|------|------|
| 焰狐 | 🔥 火 | 速度型，尾巴燃着幽蓝火焰 |
| 水蛟 | 💧 水 | 防御型，能喷强力激流的小蛟龙 |
| 竹灵 | 🌿 木 | 特攻型，以意念操控草木藤蔓 |
| 绿毛虫 | 🐛 虫 | 常见野生，Lv7 进化为蛹甲 |
| 蛹甲 | 🐚 虫 | 绿毛虫进化体，外壳坚硬 |
| 石偶 | 🪨 土 | 防御极高，由山石凝聚灵气而生 |
| 野鼠灵 | 🌀 空 | 速度最快，草丛中穿梭觅食 |

---

## 🛠️ 技术栈

| 项目 | 说明 |
|------|------|
| 引擎 | Godot 4.7 |
| 语言 | GDScript 4 |
| 分辨率 | 720×480（放大至 1440×960），pixel_snap 开启 |
| 渲染 | 像素风，pixel_snap 开启 |
| 字体 | Microsoft YaHei / 微软雅黑（系统字体） |
| 数据 | JSON（species / moves / items） |

---

## 📁 项目结构

```
RPG_Demo/
├── data/
│   ├── species.json      # 精灵种族数据
│   ├── moves.json        # 技能数据
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

### 添加自定义精灵图片

将 PNG 文件放入项目根目录，命名格式：
- `{精灵名}_front.png` — 敌方（正面）
- `{精灵名}_back.png` — 我方（背面）

例：`焰狐_front.png`，`焰狐_back.png`

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
