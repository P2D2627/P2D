# Checks the player's sounds. Running on the floor plays a step every Step Length of the walk cycle,
# on the walk's planted frames, the first on the frame the player starts to run from standing still,
# and standing still or being in the air plays none. Each step sound holds one impact, all of them
# are as loud as each other, and each step is one of them, never the same twice in a row, at
# Footstep Volume, with its pitch and amplitude inside the variations set in PlayerSounds. The wall slide sound plays while sliding down a wall and stops on landing. The sounds
# come from where the player is, so they are heard anywhere in a level and not only near its origin.
# A jump, off the floor or off a wall, plays the jump sound. Landing after a normal jump or a wall
# slide is soft and cuts the jump sound off, after a long fall hard, with both hard sounds in use,
# and landing from a few px
# (as at the start of a level) makes no sound. Jumps and landings keep their pitch inside the
# variation too.
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
## Frames of each run: two seconds at top speed is several steps.
const RUN_FRAMES: int = 120
## Frames to stand still, or to fall, while no step may play.
const QUIET_FRAMES: int = 60
## Frames to stand on the floor before a run, so it starts from standing still and not from the
## landing, whose first step comes at half a Step Length.
const STAND_FRAMES: int = 5
## Frames of a long run, to hear many steps and check all of them.
const LONG_RUN_FRAMES: int = 600
## A step lands on the frame that crosses the distance, so the count may be one off the ideal.
const STEP_COUNT_TOLERANCE: int = 1
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
## A step sound's impact: a moment within IMPACT_DB of its loudest. It ends once the sound falls
## SILENCE_DB below the loudest, so a second impact needs a quiet gap before it, as in the old
## files, where it came 143 to 145 ms after the first, after a gap at -50 dB.
const IMPACT_DB: float = 20.0
const SILENCE_DB: float = 30.0
## How finely a step sound is read: the loudest sample of each millisecond.
const ENVELOPE_MS: float = 1.0
## A start into the jump's file unlike the default, in s, so the case can tell it was used.
const TEST_START: float = 0.05
## How a step sound's loudness is read: its loudest window of LEVEL_WINDOW_MS, in RMS. The step
## sounds may differ by LEVEL_SPREAD_DB at most, so none is lost under the ambience where the others
## are heard.
const LEVEL_WINDOW_MS: float = 10.0
const LEVEL_SPREAD_DB: float = 1.0
## A Footstep Volume unlike the default, in dB, so the case can tell it was used.
const TEST_VOLUME_DB: float = 4.0


func _initialize() -> void:
	make_wall(WALL_FACE - WALL_THICKNESS, WALL_FACE, WALL_TOP)
	make_platform(WALL_FACE - WALL_THICKNESS, FLOOR_RIGHT)
	var results: Array[bool] = []
	results.append(await _first_step_plays_as_running_starts())
	results.append(await _running_steps_every_step_distance())
	results.append(await _standing_still_and_falling_make_no_steps())
	results.append(_each_step_sound_is_one_impact())
	results.append(_step_sounds_are_equally_loud())
	results.append(await _steps_vary_the_sound_pitch_and_amplitude())
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


## The bug: the first step came only after half a Step Distance, 0.2 s into the run, so starting
## to run sounded late. From standing still, it plays on the first frame the player moves.
func _first_step_plays_as_running_starts() -> bool:
	var player: Player = await spawn_on_floor(RUN_START)
	if player == null:
		return report(false, "the player never landed to start running")
	var steps: Array[int] = []
	_sounds(player).footstep_played.connect(func(index: int) -> void: steps.append(index))
	await _wait_frames(STAND_FRAMES)
	Input.action_press(&"move_right")
	var moved: bool = await wait_until(func() -> bool: return player.velocity.x != 0.0)
	# The step comes from the walk, which PlayerAnimation picks in _process: later in the same frame
	# as the physics that moved him, not on a later one.
	await process_frame
	var steps_on_the_first_frame: int = steps.size()
	Input.action_release(&"move_right")
	player.queue_free()
	return report(moved and steps_on_the_first_frame == 1,
			"Starting to run: %d step(s) on the first frame the player moves, expected 1"
			% steps_on_the_first_frame)


## Over a run of d px from standing still, the first step comes at once, then one every Step
## Length of the walk cycle.
func _running_steps_every_step_distance() -> bool:
	var player: Player = await spawn_on_floor(RUN_START)
	if player == null:
		return report(false, "the player never landed for the run")
	var sounds: PlayerSounds = _sounds(player)
	var step_length: float = sounds.animation.step_length
	var steps: Array[int] = []
	sounds.footstep_played.connect(func(index: int) -> void: steps.append(index))
	await _wait_frames(STAND_FRAMES)
	var start_x: float = player.position.x
	Input.action_press(&"move_right")
	await _wait_frames(RUN_FRAMES)
	Input.action_release(&"move_right")
	var distance: float = player.position.x - start_x
	var expected: int = floori(distance / step_length) + 1
	player.queue_free()
	return report(absi(steps.size() - expected) <= STEP_COUNT_TOLERANCE,
			"Running %.0f px with Step Length %.0f px: %d steps, expected %d"
			% [distance, step_length, steps.size(), expected])


