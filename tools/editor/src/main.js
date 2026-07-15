import { initTheme, toggleTheme, getTheme } from "./utils/theme.js";
import { openProject, loadProject, detectProjectRoot, getDataPaths, readJson, writeJson } from "./utils/api.js";
import { SpeciesTab } from "./tabs/species.js";
import { MovesTab } from "./tabs/moves.js";
import { ItemsTab } from "./tabs/items.js";
import { AbilitiesTab } from "./tabs/abilities.js";
import { NpcsTab } from "./tabs/npcs.js";
import { DialogsTab } from "./tabs/dialogs.js";
import { MapsTab } from "./tabs/maps.js";

// === State ===
const state = {
  projectRoot: null,
  dataPaths: null,
  data: {},  // { species: [...], moves: [...], ... }
  modified: {},  // { species: true, ... }
  history: {},  // { fileKey: { undo: [], redo: [] } }
};

const tabs = {};

let activeTab = "species";

// === Tab Registry ===
const TAB_DEFS = {
  species: { key: "species", label: "精灵图鉴", file: "species", TabClass: SpeciesTab },
  moves:    { key: "moves",    label: "技能库",    file: "moves",    TabClass: MovesTab },
  items:    { key: "items",    label: "道具",      file: "items",    TabClass: ItemsTab },
  abilities:{ key: "abilities",label: "特性",      file: "abilities",TabClass: AbilitiesTab },
  npcs:     { key: "npcs",     label: "角色",      file: "npcs",     TabClass: NpcsTab },
  dialogs:  { key: "dialogs",  label: "剧情文本",  file: "dialogs",  TabClass: DialogsTab },
  maps:     { key: "maps",     label: "地图",      file: "maps",     TabClass: MapsTab },
};

// === DOM Refs ===
const $ = (id) => document.getElementById(id);
const dom = {
  projectPath: $("project-path"),
  sidebarList: $("sidebar-list"),
  searchInput: $("search-input"),
  statusText: $("status-text"),
  sidebarActions: $("sidebar-actions"),
  btnAdd: $("btn-add-entry"),
  btnDelete: $("btn-delete-entry"),
};

// === Tab Switching ===
function switchTab(tabKey) {
  activeTab = tabKey;

  // Update tab buttons
  document.querySelectorAll(".tab-btn").forEach(btn => {
    btn.classList.toggle("active", btn.dataset.tab === tabKey);
  });

  // Update content panels
  document.querySelectorAll(".tab-content").forEach(el => {
    el.classList.toggle("active", el.id === `tab-${tabKey}`);
  });

  // Refresh sidebar list
  const tab = tabs[tabKey];
  if (tab) {
    dom.searchInput.value = "";
    tab.renderList();
  }

  updateSidebarButtons();
}

function updateSidebarButtons() {
  const tab = tabs[activeTab];
  if (!tab || !dom.sidebarActions) return;
  // Show actions for all tabs except dialogs (has its own add/edit flow)
  const hasActions = tab.onAdd || tab.onDelete;
  dom.sidebarActions.style.display = hasActions ? "flex" : "none";
  dom.btnDelete.style.display = tab.currentId && tab.onDelete ? "block" : "none";
}

// === Project Management ===
async function handleOpenProject() {
  try {
    setStatus("正在打开项目...");
    const result = await openProject();
    await openProjectAt(result.root);
  } catch (err) {
    setStatus(`错误: ${err}`);
  }
}

