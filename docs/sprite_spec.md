# RedMon 精灵图规格表
# 文件放到对应路径后，游戏会自动优先加载，代码占位图作为兜底
#
# 260723 Red：这是项目早期（Phase 1/2 规划阶段）写的素材清单，跟现在实际的资产组织方式
# 已经有系统性偏差，核对过路径/命名规则的地方几乎全部对不上，仅供了解历史规划思路，
# **不要按这份文档的路径/命名去找或存放文件**。实际情况：
#   - 命名**不带下划线**（如"炎喵front.png"，不是文档里写的"炎喵_front.png"），
#     跟 design_guide.md 第8节"Sprite命名"约定一致，那份文档是当前权威来源
#   - 角色立绘/行走图（教授、主角、劲敌、道馆主等）统一放在 assets/npc/，
#     不是本文档"二、角色立绘"写的 assets/portraits/、"三、大地图行走图"写的
#     assets/overworld/ ——这两个目录在当前 assets/ 树里根本不存在
#   - 行走图是一张网格 spritesheet（如"男主walk_sheet.png"），不是本文档设想的
#     "每方向独立文件"结构
#   - "四、UI图标"里的精灵球图标早就不存在——世界观里精灵球已被替换成"精灵葫芦"，
#     实际图标在 assets/ui/items/精灵葫芦.png
#   - "一、战斗精灵"举例的"绿毛虫/石偶/野鼠灵"这几个物种名在当前 data/species.json
#     里也已经不存在了，是更早期版本的占位命名
# 以下原文保留作历史记录，不再维护：

# ============================================================
# 一、战斗精灵（最高优先级）
# ============================================================

# 路径规则：res://assets/sprites/<名称>_front.png / _back.png

battle_sprites:

  # 御三家 — 战斗中玩家方显示背面，敌方/野生显示正面
  starters:
    - name: 炎喵
      front: assets/sprites/炎喵_front.png   # 规格：96×96，透明背景
      back:  assets/sprites/炎喵_back.png    # 规格：96×96，透明背景
      priority: 最高

    - name: 蓝蛇
      front: assets/sprites/蓝蛇_front.png
      back:  assets/sprites/蓝蛇_back.png
      priority: 最高

    - name: 小竹熊
      front: assets/sprites/小竹熊_front.png
      back:  assets/sprites/小竹熊_back.png
      priority: 最高

  # 野生精灵 — 只需正面（战斗敌方）
  wild_mons:
    - name: 绿毛虫
      front: assets/sprites/绿毛虫_front.png  # 规格：96×96，透明背景
      priority: 高

    - name: 石偶
      front: assets/sprites/石偶_front.png
      priority: 高

    - name: 野鼠灵
      front: assets/sprites/野鼠灵_front.png
      priority: 高

# ============================================================
# 二、角色立绘（选择场景/对话框用）
# ============================================================

portraits:

  - name: 奥克博士
    path: assets/sprites/professor.png
    size: 80×120（或更大等比缩放）
    用途: 御三家选择场景左侧
    priority: 中
    note: 正面站立，白大褂，灰白乱发，持平板，无背景

  - name: 主角_男
    path: assets/portraits/hero_m.png
    size: 80×120
    用途: 对话框/存档界面（Phase 2）
    priority: 低

  - name: 主角_女
    path: assets/portraits/hero_f.png
    size: 80×120
    用途: 同上
    priority: 低

  - name: 劲敌_女
    path: assets/portraits/rival_f.png
    size: 80×120
    用途: 对战前对话（Phase 2）
    priority: 低

# ============================================================
# 三、大地图行走图（过场/世界地图）
# ============================================================

