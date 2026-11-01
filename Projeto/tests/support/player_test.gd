# Shared setup for the player tests: platforms, a player with its own copy of Stats, a stand-in
# input to drive it, waiting for the landing, a wall or a number of frames, and printing PASS or
# FAIL. It extends base_test.gd, so the autoload Settings keeps to its defaults. A test extends this
# file instead of SceneTree, with
# extends "res://tests/support/player_test.gd"
extends "res://tests/support/base_test.gd"

## A PlayerInput a test drives by hand; see stand_in_input.gd. Not annotated, so it can be used as
## a type.
const StandInInput = preload("res://tests/support/stand_in_input.gd")
const PLAYER_SCENE: PackedScene = preload("res://player/player.tscn")
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


## A wall from x = left to x = right, and from y = top down to y = bottom, already in the scene.
func make_wall(left: float, right: float, top: float, bottom: float = 0.0) -> StaticBody2D:
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(right - left, bottom - top)
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	var wall: StaticBody2D = StaticBody2D.new()
	wall.position = Vector2((left + right) / 2.0, (top + bottom) / 2.0)
	wall.add_child(collision)
	root.add_child(wall)
	return wall


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


func wait_until_on_wall(player: Player) -> bool:
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if player.is_on_wall():
			return true
	return false


## Waits a physics frame at a time, up to frames of them, until condition holds; false if it never
## does.
func wait_until(condition: Callable, frames: int = MAX_FRAMES) -> bool:
	for _frame: int in frames:
		await physics_frame
		if condition.call():
			return true
	return false


func wait_frames(frames: int) -> void:
	for _frame: int in frames:
		await physics_frame


## Puts a stand-in in the player's input, as a child of the player, and hands it back.
func put_a_stand_in(player: Player) -> StandInInput:
	var stand_in: StandInInput = StandInInput.new()
	player.add_child(stand_in)
	player.input = stand_in
	return stand_in


## Takes the player out at the end of the frame, and waits for it.
func remove_player(player: Player) -> void:
	player.queue_free()
	await physics_frame


## How high the feet go above floor_y before the player lands again, in px; 0 if it never leaves
## the floor.
func peak_height(player: Player, floor_y: float) -> float:
	var highest_y: float = floor_y
	var left_floor: bool = false
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if player.is_on_floor():
			if left_floor:
				break
			continue
		left_floor = true
		highest_y = minf(highest_y, player.position.y)
	return floor_y - highest_y


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
