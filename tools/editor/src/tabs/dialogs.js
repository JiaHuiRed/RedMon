// 260702 Red section/key 中文映射，照搬自 tools/mon_editor.py 保持两个编辑器体验一致
 import { escapeHtml } from "../utils/dom.js";
const SEC_LABELS = {
  char_create: "角色创建", starter: "御三家选择", world: "大地图",
  home: "家（室内）", village: "青木村", rival: "劲敌",
  trainers: "训练师对话", gym_cuizhu: "翠竹馆", town: "碧溪镇",
};
const KEY_LABELS = {
  intro: "开场白", gender_prompt: "性别选择提示",
  name_prompt_male: "取名提示（男）", name_prompt_female: "取名提示（女）",
  selection_prompt: "选择提示", outro: "结束语",
  clinic_greeting: "诊所问候", clinic_healed: "诊所治愈",
  signpost: "路牌", mom_sendoff: "妈妈送行", mom_professor: "妈妈提教授",
  mom_morning: "妈妈早安", mom_encourage: "妈妈鼓励", mom_rival: "妈妈提劲敌",
  name: "地名", npc1: "NPC1", npc2: "NPC2",
  first_encounter: "初次相遇", first_battle: "初战对白",
  first_win: "赢了", first_lose: "输了", tutorial: "教程",
  leader_before: "馆主战前", leader_win: "馆主战后",
  leader_before_lines: "馆主战前台词", leader_after_lines: "馆主战后台词",
  npc_traveler: "旅行者NPC", npc_shopkeeper: "店主NPC",
};

export class DialogsTab {
  constructor(container, state, fileKey, callbacks) {
    this.container = container;
    this.state = state;
    this.fileKey = fileKey;
    this.callbacks = callbacks;
    this.currentId = null;
    this.data = {};
  }

  getData() { return this.data; }

  renderList(filter) {
    const raw = this.state.data.dialogs || {};
    this.data = raw;

    const keys = Object.keys(raw);
    const items = filter ? keys.filter(k => k.includes(filter) || (SEC_LABELS[k] || "").includes(filter)) : keys;
    const list = document.getElementById("sidebar-list");
    if (!items.length) { list.innerHTML = '<div class="placeholder">无剧情文本数据</div>'; return; }
    list.innerHTML = items.map(k =>
      `<div class="sidebar-item ${k === this.currentId ? 'active' : ''}" data-key="${k}">
         <span class="item-name">${escapeHtml(SEC_LABELS[k] || k)}</span>
         <span style="font-size:11px;color:var(--text-muted)">${escapeHtml(k)}</span>
      </div>`
    ).join("");
    list.querySelectorAll("[data-key]").forEach(el => {
      el.addEventListener("click", () => this._select(el.dataset.key));
    });
  }

  filterList(q) { this.renderList(q); }

  _select(key) {
    this.currentId = key;
    this.callbacks.onStatus(`编辑剧情: ${SEC_LABELS[key] || key}`);
    this.renderDetail(key);
    this.renderList();
  }

  onAdd() {
    const key = prompt("新增分组 key（英文，如 gym_panshi）:");
    if (!key || !key.trim()) return;
    const k = key.trim();
    if (this.data[k]) { alert("这个分组已经存在了"); return; }
    this.data[k] = {};
    this.callbacks.onModified(this.fileKey);
    this._select(k);
  }

  onDelete() {
    if (!this.currentId) return;
    if (!confirm(`确认删除分组「${escapeHtml(SEC_LABELS[this.currentId] || this.currentId)}」？此操作不可撤销。`)) return;
    delete this.data[this.currentId];
    this.currentId = null;
    this.callbacks.onModified(this.fileKey);
    this.container.innerHTML = '<div class="placeholder">分组已删除</div>';
    this.renderList();
  }

  renderDetail(key) {
    const section = this.data[key] || {};
    const secLabel = SEC_LABELS[key] || key;

    const cards = Object.entries(section).map(([k, val]) => this._buildCard(key, k, val)).join("");

    this.container.innerHTML = `
      <div class="form-section">
        <div class="section-header">
           <span class="form-section-title">编辑: ${escapeHtml(secLabel)}（${escapeHtml(key)}）</span>
          <div><button class="btn btn-sm" id="dl-add-key">+ 新增条目</button></div>
        </div>
      </div>
      ${cards}
    `;

    document.getElementById("dl-add-key")?.addEventListener("click", () => this._addKey(key));
    this._bindCardEvents(key, section);
  }

