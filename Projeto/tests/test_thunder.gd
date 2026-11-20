# Checks the thunder of the ambience. The thunders play on buses of their own, which send to a
# Thunder bus and that to Ambience, so the Ambience option and the alerts' ducking apply to them;
# the background and the main thunders' buses have a Panner, which BusPan sets. A thunder layer
# flashes first and plays the thunder Thunder Delay later, the same strike, panned Pan to the
# flash's side, at a pitch inside Random Pitch, with each wait between flashes inside Min Gap and
# Max Gap; stop() holds the flashes but not a thunder still to come, and the pause holds both. The
# lightning flash lights from the strike's side, as bright as the strike's flash at each moment,
# last in the backdrop, and goes out when the flash ends. An ambience layer with Side Pan pans each
# unpanned sound to a side, inside the range, and says it travels to the other. Level 1's two
# strikes flash no more than three times in any one second (the WCAG rule), and its three thunder
# layers have the gaps, the files, the buses and the pans asked for, with gaps long enough that two
# sounds of one layer never overlap.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_thunder.gd
extends "res://tests/support/base_test.gd"

const THUNDER_LAYER_PATH: String = "res://scenes/others/ambience/thunder_layer.tscn"
const AMBIENCE_LAYER_PATH: String = "res://scenes/others/ambience/ambience_layer.tscn"
const FLASH_PATH: String = "res://scenes/others/ambience/lightning_flash.tscn"
const LEVEL1_AMBIENCE_PATH: String = "res://scenes/levels/lust/lust_ambience.tscn"
const AMBIENCE_BUS: StringName = &"Ambience"
const THUNDER_BUS: StringName = &"Thunder"
const BACKLAYER_BUS: StringName = &"ThunderBacklayer"
const BACKGROUND_BUS: StringName = &"ThunderBackground"
const MAIN_BUS: StringName = &"ThunderMain"
## The length of a frame with --fixed-fps 60, as in the command above.
const FRAME_TIME: float = 1.0 / 60.0
## Short gaps and delays, so a test sees many strikes in little time.
const MIN_GAP: float = 1.0
const MAX_GAP: float = 2.0
const DELAY: Vector2 = Vector2(0.3, 0.6)
const PAN: float = 0.35
const RANDOM_PITCH: float = 1.04
## Strikes to see in a row, and the frames to wait for them at Max Gap each, plus a second.
const STRIKES_TO_SEE: int = 16
const FRAMES_FOR_ALL: int = int(STRIKES_TO_SEE * MAX_GAP / FRAME_TIME) + 60
## Frames in which a running layer flashes at least twice: what a held layer must stay dark for.
const QUIET_FRAMES: int = int(3.0 * MAX_GAP / FRAME_TIME)
## Frames longer than the longest delay.
const PAST_DELAY_FRAMES: int = int(DELAY.y / FRAME_TIME) + 10
## Rounding room for the time, the pan and the brightness checks.
const LIMIT_TOLERANCE: float = 0.001
## How far the light may be from the strike's flash: up to a frame of change of the test's flash.
const LIGHT_TOLERANCE: float = 0.05
## The test strike's flash: from its brightest down to dark, over this long, in s.
const TEST_FLASH_LENGTH: float = 0.5
## The silent sound the layers play: its sample rate, in Hz, and its length, in s.
const SHORT_SOUND_RATE: int = 22050
const SHORT_SOUND_LENGTH: float = 0.1
const RANDOM_SEED: int = 2026
## Frames to wait before quitting, longer than the silent sound.
const EXIT_FRAMES: int = int(SHORT_SOUND_LENGTH / FRAME_TIME) + 10
## Real milliseconds to wait before quitting, for the audio server's thread.
const EXIT_DELAY_MS: int = 200
## The WCAG rule: no more than three flashes in any one second, a flash being a rise and a fall of
## a tenth or more of the brightest light.
const FLASH_LIMIT: int = 3
const FLASH_CHANGE: float = 0.1
## Level 1's thunder: the gaps, in s, the sound files, by name, and the pans.
const BACKLAYER_GAPS: Vector2 = Vector2(32.0, 48.0)
const BACKGROUND_GAPS: Vector2 = Vector2(9.0, 15.0)
const MAIN_GAPS: Vector2 = Vector2(26.0, 38.0)
const MAIN_DELAY: Vector2 = Vector2(2.0, 6.0)
const BACKGROUND_SIDE_PAN: Vector2 = Vector2(0.5, 0.8)
const BACKLAYER_FILES: Array[String] = ["thunder_spontaneous_backlayer_1.wav",
		"thunder_spontaneous_backlayer_2.wav"]
