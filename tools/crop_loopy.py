"""裁剪 Loopy 素材图：去棋盘格背景 + 拆正反面到 512×512"""
from PIL import Image
import numpy as np
import os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SPRITE_DIR = os.path.join(SCRIPT_DIR, '..', 'assets', 'sprites')

SPECS = [
    # (filename, name_prefix)
    ('露比.png', '露比'),
    ('骑侠露比.png', '骑侠露比'),
    ('潜游露比.png', '潜游露比'),
]


def detect_bg(arr):
    """检测棋盘格/浅色背景"""
    avg = arr.mean(axis=2).astype(float)
    spread = arr.max(axis=2).astype(float) - arr.min(axis=2).astype(float)
    return (avg > 195) & (spread < 25)


def process():
    for filename, prefix in SPECS:
        path = os.path.join(SPRITE_DIR, filename)
        img = Image.open(path)
        arr = np.array(img)
        h, w = arr.shape[:2]
        print(f'\n=== {filename} ({w}×{h}) ===')

        # 去棋盘格
        bg = detect_bg(arr)
        arr[bg] = [255, 255, 255]
        print(f'  Background: {bg.sum()} px cleared')

        # 找左右两个内容区域（列投影）
        content = ~((arr[:, :, 0] > 250) & (arr[:, :, 1] > 250) & (arr[:, :, 2] > 250))
        col_content = content.sum(axis=0)

        # 找垂直方向的内容列段
        threshold = h * 0.02
        cols_with_content = col_content > threshold
        segments = []
        in_seg = False
        start = 0
        for c in range(w):
            if cols_with_content[c] and not in_seg:
                in_seg = True
                start = c
            elif not cols_with_content[c] and in_seg:
                segments.append((start, c))
                in_seg = False
        if in_seg:
            segments.append((start, w))

        # 过滤掉太窄的段（可能是分割线噪点）
        segments = [(x0, x1) for x0, x1 in segments if (x1 - x0) > 50]
        print(f'  Content segments: {segments}')

        if len(segments) < 2:
            print(f'  WARNING: expected 2 segments, got {len(segments)}, skipping')
            continue

        views = ['front', 'back']
        for i, (x0, x1) in enumerate(segments[:2]):
            view = views[i]
            cell = arr[:, x0:x1]

            # 找内容边界框
            not_white = ~((cell[:, :, 0] > 250) & (cell[:, :, 1] > 250) & (cell[:, :, 2] > 250))
            ys, xs = np.where(not_white)

            if len(ys) == 0:
                print(f'  {view}: empty!')
                continue

            pad = 4
            y_min = max(0, ys.min() - pad)
            y_max = min(cell.shape[0] - 1, ys.max() + pad)
            x_min = max(0, xs.min() - pad)
            x_max = min(cell.shape[1] - 1, xs.max() + pad)

            cropped = cell[y_min:y_max + 1, x_min:x_max + 1]
            # 保持宽高比，居中贴到 512×512 画布
            cw, ch = cropped.shape[1], cropped.shape[0]
            scale = min(512 / cw, 512 / ch)
            nw, nh = int(cw * scale), int(ch * scale)
            resized = Image.fromarray(cropped).resize((nw, nh), resample=Image.Resampling.NEAREST)
            canvas = Image.new('RGB', (512, 512), (255, 255, 255))
            x_offset = (512 - nw) // 2
            y_offset = (512 - nh) // 2
            canvas.paste(resized, (x_offset, y_offset))
            out = canvas

            out_name = f'{prefix}_{view}.png'
            out_path = os.path.join(SPRITE_DIR, out_name)
            out.save(out_path)
            print(f'  {out_name}: {cropped.shape[1]}×{cropped.shape[0]} -> 512×512')


if __name__ == '__main__':
    print('=== Loopy Sprite Crop ===')
    process()
    print('\nDone!')
