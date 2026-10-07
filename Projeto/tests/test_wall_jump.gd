# Checks the wall jump (ADR 0010). In the air against a wall, pushing into it or not, Jump kicks the
# player away from the wall at top running speed and as high as a full jump from the floor, and then
# the run does nothing for Wall Jump Lock Time, or until a landing. Against a wall the jump is the
# wall's, even with coyote frames left; one press makes one jump, and a press kept a little before
# touching the wall still kicks. So does a press for Coyote Time's frames after leaving the wall,
# and no longer; a kick or a landing uses that tolerance up. A single wall cannot be climbed, even
# with the best input, and a narrow chimney can, pressing only Jump.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_wall_jump.gd
extends "res://tests/support/player_test.gd"

## Which side of the player a wall is on, as the run direction that pushes into it.
const LEFT: float = -1.0
const RIGHT: float = 1.0
## Which way a climb goes, as the sign of the height gained from one wall jump to the next.
const HIGHER: float = 1.0
const LOWER: float = -1.0
## Walls have their face at x = WALL_FACE, unless a case moves one, and go from WALL_TOP down to
## WALL_BOTTOM, far past where any case goes.
const WALL_FACE: float = 0.0
const WALL_THICKNESS: float = 200.0
const WALL_TOP: float = -5000.0
const WALL_BOTTOM: float = 5000.0
## The floor's top is at y = 0, from behind the wall to FLOOR_RIGHT.
const FLOOR_RIGHT: float = 1000.0
## Where a case in the air starts, halfway down the walls.
const START_HEIGHT: float = 0.0
## Just above the floor, so a player spawned there lands on its first frames.
const FLOOR_SPAWN_HEIGHT: float = -2.0
## How far from the wall the player starts, in px.
const GAP: float = 40.0
## How far from the wall the player starts when it presses Jump before touching it, in px: far
## enough to press a whole Jump Buffer early, even at the top of its range.
const FAR_GAP: float = 200.0
## Frames to wait after a first contact or a change of input, so the player has settled.
const SETTLE_FRAMES: int = 3
## How high above the floor the player starts against the wall when it must land soon, in px.
const KICK_HEIGHT: float = 60.0
## A lock long enough to land in the middle of it, in s.
const LONG_LOCK_TIME: float = 1.0
## Width of the narrow chimney between its walls, in px: the player crosses it well inside the lock.
const CHIMNEY_GAP: float = 120.0
## Wall jumps a climb follows.
const KICKS: int = 4
## Frames to watch for a second jump after one press, well past Jump Buffer and Coyote Time.
const WATCH_FRAMES: int = 30
## How far a peak may be from Jump Height, in px, as in test_jump_height.gd.
const HEIGHT_TOLERANCE: float = 1.0
## How far a speed may be from the one expected, in px/s.
const SPEED_TOLERANCE: float = 0.01

## Half the width of the player's collision box, read from its scene.
var _half_width: float = 0.0


func _initialize() -> void:
	var probe: Player = PLAYER_SCENE.instantiate() as Player
	_half_width = body_size(probe).x / 2.0
	probe.queue_free()
	var results: Array[bool] = []
	results.append(await _kicking_off_a_wall_goes_away_at_top_speed_as_high_as_a_jump(LEFT))
	results.append(await _kicking_off_a_wall_goes_away_at_top_speed_as_high_as_a_jump(RIGHT))
	results.append(await _after_a_kick_the_run_does_nothing_for_the_lock())
	results.append(await _landing_ends_the_lock())
	results.append(await _one_press_makes_one_jump_the_walls_even_with_coyote_frames())
	results.append(await _a_press_kept_before_touching_the_wall_kicks())
	results.append(await _a_press_just_after_leaving_the_wall_kicks())
	results.append(await _a_press_one_frame_too_late_does_not_kick())
	results.append(await _a_new_press_right_after_a_kick_does_not_kick_again())
	results.append(await _landing_ends_the_walls_tolerance())
	results.append(await _a_single_wall_cannot_be_climbed_even_with_the_best_input())
	results.append(await _a_narrow_chimney_is_climbed_pressing_only_jump())
	finish(results)


