import { readSprite } from "../utils/api.js";

const NPC_TRAINER_TYPES = ["教授", "劲敌", "普通NPC", "家人", "村民", "道馆主", "四天王", "反派", "训练师"];

const TRAINER_CLASSES = ["普通训练师", "精英训练师", "道馆学徒", "道馆主", "四天王", "冠军", "反派干部", "反派首领", "劲敌", "路人", "商人", "研究员", "武者", "渔夫", "虫师"];

const IV_TIER_LABELS = [
  "0 - 路人杂兵 (IV=0)",
  "1 - 普通训练师 (IV=8)",
  "2 - 精英/道馆杂兵 (IV=16)",
  "3 - 道馆主/首领 (IV=25)",
  "4 - 四天王/冠军/黑风堂主 (IV=31)",
];

export class NpcsTab {
  constructor(container, state, fileKey, callbacks) {
    this.container = container;
    this.state = state;
    this.fileKey = fileKey;
    this.callbacks = callbacks;
    this.currentId = null;
    this.data = state.data.npcs || [];
    this.spritesDir = state.dataPaths?.npc_sprites_dir?.path || "";
  }

  getData() { return this.data; }

  renderList(filter) {
    this.data = this.state.data.npcs || [];
    const items = filter ? this.data.filter(m => this._match(m, filter)) : this.data;
    const list = document.getElementById("sidebar-list");
    if (!items.length) { list.innerHTML = '<div class="placeholder">无角色数据</div>'; return; }
    list.innerHTML = items.map(m =>
      `<div class="sidebar-item ${m.id === this.currentId ? 'active' : ''}" data-id="${m.id}">
        <span class="item-name">${m.name}</span>
        <span style="font-size:11px;color:var(--text-muted)">${m.trainer_type||""}</span>
      </div>`
    ).join("");
    list.querySelectorAll("[data-id]").forEach(el => {
      el.addEventListener("click", () => this._select(el.dataset.id));
    });
  }

  filterList(q) { this.renderList(q); }
  _match(m, q) { const ql=q.toLowerCase(); return m.name.toLowerCase().includes(ql) || (m.trainer_type||"").toLowerCase().includes(ql); }

  async _select(id) {
    this.currentId = id;
    this.callbacks.onStatus(`编辑角色: ${id}`);
    const npc = this.data.find(m => m.id === id);
    if (npc) await this.renderDetail(npc);
    this.renderList();
  }

