#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
RedMon 数据编辑器 — 精灵 & 技能
用法: python -X utf8 tools/mon_editor.py
"""

import json, os, sys, tkinter as tk
from tkinter import ttk, messagebox

# ── Paths ────────────────────────────────────────────────────────────────────
if getattr(sys, "frozen", False):
    ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(sys.executable))))
else:
    ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPECIES_FILE = os.path.join(ROOT, "data", "species.json")
MOVES_FILE   = os.path.join(ROOT, "data", "moves.json")

TYPES      = ["", "火", "水", "木", "虫", "土", "空", "风", "仙", "灵", "龙", "格", "电"]
GROWTH     = ["快速", "中速", "缓慢"]
CATEGORIES = ["物理", "特殊", "变化"]
GENDERS    = ["50/50", "87.5/12.5", "25/75", "0/100", "无性别"]
EFFECTS    = ["", "lower_atk", "lower_def", "lower_sp_atk", "lower_sp_def", "lower_spd",
              "lower_acc", "raise_atk", "raise_def", "raise_sp_atk", "raise_sp_def",
              "raise_spd", "raise_acc", "inflict_burn", "inflict_poison",
              "inflict_paralysis", "inflict_sleep", "inflict_freeze", "heal_self"]

# 种族值条形图颜色（神百风格）
STAT_COLORS = {
    "hp":     "#78C850",
    "atk":    "#F08030",
    "def":    "#F8D030",
    "sp_atk": "#6890F0",
    "sp_def": "#F85888",
    "spd":    "#F58BA7",
}
STAT_LABELS = [("HP（体力）", "hp"), ("ATK（攻击）", "atk"), ("DEF（防御）", "def"),
               ("SPA（特攻）", "sp_atk"), ("SPD（特防）", "sp_def"), ("SPE（速度）", "spd")]
BAR_MAX  = 180   # 条形图最大刻度
BAR_W    = 120   # 条形图像素宽度

def load_json(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)

def save_json(path, data):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

def _int(s):
    try: return int(s)
    except: return 0


# ══════════════════════════════════════════════════════════════════════════════
#  App
# ══════════════════════════════════════════════════════════════════════════════

class App:
    def __init__(self):
        self.species = load_json(SPECIES_FILE)
        self.moves   = load_json(MOVES_FILE)

        self.root = tk.Tk()
        self.root.title("RedMon 数据编辑器")
        self.root.geometry("1060x700")
        self.root.minsize(800, 500)

        self.notebook = ttk.Notebook(self.root)
        self.notebook.pack(fill="both", expand=True)

        # ── Tab 1: 精灵 ──
        self.mon_tab = ttk.Frame(self.notebook)
        self.notebook.add(self.mon_tab, text=" 精灵编辑 ")
        self._build_mon_tab()

        # ── Tab 2: 技能库 ──
        self.move_tab = ttk.Frame(self.notebook)
        self.notebook.add(self.move_tab, text=" 技能库 ")
        self._build_move_tab()

        # Status bar
        self.status = ttk.Label(self.root, relief="sunken", anchor="w")
        self.status.pack(fill="x")
        self._update_status()

        self._current_mon  = None
        self._current_move = None
        self._learnset     = []          # 当前精灵的技能池（临时编辑用）

    # ── helpers ──────────────────────────────────────────────────────────────
    def _update_status(self):
        self.status.config(text=f"精灵: {len(self.species)}  |  技能: {len(self.moves)}")

    def _draw_bar(self, canvas, value, color):
        canvas.delete("all")
        w = max(1, int((min(value, BAR_MAX) / BAR_MAX) * BAR_W))
        canvas.create_rectangle(0, 0, w, 14, fill=color, outline="")

    # ════════════════════════════════════════════════════════════════════════
    #  精灵 TAB
    # ════════════════════════════════════════════════════════════════════════

    def _build_mon_tab(self):
        # ── left: search + list ──────────────────────────────────────────────
        left = ttk.Frame(self.mon_tab, width=220)
        left.pack(side="left", fill="y", padx=5, pady=5)
        left.pack_propagate(False)

        ttk.Label(left, text="搜索:").pack(anchor="w")
        self.mon_search = ttk.Entry(left)
        self.mon_search.pack(fill="x")
        self.mon_search.bind("<KeyRelease>", lambda _: self._mon_refresh_list())

        lf = ttk.Frame(left)
        lf.pack(fill="both", expand=True, pady=(4, 4))
        sb = ttk.Scrollbar(lf, orient="vertical")
        self.mon_list = tk.Listbox(lf, yscrollcommand=sb.set, font=("Microsoft YaHei", 10))
        sb.config(command=self.mon_list.yview)
        sb.pack(side="right", fill="y")
        self.mon_list.pack(side="left", fill="both", expand=True)
        self.mon_list.bind("<<ListboxSelect>>", self._mon_select)

        bf = ttk.Frame(left)
        bf.pack(fill="x")
        ttk.Button(bf, text="+ 新增", command=self._mon_add).pack(side="left", padx=(0, 4))
        ttk.Button(bf, text="× 删除", command=self._mon_delete).pack(side="left")

        # ── right: scrollable form ───────────────────────────────────────────
        self._mon_placeholder = ttk.Label(self.mon_tab, text="  选择一个精灵开始编辑", foreground="gray")
        self._mon_placeholder.pack(side="right", fill="both", expand=True)

        self._mon_scroll = ttk.Frame(self.mon_tab)
        self._mon_canvas = tk.Canvas(self._mon_scroll, borderwidth=0, highlightthickness=0)
        self._mon_vbar   = ttk.Scrollbar(self._mon_scroll, orient="vertical", command=self._mon_canvas.yview)
        self._mon_inner  = ttk.Frame(self._mon_canvas)
        self._mon_inner.bind("<Configure>", lambda _: self._mon_canvas.configure(scrollregion=self._mon_canvas.bbox("all")))
        self._mon_canvas.create_window((0, 0), window=self._mon_inner, anchor="nw")
        self._mon_canvas.configure(yscrollcommand=self._mon_vbar.set)
        self._mon_canvas.pack(side="left", fill="both", expand=True)
        self._mon_vbar.pack(side="right", fill="y")
        self._mon_canvas.bind("<Enter>", lambda _: self._mon_canvas.bind_all("<MouseWheel>", lambda e: self._mon_canvas.yview_scroll(-1*(e.delta//120), "units")))
        self._mon_canvas.bind("<Leave>", lambda _: self._mon_canvas.unbind_all("<MouseWheel>"))

        f = self._mon_inner
        row = 0

        # ── 编号 + 名称 ──
        ttk.Label(f, text="编号:").grid(row=row, column=0, sticky="e", padx=(8, 4), pady=3)
        self.mon_id = ttk.Entry(f, width=6, justify="center")
        self.mon_id.grid(row=row, column=1, sticky="w", pady=3)
        ttk.Button(f, text="💾 保存", command=self._mon_save).grid(row=row, column=2, sticky="w", padx=(16, 0))
        row += 1
        ttk.Label(f, text="名称:").grid(row=row, column=0, sticky="e", padx=(8, 4), pady=3)
        self.mon_name = ttk.Entry(f, width=16)
        self.mon_name.grid(row=row, column=1, sticky="w", pady=3)
        row += 1

        # ── 属性 ──
        ttk.Label(f, text="属性:").grid(row=row, column=0, sticky="e", padx=(8, 4), pady=3)
        tf = ttk.Frame(f)
        tf.grid(row=row, column=1, sticky="w", pady=3)
        self.mon_t1 = ttk.Combobox(tf, values=TYPES, width=6, state="readonly")
        self.mon_t1.pack(side="left")
        self.mon_t2 = ttk.Combobox(tf, values=TYPES, width=6, state="readonly")
        self.mon_t2.pack(side="left", padx=(6, 0))
        row += 1

        # ── 种族值 (含条形图) ──
        ttk.Separator(f, orient="horizontal").grid(row=row, column=0, columnspan=4, sticky="ew", pady=6)
        row += 1
        ttk.Label(f, text="种族值", font=("Microsoft YaHei", 9, "bold")).grid(row=row, column=0, columnspan=4, sticky="w", padx=8)
        row += 1

        self.mon_stat_entries = {}
        self.mon_stat_bars    = {}
        for label, key in STAT_LABELS:
            ttk.Label(f, text=label, width=10, anchor="e").grid(row=row, column=0, sticky="e", padx=(12, 4))
            e = ttk.Entry(f, width=5, justify="center")
            e.grid(row=row, column=1, sticky="w", pady=1)
            e.bind("<KeyRelease>", lambda _: self._refresh_stat_bars())
            self.mon_stat_entries[key] = e
            c = tk.Canvas(f, width=BAR_W, height=14, highlightthickness=0, bg="#f0f0f0")
            c.grid(row=row, column=2, sticky="w", padx=(6, 4))
            self.mon_stat_bars[key] = c
            row += 1

        ttk.Label(f, text="总和:", anchor="e").grid(row=row, column=0, sticky="e", padx=(12, 4), pady=2)
        self.mon_total_label = ttk.Label(f, text="0", font=("Microsoft YaHei", 9, "bold"))
        self.mon_total_label.grid(row=row, column=1, columnspan=2, sticky="w", padx=(0, 0), pady=2)
        row += 1

        # ── 其他属性 ──
        ttk.Separator(f, orient="horizontal").grid(row=row, column=0, columnspan=4, sticky="ew", pady=6)
        row += 1

        ttk.Label(f, text="捕获率:").grid(row=row, column=0, sticky="e", padx=(8, 4), pady=3)
        self.mon_catch = ttk.Entry(f, width=6, justify="center")
        self.mon_catch.grid(row=row, column=1, sticky="w", pady=3)
        ttk.Label(f, text="经验:").grid(row=row, column=2, padx=(8, 4))
        self.mon_exp = ttk.Entry(f, width=6, justify="center")
        self.mon_exp.grid(row=row, column=3, sticky="w", pady=3)
        row += 1

        ttk.Label(f, text="成长:").grid(row=row, column=0, sticky="e", padx=(8, 4), pady=3)
        self.mon_growth = ttk.Combobox(f, values=GROWTH, width=8, state="readonly")
        self.mon_growth.grid(row=row, column=1, sticky="w", pady=3)
        row += 1

        ttk.Label(f, text="进化:").grid(row=row, column=0, sticky="e", padx=(8, 4), pady=3)
        ef = ttk.Frame(f)
        ef.grid(row=row, column=1, columnspan=3, sticky="w", pady=3)
        self.mon_evo = ttk.Combobox(ef, width=14, state="normal")
        self.mon_evo.pack(side="left")
        ttk.Label(ef, text="  Lv").pack(side="left")
        self.mon_evo_lv = ttk.Entry(ef, width=5, justify="center")
        self.mon_evo_lv.pack(side="left", padx=(4, 0))
        row += 1

        ttk.Label(f, text="性别比:").grid(row=row, column=0, sticky="e", padx=(8, 4), pady=3)
        gf = ttk.Frame(f)
        gf.grid(row=row, column=1, sticky="w", pady=3)
        ttk.Label(gf, text="♂♀").pack(side="left")
        self.mon_gender = ttk.Combobox(gf, values=GENDERS, width=10, state="normal")
        self.mon_gender.pack(side="left", padx=(4, 0))
        ttk.Label(f, text="体型:").grid(row=row, column=2, padx=(8, 4))
        self.mon_size = ttk.Entry(f, width=18)
        self.mon_size.grid(row=row, column=3, sticky="w", pady=3)
        row += 1

        ttk.Separator(f, orient="horizontal").grid(row=row, column=0, columnspan=4, sticky="ew", pady=6)
        row += 1
        ttk.Label(f, text="描述:").grid(row=row, column=0, sticky="ne", padx=(8, 4))
        self.mon_desc = tk.Text(f, width=44, height=3, wrap="word")
        self.mon_desc.grid(row=row, column=1, columnspan=3, sticky="ew", pady=3, padx=(0, 8))
        row += 1

        # ── 技能池 (Treeview 表格) ──
        ttk.Separator(f, orient="horizontal").grid(row=row, column=0, columnspan=4, sticky="ew", pady=6)
        row += 1
        ttk.Label(f, text="技能池", font=("Microsoft YaHei", 9, "bold")).grid(row=row, column=0, columnspan=4, sticky="w", padx=8)
        row += 1

        cols = ("level", "name", "type", "cat", "power", "acc", "pp")
        self.ls_tree = ttk.Treeview(f, columns=cols, show="headings", height=8, selectmode="browse")
        self.ls_tree.heading("level", text="等级")
        self.ls_tree.heading("name",  text="招式")
        self.ls_tree.heading("type",  text="属性")
        self.ls_tree.heading("cat",   text="分类")
        self.ls_tree.heading("power", text="威力")
        self.ls_tree.heading("acc",   text="命中")
        self.ls_tree.heading("pp",    text="PP")
        self.ls_tree.column("level", width=40,  anchor="center")
        self.ls_tree.column("name",  width=100, anchor="w")
        self.ls_tree.column("type",  width=40,  anchor="center")
        self.ls_tree.column("cat",   width=50,  anchor="center")
        self.ls_tree.column("power", width=45,  anchor="center")
        self.ls_tree.column("acc",   width=45,  anchor="center")
        self.ls_tree.column("pp",    width=40,  anchor="center")
        ls_scroll = ttk.Scrollbar(f, orient="vertical", command=self.ls_tree.yview)
        self.ls_tree.configure(yscrollcommand=ls_scroll.set)
        self.ls_tree.grid(row=row, column=1, columnspan=3, sticky="ew", padx=(0, 8), pady=3)
        ls_scroll.grid(row=row, column=4, sticky="ns", padx=(0, 8))
        row += 1

        ls_btn = ttk.Frame(f)
        ls_btn.grid(row=row, column=1, columnspan=3, sticky="w", padx=(0, 8), pady=3)
        ttk.Button(ls_btn, text="+ 添加技能", command=self._ls_add).pack(side="left", padx=(0, 6))
        ttk.Button(ls_btn, text="× 删除技能", command=self._ls_remove).pack(side="left")
        row += 1

        # 初始化
        self._mon_refresh_list()
        self._refresh_stat_bars()

    def _mon_show_form(self):
        self._mon_placeholder.pack_forget()
        self._mon_scroll.pack(side="right", fill="both", expand=True, padx=5, pady=5)

    def _mon_get_name(self, display):
        # "001 炎喵" → "炎喵"
        return display.split(" ", 1)[1] if " " in display else display

    def _mon_refresh_list(self):
        q = self.mon_search.get().lower()
        self.mon_list.delete(0, "end")
        items = []
        for n, d in self.species.items():
            mid = d.get("id", 0) or 0
            if not q or q in n.lower() or q in str(mid):
                items.append((mid, n))
        items.sort(key=lambda x: (x[0], x[1]))
        for mid, n in items:
            self.mon_list.insert("end", f"{mid:03d} {n}")

    def _mon_select(self, _=None):
        sel = self.mon_list.curselection()
        if not sel: return
        self._mon_load(self._mon_get_name(self.mon_list.get(sel[0])))

    def _mon_load(self, name):
        self._mon_show_form()
        d = self.species[name]
        self._current_mon = name

        self.mon_id.delete(0, "end"); self.mon_id.insert(0, str(d.get("id", 0) or 0))
        self.mon_name.delete(0, "end"); self.mon_name.insert(0, name)
        self.mon_t1.set(d.get("type1", ""))
        self.mon_t2.set(d.get("type2", ""))

        base = d.get("base", {})
        for k, e in self.mon_stat_entries.items():
            e.delete(0, "end"); e.insert(0, str(base.get(k, 0)))
        self._refresh_stat_bars()

        self.mon_catch.delete(0, "end"); self.mon_catch.insert(0, str(d.get("catch_rate", 0)))
        self.mon_exp.delete(0, "end");    self.mon_exp.insert(0, str(d.get("exp_yield", 0)))
        self.mon_growth.set(d.get("growth_rate", ""))

        evo_list = sorted([n for n in self.species.keys() if n != name])
        self.mon_evo["values"] = [""] + evo_list
        self.mon_evo.set(d.get("evolves_into", ""))
        self.mon_evo_lv.delete(0, "end")
        if d.get("evolves_into"):
            self.mon_evo_lv.insert(0, str(d.get("evolve_level", "")))

        self.mon_gender.set(d.get("gender_ratio", ""))
        self.mon_size.delete(0, "end"); self.mon_size.insert(0, d.get("size_info", ""))

        self.mon_desc.delete("1.0", "end")
        self.mon_desc.insert("1.0", d.get("desc", ""))

        # 加载技能池
        self._learnset = []
        ls = d.get("learnset", {})
        for lv_str, skills in ls.items():
            for s in skills:
                self._learnset.append({"level": int(lv_str), "name": s})
        self._learnset.sort(key=lambda x: (x["level"], x["name"]))
        self._refresh_ls_table()

    def _refresh_stat_bars(self):
        total = 0
        for label, key in STAT_LABELS:
            v = _int(self.mon_stat_entries[key].get())
            total += v
            self._draw_bar(self.mon_stat_bars[key], v, STAT_COLORS[key])
        if hasattr(self, "mon_total_label"):
            self.mon_total_label.config(text=str(total))

    # ── 技能池表格 ──

    def _refresh_ls_table(self):
        self.ls_tree.delete(*self.ls_tree.get_children())
        for item in self._learnset:
            m = self.moves.get(item["name"], {})
            self.ls_tree.insert("", "end", values=(
                item["level"],
                item["name"],
                m.get("type", "?"),
                m.get("category", "?"),
                m.get("power", "-"),
                m.get("accuracy", "-"),
                m.get("max_pp", "-"),
            ))

    def _ls_add(self):
        dlg = tk.Toplevel(self.root)
        dlg.title("添加技能")
        dlg.geometry("320x110")
        dlg.resizable(False, False)
        dlg.transient(self.root)
        dlg.grab_set()

        ttk.Label(dlg, text="等级:").grid(row=0, column=0, padx=10, pady=8, sticky="e")
        lv_var = tk.StringVar(value="1")
        ttk.Spinbox(dlg, from_=0, to=100, width=6, textvariable=lv_var).grid(row=0, column=1, sticky="w", pady=8)

        ttk.Label(dlg, text="技能:").grid(row=1, column=0, padx=10, pady=8, sticky="e")
        names = sorted(self.moves.keys())
        cb = ttk.Combobox(dlg, values=names, width=20, state="readonly")
        cb.grid(row=1, column=1, sticky="w", pady=8)
        if names: cb.current(0)

        def ok():
            lv = lv_var.get().strip()
            mv = cb.get()
            if lv.isdigit() and mv:
                self._learnset.append({"level": int(lv), "name": mv})
                self._learnset.sort(key=lambda x: (x["level"], x["name"]))
                self._refresh_ls_table()
                dlg.destroy()
            else:
                messagebox.showwarning("", "请选择等级和技能", parent=dlg)

        bf = ttk.Frame(dlg)
        bf.grid(row=2, column=0, columnspan=2, pady=6)
        ttk.Button(bf, text="确定", command=ok).pack(side="left", padx=6)
        ttk.Button(bf, text="取消", command=dlg.destroy).pack(side="left", padx=6)

    def _ls_remove(self):
        sel = self.ls_tree.selection()
        if not sel: return
        vals = self.ls_tree.item(sel[0], "values")
        level, name = int(vals[0]), vals[1]
        self._learnset = [x for x in self._learnset if not (x["level"] == level and x["name"] == name)]
        self._refresh_ls_table()

    # ── 保存精灵 ──

    def _mon_save(self):
        old = self._current_mon
        new = self.mon_name.get().strip()
        if not new:
            messagebox.showerror("错误", "名称不能为空"); return

        d = {
            "id": _int(self.mon_id.get()),
            "name": new,
            "type1": self.mon_t1.get(),
            "type2": self.mon_t2.get(),
            "base": {k: _int(self.mon_stat_entries[k].get()) for _, k in STAT_LABELS},
            "catch_rate": _int(self.mon_catch.get()),
            "exp_yield": _int(self.mon_exp.get()),
            "growth_rate": self.mon_growth.get(),
            "desc": self.mon_desc.get("1.0", "end-1c").strip(),
            "gender_ratio": self.mon_gender.get(),
            "size_info": self.mon_size.get().strip(),
        }

        evo = self.mon_evo.get().strip()
        if evo:
            d["evolves_into"] = evo
            d["evolve_level"] = _int(self.mon_evo_lv.get())
        else:
            d.pop("evolves_into", None); d.pop("evolve_level", None)

        # learnset
        ls = {}
        for item in self._learnset:
            lv = str(item["level"])
            ls.setdefault(lv, []).append(item["name"])
        d["learnset"] = ls

        # 重命名处理
        if old and old != new:
            del self.species[old]
            for mon in self.species.values():
                if mon.get("evolves_into") == old:
                    mon["evolves_into"] = new

        self.species[new] = d
        save_json(SPECIES_FILE, self.species)
        self._current_mon = new
        self._mon_refresh_list()
        self._update_status()
        messagebox.showinfo("", "已保存 ✓")

    def _mon_add(self):
        name = "新精灵"
        i = 1
        while name in self.species:
            i += 1; name = f"新精灵{i}"
        # 自动分配编号 = 最大现有 + 1
        max_id = max((d.get("id", 0) or 0) for d in self.species.values()) + 1
        self.species[name] = {
            "id": max_id, "name": name, "type1": "", "type2": "",
            "base": {"hp": 50, "atk": 50, "def": 50, "sp_atk": 50, "sp_def": 50, "spd": 50},
            "catch_rate": 45, "exp_yield": 64, "growth_rate": "中速",
            "desc": "", "gender_ratio": "50/50", "size_info": "小型 / 0.5m / 5.0kg",
            "learnset": {},
        }
        self._mon_refresh_list()
        for i in range(self.mon_list.size()):
            if self.mon_list.get(i) == name:
                self.mon_list.selection_clear(0, "end")
                self.mon_list.selection_set(i)
                self.mon_list.see(i)
                self._mon_load(name); break

    def _mon_delete(self):
        if not self._current_mon: return
        if not messagebox.askyesno("确认", f"删除「{self._current_mon}」?"): return
        del self.species[self._current_mon]
        save_json(SPECIES_FILE, self.species)
        self._current_mon = None
        self._mon_refresh_list()
        self._update_status()
        self._mon_scroll.pack_forget()
        self._mon_placeholder.pack(side="right", fill="both", expand=True)

    # ════════════════════════════════════════════════════════════════════════
    #  技能库 TAB
    # ════════════════════════════════════════════════════════════════════════

    def _build_move_tab(self):
        left = ttk.Frame(self.move_tab, width=220)
        left.pack(side="left", fill="y", padx=5, pady=5)
        left.pack_propagate(False)

        ttk.Label(left, text="搜索:").pack(anchor="w")
        self.move_search = ttk.Entry(left)
        self.move_search.pack(fill="x")
        self.move_search.bind("<KeyRelease>", lambda _: self._move_refresh_list())

        lf = ttk.Frame(left)
        lf.pack(fill="both", expand=True, pady=(4, 4))
        sb = ttk.Scrollbar(lf, orient="vertical")
        self.move_list = tk.Listbox(lf, yscrollcommand=sb.set, font=("Microsoft YaHei", 10))
        sb.config(command=self.move_list.yview)
        sb.pack(side="right", fill="y")
        self.move_list.pack(side="left", fill="both", expand=True)
        self.move_list.bind("<<ListboxSelect>>", self._move_select)

        bf = ttk.Frame(left)
        bf.pack(fill="x")
        ttk.Button(bf, text="+ 新增", command=self._move_add).pack(side="left", padx=(0, 4))
        ttk.Button(bf, text="× 删除", command=self._move_delete).pack(side="left")

        # right: form
        self._move_placeholder = ttk.Label(self.move_tab, text="  选择一个技能开始编辑", foreground="gray")
        self._move_placeholder.pack(side="right", fill="both", expand=True)

        self._move_scroll = ttk.Frame(self.move_tab)
        ms_canvas = tk.Canvas(self._move_scroll, borderwidth=0, highlightthickness=0)
        ms_vbar   = ttk.Scrollbar(self._move_scroll, orient="vertical", command=ms_canvas.yview)
        self._move_inner = ttk.Frame(ms_canvas)
        self._move_inner.bind("<Configure>", lambda _: ms_canvas.configure(scrollregion=ms_canvas.bbox("all")))
        ms_canvas.create_window((0, 0), window=self._move_inner, anchor="nw")
        ms_canvas.configure(yscrollcommand=ms_vbar.set)
        ms_canvas.pack(side="left", fill="both", expand=True)
        ms_vbar.pack(side="right", fill="y")

        f = self._move_inner
        row = 0

        ttk.Label(f, text="名称:").grid(row=row, column=0, sticky="e", padx=(8, 4), pady=3)
        self.move_name = ttk.Entry(f, width=18)
        self.move_name.grid(row=row, column=1, sticky="w", pady=3)
        row += 1

        ttk.Label(f, text="类型:").grid(row=row, column=0, sticky="e", padx=(8, 4), pady=3)
        self.move_type = ttk.Combobox(f, values=TYPES, width=8, state="readonly")
        self.move_type.grid(row=row, column=1, sticky="w", pady=3)
        ttk.Label(f, text="分类:").grid(row=row, column=2, padx=(12, 4))
        self.move_cat = ttk.Combobox(f, values=CATEGORIES, width=8, state="readonly")
        self.move_cat.grid(row=row, column=3, sticky="w", pady=3)
        row += 1

        ttk.Separator(f, orient="horizontal").grid(row=row, column=0, columnspan=4, sticky="ew", pady=6)
        row += 1

        ttk.Label(f, text="威力:").grid(row=row, column=0, sticky="e", padx=(8, 4), pady=3)
        self.move_power = ttk.Entry(f, width=6, justify="center")
        self.move_power.grid(row=row, column=1, sticky="w", pady=3)
        ttk.Label(f, text="命中:").grid(row=row, column=2, padx=(12, 4))
        self.move_acc = ttk.Entry(f, width=6, justify="center")
        self.move_acc.grid(row=row, column=3, sticky="w", pady=3)
        row += 1

        ttk.Label(f, text="PP:").grid(row=row, column=0, sticky="e", padx=(8, 4), pady=3)
        self.move_pp = ttk.Entry(f, width=6, justify="center")
        self.move_pp.grid(row=row, column=1, sticky="w", pady=3)
        row += 1

        ttk.Separator(f, orient="horizontal").grid(row=row, column=0, columnspan=4, sticky="ew", pady=6)
        row += 1

        ttk.Label(f, text="效果:").grid(row=row, column=0, sticky="e", padx=(8, 4), pady=3)
        self.move_effect = ttk.Combobox(f, values=EFFECTS, width=20, state="readonly")
        self.move_effect.grid(row=row, column=1, columnspan=3, sticky="w", pady=3)
        row += 1

        ttk.Separator(f, orient="horizontal").grid(row=row, column=0, columnspan=4, sticky="ew", pady=6)
        row += 1

        ttk.Label(f, text="描述:").grid(row=row, column=0, sticky="ne", padx=(8, 4))
        self.move_desc = tk.Text(f, width=44, height=3, wrap="word")
        self.move_desc.grid(row=row, column=1, columnspan=3, sticky="ew", pady=3, padx=(0, 8))
        row += 1

        ttk.Separator(f, orient="horizontal").grid(row=row, column=0, columnspan=4, sticky="ew", pady=6)
        row += 1
        btnf = ttk.Frame(f)
        btnf.grid(row=row, column=0, columnspan=4, pady=6)
        ttk.Button(btnf, text="保存修改", command=self._move_save).pack()

        self._move_refresh_list()

    def _move_show_form(self):
        self._move_placeholder.pack_forget()
        self._move_scroll.pack(side="right", fill="both", expand=True, padx=5, pady=5)

    def _move_refresh_list(self):
        q = self.move_search.get().lower()
        self.move_list.delete(0, "end")
        for n in sorted(self.moves.keys()):
            if not q or q in n.lower():
                self.move_list.insert("end", n)

    def _move_select(self, _=None):
        sel = self.move_list.curselection()
        if not sel: return
        self._move_load(self.move_list.get(sel[0]))

    def _move_load(self, name):
        self._move_show_form()
        d = self.moves[name]
        self._current_move = name
        self.move_name.delete(0, "end"); self.move_name.insert(0, name)
        self.move_type.set(d.get("type", ""))
        self.move_cat.set(d.get("category", ""))
        self.move_power.delete(0, "end"); self.move_power.insert(0, str(d.get("power", 0)))
        self.move_acc.delete(0, "end");   self.move_acc.insert(0, str(d.get("accuracy", 0)))
        self.move_pp.delete(0, "end");    self.move_pp.insert(0, str(d.get("max_pp", 0)))
        self.move_effect.set(d.get("effect", ""))
        self.move_desc.delete("1.0", "end")
        self.move_desc.insert("1.0", d.get("description", ""))

    def _move_save(self):
        old = self._current_move
        new = self.move_name.get().strip()
        if not new:
            messagebox.showerror("错误", "名称不能为空"); return

        d = {
            "name": new,
            "type": self.move_type.get(),
            "category": self.move_cat.get(),
            "power": _int(self.move_power.get()),
            "accuracy": _int(self.move_acc.get()),
            "max_pp": _int(self.move_pp.get()),
            "effect": self.move_effect.get(),
            "description": self.move_desc.get("1.0", "end-1c").strip(),
        }

        if old and old != new:
            del self.moves[old]
            # 更新所有精灵技能池中的旧名
            for mon in self.species.values():
                for lv in mon.get("learnset", {}):
                    mon["learnset"][lv] = [new if s == old else s for s in mon["learnset"][lv]]

        self.moves[new] = d
        save_json(MOVES_FILE, self.moves)
        self._current_move = new
        self._move_refresh_list()
        self._update_status()
        messagebox.showinfo("", "已保存 ✓")

    def _move_add(self):
        name = "新技能"
        i = 1
        while name in self.moves:
            i += 1; name = f"新技能{i}"
        self.moves[name] = {"name": name, "type": "火", "category": "物理",
                            "power": 40, "accuracy": 100, "max_pp": 20,
                            "effect": "", "description": ""}
        self._move_refresh_list()
        for i in range(self.move_list.size()):
            if self.move_list.get(i) == name:
                self.move_list.selection_clear(0, "end")
                self.move_list.selection_set(i)
                self.move_list.see(i)
                self._move_load(name); break

    def _move_delete(self):
        if not self._current_move: return
        if not messagebox.askyesno("确认", f"删除「{self._current_move}」?"): return
        del self.moves[self._current_move]
        save_json(MOVES_FILE, self.moves)
        self._current_move = None
        self._move_refresh_list()
        self._update_status()
        self._move_scroll.pack_forget()
        self._move_placeholder.pack(side="right", fill="both", expand=True)

    # ── run ──────────────────────────────────────────────────────────────────
    def run(self):
        self.root.mainloop()


if __name__ == "__main__":
    App().run()
