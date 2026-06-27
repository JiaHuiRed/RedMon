"""
将 assets/sprites/ 下所有 PNG 统一缩放到 512x512 画布
- 保持长宽比，居中，透明填充
- 缩小用 LANCZOS（AI 生成图）
- 放大用 NEAREST（像素图）
- 已经是 512x512 的跳过
"""
import os, sys
from PIL import Image

SPRITES_DIR = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..", "assets", "sprites"))
TARGET = 512

def resize_to_canvas(img):
    img = img.convert("RGBA")
    w, h = img.size

    if w == TARGET and h == TARGET:
        return None  # 不需要处理

    # 计算等比缩放尺寸
    scale = TARGET / max(w, h)
    new_w = round(w * scale)
    new_h = round(h * scale)

    # 选择重采样算法
    resample = Image.LANCZOS if scale < 1 else Image.NEAREST
    img = img.resize((new_w, new_h), resample)

    # 居中贴到 512x512 透明画布
    canvas = Image.new("RGBA", (TARGET, TARGET), (0, 0, 0, 0))
    x = (TARGET - new_w) // 2
    y = (TARGET - new_h) // 2
    canvas.paste(img, (x, y))
    return canvas

def main():
    files = [f for f in os.listdir(SPRITES_DIR)
             if f.lower().endswith(".png") and not f.endswith(".import")]
    files.sort()
    print(f"找到 {len(files)} 个 PNG，开始处理...")

    skipped = ok = fail = 0
    for fname in files:
        path = os.path.join(SPRITES_DIR, fname)
        try:
            img = Image.open(path)
            result = resize_to_canvas(img)
            if result is None:
                skipped += 1
                continue
            result.save(path, "PNG")
            print(f"  OK {img.size} -> 512x512  {fname}")
            ok += 1
        except Exception as e:
            print(f"  FAIL {fname}: {e}")
            fail += 1

    print(f"\n完成: {ok} 处理, {skipped} 跳过(已512), {fail} 失败")

if __name__ == "__main__":
    main()
