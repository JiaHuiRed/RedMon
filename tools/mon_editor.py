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
SPECIES_FILE  = os.path.join(ROOT, "data", "species.json")
MOVES_FILE    = os.path.join(ROOT, "data", "moves.json")
TRAINERS_FILE = os.path.join(ROOT, "data", "trainers.json")

TYPES      = ["", "空", "火", "水", "木", "虫", "土", "风", "仙", "灵", "龙", "格", "雷", "冰", "毒", "岩", "鬼", "暗", "钢"]
GROWTH     = ["快速", "中速", "缓慢"]
CATEGORIES = ["物理", "特殊", "变化"]
GENDERS    = ["50/50", "87.5/12.5", "25/75", "0/100", "无性别"]
TRAINER_GENDERS  = ["男", "女", "未知"]
TRAINER_CLASSES  = ["普通训练师", "精英训练师", "道馆主", "四天王", "冠军", "路人", "商人", "研究员"]
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
        self.species  = load_json(SPECIES_FILE)
        self.moves    = load_json(MOVES_FILE)
        self.trainers = load_json(TRAINERS_FILE) if os.path.exists(TRAINERS_FILE) else {}

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

        # ── Tab 3: 角色编辑 ──
        self.trainer_tab = ttk.Frame(self.notebook)
        self.notebook.add(self.trainer_tab, text=" 角色编辑 ")
        self._build_trainer_tab()

        # Status bar
        self.status = ttk.Label(self.root, relief="sunken", anchor="w")
        self.status.pack(fill="x")
        self._update_status()

        self._current_mon     = None
        self._current_move    = None
        self._current_trainer = None
        self._learnset        = []          # 当前精灵的技能池（临时编辑用）

    # ── helpers ──────────────────────────────────────────────────────────────
    def _update_status(self):
        self.status.config(text=f"精灵: {len(self.species)}  |  技能: {len(self.moves)}  |  角色: {len(self.trainers)}")

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

        # ── right: container → evo bar + scrollable form ─────────────────────
        self._mon_placeholder = ttk.Label(self.mon_tab, text="  选择一个精灵开始编辑", foreground="gray")
        self._mon_placeholder.pack(side="right", fill="both", expand=True)

        self._mon_right = ttk.Frame(self.mon_tab)
        self._evo_bar   = ttk.LabelFrame(self._mon_right, text=" 进化链对比 ")

        self._mon_scroll = ttk.Frame(self._mon_right)
        self._mon_scroll.pack(fill="both", expand=True)
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

        ttk.Label(f, text="进化分支:", anchor="ne").grid(row=row, column=0, sticky="ne", padx=(8, 4), pady=3)
        evo_f = ttk.Frame(f)
        evo_f.grid(row=row, column=1, columnspan=3, sticky="ew", pady=3, padx=(0, 8))
        self.evo_tree = ttk.Treeview(evo_f, columns=("into", "level"), show="headings",
                                     height=3, selectmode="browse")
        self.evo_tree.heading("into",  text="进化为")
        self.evo_tree.heading("level", text="等级")
        self.evo_tree.column("into",  width=120, anchor="w")
        self.evo_tree.column("level", width=50,  anchor="center")
        self.evo_tree.pack(side="left", fill="x", expand=True)
        evo_btn = ttk.Frame(evo_f)
        evo_btn.pack(side="left", padx=(4, 0))
        ttk.Button(evo_btn, text="+", width=3, command=self._evo_add).pack(pady=(0, 2))
        ttk.Button(evo_btn, text="×", width=3, command=self._evo_remove).pack()
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
        self._mon_right.pack(side="right", fill="both", expand=True)

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

        # 加载进化分支（兼容旧单分支格式）
        self.evo_tree.delete(*self.evo_tree.get_children())
        evolutions = d.get("evolutions", [])
        if not evolutions and d.get("evolves_into"):
            evolutions = [{"into": d["evolves_into"], "level": d.get("evolve_level", 0)}]
        for ev in evolutions:
            self.evo_tree.insert("", "end", values=(ev["into"], ev["level"]))

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
        self._refresh_evo_compare(name, d)

    def _refresh_evo_compare(self, name, d):
        for w in self._evo_bar.winfo_children():
            w.destroy()

        # ── 向前追溯到链的根部 ──────────────────────────────────────────────
        # ancestor_chain: [(祖先名, 进化到下一段的等级), ...] 从根到直接前置
        ancestor_chain = []
        cur, visited = name, {name}
        while True:
            pre = next((n for n, s in self.species.items()
                        if cur in [e["into"] for e in s.get("evolutions", [])]
                        or s.get("evolves_into") == cur), None)
            if not pre or pre in visited:
                break
            visited.add(pre)
            pre_data = self.species[pre]
            pre_evos = pre_data.get("evolutions", [])
            arrow_lv = next((e["level"] for e in pre_evos if e["into"] == cur),
                            pre_data.get("evolve_level", "?"))
            ancestor_chain.append((pre, arrow_lv))
            cur = pre
        ancestor_chain.reverse()   # 根 → … → 直接前置

        # ── 当前精灵的所有进化分支 ──────────────────────────────────────────
        branches = d.get("evolutions", [])
        if not branches and d.get("evolves_into"):
            branches = [{"into": d["evolves_into"], "level": d.get("evolve_level", 0)}]
        branches = [b for b in branches if b["into"] in self.species]

        if not ancestor_chain and not branches:
            self._evo_bar.pack_forget()
            return

        self._evo_bar.pack(fill="x", padx=4, pady=(4, 0))

        col = 0
        # 祖先链（逐段绘制：精灵卡 → 箭头 → …）
        for anc_name, arrow_lv in ancestor_chain:
            self._evo_card(self._evo_bar, anc_name, self.species[anc_name], False, row=0, col=col)
            col += 1
            ttk.Label(self._evo_bar, text=f"→Lv{arrow_lv}", foreground="#888888",
                      font=("", 8)).grid(row=0, column=col, padx=2)
            col += 1

        # 当前精灵（高亮）
        self._evo_card(self._evo_bar, name, d, True, row=0, col=col)
        col += 1

        # 分支进化（多行堆叠）
        if branches:
            for br_row, br in enumerate(branches):
                ttk.Label(self._evo_bar, text=f"→Lv{br['level']}", foreground="#888888",
                          font=("", 8)).grid(row=br_row, column=col, padx=2, sticky="w")
                self._evo_card(self._evo_bar, br["into"], self.species[br["into"]],
                               False, row=br_row, col=col + 1)

    def _evo_card(self, parent, mname, mdata, is_cur, row, col):
        cf = ttk.Frame(parent, relief="groove" if is_cur else "flat", borderwidth=1)
        cf.grid(row=row, column=col, padx=6, pady=4, sticky="n")
        lbl = ttk.Label(cf, text=mname, font=("Microsoft YaHei", 9, "bold"))
        if is_cur: lbl.configure(foreground="#b05000")
        lbl.pack()
        t1 = mdata.get("type1", ""); t2 = mdata.get("type2", "")
        ttk.Label(cf, text=f"{t1}{'/' + t2 if t2 else ''}", foreground="#666666",
                  font=("", 8)).pack()
        base = mdata.get("base", {}); total = 0
        for slbl, key in STAT_LABELS:
            v = base.get(key, 0); total += v
            rf = ttk.Frame(cf); rf.pack(fill="x")
            ttk.Label(rf, text=slbl[:3], width=4, anchor="e", font=("", 8)).pack(side="left")
            ttk.Label(rf, text=f"{v:3d}", width=3, font=("", 8)).pack(side="left", padx=(2, 2))
            c = tk.Canvas(rf, width=55, height=7, highlightthickness=0, bg="#dddddd")
            c.pack(side="left")
            w_bar = max(1, int(min(v, BAR_MAX) / BAR_MAX * 55))
            c.create_rectangle(0, 0, w_bar, 7, fill=STAT_COLORS[key], outline="")
        ttk.Label(cf, text=f"BST {total}", font=("Microsoft YaHei", 8, "bold")).pack(pady=(2, 0))

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

    def _evo_add(self):
        dlg = tk.Toplevel(self.root)
        dlg.title("添加进化分支")
        dlg.geometry("300x110")
        dlg.resizable(False, False)
        dlg.transient(self.root); dlg.grab_set()

        ttk.Label(dlg, text="进化为:").grid(row=0, column=0, padx=10, pady=8, sticky="e")
        mon_names = sorted(n for n in self.species if n != self._current_mon)
        cb = ttk.Combobox(dlg, values=mon_names, width=18, state="readonly")
        cb.grid(row=0, column=1, sticky="w", pady=8)
        if mon_names: cb.current(0)

        ttk.Label(dlg, text="等级:").grid(row=1, column=0, padx=10, pady=4, sticky="e")
        lv_var = tk.StringVar(value="20")
        ttk.Spinbox(dlg, from_=1, to=100, width=6, textvariable=lv_var).grid(row=1, column=1, sticky="w")

        def ok():
            tgt = cb.get(); lv = lv_var.get()
            if tgt and lv.isdigit():
                self.evo_tree.insert("", "end", values=(tgt, int(lv)))
                dlg.destroy()
            else:
                messagebox.showwarning("", "请选择目标精灵和等级", parent=dlg)
        bf = ttk.Frame(dlg); bf.grid(row=2, column=0, columnspan=2, pady=6)
        ttk.Button(bf, text="确定", command=ok).pack(side="left", padx=6)
        ttk.Button(bf, text="取消", command=dlg.destroy).pack(side="left", padx=6)

    def _evo_remove(self):
        sel = self.evo_tree.selection()
        if sel: self.evo_tree.delete(sel[0])

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

        # 进化分支
        evolutions = [
            {"into": self.evo_tree.item(iid, "values")[0],
             "level": _int(self.evo_tree.item(iid, "values")[1])}
            for iid in self.evo_tree.get_children()
        ]
        if evolutions:
            d["evolutions"] = evolutions
            # 单分支时保留旧字段兼容游戏代码
            if len(evolutions) == 1:
                d["evolves_into"] = evolutions[0]["into"]
                d["evolve_level"] = evolutions[0]["level"]

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
                for ev in mon.get("evolutions", []):
                    if ev["into"] == old:
                        ev["into"] = new

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
            if self._mon_get_name(self.mon_list.get(i)) == name:
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
        self._mon_right.pack_forget()
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
            save_json(SPECIES_FILE, self.species)

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

    # ════════════════════════════════════════════════════════════════════════
    #  角色编辑 TAB
    # ════════════════════════════════════════════════════════════════════════

    def _build_trainer_tab(self):
        # ── left: search + list ──
        left = ttk.Frame(self.trainer_tab, width=220)
        left.pack(side="left", fill="y", padx=5, pady=5)
        left.pack_propagate(False)

        ttk.Label(left, text="搜索:").pack(anchor="w")
        self.trainer_search = ttk.Entry(left)
        self.trainer_search.pack(fill="x")
        self.trainer_search.bind("<KeyRelease>", lambda _: self._trainer_refresh_list())

        lf = ttk.Frame(left)
        lf.pack(fill="both", expand=True, pady=(4, 4))
        sb = ttk.Scrollbar(lf, orient="vertical")
        self.trainer_list = tk.Listbox(lf, yscrollcommand=sb.set, font=("Microsoft YaHei", 10))
        sb.config(command=self.trainer_list.yview)
        sb.pack(side="right", fill="y")
        self.trainer_list.pack(side="left", fill="both", expand=True)
        self.trainer_list.bind("<<ListboxSelect>>", self._trainer_select)

        bf = ttk.Frame(left)
        bf.pack(fill="x")
        ttk.Button(bf, text="+ 新增", command=self._trainer_add).pack(side="left", padx=(0, 4))
        ttk.Button(bf, text="× 删除", command=self._trainer_delete).pack(side="left")

        # ── right: placeholder + form ──
        self._trainer_placeholder = ttk.Label(self.trainer_tab, text="  选择一个角色开始编辑", foreground="gray")
        self._trainer_placeholder.pack(side="right", fill="both", expand=True)

        self._trainer_form_frame = ttk.Frame(self.trainer_tab)

        ms_canvas = tk.Canvas(self._trainer_form_frame, borderwidth=0, highlightthickness=0)
        ms_vbar   = ttk.Scrollbar(self._trainer_form_frame, orient="vertical", command=ms_canvas.yview)
        self._trainer_inner = ttk.Frame(ms_canvas)
        self._trainer_inner.bind("<Configure>", lambda _: ms_canvas.configure(scrollregion=ms_canvas.bbox("all")))
        ms_canvas.create_window((0, 0), window=self._trainer_inner, anchor="nw")
        ms_canvas.configure(yscrollcommand=ms_vbar.set)
        ms_canvas.pack(side="left", fill="both", expand=True)
        ms_vbar.pack(side="right", fill="y")
        ms_canvas.bind("<Enter>", lambda c=ms_canvas: c.bind_all("<MouseWheel>", lambda e: c.yview_scroll(-1*(e.delta//120), "units")))
        ms_canvas.bind("<Leave>", lambda c=ms_canvas: c.unbind_all("<MouseWheel>"))

        f = self._trainer_inner
        row = 0

        # ID
        ttk.Label(f, text="ID:").grid(row=row, column=0, sticky="e", padx=(8, 4), pady=3)
        self.trainer_id_entry = ttk.Entry(f, width=20)
        self.trainer_id_entry.grid(row=row, column=1, sticky="w", pady=3)
        ttk.Button(f, text="💾 保存", command=self._trainer_save).grid(row=row, column=2, sticky="w", padx=(16, 0))
        row += 1

        # 名字
        ttk.Label(f, text="名字:").grid(row=row, column=0, sticky="e", padx=(8, 4), pady=3)
        self.trainer_name_entry = ttk.Entry(f, width=20)
        self.trainer_name_entry.grid(row=row, column=1, sticky="w", pady=3)
        row += 1

        # 性别 + 身份
        ttk.Label(f, text="性别:").grid(row=row, column=0, sticky="e", padx=(8, 4), pady=3)
        self.trainer_gender = ttk.Combobox(f, values=TRAINER_GENDERS, width=8, state="readonly")
        self.trainer_gender.grid(row=row, column=1, sticky="w", pady=3)
        row += 1

        ttk.Label(f, text="身份:").grid(row=row, column=0, sticky="e", padx=(8, 4), pady=3)
        self.trainer_class = ttk.Combobox(f, values=TRAINER_CLASSES, width=16, state="readonly")
        self.trainer_class.grid(row=row, column=1, sticky="w", pady=3)
        row += 1

        # 赏金
        ttk.Label(f, text="击败赏金:").grid(row=row, column=0, sticky="e", padx=(8, 4), pady=3)
        self.trainer_reward = ttk.Entry(f, width=10, justify="center")
        self.trainer_reward.grid(row=row, column=1, sticky="w", pady=3)
        row += 1

        ttk.Separator(f, orient="horizontal").grid(row=row, column=0, columnspan=4, sticky="ew", pady=6)
        row += 1

        # 对话
        ttk.Label(f, text="挑战台词:").grid(row=row, column=0, sticky="e", padx=(8, 4), pady=3)
        self.trainer_dialog_before = ttk.Entry(f, width=36)
        self.trainer_dialog_before.grid(row=row, column=1, columnspan=2, sticky="ew", pady=3, padx=(0, 8))
        row += 1

        ttk.Label(f, text="败北台词:").grid(row=row, column=0, sticky="e", padx=(8, 4), pady=3)
        self.trainer_dialog_win = ttk.Entry(f, width=36)
        self.trainer_dialog_win.grid(row=row, column=1, columnspan=2, sticky="ew", pady=3, padx=(0, 8))
        row += 1

        ttk.Separator(f, orient="horizontal").grid(row=row, column=0, columnspan=4, sticky="ew", pady=6)
        row += 1

        # 队伍
        ttk.Label(f, text="队伍精灵", font=("Microsoft YaHei", 9, "bold")).grid(row=row, column=0, columnspan=4, sticky="w", padx=8)
        row += 1

        team_cols = ("species", "level")
        self.team_tree = ttk.Treeview(f, columns=team_cols, show="headings", height=6, selectmode="browse")
        self.team_tree.heading("species", text="精灵")
        self.team_tree.heading("level",   text="等级")
        self.team_tree.column("species", width=160, anchor="w")
        self.team_tree.column("level",   width=60,  anchor="center")
        team_scroll = ttk.Scrollbar(f, orient="vertical", command=self.team_tree.yview)
        self.team_tree.configure(yscrollcommand=team_scroll.set)
        self.team_tree.grid(row=row, column=1, columnspan=2, sticky="ew", padx=(0, 8), pady=3)
        team_scroll.grid(row=row, column=3, sticky="ns", padx=(0, 8))
        row += 1

        team_btn = ttk.Frame(f)
        team_btn.grid(row=row, column=1, columnspan=2, sticky="w", padx=(0, 8), pady=3)
        ttk.Button(team_btn, text="+ 添加精灵", command=self._team_add).pack(side="left", padx=(0, 6))
        ttk.Button(team_btn, text="× 移除",     command=self._team_remove).pack(side="left")
        row += 1

        self._trainer_refresh_list()

    def _trainer_show_form(self):
        self._trainer_placeholder.pack_forget()
        self._trainer_form_frame.pack(side="right", fill="both", expand=True, padx=5, pady=5)

    def _trainer_refresh_list(self):
        q = self.trainer_search.get().lower()
        self.trainer_list.delete(0, "end")
        for tid, td in sorted(self.trainers.items(), key=lambda x: x[1].get("name", x[0])):
            name = td.get("name", tid)
            if not q or q in name.lower() or q in tid.lower():
                self.trainer_list.insert("end", f"{name}  [{tid}]")

    def _trainer_get_id(self, display):
        # "学员小闵  [t_xiaomin]" → "t_xiaomin"
        if "[" in display and display.endswith("]"):
            return display.rsplit("[", 1)[1][:-1]
        return display

    def _trainer_select(self, _=None):
        sel = self.trainer_list.curselection()
        if not sel: return
        tid = self._trainer_get_id(self.trainer_list.get(sel[0]))
        self._trainer_load(tid)

    def _trainer_load(self, tid):
        self._trainer_show_form()
        d = self.trainers[tid]
        self._current_trainer = tid

        self.trainer_id_entry.delete(0, "end"); self.trainer_id_entry.insert(0, tid)
        self.trainer_name_entry.delete(0, "end"); self.trainer_name_entry.insert(0, d.get("name", ""))
        self.trainer_gender.set(d.get("gender", "男"))
        self.trainer_class.set(d.get("class", "普通训练师"))
        self.trainer_reward.delete(0, "end"); self.trainer_reward.insert(0, str(d.get("reward", 0)))
        self.trainer_dialog_before.delete(0, "end"); self.trainer_dialog_before.insert(0, d.get("dialog_before", ""))
        self.trainer_dialog_win.delete(0, "end");    self.trainer_dialog_win.insert(0, d.get("dialog_win", ""))

        self.team_tree.delete(*self.team_tree.get_children())
        for mem in d.get("team", []):
            self.team_tree.insert("", "end", values=(mem.get("species", ""), mem.get("level", 1)))

    def _trainer_save(self):
        old_id  = self._current_trainer
        new_id  = self.trainer_id_entry.get().strip()
        name    = self.trainer_name_entry.get().strip()
        if not new_id:
            messagebox.showerror("错误", "ID 不能为空"); return
        if not name:
            messagebox.showerror("错误", "名字不能为空"); return

        team = [
            {"species": self.team_tree.item(iid, "values")[0],
             "level":   _int(self.team_tree.item(iid, "values")[1])}
            for iid in self.team_tree.get_children()
        ]

        d = {
            "id":             new_id,
            "name":           name,
            "gender":         self.trainer_gender.get(),
            "class":          self.trainer_class.get(),
            "reward":         _int(self.trainer_reward.get()),
            "dialog_before":  self.trainer_dialog_before.get().strip(),
            "dialog_win":     self.trainer_dialog_win.get().strip(),
            "team":           team,
        }

        if old_id and old_id != new_id:
            del self.trainers[old_id]

        self.trainers[new_id] = d
        save_json(TRAINERS_FILE, self.trainers)
        self._current_trainer = new_id
        self._trainer_refresh_list()
        self._update_status()
        messagebox.showinfo("", "已保存 ✓")

    def _trainer_add(self):
        tid = "new_trainer"
        i = 1
        while tid in self.trainers:
            i += 1; tid = f"new_trainer_{i}"
        self.trainers[tid] = {
            "id": tid, "name": "新训练师", "gender": "男",
            "class": "普通训练师", "reward": 100,
            "dialog_before": "", "dialog_win": "", "team": [],
        }
        self._trainer_refresh_list()
        for i in range(self.trainer_list.size()):
            if self._trainer_get_id(self.trainer_list.get(i)) == tid:
                self.trainer_list.selection_clear(0, "end")
                self.trainer_list.selection_set(i)
                self.trainer_list.see(i)
                self._trainer_load(tid); break

    def _trainer_delete(self):
        if not self._current_trainer: return
        td = self.trainers[self._current_trainer]
        if not messagebox.askyesno("确认", f"删除「{td.get('name', self._current_trainer)}」?"): return
        del self.trainers[self._current_trainer]
        save_json(TRAINERS_FILE, self.trainers)
        self._current_trainer = None
        self._trainer_refresh_list()
        self._update_status()
        self._trainer_form_frame.pack_forget()
        self._trainer_placeholder.pack(side="right", fill="both", expand=True)

    def _team_add(self):
        dlg = tk.Toplevel(self.root)
        dlg.title("添加队伍精灵")
        dlg.geometry("300x110")
        dlg.resizable(False, False)
        dlg.transient(self.root); dlg.grab_set()

        ttk.Label(dlg, text="精灵:").grid(row=0, column=0, padx=10, pady=8, sticky="e")
        mon_names = sorted(self.species.keys())
        cb = ttk.Combobox(dlg, values=mon_names, width=18, state="readonly")
        cb.grid(row=0, column=1, sticky="w", pady=8)
        if mon_names: cb.current(0)

        ttk.Label(dlg, text="等级:").grid(row=1, column=0, padx=10, pady=4, sticky="e")
        lv_var = tk.StringVar(value="10")
        ttk.Spinbox(dlg, from_=1, to=100, width=6, textvariable=lv_var).grid(row=1, column=1, sticky="w")

        def ok():
            sp = cb.get(); lv = lv_var.get()
            if sp and lv.isdigit():
                self.team_tree.insert("", "end", values=(sp, int(lv)))
                dlg.destroy()
            else:
                messagebox.showwarning("", "请选择精灵和等级", parent=dlg)

        bf = ttk.Frame(dlg); bf.grid(row=2, column=0, columnspan=2, pady=6)
        ttk.Button(bf, text="确定", command=ok).pack(side="left", padx=6)
        ttk.Button(bf, text="取消", command=dlg.destroy).pack(side="left", padx=6)

    def _team_remove(self):
        sel = self.team_tree.selection()
        if sel: self.team_tree.delete(sel[0])

    # ── run ──────────────────────────────────────────────────────────────────
    def run(self):
        self.root.mainloop()


if __name__ == "__main__":
    App().run()