func _standing_still_and_falling_make_no_steps() -> bool:
	var player: Player = await spawn_on_floor(RUN_START)
	if player == null:
		return report(false, "the player never landed to stand still")
	var steps: Array[int] = []
	_sounds(player).footstep_played.connect(func(index: int) -> void: steps.append(index))
	await _wait_frames(QUIET_FRAMES)
	var standing: int = steps.size()
	player.queue_free()
	# Running through the air, from high up, never touches the floor in QUIET_FRAMES.
	var falling_player: Player = spawn_player(Vector2(RUN_START.x, WALL_TOP))
	var falling: Array[int] = []
	_sounds(falling_player).footstep_played.connect(func(index: int) -> void: falling.append(index))
	Input.action_press(&"move_right")
	await _wait_frames(QUIET_FRAMES)
	Input.action_release(&"move_right")
	var stayed_in_the_air: bool = not falling_player.is_on_floor()
	falling_player.queue_free()
	return report(standing == 0 and falling.is_empty() and stayed_in_the_air,
			"Standing still: %d steps; running in the air: %d steps (expected 0 and 0)"
			% [standing, falling.size()])


## The bug: each of the three step files held two impacts, the second 143 to 145 ms after the
## first, so a run heard an extra hit between every two drawn steps. Each step sound in the scene,
## read from its source file, holds one.
func _each_step_sound_is_one_impact() -> bool:
	var player: Player = spawn_player(RUN_START)
	var sounds: PlayerSounds = _sounds(player)
	var counts: Array[String] = []
	var all_one: bool = not sounds.footstep_sounds.is_empty()
	for stream: AudioStream in sounds.footstep_sounds:
		var impacts: int = _impacts_in(stream)
		counts.append("%s %d" % [stream.resource_path.get_file(), impacts])
		all_one = all_one and impacts == 1
	player.queue_free()
	return report(all_one, "Impacts in each step sound (expected 1 each): %s" % ", ".join(counts))


## The bug: the six step files spread over 7 dB (their loudest 10 ms from -34.0 to -27.1 dBFS), so
## in level 1 the quiet ones sat 3 dB over the ambience and were lost while the others were heard.
## Read from their source files, they are as loud as each other.
func _step_sounds_are_equally_loud() -> bool:
	var player: Player = spawn_player(RUN_START)
	var sounds: PlayerSounds = _sounds(player)
	var levels: Array[String] = []
	var quietest: float = INF
	var loudest: float = -INF
	for stream: AudioStream in sounds.footstep_sounds:
		var level: float = _loudest_window_db(stream)
		levels.append("%s %.1f" % [stream.resource_path.get_file(), level])
		quietest = minf(quietest, level)
		loudest = maxf(loudest, level)
	player.queue_free()
	return report(loudest - quietest <= LEVEL_SPREAD_DB,
			"Loudest %.0f ms of each step sound, in dBFS: %s; spread %.1f dB, at most %.1f"
			% [LEVEL_WINDOW_MS, ", ".join(levels), loudest - quietest, LEVEL_SPREAD_DB])


