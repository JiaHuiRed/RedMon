import { initTheme, toggleTheme } from "./utils/theme.js";
import { openProject, loadProject, detectProjectRoot, getDataPaths } from "./utils/api.js";
import {
  TAB_DEFS,
  state,
  tabs,
  loadAllData,
  saveHistory,
  undo,
  redo,
  handleSaveOne,
  handleSaveAll,
  setStatus,
  updateSaveButton,
  updateSummary,
} from "./editor-state.js";

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
  state.activeTab = tabKey;

  document.querySelectorAll(".tab-btn").forEach(btn => {
    btn.classList.toggle("active", btn.dataset.tab === tabKey);
  });

  document.querySelectorAll(".tab-content").forEach(el => {
    el.classList.toggle("active", el.id === `tab-${tabKey}`);
  });

  const tab = tabs[tabKey];
  if (tab) {
    dom.searchInput.value = "";
    tab.renderList();
  }

  updateSidebarButtons();
}

function updateSidebarButtons() {
  const tab = tabs[state.activeTab];
  if (!tab || !dom.sidebarActions) return;
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

  state.dataPaths = await getDataPaths(root);
  await loadAllData();

  for (const [key, def] of Object.entries(TAB_DEFS)) {
    const container = document.getElementById(`tab-${key}`);
    const tab = new def.TabClass(container, state, key, {
      onSave: (fileKey, jsonData) => handleSaveOne(fileKey, jsonData),
      onStatus: setStatus,
      onModified: (fileKey) => { state.modified[fileKey] = true; updateSaveButton(); updateSummary(); },
      saveHistory: (fileKey) => saveHistory(fileKey),
    });
    tabs[key] = tab;
  }

  tabs[state.activeTab]?.renderList();
  setStatus(`已加载项目: ${root}`);
  updateSummary();
  updateSaveButton();
  updateSidebarButtons();
}

// === Search ===
dom.searchInput.addEventListener("input", (e) => {
  const tab = tabs[state.activeTab];
  if (tab && tab.filterList) {
    tab.filterList(e.target.value);
  }
});

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

  document.querySelectorAll(".tab-btn").forEach(btn => {
    btn.addEventListener("click", () => switchTab(btn.dataset.tab));
  });

  $("btn-open-project").addEventListener("click", handleOpenProject);
  $("btn-save-all").addEventListener("click", handleSaveAll);
  $("btn-theme").addEventListener("click", () => {
    const t = toggleTheme();
    $("btn-theme").textContent = t === "dark" ? "🌙" : "☀️";
  });

  dom.btnAdd?.addEventListener("click", () => {
    const tab = tabs[state.activeTab];
    if (tab && tab.onAdd) { tab.onAdd(); updateSidebarButtons(); }
  });
  dom.btnDelete?.addEventListener("click", () => {
    const tab = tabs[state.activeTab];
    if (tab && tab.onDelete) { tab.onDelete(); updateSidebarButtons(); }
  });

  dom.sidebarList?.addEventListener("click", () => setTimeout(updateSidebarButtons, 0));

  try {
    const result = await detectProjectRoot();
    await openProjectAt(result.root);
    return;
  } catch (err) {
    console.warn("自动检测项目失败:", err);
  }

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
