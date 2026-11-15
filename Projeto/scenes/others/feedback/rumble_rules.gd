class_name RumbleRules
extends RefCounted

## The rules of the controller's vibration, apart from any node, so the tests can run them on their
## own. Each moment starts a pulse: how hard the weak motor and the strong motor run, from 0 to 1, for
## how long, and the share of that time, at its end, over which it fades to nothing, as a blow dies
## away. Each state, such as a grab, holds a sustained vibration until it ends: low and throbbing.
## While pulses overlap, each motor runs at the strongest running pulse's level, so
## moments that come together never add up past the strongest, and a weaker pulse never cuts a
## stronger one short: once the stronger ends, the weaker goes on for the rest of its own time. A
## sustained vibration counts the same way, but it gives way to a pulse on the motors the pulse runs,
## keeping only duck_share of its level there, so the pulse reads over it; on a motor the pulse leaves
## alone it runs whole, so a tick on the weak motor does not hide a strong held one. As the pulse
## fades, the sustained vibration comes back in step with it, without a jump when the pulse ends.

## The share of its level a sustained vibration keeps, on the motors a pulse runs, while that pulse
## runs at all of its own, from 0 to 1.
var duck_share: float = 0.3

var _pulses: Array[RunningPulse] = []
var _sustains: Dictionary[StringName, RunningSustain] = {}


## Starts a pulse of weak and strong for duration s, fading over the last fade of that time: a share
## from 0, level to the end, to 1, fading from the start. Each motor and the fade are kept in 0 to 1,
## and one that is not a number counts as 0. A pulse with both motors at 0, or with no time, a
## negative one, or one that is not a number or never ends, starts nothing.
func add(weak: float, strong: float, duration: float, fade: float = 0.0) -> void:
	var weak_level: float = _share(weak)
	var strong_level: float = _share(strong)
	if (weak_level == 0.0 and strong_level == 0.0) or not is_finite(duration) or duration <= 0.0:
		return
	_pulses.append(RunningPulse.new(weak_level, strong_level, duration, _share(fade)))


## Holds weak and strong for key until end_sustain(key), throbbing beat_rate times a second, down by
## beat_depth of the level and back, from the top of a throb. Called again for the same key, it
## changes the levels and the beat and keeps the throb where it was. Each motor and the depth are
## kept in 0 to 1, and one that is not a number counts as 0; a rate that is negative, not a number or
## infinite counts as 0, a flat hum. Both motors at 0 end key's sustained vibration.
func sustain(key: StringName, weak: float, strong: float, beat_rate: float,
		beat_depth: float) -> void:
	var weak_level: float = _share(weak)
	var strong_level: float = _share(strong)
	if weak_level == 0.0 and strong_level == 0.0:
		end_sustain(key)
		return
	var held: RunningSustain = _sustains.get(key)
	if held == null:
		held = RunningSustain.new()
		_sustains[key] = held
	held.weak = weak_level
	held.strong = strong_level
	held.beat_rate = beat_rate if is_finite(beat_rate) and beat_rate > 0.0 else 0.0
	held.beat_depth = _share(beat_depth)


## Ends key's sustained vibration; nothing happens if key holds none.
func end_sustain(key: StringName) -> void:
	_sustains.erase(key)


## Lets delta s go by: each pulse runs down, the ones whose time is up end, and each sustained
## vibration throbs on. The first call after a pulse starts takes no time off it, as that is the
## frame it starts on: so a pulse lasts its whole time, and up to a frame more, at any frame rate,
## and even one shorter than a frame is felt.
func advance(delta: float) -> void:
	for index: int in range(_pulses.size() - 1, -1, -1):
		var pulse: RunningPulse = _pulses[index]
		if not pulse.started:
			pulse.started = true
			continue
		pulse.time_left -= delta
		if pulse.time_left <= 0.0:
			_pulses.remove_at(index)
	for held: RunningSustain in _sustains.values():
		held.time += delta


