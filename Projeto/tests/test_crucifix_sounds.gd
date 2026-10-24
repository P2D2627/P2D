# Checks the crucifix's sounds and the signals they follow. Raising plays the raise, then the hold
# once the raise ends; letting go or leaving the floor cuts both off and plays the holster; running
# out of Max Use Time plays the cooldown's sound instead, or nothing while it has no file. The end of
# the cooldown plays the available sound, and a press during it plays the unavailable sound, except
# a press close enough to the end that the kept press raises the crucifix once it is ready. The
# scene holds the files of those three. The cases put the step sounds in those slots instead, so
# they can tell which one played whatever the files are. The timing cases use short times on their
# own copy of Crucifix Stats, as test_crucifix.gd does.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_crucifix_sounds.gd
extends "res://tests/support/player_test.gd"

## Stand-ins for the cooldown's, the available and the unavailable sounds.
const COOLDOWN_STAND_IN: AudioStream = preload("res://assets/audio/footstep_1.wav")
const AVAILABLE_STAND_IN: AudioStream = preload("res://assets/audio/footstep_2.wav")
const UNAVAILABLE_STAND_IN: AudioStream = preload("res://assets/audio/footstep_3.wav")
## The floor's top is at y = 0, from x = FLOOR_LEFT to x = FLOOR_RIGHT.
const FLOOR_LEFT: float = -200.0
const FLOOR_RIGHT: float = 6000.0
## Where a case on the floor starts: just above it, and far from its ends.
const FLOOR_START: Vector2 = Vector2(2000.0, -2.0)
## A short platform, away from the main floor, to walk off: from x = LEDGE_LEFT to x = LEDGE_RIGHT.
const LEDGE_LEFT: float = 8000.0
const LEDGE_RIGHT: float = 8200.0
const LEDGE_START: Vector2 = Vector2(8100.0, -2.0)
## Frames to wait after a press or a contact, so what follows from it has surely happened.
const SETTLE_FRAMES: int = 3
## Frames a short use lasts before Crucifix is let go.
const SHORT_HOLD_FRAMES: int = 10
## Max Use Time and Cooldown Time of the timing cases, in s: 30 and 60 frames.
const SHORT_USE_TIME: float = 0.5
const SHORT_COOLDOWN_TIME: float = 1.0
## Max Use Time of the case that waits for the raise's sound to end, in s (1800 frames), so the
## crucifix is still up then.
const LONG_USE_TIME: float = 30.0
## Real time the raise's sound may take to end, in ms. The sounds play in real time, while the frames
## of a test run far faster than that: about 6000 a second, so the raise (0.22 s) ended on frame 1626.
const RAISE_END_WAIT_MS: int = 2000
## Real time each frame of that wait takes at least, in ms, so the wait stays well under the long
## use's frames: at most 1000 of its 1800.
const FRAME_DELAY_MS: int = 2


func _initialize() -> void:
	make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	make_platform(LEDGE_LEFT, LEDGE_RIGHT)
	var results: Array[bool] = []
	results.append(await _raising_plays_the_raise_then_the_hold())
	results.append(await _letting_go_plays_the_holster())
	results.append(await _leaving_the_floor_plays_the_holster())
	results.append(await _running_out_of_time_plays_the_cooldown_sound())
	results.append(await _running_out_of_time_with_no_cooldown_sound_plays_nothing())
	results.append(await _the_end_of_the_cooldown_plays_the_available_sound())
	results.append(await _a_press_in_the_cooldown_plays_the_unavailable_sound())
	results.append(await _a_press_is_refused_exactly_when_it_does_not_raise_it())
	results.append(_the_scene_holds_the_cooldown_sounds())
	finish(results)


