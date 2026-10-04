# Prints the movement numbers the README quotes, measured with the player's own scene and Stats at
# 60 physics frames per second. It checks nothing: after changing a value in Stats, run it and copy
# the new numbers into the README. The exit code is 1 only if a measure could not finish. Where a
# run meets the end of a ledge within a frame changes the ledge measures by a few px, so they run
# from every spot over one frame of top speed and print the smallest and largest result.
# Run from the repository root:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/measure_movement.gd
extends SceneTree

const PLAYER_SCENE: PackedScene = preload("res://scenes/actors/player.tscn")
## The player's Stats, the same resource its scene uses, read here before any player exists.
const STATS: PlayerMovementStats = preload("res://resources/player_movement_stats.tres")
## Half the width of the ground: wide enough that the player never runs off it.
const GROUND_HALF_WIDTH: float = 50000.0
const GROUND_THICKNESS: float = 100.0
## A little above the ground, so the player lands on its own.
const FLOOR_SPAWN_POSITION: Vector2 = Vector2(0.0, -2.0)
## Far above the ground, so the player is still falling when a measure ends.
const AIR_SPAWN_POSITION: Vector2 = Vector2(0.0, -100000.0)
## Physics frames to wait for anything before giving up.
const MAX_FRAMES: int = 600
## What _frames_until_speed and _frames_until_off_the_ledge return when it never happens.
const NEVER_REACHED: int = -1
## For _jump: a frame in the air that never comes, so Jump is held to the landing.
const NEVER: int = -1
## Frame in the air on which Jump is let go for the lowest jump: the first one.
const LET_GO_AT_ONCE: int = 1
## Seconds Jump stays held, from the take-off, for a short jump between the lowest and the full one.
const SHORT_HOLD_SECONDS: float = 0.1
## Where the gap runs start, on the near ledge, which ends at x = 0: far enough to reach top speed.
const RUN_UP_POSITION: Vector2 = Vector2(-1000.0, -2.0)
## The ledge measures also start from spots behind it, this many px apart, over one frame of top
## speed.
const RUN_UP_STEP: float = 1.0
## A press made after f frames of a run counts as just pressed on frame f + PRESS_DELAY_FRAMES of
## that run: frame f + 1 is the one about to run, and a script's press only counts from the frame
## after it.
const PRESS_DELAY_FRAMES: int = 2
## The gap search starts between these widths, in px: the first is always cleared, the second never.
const NO_GAP: float = 0.0
const HOPELESS_GAP: float = 2000.0
## How close, in px, the gap search gets to the widest gap cleared.
const GAP_PRECISION: float = 1.0
## How far below the ledges the player counts as fallen into the gap, in px.
const FALL_DEPTH: float = 200.0
## Frames in the air count from 1, the first frame off the floor; 0 is the last frame on it.
const LAST_FLOOR_FRAME: int = 0

var _failed: bool = false


func _initialize() -> void:
	var ground: StaticBody2D = _make_platform(-GROUND_HALF_WIDTH, GROUND_HALF_WIDTH)
	root.add_child(ground)
	var runner: Player = await _spawn_on_floor(FLOOR_SPAWN_POSITION)
	await _measure_ramps("Run", runner)
	var flyer: Player = await _spawn_in_air()
	if is_zero_approx(flyer.stats.air_control):
		print("In the air: Air Control 0, the speed stays as it was when the player left the floor")
		flyer.queue_free()
	else:
		await _measure_ramps("In the air", flyer)
	await _measure_fall()
	await _measure_jumps()
	ground.queue_free()
	var near_ledge: StaticBody2D = _make_platform(-GROUND_HALF_WIDTH, 0.0)
	root.add_child(near_ledge)
	var coyote_frames: int = STATS.get_coyote_frames()
	await _measure_widest_gap("Widest gap a running jump clears", LAST_FLOOR_FRAME)
	await _measure_late_jump(coyote_frames)
	await _measure_widest_gap("Widest gap with the jump on the last frame of Coyote Time "
			+ "(%d frames late)" % coyote_frames, coyote_frames)
	near_ledge.queue_free()
	quit(1 if _failed else 0)


