#!/usr/bin/env python3
"""
preprocess_ref.py
Preprocesses personaje_ref.png into 10 pixel-art frames at 96px target height.

Outputs:
  work/frame_01.png ... frame_10.png  — RGBA, hard alpha, shared palette
  work/palette.json                   — 32 RGB colors
  work/frame_data.json                — draw_rows data for Aseprite MCP

Usage:
  uv run --with pillow --with numpy assets/pilot_aseprite/scripts/preprocess_ref.py
"""
from pathlib import Path
import json
import numpy as np
from PIL import Image

SCRIPT_DIR = Path(__file__).parent
REF_PATH   = SCRIPT_DIR.parent / "ref" / "personaje_ref.png"
OUT_DIR    = SCRIPT_DIR.parent / "work"

CANVAS_W        = 64
CANVAS_H        = 100
FEET_Y          = CANVAS_H - 1  # y=99, feet at last row (0-indexed)
TARGET_IDLE_H   = 96
MAX_COLORS      = 32
ALPHA_DETECT    = 40    # threshold for detecting tight bbox (matches user measurements)
ALPHA_HARD      = 128   # threshold for binarizing alpha (0 or 255)

# Approximate search regions from user measurements (x0, y0, x1, y1)
# idle: 4 poses; walk: 6 poses
BBOXES = [
    # idle
    (200, 138, 328, 547),
    (437, 137, 571, 547),
    (676, 137, 809, 547),
    (912, 137, 1044, 547),
    # walk
    ( 60, 691, 194, 1090),
    (244, 691, 409, 1086),
    (450, 690, 593, 1088),
    (641, 690, 787, 1090),
    (838, 690, 988, 1090),
    (1055, 690, 1188, 1090),
]

FRAME_NAMES = [
    "idle_1", "idle_2", "idle_3", "idle_4",
    "walk_1", "walk_2", "walk_3", "walk_4", "walk_5", "walk_6",
]

# Characters used in draw_rows (32 total, '.' = transparent)
DRAW_CHARS = "0123456789abcdefghijklmnopqrstuv"


def tight_bbox(arr_rgba: np.ndarray, threshold: int):
    """Return (x0, y0, x1, y1) of non-transparent region, or None."""
    alpha = arr_rgba[:, :, 3]
    mask  = alpha > threshold
    if not mask.any():
        return None
    rows = np.where(np.any(mask, axis=1))[0]
    cols = np.where(np.any(mask, axis=0))[0]
    return int(cols[0]), int(rows[0]), int(cols[-1] + 1), int(rows[-1] + 1)


