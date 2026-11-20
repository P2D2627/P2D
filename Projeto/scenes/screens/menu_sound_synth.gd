class_name MenuSoundSynth
extends RefCounted

## The menus' sounds made in code, the reserve of MenuFeedback: it plays them only for a sound its
## scene leaves empty, as the recorded ones (assets/audio/ui/) fill every sound today. Stone, embers
## and iron, as the place the man wakes in. Each sound is built from layers that start together, and
## each variant from its own seed, so the same seed always gives the same sound.
## - Move, as the selection goes from one option to the next: a small stone's click, a bright
##   crack of noise over a short wooden knock, 70 ms, with nothing below about 150 Hz, so it never
##   muddies the music.
## - Confirm, as an option is chosen: a heavy blow on iron and stone, 600 ms: the crack, a dull
##   ringing of iron, a body that drops in pitch, a sub that drops from 75 to 45 Hz, and the breath
##   of a flame after it, in a short room.
## - Back, as a screen is left: the same stone, duller and falling, 220 ms, with no sub.
## Each comes out at the same peak, so a scene that plays them sets how loud each is against the
## others with its players' volumes; menu_feedback.tscn keeps those at 0 dB, as its recorded files
## hold their own mix.

## Samples per second: enough for the brightest layer (about 5 kHz) and half the work of 44.1 kHz.
const MIX_RATE: int = 32000
## Each sound's loudest sample, as a share of full scale, so the layers never clip.
const PEAK: float = 0.9


## The variant-th of variants of the selection's click, as a stream.
static func move(variant: int, variants: int) -> AudioStreamWAV:
	var rng: RandomNumberGenerator = _rng(&"move", variant)
	var length: float = 0.07
	var buffer: PackedFloat32Array = _silence(length)
	# Each variant knocks at its own pitch, spread over a fifth, so four in a row never sound alike.
	var knock_pitch: float = 900.0 * pow(1.5, float(variant) / maxf(1.0, float(variants - 1)))
	_add_noise(buffer, rng, 0.0, 0.0005, 0.006, 1800.0, 5200.0, 0.55)
	_add_tone(buffer, 0.0, 0.0005, 0.016, knock_pitch * 1.15, knock_pitch, 0.012, 0.6)
	_add_tone(buffer, 0.0, 0.0005, 0.010, knock_pitch * 2.6, knock_pitch * 2.4, 0.01, 0.15)
	_high_pass(buffer, 150.0)
	return _to_stream(buffer)


## The variant-th choice's blow, as a stream.
static func confirm(variant: int) -> AudioStreamWAV:
	var rng: RandomNumberGenerator = _rng(&"confirm", variant)
	var length: float = 0.6
	var buffer: PackedFloat32Array = _silence(length)
	var shift: float = 1.0 + 0.04 * float(variant)
	_add_noise(buffer, rng, 0.0, 0.0005, 0.010, 1000.0, 4500.0, 0.7)
	for partial: Vector2 in [Vector2(520.0, 0.11), Vector2(1310.0, 0.07), Vector2(2210.0, 0.05)]:
		_add_tone(buffer, 0.0, 0.001, 0.12, partial.x * shift, partial.x * shift, 0.1, partial.y)
	_add_tone(buffer, 0.0, 0.002, 0.09, 230.0 * shift, 160.0 * shift, 0.05, 0.75)
	_add_tone(buffer, 0.0, 0.004, 0.14, 75.0, 45.0, 0.09, 0.9)
	_add_noise(buffer, rng, 0.02, 0.03, 0.22, 200.0, 1200.0, 0.22)
	_add_room(buffer, 0.25)
	return _to_stream(buffer)


## The variant-th way back's thud, as a stream.
static func back(variant: int) -> AudioStreamWAV:
	var rng: RandomNumberGenerator = _rng(&"back", variant)
	var length: float = 0.22
	var buffer: PackedFloat32Array = _silence(length)
	var shift: float = 1.0 - 0.05 * float(variant)
	_add_noise(buffer, rng, 0.0, 0.0008, 0.018, 600.0, 1800.0, 0.45)
	_add_tone(buffer, 0.0, 0.002, 0.06, 300.0 * shift, 180.0 * shift, 0.05, 0.8)
	_high_pass(buffer, 120.0)
	_add_room(buffer, 0.15)
	return _to_stream(buffer)