async function openProjectAt(root) {
  state.projectRoot = root;
  dom.projectPath.textContent = root;
  dom.projectPath.title = root;
  localStorage.setItem("redmon-last-project", root);

  // Load data paths
  state.dataPaths = await getDataPaths(root);

  // Load all JSON data
  await loadAllData();

  // Initialize all tabs
  for (const [key, def] of Object.entries(TAB_DEFS)) {
    const container = document.getElementById(`tab-${key}`);
    const tab = new def.TabClass(container, state, key, {
      onSave: (fileKey, jsonData) => handleSaveOne(fileKey, jsonData),
      onStatus: setStatus,
      onModified: (fileKey) => { state.modified[fileKey] = true; updateSaveButton(); },
      saveHistory: (fileKey) => saveHistory(fileKey),
    });
    tabs[key] = tab;
  }

  // Render active tab
  tabs[activeTab]?.renderList();
  setStatus(`已加载项目: ${root}`);
  updateSaveButton();
  updateSidebarButtons();
}

async function loadAllData() {
  for (const [key, def] of Object.entries(TAB_DEFS)) {
    const info = state.dataPaths[def.file];
    if (!info || !info.exists) {
      state.data[def.file] = key === "dialogs" ? {} : [];
      continue;
    }
    try {
      let raw = await readJson(info.path);

      if (key === "dialogs") {
        state.data[def.file] = raw; // keep object format
      } else if (key === "maps") {
        // maps.json: { "_comment":"...", "maps": { "name":{...}, ... } }
        const mapsObj = raw.maps || {};
        state.data[def.file] = Object.entries(mapsObj).map(([k, v]) => {
          if (!v.name) v.name = k;
          return v;
        });
      } else {
        // Object format: { "name": { "name":"...", ... } } → array
        state.data[def.file] = Object.entries(raw).map(([k, v], idx) => {
          if (!v.name) v.name = k; // add name from key when missing
          if (v.id === undefined) v.id = idx + 1; // ensure numeric id
          // Normalize learnset from dict {"lv": ["name", ...]} to flat array [{level, name}, ...]
          // (a single level can teach multiple moves, so each name becomes its own entry)
          if (key === "species" && v.learnset && !Array.isArray(v.learnset)) {
            const flat = [];
            for (const [lvl, names] of Object.entries(v.learnset)) {
              const nameList = Array.isArray(names) ? names : [names];
              for (const nm of nameList) {
                flat.push({ level: parseInt(lvl) || 1, name: nm });
              }
            }
            v.learnset = flat;
          }
          return v;
        });
      }

      state.modified[def.file] = false;
    } catch (e) {
      console.warn(`加载 ${def.file}.json 失败:`, e);
      setStatus(`加载失败 ${def.file}.json: ${e.message || e}`);
      state.data[def.file] = key === "dialogs" ? {} : [];
    }
  }
}

// Files whose on-disk schema has no native "id" field — the loader assigns a
// synthetic id=index+1 purely so the UI has a stable selection key, but that
// synthetic value must never be written back into the JSON.
const NO_NATIVE_ID = new Set(["abilities", "items", "moves"]);

// === Undo / Redo ===
const MAX_HISTORY = 50;

function deepClone(obj) {
  try { return structuredClone(obj); } catch { return JSON.parse(JSON.stringify(obj)); }
}

function saveHistory(fileKey) {
  if (fileKey === "encounters") {
    const mapsTab = tabs["maps"];
    if (!mapsTab || !mapsTab.encountersData) return;
    state.history.encounters = state.history.encounters || { undo: [], redo: [] };
    state.history.encounters.undo.push(deepClone(mapsTab.encountersData));
    if (state.history.encounters.undo.length > MAX_HISTORY) state.history.encounters.undo.shift();
    state.history.encounters.redo = [];
    return;
  }
  const data = state.data[fileKey];
  if (!data) return;
  state.history[fileKey] = state.history[fileKey] || { undo: [], redo: [] };
  state.history[fileKey].undo.push(deepClone(data));
  if (state.history[fileKey].undo.length > MAX_HISTORY) state.history[fileKey].undo.shift();
  state.history[fileKey].redo = [];
}