## The kick, off a wall on either side: away from the wall at top running speed, and as high as a
## full jump from the floor, with Jump held.
func _kicking_off_a_wall_goes_away_at_top_speed_as_high_as_a_jump(side: float) -> bool:
	var what: String = "Kicking off a wall on the %s" % ("left" if side == LEFT else "right")
	var wall: StaticBody2D = _make_wall_on(side)
	var player: Player = await _spawn_sliding(side)
	if player == null:
		await _remove([wall])
		return report(false, "%s: never got on the wall" % what)
	Input.action_press(&"jump")
	var take_off_y: float = await _wait_for_jump(player)
	var kicked: bool = not is_nan(take_off_y)
	var speed: float = player.velocity.x
	var peak: float = 0.0
	if kicked:
		peak = take_off_y - await _highest_y(player)
	_release_all()
	var expected_speed: float = -side * player.stats.max_run_speed
	var expected_peak: float = player.stats.jump_height
	await _remove([player, wall])
	return report(kicked and absf(speed - expected_speed) <= SPEED_TOLERANCE
			and absf(peak - expected_peak) <= HEIGHT_TOLERANCE,
			"%s: speed %.1f px/s, expected %.1f px/s; peak %.1f px, Jump Height %.1f px%s"
			% [what, speed, expected_speed, peak, expected_peak, _note(kicked, "no wall jump")])


## The lock: from the kick on, the run does nothing for Wall Jump Lock Time, even pushing back into
## the wall all along, and then it turns the player back.
func _after_a_kick_the_run_does_nothing_for_the_lock() -> bool:
	var what: String = "Pushing back into the wall after a kick"
	var wall: StaticBody2D = _make_wall_on(LEFT)
	var player: Player = await _spawn_sliding(LEFT)
	if player == null:
		await _remove([wall])
		return report(false, "%s: never got on the wall" % what)
	Input.action_press(&"jump")
	var kicked: bool = not is_nan(await _wait_for_jump(player))
	var top_speed: float = player.stats.max_run_speed
	var locked_frames: int = 0
	while kicked and locked_frames < MAX_FRAMES and is_equal_approx(player.velocity.x, top_speed):
		locked_frames += 1
		await physics_frame
	var after_lock: float = player.velocity.x
	_release_all()
	var lock_frames: int = player.stats.get_wall_jump_lock_frames()
	await _remove([player, wall])
	return report(kicked and locked_frames == lock_frames and after_lock < top_speed,
			"%s: top speed for %d frames, Wall Jump Lock Time %d frames, then %.1f px/s%s"
			% [what, locked_frames, lock_frames, after_lock, _note(kicked, "no wall jump")])


## Landing ends the lock: with a lock long enough to land in the middle of it, a short kick off the
## wall lands, and on the next jump the run answers from the first frame in the air.
func _landing_ends_the_lock() -> bool:
	var what: String = "Landing in the middle of the lock"
	var wall: StaticBody2D = _make_wall_on(LEFT)
	var floor_body: StaticBody2D = make_platform(WALL_FACE - WALL_THICKNESS, FLOOR_RIGHT)
	var player: Player = spawn_player(Vector2(_x_near(LEFT, 0.0), -KICK_HEIGHT))
	player.stats.wall_jump_lock_time = LONG_LOCK_TIME
	var lock_frames: int = player.stats.get_wall_jump_lock_frames()
	await physics_frame
	Input.action_press(&"jump")
	var kicked: bool = not is_nan(await _wait_for_jump(player))
	# Let go at once, for a short jump that lands well inside the lock.
	Input.action_release(&"jump")
	var landing_frames: int = await _frames_until_on_floor(player)
	await _wait_until_stopped(player)
	Input.action_press(&"move_right")
	Input.action_press(&"jump")
	var jumped: bool = not is_nan(await _wait_for_jump(player))
	var take_off_speed: float = player.velocity.x
	await physics_frame
	var first_air_step: float = player.velocity.x - take_off_speed
	_release_all()
	var air_step: float = (player.stats.max_run_speed / player.stats.time_to_max_speed
			* player.stats.air_control / Engine.physics_ticks_per_second)
	await _remove([player, wall, floor_body])
	var landed_in_lock: bool = landing_frames != NEVER_REACHED and landing_frames < lock_frames
	return report(kicked and landed_in_lock and jumped
			and absf(first_air_step - air_step) <= SPEED_TOLERANCE,
			("%s: landed %d frames into a %d-frame lock; on the next jump, a first step in the air "
			+ "of %.1f px/s, air step %.1f px/s%s")
			% [what, landing_frames, lock_frames, first_air_step, air_step,
			_note(kicked, "no wall jump")])


