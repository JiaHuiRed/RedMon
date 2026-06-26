# RedMon 剧情设定框架
# 填写说明：[待填] = 需要你来定；已有内容 = 预设可直接修改

# ============================================================
# 一、世界观
# ============================================================

世界名称: 华灵大陆
世界背景描述: >
  [待填] 用1-3句话描述这个世界的风格和历史背景
  例：东方奇幻大陆，人与精灵共存千年，古代六大精灵神曾拯救世界...

# ============================================================
# 二、地区（分批更新解锁，Phase顺序即解锁顺序）
# ============================================================

regions:

  - phase: 1
    name: 青岚地区       # 可修改
    theme: 草原+小镇，新手区
    cities:
      - name: 翠苗镇     # 起始小镇，可修改
        desc: [待填] 镇子特色/风格（如：靠近大草原的宁静小镇）
      - name: 岚风市     # 第一个正式城市，可修改
        desc: [待填]
      - name: 赤石城     # 第二个城市，可修改
        desc: [待填]
    gyms:
      - city: 岚风市
        leader_name: [待填] 道馆馆主名字
        leader_gender: [待填] 男/女
        leader_personality: [待填] 性格描述
        type: 木系
        badge_name: [待填] 徽章名（如：翠叶徽章）
        team: [待填] 馆主使用的精灵（可留空后续填）
        pre_battle_dialog: [待填] 战前台词
      - city: 赤石城
        leader_name: [待填]
        leader_gender: [待填]
        leader_personality: [待填]
        type: 火系
        badge_name: [待填]
        team: [待填]
        pre_battle_dialog: [待填]
    key_events:
      - "[待填] 青岚地区的主要剧情事件1（如：在遗迹遭遇玄影会）"
      - "[待填] 事件2"
      - "[待填] 事件3（地区结束，前往下一地区的触发）"

  - phase: 2
    name: 昆仑地区       # 可修改
    theme: 山岳+冰雪，古遗迹
    cities:
      - name: [待填]
        desc: [待填]
      - name: [待填]
        desc: [待填]
    gyms:
      - city: [待填]
        leader_name: [待填]
        type: 岩石系
        badge_name: [待填]
        team: [待填]
      - city: [待填]
        leader_name: [待填]
        type: 冰系
        badge_name: [待填]
        team: [待填]
    key_events:
      - "[待填]"
      - "[待填]"

  - phase: 3
    name: 东海地区       # 可修改
    theme: 海域+渔村+港口
    cities:
      - name: [待填]
        desc: [待填]
      - name: [待填]
        desc: [待填]
    gyms:
      - city: [待填]
        leader_name: [待填]
        type: 水系
        badge_name: [待填]
      - city: [待填]
        leader_name: [待填]
        type: [待填]
        badge_name: [待填]
    key_events:
      - "[待填]"

  - phase: 4
    name: 百蛮地区       # 可修改
    theme: 密林+古文明
    cities:
      - name: [待填]
        desc: [待填]
    gyms:
      - leader_name: [待填]
        type: [待填]
      - leader_name: [待填]
        type: [待填]
    key_events:
      - "[待填]"

  - phase: 5
    name: 天都地区       # 终章，可修改
    theme: 华丽皇城，四天王+冠军所在地
    cities:
      - name: 天都城
        desc: [待填]
    elite_four:
      - name: [待填]
        type: [待填]
        personality: [待填]
      - name: [待填]
        type: [待填]
        personality: [待填]
      - name: [待填]
        type: [待填]
        personality: [待填]
      - name: [待填]
        type: [待填]
        personality: [待填]
    champion:
      name: [待填]
      gender: [待填]
      type: [待填] 冠军惯用属性
      personality: [待填]
      backstory: [待填] 冠军的背景故事
      pre_battle_dialog: [待填]

# ============================================================
# 三、主角
# ============================================================

protagonist:
  name_customizable: true    # 玩家自定义名字
  gender_selectable: true    # 玩家选择性别
  age: [待填]                # 建议10-15
  hometown: 翠苗镇           # 可修改
  backstory: >
    [待填] 主角的固定背景故事
    例：父亲是失踪的精灵研究员，为了找到父亲踏上旅途...
  motivation: [待填]         # 出发的动机（个人目标）
  default_boy_name: [待填]   # 玩家没改名时的默认名字（男）
  default_girl_name: [待填]  # 默认名字（女）

# ============================================================
# 四、竞争对手 Rival
# ============================================================

