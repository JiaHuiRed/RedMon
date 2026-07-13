const ABILITY_EFFECTS = {
  "": "-- 无战斗效果 --",
  "immune_status": "免疫异常状态",
  "immune_type": "免疫特定属性",
  "weather": "天气效果",
  "on_switch_in": "出场时触发",
  "stat_boost_passive": "被动数值加成",
  "stat_boost_low_hp": "低血量强化",
  "damage_reduce": "伤害减免",
  "damage_boost": "伤害加成",
  "contact_punish": "接触反伤",
  "other": "其他效果",
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
          <div class="form-group full-width">
            <label>效果描述</label>
            <textarea id="ab-desc" rows="4">${ab.desc||""}</textarea>
          </div>
        </div>
      </div>
    `;
    const bind = (id, field) => {
      document.getElementById(id)?.addEventListener("change", () => {
        ab[field] = document.getElementById(id).value;
        this.callbacks.onModified(this.fileKey);
      });
    };
    bind("ab-id", "id"); bind("ab-name", "name"); bind("ab-effect", "effect"); bind("ab-desc", "desc");
  }

  onAdd() {
    const maxId = this.data.reduce((max, m) => Math.max(max, parseInt(m.id) || 0), 0);
    this.data.push({ id: maxId + 1, name: "新特性", desc: "" });
    this.callbacks.onModified(this.fileKey);
    this._select(maxId + 1);
  }

  onDelete() {
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
