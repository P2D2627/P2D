# Checks the player's sounds; the steps are Footsteps', in test_footsteps.gd. The wall slide sound
# plays while sliding down a wall and stops on landing. The sounds come from where the player is, so
# they are heard anywhere in a level and not only near its origin. A jump, off the floor or off a
# wall, plays the jump sound. Landing after a normal jump or a wall slide is soft and cuts the jump
# sound off, after a long fall hard, with both hard sounds in use, and landing from a few px (as at
# the start of a level) makes no sound. Jumps and landings keep their pitch inside the variation.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_player_sounds.gd
extends "res://tests/support/player_test.gd"

## The wall's face is at x = WALL_FACE, on the player's left; the floor runs right from it.
const WALL_FACE: float = 0.0
const WALL_THICKNESS: float = 200.0
const WALL_TOP: float = -3000.0
const FLOOR_RIGHT: float = 20000.0
## Where a run starts: on the floor, well away from the wall.
const RUN_START: Vector2 = Vector2(500.0, -2.0)
## Where a wall slide starts: next to the wall, high enough to slide for a while.
const SLIDE_START: Vector2 = Vector2(WALL_FACE + 64.0, -1500.0)
## Well past the sound players' Max Distance from the world origin.
const FAR_FROM_THE_ORIGIN: Vector2 = Vector2(10000.0, -2.0)
## How far a sound player may be from the player, in px.
const POSITION_TOLERANCE: float = 1.0
## A fall from this high above the floor lands hard with the default Hard Land Height.
const LONG_FALL_HEIGHT: float = 1500.0
## Long falls in a row, to hear both hard landings. The seed makes the random picks repeatable.
const LONG_FALLS: int = 8
const RANDOM_SEED: int = 2026
## Physics frames after touching the floor until the player has emitted landed.
const LANDING_FRAMES: int = 2
## Rounding room for the pitch and amplitude limits.
const LIMIT_TOLERANCE: float = 0.0001
## A start into the jump's file unlike the default, in s, so the case can tell it was used.
const TEST_START: float = 0.05


func _initialize() -> void:
	make_wall(WALL_FACE - WALL_THICKNESS, WALL_FACE, WALL_TOP)
	make_platform(WALL_FACE - WALL_THICKNESS, FLOOR_RIGHT)
	var results: Array[bool] = []
	results.append(await _wall_slide_sound_plays_while_sliding_down_only())
	results.append(await _sounds_come_from_where_the_player_is())
	results.append(await _jump_plays_the_jump_sound())
	results.append(await _jump_plays_from_jump_start())
	results.append(await _wall_jump_plays_the_jump_sound())
	results.append(await _landing_from_a_few_px_is_silent())
	results.append(await _landing_after_a_normal_jump_is_soft())
	results.append(await _landing_after_a_wall_slide_is_soft())
	results.append(await _landing_after_a_long_fall_is_hard_with_both_sounds())
	finish(results)


## Pushing into the wall from the air: the sound plays once the player slides down, and stops on
## the floor.
func _wall_slide_sound_plays_while_sliding_down_only() -> bool:
	var player: Player = spawn_player(SLIDE_START)
	var sounds: PlayerSounds = _sounds(player)
	Input.action_press(&"move_left")
	var played_while_sliding: bool = false
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if player.get_state() == Player.State.ON_WALL and player.velocity.y > 0.0:
			# PlayerSounds runs after the player on the same frame, so it has already started.
			played_while_sliding = sounds.wall_slide.playing
			break
	var landed: bool = await wait_until_on_floor(player)
	await physics_frame
	var stopped_on_the_floor: bool = not sounds.wall_slide.playing
	Input.action_release(&"move_left")
	player.queue_free()
	return report(played_while_sliding and landed and stopped_on_the_floor,
			"Wall slide sound: playing while sliding down %s, stopped after landing %s"
			% [played_while_sliding, landed and stopped_on_the_floor])