## Against a wall the jump is the wall's, and one press makes one jump, as on the floor (ADR 0008).
## Standing against the wall without pushing, the floor goes away, and a press while coyote frames
## are left kicks off the wall. The kick uses the press and the coyote frames up, so nothing else
## jumps after it. A second jump on the very next frame would start at the kick's own speed, which
## is_jump cannot tell from the kick, so the case also checks that the climb is one jump high.
func _one_press_makes_one_jump_the_walls_even_with_coyote_frames() -> bool:
	var what: String = "One press against the wall with coyote frames left"
	var wall: StaticBody2D = _make_wall_on(LEFT)
	var floor_body: StaticBody2D = make_platform(WALL_FACE - WALL_THICKNESS, FLOOR_RIGHT)
	var player: Player = await spawn_on_floor(Vector2(_x_near(LEFT, GAP), FLOOR_SPAWN_HEIGHT))
	if player == null:
		await _remove([wall, floor_body])
		return report(false, "%s: never landed" % what)
	Input.action_press(_into(LEFT))
	var touched: bool = await _wait_until_on_wall(player)
	await _wait_frames(SETTLE_FRAMES)
	Input.action_release(_into(LEFT))
	await _wait_frames(SETTLE_FRAMES)
	# The floor goes at the end of this frame. The player still stands on it this frame and starts
	# the next one on it, which fills the coyote frames; a press made after this frame counts on the
	# first frame in the air.
	floor_body.queue_free()
	await physics_frame
	Input.action_press(&"jump")
	var jumps: int = 0
	var first_speed: float = 0.0
	var take_off_y: float = 0.0
	var highest_y: float = player.position.y
	var previous_speed: float = player.velocity.y
	for _frame: int in WATCH_FRAMES:
		var y_before: float = player.position.y
		await physics_frame
		if is_jump(previous_speed, player.velocity.y):
			if jumps == 0:
				first_speed = player.velocity.x
				take_off_y = y_before
			jumps += 1
		previous_speed = player.velocity.y
		highest_y = minf(highest_y, player.position.y)
	_release_all()
	var climb: float = take_off_y - highest_y if jumps > 0 else 0.0
	var jump_height: float = player.stats.jump_height
	await _remove([player, wall])
	return report(touched and jumps == 1 and first_speed > 0.0
			and absf(climb - jump_height) <= HEIGHT_TOLERANCE,
			("%s: %d jumps, the first leaving the wall at %.1f px/s and climbing %.1f px, "
			+ "Jump Height %.1f px%s")
			% [what, jumps, first_speed, climb, jump_height,
			_note(touched, "never touched the wall")])


## A press kept a little before touching the wall still kicks: flying into the wall, a press made a
## whole Jump Buffer before the first frame against it kicks on that frame.
func _a_press_kept_before_touching_the_wall_kicks() -> bool:
	var what: String = "A press kept before touching the wall"
	var wall: StaticBody2D = _make_wall_on(LEFT)
	var contact_frames: int = await _frames_until_on_wall()
	if contact_frames == NEVER_REACHED:
		await _remove([wall])
		return report(false, "%s: never reached the wall" % what)
	var player: Player = _spawn_flying_into_the_wall()
	var buffer_frames: int = player.stats.get_jump_buffer_frames()
	# The first frame against the wall is contact_frames + 1. A press made after f frames counts on
	# frame f + PRESS_DELAY_FRAMES and is kept for Jump Buffer's frames after it.
	await _wait_frames(contact_frames + 1 - PRESS_DELAY_FRAMES - buffer_frames)
	Input.action_press(&"jump")
	var kicked: bool = not is_nan(await _wait_for_jump(player))
	_release_all()
	await _remove([player, wall])
	return report(kicked,
			"%s: pressed %d frames before the first frame against it, the whole Jump Buffer%s"
			% [what, buffer_frames, _note(kicked, "no wall jump")])


