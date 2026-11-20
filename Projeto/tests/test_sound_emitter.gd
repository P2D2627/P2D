# Checks the sound emitter, the sound of a thing in the world such as a fire. Outside a level it
# hears from the centre of the screen; its loop plays only while the ear is within Hearing
# Distance, goes on a little past it, up to Hearing Margin, and stops beyond, with Godot's own
# falloff off. It loops even when its file's import does not, without changing the file, and two
# emitters start it at different points; the fire's loop plays its reverb tail out under the next
# pass, as loud through Loop End, measured in Godot's mix. The one-shots come one at a time, each
# wait within Deviation of Interval and about Interval on average. Each one-shot moves the stereo
# by Pan Spread to its side, from anywhere on the screen, and is as loud as from the thing, even
# while the ear moves: by Godot's own sums, at level 1's zoom, and measured in Godot's mix, left
# against right. Its loudness follows Default Falloff, or a Falloff of its own, from an Ear of its
# own. Disabled, it stops; told only (Plays On Its Own off), it plays no one-shot by itself and,
# with no loop, sleeps between them; the pause holds its one-shots. The fire's sound has the fire's files, on
# the Ambience bus, with the times asked for; in the lighting prototype, every fire has its sound,
# whose embers leave from its flame and hide with it, and the fires hear from the man: with the
# camera still, they are much quieter halfway between two than beside one.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_sound_emitter.gd
extends "res://tests/support/base_test.gd"

const EMITTER_PATH: String = "res://scenes/others/ambience/sound_emitter.tscn"
const FIRE_SOUND_PATH: String = "res://scenes/others/ambience/fire_sound.tscn"
const FIRE_LOOP_PATH: String = "res://assets/audio/textures/fire/fire_base_layer.ogg"
const CRACKLE_FILES: Array[String] = ["fire_crackle_1.wav", "fire_crackle_2.wav",
		"fire_crackle_3.wav", "fire_crackle_4.wav"]
const LIGHTING_LEVEL_PATH: String = "res://scenes/levels/prototypes/lighting/lighting_level1.tscn"
const AMBIENCE_BUS: StringName = &"Ambience"
## The fire's times, as asked: a crackle about every 4 s, with some deviation, up to 10% of the
## stereo field to either side, its pitch a little varied.
const FIRE_INTERVAL: float = 4.0
const FIRE_DEVIATION: Vector2 = Vector2(0.5, 2.0)
const FIRE_PAN_SPREAD: float = 0.1
const FIRE_MAX_PITCH: float = 1.1
## The game's viewport, which the headless window is set to; a camera far from the origin, zoomed
## in as level 1's camera zones are.
const SCREEN_SIZE: Vector2i = Vector2i(1920, 1080)
const CAMERA_AT: Vector2 = Vector2(5000.0, -3000.0)
const ZOOM: float = 1.3
## The length of a frame with --fixed-fps 60, as in the command above.
const FRAME_TIME: float = 1.0 / 60.0
const RANDOM_SEED: int = 2026
const HEARING: float = 1500.0
const MARGIN: float = 100.0
## Frames for a move to be heard.
const SETTLE_FRAMES: int = 3
## Short waits, so a test hears many one-shots in little time: in s.
const TEST_INTERVAL: float = 1.0
const TEST_DEVIATION: float = 0.4
const ONE_SHOTS_TO_HEAR: int = 30
const FRAMES_FOR_ALL: int = int(ONE_SHOTS_TO_HEAR * (TEST_INTERVAL + TEST_DEVIATION) / FRAME_TIME) + 60
## How far the mean wait over the one-shots may stray from Interval (about 2.8 standard deviations
## of the mean of 29 waits spread evenly over 0.8 s), and the smallest spread of the waits.
const MEAN_TOLERANCE: float = 0.12
const MIN_WAIT_SPREAD: float = 0.4
## Rounding room for the waits.
const LIMIT_TOLERANCE: float = 0.001
## Where things are put, from the centre of the screen, to check the sums: in the middle, to the
## right and below, and to the left and above, near the edge of the screen (738 px from the
## centre at zoom 1.3). From each, a one-shot keeps the side asked for.
const PLACES: Array[Vector2] = [Vector2.ZERO, Vector2(500.0, 100.0), Vector2(-600.0, -200.0)]
## How far the camera moves while a one-shot plays, in px: its volume follows.
const CAMERA_MOVE: Vector2 = Vector2(300.0, -150.0)
const FOLLOWED_AT: Vector2 = Vector2(400.0, 0.0)
const SIDES: Array[float] = [-1.0, -0.5, 0.5, 1.0]
## How far Godot's pan and loudness of a one-shot may stray from what is asked, by the sums.
const PAN_TOLERANCE: float = 0.002
const LOUDNESS_TOLERANCE: float = 0.01
## A thing near the right edge of hearing, from the ear: a one-shot to its right plays further out.
const NEAR_THE_EDGE: Vector2 = Vector2(1100.0, 0.0)
## Where an ear of the emitter's own is, from the centre of the screen: far off it, so the screen
## does not count; and the share of its volume a flat Falloff of its own gives.
const EAR_AWAY: Vector2 = Vector2(-4000.0, 2500.0)
const OWN_FALLOFF: float = 0.3
## The tone the measured case plays: sample rate, pitch, amplitude, and length, in s, longer than
## the measure.
const TONE_RATE: int = 44100
const TONE_HZ: float = 441.0
const TONE_AMPLITUDE: float = 0.3
const TONE_LENGTH: float = 3.0
## Where the thing is, from the centre of the screen, in the measured case.
const MEASURED_AT: Vector2 = Vector2(300.0, 0.0)
## Real seconds the mix settles for, and is measured over. The capture keeps more than that.
const SETTLE_TIME: float = 0.1
const MEASURE_TIME: float = 0.3
const CAPTURE_LENGTH: float = 2.0
## How far the measured pan and loudness may stray: the mix rounds, and its volume ramps.
const MEASURED_PAN_TOLERANCE: float = 0.01
const MEASURED_LOUDNESS_TOLERANCE: float = 0.03
## Frames the pause is held for: several waits.
const PAUSED_FRAMES: int = int(4.0 * (TEST_INTERVAL + TEST_DEVIATION) / FRAME_TIME)
## Frames the lighting prototype takes to set up its fires.
const LEVEL_FRAMES: int = 10
## The fire's file: its dry sound ends here, in s, and a reverb tail dies to silence after it.
const FIRE_DRY_END: float = 10.735
const FIRE_END_TOLERANCE: float = 0.05
## Where in the fire's file a pass is started, a little before its Loop End, in s, and the real
## seconds its loudness is measured over, in windows: through Loop End and well into where the tail
## alone would have died, and how far below the loudest window the quietest may fall, in dB (the
## loop's own swing, window to window, is under 4 dB; the tail alone falls 20 dB in 1.5 s).
const FIRE_TEST_FROM: float = 10.0
const FIRE_WINDOW: float = 0.25
const FIRE_WINDOWS: int = 10
const FIRE_STEADY_DB: float = 6.0
## Two fires of the prototype side by side on one floor, this far apart at least and at most, in px;
## where the man stands beside the first, from its base, and how much quieter, in dB, all the fires
## together must be halfway to the second than beside the first, wherever the camera is.
const FIRE_PAIR_GAP: Vector2 = Vector2(900.0, 1600.0)
const BESIDE_FIRE: Vector2 = Vector2(60.0, -40.0)
const WALKING_AWAY_DB: float = 9.0
## Physics frames for the man to be placed and the fires to hear it.
const PLACE_FRAMES: int = 4