## The bug: under a plain Node, the 2D sound players stayed at the world origin, and 2000 px away
## from it (their Max Distance) they went silent. Far from the origin, all of them sit on the player.
func _sounds_come_from_where_the_player_is() -> bool:
	var player: Player = await spawn_on_floor(FAR_FROM_THE_ORIGIN)
	if player == null:
		return report(false, "the player never landed far from the origin")
	var sounds: PlayerSounds = _sounds(player)
	var offsets: Array[float] = []
	for sound: AudioStreamPlayer2D in [sounds.wall_slide, sounds.jump, sounds.land]:
		offsets.append(sound.global_position.distance_to(player.global_position))
	player.queue_free()
	return report(offsets.max() <= POSITION_TOLERANCE,
			"At x = %.0f, the wall slide, the jump and the landing are %s px from the player (expected 0)"
			% [FAR_FROM_THE_ORIGIN.x, offsets])


func _jump_plays_the_jump_sound() -> bool:
	var player: Player = await spawn_on_floor(RUN_START)
	if player == null:
		return report(false, "the player never landed to jump")
	var sounds: PlayerSounds = _sounds(player)
	var jumps: Array[int] = [0]
	sounds.jump_played.connect(func() -> void: jumps[0] += 1)
	Input.action_press(&"jump")
	await _wait_frames(PRESS_DELAY_FRAMES + 1)
	Input.action_release(&"jump")
	var in_range: bool = _pitch_in_range(sounds, sounds.jump)
	player.queue_free()
	return report(jumps[0] == 1 and in_range,
			"Jump off the floor: %d jump sound(s), expected 1, pitch in range %s" % [jumps[0], in_range])


## The bug: the jump's file is quiet for its first 30 ms and loudest at 60 ms, so its loud part came
## after he had left the floor. It plays from Jump Start. jump_played comes right after the play, so
## the sound player still gives back the start it was told.
func _jump_plays_from_jump_start() -> bool:
	var player: Player = await spawn_on_floor(RUN_START)
	if player == null:
		return report(false, "the player never landed to jump from Jump Start")
	var sounds: PlayerSounds = _sounds(player)
	sounds.jump_start = TEST_START
	var starts: Array[float] = []
	sounds.jump_played.connect(func() -> void: starts.append(sounds.jump.get_playback_position()))
	Input.action_press(&"jump")
	await _wait_frames(PRESS_DELAY_FRAMES + 1)
	Input.action_release(&"jump")
	player.queue_free()
	return report(starts.size() == 1 and absf(starts[0] - TEST_START) <= LIMIT_TOLERANCE,
			"Jump from Jump Start %.2f s: started from %s s" % [TEST_START, starts])


func _wall_jump_plays_the_jump_sound() -> bool:
	var player: Player = spawn_player(SLIDE_START)
	var sounds: PlayerSounds = _sounds(player)
	var jumps: Array[int] = [0]
	sounds.jump_played.connect(func() -> void: jumps[0] += 1)
	var wall_jumps: Array[int] = [0]
	player.wall_jumped.connect(func(_late: int, _buffered: int) -> void: wall_jumps[0] += 1)
	Input.action_press(&"move_left")
	var reached: bool = false
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if player.get_state() == Player.State.ON_WALL:
			reached = true
			break
	Input.action_press(&"jump")
	await _wait_frames(PRESS_DELAY_FRAMES + 1)
	Input.action_release(&"jump")
	Input.action_release(&"move_left")
	player.queue_free()
	return report(reached and wall_jumps[0] == 1 and jumps[0] == 1,
			"Wall jump: %d wall jump(s), %d jump sound(s), expected 1 and 1"
			% [wall_jumps[0], jumps[0]])


## A player spawned 2 px above the floor lands on its first frames, as at the start of a level.
func _landing_from_a_few_px_is_silent() -> bool:
	var player: Player = spawn_player(RUN_START)
	var landings: Array[bool] = []
	_sounds(player).land_played.connect(func(hard: bool) -> void: landings.append(hard))
	var landed: bool = await wait_until_on_floor(player)
	await _wait_frames(LANDING_FRAMES)
	player.queue_free()
	return report(landed and landings.is_empty(),
			"Landing from 2 px: %d landing sound(s), expected 0" % landings.size())