function undo() {
  const tab = tabs[activeTab];
  if (!tab) return;
  const fileKey = tab.fileKey;

  // 遇效表单独走 encounters 历史栈
  if (fileKey === "maps" && tab.encountersData && state.history?.encounters?.undo?.length) {
    state.history.encounters.redo.push(deepClone(tab.encountersData));
    tab.encountersData = state.history.encounters.undo.pop();
    const curMap = tab.data.find(m => m.id === tab.currentId);
    if (curMap) tab._renderEncSection(curMap);
    setStatus("撤销遇效表");
    return;
  }

  const history = state.history?.[fileKey];
  if (!history || !history.undo.length) return;
  history.redo.push(deepClone(state.data[fileKey]));
  const prev = history.undo.pop();
  state.data[fileKey] = prev;
  tab.data = prev;
  tab.renderList();
  if (tab.currentId != null) tab.renderDetail(tab.currentId);
  setStatus("撤销");
}

function redo() {
  const tab = tabs[activeTab];
  if (!tab) return;
  const fileKey = tab.fileKey;

  if (fileKey === "maps" && tab.encountersData && state.history?.encounters?.redo?.length) {
    state.history.encounters.undo.push(deepClone(tab.encountersData));
    tab.encountersData = state.history.encounters.redo.pop();
    const curMap = tab.data.find(m => m.id === tab.currentId);
    if (curMap) tab._renderEncSection(curMap);
    setStatus("重做遇效表");
    return;
  }

  const history = state.history?.[fileKey];
  if (!history || !history.redo.length) return;
  history.undo.push(deepClone(state.data[fileKey]));
  const next = history.redo.pop();
  state.data[fileKey] = next;
  tab.data = next;
  tab.renderList();
  if (tab.currentId != null) tab.renderDetail(tab.currentId);
  setStatus("重做");
}

// Convert editor array data back to file object format for saving
function dataForSave(fileKey, data) {
  if (fileKey === "dialogs") return data;

  if (fileKey === "maps") {
    const maps = {};
    for (const item of data) maps[item.name] = item;
    return { "_comment": "地图列表——编辑器地图tab管理，关联NPC/遇敌/传送点", "maps": maps };
  }

  const keyField = fileKey === "npcs" ? "id" : "name";
  const obj = {};
  for (const item of data) {
    let toSave = fileKey === "species" ? speciesForSave(item) : item;
    if (NO_NATIVE_ID.has(fileKey)) {
      const { id, ...rest } = toSave;
      toSave = rest;
    }
    obj[item[keyField]] = toSave;
  }
  return obj;
}

// Rebuild encounters.json from species.json encounters (species is the single source of truth)
async function _syncEncountersFromSpecies() {
  const mapsTab = tabs["maps"];
  if (!mapsTab || !mapsTab.encountersPath) return;
  await mapsTab._ensureEncounters();
  const speciesData = state.data.species || [];
  mapsTab.rebuildFromSpecies(speciesData);
  await mapsTab._saveEncounters();
}

// Convert an in-memory species item (learnset as flat [{level,name}] array, for editing)
// back to the on-disk schema (learnset as {"level": ["move1", "move2", ...]} dict).
// Returns a shallow copy — does not mutate the live item still used by the UI.
function speciesForSave(item) {
  const out = { ...item };
  if (Array.isArray(item.learnset)) {
    const dict = {};
    for (const entry of item.learnset) {
      if (!entry || !entry.name) continue;
      const lvl = String(entry.level ?? 1);
      (dict[lvl] ||= []).push(entry.name);
    }
    out.learnset = dict;
  }
  return out;
}

async function handleSaveOne(fileKey, jsonData) {
  const info = state.dataPaths[fileKey];
  if (!info) return;
  try {
    await writeJson(info.path, dataForSave(fileKey, jsonData));
    state.modified[fileKey] = false;
    updateSaveButton();
    setStatus(`已保存 ${fileKey}.json`);
    if (fileKey === "species") {
      await _syncEncountersFromSpecies();
    }
  } catch (err) {
    setStatus(`保存失败: ${err}`);
  }
}

