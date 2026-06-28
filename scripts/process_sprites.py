#!/usr/bin/env python3
"""Process all new spirit sprites to 512x512 centered PNG with transparent background."""

from PIL import Image
import os, sys

SPRITES_DIR = r"F:\Pokemon\RedMon\assets\sprites"
OUTPUT_DIR = r"F:\Pokemon\RedMon\assets\sprites"
TARGET = 512

def find_content_bbox(img, bg_color, tolerance=30):
    """Find bounding box of content pixels (non-background)."""
    w, h = img.size
    pixels = img.load()
    
    def is_bg(r, g, b, a=255):
        return abs(r - bg_color[0]) <= tolerance and abs(g - bg_color[1]) <= tolerance and abs(b - bg_color[2]) <= tolerance
    
    xs, ys = [], []
    for y in range(h):
        for x in range(w):
            if img.mode == 'RGBA':
                r, g, b, a = pixels[x, y]
                if a < 128:
                    continue  # skip already transparent
            else:
                r, g, b = pixels[x, y]
            if not is_bg(r, g, b):
                xs.append(x)
                ys.append(y)
    
    if not xs or not ys:
        return None
    return (min(xs), min(ys), max(xs), max(ys))

def get_edge_bg_color(img):
    """Sample edge pixels to find background color."""
    w, h = img.size
    pixels = img.load()
    
    # Collect edge pixels
    edge_colors = []
    for x in range(w):
        for y in [0, h-1]:
            if img.mode == 'RGBA':
                edge_colors.append(pixels[x, y][:3])
            else:
                edge_colors.append(pixels[x, y])
    for y in range(1, h-1):
        for x in [0, w-1]:
            if img.mode == 'RGBA':
                edge_colors.append(pixels[x, y][:3])
            else:
                edge_colors.append(pixels[x, y])
    
    # Remove outliers and average
    r_sum, g_sum, b_sum = 0, 0, 0
    n = 0
    for r, g, b in edge_colors:
        # Skip pure black outliers (content touching edge)
        if r + g + b < 100:
            continue
        r_sum += r
        g_sum += g
        b_sum += b
        n += 1
    
    if n == 0:
        return (255, 255, 255)
    
    return (r_sum // n, g_sum // n, b_sum // n)

def process_image(source_path, name, output_path):
    """Process a single sprite image."""
    print(f"\n{'='*60}")
    print(f"Processing: {name}")
    print(f"Source: {source_path}")
    
    if not os.path.exists(source_path):
        print(f"  ERROR: Source not found: {source_path}")
        return False
    
    # Check if already good
    if os.path.exists(output_path):
        img = Image.open(output_path)
        if img.mode == 'RGBA' and img.size == (TARGET, TARGET):
            # Check if it has actual transparency
            alpha = img.split()[3]
            ext = alpha.getextrema()
            if ext != (255, 255):  # has some transparency
                print(f"  SKIP: Already processed with transparency")
                return False
    
    # Open source image
    img = Image.open(source_path)
    src_mode = img.mode
    src_size = img.size
    print(f"  Source: {src_mode} {src_size}")
    
    # Convert to RGBA
    if img.mode != 'RGBA':
        img = img.convert('RGBA')
    
    # Detect background color
    bg = get_edge_bg_color(img)
    print(f"  Background detection: edge color = {bg}")
    
    # Find content bbox
    bbox = find_content_bbox(img, bg, tolerance=30)
    
    if bbox is None or (bbox[2] - bbox[0] < 10) or (bbox[3] - bbox[1] < 10):
        # If that fails, try more aggressive tolerance
        print(f"  BBox too small with tol=30, trying tol=50...")
        bbox = find_content_bbox(img, bg, tolerance=50)
    
    if bbox is None or (bbox[2] - bbox[0] < 10) or (bbox[3] - bbox[1] < 10):
        # If still fails, try with bg_color detection from histogram
        print(f"  BBox still too small: {bbox}")
        print(f"  Trying histogram-based background detection...")
        
        # Use most common edge color as background
        from collections import Counter
        w, h = img.size
        pixels = img.load()
        edge_colors = []
        for x in range(w):
            for y in [0, h-1]:
                r, g, b, a = pixels[x, y]
                if a > 128:
                    edge_colors.append(f"{r//20},{g//20},{b//20}")
        if edge_colors:
            most_common = Counter(edge_colors).most_common(1)[0][0]
            parts = [int(x) * 20 + 10 for x in most_common.split(',')]
            bg = tuple(parts)
            print(f"  Histogram bg: {bg}")
            bbox = find_content_bbox(img, bg, tolerance=40)
    
    if bbox is None or (bbox[2] - bbox[0] < 10) or (bbox[3] - bbox[1] < 10):
        print(f"  FAILED: Could not find content bounds")
        return False
    
    x1, y1, x2, y2 = bbox
    cw = x2 - x1 + 1
    ch = y2 - y1 + 1
    print(f"  Content bbox: ({x1},{y1})-({x2},{y2}) = {cw}x{ch}")
    
    # If already close to target, do minimal crop
    if max(cw, ch) >= TARGET * 0.95:
        # Just center and resize slightly
        crop = img
    else:
        # Crop to content with margin
        margin = 20
        x1c = max(0, x1 - margin)
        y1c = max(0, y1 - margin)
        x2c = min(img.width - 1, x2 + margin)
        y2c = min(img.height - 1, y2 + margin)
        crop = img.crop((x1c, y1c, x2c, y2c))
        print(f"  Cropped: ({x1c},{y1c})-({x2c},{y2c})")
    
    # Make background transparent
    pixels = crop.load()
    w, h = crop.size
    
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if a < 128:
                continue
            if abs(r - bg[0]) <= 25 and abs(g - bg[1]) <= 25 and abs(b - bg[2]) <= 25:
                pixels[x, y] = (r, g, b, 0)
    
    # Now find content bbox again (via alpha)
    alpha = crop.split()[3]
    xs, ys = [], []
    for y in range(h):
        for x in range(w):
            if alpha.getpixel((x, y)) > 0:
                xs.append(x)
                ys.append(y)
    
    if not xs or not ys:
        print(f"  FAILED: No content after transparency")
        return False
    
    fx1, fx2 = min(xs), max(xs)
    fy1, fy2 = min(ys), max(ys)
    fw = fx2 - fx1 + 1
    fh = fy2 - fy1 + 1
    print(f"  Content after transparency: ({fx1},{fy1})-({fx2},{fy2}) = {fw}x{fh}")
    
    # Crop tight to content
    tight = crop.crop((fx1, fy1, fx2, fy2))
    
    # Resize to fit within TARGET while keeping aspect ratio
    tw, th = tight.size
    scale = min(TARGET * 0.70 / tw, TARGET * 0.85 / th, 1.0)
    if scale < 1.0:
        tight = tight.resize((int(tw * scale), int(th * scale)), Image.NEAREST)
        print(f"  Resized to: {tight.size}")
    
    # Center in TARGETxTARGET canvas
    final = Image.new('RGBA', (TARGET, TARGET), (0, 0, 0, 0))
    fw, fh = tight.size
    paste_x = (TARGET - fw) // 2
    paste_y = (TARGET - fh) // 2
    final.paste(tight, (paste_x, paste_y), tight)
    
    print(f"  Final: placed at ({paste_x},{paste_y}) on {TARGET}x{TARGET}")
    
    # Save
    final.save(output_path, 'PNG')
    print(f"  Saved to: {output_path}")
    return True


def main():
    # All sprites to process: (source_name, display_name, output_name)
    sprites = [
        # PNG originals (from AI, now opaque white backgrounds)
        ('武徒弟_front.png', '武徒弟_front', '武徒弟_front.png'),
        ('武徒弟_back.png', '武徒弟_back', '武徒弟_back.png'),
        ('枪兵_front.png', '枪兵_front', '枪兵_front.png'),
        ('枪兵_back.png', '枪兵_back', '枪兵_back.png'),
        ('棍勇_front.png', '棍勇_front', '棍勇_front.png'),
        ('棍勇_back.png', '棍勇_back', '棍勇_back.png'),
        # JPG originals
        ('喷火露比_front.jpg', '喷火露比_front', '喷火露比_front.png'),
        ('喷火露比_back.jpg', '喷火露比_back', '喷火露比_back.png'),
        ('挖洞露比_front.jpg', '挖洞露比_front', '挖洞露比_front.png'),
        ('挖洞露比_back.jpg', '挖洞露比_back', '挖洞露比_back.png'),
    ]
    
    success = 0
    failed = 0
    skipped = 0
    
    for src, name, out in sprites:
        src_path = os.path.join(SPRITES_DIR, src)
        out_path = os.path.join(OUTPUT_DIR, out)
        result = process_image(src_path, name, out_path)
        if result is True:
            success += 1
        elif result is False:
            failed += 1
        else:
            skipped += 1
    
    print(f"\n{'='*60}")
    print(f"Done! {success} processed, {failed} failed, {skipped} skipped")

if __name__ == '__main__':
    main()
