# Checks the landed signal. The player emits it once each time it is back on the floor after the
# air or a wall, with the state already ON_FLOOR when it comes: after appearing in the air, after a
# full jump, after running off a ledge onto a lower floor and after sliding down a wall. Standing
# and running on the floor emit nothing.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_landed_signal.gd
extends "res://tests/support/player_test.gd"

## The floor's top is at y = 0, from -FLOOR_HALF_WIDTH to FLOOR_HALF_WIDTH.
const FLOOR_HALF_WIDTH: float = 1000.0
## Where the drop case starts: high enough to reach top falling speed before landing.
const DROP_POSITION: Vector2 = Vector2(0.0, -400.0)
## Just above the floor, so a player spawned there lands on its first frames.
const FLOOR_SPAWN_HEIGHT: float = -2.0
## Physics frames each case watches: 2 s.
const WATCH_FRAMES: int = 120
## Physics frames the standing case stands still, and then runs.
const STAND_FRAMES: int = 60
## How far from the lower floor's top the player may rest and count as on it, in px.
const ON_FLOOR_TOLERANCE: float = 1.0
## The ledge case: an upper floor that ends at x = 0, a lower one LEDGE_DROP px below it, and the
## player starting on the upper one.
const LEDGE_DROP: float = 300.0
const UPPER_START: Vector2 = Vector2(-400.0, -2.0)
## The wall case: the wall's face is at x = WALL_FACE, from WALL_TOP down to the floor, and the
## player starts in the air close to it.
const WALL_FACE: float = 300.0
const WALL_THICKNESS: float = 200.0
const WALL_TOP: float = -2000.0
const WALL_START: Vector2 = Vector2(200.0, -400.0)


func _initialize() -> void:
	var results: Array[bool] = []
	results.append(await _a_player_that_appears_in_the_air_lands_once())
	results.append(await _standing_and_running_on_the_floor_do_not_land())
	results.append(await _a_full_jump_lands_once())
	results.append(await _running_off_a_ledge_lands_once_on_the_lower_floor())
	results.append(await _sliding_down_a_wall_lands_once())
	finish(results)


## A player that appears in the air lands once, on the floor.
func _a_player_that_appears_in_the_air_lands_once() -> bool:
	var ground: StaticBody2D = make_platform(-FLOOR_HALF_WIDTH, FLOOR_HALF_WIDTH)
	var player: Player = spawn_player(DROP_POSITION)
	var heard: Landings = Landings.new(player)
	await _watch(heard, WATCH_FRAMES)
	await _remove(player)
	await _remove(ground)
	return _report_landings("Drop from %.0f px" % -DROP_POSITION.y, heard, 1)


## Once on the floor, standing still and then running emit nothing.
func _standing_and_running_on_the_floor_do_not_land() -> bool:
	var ground: StaticBody2D = make_platform(-FLOOR_HALF_WIDTH, FLOOR_HALF_WIDTH)
	var player: Player = await _spawn_standing(Vector2(0.0, FLOOR_SPAWN_HEIGHT))
	if player == null:
		await _remove(ground)
		return report(false, "Standing and running: the player never landed")
	var heard: Landings = Landings.new(player)
	await _watch(heard, STAND_FRAMES)
	Input.action_press(&"move_right")
	await _watch(heard, STAND_FRAMES)
	Input.action_release(&"move_right")
	await _remove(player)
	await _remove(ground)
	return _report_landings("Standing, then running", heard, 0)


## A full jump from the floor lands once, back on the floor.
func _a_full_jump_lands_once() -> bool:
	var ground: StaticBody2D = make_platform(-FLOOR_HALF_WIDTH, FLOOR_HALF_WIDTH)
	var player: Player = await _spawn_standing(Vector2(0.0, FLOOR_SPAWN_HEIGHT))
	if player == null:
		await _remove(ground)
		return report(false, "Full jump: the player never landed")
	var heard: Landings = Landings.new(player)
	Input.action_press(&"jump")
	await _watch(heard, WATCH_FRAMES)
	Input.action_release(&"jump")
	await _remove(player)
	await _remove(ground)
	return _report_landings("Full jump", heard, 1)


