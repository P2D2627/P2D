# Checks the Jump Buffer in the player's Stats. A press of Jump just before landing is kept, so the
# player jumps as it lands: from up to the last frame of Jump Buffer and not one frame earlier, with
# Jump Buffer rounded to the nearest physics frame, and never from the air with Jump Buffer at 0.
# The height still comes from how long Jump is held: a tap
# let go before the landing gives the lowest jump, and holding Jump gives the full one. And one
# press makes one jump, even under a low ceiling that lands the player again inside Jump Buffer.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_jump_buffer.gd
extends "res://tests/support/player_test.gd"

## Only read, for the heights the cases expect; each player changes its own copy.
const STATS: PlayerMovementStats = preload("res://resources/player_movement_stats.tres")
## Jump Buffer for the cases, set in memory only: 0.07 s is 4.2 physics frames at 60 per second,
## which rounds to 4.
const BUFFER_TIME: float = 0.07
const BUFFER_FRAMES: int = 4
const NO_BUFFER_TIME: float = 0.0
## 0.08 s is 4.8 physics frames, which rounds up to 5: a press 5 frames before the landing must
## still jump.
const BUFFER_TIME_ROUNDING_UP: float = 0.08
const BUFFER_FRAMES_ROUNDED_UP: int = 5
## The floor runs from x = -FLOOR_HALF_WIDTH to x = FLOOR_HALF_WIDTH, with its top at y = 0.
const FLOOR_HALF_WIDTH: float = 1000.0
## The player drops from here, high enough to reach top falling speed (143 px) before landing.
const DROP_POSITION: Vector2 = Vector2(0.0, -400.0)
## Frames before the landing count from 0, the first frame on the floor; 1 is the last in the air.
const FIRST_FLOOR_FRAME: int = 0
const LAST_AIR_FRAME: int = 1
## Frame before the landing of the press in the two height cases: inside Jump Buffer.
const HEIGHT_PRESS_FRAME: int = 2
## Frames still watched after the landing: more than the 21 a full jump takes to peak.
const FRAMES_TO_WATCH: int = 45
## How far a measured rise may miss its target, in px. A smaller rise is no jump at all.
const TOLERANCE: float = 1.0
## What _rise_after_landing returns when the player never lands.
const NO_RUN: float = -1.0
## The low-ceiling case stands here, away from the drops, and builds a ceiling CEILING_GAP px above
## the player's head.
const CEILING_SPOT: Vector2 = Vector2(-600.0, -2.0)
const CEILING_HALF_WIDTH: float = 100.0
## Less than one frame of a jump's rise (22 px), so the player bumps the ceiling within the take-off
## frame.
const CEILING_GAP: float = 10.0
const ONE_TAKE_OFF: int = 1

## The frame of a drop on which the player is first on the floor, found once, without jumping.
var _landing_frame: int = NEVER_REACHED


func _initialize() -> void:
	make_platform(-FLOOR_HALF_WIDTH, FLOOR_HALF_WIDTH)
	var results: Array[bool] = []
	_landing_frame = await _frames_until_landing()
	if _landing_frame == NEVER_REACHED:
		results.append(report(false, "the player never landed"))
	else:
		results.append(await _press_on_the_first_frame_on_the_floor_jumps())
		results.append(await _press_on_the_last_frame_of_jump_buffer_jumps())
		results.append(await _press_one_frame_before_jump_buffer_does_not_jump())
		results.append(await _jump_buffer_rounds_to_the_nearest_frame())
		results.append(await _no_jump_buffer_means_no_jump_from_the_air())
		results.append(await _tap_let_go_before_the_landing_gives_the_lowest_jump())
		results.append(await _jump_held_through_the_landing_gives_the_full_jump())
		results.append(await _one_press_under_a_low_ceiling_takes_off_once())
	finish(results)


## The control case, with Jump Buffer at 0, so that only the floor can give the jump. If it fails,
## the press comes a frame early or the floor no longer gives a jump on its own.
## _no_jump_buffer_means_no_jump_from_the_air checks that the press does not come a frame late.
func _press_on_the_first_frame_on_the_floor_jumps() -> bool:
	return await _expect_jump(NO_BUFFER_TIME, FIRST_FLOOR_FRAME, true)


func _press_on_the_last_frame_of_jump_buffer_jumps() -> bool:
	return await _expect_jump(BUFFER_TIME, BUFFER_FRAMES, true)


func _press_one_frame_before_jump_buffer_does_not_jump() -> bool:
	return await _expect_jump(BUFFER_TIME, BUFFER_FRAMES + 1, false)


## Rounding down would leave 4 frames here, and the press 5 frames before the landing would be
## lost. Rounding up would give 5 frames for 0.07 s, which
## _press_one_frame_before_jump_buffer_does_not_jump catches.
func _jump_buffer_rounds_to_the_nearest_frame() -> bool:
	return await _expect_jump(BUFFER_TIME_ROUNDING_UP, BUFFER_FRAMES_ROUNDED_UP, true)


func _no_jump_buffer_means_no_jump_from_the_air() -> bool:
	return await _expect_jump(NO_BUFFER_TIME, LAST_AIR_FRAME, false)


