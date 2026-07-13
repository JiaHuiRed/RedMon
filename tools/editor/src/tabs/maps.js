const MAP_TYPES = ["野外", "城市", "室内", "道馆", "洞穴", "水域", "特殊"];

export class MapsTab {
  constructor(container, state, fileKey, callbacks) {
    this.container = container;
    this.state = state;
    this.fileKey = fileKey;
    this.callbacks = callbacks;
    this.currentId = null;
    this.data = state.data.maps || [];
  }

  getData() { return this.data; }

  renderList(filter) {
    this.data = this.state.data.maps || [];
    const items = filter ? this.data.filter(m => this._match(m, filter)) : this.data;
    const list = document.getElementById("sidebar-list");
    if (!items.length) { list.innerHTML = '<div class="placeholder">无地图数据</div>'; return; }
    list.innerHTML = items.map(m =>
      `<div class="sidebar-item ${m.id === this.currentId ? 'active' : ''}" data-id="${m.id}">
        <span class="item-name">${m.name}</span>
        <span style="font-size:11px;color:var(--text-muted)">${m.type||""}</span>
      </div>`
    ).join("");
    list.querySelectorAll("[data-id]").forEach(el => {
      el.addEventListener("click", () => this._select(parseInt(el.dataset.id)));
    });
  }

  filterList(q) { this.renderList(q); }
  _match(m, q) { const ql=q.toLowerCase(); return m.name.toLowerCase().includes(ql) || (m.type||"").toLowerCase().includes(ql); }

  _select(id) {
    this.currentId = id;
    this.callbacks.onStatus(`编辑地图: ${id}`);
    const map = this.data.find(m => m.id === id);
    if (map) this.renderDetail(map);
    this.renderList();
  }

  renderDetail(map) {
    this.container.innerHTML = `
      <div class="form-section">
        <div class="form-section-title">地图信息</div>
        <div class="form-grid">
          <div class="form-group">
            <label>ID</label><input type="number" id="mp-id" value="${map.id}" />
          </div>
          <div class="form-group">
            <label>名称</label><input type="text" id="mp-name" value="${map.name}" />
          </div>
          <div class="form-group">
            <label>类型</label>
            <select id="mp-type">${MAP_TYPES.map(t =>
              `<option value="${t}" ${map.type===t?"selected":""}>${t}</option>`
            ).join("")}</select>
          </div>
          <div class="form-group">
            <label>场景文件</label><input type="text" id="mp-scene" value="${map.scene||""}" />
          </div>
          <div class="form-group full-width">
            <label>描述</label>
            <textarea id="mp-desc" rows="3">${map.desc||""}</textarea>
          </div>
          <div class="form-group">
            <label>道馆</label>
            <input type="text" id="mp-gym" value="${map.gym||""}" placeholder="如「翠竹道馆」" />
          </div>
          <div class="form-group full-width">
            <label>关联NPC（逗号分隔）</label>
            <textarea id="mp-npcs" rows="2">${(map.npcs||[]).join(", ")}</textarea>
          </div>
        </div>
      </div>
    `;
    const bind = (id, field) => {
      document.getElementById(id)?.addEventListener("change", () => {
        map[field] = document.getElementById(id).value;
        this.callbacks.onModified(this.fileKey);
      });
    };
    bind("mp-id", "id"); bind("mp-name", "name"); bind("mp-type", "type");
    bind("mp-scene", "scene"); bind("mp-desc", "desc"); bind("mp-gym", "gym");
    document.getElementById("mp-npcs")?.addEventListener("change", (e) => {
      map.npcs = e.target.value.split(",").map(s => s.trim()).filter(Boolean);
      this.callbacks.onModified(this.fileKey);
    });
  }

  onAdd() {
    const maxId = this.data.reduce((max, m) => Math.max(max, parseInt(m.id) || 0), 0);
    this.data.push({ id: maxId + 1, name: "新地图", type: "野外", scene: "", npcs: [] });
    this.callbacks.onModified(this.fileKey);
    this._select(maxId + 1);
  }

  onDelete() {
    if (!this.currentId) return;
    const item = this.data.find(m => m.id === this.currentId);
    if (!item || !confirm(`确认删除地图「${item.name}」？`)) return;
    const idx = this.data.findIndex(m => m.id === this.currentId);
    if (idx !== -1) this.data.splice(idx, 1);
    this.currentId = null;
    this.callbacks.onModified(this.fileKey);
    this.container.innerHTML = '<div class="placeholder">地图已删除</div>';
    this.renderList();
  }
}