## A platform from x = left to x = right, with its top edge at y = 0.
func _make_platform(left: float, right: float) -> StaticBody2D:
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(right - left, GROUND_THICKNESS)
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	var platform: StaticBody2D = StaticBody2D.new()
	platform.position = Vector2((left + right) / 2.0, GROUND_THICKNESS / 2.0)
	platform.add_child(collision)
	return platform


func _spawn_on_floor(at: Vector2) -> Player:
	var player: Player = _spawn(at)
	if not await _wait_until_on_floor(player):
		_fail("the player never landed")
	return player


## Waits one physics frame, so the player is already falling, and its physics already runs.
func _spawn_in_air() -> Player:
	var player: Player = _spawn(AIR_SPAWN_POSITION)
	await physics_frame
	return player


func _spawn(at: Vector2) -> Player:
	var player: Player = PLAYER_SCENE.instantiate() as Player
	player.position = at
	root.add_child(player)
	return player


## From standing still to top speed holding Right, then to a stop after letting go.
func _measure_ramps(label: String, player: Player) -> void:
	player.velocity.x = 0.0
	var start_x: float = player.position.x
	Input.action_press(&"move_right")
	var speed_up_frames: int = await _frames_until_speed(player, player.stats.max_run_speed)
	Input.action_release(&"move_right")
	var speed_up_px: float = player.position.x - start_x
	var stop_start_x: float = player.position.x
	var stop_frames: int = await _frames_until_speed(player, 0.0)
	var stop_px: float = player.position.x - stop_start_x
	print("%s: top speed after %s and %.1f px; stops %s and %.1f px after letting go"
			% [label, _frames_text(speed_up_frames), speed_up_px, _frames_text(stop_frames), stop_px])
	player.queue_free()


## From standing still in the air: time and distance to the top falling speed.
func _measure_fall() -> void:
	var player: Player = await _spawn_in_air()
	player.velocity = Vector2.ZERO
	var start_y: float = player.position.y
	var frames: int = 0
	while player.velocity.y < player.stats.max_fall_speed:
		if frames == MAX_FRAMES:
			_fail("the player never reached the top falling speed")
			break
		await physics_frame
		frames += 1
	print("Fall: top falling speed after %s and %.1f px"
			% [_frames_text(frames), player.position.y - start_y])
	player.queue_free()


## Standing still: a full jump, the lowest jump and a short one. Then a full jump at top speed.
func _measure_jumps() -> void:
	var player: Player = await _spawn_on_floor(FLOOR_SPAWN_POSITION)
	var full: JumpResult = await _jump(player, NEVER)
	print("Full jump: peak %.1f px after %s; back on the floor %s later; %s in the air"
			% [full.peak_px, _frames_text(full.peak_frame),
			_frames_text(full.air_frames - full.peak_frame), _frames_text(full.air_frames)])
	var lowest: JumpResult = await _jump(player, LET_GO_AT_ONCE)
	print("Lowest jump, Jump let go at once: peak %.1f px" % lowest.peak_px)
	var short_hold_frames: int = roundi(SHORT_HOLD_SECONDS * Engine.physics_ticks_per_second)
	var short: JumpResult = await _jump(player, short_hold_frames)
	print("Short jump, Jump held %.2f s from the take-off: peak %.1f px"
			% [SHORT_HOLD_SECONDS, short.peak_px])
	Input.action_press(&"move_right")
	await _frames_until_speed(player, player.stats.max_run_speed)
	var running: JumpResult = await _jump(player, NEVER)
	Input.action_release(&"move_right")
	print("Running jump: %.1f px sideways from take-off to landing, %s in the air"
			% [running.sideways_px, _frames_text(running.air_frames)])
	player.queue_free()


