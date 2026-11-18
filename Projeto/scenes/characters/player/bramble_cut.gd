extends RefCounted

## How brambles cut the man apart as they kill him (#263), with no scene, so the tests run it alone.
## Slashes cross his body, all tilted the same way by a little more or less, as claw marks, evenly
## spaced down the part of him a floor hedge leaves in sight, and split his drawing into convex
## pieces, one more than the slashes, as long as no two cross within the box. Once the freeze is over the pieces fly: the higher a piece, the
## harder it is thrown up and to the side and the faster it spins, every other one the other way;
## they fall, settle into the hedge on the floor and stay; then they fade into the ink. Every value
## over time is held to the frame of the effects. The values are in Stats.

const BrambleDeathStats := preload("res://scenes/characters/player/bramble_death_stats.gd")
## A piece smaller than this, in px², is a sliver at a corner, and is left out.
const SLIVER_AREA: float = 1.0
## Hash outcomes are spread over this many steps between 0 and 1.
const CHANCE_STEPS: int = 1000
## Added to a time in frames of the effects before rounding it down: a clock summed from 60 fps
## deltas lands a hair under a frame's start now and then.
const FRAME_NUDGE: float = 0.0001


## A straight slash through Point, tilted Angle radians from level. Drawn, its middle slides along it
## by Shift times its length, so the marks are not stacked; the cut itself goes through Point.
class Cut:
	var point: Vector2
	var angle: float
	var shift: float

	func _init(at: Vector2, tilt: float, slide: float = 0.0) -> void:
		point = at
		angle = tilt
		shift = slide

	## Square to the slash, pointing below it.
	func get_normal() -> Vector2:
		return Vector2(-sin(angle), cos(angle))


var stats: BrambleDeathStats


func _init(with: BrambleDeathStats) -> void:
	stats = with


## Time held to the start of its frame of the effects.
func held(time: float) -> float:
	return floorf(time * stats.frame_rate + FRAME_NUDGE) / stats.frame_rate


## The slashes across a body from Top to Bottom (y down), through its middle Middle X. Chance picks
## the side they all tilt to, each tilt between the least and the most, and each slide.
func cuts(top: float, bottom: float, middle_x: float, chance: int) -> Array[Cut]:
	var result: Array[Cut] = []
	var side: float = 1.0 if _chance(chance, -1) < 0.5 else -1.0
	for i: int in stats.cuts:
		var share: float = 0.5 if stats.cuts == 1 else float(i) / (stats.cuts - 1)
		var y: float = lerpf(top, bottom, lerpf(stats.cut_first, stats.cut_last, share))
		var tilt: float = lerpf(stats.cut_tilt_min, stats.cut_tilt_max, _chance(chance, i))
		var slide: float = (2.0 * _chance(chance, stats.cuts + i) - 1.0) * stats.slash_stagger
		result.append(Cut.new(Vector2(middle_x, y), deg_to_rad(tilt * side), slide))
	return result


## Polygon split along every cut, in convex pieces from the top down (by their centres); slivers are
## left out.
func split(polygon: PackedVector2Array, along: Array[Cut]) -> Array[PackedVector2Array]:
	var pieces: Array[PackedVector2Array] = [polygon]
	for cut: Cut in along:
		var next: Array[PackedVector2Array] = []
		for piece: PackedVector2Array in pieces:
			for normal: Vector2 in [cut.get_normal(), -cut.get_normal()]:
				var part: PackedVector2Array = clip(piece, cut.point, normal)
				if part.size() >= 3 and area(part) > SLIVER_AREA:
					next.append(part)
		pieces = next
	pieces.sort_custom(func(a: PackedVector2Array, b: PackedVector2Array) -> bool:
		return centre(a).y < centre(b).y)
	return pieces


## The part of a convex Polygon on Normal's side of the line through Point.
static func clip(polygon: PackedVector2Array, point: Vector2, normal: Vector2) -> PackedVector2Array:
	var kept := PackedVector2Array()
	for i: int in polygon.size():
		var a: Vector2 = polygon[i]
		var b: Vector2 = polygon[(i + 1) % polygon.size()]
		var side_a: float = (a - point).dot(normal)
		var side_b: float = (b - point).dot(normal)
		if side_a >= 0.0:
			kept.append(a)
		if (side_a >= 0.0) != (side_b >= 0.0):
			kept.append(a.lerp(b, side_a / (side_a - side_b)))
	return kept


