# Checks the ducking on the Ambience bus, with the bus layout as it is. Every sound the man needs to
# hear to stay alive, the crucifix's and the demon's, played on the Alerts bus, turns the ambience
# down by at least MIN_ALERT_DIP, even the quietest, and by no more than MAX_DIP, even the loudest.
# His own sounds, steps and landings among them, played on SFX, turn it down by MAX_STEADY_DIP at
# most, so it breathes with his steps instead of pumping. The sounds are read from the scenes, so a
# new one is checked too.
# A steady tone plays on Ambience, so its level only moves when a compressor acts. Headless, the
# audio mixes in real time with no output: nothing is heard, and the test takes about a minute.
# Each line gives, for every sound, the loudest it gets on its bus (what the compressors listen to)
# and the ambience's dip, at the most, in dB.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_ambience_ducking.gd
extends "res://tests/support/base_test.gd"

const AMBIENCE_BUS: StringName = &"Ambience"
const ALERTS_BUS: StringName = &"Alerts"
const SFX_BUS: StringName = &"SFX"
## The scenes whose sounds are alerts, each with the node that holds them.
const ALERT_SOUNDS: Array[Array] = [
	["res://scenes/characters/crucifix/crucifix.tscn", ^"CrucifixSounds"],
	["res://scenes/characters/demon/demon.tscn", ^"DemonSounds"],
]
const PLAYER_SCENE: String = "res://scenes/characters/player/player.tscn"
const PLAYER_SOUNDS: NodePath = ^"PlayerSounds"
## The least an alert must turn the ambience down, so it is heard over it, and the most any sound
## may, so the ambience does not vanish; and the most the man's own sounds may: the compressor that
## listens to SFX turns the ambience down a little for them too, gently, so it breathes with his
## steps instead of pumping.
const MIN_ALERT_DIP: float = 5.0
const MAX_DIP: float = 18.0
const MAX_STEADY_DIP: float = 3.0
## The tone on the Ambience bus: its level, pitch and sample rate.
const TONE_DB: float = -12.0
const TONE_HZ: float = 220.0
const TONE_RATE: int = 44100
## How long to let the tone settle and to read its level, in ms; and how often to read the levels.
const SETTLE_MS: int = 600
const LEVEL_MS: int = 300
const SAMPLE_MS: int = 5
## A deep dip takes seconds to come back, so before each sound the test waits, up to RECOVER_MS,
## until the ambience is back within RECOVERED_DB of its level with nothing playing.
const RECOVER_MS: int = 8000
const RECOVERED_DB: float = 0.3
## Each sound plays this many times, and its dip is the smallest: a missed reading can only make a
## dip look deeper.
const TRIES: int = 2
## The longest a sound is listened to, in ms: the loops get this long.
const LONGEST_MS: int = 1500

var _tone_player: AudioStreamPlayer
var _sound_player: AudioStreamPlayer
## The ambience's level with nothing playing, in dB.
var _level: float = -INF


func _initialize() -> void:
	await process_frame
	var buses_there: bool = true
	for bus: StringName in [AMBIENCE_BUS, ALERTS_BUS, SFX_BUS]:
		buses_there = buses_there and AudioServer.get_bus_index(bus) >= 0
	if not buses_there:
		_report(false, "the Ambience, Alerts and SFX buses are in the layout")
		_finish([false])
		return
	_tone_player = AudioStreamPlayer.new()
	_tone_player.stream = _tone()
	_tone_player.bus = AMBIENCE_BUS
	root.add_child(_tone_player)
	_sound_player = AudioStreamPlayer.new()
	root.add_child(_sound_player)
	_tone_player.play()
	OS.delay_msec(SETTLE_MS)
	var ambience: int = AudioServer.get_bus_index(AMBIENCE_BUS)
	for _sample: int in LEVEL_MS / SAMPLE_MS:
		OS.delay_msec(SAMPLE_MS)
		_level = maxf(_level, AudioServer.get_bus_peak_volume_left_db(ambience, 0))
	var alerts: Array[AudioStream] = []
	for entry: Array in ALERT_SOUNDS:
		alerts.append_array(_sounds_in(entry[0], entry[1]))
	var steady: Array[AudioStream] = _sounds_in(PLAYER_SCENE, PLAYER_SOUNDS)
	var results: Array[bool] = []
	results.append(_every_alert_turns_the_ambience_down_within_bounds(alerts))
	results.append(_the_mans_own_sounds_hardly_touch_it(steady))
	_tone_player.queue_free()
	_sound_player.queue_free()
	await process_frame
	_finish(results)