## Both motors' levels now, from 0 to 1, the weak one in x and the strong one in y: the strongest of
## the running pulses, each at its fade's share, and, with with_sustains, of the sustained
## vibrations, each at its throb's share and, on each motor, given way to the pulses that run it: from
## all of its level with none, down to duck_share while one runs at all of its own, in step with the
## fade of the one that runs the most. 0 with none.
func get_levels(with_sustains: bool = true) -> Vector2:
	var levels: Vector2 = Vector2.ZERO
	# How much of their own level the pulses that run each motor are at, the most of them.
	var pulse_shares: Vector2 = Vector2.ZERO
	for pulse: RunningPulse in _pulses:
		var fade_share: float = pulse.get_fade_share()
		levels = levels.max(Vector2(pulse.weak, pulse.strong) * fade_share)
		if pulse.weak > 0.0:
			pulse_shares.x = maxf(pulse_shares.x, fade_share)
		if pulse.strong > 0.0:
			pulse_shares.y = maxf(pulse_shares.y, fade_share)
	if with_sustains and not _sustains.is_empty():
		var kept: float = _share(duck_share)
		var duck: Vector2 = Vector2(lerpf(1.0, kept, pulse_shares.x), lerpf(1.0, kept, pulse_shares.y))
		for held: RunningSustain in _sustains.values():
			levels = levels.max(Vector2(held.weak, held.strong) * held.get_throb_share() * duck)
	return levels


## How long until the last running pulse ends, in s; 0 with none. A sustained vibration has no end
## of its own: its state ends it.
func get_time_left() -> float:
	var time_left: float = 0.0
	for pulse: RunningPulse in _pulses:
		time_left = maxf(time_left, pulse.time_left)
	return time_left


## True while a pulse runs or a vibration is sustained.
func is_running() -> bool:
	return not _pulses.is_empty() or not _sustains.is_empty()


## True while a vibration is sustained.
func is_sustaining() -> bool:
	return not _sustains.is_empty()


## Ends every pulse and every sustained vibration at once.
func clear() -> void:
	_pulses.clear()
	_sustains.clear()


## Ends every pulse at once. The sustained vibrations go on, as their states do.
func clear_pulses() -> void:
	_pulses.clear()


## A level, a fade or a depth, kept in 0 to 1; one that is not a number counts as 0.
func _share(value: float) -> float:
	return 0.0 if is_nan(value) else clampf(value, 0.0, 1.0)


## A pulse that is running: its two motors, from 0 to 1, its whole time and the time it has left,
## in s, and the share of its time over which it fades.
class RunningPulse:
	var weak: float
	var strong: float
	var duration: float
	var time_left: float
	var fade: float
	## False until the first advance() after it starts, which takes no time off it.
	var started: bool = false

	func _init(pulse_weak: float, pulse_strong: float, pulse_duration: float,
			pulse_fade: float) -> void:
		weak = pulse_weak
		strong = pulse_strong
		duration = pulse_duration
		time_left = pulse_duration
		fade = pulse_fade

	## The share of its levels it runs at now: all of them until its fade begins, then less in a
	## straight line, down to none as its time runs out.
	func get_fade_share() -> float:
		var fade_time: float = duration * fade
		if fade_time <= 0.0 or time_left >= fade_time:
			return 1.0
		return maxf(time_left, 0.0) / fade_time


## A sustained vibration: its two motors, from 0 to 1, its throb, and how long it has run, in s.
class RunningSustain:
	var weak: float = 0.0
	var strong: float = 0.0
	var beat_rate: float = 0.0
	var beat_depth: float = 0.0
	var time: float = 0.0

	## The share of its levels it runs at now: all of them at the top of each throb, down by
	## beat_depth halfway through it, along a cosine; all of them, flat, with no rate or no depth.
	func get_throb_share() -> float:
		if beat_rate <= 0.0 or beat_depth <= 0.0:
			return 1.0
		return 1.0 - beat_depth * (0.5 - 0.5 * cos(TAU * beat_rate * time))
