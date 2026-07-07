"""
修复女主 walk_sheet.png 白底透明化
使用逐帧洪水填充（从帧四角向内），只去掉连通的背景白色，不影响皮肤等内部颜色
"""
from PIL import Image
import numpy as np
from collections import deque

SHEET_PATH = r"D:\AI\Game\RPG_Demo\assets\npc\女主walk_sheet.png"

FRAME_W = 96
FRAME_H = 160
COLS    = 5   # 当前是5列（侧走扩展后）
ROWS    = 4

# 白色判定阈值（更宽松些，确保纯白都能去掉）
WHITE_R = 220
WHITE_G = 220
WHITE_B = 220

def flood_fill_bg(arr, frame_x, frame_y):
    """从帧的四个角开始洪水填充，标记所有连通白色区域为背景"""
    h, w = FRAME_H, FRAME_W
    # 创建本帧的 RGBA 副本视图（避免越界）
    visited = np.zeros((h, w), dtype=bool)
    queue = deque()

    # 从帧内四个角和四条边开始（只加白色起点）
    seeds = []
    for ry in range(h):
        seeds.append((ry, 0))
        seeds.append((ry, w-1))
    for rx in range(w):
        seeds.append((0, rx))
        seeds.append((h-1, rx))

    for (ry, rx) in seeds:
        py, px = frame_y + ry, frame_x + rx
        r, g, b, a = arr[py, px]
        if a > 10 and r >= WHITE_R and g >= WHITE_G and b >= WHITE_B and not visited[ry, rx]:
            queue.append((ry, rx))
            visited[ry, rx] = True

    while queue:
        ry, rx = queue.popleft()
        py, px = frame_y + ry, frame_x + rx
        arr[py, px, 3] = 0  # 设为透明

        for dy, dx in [(-1,0),(1,0),(0,-1),(0,1)]:
            ny, nx = ry+dy, rx+dx
            if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx]:
                npy, npx = frame_y+ny, frame_x+nx
                r, g, b, a = arr[npy, npx]
                if a > 10 and r >= WHITE_R and g >= WHITE_G and b >= WHITE_B:
                    visited[ny, nx] = True
                    queue.append((ny, nx))

img = Image.open(SHEET_PATH).convert("RGBA")
arr = np.array(img, dtype=np.uint8)
print(f"Sheet size: {img.width}×{img.height}, COLS={COLS}, ROWS={ROWS}")

for row in range(ROWS):
    for col in range(COLS):
        fx = col * FRAME_W
        fy = row * FRAME_H
        if fy + FRAME_H > arr.shape[0] or fx + FRAME_W > arr.shape[1]:
            continue
        flood_fill_bg(arr, fx, fy)
        print(f"  Frame ({col},{row}) processed")

result = Image.fromarray(arr, 'RGBA')
result.save(SHEET_PATH)
print(f"Saved: {SHEET_PATH}")

# 检验：统计仍有白色的像素
white_mask = (arr[:,:,0] >= WHITE_R) & (arr[:,:,1] >= WHITE_G) & (arr[:,:,2] >= WHITE_B) & (arr[:,:,3] > 10)
print(f"Remaining white-ish visible pixels: {white_mask.sum()} (should be small, these are interior highlights)")