var _emitter_scene: PackedScene
var _camera: Camera2D
## When each one-shot played, in frames since _listen() began, and from which side.
var _frame: int = 0
var _heard_frames: Array[int] = []
var _heard_sides: Array[float] = []


func _initialize() -> void:
	_emitter_scene = load(EMITTER_PATH) as PackedScene
	if _emitter_scene == null:
		_report(false, "%s loads as a scene" % EMITTER_PATH)
		_finish([false])
		return
	# Without a window, the root takes the game's viewport only after a frame (see the commands'
	# notes).
	await process_frame
	root.size = SCREEN_SIZE
	await process_frame
	_camera = Camera2D.new()
	# The project interpolates physics, which moves every Camera2D to the physics frame anyway.
	_camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	_camera.position = CAMERA_AT
	_camera.zoom = Vector2(ZOOM, ZOOM)
	root.add_child(_camera)
	_camera.make_current()
	await _wait_frames(SETTLE_FRAMES)
	seed(RANDOM_SEED)
	var results: Array[bool] = []
	results.append(await _heard_only_within_hearing_distance())
	results.append(await _the_loop_loops_without_changing_its_file())
	results.append(await _the_fire_loop_goes_on_over_its_tail())
	results.append(await _one_shots_come_about_every_interval())
	results.append(await _one_shots_move_the_stereo_by_pan_spread_as_loud())
	results.append(await _the_volume_follows_the_ear())
	results.append(await _measured_in_the_mix())
	results.append(await _the_falloff_follows_its_curve())
	results.append(await _disabled_it_stops())
	results.append(await _told_only_it_plays_and_sleeps_between())
	results.append(await _the_pause_holds_the_one_shots())
	results.append(_the_fire_sound_has_the_fire_files())
	results.append(await _every_prototype_fire_has_its_sound())
	results.append(await _walking_away_from_a_fire_makes_it_quieter())
	_camera.queue_free()
	await process_frame
	_finish(results)


func _heard_only_within_hearing_distance() -> bool:
	var emitter: SoundEmitter = _new_emitter(_tone(true), null)
	var centre: Vector2 = _camera.get_screen_center_position()
	var listens_at_centre: bool = emitter.get_ear_position().is_equal_approx(centre)
	emitter.global_position = centre + Vector2(HEARING + MARGIN + 200.0, 0.0)
	await _wait_frames(SETTLE_FRAMES)
	var silent_far: bool = not emitter.is_hearing() and not emitter.loop_player.playing
	emitter.global_position = centre + Vector2(0.0, HEARING - 50.0)
	await _wait_frames(SETTLE_FRAMES)
	var heard_near: bool = emitter.is_hearing() and emitter.loop_player.playing
	emitter.global_position = centre + Vector2(-(HEARING + MARGIN * 0.5), 0.0)
	await _wait_frames(SETTLE_FRAMES)
	var heard_in_margin: bool = emitter.is_hearing() and emitter.loop_player.playing
	emitter.global_position = centre + Vector2(-(HEARING + MARGIN + 50.0), 0.0)
	await _wait_frames(SETTLE_FRAMES)
	var stopped_past: bool = not emitter.is_hearing() and not emitter.loop_player.playing
	var players_set: bool = true
	for player: AudioStreamPlayer2D in [emitter.loop_player, emitter.one_shot_player]:
		players_set = (players_set and player.attenuation == SoundEmitter.GODOT_ATTENUATION
				and player.max_distance == SoundEmitter.GODOT_MAX_DISTANCE)
	emitter.queue_free()
	return _report(listens_at_centre and silent_far and heard_near and heard_in_margin
			and stopped_past and players_set,
			"outside a level it hears from the centre of the screen (%s), is silent far off (%s), "
			% [listens_at_centre, silent_far]
			+ "plays within Hearing Distance (%s), goes on within the margin (%s), stops past it "
			% [heard_near, heard_in_margin]
			+ "(%s), and Godot's own falloff is off in its players (%s)" % [stopped_past, players_set])