## The wall's tolerance, like coyote time off the floor: pushing away from the wall, a press that
## counts on the last of Coyote Time's frames after the player left the wall still kicks away from it.
func _a_press_just_after_leaving_the_wall_kicks() -> bool:
	var what: String = "A press on the last frame of Coyote Time after leaving the wall"
	var wall: StaticBody2D = _make_wall_on(LEFT)
	var player: Player = await _spawn_leaving_the_wall(LEFT)
	if player == null:
		await _remove([wall])
		return report(false, "%s: never left the wall" % what)
	var coyote_frames: int = player.stats.get_coyote_frames()
	# Frame 1 off the wall is about to run, and a press made after w more frames counts on frame
	# w + PRESS_DELAY_FRAMES off the wall: here, the last of Coyote Time's frames.
	await _wait_frames(coyote_frames - PRESS_DELAY_FRAMES)
	Input.action_press(&"jump")
	var kicked: bool = not is_nan(await _wait_for_jump(player, WATCH_FRAMES))
	var speed: float = player.velocity.x if kicked else 0.0
	_release_all()
	var expected: float = player.stats.max_run_speed
	await _remove([player, wall])
	return report(kicked and is_equal_approx(speed, expected),
			"%s (%d frames): speed %.1f px/s, expected %.1f px/s%s"
			% [what, coyote_frames, speed, expected, _note(kicked, "no jump")])


## The wall's tolerance ends on time: a press one frame later than in the case above does not kick,
## and with no floor near it does not jump at all.
func _a_press_one_frame_too_late_does_not_kick() -> bool:
	var what: String = "A press one frame after Coyote Time after leaving the wall"
	var wall: StaticBody2D = _make_wall_on(LEFT)
	var player: Player = await _spawn_leaving_the_wall(LEFT)
	if player == null:
		await _remove([wall])
		return report(false, "%s: never left the wall" % what)
	await _wait_frames(player.stats.get_coyote_frames() + 1 - PRESS_DELAY_FRAMES)
	Input.action_press(&"jump")
	var jumps: int = await _count_jumps(player, WATCH_FRAMES)
	_release_all()
	await _remove([player, wall])
	return report(jumps == 0, "%s: %d jumps" % [what, jumps])


## A kick uses the wall's tolerance up: a new press just after a kick, while the player would still
## be inside Coyote Time from the wall, does not kick again.
func _a_new_press_right_after_a_kick_does_not_kick_again() -> bool:
	var what: String = "A new press right after a kick"
	var wall: StaticBody2D = _make_wall_on(LEFT)
	var player: Player = await _spawn_sliding(LEFT)
	if player == null:
		await _remove([wall])
		return report(false, "%s: never got on the wall" % what)
	Input.action_press(&"jump")
	var kicked: bool = not is_nan(await _wait_for_jump(player))
	Input.action_release(&"jump")
	await physics_frame
	Input.action_press(&"jump")
	var jumps: int = await _count_jumps(player, WATCH_FRAMES)
	_release_all()
	await _remove([player, wall])
	return report(kicked and jumps == 0,
			"%s: %d more jumps%s" % [what, jumps, _note(kicked, "no wall jump")])


## Landing uses the wall's tolerance up: after falling against the wall onto the floor, stepping away
## and losing the floor without jumping, a press is the floor's coyote jump, straight up, and not a
## jump off the wall the player touched just before landing.
func _landing_ends_the_walls_tolerance() -> bool:
	var what: String = "Losing the floor after landing against the wall"
	var wall: StaticBody2D = _make_wall_on(LEFT)
	var floor_body: StaticBody2D = make_platform(WALL_FACE - WALL_THICKNESS, FLOOR_RIGHT)
	var player: Player = spawn_player(Vector2(_x_near(LEFT, 0.0), -KICK_HEIGHT))
	var landed: bool = await wait_until_on_floor(player)
	Input.action_press(_into(RIGHT))
	await _wait_frames(SETTLE_FRAMES)
	Input.action_release(_into(RIGHT))
	await _wait_until_stopped(player)
	var stood_away: bool = landed and not player.is_on_wall()
	# As in the case with coyote frames above: the floor goes at the end of this frame, and a press
	# made after the next one counts on the first frame in the air.
	floor_body.queue_free()
	await physics_frame
	Input.action_press(&"jump")
	var jumped: bool = not is_nan(await _wait_for_jump(player, WATCH_FRAMES))
	var speed: float = player.velocity.x
	_release_all()
	await _remove([player, wall])
	return report(stood_away and jumped and is_zero_approx(speed),
			"%s: %s at %.1f px/s sideways, expected 0.0 px/s, as off the floor%s"
			% [what, "jumped" if jumped else "no jump", speed,
			_note(stood_away, "never stood away from the wall")])