overworld_sprites:

  note: >
    GBA风格行走图：每方向3帧（停止/左脚/右脚），4方向 = 12帧
    拼成一张 spritesheet：48×96（每帧16×24）
    当前代码用16×20静态单帧，升级行走动画时替换

  - name: 主角_男_行走
    path: assets/overworld/hero_m_walk.png
    size: 48×96（spritesheet，4行×3列）
    priority: 中（有静态占位可先跑通）

  - name: 主角_女_行走
    path: assets/overworld/hero_f_walk.png
    size: 48×96
    priority: 低（Phase 2，性别选择实装后）

  - name: 奥克博士_站立
    path: assets/overworld/professor_stand.png
    size: 16×24，单帧
    priority: 低（NPC实装时）

  - name: 劲敌_行走
    path: assets/overworld/rival_walk.png
    size: 48×96
    priority: 低（Phase 2）

# ============================================================
# 四、UI 图标（可选，当前用代码绘制）
# ============================================================

ui_icons:

  - name: 精灵球图标
    path: assets/ui/pokeball.png
    size: 16×16
    priority: 低

  - name: 属性徽章（火/水/木/虫/土/无）
    path: assets/ui/type_<属性>.png
    size: 32×12
    priority: 低

# ============================================================
# 五、Gemini 生图规范（260629 更新）
# ============================================================

# ── 生图原则 ─────────────────────────────────────────────────
# 1. 每次只生成【一张图】——不要在同一图中并排正面+背面，
#    否则会被裁剪成左半/右半，像素比例变形。
# 2. 正面图：纯白背景，精灵完整居中，单张 512×512 输出。
# 3. 背面图：精灵背面，身体朝右侧偏转约30°（战场上玩家精灵
#    在左下，背影应面向右上方的敌方）；纯白背景，512×512。
# 4. 生成后由脚本去白底、裁内容边框、填透明 padding 至 3:4
#    比例，再 resize 到目标尺寸，不手动裁剪。
# ──────────────────────────────────────────────────────────────

prompt_templates:

  pokemon_front: >
    宝可梦火红风格像素艺术，[精灵名称及特征描述]，
    正面站立战斗姿态，纯白色背景，单张图，完整居中，
    精灵全身可见（头顶不截断、脚底不截断），
    像素艺术风格，简洁配色，Q版可爱，无抗锯齿。

  pokemon_back: >
    宝可梦火红风格像素艺术，[精灵名称及特征描述]，
    背面视角战斗姿态，身体朝右偏转约30°（面向右上方），
    纯白色背景，单张图，完整居中，
    精灵全身可见（头顶不截断、脚底不截断），
    像素艺术风格，简洁配色，Q版可爱，无抗锯齿。

  professor_portrait: >
    GBA Pokemon style NPC portrait, elderly male professor,
    white lab coat, messy grey hair, grey beard, holding tablet,
    front-facing, pixel art style, 80x120 pixels, transparent background,
    warm friendly expression

  hero_male: >
    GBA Pokemon FireRed style trainer sprite, male protagonist,
    red baseball cap, dark hair, red open jacket, black t-shirt,
    black pants, red sneakers, front-facing battle pose,
    96x96 pixels, transparent background, pixel art

  hero_female: >
    GBA Pokemon style trainer sprite, female protagonist,
    red cap, long dark hair, black crop top, red jacket,
    black shorts, black stockings, red sneakers,
    front-facing pose, 96x96 pixels, transparent background, pixel art

  rival_female: >
    GBA Pokemon style trainer sprite, female rival character,
    pink baseball cap, long wavy dark hair, white shirt,
    pink skirt, white thigh-high socks, pink shoes,
    confident pose, 96x96 pixels, transparent background, pixel art

# ============================================================
# 六、Phase 1 最小可用素材清单（先做这些就能跑完整流程）
# ============================================================

phase1_minimum:
  - 炎喵_front.png   # 选择卡+敌方野生炎喵
  - 炎喵_back.png    # 玩家战斗方
  - 蓝蛇_front.png
  - 蓝蛇_back.png
  - 小竹熊_front.png
  - 小竹熊_back.png
  - 绿毛虫_front.png  # 最常见野生
  - 石偶_front.png
  - 野鼠灵_front.png
  # 教授和主角有代码占位，暂时不影响流程
