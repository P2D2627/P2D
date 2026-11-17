# Checks the ambience layers. A layer plays its sounds one at a time, and each wait, from start()
# to the first sound and from one sound to the next, is between Min Gap and Max Gap and not always
# the same. Each sound comes from inside the spread around the centre of the screen, from both
# sides of it, or around the layer itself when there is no camera. The sounds play on the Ambience
# bus, so the Ambience volume option applies to them. Without Autostart a layer waits for start(),
# stop() holds it, and so does the pause. A layer without sounds plays nothing.
# The sounds the player needs to hear to stay alive, the demon's and the crucifix's, play on the
# Alerts bus, which sends to SFX, and a compressor on the Ambience bus listens to Alerts, so they
# turn the ambience down while they play. The player's own sounds, steps among them, stay on SFX
# and leave the ambience alone, so it does not dip on every step.
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

var _layer_scene: PackedScene
## Process frames since the last _listen() began, when each sound played and from where.
var _frame: int = 0
var _heard_frames: Array[int] = []
var _heard_positions: Array[Vector2] = []


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
	results.append(await _without_autostart_waits_for_start())
	results.append(await _stop_holds_the_sounds())
	results.append(await _pause_holds_the_sounds())
	results.append(await _without_sounds_plays_nothing())
	results.append(_alerts_turn_the_ambience_down_and_the_players_sounds_do_not())
	# Lets the last layer's queue_free() happen before quitting.
	await process_frame
	_finish(results)


func _plays_on_the_ambience_bus() -> bool:
	var sounds := _short_sound()
	var layer: AmbienceLayer = _new_layer(sounds)
	var player: AudioStreamPlayer2D = layer.player
	var passed: bool = (player != null and player.bus == AMBIENCE_BUS and player.stream == sounds
			and AudioServer.get_bus_index(AMBIENCE_BUS) != -1)
	layer.queue_free()
	return _report(passed, "the sounds play on the Ambience bus, with the layer's Sounds")


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
	var silent: bool = _heard_frames.is_empty() and not layer.player.playing
	layer.queue_free()
	return _report(silent, "a layer without Sounds plays nothing")


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
	var on_played: Callable = func(at: Vector2) -> void:
		_heard_frames.append(_frame)
		_heard_positions.append(at)
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
func _short_sound() -> AudioStreamWAV:
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = SHORT_SOUND_RATE
	var bytes := PackedByteArray()
	bytes.resize(int(SHORT_SOUND_RATE * SHORT_SOUND_LENGTH) * 2)
	sound.data = bytes
	return sound