## Jumps from the floor and measures the jump. Frames in the air count from 1: Jump is let go on
## let_go_frame, and NEVER holds it to the landing. A direction held before the call stays held.
## A press from a script counts as just pressed from the next physics frame on, so the take-off
## comes a frame after the press: the start follows the player until it leaves the floor.
func _jump(player: Player, let_go_frame: int) -> JumpResult:
	var result: JumpResult = JumpResult.new()
	if not await _wait_until_on_floor(player):
		_fail("the player never landed before a jump")
		return result
	var start: Vector2 = player.position
	var peak_y: float = start.y
	var landed: bool = false
	Input.action_press(&"jump")
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if player.is_on_floor():
			if result.air_frames > 0:
				landed = true
				break
			start = player.position
			continue
		result.air_frames += 1
		if result.air_frames == let_go_frame:
			Input.action_release(&"jump")
		if player.position.y < peak_y:
			peak_y = player.position.y
			result.peak_frame = result.air_frames
	Input.action_release(&"jump")
	if not landed:
		_fail("the player did not jump, or never landed")
	result.peak_px = start.y - peak_y
	result.sideways_px = player.position.x - start.x
	return result


## Widest gap between two ledges that a running jump on air_frame clears, in px, from the near
## ledge already in place and from every run-up spot. A first run from each spot, without jumping,
## finds the frame on which the player runs off the ledge. Then each try halves the range between a
## gap that was cleared and one that was not.
func _measure_widest_gap(label: String, air_frame: int) -> void:
	var widest: Array[float] = []
	for run_up: Vector2 in _run_up_spots():
		var off_the_ledge_frame: int = await _frames_until_off_the_ledge(run_up)
		if off_the_ledge_frame == NEVER_REACHED:
			_fail("the player never ran off the ledge")
			return
		var press_frame: int = _press_frame_in_run(off_the_ledge_frame, air_frame)
		var cleared: float = NO_GAP
		var missed: float = HOPELESS_GAP
		while missed - cleared > GAP_PRECISION:
			var gap: float = floorf((cleared + missed) / 2.0)
			if await _clears_gap(gap, run_up, press_frame):
				cleared = gap
			else:
				missed = gap
		widest.append(cleared)
	print("%s, ledge to ledge: %s" % [label, _range_text(widest, "%.0f")])


## True if a running jump from the near ledge, which ends at x = 0, lands on a far ledge that starts
## at x = gap.
func _clears_gap(gap: float, run_up: Vector2, press_frame: int) -> bool:
	var far_ledge: StaticBody2D = _make_platform(gap, gap + GROUND_HALF_WIDTH)
	root.add_child(far_ledge)
	var cleared: bool = await _jumps_across(run_up, press_frame)
	far_ledge.queue_free()
	return cleared


## A running jump off the end of the near ledge on the last frame of Coyote Time, with nothing past
## the ledge, from every run-up spot: how far below the ledge and past its end the player takes off,
## and how high above the ledge it peaks.
func _measure_late_jump(coyote_frames: int) -> void:
	var depths: Array[float] = []
	var pasts: Array[float] = []
	var peaks: Array[float] = []
	for run_up: Vector2 in _run_up_spots():
		var off_the_ledge_frame: int = await _frames_until_off_the_ledge(run_up)
		if off_the_ledge_frame == NEVER_REACHED:
			_fail("the player never ran off the ledge")
			return
		var late: LateJumpResult = await _late_jump(run_up,
				_press_frame_in_run(off_the_ledge_frame, coyote_frames))
		if late == null:
			_fail("the player did not jump on the last frame of Coyote Time")
			return
		depths.append(late.depth_px)
		pasts.append(late.past_px)
		peaks.append(late.peak_px)
	print(("Jump on the last frame of Coyote Time (%d frames late): takes off %s below the ledge, "
			+ "with the back of the body %s past its end, and peaks %s above the ledge")
			% [coyote_frames, _range_text(depths, "%.1f"), _range_text(pasts, "%.1f"),
			_range_text(peaks, "%.1f")])


## Runs right from run_up, presses Jump after press_frame frames and measures the jump, or returns
## null if the player does not jump.
func _late_jump(run_up: Vector2, press_frame: int) -> LateJumpResult:
	var player: Player = await _spawn_on_floor(run_up)
	var ledge_y: float = player.position.y
	Input.action_press(&"move_right")
	await _wait_frames(press_frame)
	Input.action_press(&"jump")
	var before_take_off: Vector2 = player.position
	var top_y: float = INF
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if player.velocity.y < 0.0:
			top_y = minf(top_y, player.position.y)
		elif top_y < INF:
			break
		else:
			before_take_off = player.position
	Input.action_release(&"move_right")
	Input.action_release(&"jump")
	var back_of_the_body: float = before_take_off.x - _half_width(player)
	player.queue_free()
	if top_y == INF:
		return null
	var result: LateJumpResult = LateJumpResult.new()
	result.depth_px = before_take_off.y - ledge_y
	result.past_px = back_of_the_body
	result.peak_px = ledge_y - top_y
	return result


