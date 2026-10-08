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
## Walls have their face at x = 0 and stand left of it, this thick, from WALL_REACH px above the
## height they are made for to WALL_REACH px below it: past where any measure goes.
const WALL_THICKNESS: float = 200.0
const WALL_REACH: float = 5000.0
## How far from a wall's face the player starts, in px: a push into the wall reaches it on the first
## frame.
const WALL_GAP: float = 1.0
## How much faster than on the frame before the player must go up to count as jumping, in px/s, as
## in the tests. A jump adds over 1300.
const JUMP_KICK: float = 1.0
## The first frame in the air a kick in the corner is tried on: Jump stays held for the first frame
## in the air, is let go for one frame and pressed again, and that press counts PRESS_DELAY_FRAMES
## frames later.
const FIRST_KICK_FRAME: int = PRESS_DELAY_FRAMES + 2
## The chimney search starts between these widths, wall face to wall face, in px: the first is the
## test room's, which test_wall_jump.gd climbs pressing only Jump, and the second is never climbed.
const NARROW_CHIMNEY: float = 120.0
const HOPELESS_CHIMNEY: float = 2000.0
## How close, in px, the chimney search gets to the widest chimney climbed.
const CHIMNEY_PRECISION: float = 1.0
## Kicks a climb follows, as in test_wall_jump.gd.
const CLIMB_KICKS: int = 4

var _failed: bool = false
## Frames in a row the player has touched a wall, for _tap_late.
var _frames_on_wall: int = 0


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
	var wall: StaticBody2D = _make_wall(AIR_SPAWN_POSITION.y)
	root.add_child(wall)
	await _measure_wall_slide()
	await _measure_kick()
	await _measure_chimneys()
	await _measure_single_wall()
	wall.queue_free()
	var corner_floor: StaticBody2D = _make_platform(-GROUND_HALF_WIDTH, GROUND_HALF_WIDTH)
	var corner_wall: StaticBody2D = _make_wall(0.0)
	root.add_child(corner_floor)
	root.add_child(corner_wall)
	await _measure_corner()
	corner_floor.queue_free()
	corner_wall.queue_free()
	quit(1 if _failed else 0)


## A box from x = left to x = right and from y = top down to y = bottom.
func _make_box(left: float, right: float, top: float, bottom: float) -> StaticBody2D:
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(right - left, bottom - top)
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	var box: StaticBody2D = StaticBody2D.new()
	box.position = Vector2((left + right) / 2.0, (top + bottom) / 2.0)
	box.add_child(collision)
	return box


## A platform from x = left to x = right, with its top edge at y = 0.
func _make_platform(left: float, right: float) -> StaticBody2D:
	return _make_box(left, right, 0.0, GROUND_THICKNESS)


## A wall with its face at x = 0, standing left of it, around the height y.
func _make_wall(y: float) -> StaticBody2D:
	return _make_box(-WALL_THICKNESS, 0.0, y - WALL_REACH, y + WALL_REACH)


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


## A player in the air with the left side of its body gap px from a wall's face at x = 0, at the
## height y. Waits one physics frame, so the player is already falling.
func _spawn_by_the_wall(y: float, gap: float = WALL_GAP) -> Player:
	var player: Player = PLAYER_SCENE.instantiate() as Player
	player.position = Vector2(_half_width(player) + gap, y)
	root.add_child(player)
	await physics_frame
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


## The slide: falling at top speed by the wall, the player pushes into it. Prints the falling speed
## before the push and from the frame after the first touch, and the time the slide takes to go
## down one body height.
func _measure_wall_slide() -> void:
	var player: Player = await _spawn_by_the_wall(AIR_SPAWN_POSITION.y)
	for _frame: int in MAX_FRAMES:
		if player.velocity.y >= player.stats.max_fall_speed:
			break
		await physics_frame
	var falling_speed: float = player.velocity.y
	Input.action_press(&"move_left")
	if not await _wait_until_on_wall(player):
		_fail("the player never got to the wall")
	await physics_frame
	var sliding_speed: float = player.velocity.y
	var body_height: float = _body_size(player).y
	var start_y: float = player.position.y
	var frames: int = 0
	while player.position.y - start_y < body_height and frames < MAX_FRAMES:
		await physics_frame
		frames += 1
	Input.action_release(&"move_left")
	print(("Wall slide: falling at %.1f px/s, then %.1f px/s from the frame after touching the "
			+ "wall; one body height (%.0f px) slid in %s")
			% [falling_speed, sliding_speed, body_height, _frames_text(frames)])
	player.queue_free()