func _the_loop_loops_without_changing_its_file() -> bool:
	var file: AudioStreamOggVorbis = load(FIRE_LOOP_PATH) as AudioStreamOggVorbis
	var file_loops: bool = file != null and file.loop
	var first: SoundEmitter = _new_emitter(file, null, _camera.get_screen_center_position())
	var second: SoundEmitter = _new_emitter(file, null, _camera.get_screen_center_position())
	await _wait_frames(SETTLE_FRAMES)
	var ogg: AudioStreamOggVorbis = first.loop_player.stream as AudioStreamOggVorbis
	var loops: bool = ogg != null and ogg.loop and file.loop == file_loops
	var apart: float = absf(first.loop_player.get_playback_position()
			- second.loop_player.get_playback_position())
	var wav: AudioStreamWAV = _tone(false)
	var looped_wav: AudioStreamWAV = SoundEmitter._looping(wav) as AudioStreamWAV
	var wav_loops: bool = (looped_wav != wav and looped_wav.loop_mode == AudioStreamWAV.LOOP_FORWARD
			and looped_wav.loop_end == int(TONE_RATE * TONE_LENGTH)
			and wav.loop_mode == AudioStreamWAV.LOOP_DISABLED)
	first.queue_free()
	second.queue_free()
	return _report(loops and wav_loops and apart > 0.5,
			"the fire's loop plays looping (%s) and its file stays as imported (loop %s); a WAV "
			% [loops, file_loops]
			+ "loop loops too (%s); two emitters start %.2f s apart" % [wav_loops, apart])


## The fire's file ends in a reverb tail after its loop: started a little before Loop End, the loop
## goes on as loud through it and past it, measured in Godot's mix, instead of dying into the tail
## and going quiet until the file starts over; the tail plays out under the next pass.
func _the_fire_loop_goes_on_over_its_tail() -> bool:
	var fire: SoundEmitter = (load(FIRE_SOUND_PATH) as PackedScene).instantiate() as SoundEmitter
	var loop_start: float = float(fire.get(&"loop_start")) if fire.get(&"loop_start") != null else 0.0
	var loop_end: float = float(fire.get(&"loop_end")) if fire.get(&"loop_end") != null else 0.0
	fire.free()
	var capture: AudioEffectCapture = _capture_bus(&"TestLoop")
	var emitter: SoundEmitter = _emitter_scene.instantiate() as SoundEmitter
	emitter.loop = load(FIRE_LOOP_PATH) as AudioStream
	emitter.set(&"loop_start", loop_start)
	emitter.set(&"loop_end", loop_end)
	emitter.random_start = false
	emitter.position = _camera.get_screen_center_position()
	root.add_child(emitter)
	emitter.loop_player.bus = &"TestLoop"
	await _wait_frames(SETTLE_FRAMES)
	emitter.loop_player.stop()
	emitter.loop_player.play(FIRE_TEST_FROM)
	await _wait_real(SETTLE_TIME)
	capture.clear_buffer()
	var windows: Array[float] = []
	for _k: int in FIRE_WINDOWS:
		await _wait_real(FIRE_WINDOW)
		var level: Vector2 = _rms(capture)
		capture.clear_buffer()
		windows.append(linear_to_db(maxf(level.x + level.y, 0.000001)))
	emitter.queue_free()
	await process_frame
	_remove_bus(&"TestLoop")
	var fall: float = windows.max() - windows.min()
	var shown: Array[String] = []
	for level_db: float in windows:
		shown.append("%.0f" % level_db)
	return _report(absf(loop_end - FIRE_DRY_END) <= FIRE_END_TOLERANCE and fall <= FIRE_STEADY_DB,
			"the fire's Loop End is where its dry sound ends (%.3f s of %.3f), and from %.1f s " % [
			loop_end, FIRE_DRY_END, FIRE_TEST_FROM]
			+ "its loop goes on through it, the quietest window %.1f dB below the loudest " % fall
			+ "(dB per %.2f s: %s)" % [FIRE_WINDOW, ", ".join(shown)])