## Running off the end of a floor onto a lower one lands once, on the lower floor.
func _running_off_a_ledge_lands_once_on_the_lower_floor() -> bool:
	var upper: StaticBody2D = make_platform(-FLOOR_HALF_WIDTH, 0.0)
	var lower: StaticBody2D = make_platform(-FLOOR_HALF_WIDTH, 2.0 * FLOOR_HALF_WIDTH, LEDGE_DROP)
	var player: Player = await _spawn_standing(UPPER_START)
	if player == null:
		await _remove(upper)
		await _remove(lower)
		return report(false, "Off a ledge: the player never landed")
	var heard: Landings = Landings.new(player)
	Input.action_press(&"move_right")
	await _watch(heard, WATCH_FRAMES)
	Input.action_release(&"move_right")
	var on_the_lower_floor: bool = absf(player.global_position.y - LEDGE_DROP) < ON_FLOOR_TOLERANCE
	await _remove(player)
	await _remove(upper)
	await _remove(lower)
	return _report_landings("Off a %.0f px ledge, on the lower floor %s" % [LEDGE_DROP,
			on_the_lower_floor], heard, 1 if on_the_lower_floor else -1)


## Sliding down a wall, pushing into it, and reaching the floor lands once.
func _sliding_down_a_wall_lands_once() -> bool:
	var ground: StaticBody2D = make_platform(-FLOOR_HALF_WIDTH, FLOOR_HALF_WIDTH)
	var wall: StaticBody2D = make_wall(WALL_FACE, WALL_FACE + WALL_THICKNESS, WALL_TOP)
	var player: Player = spawn_player(WALL_START)
	var heard: Landings = Landings.new(player)
	Input.action_press(&"move_right")
	await _watch(heard, WATCH_FRAMES)
	Input.action_release(&"move_right")
	await _remove(player)
	await _remove(wall)
	await _remove(ground)
	return _report_landings("Down a wall, on the wall first %s" % heard.saw_the_wall, heard,
			1 if heard.saw_the_wall else -1)


## spawn_on_floor, then waits for the state to turn ON_FLOOR too, which comes a frame after the
## touch, so the landing of the spawn is over before a case starts listening. Returns null if the
## player never lands.
func _spawn_standing(at: Vector2) -> Player:
	var player: Player = await spawn_on_floor(at)
	if player == null:
		return null
	for _frame: int in MAX_FRAMES:
		if player.get_state() == Player.State.ON_FLOOR:
			return player
		await physics_frame
	player.queue_free()
	return null


## Steps the physics, telling heard each frame what the player's state is.
func _watch(heard: Landings, frames: int) -> void:
	for _frame: int in frames:
		await physics_frame
		heard.saw(heard.player.get_state())


## Passes when the player has the signal, emitted expected times, each with the state already
## ON_FLOOR. An expected count below 0 means the case's setup went wrong, which fails too.
func _report_landings(what: String, heard: Landings, expected: int) -> bool:
	if heard.missing:
		return report(false, "%s: the player has no landed signal" % what)
	return report(expected >= 0 and heard.count == expected and heard.on_floor_each_time,
			"%s: landed %d times (expected %d), state ON_FLOOR each time %s"
			% [what, heard.count, expected, heard.on_floor_each_time])


func _remove(node: Node) -> void:
	node.queue_free()
	await physics_frame


## What a player's landed signal did: how many times it came, and whether the state was ON_FLOOR
## each time. missing is true if the player has no such signal.
class Landings:
	var player: Player
	var count: int = 0
	var on_floor_each_time: bool = true
	var missing: bool = false
	var saw_the_wall: bool = false

	func _init(watched: Player) -> void:
		player = watched
		if player.has_signal(&"landed"):
			player.connect(&"landed", _on_landed)
		else:
			missing = true

	func saw(state: Player.State) -> void:
		saw_the_wall = saw_the_wall or state == Player.State.ON_WALL

	func _on_landed() -> void:
		count += 1
		on_floor_each_time = (on_floor_each_time and player.get_state() == Player.State.ON_FLOOR
				and player.is_on_floor())
