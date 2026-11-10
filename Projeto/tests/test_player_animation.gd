# Checks PlayerAnimation. The choice alone: each state and velocity gives its animation, a
# knockback gives hurt over any of them, and held by a demon he shows escape over everything. Missing
# art falls back: the wall slide to the fall, the fall to the jump, the rest to idle. The jump's frame comes from the speed up or down: crouched on
# the take-off, then up, top, down and braced, with the top only after going up. In player.tscn:
# standing he is idle, running he walks, in the air he jumps, and a jump from standing shows its
# frames in order, from the crouch to the braced landing. Running, every step comes on a planted
# frame and Step Length apart, so the feet keep to the ground; landing while running, the walk
# starts halfway to the next step, with no step on the landing.
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
## Frames of the steady run: four seconds, over a dozen steps.
const RUN_FRAMES: int = 240
## Steps at the start of the run left out of the spacing, while he speeds up.
const SPEED_UP_STEPS: int = 2
## How far two steps may be from Step Length apart, in px: a frame of the walk only changes on a
## drawn frame, 12 px of running apart at top speed, and the speed it reads is a frame old.
const STEP_SPACING_TOLERANCE: float = 30.0
## Frames of running before the jump, to be at top speed.
const RUN_UP_FRAMES: int = 30
## Speeds for the jump's frames: the top of the jump is under APEX, bracing from FAST_FALL.
const APEX: float = 300.0
const FAST_FALL: float = 900.0


func _initialize() -> void:
	await process_frame
	make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var results: Array[bool] = []
	results.append(_each_state_and_velocity_gives_its_animation())
	results.append(_missing_art_falls_back_to_the_nearest_animation())
	results.append(_the_jump_frame_follows_the_speed_up_or_down())
	results.append(await _in_the_scene_he_stands_walks_and_jumps())
	results.append(await _a_jump_shows_its_frames_in_order())
	results.append(await _running_steps_land_on_planted_frames_a_step_length_apart())
	results.append(await _landing_while_running_starts_the_walk_halfway())
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


## With idle and jump only, as player.tscn has them: the wall slide and the fall show the jump, hurt
## stands. With idle alone, everything stands.
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


func _running_steps_land_on_planted_frames_a_step_length_apart() -> bool:
	var player: Player = await spawn_on_floor(START)
	if player == null:
		return report(false, "Steps: the player never landed")
	var stand_in: StandInInput = put_a_stand_in(player)
	var animation: PlayerAnimation = player.get_node(^"PlayerAnimation") as PlayerAnimation
	var sprite: AnimatedSprite2D = player.get_node(^"Sprite") as AnimatedSprite2D
	await wait_frames(SETTLE_FRAMES)
	var step_x: Array[float] = []
	var off_contact: Array[int] = []
	animation.stepped.connect(func() -> void:
		step_x.append(player.position.x)
		if sprite.frame not in animation.contact_frames:
			off_contact.append(sprite.frame))
	stand_in.run_direction = 1.0
	await wait_frames(RUN_FRAMES)
	stand_in.run_direction = 0.0
	var worst: float = 0.0
	for i: int in range(SPEED_UP_STEPS + 1, step_x.size()):
		worst = maxf(worst, absf(step_x[i] - step_x[i - 1] - animation.step_length))
	var enough: bool = step_x.size() > SPEED_UP_STEPS + 2
	var step_length: float = animation.step_length
	await remove_player(player)
	return report(enough and off_contact.is_empty() and worst <= STEP_SPACING_TOLERANCE,
			"Steps: %d over the run, off a planted frame %s, spacing off Step Length %.0f px by %.1f px at most"
			% [step_x.size(), off_contact, step_length, worst])


func _landing_while_running_starts_the_walk_halfway() -> bool:
	var player: Player = await spawn_on_floor(START)
	if player == null:
		return report(false, "Landing: the player never landed")
	var stand_in: StandInInput = put_a_stand_in(player)
	var animation: PlayerAnimation = player.get_node(^"PlayerAnimation") as PlayerAnimation
	var sprite: AnimatedSprite2D = player.get_node(^"Sprite") as AnimatedSprite2D
	stand_in.run_direction = 1.0
	await wait_frames(RUN_UP_FRAMES)
	stand_in.hold_jump = true
	stand_in.press_jump()
	var in_air: bool = await wait_until(
			func() -> bool: return player.get_state() == Player.State.IN_AIR)
	var steps: Array[int] = []
	animation.stepped.connect(func() -> void: steps.append(sprite.frame))
	var landed: bool = await wait_until(
			func() -> bool: return player.get_state() == Player.State.ON_FLOOR)
	await process_frame
	var first_frame: int = sprite.frame
	var walking: bool = sprite.animation == PlayerAnimation.WALK
	var on_contact: bool = first_frame in animation.contact_frames
	stand_in.run_direction = 0.0
	await remove_player(player)
	return report(in_air and landed and walking and not on_contact and steps.is_empty(),
			"Landing while running: in the air %s, landed %s, walking %s on frame %d, steps on landing %s"
			% [in_air, landed, walking, first_frame, steps])