const BACKGROUND_FILES: Array[String] = ["thunder_background_1.wav", "thunder_background_2.wav"]
const MAIN_FILES: Array[String] = ["thunder_1.wav", "thunder_2.wav"]

var _thunder_scene: PackedScene
var _ambience_layer_scene: PackedScene
var _flash_scene: PackedScene
## Process frames since the last _watch() began, and what happened in them: each flash's frame,
## strike and side, each thunder's frame, strike, side, the pan on its bus and its pitch.
var _frame: int = 0
var _flash_frames: Array[int] = []
var _flash_strikes: Array[ThunderStrike] = []
var _flash_sides: Array[int] = []
var _thunder_frames: Array[int] = []
var _thunder_strikes: Array[ThunderStrike] = []
var _thunder_sides: Array[int] = []
var _thunder_pans: Array[float] = []
var _thunder_pitches: Array[float] = []


func _initialize() -> void:
	_thunder_scene = load(THUNDER_LAYER_PATH) as PackedScene
	_ambience_layer_scene = load(AMBIENCE_LAYER_PATH) as PackedScene
	_flash_scene = load(FLASH_PATH) as PackedScene
	if _thunder_scene == null or _ambience_layer_scene == null or _flash_scene == null:
		_report(false, "the thunder layer, the ambience layer and the lightning flash load as scenes")
		_finish([false])
		return
	# A node added before the root is ready only gets _ready() with the root, on the first frame.
	await process_frame
	seed(RANDOM_SEED)
	var results: Array[bool] = []
	results.append(_the_thunder_buses_send_to_ambience_with_their_panners())
	results.append(_bus_pan_sets_the_panner_on_a_bus())
	results.append(await _a_flash_comes_first_and_its_thunder_follows())
	results.append(await _stop_holds_the_flashes_but_not_a_coming_thunder())
	results.append(await _the_pause_holds_the_thunder())
	results.append(await _the_light_follows_the_strike_from_its_side())
	results.append(await _side_pan_pans_each_unpanned_sound_to_a_side())
	results.append(_level1_strikes_flash_at_most_three_times_a_second())
	results.append(_level1_has_the_thunder_layers())
	BusPan.set_pan(BACKGROUND_BUS, 0.0)
	BusPan.set_pan(MAIN_BUS, 0.0)
	# Lets the last nodes' queue_free() happen, and the audio server let go of their sounds, before
	# quitting: it does in its own thread, in real time, and with --fixed-fps the frames run faster.
	await _wait_frames(EXIT_FRAMES)
	OS.delay_msec(EXIT_DELAY_MS)
	await process_frame
	_finish(results)


