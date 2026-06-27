"""分析精灵图的连通分量，找出可能残留的文字"""
from PIL import Image
import numpy as np
from scipy.ndimage import label

SPRITE_DIR = 'assets/sprites'

def analyze(filename):
    img = Image.open(f'{SPRITE_DIR}/{filename}')
    arr = np.array(img)
    r, g, b, a = arr[:,:,0].astype(int), arr[:,:,1].astype(int), arr[:,:,2].astype(int), arr[:,:,3]
    opaque = a > 200
    labeled, num_features = label(opaque)
    h, w = arr.shape[:2]
    print(f'{filename}: {num_features} components, {h}x{w}')

    components = []
    for i in range(1, num_features + 1):
        comp_mask = labeled == i
        ys, xs = np.where(comp_mask)
        if len(ys) == 0:
            continue
        size = len(ys)
        y_min, y_max = int(ys.min()), int(ys.max())
        x_min, x_max = int(xs.min()), int(xs.max())
        height = y_max - y_min + 1
        width = x_max - x_min + 1
        aspect = width / max(height, 1)

        # 关注 top 区域的小组件
        if y_min < h//3 and size > 3 and size < 300:
            avg_r = float(r[comp_mask].mean())
            avg_g = float(g[comp_mask].mean())
            avg_b = float(b[comp_mask].mean())
            components.append({
                'size': size, 'y': y_min, 'x': x_min,
                'w': width, 'h': height, 'aspect': aspect,
                'rgb': f'({avg_r:.0f},{avg_g:.0f},{avg_b:.0f})'
            })

    components.sort(key=lambda c: c['y'])
    print(f'  Top-region components (y < {h//3}): {len(components)}')
    for c in components[:20]:
        print(f'  y={c["y"]:3d} x={c["x"]:3d}  size={c["size"]:3d}  {c["w"]}x{c["h"]}  aspect={c["aspect"]:.1f}  RGB{c["rgb"]}')

    return components


analyze('震霆龙_front.png')
print()
analyze('雷螈_front.png')
