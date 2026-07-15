import { readJson, writeJson } from "../utils/api.js";

const MAP_TYPES = ["野外", "城市", "室内", "道馆", "洞穴", "水域", "特殊"];

export class MapsTab {
  constructor(container, state, fileKey, callbacks) {
    this.container = container;
    this.state = state;
    this.fileKey = fileKey;
    this.callbacks = callbacks;
    this.currentId = null;
    this.data = state.data.maps || [];
    // 遇效表 data/encounters.json（按 map_id 索引）独立于 maps.json 加载/保存，
    // 因为它不属于 main.js 的 TAB_DEFS 注册表
    this.encountersPath = state.projectRoot ? `${state.projectRoot}/data/encounters.json` : null;
    this.encountersData = null;
    this.encModified = false;
  }

  async _ensureEncounters() {
    if (this.encountersData || !this.encountersPath) return this.encountersData;
    try {
      this.encountersData = await readJson(this.encountersPath);
    } catch {
      this.encountersData = { "_comment": "遇效表——按 map_id 索引", "maps": {} };
    }
    if (!this.encountersData.maps) this.encountersData.maps = {};
    return this.encountersData;
  }

  async _saveEncounters() {
    if (!this.encountersPath) return;
    await writeJson(this.encountersPath, this.encountersData);
    this.encModified = false;
    this.callbacks.onStatus("已保存 encounters.json");
    this._renderEncSaveState();
  }

  _renderEncSaveState() {
    const btn = document.getElementById("enc-save-btn");
    if (btn) btn.style.opacity = this.encModified ? "1" : "0.4";
  }

