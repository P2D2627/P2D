# Checks the ambience layers. A layer plays its sounds one at a time, and each wait, from start()
# to the first sound and from one sound to the next, is between Min Gap and Max Gap and not always
# the same. Each sound comes from inside the spread around the centre of the screen, from both
# sides of it, or around the layer itself when there is no camera. The sounds play on the Ambience
# bus, so the Ambience volume option applies to them. Without Autostart a layer waits for start(),
# stop() holds it, and so does the pause. A layer without sounds plays nothing.
# Unpanned sounds, which keep their own stereo, play from the centre of the screen on a player
# that is not 2D, never two in a row, about Unpanned Share of the time, and travel as Unpanned
# Travel says; a placed sound travels from its side of the screen towards the other. A layer with
# only unpanned sounds plays all of them unpanned. A placed sound keeps its place on the screen
# while it plays, as the camera moves on. In level 1, the passing gusts and the low rumbles are two
# layers, with their gaps, their sounds and their buses, and a gust turns the beds down: the beds
# play on Beds, the gusts on Gusts, both into Ambience, and a compressor on Beds listens to Gusts.
# The sounds the player needs to hear to stay alive, the demon's and the crucifix's, play on the
# Alerts bus, which sends to SFX, and a compressor on the Ambience bus listens to Alerts, so they
# turn the ambience down while they play. The player's own sounds, steps among them, stay on SFX,
# so that compressor ignores them and the ambience does not dip on every step; how far each sound
# turns it down is test_ambience_ducking.gd's.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_ambience_layer.gd
extends "res://tests/support/base_test.gd"

const LAYER_PATH: String = "res://scenes/others/ambience/ambience_layer.tscn"
const AMBIENCE_BUS: StringName = &"Ambience"
const ALERTS_BUS: StringName = &"Alerts"
const SFX_BUS: StringName = &"SFX"
## The scenes whose every sound player is on Alerts: what the player must hear to stay alive.
const ALERT_SCENES: Array[String] = [
	"res://scenes/characters/demon/demon.tscn",
	"res://scenes/characters/crucifix/crucifix.tscn",
]
## The player's own sounds, under PlayerSounds, stay on SFX: they play all the time. The player
## scene also holds the crucifix, whose sounds are on Alerts.
const PLAYER_SCENE_PATH: String = "res://scenes/characters/player/player.tscn"
const PLAYER_SOUNDS: NodePath = ^"PlayerSounds"
## Short gaps, so a test hears many sounds in little time.
const MIN_GAP: float = 1.0
const MAX_GAP: float = 2.0
## The length of a frame with --fixed-fps 60, as in the command above. A sound plays on the frame
## its wait runs out, so a wait can be up to a frame longer than the one picked.
const FRAME_TIME: float = 1.0 / 60.0
## Sounds to hear in a row, to see the waits and the places vary.
const SOUNDS_TO_HEAR: int = 20
## Frames to wait for SOUNDS_TO_HEAR sounds at Max Gap each, plus a second.
const FRAMES_FOR_ALL: int = int(SOUNDS_TO_HEAR * MAX_GAP / FRAME_TIME) + 60
## Frames in which a running layer plays at least two sounds: what a held layer must stay silent
## for.
const QUIET_FRAMES: int = int(3.0 * MAX_GAP / FRAME_TIME)
## Frames in which a running layer plays its next sound.
const NEXT_SOUND_FRAMES: int = int(MAX_GAP / FRAME_TIME) + 2
## The smallest spread of the waits over SOUNDS_TO_HEAR sounds: picked at random between 1 s and
## 2 s, they cover much more of it.
const MIN_GAP_SPREAD: float = 0.25
const HORIZONTAL_SPREAD: float = 500.0
const VERTICAL_SPREAD: float = 200.0
## Where the layer is, and the camera, far from the world origin and from each other.
const LAYER_AT: Vector2 = Vector2(-700.0, 400.0)
const CAMERA_AT: Vector2 = Vector2(5000.0, -3000.0)
## Frames for a new camera to become the current one and settle.
const CAMERA_FRAMES: int = 2
## The seed makes the random waits and places repeatable.
const RANDOM_SEED: int = 2026
## The silent sound the layers play: its sample rate, in Hz, and its length, in seconds.
const SHORT_SOUND_RATE: int = 22050
const SHORT_SOUND_LENGTH: float = 0.1
## Rounding room for the time and place limits.
const LIMIT_TOLERANCE: float = 0.001
## Sounds to hear in a row with unpanned ones among them, to count their share.
const MIXED_SOUNDS_TO_HEAR: int = 60
const MIXED_FRAMES: int = int(MIXED_SOUNDS_TO_HEAR * MAX_GAP / FRAME_TIME) + 60
## The share of unpanned sounds asked for, and how far the count over MIXED_SOUNDS_TO_HEAR may
## stray from it: about two standard deviations of a run of 60.
const UNPANNED_SHARE: float = 0.33
const UNPANNED_SHARE_TOLERANCE: float = 0.13
## Level 1's ambience and what its wind layers must be: the gaps, in s, and the sound files, by
## name.
const LEVEL1_AMBIENCE_PATH: String = "res://scenes/levels/lust/lust_ambience.tscn"
const PASSING_GAPS: Vector2 = Vector2(21.0, 33.0)
const RUMBLE_GAPS: Vector2 = Vector2(11.0, 19.0)
const PASSING_FILES: Array[String] = ["one_shot_wind_2.wav", "one_shot_wind_5.wav"]
const BAKED_PAN_FILES: Array[String] = ["one_shot_wind_1_bakedpan.wav"]
const RUMBLE_FILES: Array[String] = ["one_shot_wind_3_low.wav", "one_shot_wind_4_low.wav"]
## The beds' bus and the passing gusts': both send to Ambience, and a compressor on Beds listens to
## Gusts, so a gust turns the beds down while it blows.
const BEDS_BUS: StringName = &"Beds"
const GUSTS_BUS: StringName = &"Gusts"
const LEVEL1_BEDS: Array[NodePath] = [^"Bed1", ^"Bed2"]
## A sound long enough to play on while the camera moves, in s; how far the camera moves, in px,
## and how near its place on the screen the sound must stay, in px.
const FOLLOWED_SOUND_LENGTH: float = 3.0
const CAMERA_MOVE: Vector2 = Vector2(800.0, -300.0)
const PLACE_TOLERANCE: float = 0.5

