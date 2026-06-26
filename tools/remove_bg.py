#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
批量将精灵图的白色背景转为透明。
策略：取左上角像素颜色作为背景色，BFS flood-fill 从四角向内找连通背景区域，
     只透明化背景，不影响精灵身上同色的区域。

用法:
  python -X utf8 tools/remove_bg.py                 # 处理 assets/sprites/ 下所有 PNG
  python -X utf8 tools/remove_bg.py --preview 炎喵  # 仅预览一张（输出 _preview.png）
  python -X utf8 tools/remove_bg.py --tolerance 30  # 调整颜色容差（默认15）
"""

import os, sys, argparse
from PIL import Image
from collections import deque

ROOT       = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPRITE_DIR = os.path.join(ROOT, "assets", "sprites")

def color_dist(c1, c2):
    return max(abs(c1[i] - c2[i]) for i in range(3))

def remove_bg(img: Image.Image, tolerance: int = 15) -> Image.Image:
    """返回已去背景的 RGBA 图像（原图不修改）。"""
    rgba = img.convert("RGBA")
    w, h = rgba.size
    pixels = rgba.load()

    # 背景色 = 左上角像素 RGB
    bg_color = pixels[0, 0][:3]

    # BFS 从四角出发，找所有连通的背景像素
    visited = [[False] * h for _ in range(w)]
    queue   = deque()

    def enqueue(x, y):
        if 0 <= x < w and 0 <= y < h and not visited[x][y]:
            if color_dist(pixels[x, y][:3], bg_color) <= tolerance:
                visited[x][y] = True
                queue.append((x, y))

    for corner in [(0, 0), (w-1, 0), (0, h-1), (w-1, h-1)]:
        enqueue(*corner)

    while queue:
        x, y = queue.popleft()
        for dx, dy in [(-1,0),(1,0),(0,-1),(0,1)]:
            enqueue(x+dx, y+dy)

    # 将背景区域 alpha 设为 0
    result = rgba.copy()
    rpx = result.load()
    for x in range(w):
        for y in range(h):
            if visited[x][y]:
                r, g, b, _ = rpx[x, y]
                rpx[x, y] = (r, g, b, 0)

    return result


def process_file(path: str, tolerance: int, preview: bool = False):
    img = Image.open(path)
    out = remove_bg(img, tolerance)

    if preview:
        preview_path = path.replace(".png", "_preview.png")
        out.save(preview_path)
        print(f"预览已保存: {preview_path}")
    else:
        out.save(path)
        print(f"已处理: {os.path.basename(path)}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--preview", metavar="NAME",
                        help="仅预览指定精灵名（不含扩展名）")
    parser.add_argument("--tolerance", type=int, default=15,
                        help="颜色容差 0-255（默认15）")
    args = parser.parse_args()

    if args.preview:
        # 找匹配文件
        matches = [f for f in os.listdir(SPRITE_DIR)
                   if args.preview in f and f.endswith(".png")]
        if not matches:
            print(f"找不到包含 '{args.preview}' 的 PNG")
            sys.exit(1)
        for name in matches:
            process_file(os.path.join(SPRITE_DIR, name), args.tolerance, preview=True)
    else:
        files = sorted(f for f in os.listdir(SPRITE_DIR) if f.endswith(".png"))
        print(f"找到 {len(files)} 个 PNG，容差={args.tolerance}，开始处理…")
        for name in files:
            process_file(os.path.join(SPRITE_DIR, name), args.tolerance)
        print("全部完成。")


if __name__ == "__main__":
    main()
