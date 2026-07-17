const ABILITY_EFFECTS = {
  "": "-- 无战斗效果 --",
  "immune_status": "免疫异常状态",
  "immune_type": "免疫特定属性",
  "weather": "天气效果",
  "field_terrain": "场地效果",
  "on_switch_in": "出场时触发",
  "stat_boost_passive": "被动数值加成",
  "stat_boost_low_hp": "低血量强化",
  "damage_reduce": "伤害减免",
  "damage_boost": "伤害加成",
  "contact_punish": "接触反伤",
  "other": "其他效果",
};

// 能力等级类效果：走游戏里 MonDB._stage_mult() 的真实公式（攻/防/特攻/特防/速度/命中/闪避），单位"段"，-6~6
const STAGE_FORMULA_EFFECTS = new Set(["stat_boost_passive", "stat_boost_low_hp"]);

// 固定倍率类效果（招式威力加成/属性抗性等非能力等级效果），单位"阶"，五阶每阶20%，-5~5
function getMagnitudeUnit(effect) {
  if (STAGE_FORMULA_EFFECTS.has(effect)) {
    return { label: "段", min: -6, max: 6 };
  }
  return { label: "阶", min: -5, max: 5 };
}

function magnitudeToPercent(value, effect) {
  if (!value) return "0%";
  let pct;
  if (STAGE_FORMULA_EFFECTS.has(effect)) {
    const mult = value >= 0 ? (2 + value) / 2 : 2 / (2 - value);
    pct = Math.round((mult - 1) * 100);
  } else {
    pct = value * 20;
  }
  return `${pct >= 0 ? "+" : ""}${pct}%`;
}

const ABILITY_CATEGORIES = {
  "": "-- 未分类 --",
  "天气场地": "天气/场地类",
  "攻击强化": "攻击强化类",
  "防御减伤": "防御/减伤类",
  "状态触发": "状态触发/免疫类",
  "出场交换": "出场/交换类",
  "命中回避": "命中/回避/暴击类",
  "特殊机制": "特殊机制类",
  "稀有专属": "稀有/传说专属类",
  "常规实用": "常规实用类",
};


export class AbilitiesTab {
  constructor(container, state, fileKey, callbacks) {
    this.container = container;
    this.state = state;
    this.fileKey = fileKey;
    this.callbacks = callbacks;
    this.currentId = null;
    this.data = state.data.abilities || [];
  }

  getData() { return this.data; }

  renderList(filter) {
    this.data = this.state.data.abilities || [];
    const items = filter ? this.data.filter(m => this._match(m, filter)) : this.data;
    const list = document.getElementById("sidebar-list");
    if (!items.length) { list.innerHTML = '<div class="placeholder">无特性数据</div>'; return; }
    list.innerHTML = items.map(m =>
      `<div class="sidebar-item ${m.id === this.currentId ? 'active' : ''}" data-id="${m.id}">
        <span class="item-name">${m.name}</span>
      </div>`
    ).join("");
    list.querySelectorAll("[data-id]").forEach(el => {
      el.addEventListener("click", () => this._select(parseInt(el.dataset.id)));
    });
  }

  filterList(q) { this.renderList(q); }
  _match(m, q) { return m.name.toLowerCase().includes(q.toLowerCase()); }

  _select(id) {
    this.currentId = id;
    this.callbacks.onStatus(`编辑特性: ${id}`);
    const ab = this.data.find(m => m.id === id);
    if (ab) this.renderDetail(ab);
    this.renderList();
  }

