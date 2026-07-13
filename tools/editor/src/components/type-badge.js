// 从游戏 mon_db.gd type_colors 复制
const TYPE_COLORS = {
  "空": "#A6A6A6",
  "火": "#F2661A",
  "水": "#337FF2",
  "木": "#33BF40",
  "雷": "#F2D91A",
  "冰": "#99D9F2",
  "格": "#BF401A",
  "毒": "#9933BF",
  "土": "#BF8C33",
  "风": "#8CBFF2",
  "灵": "#E659A6",
  "虫": "#80BF1A",
  "岩": "#B3994D",
  "鬼": "#664DA6",
  "龙": "#4D33E6",
  "暗": "#4D404D",
  "钢": "#B3B3CC",
  "仙": "#F2A6CC",
  "光": "#F2E680",
};

export function renderTypeBadge(type) {
  if (!type) return "";
  const color = TYPE_COLORS[type] || "#999";
  return `<span class="type-badge" style="background:${color}22; color:${color}; border:1px solid ${color}44">${type}</span>`;
}

export function renderTypeOptions(selected) {
  const types = Object.keys(TYPE_COLORS);
  return types.map(t =>
    `<option value="${t}" ${t === selected ? "selected" : ""}>${t}</option>`
  ).join("");
}

export { TYPE_COLORS };