## The raise plays on the cue with the hold quiet; once it ends, with the crucifix still up, the
## hold plays.
func _raising_plays_the_raise_then_the_hold() -> bool:
	var player: Player = await spawn_on_floor(FLOOR_START)
	if player == null:
		return report(false, "Raising: the player never landed")
	var crucifix: Crucifix = _crucifix_of(player)
	var sounds: CrucifixSounds = _sounds_of(crucifix)
	crucifix.stats = crucifix.stats.duplicate() as CrucifixStats
	crucifix.stats.max_use_time = LONG_USE_TIME
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.crucifix_held = true
	await wait_frames(SETTLE_FRAMES)
	var raise_playing: bool = sounds.cue.playing and sounds.cue.stream == sounds.raise_sound
	var hold_quiet: bool = not sounds.hold.playing
	var deadline: int = Time.get_ticks_msec() + RAISE_END_WAIT_MS
	while not sounds.hold.playing and crucifix.is_raised() and Time.get_ticks_msec() < deadline:
		OS.delay_msec(FRAME_DELAY_MS)
		await physics_frame
	var hold_then: bool = sounds.hold.playing and crucifix.is_raised()
	await remove_player(player)
	return report(raise_playing and hold_quiet and hold_then,
			"Raising: raise playing %s, hold quiet meanwhile %s, hold playing once the raise ends %s"
			% [raise_playing, hold_quiet, hold_then])


func _letting_go_plays_the_holster() -> bool:
	var player: Player = await spawn_on_floor(FLOOR_START)
	if player == null:
		return report(false, "Letting go: the player never landed")
	var crucifix: Crucifix = _crucifix_of(player)
	var sounds: CrucifixSounds = _sounds_of(crucifix)
	sounds.cooldown_sound = COOLDOWN_STAND_IN
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.crucifix_held = true
	await wait_frames(SETTLE_FRAMES + SHORT_HOLD_FRAMES)
	stand_in.crucifix_held = false
	var went_down: bool = await wait_until(func() -> bool: return not crucifix.is_raised(),
			SETTLE_FRAMES)
	var holster: bool = sounds.cue.playing and sounds.cue.stream == sounds.holster_sound
	var hold_stopped: bool = not sounds.hold.playing
	await remove_player(player)
	return report(went_down and holster and hold_stopped,
			"Letting go: went down %s, holster playing %s, hold stopped %s"
			% [went_down, holster, hold_stopped])


## Walking off a ledge with the crucifix up lowers it with the holster, not the cooldown's sound.
func _leaving_the_floor_plays_the_holster() -> bool:
	var player: Player = await spawn_on_floor(LEDGE_START)
	if player == null:
		return report(false, "Walking off a ledge: the player never landed")
	var crucifix: Crucifix = _crucifix_of(player)
	var sounds: CrucifixSounds = _sounds_of(crucifix)
	sounds.cooldown_sound = COOLDOWN_STAND_IN
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.crucifix_held = true
	await wait_frames(SETTLE_FRAMES)
	var up_before: bool = crucifix.is_raised()
	stand_in.run_direction = 1.0
	var went_down: bool = await wait_until(func() -> bool: return not crucifix.is_raised())
	var left_floor: bool = not player.is_on_floor()
	var holster: bool = sounds.cue.playing and sounds.cue.stream == sounds.holster_sound
	await remove_player(player)
	return report(up_before and went_down and left_floor and holster,
			"Walking off a ledge: up before %s, went down in the air %s, holster playing %s"
			% [up_before, went_down and left_floor, holster])


## Held until Max Use Time runs out: ran_out once, then the cooldown's sound, with the hold stopped.
func _running_out_of_time_plays_the_cooldown_sound() -> bool:
	var player: Player = await spawn_on_floor(FLOOR_START)
	if player == null:
		return report(false, "Running out of time: the player never landed")
	var crucifix: Crucifix = _crucifix_of(player)
	var sounds: CrucifixSounds = _sounds_of(crucifix)
	_use_short_times(crucifix)
	sounds.cooldown_sound = COOLDOWN_STAND_IN
	var ran_out: Array[int] = [0]
	crucifix.ran_out.connect(func() -> void: ran_out[0] += 1)
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.crucifix_held = true
	var cooling: bool = await _wait_for_the_cooldown(crucifix)
	var cooldown_sound: bool = sounds.cue.playing and sounds.cue.stream == COOLDOWN_STAND_IN
	var hold_stopped: bool = not sounds.hold.playing
	await remove_player(player)
	return report(cooling and ran_out[0] == 1 and cooldown_sound and hold_stopped,
			"Running out of time: cooldown reached %s, ran_out %d time(s), expected 1, cooldown sound playing %s, hold stopped %s"
			% [cooling, ran_out[0], cooldown_sound, hold_stopped])