static func area(polygon: PackedVector2Array) -> float:
	var twice: float = 0.0
	for i: int in polygon.size():
		twice += polygon[i].cross(polygon[(i + 1) % polygon.size()])
	return absf(twice) / 2.0


## The centre of a polygon's area.
static func centre(polygon: PackedVector2Array) -> Vector2:
	var twice: float = 0.0
	var sum: Vector2 = Vector2.ZERO
	for i: int in polygon.size():
		var a: Vector2 = polygon[i]
		var b: Vector2 = polygon[(i + 1) % polygon.size()]
		var cross: float = a.cross(b)
		twice += cross
		sum += (a + b) * cross
	if is_zero_approx(twice):
		return polygon[0]
	return sum / (3.0 * twice)


## How the piece at Rank (0 at the top) of Count is thrown, in px/s; Side is the way the top one
## goes, 1 to the right.
func throw(rank: int, count: int, side: float) -> Vector2:
	var height: float = _height_share(rank, count)
	var away: float = 1.0 if rank % 2 == 0 else -stats.counter_push
	return Vector2(side * away * stats.push_speed * height, -stats.pop_speed * height)


## How fast the piece at Rank spins, in degrees a second, turning the way it is thrown.
func spin(rank: int, count: int, side: float) -> float:
	var away: float = 1.0 if rank % 2 == 0 else -stats.counter_push
	return side * away * stats.spin_speed * _height_share(rank, count)


## When a piece thrown from Start at Velocity, under Gravity, comes down to Rest Y: at once if it
## starts below it.
static func landing(start: Vector2, velocity: Vector2, gravity: float, rest_y: float) -> float:
	var drop: float = rest_y - start.y
	if drop <= 0.0 or gravity <= 0.0:
		return 0.0 if drop <= 0.0 else INF
	return (-velocity.y + sqrt(velocity.y * velocity.y + 2.0 * gravity * drop)) / gravity


## Where the piece is Time after the freeze: thrown, falling, and still once it has come to Rest Y.
func place(start: Vector2, velocity: Vector2, gravity: float, rest_y: float, time: float) -> Vector2:
	var flying: float = minf(held(time), landing(start, velocity, gravity, rest_y))
	var at: Vector2 = start + velocity * flying + Vector2(0.0, 0.5 * gravity * flying * flying)
	return Vector2(at.x, minf(at.y, maxf(rest_y, start.y)))


## How far it has turned Time after the freeze, in radians: it stops turning when it lands.
func turn(spin_speed: float, start: Vector2, velocity: Vector2, gravity: float, rest_y: float,
		time: float) -> float:
	return deg_to_rad(spin_speed * minf(held(time), landing(start, velocity, gravity, rest_y)))


## How faded the pieces are Time after the freeze: 0 whole, 1 gone.
func fade(time: float) -> float:
	return clampf((held(time) - stats.fade_start) / stats.fade_time, 0.0, 1.0)


## How strongly the slashes are drawn Time after the freeze: whole during it, gone after Slash Fade.
func slash_strength(time: float) -> float:
	return 1.0 - clampf(held(time) / stats.slash_fade, 0.0, 1.0)


## The slash's length Time after the freeze, for a body Width px wide.
func slash_length(time: float, width: float) -> float:
	return width * stats.slash_length * (1.0 + stats.slash_growth * held(time))


## The point of the frame's picture a sprite draws at Local, in its own px: Frame Size is the size
## of a frame, Offset the sprite's, and Flipped whether it is drawn mirrored. Centred, as Godot's
## sprites are by default.
static func frame_point(local: Vector2, frame_size: Vector2, offset: Vector2, flipped: bool) -> Vector2:
	var from_middle: Vector2 = local - offset
	if flipped:
		from_middle.x = -from_middle.x
	return from_middle + frame_size / 2.0


## 1 for the top piece, down to 0 for the bottom one.
func _height_share(rank: int, count: int) -> float:
	return 1.0 - float(rank) / maxf(count - 1, 1)


func _chance(chance: int, index: int) -> float:
	return float(absi(hash(Vector2i(chance, index))) % CHANCE_STEPS) / (CHANCE_STEPS - 1)
