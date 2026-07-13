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
          // Normalize learnset from dict {"lv":"name"} to array [{level, name}]
          if (key === "species" && v.learnset && !Array.isArray(v.learnset)) {
            v.learnset = Object.entries(v.learnset).map(([lvl, nm]) => ({
              level: parseInt(lvl) || 1,
              name: nm,
            }));
          }
          return v;
        });
      }

      state.modified[def.file] = false;
    } catch (e) {
      console.warn(`加载 ${def.file}.json 失败:`, e);
      state.data[def.file] = key === "dialogs" ? {} : [];
    }
  }
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
  for (const item of data) obj[item[keyField]] = item;
  return obj;
}

async function handleSaveOne(fileKey, jsonData) {
  const info = state.dataPaths[fileKey];
  if (!info) return;
  try {
    await writeJson(info.path, dataForSave(fileKey, jsonData));
    state.modified[fileKey] = false;
    updateSaveButton();
    setStatus(`已保存 ${fileKey}.json`);
  } catch (err) {
    setStatus(`保存失败: ${err}`);
  }
}

async function handleSaveAll() {
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
