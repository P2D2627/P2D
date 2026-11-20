# Checks Footsteps. A step frame counts once, also when a slow frame skips over it, and starting the
# walk on one counts. In player.tscn: running, each step plays on one of Step Frames, 3 and 9, one
# Step Length apart; standing still and running in the air play none, and landing while running
# plays none on the landing. Double Layer picks the set, the six _d files or the six single ones,
# each step one of them at random, all six heard; each step's pitch stays within Pitch Variation, 4%,
# either way, and the node's own pitch stays at 1. Step Frames changed while running are heard at
# once. The steps go to the SFX bus, and the node stops playing once the last step's file is over.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_footsteps.gd
extends "res://tests/support/player_test.gd"

const FLOOR_LEFT: float = -2000.0
const FLOOR_RIGHT: float = 6000.0
## Where a run starts: near the floor's left end, so a long run stays on it.
const RUN_START: Vector2 = Vector2(FLOOR_LEFT + 200.0, -2.0)
## High above the floor: running from there never touches it in QUIET_FRAMES.
const HIGH_UP: Vector2 = Vector2(0.0, -5000.0)
## The step frames and the pitch variation the README of the sounds asks for.
const EXPECTED_STEP_FRAMES: Array[int] = [3, 9]
const EXPECTED_PITCH_VARIATION: float = 0.04
## Files in each set.
const SET_SIZE: int = 6
## Frames of a run: four seconds, about ten steps.
const RUN_FRAMES: int = 240
## Frames to stand still, or to fall, while no step may play.
const QUIET_FRAMES: int = 60
## Frames of running before the jump, to be at top speed.
const RUN_UP_FRAMES: int = 30
## Frames of running before Step Frames change, and after.
const BEFORE_CHANGE_FRAMES: int = 60
const AFTER_CHANGE_FRAMES: int = 120
## Steps at the start of a run left out of the spacing, while he speeds up.
const SPEED_UP_STEPS: int = 2
## How far two steps may be from Step Length apart, in px: a frame of the walk only changes on a
## drawn frame, 12 px of running apart at top speed, and the speed it reads is a frame old.
const STEP_SPACING_TOLERANCE: float = 30.0
## Steps played at once to read the picks and the pitches. The seed makes them repeatable.
const PICKS: int = 120
const RANDOM_SEED: int = 2026
## Rounding room for the pitch limits.
const LIMIT_TOLERANCE: float = 0.0001
## Frames after the last step to wait for the node to stop: past the longest file at the lowest
## pitch, 0.72 s / 0.96, with room.
const STOP_FRAMES: int = 60
## Frames for a removed player's sounds to end before the run quits, or they are reported as leaks.
const QUIT_FRAMES: int = 30
## A frame before any frame of the walk, for the cases that start from it.
const BEFORE_THE_WALK: int = Footsteps.NOT_WALKING


func _initialize() -> void:
	await process_frame
	make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var results: Array[bool] = []
	results.append(_a_step_frame_counts_once_even_when_skipped())
	results.append(await _running_steps_play_on_the_step_frames_a_step_length_apart())
	results.append(await _standing_still_and_running_in_the_air_play_no_steps())
	results.append(await _landing_while_running_plays_no_step_on_the_landing())
	results.append(await _double_layer_picks_the_set_and_every_file_is_heard())
	results.append(await _each_step_pitch_stays_within_the_variation())
	results.append(await _step_frames_changed_while_running_are_heard_at_once())
	results.append(await _the_node_stops_once_the_last_step_is_over())
	await wait_frames(QUIT_FRAMES)
	finish(results)


func _a_step_frame_counts_once_even_when_skipped() -> bool:
	var steps: Array[int] = [3, 9]
	# [last frame, frame, expected], in a walk of 12 frames.
	var cases: Array[Array] = [
		[BEFORE_THE_WALK, 3, true],
		[BEFORE_THE_WALK, 0, false],
		[2, 3, true],
		[3, 3, false],
		[3, 4, false],
		[1, 5, true],
		[4, 8, false],
		[8, 10, true],
		[11, 2, false],
		[10, 4, true],
	]
	var wrong: Array[String] = []
	for case: Array in cases:
		var reached: bool = Footsteps.reached_step_frame(case[0], case[1], 12, steps)
		if reached != case[2]:
			wrong.append("%d -> %d gave %s" % [case[0], case[1], reached])
	return report(wrong.is_empty(), "Step frames %s reached once, skipped or not: wrong %s"
			% [steps, wrong])


