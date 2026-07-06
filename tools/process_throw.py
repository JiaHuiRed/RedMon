"""
处理 女主throw.jpg:
- 黑色背景（透明→JPG→黑）洪水填充还原透明
- 裁掉底部文字（y>=1295 全黑行）
- 按分割线切成 2 帧
- 每帧缩放到 96×160，输出 192×160 水平拼接 PNG
"""
from PIL import Image, ImageOps
import numpy as np
from collections import deque

SRC  = r"D:\AI\Game\RPG_Demo\assets\download\女主throw.jpg"
OUT  = r"D:\AI\Game\RPG_Demo\assets\npc\女主throw.png"

FRAME_W = 96
FRAME_H = 160

# ── 洪水填充去黑底（从边缘的近黑色向内扩散）──────────────────
def flood_remove_black(arr, thresh=40):
    h, w = arr.shape[:2]
    visited = np.zeros((h, w), dtype=bool)
    queue = deque()
    def is_bg(y, x):
        r,g,b = arr[y,x,0], arr[y,x,1], arr[y,x,2]
        return int(r)<thresh and int(g)<thresh and int(b)<thresh
    for ry in range(h):
        for rx in [0, w-1]:
            if not visited[ry,rx] and is_bg(ry,rx):
                visited[ry,rx]=True; queue.append((ry,rx))
    for rx in range(w):
        for ry in [0,h-1]:
            if not visited[ry,rx] and is_bg(ry,rx):
                visited[ry,rx]=True; queue.append((ry,rx))
    while queue:
        ry,rx = queue.popleft()
        arr[ry,rx,3] = 0
        for dy,dx in [(-1,0),(1,0),(0,-1),(0,1)]:
            ny,nx = ry+dy,rx+dx
            if 0<=ny<h and 0<=nx<w and not visited[ny,nx] and is_bg(ny,nx):
                visited[ny,nx]=True; queue.append((ny,nx))
    return arr

img = Image.open(SRC).convert('RGBA')
arr = np.array(img)

# 裁掉底部文字行（y >= 1295 全黑）
arr = arr[:1295, :, :]

# 去黑底
arr = flood_remove_black(arr)

# 找分割线（列平均黑色程度>70%，宽>3px）
h, w = arr.shape[:2]
black_col = np.mean((arr[:,:,0]<30) & (arr[:,:,1]<30) & (arr[:,:,2]<30) & (arr[:,:,3]>0), axis=0)
# 也考虑透明列
alpha_col = np.mean(arr[:,:,3] < 10, axis=0)
sep = (black_col + alpha_col) > 0.85

gaps = []; in_g=False; gs=0
for c in range(w):
    if sep[c] and not in_g: in_g=True; gs=c
    elif not sep[c] and in_g: in_g=False; gaps.append((gs,c-1))
if in_g: gaps.append((gs,w-1))

# 内容段
bounds = []; prev=-1
for gs,ge in gaps:
    if prev+1 <= gs-1: bounds.append((prev+1, gs-1))
    prev = ge
if prev < w-1: bounds.append((prev+1, w-1))
print(f"Detected {len(bounds)} frame(s): {[(c1-c0+1) for c0,c1 in bounds]}px wide")

def extract(arr, c0, c1):
    crop = arr[:, c0:c1+1, :].copy()
    alpha = crop[:,:,3]
    rows = np.any(alpha>10, axis=1); cols = np.any(alpha>10, axis=0)
    if not rows.any(): return Image.new('RGBA',(FRAME_W,FRAME_H),(0,0,0,0))
    rmin,rmax = np.where(rows)[0][[0,-1]]
    cmin,cmax = np.where(cols)[0][[0,-1]]
    content = crop[rmin:rmax+1, cmin:cmax+1, :]
    spr = Image.fromarray(content,'RGBA')
    sw,sh = spr.size
    ratio = min(FRAME_W/sw, FRAME_H/sh)
    nw,nh = int(sw*ratio), int(sh*ratio)
    spr = spr.resize((nw,nh), Image.LANCZOS)
    canvas = Image.new('RGBA',(FRAME_W,FRAME_H),(0,0,0,0))
    canvas.paste(spr, ((FRAME_W-nw)//2,(FRAME_H-nh)//2), spr)
    return canvas

n = len(bounds)
sheet = Image.new('RGBA', (FRAME_W*n, FRAME_H), (0,0,0,0))
for i,(c0,c1) in enumerate(bounds):
    f = extract(arr, c0, c1)
    sheet.paste(f, (i*FRAME_W, 0), f)

sheet.save(OUT)
print(f"Saved {n}-frame throw sheet: {sheet.size} → {OUT}")