func _the_thunder_buses_send_to_ambience_with_their_panners() -> bool:
	var sends: bool = (_send_of(THUNDER_BUS) == AMBIENCE_BUS and _send_of(BACKLAYER_BUS) == THUNDER_BUS
			and _send_of(BACKGROUND_BUS) == THUNDER_BUS and _send_of(MAIN_BUS) == THUNDER_BUS)
	var panners: bool = (BusPan.panner_of(BACKGROUND_BUS) != null
			and BusPan.panner_of(MAIN_BUS) != null and BusPan.panner_of(BACKLAYER_BUS) == null)
	var backlayer_db: float = _volume_of(BACKLAYER_BUS)
	var quietest: bool = (backlayer_db < _volume_of(BACKGROUND_BUS)
			and backlayer_db < _volume_of(MAIN_BUS))
	return _report(sends and panners and quietest,
			"the three thunder buses send to Thunder and Thunder to Ambience %s; the background and "
			% sends + "the main ones have a Panner, the backlayer none %s; the backlayer's is the "
			% panners + "lowest (%.1f dB) %s" % [backlayer_db, quietest])


func _bus_pan_sets_the_panner_on_a_bus() -> bool:
	var set_main: bool = BusPan.set_pan(MAIN_BUS, PAN)
	var read_back: float = BusPan.get_pan(MAIN_BUS)
	var clamped: bool = BusPan.set_pan(MAIN_BUS, -2.0) and is_equal_approx(BusPan.get_pan(MAIN_BUS), -1.0)
	var without: bool = not BusPan.set_pan(&"Master", PAN) and not BusPan.set_pan(&"NoSuchBus", PAN)
	BusPan.set_pan(MAIN_BUS, 0.0)
	return _report(set_main and is_equal_approx(read_back, PAN) and clamped and without,
			"BusPan sets the panner on a bus (%.2f), keeps it inside -1 and 1, and does nothing on a "
			% read_back + "bus without one")


## Many strikes in a row: each thunder follows its own flash, the same strike on the same side,
## within Thunder Delay, panned to that side, at a pitch inside Random Pitch; the flashes come from
## both sides, Min Gap to Max Gap apart, and both strikes are picked.
func _a_flash_comes_first_and_its_thunder_follows() -> bool:
	var first: ThunderStrike = _test_strike()
	var second: ThunderStrike = _test_strike()
	var layer: ThunderLayer = _new_thunder_layer([first, second])
	await _watch(layer, FRAMES_FOR_ALL, STRIKES_TO_SEE)
	layer.queue_free()
	var seen: int = mini(_flash_frames.size(), _thunder_frames.size())
	if seen < STRIKES_TO_SEE:
		return _report(false, "only %d of %d strikes with their thunder in %d frames"
				% [seen, STRIKES_TO_SEE, FRAMES_FOR_ALL])
	var wrong: Array[String] = []
	for index: int in seen:
		var delay: float = (_thunder_frames[index] - _flash_frames[index]) * FRAME_TIME
		if delay < DELAY.x - FRAME_TIME - LIMIT_TOLERANCE or delay > DELAY.y + FRAME_TIME + LIMIT_TOLERANCE:
			wrong.append("thunder %d after %.3f s" % [index, delay])
		if _thunder_strikes[index] != _flash_strikes[index] or _thunder_sides[index] != _flash_sides[index]:
			wrong.append("thunder %d is not its flash's strike or side" % index)
		if absf(_thunder_pans[index] - _thunder_sides[index] * PAN) > LIMIT_TOLERANCE:
			wrong.append("thunder %d panned %.3f" % [index, _thunder_pans[index]])
		var pitch: float = _thunder_pitches[index]
		if pitch < 1.0 / RANDOM_PITCH - LIMIT_TOLERANCE or pitch > RANDOM_PITCH + LIMIT_TOLERANCE:
			wrong.append("thunder %d at pitch %.3f" % [index, pitch])
		if index > 0:
			var gap: float = (_flash_frames[index] - _flash_frames[index - 1]) * FRAME_TIME
			if gap < MIN_GAP - LIMIT_TOLERANCE or gap > MAX_GAP + FRAME_TIME + LIMIT_TOLERANCE:
				wrong.append("flash %d after %.3f s" % [index, gap])
	var both_sides: bool = _flash_sides.has(-1) and _flash_sides.has(1)
	var both_strikes: bool = _flash_strikes.has(first) and _flash_strikes.has(second)
	return _report(wrong.is_empty() and both_sides and both_strikes,
			"in %d strikes, each thunder comes Thunder Delay after its flash, the same strike on the "
			% seen + "same side, panned to it, at a pitch inside Random Pitch, with the flashes Min "
			+ "Gap to Max Gap apart (wrong: %s); from both sides %s, both strikes %s"
			% [", ".join(wrong), both_sides, both_strikes])


