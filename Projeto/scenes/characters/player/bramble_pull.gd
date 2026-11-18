extends RefCounted

## How brambles pull the man in as they kill him (#263), with no scene, so the tests run it alone.
## The hedge pulls from Grab Time to Pull End, speeding up as if sucked in: on a floor hedge he goes
## under. If there are vines (none by default), they grow out of the hedge to him by Grab Time,
## from his legs up, and wrap across him, each from the side it climbs to the other and round behind
## him; on a floor hedge they climb one side then the other, by a wall or a ceiling from the hedge's
## side; the parts that go under with him are no longer drawn, and they writhe. With Jerk Px, he
## jerks while pulled. Every value over time is held to the frame of the effects. The values are in
## Stats.

const BrambleDeathStats := preload("res://scenes/characters/player/bramble_death_stats.gd")
## Hash outcomes are spread over this many steps between 0 and 1.
const CHANCE_STEPS: int = 1000
## The first point of a vine that is on him, and moves with him: before it, the root and the bend.
const ON_HIM: int = 2
## How far beyond the hedge's base line, in px, a point still counts as on it.
const ON_LINE: float = 0.01
## How far back a vine's curl reaches, as a share of how far up it goes (Vine Hook).
const HOOK_BACK_SHARE: float = 0.5
## Added to a time in frames of the effects before rounding it down: a clock summed from 60 fps
## deltas lands a hair under a frame's start now and then.
const FRAME_NUDGE: float = 0.0001


## A vine, as a line through Points: its root on the hedge, its bend, the side of him it climbs,
## the other side, and the end of its curl behind him. Leaves are at these shares of its length.
class Vine:
	var points: PackedVector2Array = PackedVector2Array()
	var leaves: PackedFloat32Array = PackedFloat32Array()


var stats: BrambleDeathStats


func _init(with: BrambleDeathStats) -> void:
	stats = with


## Time held to the start of its frame of the effects.
func held(time: float) -> float:
	return frame_of(time) / stats.frame_rate


func frame_of(time: float) -> int:
	return floori(time * stats.frame_rate + FRAME_NUDGE)


## The vines round a body Body, in the world, for a hedge whose base line goes through Base and
## whose Up points away from it; Floor Like for a floor hedge. Chance picks the side the first one
## climbs on a floor hedge.
func vines(body: Rect2, base: Vector2, up: Vector2, floor_like: bool, chance: int) -> Array[Vine]:
	var along_hedge := Vector2(-up.y, up.x)
	var half_wrap: float = body.size.x * stats.wrap_share / 2.0
	var middle_x: float = body.get_center().x
	var side: float = 1.0 if _chance(chance, -1) < 0.5 else -1.0
	var hedge_side: float = signf(-up.x)
	var result: Array[Vine] = []
	for i: int in stats.vines:
		var share: float = 0.5 if stats.vines == 1 else float(i) / (stats.vines - 1)
		var y: float = body.end.y - body.size.y * lerpf(stats.vine_first, stats.vine_last, share)
		var climbs: float = side if floor_like or hedge_side == 0.0 else hedge_side
		var near := Vector2(middle_x + climbs * half_wrap, y)
		var far := Vector2(middle_x - climbs * half_wrap, y + stats.wrap_tilt * (1.0 if i % 2 == 0 else -1.0))
		var hook: Vector2 = far + Vector2(-climbs * stats.vine_hook * HOOK_BACK_SHARE, -stats.vine_hook)
		var out: float = climbs if floor_like else (1.0 if i % 2 == 0 else -1.0)
		var root: Vector2 = base + along_hedge * ((near - base).dot(along_hedge)
				+ out * stats.vine_spread * signf(along_hedge.x + along_hedge.y))
		var reach: Vector2 = near - root
		var across: Vector2 = Vector2(-reach.y, reach.x).normalized() if reach != Vector2.ZERO else Vector2.ZERO
		var bend: Vector2 = root.lerp(near, 0.5) + across * stats.vine_bend * (1.0 if i % 2 == 0 else -1.0)
		var vine := Vine.new()
		vine.points = PackedVector2Array([root, bend, near, far, hook])
		for leaf: int in stats.leaves_per_vine:
			vine.leaves.append(0.5 * float(leaf + 1) / (stats.leaves_per_vine + 1))
		result.append(vine)
		if floor_like:
			side = -side
	return result


## How far the vines have grown, Time after the freeze: 0 to 1 by Grab Time; at once if it is 0.
func grown(time: float) -> float:
	if stats.grab_time <= 0.0:
		return 1.0
	return clampf(held(time) / stats.grab_time, 0.0, 1.0)


## How far the hedge has pulled him, Time after the freeze: nothing until Grab Time, all the way by
## Pull End, speeding up as if sucked in, so he shows going under until the screen darkens.
func pulled(time: float) -> float:
	var share: float = clampf((held(time) - stats.grab_time) / (stats.pull_end - stats.grab_time), 0.0, 1.0)
	return share * share


## His jerk, Time after the freeze, from -1 to 1, new on each frame of the effects while they pull,
## and 0 before and after.
func jerk(time: float, chance: int) -> float:
	var share: float = pulled(time)
	if share <= 0.0 or share >= 1.0:
		return 0.0
	return 2.0 * _chance(chance, frame_of(time)) - 1.0


## How far Vine's bend writhes, Time after the freeze, in px.
func writhe(time: float, vine: int, chance: int) -> Vector2:
	var frame: int = frame_of(time)
	return Vector2(2.0 * _chance(chance + vine, 2 * frame) - 1.0,
			2.0 * _chance(chance + vine, 2 * frame + 1) - 1.0) * stats.vine_writhe


## The start of the line through Points, Share of its length long.
static func part(points: PackedVector2Array, share: float) -> PackedVector2Array:
	var total: float = 0.0
	for i: int in range(1, points.size()):
		total += points[i - 1].distance_to(points[i])
	var left: float = total * clampf(share, 0.0, 1.0)
	var kept := PackedVector2Array()
	if points.is_empty() or left <= 0.0:
		return kept
	kept.append(points[0])
	for i: int in range(1, points.size()):
		var step: float = points[i - 1].distance_to(points[i])
		if step >= left:
			kept.append(points[i - 1].move_toward(points[i], left))
			return kept
		kept.append(points[i])
		left -= step
	return kept


## The line through Points from its start up to where it first goes past the line through Base
## along the hedge, to the side away from Up. A point within On Line of it counts as on it: a
## turned hedge's Up is a rounded sine, so a root on its line can come out a hair beyond.
static func above(points: PackedVector2Array, base: Vector2, up: Vector2) -> PackedVector2Array:
	var kept := PackedVector2Array()
	for i: int in points.size():
		var height: float = (points[i] - base).dot(up)
		if height >= -ON_LINE:
			kept.append(points[i])
			continue
		if i > 0:
			var before: float = (points[i - 1] - base).dot(up)
			kept.append(points[i - 1].lerp(points[i], before / (before - height)))
		break
	return kept


func _chance(chance: int, index: int) -> float:
	return float(absi(hash(Vector2i(chance, index))) % CHANCE_STEPS) / (CHANCE_STEPS - 1)