  renderDetail(ab) {
    const unit = getMagnitudeUnit(ab.effect);
    this.container.innerHTML = `
      <div class="form-section">
        <div class="form-section-title">特性信息</div>
        <div class="form-grid">
          <div class="form-group">
            <label>ID</label><input type="text" id="ab-id" value="${ab.id}" />
          </div>
          <div class="form-group">
            <label>名称</label><input type="text" id="ab-name" value="${ab.name}" />
          </div>
          <div class="form-group">
            <label>效果类型</label>
            <select id="ab-effect">${Object.entries(ABILITY_EFFECTS).map(([k,v]) =>
              `<option value="${k}" ${ab.effect===k?"selected":""}>${v}</option>`
            ).join("")}</select>
          </div>
          <div class="form-group">
            <label>分类标签</label>
            <select id="ab-category">${Object.entries(ABILITY_CATEGORIES).map(([k,v]) =>
              `<option value="${k}" ${ab.category===k?"selected":""}>${v}</option>`
            ).join("")}</select>
          </div>
          <div class="form-group">
            <label>主数值（<span id="ab-stage-unit">${unit.label}，${unit.min}~${unit.max}</span>） <span id="ab-stage-pct" style="color:var(--accent)">${magnitudeToPercent(ab.stage||0, ab.effect)}</span></label>
            <input type="number" id="ab-stage" value="${ab.stage||0}" min="${unit.min}" max="${unit.max}" step="1" />
          </div>
          <div class="form-group">
            <label>副数值（<span id="ab-stage2-unit">${unit.label}，${unit.min}~${unit.max}</span>，可选） <span id="ab-stage2-pct" style="color:var(--accent)">${magnitudeToPercent(ab.stage2||0, ab.effect)}</span></label>
            <input type="number" id="ab-stage2" value="${ab.stage2||0}" min="${unit.min}" max="${unit.max}" step="1" />
          </div>
          <div class="form-group full-width">
            <label>效果描述</label>
            <textarea id="ab-desc" rows="4">${ab.desc||""}</textarea>
          </div>
        </div>
      </div>
    `;
    const bind = (id, field) => {
      document.getElementById(id)?.addEventListener("change", () => {
        this.callbacks.saveHistory(this.fileKey);
        ab[field] = document.getElementById(id).value;
        this.callbacks.onModified(this.fileKey);
      });
    };
    bind("ab-id", "id"); bind("ab-name", "name"); bind("ab-desc", "desc"); bind("ab-category", "category");

    const clampToUnit = (v) => {
      const u = getMagnitudeUnit(ab.effect);
      return Math.max(u.min, Math.min(u.max, parseInt(v) || 0));
    };
    const refreshValues = () => {
      const u = getMagnitudeUnit(ab.effect);
      const stageEl = document.getElementById("ab-stage");
      const stage2El = document.getElementById("ab-stage2");
      if (stageEl) { stageEl.min = u.min; stageEl.max = u.max; }
      if (stage2El) { stage2El.min = u.min; stage2El.max = u.max; }
      const unit1 = document.getElementById("ab-stage-unit");
      const unit2 = document.getElementById("ab-stage2-unit");
      if (unit1) unit1.textContent = `${u.label}，${u.min}~${u.max}`;
      if (unit2) unit2.textContent = `${u.label}，${u.min}~${u.max}`;
      const pct1 = document.getElementById("ab-stage-pct");
      const pct2 = document.getElementById("ab-stage2-pct");
      if (pct1) pct1.textContent = magnitudeToPercent(ab.stage || 0, ab.effect);
      if (pct2) pct2.textContent = magnitudeToPercent(ab.stage2 || 0, ab.effect);
    };

    const effectEl = document.getElementById("ab-effect");
    if (effectEl) {
      effectEl.addEventListener("change", () => {
        this.callbacks.saveHistory(this.fileKey);
        ab.effect = effectEl.value;
        ab.stage = clampToUnit(ab.stage || 0);
        ab.stage2 = clampToUnit(ab.stage2 || 0);
        const stageEl = document.getElementById("ab-stage");
        const stage2El = document.getElementById("ab-stage2");
        if (stageEl) stageEl.value = ab.stage;
        if (stage2El) stage2El.value = ab.stage2;
        refreshValues();
        this.callbacks.onModified(this.fileKey);
      });
    }
    document.getElementById("ab-stage")?.addEventListener("input", (e) => { ab.stage = clampToUnit(e.target.value); refreshValues(); });
    document.getElementById("ab-stage")?.addEventListener("change", (e) => {
      this.callbacks.saveHistory(this.fileKey);
      ab.stage = clampToUnit(e.target.value);
      refreshValues();
      this.callbacks.onModified(this.fileKey);
    });
    document.getElementById("ab-stage2")?.addEventListener("input", (e) => { ab.stage2 = clampToUnit(e.target.value); refreshValues(); });
    document.getElementById("ab-stage2")?.addEventListener("change", (e) => {
      this.callbacks.saveHistory(this.fileKey);
      ab.stage2 = clampToUnit(e.target.value);
      refreshValues();
      this.callbacks.onModified(this.fileKey);
    });
  }

  onAdd() {
    this.callbacks.saveHistory(this.fileKey);
    const maxId = this.data.reduce((max, m) => Math.max(max, parseInt(m.id) || 0), 0);
    this.data.push({ id: maxId + 1, name: "新特性", desc: "" });
    this.callbacks.onModified(this.fileKey);
    this._select(maxId + 1);
  }

  onDelete() {
    this.callbacks.saveHistory(this.fileKey);
    if (!this.currentId) return;
    const item = this.data.find(m => m.id === this.currentId);
    if (!item || !confirm(`确认删除特性「${item.name}」？`)) return;
    const idx = this.data.findIndex(m => m.id === this.currentId);
    if (idx !== -1) this.data.splice(idx, 1);
    this.currentId = null;
    this.callbacks.onModified(this.fileKey);
    this.container.innerHTML = '<div class="placeholder">特性已删除</div>';
    this.renderList();
  }
}
