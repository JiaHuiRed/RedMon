"""
批量转换 sprites 目录下所有 JPG → PNG（去除背景）
角点采样法去背景，tolerance=40
转换成功后删除原 JPG
"""
import os
import sys
from PIL import Image, ImageOps

SPRITES_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites")
SPRITES_DIR = os.path.abspath(SPRITES_DIR)

def remove_bg(img, tolerance=40):
    img = img.convert("RGBA")
    w, h = img.size
    # 采样四角 + 四边中点，取平均背景色
    sample_points = [
        (0, 0), (w-1, 0), (0, h-1), (w-1, h-1),
        (w//2, 0), (w//2, h-1), (0, h//2), (w-1, h//2),
    ]
    samples = [img.getpixel(p)[:3] for p in sample_points]
    bg_r = sum(s[0] for s in samples) // len(samples)
    bg_g = sum(s[1] for s in samples) // len(samples)
    bg_b = sum(s[2] for s in samples) // len(samples)

    data = list(img.getdata())
    new_data = []
    for pixel in data:
        r, g, b, a = pixel
        if (abs(r - bg_r) < tolerance and
            abs(g - bg_g) < tolerance and
            abs(b - bg_b) < tolerance):
            new_data.append((0, 0, 0, 0))
        else:
            new_data.append((r, g, b, a))
    img.putdata(new_data)
    return img

def convert_all():
    jpg_files = [f for f in os.listdir(SPRITES_DIR) if f.lower().endswith(".jpg")]
    if not jpg_files:
        print("没有找到 JPG 文件")
        return

    print(f"找到 {len(jpg_files)} 个 JPG 文件，开始转换...\n")
    ok = 0
    fail = 0

    for fname in sorted(jpg_files):
        src = os.path.join(SPRITES_DIR, fname)
        dst = os.path.join(SPRITES_DIR, os.path.splitext(fname)[0] + ".png")

        try:
            img = Image.open(src)
            result = remove_bg(img, tolerance=40)
            result.save(dst, "PNG")
            os.remove(src)
            print(f"  OK {fname} -> {os.path.basename(dst)}")
            ok += 1
        except Exception as e:
            print(f"  FAIL {fname}: {e}")
            fail += 1

    print(f"\n完成：{ok} 成功，{fail} 失败")

if __name__ == "__main__":
    convert_all()
