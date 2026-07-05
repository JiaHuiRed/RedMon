"""
Batch process new sprites placed in assets/sprites/
Run this script after placing new PNGs (those without a .import file).

Classification rules:
  - walk sheet : filename contains '_walk_sheet' OR '行走图'
  - background : filename in BACKGROUNDS dict
  - sprite     : everything else (front/back mon sprites, NPC fronts)

Processing:
  - sprite     -> remove bg, crop, pad to 512x512 RGBA
  - walk sheet -> remove bg, resize to 144x192 RGBA
  - background -> resize to 960x640 RGB, copy to backgrounds/
"""
import os, shutil
from PIL import Image
import numpy as np
from collections import deque

SPRITES_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sprites")
SPRITES_DIR = os.path.abspath(SPRITES_DIR)
BG_DIR      = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "backgrounds")
BG_DIR      = os.path.abspath(BG_DIR)

# Explicitly named backgrounds -> output filename in backgrounds/
BACKGROUNDS = {
    "翠竹馆战斗背景.png": "战斗背景_竹馆.png",
    "翠竹馆内.png":       "翠竹馆内.png",
}

# NPC single-image files that should be treated as walk-sheet-like
# (tall aspect, NOT mons, NOT gym leaders)
SINGLE_NPC = {"少女.png", "漂亮姐姐.png", "老奶奶.png", "老爷爷.png",
              "胖女人.png", "胖男人.png", "青年.png"}


def flood_fill_bg(arr: np.ndarray, tolerance: int = 55) -> np.ndarray:
    h, w = arr.shape[:2]
    rgb = arr[:, :, :3].astype(np.int32)
    result = arr.copy()
    visited = np.zeros((h, w), dtype=bool)
    queue = deque()
    for r, c in [(0, 0), (0, w-1), (h-1, 0), (h-1, w-1)]:
        if not visited[r, c]:
            visited[r, c] = True
            queue.append((r, c))
    ref = rgb[0, 0]
    while queue:
        r, c = queue.popleft()
        result[r, c, 3] = 0
        for dr, dc in [(-1,0),(1,0),(0,-1),(0,1)]:
            nr, nc = r+dr, c+dc
            if 0 <= nr < h and 0 <= nc < w and not visited[nr, nc]:
                if int(np.abs(rgb[nr, nc] - ref).max()) <= tolerance:
                    visited[nr, nc] = True
                    queue.append((nr, nc))
    return result


def crop_to_content(arr: np.ndarray, pad: int = 4) -> np.ndarray:
    alpha = arr[:, :, 3]
    rows = np.any(alpha > 10, axis=1)
    cols = np.any(alpha > 10, axis=0)
    if not rows.any():
        return arr
    r0, r1 = np.where(rows)[0][[0, -1]]
    c0, c1 = np.where(cols)[0][[0, -1]]
    h, w = arr.shape[:2]
    return arr[max(0,r0-pad):min(h,r1+pad+1), max(0,c0-pad):min(w,c1+pad+1)]


def pad_to_square(arr: np.ndarray, size: int) -> np.ndarray:
    h, w = arr.shape[:2]
    scale = min(size/w, size/h)
    nw, nh = int(w*scale), int(h*scale)
    pil = Image.fromarray(arr, "RGBA").resize((nw, nh), Image.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0,0,0,0))
    canvas.paste(pil, ((size-nw)//2, (size-nh)//2))
    return np.array(canvas)


def process_sprite(path: str):
    """Remove bg + crop + pad to 1024x1024. For mons and NPC fronts."""
    arr = np.array(Image.open(path).convert("RGBA"))
    arr = flood_fill_bg(arr, tolerance=55)
    arr = crop_to_content(arr)
    arr = pad_to_square(arr, 1024)
    Image.fromarray(arr, "RGBA").save(path)
    print(f"  [sprite 1024x1024] {os.path.basename(path)}")


def process_walk_sheet(path: str, out_path: str = None):
    """Remove bg + resize to 144x192. For walk sheets and NPC standing poses."""
    arr = np.array(Image.open(path).convert("RGBA"))
    arr = flood_fill_bg(arr, tolerance=55)
    pil = Image.fromarray(arr, "RGBA").resize((144, 192), Image.LANCZOS)
    pil.save(out_path or path)
    print(f"  [walk 144x192]   {os.path.basename(out_path or path)}")


def process_background(fname: str, out_name: str):
    src = os.path.join(SPRITES_DIR, fname)
    img = Image.open(src).convert("RGB").resize((960, 640), Image.LANCZOS)
    dst = os.path.join(BG_DIR, out_name)
    img.save(dst)
    print(f"  [bg 960x640]     {out_name}  -> backgrounds/")


def is_walk_sheet(fname: str) -> bool:
    return "_walk_sheet" in fname or "行走图" in fname


def main():
    print("=== Batch sprite processor ===\n")

    for fname in sorted(os.listdir(SPRITES_DIR)):
        if not fname.endswith(".png"):
            continue
        if fname + ".import" in os.listdir(SPRITES_DIR):
            continue  # already imported by Godot, skip

        path = os.path.join(SPRITES_DIR, fname)

        # Backgrounds
        if fname in BACKGROUNDS:
            process_background(fname, BACKGROUNDS[fname])
            continue

        # Walk sheets (by name)
        if is_walk_sheet(fname):
            process_walk_sheet(path)
            continue

        # NPC single standing images (tall format, treat as walk sheet)
        if fname in SINGLE_NPC:
            process_walk_sheet(path)
            continue

        # Everything else = sprite (mon front/back, gym leaders, NPC fronts)
        process_sprite(path)

    # Create alias for home_scene.gd
    src = os.path.join(SPRITES_DIR, "漂亮姐姐.png")
    dst = os.path.join(SPRITES_DIR, "npc_young_woman_walk_sheet.png")
    if os.path.exists(src) and not os.path.exists(dst):
        shutil.copy2(src, dst)
        print(f"  [alias] npc_young_woman_walk_sheet.png <- 漂亮姐姐.png")

    print("\nDone.")


if __name__ == "__main__":
    main()
