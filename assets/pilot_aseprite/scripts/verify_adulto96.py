"""Verify adulto96 output: 10 PNGs + spritesheet, dimensions, palette, alpha."""
import sys
from pathlib import Path
from PIL import Image

WORK = Path(__file__).parent.parent / "work"
SHEET = Path(__file__).parent.parent / "adulto96_sheet.png"
SHEET_JSON = Path(__file__).parent.parent / "adulto96_sheet.json"
CANVAS_W, CANVAS_H = 64, 100
MAX_COLORS = 28  # pasada-2 palette: 5 skin + 4 hair + 5 jersey + 3 cream + 4 denim + 4 boots + 3 outline
IDLE_H_MIN, IDLE_H_MAX = 93, 100   # idle frames typically 96px
WALK_H_MIN, WALK_H_MAX = 88, 100   # walk frames slightly shorter

# Skin shadow/mid colors that must NOT appear in the jersey chest (snowflake) area.
# These were the contamination fixed in pasada-2.
SKIN_CONTAMINATION = {
    (158, 101, 83),  # #9E6553  skin deep-shadow
    (201, 143, 115), # #C98F73  skin mid-shadow
}

errors = []

# 1. All 10 source PNGs exist
for i in range(1, 11):
    p = WORK / f"frame_{i:02d}.png"
    if not p.exists():
        errors.append(f"MISSING {p.name}")

# 2. Spritesheet files exist
for p in [SHEET, SHEET_JSON]:
    if not p.exists():
        errors.append(f"MISSING {p.name}")

# 3. Per-frame checks on source PNGs
all_colors = set()
for i in range(1, 11):
    p = WORK / f"frame_{i:02d}.png"
    if not p.exists():
        continue
    img = Image.open(p).convert("RGBA")
    w, h = img.size
    if w != CANVAS_W or h != CANVAS_H:
        errors.append(f"frame_{i:02d}.png size {w}x{h} != {CANVAS_W}x{CANVAS_H}")
    pix = list(img.getdata())
    # alpha strictly 0 or 255
    bad_alpha = [px for px in pix if px[3] not in (0, 255)]
    if bad_alpha:
        errors.append(f"frame_{i:02d}.png has {len(bad_alpha)} semi-transparent pixels")
    # collect opaque colors
    opaque = set((r, g, b) for r, g, b, a in pix if a == 255)
    all_colors |= opaque
    # orphan pixels: opaque with all 4 cardinal neighbors transparent
    alpha_grid = [[img.getpixel((x, y))[3] for x in range(w)] for y in range(h)]
    orphans = []
    for y in range(h):
        for x in range(w):
            if alpha_grid[y][x] == 255:
                neighbors = [
                    alpha_grid[y-1][x] if y > 0 else 0,
                    alpha_grid[y+1][x] if y < h-1 else 0,
                    alpha_grid[y][x-1] if x > 0 else 0,
                    alpha_grid[y][x+1] if x < w-1 else 0,
                ]
                if all(n == 0 for n in neighbors):
                    orphans.append((x, y))
    if orphans:
        errors.append(f"frame_{i:02d}.png has {len(orphans)} orphan pixels (isolated opaque): {orphans[:5]}")
    # skin shadow/mid must not appear in jersey chest (snowflake) area x=18-44, y=38-57
    # (cols 45+ excluded: arm pixels legitimately overlap the right jersey edge)
    contamination_in_jersey = []
    for cy in range(38, 58):
        for cx in range(18, 45):
            r2, g2, b2, a2 = img.getpixel((cx, cy))
            if a2 == 255 and (r2, g2, b2) in SKIN_CONTAMINATION:
                contamination_in_jersey.append((cx, cy, f"#{r2:02X}{g2:02X}{b2:02X}"))
    if contamination_in_jersey:
        errors.append(f"frame_{i:02d}.png skin contamination in jersey chest: {len(contamination_in_jersey)} px, e.g. {contamination_in_jersey[:3]}")
    # measure content bbox height
    xs = [x for x in range(w) for y in range(h) if img.getpixel((x, y))[3] == 255]
    ys = [y for x in range(w) for y in range(h) if img.getpixel((x, y))[3] == 255]
    if ys:
        bbox_h = max(ys) - min(ys) + 1
        expected_min = IDLE_H_MIN if i <= 4 else WALK_H_MIN
        expected_max = IDLE_H_MAX if i <= 4 else WALK_H_MAX
        if not (expected_min <= bbox_h <= expected_max):
            errors.append(f"frame_{i:02d}.png bbox_h={bbox_h} outside [{expected_min},{expected_max}]")

# 4. Palette size across all frames
if len(all_colors) > MAX_COLORS:
    errors.append(f"total palette {len(all_colors)} colors > {MAX_COLORS}")

# 5. Spritesheet dimensions
if SHEET.exists():
    sheet = Image.open(SHEET)
    sw, sh = sheet.size
    expected_w = CANVAS_W * 10
    if sw != expected_w or sh != CANVAS_H:
        errors.append(f"sheet size {sw}x{sh} != {expected_w}x{CANVAS_H}")

if errors:
    print("FAIL")
    for e in errors:
        print(" ", e)
    sys.exit(1)
else:
    print(f"OK - 10 frames, palette={len(all_colors)} colors, sheet={CANVAS_W*10}x{CANVAS_H}")
