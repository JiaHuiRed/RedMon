const MAX_STAT = 255;
const STAT_LABELS = {
  hp: "HP", atk: "ATK", def: "DEF",
  spatk: "SP.ATK", spdef: "SP.DEF", spd: "SPD"
};
const STAT_COLORS = {
  hp: "#FF5959", atk: "#F5AC78", def: "#FAE078",
  spatk: "#9DB7F5", spdef: "#A7DB8D", spd: "#FA92B2"
};

// 与 mon_editor.py 的 _refresh_stat_bars 保持一致：Lv60/Lv120 的真实数值（种族值×努力值×个体值均取满时的近似展示）
export function calcLvStat(base, isHp) {
  const lv60 = Math.floor((3 * base * 60) / 100) + (isHp ? 70 : 5);
  const lv120 = Math.floor((3 * base * 120) / 100) + (isHp ? 130 : 5);
  return { lv60, lv120 };
}

export function renderStatBar(label, value, max = MAX_STAT) {
  const pct = Math.min(100, (value / max) * 100);
  const color = STAT_COLORS[label] || "#aaa";
  const displayLabel = STAT_LABELS[label] || label.toUpperCase();
  const { lv60, lv120 } = calcLvStat(value, label === "hp");
  return `
    <div class="stat-row">
      <span class="stat-label">${displayLabel}</span>
      <div class="stat-track">
        <div class="stat-fill" style="width:${pct}%; background:${color}"></div>
      </div>
      <span class="stat-value">${value}</span>
      <span class="stat-lv" title="Lv60 / Lv120 实际数值">${lv60} / ${lv120}</span>
    </div>
  `;
}

export function renderTotalBar(total) {
  const pct = Math.min(100, (total / 720) * 100);
  return `
    <div class="stat-row total">
      <span class="stat-label">总计</span>
      <div class="stat-track">
        <div class="stat-fill total" style="width:${pct}%"></div>
      </div>
      <span class="stat-value">${total}</span>
    </div>
  `;
}

export { STAT_LABELS, STAT_COLORS, MAX_STAT };