## A kept tap rises like a tap from the floor: the take-off frame at full take-off speed, then the
## cut gravity, as test_jump_height.gd checks.
func _tap_let_go_before_the_landing_gives_the_lowest_jump() -> bool:
	var rise: float = await _rise_after_landing(BUFFER_TIME, HEIGHT_PRESS_FRAME, false)
	if rise == NO_RUN:
		return report(false, "the player never landed")
	var one_frame_of_rise: float = STATS.get_jump_velocity() / Engine.physics_ticks_per_second
	var lowest: float = STATS.min_jump_height - TOLERANCE
	var highest: float = STATS.min_jump_height + one_frame_of_rise
	return report(rise >= lowest and rise <= highest,
			"Jump tapped on %s: rose %.1f px, allowed %.1f to %.1f px"
			% [_frame_text(HEIGHT_PRESS_FRAME), rise, lowest, highest])


func _jump_held_through_the_landing_gives_the_full_jump() -> bool:
	var rise: float = await _rise_after_landing(BUFFER_TIME, HEIGHT_PRESS_FRAME, true)
	if rise == NO_RUN:
		return report(false, "the player never landed")
	return report(absf(rise - STATS.jump_height) <= TOLERANCE,
			"Jump held from %s: rose %.1f px, Jump Height %.1f px"
			% [_frame_text(HEIGHT_PRESS_FRAME), rise, STATS.jump_height])


## Under a low ceiling the player bumps it at once and lands again inside Jump Buffer, so a jump
## must use the kept press up, or that one press makes it take off again on the new landing. This
## case counts take-offs, not jumps by speed, because the ceiling takes the jump's speed away within
## the take-off frame. The player's origin is at its feet, so its head is a body height above it.
func _one_press_under_a_low_ceiling_takes_off_once() -> bool:
	var player: Player = await spawn_on_floor(CEILING_SPOT)
	if player == null:
		return report(false, "the player never landed under the ceiling")
	player.stats.jump_buffer_time = BUFFER_TIME
	var head_y: float = player.position.y - body_size(player).y
	var ceiling: StaticBody2D = make_platform(CEILING_SPOT.x - CEILING_HALF_WIDTH,
			CEILING_SPOT.x + CEILING_HALF_WIDTH, head_y - CEILING_GAP - PLATFORM_THICKNESS)
	var take_offs: int = 0
	var was_on_floor: bool = true
	var last_y: float = player.position.y
	Input.action_press(&"jump")
	for _frame: int in FRAMES_TO_WATCH:
		await physics_frame
		Input.action_release(&"jump")
		var on_floor: bool = player.is_on_floor()
		if was_on_floor and not on_floor and player.position.y < last_y:
			take_offs += 1
		was_on_floor = on_floor
		last_y = player.position.y
	player.queue_free()
	ceiling.queue_free()
	return report(take_offs == ONE_TAKE_OFF,
			"One press under a ceiling %.0f px above the head: %d take-off(s), expected %d"
			% [CEILING_GAP, take_offs, ONE_TAKE_OFF])


func _expect_jump(buffer_time: float, press_frame: int, should_jump: bool) -> bool:
	var rise: float = await _rise_after_landing(buffer_time, press_frame, false)
	if rise == NO_RUN:
		return report(false, "the player never landed")
	var jumped: bool = rise > TOLERANCE
	return report(jumped == should_jump, "Jump Buffer %.2f s, Jump on %s: rose %.1f px, expected %s"
			% [buffer_time, _frame_text(press_frame), rise, "a jump" if should_jump else "no jump"])


## Drops the player without jumping and returns the frame of the drop on which it is first on the
## floor, or NEVER_REACHED. Like every drop, it starts inside a physics frame.
func _frames_until_landing() -> int:
	await physics_frame
	var player: Player = spawn_player(DROP_POSITION)
	var frames: int = NEVER_REACHED
	for frame: int in MAX_FRAMES:
		await physics_frame
		if player.is_on_floor():
			frames = frame + 1
			break
	player.queue_free()
	return frames


## Drops the player with Jump Buffer at buffer_time and presses Jump so that it counts on
## press_frame before the landing, letting go on the next frame unless hold is true. Returns how
## high the player rose after landing, 0 if it did not jump, or NO_RUN if it never landed.
func _rise_after_landing(buffer_time: float, press_frame: int, hold: bool) -> float:
	await physics_frame
	var player: Player = spawn_player(DROP_POSITION)
	player.stats.jump_buffer_time = buffer_time
	var press_at: int = _press_frame_in_run(press_frame)
	var landed: bool = false
	var landing_y: float = 0.0
	var top_y: float = 0.0
	for frame: int in _landing_frame + FRAMES_TO_WATCH:
		if frame == press_at:
			Input.action_press(&"jump")
		await physics_frame
		if not hold:
			Input.action_release(&"jump")
		if landed:
			top_y = minf(top_y, player.position.y)
		elif player.is_on_floor():
			landed = true
			landing_y = player.position.y
			top_y = landing_y
	Input.action_release(&"jump")
	player.queue_free()
	if not landed:
		return NO_RUN
	return landing_y - top_y


## The frame of a drop on which to press Jump so that it counts on frames_before_landing: frame j
## before the landing comes _landing_frame + 1 - j frames into the drop.
func _press_frame_in_run(frames_before_landing: int) -> int:
	return _landing_frame + 1 - frames_before_landing - PRESS_DELAY_FRAMES


func _frame_text(frames_before_landing: int) -> String:
	if frames_before_landing == FIRST_FLOOR_FRAME:
		return "the first frame on the floor"
	return "frame %d before the landing" % frames_before_landing
