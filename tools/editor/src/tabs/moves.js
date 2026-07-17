import { renderTypeBadge, renderTypeOptions } from "../components/type-badge.js";

const MOVE_CATEGORIES = ["物理", "特殊", "变化"];

// 从游戏 moves.json 中提取的实际效果
const MOVE_EFFECTS = {
  "": "-- 无效果 --",
  "inflict_burn": "烧伤",
  "inflict_freeze": "冰冻",
  "inflict_paralysis": "麻痹",
  "inflict_poison": "中毒",
  "inflict_sleep": "睡眠",
  "heal_self": "回复HP",
  "high_crit": "易暴击",
  "lower_atk": "降低物攻",
  "lower_acc": "降低命中",
  "lower_spd": "降低速度",
  "raise_def": "提升物防",
  "raise_sp_atk": "提升特攻",
  "raise_sp_def": "提升特防",
  "raise_spd": "提升速度",
  "recoil": "反伤",
  "priority": "先制",
};

const EFFECT_NEEDS_CHANCE = new Set([
  "inflict_burn", "inflict_freeze", "inflict_paralysis",
  "inflict_poison", "inflict_sleep",
]);

const EFFECT_NEEDS_VALUE = new Set([
  "heal_self", "recoil",
]);

export class MovesTab {
  constructor(container, state, fileKey, callbacks) {
    this.container = container;
    this.state = state;
    this.fileKey = fileKey;
    this.callbacks = callbacks;
    this.currentId = null;
    this.data = state.data.moves || [];
  }

  getData() { return this.data; }

  renderList(filter) {
    this.data = this.state.data.moves || [];
    const items = filter ? this.data.filter(m => this._match(m, filter)) : this.data;
    const list = document.getElementById("sidebar-list");
    if (!items.length) { list.innerHTML = '<div class="placeholder">无技能数据</div>'; return; }

    list.innerHTML = items.map(m =>
      `<div class="sidebar-item ${m.id === this.currentId ? 'active' : ''}" data-move="${m.id}">
        <span class="item-name">${m.name}</span>
        <span style="font-size:11px;color:var(--text-muted)">${m.type||""} ${m.category||""}</span>
        <span style="font-size:11px;color:var(--text-muted);font-family:var(--font-mono)">${m.power||"-"}/${m.accuracy||"-"}</span>
      </div>`
    ).join("");
    list.querySelectorAll("[data-move]").forEach(el => {
      el.addEventListener("click", () => this._select(parseInt(el.dataset.move)));
    });
  }

  filterList(q) { this.renderList(q); }

  _match(m, q) {
    const ql = q.toLowerCase();
    return m.name.toLowerCase().includes(ql) || (m.type && m.type.includes(q));
  }

  _select(id) {
    this.currentId = id;
    this.callbacks.onStatus(`编辑技能: ${id}`);
    const move = this.data.find(m => m.id === id);
    if (move) this.renderDetail(move);
    this.renderList();
  }

