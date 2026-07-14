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

// 徽章用纯色底 + 按底色亮度自动选黑/白字，取代"半透明底+同色字"的旧方案——
// 后者的文字对比度取决于页面主题背景色，日间模式下雷(黄)、夜间模式下暗/格这类偏暗色系就会看不清；
// 纯色底的文字对比度只取决于徽章自己的颜色，跟主题无关，两种主题下都稳定可读。
export function contrastTextColor(hex) {
  const n = parseInt(hex.replace("#", ""), 16);
  const r = (n >> 16) & 255, g = (n >> 8) & 255, b = n & 255;
  const toLinear = (c) => { c /= 255; return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4); };
  const luminance = 0.2126 * toLinear(r) + 0.7152 * toLinear(g) + 0.0722 * toLinear(b);
  return luminance > 0.45 ? "#1a1b2e" : "#ffffff";
}

export function renderTypeBadge(type) {
  if (!type) return "";
  const color = TYPE_COLORS[type] || "#999";
  return `<span class="type-badge" style="background:${color}; color:${contrastTextColor(color)}">${type}</span>`;
}

export function renderTypeOptions(selected) {
  const types = Object.keys(TYPE_COLORS);
  return types.map(t =>
    `<option value="${t}" ${t === selected ? "selected" : ""}>${t}</option>`
  ).join("");
}

export { TYPE_COLORS };