## A single wall cannot be climbed, even with the best input (_best_input): each kick takes off
## lower than the one before. A kick sets both speeds, so every round after the first is the same,
## wherever the player came from.
func _a_single_wall_cannot_be_climbed_even_with_the_best_input() -> bool:
	var wall: StaticBody2D = _make_wall_on(LEFT)
	var player: Player = spawn_player(Vector2(_x_near(LEFT, GAP), START_HEIGHT))
	Input.action_press(_into(LEFT))
	var take_offs: Array[float] = await _take_offs(player, _best_input)
	_release_all()
	await _remove([player, wall])
	return report(_every_kick_goes(LOWER, take_offs),
			"A single wall, with the best input: %d kicks, each higher than the last by %s"
			% [take_offs.size(), _climb_note(take_offs)])


## A narrow chimney can be climbed pressing only Jump, with no direction (_jump_on_touch): each kick
## takes off higher than the one before. With no direction the player never pushes into a wall, so
## this also checks that just touching one is enough.
func _a_narrow_chimney_is_climbed_pressing_only_jump() -> bool:
	var left_wall: StaticBody2D = _make_wall_on(LEFT)
	var right_wall: StaticBody2D = _make_wall_on(RIGHT, WALL_FACE + CHIMNEY_GAP)
	var player: Player = spawn_player(Vector2(_x_near(LEFT, 0.0), START_HEIGHT))
	var take_offs: Array[float] = await _take_offs(player, _jump_on_touch)
	_release_all()
	await _remove([player, left_wall, right_wall])
	return report(_every_kick_goes(HIGHER, take_offs),
			"A chimney %.0f px wide, pressing only Jump: %d kicks, each higher than the last by %s"
			% [CHIMNEY_GAP, take_offs.size(), _climb_note(take_offs)])


## The best input for climbing a wall, with the direction into it held by the case: Jump held on the
## way up, for full jumps, and pressed again every other frame on the way down, so a fresh press is
## always kept for the moment the player gets back to the wall.
func _best_input(player: Player) -> void:
	if player.velocity.y < 0.0 or not Input.is_action_pressed(&"jump"):
		Input.action_press(&"jump")
	else:
		Input.action_release(&"jump")


## Jump pressed while the player touches a wall and let go while it is off the walls: one press per
## wall, as a person taps.
func _jump_on_touch(player: Player) -> void:
	if player.is_on_wall():
		Input.action_press(&"jump")
	else:
		Input.action_release(&"jump")


## A wall on the player's side side, with its face at x = face.
func _make_wall_on(side: float, face: float = WALL_FACE) -> StaticBody2D:
	var back: float = face + side * WALL_THICKNESS
	return make_wall(minf(face, back), maxf(face, back), WALL_TOP, WALL_BOTTOM)


## The x at which the side of the player's body is gap px from the wall on its side side.
func _x_near(side: float, gap: float) -> float:
	return WALL_FACE - side * (_half_width + gap)


## The run action that pushes into a wall on the player's side side.
func _into(side: float) -> StringName:
	return &"move_left" if side == LEFT else &"move_right"


## A player sliding down the wall on its side side, still pushing into it. Null, with nothing held,
## if it never gets on the wall.
func _spawn_sliding(side: float) -> Player:
	var player: Player = spawn_player(Vector2(_x_near(side, GAP), START_HEIGHT))
	Input.action_press(_into(side))
	if not await _wait_until_on_wall(player):
		_release_all()
		await _remove([player])
		return null
	await _wait_frames(SETTLE_FRAMES)
	return player


## A player that slid down the wall on its side side and has just left it, pushing away from it,
## with that push still held. Null, with nothing held, if it never got on the wall or off it.
func _spawn_leaving_the_wall(side: float) -> Player:
	var player: Player = await _spawn_sliding(side)
	if player == null:
		return null
	Input.action_release(_into(side))
	Input.action_press(_into(-side))
	if not await _wait_until_off_the_wall(player):
		_release_all()
		await _remove([player])
		return null
	return player