  renderDetail(move) {
    this.container.innerHTML = `
      <div class="form-section">
        <div class="form-section-title">技能信息</div>
        <div class="form-grid">
          <div class="form-group">
            <label>ID</label>
            <input type="text" id="mv-id" value="${move.id}" />
          </div>
          <div class="form-group">
            <label>名称</label>
            <input type="text" id="mv-name" value="${move.name}" />
          </div>
          <div class="form-group">
            <label>属性</label>
            <select id="mv-type">${renderTypeOptions(move.type)}</select>
          </div>
          <div class="form-group">
            <label>分类</label>
            <select id="mv-category">${MOVE_CATEGORIES.map(c =>
              `<option value="${c}" ${move.category===c?"selected":""}>${c}</option>`
            ).join("")}</select>
          </div>
          <div class="form-group">
            <label>威力</label>
            <input type="number" id="mv-power" value="${move.power||0}" min="0" />
          </div>
          <div class="form-group">
            <label>命中率</label>
            <input type="number" id="mv-accuracy" value="${move.accuracy||0}" min="0" max="100" />
          </div>
          <div class="form-group">
            <label>PP</label>
            <input type="number" id="mv-pp" value="${move.pp||0}" min="0" />
          </div>
          <div class="form-group">
            <label>优先级</label>
            <input type="number" id="mv-priority" value="${move.priority||0}" />
          </div>
          <div class="form-group">
            <label>效果类型</label>
            <select id="mv-effect">${Object.entries(MOVE_EFFECTS).map(([k,v]) =>
              `<option value="${k}" ${move.effect===k?"selected":""}>${v}</option>`
            ).join("")}</select>
          </div>
          <div class="form-group" id="mv-effect-chance-group" style="display:${EFFECT_NEEDS_CHANCE.has(move.effect)?"flex":"none"}">
            <label>概率%</label>
            <input type="number" id="mv-effect-chance" value="${move.effect_chance||0}" min="0" max="100" />
          </div>
          <div class="form-group" id="mv-effect-value-group" style="display:${EFFECT_NEEDS_VALUE.has(move.effect)?"flex":"none"}">
            <label>数值%</label>
            <input type="number" id="mv-effect-value" value="${move.effect_value||0}" min="0" />
          </div>
          <div class="form-group full-width">
            <label>效果描述</label>
            <textarea id="mv-desc" rows="3">${move.desc||""}</textarea>
          </div>
        </div>
      </div>
    `;

    const bind = (id, field) => {
      document.getElementById(id)?.addEventListener("change", () => {
        this.callbacks.saveHistory(this.fileKey);
        const val = document.getElementById(id).value;
        if (field === "power" || field === "accuracy" || field === "pp" || field === "priority") {
          move[field] = parseInt(val) || 0;
        } else {
          move[field] = val;
        }
        this.callbacks.onModified(this.fileKey);
      });
    };
    bind("mv-id", "id"); bind("mv-name", "name"); bind("mv-type", "type");
    bind("mv-category", "category"); bind("mv-power", "power");
    bind("mv-accuracy", "accuracy"); bind("mv-pp", "pp");
    bind("mv-priority", "priority"); bind("mv-desc", "desc");
    const effectEl = document.getElementById("mv-effect");
    if (effectEl) {
      effectEl.addEventListener("change", () => {
        this.callbacks.saveHistory(this.fileKey);
        move.effect = effectEl.value;
        const chanceGroup = document.getElementById("mv-effect-chance-group");
        const valueGroup = document.getElementById("mv-effect-value-group");
        if (chanceGroup) chanceGroup.style.display = EFFECT_NEEDS_CHANCE.has(effectEl.value) ? "block" : "none";
        if (valueGroup) valueGroup.style.display = EFFECT_NEEDS_VALUE.has(effectEl.value) ? "block" : "none";
        this.callbacks.onModified(this.fileKey);
      });
    }
    document.getElementById("mv-effect-chance")?.addEventListener("change", (e) => {
      this.callbacks.saveHistory(this.fileKey);
      move.effect_chance = parseInt(e.target.value) || 0;
      this.callbacks.onModified(this.fileKey);
    });
    document.getElementById("mv-effect-value")?.addEventListener("change", (e) => {
      this.callbacks.saveHistory(this.fileKey);
      move.effect_value = parseInt(e.target.value) || 0;
      this.callbacks.onModified(this.fileKey);
    });
  }

  onAdd() {
    this.callbacks.saveHistory(this.fileKey);
    const maxId = this.data.reduce((max, m) => Math.max(max, parseInt(m.id) || 0), 0);
    this.data.push({ id: String(maxId + 1), name: "新技能", type: "木", category: "物理", power: 60, accuracy: 100, pp: 20, priority: 0, desc: "" });
    this.callbacks.onModified(this.fileKey);
    this._select(parseInt(maxId + 1));
  }

  onDelete() {
    this.callbacks.saveHistory(this.fileKey);
    if (!this.currentId) return;
    const item = this.data.find(m => m.id === this.currentId);
    if (!item || !confirm(`确认删除技能「${item.name}」？`)) return;
    this.data = this.data.filter(m => m.id !== this.currentId);
    this.state.data.moves = this.data;
    this.currentId = null;
    this.callbacks.onModified(this.fileKey);
    this.container.innerHTML = '<div class="placeholder">技能已删除</div>';
    this.renderList();
  }
}
