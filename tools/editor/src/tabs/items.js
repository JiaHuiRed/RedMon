import { readSprite } from "../utils/api.js";

const ITEM_CATEGORIES = ["回复", "技能机", "捕捉", "滋补", "进化"];

const TRAIN_STATS = [
  { value: "", label: "-- 无 --" },
  { value: "hp", label: "HP" },
  { value: "atk", label: "ATK" },
  { value: "def", label: "DEF" },
  { value: "sp_atk", label: "SP.ATK" },
  { value: "sp_def", label: "SP.DEF" },
  { value: "spd", label: "SPD" },
];

export class ItemsTab {
  constructor(container, state, fileKey, callbacks) {
    this.container = container;
    this.state = state;
    this.fileKey = fileKey;
    this.callbacks = callbacks;
    this.currentId = null;
    this.data = state.data.items || [];
    this.iconsDir = state.dataPaths?.items_dir?.path || "";
  }

  getData() { return this.data; }

  renderList(filter) {
    this.data = this.state.data.items || [];
    const items = filter ? this.data.filter(m => this._match(m, filter)) : this.data;
    const list = document.getElementById("sidebar-list");
    if (!items.length) { list.innerHTML = '<div class="placeholder">无道具数据</div>'; return; }
    list.innerHTML = items.map(m =>
      `<div class="sidebar-item ${m.id === this.currentId ? 'active' : ''}" data-id="${m.id}">
        <span class="item-name">${m.name}</span>
        <span style="font-size:11px;color:var(--text-muted)">${m.category||""}</span>
      </div>`
    ).join("");
    list.querySelectorAll("[data-id]").forEach(el => {
      el.addEventListener("click", () => this._select(parseInt(el.dataset.id)));
    });
  }

  filterList(q) { this.renderList(q); }
  _match(m, q) { const ql=q.toLowerCase(); return m.name.toLowerCase().includes(ql) || (m.category||"").includes(q); }

  _select(id) {
    this.currentId = id;
    this.callbacks.onStatus(`编辑道具: ${id}`);
    const item = this.data.find(m => m.id === id);
    if (item) this.renderDetail(item);
    this.renderList();
  }

  renderDetail(item) {
    this.container.innerHTML = `
      <div class="auto-grid">
        <div class="form-section">
          <div class="form-section-title">道具信息</div>
          <div class="form-grid">
            <div class="form-group">
              <label>ID</label><input type="text" id="it-id" value="${item.id}" />
            </div>
            <div class="form-group">
              <label>名称</label><input type="text" id="it-name" value="${item.name}" />
            </div>
            <div class="form-group">
              <label>分类</label>
              <select id="it-category">${ITEM_CATEGORIES.map(c =>
                `<option value="${c}" ${item.category===c?"selected":""}>${c}</option>`
              ).join("")}</select>
            </div>
            <div class="form-group">
              <label>价格</label><input type="number" id="it-price" value="${item.price||0}" min="0" />
            </div>
            <div class="form-group">
              <label>效果</label><input type="text" id="it-effect" value="${item.effect||""}" />
            </div>
            <div class="form-group" id="it-train-stat-group" style="display:${item.category==="滋补"?"block":"none"}">
              <label>努力值属性</label>
              <select id="it-train-stat">${TRAIN_STATS.map(s =>
                `<option value="${s.value}" ${item.train_stat===s.value?"selected":""}>${s.label}</option>`
              ).join("")}</select>
            </div>
            <div class="form-group" id="it-train-amount-group" style="display:${item.category==="滋补"?"block":"none"}">
              <label>努力值增量</label>
              <input type="number" id="it-train-amount" value="${item.train_amount||0}" min="0" />
            </div>
            <div class="form-group full-width">
              <label>描述</label>
              <textarea id="it-desc" rows="3">${item.desc||""}</textarea>
            </div>
          </div>
        </div>
        <div class="form-section">
          <div class="sprite-preview" id="item-icon-preview">
            <div class="sprite-placeholder">无图标</div>
          </div>
        </div>
      </div>
    `;
    const bind = (id, field, num) => {
      document.getElementById(id)?.addEventListener("change", () => {
        this.callbacks.saveHistory(this.fileKey);
        const v = document.getElementById(id).value;
        item[field] = num ? (parseInt(v)||0) : v;
        this.callbacks.onModified(this.fileKey);
      });
    };
    bind("it-id", "id"); bind("it-name", "name"); bind("it-category", "category");
    bind("it-price", "price", true); bind("it-effect", "effect"); bind("it-desc", "desc");
    bind("it-train-stat", "train_stat");
    document.getElementById("it-train-amount")?.addEventListener("change", () => {
      this.callbacks.saveHistory(this.fileKey);
      item.train_amount = parseInt(document.getElementById("it-train-amount").value) || 0;
      this.callbacks.onModified(this.fileKey);
    });
    // Toggle train fields when category changes
    document.getElementById("it-category")?.addEventListener("change", function() {
      const show = this.value === "滋补";
      const sg = document.getElementById("it-train-stat-group");
      const ag = document.getElementById("it-train-amount-group");
      if (sg) sg.style.display = show ? "block" : "none";
      if (ag) ag.style.display = show ? "block" : "none";
    });
    this._loadItemIcon(item);
  }

  async _loadItemIcon(item) {
    const container = document.getElementById("item-icon-preview");
    if (!container) return;
    const name = item.name;
    if (!name) { container.innerHTML = '<div class="sprite-placeholder">无图标</div>'; return; }
    const path = `${this.iconsDir}/${name}.png`;
    console.debug("[items] loading icon from:", path);
    try {
      const dataUrl = await readSprite(path);
      container.innerHTML = `<img src="${dataUrl}" alt="${name}" />`;
    } catch (e) {
      console.warn("[items] icon load error:", e);
      container.innerHTML = '<div class="sprite-placeholder">无图标</div>';
    }
  }

  onAdd() {
    this.callbacks.saveHistory(this.fileKey);
    const maxId = this.data.reduce((max, m) => Math.max(max, parseInt(m.id) || 0), 0);
    this.data.push({ id: maxId + 1, name: "新道具", category: "回复", price: 0, effect: "", desc: "" });
    this.callbacks.onModified(this.fileKey);
    this._select(maxId + 1);
  }

  onDelete() {
    this.callbacks.saveHistory(this.fileKey);
    if (!this.currentId) return;
    const item = this.data.find(m => m.id === this.currentId);
    if (!item || !confirm(`确认删除道具「${item.name}」？`)) return;
    const idx = this.data.findIndex(m => m.id === this.currentId);
    if (idx !== -1) this.data.splice(idx, 1);
    this.currentId = null;
    this.callbacks.onModified(this.fileKey);
    this.container.innerHTML = '<div class="placeholder">道具已删除</div>';
    this.renderList();
  }
}
