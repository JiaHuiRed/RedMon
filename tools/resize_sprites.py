"""
将 assets/sprites/ 下所有图片统一处理：
1. JPG/JPEG → PNG 转换（删除原 JPG）
2. 统一缩放到 1024x1024 画布（保持长宽比，居中，透明填充）
- 缩小用 LANCZOS（AI 生成图）
- 放大用 NEAREST（像素图）
- 已经是 1024x1024 的跳过
"""
import os, sys
from PIL import Image

if getattr(sys, 'frozen', False):
    # PyInstaller EXE — 直接处理 exe 所在目录
    SPRITES_DIR = os.path.abspath(os.path.dirname(sys.executable))
else:
    # Python 脚本 — 相对项目根
    SPRITES_DIR = os.path.abspath(
        os.path.join(os.path.dirname(__file__), "..", "assets", "sprites"))
TARGET = 1024

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

    # 居中贴到目标尺寸透明画布
    canvas = Image.new("RGBA", (TARGET, TARGET), (0, 0, 0, 0))
    x = (TARGET - new_w) // 2
    y = (TARGET - new_h) // 2
    canvas.paste(img, (x, y))
    return canvas

def convert_jpgs(directory):
    """将目录下所有 JPG/JPEG 转为 PNG 并删除原文件"""
    converted = 0
    jpgs = [f for f in os.listdir(directory)
            if f.lower().endswith((".jpg", ".jpeg")) and not f.endswith(".import")]
    for fname in sorted(jpgs):
        src = os.path.join(directory, fname)
        # 去掉 .jpg/.jpeg 后缀，加 .png
        base = os.path.splitext(fname)[0]
        dst = os.path.join(directory, base + ".png")
        try:
            img = Image.open(src).convert("RGBA")
            img.save(dst, "PNG")
            os.remove(src)
            # 同时删除 Godot 的 .import 缓存
            imp = src + ".import"
            if os.path.exists(imp):
                os.remove(imp)
            print(f"  JPG→PNG  {fname} → {base}.png")
            converted += 1
        except Exception as e:
            print(f"  FAIL JPG转换 {fname}: {e}")
    return converted

def main():
    print("=== 第一步：JPG → PNG 转换 ===")
    j = convert_jpgs(SPRITES_DIR)
    print(f"转换了 {j} 个 JPG\n")

    print("=== 第二步：统一缩放到 1024x1024 ===")
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
            print(f"  OK {img.size} -> {TARGET}x{TARGET}  {fname}")
            ok += 1
        except Exception as e:
            print(f"  FAIL {fname}: {e}")
            fail += 1

    print(f"\n完成: JPG转换 {j} 个, 缩放 {ok} 个({TARGET}x{TARGET}), 跳过 {skipped} 个(已是{TARGET}x{TARGET}), 失败 {fail} 个")

if __name__ == "__main__":
    main()
