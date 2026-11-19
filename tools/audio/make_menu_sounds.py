r"""Makes the menus' sounds (Projeto/assets/audio/ui/) from their public domain (CC0) sources.

Each sound is cut at its attack, faded out, filtered and brought to its event's loudness, so the
mix lives in the files and every player in menu_feedback.tscn stays at 0 dB. The loudness is the
loudest 50 ms of RMS, in dBFS; no peak goes above -1 dBFS. The targets keep the click of a move
about 9 dB under the blow of a choice, so moving through a list never covers the choice.

The sources are not in the repository: download them (README, section Créditos) into one folder,
with the layout of SOURCES below. From the repository root, set up a virtual environment once
(Windows; elsewhere the activate script is .venv/bin/activate):

    python -m venv .venv
    .venv\Scripts\activate
    python -m pip install -r tools/audio/requirements.txt

and, with it active, run:

    python tools/audio/make_menu_sounds.py <sources folder> Projeto/assets/audio/ui

The Freesound sources are the site's previews (OGG); the WAV originals need an account.
"""
import argparse
import math
from pathlib import Path

import numpy as np
import soundfile as sf

RATE = 44100
# No sample goes above this, in dBFS.
CEILING_DB = -1.0
# Each event's loudness, in dBFS (loudest 50 ms of RMS), at a player volume of 0 dB.
TARGETS: dict[str, float] = {"move": -27.0, "confirm": -18.0, "back": -22.0, "tick": -29.0,
                             "switch": -25.0, "refuse": -23.0}
# The window the loudness is measured over, in s.
LOUDNESS_WINDOW = 0.05
# How hard the low hit is driven into its soft clipping.
SATURATION = 3.0
# Where each source lies in the sources folder.
SOURCES: dict[str, str] = {
    "mouse": "click_mech/fs_223445_mouse_click_clean/223445_1482559-hq.ogg",
    "mouse2": "click_mech/fs_534103_mouse_click_single/534103_11830391-hq.ogg",
    "mouse3": "click_mech/fs_687107_mouse_right_fast_click/687107_11545182-hq.ogg",
    "torch": "click_mech/fs_457463_flashlight_click_on/457463_4921277-hq.ogg",
    "kick": "kick_low/fs_418725_mute_bass_drum/418725_7844747-hq.ogg",
    "kenney_mouse": "click_ui/oga_kenney_ui_sfx_set/extracted/mouseclick1.wav",
    "kenney_tick": "click_ui/oga_kenney_interface_sounds/extracted/Audio/tick_001.ogg",
}


def load(sources: Path, name: str) -> np.ndarray:
    """The source in mono, without its DC offset, at RATE."""
    data, rate = sf.read(sources / SOURCES[name], dtype="float32", always_2d=True)
    x = data.mean(axis=1)
    x = x - x.mean()
    if rate != RATE:
        t = np.arange(int(len(x) * RATE / rate)) * rate / RATE
        x = np.interp(t, np.arange(len(x)), x).astype(np.float32)
    return x.astype(np.float32)