func _running_steps_play_on_the_step_frames_a_step_length_apart() -> bool:
	var player: Player = await spawn_on_floor(RUN_START)
	if player == null:
		return report(false, "Steps: the player never landed")
	var stand_in: StandInInput = put_a_stand_in(player)
	var footsteps: Footsteps = _footsteps(player)
	var animation: PlayerAnimation = player.get_node(^"PlayerAnimation") as PlayerAnimation
	var sprite: AnimatedSprite2D = player.get_node(^"Sprite") as AnimatedSprite2D
	var step_x: Array[float] = []
	var off_frames: Array[String] = []
	footsteps.step_played.connect(func(_stream: AudioStream, _pitch: float) -> void:
		step_x.append(player.position.x)
		if sprite.animation != PlayerAnimation.WALK or sprite.frame not in footsteps.step_frames:
			off_frames.append("%s %d" % [sprite.animation, sprite.frame]))
	stand_in.run_direction = 1.0
	await wait_frames(RUN_FRAMES)
	stand_in.run_direction = 0.0
	var worst: float = 0.0
	for i: int in range(SPEED_UP_STEPS + 1, step_x.size()):
		worst = maxf(worst, absf(step_x[i] - step_x[i - 1] - animation.step_length))
	var enough: bool = step_x.size() > SPEED_UP_STEPS + 2
	var frames_ok: bool = footsteps.step_frames == EXPECTED_STEP_FRAMES
	var step_frames: Array[int] = footsteps.step_frames
	await remove_player(player)
	return report(frames_ok and enough and off_frames.is_empty()
			and worst <= STEP_SPACING_TOLERANCE,
			"Steps on Step Frames %s (expected %s): %d over the run, off them %s, spacing off Step Length by %.1f px at most"
			% [step_frames, EXPECTED_STEP_FRAMES, step_x.size(), off_frames, worst])


func _standing_still_and_running_in_the_air_play_no_steps() -> bool:
	var player: Player = await spawn_on_floor(RUN_START)
	if player == null:
		return report(false, "Quiet: the player never landed to stand still")
	var standing: Array[int] = [0]
	_footsteps(player).step_played.connect(func(_stream: AudioStream, _pitch: float) -> void:
		standing[0] += 1)
	await wait_frames(QUIET_FRAMES)
	await remove_player(player)
	var falling_player: Player = spawn_player(HIGH_UP)
	var stand_in: StandInInput = put_a_stand_in(falling_player)
	var falling: Array[int] = [0]
	_footsteps(falling_player).step_played.connect(
			func(_stream: AudioStream, _pitch: float) -> void: falling[0] += 1)
	stand_in.run_direction = 1.0
	await wait_frames(QUIET_FRAMES)
	var stayed_in_the_air: bool = not falling_player.is_on_floor()
	await remove_player(falling_player)
	return report(standing[0] == 0 and falling[0] == 0 and stayed_in_the_air,
			"Standing still: %d steps; running in the air: %d steps (expected 0 and 0)"
			% [standing[0], falling[0]])


## The walk starts from its first frame on landing, which is not a step frame, so the landing sound
## is not crowded by a step.
func _landing_while_running_plays_no_step_on_the_landing() -> bool:
	var player: Player = await spawn_on_floor(RUN_START)
	if player == null:
		return report(false, "Landing: the player never landed")
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.run_direction = 1.0
	await wait_frames(RUN_UP_FRAMES)
	stand_in.hold_jump = true
	stand_in.press_jump()
	var in_air: bool = await wait_until(
			func() -> bool: return player.get_state() == Player.State.IN_AIR)
	var steps: Array[int] = [0]
	_footsteps(player).step_played.connect(func(_stream: AudioStream, _pitch: float) -> void:
		steps[0] += 1)
	var landed: bool = await wait_until(
			func() -> bool: return player.get_state() == Player.State.ON_FLOOR)
	await process_frame
	await process_frame
	var on_landing: int = steps[0]
	stand_in.run_direction = 0.0
	await remove_player(player)
	return report(in_air and landed and on_landing == 0,
			"Landing while running: in the air %s, landed %s, steps on the landing %d (expected 0)"
			% [in_air, landed, on_landing])


## Each set is the six files of its kind, and every step comes from the set Double Layer picks.
func _double_layer_picks_the_set_and_every_file_is_heard() -> bool:
	seed(RANDOM_SEED)
	var player: Player = await spawn_on_floor(RUN_START)
	if player == null:
		return report(false, "Sets: the player never landed")
	var footsteps: Footsteps = _footsteps(player)
	var files_ok: bool = (footsteps.single_sounds.size() == SET_SIZE
			and footsteps.double_sounds.size() == SET_SIZE)
	for sound: AudioStream in footsteps.single_sounds:
		files_ok = files_ok and not sound.resource_path.get_file().begins_with("footstep_d_")
	for sound: AudioStream in footsteps.double_sounds:
		files_ok = files_ok and sound.resource_path.get_file().begins_with("footstep_d_")
	var off_by_default: bool = not footsteps.double_layer
	var heard: Array[AudioStream] = []
	footsteps.step_played.connect(func(stream: AudioStream, _pitch: float) -> void:
		heard.append(stream))
	var first_voice: int = footsteps.play_step()
	for _pick: int in PICKS - 1:
		footsteps.play_step()
	var single_ok: bool = _all_from(heard, footsteps.single_sounds)
	var single_used: int = _used(heard, footsteps.single_sounds)
	heard.clear()
	footsteps.double_layer = true
	for _pick: int in PICKS:
		footsteps.play_step()
	var double_ok: bool = _all_from(heard, footsteps.double_sounds)
	var double_used: int = _used(heard, footsteps.double_sounds)
	var on_sfx: bool = footsteps.bus == &"SFX"
	await remove_player(player)
	return report(files_ok and off_by_default and single_ok and double_ok
			and single_used == SET_SIZE and double_used == SET_SIZE and on_sfx
			and first_voice != AudioStreamPlaybackPolyphonic.INVALID_ID,
			"Sets of %d (single, then _d) %s, Double Layer off by default %s; off: all single %s, %d used; on: all _d %s, %d used; on SFX %s; first step played %s"
			% [SET_SIZE, files_ok, off_by_default, single_ok, single_used, double_ok, double_used,
			on_sfx, first_voice != AudioStreamPlaybackPolyphonic.INVALID_ID])


