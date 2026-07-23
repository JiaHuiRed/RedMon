// === Editor State ===
// 集中管理编辑器全局状态、数据读写、撤销/重做、保存序列化。
// main.js 只负责 DOM 绑定和 init，不再直接持有 state/tabs/activeTab。

import { readJson, writeJson } from "./utils/api.js";
import { SpeciesTab } from "./tabs/species.js";
import { MovesTab } from "./tabs/moves.js";
import { ItemsTab } from "./tabs/items.js";
import { AbilitiesTab } from "./tabs/abilities.js";
import { NpcsTab } from "./tabs/npcs.js";
import { DialogsTab } from "./tabs/dialogs.js";
import { MapsTab } from "./tabs/maps.js";

export const TAB_DEFS = {
  species: { key: "species", label: "精灵图鉴", file: "species", TabClass: SpeciesTab },
  moves:    { key: "moves",    label: "技能库",    file: "moves",    TabClass: MovesTab },
  items:    { key: "items",    label: "道具",      file: "items",    TabClass: ItemsTab },
  abilities:{ key: "abilities",label: "特性",      file: "abilities",TabClass: AbilitiesTab },
  npcs:     { key: "npcs",     label: "角色",      file: "npcs",     TabClass: NpcsTab },
  dialogs:  { key: "dialogs",  label: "剧情文本",  file: "dialogs",  TabClass: DialogsTab },
  maps:     { key: "maps",     label: "地图",      file: "maps",     TabClass: MapsTab },
};

export const NO_NATIVE_ID = new Set(["abilities", "items", "moves"]);

export const state = {
  projectRoot: null,
  dataPaths: null,
  data: {},
  modified: {},
  history: {},
};

export const tabs = {};
export let activeTab = "species";

const MAX_HISTORY = 50;

function deepClone(obj) {
  try { return structuredClone(obj); } catch { return JSON.parse(JSON.stringify(obj)); }
}

export function saveHistory(fileKey) {
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

export function undo() {
  const mapsTab = tabs["maps"];
  if (mapsTab && mapsTab.encountersData && state.history?.encounters?.undo?.length) {
    state.history.encounters.redo.push(deepClone(mapsTab.encountersData));
    mapsTab.encountersData = state.history.encounters.undo.pop();
    const curMap = mapsTab.data.find(m => m.id === mapsTab.currentId);
    if (curMap) mapsTab._renderEncSection(curMap);
    return "撤销遇效表";
  }

  const tab = tabs[activeTab];
  if (!tab) return;
  const fileKey = tab.fileKey;

  const history = state.history?.[fileKey];
  if (!history || !history.undo.length) return;
  history.redo.push(deepClone(state.data[fileKey]));
  const prev = history.undo.pop();
  state.data[fileKey] = prev;
  tab.data = prev;
  tab.renderList();
  if (tab.currentId != null) tab.renderDetail(tab.currentId);
  return "撤销";
}

export function redo() {
  const mapsTab = tabs["maps"];
  if (mapsTab && mapsTab.encountersData && state.history?.encounters?.redo?.length) {
    state.history.encounters.undo.push(deepClone(mapsTab.encountersData));
    mapsTab.encountersData = state.history.encounters.redo.pop();
    const curMap = mapsTab.data.find(m => m.id === mapsTab.currentId);
    if (curMap) mapsTab._renderEncSection(curMap);
    return "重做遇效表";
  }

  const tab = tabs[activeTab];
  if (!tab) return;
  const fileKey = tab.fileKey;

  const history = state.history?.[fileKey];
  if (!history || !history.redo.length) return;
  history.undo.push(deepClone(state.data[fileKey]));
  const next = history.redo.pop();
  state.data[fileKey] = next;
  tab.data = next;
  tab.renderList();
  if (tab.currentId != null) tab.renderDetail(tab.currentId);
  return "重做";
}

export function dataForSave(fileKey, data) {
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

export function speciesForSave(item) {
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

export async function loadAllData() {
  for (const [key, def] of Object.entries(TAB_DEFS)) {
    const info = state.dataPaths[def.file];
    if (!info || !info.exists) {
      state.data[def.file] = key === "dialogs" ? {} : [];
      continue;
    }
    try {
      let raw = await readJson(info.path);

      if (key === "dialogs") {
        state.data[def.file] = raw;
      } else if (key === "maps") {
        const mapsObj = raw.maps || {};
        state.data[def.file] = Object.entries(mapsObj).map(([k, v]) => {
          if (!v.name) v.name = k;
          return v;
        });
      } else {
        state.data[def.file] = Object.entries(raw).map(([k, v], idx) => {
          if (!v.name) v.name = k;
          if (v.id === undefined) v.id = idx + 1;
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
      state.data[def.file] = key === "dialogs" ? {} : [];
    }
  }
}

export async function _syncEncountersFromSpecies() {
  const mapsTab = tabs["maps"];
  if (!mapsTab || !mapsTab.encountersPath) return;
  await mapsTab._ensureEncounters();
  const speciesData = state.data.species || [];
  mapsTab.rebuildFromSpecies(speciesData);
  await mapsTab._saveEncounters();
}

export function setStatus(msg) {
  const el = document.getElementById("status-text");
  if (el) el.textContent = msg;
}

export function updateSaveButton() {
  const hasModified = Object.values(state.modified).some(v => v);
  const btn = document.getElementById("btn-save-all");
  if (btn) btn.style.opacity = hasModified ? "1" : "0.4";
}

export function updateSummary() {
  const el = document.getElementById("status-summary");
  if (!el || !state.data) return;
  const sp = (state.data.species || []).length;
  const mv = (state.data.moves || []).length;
  const ab = (state.data.abilities || []).length;
  const it = (state.data.items || []).length;
  el.textContent = `精灵 ${sp}只  ·  技能 ${mv}个  ·  特性 ${ab}种  ·  道具 ${it}种`;
}

export async function handleSaveOne(fileKey, jsonData) {
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

export async function handleSaveAll() {
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
  if (speciesModified) {
    await _syncEncountersFromSpecies();
  }
  const mapsTab = tabs["maps"];
  if (mapsTab && mapsTab.encModified && mapsTab.encountersPath) {
    await mapsTab._saveEncounters();
  }
  state.modified = {};
  updateSaveButton();
  setStatus("全部已保存");
}