func _every_alert_turns_the_ambience_down_within_bounds(alerts: Array[AudioStream]) -> bool:
	var lines: Array[String] = []
	var passed: bool = alerts.size() > 0
	for sound: AudioStream in alerts:
		var heard: Vector2 = _dip_under(sound, ALERTS_BUS)
		passed = passed and heard.y >= MIN_ALERT_DIP and heard.y <= MAX_DIP
		lines.append("%s %.1f dB, dip %.1f" % [sound.resource_path.get_file(), heard.x, heard.y])
	return _report(passed, "each of %d alerts on Alerts dips the ambience by %.0f to %.0f dB:\n  %s"
			% [alerts.size(), MIN_ALERT_DIP, MAX_DIP, "\n  ".join(lines)])


func _the_mans_own_sounds_hardly_touch_it(steady: Array[AudioStream]) -> bool:
	var lines: Array[String] = []
	var passed: bool = steady.size() > 0
	for sound: AudioStream in steady:
		var heard: Vector2 = _dip_under(sound, SFX_BUS)
		passed = passed and heard.y <= MAX_STEADY_DIP
		lines.append("%s %.1f dB, dip %.1f" % [sound.resource_path.get_file(), heard.x, heard.y])
	return _report(passed, "each of the man's %d own sounds on SFX dips it by %.0f dB at most:\n  %s"
			% [steady.size(), MAX_STEADY_DIP, "\n  ".join(lines)])


## Plays sound TRIES times on bus, each once the ambience is back at its level, and returns the
## loudest it got on that bus, in dB, and the smallest of its dips under the ambience's level, in dB.
func _dip_under(sound: AudioStream, bus: StringName) -> Vector2:
	var ambience: int = AudioServer.get_bus_index(AMBIENCE_BUS)
	var index: int = AudioServer.get_bus_index(bus)
	var loudest: float = -INF
	var dip: float = INF
	for _try: int in TRIES:
		_wait_until_the_ambience_is_back(ambience)
		_sound_player.stream = sound
		_sound_player.bus = bus
		_sound_player.play()
		var listen_ms: int = mini(int(sound.get_length() * 1000.0) + 200, LONGEST_MS)
		var lowest: float = INF
		for _sample: int in listen_ms / SAMPLE_MS:
			OS.delay_msec(SAMPLE_MS)
			lowest = minf(lowest, AudioServer.get_bus_peak_volume_left_db(ambience, 0))
			loudest = maxf(loudest, maxf(AudioServer.get_bus_peak_volume_left_db(index, 0),
					AudioServer.get_bus_peak_volume_right_db(index, 0)))
		_sound_player.stop()
		dip = minf(dip, _level - lowest)
	return Vector2(loudest, dip)


func _wait_until_the_ambience_is_back(ambience: int) -> void:
	for _sample: int in RECOVER_MS / SAMPLE_MS:
		OS.delay_msec(SAMPLE_MS)
		if AudioServer.get_bus_peak_volume_left_db(ambience, 0) >= _level - RECOVERED_DB:
			return


## Every sound the node at holder holds in the scene at path: in its properties, in arrays among
## them, and in the streams of its sound players. Each once.
func _sounds_in(path: String, holder: NodePath) -> Array[AudioStream]:
	var found: Array[AudioStream] = []
	var scene: PackedScene = load(path) as PackedScene
	if scene == null:
		return found
	var instance: Node = scene.instantiate()
	var node: Node = instance.get_node_or_null(holder)
	if node != null:
		var values: Array = []
		for property: Dictionary in node.get_property_list():
			var value: Variant = node.get(property["name"])
			if value is Array:
				values.append_array(value)
			else:
				values.append(value)
		for player: Node in node.find_children("*", "AudioStreamPlayer2D", true, false):
			values.append((player as AudioStreamPlayer2D).stream)
		for value: Variant in values:
			if value is AudioStream and value not in found:
				found.append(value as AudioStream)
	instance.queue_free()
	return found


## A second of a sine tone at TONE_DB, looping, so the ambience holds one level.
func _tone() -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = TONE_RATE
	var bytes := PackedByteArray()
	bytes.resize(TONE_RATE * 2)
	var amplitude: float = db_to_linear(TONE_DB) * 32767.0
	for frame: int in TONE_RATE:
		bytes.encode_s16(frame * 2, int(amplitude * sin(TAU * TONE_HZ * frame / TONE_RATE)))
	wav.data = bytes
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = TONE_RATE
	return wav


func _report(passed: bool, what: String) -> bool:
	print("%s: %s" % ["PASS" if passed else "FAIL", what])
	return passed


## Quits with exit code 0 if every case passed, and 1 otherwise.
func _finish(results: Array[bool]) -> void:
	quit(1 if results.has(false) else 0)
