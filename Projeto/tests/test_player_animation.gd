# Checks PlayerAnimation. The choice alone: each state and velocity gives its animation, a
# knockback gives hurt over any of them, and held by a demon he shows escape over everything.
# Missing art falls back: the wall slide to the fall, the fall to the jump, the rest to idle. The
# jump's frame comes from the speed up or down: crouched on the take-off, then up, top, down and
# braced, with the top only after going up. A press in the grab jumps to the start of escape's next
# pose, from any of its frames, and the poses must start in order, once each, within its frames. In
# player.tscn:
# standing he is idle, running he walks, in the air he jumps, and a jump from standing shows its
# frames in order, from the crouch to the braced landing. Running, the walk plays one loop every
# Steps Per Loop × Step Length, so the feet keep to the ground; landing while running, the walk
# starts from its first frame, with the legs together. Sliding down a wall he shows wall_slide,
# turned to the wall: the art, drawn with the wall on his right, is stored turned over, so the
# Sprite, flipped when he faces right, shows it as drawn against a wall on his right.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_player_animation.gd
extends "res://tests/support/player_test.gd"

const FLOOR_LEFT: float = -2000.0
const FLOOR_RIGHT: float = 2000.0
const START: Vector2 = Vector2(0.0, -2.0)
## A speed well above Walk Min Speed and one below it, in px/s.
const FAST: float = 300.0
const SLOW: float = 5.0
const WALK_MIN_SPEED: float = 20.0
## Frames to settle on the floor after landing, and after letting the run go.
const SETTLE_FRAMES: int = 30
## Frames of the steady run: four seconds, over five loops of the walk.
const RUN_FRAMES: int = 240
## Where the steady run starts: near the floor's left end, so the whole run stays on it.
const RUN_START: Vector2 = Vector2(FLOOR_LEFT + 200.0, -2.0)
## Loops at the start of the run left out of the spacing, while he speeds up.
const SPEED_UP_LOOPS: int = 1
## How far two loops may be from their length apart, in px: a frame of the walk only changes on a
## drawn frame, 12 px of running apart at top speed, and the speed it reads is a frame old.
const LOOP_SPACING_TOLERANCE: float = 30.0
## Frames of running before the jump, to be at top speed.
const RUN_UP_FRAMES: int = 30
## Speeds for the jump's frames: the top of the jump is under APEX, bracing from FAST_FALL.
const APEX: float = 300.0
const FAST_FALL: float = 900.0
## The walls the man slides down, each side of the start, and how high above the floor he starts.
const WALL_GAP: float = 600.0
const WALL_THICKNESS: float = 100.0
const WALL_HEIGHT: float = 2000.0
const SLIDE_START_HEIGHT: float = 1200.0
## Frames given to reach the wall and slide down it.
const SLIDE_FRAMES: int = 120


func _initialize() -> void:
	await process_frame
	make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var results: Array[bool] = []
	results.append(_each_state_and_velocity_gives_its_animation())
	results.append(_missing_art_falls_back_to_the_nearest_animation())
	results.append(_the_jump_frame_follows_the_speed_up_or_down())
	results.append(_a_press_jumps_to_the_next_pose())
	results.append(await _in_the_scene_he_stands_walks_and_jumps())
	results.append(await _a_jump_shows_its_frames_in_order())
	results.append(await _running_the_walk_loops_every_steps_per_loop_step_lengths())
	results.append(await _landing_while_running_starts_the_walk_from_its_first_frame())
	results.append(await _down_a_wall_he_slides_turned_to_it(1.0))
	results.append(await _down_a_wall_he_slides_turned_to_it(-1.0))
	finish(results)


func _each_state_and_velocity_gives_its_animation() -> bool:
	var floor_state: Player.State = Player.State.ON_FLOOR
	var air: Player.State = Player.State.IN_AIR
	var wall: Player.State = Player.State.ON_WALL
	var grabbed: Player.State = Player.State.GRABBED
	var cases: Array[Array] = [
		[floor_state, Vector2.ZERO, false, PlayerAnimation.IDLE],
		[floor_state, Vector2(SLOW, 0.0), false, PlayerAnimation.IDLE],
		[floor_state, Vector2(FAST, 0.0), false, PlayerAnimation.WALK],
		[floor_state, Vector2(-FAST, 0.0), false, PlayerAnimation.WALK],
		[air, Vector2(0.0, -FAST), false, PlayerAnimation.JUMP],
		[air, Vector2.ZERO, false, PlayerAnimation.FALL],
		[air, Vector2(FAST, FAST), false, PlayerAnimation.FALL],
		[wall, Vector2(0.0, FAST), false, PlayerAnimation.WALL_SLIDE],
		[wall, Vector2(0.0, -FAST), false, PlayerAnimation.JUMP],
		[floor_state, Vector2(FAST, 0.0), true, PlayerAnimation.HURT],
		[air, Vector2(0.0, -FAST), true, PlayerAnimation.HURT],
		[grabbed, Vector2.ZERO, false, PlayerAnimation.ESCAPE],
		[grabbed, Vector2(0.0, FAST), false, PlayerAnimation.ESCAPE],
		[grabbed, Vector2(FAST, 0.0), true, PlayerAnimation.ESCAPE],
	]
	var wrong: Array[String] = []
	for case: Array in cases:
		var got: StringName = PlayerAnimation.animation_for(case[0], case[1], case[2],
				WALK_MIN_SPEED)
		if got != case[3]:
			wrong.append("%s %s knocked %s: %s, not %s" % [Player.State.find_key(case[0]), case[1],
					case[2], got, case[3]])
	return report(wrong.is_empty(), "The choice alone, %d cases%s" % [cases.size(),
			"" if wrong.is_empty() else ": " + "; ".join(wrong)])


