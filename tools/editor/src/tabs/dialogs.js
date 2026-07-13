export class DialogsTab {
  constructor(container, state, fileKey, callbacks) {
    this.container = container;
    this.state = state;
    this.fileKey = fileKey;
    this.callbacks = callbacks;
    this.currentId = null;
    this.data = [];
  }

  getData() { return this.data; }

  renderList(filter) {
    const raw = this.state.data.dialogs || {};
    this.data = raw;

    // Build a flat list of keys for sidebar
    const keys = Object.keys(raw);
    const items = filter ? keys.filter(k => k.includes(filter)) : keys;
    const list = document.getElementById("sidebar-list");
    if (!items.length) { list.innerHTML = '<div class="placeholder">无剧情文本数据</div>'; return; }
    list.innerHTML = items.map(k =>
      `<div class="sidebar-item ${k === this.currentId ? 'active' : ''}" data-key="${k}">
        <span class="item-name">${k}</span>
      </div>`
    ).join("");
    list.querySelectorAll("[data-key]").forEach(el => {
      el.addEventListener("click", () => this._select(el.dataset.key));
    });
  }

  filterList(q) { this.renderList(q); }

  _select(key) {
    this.currentId = key;
    this.callbacks.onStatus(`编辑剧情: ${key}`);
    this.renderDetail(key);
    this.renderList();
  }

  renderDetail(key) {
    const content = this.data[key] || "";

    this.container.innerHTML = `
      <div class="form-section">
        <div class="form-section-title">${key}</div>
        <div class="form-grid">
          <div class="form-group full-width">
            <label>内容</label>
            <textarea id="dl-content" rows="20" style="font-family:var(--font-mono);font-size:13px;line-height:1.6">${typeof content === 'object' ? JSON.stringify(content, null, 2) : content}</textarea>
          </div>
        </div>
      </div>
    `;

    document.getElementById("dl-content")?.addEventListener("change", (e) => {
      const raw = e.target.value;
      try {
        this.data[key] = JSON.parse(raw);
      } catch {
        this.data[key] = raw;
      }
      this.callbacks.onModified(this.fileKey);
    });
  }
}
