extends RefCounted

## The dark of a restart (#263) over time, with no scene, so the tests run it alone. As a fade: the
## screen darkens smoothly and is all dark for the last frame of the effects, so the new copy takes
## the old one's place on black, and the new copy's screen lightens from dark. As an iris: closing,
## its radius starts full and shrinks faster as it goes, and is 0 for that last frame; opening, it
## grows from 0 to full, fast at first, each value held to the frame of the effects. The values are
## in Stats.

const DeathIrisStats := preload("res://scenes/levels/death_iris_stats.gd")
## Added to a time in frames of the effects before rounding it down: a clock summed from 60 fps
## deltas lands a hair under a frame's start now and then.
const FRAME_NUDGE: float = 0.0001

var stats: DeathIrisStats


func _init(with: DeathIrisStats) -> void:
	stats = with


## Time held to the start of its frame of the effects.
func held(time: float) -> float:
	return frame_of(time) / stats.frame_rate


## The frame of the effects Time falls on, from 0. The small nudge keeps a time that lands on a
## frame, as 3 / 60 does on the frame of 0.05 at 20 fps, from falling into the one before.
func frame_of(time: float) -> int:
	return floori(time * stats.frame_rate + FRAME_NUDGE)


## The radius Into seconds into a close that lasts Close, from Full: 0 from its last frame on.
## Counted in whole frames, so that last frame is exactly 0.
func closing(into: float, close: float, full: float) -> float:
	var shrinking_frames: int = roundi(close * stats.frame_rate) - 1
	if shrinking_frames <= 0:
		return 0.0
	var share: float = clampf(float(frame_of(into)) / shrinking_frames, 0.0, 1.0)
	return full * (1.0 - share * share)


## How dark the screen is Into seconds into a fade out that lasts Close: from 0, faint at first and
## firmer as it goes (Fade Ease), to all dark from its last frame of the effects on.
func fading_out(into: float, close: float) -> float:
	var darkening: float = close - 1.0 / stats.frame_rate
	if darkening <= 0.0:
		return 1.0
	return pow(clampf(into / darkening, 0.0, 1.0), stats.fade_ease)


## How dark the screen is Since seconds into the fade in: from all dark to none over Open Time, most
## of it at once and the last of it slowly (Fade Ease).
func fading_in(since: float) -> float:
	return pow(1.0 - clampf(since / stats.open_time, 0.0, 1.0), stats.fade_ease)


## The radius Since seconds into the opening, up to Full.
func opening(since: float, full: float) -> float:
	var share: float = clampf(held(since) / stats.open_time, 0.0, 1.0)
	return full * (1.0 - (1.0 - share) * (1.0 - share))


## The radius that leaves a screen of Size clear around Centre: past its farthest corner by the
## wobble, so no ink is left in a corner.
func full_radius(centre: Vector2, size: Vector2) -> float:
	var farthest: float = maxf(maxf(centre.length(), centre.distance_to(Vector2(size.x, 0.0))),
			maxf(centre.distance_to(Vector2(0.0, size.y)), centre.distance_to(size)))
	return farthest + stats.wobble_px