  async renderDetail(npc) {
    const t = npc.trainer || {};
    const teamHtml = (t.team || []).map((p, i) =>
      `<tr>
        <td><input type="text" value="${p.species||""}" class="tr-team-species" data-idx="${i}" style="width:80px" /></td>
        <td><input type="number" value="${p.level||1}" class="tr-team-level" data-idx="${i}" style="width:50px" min="1" /></td>
        <td><input type="text" value="${(p.moves||[]).join(",")}" class="tr-team-moves" data-idx="${i}" style="width:120px" placeholder="用逗号分隔" /></td>
        <td><input type="text" value="${p.item||""}" class="tr-team-item" data-idx="${i}" style="width:60px" /></td>
        <td><button class="remove-btn tr-team-remove" data-idx="${i}">✕</button></td>
      </tr>`
    ).join("") || '<tr><td colspan="5" style="text-align:center;color:var(--text-muted)">无队伍</td></tr>';

    const partyHtml = (npc.party || []).map((p, i) =>
      `<tr>
        <td><input type="text" value="${p.id||""}" class="np-party-id" data-idx="${i}" style="width:60px" /></td>
        <td><input type="number" value="${p.level||1}" class="np-party-level" data-idx="${i}" style="width:50px" min="1" /></td>
        <td><button class="remove-btn np-party-remove" data-idx="${i}">✕</button></td>
      </tr>`
    ).join("") || '<tr><td colspan="3" style="text-align:center;color:var(--text-muted)">无队伍</td></tr>';

    this.container.innerHTML = `
      <div class="auto-grid">
        <div class="form-section">
          <div class="sprite-preview" id="npc-sprite-preview">
            <div class="sprite-placeholder">加载中...</div>
          </div>
        </div>
        <div class="form-section">
          <div class="form-section-title">角色信息</div>
          <div class="form-grid">
            <div class="form-group">
              <label>ID</label><input type="text" id="np-id" value="${npc.id}" />
            </div>
            <div class="form-group">
              <label>名称</label><input type="text" id="np-name" value="${npc.name}" />
            </div>
            <div class="form-group">
              <label>称号</label><input type="text" id="np-title" value="${npc.title||""}" placeholder="如「青木村的守护者」" />
            </div>
            <div class="form-group">
              <label>训练师类型</label>
              <select id="np-type">${NPC_TRAINER_TYPES.map(tp =>
                `<option value="${tp}" ${npc.trainer_type === tp ? "selected" : ""}>${tp}</option>`
              ).join("")}</select>
            </div>
            <div class="form-group">
              <label>性别</label>
              <select id="np-gender">
                <option value="">未设置</option>
                <option value="男" ${npc.gender === "男" ? "selected" : ""}>男</option>
                <option value="女" ${npc.gender === "女" ? "selected" : ""}>女</option>
              </select>
            </div>
            <div class="form-group full-width">
              <label>描述</label>
              <textarea id="np-desc" rows="2">${npc.desc||""}</textarea>
            </div>
            <div class="form-group full-width">
              <label>对话</label>
              <textarea id="np-dialog" rows="3">${npc.dialog||""}</textarea>
            </div>
          </div>
        </div>
      </div>
      <details class="form-section" ${t.trainer_id ? "open" : ""}>
        <summary class="form-section-title">训练师数据</summary>
        <div class="form-grid">
          <div class="form-group">
            <label>训练师ID</label><input type="text" id="tr-id" value="${t.trainer_id||""}" />
          </div>
          <div class="form-group">
            <label>职业</label>
            <select id="tr-class">${TRAINER_CLASSES.map(tc =>
              `<option value="${tc}" ${t.class===tc?"selected":""}>${tc}</option>`
            ).join("")}</select>
          </div>
          <div class="form-group">
            <label>奖金</label><input type="number" id="tr-reward" value="${t.reward||0}" />
          </div>
          <div class="form-group">
            <label>IV等级</label>
            <select id="tr-iv-tier">${IV_TIER_LABELS.map((l,i) =>
              `<option value="${i}" ${(t.iv_tier??-1)===i?"selected":""}>${l}</option>`
            ).join("")}</select>
          </div>
          <div class="form-group full-width">
            <label>战前对话</label>
            <textarea id="tr-dialog-before" rows="2">${t.dialog_before||""}</textarea>
          </div>
          <div class="form-group full-width">
            <label>战后对话（胜利）</label>
            <textarea id="tr-dialog-win" rows="2">${t.dialog_win||""}</textarea>
          </div>
          <div class="form-group full-width">
            <label>战后对话（失败）</label>
            <textarea id="tr-dialog-lose" rows="2">${t.dialog_lose||""}</textarea>
          </div>
          <div class="form-group full-width">
            <label>玩家败北对话</label>
            <textarea id="tr-dialog-player-lose" rows="2">${t.dialog_player_lose||""}</textarea>
          </div>
          <div class="form-group full-width">
            <label>战后对话</label>
            <textarea id="tr-dialog-after" rows="2">${t.dialog_after||""}</textarea>
          </div>
        </div>
        <div class="section-header" style="margin-top:12px">
          <span class="form-section-title">训练师队伍</span>
          <button class="btn btn-sm" id="tr-add-team">+ 添加</button>
        </div>
        <table class="list-table">
          <thead><tr><th style="width:90px">精灵</th><th style="width:60px">等级</th><th style="width:130px">技能</th><th style="width:70px">携带道具</th><th style="width:40px"></th></tr></thead>
          <tbody>${teamHtml}</tbody>
        </table>
      </details>
      <div class="form-section">
        <div class="section-header">
          <span class="form-section-title">NPC队伍（旧格式，建议用训练师队伍）</span>
          <button class="btn btn-sm" id="np-add-party">+ 添加</button>
        </div>
        <table class="list-table">
          <thead><tr><th style="width:70px">精灵ID</th><th style="width:60px">等级</th><th style="width:40px"></th></tr></thead>
          <tbody>${partyHtml}</tbody>
        </table>
      </div>
    `;

    document.getElementById("np-id")?.addEventListener("change", (e) => { npc.id = e.target.value; this.callbacks.onModified(this.fileKey); });
    document.getElementById("np-name")?.addEventListener("change", (e) => { npc.name = e.target.value; this.callbacks.onModified(this.fileKey); });
    document.getElementById("np-title")?.addEventListener("change", (e) => { npc.title = e.target.value; this.callbacks.onModified(this.fileKey); });
    document.getElementById("np-type")?.addEventListener("change", (e) => { npc.trainer_type = e.target.value; this.callbacks.onModified(this.fileKey); });
    document.getElementById("np-gender")?.addEventListener("change", (e) => { npc.gender = e.target.value; this.callbacks.onModified(this.fileKey); });
    document.getElementById("np-desc")?.addEventListener("change", (e) => { npc.desc = e.target.value; this.callbacks.onModified(this.fileKey); });
    document.getElementById("np-dialog")?.addEventListener("change", (e) => { npc.dialog = e.target.value; this.callbacks.onModified(this.fileKey); });

    // — 训练师数据事件 —
    const getT = () => { if (!npc.trainer) npc.trainer = {}; return npc.trainer; };
    const bindTr = (id, field) => {
      document.getElementById(id)?.addEventListener("change", (e) => { const t = getT(); t[field] = e.target.value; this.callbacks.onModified(this.fileKey); });
    };
    bindTr("tr-id", "trainer_id"); bindTr("tr-class", "class");
    bindTr("tr-dialog-before", "dialog_before"); bindTr("tr-dialog-win", "dialog_win");
    bindTr("tr-dialog-lose", "dialog_lose"); bindTr("tr-dialog-player-lose", "dialog_player_lose");
    bindTr("tr-dialog-after", "dialog_after");

    document.getElementById("tr-reward")?.addEventListener("change", (e) => { const t = getT(); t.reward = parseInt(e.target.value)||0; this.callbacks.onModified(this.fileKey); });
    document.getElementById("tr-iv-tier")?.addEventListener("change", (e) => { const t = getT(); t.iv_tier = parseInt(e.target.value); this.callbacks.onModified(this.fileKey); });

    document.getElementById("tr-add-team")?.addEventListener("click", () => {
      const t = getT();
      if (!t.team) t.team = [];
      t.team.push({ species: "", level: 5, moves: [], item: "" });
      this.callbacks.onModified(this.fileKey);
      this.renderDetail(npc);
    });

    document.querySelectorAll(".tr-team-species, .tr-team-level, .tr-team-moves, .tr-team-item").forEach(el => {
      el.addEventListener("change", () => {
        const t = getT();
        const idx = parseInt(el.dataset.idx);
        if (!t.team[idx]) return;
        if (el.classList.contains("tr-team-species")) t.team[idx].species = el.value;
        else if (el.classList.contains("tr-team-level")) t.team[idx].level = parseInt(el.value)||1;
        else if (el.classList.contains("tr-team-moves")) t.team[idx].moves = el.value ? el.value.split(",").map(s=>s.trim()).filter(Boolean) : [];
        else if (el.classList.contains("tr-team-item")) t.team[idx].item = el.value;
        this.callbacks.onModified(this.fileKey);
      });
    });
    document.querySelectorAll(".tr-team-remove").forEach(el => {
      el.addEventListener("click", () => {
        const t = getT();
        const idx = parseInt(el.dataset.idx);
        if (t.team) { t.team.splice(idx, 1); this.callbacks.onModified(this.fileKey); this.renderDetail(npc); }
      });
    });

    document.getElementById("np-add-party")?.addEventListener("click", () => {
      if (!npc.party) npc.party = [];
      npc.party.push({ id: "", level: 5 });
      this.callbacks.onModified(this.fileKey);
      this.renderDetail(npc);
    });

    document.querySelectorAll(".np-party-id").forEach(el => {
      el.addEventListener("change", () => {
        const idx = parseInt(el.dataset.idx);
        if (npc.party[idx]) { npc.party[idx].id = el.value; this.callbacks.onModified(this.fileKey); }
      });
    });
    document.querySelectorAll(".np-party-level").forEach(el => {
      el.addEventListener("change", () => {
        const idx = parseInt(el.dataset.idx);
        if (npc.party[idx]) { npc.party[idx].level = parseInt(el.value)||1; this.callbacks.onModified(this.fileKey); }
      });
    });
    document.querySelectorAll(".np-party-remove").forEach(el => {
      el.addEventListener("click", () => {
        const idx = parseInt(el.dataset.idx);
        if (npc.party) { npc.party.splice(idx, 1); this.callbacks.onModified(this.fileKey); this.renderDetail(npc); }
      });
    });

    this._loadNpcSprite(npc);
  }

