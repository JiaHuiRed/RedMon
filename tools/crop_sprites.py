"""
crop_sprites.py
把 material/御三家.png 的 3×3 九宫格裁成单独精灵图
输出到 assets/sprites/，文件名自动对应游戏加载规则

用法：
    python tools/crop_sprites.py
"""

from PIL import Image
import os, sys
from collections import deque

# ── 配置 ──────────────────────────────────────────────────────────────────────
INPUT  = os.path.join(os.path.dirname(__file__), "../material/御三家.png")
OUTDIR = os.path.join(os.path.dirname(__file__), "../assets/sprites")

NAMES = [
    ["炎喵",   "烈火猫",   "焚焰狮"],
    ["蓝蛇",   "江蛟",     "覆海龙"],
    ["小竹熊", "武道熊",   "功夫熊师"],
]

OUT_SIZE = 96

# 裁掉每格顶部标签区域的比例（原图每格约占 1/3，标签约占顶部 12%）
TRIM_TOP_RATIO = 0.12

# flood fill 容差：与起始像素颜色相差在此范围内的都视为背景
FLOOD_THRESHOLD = 70

# ── 工具函数 ──────────────────────────────────────────────────────────────────
def color_diff(c1, c2):
    return max(abs(int(c1[0]) - int(c2[0])),
               abs(int(c1[1]) - int(c2[1])),
               abs(int(c1[2]) - int(c2[2])))

def flood_fill_transparent(img: Image.Image, threshold: int) -> Image.Image:
    """从四个角做 BFS flood fill，把背景变透明"""
    img = img.convert("RGBA")
    pixels = img.load()
    w, h = img.size
    visited = [[False] * h for _ in range(w)]
    queue = deque()

    # 四角 + 四边中点作为种子点
    corners = [(0, 0), (w-1, 0), (0, h-1), (w-1, h-1),
               (w//2, 0), (w//2, h-1), (0, h//2), (w-1, h//2)]
    seed_colors = [pixels[x, y][:3] for x, y in corners]
    # 取四角颜色的平均作为背景基准色
    bg_r = sum(c[0] for c in seed_colors) // 4
    bg_g = sum(c[1] for c in seed_colors) // 4
    bg_b = sum(c[2] for c in seed_colors) // 4
    bg_color = (bg_r, bg_g, bg_b)

    for x, y in corners:
        if not visited[x][y]:
            queue.append((x, y))
            visited[x][y] = True

    while queue:
        x, y = queue.popleft()
        r, g, b, a = pixels[x, y]
        if color_diff((r, g, b), bg_color) <= threshold:
            pixels[x, y] = (r, g, b, 0)
            for nx, ny in [(x+1,y),(x-1,y),(x,y+1),(x,y-1)]:
                if 0 <= nx < w and 0 <= ny < h and not visited[nx][ny]:
                    visited[nx][ny] = True
                    queue.append((nx, ny))

    return img

def crop_grid(src: Image.Image, rows: int, cols: int, trim_top_ratio: float):
    w, h = src.size
    cell_w = w // cols
    cell_h = h // rows
    trim_top = int(cell_h * trim_top_ratio)
    cells = []
    for row in range(rows):
        row_cells = []
        for col in range(cols):
            left   = col * cell_w
            top    = row * cell_h + trim_top   # 裁掉顶部标签
            right  = left + cell_w
            bottom = row * cell_h + cell_h
            cell = src.crop((left, top, right, bottom))
            row_cells.append(cell)
        cells.append(row_cells)
    return cells

# ── 主逻辑 ────────────────────────────────────────────────────────────────────
def main():
    if not os.path.exists(INPUT):
        print(f"[错误] 找不到输入文件：{INPUT}")
        sys.exit(1)

    os.makedirs(OUTDIR, exist_ok=True)

    src = Image.open(INPUT).convert("RGBA")
    print(f"[读取] 御三家.png  ({src.size[0]}x{src.size[1]})")

    cells = crop_grid(src, rows=3, cols=3, trim_top_ratio=TRIM_TOP_RATIO)

    for row_idx, row in enumerate(cells):
        for col_idx, cell in enumerate(row):
            name = NAMES[row_idx][col_idx]

            sprite = flood_fill_transparent(cell, FLOOD_THRESHOLD)
            sprite = sprite.resize((OUT_SIZE, OUT_SIZE), Image.LANCZOS)

            front_path = os.path.join(OUTDIR, f"{name}_front.png")
            sprite.save(front_path, "PNG")

            back = sprite.transpose(Image.FLIP_LEFT_RIGHT)
            back_path = os.path.join(OUTDIR, f"{name}_back.png")
            back.save(back_path, "PNG")

            print(f"[输出] {name}_front.png  /  {name}_back.png")

    print(f"\n完成！18 个文件 -> {OUTDIR}")

if __name__ == "__main__":
    main()
