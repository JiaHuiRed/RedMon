import { TYPE_COLORS } from "../components/type-badge.js";
import { renderStatBar, renderTotalBar } from "../components/stat-bar.js";
import { readSprite } from "../utils/api.js";
import { openModal } from "../components/modal.js";
import { attachSearchableSelect } from "../components/searchable-select.js";
import { computeMatchup } from "../components/type-chart.js";

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
        <div class="form-section-title">种族值 <span style="font-weight:400;color:var(--text-muted);font-size:12px">（右侧数值为 Lv50 / Lv100 实际数值，个体值/努力值均取满）</span></div>
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
          <div class="form-group full-width">
            <label>设计灵感来源</label>
            <input type="text" id="field-design-origin" value="${mon.design_origin || ""}" placeholder="例：瑞兽火猫 + 祥云纹" />
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
      base: { hp: 50, atk: 50, def: 50, sp_atk: 50, sp_def: 50, spd: 50 },
      tier: "凡",
      catch_rate: 45,
      exp_yield: 100,
      growth_rate: "中",
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

  _renderEvoChain(mon) {
    if (!mon.evolutions || mon.evolutions.length === 0) {
      return '<div style="color:var(--text-muted);padding:8px">无进化</div>';
    }

    // 真实 species.json 里进化目标是精灵名字符串 `into`，不是数字 id
    return `<div class="evo-chain">
      <div class="evo-node">
        <span class="evo-name">${mon.name}</span>
      </div>
      ${mon.evolutions.map((evo, i) => `
        <span class="evo-arrow">→</span>
        <div class="evo-node" data-evo-idx="${i}">
          <span class="evo-name">${evo.into || "?"}</span>
          <span class="evo-condition">${[
            evo.level ? `Lv.${evo.level}` : "",
            evo.item ? `「${evo.item}」` : "",
          ].filter(Boolean).join(" ")}</span>
        </div>
      `).join("")}
    </div>`;
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
          <input type="number" id="evo-level-input" min="1" max="100" value="${draft.level}" />
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
          <input type="number" id="learn-level-input" min="0" max="100" value="1" />
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
          let txt = `属性: ${m.type || "?"}   分类: ${m.category || "?"}   威力: ${m.power ?? "-"}   命中: ${m.accuracy ?? "-"}   PP: ${m.pp ?? "-"}`;
          if (m.desc) txt += `\n${m.desc}`;
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
    const t1 = mon.type1, t2 = mon.type2;
    if (!t1) return '<div style="color:var(--text-muted)">请先选择属性</div>';

    const { offense, defense } = computeMatchup(t1, t2);

    const chip = (typ, val) => {
      const bg = TYPE_COLORS[typ] || "#999";
      return `<span class="type-badge type-badge-sm" style="background:${bg}22;color:${bg};border:1px solid ${bg}44">${typ} ${val}</span>`;
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
        if (!mon.evolutions) mon.evolutions = [];
        this._openEvoModal({ into: "", level: 16 }, (evo) => mon.evolutions.push(evo), mon);
      });
    }

    // Evolution nodes — click to edit target name / level / item
    document.querySelectorAll("[data-evo-idx]").forEach(el => {
      const idx = parseInt(el.dataset.evoIdx);
      el.addEventListener("click", () => {
        const evo = mon.evolutions?.[idx];
        if (!evo) return;
        this._openEvoModal(evo, (updated) => { mon.evolutions[idx] = updated; }, mon);
      });
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