func _one_shots_come_about_every_interval() -> bool:
	var emitter: SoundEmitter = _new_emitter(_tone(true), _tone(false),
			_camera.get_screen_center_position())
	emitter.interval = TEST_INTERVAL
	emitter.deviation = TEST_DEVIATION
	await _listen(emitter, FRAMES_FOR_ALL, ONE_SHOTS_TO_HEAR)
	emitter.queue_free()
	if _heard_frames.size() < ONE_SHOTS_TO_HEAR:
		return _report(false, "only %d of %d one-shots played in %d frames"
				% [_heard_frames.size(), ONE_SHOTS_TO_HEAR, FRAMES_FOR_ALL])
	var waits: Array[float] = []
	for k: int in range(1, _heard_frames.size()):
		waits.append((_heard_frames[k] - _heard_frames[k - 1]) * FRAME_TIME)
	var outside: Array[String] = []
	var total: float = 0.0
	for wait: float in waits:
		total += wait
		if (wait < TEST_INTERVAL - TEST_DEVIATION - LIMIT_TOLERANCE
				or wait > TEST_INTERVAL + TEST_DEVIATION + FRAME_TIME + LIMIT_TOLERANCE):
			outside.append("%.3f s" % wait)
	var mean: float = total / waits.size()
	var spread: float = waits.max() - waits.min()
	var both_sides: bool = _heard_sides.min() < -0.5 and _heard_sides.max() > 0.5
	return _report(outside.is_empty() and absf(mean - TEST_INTERVAL) <= MEAN_TOLERANCE
			and spread >= MIN_WAIT_SPREAD and both_sides,
			"each wait is within Deviation of Interval (outside: %s), %.3f s on average, they vary "
			% [", ".join(outside), mean]
			+ "(%.2f s apart), and they come from both sides (%s)" % [spread, both_sides])


## For each place and each side: Godot's own sums (AudioStreamPlayer2D::_update_panning) give the
## one-shot the thing's pan moved by side times Pan Spread, and the thing's loudness.
func _one_shots_move_the_stereo_by_pan_spread_as_loud() -> bool:
	var centre: Vector2 = _camera.get_screen_center_position()
	var emitter: SoundEmitter = _new_emitter(_tone(true), _tone(false), centre)
	await _wait_frames(SETTLE_FRAMES)
	var problems: Array[String] = []
	for place: Vector2 in PLACES:
		emitter.global_position = centre + place
		for side: float in SIDES:
			var told: Array[float] = []
			emitter.one_shot_played.connect(func(_at: Vector2, heard: float) -> void:
				told.append(heard), CONNECT_ONE_SHOT)
			emitter.play_one_shot(side)
			var player: AudioStreamPlayer2D = emitter.one_shot_player
			var moved: float = _pan(player.global_position, player) - _pan(emitter.global_position, player)
			var loud: float = _loudness(player.global_position, player, player.volume_db)
			var asked: float = _from_the_thing(emitter)
			if (told.size() != 1 or absf(told[0] - side) > 0.0001
					or absf(moved - side * emitter.pan_spread) > PAN_TOLERANCE
					or absf(loud / asked - 1.0) > LOUDNESS_TOLERANCE):
				problems.append("at %s side %.1f: moved %.4f, loudness %.4f of the thing's"
						% [place, side, moved, loud / asked])
	emitter.queue_free()
	return _report(problems.is_empty(),
			"at zoom %.1f, from anywhere on the screen, each one-shot keeps its side, moves the " % ZOOM
			+ "stereo by that side of Pan Spread and is as loud as from the thing (problems: %s)"
			% "; ".join(problems))


## A one-shot from the right while the ear (outside a level, the centre of the screen) moves towards
## the thing: the thing gets louder, and the one-shot follows, as loud as from the thing.
func _the_volume_follows_the_ear() -> bool:
	var centre: Vector2 = _camera.get_screen_center_position()
	var emitter: SoundEmitter = _new_emitter(_tone(true), _tone(false), centre + FOLLOWED_AT)
	await _wait_frames(SETTLE_FRAMES)
	# No one-shot of its own while it is watched.
	emitter._time_left = INF
	emitter.play_one_shot(1.0)
	var player: AudioStreamPlayer2D = emitter.one_shot_player
	var gain_before: float = _from_the_thing(emitter)
	var before: float = _loudness(player.global_position, player, player.volume_db) / gain_before
	_camera.position += CAMERA_MOVE
	await _wait_frames(SETTLE_FRAMES)
	var gain_after: float = _from_the_thing(emitter)
	var after: float = _loudness(player.global_position, player, player.volume_db) / gain_after
	var playing: bool = player.playing
	_camera.position -= CAMERA_MOVE
	emitter.queue_free()
	await _wait_frames(SETTLE_FRAMES)
	return _report(playing and gain_after > gain_before and absf(before - 1.0) <= LOUDNESS_TOLERANCE
			and absf(after - 1.0) <= LOUDNESS_TOLERANCE,
			"as the ear nears the thing, it gets louder (%.3f, then %.3f of its volume), " % [
			gain_before, gain_after] + "and a one-shot playing stays as loud as from the thing "
			+ "(%.4f, then %.4f)" % [before, after])