## RUN_UP_POSITION and the spots behind it, RUN_UP_STEP px apart, over one frame of top speed.
func _run_up_spots() -> Array[Vector2]:
	var px_per_frame: float = STATS.max_run_speed / Engine.physics_ticks_per_second
	var spots: Array[Vector2] = []
	for step: int in ceili(px_per_frame / RUN_UP_STEP):
		spots.append(RUN_UP_POSITION + Vector2.LEFT * step * RUN_UP_STEP)
	return spots


## The frame of a run on which to press Jump for it to count on air_frame: frame k in the air comes
## off_the_ledge_frame + k frames into the run.
func _press_frame_in_run(off_the_ledge_frame: int, air_frame: int) -> int:
	return off_the_ledge_frame + air_frame - PRESS_DELAY_FRAMES


## One number when all the values print the same, or "smallest to largest" otherwise, in px.
func _range_text(values: Array[float], number_format: String) -> String:
	var lowest: String = number_format % values.min()
	var highest: String = number_format % values.max()
	if lowest == highest:
		return lowest + " px"
	return "%s to %s px" % [lowest, highest]


## Half the width of the player's collision box, read from its scene.
func _half_width(player: Player) -> float:
	var collision: CollisionShape2D = player.get_node(^"CollisionShape2D") as CollisionShape2D
	return (collision.shape as RectangleShape2D).size.x / 2.0


## Runs right from run_up without jumping and returns the frame of the run on which the player is
## first off the floor, or NEVER_REACHED if it never falls.
func _frames_until_off_the_ledge(run_up: Vector2) -> int:
	var player: Player = await _spawn_on_floor(run_up)
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


## Runs right from run_up, presses Jump after press_frame frames and holds it. True if the player
## lands again, which past the near ledge can only happen on the far one.
func _jumps_across(run_up: Vector2, press_frame: int) -> bool:
	var player: Player = await _spawn_on_floor(run_up)
	Input.action_press(&"move_right")
	await _wait_frames(press_frame)
	Input.action_press(&"jump")
	var left_floor: bool = false
	var landed: bool = false
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if not player.is_on_floor():
			left_floor = true
			if player.position.y > FALL_DEPTH:
				break
		elif left_floor:
			landed = true
			break
	Input.action_release(&"move_right")
	Input.action_release(&"jump")
	player.queue_free()
	return landed


func _frames_until_speed(player: Player, target: float) -> int:
	for frame: int in MAX_FRAMES:
		await physics_frame
		if is_equal_approx(player.velocity.x, target):
			return frame + 1
	_fail("the speed never reached %.1f px/s" % target)
	return NEVER_REACHED


func _wait_frames(count: int) -> void:
	for _frame: int in count:
		await physics_frame


func _wait_until_on_floor(player: Player) -> bool:
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if player.is_on_floor():
			return true
	return false


func _frames_text(frames: int) -> String:
	return "%d frames (%.2f s)" % [frames, float(frames) / Engine.physics_ticks_per_second]


func _fail(what: String) -> void:
	printerr("Could not measure: %s." % what)
	_failed = true


## What _jump measures: the peak in px above the floor, the frame in the air it happens on, the
## frames in the air, and the px moved sideways from the take-off to the landing.
class JumpResult:
	var peak_px: float = 0.0
	var peak_frame: int = 0
	var air_frames: int = 0
	var sideways_px: float = 0.0


## What _late_jump measures, in px: how far below the ledge the player takes off, how far past its
## end the back of the body is then, and how high above the ledge the jump peaks.
class LateJumpResult:
	var depth_px: float = 0.0
	var past_px: float = 0.0
	var peak_px: float = 0.0