## Over a long run, every sound is heard, none twice in a row, and each step plays at Footstep
## Volume, here set to a test value, with its pitch and amplitude within the variations around it.
## The seed makes the random picks repeatable: with six sounds, a run of about 27 steps could
## otherwise miss one by chance.
func _steps_vary_the_sound_pitch_and_amplitude() -> bool:
	seed(RANDOM_SEED)
	var player: Player = await spawn_on_floor(RUN_START)
	if player == null:
		return report(false, "the player never landed for the long run")
	var sounds: PlayerSounds = _sounds(player)
	sounds.footstep_volume_db = TEST_VOLUME_DB
	var base: float = db_to_linear(TEST_VOLUME_DB)
	var indices: Array[int] = []
	var pitch_ok: Array[bool] = [true]
	var volume_ok: Array[bool] = [true]
	sounds.footstep_played.connect(func(index: int) -> void:
		indices.append(index)
		if absf(sounds.footstep.pitch_scale - 1.0) > sounds.pitch_variation + LIMIT_TOLERANCE:
			pitch_ok[0] = false
		if absf(sounds.footstep.volume_linear / base - 1.0) \
				> sounds.footstep_volume_variation + LIMIT_TOLERANCE:
			volume_ok[0] = false)
	Input.action_press(&"move_right")
	await _wait_frames(LONG_RUN_FRAMES)
	Input.action_release(&"move_right")
	player.queue_free()
	var repeats: int = 0
	for i: int in range(1, indices.size()):
		if indices[i] == indices[i - 1]:
			repeats += 1
	var used: int = 0
	for index: int in sounds.footstep_sounds.size():
		if indices.has(index):
			used += 1
	return report(repeats == 0 and used == sounds.footstep_sounds.size()
			and pitch_ok[0] and volume_ok[0],
			"%d steps: %d of %d sounds used, %d repeats in a row, pitch in range %s, amplitude in range around Footstep Volume %.0f dB %s"
			% [indices.size(), used, sounds.footstep_sounds.size(), repeats, pitch_ok[0],
			TEST_VOLUME_DB, volume_ok[0]])


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
## from it (their Max Distance) they went silent. Far from the origin, both sit on the player.
func _sounds_come_from_where_the_player_is() -> bool:
	var player: Player = await spawn_on_floor(FAR_FROM_THE_ORIGIN)
	if player == null:
		return report(false, "the player never landed far from the origin")
	var sounds: PlayerSounds = _sounds(player)
	var footstep_offset: float = sounds.footstep.global_position.distance_to(player.global_position)
	var slide_offset: float = sounds.wall_slide.global_position.distance_to(player.global_position)
	player.queue_free()
	return report(footstep_offset <= POSITION_TOLERANCE and slide_offset <= POSITION_TOLERANCE,
			"At x = %.0f, the footstep is %.0f px from the player and the wall slide %.0f px (expected 0)"
			% [FAR_FROM_THE_ORIGIN.x, footstep_offset, slide_offset])


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


## A sound's source file as plain 16-bit samples, or null when it is not a WAV that reads so.
func _pcm(stream: AudioStream) -> AudioStreamWAV:
	var wav: AudioStreamWAV = AudioStreamWAV.load_from_file(stream.resource_path,
			{"compress/mode": 0})
	if wav == null or wav.format != AudioStreamWAV.FORMAT_16_BITS:
		return null
	return wav


## The loudest LEVEL_WINDOW_MS of a sound's source file, in RMS dBFS over all its channels, with
## windows every half window. -INF when it does not read.
func _loudest_window_db(stream: AudioStream) -> float:
	var wav: AudioStreamWAV = _pcm(stream)
	if wav == null:
		return -INF
	var channels: int = 2 if wav.stereo else 1
	var window: int = roundi(wav.mix_rate * LEVEL_WINDOW_MS / 1000.0) * channels
	var data: PackedByteArray = wav.data
	var squares: PackedFloat64Array = []
	for i: int in data.size() / 2:
		var sample: float = data.decode_s16(i * 2) / 32768.0
		squares.append(sample * sample)
	var loudest: float = 0.0
	for start: int in range(0, squares.size() - window, window / 2):
		var sum: float = 0.0
		for i: int in range(start, start + window):
			sum += squares[i]
		loudest = maxf(loudest, sqrt(sum / window))
	return linear_to_db(loudest)


## How many impacts a sound holds, read from its source file as plain 16-bit samples, one loudest
## sample per ENVELOPE_MS.
func _impacts_in(stream: AudioStream) -> int:
	var wav: AudioStreamWAV = _pcm(stream)
	if wav == null:
		return 0
	var channels: int = 2 if wav.stereo else 1
	var per_ms: int = maxi(roundi(wav.mix_rate * ENVELOPE_MS / 1000.0), 1)
	var data: PackedByteArray = wav.data
	var envelope: PackedFloat32Array = []
	var loudest: float = 0.0
	var sample_count: int = data.size() / 2
	for start: int in range(0, sample_count, per_ms * channels):
		var peak: float = 0.0
		for i: int in range(start, mini(start + per_ms * channels, sample_count)):
			peak = maxf(peak, absf(data.decode_s16(i * 2)))
		envelope.append(peak)
		loudest = maxf(loudest, peak)
	var impact_level: float = loudest * db_to_linear(-IMPACT_DB)
	var silence_level: float = loudest * db_to_linear(-SILENCE_DB)
	var impacts: int = 0
	var in_impact: bool = false
	for peak: float in envelope:
		if not in_impact and peak >= impact_level:
			impacts += 1
			in_impact = true
		elif in_impact and peak < silence_level:
			in_impact = false
	return impacts


func _pitch_in_range(sounds: PlayerSounds, sound: AudioStreamPlayer2D) -> bool:
	return absf(sound.pitch_scale - 1.0) <= sounds.pitch_variation + LIMIT_TOLERANCE


func _sounds(player: Player) -> PlayerSounds:
	return player.get_node(^"PlayerSounds") as PlayerSounds


func _wait_frames(frames: int) -> void:
	for _frame: int in frames:
		await physics_frame