var _layer_scene: PackedScene
## Process frames since the last _listen() began, when each sound played, from where, which way it
## travels, and where the layer's 2D player was then.
var _frame: int = 0
var _heard_frames: Array[int] = []
var _heard_positions: Array[Vector2] = []
var _heard_travels: Array[int] = []
var _heard_player_at: Array[Vector2] = []


func _initialize() -> void:
	_layer_scene = load(LAYER_PATH) as PackedScene
	if _layer_scene == null:
		_report(false, "%s loads as a scene" % LAYER_PATH)
		_finish([false])
		return
	# A node added before the root is ready only gets _ready() with the root, on the first frame.
	await process_frame
	seed(RANDOM_SEED)
	var results: Array[bool] = []
	results.append(_plays_on_the_ambience_bus())
	results.append(await _waits_stay_between_min_and_max_gap())
	results.append(await _without_a_camera_sounds_come_from_around_the_layer())
	results.append(await _sounds_come_from_around_the_screen_centre())
	results.append(await _a_placed_sound_keeps_its_place_on_the_screen())
	results.append(await _without_autostart_waits_for_start())
	results.append(await _stop_holds_the_sounds())
	results.append(await _pause_holds_the_sounds())
	results.append(await _without_sounds_plays_nothing())
	results.append(await _unpanned_sounds_play_as_they_are())
	results.append(await _with_only_unpanned_sounds_every_sound_is_unpanned())
	results.append(_level1_has_the_wind_layers())
	results.append(_gusts_turn_the_beds_down())
	results.append(_alerts_turn_the_ambience_down_and_the_players_sounds_do_not())
	# Lets the last layer's queue_free() happen before quitting.
	await process_frame
	_finish(results)


func _plays_on_the_ambience_bus() -> bool:
	var sounds := _short_sound()
	var layer: AmbienceLayer = _new_layer(sounds)
	var player: AudioStreamPlayer2D = layer.player
	var unpanned: AudioStreamPlayer = layer.unpanned_player
	var passed: bool = (player != null and player.bus == AMBIENCE_BUS and player.stream == sounds
			and unpanned != null and unpanned.bus == AMBIENCE_BUS
			and AudioServer.get_bus_index(AMBIENCE_BUS) != -1)
	layer.queue_free()
	return _report(passed, "the sounds and the unpanned sounds play on the Ambience bus, with the "
			+ "layer's Sounds")


