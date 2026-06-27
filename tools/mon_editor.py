#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
RedMon 数据编辑器 — 精灵 & 技能 & 角色
用法: python -X utf8 tools/mon_editor.py
"""

import json, os, re, sys, tkinter as tk
from tkinter import ttk, messagebox

try:
    from PIL import Image, ImageTk
    HAS_PIL = True
except ImportError:
    HAS_PIL = False

# ── Paths ──────────────────────────────────────────────────────────────────────
if getattr(sys, "frozen", False):
    ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(sys.executable))))
else:
    ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPECIES_FILE  = os.path.join(ROOT, "data", "species.json")
MOVES_FILE    = os.path.join(ROOT, "data", "moves.json")
TRAINERS_FILE = os.path.join(ROOT, "data", "trainers.json")
DIALOGS_FILE  = os.path.join(ROOT, "data", "dialogs.json")
SPRITES_DIR   = os.path.join(ROOT, "assets", "sprites")

TYPES      = ["", "空", "火", "水", "木", "虫", "土", "风", "仙", "灵", "龙", "格", "雷", "冰", "毒", "岩", "鬼", "暗", "钢"]
GROWTH     = ["快速", "中速", "缓慢"]
CATEGORIES = ["物理", "特殊", "变化"]
GENDERS    = ["50/50", "87.5/12.5", "25/75", "0/100", "无性别"]
TRAINER_GENDERS = ["男", "女", "未知"]
TRAINER_CLASSES = ["普通训练师", "精英训练师", "道馆主", "四天王", "冠军", "路人", "商人", "研究员"]
EFFECTS_RAW = ["", "lower_atk", "lower_def", "lower_sp_atk", "lower_sp_def", "lower_spd",
               "lower_acc", "raise_atk", "raise_def", "raise_sp_atk", "raise_sp_def",
               "raise_spd", "raise_acc", "inflict_burn", "inflict_poison",
               "inflict_paralysis", "inflict_sleep", "inflict_freeze", "heal_self"]
EFFECT_LABELS = {
    "": "", "lower_atk": "降攻击", "lower_def": "降防御",
    "lower_sp_atk": "降特攻", "lower_sp_def": "降特防", "lower_spd": "降速度",
    "lower_acc": "降命中", "raise_atk": "升攻击", "raise_def": "升防御",
    "raise_sp_atk": "升特攻", "raise_sp_def": "升特防", "raise_spd": "升速度",
    "raise_acc": "升命中", "inflict_burn": "灼伤", "inflict_poison": "中毒",
    "inflict_paralysis": "麻痹", "inflict_sleep": "催眠", "inflict_freeze": "冰冻",
    "heal_self": "自我回复",
}
EFFECTS = [EFFECT_LABELS.get(e, e) for e in EFFECTS_RAW]
# Reverse lookup: Chinese label → raw key
EFFECT_TO_RAW = {v: k for k, v in EFFECT_LABELS.items()}

# Type matchup chart (attack_type → {defense_type: multiplier})
TYPE_CHART = {
    "空": {"岩": 0.6, "钢": 0.6, "鬼": 0.0},
    "火": {"木": 1.5, "冰": 1.5, "虫": 1.5, "钢": 1.5, "火": 0.6, "水": 0.6, "岩": 0.6, "龙": 0.6},
    "水": {"火": 1.5, "土": 1.5, "岩": 1.5, "水": 0.6, "木": 0.6, "龙": 0.6},
    "木": {"水": 1.5, "土": 1.5, "岩": 1.5, "火": 0.6, "木": 0.6, "毒": 0.6, "风": 0.6, "虫": 0.6, "龙": 0.6, "钢": 0.6},
    "雷": {"水": 1.5, "风": 1.5, "雷": 0.6, "木": 0.6, "龙": 0.6, "土": 0.0},
    "冰": {"木": 1.5, "土": 1.5, "风": 1.5, "龙": 1.5, "水": 0.6, "冰": 0.6, "钢": 0.6},
    "格": {"空": 1.5, "冰": 1.5, "岩": 1.5, "暗": 1.5, "钢": 1.5, "毒": 0.6, "风": 0.6, "灵": 0.6, "虫": 0.6, "仙": 0.6, "鬼": 0.0},
    "毒": {"木": 1.5, "仙": 1.5, "毒": 0.6, "土": 0.6, "岩": 0.6, "鬼": 0.6, "钢": 0.0},
    "土": {"火": 1.5, "雷": 1.5, "毒": 1.5, "岩": 1.5, "钢": 1.5, "木": 0.6, "虫": 0.6, "风": 0.0},
    "风": {"木": 1.5, "格": 1.5, "虫": 1.5, "雷": 0.6, "岩": 0.6, "钢": 0.6},
    "灵": {"格": 1.5, "毒": 1.5, "灵": 0.6, "钢": 0.6},
    "虫": {"木": 1.5, "灵": 1.5, "暗": 1.5, "仙": 1.5, "火": 0.6, "格": 0.6, "风": 0.6, "鬼": 0.6, "钢": 0.6},
    "岩": {"火": 1.5, "冰": 1.5, "风": 1.5, "虫": 1.5, "格": 0.6, "土": 0.6, "钢": 0.6},
    "鬼": {"灵": 1.5, "鬼": 1.5, "暗": 0.6, "空": 0.0},
    "龙": {"龙": 1.5, "钢": 0.6, "仙": 0.0},
    "暗": {"灵": 1.5, "鬼": 1.5, "格": 0.6, "暗": 0.6, "仙": 0.6},
    "钢": {"冰": 1.5, "岩": 1.5, "仙": 1.5, "火": 0.6, "水": 0.6, "雷": 0.6, "钢": 0.6},
    "仙": {"格": 1.5, "龙": 1.5, "暗": 1.5, "火": 0.6, "毒": 0.6, "钢": 0.6},
}
ALL_TYPES = ["空", "火", "水", "木", "雷", "冰", "格", "毒", "土", "风", "灵", "虫", "岩", "鬼", "龙", "暗", "钢", "仙"]

# (text_color, bg_color) per type
TYPE_COLORS = {
    "空": ("#1C1C1E", "#9EA0A3"), "火": ("#FFFFFF", "#E8522B"), "水": ("#FFFFFF", "#5A7CF0"),
    "木": ("#FFFFFF", "#5DAA3C"), "虫": ("#FFFFFF", "#8FAC14"), "土": ("#1C1C1E", "#D4A84B"),
    "风": ("#1C1C1E", "#78C8C8"), "仙": ("#FFFFFF", "#D065A7"), "灵": ("#FFFFFF", "#D14B80"),
    "龙": ("#FFFFFF", "#5028D0"), "格": ("#FFFFFF", "#9C2222"), "雷": ("#1C1C1E", "#EEC830"),
    "冰": ("#1C1C1E", "#78C8D0"), "毒": ("#FFFFFF", "#8830A0"), "岩": ("#FFFFFF", "#9A8228"),
    "鬼": ("#FFFFFF", "#5C3878"), "暗": ("#FFFFFF", "#524238"), "钢": ("#1C1C1E", "#9898B8"),
}

STAT_COLORS = {
    "hp":     "#78C850", "atk":    "#F08030", "def":    "#F8D030",
    "sp_atk": "#6890F0", "sp_def": "#F85888", "spd":    "#98D8D8",
}
STAT_LABELS = [("HP", "hp"), ("攻击", "atk"), ("防御", "def"),
               ("特攻", "sp_atk"), ("特防", "sp_def"), ("速度", "spd")]
BAR_MAX = 180
BAR_W   = 150

# ── Palette ────────────────────────────────────────────────────────────────────
BG_MAIN  = "#F5F5F7"
BG_SIDE  = "#EBEBED"
BG_CARD  = "#FFFFFF"
ACCENT   = "#007AFF"
TEXT_PRI = "#1C1C1E"
TEXT_SEC = "#636366"
BORDER   = "#D1D1D6"
DOT_RED  = "#FF5F56"
DOT_YLW  = "#FFBD2E"
DOT_GRN  = "#27C93F"
FONT_CJK = "Microsoft YaHei"


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
#  SearchableCombo — Entry + live-filter popup list
# ══════════════════════════════════════════════════════════════════════════════

class SearchableCombo(tk.Frame):
    """Replaces readonly Combobox: type to filter, arrow/click to select."""

    def __init__(self, parent, items: list, width=20, **kw):
        super().__init__(parent, bg=BG_MAIN, **kw)
        self._all   = items
        self._var   = tk.StringVar()
        self._popup = None
        self._lb    = None

        self._entry = ttk.Entry(self, textvariable=self._var, width=width)
        self._entry.pack(fill="x", expand=True)

        self._entry.bind("<KeyRelease>",  self._on_key)
        self._entry.bind("<Down>",        self._focus_list)
        self._entry.bind("<Escape>",      lambda _: self._close())
        self._entry.bind("<FocusOut>",    lambda _: self.after(200, self._maybe_close))

    def get(self):    return self._var.get()
    def set(self, v): self._var.set(v)

    def _filtered(self):
        q = self._var.get().lower()
        return [i for i in self._all if q in i.lower()] if q else list(self._all)

    def _on_key(self, e):
        if e.keysym in ("Return", "Up", "Down", "Escape", "Tab"):
            return
        items = self._filtered()
        if items:
            self._open_popup(items)
        else:
            self._close()

    def _open_popup(self, items):
        x = self._entry.winfo_rootx()
        y = self._entry.winfo_rooty() + self._entry.winfo_height()
        h = min(8, len(items))

        if self._popup and self._popup.winfo_exists():
            self._lb.delete(0, "end")
            self._popup.geometry(f"+{x}+{y}")
        else:
            self._popup = tk.Toplevel(self._entry)
            self._popup.overrideredirect(True)
            self._popup.attributes("-topmost", True)
            self._popup.geometry(f"+{x}+{y}")

            outer = tk.Frame(self._popup, bg=BORDER)
            outer.pack(fill="both", expand=True, padx=1, pady=1)

            sb = tk.Scrollbar(outer, orient="vertical")
            self._lb = tk.Listbox(outer, yscrollcommand=sb.set, height=h,
                                   font=(FONT_CJK, 9), bg=BG_CARD,
                                   selectbackground=ACCENT, selectforeground="white",
                                   borderwidth=0, highlightthickness=0,
                                   relief="flat", activestyle="dotbox")
            sb.config(command=self._lb.yview)
            sb.pack(side="right", fill="y")
            self._lb.pack(side="left", fill="both", expand=True)

            self._lb.bind("<<ListboxSelect>>", lambda _: self._pick())
            self._lb.bind("<Return>",          lambda _: self._pick())
            self._lb.bind("<Escape>",          lambda _: self._close())
            self._lb.bind("<FocusOut>",        lambda _: self.after(200, self._maybe_close))

        for it in items[:30]:
            self._lb.insert("end", it)
        self._lb.config(height=min(8, len(items)))

    def _pick(self):
        if self._lb:
            sel = self._lb.curselection()
            if sel:
                self._var.set(self._lb.get(sel[0]))
        self._close()

    def _focus_list(self, _=None):
        if self._popup and self._popup.winfo_exists():
            self._lb.focus_set()
            if not self._lb.curselection():
                self._lb.selection_set(0)

    def _maybe_close(self):
        try:
            fw = self.focus_get()
            if fw is self._entry or (self._lb and fw is self._lb):
                return
        except Exception:
            pass
        self._close()

    def _close(self):
        if self._popup and self._popup.winfo_exists():
            self._popup.destroy()
        self._popup = None
        self._lb    = None


# ══════════════════════════════════════════════════════════════════════════════
#  Helpers
# ══════════════════════════════════════════════════════════════════════════════

def _type_badge(parent, type_name: str, bg: str) -> tk.Canvas:
    """Rounded pill badge for a type name."""
    fg, fill = TYPE_COLORS.get(type_name, ("#1C1C1E", "#CCCCCC"))
    c = tk.Canvas(parent, width=38, height=18, bg=bg, highlightthickness=0)
    r = 5
    W, H = 38, 18
    c.create_rectangle(r, 0, W - r, H, fill=fill, outline="")
    c.create_rectangle(0, r, W,     H - r, fill=fill, outline="")
    for ox, oy, ex, ey, start in [(0, 0, 2*r, 2*r, 90), (W-2*r, 0, W, 2*r, 0),
                                    (0, H-2*r, 2*r, H, 180), (W-2*r, H-2*r, W, H, 270)]:
        c.create_arc(ox, oy, ex, ey, start=start, extent=90, fill=fill, outline="")
    c.create_text(W // 2, H // 2, text=type_name, fill=fg,
                  font=(FONT_CJK, 8, "bold"))
    return c


def _sep(parent, bg=BG_MAIN, row=0, col=0, cols=5, pady=4, padx=10):
    """Horizontal separator helper."""
    f = tk.Frame(parent, bg=BORDER, height=1)
    f.grid(row=row, column=col, columnspan=cols, sticky="ew", padx=padx, pady=pady)
    return f


def _lbl(parent, text, bg=None, fg=None, bold=False, size=8):
    bg = bg or BG_MAIN
    fg = fg or TEXT_SEC
    font = (FONT_CJK, size, "bold") if bold else (FONT_CJK, size)
    return tk.Label(parent, text=text, bg=bg, fg=fg, font=font)


# ══════════════════════════════════════════════════════════════════════════════
#  App
# ══════════════════════════════════════════════════════════════════════════════

class App:
    def __init__(self):
        self.species  = load_json(SPECIES_FILE)
        self.moves    = load_json(MOVES_FILE)
        self.trainers = load_json(TRAINERS_FILE) if os.path.exists(TRAINERS_FILE) else {}

        # 隐藏根窗口用于保留任务栏图标，实际 UI 在 Toplevel 上
        self._ghost = tk.Tk()
        self._ghost.title("RedMon 数据编辑器")
        self._ghost.geometry("0x0+0+0")
        self._ghost.attributes("-alpha", 0)
        self._ghost.bind("<Map>", lambda e: self.root.deiconify())
        self._ghost.bind("<Unmap>", lambda e: self.root.withdraw())
        self._ghost.protocol("WM_DELETE_WINDOW", self._on_close)
        # 设置任务栏图标（使用 Godot 项目图标，若无则用默认）
        _icon_path = os.path.join(ROOT, "icon.ico")
        if os.path.exists(_icon_path):
            self._ghost.iconbitmap(_icon_path)

        self.root = tk.Toplevel(self._ghost)
        self.root.title("RedMon 数据编辑器")
        self.root.geometry("1360x800")
        self.root.minsize(960, 620)
        self.root.configure(bg=BG_MAIN)
        self.root.overrideredirect(True)   # 移除系统标题栏
        self.root.protocol("WM_DELETE_WINDOW", self._on_close)
        self._drag_x = 0
        self._drag_y = 0
        self._is_maximized  = False
        self._normal_geo    = None
        self._resize_dir    = None
        self._resize_x0     = 0
        self._resize_y0     = 0
        self._resize_geom   = (1360, 800, 0, 0)

        self._apply_theme()
        self._build_titlebar()
        self._setup_resize()

        self.notebook = ttk.Notebook(self.root)
        self.notebook.pack(fill="both", expand=True)

        self.mon_tab     = ttk.Frame(self.notebook)
        self.move_tab    = ttk.Frame(self.notebook)
        self.trainer_tab = ttk.Frame(self.notebook)
        self.dialog_tab  = ttk.Frame(self.notebook)
        self.notebook.add(self.mon_tab,     text="  精灵图鉴  ")
        self.notebook.add(self.move_tab,    text="  技能库  ")
        self.notebook.add(self.trainer_tab, text="  角色编辑  ")
        self.notebook.add(self.dialog_tab,  text="  剧情文本  ")

        self._build_mon_tab()
        self._build_move_tab()
        self._build_trainer_tab()
        self._build_dialog_tab()

        self.status = tk.Label(self.root, anchor="w", bg=BG_SIDE, fg=TEXT_SEC,
                               font=(FONT_CJK, 8), padx=14)
        self.status.pack(fill="x", side="bottom", ipady=4)
        self._update_status()

        self._current_mon     = None
        self._current_move    = None
        self._current_trainer = None
        self._learnset        = []
        self._photo_front     = None  # prevent GC
        self._photo_back      = None

    # ── Theme ──────────────────────────────────────────────────────────────

    def _apply_theme(self):
        s = ttk.Style(self.root)
        s.theme_use("clam")
        s.configure(".", background=BG_MAIN, foreground=TEXT_PRI,
                    font=(FONT_CJK, 9), relief="flat")
        s.configure("TFrame",              background=BG_MAIN)
        s.configure("TLabel",              background=BG_MAIN, foreground=TEXT_PRI)
        s.configure("TLabelframe",         background=BG_MAIN, bordercolor=BORDER)
        s.configure("TLabelframe.Label",   background=BG_MAIN, foreground=TEXT_SEC,
                    font=(FONT_CJK, 8, "bold"))
        s.configure("TNotebook",           background=BG_SIDE, borderwidth=0)
        s.configure("TNotebook.Tab",       background=BG_SIDE, foreground=TEXT_SEC,
                    padding=(14, 6))
        s.map("TNotebook.Tab",
              background=[("selected", BG_MAIN)],
              foreground=[("selected", ACCENT)])
        s.configure("TButton",             background=BG_CARD, foreground=TEXT_PRI,
                    borderwidth=1, relief="flat", padding=(8, 4))
        s.map("TButton",
              background=[("active", "#E5E5EA"), ("pressed", BORDER)])
        s.configure("TEntry",              fieldbackground=BG_CARD, borderwidth=1,
                    relief="flat")
        s.configure("TCombobox",           fieldbackground=BG_CARD)
        s.configure("TSpinbox",            fieldbackground=BG_CARD)
        s.configure("Treeview",            background=BG_CARD, fieldbackground=BG_CARD,
                    foreground=TEXT_PRI, rowheight=22, borderwidth=0)
        s.configure("Treeview.Heading",    background=BG_SIDE, foreground=TEXT_SEC,
                    font=(FONT_CJK, 8, "bold"), relief="flat")
        s.map("Treeview",
              background=[("selected", ACCENT)],
              foreground=[("selected", "white")])
        s.configure("TSeparator",          background=BORDER)

    # ── Traffic-light title bar ─────────────────────────────────────────────

    def _build_titlebar(self):
        hdr = tk.Frame(self.root, bg=BG_SIDE, height=40)
        hdr.pack(fill="x", side="top")
        hdr.pack_propagate(False)

        # 拖动支持（整个标题栏可拖动窗口）
        hdr.bind("<ButtonPress-1>", self._on_drag_start)
        hdr.bind("<B1-Motion>",     self._on_drag_motion)

        dot_row = tk.Frame(hdr, bg=BG_SIDE)
        dot_row.place(x=14, rely=0.5, anchor="w")

        actions = [
            (DOT_RED, self._on_close),
            (DOT_YLW, self._iconify),
            (DOT_GRN, self._toggle_maximize),
        ]
        for color, action in actions:
            c = tk.Canvas(dot_row, width=13, height=13, bg=BG_SIDE,
                          highlightthickness=0, cursor="hand2")
            c.pack(side="left", padx=4)
            c.create_oval(1, 1, 12, 12, fill=color, outline="", width=0)
            c.bind("<Button-1>", lambda e, a=action: a())

        tk.Label(hdr, text="RedMon 数据编辑器", bg=BG_SIDE, fg=TEXT_PRI,
                 font=(FONT_CJK, 10, "bold")).place(relx=0.5, rely=0.5, anchor="center")

    def _on_close(self):
        self.root.destroy()
        self._ghost.destroy()

    def _iconify(self):
        self.root.withdraw()
        self._ghost.iconify()

    def _on_drag_start(self, event):
        self._drag_x = event.x_root - self.root.winfo_x()
        self._drag_y = event.y_root - self.root.winfo_y()

    def _on_drag_motion(self, event):
        if self._is_maximized or self._resize_dir:
            return
        self.root.geometry(f"+{event.x_root - self._drag_x}+{event.y_root - self._drag_y}")

    # ── Resize (root-level binding, works over any child widget) ────────────

    def _setup_resize(self):
        self.root.bind("<Motion>",          self._resize_hover)
        self.root.bind("<ButtonPress-1>",   self._resize_press)
        self.root.bind("<B1-Motion>",       self._resize_move)
        self.root.bind("<ButtonRelease-1>", self._resize_release)

    def _resize_zone(self, rx, ry):
        """Return resize direction string or None based on window-relative coords."""
        W = self.root.winfo_width()
        H = self.root.winfo_height()
        E = 8
        on_w = rx < E
        on_e = rx > W - E
        on_s = ry > H - E
        if on_s and on_w: return "sw"
        if on_s and on_e: return "se"
        if on_s:          return "s"
        if on_w:          return "w"
        if on_e:          return "e"
        return None

    def _resize_hover(self, event):
        if self._is_maximized: return
        zone = self._resize_zone(event.x_root - self.root.winfo_x(),
                                 event.y_root - self.root.winfo_y())
        cur = {"sw": "sizing", "se": "sizing",
               "s":  "sb_v_double_arrow",
               "w":  "sb_h_double_arrow",
               "e":  "sb_h_double_arrow"}.get(zone, "")
        self.root.config(cursor=cur)

    def _resize_press(self, event):
        if self._is_maximized: return
        zone = self._resize_zone(event.x_root - self.root.winfo_x(),
                                 event.y_root - self.root.winfo_y())
        if zone:
            self._resize_dir = zone
            self._resize_x0  = event.x_root
            self._resize_y0  = event.y_root
            geo = self.root.geometry()
            m = re.match(r"(\d+)x(\d+)([+-]\d+)([+-]\d+)", geo)
            if m:
                self._resize_geom = tuple(int(m.group(i)) for i in range(1, 5))
        else:
            self._resize_dir = None

    def _resize_move(self, event):
        if not self._resize_dir or self._is_maximized: return
        dx = event.x_root - self._resize_x0
        dy = event.y_root - self._resize_y0
        W, H, X, Y = self._resize_geom
        nW, nH, nX, nY = W, H, X, Y
        MIN_W, MIN_H = self.root.minsize()
        d = self._resize_dir
        if "e" in d: nW = max(MIN_W, W + dx)
        if "s" in d: nH = max(MIN_H, H + dy)
        if "w" in d:
            nW = max(MIN_W, W - dx)
            nX = X + W - nW
        self.root.geometry(f"{nW}x{nH}+{nX}+{nY}")

    def _resize_release(self, event):
        self._resize_dir = None

    def _toggle_maximize(self):
        if self._is_maximized:
            self.root.geometry(self._normal_geo)
            self._is_maximized = False
        else:
            self._normal_geo = self.root.geometry()
            sw = self.root.winfo_screenwidth()
            sh = self.root.winfo_screenheight()
            self.root.geometry(f"{sw}x{sh}+0+0")
            self._is_maximized = True

    # ── Status / draw helpers ───────────────────────────────────────────────

    def _update_status(self, msg=None):
        if msg:
            self.status.config(text=f"  {msg}")
        else:
            n_sp = len(self.species)
            n_mv = len(self.moves)
            n_tr = len(self.trainers)
            self.status.config(
                text=f"  精灵 {n_sp} 种  ·  技能 {n_mv} 个  ·  角色 {n_tr} 名")

    def _draw_bar(self, canvas, value, color):
        canvas.delete("all")
        w = max(2, int(min(value, BAR_MAX) / BAR_MAX * BAR_W))
        canvas.create_rectangle(0, 2, BAR_W, 12, fill="#E5E5EA", outline="")
        canvas.create_rectangle(0, 2, w,     12, fill=color,    outline="")

    # ══════════════════════════════════════════════════════════════════════════
    #  精灵图鉴 TAB
    # ══════════════════════════════════════════════════════════════════════════

    def _build_mon_tab(self):
        # ── Left sidebar ────────────────────────────────────────────────────
        left = tk.Frame(self.mon_tab, bg=BG_SIDE, width=230)
        left.pack(side="left", fill="y")
        left.pack_propagate(False)

        _lbl(left, "精灵列表", bg=BG_SIDE, bold=True).pack(
            anchor="w", padx=12, pady=(12, 2))

        srch_f = tk.Frame(left, bg=BG_SIDE)
        srch_f.pack(fill="x", padx=10, pady=(0, 6))
        self.mon_search = ttk.Entry(srch_f)
        self.mon_search.pack(fill="x")
        self.mon_search.bind("<KeyRelease>", lambda _: self._mon_refresh_list())

        lf = tk.Frame(left, bg=BG_SIDE)
        lf.pack(fill="both", expand=True, padx=10)
        sb = ttk.Scrollbar(lf, orient="vertical")
        self.mon_list = tk.Listbox(
            lf, yscrollcommand=sb.set, font=(FONT_CJK, 10),
            bg=BG_CARD, fg=TEXT_PRI,
            selectbackground=ACCENT, selectforeground="white",
            borderwidth=0, highlightthickness=0, relief="flat",
            activestyle="none")
        sb.config(command=self.mon_list.yview)
        sb.pack(side="right", fill="y")
        self.mon_list.pack(side="left", fill="both", expand=True)
        self.mon_list.bind("<<ListboxSelect>>", self._mon_select)

        bf = tk.Frame(left, bg=BG_SIDE)
        bf.pack(fill="x", padx=10, pady=(6, 12))
        ttk.Button(bf, text="+ 新增", command=self._mon_add).pack(
            side="left", padx=(0, 4))
        ttk.Button(bf, text="× 删除", command=self._mon_delete).pack(side="left")

        # ── Placeholder ──────────────────────────────────────────────────────
        self._mon_placeholder = tk.Label(
            self.mon_tab, text="← 选择一个精灵开始编辑",
            bg=BG_MAIN, fg=TEXT_SEC, font=(FONT_CJK, 12))
        self._mon_placeholder.pack(side="right", fill="both", expand=True)

        # ── Right container ──────────────────────────────────────────────────
        self._mon_right = tk.Frame(self.mon_tab, bg=BG_MAIN)

        # ── Top: form + right panel (sprite + learnset) ─────────────────────
        split = tk.Frame(self._mon_right, bg=BG_MAIN)
        split.pack(side="top", fill="both", expand=True)

        # ── Center: scrollable form ──────────────────────────────────────────
        form_wrap = tk.Frame(split, bg=BG_MAIN)
        form_wrap.pack(side="left", fill="both", expand=True)

        self._mon_canvas = tk.Canvas(
            form_wrap, bg=BG_MAIN, borderwidth=0, highlightthickness=0)
        self._mon_vbar = ttk.Scrollbar(
            form_wrap, orient="vertical", command=self._mon_canvas.yview)
        self._mon_inner = tk.Frame(self._mon_canvas, bg=BG_MAIN)
        self._mon_inner.bind(
            "<Configure>",
            lambda _: self._mon_canvas.configure(
                scrollregion=self._mon_canvas.bbox("all")))
        self._mon_canvas.create_window((0, 0), window=self._mon_inner, anchor="nw")
        self._mon_canvas.configure(yscrollcommand=self._mon_vbar.set)
        self._mon_canvas.pack(side="left", fill="both", expand=True)
        self._mon_vbar.pack(side="right", fill="y")
        self._mon_canvas.bind(
            "<Enter>",
            lambda _: self._mon_canvas.bind_all(
                "<MouseWheel>",
                lambda e: self._mon_canvas.yview_scroll(-1*(e.delta//120), "units")))
        self._mon_canvas.bind(
            "<Leave>",
            lambda _: self._mon_canvas.unbind_all("<MouseWheel>"))

        # ── Right panel: sprite + learnset + matchup ─────────────────────────
        rp_outer = tk.Frame(split, bg=BG_SIDE, width=440)
        rp_outer.pack(side="right", fill="both")
        rp_outer.pack_propagate(False)
        rp_canvas = tk.Canvas(rp_outer, bg=BG_SIDE, borderwidth=0, highlightthickness=0)
        rp_vbar = ttk.Scrollbar(rp_outer, orient="vertical", command=rp_canvas.yview)
        rp = tk.Frame(rp_canvas, bg=BG_SIDE)
        rp.bind("<Configure>", lambda _: rp_canvas.configure(scrollregion=rp_canvas.bbox("all")))
        rp_canvas.create_window((0, 0), window=rp, anchor="nw")
        rp_canvas.configure(yscrollcommand=rp_vbar.set)
        rp_canvas.pack(side="left", fill="both", expand=True)
        rp_vbar.pack(side="right", fill="y")
        rp_canvas.bind(
            "<Enter>",
            lambda _: rp_canvas.bind_all(
                "<MouseWheel>",
                lambda e: rp_canvas.yview_scroll(-1*(e.delta//120), "units")))
        rp_canvas.bind(
            "<Leave>",
            lambda _: rp_canvas.unbind_all("<MouseWheel>"))

        # Sprite card
        sp_card = tk.Frame(rp, bg=BG_CARD)
        sp_card.pack(fill="x", padx=10, pady=(10, 4))

        _lbl(sp_card, "图鉴预览", bg=BG_CARD, bold=True).pack(
            anchor="w", padx=10, pady=(8, 4))

        sp_imgs = tk.Frame(sp_card, bg=BG_CARD)
        sp_imgs.pack(fill="x", padx=10, pady=(0, 8))

        front_col = tk.Frame(sp_imgs, bg=BG_CARD)
        front_col.pack(side="left", expand=True)
        self._sprite_front_lbl = tk.Label(
            front_col, bg=BG_CARD, width=110, height=110,
            text="暂无", fg=TEXT_SEC, font=(FONT_CJK, 8))
        self._sprite_front_lbl.pack()
        _lbl(front_col, "正面", bg=BG_CARD, fg=TEXT_SEC).pack()

        back_col = tk.Frame(sp_imgs, bg=BG_CARD)
        back_col.pack(side="left", expand=True)
        self._sprite_back_lbl = tk.Label(
            back_col, bg=BG_CARD, width=110, height=110,
            text="暂无", fg=TEXT_SEC, font=(FONT_CJK, 8))
        self._sprite_back_lbl.pack()
        _lbl(back_col, "背面", bg=BG_CARD, fg=TEXT_SEC).pack()

        # Type badges row (updated on load)
        self._badge_frame = tk.Frame(sp_card, bg=BG_CARD, height=28)
        self._badge_frame.pack(fill="x", padx=10, pady=(0, 8))

        # Learnset panel
        ls_card = tk.Frame(rp, bg=BG_CARD)
        ls_card.pack(fill="x", padx=10, pady=(0, 4))

        _lbl(ls_card, "技能池", bg=BG_CARD, bold=True).pack(
            anchor="w", padx=10, pady=(8, 2))

        # 按钮先 pack（side=bottom），这样无论 treeview 多高按钮都不会被覆盖
        ls_btn = tk.Frame(ls_card, bg=BG_CARD)
        ls_btn.pack(side="bottom", fill="x", padx=10, pady=(4, 8))
        ttk.Button(ls_btn, text="+ 添加技能",
                   command=self._ls_add).pack(side="left", padx=(0, 6))
        ttk.Button(ls_btn, text="× 删除技能",
                   command=self._ls_remove).pack(side="left")
        ttk.Button(ls_btn, text="✏ 编辑等级",
                   command=self._ls_edit_level).pack(side="left", padx=(6, 0))

        _ls_cols = ("level", "name", "type", "cat", "power", "acc", "pp")
        ls_tree_f = tk.Frame(ls_card, bg=BG_CARD)
        ls_tree_f.pack(side="top", fill="x", padx=6)
        self.ls_tree = ttk.Treeview(
            ls_tree_f, columns=_ls_cols, show="headings",
            selectmode="browse", height=8)
        for col_id, head, w, anc in [
            ("level", "等级", 40, "center"), ("name",  "招式", 100, "w"),
            ("type",  "属性", 36, "center"), ("cat",   "分类", 44, "center"),
            ("power", "威力", 42, "center"), ("acc",   "命中", 42, "center"),
            ("pp",    "PP",   36, "center"),
        ]:
            self.ls_tree.heading(col_id, text=head)
            self.ls_tree.column(col_id, width=w, anchor=anc)
        _ls_sv = ttk.Scrollbar(ls_tree_f, orient="vertical",
                                command=self.ls_tree.yview)
        self.ls_tree.configure(yscrollcommand=_ls_sv.set)
        _ls_sv.pack(side="right", fill="y")
        self.ls_tree.pack(side="left", fill="x")

        # ── Bottom: evo chain + type matchup side by side ────────────────────
        _bottom_area = tk.Frame(self._mon_right, bg=BG_MAIN)
        _bottom_area.pack(side="bottom", fill="x")

        self._evo_bar = ttk.LabelFrame(_bottom_area, text=" 进化链对比 ")
        self._matchup_card = tk.Frame(_bottom_area, bg=BG_CARD, bd=1, relief="groove")
        _lbl(self._matchup_card, "属性克制", bg=BG_CARD, bold=True).pack(
            anchor="w", padx=10, pady=(8, 4))
        self._matchup_inner = tk.Frame(self._matchup_card, bg=BG_CARD)
        self._matchup_inner.pack(fill="x", padx=10, pady=(0, 8))

        # ── Build form inside _mon_inner ─────────────────────────────────────
        f   = self._mon_inner
        row = 0
        PAD = (10, 4)

        # Header row: 编号 + 名称 + 保存
        hf = tk.Frame(f, bg=BG_MAIN)
        hf.grid(row=row, column=0, columnspan=5, sticky="ew",
                padx=12, pady=(14, 4))
        _lbl(hf, "编号", bg=BG_MAIN).pack(side="left")
        self.mon_id = ttk.Entry(hf, width=5, justify="center")
        self.mon_id.pack(side="left", padx=(4, 18))
        _lbl(hf, "名称", bg=BG_MAIN).pack(side="left")
        self.mon_name = ttk.Entry(hf, width=14)
        self.mon_name.pack(side="left", padx=(4, 18))
        ttk.Button(hf, text="💾 保存", command=self._mon_save).pack(side="left")
        ttk.Button(hf, text="⚡ 推荐", command=self._suggest_tier_role).pack(side="left", padx=(8, 0))
        tk.Frame(hf, bg=BORDER, width=1, height=20).pack(side="left", fill="y", padx=(12, 8))
        _lbl(hf, "品阶", bg=BG_MAIN).pack(side="left")
        self.mon_tier = ttk.Combobox(
            hf, values=["", "凡", "灵", "玄", "地", "神", "天"],
            width=4, state="readonly")
        self.mon_tier.pack(side="left", padx=(4, 10))
        _lbl(hf, "定位", bg=BG_MAIN).pack(side="left")
        self.mon_role = ttk.Combobox(
            hf, values=["", "物攻手", "特攻手", "混攻手", "快攻手",
                        "物盾", "特盾", "全盾", "辅助", "均衡"],
            width=6, state="readonly")
        self.mon_role.pack(side="left", padx=(4, 0))
        row += 1

        # 属性
        _sep(f, row=row, col=0); row += 1
        _lbl(f, "属性").grid(row=row, column=0, sticky="e", padx=PAD, pady=3)
        tf = tk.Frame(f, bg=BG_MAIN)
        tf.grid(row=row, column=1, columnspan=3, sticky="w", pady=3)
        self.mon_t1 = ttk.Combobox(tf, values=TYPES, width=7, state="readonly")
        self.mon_t1.pack(side="left")
        self.mon_t2 = ttk.Combobox(tf, values=TYPES, width=7, state="readonly")
        self.mon_t2.pack(side="left", padx=(6, 0))
        self.mon_t1.bind("<<ComboboxSelected>>", lambda _: self._refresh_badges())
        self.mon_t2.bind("<<ComboboxSelected>>", lambda _: self._refresh_badges())
        row += 1

        # 种族值
        _sep(f, row=row, col=0); row += 1
        sh = tk.Frame(f, bg=BG_MAIN)
        sh.grid(row=row, column=0, columnspan=5, sticky="w", padx=12)
        _lbl(sh, "种族值", bg=BG_MAIN, bold=True, size=9).pack(side="left")
        row += 1

        _lbl(f, "", bg=BG_MAIN).grid(row=row, column=0)
        _lbl(f, "", bg=BG_MAIN).grid(row=row, column=1)
        _lbl(f, "", bg=BG_MAIN).grid(row=row, column=2)
        _lbl(f, "Lv 50", bg=BG_MAIN, fg=TEXT_SEC).grid(row=row, column=3, padx=(4, 2))
        _lbl(f, "Lv100", bg=BG_MAIN, fg=TEXT_SEC).grid(row=row, column=4, padx=(2, 10))
        row += 1

        self.mon_stat_entries = {}
        self.mon_stat_bars    = {}
        self.mon_stat_lv50    = {}
        self.mon_stat_lv100   = {}
        for label, key in STAT_LABELS:
            _lbl(f, label, bg=BG_MAIN, fg=TEXT_SEC).grid(
                row=row, column=0, sticky="e", padx=PAD, pady=2)
            e = ttk.Entry(f, width=5, justify="center")
            e.grid(row=row, column=1, sticky="w", pady=2)
            e.bind("<KeyRelease>", lambda _: self._refresh_stat_bars())
            self.mon_stat_entries[key] = e

            c = tk.Canvas(f, width=BAR_W, height=14,
                          bg=BG_MAIN, highlightthickness=0)
            c.grid(row=row, column=2, sticky="w", padx=(8, 4))
            self.mon_stat_bars[key] = c

            l50 = _lbl(f, "0", bg=BG_MAIN, fg=TEXT_SEC)
            l50.configure(width=4, font=(FONT_CJK, 7))
            l50.grid(row=row, column=3, padx=(4, 2))
            self.mon_stat_lv50[key] = l50

            l100 = _lbl(f, "0", bg=BG_MAIN, fg=TEXT_SEC)
            l100.configure(width=4, font=(FONT_CJK, 7))
            l100.grid(row=row, column=4, padx=(2, 10))
            self.mon_stat_lv100[key] = l100
            row += 1

        bst_f = tk.Frame(f, bg=BG_MAIN)
        bst_f.grid(row=row, column=0, columnspan=5, sticky="w", padx=12, pady=(2, 4))
        _lbl(bst_f, "种族值总和  BST:", bg=BG_MAIN).pack(side="left")
        self.mon_total_label = tk.Label(
            bst_f, text="0", bg=BG_MAIN, fg=TEXT_PRI,
            font=(FONT_CJK, 10, "bold"))
        self.mon_total_label.pack(side="left", padx=6)
        row += 1

        # 其他属性 + 进化分支（并排）
        _sep(f, row=row, col=0); row += 1
        misc_evo_f = tk.Frame(f, bg=BG_MAIN)
        misc_evo_f.grid(row=row, column=0, columnspan=5, sticky="ew", padx=12, pady=2)

        misc = tk.Frame(misc_evo_f, bg=BG_MAIN)
        misc.pack(side="left", anchor="n", padx=(0, 8))
        for r2, (lbl_txt, attr, w2) in enumerate([
            ("捕获率", "mon_catch",  6),
            ("经验值", "mon_exp",    6),
            ("成长速度", None,       0),
            ("性别比例", None,       0),
            ("身高 m",  "mon_height", 7),
            ("体重 kg", "mon_weight", 7),
        ]):
            col2 = (r2 % 2) * 3
            r2b  = r2 // 2
            _lbl(misc, lbl_txt, bg=BG_MAIN).grid(
                row=r2b, column=col2, sticky="e", padx=(0 if col2 else 0, 4), pady=2)
            if attr:
                e = ttk.Entry(misc, width=w2, justify="center")
                e.grid(row=r2b, column=col2 + 1, sticky="w")
                setattr(self, attr, e)

        # Patch comboboxes into misc layout
        self.mon_growth = ttk.Combobox(misc, values=GROWTH, width=8, state="readonly")
        self.mon_growth.grid(row=1, column=1, sticky="w", pady=2)
        self.mon_gender = ttk.Combobox(misc, values=GENDERS, width=12, state="normal")
        self.mon_gender.grid(row=1, column=4, sticky="w", pady=2)

        # 进化分支（与捕获率并列，同行右侧）
        tk.Frame(misc_evo_f, bg=BORDER, width=1).pack(side="left", fill="y", padx=(0, 8))
        evo_col = tk.Frame(misc_evo_f, bg=BG_MAIN)
        evo_col.pack(side="left", anchor="n", fill="x", expand=True)
        _lbl(evo_col, "进化分支", bg=BG_MAIN).pack(anchor="w", pady=(0, 2))
        evo_f = tk.Frame(evo_col, bg=BG_MAIN)
        evo_f.pack(fill="x")
        self.evo_tree = ttk.Treeview(
            evo_f, columns=("into", "level"), show="headings",
            height=3, selectmode="browse")
        self.evo_tree.heading("into",  text="进化为")
        self.evo_tree.heading("level", text="等级")
        self.evo_tree.column("into",  width=120, anchor="w")
        self.evo_tree.column("level", width=50,  anchor="center")
        self.evo_tree.pack(side="left", fill="x", expand=True)
        evo_btn = tk.Frame(evo_f, bg=BG_MAIN)
        evo_btn.pack(side="left", padx=(4, 0))
        ttk.Button(evo_btn, text="+", width=3,
                   command=self._evo_add).pack(pady=(0, 2))
        ttk.Button(evo_btn, text="×", width=3,
                   command=self._evo_remove).pack()
        row += 1

        # 描述
        _sep(f, row=row, col=0); row += 1
        _lbl(f, "图鉴描述").grid(row=row, column=0, sticky="ne", padx=PAD, pady=3)
        self.mon_desc = tk.Text(
            f, width=28, height=4, wrap="word", bg=BG_CARD,
            font=(FONT_CJK, 9), relief="flat", borderwidth=1,
            highlightthickness=1, highlightcolor=ACCENT,
            highlightbackground=BORDER)
        self.mon_desc.grid(
            row=row, column=1, columnspan=4,
            sticky="ew", pady=3, padx=(0, 12))
        row += 1

        self._mon_refresh_list()
        self._refresh_stat_bars()

    # ── Mon tab helpers ─────────────────────────────────────────────────────

    def _suggest_tier_role(self):
        """根据当前种族值自动推荐品阶和定位"""
        v = {}
        for _, key in STAT_LABELS:
            try:    v[key] = int(self.mon_stat_entries[key].get())
            except: v[key] = 0
        hp     = v.get("hp",     0)
        atk    = v.get("atk",    0)
        def_   = v.get("def",    0)
        sp_atk = v.get("sp_atk", 0)
        sp_def = v.get("sp_def", 0)
        spd    = v.get("spd",    0)
        total  = hp + atk + def_ + sp_atk + sp_def + spd

        # 品阶（按BST阈值）
        if   total >= 650: tier = "天"
        elif total >= 600: tier = "神"
        elif total >= 535: tier = "地"
        elif total >= 450: tier = "玄"
        elif total >= 360: tier = "灵"
        else:              tier = "凡"

        # 定位（极差 > 20 为单攻手判定线）
        diff     = atk - sp_atk          # 正=偏物，负=偏特
        main_atk = max(atk, sp_atk)
        avg_off  = (atk + sp_atk) / 2
        avg_def  = (def_ + sp_def) / 2
        top_stat = max(hp, atk, def_, sp_atk, sp_def, spd)

        if spd == top_stat and main_atk >= 65:
            role = "快攻手"
        elif diff > 20:
            role = "物攻手"
        elif diff < -20:
            role = "特攻手"
        elif avg_def > avg_off + 15 and main_atk < 75:
            if   def_ >= sp_def + 20: role = "物盾"
            elif sp_def >= def_ + 20: role = "特盾"
            else:                      role = "全盾"
        elif main_atk >= 70 and abs(diff) <= 20:
            role = "混攻手"
        elif spd >= 80 and main_atk < 65:
            role = "辅助"
        else:
            role = "均衡"

        self.mon_tier.set(tier)
        self.mon_role.set(role)

    def _mon_show_form(self):
        self._mon_placeholder.pack_forget()
        self._mon_right.pack(side="right", fill="both", expand=True)

    def _mon_get_name(self, display):
        return display.split(" ", 1)[1] if " " in display else display

    def _mon_refresh_list(self):
        q = self.mon_search.get().lower()
        self.mon_list.delete(0, "end")
        items = [(d.get("id", 0) or 0, n)
                 for n, d in self.species.items()
                 if not q or q in n.lower() or q in str(d.get("id", 0))]
        for mid, n in sorted(items):
            self.mon_list.insert("end", f"{mid:03d} {n}")

    def _mon_select(self, _=None):
        sel = self.mon_list.curselection()
        if not sel: return
        self._mon_load(self._mon_get_name(self.mon_list.get(sel[0])))

    def _mon_load(self, name):
        self._mon_show_form()
        d = self.species[name]
        self._current_mon = name

        self.mon_id.delete(0, "end")
        self.mon_id.insert(0, str(d.get("id", 0) or 0))
        self.mon_name.delete(0, "end")
        self.mon_name.insert(0, name)
        self.mon_t1.set(d.get("type1", ""))
        self.mon_t2.set(d.get("type2", ""))
        self._refresh_badges()

        base = d.get("base", {})
        for k, e in self.mon_stat_entries.items():
            e.delete(0, "end"); e.insert(0, str(base.get(k, 0)))
        self._refresh_stat_bars()

        self.mon_catch.delete(0, "end")
        self.mon_catch.insert(0, str(d.get("catch_rate", 0)))
        self.mon_exp.delete(0, "end")
        self.mon_exp.insert(0, str(d.get("exp_yield", 0)))
        self.mon_growth.set(d.get("growth_rate", ""))
        self.mon_gender.set(d.get("gender_ratio", ""))

        # height / weight — backward-compat: parse old size_info if needed
        height = d.get("height", "")
        weight = d.get("weight", "")
        if not height and not weight:
            si = d.get("size_info", "")
            for part in si.split("/"):
                p = part.strip()
                if p.endswith("kg"):
                    weight = p[:-2].strip()
                elif p.endswith("m"):
                    height = p[:-1].strip()
        self.mon_height.delete(0, "end"); self.mon_height.insert(0, str(height))
        self.mon_weight.delete(0, "end"); self.mon_weight.insert(0, str(weight))

        # evolutions
        self.evo_tree.delete(*self.evo_tree.get_children())
        evolutions = d.get("evolutions", [])
        if not evolutions and d.get("evolves_into"):
            evolutions = [{"into": d["evolves_into"],
                           "level": d.get("evolve_level", 0)}]
        for ev in evolutions:
            self.evo_tree.insert("", "end", values=(ev["into"], ev["level"]))

        self.mon_desc.delete("1.0", "end")
        self.mon_desc.insert("1.0", d.get("desc", ""))
        self.mon_tier.set(d.get("tier", ""))
        self.mon_role.set(d.get("role", ""))

        # learnset
        self._learnset = []
        for lv_str, skills in d.get("learnset", {}).items():
            for s in skills:
                self._learnset.append({"level": int(lv_str), "name": s})
        self._learnset.sort(key=lambda x: (x["level"], x["name"]))
        self._refresh_ls_table()

        self._refresh_evo_compare(name, d)
        self._load_sprite(name)

    def _load_sprite(self, name):
        if not HAS_PIL:
            return
        self._photo_front = None
        self._photo_back  = None
        for suffix, lbl in [("front", self._sprite_front_lbl),
                             ("back",  self._sprite_back_lbl)]:
            path = os.path.join(SPRITES_DIR, f"{name}_{suffix}.png")
            if os.path.exists(path):
                try:
                    img   = Image.open(path).convert("RGBA")
                    img.thumbnail((110, 110), Image.LANCZOS)
                    photo = ImageTk.PhotoImage(img)
                    lbl.configure(image=photo, text="")
                    if suffix == "front":
                        self._photo_front = photo
                    else:
                        self._photo_back  = photo
                except Exception:
                    lbl.configure(image="", text="加载失败")
            else:
                lbl.configure(image="", text="无图片")

    def _refresh_badges(self):
        for w in self._badge_frame.winfo_children():
            w.destroy()
        for tp in [self.mon_t1.get(), self.mon_t2.get()]:
            if tp:
                _type_badge(self._badge_frame, tp, BG_CARD).pack(
                    side="left", padx=(0, 4))
        self._refresh_type_matchup()

    def _refresh_type_matchup(self):
        for w in self._matchup_inner.winfo_children():
            w.destroy()
        t1 = self.mon_t1.get()
        t2 = self.mon_t2.get()
        if not t1:
            _lbl(self._matchup_inner, "请先选择属性", bg=BG_CARD, fg=TEXT_SEC).pack(anchor="w")
            return

        # Defensive: for each attacking type, find multiplier against THIS species
        weak = []    # 2x or 4x
        resist = []  # 0.5x or 0.25x
        immune = []  # 0x
        for atk in ALL_TYPES:
            chart = TYPE_CHART.get(atk, {})
            mult = chart.get(t1, 1.0)
            if t2:
                mult *= chart.get(t2, 1.0)
            if mult == 0:
                immune.append((atk, "0"))
            elif mult > 1.0:
                weak.append((atk, f"{mult:g}x"))
            elif mult < 1.0:
                resist.append((atk, f"{mult:g}x"))

        # Offensive: for THIS species' types as attacker, find what they're strong against
        super_eff = []  # types this species is super effective against
        not_eff = []    # types this species is not very effective against
        no_dmg = []     # types this species deals 0 damage to
        for my_atk in [t1] + ([t2] if t2 else []):
            chart = TYPE_CHART.get(my_atk, {})
            for def_type, mult in chart.items():
                # Skip duplicates (dual-type species might list same def_type from both types)
                if mult == 1.0:
                    continue
                label = f"{mult:g}x"
                entry = (def_type, label)
                if mult == 0 and entry not in no_dmg:
                    no_dmg.append(entry)
                elif mult > 1.0 and entry not in super_eff:
                    super_eff.append(entry)
                elif mult < 1.0 and entry not in not_eff:
                    not_eff.append(entry)

        def _render_section(title, entries, bg_c, max_per_row=8):
            if not entries:
                return
            for chunk_i in range(0, len(entries), max_per_row):
                chunk = entries[chunk_i:chunk_i + max_per_row]
                row_f = tk.Frame(self._matchup_inner, bg=BG_CARD)
                row_f.pack(fill="x", pady=0)
                tk.Label(row_f,
                         text=f"{title}:" if chunk_i == 0 else "",
                         bg=BG_CARD, fg=TEXT_SEC,
                         font=(FONT_CJK, 8), width=4, anchor="e").pack(side="left")
                for typ, mult_s in chunk:
                    cell = tk.Frame(row_f, bg=bg_c, bd=1, relief="groove")
                    cell.pack(side="left", padx=1, pady=1)
                    fg, tbg = TYPE_COLORS.get(typ, ("#1C1C1E", "#AAAAAA"))
                    tk.Label(cell, text=typ, bg=tbg, fg=fg,
                             font=(FONT_CJK, 8, "bold"), width=2).pack(side="left")
                    tk.Label(cell, text=mult_s, bg=bg_c, fg=TEXT_PRI,
                             font=(FONT_CJK, 7)).pack(side="left", padx=1)

        _render_section("弱点", weak,      "#FFE0E0")
        _render_section("抵抗", resist,    "#E0FFE0")
        _render_section("抗性", immune,    "#E8E8F0")
        _render_section("克制", super_eff, "#D0F0D0")
        _render_section("被克", not_eff, "#FFF5D0")

    def _refresh_evo_compare(self, name, d):
        for w in self._evo_bar.winfo_children():
            w.destroy()

        # Trace ancestors up to root
        ancestor_chain = []
        cur, visited = name, {name}
        while True:
            pre = next(
                (n for n, s in self.species.items()
                 if cur in [e["into"] for e in s.get("evolutions", [])]
                 or s.get("evolves_into") == cur),
                None)
            if not pre or pre in visited:
                break
            visited.add(pre)
            pd   = self.species[pre]
            pe   = pd.get("evolutions", [])
            alv  = next((e["level"] for e in pe if e["into"] == cur),
                        pd.get("evolve_level", "?"))
            ancestor_chain.append((pre, alv))
            cur = pre
        ancestor_chain.reverse()

        branches = d.get("evolutions", [])
        if not branches and d.get("evolves_into"):
            branches = [{"into": d["evolves_into"],
                         "level": d.get("evolve_level", 0)}]
        branches = [b for b in branches if b["into"] in self.species]

        if not ancestor_chain and not branches:
            self._evo_bar.pack_forget()
            self._matchup_card.pack(side="left", fill="both", expand=True,
                                    padx=6, pady=(4, 4))
            return

        # Evo bar: only as wide as its content; matchup gets the rest
        self._matchup_card.pack(side="right", fill="both", expand=True,
                                padx=(0, 6), pady=(4, 4))
        self._evo_bar.pack(side="left", fill="y", padx=(6, 0), pady=(4, 4))
        col = 0

        # Ancestor chain — all on row 0
        for anc_name, alv in ancestor_chain:
            self._evo_card(self._evo_bar, anc_name,
                           self.species[anc_name], False, 0, col)
            col += 1
            tk.Label(self._evo_bar, text=f"→Lv{alv}",
                     bg=BG_MAIN, fg=TEXT_SEC,
                     font=(FONT_CJK, 8)).grid(row=0, column=col, padx=2)
            col += 1

        # Current species — row 0
        self._evo_card(self._evo_bar, name, d, True, 0, col)
        col += 1

        # Branches — all on row 0, separated by ┃
        for br_idx, br in enumerate(branches):
            if br_idx > 0:
                tk.Label(self._evo_bar, text="┃",
                         bg=BG_MAIN, fg=TEXT_SEC,
                         font=(FONT_CJK, 33)).grid(row=0, column=col, padx=4)
                col += 1
            tk.Label(self._evo_bar, text=f"→Lv{br['level']}",
                     bg=BG_MAIN, fg=TEXT_SEC,
                     font=(FONT_CJK, 8)).grid(row=0, column=col,
                                              padx=2, sticky="w")
            col += 1
            br_name = br["into"]
            self._evo_card(self._evo_bar, br_name,
                           self.species[br_name], False, 0, col)
            col += 1

            seen_fwd = visited | {br_name}
            cur_fwd  = br_name
            while True:
                cd = self.species.get(cur_fwd, {})
                fe = cd.get("evolutions", [])
                if not fe and cd.get("evolves_into"):
                    fe = [{"into": cd["evolves_into"],
                           "level": cd.get("evolve_level", 0)}]
                fe = [e for e in fe
                      if e["into"] in self.species
                      and e["into"] not in seen_fwd]
                if len(fe) != 1:
                    break
                nxt = fe[0]
                tk.Label(self._evo_bar, text=f"→Lv{nxt['level']}",
                         bg=BG_MAIN, fg=TEXT_SEC,
                         font=(FONT_CJK, 8)).grid(
                    row=0, column=col, padx=2, sticky="w")
                col += 1
                self._evo_card(self._evo_bar, nxt["into"],
                               self.species[nxt["into"]], False, 0, col)
                col += 1
                seen_fwd.add(nxt["into"])
                cur_fwd = nxt["into"]

    def _evo_card(self, parent, mname, mdata, is_cur, row, col, rowspan=1):
        bg = BG_CARD if is_cur else BG_MAIN
        cf = tk.Frame(parent, bg=bg, bd=1,
                      relief="solid" if is_cur else "flat")
        cf.grid(row=row, column=col, padx=6, pady=4, sticky="n",
                rowspan=rowspan)

        tk.Label(cf, text=mname, bg=bg,
                 fg=ACCENT if is_cur else TEXT_PRI,
                 font=(FONT_CJK, 9, "bold")).pack()

        t1 = mdata.get("type1", ""); t2 = mdata.get("type2", "")
        tk.Label(cf, text=f"{t1}{'/' + t2 if t2 else ''}",
                 bg=bg, fg=TEXT_SEC, font=(FONT_CJK, 7)).pack()

        base  = mdata.get("base", {})
        total = 0
        for slbl, key in STAT_LABELS:
            v      = base.get(key, 0)
            total += v
            rf = tk.Frame(cf, bg=bg); rf.pack(fill="x")
            tk.Label(rf, text=slbl[:2], width=2, anchor="e",
                     bg=bg, fg=TEXT_SEC, font=(FONT_CJK, 7)).pack(side="left")
            tk.Label(rf, text=f"{v:3d}", width=3, bg=bg,
                     fg=TEXT_PRI, font=(FONT_CJK, 7)).pack(side="left", padx=2)
            c = tk.Canvas(rf, width=55, height=6, bg=bg, highlightthickness=0)
            c.pack(side="left")
            w_bar = max(1, int(min(v, BAR_MAX) / BAR_MAX * 55))
            c.create_rectangle(0, 0, 55, 6, fill="#E5E5EA", outline="")
            c.create_rectangle(0, 0, w_bar, 6, fill=STAT_COLORS[key], outline="")
        tk.Label(cf, text=f"BST {total}", bg=bg,
                 fg=ACCENT if is_cur else TEXT_SEC,
                 font=(FONT_CJK, 8, "bold")).pack(pady=(2, 2))

    def _refresh_stat_bars(self):
        total = 0
        for label, key in STAT_LABELS:
            v      = _int(self.mon_stat_entries[key].get())
            total += v
            self._draw_bar(self.mon_stat_bars[key], v, STAT_COLORS[key])
            is_hp = key == "hp"
            lv50  = (3 * v * 50  // 100) + (60  if is_hp else 5)
            lv100 = (3 * v)               + (110 if is_hp else 5)
            self.mon_stat_lv50[key].config(text=str(lv50))
            self.mon_stat_lv100[key].config(text=str(lv100))
        self.mon_total_label.config(text=str(total))
        # Color-code BST tier: 天/神/地/玄/灵/凡
        if   total >= 650: col = "#D42020"   # 红   — 天（顶级神兽 650+）
        elif total >= 600: col = "#C85A00"   # 橙红  — 神（幻兽/弱神兽 600-649）
        elif total >= 535: col = "#B8860B"   # 金   — 地（伪神/准神 535-599）
        elif total >= 450: col = "#7B2FBE"   # 紫   — 玄（强力进化型 450-534）
        elif total >= 360: col = "#1A56CC"   # 蓝   — 灵（普通进化型 360-449）
        else:              col = TEXT_SEC    # 灰   — 凡（基础形态 <360）
        self.mon_total_label.config(fg=col)

    def _refresh_ls_table(self):
        self.ls_tree.delete(*self.ls_tree.get_children())
        for item in self._learnset:
            m = self.moves.get(item["name"], {})
            self.ls_tree.insert("", "end", values=(
                item["level"], item["name"],
                m.get("type", "?"), m.get("category", "?"),
                m.get("power", "-"), m.get("accuracy", "-"),
                m.get("max_pp", "-"),
            ))

    def _evo_add(self):
        dlg = tk.Toplevel(self.root)
        dlg.title("添加进化分支")
        dlg.resizable(False, False)
        dlg.transient(self.root); dlg.grab_set()
        dw, dh = 340, 130
        dlg.update_idletasks()
        x = self.root.winfo_x() + (self.root.winfo_width() - dw) // 2
        y = self.root.winfo_y() + (self.root.winfo_height() - dh) // 2
        dlg.geometry(f"{dw}x{dh}+{x}+{y}")

        tk.Label(dlg, text="进化为:").grid(
            row=0, column=0, padx=12, pady=12, sticky="e")
        mon_names = sorted(n for n in self.species if n != self._current_mon)
        cb = SearchableCombo(dlg, mon_names, width=20)
        cb.grid(row=0, column=1, sticky="w", pady=12, padx=(0, 12))
        if mon_names: cb.set(mon_names[0])

        tk.Label(dlg, text="等级:").grid(
            row=1, column=0, padx=12, pady=6, sticky="e")
        lv_var = tk.StringVar(value="20")
        ttk.Spinbox(dlg, from_=1, to=100, width=7,
                    textvariable=lv_var).grid(row=1, column=1, sticky="w")

        def ok():
            tgt = cb.get(); lv = lv_var.get()
            if tgt and lv.isdigit():
                self.evo_tree.insert("", "end", values=(tgt, int(lv)))
                dlg.destroy()
            else:
                messagebox.showwarning("", "请选择目标精灵和等级", parent=dlg)

        bf = ttk.Frame(dlg)
        bf.grid(row=2, column=0, columnspan=2, pady=10)
        ttk.Button(bf, text="确定", command=ok).pack(side="left", padx=6)
        ttk.Button(bf, text="取消", command=dlg.destroy).pack(side="left", padx=6)

    def _evo_remove(self):
        sel = self.evo_tree.selection()
        if sel: self.evo_tree.delete(sel[0])

    def _ls_add(self):
        dlg = tk.Toplevel(self.root)
        dlg.title("添加技能")
        dlg.geometry("360x130")
        dlg.resizable(False, False)
        dlg.transient(self.root); dlg.grab_set()

        tk.Label(dlg, text="等级:").grid(
            row=0, column=0, padx=12, pady=12, sticky="e")
        lv_var = tk.StringVar(value="1")
        ttk.Spinbox(dlg, from_=0, to=100, width=7,
                    textvariable=lv_var).grid(row=0, column=1, sticky="w", pady=12)

        tk.Label(dlg, text="技能:").grid(
            row=1, column=0, padx=12, pady=6, sticky="e")
        names = sorted(self.moves.keys())
        cb = SearchableCombo(dlg, names, width=22)
        cb.grid(row=1, column=1, sticky="w", padx=(0, 12))
        if names: cb.set(names[0])

        def ok():
            lv = lv_var.get().strip(); mv = cb.get()
            if lv.isdigit() and mv:
                self._learnset.append({"level": int(lv), "name": mv})
                self._learnset.sort(key=lambda x: (x["level"], x["name"]))
                self._refresh_ls_table()
                dlg.destroy()
            else:
                messagebox.showwarning("", "请选择等级和技能", parent=dlg)

        bf = ttk.Frame(dlg)
        bf.grid(row=2, column=0, columnspan=2, pady=10)
        ttk.Button(bf, text="确定", command=ok).pack(side="left", padx=6)
        ttk.Button(bf, text="取消", command=dlg.destroy).pack(side="left", padx=6)

    def _ls_remove(self):
        sel = self.ls_tree.selection()
        if not sel: return
        vals  = self.ls_tree.item(sel[0], "values")
        level, name = int(vals[0]), vals[1]
        self._learnset = [
            x for x in self._learnset
            if not (x["level"] == level and x["name"] == name)]
        self._refresh_ls_table()

    def _ls_edit_level(self):
        """修改选中技能的习得等级。"""
        sel = self.ls_tree.selection()
        if not sel: return
        vals  = self.ls_tree.item(sel[0], "values")
        level, name = int(vals[0]), vals[1]

        dlg = tk.Toplevel(self.root)
        dlg.title("编辑等级")
        dlg.geometry("260x100")
        dlg.resizable(False, False)
        dlg.transient(self.root); dlg.grab_set()

        tk.Label(dlg, text=f"技能：{name}  新等级:").grid(
            row=0, column=0, padx=12, pady=14, sticky="e")
        lv_var = tk.StringVar(value=str(level))
        ttk.Spinbox(dlg, from_=0, to=100, width=7,
                    textvariable=lv_var).grid(row=0, column=1, sticky="w", pady=14)

        def ok():
            new_lv = lv_var.get().strip()
            if new_lv.isdigit():
                for entry in self._learnset:
                    if entry["level"] == level and entry["name"] == name:
                        entry["level"] = int(new_lv); break
                self._learnset.sort(key=lambda x: (x["level"], x["name"]))
                self._refresh_ls_table(); dlg.destroy()

        bf = ttk.Frame(dlg)
        bf.grid(row=1, column=0, columnspan=2, pady=6)
        ttk.Button(bf, text="确定", command=ok).pack(side="left", padx=6)
        ttk.Button(bf, text="取消", command=dlg.destroy).pack(side="left", padx=6)

    def _mon_save(self):
        old = self._current_mon
        new = self.mon_name.get().strip()
        if not new:
            messagebox.showerror("错误", "名称不能为空"); return

        d = {
            "id":          _int(self.mon_id.get()),
            "name":        new,
            "type1":       self.mon_t1.get(),
            "type2":       self.mon_t2.get(),
            "base":        {k: _int(self.mon_stat_entries[k].get())
                            for _, k in STAT_LABELS},
            "catch_rate":  _int(self.mon_catch.get()),
            "exp_yield":   _int(self.mon_exp.get()),
            "growth_rate": self.mon_growth.get(),
            "desc":        self.mon_desc.get("1.0", "end-1c").strip(),
            "tier":        self.mon_tier.get(),
            "role":        self.mon_role.get(),
            "gender_ratio": self.mon_gender.get(),
            "height":      self.mon_height.get().strip(),
            "weight":      self.mon_weight.get().strip(),
        }

        evolutions = [
            {"into":  self.evo_tree.item(iid, "values")[0],
             "level": _int(self.evo_tree.item(iid, "values")[1])}
            for iid in self.evo_tree.get_children()
        ]
        if evolutions:
            d["evolutions"] = evolutions
            if len(evolutions) == 1:
                d["evolves_into"] = evolutions[0]["into"]
                d["evolve_level"] = evolutions[0]["level"]

        ls = {}
        for item in self._learnset:
            ls.setdefault(str(item["level"]), []).append(item["name"])
        d["learnset"] = ls

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
        # Restore selection to the saved mon
        for i in range(self.mon_list.size()):
            if self._mon_get_name(self.mon_list.get(i)) == new:
                self.mon_list.selection_clear(0, "end")
                self.mon_list.selection_set(i)
                self.mon_list.see(i)
                break
        self._update_status()
        messagebox.showinfo("", "已保存 ✓")

    def _mon_add(self):
        name = "新精灵"
        i = 1
        while name in self.species:
            i += 1; name = f"新精灵{i}"
        max_id = max((d.get("id", 0) or 0)
                     for d in self.species.values()) + 1
        self.species[name] = {
            "id": max_id, "name": name, "type1": "", "type2": "",
            "base": {"hp": 50, "atk": 50, "def": 50,
                     "sp_atk": 50, "sp_def": 50, "spd": 50},
            "catch_rate": 45, "exp_yield": 64, "growth_rate": "中速",
            "desc": "", "gender_ratio": "50/50",
            "height": "0.5", "weight": "5.0", "learnset": {},
        }
        self._mon_refresh_list()
        for i in range(self.mon_list.size()):
            if self._mon_get_name(self.mon_list.get(i)) == name:
                self.mon_list.selection_clear(0, "end")
                self.mon_list.selection_set(i)
                self.mon_list.see(i)
                self._mon_load(name)
                break

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

    # ══════════════════════════════════════════════════════════════════════════
    #  技能库 TAB
    # ══════════════════════════════════════════════════════════════════════════

    def _build_move_tab(self):
        left = tk.Frame(self.move_tab, bg=BG_SIDE, width=230)
        left.pack(side="left", fill="y")
        left.pack_propagate(False)

        _lbl(left, "技能列表", bg=BG_SIDE, bold=True).pack(
            anchor="w", padx=12, pady=(12, 2))
        self.move_search = ttk.Entry(left)
        self.move_search.pack(fill="x", padx=10)
        self.move_search.bind("<KeyRelease>",
                              lambda _: self._move_refresh_list())

        lf = tk.Frame(left, bg=BG_SIDE)
        lf.pack(fill="both", expand=True, padx=10, pady=(6, 4))
        sb = ttk.Scrollbar(lf, orient="vertical")
        self.move_list = tk.Listbox(
            lf, yscrollcommand=sb.set, font=(FONT_CJK, 10),
            bg=BG_CARD, fg=TEXT_PRI,
            selectbackground=ACCENT, selectforeground="white",
            borderwidth=0, highlightthickness=0, relief="flat",
            activestyle="none")
        sb.config(command=self.move_list.yview)
        sb.pack(side="right", fill="y")
        self.move_list.pack(side="left", fill="both", expand=True)
        self.move_list.bind("<<ListboxSelect>>", self._move_select)

        bf = tk.Frame(left, bg=BG_SIDE)
        bf.pack(fill="x", padx=10, pady=(0, 12))
        ttk.Button(bf, text="+ 新增",
                   command=self._move_add).pack(side="left", padx=(0, 4))
        ttk.Button(bf, text="× 删除",
                   command=self._move_delete).pack(side="left")

        self._move_placeholder = tk.Label(
            self.move_tab, text="← 选择一个技能开始编辑",
            bg=BG_MAIN, fg=TEXT_SEC, font=(FONT_CJK, 12))
        self._move_placeholder.pack(side="right", fill="both", expand=True)

        self._move_scroll = tk.Frame(self.move_tab, bg=BG_MAIN)
        ms_cv = tk.Canvas(self._move_scroll, bg=BG_MAIN,
                           borderwidth=0, highlightthickness=0)
        ms_sb = ttk.Scrollbar(self._move_scroll, orient="vertical",
                               command=ms_cv.yview)
        self._move_inner = tk.Frame(ms_cv, bg=BG_MAIN)
        self._move_inner.bind(
            "<Configure>",
            lambda _: ms_cv.configure(scrollregion=ms_cv.bbox("all")))
        ms_cv.create_window((0, 0), window=self._move_inner, anchor="nw")
        ms_cv.configure(yscrollcommand=ms_sb.set)
        ms_cv.pack(side="left", fill="both", expand=True)
        ms_sb.pack(side="right", fill="y")

        f   = self._move_inner
        row = 0
        PAD = (10, 4)

        hf = tk.Frame(f, bg=BG_MAIN)
        hf.grid(row=row, column=0, columnspan=4, sticky="ew",
                padx=12, pady=(14, 4))
        _lbl(hf, "名称", bg=BG_MAIN).pack(side="left")
        self.move_name = ttk.Entry(hf, width=18)
        self.move_name.pack(side="left", padx=(4, 16))
        ttk.Button(hf, text="💾 保存",
                   command=self._move_save).pack(side="left")
        row += 1

        _sep(f, row=row, col=0); row += 1
        _lbl(f, "类型").grid(row=row, column=0, sticky="e", padx=PAD, pady=3)
        self.move_type = ttk.Combobox(f, values=TYPES, width=8, state="readonly")
        self.move_type.grid(row=row, column=1, sticky="w", pady=3)
        _lbl(f, "分类").grid(row=row, column=2, padx=(16, 4))
        self.move_cat = ttk.Combobox(f, values=CATEGORIES, width=8, state="readonly")
        self.move_cat.grid(row=row, column=3, sticky="w", pady=3)
        row += 1

        _sep(f, row=row, col=0); row += 1
        for lbl_txt, attr in [("威力", "move_power"),
                               ("命中", "move_acc"),
                               ("PP",   "move_pp")]:
            _lbl(f, lbl_txt).grid(row=row, column=0, sticky="e",
                                   padx=PAD, pady=3)
            e = ttk.Entry(f, width=7, justify="center")
            e.grid(row=row, column=1, sticky="w", pady=3)
            setattr(self, attr, e)
            row += 1

        _sep(f, row=row, col=0); row += 1
        _lbl(f, "效果").grid(row=row, column=0, sticky="e", padx=PAD, pady=3)
        self.move_effect = ttk.Combobox(
            f, values=EFFECTS, width=24, state="readonly")
        self.move_effect.grid(row=row, column=1, columnspan=3,
                              sticky="w", pady=3)
        row += 1

        _sep(f, row=row, col=0); row += 1
        _lbl(f, "描述").grid(row=row, column=0, sticky="ne", padx=PAD, pady=3)
        self.move_desc = tk.Text(
            f, width=36, height=4, wrap="word", bg=BG_CARD,
            font=(FONT_CJK, 9), relief="flat", borderwidth=1,
            highlightthickness=1, highlightcolor=ACCENT,
            highlightbackground=BORDER)
        self.move_desc.grid(row=row, column=1, columnspan=3,
                            sticky="ew", pady=3, padx=(0, 12))
        row += 1

        self._move_refresh_list()

    def _move_show_form(self):
        self._move_placeholder.pack_forget()
        self._move_scroll.pack(side="right", fill="both", expand=True,
                               padx=6, pady=6)

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
        self.move_power.delete(0, "end")
        self.move_power.insert(0, str(d.get("power", 0)))
        self.move_acc.delete(0, "end")
        self.move_acc.insert(0, str(d.get("accuracy", 0)))
        self.move_pp.delete(0, "end")
        self.move_pp.insert(0, str(d.get("max_pp", 0)))
        self.move_effect.set(EFFECT_LABELS.get(d.get("effect", ""), d.get("effect", "")))
        self.move_desc.delete("1.0", "end")
        self.move_desc.insert("1.0", d.get("description", ""))

    def _move_save(self):
        old = self._current_move
        new = self.move_name.get().strip()
        if not new:
            messagebox.showerror("错误", "名称不能为空"); return

        d = {
            "name":        new,
            "type":        self.move_type.get(),
            "category":    self.move_cat.get(),
            "power":       _int(self.move_power.get()),
            "accuracy":    _int(self.move_acc.get()),
            "max_pp":      _int(self.move_pp.get()),
            "effect":      EFFECT_TO_RAW.get(self.move_effect.get(), self.move_effect.get()),
            "description": self.move_desc.get("1.0", "end-1c").strip(),
        }

        if old and old != new:
            del self.moves[old]
            for mon in self.species.values():
                for lv in mon.get("learnset", {}):
                    mon["learnset"][lv] = [
                        new if s == old else s
                        for s in mon["learnset"][lv]]
            save_json(SPECIES_FILE, self.species)

        self.moves[new] = d
        save_json(MOVES_FILE, self.moves)
        self._current_move = new
        self._move_refresh_list()
        self._update_status()
        messagebox.showinfo("", "已保存 ✓")

    def _move_add(self):
        name = "新技能"; i = 1
        while name in self.moves:
            i += 1; name = f"新技能{i}"
        self.moves[name] = {
            "name": name, "type": "火", "category": "物理",
            "power": 40, "accuracy": 100, "max_pp": 20,
            "effect": "", "description": "",
        }
        self._move_refresh_list()
        for i in range(self.move_list.size()):
            if self.move_list.get(i) == name:
                self.move_list.selection_clear(0, "end")
                self.move_list.selection_set(i)
                self.move_list.see(i)
                self._move_load(name)
                break

    def _move_delete(self):
        if not self._current_move: return
        if not messagebox.askyesno("确认",
                                   f"删除「{self._current_move}」?"): return
        del self.moves[self._current_move]
        save_json(MOVES_FILE, self.moves)
        self._current_move = None
        self._move_refresh_list()
        self._update_status()
        self._move_scroll.pack_forget()
        self._move_placeholder.pack(side="right", fill="both", expand=True)

    # ══════════════════════════════════════════════════════════════════════════
    #  角色编辑 TAB
    # ══════════════════════════════════════════════════════════════════════════

    def _build_trainer_tab(self):
        left = tk.Frame(self.trainer_tab, bg=BG_SIDE, width=230)
        left.pack(side="left", fill="y")
        left.pack_propagate(False)

        _lbl(left, "角色列表", bg=BG_SIDE, bold=True).pack(
            anchor="w", padx=12, pady=(12, 2))
        self.trainer_search = ttk.Entry(left)
        self.trainer_search.pack(fill="x", padx=10)
        self.trainer_search.bind("<KeyRelease>",
                                 lambda _: self._trainer_refresh_list())

        lf = tk.Frame(left, bg=BG_SIDE)
        lf.pack(fill="both", expand=True, padx=10, pady=(6, 4))
        sb = ttk.Scrollbar(lf, orient="vertical")
        self.trainer_list = tk.Listbox(
            lf, yscrollcommand=sb.set, font=(FONT_CJK, 10),
            bg=BG_CARD, fg=TEXT_PRI,
            selectbackground=ACCENT, selectforeground="white",
            borderwidth=0, highlightthickness=0, relief="flat",
            activestyle="none")
        sb.config(command=self.trainer_list.yview)
        sb.pack(side="right", fill="y")
        self.trainer_list.pack(side="left", fill="both", expand=True)
        self.trainer_list.bind("<<ListboxSelect>>", self._trainer_select)

        bf = tk.Frame(left, bg=BG_SIDE)
        bf.pack(fill="x", padx=10, pady=(0, 12))
        ttk.Button(bf, text="+ 新增",
                   command=self._trainer_add).pack(side="left", padx=(0, 4))
        ttk.Button(bf, text="× 删除",
                   command=self._trainer_delete).pack(side="left")

        self._trainer_placeholder = tk.Label(
            self.trainer_tab, text="← 选择一个角色开始编辑",
            bg=BG_MAIN, fg=TEXT_SEC, font=(FONT_CJK, 12))
        self._trainer_placeholder.pack(side="right", fill="both", expand=True)

        self._trainer_form_frame = tk.Frame(self.trainer_tab, bg=BG_MAIN)
        tc = tk.Canvas(self._trainer_form_frame, bg=BG_MAIN,
                        borderwidth=0, highlightthickness=0)
        ts = ttk.Scrollbar(self._trainer_form_frame, orient="vertical",
                            command=tc.yview)
        self._trainer_inner = tk.Frame(tc, bg=BG_MAIN)
        self._trainer_inner.bind(
            "<Configure>",
            lambda _: tc.configure(scrollregion=tc.bbox("all")))
        tc.create_window((0, 0), window=self._trainer_inner, anchor="nw")
        tc.configure(yscrollcommand=ts.set)
        tc.pack(side="left", fill="both", expand=True)
        ts.pack(side="right", fill="y")
        tc.bind("<Enter>", lambda c=tc: c.bind_all(
            "<MouseWheel>",
            lambda e: c.yview_scroll(-1*(e.delta//120), "units")))
        tc.bind("<Leave>", lambda c=tc: c.unbind_all("<MouseWheel>"))

        f   = self._trainer_inner
        row = 0
        PAD = (10, 4)

        hf = tk.Frame(f, bg=BG_MAIN)
        hf.grid(row=row, column=0, columnspan=3, sticky="ew",
                padx=12, pady=(14, 4))
        _lbl(hf, "ID", bg=BG_MAIN).pack(side="left")
        self.trainer_id_entry = ttk.Entry(hf, width=20)
        self.trainer_id_entry.pack(side="left", padx=(4, 16))
        ttk.Button(hf, text="💾 保存",
                   command=self._trainer_save).pack(side="left")
        row += 1

        _sep(f, row=row, col=0, cols=3); row += 1
        for lbl_txt, attr in [("名字",    "trainer_name_entry"),
                               ("击败赏金", "trainer_reward"),
                               ("挑战台词", "trainer_dialog_before"),
                               ("败北台词", "trainer_dialog_win")]:
            _lbl(f, lbl_txt).grid(row=row, column=0, sticky="e",
                                   padx=PAD, pady=3)
            e = ttk.Entry(f, width=32)
            e.grid(row=row, column=1, columnspan=2, sticky="ew",
                   pady=3, padx=(0, 12))
            setattr(self, attr, e)
            row += 1

        _lbl(f, "性别").grid(row=row, column=0, sticky="e", padx=PAD, pady=3)
        self.trainer_gender = ttk.Combobox(
            f, values=TRAINER_GENDERS, width=8, state="readonly")
        self.trainer_gender.grid(row=row, column=1, sticky="w", pady=3)
        row += 1

        _lbl(f, "身份").grid(row=row, column=0, sticky="e", padx=PAD, pady=3)
        self.trainer_class = ttk.Combobox(
            f, values=TRAINER_CLASSES, width=16, state="readonly")
        self.trainer_class.grid(row=row, column=1, sticky="w", pady=3)
        row += 1

        _sep(f, row=row, col=0, cols=3); row += 1
        _lbl(f, "队伍精灵", bold=True, size=9).grid(
            row=row, column=0, columnspan=3, sticky="w", padx=12, pady=(0, 4))
        row += 1

        self.team_tree = ttk.Treeview(
            f, columns=("species", "level"), show="headings",
            height=6, selectmode="browse")
        self.team_tree.heading("species", text="精灵")
        self.team_tree.heading("level",   text="等级")
        self.team_tree.column("species", width=180, anchor="w")
        self.team_tree.column("level",   width=60,  anchor="center")
        t_sb = ttk.Scrollbar(f, orient="vertical", command=self.team_tree.yview)
        self.team_tree.configure(yscrollcommand=t_sb.set)
        self.team_tree.grid(row=row, column=0, columnspan=2,
                            sticky="ew", padx=12, pady=3)
        t_sb.grid(row=row, column=2, sticky="ns", padx=(0, 12))
        row += 1

        tb = tk.Frame(f, bg=BG_MAIN)
        tb.grid(row=row, column=0, columnspan=3, sticky="w", padx=12, pady=4)
        ttk.Button(tb, text="+ 添加精灵",
                   command=self._team_add).pack(side="left", padx=(0, 6))
        ttk.Button(tb, text="× 移除",
                   command=self._team_remove).pack(side="left")
        row += 1

        self._trainer_refresh_list()

    def _trainer_show_form(self):
        self._trainer_placeholder.pack_forget()
        self._trainer_form_frame.pack(
            side="right", fill="both", expand=True)

    def _trainer_refresh_list(self):
        q = self.trainer_search.get().lower()
        self.trainer_list.delete(0, "end")
        for tid, td in sorted(self.trainers.items(),
                               key=lambda x: x[1].get("name", x[0])):
            name = td.get("name", tid)
            if not q or q in name.lower() or q in tid.lower():
                self.trainer_list.insert("end", f"{name}  [{tid}]")

    def _trainer_get_id(self, display):
        if "[" in display and display.endswith("]"):
            return display.rsplit("[", 1)[1][:-1]
        return display

    def _trainer_select(self, _=None):
        sel = self.trainer_list.curselection()
        if not sel: return
        self._trainer_load(self._trainer_get_id(
            self.trainer_list.get(sel[0])))

    def _trainer_load(self, tid):
        self._trainer_show_form()
        d = self.trainers[tid]
        self._current_trainer = tid

        self.trainer_id_entry.delete(0, "end")
        self.trainer_id_entry.insert(0, tid)
        self.trainer_name_entry.delete(0, "end")
        self.trainer_name_entry.insert(0, d.get("name", ""))
        self.trainer_gender.set(d.get("gender", "男"))
        self.trainer_class.set(d.get("class", "普通训练师"))
        self.trainer_reward.delete(0, "end")
        self.trainer_reward.insert(0, str(d.get("reward", 0)))
        self.trainer_dialog_before.delete(0, "end")
        self.trainer_dialog_before.insert(0, d.get("dialog_before", ""))
        self.trainer_dialog_win.delete(0, "end")
        self.trainer_dialog_win.insert(0, d.get("dialog_win", ""))

        self.team_tree.delete(*self.team_tree.get_children())
        for mem in d.get("team", []):
            self.team_tree.insert("", "end", values=(
                mem.get("species", ""), mem.get("level", 1)))

    def _trainer_save(self):
        old_id = self._current_trainer
        new_id = self.trainer_id_entry.get().strip()
        name   = self.trainer_name_entry.get().strip()
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
            "id":            new_id,
            "name":          name,
            "gender":        self.trainer_gender.get(),
            "class":         self.trainer_class.get(),
            "reward":        _int(self.trainer_reward.get()),
            "dialog_before": self.trainer_dialog_before.get().strip(),
            "dialog_win":    self.trainer_dialog_win.get().strip(),
            "team":          team,
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
        tid = "new_trainer"; i = 1
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
                self._trainer_load(tid)
                break

    def _trainer_delete(self):
        if not self._current_trainer: return
        td  = self.trainers[self._current_trainer]
        if not messagebox.askyesno(
                "确认", f"删除「{td.get('name', self._current_trainer)}」?"): return
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
        dlg.geometry("360x130")
        dlg.resizable(False, False)
        dlg.transient(self.root); dlg.grab_set()

        tk.Label(dlg, text="精灵:").grid(
            row=0, column=0, padx=12, pady=12, sticky="e")
        mon_names = sorted(self.species.keys())
        cb = SearchableCombo(dlg, mon_names, width=22)
        cb.grid(row=0, column=1, sticky="w", pady=12, padx=(0, 12))
        if mon_names: cb.set(mon_names[0])

        tk.Label(dlg, text="等级:").grid(
            row=1, column=0, padx=12, pady=6, sticky="e")
        lv_var = tk.StringVar(value="10")
        ttk.Spinbox(dlg, from_=1, to=100, width=7,
                    textvariable=lv_var).grid(row=1, column=1, sticky="w")

        def ok():
            sp = cb.get(); lv = lv_var.get()
            if sp and lv.isdigit():
                self.team_tree.insert("", "end", values=(sp, int(lv)))
                dlg.destroy()
            else:
                messagebox.showwarning("", "请选择精灵和等级", parent=dlg)

        bf = ttk.Frame(dlg)
        bf.grid(row=2, column=0, columnspan=2, pady=10)
        ttk.Button(bf, text="确定", command=ok).pack(side="left", padx=6)
        ttk.Button(bf, text="取消", command=dlg.destroy).pack(side="left", padx=6)

    def _team_remove(self):
        sel = self.team_tree.selection()
        if sel: self.team_tree.delete(sel[0])

    # ── 剧情文本 Tab ────────────────────────────────────────────────────────────
    def _build_dialog_tab(self):
        self._dlg_data = load_json(DIALOGS_FILE) if os.path.exists(DIALOGS_FILE) else {}

        left = tk.Frame(self.dialog_tab, bg=BG_SIDE, width=230)
        left.pack(side="left", fill="y")
        left.pack_propagate(False)

        tk.Label(left, text="场景分组", bg=BG_SIDE, fg=TEXT_PRI,
                 font=(FONT_CJK, 11, "bold"), anchor="w").pack(fill="x", padx=14, pady=(10, 4))

        self._dlg_tree = ttk.Treeview(left, show="tree", selectmode="browse")
        self._dlg_tree.pack(fill="both", expand=True, padx=8, pady=4)
        self._dlg_tree.bind("<<TreeviewSelect>>", self._on_dlg_section_select)

        btn_frame = tk.Frame(left, bg=BG_SIDE)
        btn_frame.pack(fill="x", padx=8, pady=6)
        tk.Button(btn_frame, text="+ 新增分组", font=(FONT_CJK, 9),
                  command=self._dlg_add_section).pack(side="left", padx=2)
        tk.Button(btn_frame, text="- 删除分组", font=(FONT_CJK, 9),
                  command=self._dlg_del_section).pack(side="left", padx=2)

        self._dlg_placeholder = tk.Label(
            self.dialog_tab, text="← 选择一个场景分组开始编辑",
            bg=BG_MAIN, fg=TEXT_SEC, font=(FONT_CJK, 13))
        self._dlg_placeholder.pack(fill="both", expand=True)

        self._dlg_right = tk.Frame(self.dialog_tab, bg=BG_MAIN)
        self._dlg_current_section = None
        self._dlg_editors = {}

        self._refresh_dlg_tree()

    def _refresh_dlg_tree(self):
        self._dlg_tree.delete(*self._dlg_tree.get_children())
        section_labels = {
            "char_create": "角色创建",
            "starter": "御三家选择",
            "world": "大地图",
            "trainers": "训练师对话",
        }
        for sec_id in self._dlg_data:
            label = section_labels.get(sec_id, sec_id)
            self._dlg_tree.insert("", "end", iid=sec_id, text=f"  {label}")

    def _on_dlg_section_select(self, _event=None):
        sel = self._dlg_tree.selection()
        if not sel:
            return
        sec_id = sel[0]
        if sec_id == self._dlg_current_section:
            return
        self._dlg_current_section = sec_id
        self._dlg_placeholder.pack_forget()
        self._dlg_right.pack_forget()
        self._dlg_right.destroy()
        self._dlg_right = tk.Frame(self.dialog_tab, bg=BG_MAIN)
        self._dlg_right.pack(side="left", fill="both", expand=True)
        self._dlg_build_section(sec_id)

    def _dlg_build_section(self, sec_id):
        data = self._dlg_data.get(sec_id, {})
        canvas = tk.Canvas(self._dlg_right, bg=BG_MAIN, highlightthickness=0)
        scrollbar = ttk.Scrollbar(self._dlg_right, orient="vertical", command=canvas.yview)
        scroll_frame = tk.Frame(canvas, bg=BG_MAIN)
        scroll_frame.bind("<Configure>", lambda e: canvas.configure(scrollregion=canvas.bbox("all")))
        canvas.create_window((0, 0), window=scroll_frame, anchor="nw")
        canvas.configure(yscrollcommand=scrollbar.set)
        scrollbar.pack(side="right", fill="y")
        canvas.pack(side="left", fill="both", expand=True)
        canvas.bind_all("<MouseWheel>", lambda e: canvas.yview_scroll(int(-e.delta / 120), "units"))

        # Title
        tk.Label(scroll_frame, text=f"编辑: {sec_id}", bg=BG_MAIN, fg=TEXT_PRI,
                 font=(FONT_CJK, 14, "bold")).pack(anchor="w", padx=16, pady=(12, 6))

        self._dlg_editors = {}
        row = 0
        for key, val in data.items():
            row += 1
            frame = tk.Frame(scroll_frame, bg=BG_CARD, bd=1, relief="solid")
            frame.pack(fill="x", padx=14, pady=4)

            tk.Label(frame, text=key, bg=BG_CARD, fg=ACCENT,
                     font=(FONT_CJK, 10, "bold"), anchor="w").pack(fill="x", padx=8, pady=(6, 2))

            if isinstance(val, list):
                # Array of strings — one Text per element, with add/remove buttons
                list_frame = tk.Frame(frame, bg=BG_CARD)
                list_frame.pack(fill="x", padx=8, pady=(0, 6))
                self._dlg_editors[key] = ("list", list_frame, sec_id, key)
                self._dlg_build_list_entries(list_frame, val)
                btn_f = tk.Frame(frame, bg=BG_CARD)
                btn_f.pack(fill="x", padx=8, pady=(0, 6))
                tk.Button(btn_f, text="+ 添加行", font=(FONT_CJK, 8),
                          command=lambda lf=list_frame, k=key: self._dlg_list_add(lf, k)).pack(side="left", padx=2)
            elif isinstance(val, dict):
                # Nested dict (e.g. trainers section)
                for sub_key, sub_val in val.items():
                    sub_frame = tk.Frame(frame, bg="#F8F8FA", bd=0)
                    sub_frame.pack(fill="x", padx=12, pady=2)
                    tk.Label(sub_frame, text=f"  {sub_key}:", bg="#F8F8FA", fg=TEXT_SEC,
                             font=(FONT_CJK, 9)).pack(anchor="w")
                    if isinstance(sub_val, dict):
                        for dk, dv in sub_val.items():
                            df = tk.Frame(sub_frame, bg="#F8F8FA")
                            df.pack(fill="x", padx=16, pady=1)
                            tk.Label(df, text=dk, bg="#F8F8FA", fg=TEXT_SEC,
                                     font=(FONT_CJK, 8), width=14, anchor="w").pack(side="left")
                            t = tk.Text(df, height=2, width=40, font=(FONT_CJK, 10),
                                        wrap="word", bd=1, relief="solid")
                            t.insert("1.0", str(dv))
                            t.pack(side="left", fill="x", expand=True, padx=4)
                            self._dlg_editors[f"{key}.{sub_key}.{dk}"] = ("text", t)
                    else:
                        t = tk.Text(sub_frame, height=2, width=40, font=(FONT_CJK, 10),
                                    wrap="word", bd=1, relief="solid")
                        t.insert("1.0", str(sub_val))
                        t.pack(fill="x", padx=16, pady=2)
                        self._dlg_editors[f"{key}.{sub_key}"] = ("text", t)
            else:
                # Simple string
                t = tk.Text(frame, height=3, width=50, font=(FONT_CJK, 10),
                            wrap="word", bd=1, relief="solid")
                t.insert("1.0", str(val))
                t.pack(fill="x", padx=8, pady=(0, 6))
                self._dlg_editors[key] = ("text", t)

        # Buttons
        btn_f2 = tk.Frame(scroll_frame, bg=BG_MAIN)
        btn_f2.pack(fill="x", padx=14, pady=12)
        tk.Button(btn_f2, text="💾 保存剧情文本", font=(FONT_CJK, 11, "bold"),
                  bg=ACCENT, fg="white", bd=0, padx=16, pady=6,
                  command=self._dlg_save).pack(side="left")
        tk.Button(btn_f2, text="+ 新增条目", font=(FONT_CJK, 9),
                  command=self._dlg_add_key).pack(side="left", padx=12)

    def _dlg_build_list_entries(self, parent, items):
        for w in parent.winfo_children():
            w.destroy()
        for i, item in enumerate(items):
            row_f = tk.Frame(parent, bg=BG_CARD)
            row_f.pack(fill="x", pady=1)
            tk.Label(row_f, text=f"[{i}]", bg=BG_CARD, fg=TEXT_SEC,
                     font=(FONT_CJK, 8), width=4).pack(side="left")
            t = tk.Text(row_f, height=3, width=45, font=(FONT_CJK, 10),
                        wrap="word", bd=1, relief="solid")
            t.insert("1.0", str(item))
            t.pack(side="left", fill="x", expand=True, padx=4)
            tk.Button(row_f, text="×", font=(FONT_CJK, 8), width=2,
                      command=lambda idx=i, p=parent, k=self._dlg_current_section: self._dlg_list_remove(p, idx)).pack(side="left", padx=2)

    def _dlg_list_add(self, parent, key):
        sec = self._dlg_data.get(self._dlg_current_section, {})
        lst = sec.get(key, [])
        lst.append("")
        sec[key] = lst
        self._dlg_build_list_entries(parent, lst)

    def _dlg_list_remove(self, parent, idx):
        # Collect current text from all entries first
        texts = []
        for row_f in parent.winfo_children():
            for w in row_f.winfo_children():
                if isinstance(w, tk.Text):
                    texts.append(w.get("1.0", "end-1c"))
        if idx < len(texts):
            texts.pop(idx)
        self._dlg_build_list_entries(parent, texts)

    def _dlg_add_key(self):
        sec_id = self._dlg_current_section
        if not sec_id:
            return
        dlg = tk.Toplevel(self.root)
        dlg.title("新增文本条目")
        dlg.geometry("340x180")
        dlg.transient(self.root)
        tk.Label(dlg, text="条目 Key:", font=(FONT_CJK, 10)).pack(pady=(12, 2))
        key_e = tk.Entry(dlg, font=(FONT_CJK, 10), width=28)
        key_e.pack(pady=2)
        key_e.focus_set()
        var_type = tk.StringVar(value="string")
        tf = tk.Frame(dlg)
        tf.pack(pady=4)
        tk.Radiobutton(tf, text="单行文本", variable=var_type, value="string").pack(side="left", padx=6)
        tk.Radiobutton(tf, text="多行列表", variable=var_type, value="list").pack(side="left", padx=6)
        def ok():
            k = key_e.get().strip()
            if not k:
                return
            sec = self._dlg_data.setdefault(sec_id, {})
            if k not in sec:
                sec[k] = [] if var_type.get() == "list" else ""
                save_json(DIALOGS_FILE, self._dlg_data)
                dlg.destroy()
                self._on_dlg_section_select()
        tk.Button(dlg, text="确定", command=ok).pack(pady=8)

    def _dlg_save(self):
        sec_id = self._dlg_current_section
        if not sec_id:
            return
        sec = self._dlg_data.get(sec_id, {})

        for editor_key, editor_info in self._dlg_editors.items():
            if editor_info[0] == "text":
                val = editor_info[1].get("1.0", "end-1c")
                parts = editor_key.split(".")
                if len(parts) == 1:
                    sec[parts[0]] = val
                elif len(parts) == 2:
                    if parts[0] not in sec:
                        sec[parts[0]] = {}
                    sec[parts[0]][parts[1]] = val
                elif len(parts) == 3:
                    if parts[0] not in sec:
                        sec[parts[0]] = {}
                    if parts[1] not in sec[parts[0]]:
                        sec[parts[0]][parts[1]] = {}
                    sec[parts[0]][parts[1]][parts[2]] = val
            elif editor_info[0] == "list":
                list_frame = editor_info[1]
                texts = []
                for row_f in list_frame.winfo_children():
                    for w in row_f.winfo_children():
                        if isinstance(w, tk.Text):
                            texts.append(w.get("1.0", "end-1c"))
                sec[editor_info[3]] = texts

        self._dlg_data[sec_id] = sec
        save_json(DIALOGS_FILE, self._dlg_data)
        self._update_status(f"剧情文本已保存 — {sec_id}")

    def _dlg_add_section(self):
        dlg = tk.Toplevel(self.root)
        dlg.title("新增场景分组")
        dlg.geometry("300x120")
        dlg.transient(self.root)
        tk.Label(dlg, text="分组 ID（英文）:", font=(FONT_CJK, 10)).pack(pady=(12, 4))
        entry = tk.Entry(dlg, font=(FONT_CJK, 10), width=24)
        entry.pack(pady=4)
        entry.focus_set()
        def ok():
            sid = entry.get().strip()
            if sid and sid not in self._dlg_data:
                self._dlg_data[sid] = {}
                save_json(DIALOGS_FILE, self._dlg_data)
                self._refresh_dlg_tree()
                dlg.destroy()
        tk.Button(dlg, text="确定", command=ok).pack(pady=8)

    def _dlg_del_section(self):
        sel = self._dlg_tree.selection()
        if not sel:
            return
        sec_id = sel[0]
        if messagebox.askyesno("删除", f"确定删除分组 '{sec_id}'？", parent=self.root):
            self._dlg_data.pop(sec_id, None)
            save_json(DIALOGS_FILE, self._dlg_data)
            self._dlg_current_section = None
            self._refresh_dlg_tree()
            self._dlg_right.pack_forget()
            self._dlg_placeholder.pack(fill="both", expand=True)

    def run(self):
        self._ghost.mainloop()


if __name__ == "__main__":
    App().run()
