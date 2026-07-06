"""
从原始 JPG 素材重建女主 walk_sheet.png
格式: 5列×4行, 每帧 96×160 px (RGBA)
行顺序: 0=下(正面), 1=上(背面), 2=右侧, 3=左侧(镜像)
列顺序: 各方向帧序列(正/背3帧, 侧5帧)
"""
from PIL import Image, ImageOps
import numpy as np
from collections import deque

FRAME_W = 96
FRAME_H = 160
COLS    = 5
ROWS    = 4

D = r"D:\AI\Game\RPG_Demo\assets\download"
OUT = r"D:\AI\Game\RPG_Demo\assets\npc\女主walk_sheet.png"

# ── 洪水填充去白底 ──────────────────────────────────────────────
def flood_remove_bg(arr, white_r=215, white_g=215, white_b=215):
    """从图像四条边洪水填充，去掉连通白色背景"""
    h, w = arr.shape[:2]
    visited = np.zeros((h, w), dtype=bool)
    queue = deque()

    def is_white(y, x):
        r, g, b, a = arr[y, x]
        return int(r) >= white_r and int(g) >= white_g and int(b) >= white_b and int(a) > 30

    for ry in range(h):
        for rx in [0, w-1]:
            if not visited[ry, rx] and is_white(ry, rx):
                visited[ry, rx] = True; queue.append((ry, rx))
    for rx in range(w):
        for ry in [0, h-1]:
            if not visited[ry, rx] and is_white(ry, rx):
                visited[ry, rx] = True; queue.append((ry, rx))

    while queue:
        ry, rx = queue.popleft()
        arr[ry, rx, 3] = 0
        for dy, dx in [(-1,0),(1,0),(0,-1),(0,1)]:
            ny, nx = ry+dy, rx+dx
            if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx] and is_white(ny, nx):
                visited[ny, nx] = True; queue.append((ny, nx))
    return arr

# ── 提取帧边界（按白色分隔列检测）────────────────────────────────
def get_frame_bounds(img):
    arr = np.array(img.convert('RGBA'))
    h, w = arr.shape[:2]
    # 每列白色像素占比
    white_col = np.mean(
        (arr[:,:,0] > 210) & (arr[:,:,1] > 210) & (arr[:,:,2] > 210), axis=0
    )
    is_sep = white_col > 0.97  # 几乎全白的列为分隔

    # 找连续分隔段
    gaps = []
    in_gap = False; gs = 0
    for c in range(w):
        if is_sep[c] and not in_gap:
            in_gap = True; gs = c
        elif not is_sep[c] and in_gap:
            in_gap = False; gaps.append((gs, c-1))
    if in_gap: gaps.append((gs, w-1))

    # 内容段 = gap 之间
    bounds = []
    prev_end = -1
    for gstart, gend in gaps:
        if prev_end + 1 <= gstart - 1:
            bounds.append((prev_end + 1, gstart - 1))
        prev_end = gend
    if prev_end < w - 1:
        bounds.append((prev_end + 1, w - 1))

    return bounds  # list of (col_start, col_end)

# ── 提取单帧 → 去白底 → 缩放到 96×160 ──────────────────────────
def extract_frame(img_arr, c0, c1):
    """从原始图像提取一列帧，去白底，自动裁剪内容，缩放到 FRAME_W×FRAME_H"""
    h = img_arr.shape[0]
    crop = img_arr[:, c0:c1+1, :].copy()

    # 确保 RGBA
    if crop.shape[2] == 3:
        alpha = np.full((h, crop.shape[1], 1), 255, dtype=np.uint8)
        crop = np.concatenate([crop, alpha], axis=2)

    # 洪水去白底
    crop = flood_remove_bg(crop)

    # 找内容边界（非透明像素）
    alpha = crop[:, :, 3]
    rows_used = np.any(alpha > 10, axis=1)
    cols_used = np.any(alpha > 10, axis=0)

    if not rows_used.any():
        return Image.new('RGBA', (FRAME_W, FRAME_H), (0,0,0,0))

    rmin, rmax = np.where(rows_used)[0][[0,-1]]
    cmin, cmax = np.where(cols_used)[0][[0,-1]]
    content = crop[rmin:rmax+1, cmin:cmax+1, :]
    sprite = Image.fromarray(content, 'RGBA')

    # 保持宽高比缩放以适应 FRAME_W×FRAME_H
    sw, sh = sprite.size
    ratio = min(FRAME_W / sw, FRAME_H / sh)
    nw, nh = int(sw * ratio), int(sh * ratio)
    sprite = sprite.resize((nw, nh), Image.LANCZOS)

    # 居中放置
    canvas = Image.new('RGBA', (FRAME_W, FRAME_H), (0, 0, 0, 0))
    ox = (FRAME_W - nw) // 2
    oy = (FRAME_H - nh) // 2
    canvas.paste(sprite, (ox, oy), sprite)
    return canvas

# ── 主流程 ──────────────────────────────────────────────────────
print("读取原始素材...")
front_img = Image.open(f"{D}/女主正面行走图.jpg").convert('RGBA')
back_img  = Image.open(f"{D}/女主背面图.jpg").convert('RGBA')
side_img  = Image.open(f"{D}/女主侧走图.jpg").convert('RGBA')

front_arr = np.array(front_img)
back_arr  = np.array(back_img)
side_arr  = np.array(side_img)

front_bounds = get_frame_bounds(front_img)
back_bounds  = get_frame_bounds(back_img)
side_bounds  = get_frame_bounds(side_img)

print(f"正面: {len(front_bounds)} 帧 @ {front_bounds}")
print(f"背面: {len(back_bounds)} 帧 @ {back_bounds}")
print(f"侧走: {len(side_bounds)} 帧 @ {side_bounds}")

# ── 构建 walk_sheet ─────────────────────────────────────────────
sheet = Image.new('RGBA', (FRAME_W * COLS, FRAME_H * ROWS), (0, 0, 0, 0))

def paste_frame(frame_img, col, row):
    x, y = col * FRAME_W, row * FRAME_H
    sheet.paste(frame_img, (x, y), frame_img)

# Row 0: 正面(下)  3帧 → cols 0,1,2
for i, (c0, c1) in enumerate(front_bounds[:3]):
    f = extract_frame(front_arr, c0, c1)
    paste_frame(f, i, 0)
    print(f"  front[{i}] done")

# Row 1: 背面(上)  3帧 → cols 0,1,2
for i, (c0, c1) in enumerate(back_bounds[:3]):
    f = extract_frame(back_arr, c0, c1)
    paste_frame(f, i, 1)
    print(f"  back[{i}] done")

# Row 2: 右侧走  5帧 → cols 0-4
for i, (c0, c1) in enumerate(side_bounds[:5]):
    f = extract_frame(side_arr, c0, c1)
    paste_frame(f, i, 2)
    print(f"  side[{i}] done")

# Row 3: 左侧走  = Row 2 水平镜像
for col in range(COLS):
    x0, y0 = col * FRAME_W, 2 * FRAME_H
    x1, y1 = col * FRAME_W, 3 * FRAME_H
    src = sheet.crop((x0, y0, x0 + FRAME_W, y0 + FRAME_H))
    mirrored = ImageOps.mirror(src)
    sheet.paste(mirrored, (x1, y1), mirrored)
    print(f"  left[{col}] mirrored")

sheet.save(OUT)
print(f"\n✓ 保存到 {OUT}  ({sheet.size})")