func _waits_stay_between_min_and_max_gap() -> bool:
	var layer: AmbienceLayer = _new_layer(_short_sound())
	await _listen(layer, FRAMES_FOR_ALL, SOUNDS_TO_HEAR)
	layer.queue_free()
	if _heard_frames.size() < SOUNDS_TO_HEAR:
		return _report(false, "only %d of %d sounds played in %d frames"
				% [_heard_frames.size(), SOUNDS_TO_HEAR, FRAMES_FOR_ALL])
	var waits: Array[float] = []
	var previous: int = 0
	for frame: int in _heard_frames:
		waits.append((frame - previous) * FRAME_TIME)
		previous = frame
	var outside: Array[String] = []
	for wait: float in waits:
		if wait < MIN_GAP - LIMIT_TOLERANCE or wait > MAX_GAP + FRAME_TIME + LIMIT_TOLERANCE:
			outside.append("%.3f s" % wait)
	var spread: float = waits.max() - waits.min()
	return _report(outside.is_empty() and spread >= MIN_GAP_SPREAD,
			"each wait is between Min Gap and Max Gap (outside: %s) and they vary (%.2f s apart)"
			% [", ".join(outside), spread])


func _without_a_camera_sounds_come_from_around_the_layer() -> bool:
	var layer: AmbienceLayer = _new_layer(_short_sound(), true, LAYER_AT)
	await _listen(layer, FRAMES_FOR_ALL, SOUNDS_TO_HEAR)
	layer.queue_free()
	return _report(_inside_the_spread_on_both_sides(LAYER_AT),
			"without a camera, the sounds come from around the layer, on both sides of it")


func _sounds_come_from_around_the_screen_centre() -> bool:
	var camera := Camera2D.new()
	# The project interpolates physics, which moves every Camera2D to the physics frame anyway.
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	camera.position = CAMERA_AT
	root.add_child(camera)
	camera.make_current()
	await _wait_frames(CAMERA_FRAMES)
	var centre: Vector2 = camera.get_screen_center_position()
	var layer: AmbienceLayer = _new_layer(_short_sound(), true, LAYER_AT)
	await _listen(layer, FRAMES_FOR_ALL, SOUNDS_TO_HEAR)
	var player_at_last: bool = (not _heard_positions.is_empty()
			and layer.player.global_position.is_equal_approx(_heard_positions.back()))
	layer.queue_free()
	camera.queue_free()
	await process_frame
	return _report(_inside_the_spread_on_both_sides(centre) and player_at_last,
			"the sounds come from around the centre of the screen, on both sides of it, and the "
			+ "player is where the last one came from")


## A placed sound keeps its place on the screen while it plays, as the camera moves on: it neither
## falls behind nor pans away as the man runs on.
func _a_placed_sound_keeps_its_place_on_the_screen() -> bool:
	var camera: Camera2D = await _new_camera()
	var layer: AmbienceLayer = _new_layer(_short_sound(FOLLOWED_SOUND_LENGTH), true, LAYER_AT)
	await _listen(layer, NEXT_SOUND_FRAMES, 1)
	var played: bool = _heard_frames.size() == 1
	var offset: Vector2 = layer.player.global_position - camera.get_screen_center_position()
	camera.position += CAMERA_MOVE
	# The layer follows a frame behind the camera, which takes its new place after the layer's frame.
	await _wait_frames(CAMERA_FRAMES + 1)
	var kept: Vector2 = layer.player.global_position - camera.get_screen_center_position()
	var playing: bool = layer.player.playing
	layer.queue_free()
	camera.queue_free()
	await process_frame
	return _report(played and playing and kept.distance_to(offset) <= PLACE_TOLERANCE,
			"a placed sound playing keeps its place on the screen as the camera moves on "
			+ "(%s from the centre, then %s)" % [offset.round(), kept.round()])