## The same in Godot's mix: the loop, from the thing, and a one-shot from its right on buses of
## their own, each captured; the share of right in left and right moves by Pan Spread, and the two
## are as loud.
func _measured_in_the_mix() -> bool:
	var loop_capture: AudioEffectCapture = _capture_bus(&"TestLoop")
	var shot_capture: AudioEffectCapture = _capture_bus(&"TestShot")
	var centre: Vector2 = _camera.get_screen_center_position()
	var emitter: SoundEmitter = _new_emitter(_tone(true), _tone(false), centre + MEASURED_AT)
	emitter.loop_player.bus = &"TestLoop"
	emitter.one_shot_player.bus = &"TestShot"
	emitter.interval = 60.0
	emitter.deviation = 0.0
	await _wait_frames(SETTLE_FRAMES)
	# The frames run unthrottled while the mix runs in real time: no one-shot of its own in between.
	emitter._time_left = INF
	emitter.play_one_shot(1.0)
	var rights: Array[float] = []
	var loudness: Array[float] = []
	await _wait_real(SETTLE_TIME)
	loop_capture.clear_buffer()
	shot_capture.clear_buffer()
	await _wait_real(MEASURE_TIME)
	for capture: AudioEffectCapture in [loop_capture, shot_capture]:
		var level: Vector2 = _rms(capture)
		rights.append(level.y / maxf(level.x + level.y, 0.000001))
		loudness.append(level.x + level.y)
	var spread: float = emitter.pan_spread
	emitter.queue_free()
	await process_frame
	_remove_bus(&"TestLoop")
	_remove_bus(&"TestShot")
	var moved: float = rights[1] - rights[0]
	var as_loud: float = loudness[1] / maxf(loudness[0], 0.000001)
	return _report(loudness[0] > 0.0 and absf(moved - spread) <= MEASURED_PAN_TOLERANCE
			and absf(as_loud - 1.0) <= MEASURED_LOUDNESS_TOLERANCE,
			"in Godot's mix, a one-shot from the right moves the stereo by %.3f (from %.3f right) "
			% [moved, rights[0]] + "and is %.3f as loud as the loop" % as_loud)