func _missing_art_falls_back_to_the_nearest_animation() -> bool:
	var with_jump: SpriteFrames = SpriteFrames.new()
	with_jump.rename_animation(&"default", PlayerAnimation.IDLE)
	with_jump.add_animation(PlayerAnimation.JUMP)
	var idle_only: SpriteFrames = SpriteFrames.new()
	idle_only.rename_animation(&"default", PlayerAnimation.IDLE)
	var cases: Array[Array] = [
		[PlayerAnimation.WALL_SLIDE, with_jump, PlayerAnimation.JUMP],
		[PlayerAnimation.FALL, with_jump, PlayerAnimation.JUMP],
		[PlayerAnimation.JUMP, with_jump, PlayerAnimation.JUMP],
		[PlayerAnimation.HURT, with_jump, PlayerAnimation.IDLE],
		[PlayerAnimation.WALK, with_jump, PlayerAnimation.IDLE],
		[PlayerAnimation.WALL_SLIDE, idle_only, PlayerAnimation.IDLE],
		[PlayerAnimation.FALL, idle_only, PlayerAnimation.IDLE],
		[PlayerAnimation.ESCAPE, with_jump, PlayerAnimation.IDLE],
	]
	var wrong: Array[String] = []
	for case: Array in cases:
		var got: StringName = PlayerAnimation.shown_animation(case[0], case[1])
		if got != case[2]:
			wrong.append("%s with %s: %s, not %s" % [case[0],
					case[1].get_animation_names(), got, case[2]])
	return report(wrong.is_empty(), "Fallbacks, %d cases%s" % [cases.size(),
			"" if wrong.is_empty() else ": " + "; ".join(wrong)])


func _the_jump_frame_follows_the_speed_up_or_down() -> bool:
	# [velocity.y, taking off, went up, frame]
	var cases: Array[Array] = [
		[-1300.0, true, false, PlayerAnimation.TAKE_OFF_FRAME],
		[400.0, true, true, PlayerAnimation.TAKE_OFF_FRAME],
		[-1300.0, false, true, PlayerAnimation.RISE_FRAME],
		[-APEX - 1.0, false, true, PlayerAnimation.RISE_FRAME],
		[-APEX + 1.0, false, true, PlayerAnimation.APEX_FRAME],
		[0.0, false, true, PlayerAnimation.APEX_FRAME],
		[APEX - 1.0, false, true, PlayerAnimation.APEX_FRAME],
		[APEX, false, true, PlayerAnimation.FALL_FRAME],
		[0.0, false, false, PlayerAnimation.FALL_FRAME],
		[FAST_FALL - 1.0, false, true, PlayerAnimation.FALL_FRAME],
		[FAST_FALL, false, true, PlayerAnimation.FAST_FALL_FRAME],
		[1400.0, false, false, PlayerAnimation.FAST_FALL_FRAME],
	]
	var wrong: Array[String] = []
	for case: Array in cases:
		var got: int = PlayerAnimation.air_frame_for(case[0], case[1], case[2], APEX, FAST_FALL)
		if got != case[3]:
			wrong.append("%.0f px/s taking off %s went up %s: %d, not %d" % [case[0], case[1],
					case[2], got, case[3]])
	return report(wrong.is_empty(), "Jump frames, %d cases%s" % [cases.size(),
			"" if wrong.is_empty() else ": " + "; ".join(wrong)])