## Until crucifix_cd exists, running out of time goes down in silence, never with the holster.
func _running_out_of_time_with_no_cooldown_sound_plays_nothing() -> bool:
	var player: Player = await spawn_on_floor(FLOOR_START)
	if player == null:
		return report(false, "Running out of time with no sound: the player never landed")
	var crucifix: Crucifix = _crucifix_of(player)
	var sounds: CrucifixSounds = _sounds_of(crucifix)
	_use_short_times(crucifix)
	sounds.cooldown_sound = null
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.crucifix_held = true
	var cooling: bool = await _wait_for_the_cooldown(crucifix)
	var silent: bool = not sounds.cue.playing and not sounds.hold.playing
	await remove_player(player)
	return report(cooling and silent,
			"Running out of time with no cooldown sound: cooldown reached %s, silent %s"
			% [cooling, silent])


func _the_end_of_the_cooldown_plays_the_available_sound() -> bool:
	var player: Player = await spawn_on_floor(FLOOR_START)
	if player == null:
		return report(false, "The end of the cooldown: the player never landed")
	var crucifix: Crucifix = _crucifix_of(player)
	var sounds: CrucifixSounds = _sounds_of(crucifix)
	_use_short_times(crucifix)
	sounds.available_sound = AVAILABLE_STAND_IN
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.crucifix_held = true
	await wait_frames(SETTLE_FRAMES + SHORT_HOLD_FRAMES)
	stand_in.crucifix_held = false
	var cooling: bool = await _wait_for_the_cooldown(crucifix)
	var ready_again: bool = await wait_until(func() -> bool:
		return crucifix.get_phase() == Crucifix.Phase.READY,
		crucifix.stats.get_cooldown_frames() + SETTLE_FRAMES)
	var available: bool = sounds.cue.playing and sounds.cue.stream == AVAILABLE_STAND_IN
	await remove_player(player)
	return report(cooling and ready_again and available,
			"The end of the cooldown: ready again %s, available sound playing %s"
			% [cooling and ready_again, available])


## A press early in the cooldown is refused once, plays the unavailable sound and raises nothing.
func _a_press_in_the_cooldown_plays_the_unavailable_sound() -> bool:
	var player: Player = await spawn_on_floor(FLOOR_START)
	if player == null:
		return report(false, "A press in the cooldown: the player never landed")
	var crucifix: Crucifix = _crucifix_of(player)
	var sounds: CrucifixSounds = _sounds_of(crucifix)
	_use_short_times(crucifix)
	sounds.unavailable_sound = UNAVAILABLE_STAND_IN
	var refusals: Array[int] = [0]
	crucifix.refused.connect(func() -> void: refusals[0] += 1)
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.crucifix_held = true
	await wait_frames(SETTLE_FRAMES + SHORT_HOLD_FRAMES)
	stand_in.crucifix_held = false
	var cooling: bool = await _wait_for_the_cooldown(crucifix)
	await wait_frames(SETTLE_FRAMES)
	stand_in.crucifix_held = true
	await wait_frames(SETTLE_FRAMES)
	var unavailable: bool = sounds.cue.playing and sounds.cue.stream == UNAVAILABLE_STAND_IN
	var still_down: bool = not crucifix.is_raised()
	await remove_player(player)
	return report(cooling and refusals[0] == 1 and unavailable and still_down,
			"A press in the cooldown: refused %d time(s), expected 1, unavailable sound playing %s, still down %s"
			% [refusals[0], unavailable, still_down])