func _without_autostart_waits_for_start() -> bool:
	var layer: AmbienceLayer = _new_layer(_short_sound(), false)
	await _listen(layer, QUIET_FRAMES)
	var silent_before: bool = _heard_frames.is_empty() and not layer.is_running()
	layer.start()
	await _listen(layer, NEXT_SOUND_FRAMES, 1)
	var played_after: bool = _heard_frames.size() == 1 and layer.is_running()
	layer.queue_free()
	return _report(silent_before and played_after,
			"without Autostart, a layer is silent until start() and then plays within Max Gap")


func _stop_holds_the_sounds() -> bool:
	var layer: AmbienceLayer = _new_layer(_short_sound())
	layer.stop()
	await _listen(layer, QUIET_FRAMES)
	var held: bool = _heard_frames.is_empty() and not layer.is_running()
	layer.queue_free()
	return _report(held, "stop() holds the sounds")


func _pause_holds_the_sounds() -> bool:
	var layer: AmbienceLayer = _new_layer(_short_sound())
	paused = true
	await _listen(layer, QUIET_FRAMES)
	var held: bool = _heard_frames.is_empty()
	paused = false
	await _listen(layer, NEXT_SOUND_FRAMES, 1)
	var resumed: bool = _heard_frames.size() == 1
	layer.queue_free()
	return _report(held and resumed, "the pause holds the sounds, and they come back after it")


func _without_sounds_plays_nothing() -> bool:
	var layer: AmbienceLayer = _new_layer(null)
	await _listen(layer, QUIET_FRAMES)
	var silent: bool = (_heard_frames.is_empty() and not layer.player.playing
			and not layer.unpanned_player.playing)
	layer.queue_free()
	return _report(silent, "a layer without Sounds plays nothing")


## Sounds and unpanned sounds together, with a camera: the unpanned ones come from the centre of
## the screen, travelling left to right, without moving the 2D player, never two in a row and
## about Unpanned Share of the time; the placed ones travel away from their side.
func _unpanned_sounds_play_as_they_are() -> bool:
	var camera: Camera2D = await _new_camera()
	var centre: Vector2 = camera.get_screen_center_position()
	var layer: AmbienceLayer = _new_layer(_short_sound(), false, LAYER_AT)
	layer.unpanned_sounds = _short_sound()
	layer.unpanned_player.stream = layer.unpanned_sounds
	layer.unpanned_share = UNPANNED_SHARE
	layer.unpanned_travel = AmbienceLayer.Travel.LEFT_TO_RIGHT
	layer.start()
	await _listen(layer, MIXED_FRAMES, MIXED_SOUNDS_TO_HEAR)
	var on_unpanned_player: bool = layer.unpanned_player.stream == layer.unpanned_sounds
	layer.queue_free()
	camera.queue_free()
	await process_frame
	if _heard_frames.size() < MIXED_SOUNDS_TO_HEAR:
		return _report(false, "only %d of %d sounds played with unpanned ones among them"
				% [_heard_frames.size(), MIXED_SOUNDS_TO_HEAR])
	var unpanned: int = 0
	var in_a_row: int = 0
	var wrong: Array[String] = []
	var previous_unpanned: bool = false
	for index: int in _heard_positions.size():
		var at: Vector2 = _heard_positions[index]
		var travel: int = _heard_travels[index]
		# An unpanned sound comes from the very centre; a placed one, from a random offset that is
		# never exactly nothing.
		var is_unpanned: bool = at.is_equal_approx(centre)
		if is_unpanned:
			unpanned += 1
			if previous_unpanned:
				in_a_row += 1
			if travel != 1 or _heard_player_at[index].is_equal_approx(at):
				wrong.append("unpanned #%d: travel %d" % [index, travel])
		elif travel != -int(signf(at.x - centre.x)):
			wrong.append("placed #%d at %+.0f px: travel %d" % [index, at.x - centre.x, travel])
		previous_unpanned = is_unpanned
	var share: float = float(unpanned) / _heard_positions.size()
	return _report(on_unpanned_player and in_a_row == 0 and wrong.is_empty()
			and absf(share - UNPANNED_SHARE) <= UNPANNED_SHARE_TOLERANCE,
			"unpanned sounds come from the screen's centre, travelling left to right, on their own "
			+ "player, never two in a row (%d), %.2f of the time for %.2f, and placed ones travel "
			% [in_a_row, share, UNPANNED_SHARE] + "away from their side (wrong: %s)"
			% ", ".join(wrong))