rival:
  name: [待填]
  gender: [待填]
  starter_type_vs_player: >
    克制主角御三家（主角选火→对方选水，以此类推）
  personality: 傲气但不坏，最终成为朋友  # 可修改
  backstory: >
    [待填] rival的背景故事
    例：精灵学院的尖子生，想证明自己比任何人都强...
  first_meeting: >
    [待填] 与主角第一次相遇的场景描述
  key_moments:
    - "[待填] 首次对战（在哪里，什么情况）"
    - "[待填] 中期转折（rival开始改变的契机）"
    - "[待填] 最终关系（成为朋友/盟友的方式）"

# ============================================================
# 五、反派组织：玄影会
# ============================================================

villain_team:
  name: 玄影会             # 可修改
  goal: 寻找并控制传说精灵「鸿蒙」，同时非法走私贩卖稀有精灵
  slogan: [待填]           # 组织口号/信条
  uniform_desc: [待填]     # 制服外观描述

  boss:
    name: 玄渊             # 可修改
    gender: [待填]
    personality: [待填]
    backstory: >
      [待填] boss的动机和背景
      例：曾是知名精灵学者，因某事件走上极端...
    belief: >
      相信控制鸿蒙能让人类超越精灵，建立新秩序  # 可修改

  admins:                  # 3名干部，在不同地区阻挠主角
    - name: [待填]
      gender: [待填]
      personality: [待填]
      region: 青岚地区     # 哪个地区出没
      specialty_type: [待填] 惯用精灵属性
      first_encounter_scene: >
        [待填] 与主角第一次交锋的场景
      defeat_reaction: >
        [待填] 被击败后的台词/反应

    - name: [待填]
      gender: [待填]
      personality: [待填]
      region: 昆仑地区
      specialty_type: [待填]
      first_encounter_scene: "[待填]"
      defeat_reaction: "[待填]"

    - name: [待填]
      gender: [待填]
      personality: [待填]
      region: 东海地区
      specialty_type: [待填]
      first_encounter_scene: "[待填]"
      defeat_reaction: "[待填]"

# ============================================================
# 六、传说精灵
# ============================================================

legendaries:

  - name: 鸿蒙             # 主传说，可修改
    type: 混沌              # 特殊属性，无克制无弱点
    appearance: >
      [待填] 外观描述
      预设：中国龙形态，融合阴阳鱼元素，黑白双色...
    lore: >
      [待填] 传说故事
      预设：华灵大陆创世之龙，沉睡于天都深处遗迹...
    obtainable: true        # 主线结束后可捕获
    obtain_method: "[待填] 如何获得（击败boss后，在遗迹深处）"

  - name: [待填]            # 可选：次级传说精灵（可留空）
    type: [待填]
    appearance: "[待填]"
    lore: "[待填]"

# ============================================================
# 七、重要NPC
# ============================================================

npcs:

  - name: 陈教授
    role: 精灵研究者，给予御三家
    location: 翠苗镇
    personality: [待填] 性格描述
    backstory: >
      [待填] 教授的背景
      例：与主角父亲是旧友，托付精灵图鉴任务有特殊原因...
    key_role_in_story: "[待填] 在主线中的额外作用（如果有）"

  - name: [待填]            # 可添加更多重要NPC
    role: [待填]
    location: [待填]
    personality: [待填]
    backstory: "[待填]"

# ============================================================
# 八、主线剧情大纲（分Phase填写）
# ============================================================

story_outline:

  prologue: >
    [待填] 序章：主角在翠苗镇的日常，触发事件（如：野生精灵闯入镇子？
    陈教授紧急招募助手？），推动主角去找陈教授领取御三家

  phase1_story: >
    [待填] 青岚地区主线（3-5个关键事件，串联道馆挑战与反派初登场）

  phase2_story: >
    [待填] 昆仑地区主线

  phase3_story: >
    [待填] 东海地区主线

  phase4_story: >
    [待填] 百蛮地区主线

  phase5_story: >
    [待填] 终章：天都决战，揭开鸿蒙真相，击败玄影会boss，挑战四天王冠军

  epilogue: >
    [待填] 尾声：成为冠军后的世界变化，rival的去向，可选：鸿蒙的处置

# ============================================================
# 九、其他设定（选填）
# ============================================================

misc:
  currency_name: 灵币      # 游戏内货币名称，可修改
  pokemart_name: 精灵商会  # 商店名称，可修改
  pokecenter_name: 灵疗所  # 精灵中心名称，可修改
  professor_gift_item: "[待填] 陈教授除御三家外给予的初始道具"
  rival_first_mon_name: "[待填] rival的第一只精灵名（克制主角御三家）"
  additional_notes: >
    [待填] 其他你想加入的设定、灵感、特殊机制等