func _stop_holds_the_flashes_but_not_a_coming_thunder() -> bool:
	var layer: ThunderLayer = _new_thunder_layer([_test_strike()])
	layer.strike_now()
	layer.stop()
	await _watch(layer, QUIET_FRAMES)
	var held: bool = _flash_frames.is_empty() and not layer.is_running()
	var came: bool = _thunder_frames.size() == 1 and not layer.is_thunder_coming()
	layer.queue_free()
	return _report(held and came,
			"stop() holds the flashes %s, and the thunder of the last one still comes %s"
			% [held, came])


func _the_pause_holds_the_thunder() -> bool:
	var layer: ThunderLayer = _new_thunder_layer([_test_strike()])
	layer.strike_now()
	paused = true
	await _watch(layer, PAST_DELAY_FRAMES)
	var held: bool = _thunder_frames.is_empty() and layer.is_thunder_coming()
	paused = false
	await _watch(layer, PAST_DELAY_FRAMES)
	var came: bool = _thunder_frames.size() == 1
	layer.queue_free()
	return _report(held and came,
			"the pause holds a thunder still to come %s, and it comes after the pause %s"
			% [held, came])


## A flash from the left, then one from the right: the light is drawn last in the backdrop, comes
## from the strike's side, follows the strike's flash frame by frame and goes out when it ends.
func _the_light_follows_the_strike_from_its_side() -> bool:
	var strike: ThunderStrike = _test_strike()
	var layer: ThunderLayer = _new_thunder_layer([strike], false)
	var backdrop := Node2D.new()
	backdrop.add_child(Node2D.new())
	root.add_child(backdrop)
	var light: LightningFlash = _flash_scene.instantiate() as LightningFlash
	light.thunder_layer = layer
	light.backdrop = backdrop
	root.add_child(light)
	await _wait_frames(2)
	var last_in_backdrop: bool = light.is_in_backdrop() and backdrop.get_child(-1) is ColorRect
	var dark_before: bool = not light.is_flashing() and light.get_intensity() == 0.0
	layer.strike_now(-1)
	var at_start: float = light.get_intensity()
	var left: bool = light.get_light_centre().x < 0.5
	var off: Array[String] = []
	var frames: int = 0
	while light.is_flashing() and frames < int(TEST_FLASH_LENGTH / FRAME_TIME) + 10:
		await process_frame
		frames += 1
		if not light.is_flashing():
			break
		var expected: float = strike.brightness_at(frames * FRAME_TIME) * light.brightness
		if absf(light.get_intensity() - expected) > LIGHT_TOLERANCE * light.brightness:
			off.append("%.2f, not %.2f, at %d" % [light.get_intensity(), expected, frames])
	var flash_time: float = frames * FRAME_TIME
	var ended: bool = (not light.is_flashing() and light.get_intensity() == 0.0
			and absf(flash_time - TEST_FLASH_LENGTH) <= 2.0 * FRAME_TIME)
	layer.strike_now(1)
	var right: bool = light.get_light_centre().x > 0.5
	var full: float = light.brightness
	light.queue_free()
	layer.queue_free()
	backdrop.queue_free()
	await process_frame
	return _report(last_in_backdrop and dark_before and left and right and off.is_empty() and ended
			and is_equal_approx(at_start, full),
			"the light is drawn last in the backdrop %s and dark between flashes %s; it comes from "
			% [last_in_backdrop, dark_before] + "the strike's side (left %s, right %s), starts at "
			% [left, right] + "the strike's brightest (%.2f) and follows its flash (off: %s), and "
			% [at_start, ", ".join(off)] + "goes out when it ends, after %.3f s %s"
			% [flash_time, ended])