## A layer with only unpanned sounds, travelling nowhere, as the low rumbles: every sound is
## unpanned, one after another, from the centre of the screen, and the 2D player never moves.
func _with_only_unpanned_sounds_every_sound_is_unpanned() -> bool:
	var camera: Camera2D = await _new_camera()
	var centre: Vector2 = camera.get_screen_center_position()
	var layer: AmbienceLayer = _new_layer(null, false, LAYER_AT)
	layer.unpanned_sounds = _short_sound()
	layer.unpanned_player.stream = layer.unpanned_sounds
	var player_from: Vector2 = layer.player.global_position
	layer.start()
	await _listen(layer, FRAMES_FOR_ALL, SOUNDS_TO_HEAR)
	var player_stayed: bool = layer.player.global_position.is_equal_approx(player_from)
	layer.queue_free()
	camera.queue_free()
	await process_frame
	var off: int = 0
	for index: int in _heard_positions.size():
		if not _heard_positions[index].is_equal_approx(centre) or _heard_travels[index] != 0:
			off += 1
	return _report(_heard_positions.size() >= SOUNDS_TO_HEAR and off == 0 and player_stayed,
			"with only Unpanned Sounds, all %d sounds are unpanned, from the centre, travelling "
			% _heard_positions.size() + "nowhere (off: %d), and the 2D player stays put" % off)


## Level 1's two wind layers: the passing gusts, about every 27 s, two of them placed by Godot and
## the baked pan unpanned, left to right; and the low rumbles, about every 15 s, all unpanned and
## centred.
func _level1_has_the_wind_layers() -> bool:
	var scene: PackedScene = load(LEVEL1_AMBIENCE_PATH) as PackedScene
	if scene == null:
		return _report(false, "%s loads as a scene" % LEVEL1_AMBIENCE_PATH)
	var ambience: Node = scene.instantiate()
	var passing := ambience.get_node_or_null(^"PassingWind") as AmbienceLayer
	var rumble := ambience.get_node_or_null(^"LowRumble") as AmbienceLayer
	var problems: Array[String] = []
	if passing == null or rumble == null:
		problems.append("PassingWind and LowRumble are AmbienceLayers")
	else:
		problems.append_array(_layer_problems(passing, PASSING_GAPS, PASSING_FILES,
				BAKED_PAN_FILES, AmbienceLayer.Travel.LEFT_TO_RIGHT, GUSTS_BUS))
		problems.append_array(_layer_problems(rumble, RUMBLE_GAPS, [], RUMBLE_FILES,
				AmbienceLayer.Travel.NONE, AMBIENCE_BUS))
	ambience.queue_free()
	return _report(problems.is_empty(), "level 1 has the passing gusts every %.0f to %.0f s and "
			% [PASSING_GAPS.x, PASSING_GAPS.y] + "the low rumbles every %.0f to %.0f s, with "
			% [RUMBLE_GAPS.x, RUMBLE_GAPS.y] + "their sounds (problems: %s)"
			% "; ".join(problems))


## What a level's layer gets wrong against its gaps, the files of its Sounds and of its Unpanned
## Sounds, by name, its Unpanned Travel, and the bus its players play on.
func _layer_problems(layer: AmbienceLayer, gaps: Vector2, placed: Array[String],
		unpanned: Array[String], travel: AmbienceLayer.Travel, bus: StringName) -> Array[String]:
	var problems: Array[String] = []
	if not is_equal_approx(layer.min_gap, gaps.x) or not is_equal_approx(layer.max_gap, gaps.y):
		problems.append("%s gaps %.1f to %.1f s" % [layer.name, layer.min_gap, layer.max_gap])
	var placed_files: Array[String] = _file_names(layer.sounds)
	var unpanned_files: Array[String] = _file_names(layer.unpanned_sounds)
	placed_files.sort()
	unpanned_files.sort()
	if placed_files != placed:
		problems.append("%s Sounds %s" % [layer.name, placed_files])
	if unpanned_files != unpanned:
		problems.append("%s Unpanned Sounds %s" % [layer.name, unpanned_files])
	if layer.unpanned_travel != travel:
		problems.append("%s Unpanned Travel %d" % [layer.name, layer.unpanned_travel])
	if layer.unpanned_player == null or layer.player == null:
		problems.append("%s has no players" % layer.name)
	elif _players_bus(layer.bus, [layer.player.bus, layer.unpanned_player.bus]) != bus:
		problems.append("%s plays off the %s bus" % [layer.name, bus])
	return problems