## A press jumps to the start of the pose after the one the frame is in; a frame before the first
## start is still in the last pose; with no poses, the frame stays. The poses must start in order,
## once each, within the animation's frames.
func _a_press_jumps_to_the_next_pose() -> bool:
	# [where the poses start, frame, frame after the press]
	var presses: Array[Array] = [
		[[0, 2], 0, 2], [[0, 2], 1, 2], [[0, 2], 2, 0], [[0, 2], 3, 0],
		[[1, 3], 0, 1], [[1, 3], 1, 3], [[1, 3], 2, 3], [[1, 3], 3, 1],
		[[0], 0, 0], [[], 3, 3],
	]
	# [where the poses start, frames in the animation, fit]
	var lists: Array[Array] = [
		[[0, 2], 4, true], [[0], 1, true], [[1, 3], 4, true], [[2, 0], 4, false],
		[[0, 0], 4, false], [[0, 4], 4, false], [[-1, 2], 4, false], [[], 4, false],
	]
	var wrong: Array[String] = []
	var poses: Array[int] = []
	for press: Array in presses:
		poses.assign(press[0])
		var got: int = PlayerAnimation.next_pose_frame(press[1], poses)
		if got != press[2]:
			wrong.append("%s from %d: %d, not %d" % [poses, press[1], got, press[2]])
	for list: Array in lists:
		poses.assign(list[0])
		var fits: bool = PlayerAnimation.are_valid_pose_frames(poses, list[1])
		if fits != list[2]:
			wrong.append("%s in %d frames: %s, not %s" % [poses, list[1], fits, list[2]])
	return report(wrong.is_empty(), "Escape's poses, %d presses and %d lists%s" % [presses.size(),
			lists.size(), "" if wrong.is_empty() else ": " + "; ".join(wrong)])


## From standing, a full jump: every frame drawn in the air, from the take-off to the landing, is
## the jump's, and they go 0, 1, 2, 3, 4 in order, never back.
func _a_jump_shows_its_frames_in_order() -> bool:
	var player: Player = await spawn_on_floor(START)
	if player == null:
		return report(false, "Jump frames in the scene: the player never landed")
	var stand_in: StandInInput = put_a_stand_in(player)
	var sprite: AnimatedSprite2D = player.get_node(^"Sprite") as AnimatedSprite2D
	await wait_frames(SETTLE_FRAMES)
	stand_in.hold_jump = true
	stand_in.press_jump()
	var shown: Array[int] = []
	var other: Array[StringName] = []
	var left_floor: bool = false
	for _frame: int in MAX_FRAMES:
		await process_frame
		var in_the_air: bool = player.get_state() != Player.State.ON_FLOOR
		if left_floor and not in_the_air:
			break
		left_floor = left_floor or in_the_air
		if sprite.animation != PlayerAnimation.JUMP:
			if left_floor:
				other.append(sprite.animation)
			continue
		if shown.is_empty() or shown.back() != sprite.frame:
			shown.append(sprite.frame)
	await remove_player(player)
	var expected: Array[int] = [PlayerAnimation.TAKE_OFF_FRAME, PlayerAnimation.RISE_FRAME,
			PlayerAnimation.APEX_FRAME, PlayerAnimation.FALL_FRAME, PlayerAnimation.FAST_FALL_FRAME]
	return report(left_floor and other.is_empty() and shown == expected,
			"Jump frames in the scene: %s, expected %s; other animations in the air %s"
			% [shown, expected, other])


func _in_the_scene_he_stands_walks_and_jumps() -> bool:
	var player: Player = await spawn_on_floor(START)
	if player == null:
		return report(false, "In the scene: the player never landed")
	var stand_in: StandInInput = put_a_stand_in(player)
	var sprite: AnimatedSprite2D = player.get_node(^"Sprite") as AnimatedSprite2D
	await wait_frames(SETTLE_FRAMES)
	await process_frame
	var standing: StringName = sprite.animation
	stand_in.run_direction = 1.0
	var walked: bool = await wait_until(func() -> bool: return sprite.animation == &"walk")
	stand_in.run_direction = 0.0
	stand_in.hold_jump = true
	stand_in.press_jump()
	# The state turns IN_AIR a frame after the body leaves the floor, so wait for the state.
	var left_floor: bool = await wait_until(
			func() -> bool: return player.get_state() == Player.State.IN_AIR)
	await process_frame
	var in_air: StringName = sprite.animation
	await remove_player(player)
	return report(standing == &"idle" and walked and left_floor and in_air == &"jump",
			"In the scene: standing %s, walked %s, left the floor %s, in the air %s" % [standing,
			walked, left_floor, in_air])


