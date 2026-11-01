# Prints what the list of everything inside the crucifix's radius costs. _repel() asks the repel
# area for that list, with get_overlapping_areas(), on every physics frame the crucifix is up, and
# the area builds it anew each time. Measured with 10, 50 and 200 stand-in demons inside the radius,
# the crucifix down so it pushes none of them out, in two ways: many calls in a row, with the
# processor's cache warm, and one call per physics step after writing over more memory than the
# cache holds, the worst case. Both include building and freeing the list. It checks nothing: the
# exit code is 1 only if the player never lands or the radius does not find every demon. The README
# quotes the result in the crucifix's section, "Crucifixo: componentes e modificadores de movimento".
# Run from the repository root:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/measure_crucifix_repel.gd
extends "res://tests/support/player_test.gd"

const REPELLABLE_SCENE: PackedScene = preload("res://components/repellable.tscn")
## How many stand-in demons sit inside the radius in each measure.
const DEMON_COUNTS: Array[int] = [10, 50, 200]
const DEMON_RADIUS: float = 16.0
## Farthest a demon sits from the crucifix, in px: inside the 200 px of crucifix_stats.tres.
const DEMON_SPREAD: float = 150.0
## The project's enemy physics layer, layer 3, the one a demon is on.
const ENEMY_LAYER: int = 1 << 2
## The project's world physics layer, layer 1, the one a demon collides with.
const WORLD_LAYER: int = 1
## Calls made before the warm ones, so the first calls' setup does not count.
const WARM_UP_CALLS: int = 100
## Calls in a row in the warm measure; the result is their average.
const WARM_CALLS: int = 2000
## Physics steps in the cold measure, one call each; the result is their average.
const COLD_STEPS: int = 300
## Bytes written over before each cold call: more than a processor's caches hold, so the call finds
## nothing of the last one in them.
const CACHE_SWEEP_BYTES: int = 32 * 1024 * 1024
## Physics frames the radius takes to find demons just put in it, or to forget removed ones.
const SETTLE_FRAMES: int = 3
## The cost the list may have on one physics frame, in ms: 0.3 % of a 16.6 ms frame.
const BUDGET_MS: float = 0.05
const USEC_PER_MS: float = 1000.0
## What a measure returns when a list came back with another number of areas.
const LIST_CHANGED: float = -1.0
const FLOOR_HALF_WIDTH: float = 2000.0
## A little above the floor, so the player lands on its own.
const FLOOR_START: Vector2 = Vector2(0.0, -2.0)

var _cache_sweep: PackedByteArray = PackedByteArray()


func _initialize() -> void:
	_cache_sweep.resize(CACHE_SWEEP_BYTES)
	make_platform(-FLOOR_HALF_WIDTH, FLOOR_HALF_WIDTH)
	var player: Player = await spawn_on_floor(FLOOR_START)
	if player == null:
		printerr("The player never landed.")
		quit(1)
		return
	var crucifix: Crucifix = player.get_node(^"Crucifix") as Crucifix
	var repel_area: Area2D = crucifix.get_node(^"%RepelArea") as Area2D
	for count: int in DEMON_COUNTS:
		var demons: Array[CharacterBody2D] = []
		for index: int in count:
			var direction: Vector2 = Vector2.from_angle(TAU * index / count)
			var distance: float = DEMON_SPREAD * float(index + 1) / count
			demons.append(_make_demon(crucifix.global_position + direction * distance))
		await wait_frames(SETTLE_FRAMES)
		var warm_ms: float = _warm_cost_ms(repel_area, count)
		var cold_ms: float = await _cold_cost_ms(repel_area, count)
		if warm_ms == LIST_CHANGED or cold_ms == LIST_CHANGED:
			printerr("%d demons in the radius, but a list did not hold them all." % count)
			quit(1)
			return
		print("%d demons in the radius: %.1f us in a row, %.1f us once per step with a cold cache; budget %.0f us, %s"
				% [count, warm_ms * USEC_PER_MS, cold_ms * USEC_PER_MS, BUDGET_MS * USEC_PER_MS,
				"within" if maxf(warm_ms, cold_ms) < BUDGET_MS else "OVER"])
		for demon: CharacterBody2D in demons:
			demon.queue_free()
		await wait_frames(SETTLE_FRAMES)
	await remove_player(player)
	quit(0)


## Average time of one get_overlapping_areas() call, in ms, over WARM_CALLS calls in a row: the call
## _repel() makes on every physics frame the crucifix is up. LIST_CHANGED if a list did not hold
## count areas.
func _warm_cost_ms(repel_area: Area2D, count: int) -> float:
	var seen: int = 0
	for _call: int in WARM_UP_CALLS:
		seen += repel_area.get_overlapping_areas().size()
	var start: int = Time.get_ticks_usec()
	for _call: int in WARM_CALLS:
		seen += repel_area.get_overlapping_areas().size()
	var elapsed_usec: int = Time.get_ticks_usec() - start
	if seen != count * (WARM_UP_CALLS + WARM_CALLS):
		return LIST_CHANGED
	return elapsed_usec / USEC_PER_MS / WARM_CALLS


## The same, over COLD_STEPS physics steps, one call each, made after writing over
## CACHE_SWEEP_BYTES.
func _cold_cost_ms(repel_area: Area2D, count: int) -> float:
	var elapsed_usec: int = 0
	for _step: int in COLD_STEPS:
		await physics_frame
		_cache_sweep.fill(0)
		var start: int = Time.get_ticks_usec()
		var found: int = repel_area.get_overlapping_areas().size()
		elapsed_usec += Time.get_ticks_usec() - start
		if found != count:
			return LIST_CHANGED
	return elapsed_usec / USEC_PER_MS / COLD_STEPS


## A demon stand-in at the given spot: a body with a Repellable, as the crucifix tests use.
func _make_demon(at: Vector2) -> CharacterBody2D:
	var demon: CharacterBody2D = CharacterBody2D.new()
	demon.collision_layer = ENEMY_LAYER
	demon.collision_mask = WORLD_LAYER
	demon.global_position = at
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = DEMON_RADIUS
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	var repellable: Repellable = REPELLABLE_SCENE.instantiate() as Repellable
	repellable.target = demon
	repellable.add_child(collision)
	demon.add_child(repellable)
	root.add_child(demon)
	return demon