## An ambience layer with Side Pan pans each unpanned sound to a side picked at random, inside the
## range, and says it travels to the other side; without it, the bus's pan is left as it is.
func _side_pan_pans_each_unpanned_sound_to_a_side() -> bool:
	var layer: AmbienceLayer = _ambience_layer_scene.instantiate() as AmbienceLayer
	layer.unpanned_sounds = _short_sound()
	layer.bus = BACKGROUND_BUS
	layer.side_pan = BACKGROUND_SIDE_PAN
	layer.min_gap = MIN_GAP
	layer.max_gap = MAX_GAP
	var pans: Array[float] = []
	var travels: Array[int] = []
	layer.sound_played.connect(func(_at: Vector2, travel: int) -> void:
			pans.append(BusPan.get_pan(BACKGROUND_BUS))
			travels.append(travel))
	root.add_child(layer)
	var frames: int = 0
	while pans.size() < STRIKES_TO_SEE and frames < FRAMES_FOR_ALL:
		await process_frame
		frames += 1
	layer.queue_free()
	var wrong: Array[String] = []
	for index: int in pans.size():
		var amount: float = absf(pans[index])
		if (amount < BACKGROUND_SIDE_PAN.x - LIMIT_TOLERANCE
				or amount > BACKGROUND_SIDE_PAN.y + LIMIT_TOLERANCE):
			wrong.append("%.3f" % pans[index])
		if travels[index] != -int(signf(pans[index])):
			wrong.append("%.3f travelling %d" % [pans[index], travels[index]])
	var both_sides: bool = pans.any(func(pan: float) -> bool: return pan < 0.0) and pans.any(
			func(pan: float) -> bool: return pan > 0.0)
	# Without Side Pan, the bus keeps its pan.
	BusPan.set_pan(BACKGROUND_BUS, 0.0)
	var plain: AmbienceLayer = _ambience_layer_scene.instantiate() as AmbienceLayer
	plain.unpanned_sounds = _short_sound()
	plain.bus = BACKGROUND_BUS
	plain.min_gap = MIN_GAP
	plain.max_gap = MAX_GAP
	var heard: Array[int] = []
	plain.sound_played.connect(func(_at: Vector2, _travel: int) -> void: heard.append(1))
	root.add_child(plain)
	frames = 0
	while heard.size() < 2 and frames < QUIET_FRAMES:
		await process_frame
		frames += 1
	var kept: bool = heard.size() >= 2 and BusPan.get_pan(BACKGROUND_BUS) == 0.0
	plain.queue_free()
	return _report(pans.size() >= STRIKES_TO_SEE and wrong.is_empty() and both_sides and kept,
			"with Side Pan, each of %d unpanned sounds is panned inside the range and travels to "
			% pans.size() + "the other side (wrong: %s), from both sides %s; without it, the pan "
			% [", ".join(wrong), both_sides] + "stays %s" % kept)


func _level1_strikes_flash_at_most_three_times_a_second() -> bool:
	var ambience: Node = (load(LEVEL1_AMBIENCE_PATH) as PackedScene).instantiate()
	var layer := ambience.get_node_or_null(^"ThunderMain") as ThunderLayer
	var lines: Array[String] = []
	var passed: bool = layer != null and not layer.strikes.is_empty()
	var brightest: float = 0.0
	if layer != null:
		for strike: ThunderStrike in layer.strikes:
			var count: Array = _most_flashes_in_a_second(strike)
			brightest = maxf(brightest, strike.strength)
			var ends_dark: bool = strike.brightness_at(strike.flash_length) <= LIMIT_TOLERANCE
			passed = passed and count[0] <= FLASH_LIMIT and count[1] and ends_dark
			lines.append("%s: %d flashes at most in one second, inside 0 to 1 %s, ends dark %s"
					% [strike.sound.resource_path.get_file(), count[0], count[1], ends_dark])
	ambience.free()
	passed = passed and is_equal_approx(brightest, 1.0)
	return _report(passed, "level 1's strikes flash no more than %d times in any second, the "
			% FLASH_LIMIT + "loudest at full strength (%s)" % "; ".join(lines))


