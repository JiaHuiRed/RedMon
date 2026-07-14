// 19 属性克制表 —— 必须与 scripts/autoload/mon_db.gd 的 _type_chart 保持一致
// （已逐条核对过，2026-07-14）。以后改动游戏侧克制表时记得同步这里。
// 结构：{ 攻击方: { 防御方: 倍率 } }
export const TYPE_CHART = {
  "空": { "岩": 0.6, "钢": 0.6, "鬼": 0.0 },
  "火": { "木": 1.5, "冰": 1.5, "虫": 1.5, "钢": 1.5, "火": 0.6, "水": 0.6, "岩": 0.6, "龙": 0.6 },
  "水": { "火": 1.5, "土": 1.5, "岩": 1.5, "水": 0.6, "木": 0.6, "龙": 0.6 },
  "木": { "水": 1.5, "土": 1.5, "岩": 1.5, "火": 0.6, "木": 0.6, "毒": 0.6, "风": 0.6, "虫": 0.6, "龙": 0.6, "钢": 0.6 },
  "雷": { "水": 1.5, "风": 1.5, "雷": 0.6, "木": 0.6, "龙": 0.6, "土": 0.0 },
  "冰": { "木": 1.5, "土": 1.5, "风": 1.5, "龙": 1.5, "火": 0.6, "水": 0.6, "冰": 0.6, "钢": 0.6 },
  "格": { "空": 1.5, "冰": 1.5, "岩": 1.5, "暗": 1.5, "钢": 1.5, "毒": 0.6, "风": 0.6, "灵": 0.6, "虫": 0.6, "仙": 0.6, "鬼": 0.0 },
  "毒": { "木": 1.5, "仙": 1.5, "毒": 0.6, "土": 0.6, "岩": 0.6, "鬼": 0.6, "钢": 0.0 },
  "土": { "火": 1.5, "雷": 1.5, "毒": 1.5, "岩": 1.5, "钢": 1.5, "木": 0.6, "虫": 0.6, "风": 0.0 },
  "风": { "木": 1.5, "格": 1.5, "虫": 1.5, "雷": 0.6, "岩": 0.6, "钢": 0.6 },
  "灵": { "格": 1.5, "毒": 1.5, "灵": 0.6, "钢": 0.6 },
  "虫": { "木": 1.5, "灵": 1.5, "暗": 1.5, "仙": 1.5, "火": 0.6, "格": 0.6, "风": 0.6, "鬼": 0.6, "钢": 0.6 },
  "岩": { "火": 1.5, "冰": 1.5, "风": 1.5, "虫": 1.5, "格": 0.6, "土": 0.6, "钢": 0.6 },
  "鬼": { "灵": 1.5, "鬼": 1.5, "暗": 0.6, "空": 0.0 },
  "龙": { "龙": 1.5, "钢": 0.6, "仙": 0.0 },
  "暗": { "灵": 1.5, "鬼": 1.5, "光": 1.5, "格": 0.6, "暗": 0.6, "仙": 0.6 },
  "钢": { "冰": 1.5, "岩": 1.5, "仙": 1.5, "火": 0.6, "水": 0.6, "雷": 0.6, "钢": 0.6 },
  "仙": { "格": 1.5, "龙": 1.5, "暗": 1.5, "火": 0.6, "毒": 0.6, "钢": 0.6 },
  "光": { "鬼": 1.5, "虫": 1.5, "冰": 1.5, "暗": 1.5, "火": 0.6, "钢": 0.6, "光": 0.6, "水": 0.6, "木": 0.0 },
};

export const ALL_TYPES = Object.keys(TYPE_CHART);

// 避免连乘产生的浮点误差（如 0.6*1.5 -> 0.8999999999999999），对齐 Python 的 %g 格式化
function fmt(n) {
  return parseFloat(n.toPrecision(6)).toString();
}

// 计算 t1(/t2) 这个属性组合的克制关系：
// - offense: 主动攻击时，己方属性打各防御属性的最高倍率（克制 >1 / 效果不佳 <1 / 无效 0）
// - defense: 被动挨打时，各攻击属性打己方的倍率（弱点 >1 / 抵抗 <1 / 免疫 0）
export function computeMatchup(t1, t2) {
  const offense = { superEffective: [], notEffective: [], noEffect: [] };
  const defense = { weak: [], resist: [], immune: [] };
  if (!t1) return { offense, defense };

  const atkTypes = [t1, t2].filter(Boolean);
  for (const defType of ALL_TYPES) {
    const best = Math.max(...atkTypes.map(at => TYPE_CHART[at]?.[defType] ?? 1.0));
    if (best === 0) offense.noEffect.push([defType, "0"]);
    else if (best > 1) offense.superEffective.push([defType, `${fmt(best)}x`]);
    else if (best < 1) offense.notEffective.push([defType, `${fmt(best)}x`]);
  }

  for (const atk of ALL_TYPES) {
    const chart = TYPE_CHART[atk] || {};
    let mult = chart[t1] ?? 1.0;
    if (t2) mult *= chart[t2] ?? 1.0;
    if (mult === 0) defense.immune.push([atk, "0"]);
    else if (mult > 1) defense.weak.push([atk, `${fmt(mult)}x`]);
    else if (mult < 1) defense.resist.push([atk, `${fmt(mult)}x`]);
  }

  return { offense, defense };
}
