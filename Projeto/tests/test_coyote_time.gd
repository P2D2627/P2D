# Checks the Coyote Time in the player's Stats. After running off a ledge without jumping, Jump
# still works up to the last frame of Coyote Time and not one frame later, with Coyote Time rounded
# to the nearest physics frame. It never works late with Coyote Time at 0, and jumping uses Coyote
# Time up, so a second press in the air never jumps again.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_coyote_time.gd
extends "res://tests/support/player_test.gd"

## Coyote Time for the cases, set in memory only: 0.07 s is 4.2 physics frames at 60 per second,
## which rounds to 4.
const COYOTE_TIME: float = 0.07
const COYOTE_FRAMES: int = 4
const NO_COYOTE_TIME: float = 0.0
## 0.08 s is 4.8 physics frames, which rounds up to 5: Jump must still work on frame 5 in the air.
const COYOTE_TIME_ROUNDING_UP: float = 0.08
const COYOTE_FRAMES_ROUNDED_UP: int = 5
## The ledge runs from x = -LEDGE_LENGTH to x = 0, with nothing past it.
const LEDGE_LENGTH: float = 2000.0
## Where each run starts: far enough from the end of the ledge to reach top speed.
const RUN_UP_POSITION: Vector2 = Vector2(-1000.0, -2.0)
## Frames in the air count from 1, the first frame off the floor; 0 is the last frame on it.
const LAST_FLOOR_FRAME: int = 0
const FIRST_AIR_FRAME: int = 1
## For _count_jumps: a frame in the air that never comes, so there is no second press.
const NEVER: int = -1
## Frame in the air of the second press in the used-up case: well inside Coyote Time.
const SECOND_PRESS_FRAME: int = 2
const ONE_JUMP: int = 1
const NO_JUMP: int = 0
## Frames still watched after the last press, so that a jump has time to show.
const FRAMES_TO_WATCH: int = 10
## What _count_jumps returns when the player never lands on the ledge.
const NO_RUN: int = -1

## The frame of a run on which the player is first off the floor, found once, without jumping.
var _off_the_ledge_frame: int = NEVER_REACHED


func _initialize() -> void:
	make_platform(-LEDGE_LENGTH, 0.0)
	var results: Array[bool] = []
	_off_the_ledge_frame = await _frames_until_off_the_ledge()
	if _off_the_ledge_frame == NEVER_REACHED:
		results.append(report(false, "the player never ran off the ledge"))
	else:
		results.append(await _jump_on_the_last_frame_on_the_floor_jumps())
		results.append(await _jump_on_the_last_frame_of_coyote_time_jumps())
		results.append(await _jump_one_frame_after_coyote_time_does_not_jump())
		results.append(await _coyote_time_rounds_to_the_nearest_frame())
		results.append(await _no_coyote_time_means_no_late_jump())
		results.append(await _jumping_uses_coyote_time_up())
	finish(results)


## The control case, with Coyote Time at 0, so that only the floor can give the jump. If it fails,
## the press comes a frame late or the floor no longer gives a jump on its own.
## _no_coyote_time_means_no_late_jump checks that the press does not come a frame early.
func _jump_on_the_last_frame_on_the_floor_jumps() -> bool:
	return await _expect_jumps(NO_COYOTE_TIME, ONE_JUMP, LAST_FLOOR_FRAME)


func _jump_on_the_last_frame_of_coyote_time_jumps() -> bool:
	return await _expect_jumps(COYOTE_TIME, ONE_JUMP, COYOTE_FRAMES)


func _jump_one_frame_after_coyote_time_does_not_jump() -> bool:
	return await _expect_jumps(COYOTE_TIME, NO_JUMP, COYOTE_FRAMES + 1)


## Rounding down would leave 4 frames here, and frame 5 would not jump. Rounding up would give 5
## frames for 0.07 s, which _jump_one_frame_after_coyote_time_does_not_jump catches.
func _coyote_time_rounds_to_the_nearest_frame() -> bool:
	return await _expect_jumps(COYOTE_TIME_ROUNDING_UP, ONE_JUMP, COYOTE_FRAMES_ROUNDED_UP)


func _no_coyote_time_means_no_late_jump() -> bool:
	return await _expect_jumps(NO_COYOTE_TIME, NO_JUMP, FIRST_AIR_FRAME)


## A jump from the floor must use Coyote Time up, or a second press inside it jumps again.
func _jumping_uses_coyote_time_up() -> bool:
	return await _expect_jumps(COYOTE_TIME, ONE_JUMP, LAST_FLOOR_FRAME, SECOND_PRESS_FRAME)


func _expect_jumps(coyote_time: float, expected: int, press_frame: int,
		second_press_frame: int = NEVER) -> bool:
	var jumps: int = await _count_jumps(coyote_time, press_frame, second_press_frame)
	if jumps == NO_RUN:
		return report(false, "the player never landed on the ledge")
	var presses: String = _frame_text(press_frame)
	if second_press_frame != NEVER:
		presses += " and again on " + _frame_text(second_press_frame)
	return report(jumps == expected, "Coyote Time %.2f s, Jump on %s: %d jump(s), expected %d"
			% [coyote_time, presses, jumps, expected])


## Runs right from the run-up spot without jumping and returns the frame of the run on which the
## player is first off the floor, or NEVER_REACHED.
func _frames_until_off_the_ledge() -> int:
	var player: Player = await spawn_on_floor(RUN_UP_POSITION)
	if player == null:
		return NEVER_REACHED
	var frames: int = NEVER_REACHED
	Input.action_press(&"move_right")
	for frame: int in MAX_FRAMES:
		await physics_frame
		if not player.is_on_floor():
			frames = frame + 1
			break
	Input.action_release(&"move_right")
	player.queue_free()
	return frames


## Runs right off the ledge with Coyote Time at coyote_time and presses Jump so that it counts on
## press_frame in the air, and again on second_press_frame unless that is NEVER. Returns how many
## times the player jumped, or NO_RUN if it never landed on the ledge.
func _count_jumps(coyote_time: float, press_frame: int, second_press_frame: int) -> int:
	var player: Player = await spawn_on_floor(RUN_UP_POSITION)
	if player == null:
		return NO_RUN
	player.stats.coyote_time = coyote_time
	var first_press_at: int = _press_frame_in_run(press_frame)
	var second_press_at: int = NEVER
	if second_press_frame != NEVER:
		second_press_at = _press_frame_in_run(second_press_frame)
	var jumps: int = 0
	var last_speed: float = player.velocity.y
	Input.action_press(&"move_right")
	for frame: int in maxi(first_press_at, second_press_at) + FRAMES_TO_WATCH:
		if frame == first_press_at or frame == second_press_at:
			Input.action_press(&"jump")
		await physics_frame
		# The press already counts on the coming frame; letting go keeps the next press a new one.
		Input.action_release(&"jump")
		if is_jump(last_speed, player.velocity.y):
			jumps += 1
		last_speed = player.velocity.y
	Input.action_release(&"move_right")
	player.queue_free()
	return jumps


## The frame of a run on which to press Jump so that it counts on air_frame: frame k in the air
## comes _off_the_ledge_frame + k frames into the run.
func _press_frame_in_run(air_frame: int) -> int:
	return _off_the_ledge_frame + air_frame - PRESS_DELAY_FRAMES


func _frame_text(air_frame: int) -> String:
	if air_frame == LAST_FLOOR_FRAME:
		return "the last frame on the floor"
	return "frame %d in the air" % air_frame