## The bus players end on: bus, if set, and else theirs, if they share one; none otherwise.
func _players_bus(bus: StringName, theirs: Array[StringName]) -> StringName:
	if bus != &"":
		return bus
	for each: StringName in theirs:
		if each != theirs[0]:
			return &""
	return theirs[0]


## Level 1's gusts turn its beds down: Beds and Gusts send to Ambience, so the Ambience option
## applies to both, a compressor on Beds listens to Gusts, and the beds play on Beds (the passing
## gusts on Gusts: _level1_has_the_wind_layers).
func _gusts_turn_the_beds_down() -> bool:
	var problems: Array[String] = []
	for bus: StringName in [BEDS_BUS, GUSTS_BUS]:
		var index: int = AudioServer.get_bus_index(bus)
		if index == -1 or AudioServer.get_bus_send(index) != AMBIENCE_BUS:
			problems.append("%s does not send to Ambience" % bus)
	var beds: int = AudioServer.get_bus_index(BEDS_BUS)
	var listens: bool = false
	if beds != -1:
		for index: int in AudioServer.get_bus_effect_count(beds):
			var compressor := AudioServer.get_bus_effect(beds, index) as AudioEffectCompressor
			listens = listens or (compressor != null and compressor.sidechain == GUSTS_BUS
					and AudioServer.is_bus_effect_enabled(beds, index))
	if not listens:
		problems.append("no compressor on Beds listens to Gusts")
	var ambience: Node = (load(LEVEL1_AMBIENCE_PATH) as PackedScene).instantiate()
	for path: NodePath in LEVEL1_BEDS:
		var bed := ambience.get_node_or_null(path) as AmbienceBed
		if bed == null or _players_bus(bed.bus, [bed.first_player.bus, bed.second_player.bus]) != BEDS_BUS:
			problems.append("%s plays off Beds" % path)
	ambience.free()
	return _report(problems.is_empty(), "the gusts turn level 1's beds down: Beds and Gusts send to "
			+ "Ambience, a compressor on Beds listens to Gusts, and the beds play on Beds (problems: "
			+ "%s)" % "; ".join(problems))


## The file names in a sound: the streams of an AudioStreamRandomizer, the sound itself, or none.
func _file_names(sound: AudioStream) -> Array[String]:
	var names: Array[String] = []
	if sound == null:
		return names
	var randomizer := sound as AudioStreamRandomizer
	if randomizer == null:
		names.append(sound.resource_path.get_file())
		return names
	for index: int in randomizer.streams_count:
		var stream: AudioStream = randomizer.get_stream(index)
		names.append(stream.resource_path.get_file() if stream != null else "<empty>")
	return names


## A camera at CAMERA_AT, current and settled.
func _new_camera() -> Camera2D:
	var camera := Camera2D.new()
	# The project interpolates physics, which moves every Camera2D to the physics frame anyway.
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	camera.position = CAMERA_AT
	root.add_child(camera)
	camera.make_current()
	await _wait_frames(CAMERA_FRAMES)
	return camera


func _alerts_turn_the_ambience_down_and_the_players_sounds_do_not() -> bool:
	var alerts: int = AudioServer.get_bus_index(ALERTS_BUS)
	var into_sfx: bool = alerts != -1 and AudioServer.get_bus_send(alerts) == SFX_BUS
	var listens: bool = false
	var ambience: int = AudioServer.get_bus_index(AMBIENCE_BUS)
	if ambience != -1:
		for index: int in AudioServer.get_bus_effect_count(ambience):
			var compressor := AudioServer.get_bus_effect(ambience, index) as AudioEffectCompressor
			listens = listens or (compressor != null and compressor.sidechain == ALERTS_BUS
					and AudioServer.is_bus_effect_enabled(ambience, index))
	var elsewhere: Array[String] = []
	for path: String in ALERT_SCENES:
		elsewhere.append_array(_players_not_on(path, ALERTS_BUS))
	elsewhere.append_array(_players_not_on(PLAYER_SCENE_PATH, SFX_BUS, PLAYER_SOUNDS))
	return _report(into_sfx and listens and elsewhere.is_empty(),
			"Alerts sends to SFX (%s) and a compressor on Ambience listens to it (%s); "
			% [into_sfx, listens]
			+ "the demon and the crucifix are on Alerts and the player on SFX (off: %s)"
			% ", ".join(elsewhere))


