import { readSprite } from "../utils/api.js";
import { renderStatBar, renderTotalBar } from "../components/stat-bar.js";
import { escapeHtml } from "../utils/dom.js";

// 与 mon_editor.py 的 NPC_ROLE_MAP 保持一致（npcs.json 里 role 字段的真实取值是这些英文 key）
// 额外补了 "champion"（真实数据里存在，但旧编辑器的映射表里也没有）
const NPC_ROLE_MAP = {
  "": "（未设置）",
  professor: "教授",
  rival: "劲敌",
  npc: "普通NPC",
  family: "家人",
  villager: "村民",
  gym_leader: "道馆主",
  elite_four: "四天王",
  villain: "反派",
  champion: "冠军",
  trainer: "训练师",
};

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
    this.speciesSpritesDir = state.dataPaths?.sprites_dir?.path || "";
    this.roleFilter = "全部";
  }

  getData() { return this.data; }

  renderList(filter) {
    this.data = this.state.data.npcs || [];
    const q = filter !== undefined ? filter : (document.getElementById("search-input")?.value || "");
    const items = this.data.filter(m => {
      if (q && !this._match(m, q)) return false;
      return this._matchRoleFilter(m);
    });
    const list = document.getElementById("sidebar-list");

    const roleOptions = ["全部", "训练师", "非训练师", ...Object.entries(NPC_ROLE_MAP).filter(([k]) => k).map(([, v]) => v)];
    const filterHtml = `
      <div style="padding:6px 10px;border-bottom:1px solid var(--border)">
        <select id="npc-role-filter" style="width:100%;font-size:12px">
          ${roleOptions.map(o => `<option value="${o}" ${this.roleFilter === o ? "selected" : ""}>${o}</option>`).join("")}
        </select>
      </div>`;

    const itemsHtml = items.length
      ? items.map(m => {
          const isTrainer = !!m.trainer;
          return `<div class="sidebar-item ${m.id == this.currentId ? 'active' : ''}" data-id="${m.id}">
            <span class="item-name">${isTrainer ? "⚔ " : ""}${escapeHtml(m.name)}</span>
            <span style="font-size:11px;color:var(--text-muted)">${NPC_ROLE_MAP[m.role || ""] || m.role || ""}</span>
          </div>`;
        }).join("")
      : '<div class="placeholder">无角色数据</div>';

    list.innerHTML = filterHtml + itemsHtml;

    list.querySelectorAll("[data-id]").forEach(el => {
      el.addEventListener("click", () => this._select(el.dataset.id));
    });
    document.getElementById("npc-role-filter")?.addEventListener("change", (e) => {
      this.roleFilter = e.target.value;
      this.renderList(q);
    });
  }

  filterList(q) { this.renderList(q); }
  _match(m, q) { const ql=q.toLowerCase(); return m.name.toLowerCase().includes(ql) || (NPC_ROLE_MAP[m.role || ""] || "").toLowerCase().includes(ql); }
  _matchRoleFilter(m) {
    if (this.roleFilter === "全部") return true;
    const isTrainer = !!m.trainer;
    if (this.roleFilter === "训练师") return isTrainer;
    if (this.roleFilter === "非训练师") return !isTrainer;
    return (NPC_ROLE_MAP[m.role || ""] || "") === this.roleFilter;
  }

  async _select(id) {
    this.currentId = id;
    this.callbacks.onStatus(`编辑角色: ${id}`);
    const npc = this.data.find(m => m.id == id);
    if (npc) await this.renderDetail(npc);
    this.renderList();
  }

  async renderDetail(npc) {
    const t = npc.trainer || {};
    const teamHtml = (t.team || []).map((p, i) =>
      `<tr>
        <td><input type="text" value="${escapeHtml(p.species||"")}" class="tr-team-species" data-idx="${i}" style="width:80px" /></td>
        <td><input type="number" value="${escapeHtml(String(p.level||1))}" class="tr-team-level" data-idx="${i}" style="width:50px" min="1" /></td>
        <td><input type="text" value="${escapeHtml((p.moves||[]).join(","))}" class="tr-team-moves" data-idx="${i}" style="width:120px" placeholder="用逗号分隔" /></td>
        <td><input type="text" value="${escapeHtml(p.item||"")}" class="tr-team-item" data-idx="${i}" style="width:60px" /></td>
        <td><button class="remove-btn tr-team-remove" data-idx="${i}">✕</button></td>
      </tr>`
    ).join("") || '<tr><td colspan="5" style="text-align:center;color:var(--text-muted)">无队伍</td></tr>';

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
              <label>ID</label><input type="text" id="np-id" value="${escapeHtml(String(npc.id))}" />
            </div>
            <div class="form-group">
              <label>名称</label><input type="text" id="np-name" value="${escapeHtml(npc.name)}" />
            </div>
            <div class="form-group">
              <label>称号</label><input type="text" id="np-title" value="${escapeHtml(npc.title||"")}" placeholder="如「青木村的守护者」" />
            </div>
            <div class="form-group">
              <label>角色类型</label>
              <select id="np-type">${Object.entries(NPC_ROLE_MAP).map(([key, label]) =>
                `<option value="${key}" ${(npc.role || "") === key ? "selected" : ""}>${label}</option>`
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
              <textarea id="np-desc" rows="2">${escapeHtml(npc.desc||"")}</textarea>
            </div>
            <div class="form-group full-width">
              <label>对话</label>
              <textarea id="np-dialog" rows="3">${escapeHtml(npc.dialog||"")}</textarea>
            </div>
          </div>
        </div>
      </div>
      <details class="form-section" ${t.trainer_id ? "open" : ""}>
        <summary class="form-section-title">训练师数据</summary>
        <div class="form-grid">
          <div class="form-group">
            <label>训练师ID</label><input type="text" id="tr-id" value="${escapeHtml(t.trainer_id||"")}" />
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
            <textarea id="tr-dialog-before" rows="2">${escapeHtml(t.dialog_before||"")}</textarea>
          </div>
          <div class="form-group full-width">
            <label>战后对话（胜利）</label>
            <textarea id="tr-dialog-win" rows="2">${escapeHtml(t.dialog_win||"")}</textarea>
          </div>
          <div class="form-group full-width">
            <label>战后对话（失败）</label>
            <textarea id="tr-dialog-lose" rows="2">${escapeHtml(t.dialog_lose||"")}</textarea>
          </div>
          <div class="form-group full-width">
            <label>玩家败北对话</label>
            <textarea id="tr-dialog-player-lose" rows="2">${escapeHtml(t.dialog_player_lose||"")}</textarea>
          </div>
          <div class="form-group full-width">
            <label>战后对话</label>
            <textarea id="tr-dialog-after" rows="2">${escapeHtml(t.dialog_after||"")}</textarea>
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
        <div class="form-section" style="margin-top:10px">
          <div class="form-section-title">选中精灵预览</div>
          <div id="team-mon-preview-body"><div class="placeholder">点击/编辑上方队伍中的精灵名称查看预览</div></div>
        </div>
      </details>
    `;

    document.getElementById("np-id")?.addEventListener("change", (e) => { this.callbacks.saveHistory(this.fileKey); npc.id = e.target.value; this.callbacks.onModified(this.fileKey); });
    document.getElementById("np-name")?.addEventListener("change", (e) => { this.callbacks.saveHistory(this.fileKey); npc.name = e.target.value; this.callbacks.onModified(this.fileKey); });
    document.getElementById("np-title")?.addEventListener("change", (e) => { this.callbacks.saveHistory(this.fileKey); npc.title = e.target.value; this.callbacks.onModified(this.fileKey); });
    document.getElementById("np-type")?.addEventListener("change", (e) => { this.callbacks.saveHistory(this.fileKey); npc.role = e.target.value; this.callbacks.onModified(this.fileKey); });
    document.getElementById("np-gender")?.addEventListener("change", (e) => { this.callbacks.saveHistory(this.fileKey); npc.gender = e.target.value; this.callbacks.onModified(this.fileKey); });
    document.getElementById("np-desc")?.addEventListener("change", (e) => { this.callbacks.saveHistory(this.fileKey); npc.desc = e.target.value; this.callbacks.onModified(this.fileKey); });
    document.getElementById("np-dialog")?.addEventListener("change", (e) => { this.callbacks.saveHistory(this.fileKey); npc.dialog = e.target.value; this.callbacks.onModified(this.fileKey); });

    // — 训练师数据事件 —
    const getT = () => { if (!npc.trainer) npc.trainer = {}; return npc.trainer; };
    const bindTr = (id, field) => {
      document.getElementById(id)?.addEventListener("change", (e) => { this.callbacks.saveHistory(this.fileKey); const t = getT(); t[field] = e.target.value; this.callbacks.onModified(this.fileKey); });
    };
    bindTr("tr-id", "trainer_id"); bindTr("tr-class", "class");
    bindTr("tr-dialog-before", "dialog_before"); bindTr("tr-dialog-win", "dialog_win");
    bindTr("tr-dialog-lose", "dialog_lose"); bindTr("tr-dialog-player-lose", "dialog_player_lose");
    bindTr("tr-dialog-after", "dialog_after");

    document.getElementById("tr-reward")?.addEventListener("change", (e) => { this.callbacks.saveHistory(this.fileKey); const t = getT(); t.reward = parseInt(e.target.value)||0; this.callbacks.onModified(this.fileKey); });
    document.getElementById("tr-iv-tier")?.addEventListener("change", (e) => { this.callbacks.saveHistory(this.fileKey); const t = getT(); t.iv_tier = parseInt(e.target.value); this.callbacks.onModified(this.fileKey); });

    document.getElementById("tr-add-team")?.addEventListener("click", () => {
      this.callbacks.saveHistory(this.fileKey);
      const t = getT();
      if (!t.team) t.team = [];
      t.team.push({ species: "", level: 5, moves: [], item: "" });
      this.callbacks.onModified(this.fileKey);
      this.renderDetail(npc);
    });

    document.querySelectorAll(".tr-team-species, .tr-team-level, .tr-team-moves, .tr-team-item").forEach(el => {
      el.addEventListener("change", () => {
        this.callbacks.saveHistory(this.fileKey);
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
    document.querySelectorAll(".tr-team-species").forEach(el => {
      el.addEventListener("focus", () => this._renderTeamPreview(el.value));
      el.addEventListener("input", () => this._renderTeamPreview(el.value));
    });
    document.querySelectorAll(".tr-team-remove").forEach(el => {
      el.addEventListener("click", () => {
        this.callbacks.saveHistory(this.fileKey);
        const t = getT();
        const idx = parseInt(el.dataset.idx);
        if (t.team) { t.team.splice(idx, 1); this.callbacks.onModified(this.fileKey); this.renderDetail(npc); }
      });
    });


    this._loadNpcSprite(npc);
  }

  async _renderTeamPreview(speciesName) {
    const body = document.getElementById("team-mon-preview-body");
    if (!body) return;
    if (!speciesName) {
      body.innerHTML = '<div class="placeholder">点击/编辑上方队伍中的精灵名称查看预览</div>';
      return;
    }
    const sp = (this.state.data.species || []).find(s => s.name === speciesName);
    if (!sp) {
      body.innerHTML = `<div class="placeholder">未找到精灵「${escapeHtml(speciesName)}」</div>`;
      return;
    }
    const base = sp.base || {};
    const bst = ["hp", "atk", "def", "sp_atk", "sp_def", "spd"].reduce((s, k) => s + (base[k] || 0), 0);
    body.innerHTML = `
      <div style="display:flex;gap:12px;align-items:flex-start">
        <div class="sprite-preview" id="team-preview-sprite" style="width:80px;height:80px;flex-shrink:0">
          <div class="sprite-placeholder">加载中...</div>
        </div>
        <div style="flex:1;min-width:0">
          <div style="font-weight:600">${escapeHtml(sp.name)} <span style="font-weight:400;color:var(--text-muted);font-size:12px">${escapeHtml(sp.type1)}${sp.type2 ? "/" + escapeHtml(sp.type2) : ""}</span></div>
          <div class="stat-group" style="margin-top:6px">
            ${renderStatBar("hp", base.hp || 0)}
            ${renderStatBar("atk", base.atk || 0)}
            ${renderStatBar("def", base.def || 0)}
            ${renderStatBar("spatk", base.sp_atk || 0)}
            ${renderStatBar("spdef", base.sp_def || 0)}
            ${renderStatBar("spd", base.spd || 0)}
            ${renderTotalBar(bst)}
          </div>
        </div>
      </div>
    `;
    const sprContainer = document.getElementById("team-preview-sprite");
    if (sprContainer && this.speciesSpritesDir) {
      try {
        const dataUrl = await readSprite(`${this.speciesSpritesDir}/${sp.name}front.png`);
        sprContainer.innerHTML = `<img src="${dataUrl}" alt="${escapeHtml(sp.name)}" />`;
      } catch {
        sprContainer.innerHTML = '<div class="sprite-placeholder">无精灵图</div>';
      }
    }
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
      container.innerHTML = `<img src="${dataUrl}" alt="${escapeHtml(npc.name)}" />`;
    } catch {
      container.innerHTML = '<div class="sprite-placeholder">无精灵图</div>';
    }
  }

  onAdd() {
    this.callbacks.saveHistory(this.fileKey);
    const newNpc = {
      id: `npc_${Date.now()}`,
      name: "新角色",
      role: "npc",
      title: "",
      gender: "",
      desc: "",
      dialog: "",
      sprite_front: "",
    };
    this.data.push(newNpc);
    this.callbacks.onModified(this.fileKey);
    this._select(newNpc.id);
  }

  onDelete() {
    this.callbacks.saveHistory(this.fileKey);
    if (!this.currentId) return;
    const npc = this.data.find(m => m.id == this.currentId);
    if (!npc) return;
    if (!confirm(`确认删除角色「${npc.name}」？`)) return;
    const idx = this.data.findIndex(m => m.id == this.currentId);
    if (idx !== -1) this.data.splice(idx, 1);
    this.currentId = null;
    this.callbacks.onModified(this.fileKey);
    this.container.innerHTML = '<div class="placeholder">角色已删除</div>';
    this.renderList();
  }
}
