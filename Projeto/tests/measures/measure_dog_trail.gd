# Prints what the biggest dog's trail costs on a physics frame (#271, phase C). The room of test_dog_trail.gd: a
# floor, a one-way platform up to the left and a one-way shelf above it reaching right over the dog. The dog
# notices the man on the floor; he goes up by the platform onto the shelf and along it to right above the dog.
# Then, for FRAMES physics frames, it measures the whole frame, from one physics frame to the next, which with
# --fixed-fps and no window waits for nothing: with Follows Trail, the dog walks to the platform, plays out its
# jumps against the room (_arc_lands) on each frame it might take off, jumps up twice and walks along the shelf;
# without it, it stands out of reach below him. RUNS of each, taking turns, with a new room each time. It checks
# nothing: the exit code is 1 only if the dog never notices the man.
# Run from the repository root:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/measures/measure_dog_trail.gd
extends "res://tests/support/player_test.gd"

const BIGGEST_SCENE: PackedScene = preload("res://scenes/characters/demon/biggest_demon.tscn")
const PLATFORM_DEPTH: float = 24.0
const FLOOR_HALF_LENGTH: float = 2400.0
const DOG_X: float = 900.0
const MAN_NOTICED_X: float = 600.0
const LEFT_PLATFORM: Rect2 = Rect2(-500.0, -192.0, 144.0, PLATFORM_DEPTH)
const SHELF: Rect2 = Rect2(-450.0, -384.0, 1850.0, PLATFORM_DEPTH)
const WAY: Array[Vector2] = [Vector2(-428.0, -192.0), Vector2(-300.0, -384.0), Vector2(900.0, -384.0)]
const DROP_IN: float = 40.0
const NOTICE_FRAMES: int = 120
const LAND_FRAMES: int = 120
const FRAMES: int = 300
const RUNS: int = 3


func _initialize() -> void:
	for run: int in RUNS:
		for follows_trail: bool in [true, false]:
			var cost: Array[float] = await _measure(follows_trail)
			if cost.is_empty():
				quit(1)
				return
			print("Run %d, Follows Trail %s: whole frame %.0f us on average, %.0f us on the worst, over %d frames; the dog ended on the shelf %s"
					% [run + 1, follows_trail, cost[0], cost[1], FRAMES, cost[2] > 0.0])
	quit(0)


## The average and worst whole frame, in us, and 1 if the dog ended on the shelf, 0 if not; empty if the dog
## never noticed the man.
func _measure(follows_trail: bool) -> Array[float]:
	var bodies: Array[StaticBody2D] = [make_platform(-FLOOR_HALF_LENGTH, FLOOR_HALF_LENGTH),
			_make_one_way(LEFT_PLATFORM), _make_one_way(SHELF)]
	var big: Demon = BIGGEST_SCENE.instantiate() as Demon
	big.stats = big.stats.duplicate() as DemonStats
	big.stats.follows_trail = follows_trail
	big.position = Vector2(DOG_X, -2.0)
	big.faces_left = true
	root.add_child(big)
	await wait_until(big.is_on_floor)
	var man: Player = await spawn_on_floor(Vector2(MAN_NOTICED_X, -2.0))
	man.god_mode = true
	var noticed: bool = await wait_until(big.has_target, NOTICE_FRAMES)
	for spot: Vector2 in WAY:
		man.global_position = spot + Vector2(0.0, -DROP_IN)
		man.velocity = Vector2.ZERO
		await wait_until(func() -> bool: return man.is_on_floor() and absf(man.global_position.y - spot.y) < 4.0,
				LAND_FRAMES)
	var total: int = 0
	var worst: int = 0
	await physics_frame
	var last: int = Time.get_ticks_usec()
	for _frame: int in FRAMES:
		await physics_frame
		var now: int = Time.get_ticks_usec()
		total += now - last
		worst = maxi(worst, now - last)
		last = now
	var on_shelf: bool = big.is_on_floor() and absf(big.global_position.y - SHELF.position.y) < 4.0
	big.queue_free()
	for body: StaticBody2D in bodies:
		body.queue_free()
	await remove_player(man)
	if not noticed:
		return []
	return [float(total) / FRAMES, float(worst), 1.0 if on_shelf else 0.0]


func _make_one_way(rect: Rect2) -> StaticBody2D:
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = rect.size
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	collision.one_way_collision = true
	var platform: StaticBody2D = StaticBody2D.new()
	platform.position = rect.get_center()
	platform.add_child(collision)
	root.add_child(platform)
	return platform
