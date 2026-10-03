# Checks the run's control on the floor and in the air, set in the player's Stats. On the floor,
# speeding up, turning around and braking take their times in Stats; in the air, those times divided
# by Air Control, also with other Air Control values; the floor's control lasts through the take-off
# frame and the air's through the landing frame; and at 0 nothing changes the speed in the air.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_air_control.gd
extends SceneTree

const PLAYER_SCENE: PackedScene = preload("res://scenes/actors/player.tscn")
## Float error allowed when rounding an expected frame count up: 6.000001 frames counts as 6.
const ROUNDING_SLACK: float = 0.001
## How far a measured speed change may miss its target, in px/s. Speeds are stored as 32-bit floats.
const STEP_TOLERANCE: float = 0.01
## Physics frames to wait for the player to land, or for the speed to get there, before giving up.
const MAX_FRAMES: int = 300
const GROUND_SIZE: Vector2 = Vector2(2000.0, 100.0)
## A little above the ground, so the player lands on its own before running.
const FLOOR_SPAWN_POSITION: Vector2 = Vector2(0.0, -2.0)
## Far above the ground, so the player is still falling when a case ends.
const AIR_SPAWN_POSITION: Vector2 = Vector2(0.0, -100000.0)
## What _frames_until_speed returns when the speed never gets there.
const NEVER_REACHED: int = -1
## Air Control values tried after the one in Stats. At 1, the air must match the floor.
const OTHER_AIR_CONTROLS: Array[float] = [0.5, 1.0]
## Air Control for the take-off and landing case: low enough that the speed is still going up when
## the player lands, so every frame's speed change shows which control it used.
const SWITCH_CASE_AIR_CONTROL: float = 0.05
## Physics frames the no-control case watches the speed for, first letting go, then pushing back.
const NO_CONTROL_FRAMES: int = 30


func _initialize() -> void:
	root.add_child(_make_ground())
	var results: Array[bool] = []
	results.append(await _floor_ramps_follow_floor_times())
	results.append(await _air_ramps_follow_air_control())
	results.append(await _control_switches_on_take_off_and_landing())
	results.append(await _no_air_control_keeps_the_speed())
	quit(1 if results.has(false) else 0)


## Ground with its top edge at y = 0.
func _make_ground() -> StaticBody2D:
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = GROUND_SIZE
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	var ground: StaticBody2D = StaticBody2D.new()
	ground.position.y = GROUND_SIZE.y / 2.0
	ground.add_child(collision)
	return ground


func _spawn_player(at: Vector2) -> Player:
	var player: Player = PLAYER_SCENE.instantiate() as Player
	player.position = at
	root.add_child(player)
	return player


## Waits one physics frame after spawning, so the player is already falling, and its physics already
## runs, when a case starts counting frames.
func _spawn_player_in_air() -> Player:
	var player: Player = _spawn_player(AIR_SPAWN_POSITION)
	await physics_frame
	return player


## The floor keeps the whole control, whatever Air Control is.
func _floor_ramps_follow_floor_times() -> bool:
	var player: Player = _spawn_player(FLOOR_SPAWN_POSITION)
	if not await _wait_until_on_floor(player):
		printerr("FAIL: the player never landed.")
		player.queue_free()
		return false
	var passed: bool = await _ramps_match(player, "on the floor", 1.0)
	player.queue_free()
	return passed


## In the air, every ramp takes its floor time divided by Air Control, for the value in Stats and
## for others. Air Control 0 has its own case. The resource is changed in memory only and set back
## at the end; the file is never saved.
func _air_ramps_follow_air_control() -> bool:
	var player: Player = await _spawn_player_in_air()
	var stats: PlayerMovementStats = player.stats
	var original_air_control: float = stats.air_control
	var air_controls: Array[float] = [original_air_control]
	air_controls.append_array(OTHER_AIR_CONTROLS)
	var all_passed: bool = true
	for air_control: float in air_controls:
		if is_zero_approx(air_control):
			continue
		stats.air_control = air_control
		var where: String = "in the air at Air Control %.2f" % air_control
		var passed: bool = await _ramps_match(player, where, air_control)
		all_passed = all_passed and passed
	stats.air_control = original_air_control
	player.queue_free()
	return all_passed