def attack(x: np.ndarray, threshold_db: float = -30.0) -> np.ndarray:
    """x from 1 ms before it first rises above threshold_db under its peak."""
    threshold = np.abs(x).max() * 10 ** (threshold_db / 20)
    start = int(np.argmax(np.abs(x) > threshold))
    return x[max(0, start - RATE // 1000):]


def crop(x: np.ndarray, ms: float, fade_ms: float) -> np.ndarray:
    """The first ms of x, with an exponential fade over its last fade_ms and a 0.5 ms fade in."""
    n = min(len(x), int(RATE * ms / 1000))
    y = x[:n].copy()
    fade = min(n, int(RATE * fade_ms / 1000))
    if fade > 0:
        y[-fade:] *= np.exp(-5.0 * np.linspace(0, 1, fade)).astype(np.float32)
    fade_in = min(n, int(RATE * 0.0005))
    y[:fade_in] *= np.linspace(0, 1, fade_in, dtype=np.float32)
    return y


def biquad(x: np.ndarray, kind: str, freq: float, q: float = 0.707) -> np.ndarray:
    """A second order high pass ("hp") or low pass ("lp") filter (RBJ's cookbook)."""
    w = 2 * math.pi * freq / RATE
    a = math.sin(w) / (2 * q)
    c = math.cos(w)
    if kind == "hp":
        b0, b1, b2 = (1 + c) / 2, -(1 + c), (1 + c) / 2
    else:
        b0, b1, b2 = (1 - c) / 2, 1 - c, (1 - c) / 2
    a0, a1, a2 = 1 + a, -2 * c, 1 - a
    b0, b1, b2, a1, a2 = b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0
    y = np.zeros_like(x)
    x1 = x2 = y1 = y2 = 0.0
    for i, v in enumerate(x.tolist()):
        o = b0 * v + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
        x2, x1, y2, y1 = x1, v, y1, o
        y[i] = o
    return y


def pitch(x: np.ndarray, factor: float) -> np.ndarray:
    """x played factor times as fast: above 1 higher and shorter, below 1 lower and longer."""
    t = np.arange(0, len(x) - 1, factor)
    return np.interp(t, np.arange(len(x)), x).astype(np.float32)


def mix(layers: list[tuple[np.ndarray, float, float]]) -> np.ndarray:
    """The layers summed; each is (signal, offset in ms, gain in dB)."""
    n = max(int(RATE * offset / 1000) + len(x) for x, offset, _ in layers)
    y = np.zeros(n, dtype=np.float32)
    for x, offset, gain_db in layers:
        start = int(RATE * offset / 1000)
        y[start:start + len(x)] += x * 10 ** (gain_db / 20)
    return y


def loudness(x: np.ndarray) -> float:
    """The loudest LOUDNESS_WINDOW of RMS, in dBFS, in steps of a quarter window."""
    window = int(LOUDNESS_WINDOW * RATE)
    if len(x) <= window:
        return 20 * math.log10(max(1e-9, float(np.sqrt(np.mean(x ** 2)))))
    best = max(float(np.sqrt(np.mean(x[i:i + window] ** 2)))
               for i in range(0, len(x) - window, window // 4))
    return 20 * math.log10(max(1e-9, best))


def click(sources: Path, name: str, ms: float, hp: float, fade: float,
          factor: float = 1.0) -> np.ndarray:
    """A click: cut at its attack, maybe pitched, cropped and high passed."""
    x = attack(load(sources, name))
    if factor != 1.0:
        x = pitch(x, factor)
    x = crop(x, ms, fade)
    return biquad(x, "hp", hp)


def low(sources: Path, name: str, ms: float, lp: float = 1800.0, fade: float = 60.0,
        factor: float = 1.0) -> np.ndarray:
    """A low hit, softly saturated so it gains the harmonics a laptop's speakers can play: below
    about 100 Hz they play almost nothing."""
    x = attack(load(sources, name))
    if factor != 1.0:
        x = pitch(x, factor)
    x = crop(x, ms, fade)
    x = biquad(x, "hp", 35.0)
    x = x / max(1e-9, float(np.abs(x).max()))
    x = (np.tanh(SATURATION * x) / math.tanh(SATURATION)).astype(np.float32)
    return biquad(x, "lp", lp)


def to_target(x: np.ndarray, target_db: float) -> np.ndarray:
    """x at target_db of loudness, unless that would take its peak over the ceiling."""
    gain = 10 ** ((target_db - loudness(x)) / 20)
    ceiling = 10 ** (CEILING_DB / 20) / max(1e-9, float(np.abs(x).max()))
    return (x * min(gain, ceiling)).astype(np.float32)


def sounds(sources: Path) -> dict[str, list[np.ndarray]]:
    """Each event's variants. Those of one event come from one family of sound, mouse clicks for
    the moves, so they read as the same event. The refusal is the way back's thud twice, the second
    lower, a «no» told from the way back by the count of its hits."""
    def mouse(name: str) -> np.ndarray:
        return click(sources, name, 60, hp=400.0, fade=25.0)

    def thud(click_factor: float, kick_factor: float) -> np.ndarray:
        return mix([(click(sources, "mouse", 70, hp=300.0, fade=30.0, factor=click_factor), 0, 0),
                    (low(sources, "kick", 140, lp=900.0, factor=kick_factor), 0, -9)])

    return {
        "move": [mouse("mouse"), mouse("mouse2"), mouse("mouse3"), mouse("kenney_mouse")],
        "confirm": [
            mix([(click(sources, "mouse", 70, hp=400.0, fade=30.0), 0, -1),
                 (low(sources, "kick", 170), 0, 0)]),
            mix([(click(sources, "mouse2", 70, hp=400.0, fade=30.0), 0, -1),
                 (low(sources, "kick", 190, factor=0.97), 0, 0)]),
        ],
        "back": [thud(0.8, 0.85)],
        "tick": [click(sources, "kenney_tick", 30, hp=1000.0, fade=10.0)],
        "switch": [click(sources, "torch", 190, hp=400.0, fade=40.0)],
        "refuse": [mix([(thud(0.8, 0.85), 0, 0), (thud(0.68, 0.72), 90, -2)])],
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Makes the menus' sounds from their sources.")
    parser.add_argument("sources", type=Path, help="the folder with the downloaded sources")
    parser.add_argument("out", type=Path, help="where the WAV files go")
    args = parser.parse_args()
    args.out.mkdir(parents=True, exist_ok=True)
    for event, variants in sounds(args.sources).items():
        variants = [to_target(x, TARGETS[event]) for x in variants]
        for index, x in enumerate(variants):
            # The move, the choice and the way back are random sets, numbered; the others are one.
            suffix = "_%d" % (index + 1) if event in ("move", "confirm", "back") else ""
            sf.write(args.out / ("menu_%s%s.wav" % (event, suffix)), x, RATE, subtype="PCM_16")
        levels = ", ".join("%.1f" % loudness(x) for x in variants)
        print("%s: loudness %s dBFS (target %.1f)" % (event, levels, TARGETS[event]))


if __name__ == "__main__":
    main()