func _level1_has_the_thunder_layers() -> bool:
	# Read as the scene sets them, outside the tree: no sound starts.
	var ambience: Node = (load(LEVEL1_AMBIENCE_PATH) as PackedScene).instantiate()
	var backlayer := ambience.get_node_or_null(^"ThunderBacklayer") as AmbienceLayer
	var background := ambience.get_node_or_null(^"ThunderBackground") as AmbienceLayer
	var main := ambience.get_node_or_null(^"ThunderMain") as ThunderLayer
	var light := ambience.get_node_or_null(^"LightningFlash") as LightningFlash
	var lines: Array[String] = []
	var passed: bool = backlayer != null and background != null and main != null and light != null
	if passed:
		var backlayer_ok: bool = (_gaps_of(backlayer) == BACKLAYER_GAPS
				and _randomizer_files(backlayer.unpanned_sounds) == BACKLAYER_FILES
				and backlayer.bus == BACKLAYER_BUS and backlayer.side_pan == Vector2.ZERO
				and backlayer.sounds == null
				and backlayer.min_gap > _longest(backlayer.unpanned_sounds))
		var background_ok: bool = (_gaps_of(background) == BACKGROUND_GAPS
				and _randomizer_files(background.unpanned_sounds) == BACKGROUND_FILES
				and background.bus == BACKGROUND_BUS
				and background.side_pan == BACKGROUND_SIDE_PAN and background.sounds == null
				and background.min_gap > _longest(background.unpanned_sounds))
		var main_files: Array[String] = []
		var main_longest: float = 0.0
		for strike: ThunderStrike in main.strikes:
			main_files.append(strike.sound.resource_path.get_file())
			main_longest = maxf(main_longest, strike.sound.get_length() * main.random_pitch)
		main_files.sort()
		var main_ok: bool = (Vector2(main.min_gap, main.max_gap) == MAIN_GAPS
				and main_files == MAIN_FILES and main.bus == MAIN_BUS
				and main.thunder_delay == MAIN_DELAY and is_equal_approx(main.pan, PAN)
				and main.min_gap > main.thunder_delay.y + main_longest)
		var light_ok: bool = light.thunder_layer == main
		lines.append("backlayer %s, background %s, main %s, flash on the main layer %s"
				% [backlayer_ok, background_ok, main_ok, light_ok])
		passed = backlayer_ok and background_ok and main_ok and light_ok
	ambience.free()
	return _report(passed, "level 1 has the three thunder layers with their gaps, files, buses and "
			+ "pans, no two sounds of a layer overlapping, and the flash on the main thunder (%s)"
			% "; ".join(lines))


## The most flashes in any one second of strike's flash, sampled at 60 frames a second, a flash
## being a rise and then a fall of FLASH_CHANGE or more; and whether it stays inside 0 and 1.
func _most_flashes_in_a_second(strike: ThunderStrike) -> Array:
	var turns: Array[float] = []
	var inside: bool = true
	var high: float = strike.brightness_at(0.0)
	var low: float = high
	var rising: bool = true
	for step: int in int(strike.flash_length / FRAME_TIME) + 1:
		var time: float = step * FRAME_TIME
		var value: float = strike.brightness_at(time)
		inside = inside and value >= 0.0 and value <= 1.0
		if rising:
			high = maxf(high, value)
			if high - value >= FLASH_CHANGE:
				turns.append(time)
				rising = false
				low = value
		else:
			low = minf(low, value)
			if value - low >= FLASH_CHANGE:
				rising = true
				high = value
	var most: int = 0
	for start: float in turns:
		most = maxi(most, turns.filter(func(t: float) -> bool:
				return t >= start and t < start + 1.0).size())
	return [most, inside]


