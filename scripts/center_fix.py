#!/usr/bin/env python3
"""Fine-tune centering for sprites that are slightly off-center."""

from PIL import Image

SPRITES_DIR = r"F:\Pokemon\RedMon\assets\sprites"
TARGET = 512

adjustments = {
    '枪兵_front.png': {'h': 6, 'v': 0},       # shift LEFT by 6px (fix right bias)
    '武徒弟_front.png': {'h': 9, 'v': -5},     # shift LEFT by 9, DOWN by 5
    '喷火露比_front.png': {'h': 0, 'v': -8},   # shift DOWN by 8 (fix upward bias)
}

for name, adj in adjustments.items():
    path = f"{SPRITES_DIR}/{name}"
    img = Image.open(path)
    print(f"{name}: {img.size} {img.mode}")
    
    w, h = img.size
    # Create new transparent canvas
    result = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    
    # Paste with offset
    dx, dy = adj['h'], adj['v']
    result.paste(img, (dx, dy), img)
    result.save(path, 'PNG')
    print(f"  Shifted: h={dx:+d}, v={dy:+d}")

print("\nDone!")