  // ===== Card rendering by value type: string / array / nested dict (1 level) =====
  _buildCard(secId, k, val) {
    const label = KEY_LABELS[k] || k;
    let bodyHtml;
    if (Array.isArray(val)) {
      bodyHtml = `
        <div class="dl-list" data-dl-list="${k}">
          ${val.map((item, i) => `
            <div class="dl-list-row" style="display:flex;gap:6px;align-items:flex-start;margin-bottom:4px">
              <span style="color:var(--text-muted);font-size:11px;padding-top:6px">[${i}]</span>
               <textarea class="dl-list-item" data-key="${k}" data-idx="${i}" rows="2" style="flex:1">${escapeHtml(item ?? "")}</textarea>
              <button class="remove-btn dl-list-remove" data-key="${k}" data-idx="${i}">✕</button>
            </div>
          `).join("")}
        </div>
        <button class="btn btn-sm dl-list-add" data-key="${k}">+ 添加行</button>
      `;
    } else if (val && typeof val === "object") {
      bodyHtml = Object.entries(val).map(([subK, subV]) => `
        <div style="margin:6px 0 6px 12px">
           <label style="font-size:11px;color:var(--text-muted)">${escapeHtml(subK)}</label>
           <textarea class="dl-nested" data-key="${k}" data-subkey="${subK}" rows="2" style="width:100%">${
             (subV && typeof subV === "object") ? JSON.stringify(subV, null, 2) : escapeHtml(subV ?? "")
           }</textarea>
        </div>
      `).join("");
    } else {
      bodyHtml = `<textarea class="dl-string" data-key="${k}" rows="3" style="width:100%">${escapeHtml(val ?? "")}</textarea>`;
    }
    return `
      <div class="form-section dl-card" data-card-key="${k}">
        <div class="section-header">
           <span class="form-section-title" style="color:var(--accent, inherit)">${escapeHtml(label)}（${escapeHtml(k)}）</span>
          <button class="remove-btn dl-key-remove" data-key="${k}" title="删除此条目">✕</button>
        </div>
        ${bodyHtml}
      </div>
    `;
  }

  _bindCardEvents(secId, section) {
    // Plain string value
    this.container.querySelectorAll(".dl-string").forEach(el => {
      el.addEventListener("change", () => {
        section[el.dataset.key] = el.value;
        this.callbacks.onModified(this.fileKey);
      });
    });

    // Array elements
    this.container.querySelectorAll(".dl-list-item").forEach(el => {
      el.addEventListener("change", () => {
        this.callbacks.saveHistory(this.fileKey);
        section[el.dataset.key][parseInt(el.dataset.idx)] = el.value;
        this.callbacks.onModified(this.fileKey);
      });
    });
    this.container.querySelectorAll(".dl-list-add").forEach(el => {
      el.addEventListener("click", () => {
        this.callbacks.saveHistory(this.fileKey);
        section[el.dataset.key].push("");
        this.callbacks.onModified(this.fileKey);
        this.renderDetail(this.currentId);
      });
    });
    this.container.querySelectorAll(".dl-list-remove").forEach(el => {
      el.addEventListener("click", () => {
        this.callbacks.saveHistory(this.fileKey);
        section[el.dataset.key].splice(parseInt(el.dataset.idx), 1);
        this.callbacks.onModified(this.fileKey);
        this.renderDetail(this.currentId);
      });
    });

    // Nested dict leaves (one level, e.g. trainers.t_xiaomin -> dialog_before)
    this.container.querySelectorAll(".dl-nested").forEach(el => {
      el.addEventListener("change", () => {
        this.callbacks.saveHistory(this.fileKey);
        const parent = section[el.dataset.key];
        const raw = el.value;
        // Preserve original type: if it was an object/array, try to parse back as JSON
        const original = parent[el.dataset.subkey];
        if (original && typeof original === "object") {
          try { parent[el.dataset.subkey] = JSON.parse(raw); }
          catch { this.callbacks.onStatus(`「${el.dataset.subkey}」不是合法 JSON，未保存该字段的改动`); return; }
        } else {
          parent[el.dataset.subkey] = raw;
        }
        this.callbacks.onModified(this.fileKey);
      });
    });

    // Delete a whole top-level key
    this.container.querySelectorAll(".dl-key-remove").forEach(el => {
      el.addEventListener("click", () => {
        this.callbacks.saveHistory(this.fileKey);
         if (!confirm(`删除条目「${escapeHtml(KEY_LABELS[el.dataset.key] || el.dataset.key)}」？`)) return;
        delete section[el.dataset.key];
        this.callbacks.onModified(this.fileKey);
        this.renderDetail(this.currentId);
      });
    });
  }

  _addKey(secId) {
    const key = prompt("条目 key（英文，如 npc3）:");
    if (!key || !key.trim()) return;
    const k = key.trim();
    const section = this.data[secId];
    if (section[k] !== undefined) { alert("这个 key 已经存在了"); return; }
    const isList = confirm("按「确定」新增为多行列表，按「取消」新增为单行文本");
    section[k] = isList ? [] : "";
    this.callbacks.onModified(this.fileKey);
    this.renderDetail(secId);
  }
}
