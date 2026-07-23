// 通用可搜索下拉组件，对齐 mon_editor.py 里 SearchableCombo 的体验：
// 输入即过滤、点击选中、失焦收起。用于所有跨表引用字段（精灵名/技能名/道具名/特性名）。
//
// 用法：
//   <input type="text" id="xxx" autocomplete="off" />
//   attachSearchableSelect(document.getElementById("xxx"), {
//     items: ["选项A", "选项B", ...],
//     value: "选项A",              // 初始值（可选）
//     onChange: (val) => { ... },  // 选中或失焦确认时触发
//     allowEmpty: true,            // 是否允许清空（默认 true）
//   });

import { escapeHtml } from "../utils/dom.js";

let _activeDropdown = null; // 同一时间只允许一个下拉展开

export function attachSearchableSelect(input, { items = [], value = "", onChange, allowEmpty = true } = {}) {
  input.classList.add("ss-input");
  input.setAttribute("autocomplete", "off");
  if (value !== undefined) input.value = value;

  const wrapper = document.createElement("div");
  wrapper.className = "ss-wrapper";
  input.parentNode.insertBefore(wrapper, input);
  wrapper.appendChild(input);

  const list = document.createElement("div");
  list.className = "ss-dropdown";
  list.style.display = "none";
  wrapper.appendChild(list);

  let currentItems = items;
  let highlighted = -1;

  function renderList(filter) {
    const q = (filter || "").toLowerCase();
    const filtered = q ? currentItems.filter(it => it.toLowerCase().includes(q)) : currentItems;
    if (!filtered.length) {
      list.innerHTML = '<div class="ss-empty">无匹配项</div>';
    } else {
      list.innerHTML = filtered.slice(0, 200).map((it, i) =>
        `<div class="ss-item${i === highlighted ? ' hl' : ''}" data-val="${escapeHtml(it)}">${escapeHtml(it)}</div>`
      ).join("");
    }
    return filtered;
  }

  function open() {
    if (_activeDropdown && _activeDropdown !== list) _activeDropdown.style.display = "none";
    _activeDropdown = list;
    highlighted = -1;
    renderList(input.value);
    list.style.display = "block";
  }
  function close() {
    list.style.display = "none";
    if (_activeDropdown === list) _activeDropdown = null;
  }
  function commit(val) {
    input.value = val;
    close();
    onChange?.(val);
  }

  input.addEventListener("focus", open);
  input.addEventListener("input", () => { open(); renderList(input.value); });
  input.addEventListener("blur", () => {
    // Delay so a click on a dropdown item registers before we close/commit
    setTimeout(() => {
      close();
      const v = input.value.trim();
      if (v || allowEmpty) onChange?.(v);
    }, 150);
  });
  input.addEventListener("keydown", (e) => {
    const rows = () => Array.from(list.querySelectorAll(".ss-item"));
    if (e.key === "ArrowDown") {
      e.preventDefault();
      if (list.style.display === "none") { open(); return; }
      const r = rows(); if (!r.length) return;
      highlighted = Math.min(highlighted + 1, r.length - 1);
      renderList(input.value);
    } else if (e.key === "ArrowUp") {
      e.preventDefault();
      const r = rows(); if (!r.length) return;
      highlighted = Math.max(highlighted - 1, 0);
      renderList(input.value);
    } else if (e.key === "Enter") {
      e.preventDefault();
      const r = rows();
      if (highlighted >= 0 && r[highlighted]) commit(r[highlighted].dataset.val);
      else close();
    } else if (e.key === "Escape") {
      close();
    }
  });
  list.addEventListener("mousedown", (e) => {
    // mousedown (not click) so it fires before the input's blur handler closes the list
    const item = e.target.closest(".ss-item");
    if (item) commit(item.dataset.val);
  });

  return {
    setItems(newItems) { currentItems = newItems; },
    setValue(v) { input.value = v; },
    getValue() { return input.value; },
  };
}
