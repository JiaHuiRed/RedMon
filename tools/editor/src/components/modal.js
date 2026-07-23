// 轻量弹窗组件，对齐 mon_editor.py 里 tk.Toplevel 弹窗的用法：
// 标题 + 自定义表单内容 + 确定/取消。onConfirm 返回 false 时弹窗不关闭（用于校验失败提示）。
//
// 用法：
//   openModal({
//     title: "添加进化分支",
//     bodyHtml: `<div class="form-group">...</div>`,
//     onMount: (body) => { ... 在这里给 body 里的输入框接事件/SearchableSelect ... },
//     onConfirm: (body) => { ... 返回 false 表示校验失败、弹窗保持打开 ... },
//   });

import { escapeHtml } from "../utils/dom.js";

export function openModal({ title, bodyHtml, onMount, onConfirm, confirmText = "确定", cancelText = "取消" }) {
  const overlay = document.createElement("div");
  overlay.className = "modal-overlay";
  overlay.innerHTML = `
      <div class="modal-box">
        <div class="modal-title">${escapeHtml(title)}</div>
        <div class="modal-body">${bodyHtml}</div>
      <div class="modal-actions">
        <button class="btn" id="modal-cancel">${cancelText}</button>
        <button class="btn btn-primary" id="modal-confirm">${confirmText}</button>
      </div>
    </div>
  `;
  document.body.appendChild(overlay);

  const body = overlay.querySelector(".modal-body");
  const close = () => overlay.remove();

  overlay.addEventListener("mousedown", (e) => { if (e.target === overlay) close(); });
  overlay.querySelector("#modal-cancel").addEventListener("click", close);
  overlay.querySelector("#modal-confirm").addEventListener("click", () => {
    const ok = onConfirm ? onConfirm(body) : true;
    if (ok !== false) close();
  });
  const escHandler = (e) => { if (e.key === "Escape") { close(); document.removeEventListener("keydown", escHandler); } };
  document.addEventListener("keydown", escHandler);

  onMount?.(body);
  return { close, body };
}