## A player in the air FAR_GAP px from the wall on its left, pushing toward it.
func _spawn_flying_into_the_wall() -> Player:
	var player: Player = spawn_player(Vector2(_x_near(LEFT, FAR_GAP), START_HEIGHT))
	Input.action_press(_into(LEFT))
	return player


## Frames from the spawn until a player flying into the wall first touches it, or NEVER_REACHED.
func _frames_until_on_wall() -> int:
	var player: Player = _spawn_flying_into_the_wall()
	var frames: int = NEVER_REACHED
	for frame: int in MAX_FRAMES:
		await physics_frame
		if player.is_on_wall():
			frames = frame + 1
			break
	_release_all()
	await _remove([player])
	return frames


func _wait_until_on_wall(player: Player) -> bool:
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if player.is_on_wall():
			return true
	return false


func _wait_until_off_the_wall(player: Player) -> bool:
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if not player.is_on_wall():
			return true
	return false


func _wait_frames(frames: int) -> void:
	for _frame: int in frames:
		await physics_frame


## How many jumps the player makes in the next frames frames.
func _count_jumps(player: Player, frames: int) -> int:
	var jumps: int = 0
	var previous_speed: float = player.velocity.y
	for _frame: int in frames:
		await physics_frame
		if is_jump(previous_speed, player.velocity.y):
			jumps += 1
		previous_speed = player.velocity.y
	return jumps


## Frames until the player lands, or NEVER_REACHED.
func _frames_until_on_floor(player: Player) -> int:
	for frame: int in MAX_FRAMES:
		await physics_frame
		if player.is_on_floor():
			return frame + 1
	return NEVER_REACHED


## Waits until the player stands still sideways.
func _wait_until_stopped(player: Player) -> void:
	for _frame: int in MAX_FRAMES:
		if is_zero_approx(player.velocity.x):
			return
		await physics_frame


## Waits up to frames frames for the next jump and returns the y it took off from: where the player
## was before the frame on which it went up faster than on the frame before. NAN if no jump comes.
func _wait_for_jump(player: Player, frames: int = MAX_FRAMES) -> float:
	var previous_speed: float = player.velocity.y
	for _frame: int in frames:
		var take_off_y: float = player.position.y
		await physics_frame
		if is_jump(previous_speed, player.velocity.y):
			return take_off_y
		previous_speed = player.velocity.y
	return NAN


## Follows the player until it stops going up, and returns the highest point it reached, its
## smallest y.
func _highest_y(player: Player) -> float:
	var highest_y: float = player.position.y
	for _frame: int in MAX_FRAMES:
		if player.velocity.y >= 0.0:
			break
		await physics_frame
		highest_y = minf(highest_y, player.position.y)
	return highest_y


## Calls drive(player) before every frame until the player has made KICKS jumps, or MAX_FRAMES go
## by, and returns the y each jump took off from.
func _take_offs(player: Player, drive: Callable) -> Array[float]:
	var take_offs: Array[float] = []
	var previous_speed: float = player.velocity.y
	for _frame: int in MAX_FRAMES:
		drive.call(player)
		var take_off_y: float = player.position.y
		await physics_frame
		if is_jump(previous_speed, player.velocity.y):
			take_offs.append(take_off_y)
			if take_offs.size() == KICKS:
				break
		previous_speed = player.velocity.y
	return take_offs


## True if take_offs holds KICKS jumps and each took off higher than the one before (HIGHER) or
## lower (LOWER).
func _every_kick_goes(way: float, take_offs: Array[float]) -> bool:
	if take_offs.size() < KICKS:
		return false
	for i: int in range(1, take_offs.size()):
		if signf(take_offs[i - 1] - take_offs[i]) != way:
			return false
	return true


## How much higher each jump took off than the one before, in px, as text.
func _climb_note(take_offs: Array[float]) -> String:
	var climbs: PackedStringArray = []
	for i: int in range(1, take_offs.size()):
		climbs.append("%+.1f px" % (take_offs[i - 1] - take_offs[i]))
	return ", ".join(climbs) if not climbs.is_empty() else "nothing (fewer than 2 kicks)"


func _note(ok: bool, problem: String) -> String:
	return "" if ok else " (%s)" % problem


func _release_all() -> void:
	for action: StringName in [&"move_left", &"move_right", &"jump"]:
		Input.action_release(action)


func _remove(nodes: Array[Node]) -> void:
	for node: Node in nodes:
		node.queue_free()
	await physics_frame