func _landing_after_a_normal_jump_is_soft() -> bool:
	var player: Player = await spawn_on_floor(RUN_START)
	if player == null:
		return report(false, "the player never landed to jump")
	var sounds: PlayerSounds = _sounds(player)
	var landings: Array[bool] = []
	sounds.land_played.connect(func(hard: bool) -> void: landings.append(hard))
	Input.action_press(&"jump")
	await _wait_frames(PRESS_DELAY_FRAMES + 1)
	var rose: bool = not player.is_on_floor()
	Input.action_release(&"jump")
	var landed: bool = await wait_until_on_floor(player)
	await _wait_frames(LANDING_FRAMES)
	var in_range: bool = _pitch_in_range(sounds, sounds.land)
	var soft: bool = sounds.land.stream == sounds.soft_land_sound
	var jump_cut: bool = not sounds.jump.playing
	player.queue_free()
	return report(rose and landed and landings == [false] and soft and in_range and jump_cut,
			"Landing after a normal jump: landings %s, expected [false] (soft), soft sound %s, pitch in range %s, jump sound stopped %s"
			% [landings, soft, in_range, jump_cut])


## The wall is far taller than Hard Land Height, but sliding down it is not a fall.
func _landing_after_a_wall_slide_is_soft() -> bool:
	var player: Player = spawn_player(SLIDE_START)
	var landings: Array[bool] = []
	_sounds(player).land_played.connect(func(hard: bool) -> void: landings.append(hard))
	Input.action_press(&"move_left")
	var landed: bool = await wait_until_on_floor(player)
	await _wait_frames(LANDING_FRAMES)
	Input.action_release(&"move_left")
	player.queue_free()
	return report(landed and landings == [false],
			"Landing after a %.0f px wall slide: landings %s, expected [false] (soft)"
			% [-SLIDE_START.y, landings])


func _landing_after_a_long_fall_is_hard_with_both_sounds() -> bool:
	seed(RANDOM_SEED)
	var hard_falls: int = 0
	var streams_heard: Array[AudioStream] = []
	var pitches_in_range: bool = true
	for _fall: int in LONG_FALLS:
		var player: Player = spawn_player(Vector2(RUN_START.x, -LONG_FALL_HEIGHT))
		var sounds: PlayerSounds = _sounds(player)
		var landings: Array[bool] = []
		sounds.land_played.connect(func(hard: bool) -> void: landings.append(hard))
		await wait_until_on_floor(player)
		await _wait_frames(LANDING_FRAMES)
		if landings == [true]:
			hard_falls += 1
		if not streams_heard.has(sounds.land.stream):
			streams_heard.append(sounds.land.stream)
		pitches_in_range = pitches_in_range and _pitch_in_range(sounds, sounds.land)
		player.queue_free()
	var probe: PlayerSounds = _sounds(PLAYER_SCENE.instantiate() as Player)
	var both_used: bool = streams_heard.size() == probe.hard_land_sounds.size() 			and probe.hard_land_sounds.all(func(sound: AudioStream) -> bool:
				return streams_heard.has(sound))
	probe.get_parent().free()
	return report(hard_falls == LONG_FALLS and both_used and pitches_in_range,
			"%d falls of %.0f px: %d hard landings, both hard sounds used %s, pitch in range %s"
			% [LONG_FALLS, LONG_FALL_HEIGHT, hard_falls, both_used, pitches_in_range])


func _pitch_in_range(sounds: PlayerSounds, sound: AudioStreamPlayer2D) -> bool:
	return absf(sound.pitch_scale - 1.0) <= sounds.pitch_variation + LIMIT_TOLERANCE


func _sounds(player: Player) -> PlayerSounds:
	return player.get_node(^"PlayerSounds") as PlayerSounds


func _wait_frames(frames: int) -> void:
	for _frame: int in frames:
		await physics_frame
