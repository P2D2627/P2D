# Shared setup for the player tests: platforms, a player with its own copy of Stats, waiting for
# the landing, and printing PASS or FAIL. A test extends this file instead of SceneTree, with
# extends "res://tests/support/player_test.gd"
extends SceneTree

const PLAYER_SCENE: PackedScene = preload("res://scenes/actors/player.tscn")
## Physics frames to wait for anything before giving up.
const MAX_FRAMES: int = 600
const PLATFORM_THICKNESS: float = 100.0
## What a frame count is when the thing it counts never happens.
const NEVER_REACHED: int = -1
## A press made after f frames of a run counts as just pressed on frame f + PRESS_DELAY_FRAMES of
## that run: frame f + 1 is the one about to run, and a script's press only counts from the frame
## after it. measure_movement.gd presses two frames early for the same reason.
const PRESS_DELAY_FRAMES: int = 2
## How much faster than on the frame before the player must go up to count as jumping, in px/s. A
## jump adds over 1300.
const JUMP_KICK: float = 1.0


## This file only holds what the tests share, so on its own it says so and stops.
func _initialize() -> void:
	printerr("player_test.gd only holds shared setup: run one of the tests/test_*.gd files.")
	quit(1)


## A platform from x = left to x = right, with its top edge at y = top, already in the scene.
func make_platform(left: float, right: float, top: float = 0.0) -> StaticBody2D:
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(right - left, PLATFORM_THICKNESS)
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	var platform: StaticBody2D = StaticBody2D.new()
	platform.position = Vector2((left + right) / 2.0, top + PLATFORM_THICKNESS / 2.0)
	platform.add_child(collision)
	root.add_child(platform)
	return platform


## A player at the given spot with its own copy of Stats, so a case can change values in memory
## without touching the .tres or the other cases.
func spawn_player(at: Vector2) -> Player:
	var player: Player = PLAYER_SCENE.instantiate() as Player
	player.stats = player.stats.duplicate() as PlayerMovementStats
	player.position = at
	root.add_child(player)
	return player


## spawn_player, then waits for the landing. Returns null if the player never lands.
func spawn_on_floor(at: Vector2) -> Player:
	var player: Player = spawn_player(at)
	if not await wait_until_on_floor(player):
		player.queue_free()
		return null
	return player


func wait_until_on_floor(player: Player) -> bool:
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if player.is_on_floor():
			return true
	return false


## True if the player goes up, and faster than on the frame before, which only a jump does. A
## landing also takes the falling speed away, but leaves the player at rest, not going up.
func is_jump(previous_speed: float, speed: float) -> bool:
	return speed < 0.0 and speed < previous_speed - JUMP_KICK


## The size of the player's collision box, read from its scene.
func body_size(player: Player) -> Vector2:
	var collision: CollisionShape2D = player.get_node(^"CollisionShape2D") as CollisionShape2D
	return (collision.shape as RectangleShape2D).size


## Prints the verdict and what was measured, and hands the verdict back.
func report(passed: bool, what: String) -> bool:
	print("%s: %s" % ["PASS" if passed else "FAIL", what])
	return passed


## Quits with exit code 0 if every case passed, and 1 otherwise.
func finish(results: Array[bool]) -> void:
	quit(1 if results.has(false) else 0)
