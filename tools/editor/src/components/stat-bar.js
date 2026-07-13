const MAX_STAT = 255;
const STAT_LABELS = {
  hp: "HP", atk: "ATK", def: "DEF",
  spatk: "SP.ATK", spdef: "SP.DEF", spd: "SPD"
};
const STAT_COLORS = {
  hp: "#FF5959", atk: "#F5AC78", def: "#FAE078",
  spatk: "#9DB7F5", spdef: "#A7DB8D", spd: "#FA92B2"
};

export function renderStatBar(label, value, max = MAX_STAT) {
  const pct = Math.min(100, (value / max) * 100);
  const color = STAT_COLORS[label] || "#aaa";
  const displayLabel = STAT_LABELS[label] || label.toUpperCase();
  return `
    <div class="stat-row">
      <span class="stat-label">${displayLabel}</span>
      <div class="stat-track">
        <div class="stat-fill" style="width:${pct}%; background:${color}"></div>
      </div>
      <span class="stat-value">${value}</span>
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

export { STAT_LABELS, MAX_STAT };
