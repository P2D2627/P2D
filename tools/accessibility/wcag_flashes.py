r"""Checks recorded frames against the WCAG 2.2 general flash and red flash thresholds.

Definition: https://www.w3.org/TR/WCAG22/#dfn-general-flash-and-red-flash-thresholds

- General flash: a transition is a change of 0.1 or more of relative luminance from the last
  extreme, with the darker side below 0.8; a flash is two opposing transitions.
- Red flash: a transition is a change of more than 0.2 in CIE 1976 u'v' chromaticity from the
  last state, with one of the two states a saturated red, R / (R + G + B) >= 0.8. The definition
  does not say whether R, G and B are linear; this tool takes them linear, the stricter choice
  (more pixels count as saturated red), and gives black, which has no chromaticity, the D65 white
  point (also the stricter choice).

A pixel fails with more than 3 flashes, so more than 6 transitions, within any 1 s. The tool
reports the share of the screen that fails. The thresholds let flashes cover at most 25 % of a
10 degree field of view: 21 824 px of a 1024 x 768 screen, about 2.8 % of it (W3C technique G176,
https://www.w3.org/WAI/WCAG22/Techniques/general/G176). It samples every Step pixels.

Record the frames with Godot's Movie Maker at a fixed 60 fps, for example the main menu for 11 s:

    godot --path Projeto --write-movie <frames dir>/f.png --fixed-fps 60 --quit-after 660

then, from the repository root, with the virtual environment of tools/ active (see
tools/audio/make_menu_sounds.py) and tools/accessibility/requirements.txt installed:

    python tools/accessibility/wcag_flashes.py <frames dir> --first 60 --last 660

The first second is left out: the scene settles in it.
"""
import argparse
import glob
from pathlib import Path

import numpy as np
from PIL import Image

FPS = 60
# Relative luminance and the flashes' thresholds, from the WCAG 2.2 definitions.
LUMINANCE = np.array([0.2126, 0.7152, 0.0722], dtype=np.float32)
GENERAL_STEP = 0.1
DARK_SIDE_BELOW = 0.8
RED_SHARE = 0.8
RED_CHROMA_STEP = 0.2
# More than 3 flashes in 1 s: more than this many transitions.
MOST_TRANSITIONS = 6
# Linear sRGB to CIE XYZ (D65), and the D65 white point in u'v'.
TO_XYZ = np.array([[0.4124, 0.2126, 0.0193], [0.3576, 0.7152, 0.1192],
                   [0.1805, 0.0722, 0.9505]], dtype=np.float32)
WHITE_UV = np.array([0.1978, 0.4683], dtype=np.float32)
# The sRGB transfer function, as a table for 8-bit values.
_C = np.arange(256) / 255.0
LINEAR = np.where(_C <= 0.04045, _C / 12.92, ((_C + 0.055) / 1.055) ** 2.4).astype(np.float32)


def read_frame(path: str, step: int) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """Every step-th pixel of the frame: its relative luminance, its u'v' chromaticity and whether
    it is a saturated red."""
    rgb = LINEAR[np.asarray(Image.open(path).convert("RGB"))[::step, ::step]].reshape(-1, 3)
    luminance = rgb @ LUMINANCE
    xyz = rgb @ TO_XYZ
    denominator = xyz[:, 0] + 15 * xyz[:, 1] + 3 * xyz[:, 2]
    black = denominator <= 1e-6
    safe = np.where(black, 1.0, denominator)
    uv = np.stack([4 * xyz[:, 0] / safe, 9 * xyz[:, 1] / safe], axis=1)
    uv[black] = WHITE_UV
    total = rgb.sum(axis=1)
    red = (total > 1e-6) & (rgb[:, 0] >= RED_SHARE * total)
    return luminance, uv, red


def transitions(files: list[str], step: int) -> tuple[np.ndarray, np.ndarray]:
    """For each frame and sampled pixel, whether a general transition and a red one end there."""
    luminance, uv, red = read_frame(files[0], step)
    pixels = luminance.size
    low, high, reference = luminance.copy(), luminance.copy(), luminance.copy()
    direction = np.zeros(pixels, np.int8)
    reference_uv, reference_red = uv.copy(), red.copy()
    general = np.zeros((len(files), pixels), bool)
    reds = np.zeros((len(files), pixels), bool)
    for frame in range(1, len(files)):
        value, uv, red = read_frame(files[frame], step)
        undecided, rising, falling = direction == 0, direction == 1, direction == -1
        # Until the first transition, the extremes so far; then from the last extreme each way.
        low = np.where(undecided, np.minimum(low, value), low)
        high = np.where(undecided, np.maximum(high, value), high)
        first = undecided & (high - low >= GENERAL_STEP) & (low < DARK_SIDE_BELOW)
        higher = rising & (value > reference)
        down = rising & ~higher & (reference - value >= GENERAL_STEP) & (value < DARK_SIDE_BELOW)
        lower = falling & (value < reference)
        up = falling & ~lower & (value - reference >= GENERAL_STEP) & (reference < DARK_SIDE_BELOW)
        reference = np.where(first | higher | down | lower | up, value, reference)
        direction = np.where(first, np.where(value == high, 1, -1), direction).astype(np.int8)
        direction = np.where(down, -1, np.where(up, 1, direction)).astype(np.int8)
        general[frame] = first | down | up
        chroma_step = np.linalg.norm(uv - reference_uv, axis=1)
        red_moved = (chroma_step > RED_CHROMA_STEP) & (red | reference_red)
        reds[frame] = red_moved
        reference_uv = np.where(red_moved[:, None], uv, reference_uv)
        reference_red = np.where(red_moved, red, reference_red)
    return general, reds


def report(name: str, marks: np.ndarray) -> None:
    """The share of the screen with any transition, the share that fails, and the most
    transitions any pixel has within 1 s."""
    counts = np.cumsum(marks, axis=0, dtype=np.int32)
    in_a_second = counts[FPS:] - counts[:-FPS] if len(marks) > FPS else counts[-1:]
    most = in_a_second.max(axis=0)
    failing = most > MOST_TRANSITIONS
    print(f"{name}: pixels with any transition {100 * marks.any(axis=0).mean():.3f} %;"
          f" more than 3 flashes in 1 s on {100 * failing.mean():.4f} % of the screen;"
          f" most transitions in 1 s at one pixel {int(most.max())}")


def main() -> None:
    parser = argparse.ArgumentParser(description="WCAG 2.2 flash check on recorded frames.")
    parser.add_argument("frames", type=Path, help="the folder of Movie Maker's f*.png frames")
    parser.add_argument("--first", type=int, default=0, help="the first frame to check")
    parser.add_argument("--last", type=int, default=None, help="the frame after the last one")
    parser.add_argument("--step", type=int, default=2, help="sample every step-th pixel")
    args = parser.parse_args()
    files = sorted(glob.glob(str(args.frames / "f*.png")))[args.first:args.last]
    if len(files) < 2:
        parser.error("fewer than 2 frames in that range")
    general, reds = transitions(files, args.step)
    print(f"frames {len(files)}, sampled pixels {general.shape[1]} (every {args.step} px)")
    report("general flashes", general)
    report("red flashes", reds)


if __name__ == "__main__":
    main()