## is_on_floor() comes from the last move_and_slide(), so the take-off frame still changes the speed
## with the floor's control, and the landing frame with the air's. Holding Right and Jump from a
## standstill, the case finds both frames and checks the speed change on them and on the next ones.
## The resource is changed in memory only and set back at the end.
func _control_switches_on_take_off_and_landing() -> bool:
	var player: Player = _spawn_player(FLOOR_SPAWN_POSITION)
	if not await _wait_until_on_floor(player):
		printerr("FAIL: the player never landed.")
		player.queue_free()
		return false
	var stats: PlayerMovementStats = player.stats
	var original_air_control: float = stats.air_control
	stats.air_control = SWITCH_CASE_AIR_CONTROL
	var delta: float = player.get_physics_process_delta_time()
	var floor_step: float = stats.max_run_speed / stats.time_to_max_speed * delta
	var air_step: float = floor_step * stats.air_control
	var steps: Array[float] = []
	var speed: float = player.velocity.x
	var take_off: int = NEVER_REACHED
	var landing: int = NEVER_REACHED
	Input.action_press(&"move_right")
	Input.action_press(&"jump")
	for frame: int in MAX_FRAMES:
		await physics_frame
		steps.append(player.velocity.x - speed)
		speed = player.velocity.x
		if take_off == NEVER_REACHED and not player.is_on_floor():
			take_off = frame
		elif take_off != NEVER_REACHED and landing == NEVER_REACHED and player.is_on_floor():
			landing = frame
		elif landing != NEVER_REACHED:
			break
	Input.action_release(&"move_right")
	Input.action_release(&"jump")
	stats.air_control = original_air_control
	player.queue_free()
	if landing == NEVER_REACHED or landing + 1 >= steps.size():
		printerr("FAIL: the player never jumped and landed.")
		return false
	var passed: bool = (_is_step(steps[take_off], floor_step)
			and _is_step(steps[take_off + 1], air_step)
			and _is_step(steps[landing], air_step)
			and _is_step(steps[landing + 1], floor_step))
	var verdict: String = "PASS" if passed else "FAIL"
	print("%s: speed change %.1f on the take-off frame and %.1f after it, expected %.1f and %.1f"
			% [verdict, steps[take_off], steps[take_off + 1], floor_step, air_step])
	print("%s: speed change %.1f on the landing frame and %.1f after it, expected %.1f and %.1f"
			% [verdict, steps[landing], steps[landing + 1], air_step, floor_step])
	return passed


## At 0, neither letting go nor pushing the other way changes the speed in the air. The resource is
## changed in memory only and set back at the end.
func _no_air_control_keeps_the_speed() -> bool:
	var player: Player = await _spawn_player_in_air()
	var stats: PlayerMovementStats = player.stats
	var original_air_control: float = stats.air_control
	var top_speed: float = stats.max_run_speed
	stats.air_control = 0.0
	player.velocity.x = top_speed
	await _wait_frames(NO_CONTROL_FRAMES)
	var speed_after_letting_go: float = player.velocity.x
	Input.action_press(&"move_left")
	await _wait_frames(NO_CONTROL_FRAMES)
	Input.action_release(&"move_left")
	var speed_after_pushing_back: float = player.velocity.x
	stats.air_control = original_air_control
	player.queue_free()
	var passed: bool = (is_equal_approx(speed_after_letting_go, top_speed)
			and is_equal_approx(speed_after_pushing_back, top_speed))
	var verdict: String = "PASS" if passed else "FAIL"
	print("%s: Air Control 0, %.1f px/s after letting go and %.1f after pushing back, expected %.1f"
			% [verdict, speed_after_letting_go, speed_after_pushing_back, top_speed])
	return passed


## Speeds up holding Right, turns around holding Left, then lets go, and checks each ramp against
## its time in Stats divided by control. Turning around crosses twice the top speed, so it takes
## twice the time to speed up. Ends with the player standing still.
func _ramps_match(player: Player, where: String, control: float) -> bool:
	var stats: PlayerMovementStats = player.stats
	var top_speed: float = stats.max_run_speed
	Input.action_press(&"move_right")
	var speed_up_frames: int = await _frames_until_speed(player, top_speed)
	Input.action_release(&"move_right")
	Input.action_press(&"move_left")
	var turn_frames: int = await _frames_until_speed(player, -top_speed)
	Input.action_release(&"move_left")
	var stop_frames: int = await _frames_until_speed(player, 0.0)
	var speed_up_passed: bool = _report("%s, top speed" % where, speed_up_frames,
			_expected_frames(stats.time_to_max_speed, control))
	var turn_passed: bool = _report("%s, turn around" % where, turn_frames,
			_expected_frames(2.0 * stats.time_to_max_speed, control))
	var stop_passed: bool = _report("%s, stop" % where, stop_frames,
			_expected_frames(stats.time_to_stop, control))
	return speed_up_passed and turn_passed and stop_passed


func _frames_until_speed(player: Player, target: float) -> int:
	for frame: int in MAX_FRAMES:
		await physics_frame
		if is_equal_approx(player.velocity.x, target):
			return frame + 1
	return NEVER_REACHED


## Frames a ramp takes: its time in Stats, in physics frames, divided by the control kept, and
## rounded up, because the speed only reaches its target at the end of a whole frame.
func _expected_frames(ramp_time: float, control: float) -> int:
	return ceili(ramp_time * Engine.physics_ticks_per_second / control - ROUNDING_SLACK)


func _is_step(measured: float, expected: float) -> bool:
	return absf(measured - expected) <= STEP_TOLERANCE


## Prints PASS or FAIL for a measured ramp and returns whether it passed.
func _report(what: String, frames: int, expected: int) -> bool:
	var passed: bool = frames == expected
	var verdict: String = "PASS" if passed else "FAIL"
	print("%s: %s in %d frames, expected %d" % [verdict, what, frames, expected])
	return passed


func _wait_frames(count: int) -> void:
	for _frame: int in count:
		await physics_frame


func _wait_until_on_floor(player: Player) -> bool:
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if player.is_on_floor():
			return true
	return false