## The sound players under the node at under, in the scene at path, that are not on bus, as
## "scene/node: bus". With no under, the whole scene.
func _players_not_on(path: String, bus: StringName, under: NodePath = ^".") -> Array[String]:
	var scene: PackedScene = load(path) as PackedScene
	if scene == null:
		return ["%s does not load" % path]
	var instance: Node = scene.instantiate()
	var top: Node = instance.get_node_or_null(under)
	if top == null:
		instance.queue_free()
		return ["%s has no %s" % [path.get_file(), under]]
	var players: Array[Node] = top.find_children("*", "AudioStreamPlayer2D", true, false)
	if players.is_empty():
		instance.queue_free()
		return ["%s/%s has no sound players" % [path.get_file(), under]]
	var off: Array[String] = []
	for player: Node in players:
		var on: StringName = (player as AudioStreamPlayer2D).bus
		if on != bus:
			off.append("%s/%s: %s" % [path.get_file(), instance.get_path_to(player), on])
	instance.queue_free()
	return off


## A layer with short gaps and a small spread, at position, already in the tree: with autostart,
## its countdown starts now.
func _new_layer(sounds: AudioStream, autostart: bool = true,
		position: Vector2 = Vector2.ZERO) -> AmbienceLayer:
	var layer: AmbienceLayer = _layer_scene.instantiate() as AmbienceLayer
	layer.sounds = sounds
	layer.autostart = autostart
	layer.min_gap = MIN_GAP
	layer.max_gap = MAX_GAP
	layer.horizontal_spread = HORIZONTAL_SPREAD
	layer.vertical_spread = VERTICAL_SPREAD
	layer.position = position
	root.add_child(layer)
	return layer


## Waits up to frames process frames, and keeps the frame and the place of each sound the layer
## plays, counting frames from now. It stops early once enough sounds have played, if enough is
## more than 0.
func _listen(layer: AmbienceLayer, frames: int, enough: int = 0) -> void:
	_frame = 0
	_heard_frames.clear()
	_heard_positions.clear()
	_heard_travels.clear()
	_heard_player_at.clear()
	var on_played: Callable = func(at: Vector2, travel: int) -> void:
		_heard_frames.append(_frame)
		_heard_positions.append(at)
		_heard_travels.append(travel)
		_heard_player_at.append(layer.player.global_position)
	layer.sound_played.connect(on_played)
	for _step: int in frames:
		await process_frame
		_frame += 1
		if enough > 0 and _heard_frames.size() >= enough:
			break
	layer.sound_played.disconnect(on_played)


## Whether every sound heard came from inside the spread around centre, and some from each side.
func _inside_the_spread_on_both_sides(centre: Vector2) -> bool:
	if _heard_positions.size() < SOUNDS_TO_HEAR:
		return false
	var left: bool = false
	var right: bool = false
	for at: Vector2 in _heard_positions:
		var offset: Vector2 = at - centre
		if absf(offset.x) > HORIZONTAL_SPREAD + LIMIT_TOLERANCE:
			return false
		if absf(offset.y) > VERTICAL_SPREAD + LIMIT_TOLERANCE:
			return false
		left = left or offset.x < 0.0
		right = right or offset.x > 0.0
	return left and right


func _wait_frames(frames: int) -> void:
	for _step: int in frames:
		await process_frame


func _report(passed: bool, what: String) -> bool:
	print("%s: %s" % ["PASS" if passed else "FAIL", what])
	return passed


## Quits with exit code 0 if every case passed, and 1 otherwise.
func _finish(results: Array[bool]) -> void:
	quit(1 if results.has(false) else 0)


## A tenth of a second of silence, made in memory: the test needs a sound to play, not to hear one.
func _short_sound(length: float = SHORT_SOUND_LENGTH) -> AudioStreamWAV:
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = SHORT_SOUND_RATE
	var bytes := PackedByteArray()
	bytes.resize(int(SHORT_SOUND_RATE * length) * 2)
	sound.data = bytes
	return sound