## A generator seeded by the sound's name and variant, so each variant is the same on every run.
static func _rng(sound: StringName, variant: int) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(String(sound)) + variant * 7919
	return rng


static func _silence(length: float) -> PackedFloat32Array:
	var buffer: PackedFloat32Array = PackedFloat32Array()
	buffer.resize(int(length * MIX_RATE))
	return buffer


## Adds noise from start, in s, that rises over attack and dies away with decay as its time
## constant, kept to the band from low to high, in Hz, at level.
static func _add_noise(buffer: PackedFloat32Array, rng: RandomNumberGenerator, start: float,
		attack: float, decay: float, low: float, high: float, level: float) -> void:
	var low_pass_a: float = _one_pole(high)
	var floor_a: float = _one_pole(low)
	var smooth: float = 0.0
	var floor_value: float = 0.0
	for i: int in range(int(start * MIX_RATE), buffer.size()):
		var t: float = float(i) / MIX_RATE - start
		smooth += low_pass_a * (rng.randf_range(-1.0, 1.0) - smooth)
		floor_value += floor_a * (smooth - floor_value)
		buffer[i] += (smooth - floor_value) * _envelope(t, attack, decay) * level


## Adds a sine from start, in s, whose pitch falls from from_hz to to_hz with fall as its time
## constant, shaped as _add_noise's, at level.
static func _add_tone(buffer: PackedFloat32Array, start: float, attack: float, decay: float,
		from_hz: float, to_hz: float, fall: float, level: float) -> void:
	var phase: float = 0.0
	for i: int in range(int(start * MIX_RATE), buffer.size()):
		var t: float = float(i) / MIX_RATE - start
		var pitch: float = to_hz + (from_hz - to_hz) * exp(-t / fall)
		phase += TAU * pitch / MIX_RATE
		buffer[i] += sin(phase) * _envelope(t, attack, decay) * level


## A short, dark room round the sound: two echoes that feed back, at wet's share.
static func _add_room(buffer: PackedFloat32Array, wet: float) -> void:
	var dry: PackedFloat32Array = buffer.duplicate()
	for delay_s: float in [0.031, 0.047]:
		var delay: int = int(delay_s * MIX_RATE)
		var echo: PackedFloat32Array = PackedFloat32Array()
		echo.resize(buffer.size())
		var dark: float = 0.0
		var dark_a: float = _one_pole(2500.0)
		for i: int in range(delay, buffer.size()):
			dark += dark_a * ((dry[i - delay] + echo[i - delay] * 0.55) - dark)
			echo[i] = dark
		for i: int in buffer.size():
			buffer[i] += echo[i] * wet


static func _high_pass(buffer: PackedFloat32Array, cutoff: float) -> void:
	var a: float = _one_pole(cutoff)
	var low: float = 0.0
	for i: int in buffer.size():
		low += a * (buffer[i] - low)
		buffer[i] -= low


## The share of the way a one-pole filter moves each sample, for its cutoff in Hz.
static func _one_pole(cutoff: float) -> float:
	return 1.0 - exp(-TAU * cutoff / MIX_RATE)


static func _envelope(t: float, attack: float, decay: float) -> float:
	return minf(1.0, t / attack) * exp(-t / decay)


## The buffer at PEAK, faded out over its last 5 ms so it never ends on a click, as 16-bit mono.
static func _to_stream(buffer: PackedFloat32Array) -> AudioStreamWAV:
	var loudest: float = 0.0
	for value: float in buffer:
		loudest = maxf(loudest, absf(value))
	var gain: float = PEAK / loudest if loudest > 0.0 else 0.0
	var tail: int = mini(buffer.size(), int(0.005 * MIX_RATE))
	var data: PackedByteArray = PackedByteArray()
	data.resize(buffer.size() * 2)
	for i: int in buffer.size():
		var fade: float = minf(1.0, float(buffer.size() - 1 - i) / float(tail)) if tail > 0 else 1.0
		data.encode_s16(i * 2, int(clampf(buffer[i] * gain * fade, -1.0, 1.0) * 32767.0))
	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream
