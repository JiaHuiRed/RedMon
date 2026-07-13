import { TYPE_COLORS } from "../components/type-badge.js";
import { renderStatBar, renderTotalBar } from "../components/stat-bar.js";
import { readSprite } from "../utils/api.js";

const GROWTH_RATES = ["慢", "中慢", "中", "中快", "快"];

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
  }

  getData() {
    return this.data;
  }

  // ===== Sidebar List =====
  renderList(filter) {
    this.data = this.state.data.species || [];
    this.filteredData = (filter
      ? this.data.filter(m => this._matchFilter(m, filter))
      : this.data
    ).sort((a, b) => a.id - b.id);

    const list = document.getElementById("sidebar-list");
    if (!this.filteredData.length) {
      list.innerHTML = '<div class="placeholder">没有精灵数据</div>';
      return;
    }

    list.innerHTML = this.filteredData.map(m =>
      `<div class="sidebar-item ${m.id === this.currentId ? "active" : ""}" data-id="${m.id}">
        <span class="item-id">#${String(m.id).padStart(3, "0")}</span>
        <span class="item-name">${m.name}</span>
        <span class="type-badge type-badge-sm" style="background:${TYPE_COLORS[m.type1]||"#999"}22; color:${TYPE_COLORS[m.type1]||"#999"}">${m.type1}</span>
        ${m.type2 ? `<span class="type-badge type-badge-sm" style="background:${TYPE_COLORS[m.type2]||"#999"}22; color:${TYPE_COLORS[m.type2]||"#999"}">${m.type2}</span>` : ""}
      </div>`
    ).join("");

    list.querySelectorAll(".sidebar-item").forEach(el => {
      el.addEventListener("click", () => this._selectMon(parseInt(el.dataset.id)));
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

  // Normalise stat names (data uses sp_atk/sp_def but code uses spatk/spdef)
  _stat(base, key) {
    return base[key] || base[key.replace("atk", "_atk").replace("def", "_def")] || 0;
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
    const spatk = this._stat(base, "spatk");
    const spdef = this._stat(base, "spdef");
    const spd = base.spd || 0;
    const bst = hp + atk + def + spatk + spdef + spd;

    this.container.innerHTML = `
      <!-- Top: Sprites + Basic Info -->
      <div class="auto-grid">
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
              <label>品阶</label>
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
              <label>性别比例</label>
              <input type="text" id="field-gender" value="${mon.gender_ratio || ""}" placeholder="如 1:1" />
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
              <select id="field-ability1">${this._abilityOptions(mon.abilities?.[0] || "")}</select>
            </div>
            <div class="form-group">
              <label>特性 2</label>
              <select id="field-ability2">${this._abilityOptions(mon.abilities?.[1] || "")}</select>
            </div>
          </div>
        </div>
      </div>

      <!-- Stats -->
      <div class="form-section">
        <div class="form-section-title">种族值 <span style="font-weight:400;color:var(--text-muted);font-size:12px">Lv50: ${Math.floor(bst * 0.5 + 60)} | Lv100: ${bst + 60}</span></div>
        <div class="form-grid" style="margin-bottom:12px">
          <div class="form-group"><label>HP</label><input type="number" id="stat-hp" value="${hp}" min="0" max="255" /></div>
          <div class="form-group"><label>ATK</label><input type="number" id="stat-atk" value="${atk}" min="0" max="255" /></div>
          <div class="form-group"><label>DEF</label><input type="number" id="stat-def" value="${def}" min="0" max="255" /></div>
          <div class="form-group"><label>SP.ATK</label><input type="number" id="stat-spatk" value="${spatk}" min="0" max="255" /></div>
          <div class="form-group"><label>SP.DEF</label><input type="number" id="stat-spdef" value="${spdef}" min="0" max="255" /></div>
          <div class="form-group"><label>SPD</label><input type="number" id="stat-spd" value="${spd}" min="0" max="255" /></div>
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

      <!-- Evolution -->
      <div class="form-section">
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
        <table class="list-table" id="learnset-table">
          <thead>
            <tr>
              <th style="width:50px">等级</th>
              <th>技能名称</th>
              <th style="width:40px"></th>
            </tr>
          </thead>
          <tbody>
            ${this._renderLearnset(mon)}
          </tbody>
        </table>
      </div>

      <!-- Description -->
      <div class="form-section">
        <div class="form-section-title">图鉴描述</div>
        <div class="form-grid">
          <div class="form-group full-width">
            <textarea id="field-desc" rows="3">${mon.desc || ""}</textarea>
          </div>
        </div>
      </div>

      <!-- Type Matchup -->
      <div class="form-section">
        <div class="form-section-title">属性克制</div>
        <div id="matchup-container">
          ${this._renderMatchup(mon)}
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
      base: { hp: 50, atk: 50, def: 50, spatk: 50, spdef: 50, spd: 50 },
      tier: "凡",
      catch_rate: 45,
      exp_yield: 100,
      growth_rate: "中",
      desc: "",
      height: "",
      weight: "",
      gender_ratio: "",
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

  _abilityOptions(selected) {
    const list = this._getAbilitiesList();
    return `<option value="">无</option>${
      list.map(a => `<option value="${a}" ${a === selected ? "selected" : ""}>${a}</option>`).join("")
    }`;
  }

  _typeOptions(selected) {
    return Object.keys(TYPE_COLORS).map(t =>
      `<option value="${t}" ${t === selected ? "selected" : ""}>${t}</option>`
    ).join("");
  }

  _renderEvoChain(mon) {
    if (!mon.evolutions || mon.evolutions.length === 0) {
      return '<div style="color:var(--text-muted);padding:8px">无进化</div>';
    }

    const species = this.data;
    // Support both `id` (number) and `into` (name) fields in evolution data
    const resolveEvoName = (evo) => {
      if (evo.id) {
        const m = species.find(s => s.id == evo.id);
        return m ? m.name : `#${evo.id}`;
      }
      if (evo.into) return evo.into;
      return "?";
    };

    return `<div class="evo-chain">
      <div class="evo-node">
        <span class="evo-name">${mon.name}</span>
      </div>
      ${mon.evolutions.map(evo => `
        <span class="evo-arrow">→</span>
        <div class="evo-node" data-evo-id="${evo.id || ""}">
          <span class="evo-name">${resolveEvoName(evo)}</span>
          <span class="evo-condition">${evo.level ? `Lv.${evo.level}` : evo.condition || ""}</span>
        </div>
      `).join("")}
    </div>`;
  }

  _renderLearnset(mon) {
    if (!mon.learnset || mon.learnset.length === 0) {
      return '<tr><td colspan="3" style="text-align:center;color:var(--text-muted)">无技能</td></tr>';
    }

    const sorted = [...mon.learnset].sort((a, b) => (a.level || 999) - (b.level || 999));
    return sorted.map((l, i) =>
      `<tr>
        <td><input type="number" value="${l.level || 0}" class="learn-level" data-idx="${i}" style="width:50px" /></td>
        <td><input type="text" value="${l.name || ""}" class="learn-name" data-idx="${i}" style="width:100%" /></td>
        <td><button class="remove-btn learn-remove" data-idx="${i}">✕</button></td>
      </tr>`
    ).join("");
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
    const types = Object.keys(TYPE_COLORS);
    const t1 = mon.type1, t2 = mon.type2;
    const chart = {
      "空":{"岩":0.6,"钢":0.6,"鬼":0.0},
      "火":{"木":1.5,"冰":1.5,"虫":1.5,"钢":1.5,"火":0.6,"水":0.6,"岩":0.6,"龙":0.6},
      "水":{"火":1.5,"土":1.5,"岩":1.5,"水":0.6,"木":0.6,"龙":0.6},
      "木":{"水":1.5,"土":1.5,"岩":1.5,"火":0.6,"木":0.6,"毒":0.6,"风":0.6,"虫":0.6,"龙":0.6,"钢":0.6},
      "雷":{"水":1.5,"风":1.5,"雷":0.6,"木":0.6,"龙":0.6,"土":0.0},
      "冰":{"木":1.5,"土":1.5,"风":1.5,"龙":1.5,"火":0.6,"水":0.6,"冰":0.6,"钢":0.6},
      "格":{"空":1.5,"冰":1.5,"岩":1.5,"暗":1.5,"钢":1.5,"毒":0.6,"风":0.6,"灵":0.6,"虫":0.6,"仙":0.6,"鬼":0.0},
      "毒":{"木":1.5,"仙":1.5,"毒":0.6,"土":0.6,"岩":0.6,"鬼":0.6,"钢":0.0},
      "土":{"火":1.5,"雷":1.5,"毒":1.5,"岩":1.5,"钢":1.5,"木":0.6,"虫":0.6,"风":0.0},
      "风":{"木":1.5,"格":1.5,"虫":1.5,"雷":0.6,"岩":0.6,"钢":0.6},
      "灵":{"格":1.5,"毒":1.5,"灵":0.6,"钢":0.6},
      "虫":{"木":1.5,"灵":1.5,"暗":1.5,"仙":1.5,"火":0.6,"格":0.6,"风":0.6,"鬼":0.6,"钢":0.6},
      "岩":{"火":1.5,"冰":1.5,"风":1.5,"虫":1.5,"格":0.6,"土":0.6,"钢":0.6},
      "鬼":{"灵":1.5,"鬼":1.5,"暗":0.6,"空":0.0},
      "龙":{"龙":1.5,"钢":0.6,"仙":0.0},
      "暗":{"灵":1.5,"鬼":1.5,"光":1.5,"格":0.6,"暗":0.6,"仙":0.6},
      "钢":{"冰":1.5,"岩":1.5,"仙":1.5,"火":0.6,"水":0.6,"雷":0.6,"钢":0.6},
      "仙":{"格":1.5,"龙":1.5,"暗":1.5,"火":0.6,"毒":0.6,"钢":0.6},
      "光":{"鬼":1.5,"虫":1.5,"冰":1.5,"暗":1.5,"火":0.6,"钢":0.6,"光":0.6,"水":0.6,"木":0.0},
    };

    return `<table class="matchup-table">
      <thead><tr><th>攻击属性</th><th>${t1}${t2 ? " / "+t2 : ""}</th></tr></thead>
      <tbody>
      ${types.filter(atk => atk).map(atk => {
        const eff1 = chart[atk]?.[t1] ?? 1;
        const v = t2 ? eff1 * (chart[atk]?.[t2] ?? 1) : eff1;
        const label = v === 0 ? "免" : v < 1 ? `×${v}` : v > 1 ? `×${v}` : "—";
        const cls = v === 0 ? "immune" : v < 1 ? "resist" : v > 1 ? "weak" : "normal";
        const bg = TYPE_COLORS[atk];
        return `<tr class="${cls}">
          <td><span class="type-badge type-badge-sm" style="background:${bg||"#999"}">${atk}</span></td>
          <td class="matchup-val">${label}</td>
        </tr>`;
      }).join("")}
      </tbody>
    </table>`;
  }

  // ===== Sprite Loading =====
  async _loadSprite(id) {
    const container = document.getElementById("sprite-preview");
    if (!container) return;

    const path = `${this.spritesDir}/${String(id).padStart(3, "0")}.png`;
    try {
      const dataUrl = await readSprite(path);
      container.innerHTML = `
        <img src="${dataUrl}" alt="Sprite #${id}" />
        <div class="sprite-controls">
          <button class="btn btn-sm" id="btn-toggle-shiny" title="闪光预览">✨</button>
        </div>
      `;
      const shinyBtn = document.getElementById("btn-toggle-shiny");
      if (shinyBtn) {
        const shinyPath = path.replace(".png", "_shiny.png");
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
      console.warn("[species] front sprite load failed for", id);
    }

    // Back sprite
    const backContainer = document.getElementById("sprite-back-preview");
    if (backContainer) {
      const backPath = `${this.spritesDir}/${String(id).padStart(3, "0")}_back.png`;
      try {
        const backDataUrl = await readSprite(backPath);
        backContainer.innerHTML = `<img src="${backDataUrl}" alt="Back #${id}" />`;
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
    bindStr("field-gender", "gender_ratio");
    bindStr("field-height", "height");
    bindStr("field-weight", "weight");
    bindStr("field-desc", "desc");
    bind("field-ability1", "abilities", v => {
      const a1 = v || "", a2 = mon.abilities?.[1] || "";
      if (!v && !a2) { mon.abilities = []; return; }
      mon.abilities = [a1, a2].filter(Boolean);
    });
    bind("field-ability2", "abilities", v => {
      const a1 = mon.abilities?.[0] || "", a2 = v || "";
      if (!a1 && !v) { mon.abilities = []; return; }
      mon.abilities = [a1, a2].filter(Boolean);
    });

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
    bindStat("stat-spatk", "spatk");
    bindStat("stat-spdef", "spdef");
    bindStat("stat-spd", "spd");

    // Evolution
    const addEvoBtn = document.getElementById("btn-add-evo");
    if (addEvoBtn) {
      addEvoBtn.addEventListener("click", () => {
        if (!mon.evolutions) mon.evolutions = [];
        mon.evolutions.push({ id: 0, level: 16, condition: "" });
        this.callbacks.onModified(this.fileKey);
        this.renderDetail(mon.id);
      });
    }

    // Evolution nodes
    document.querySelectorAll("[data-evo-id]").forEach(el => {
      const evoId = parseInt(el.dataset.evoId);
      // Click to edit: select the evolved species
      el.addEventListener("click", () => {
        const evo = mon.evolutions?.find(e => e.id === evoId);
        if (evo) {
          const newId = prompt("进化目标 ID:", evo.id);
          if (newId) {
            evo.id = parseInt(newId) || 0;
            this.callbacks.onModified(this.fileKey);
            this.renderDetail(mon.id);
          }
        }
      });
    });

    // Learnset
    const addLearnBtn = document.getElementById("btn-add-learn");
    if (addLearnBtn) {
      addLearnBtn.addEventListener("click", () => {
        if (!mon.learnset) mon.learnset = [];
        mon.learnset.push({ level: 1, name: "" });
        this.callbacks.onModified(this.fileKey);
        this.renderDetail(mon.id);
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

    document.querySelectorAll(".learn-name").forEach(input => {
      input.addEventListener("change", () => {
        const idx = parseInt(input.dataset.idx);
        if (mon.learnset && mon.learnset[idx]) {
          mon.learnset[idx].name = input.value;
          this.callbacks.onModified(this.fileKey);
        }
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