## With an ear of its own, far from the centre of the screen: as loud as at the thing within Near
## Distance, at each point of Default Falloff as loud as it says, and as a Falloff of its own says
## when it has one; near the edge of hearing, a one-shot on its far side keeps that side and is as
## loud as from the thing.
func _the_falloff_follows_its_curve() -> bool:
	var ear := Node2D.new()
	ear.position = _camera.get_screen_center_position() + EAR_AWAY
	root.add_child(ear)
	var emitter: SoundEmitter = _new_emitter(_tone(true), _tone(false), ear.position)
	emitter.ear = ear
	emitter._time_left = INF
	var span: float = HEARING - emitter.near_distance
	var problems: Array[String] = []
	var spots: Array[Vector2] = [Vector2(emitter.near_distance * 0.5, 1.0)]
	for point: Vector2 in SoundEmitter.DEFAULT_FALLOFF:
		if point.y > 0.0:
			spots.append(Vector2(emitter.near_distance + point.x * span, point.y))
	for spot: Vector2 in spots:
		emitter.position = ear.position + Vector2(0.0, -spot.x)
		await _wait_frames(SETTLE_FRAMES)
		var gain: float = (_loudness(emitter.global_position, emitter.loop_player,
				emitter.loop_player.volume_db) / db_to_linear(emitter.loop_volume_db))
		if absf(gain - spot.y) > LOUDNESS_TOLERANCE:
			problems.append("%.0f px: %.3f for %.3f" % [spot.x, gain, spot.y])
	var own := Curve.new()
	own.add_point(Vector2(0.0, OWN_FALLOFF), 0.0, 0.0, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
	own.add_point(Vector2(1.0, OWN_FALLOFF), 0.0, 0.0, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
	emitter.falloff = own
	emitter.position = ear.position + Vector2(0.0, -(emitter.near_distance + span * 0.5))
	await _wait_frames(SETTLE_FRAMES)
	var own_gain: float = db_to_linear(emitter.loop_player.volume_db - emitter.loop_volume_db)
	if absf(own_gain - OWN_FALLOFF) > LOUDNESS_TOLERANCE:
		problems.append("its own falloff: %.3f for %.3f" % [own_gain, OWN_FALLOFF])
	emitter.falloff = null
	emitter.position = ear.position + NEAR_THE_EDGE
	await _wait_frames(SETTLE_FRAMES)
	var told: Array[float] = []
	emitter.one_shot_played.connect(func(_at: Vector2, heard: float) -> void: told.append(heard))
	emitter.play_one_shot(1.0)
	var player: AudioStreamPlayer2D = emitter.one_shot_player
	var edge: float = _loudness(player.global_position, player, player.volume_db) / _from_the_thing(emitter)
	if told.size() != 1 or told[0] != 1.0 or absf(edge - 1.0) > LOUDNESS_TOLERANCE:
		problems.append("near the edge, a one-shot to the right: side %s, %.4f as loud" % [told, edge])
	emitter.queue_free()
	ear.queue_free()
	return _report(problems.is_empty(),
			"with an ear of its own, it is as loud as at the thing within Near Distance, as Default "
			+ "Falloff says at each of its points, as its own Falloff says, and a one-shot near the "
			+ "edge of hearing keeps its side, as loud (problems: %s)" % "; ".join(problems))


func _disabled_it_stops() -> bool:
	var emitter: SoundEmitter = _new_emitter(_tone(true), _tone(false),
			_camera.get_screen_center_position())
	emitter.interval = TEST_INTERVAL
	emitter.deviation = TEST_DEVIATION
	await _wait_frames(SETTLE_FRAMES)
	var heard_on: bool = emitter.is_hearing()
	emitter.enabled = false
	await _listen(emitter, PAUSED_FRAMES)
	var silent: bool = (not emitter.is_hearing() and not emitter.loop_player.playing
			and _heard_frames.is_empty())
	emitter.enabled = true
	await _wait_frames(SETTLE_FRAMES)
	var back: bool = emitter.is_hearing()
	emitter.queue_free()
	return _report(heard_on and silent and back,
			"disabled, it stops and plays no one-shots (%s); enabled again, it plays (%s)"
			% [silent, back])


## With Plays On Its Own off, as for a dog's voice, a heard emitter with a loop plays the loop and
## no one-shot by itself. With no loop either, it sleeps, its physics frame off; told to play a
## one-shot, it wakes, keeps the one-shot's volume to the ear as the thing moves away, and sleeps
## again once the one-shot is over. Disabled, it plays none when told.
func _told_only_it_plays_and_sleeps_between() -> bool:
	var centre: Vector2 = _camera.get_screen_center_position()
	var looping: SoundEmitter = _new_emitter(_tone(true), _tone(false), centre)
	looping.plays_on_its_own = false
	looping.interval = TEST_INTERVAL
	looping.deviation = TEST_DEVIATION
	await _listen(looping, PAUSED_FRAMES)
	var loop_only: bool = looping.is_hearing() and looping.loop_player.playing \
			and _heard_frames.is_empty()
	looping.queue_free()
	var told: SoundEmitter = _emitter_scene.instantiate() as SoundEmitter
	told.one_shots = _tone(false)
	told.plays_on_its_own = false
	told.hearing_distance = HEARING
	told.position = centre
	root.add_child(told)
	await _wait_frames(SETTLE_FRAMES)
	var asleep: bool = not told.is_physics_processing() and not told.one_shot_player.playing
	told.play_one_shot(0.0)
	var woke: bool = told.is_physics_processing() and told.one_shot_player.playing
	var near_db: float = told.one_shot_player.volume_db
	told.position = centre + Vector2(HEARING * 0.75, 0.0)
	await _wait_frames(SETTLE_FRAMES)
	var far_db: float = told.one_shot_player.volume_db
	var follows: bool = far_db < near_db - 10.0
	told.one_shot_player.stop()
	await _wait_frames(SETTLE_FRAMES)
	var asleep_again: bool = not told.is_physics_processing()
	told.enabled = false
	told.play_one_shot(0.0)
	var none_disabled: bool = not told.one_shot_player.playing and not told.is_physics_processing()
	told.queue_free()
	return _report(loop_only and asleep and woke and follows and asleep_again and none_disabled,
			"told only: with a loop, it loops and plays no one-shot by itself (%s); with none, it "
			% loop_only + "sleeps (%s), wakes to play one (%s), follows the ear (%.1f, then %.1f dB), "
			% [asleep, woke, near_db, far_db] + "sleeps once it is over (%s), and disabled plays none (%s)"
			% [asleep_again, none_disabled])


func _the_pause_holds_the_one_shots() -> bool:
	var emitter: SoundEmitter = _new_emitter(_tone(true), _tone(false),
			_camera.get_screen_center_position())
	emitter.interval = TEST_INTERVAL
	emitter.deviation = TEST_DEVIATION
	await _wait_frames(SETTLE_FRAMES)
	paused = true
	await _listen(emitter, PAUSED_FRAMES)
	var held: bool = _heard_frames.is_empty()
	paused = false
	await _listen(emitter, PAUSED_FRAMES, 1)
	var after: bool = _heard_frames.size() == 1
	emitter.queue_free()
	return _report(held and after,
			"the pause holds the one-shots (%s), and they come again after it (%s)" % [held, after])


func _the_fire_sound_has_the_fire_files() -> bool:
	var scene: PackedScene = load(FIRE_SOUND_PATH) as PackedScene
	var sound: SoundEmitter = scene.instantiate() as SoundEmitter if scene != null else null
	if sound == null:
		return _report(false, "%s is a SoundEmitter" % FIRE_SOUND_PATH)
	var crackles: AudioStreamRandomizer = sound.one_shots as AudioStreamRandomizer
	var files: Array[String] = []
	if crackles != null:
		for k: int in crackles.streams_count:
			files.append(crackles.get_stream(k).resource_path.get_file())
	files.sort()
	var embers: RisingEmbers = sound.get_node_or_null(^"%RisingEmbers") as RisingEmbers
	var passed: bool = (sound.loop != null and sound.loop.resource_path == FIRE_LOOP_PATH
			and crackles != null and files == CRACKLE_FILES
			and crackles.playback_mode == AudioStreamRandomizer.PLAYBACK_RANDOM_NO_REPEATS
			and crackles.random_pitch > 1.0 and crackles.random_pitch <= FIRE_MAX_PITCH
			and sound.interval == FIRE_INTERVAL
			and sound.deviation >= FIRE_DEVIATION.x and sound.deviation <= FIRE_DEVIATION.y
			and sound.pan_spread == FIRE_PAN_SPREAD
			and sound.loop_player.bus == AMBIENCE_BUS and sound.one_shot_player.bus == AMBIENCE_BUS
			and embers != null and embers.emitter == sound)
	sound.free()
	return _report(passed, "the fire's sound loops the base layer and plays the four crackles "
			+ "(%s), without repeats, a little varied in pitch, about every 4 s, up to 10%% to " % [files]
			+ "either side, on the Ambience bus, and its embers listen to it")


func _every_prototype_fire_has_its_sound() -> bool:
	var scene: PackedScene = load(LIGHTING_LEVEL_PATH) as PackedScene
	if scene == null:
		return _report(false, "%s loads as a scene" % LIGHTING_LEVEL_PATH)
	var level: Node = scene.instantiate()
	root.add_child(level)
	await _wait_frames(LEVEL_FRAMES)
	var holder: Node = level.find_child("ProtoFires", true, false)
	var fires: int = 0
	var problems: Array[String] = []
	if holder != null:
		for fire: Node in holder.get_children():
			fires += 1
			var sound: SoundEmitter = null
			for child: Node in fire.get_children():
				if child is SoundEmitter:
					sound = child as SoundEmitter
			var embers: RisingEmbers = (sound.get_node_or_null(^"%RisingEmbers") as RisingEmbers
					if sound != null else null)
			if sound == null or embers == null or embers.fade_with != fire:
				problems.append(fire.name)
				continue
			var flame: Rect2 = fire.call("get_flame_rect")
			var area := Rect2(embers.emit_area.position + sound.global_position, embers.emit_area.size)
			if not flame.encloses(area):
				problems.append("%s's embers leave from outside its flame" % fire.name)
	level.queue_free()
	await process_frame
	return _report(fires > 0 and problems.is_empty(),
			"each of the prototype's %d fires has its sound, whose embers leave from its flame and " % fires
			+ "hide with it (problems: %s)" % ", ".join(problems))


## In the lighting prototype, with the camera held still: the man beside a fire, then halfway to the
## next one on the same floor. What Godot plays of all the fires' loops together, by its own sums,
## is Walking Away dB quieter halfway than beside the fire.
func _walking_away_from_a_fire_makes_it_quieter() -> bool:
	var scene: PackedScene = load(LIGHTING_LEVEL_PATH) as PackedScene
	var holder: Node2D = scene.instantiate() as Node2D
	# Its own camera follows the man: the test's steps aside for it.
	_camera.enabled = false
	root.add_child(holder)
	await _wait_frames(LEVEL_FRAMES)
	var level: Level = holder.find_child("Level1", true, false) as Level
	var man: Player = level.player if level != null else null
	var emitters: Array[SoundEmitter] = []
	for node: Node in holder.find_children("*", "", true, false):
		if node is SoundEmitter:
			emitters.append(node as SoundEmitter)
	var pair: Array[SoundEmitter] = _fire_pair(emitters, man)
	var level_camera: Camera2D = root.get_viewport().get_camera_2d()
	if man == null or pair.is_empty() or level_camera == null:
		holder.queue_free()
		_camera.enabled = true
		await process_frame
		return _report(false, "the lighting prototype has its man (%s), a camera (%s) and two fires " % [
				man != null, level_camera != null] + "side by side on one floor (%s)" % not pair.is_empty())
	level_camera.set_physics_process(false)
	level_camera.set_process(false)
	var beside: Vector2 = pair[0].global_position + BESIDE_FIRE
	var halfway: Vector2 = (pair[0].global_position + pair[1].global_position) * 0.5 + Vector2(0.0, BESIDE_FIRE.y)
	var hears_the_man: bool = pair[0].get_ear_position().is_equal_approx(man.global_position)
	var heard: Array[float] = []
	for spot: Vector2 in [beside, halfway]:
		man.global_position = spot
		man.velocity = Vector2.ZERO
		for _k: int in PLACE_FRAMES:
			await physics_frame
		heard.append(_fires_heard_db(emitters))
	var gap: float = pair[0].global_position.distance_to(pair[1].global_position)
	holder.queue_free()
	_camera.enabled = true
	_camera.make_current()
	await _wait_frames(SETTLE_FRAMES)
	var quieter: float = heard[0] - heard[1]
	return _report(hears_the_man and quieter >= WALKING_AWAY_DB,
			"the fires hear from the man (%s), and with the camera still they are together " % hears_the_man
			+ "%.1f dB quieter halfway between two (%.0f px apart) than beside one " % [quieter, gap]
			+ "(%.1f dB, then %.1f dB)" % [heard[0], heard[1]])


## Two fires on one floor, next to each other and Fire Pair Gap apart, the first nearest the man.
func _fire_pair(emitters: Array[SoundEmitter], man: Node2D) -> Array[SoundEmitter]:
	if man == null:
		return []
	var best: Array[SoundEmitter] = []
	var best_distance: float = INF
	for a: SoundEmitter in emitters:
		var next: SoundEmitter = null
		for b: SoundEmitter in emitters:
			if (b != a and is_equal_approx(b.global_position.y, a.global_position.y)
					and b.global_position.x > a.global_position.x
					and (next == null or b.global_position.x < next.global_position.x)):
				next = b
		if next == null:
			continue
		var gap: float = next.global_position.x - a.global_position.x
		var distance: float = a.global_position.distance_to(man.global_position)
		if gap >= FIRE_PAIR_GAP.x and gap <= FIRE_PAIR_GAP.y and distance < best_distance:
			best = [a, next]
			best_distance = distance
	return best


## What Godot plays of the emitters' loops together, in dB: each playing loop player's attenuation
## over its distance from the centre of the screen and its volume, summed as powers.
func _fires_heard_db(emitters: Array[SoundEmitter]) -> float:
	var power: float = 0.0
	var viewport: Viewport = root.get_viewport()
	var centre: Vector2 = ((viewport.get_global_canvas_transform() * viewport.get_canvas_transform())
			.affine_inverse() * (viewport.get_visible_rect().size * 0.5))
	for emitter: SoundEmitter in emitters:
		var player: AudioStreamPlayer2D = emitter.loop_player
		if not player.playing:
			continue
		var distance: float = player.global_position.distance_to(centre)
		var gain: float = (pow(maxf(1.0 - distance / player.max_distance, 0.0), player.attenuation)
				* db_to_linear(player.volume_db))
		power += gain * gain
	return linear_to_db(sqrt(power)) if power > 0.0 else -INF


func _new_emitter(loop: AudioStream, one_shots: AudioStream,
		position: Vector2 = Vector2.ZERO) -> SoundEmitter:
	var emitter: SoundEmitter = _emitter_scene.instantiate() as SoundEmitter
	emitter.loop = loop
	emitter.one_shots = one_shots
	emitter.hearing_distance = HEARING
	emitter.hearing_margin = MARGIN
	emitter.position = position
	root.add_child(emitter)
	return emitter


## Waits up to frames process frames, and keeps the frame and the side of each one-shot, until
## enough have played (0: all the frames).
func _listen(emitter: SoundEmitter, frames: int, enough: int = 0) -> void:
	_frame = 0
	_heard_frames.clear()
	_heard_sides.clear()
	var keep := func(_at: Vector2, side: float) -> void:
		_heard_frames.append(_frame)
		_heard_sides.append(side)
	emitter.one_shot_played.connect(keep)
	for _step: int in frames:
		await process_frame
		_frame += 1
		if enough > 0 and _heard_frames.size() >= enough:
			break
	emitter.one_shot_played.disconnect(keep)


## How loud a one-shot of emitter should be, by its own sums: its volume, lowered by the falloff
## over the thing's distance from the ear.
func _from_the_thing(emitter: SoundEmitter) -> float:
	return (emitter.get_gain(emitter.global_position.distance_to(emitter.get_ear_position()))
			* db_to_linear(emitter.one_shot_volume_db))


## Godot's pan for a 2D player at a point of the world: the share of the right speaker, 0.5 at the
## centre of the screen.
func _pan(at: Vector2, player: AudioStreamPlayer2D) -> float:
	var canvas: Transform2D = root.get_global_canvas_transform() * root.get_canvas_transform()
	var screen: Vector2 = root.get_visible_rect().size
	var relative: float = (canvas * at).x - screen.x * 0.5
	var strength: float = (player.panning_strength
			* float(ProjectSettings.get_setting("audio/general/2d_panning_strength", 0.5)) * 0.5)
	return clampf(0.5 + clampf(relative / screen.x, -1.0, 1.0) * strength, 0.0, 1.0)


## Godot's loudness for a 2D player at a point of the world, at volume_db: its attenuation over
## the distance from the centre of the screen.
func _loudness(at: Vector2, player: AudioStreamPlayer2D, volume_db: float) -> float:
	var distance: float = at.distance_to(_camera.get_screen_center_position())
	return pow(maxf(1.0 - distance / player.max_distance, 0.0), player.attenuation) * db_to_linear(volume_db)


## A bus of its own, sending to Master, with a capture of what plays on it.
func _capture_bus(bus_name: StringName) -> AudioEffectCapture:
	var index: int = AudioServer.bus_count
	AudioServer.add_bus(index)
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, &"Master")
	var capture := AudioEffectCapture.new()
	capture.buffer_length = CAPTURE_LENGTH
	AudioServer.add_bus_effect(index, capture)
	return capture


func _remove_bus(bus_name: StringName) -> void:
	var index: int = AudioServer.get_bus_index(bus_name)
	if index != -1:
		AudioServer.remove_bus(index)


## The root mean square of what a capture holds, left (x) and right (y).
func _rms(capture: AudioEffectCapture) -> Vector2:
	var frames: int = capture.get_frames_available()
	var data: PackedVector2Array = capture.get_buffer(frames)
	var sum := Vector2.ZERO
	for frame: Vector2 in data:
		sum += frame * frame
	return Vector2(sqrt(sum.x / maxf(frames, 1.0)), sqrt(sum.y / maxf(frames, 1.0)))


## A steady tone, made in memory, mono: looping, for a loop, or not, for a one-shot.
func _tone(loops: bool) -> AudioStreamWAV:
	var tone := AudioStreamWAV.new()
	tone.format = AudioStreamWAV.FORMAT_16_BITS
	tone.mix_rate = TONE_RATE
	var frames: int = int(TONE_RATE * TONE_LENGTH)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	for k: int in frames:
		bytes.encode_s16(k * 2, int(sin(TAU * TONE_HZ * k / TONE_RATE) * TONE_AMPLITUDE * 32767.0))
	tone.data = bytes
	if loops:
		tone.loop_mode = AudioStreamWAV.LOOP_FORWARD
		tone.loop_end = frames
	return tone


func _wait_frames(frames: int) -> void:
	for _step: int in frames:
		await process_frame


## Waits real seconds: the frames run unthrottled, the mix in real time.
func _wait_real(seconds: float) -> void:
	var until: int = Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < until:
		await process_frame


func _report(passed: bool, what: String) -> bool:
	print("%s: %s" % ["PASS" if passed else "FAIL", what])
	return passed


## Quits with exit code 0 if every case passed, and 1 otherwise.
func _finish(results: Array[bool]) -> void:
	quit(1 if results.has(false) else 0)