## The kept press lasts Raise Buffer Time. A press with that many frames of cooldown left raises the
## crucifix once it is ready and is not refused; one a frame earlier is refused and raises nothing.
func _a_press_is_refused_exactly_when_it_does_not_raise_it() -> bool:
	var probe: Player = PLAYER_SCENE.instantiate() as Player
	var buffer_frames: int = _crucifix_of(probe).stats.get_raise_buffer_frames()
	probe.queue_free()
	var kept: Array = await _press_with_cooldown_frames_left(buffer_frames)
	var early: Array = await _press_with_cooldown_frames_left(buffer_frames + 1)
	if kept.is_empty() or early.is_empty():
		return report(false, "A press near the end of the cooldown: the player never landed")
	return report(kept == [true, 0, true] and early == [true, 1, false],
			"A press with %d frames of cooldown left: refused %d, raised %s (expected 0, true); with %d left: refused %d, raised %s (expected 1, false)"
			% [buffer_frames, kept[1], kept[2], buffer_frames + 1, early[1], early[2]])


## The crucifix scene has the cooldown's, the available and the unavailable sounds in their slots,
## so none of those moments goes silent.
func _the_scene_holds_the_cooldown_sounds() -> bool:
	var probe: Player = PLAYER_SCENE.instantiate() as Player
	var sounds: CrucifixSounds = _sounds_of(_crucifix_of(probe))
	var files: Array[String] = []
	for sound: AudioStream in [sounds.cooldown_sound, sounds.available_sound,
			sounds.unavailable_sound]:
		files.append(sound.resource_path.get_file() if sound != null else "(empty)")
	probe.queue_free()
	return report(files == ["crucifix_cd.wav", "crucifix_avail.wav", "upgrade_unavail.wav"],
			"The crucifix scene's cooldown, available and unavailable sounds: %s" % [files])


## Uses the crucifix briefly, presses and holds Crucifix with frames_left frames of cooldown left,
## and gives back [whether that moment came, how many refusals, whether it went up], or [] if the
## player never landed.
func _press_with_cooldown_frames_left(frames_left: int) -> Array:
	var player: Player = await spawn_on_floor(FLOOR_START)
	if player == null:
		return []
	var crucifix: Crucifix = _crucifix_of(player)
	_use_short_times(crucifix)
	var refusals: Array[int] = [0]
	crucifix.refused.connect(func() -> void: refusals[0] += 1)
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.crucifix_held = true
	await wait_frames(SETTLE_FRAMES + SHORT_HOLD_FRAMES)
	stand_in.crucifix_held = false
	# Each wait ends just before a frame runs, so the press counts on a frame that starts with
	# frames_left frames of cooldown.
	var reached: bool = await wait_until(func() -> bool:
		return roundi(crucifix.get_cooldown_left() * Engine.physics_ticks_per_second) == frames_left)
	stand_in.crucifix_held = true
	var up: bool = await wait_until(crucifix.is_raised,
			frames_left + crucifix.stats.get_raise_buffer_frames() + SETTLE_FRAMES)
	await remove_player(player)
	return [reached, refusals[0], up]


## Waits until the crucifix is cooling down, for at most a whole use; false if it never does.
func _wait_for_the_cooldown(crucifix: Crucifix) -> bool:
	return await wait_until(func() -> bool:
		return crucifix.get_phase() == Crucifix.Phase.COOLDOWN,
		crucifix.stats.get_max_use_frames() + SETTLE_FRAMES)


func _crucifix_of(player: Player) -> Crucifix:
	return player.get_node(^"Crucifix") as Crucifix


func _sounds_of(crucifix: Crucifix) -> CrucifixSounds:
	return crucifix.get_node(^"CrucifixSounds") as CrucifixSounds


## Gives the crucifix its own copy of Stats with SHORT_USE_TIME and SHORT_COOLDOWN_TIME, so the case
## neither waits the real times nor touches the .tres or the other cases.
func _use_short_times(crucifix: Crucifix) -> void:
	crucifix.stats = crucifix.stats.duplicate() as CrucifixStats
	crucifix.stats.max_use_time = SHORT_USE_TIME
	crucifix.stats.cooldown_time = SHORT_COOLDOWN_TIME
