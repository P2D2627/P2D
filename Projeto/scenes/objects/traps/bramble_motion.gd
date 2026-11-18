extends RefCounted

## The rules of how a bramble of lethal spikes moves (#263), with no scene, so the tests run them
## alone. A bramble moves only by its top sliding along its strip while its base stays put, as a
## drawing tilted from its foot: the sway at rest, the shiver when the man comes at it, and the
## thrash and the lean in when he dies on the spikes add up to how far the top slides. Time is held
## to the frame of the effects, so a bramble keeps its pose for a frame, as a hand-drawn one does.
## The values are in Stats.

const BrambleMotionStats := preload("res://scenes/objects/traps/bramble_motion_stats.gd")

## How many values the shiver's chance picks from.
const CHANCE_STEPS: int = 1000
## The thrash's smallest swing, as a share of its size, so no frame stands still.
const SMALLEST_SWING: float = 0.6
## Added to a time in frames of the effects before rounding it down, against a summed clock's error.
const FRAME_NUDGE: float = 0.0001

var stats: BrambleMotionStats


func _init(with: BrambleMotionStats) -> void:
	stats = with


## The transform that draws a bramble from Middle, the middle of its foot, Height tall, mirrored or
## not, with its top slid Offset px along the strip: its foot stays put and its top moves Offset.
static func tilt(middle: Vector2, height: float, mirrored: bool, offset: float) -> Transform2D:
	var slant: float = -offset / height if height > 0.0 else 0.0
	return Transform2D(Vector2(-1.0 if mirrored else 1.0, 0.0), Vector2(slant, 1.0), middle)


## Which frame of the effects Time falls in. A clock summed from 60 fps deltas lands a hair under a
## frame's start now and then: Frame Nudge keeps it on that frame, so every drawing is held as long.
func frame_of(time: float) -> int:
	return floori(time * stats.frame_rate + FRAME_NUDGE)


## Time held to the start of its frame of the effects.
func held(time: float) -> float:
	return frame_of(time) / stats.frame_rate


## How far a bramble's top sways at rest at Time, swaying once every Period seconds, from Start (0
## to 1) of its sway.
func sway(time: float, period: float, start: float) -> float:
	if period <= 0.0:
		return 0.0
	return stats.sway_amplitude * sin(TAU * (held(time) / period + start))


## How much the man stirs a bramble whose top is at Top, from 0 to 1: only while he comes at it
## within Stir Radius of his Body, the more the nearer and the faster, up to Stir Speed. Going away,
## passing it by or standing still stirs nothing. Top, Body and Velocity in the same space.
func stir_target(top: Vector2, body: Rect2, velocity: Vector2) -> float:
	var distance: float = top.distance_to(top.clamp(body.position, body.end))
	if distance >= stats.stir_radius:
		return 0.0
	var towards: Vector2 = (top - body.get_center()).normalized()
	var coming: float = clampf(velocity.dot(towards) / stats.stir_speed, 0.0, 1.0)
	return coming * (1.0 - distance / stats.stir_radius)


## A bramble's stir after Delta seconds, from Stir: up to Target at once, or else fading by Stir Fade.
func stir_after(stir: float, target: float, delta: float) -> float:
	return maxf(target, stir * exp(-delta / stats.stir_fade))


## How far the top of bramble Index shivers at Time with Stir: to a side and by an amount picked at
## random each frame of the effects.
func shiver(stir: float, index: int, time: float) -> float:
	if stir <= 0.0:
		return 0.0
	return stats.stir_amplitude * stir * (2.0 * _chance(index, frame_of(time)) - 1.0)


## How far the top of bramble Index, with its foot at Base, thrashes Since seconds after the man died
## on spikes at Death: the nearer, the sooner and the harder, side to side each frame of the effects,
## dying down by Thrash Fade; nothing beyond Thrash Radius, nor before its start. Base and Death in
## the strip's space.
func thrash(base: Vector2, death: Vector2, since: float, index: int) -> float:
	var share: float = _share_of_death(base, death)
	var after: float = held(since) - _start_after_death(share)
	if share <= 0.0 or after < 0.0:
		return 0.0
	var frame: int = frame_of(since)
	var side: float = 1.0 if frame % 2 == 0 else -1.0
	var swing: float = lerpf(SMALLEST_SWING, 1.0, _chance(index, frame))
	return stats.thrash_amplitude * share * exp(-after / stats.thrash_fade) * side * swing


## How far the top of a bramble with its foot at Base leans in towards where the man died on spikes,
## at Death, Since seconds after: from the thrash's start, over Lean Time, then it stays. Brambles
## beside him lean fully, those under him barely; nothing beyond Thrash Radius.
func lean(base: Vector2, death: Vector2, since: float) -> float:
	var share: float = _share_of_death(base, death)
	var after: float = held(since) - _start_after_death(share)
	if share <= 0.0 or after < 0.0:
		return 0.0
	var towards: float = clampf((death.x - base.x) / stats.lean_reach, -1.0, 1.0)
	return stats.lean_amplitude * share * towards * smoothstep(0.0, stats.lean_time, after)


## How much of the death's reach a bramble at Base gets: 1 where he died, 0 at Thrash Radius.
func _share_of_death(base: Vector2, death: Vector2) -> float:
	if stats.thrash_radius <= 0.0:
		return 0.0
	return maxf(1.0 - base.distance_to(death) / stats.thrash_radius, 0.0)


## When a bramble with Share of the death's reach starts, after his death: the nearest at Thrash
## Delay, the farthest Thrash Spread later.
func _start_after_death(share: float) -> float:
	return stats.thrash_delay + stats.thrash_spread * (1.0 - share)


## A chance from 0 to 1 that is the same for the same bramble on the same frame.
func _chance(index: int, frame: int) -> float:
	return float(posmod(hash(Vector2i(index, frame)), CHANCE_STEPS)) / CHANCE_STEPS
