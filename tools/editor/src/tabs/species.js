import { TYPE_COLORS, contrastTextColor } from "../components/type-badge.js";
import { renderStatBar, renderTotalBar, STAT_LABELS, STAT_COLORS } from "../components/stat-bar.js";
import { readSprite } from "../utils/api.js";
import { openModal } from "../components/modal.js";
import { attachSearchableSelect } from "../components/searchable-select.js";
import { computeMatchup } from "../components/type-chart.js";

const GROWTH_RATES = ["早熟", "正常", "大器晚成"];

const TIERS = ["凡", "灵", "玄", "地", "神", "天"];

export class SpeciesTab {
  constructor(container, state, fileKey, callbacks) {
    this.container = container;
    this.state = state;
    this.fileKey = fileKey;
    this.callbacks = callbacks;
    this.currentId = null;
    this.data = state.data.species || [];
    this.filteredData = this.data;
    this.spritesDir = state.dataPaths?.sprites_dir?.path || "";
    this.typeFilter = "全部";
    this.tierFilter = "全部";
  }

  getData() {
    return this.data;
  }

  // ===== Sidebar List =====
  renderList(filter) {
    this.data = this.state.data.species || [];
    const q = filter !== undefined ? filter : (document.getElementById("search-input")?.value || "");

    this.filteredData = this.data
      .filter(m => (!q || this._matchFilter(m, q)) && this._matchTypeTier(m))
      .sort((a, b) => a.id - b.id);

    const list = document.getElementById("sidebar-list");

    const typeOptions = ["全部", ...Object.keys(TYPE_COLORS)];
    const tierOptions = ["全部", ...TIERS];
    const filterHtml = `
      <div class="sidebar-filter-bar">
        <select id="species-type-filter">${typeOptions.map(t => `<option value="${t}" ${this.typeFilter === t ? "selected" : ""}>${t === "全部" ? "全部属性" : t}</option>`).join("")}</select>
        <select id="species-tier-filter">${tierOptions.map(t => `<option value="${t}" ${this.tierFilter === t ? "selected" : ""}>${t === "全部" ? "全部品阶" : t}</option>`).join("")}</select>
      </div>`;

    const itemsHtml = this.filteredData.length
      ? this.filteredData.map(m =>
          `<div class="sidebar-item ${m.id === this.currentId ? "active" : ""}" data-id="${m.id}">
            <span class="item-id">#${String(m.id).padStart(3, "0")}</span>
            <span class="item-name">${m.name}</span>
            <span class="type-badge type-badge-sm" style="background:${TYPE_COLORS[m.type1]||"#999"}; color:${contrastTextColor(TYPE_COLORS[m.type1]||"#999")}">${m.type1}</span>
            ${m.type2 ? `<span class="type-badge type-badge-sm" style="background:${TYPE_COLORS[m.type2]||"#999"}; color:${contrastTextColor(TYPE_COLORS[m.type2]||"#999")}">${m.type2}</span>` : ""}
          </div>`
        ).join("")
      : '<div class="placeholder">没有精灵数据</div>';

    list.innerHTML = filterHtml + itemsHtml;

    list.querySelectorAll(".sidebar-item").forEach(el => {
      el.addEventListener("click", () => this._selectMon(parseInt(el.dataset.id)));
    });
    document.getElementById("species-type-filter")?.addEventListener("change", (e) => {
      this.typeFilter = e.target.value;
      this.renderList(q);
    });
    document.getElementById("species-tier-filter")?.addEventListener("change", (e) => {
      this.tierFilter = e.target.value;
      this.renderList(q);
    });
  }

  filterList(query) {
    this.renderList(query);
  }

  _matchFilter(m, query) {
    const q = query.toLowerCase();
    return m.name.toLowerCase().includes(q) ||
           String(m.id).includes(q) ||
           (m.type1 && m.type1.includes(q)) ||
           (m.type2 && m.type2.includes(q));
  }

  _matchTypeTier(m) {
    if (this.typeFilter !== "全部" && m.type1 !== this.typeFilter && m.type2 !== this.typeFilter) return false;
    if (this.tierFilter !== "全部" && m.tier !== this.tierFilter) return false;
    return true;
  }

  // ===== Species Selection =====
  async _selectMon(id) {
    try {
      this.currentId = id;
      const mon = this._getSpecies(id);
      this.callbacks.onStatus(`编辑: ${mon?.name || id}`);
      await this.renderDetail(id);
      this.renderList();
    } catch (err) {
      console.error("选择精灵失败:", err);
      this.callbacks.onStatus(`错误: ${err}`);
    }
  }

  _getSpecies(id) {
    return this.data.find(m => m.id == id);
  }

  // ===== Detail View =====
  async renderDetail(id) {
    try {
      await this._doRender(id);
    } catch (err) {
      console.error("渲染精灵详情失败:", err);
      this.container.innerHTML = `<div class="placeholder">渲染错误: ${err.message || err}</div>`;
    }
  }

  async _doRender(id) {
    const mon = this._getSpecies(id);
    if (!mon) {
      this.container.innerHTML = '<div class="placeholder">未找到精灵</div>';
      return;
    }

    // Debug info in console
    console.log("渲染精灵:", id, mon?.name);

    const base = mon.base || {};
    const hp = base.hp || 0, atk = base.atk || 0, def = base.def || 0;
    const spatk = base.sp_atk || 0;
    const spdef = base.sp_def || 0;
    const spd = base.spd || 0;
    const bst = hp + atk + def + spatk + spdef + spd;

    this.container.innerHTML = `
      <!-- Top: Sprites + Basic Info (left) / Stats (right) -->
      <div class="auto-grid">
        <div class="form-section-stack">
          <div class="form-section">
            <div style="display:flex;gap:12px">
              <div class="sprite-preview" id="sprite-preview">
                <div class="sprite-placeholder">加载中...</div>
              </div>
              <div class="sprite-preview" id="sprite-back-preview">
                <div class="sprite-placeholder">背面</div>
              </div>
            </div>
          </div>

          <div class="form-section">
            <div class="form-section-title">基本信息</div>
            <div class="form-grid">
              <div class="form-group">
                <label>ID</label>
                <input type="number" id="field-id" value="${mon.id}" min="1" />
              </div>
              <div class="form-group">
                <label>名称</label>
                <input type="text" id="field-name" value="${mon.name}" />
              </div>
              <div class="form-group">
                <label>属性 1</label>
                <select id="field-type1">${this._typeOptions(mon.type1)}</select>
              </div>
              <div class="form-group">
                <label>属性 2</label>
                <select id="field-type2"><option value="">无</option>${this._typeOptions(mon.type2)}</select>
              </div>
              <div class="form-group">
                <label>品阶
                  <button type="button" class="btn btn-sm" id="btn-suggest-tier"
                          style="margin-left:6px;padding:1px 6px;font-size:11px"
                          title="根据当前种族值总和自动推荐品阶">⚡推荐</button>
                </label>
                <select id="field-tier">${TIERS.map(t =>
                  `<option value="${t}" ${mon.tier === t ? "selected" : ""}>${t}</option>`
                ).join("")}</select>
              </div>
              <div class="form-group">
                <label>捕获率</label>
                <input type="number" id="field-catch" value="${mon.catch_rate || 45}" min="0" max="255" />
              </div>
              <div class="form-group">
                <label>经验值</label>
                <input type="number" id="field-exp" value="${mon.exp_yield || 100}" min="0" />
              </div>
              <div class="form-group">
                <label>成长率</label>
                <select id="field-growth">${GROWTH_RATES.map(g =>
                  `<option value="${g}" ${mon.growth_rate === g ? "selected" : ""}>${g}</option>`
                ).join("")}</select>
              </div>
              <div class="form-group">
                <label>性别比例（雌性 %）</label>
                <div style="display:flex;align-items:center;gap:8px">
                  <input type="range" id="field-gender-slider" min="0" max="100" step="10"
                         value="${this._parseGenderRatio(mon.gender_ratio).femalePct}"
                         ${this._parseGenderRatio(mon.gender_ratio).isAsexual ? "disabled" : ""}
                         style="flex:1" />
                  <span id="field-gender-value" style="width:34px;text-align:right;font-size:12px">${this._parseGenderRatio(mon.gender_ratio).femalePct}%</span>
                </div>
                <label style="display:flex;align-items:center;gap:4px;font-size:12px">
                  <input type="checkbox" id="field-gender-asexual" ${this._parseGenderRatio(mon.gender_ratio).isAsexual ? "checked" : ""} /> 无性别
                </label>
              </div>
              <div class="form-group">
                <label>身高 (m)</label>
                <input type="text" id="field-height" value="${mon.height || ""}" />
              </div>
              <div class="form-group">
                <label>体重 (kg)</label>
                <input type="text" id="field-weight" value="${mon.weight || ""}" />
              </div>
              <div class="form-group">
                <label>特性 1</label>
                <input type="text" id="field-ability1" value="${mon.abilities?.[0] || ""}" />
              </div>
              <div class="form-group">
                <label>特性 2</label>
                <input type="text" id="field-ability2" value="${mon.abilities?.[1] || ""}" />
              </div>
            </div>
          </div>
        </div>

        <div class="form-section-stack">
          <div class="form-section">
            <div class="form-section-title">种族值 <span style="font-weight:400;color:var(--text-muted);font-size:12px">（右侧数值为 Lv60 / Lv120 实际数值，个体值/努力值均取满）</span></div>
            <div class="form-grid" style="margin-bottom:12px">
              <div class="form-group"><label>体力 <span class="stat-label-en">HP</span></label><input type="number" id="stat-hp" value="${hp}" min="0" max="255" /></div>
              <div class="form-group"><label>物攻 <span class="stat-label-en">ATK</span></label><input type="number" id="stat-atk" value="${atk}" min="0" max="255" /></div>
              <div class="form-group"><label>物防 <span class="stat-label-en">DEF</span></label><input type="number" id="stat-def" value="${def}" min="0" max="255" /></div>
              <div class="form-group"><label>特攻 <span class="stat-label-en">SP.ATK</span></label><input type="number" id="stat-spatk" value="${spatk}" min="0" max="255" /></div>
              <div class="form-group"><label>特防 <span class="stat-label-en">SP.DEF</span></label><input type="number" id="stat-spdef" value="${spdef}" min="0" max="255" /></div>
              <div class="form-group"><label>速度 <span class="stat-label-en">SPD</span></label><input type="number" id="stat-spd" value="${spd}" min="0" max="255" /></div>
            </div>
            <div class="stat-group">
              ${renderStatBar("hp", hp)}
              ${renderStatBar("atk", atk)}
              ${renderStatBar("def", def)}
              ${renderStatBar("spatk", spatk)}
              ${renderStatBar("spdef", spdef)}
              ${renderStatBar("spd", spd)}
              ${renderTotalBar(bst)}
            </div>
          </div>

          <!-- Encounters -->
          <div class="form-section">
            <div class="section-header">
              <span class="form-section-title">遭遇地</span>
              <div>
                <button class="btn btn-sm" id="btn-add-enc">+ 添加地点</button>
              </div>
            </div>
            <div id="enc-container">
              ${this._renderEncounters(mon)}
            </div>
          </div>
        </div>
      </div>

      <!-- Evolution -->
      <div class="form-section form-section-tall">
        <div class="section-header">
          <span class="form-section-title">进化链</span>
          <div>
            <button class="btn btn-sm" id="btn-add-evo">+ 添加进化</button>
          </div>
        </div>
        <div id="evo-container">
          ${this._renderEvoChain(mon)}
        </div>
      </div>

      <!-- Learnset -->
      <div class="form-section">
        <div class="section-header">
          <span class="form-section-title">学习技能</span>
          <div>
            <button class="btn btn-sm" id="btn-add-learn">+ 添加技能</button>
          </div>
        </div>
        <div id="learnset-table">
          ${this._renderLearnset(mon)}
        </div>
      </div>

      <!-- Description + Type Matchup -->
      <div class="auto-grid">
        <div class="form-section">
          <div class="form-section-title">图鉴描述</div>
          <div class="form-grid">
            <div class="form-group full-width">
              <textarea id="field-desc" rows="3">${mon.desc || ""}</textarea>
            </div>
            <div class="form-group full-width">
              <label>设计灵感来源</label>
              <input type="text" id="field-design-origin" value="${mon.design_origin || ""}" placeholder="例：瑞兽火猫 + 祥云纹" />
            </div>
          </div>
        </div>

        <div class="form-section">
          <div class="form-section-title">属性克制</div>
          <div id="matchup-container">
            ${this._renderMatchup(mon)}
          </div>
        </div>
      </div>
    `;

    this._bindDetailEvents(mon);
    this._loadSprite(mon.id);
  }

  // ===== Add / Delete =====
  onAdd() {
    const maxId = this.data.reduce((max, m) => Math.max(max, m.id || 0), 0);
    const newMon = {
      id: maxId + 1,
      name: "新精灵",
      type1: "木",
      type2: "",
      base: { hp: 50, atk: 50, def: 50, sp_atk: 50, sp_def: 50, spd: 50 },
      tier: "凡",
      catch_rate: 45,
      exp_yield: 100,
      growth_rate: "早熟",
      desc: "",
      height: "",
      weight: "",
      gender_ratio: "50/50",
      evolutions: [],
      learnset: [],
      abilities: [],
    };
    this.data.push(newMon);
    this.callbacks.onModified(this.fileKey);
    this._selectMon(newMon.id);
  }

  onDelete() {
    if (!this.currentId) return;
    const mon = this._getSpecies(this.currentId);
    if (!mon) return;
    const name = mon.name || `#${mon.id}`;
    if (!confirm(`确认删除「${name}」？此操作不可撤销。`)) return;
    const idx = this.data.findIndex(m => m.id == this.currentId);
    if (idx !== -1) this.data.splice(idx, 1);
    this.currentId = null;
    this.callbacks.onModified(this.fileKey);
    this.container.innerHTML = '<div class="placeholder">精灵已删除</div>';
    this.renderList();
  }

  _getAbilitiesList() {
    const abData = this.state.data.abilities || [];
    return abData.map(a => a.name).filter(Boolean);
  }

  _typeOptions(selected) {
    return Object.keys(TYPE_COLORS).map(t =>
      `<option value="${t}" ${t === selected ? "selected" : ""}>${t}</option>`
    ).join("");
  }

  // 性别比例："87.5/12.5"(雄/雌) 或 "无性别"；滑动条代表雌性% 每10%一档，对齐原编辑器
  _parseGenderRatio(val) {
    if (val === "无性别") return { isAsexual: true, femalePct: 0 };
    const parts = String(val || "").split("/");
    const f = parts.length === 2 ? Math.round((parseFloat(parts[1]) || 0) / 10) * 10 : 50;
    return { isAsexual: false, femalePct: f };
  }

  _bindGenderRatio(mon) {
    const slider = document.getElementById("field-gender-slider");
    const valueLbl = document.getElementById("field-gender-value");
    const asexualChk = document.getElementById("field-gender-asexual");
    if (!slider || !asexualChk) return;

    const applyRatio = () => {
      if (asexualChk.checked) {
        mon.gender_ratio = "无性别";
      } else {
        const f = parseInt(slider.value) || 0;
        mon.gender_ratio = `${100 - f}/${f}`;
      }
      this.callbacks.onModified(this.fileKey);
    };

    slider.addEventListener("input", () => { if (valueLbl) valueLbl.textContent = `${slider.value}%`; });
    slider.addEventListener("change", applyRatio);
    asexualChk.addEventListener("change", () => {
      slider.disabled = asexualChk.checked;
      applyRatio();
    });
  }

  _speciesByName(name) {
    return this.data.find(s => s.name === name);
  }

  // 精灵自身的进化分支：优先用 evolutions 数组，为空时兜底旧版 evolves_into/evolve_level 单分支字段
  // （现存数据里两者常常并存，但也有极少数精灵只有旧字段，如"鸣武者"）
  _ownEvoBranches(sp) {
    let branches = Array.isArray(sp.evolutions) ? sp.evolutions : [];
    if (branches.length === 0 && sp.evolves_into) {
      branches = [{ into: sp.evolves_into, level: sp.evolve_level }];
    }
    return branches.filter(b => b && b.into && this._speciesByName(b.into));
  }

  _evoCondLabel(evo) {
    if (evo.level) return `Lv${evo.level}`;
    if (evo.item) return evo.item;
    return "?";
  }

  // 沿 evolutions/evolves_into 向上找祖先链，对齐 mon_editor.py 的 _refresh_evo_compare
  _findAncestorChain(mon) {
    const chain = [];
    let cur = mon.name;
    const visited = new Set([mon.name]);
    while (true) {
      const pre = this.data.find(s => this._ownEvoBranches(s).some(e => e.into === cur));
      if (!pre || visited.has(pre.name)) break;
      visited.add(pre.name);
      const evo = this._ownEvoBranches(pre).find(e => e.into === cur);
      chain.push({ sp: pre, cond: this._evoCondLabel(evo) });
      cur = pre.name;
    }
    chain.reverse();
    return chain;
  }

  // 进化家族里的一张精灵卡片：属性 + 六维种族值迷你条，方便设计时直观对比上一形态
  _evoCardHtml(sp, isCurrent) {
    const t2 = sp.type2 ? `/${sp.type2}` : "";
    const base = sp.base || {};
    let total = 0;
    const statRows = Object.keys(STAT_LABELS).map(key => {
      const dataKey = key === "spatk" ? "sp_atk" : key === "spdef" ? "sp_def" : key;
      const v = base[dataKey] || 0;
      total += v;
      const pct = Math.min(100, (v / 255) * 100);
      return `<div class="evo-card-stat-row">
        <span class="evo-card-stat-label">${STAT_LABELS[key].slice(0, 3)}</span>
        <div class="evo-card-stat-track"><div class="evo-card-stat-fill" style="width:${pct}%;background:${STAT_COLORS[key]}"></div></div>
        <span class="evo-card-stat-value">${v}</span>
      </div>`;
    }).join("");
    return `<div class="evo-stat-card ${isCurrent ? "current" : ""}" ${!isCurrent ? `data-evo-goto="${sp.id}"` : ""}>
      <div class="evo-card-name">${sp.name}</div>
      <div class="evo-card-type">${sp.type1}${t2}</div>
      ${statRows}
      <div class="evo-card-total">总计 ${total}</div>
    </div>`;
  }

  _renderEvoChain(mon) {
    const ancestors = this._findAncestorChain(mon);
    const branches = this._ownEvoBranches(mon);

    if (ancestors.length === 0 && branches.length === 0) {
      return '<div style="color:var(--text-muted);padding:8px">无进化</div>';
    }

    let html = '<div class="evo-chain">';

    ancestors.forEach(({ sp, cond }) => {
      html += this._evoCardHtml(sp, false);
      html += `<span class="evo-arrow-label">${cond}</span>`;
    });

    html += this._evoCardHtml(mon, true);

    branches.forEach((evo, i) => {
      if (i > 0) html += '<div class="evo-branch-sep"></div>';
      html += `<span class="evo-arrow-label editable" data-evo-idx="${i}" title="点击编辑">${this._evoCondLabel(evo)} ✎</span>`;
      let curSp = this._speciesByName(evo.into);
      if (!curSp) return;
      html += this._evoCardHtml(curSp, false);

      // 单一分支时自动往下延伸整条链；出现分叉（同一精灵有多个未见过的下一形态）就停在这里
      const seenFwd = new Set([mon.name, curSp.name]);
      while (true) {
        const fe = this._ownEvoBranches(curSp).filter(e => !seenFwd.has(e.into));
        if (fe.length !== 1) break;
        const next = fe[0];
        const nextSp = this._speciesByName(next.into);
        if (!nextSp) break;
        html += `<span class="evo-arrow-label">${this._evoCondLabel(next)}</span>`;
        html += this._evoCardHtml(nextSp, false);
        seenFwd.add(nextSp.name);
        curSp = nextSp;
      }
    });

    html += '</div>';
    return html;
  }

  // 首次编辑时，把只存在于旧版 evolves_into/evolve_level 字段的分支迁移进 evolutions 数组
  _ensureOwnEvolutionsArray(mon) {
    if (!Array.isArray(mon.evolutions) || mon.evolutions.length === 0) {
      mon.evolutions = this._ownEvoBranches(mon).map(b => {
        const out = { into: b.into };
        if (b.level) out.level = b.level;
        if (b.item) out.item = b.item;
        return out;
      });
    }
  }

  // 添加/编辑进化分支：目标精灵(可搜索下拉)+等级+进化道具(可搜索下拉)
  _openEvoModal(evo, onSave, mon) {
    const speciesNames = this.data.map(s => s.name).filter(n => n !== mon.name).sort();
    const itemNames = (this.state.data.items || []).map(it => it.name).sort();

    const draft = { into: evo.into || "", level: evo.level ?? "", item: evo.item || "" };

    openModal({
      title: "进化分支",
      bodyHtml: `
        <div class="form-group">
          <label>进化为</label>
          <input type="text" id="evo-into-input" />
        </div>
        <div class="form-group">
          <label>等级（留空则不限等级）</label>
          <input type="number" id="evo-level-input" min="1" max="120" value="${draft.level}" />
        </div>
        <div class="form-group">
          <label>进化道具（留空则无）</label>
          <input type="text" id="evo-item-input" />
        </div>
      `,
      onMount: (body) => {
        attachSearchableSelect(body.querySelector("#evo-into-input"), { items: speciesNames, value: draft.into });
        attachSearchableSelect(body.querySelector("#evo-item-input"), { items: itemNames, value: draft.item });
      },
      onConfirm: (body) => {
        // 直接读输入框的实时 value，而不是靠 onChange 回调的 draft
        // （searchable-select 的 blur→onChange 有意延迟，点确定按钮时可能还没触发）
        const into = body.querySelector("#evo-into-input").value.trim();
        const level = body.querySelector("#evo-level-input").value;
        const item = body.querySelector("#evo-item-input").value.trim();
        if (!into) {
          this.callbacks.onStatus("请填写进化目标精灵");
          return false;
        }
        const updated = { into };
        if (String(level).trim()) updated.level = parseInt(level) || 0;
        if (item) updated.item = item;
        onSave(updated);
        this.callbacks.onModified(this.fileKey);
        this.renderDetail(mon.id);
      },
    });
  }

  // 添加学习技能：等级 + 属性筛选(先缩小范围) + 技能名可搜索下拉(按属性过滤) + 实时预览
  _openAddLearnModal(mon) {
    const moves = this.state.data.moves || [];
    const types = ["全部", ...Object.keys(TYPE_COLORS)];
    let currentType = "全部";
    const namesForType = (t) => moves
      .filter(m => t === "全部" || m.type === t)
      .map(m => m.name).sort();

    let ss; // searchable-select handle for the move-name input, rebuilt when type filter changes

    openModal({
      title: "添加学习技能",
      bodyHtml: `
        <div class="form-group">
          <label>等级</label>
          <input type="number" id="learn-level-input" min="0" max="120" value="1" />
        </div>
        <div class="form-group">
          <label>属性筛选</label>
          <select id="learn-type-filter">${types.map(t => `<option value="${t}">${t}</option>`).join("")}</select>
        </div>
        <div class="form-group">
          <label>技能</label>
          <input type="text" id="learn-name-input" />
        </div>
        <div class="modal-info-box" id="learn-move-info">选择技能查看详情</div>
      `,
      onMount: (body) => {
        const nameInput = body.querySelector("#learn-name-input");
        const infoBox = body.querySelector("#learn-move-info");
        const draft = { name: "" };

        const updateInfo = () => {
          const m = moves.find(mv => mv.name === draft.name);
          if (!m) { infoBox.textContent = "（未找到该技能）"; return; }
          let txt = `属性: ${m.type || "?"}   分类: ${m.category || "?"}   威力: ${m.power ?? "-"}   命中: ${m.accuracy ?? "-"}   PP: ${m.max_pp ?? "-"}`;
          if (m.description) txt += `\n${m.description}`;
          infoBox.textContent = txt;
        };

        ss = attachSearchableSelect(nameInput, {
          items: namesForType(currentType),
          onChange: (v) => { draft.name = v; updateInfo(); },
        });

        body.querySelector("#learn-type-filter").addEventListener("change", (e) => {
          currentType = e.target.value;
          ss.setItems(namesForType(currentType));
          ss.setValue("");
          draft.name = "";
          updateInfo();
        });
      },
      onConfirm: (body) => {
        // 直接读输入框实时 value，避免 searchable-select 的延迟 onChange 在点确定时还没触发
        const level = parseInt(body.querySelector("#learn-level-input").value) || 0;
        const name = body.querySelector("#learn-name-input").value.trim();
        if (!name) {
          this.callbacks.onStatus("请选择技能");
          return false;
        }
        mon.learnset.push({ level, name });
        this.callbacks.onModified(this.fileKey);
        this.renderDetail(mon.id);
      },
    });
  }

  _renderLearnset(mon) {
    if (!mon.learnset || mon.learnset.length === 0) {
      return '<div style="color:var(--text-muted);padding:8px">无技能</div>';
    }

    const CAT_LABEL = { "物理": "物", "特殊": "特", "变化": "变" };
    const moves = this.state.data.moves || [];

    // 保留在 mon.learnset 里的原始下标（存储顺序），展示时再按等级排序，
    // 避免排序后下标错位导致编辑/删除改到别的技能
    const withIdx = mon.learnset.map((l, idx) => ({ ...l, _idx: idx }));
    const sorted = withIdx.sort((a, b) => (a.level || 0) - (b.level || 0));

    return `<div class="learn-grid">
      ${sorted.map(l => {
        const info = moves.find(m => m.name === l.name);
        const badge = info
          ? `<span class="learn-move-badge" style="background:${(TYPE_COLORS[info.type] || "#999")};color:${contrastTextColor(TYPE_COLORS[info.type] || "#999")}">${info.type || "?"}·${CAT_LABEL[info.category] || info.category || "?"}${info.category !== "变化" ? `·威力${info.power ?? "-"}` : ""}</span>`
          : '<span class="learn-move-badge learn-move-badge-unknown">未知技能</span>';
        return `<div class="learn-card">
          <input type="number" value="${l.level || 0}" class="learn-level" data-idx="${l._idx}" style="width:40px" />
          <div class="learn-card-main">
            <input type="text" value="${l.name || ""}" class="learn-name" data-idx="${l._idx}" />
            ${badge}
          </div>
          <button class="remove-btn learn-remove" data-idx="${l._idx}">✕</button>
        </div>`;
      }).join("")}
    </div>`;
  }

  _renderEncounters(mon) {
    if (!mon.encounters || mon.encounters.length === 0) {
      return '<div style="color:var(--text-muted);padding:8px">无遭遇数据</div>';
    }
    return mon.encounters.map((enc, i) =>
      `<div class="enc-item" data-enc-idx="${i}">
        <input type="text" class="enc-location" data-idx="${i}" value="${enc.location || ""}" placeholder="地点" />
        <input type="number" class="enc-rate" data-idx="${i}" value="${enc.rate || 0}" min="0" max="100" style="width:60px" placeholder="%" />
        <button class="remove-btn enc-remove" data-idx="${i}">✕</button>
      </div>`
    ).join("");
  }

  _renderMatchup(mon) {
    const t1 = mon.type1, t2 = mon.type2;
    if (!t1) return '<div style="color:var(--text-muted)">请先选择属性</div>';

    const { offense, defense } = computeMatchup(t1, t2);

    const chip = (typ, val) => {
      const bg = TYPE_COLORS[typ] || "#999";
      return `<span class="type-badge type-badge-sm" style="background:${bg};color:${contrastTextColor(bg)}">${typ} ${val}</span>`;
    };
    const section = (title, entries) => entries.length ? `
      <div style="margin-bottom:8px">
        <div style="font-size:11px;color:var(--text-muted);margin-bottom:4px">${title}</div>
        <div style="display:flex;flex-wrap:wrap;gap:4px">${entries.map(([t, v]) => chip(t, v)).join("")}</div>
      </div>` : "";

    return `
      ${section("克制（主动攻击时效果拔群）", offense.superEffective)}
      ${section("弱点（被攻击时效果拔群）", defense.weak)}
      ${section("抵抗（被攻击时效果不佳）", defense.resist)}
      ${section("免疫", defense.immune)}
      ${!offense.superEffective.length && !defense.weak.length && !defense.resist.length && !defense.immune.length
        ? '<div style="color:var(--text-muted)">无特殊克制关系</div>' : ""}
    `;
  }

  // ===== Sprite Loading =====
  // 命名约定：{精灵名}front.png / {精灵名}back.png（不是数字ID），见 README「添加自定义精灵图片」
  async _loadSprite(id) {
    const container = document.getElementById("sprite-preview");
    if (!container) return;
    const mon = this._getSpecies(id);
    const name = mon?.name || "";

    const path = `${this.spritesDir}/${name}front.png`;
    try {
      const dataUrl = await readSprite(path);
      container.innerHTML = `
        <img src="${dataUrl}" alt="${name} 正面" />
        <div class="sprite-controls">
          <button class="btn btn-sm" id="btn-toggle-shiny" title="闪光预览">✨</button>
        </div>
      `;
      const shinyBtn = document.getElementById("btn-toggle-shiny");
      if (shinyBtn) {
        const shinyPath = `${this.spritesDir}/${name}front_shiny.png`;
        shinyBtn.addEventListener("click", async () => {
          try {
            const shinyDataUrl = await readSprite(shinyPath);
            const img = container.querySelector("img");
            if (img) img.src = shinyDataUrl;
          } catch {
            this.callbacks.onStatus("无闪光精灵图");
          }
        });
      }
    } catch {
      container.innerHTML = '<div class="sprite-placeholder">无精灵图</div>';
      console.warn("[species] front sprite load failed for", name);
    }

    // Back sprite
    const backContainer = document.getElementById("sprite-back-preview");
    if (backContainer) {
      const backPath = `${this.spritesDir}/${name}back.png`;
      try {
        const backDataUrl = await readSprite(backPath);
        backContainer.innerHTML = `<img src="${backDataUrl}" alt="${name} 背面" />`;
      } catch {
        backContainer.innerHTML = '<div class="sprite-placeholder">无背面图</div>';
      }
    }
  }

  // ===== Event Binding =====
  _bindDetailEvents(mon) {
    const bind = (id, field, parser) => {
      const el = document.getElementById(id);
      if (!el) return;
      el.addEventListener("change", () => {
        mon[field] = parser ? parser(el.value) : el.value;
        this.callbacks.onModified(this.fileKey);
      });
    };

    const bindNumeric = (id, field) => bind(id, field, v => v === "" ? 0 : parseInt(v) || 0);
    const bindStr = (id, field) => bind(id, field, v => v);

    // Basic fields
    bindNumeric("field-id", "id");
    bindStr("field-name", "name");
    bind("field-type1", "type1");
    bind("field-type2", "type2");
    bind("field-tier", "tier");
    bindNumeric("field-catch", "catch_rate");
    bindNumeric("field-exp", "exp_yield");
    bind("field-growth", "growth_rate");
    this._bindGenderRatio(mon);
    bindStr("field-height", "height");
    bindStr("field-weight", "weight");
    bindStr("field-desc", "desc");
    bindStr("field-design-origin", "design_origin");
    // 特性下拉改成可搜索输入框（原生 select 逐条滚动选特性太慢，对齐旧编辑器的自动补全体验）
    const abilityNames = this._getAbilitiesList();
    const setAbilities = (a1, a2) => {
      // 保留槽位顺序：只有 a2 有值而 a1 为空时，用空字符串占住槽位 0，避免 a2 的值错位挪到 abilities[0]
      if (!a1 && !a2) mon.abilities = [];
      else if (!a1) mon.abilities = ["", a2];
      else if (!a2) mon.abilities = [a1];
      else mon.abilities = [a1, a2];
      this.callbacks.onModified(this.fileKey);
    };
    const ability1Input = document.getElementById("field-ability1");
    const ability2Input = document.getElementById("field-ability2");
    if (ability1Input) {
      attachSearchableSelect(ability1Input, {
        items: abilityNames, value: mon.abilities?.[0] || "",
        onChange: (v) => setAbilities(v, ability2Input?.value.trim() || mon.abilities?.[1] || ""),
      });
    }
    if (ability2Input) {
      attachSearchableSelect(ability2Input, {
        items: abilityNames, value: mon.abilities?.[1] || "",
        onChange: (v) => setAbilities(ability1Input?.value.trim() || mon.abilities?.[0] || "", v),
      });
    }

    // Base stats
    const bindStat = (id, field) => {
      const el = document.getElementById(id);
      if (!el) return;
      el.addEventListener("change", () => {
        if (!mon.base) mon.base = {};
        mon.base[field] = parseInt(el.value) || 0;
        this.callbacks.onModified(this.fileKey);
        // Refresh to update total
        this.renderDetail(mon.id);
      });
    };

    bindStat("stat-hp", "hp");
    bindStat("stat-atk", "atk");
    bindStat("stat-def", "def");
    bindStat("stat-spatk", "sp_atk");
    bindStat("stat-spdef", "sp_def");
    bindStat("stat-spd", "spd");

    // Tier auto-suggest — 与 mon_editor.py 的 _suggest_tier_role 阈值一致
    const suggestTierBtn = document.getElementById("btn-suggest-tier");
    if (suggestTierBtn) {
      suggestTierBtn.addEventListener("click", () => {
        const statIds = ["stat-hp", "stat-atk", "stat-def", "stat-spatk", "stat-spdef", "stat-spd"];
        const total = statIds.reduce((sum, id) => sum + (parseInt(document.getElementById(id)?.value) || 0), 0);
        let tier;
        if (total >= 670) tier = "天";
        else if (total >= 600) tier = "神";
        else if (total >= 535) tier = "地";
        else if (total >= 450) tier = "玄";
        else if (total >= 360) tier = "灵";
        else tier = "凡";
        const sel = document.getElementById("field-tier");
        sel.value = tier;
        mon.tier = tier;
        this.callbacks.onModified(this.fileKey);
      });
    }

    // Evolution
    const addEvoBtn = document.getElementById("btn-add-evo");
    if (addEvoBtn) {
      addEvoBtn.addEventListener("click", () => {
        this._ensureOwnEvolutionsArray(mon);
        this._openEvoModal({ into: "", level: 16 }, (evo) => mon.evolutions.push(evo), mon);
      });
    }

    // Evolution arrows — click to edit target name / level / item (only this mon's own branches)
    document.querySelectorAll("[data-evo-idx]").forEach(el => {
      const idx = parseInt(el.dataset.evoIdx);
      el.addEventListener("click", () => {
        this._ensureOwnEvolutionsArray(mon);
        const evo = mon.evolutions[idx];
        if (!evo) return;
        this._openEvoModal(evo, (updated) => { mon.evolutions[idx] = updated; }, mon);
      });
    });

    // Ancestor/descendant cards — click to jump to that species for stat comparison
    document.querySelectorAll("[data-evo-goto]").forEach(el => {
      el.addEventListener("click", () => this._selectMon(parseInt(el.dataset.evoGoto)));
    });

    // Learnset
    const addLearnBtn = document.getElementById("btn-add-learn");
    if (addLearnBtn) {
      addLearnBtn.addEventListener("click", () => {
        if (!mon.learnset) mon.learnset = [];
        this._openAddLearnModal(mon);
      });
    }

    // Learnset remove
    document.querySelectorAll(".learn-remove").forEach(btn => {
      btn.addEventListener("click", () => {
        const idx = parseInt(btn.dataset.idx);
        if (mon.learnset) {
          mon.learnset.splice(idx, 1);
          this.callbacks.onModified(this.fileKey);
          this.renderDetail(mon.id);
        }
      });
    });

    // Learnset inline edits
    document.querySelectorAll(".learn-level").forEach(input => {
      input.addEventListener("change", () => {
        const idx = parseInt(input.dataset.idx);
        if (mon.learnset && mon.learnset[idx]) {
          mon.learnset[idx].level = parseInt(input.value) || 0;
          this.callbacks.onModified(this.fileKey);
        }
      });
    });

    // 技能名改成可搜索输入框，改完重新渲染以刷新旁边的属性/分类/威力标签
    const learnMoveNames = (this.state.data.moves || []).map(m => m.name).sort();
    document.querySelectorAll(".learn-name").forEach(input => {
      const idx = parseInt(input.dataset.idx);
      attachSearchableSelect(input, {
        items: learnMoveNames,
        value: input.value,
        onChange: (v) => {
          if (mon.learnset && mon.learnset[idx]) {
            mon.learnset[idx].name = v;
            this.callbacks.onModified(this.fileKey);
            this.renderDetail(mon.id);
          }
        },
      });
    });

    // Encounter add
    const addEncBtn = document.getElementById("btn-add-enc");
    if (addEncBtn) {
      addEncBtn.addEventListener("click", () => {
        if (!mon.encounters) mon.encounters = [];
        mon.encounters.push({ location: "", rate: 0 });
        this.callbacks.onModified(this.fileKey);
        this.renderDetail(mon.id);
      });
    }

    // Encounter remove
    document.querySelectorAll(".enc-remove").forEach(btn => {
      btn.addEventListener("click", () => {
        const idx = parseInt(btn.dataset.idx);
        if (mon.encounters) {
          mon.encounters.splice(idx, 1);
          this.callbacks.onModified(this.fileKey);
          this.renderDetail(mon.id);
        }
      });
    });

    // Encounter field edits
    document.querySelectorAll(".enc-location").forEach(input => {
      input.addEventListener("change", () => {
        const idx = parseInt(input.dataset.idx);
        if (mon.encounters && mon.encounters[idx]) {
          mon.encounters[idx].location = input.value;
          this.callbacks.onModified(this.fileKey);
        }
      });
    });
    document.querySelectorAll(".enc-rate").forEach(input => {
      input.addEventListener("change", () => {
        const idx = parseInt(input.dataset.idx);
        if (mon.encounters && mon.encounters[idx]) {
          mon.encounters[idx].rate = parseInt(input.value) || 0;
          this.callbacks.onModified(this.fileKey);
        }
      });
    });
  }
}