async function handleSaveAll() {
  const speciesModified = state.modified["species"];
  for (const [key, def] of Object.entries(TAB_DEFS)) {
    const info = state.dataPaths[def.file];
    if (info && info.exists && state.modified[def.file]) {
      const tab = tabs[key];
      if (tab && tab.getData) {
        try {
          const data = tab.getData();
          await writeJson(info.path, dataForSave(def.file, data));
          state.modified[def.file] = false;
        } catch (err) {
          setStatus(`保存 ${def.file}.json 失败: ${err}`);
          return;
        }
      }
    }
  }
  // 以 species.json 为唯一数据源，species 有改动时才重建 encounters.json
  if (speciesModified) {
    await _syncEncountersFromSpecies();
  }
  // 同时保存地图 tab 手动修改的遇效表（若与 species 不同步）
  const mapsTab = tabs["maps"];
  if (mapsTab && mapsTab.encModified && mapsTab.encountersPath) {
    await mapsTab._saveEncounters();
  }
  state.modified = {};
  updateSaveButton();
  setStatus("全部已保存");
}

function updateSaveButton() {
  const hasModified = Object.values(state.modified).some(v => v);
  const btn = $("btn-save-all");
  if (btn) btn.style.opacity = hasModified ? "1" : "0.4";
}

// === Search ===
dom.searchInput.addEventListener("input", (e) => {
  const tab = tabs[activeTab];
  if (tab && tab.filterList) {
    tab.filterList(e.target.value);
  }
});

// === Status ===
function setStatus(msg) {
  dom.statusText.textContent = msg;
}

// === Keyboard Shortcuts ===
document.addEventListener("keydown", (e) => {
  if ((e.ctrlKey || e.metaKey) && e.key === "s") {
    e.preventDefault();
    handleSaveAll();
  }
  if ((e.ctrlKey || e.metaKey) && e.key === "z" && !e.shiftKey) {
    e.preventDefault();
    undo();
  }
  if ((e.ctrlKey || e.metaKey) && (e.key === "y" || (e.key === "z" && e.shiftKey))) {
    e.preventDefault();
    redo();
  }
});

// === Init ===
async function init() {
  initTheme();

  // Tab click handlers
  document.querySelectorAll(".tab-btn").forEach(btn => {
    btn.addEventListener("click", () => switchTab(btn.dataset.tab));
  });

  // Top bar buttons
  $("btn-open-project").addEventListener("click", handleOpenProject);
  $("btn-save-all").addEventListener("click", handleSaveAll);
  $("btn-theme").addEventListener("click", () => {
    const t = toggleTheme();
    $("btn-theme").textContent = t === "dark" ? "🌙" : "☀️";
  });

  // Sidebar action buttons
  dom.btnAdd?.addEventListener("click", () => {
    const tab = tabs[activeTab];
    if (tab && tab.onAdd) { tab.onAdd(); updateSidebarButtons(); }
  });
  dom.btnDelete?.addEventListener("click", () => {
    const tab = tabs[activeTab];
    if (tab && tab.onDelete) { tab.onDelete(); updateSidebarButtons(); }
  });

  // Global click on sidebar items → update delete button
  dom.sidebarList?.addEventListener("click", () => setTimeout(updateSidebarButtons, 0));

  // Auto-detect project (editor lives inside the project tree)
  try {
    const result = await detectProjectRoot();
    await openProjectAt(result.root);
    return;
  } catch (err) {
    console.warn("自动检测项目失败:", err);
  }

  // Fallback: last opened project
  const lastPath = localStorage.getItem("redmon-last-project");
  if (lastPath) {
    try {
      await loadProject(lastPath);
      await openProjectAt(lastPath);
      return;
    } catch (err) {
      console.warn("自动加载失败:", err);
    }
  }

  setStatus("就绪 — 点击 📂 打开项目");
}

init();