func _new_thunder_layer(strikes: Array[ThunderStrike], autostart: bool = true) -> ThunderLayer:
	var layer: ThunderLayer = _thunder_scene.instantiate() as ThunderLayer
	layer.strikes = strikes
	layer.bus = MAIN_BUS
	layer.autostart = autostart
	layer.min_gap = MIN_GAP
	layer.max_gap = MAX_GAP
	layer.thunder_delay = DELAY
	layer.pan = PAN
	layer.random_pitch = RANDOM_PITCH
	root.add_child(layer)
	return layer


## Waits up to frames process frames, and keeps what the layer does in them, counting frames from
## now. It stops early once enough thunders have played, each after its flash, if enough is more
## than 0.
func _watch(layer: ThunderLayer, frames: int, enough: int = 0) -> void:
	_frame = 0
	_flash_frames.clear()
	_flash_strikes.clear()
	_flash_sides.clear()
	_thunder_frames.clear()
	_thunder_strikes.clear()
	_thunder_sides.clear()
	_thunder_pans.clear()
	_thunder_pitches.clear()
	var on_struck: Callable = func(strike: ThunderStrike, side: int) -> void:
		_flash_frames.append(_frame)
		_flash_strikes.append(strike)
		_flash_sides.append(side)
	var on_played: Callable = func(strike: ThunderStrike, side: int) -> void:
		_thunder_frames.append(_frame)
		_thunder_strikes.append(strike)
		_thunder_sides.append(side)
		_thunder_pans.append(BusPan.get_pan(layer.player.bus))
		_thunder_pitches.append(layer.player.pitch_scale)
	layer.lightning_struck.connect(on_struck)
	layer.thunder_played.connect(on_played)
	for _step: int in frames:
		await process_frame
		_frame += 1
		if enough > 0 and _thunder_frames.size() >= enough:
			break
	layer.lightning_struck.disconnect(on_struck)
	layer.thunder_played.disconnect(on_played)


## A strike with a silent sound and a flash that falls in a straight line from its brightest to
## dark over TEST_FLASH_LENGTH.
func _test_strike() -> ThunderStrike:
	var strike := ThunderStrike.new()
	strike.sound = _short_sound()
	strike.flash = Curve.new()
	strike.flash.add_point(Vector2(0.0, 1.0), 0.0, -1.0, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
	strike.flash.add_point(Vector2(1.0, 0.0), -1.0, 0.0, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
	strike.flash_length = TEST_FLASH_LENGTH
	strike.strength = 1.0
	return strike


## The file names of an AudioStreamRandomizer's sounds, sorted.
func _randomizer_files(stream: AudioStream) -> Array[String]:
	var files: Array[String] = []
	var randomizer := stream as AudioStreamRandomizer
	if randomizer == null:
		return files
	for index: int in randomizer.streams_count:
		files.append(randomizer.get_stream(index).resource_path.get_file())
	files.sort()
	return files


## The longest of an AudioStreamRandomizer's sounds at its lowest pitch, in s.
func _longest(stream: AudioStream) -> float:
	var randomizer := stream as AudioStreamRandomizer
	if randomizer == null:
		return 0.0
	var longest: float = 0.0
	for index: int in randomizer.streams_count:
		longest = maxf(longest, randomizer.get_stream(index).get_length())
	return longest * randomizer.random_pitch


func _gaps_of(layer: AmbienceLayer) -> Vector2:
	return Vector2(layer.min_gap, layer.max_gap)


func _send_of(bus: StringName) -> StringName:
	var index: int = AudioServer.get_bus_index(bus)
	return AudioServer.get_bus_send(index) if index >= 0 else &""


func _volume_of(bus: StringName) -> float:
	return AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus))


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