## Every step's pitch is within Pitch Variation either way, both ways are heard, and the node's own
## pitch, which would also move the tails still sounding, stays at 1.
func _each_step_pitch_stays_within_the_variation() -> bool:
	seed(RANDOM_SEED)
	var player: Player = await spawn_on_floor(RUN_START)
	if player == null:
		return report(false, "Pitch: the player never landed")
	var footsteps: Footsteps = _footsteps(player)
	var variation: float = footsteps.pitch_variation
	var lowest: Array[float] = [INF]
	var highest: Array[float] = [-INF]
	footsteps.step_played.connect(func(_stream: AudioStream, pitch: float) -> void:
		lowest[0] = minf(lowest[0], pitch)
		highest[0] = maxf(highest[0], pitch))
	for _pick: int in PICKS:
		footsteps.play_step()
	var own_pitch: float = footsteps.pitch_scale
	await remove_player(player)
	var in_range: bool = (lowest[0] >= 1.0 - variation - LIMIT_TOLERANCE
			and highest[0] <= 1.0 + variation + LIMIT_TOLERANCE)
	var both_ways: bool = lowest[0] < 1.0 - variation / 2.0 and highest[0] > 1.0 + variation / 2.0
	return report(is_equal_approx(variation, EXPECTED_PITCH_VARIATION) and in_range and both_ways
			and own_pitch == 1.0,
			"Pitch Variation %.3f (expected %.3f): %d steps from %.4f to %.4f, in range %s, both ways %s; own pitch %.2f"
			% [variation, EXPECTED_PITCH_VARIATION, PICKS, lowest[0], highest[0], in_range,
			both_ways, own_pitch])


## As in the Remote tab: Step Frames set while he runs are the ones heard from then on.
func _step_frames_changed_while_running_are_heard_at_once() -> bool:
	var player: Player = await spawn_on_floor(RUN_START)
	if player == null:
		return report(false, "Live change: the player never landed")
	var stand_in: StandInInput = put_a_stand_in(player)
	var footsteps: Footsteps = _footsteps(player)
	var sprite: AnimatedSprite2D = player.get_node(^"Sprite") as AnimatedSprite2D
	stand_in.run_direction = 1.0
	await wait_frames(BEFORE_CHANGE_FRAMES)
	var new_frames: Array[int] = [0, 6]
	footsteps.step_frames = new_frames
	var frames: Array[int] = []
	footsteps.step_played.connect(func(_stream: AudioStream, _pitch: float) -> void:
		frames.append(sprite.frame))
	await wait_frames(AFTER_CHANGE_FRAMES)
	stand_in.run_direction = 0.0
	await remove_player(player)
	var all_new: bool = not frames.is_empty()
	for frame: int in frames:
		all_new = all_new and frame in new_frames
	return report(all_new, "Step Frames changed to %s while running: steps on %s" % [new_frames,
			frames])


func _the_node_stops_once_the_last_step_is_over() -> bool:
	var player: Player = await spawn_on_floor(RUN_START)
	if player == null:
		return report(false, "Stop: the player never landed")
	var footsteps: Footsteps = _footsteps(player)
	var still_before: bool = not footsteps.playing
	footsteps.play_step()
	var playing_on_the_step: bool = footsteps.playing
	await wait_frames(STOP_FRAMES)
	var stopped_after: bool = not footsteps.playing
	await remove_player(player)
	return report(still_before and playing_on_the_step and stopped_after,
			"Footsteps: still before any step %s, playing on a step %s, stopped %d frames later %s"
			% [still_before, playing_on_the_step, STOP_FRAMES, stopped_after])


## True when every stream in heard is one of sounds.
func _all_from(heard: Array[AudioStream], sounds: Array[AudioStream]) -> bool:
	for stream: AudioStream in heard:
		if stream not in sounds:
			return false
	return not heard.is_empty()


## How many of sounds are in heard.
func _used(heard: Array[AudioStream], sounds: Array[AudioStream]) -> int:
	var used: int = 0
	for sound: AudioStream in sounds:
		if sound in heard:
			used += 1
	return used


func _footsteps(player: Player) -> Footsteps:
	return player.get_node(^"Footsteps") as Footsteps