## A kick off the wall from a slide down it, with Jump held and the run held away from the wall from
## the kick on. Prints, from the take-off, how high the kick peaks, after how long and how far from
## the wall, how far the lock carries the player, and how far from the wall it is when it is back at
## the take-off height.
func _measure_kick() -> void:
	var player: Player = await _spawn_by_the_wall(AIR_SPAWN_POSITION.y)
	Input.action_press(&"move_left")
	if not await _wait_until_on_wall(player):
		_fail("the player never got to the wall")
	await physics_frame
	Input.action_press(&"jump")
	var take_off: Vector2 = player.position
	var previous_speed: float = player.velocity.y
	var kicked: bool = false
	for _frame: int in MAX_FRAMES:
		take_off = player.position
		await physics_frame
		if _is_jump(previous_speed, player.velocity.y):
			kicked = true
			break
		previous_speed = player.velocity.y
	Input.action_release(&"move_left")
	Input.action_press(&"move_right")
	var half_width: float = _half_width(player)
	var lock_frames: int = player.stats.get_wall_jump_lock_frames()
	# Frames count from 1, the frame of the kick, which has already run.
	var frames: int = 1
	var lock_px: float = player.position.x - take_off.x
	var peak: Vector2 = player.position
	var peak_frame: int = frames
	while kicked and player.position.y < take_off.y and frames < MAX_FRAMES:
		await physics_frame
		frames += 1
		if frames == lock_frames:
			lock_px = player.position.x - take_off.x
		if player.position.y < peak.y:
			peak = player.position
			peak_frame = frames
	Input.action_release(&"move_right")
	Input.action_release(&"jump")
	if not kicked:
		_fail("the player never kicked off the wall")
	print(("Kick off a slide, Jump held, run held away: peak %.1f px above the take-off after %s, "
			+ "%.1f px from the wall; the lock carries it %.1f px in %s; back at the take-off "
			+ "height %.1f px from the wall")
			% [take_off.y - peak.y, _frames_text(peak_frame), peak.x - half_width, lock_px,
			_frames_text(lock_frames), player.position.x - half_width])
	player.queue_free()


## Chimneys between the wall and a second one facing it: the widest climbed pressing only Jump on
## touching a wall, and a little late, how much each kick climbs in the narrow one, and the widest
## climbed with the best input.
func _measure_chimneys() -> void:
	var narrow: Array[float] = await _chimney_take_offs(NARROW_CHIMNEY, _tap_on_touch)
	var widest_tapping: float = await _widest_chimney(_tap_on_touch)
	var widest_late: float = await _widest_chimney(_tap_late)
	var widest_best: float = await _widest_chimney(_best_chimney_input)
	print(("Chimney, pressing only Jump on touching a wall: widest climbed %.0f px wall to wall; "
			+ "%.0f px wide, each kick climbs %s")
			% [widest_tapping, NARROW_CHIMNEY, _range_text(_climbs_per_kick(narrow), "%.1f")])
	print(("Chimney, pressing only Jump %d frames after touching a wall: widest climbed %.0f px "
			+ "wall to wall") % [STATS.get_coyote_frames(), widest_late])
	print("Chimney, best input: widest climbed %.0f px wall to wall" % widest_best)


## A single wall, with the best input for climbing it: the run held into the wall all along, and
## Jump as in _hold_up_press_down. Prints how much lower each kick takes off than the one before.
func _measure_single_wall() -> void:
	var player: Player = await _spawn_by_the_wall(AIR_SPAWN_POSITION.y, 0.0)
	Input.action_press(&"move_left")
	var take_offs: Array[float] = await _take_offs(player, _hold_up_press_down)
	_release_all()
	player.queue_free()
	var drops: Array[float] = []
	for climb: float in _climbs_per_kick(take_offs):
		drops.append(-climb)
	print("Single wall, best input: each kick takes off %s lower than the one before"
			% _range_text(drops, "%.1f"))


## Widest chimney, wall face to wall face, that drive climbs, in px. Each try halves the range
## between a width that was climbed and one that was not, as the gap search does.
func _widest_chimney(drive: Callable) -> float:
	var climbed: float = NARROW_CHIMNEY
	var not_climbed: float = HOPELESS_CHIMNEY
	if not _climbs(await _chimney_take_offs(climbed, drive)):
		_fail("a chimney %.0f px wide was not climbed" % climbed)
	while not_climbed - climbed > CHIMNEY_PRECISION:
		var middle: float = (climbed + not_climbed) / 2.0
		if _climbs(await _chimney_take_offs(middle, drive)):
			climbed = middle
		else:
			not_climbed = middle
	return climbed


## The take-offs of CLIMB_KICKS kicks with drive, starting against the wall, in a chimney width px
## wide, wall face to wall face, between the wall and a second one facing it.
func _chimney_take_offs(width: float, drive: Callable) -> Array[float]:
	_frames_on_wall = 0
	var y: float = AIR_SPAWN_POSITION.y
	var other_wall: StaticBody2D = _make_box(width, width + WALL_THICKNESS, y - WALL_REACH,
			y + WALL_REACH)
	root.add_child(other_wall)
	var player: Player = await _spawn_by_the_wall(y, 0.0)
	var take_offs: Array[float] = await _take_offs(player, drive)
	_release_all()
	player.queue_free()
	other_wall.queue_free()
	return take_offs


## Calls drive(player) before every frame until the player has made CLIMB_KICKS jumps, or
## MAX_FRAMES go by, and returns the height each jump took off from, in px above the start.
func _take_offs(player: Player, drive: Callable) -> Array[float]:
	var start_y: float = player.position.y
	var take_offs: Array[float] = []
	var previous_speed: float = player.velocity.y
	for _frame: int in MAX_FRAMES:
		drive.call(player)
		var take_off_y: float = player.position.y
		await physics_frame
		if _is_jump(previous_speed, player.velocity.y):
			take_offs.append(start_y - take_off_y)
			if take_offs.size() == CLIMB_KICKS:
				break
		previous_speed = player.velocity.y
	return take_offs


## True if take_offs holds CLIMB_KICKS jumps and each took off higher than the one before.
func _climbs(take_offs: Array[float]) -> bool:
	if take_offs.size() < CLIMB_KICKS:
		return false
	for climb: float in _climbs_per_kick(take_offs):
		if climb <= 0.0:
			return false
	return true


## How much higher each take-off is than the one before, in px.
func _climbs_per_kick(take_offs: Array[float]) -> Array[float]:
	var climbs: Array[float] = []
	for i: int in range(1, take_offs.size()):
		climbs.append(take_offs[i] - take_offs[i - 1])
	return climbs


## Jump pressed while the player touches a wall and let go while it is off the walls, with no
## direction: one press per wall, as a person taps, as in test_wall_jump.gd.
func _tap_on_touch(player: Player) -> void:
	if player.is_on_wall():
		Input.action_press(&"jump")
	else:
		Input.action_release(&"jump")


## As _tap_on_touch, but Jump is pressed only once the player has touched a wall for Coyote Time's
## frames in a row: a person tapping a little late.
func _tap_late(player: Player) -> void:
	_frames_on_wall = _frames_on_wall + 1 if player.is_on_wall() else 0
	if _frames_on_wall > STATS.get_coyote_frames():
		Input.action_press(&"jump")
	else:
		Input.action_release(&"jump")


## Jump for the best climb, as in test_wall_jump.gd: held on the way up, for full jumps, and pressed
## again every other frame on the way down, so a fresh press is always kept for the moment the
## player gets to a wall.
func _hold_up_press_down(player: Player) -> void:
	if player.velocity.y < 0.0 or not Input.is_action_pressed(&"jump"):
		Input.action_press(&"jump")
	else:
		Input.action_release(&"jump")


## The best climb up a chimney: Jump as in _hold_up_press_down, and the run held toward the wall the
## player flies to, so it gets there as soon as it can.
func _best_chimney_input(player: Player) -> void:
	_hold_up_press_down(player)
	if player.velocity.x > 0.0:
		Input.action_release(&"move_left")
		Input.action_press(&"move_right")
	elif player.velocity.x < 0.0:
		Input.action_release(&"move_right")
		Input.action_press(&"move_left")


## The corner: on the floor against the wall, a full jump up along it, then a kick off it. The kick
## is tried on every frame in the air from FIRST_KICK_FRAME on, until the player lands before it.
## Prints the highest peak above the floor, the frame in the air its kick came on, how far from the
## wall that peak is, and the lowest peak with the kick up to Coyote Time's frames off that frame.
func _measure_corner() -> void:
	var tries: Array[CornerResult] = []
	for kick_frame: int in range(FIRST_KICK_FRAME, MAX_FRAMES):
		var corner: CornerResult = await _corner_try(kick_frame)
		if not corner.kicked:
			break
		tries.append(corner)
	if tries.is_empty():
		_fail("the player never kicked off the wall in the corner")
		return
	var best: CornerResult = tries[0]
	for corner: CornerResult in tries:
		if corner.peak_px > best.peak_px:
			best = corner
	var off_frames: int = STATS.get_coyote_frames()
	var lowest_near_best: float = best.peak_px
	for corner: CornerResult in tries:
		if absi(corner.kick_frame - best.kick_frame) <= off_frames:
			lowest_near_best = minf(lowest_near_best, corner.peak_px)
	print(("Corner, a full jump up along the wall and a kick off it, Jump held, run held away: "
			+ "highest peak %.1f px above the floor, kicking on frame %d in the air, %.1f px from "
			+ "the wall; with the kick up to %d frames off that frame, at least %.1f px")
			% [best.peak_px, best.kick_frame, best.peak_from_wall_px, off_frames, lowest_near_best])


## One try in the corner: standing against the wall, a full jump up along it, pushing into the wall,
## then Jump let go for a frame and pressed again to count on air frame kick_frame. From the kick
## on, the run is held away from the wall, until the peak. The result says if the kick came before
## the landing.
func _corner_try(kick_frame: int) -> CornerResult:
	var result: CornerResult = CornerResult.new()
	var player: Player = await _spawn_by_the_wall(FLOOR_SPAWN_POSITION.y)
	if not await _wait_until_on_floor(player):
		_fail("the player never landed by the wall")
	Input.action_press(&"move_left")
	if not await _wait_until_on_wall(player):
		_fail("the player never got to the wall")
	Input.action_press(&"jump")
	var floor_y: float = player.position.y
	var previous_speed: float = player.velocity.y
	var air_frames: int = 0
	for _frame: int in MAX_FRAMES:
		if air_frames == kick_frame - PRESS_DELAY_FRAMES - 1:
			Input.action_release(&"jump")
		elif air_frames == kick_frame - PRESS_DELAY_FRAMES:
			Input.action_press(&"jump")
		await physics_frame
		if player.is_on_floor():
			if air_frames > 0:
				break
			floor_y = player.position.y
			continue
		air_frames += 1
		# Frame 1 in the air is the jump off the floor; a jump after it is the kick.
		if air_frames > 1 and _is_jump(previous_speed, player.velocity.y):
			result.kicked = true
			result.kick_frame = air_frames
			break
		previous_speed = player.velocity.y
	Input.action_release(&"move_left")
	if result.kicked:
		Input.action_press(&"move_right")
		var peak: Vector2 = player.position
		for _frame: int in MAX_FRAMES:
			if player.velocity.y >= 0.0:
				break
			await physics_frame
			if player.position.y < peak.y:
				peak = player.position
		Input.action_release(&"move_right")
		result.peak_px = floor_y - peak.y
		result.peak_from_wall_px = peak.x - _half_width(player)
	Input.action_release(&"jump")
	player.queue_free()
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


## The size of the player's collision box, read from its scene.
func _body_size(player: Player) -> Vector2:
	var collision: CollisionShape2D = player.get_node(^"CollisionShape2D") as CollisionShape2D
	return (collision.shape as RectangleShape2D).size


## Half the width of the player's collision box.
func _half_width(player: Player) -> float:
	return _body_size(player).x / 2.0


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


func _wait_until_on_wall(player: Player) -> bool:
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if player.is_on_wall():
			return true
	return false


## True if the player goes up, and faster than on the frame before, which only a jump does, as in
## the tests.
func _is_jump(previous_speed: float, speed: float) -> bool:
	return speed < 0.0 and speed < previous_speed - JUMP_KICK


func _release_all() -> void:
	for action: StringName in [&"move_left", &"move_right", &"jump"]:
		Input.action_release(action)


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


## What _corner_try measures: whether the kick came before the landing, the frame in the air it came
## on, and the peak after it, in px above the floor and from the wall.
class CornerResult:
	var kicked: bool = false
	var kick_frame: int = 0
	var peak_px: float = 0.0
	var peak_from_wall_px: float = 0.0