  async _loadNpcSprite(npc) {
    const container = document.getElementById("npc-sprite-preview");
    if (!container) return;

    const frontPath = npc.sprite_front;
    if (!frontPath) {
      container.innerHTML = '<div class="sprite-placeholder">无精灵图</div>';
      return;
    }

    const fullPath = `${this.spritesDir}/${frontPath}`;
    try {
      const dataUrl = await readSprite(fullPath);
      container.innerHTML = `<img src="${dataUrl}" alt="${npc.name}" />`;
    } catch {
      container.innerHTML = '<div class="sprite-placeholder">无精灵图</div>';
    }
  }

  onAdd() {
    const newNpc = {
      id: `npc_${Date.now()}`,
      name: "新角色",
      trainer_type: "普通NPC",
      title: "",
      gender: "",
      desc: "",
      dialog: "",
      sprite_front: "",
      party: [],
    };
    this.data.push(newNpc);
    this.callbacks.onModified(this.fileKey);
    this._select(newNpc.id);
  }

  onDelete() {
    if (!this.currentId) return;
    const npc = this.data.find(m => m.id === this.currentId);
    if (!npc) return;
    if (!confirm(`确认删除角色「${npc.name}」？`)) return;
    const idx = this.data.findIndex(m => m.id === this.currentId);
    if (idx !== -1) this.data.splice(idx, 1);
    this.currentId = null;
    this.callbacks.onModified(this.fileKey);
    this.container.innerHTML = '<div class="placeholder">角色已删除</div>';
    this.renderList();
  }
}
