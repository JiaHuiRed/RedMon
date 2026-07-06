"""
通用行走图重建脚本 v2
- 等分法提取帧（不依赖白色列检测，更可靠）
- 5列×4行 480×640 RGBA
- 侧走3帧时 ping-pong 填充5列: [0,1,2,1,0]
"""
from PIL import Image, ImageOps
import numpy as np
from collections import deque

FRAME_W = 96
FRAME_H = 160
SHEET_COLS = 5
SHEET_ROWS = 4

# ── 洪水填充去白底（逐帧）────────────────────────────────────────
def flood_remove_bg(arr, white_r=210, white_g=210, white_b=210):
    h, w = arr.shape[:2]
    visited = np.zeros((h, w), dtype=bool)
    queue = deque()
    def is_white(y, x):
        r,g,b,a = arr[y,x]
        return int(r)>=white_r and int(g)>=white_g and int(b)>=white_b and int(a)>30
    for ry in range(h):
        for rx in [0, w-1]:
            if not visited[ry,rx] and is_white(ry,rx):
                visited[ry,rx]=True; queue.append((ry,rx))
    for rx in range(w):
        for ry in [0,h-1]:
            if not visited[ry,rx] and is_white(ry,rx):
                visited[ry,rx]=True; queue.append((ry,rx))
    while queue:
        ry,rx = queue.popleft()
        arr[ry,rx,3] = 0
        for dy,dx in [(-1,0),(1,0),(0,-1),(0,1)]:
            ny,nx = ry+dy,rx+dx
            if 0<=ny<h and 0<=nx<w and not visited[ny,nx] and is_white(ny,nx):
                visited[ny,nx]=True; queue.append((ny,nx))
    return arr

# ── 等分提取单帧 → 缩放到 96×160 ───────────────────────────────
def extract_frame_equal(img_arr, frame_idx, total_frames, fit_mode='both'):
    """
    等分法：将图像横向等分为 total_frames 份，取第 frame_idx 份
    fit_mode: 'both'=fit内框, 'width'=按宽缩放(适合高细长角色)
    """
    h, w = img_arr.shape[:2]
    slice_w = w // total_frames
    c0 = frame_idx * slice_w
    c1 = c0 + slice_w - 1
    crop = img_arr[:, c0:c1+1, :].copy()

    if crop.shape[2] == 3:
        alpha = np.full((h, crop.shape[1], 1), 255, dtype=np.uint8)
        crop = np.concatenate([crop, alpha], axis=2)

    crop = flood_remove_bg(crop)

    alpha = crop[:,:,3]
    rows_used = np.any(alpha > 10, axis=1)
    cols_used = np.any(alpha > 10, axis=0)
    if not rows_used.any():
        return Image.new('RGBA', (FRAME_W, FRAME_H), (0,0,0,0))

    rmin,rmax = np.where(rows_used)[0][[0,-1]]
    cmin,cmax = np.where(cols_used)[0][[0,-1]]
    content = crop[rmin:rmax+1, cmin:cmax+1, :]
    sprite = Image.fromarray(content, 'RGBA')

    sw, sh = sprite.size
    if fit_mode == 'width':
        # 按宽缩放，超高时裁剪顶部，保留底部（身体）
        ratio = FRAME_W / sw
        nw, nh = FRAME_W, int(sh * ratio)
        sprite = sprite.resize((nw, nh), Image.LANCZOS)
        if nh > FRAME_H:
            # 裁掉顶部（武器/装饰），保留底部（身体）
            sprite = sprite.crop((0, nh - FRAME_H, FRAME_W, nh))
            nh = FRAME_H
        canvas = Image.new('RGBA', (FRAME_W, FRAME_H), (0,0,0,0))
        oy = FRAME_H - nh
        canvas.paste(sprite, (0, oy), sprite)
    else:
        ratio = min(FRAME_W / sw, FRAME_H / sh)
        nw, nh = int(sw * ratio), int(sh * ratio)
        sprite = sprite.resize((nw, nh), Image.LANCZOS)
        canvas = Image.new('RGBA', (FRAME_W, FRAME_H), (0,0,0,0))
        ox = (FRAME_W - nw) // 2
        oy = (FRAME_H - nh) // 2
        canvas.paste(sprite, (ox, oy), sprite)
    return canvas

# ── 主构建函数 ───────────────────────────────────────────────────
def build_sheet(out_path, front_src, back_src, side_src,
                front_n=3, back_n=3, side_n=3, fit_mode='both'):
    D = r"D:\AI\Game\RPG_Demo\assets\download"
    sheet = Image.new('RGBA', (FRAME_W * SHEET_COLS, FRAME_H * SHEET_ROWS), (0,0,0,0))

    def paste(frame_img, col, row):
        sheet.paste(frame_img, (col*FRAME_W, row*FRAME_H), frame_img)

    front_arr = np.array(Image.open(f"{D}/{front_src}").convert('RGBA'))
    back_arr  = np.array(Image.open(f"{D}/{back_src}").convert('RGBA'))
    side_arr  = np.array(Image.open(f"{D}/{side_src}").convert('RGBA'))

    # Row 0: 正面(下)  最多3帧放cols 0,1,2
    for i in range(min(front_n, 3)):
        f = extract_frame_equal(front_arr, i, front_n, fit_mode)
        paste(f, i, 0)
    # Row 1: 背面(上)
    for i in range(min(back_n, 3)):
        f = extract_frame_equal(back_arr, i, back_n, fit_mode)
        paste(f, i, 1)

    # Row 2: 右侧走  ping-pong 填5列
    side_frames = []
    for i in range(side_n):
        side_frames.append(extract_frame_equal(side_arr, i, side_n, fit_mode))
    # ping-pong: [0,1,2,1,0] for 3 frames; [0,1,2,3,4] for 5; [0,1,0] for 2 etc.
    if side_n == 3:
        order = [0, 1, 2, 1, 0]
    elif side_n == 5:
        order = [0, 1, 2, 3, 4]
    elif side_n == 4:
        order = [0, 1, 2, 3, 2]
    else:
        order = ([i for i in range(side_n)] + [side_n-2-i for i in range(max(0, 5-side_n))])[:5]
    for col, fi in enumerate(order):
        paste(side_frames[fi], col, 2)

    # Row 3: 左侧走 = Row 2 镜像
    for col in range(SHEET_COLS):
        src = sheet.crop((col*FRAME_W, 2*FRAME_H, (col+1)*FRAME_W, 3*FRAME_H))
        paste(ImageOps.mirror(src), col, 3)

    sheet.save(out_path)
    print(f"Saved: {out_path}")

# ════════════════════════════════════════════════════════════════
NPC = r"D:\AI\Game\RPG_Demo\assets\npc"

print("=== 劲敌 walk_sheet ===")
build_sheet(
    out_path=f"{NPC}/劲敌walk_sheet.png",
    front_src="劲敌正面行走.jpg",
    back_src ="劲敌背面图.jpg",
    side_src ="劲敌侧走.jpg",
    front_n=3, back_n=3, side_n=3,
    fit_mode='both'
)

print("=== 申鹤 walk_sheet ===")
build_sheet(
    out_path=f"{NPC}/申鹤walk_sheet.png",
    front_src="正走申鹤.jpg",
    back_src ="背面申鹤.jpg",
    side_src ="侧走申鹤.jpg",
    front_n=3, back_n=3, side_n=3,
    fit_mode='width'   # 申鹤高细长，按宽缩放
)

print("Done!")