## The walk comes back to its first frame once every Steps Per Loop × Step Length run, so the feet
## keep to the ground.
func _running_the_walk_loops_every_steps_per_loop_step_lengths() -> bool:
	var player: Player = await spawn_on_floor(RUN_START)
	if player == null:
		return report(false, "Walk loops: the player never landed")
	var stand_in: StandInInput = put_a_stand_in(player)
	var animation: PlayerAnimation = player.get_node(^"PlayerAnimation") as PlayerAnimation
	var sprite: AnimatedSprite2D = player.get_node(^"Sprite") as AnimatedSprite2D
	var last_frame: int = sprite.sprite_frames.get_frame_count(PlayerAnimation.WALK) - 1
	await wait_frames(SETTLE_FRAMES)
	# Only the wraps from the last frame back to the first count, not the start of the walk.
	var wraps: Array[float] = []
	var previous: Array[int] = [-1]
	sprite.frame_changed.connect(func() -> void:
		if sprite.animation == PlayerAnimation.WALK:
			if sprite.frame == 0 and previous[0] == last_frame:
				wraps.append(player.position.x)
			previous[0] = sprite.frame
		else:
			previous[0] = -1)
	stand_in.run_direction = 1.0
	await wait_frames(RUN_FRAMES)
	stand_in.run_direction = 0.0
	var loop_length: float = animation.steps_per_loop * animation.step_length
	var worst: float = 0.0
	for i: int in range(SPEED_UP_LOOPS + 1, wraps.size()):
		worst = maxf(worst, absf(wraps[i] - wraps[i - 1] - loop_length))
	var enough: bool = wraps.size() > SPEED_UP_LOOPS + 2
	var on_the_floor: bool = player.is_on_floor()
	await remove_player(player)
	return report(enough and on_the_floor and worst <= LOOP_SPACING_TOLERANCE,
			"Walk loops: %d over the run, on the floor to the end %s, spacing off %.0f px by %.1f px at most"
			% [wraps.size(), on_the_floor, loop_length, worst])


func _landing_while_running_starts_the_walk_from_its_first_frame() -> bool:
	var player: Player = await spawn_on_floor(START)
	if player == null:
		return report(false, "Landing: the player never landed")
	var stand_in: StandInInput = put_a_stand_in(player)
	var sprite: AnimatedSprite2D = player.get_node(^"Sprite") as AnimatedSprite2D
	stand_in.run_direction = 1.0
	await wait_frames(RUN_UP_FRAMES)
	stand_in.hold_jump = true
	stand_in.press_jump()
	var in_air: bool = await wait_until(
			func() -> bool: return player.get_state() == Player.State.IN_AIR)
	var landed: bool = await wait_until(
			func() -> bool: return player.get_state() == Player.State.ON_FLOOR)
	await process_frame
	var first_frame: int = sprite.frame
	var walking: bool = sprite.animation == PlayerAnimation.WALK
	stand_in.run_direction = 0.0
	await remove_player(player)
	return report(in_air and landed and walking and first_frame == 0,
			"Landing while running: in the air %s, landed %s, walking %s on frame %d (expected 0)"
			% [in_air, landed, walking, first_frame])


## Pressed against a wall on side (1 right, -1 left) and sliding down it, he shows wall_slide facing
## the wall: flipped with the wall on his right, which shows the stored art as drawn; let go and
## turned away, he stays on it and the drawing turns back to the wall.
func _down_a_wall_he_slides_turned_to_it(side: float) -> bool:
	var face: float = side * WALL_GAP
	var wall: StaticBody2D = make_wall(face if side > 0.0 else face - WALL_THICKNESS,
			face + WALL_THICKNESS if side > 0.0 else face, -WALL_HEIGHT)
	var player: Player = spawn_player(Vector2(face - side * 100.0, -SLIDE_START_HEIGHT))
	var stand_in: StandInInput = put_a_stand_in(player)
	var sprite: AnimatedSprite2D = player.get_node(^"Sprite") as AnimatedSprite2D
	stand_in.run_direction = side
	var sliding: bool = await wait_until(func() -> bool:
			return player.get_state() == Player.State.ON_WALL and player.velocity.y > 0.0,
			SLIDE_FRAMES)
	await process_frame
	var shown: StringName = sprite.animation
	var flipped: bool = sprite.flip_h
	# Let go, he stays on the wall; turned the other way, as a last press away would leave him, the
	# drawing turns back to the wall on the next frame drawn.
	stand_in.run_direction = 0.0
	sprite.flip_h = side < 0.0
	await physics_frame
	await process_frame
	var still_on: bool = player.get_state() == Player.State.ON_WALL
	var turned_back: bool = sprite.flip_h == (side > 0.0)
	await remove_player(player)
	wall.queue_free()
	var side_name: String = "right" if side > 0.0 else "left"
	return report(sliding and shown == PlayerAnimation.WALL_SLIDE and flipped == (side > 0.0)
			and still_on and turned_back,
			("Wall on his %s: sliding %s, shows %s, flipped %s (%s); let go, on the wall %s, turned "
			+ "back to it %s") % [side_name, sliding, shown,
			flipped, side > 0.0, still_on, turned_back])