  rebuildFromSpecies(speciesData) {
    // Build name -> map_id lookup from maps.json
    const nameToId = {};
    for (const m of (this.state.data.maps || [])) {
      if (m.name) nameToId[m.name] = String(m.id ?? m.name);
    }
    const result = { "_comment": "中央遇敌表——按 map_id 索引", "maps": {} };
    for (const sp of speciesData) {
      if (!sp.encounters) continue;
      for (const enc of sp.encounters) {
        const mapName = enc.location;
        if (!mapName) continue;
        const mapId = nameToId[mapName] || mapName;
        if (!result.maps[mapId]) {
          result.maps[mapId] = { encounter_rate: enc.rate || 0, mons: [] };
        } else {
          // Preserve existing encounter_rate if species doesn't specify one
          if (enc.rate && !result.maps[mapId].encounter_rate) {
            result.maps[mapId].encounter_rate = enc.rate;
          }
        }
        const existing = result.maps[mapId].mons.find(m => m.species === sp.name);
        if (existing) {
          existing.weight = enc.rate || existing.weight;
        } else {
          result.maps[mapId].mons.push({ species: sp.name, weight: enc.rate || 0 });
        }
      }
    }
    this.encountersData = result;
    this.encModified = true;
    this._renderEncSaveState();
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
            <label>场景文件</label><input type="text" id="mp-scene" value="${map.scene_file||""}" />
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
      <div class="form-section" id="enc-section">
        <div class="section-header">
          <span class="form-section-title">遇效表（data/encounters.json，按 map_id 索引，游戏实际读取的数据源）</span>
          <div>
            <button class="btn btn-sm" id="enc-save-btn" style="opacity:0.4">💾 保存遇效表</button>
          </div>
        </div>
        <div id="enc-body">加载中...</div>
      </div>
    `;
    const bind = (id, field) => {
      document.getElementById(id)?.addEventListener("change", () => {
        this.callbacks.saveHistory(this.fileKey);
        map[field] = document.getElementById(id).value;
        this.callbacks.onModified(this.fileKey);
      });
    };
    bind("mp-id", "id"); bind("mp-name", "name"); bind("mp-type", "type");
    bind("mp-scene", "scene_file"); bind("mp-desc", "desc"); bind("mp-gym", "gym");
    document.getElementById("mp-npcs")?.addEventListener("change", (e) => {
      this.callbacks.saveHistory(this.fileKey);
      map.npcs = e.target.value.split(",").map(s => s.trim()).filter(Boolean);
      this.callbacks.onModified(this.fileKey);
    });
    document.getElementById("enc-save-btn")?.addEventListener("click", () => this._saveEncounters());

    this._renderEncSection(map);
  }

  async _renderEncSection(map) {
    await this._ensureEncounters();
    const body = document.getElementById("enc-body");
    if (!body) return; // user navigated away before load finished

    const mapKey = String(map.id);
    const entry = this.encountersData.maps[mapKey] || { encounter_rate: 0, mons: [] };
    this.encountersData.maps[mapKey] = entry; // ensure it exists so edits have somewhere to land

    const speciesNames = (this.state.data.species || []).map(s => s.name).sort();

    body.innerHTML = `
      <datalist id="enc-species-list">${speciesNames.map(n => `<option value="${n}">`).join("")}</datalist>
      <div class="form-group" style="max-width:200px">
        <label>草丛遇敌率 %</label>
        <input type="number" id="enc-rate" value="${entry.encounter_rate || 0}" min="0" max="100" />
      </div>
      <table class="list-table" id="enc-mons-table">
        <thead><tr><th>精灵</th><th style="width:80px">权重</th><th style="width:40px"></th></tr></thead>
        <tbody>
          ${entry.mons.map((m, i) => `
            <tr>
              <td><input type="text" list="enc-species-list" class="enc-mon-species" data-idx="${i}" value="${m.species||""}" /></td>
              <td><input type="number" class="enc-mon-weight" data-idx="${i}" value="${m.weight||0}" min="0" /></td>
              <td><button class="remove-btn enc-mon-remove" data-idx="${i}">✕</button></td>
            </tr>
          `).join("") || '<tr><td colspan="3" style="text-align:center;color:var(--text-muted)">无遇敌精灵，点下方添加</td></tr>'}
        </tbody>
      </table>
      <button class="btn btn-sm" id="enc-add-mon">+ 添加精灵</button>
    `;

    const markEncModified = () => { this.encModified = true; this._renderEncSaveState(); };

    document.getElementById("enc-rate")?.addEventListener("change", (e) => {
      this.callbacks.saveHistory("encounters");
      entry.encounter_rate = parseInt(e.target.value) || 0;
      markEncModified();
    });
    document.getElementById("enc-add-mon")?.addEventListener("click", () => {
      this.callbacks.saveHistory("encounters");
      entry.mons.push({ species: "", weight: 10 });
      markEncModified();
      this._renderEncSection(map);
    });
    body.querySelectorAll(".enc-mon-species").forEach(el => {
      el.addEventListener("change", () => {
        this.callbacks.saveHistory("encounters");
        entry.mons[parseInt(el.dataset.idx)].species = el.value;
        markEncModified();
      });
    });
    body.querySelectorAll(".enc-mon-weight").forEach(el => {
      el.addEventListener("change", () => {
        this.callbacks.saveHistory("encounters");
        entry.mons[parseInt(el.dataset.idx)].weight = parseInt(el.target.value) || 0;
        markEncModified();
      });
    });
    body.querySelectorAll(".enc-mon-remove").forEach(el => {
      el.addEventListener("click", () => {
        this.callbacks.saveHistory("encounters");
        entry.mons.splice(parseInt(el.dataset.idx), 1);
        markEncModified();
        this._renderEncSection(map);
      });
    });
  }

  onAdd() {
    this.callbacks.saveHistory(this.fileKey);
    const maxId = this.data.reduce((max, m) => Math.max(max, parseInt(m.id) || 0), 0);
    this.data.push({ id: maxId + 1, name: "新地图", type: "野外", scene_file: "", npcs: [] });
    this.callbacks.onModified(this.fileKey);
    this._select(maxId + 1);
  }

  onDelete() {
    this.callbacks.saveHistory(this.fileKey);
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
