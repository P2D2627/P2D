extends RefCounted

## The man's pose as brambles kill him (#263), with no scene, so the tests run it alone. Time counts
## from the end of the freeze: over Buckle Time his knees give (he squashes and starts to tilt), and
## by Slump Time he has slumped (tilted further, a little less squashed, sunk) and stays. Each value
## is held to the frame of the effects, as a hand-drawn pose is. The values are in Stats.

const BrambleDeathStats := preload("res://scenes/characters/player/bramble_death_stats.gd")
## Added to a time in frames of the effects before rounding it down: a clock summed from 60 fps
## deltas lands a hair under a frame's start now and then.
const FRAME_NUDGE: float = 0.0001

var stats: BrambleDeathStats


func _init(with: BrambleDeathStats) -> void:
	stats = with


## Time held to the start of its frame of the effects.
func held(time: float) -> float:
	return floorf(time * stats.frame_rate + FRAME_NUDGE) / stats.frame_rate


## How far he tilts at Time, in degrees, before the side is chosen, on a floor hedge; on a wall or
## a ceiling hedge (On Floor false), scaled down to end at Wall Tilt.
func tilt(time: float, on_floor: bool = true) -> float:
	var degrees: float = lerpf(0.0, stats.buckle_tilt, _buckled(time)) \
			+ (stats.slump_tilt - stats.buckle_tilt) * _slumped(time)
	if on_floor or stats.slump_tilt <= 0.0:
		return degrees
	return degrees * stats.wall_tilt / stats.slump_tilt


## His scale at Time, as a share of his own: shorter and a little wider.
func squash(time: float) -> Vector2:
	var height: float = lerpf(lerpf(1.0, stats.buckle_squash, _buckled(time)), stats.slump_squash,
			_slumped(time))
	return Vector2(1.0 + (1.0 - height) / 2.0, height)


## How far he has sunk at Time, in px, on a floor hedge, caught with his feet Height px above the
## floor it grows from: down to that floor, and never more than Sink Px.
func sink(time: float, height: float) -> float:
	return clampf(height, 0.0, stats.sink_px) * _slumped(time)


## How far through the buckle he is at Time, 0 to 1.
func _buckled(time: float) -> float:
	return smoothstep(0.0, stats.buckle_time, held(time))


## How far through the slump he is at Time, 0 to 1: it follows the buckle.
func _slumped(time: float) -> float:
	return smoothstep(stats.buckle_time, stats.slump_time, held(time))