def nearest_color_indices(rgb_flat: np.ndarray, palette: np.ndarray) -> np.ndarray:
    """
    rgb_flat : (N, 3) uint8
    palette  : (K, 3) uint8
    returns  : (N,) int32 indices into palette
    """
    rf = rgb_flat.astype(np.float32)
    pf = palette.astype(np.float32)
    diff = rf[:, None, :] - pf[None, :, :]   # (N, K, 3)
    dist = (diff ** 2).sum(axis=-1)            # (N, K)
    return dist.argmin(axis=-1).astype(np.int32)


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    print(f"Loading {REF_PATH}")
    ref     = Image.open(REF_PATH).convert("RGBA")
    ref_arr = np.array(ref, dtype=np.uint8)
    print(f"Reference: {ref.width}x{ref.height}")

    # 1. Crop each pose tightly within its search region
    crops = []
    for i, (x0, y0, x1, y1) in enumerate(BBOXES):
        region = ref_arr[y0:y1, x0:x1]
        bbox   = tight_bbox(region, ALPHA_DETECT)
        if bbox is None:
            raise ValueError(f"Frame {i+1} ({FRAME_NAMES[i]}): no pixels in region {(x0,y0,x1,y1)}")
        cx0, cy0, cx1, cy1 = bbox
        crop = region[cy0:cy1, cx0:cx1]
        crops.append(crop)
        print(f"  F{i+1:02d} {FRAME_NAMES[i]:8s}: region {x1-x0}x{y1-y0}  tight {cx1-cx0}x{cy1-cy0}")

    # 2. Common scale: idle frames -> TARGET_IDLE_H px
    idle_heights = [crops[i].shape[0] for i in range(4)]
    avg_idle_h   = sum(idle_heights) / len(idle_heights)
    scale        = TARGET_IDLE_H / avg_idle_h
    print(f"\nIdle heights: {idle_heights}, avg={avg_idle_h:.1f}px -> scale={scale:.5f}")

    # 3. Scale all frames uniformly (BOX = area sampling) + hard alpha
    scaled_frames = []
    max_scaled_w  = 0
    for i, crop in enumerate(crops):
        h, w  = crop.shape[:2]
        new_w = max(1, round(w * scale))
        new_h = max(1, round(h * scale))
        pil_s = Image.fromarray(crop, "RGBA").resize((new_w, new_h), Image.BOX)
        arr_s = np.array(pil_s, dtype=np.uint8)
        # Hard alpha
        arr_s[:, :, 3] = np.where(arr_s[:, :, 3] >= ALPHA_HARD, 255, 0)
        scaled_frames.append(arr_s)
        max_scaled_w = max(max_scaled_w, new_w)
        print(f"  F{i+1:02d}: {w}x{h} -> {new_w}x{new_h}")

    # Canvas width: at least CANVAS_W, enough for widest frame + 2px each side
    canvas_w = max(CANVAS_W, max_scaled_w + 4)
    if canvas_w % 2 != 0:
        canvas_w += 1
    print(f"\nCanvas: {canvas_w}x{CANVAS_H}  (feet at y={FEET_Y})")

    # 4. Place frames on canvas (feet-aligned, horizontally centered)
    canvases       = []
    all_opaque_rgb = []
    placements     = []
    for i, arr_s in enumerate(scaled_frames):
        nh, nw = arr_s.shape[:2]
        canvas  = np.zeros((CANVAS_H, canvas_w, 4), dtype=np.uint8)
        y_start = FEET_Y - nh + 1          # feet at last row
        y_start = max(0, y_start)
        x_start = (canvas_w - nw) // 2    # centered horizontally
        canvas[y_start:y_start+nh, x_start:x_start+nw] = arr_s
        canvases.append(canvas)
        placements.append((y_start, x_start, nw, nh))

        alpha_mask = canvas[:, :, 3] > 0
        all_opaque_rgb.append(canvas[alpha_mask, :3])
        opaque_px = int(alpha_mask.sum())
        print(f"  F{i+1:02d}: nh={nh} y_start={y_start} x_start={x_start} opaque_px={opaque_px}")

    # 5. Compute shared palette from all opaque pixels (median cut)
    all_pix = np.vstack(all_opaque_rgb)
    print(f"\nTotal opaque pixels (all frames): {len(all_pix)}")
    rng  = np.random.default_rng(42)
    n    = min(len(all_pix), 100_000)
    samp = all_pix[rng.choice(len(all_pix), n, replace=False)]
    combined_img = Image.fromarray(samp.reshape(1, n, 3), "RGB")
    q_img   = combined_img.quantize(
        colors=MAX_COLORS,
        method=Image.Quantize.MEDIANCUT,
        dither=Image.Dither.NONE,
    )
    raw_pal = q_img.getpalette()   # 256x3 flattened
    palette = np.array(
        [[raw_pal[j*3], raw_pal[j*3+1], raw_pal[j*3+2]] for j in range(MAX_COLORS)],
        dtype=np.uint8,
    )
    print(f"Palette: {MAX_COLORS} colors derived. First 4: {palette[:4].tolist()}")

    # Build draw_rows color mapping
    assert len(DRAW_CHARS) >= MAX_COLORS, "Not enough draw characters"
    idx_to_char   = {j: DRAW_CHARS[j] for j in range(MAX_COLORS)}
    color_to_char = {tuple(palette[j].tolist()): DRAW_CHARS[j] for j in range(MAX_COLORS)}

    # 6. Quantize each frame with shared palette + save PNGs
    frame_data_list = []
    for i, canvas in enumerate(canvases):
        alpha = canvas[:, :, 3]
        rgb   = canvas[:, :, :3].reshape(-1, 3)

        indices   = nearest_color_indices(rgb, palette)
        quant_rgb = palette[indices].reshape(CANVAS_H, canvas_w, 3)

        result = np.zeros((CANVAS_H, canvas_w, 4), dtype=np.uint8)
        result[:, :, :3] = quant_rgb
        result[:, :, 3]  = alpha   # restore hard alpha

        # Save PNG
        out_path = OUT_DIR / f"frame_{i+1:02d}.png"
        Image.fromarray(result, "RGBA").save(out_path)

        # Build draw_rows data (row strings + transparent as '.')
        rows = []
        for y in range(CANVAS_H):
            row_chars = []
            for x in range(canvas_w):
                if alpha[y, x] == 0:
                    row_chars.append(".")
                else:
                    r, g, b = int(result[y, x, 0]), int(result[y, x, 1]), int(result[y, x, 2])
                    row_chars.append(color_to_char[(r, g, b)])
            rows.append("".join(row_chars))
        frame_data_list.append(rows)

        n_colors_used = len(set(map(tuple, quant_rgb[alpha > 0].tolist())))
        print(f"  F{i+1:02d}: {out_path.name}  colors_used={n_colors_used}")

    # 7. Write palette.json
    palette_json = []
    for j in range(MAX_COLORS):
        r, g, b = int(palette[j, 0]), int(palette[j, 1]), int(palette[j, 2])
        palette_json.append({
            "index": j,
            "char":  DRAW_CHARS[j],
            "hex":   f"#{r:02X}{g:02X}{b:02X}",
            "rgb":   [r, g, b],
        })
    with open(OUT_DIR / "palette.json", "w") as f:
        json.dump(palette_json, f, indent=2)

    # 8. Write frame_data.json
    colors_dict = {
        DRAW_CHARS[j]: f"#{int(palette[j,0]):02X}{int(palette[j,1]):02X}{int(palette[j,2]):02X}"
        for j in range(MAX_COLORS)
    }
    frame_data_json = {
        "canvas_w": canvas_w,
        "canvas_h": CANVAS_H,
        "scale":    round(float(scale), 6),
        "max_colors": MAX_COLORS,
        "transparent_char": ".",
        "colors": colors_dict,
        "frames": frame_data_list,
        "frame_names": FRAME_NAMES,
        "placements": [
            {"y_start": int(p[0]), "x_start": int(p[1]), "w": int(p[2]), "h": int(p[3])}
            for p in placements
        ],
    }
    with open(OUT_DIR / "frame_data.json", "w") as f:
        json.dump(frame_data_json, f)

    # Summary
    print(f"\n--- Summary ---")
    print(f"Canvas size  : {canvas_w}x{CANVAS_H}px")
    print(f"Scale factor : {scale:.5f}  (idle avg {avg_idle_h:.1f}px -> 96px)")
    print(f"Palette      : {MAX_COLORS} colors (shared, no dithering)")
    print(f"Output dir   : {OUT_DIR}")
    print(f"Frames saved : {len(frame_data_list)}")
    for j, entry in enumerate(palette_json):
        print(f"  idx={j:2d} char={entry['char']} {entry['hex']}")


if __name__ == "__main__":
    main()
