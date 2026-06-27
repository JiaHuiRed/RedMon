"""Add missing monsters to species.json — one-time script"""
import json

path = 'D:/AI/Game/RPG_Demo/data/species.json'
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)

# Fix: 灵芽儿 evolution chain: 灵芽儿 → 大树鲁特 → 古檀灵
if '灵芽儿' in data:
    la = data['灵芽儿']
    la['evolutions'] = [{"into": "大树鲁特", "level": 25}]
    la['evolves_into'] = "大树鲁特"
    la['evolve_level'] = 25

# 粉粉丘 → 霆啸
if '粉粉丘' in data:
    pp = data['粉粉丘']
    pp['evolutions'] = [{"into": "霆啸", "level": 36}]
    pp['evolves_into'] = "霆啸"
    pp['evolve_level'] = 36

new_monsters = {
    # ====== 火猫系（祥云火猫 → 烈云猫兽 → 焱纹虎）======
    "祥云火猫": {
        "id": 85, "name": "祥云火猫",
        "type1": "火", "type2": "",
        "base": {"hp": 45, "atk": 50, "def": 35, "sp_atk": 55, "sp_def": 40, "spd": 60},
        "catch_rate": 120, "exp_yield": 62, "growth_rate": "中速",
        "desc": "脚踏祥云的小火猫，跳跃时尾巴拖出火焰云纹。性格顽皮，喜欢在屋顶上追逐火蝶。",
        "design_origin": "瑞兽火猫 + 祥云纹",
        "tier": "凡", "role": "快攻手",
        "gender_ratio": "50/50", "height": "0.4", "weight": "5.5",
        "evolutions": [{"into": "烈云猫兽", "level": 22}],
        "evolves_into": "烈云猫兽", "evolve_level": 22,
        "learnset": {
            "1": ["撞击", "火花"], "5": ["吼叫"], "9": ["烟雾弹"],
            "13": ["焰喷"], "17": ["电光一闪"], "21": ["撕咬"]
        }
    },
    "烈云猫兽": {
        "id": 86, "name": "烈云猫兽",
        "type1": "火", "type2": "风",
        "base": {"hp": 65, "atk": 75, "def": 55, "sp_atk": 80, "sp_def": 60, "spd": 85},
        "catch_rate": 60, "exp_yield": 148, "growth_rate": "中速",
        "desc": "驾驭烈焰与狂风的猫兽，奔跑时身周卷起火焰旋风。据说它出现的地方，天空都会染上橘红色。",
        "design_origin": "云豹 + 火焰旋风",
        "tier": "灵", "role": "混攻手",
        "gender_ratio": "50/50", "height": "1.1", "weight": "28.0",
        "evolutions": [{"into": "焱纹虎", "level": 38}],
        "evolves_into": "焱纹虎", "evolve_level": 38,
        "learnset": {
            "1": ["撞击", "火花", "吼叫"], "9": ["烟雾弹"],
            "13": ["焰喷"], "17": ["电光一闪"], "22": ["空气斩"],
            "26": ["撕咬"], "30": ["啄钻"], "34": ["猛撞"]
        }
    },
    "焱纹虎": {
        "id": 87, "name": "焱纹虎",
        "type1": "火", "type2": "风",
        "base": {"hp": 85, "atk": 105, "def": 70, "sp_atk": 100, "sp_def": 75, "spd": 110},
        "catch_rate": 45, "exp_yield": 240, "growth_rate": "中速",
        "desc": "身披焱形虎纹的烈风猛虎，一跃可腾空百丈。虎啸时火焰虎纹绽放光芒，方圆百里草木皆焚。",
        "design_origin": "白虎 + 焱字纹 + 风火轮",
        "tier": "玄", "role": "快攻手",
        "gender_ratio": "50/50", "height": "2.0", "weight": "95.0",
        "evolutions": [],
        "learnset": {
            "1": ["撞击", "火花", "吼叫"], "9": ["烟雾弹"],
            "13": ["焰喷"], "17": ["电光一闪"], "22": ["空气斩"],
            "26": ["撕咬"], "30": ["啄钻"],
            "38": ["勇鸟猛攻"], "44": ["暴风"], "50": ["大闹一番"]
        }
    },

    # ====== 铎狐 → 钺霄（钢/灵 → 钢/风）======
    "铎狐": {
        "id": 88, "name": "铎狐",
        "type1": "钢", "type2": "灵",
        "base": {"hp": 60, "atk": 50, "def": 65, "sp_atk": 75, "sp_def": 70, "spd": 65},
        "catch_rate": 75, "exp_yield": 145, "growth_rate": "中速",
        "desc": "额间悬一枚铜铎的灵狐，铎声可安抚魂灵、驱散邪祟。传说是古代巫祝的守护精灵。",
        "design_origin": "九尾狐 + 青铜铎铃 + 巫祝",
        "tier": "灵", "role": "特攻手",
        "gender_ratio": "50/50", "height": "0.8", "weight": "15.0",
        "evolutions": [{"into": "钺霄", "level": 36}],
        "evolves_into": "钺霄", "evolve_level": 36,
        "learnset": {
            "1": ["撞击", "金属爪"], "7": ["瞪眼"],
            "12": ["金属音"], "18": ["铁头"],
            "24": ["钢翼"], "30": ["加农光炮"]
        }
    },
    "钺霄": {
        "id": 89, "name": "钺霄",
        "type1": "钢", "type2": "风",
        "base": {"hp": 80, "atk": 120, "def": 95, "sp_atk": 55, "sp_def": 70, "spd": 105},
        "catch_rate": 45, "exp_yield": 230, "growth_rate": "中速",
        "desc": "铎狐觉醒天钺之力后化形，手持天钺翱翔九霄。翅刃削铁如泥，一钺劈下妖邪立散。",
        "design_origin": "金翅大鹏 + 青铜钺 + 天兵",
        "tier": "玄", "role": "物攻手",
        "gender_ratio": "50/50", "height": "1.9", "weight": "68.0",
        "evolutions": [],
        "learnset": {
            "1": ["撞击", "金属爪", "瞪眼"],
            "12": ["金属音"], "18": ["铁头"], "24": ["钢翼"],
            "30": ["加农光炮"], "36": ["空气斩"],
            "40": ["巨兽斩"], "46": ["勇鸟猛攻"], "52": ["画龙点睛"]
        }
    },

    # ====== 炎凰（火/仙，神品）======
    "炎凰": {
        "id": 90, "name": "炎凰",
        "type1": "火", "type2": "仙",
        "base": {"hp": 100, "atk": 70, "def": 80, "sp_atk": 135, "sp_def": 110, "spd": 115},
        "catch_rate": 3, "exp_yield": 306, "growth_rate": "缓慢",
        "desc": "浴火重生的不死凤凰，羽翼流转仙火霞光。每五百年涅槃一次，新生之时百花齐放、万物复苏。",
        "design_origin": "凤凰 + 涅槃 + 仙火",
        "tier": "神", "role": "特攻手",
        "gender_ratio": "0/100", "height": "2.5", "weight": "48.0",
        "evolutions": [],
        "learnset": {
            "1": ["火花", "空气斩"], "10": ["焰喷"],
            "20": ["归天之翼"], "30": ["暴风"],
            "40": ["大闹一番"], "50": ["勇鸟猛攻"], "60": ["神鸟猛击"]
        }
    },

    # ====== 霆啸（雷，粉粉丘进化）======
    "霆啸": {
        "id": 91, "name": "霆啸",
        "type1": "雷", "type2": "",
        "base": {"hp": 90, "atk": 115, "def": 60, "sp_atk": 118, "sp_def": 75, "spd": 112},
        "catch_rate": 45, "exp_yield": 236, "growth_rate": "中速",
        "desc": "雷云化形的霆兽，怒吼时万雷齐鸣天地变色。雷原霸主，一声长啸便能劈开山岳。",
        "design_origin": "雷兽 + 霆 + 啸天犬",
        "tier": "玄", "role": "混攻手",
        "gender_ratio": "50/50", "height": "1.8", "weight": "62.0",
        "evolutions": [],
        "learnset": {
            "1": ["撞击", "电光一闪"], "10": ["撕咬"],
            "18": ["猛撞"], "26": ["吼叫"],
            "34": ["大闹一番"], "42": ["破坏光线"]
        }
    },

    # ====== 蛛系（蛛优优 → 小蛛妖 → 蛛灵儿 → 盘丝妖后）======
    "蛛优优": {
        "id": 92, "name": "蛛优优",
        "type1": "虫", "type2": "毒",
        "base": {"hp": 35, "atk": 40, "def": 35, "sp_atk": 30, "sp_def": 35, "spd": 45},
        "catch_rate": 200, "exp_yield": 45, "growth_rate": "快速",
        "desc": "刚出生的幼蛛，圆滚滚的身体缀满彩色斑点。喜欢跟在母蛛身后摇摇晃晃地学织网。",
        "design_origin": "幼蛛 + 可爱蜘蛛",
        "tier": "凡", "role": "均衡",
        "gender_ratio": "50/50", "height": "0.2", "weight": "1.2",
        "evolutions": [{"into": "小蛛妖", "level": 12}],
        "evolves_into": "小蛛妖", "evolve_level": 12,
        "learnset": {
            "1": ["撞击", "吐丝"], "4": ["乱抓"], "8": ["啃咬"]
        }
    },
    "小蛛妖": {
        "id": 93, "name": "小蛛妖",
        "type1": "虫", "type2": "毒",
        "base": {"hp": 45, "atk": 55, "def": 40, "sp_atk": 45, "sp_def": 40, "spd": 60},
        "catch_rate": 150, "exp_yield": 75, "growth_rate": "快速",
        "desc": "织网捕虫的小妖蛛，丝线含有微弱毒素。虽然体型小，编织的蛛网却精巧异常。",
        "design_origin": "蜘蛛精 + 蛛网",
        "tier": "凡", "role": "快攻手",
        "gender_ratio": "50/50", "height": "0.4", "weight": "4.0",
        "evolutions": [{"into": "蛛灵儿", "level": 24}],
        "evolves_into": "蛛灵儿", "evolve_level": 24,
        "learnset": {
            "1": ["撞击", "吐丝"], "4": ["乱抓"],
            "8": ["啃咬"], "12": ["撕咬"],
            "16": ["猛撞"], "20": ["乱抓"]
        }
    },
    "蛛灵儿": {
        "id": 94, "name": "蛛灵儿",
        "type1": "虫", "type2": "毒",
        "base": {"hp": 60, "atk": 70, "def": 55, "sp_atk": 75, "sp_def": 60, "spd": 80},
        "catch_rate": 75, "exp_yield": 152, "growth_rate": "快速",
        "desc": "半人形的蛛妖，六臂能同时编织六张毒网。已有灵智，善于以丝线布阵困敌。",
        "design_origin": "蜘蛛精 + 织女",
        "tier": "灵", "role": "快攻手",
        "gender_ratio": "12.5/87.5", "height": "0.9", "weight": "18.0",
        "evolutions": [{"into": "盘丝妖后", "level": 38}],
        "evolves_into": "盘丝妖后", "evolve_level": 38,
        "learnset": {
            "1": ["撞击", "吐丝", "乱抓"],
            "8": ["啃咬"], "12": ["撕咬"],
            "16": ["猛撞"], "24": ["大闹一番"],
            "30": ["撕咬"], "34": ["猛撞"]
        }
    },
    "盘丝妖后": {
        "id": 95, "name": "盘丝妖后",
        "type1": "虫", "type2": "毒",
        "base": {"hp": 80, "atk": 80, "def": 65, "sp_atk": 115, "sp_def": 80, "spd": 105},
        "catch_rate": 45, "exp_yield": 248, "growth_rate": "快速",
        "desc": "盘丝洞的妖后，千丝万缕皆含剧毒。人形妖姿倾国倾城，猎物一旦触网便再无生路。",
        "design_origin": "盘丝大仙 + 蜘蛛精 + 西游记",
        "tier": "神", "role": "特攻手",
        "gender_ratio": "0/100", "height": "1.6", "weight": "35.0",
        "evolutions": [],
        "learnset": {
            "1": ["撞击", "吐丝", "乱抓"],
            "8": ["啃咬"], "12": ["撕咬"], "16": ["猛撞"],
            "24": ["大闹一番"], "32": ["撕咬"],
            "38": ["破坏光线"], "44": ["大闹一番"]
        }
    },

    # ====== 猴系（小顽猴 → 持棍猿 → 猿圣）======
    "小顽猴": {
        "id": 103, "name": "小顽猴",
        "type1": "格", "type2": "",
        "base": {"hp": 45, "atk": 55, "def": 30, "sp_atk": 35, "sp_def": 30, "spd": 70},
        "catch_rate": 120, "exp_yield": 58, "growth_rate": "中速",
        "desc": "活泼好动的小猴子，整日在山林间上蹿下跳。天生好斗，喜欢和同伴比试拳脚。",
        "design_origin": "灵猴 + 猿猴",
        "tier": "凡", "role": "快攻手",
        "gender_ratio": "50/50", "height": "0.5", "weight": "8.0",
        "evolutions": [{"into": "持棍猿", "level": 20}],
        "evolves_into": "持棍猿", "evolve_level": 20,
        "learnset": {
            "1": ["撞击", "瞪眼"], "5": ["乱抓"],
            "9": ["电光一闪"], "13": ["撕咬"], "17": ["猛撞"]
        }
    },
    "持棍猿": {
        "id": 104, "name": "持棍猿",
        "type1": "格", "type2": "",
        "base": {"hp": 65, "atk": 82, "def": 50, "sp_atk": 48, "sp_def": 50, "spd": 90},
        "catch_rate": 60, "exp_yield": 142, "growth_rate": "中速",
        "desc": "悟得棍术的战猿，手持石棍如风车般旋转攻击。身法灵活以速制敌，已有武者之姿。",
        "design_origin": "孙悟空 + 猿猴棍术",
        "tier": "灵", "role": "物攻手",
        "gender_ratio": "50/50", "height": "1.2", "weight": "32.0",
        "evolutions": [{"into": "猿圣", "level": 38}],
        "evolves_into": "猿圣", "evolve_level": 38,
        "learnset": {
            "1": ["撞击", "瞪眼", "乱抓"],
            "9": ["电光一闪"], "13": ["撕咬"], "17": ["猛撞"],
            "20": ["劈开"], "25": ["神速"], "30": ["大闹一番"]
        }
    },
    "猿圣": {
        "id": 105, "name": "猿圣",
        "type1": "格", "type2": "龙",
        "base": {"hp": 90, "atk": 120, "def": 75, "sp_atk": 65, "sp_def": 70, "spd": 115},
        "catch_rate": 45, "exp_yield": 252, "growth_rate": "中速",
        "desc": "修炼成圣的齐天大猿，金棍横扫可碎山裂地。龙血觉醒后获得不灭战意，被尊为武道至尊。",
        "design_origin": "齐天大圣 + 斗战胜佛 + 龙",
        "tier": "地", "role": "物攻手",
        "gender_ratio": "87.5/12.5", "height": "1.8", "weight": "72.0",
        "evolutions": [],
        "learnset": {
            "1": ["撞击", "瞪眼", "乱抓"],
            "9": ["电光一闪"], "13": ["撕咬"], "17": ["猛撞"],
            "20": ["劈开"], "25": ["神速"], "30": ["大闹一番"],
            "38": ["多属性攻击"], "44": ["破坏光线"], "50": ["大闹一番"]
        }
    },

    # ====== 蚩极（格/暗，地品准神）======
    "蚩极": {
        "id": 106, "name": "蚩极",
        "type1": "格", "type2": "暗",
        "base": {"hp": 95, "atk": 130, "def": 90, "sp_atk": 60, "sp_def": 80, "spd": 100},
        "catch_rate": 15, "exp_yield": 270, "growth_rate": "缓慢",
        "desc": "战神蚩尤之魂所化，铜头铁额身披兽皮战甲。战意燃起时周身黑雾弥漫，百步之内寸草不生。",
        "design_origin": "蚩尤 + 战神 + 铜头铁额",
        "tier": "地", "role": "物攻手",
        "gender_ratio": "100/0", "height": "2.2", "weight": "145.0",
        "evolutions": [],
        "learnset": {
            "1": ["撞击", "瞪眼"], "10": ["撕咬"],
            "20": ["猛撞"], "30": ["劈开"],
            "40": ["大闹一番"], "50": ["破坏光线"], "60": ["多属性攻击"]
        }
    },

    # ====== 玄溟（水/暗，地品准神）======
    "玄溟": {
        "id": 107, "name": "玄溟",
        "type1": "水", "type2": "暗",
        "base": {"hp": 100, "atk": 75, "def": 85, "sp_atk": 125, "sp_def": 95, "spd": 75},
        "catch_rate": 15, "exp_yield": 270, "growth_rate": "缓慢",
        "desc": "沉眠深渊万载的幽海之主，身躯蜿蜒如墨色长河。苏醒时海底翻涌黑潮，万物噤声。",
        "design_origin": "玄武 + 溟海 + 深渊巨蛇",
        "tier": "地", "role": "特攻手",
        "gender_ratio": "100/0", "height": "8.5", "weight": "520.0",
        "evolutions": [],
        "learnset": {
            "1": ["撞击", "瞪眼"], "10": ["撕咬"],
            "20": ["猛撞"], "30": ["冲浪"],
            "40": ["破坏光线"], "50": ["大闹一番"]
        }
    },

    # ====== 幽魂系（幽荧 → 夜幽魂 → 墟梦魇）======
    "幽荧": {
        "id": 108, "name": "幽荧",
        "type1": "鬼", "type2": "",
        "base": {"hp": 35, "atk": 25, "def": 30, "sp_atk": 55, "sp_def": 45, "spd": 60},
        "catch_rate": 150, "exp_yield": 55, "growth_rate": "中速",
        "desc": "夜间漂浮的幽绿光球，像是鬼火凝结成形。引诱迷路旅人，其实只是想找玩伴。",
        "design_origin": "鬼火 + 磷火 + 荧",
        "tier": "凡", "role": "特攻手",
        "gender_ratio": "50/50", "height": "0.3", "weight": "0.5",
        "evolutions": [{"into": "夜幽魂", "level": 25}],
        "evolves_into": "夜幽魂", "evolve_level": 25,
        "learnset": {
            "1": ["撞击", "瞪眼"], "6": ["乱抓"],
            "11": ["撕咬"], "16": ["猛撞"], "21": ["大闹一番"]
        }
    },
    "夜幽魂": {
        "id": 109, "name": "夜幽魂",
        "type1": "鬼", "type2": "暗",
        "base": {"hp": 55, "atk": 40, "def": 50, "sp_atk": 85, "sp_def": 70, "spd": 80},
        "catch_rate": 75, "exp_yield": 152, "growth_rate": "中速",
        "desc": "吞噬月光的幽暗魂体，漆黑斗篷下闪烁猩红双眸。被它盯上的人会连做七夜噩梦。",
        "design_origin": "夜游神 + 幽灵 + 暗影",
        "tier": "灵", "role": "特攻手",
        "gender_ratio": "50/50", "height": "1.0", "weight": "5.0",
        "evolutions": [{"into": "墟梦魇", "level": 42}],
        "evolves_into": "墟梦魇", "evolve_level": 42,
        "learnset": {
            "1": ["撞击", "瞪眼", "乱抓"],
            "11": ["撕咬"], "16": ["猛撞"],
            "21": ["大闹一番"], "25": ["撕咬"],
            "30": ["猛撞"], "36": ["破坏光线"]
        }
    },
    "墟梦魇": {
        "id": 110, "name": "墟梦魇",
        "type1": "鬼", "type2": "暗",
        "base": {"hp": 75, "atk": 55, "def": 65, "sp_atk": 120, "sp_def": 95, "spd": 100},
        "catch_rate": 45, "exp_yield": 245, "growth_rate": "中速",
        "desc": "废墟中诞生的梦魇之王，编织令人永远无法醒来的噩梦。漆黑身影所过之处连光都被吞噬。",
        "design_origin": "梦魇 + 废墟 + 噩梦之主",
        "tier": "玄", "role": "特攻手",
        "gender_ratio": "50/50", "height": "1.8", "weight": "28.0",
        "evolutions": [],
        "learnset": {
            "1": ["撞击", "瞪眼", "乱抓"],
            "11": ["撕咬"], "16": ["猛撞"],
            "25": ["大闹一番"], "30": ["撕咬"],
            "36": ["破坏光线"], "42": ["大闹一番"]
        }
    },

    # ====== 大树鲁特（灵芽儿 → 大树鲁特 → 古檀灵）======
    "大树鲁特": {
        "id": 111, "name": "大树鲁特",
        "type1": "木", "type2": "灵",
        "base": {"hp": 78, "atk": 52, "def": 62, "sp_atk": 78, "sp_def": 76, "spd": 65},
        "catch_rate": 75, "exp_yield": 145, "growth_rate": "中速",
        "desc": "灵芽成长为参天大树的中间形态，树冠中藏着灵光闪烁的灵核。扎根大地汲取灵气，守护一方森林。",
        "design_origin": "树精 + 灵木 + 守护之树",
        "tier": "灵", "role": "特盾",
        "gender_ratio": "50/50", "height": "1.5", "weight": "45.0",
        "evolutions": [{"into": "古檀灵", "level": 42}],
        "evolves_into": "古檀灵", "evolve_level": 42,
        "learnset": {
            "1": ["撞击", "瞪眼"], "8": ["撕咬"],
            "15": ["猛撞"], "22": ["大闹一番"], "30": ["破坏光线"]
        }
    },

    # ====== 铜角系（铜角幼 → 战甲铜）======
    "铜角幼": {
        "id": 112, "name": "铜角幼",
        "type1": "钢", "type2": "土",
        "base": {"hp": 50, "atk": 55, "def": 60, "sp_atk": 25, "sp_def": 45, "spd": 35},
        "catch_rate": 120, "exp_yield": 60, "growth_rate": "中速",
        "desc": "头生青铜短角的幼兽，出没于古墓废墟周围。身体沾满泥土，但铜角始终闪闪发光。",
        "design_origin": "青铜器 + 犀牛幼崽 + 三星堆",
        "tier": "凡", "role": "物盾",
        "gender_ratio": "50/50", "height": "0.5", "weight": "28.0",
        "evolutions": [{"into": "战甲铜", "level": 30}],
        "evolves_into": "战甲铜", "evolve_level": 30,
        "learnset": {
            "1": ["撞击", "变硬"], "6": ["金属爪"],
            "11": ["瞪眼"], "16": ["铁头"],
            "21": ["石击"], "26": ["铁壁"]
        }
    },
    "战甲铜": {
        "id": 113, "name": "战甲铜",
        "type1": "钢", "type2": "土",
        "base": {"hp": 80, "atk": 95, "def": 110, "sp_atk": 40, "sp_def": 75, "spd": 50},
        "catch_rate": 60, "exp_yield": 195, "growth_rate": "中速",
        "desc": "全身覆盖青铜战甲的重装巨兽，上古将军坐骑化灵而成。践踏大地时铠甲铿锵作响。",
        "design_origin": "青铜重甲 + 战象 + 三星堆铜兽",
        "tier": "玄", "role": "物盾",
        "gender_ratio": "50/50", "height": "2.0", "weight": "350.0",
        "evolutions": [],
        "learnset": {
            "1": ["撞击", "变硬", "金属爪"],
            "11": ["瞪眼"], "16": ["铁头"], "21": ["石击"],
            "26": ["铁壁"], "30": ["地震"],
            "36": ["巨兽斩"], "42": ["铁尾"]
        }
    },
}

data.update(new_monsters)

with open(path, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(f"Done! Total species: {len(data)}")
used_ids = sorted(v.get('id', 0) for v in data.values())
dups = [i for i in used_ids if used_ids.count(i) > 1]
if dups:
    print(f"WARNING: Duplicate IDs: {set(dups)}")
else:
    print("No duplicate IDs")
print(f"ID range: {min(used_ids)}-{max(used_ids)}")

# Verify all evolution targets exist
for name, v in data.items():
    for e in v.get('evolutions', []):
        if e['into'] not in data:
            print(f"BROKEN EVO: {name} -> {e['into']}")
    ei = v.get('evolves_into', '')
    if ei and ei not in data:
        print(f"BROKEN evolves_into: {name} -> {ei}")
