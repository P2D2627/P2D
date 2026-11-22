class_name ThunderLayer
extends Node

## The thunder of a storm out of sight. Now and then, at random, a lightning flash lights the sky on
## one side of the screen, and its thunder follows, Thunder Delay seconds later, from the same side:
## the light comes first, as it does over the distance a storm is away. Each strike, its sound and
## its flash, is picked at random from Strikes, at a pitch that varies a little each time, and
## panned Pan to its side through the panner on Player's bus (BusPan), so it keeps its own stereo.
## What draws the flash is not here: lightning_struck tells it, and a LightningFlash, or any node
## that replaces it, draws it.
## It counts down in its frame, so whatever stops its frame stops it too: inside a level, under the
## LevelSlot, the pause holds the countdown, the thunder still to come and the sound playing.

## A flash begins, on side: -1 the left of the screen, 1 the right. Its thunder follows.
signal lightning_struck(strike: ThunderStrike, side: int)
## The thunder of a strike begins to play, panned to side.
signal thunder_played(strike: ThunderStrike, side: int)

## The strikes to pick from, at random.
@export var strikes: Array[ThunderStrike] = []
## Plays the thunders: not a 2D player, so neither the camera nor a distance changes them. Its
## volume is set in it; its bus needs a Panner effect, which Pan sets before each thunder.
@export var player: AudioStreamPlayer
## The bus Player plays on, with its Panner; empty, its own.
@export var bus: StringName = &""
## Starts the countdown to the first flash on entering the tree. Without it, the layer waits for
## start(), from a zone or an event.
@export var autostart: bool = true
## Never the same strike twice in a row.
@export var avoid_repeats: bool = false

@export_group("Timing")
## The shortest and the longest wait from one flash to the next, and from start() to the first:
## each wait is picked at random between the two. Keep Min Gap longer than the longest Thunder
## Delay plus the longest thunder, so two thunders never share the bus's panner.
@export_range(0.5, 300.0, 0.5, "suffix:s") var min_gap: float = 26.0
@export_range(0.5, 300.0, 0.5, "suffix:s") var max_gap: float = 38.0
## How long after its flash a thunder comes, from the shortest (x) to the longest (y), in s.
@export var thunder_delay: Vector2 = Vector2(2.0, 6.0)

@export_group("Sound")
## How far to its side a thunder is panned, from 0 (the centre) to 1 (all in one speaker).
@export_range(0.0, 1.0, 0.01) var pan: float = 0.35
## How far the pitch varies, as an AudioStreamRandomizer's Random Pitch: each thunder plays at a
## pitch between 1 / Random Pitch and Random Pitch. 1 leaves it as it is.
@export_range(1.0, 2.0, 0.005) var random_pitch: float = 1.04

## Seconds until the next flash, and whether the countdown runs.
var _time_left: float = 0.0
var _running: bool = false
## The strike whose thunder is still to come, its side and the seconds until it plays.
var _coming: ThunderStrike = null
var _coming_side: int = 0
var _thunder_in: float = 0.0
## The last strike, so the next is not the same with Avoid Repeats.
var _last: ThunderStrike = null


func _ready() -> void:
	set_process(false)
	if player != null and bus != &"":
		player.bus = bus
	if player == null or _playable().is_empty():
		push_warning("ThunderLayer %s: no Strikes with a sound, or no Player, to play." % name)
	elif BusPan.panner_of(player.bus) == null:
		push_warning("ThunderLayer %s: the bus %s has no Panner; the thunders play in the centre."
				% [name, player.bus])
	if minf(min_gap, max_gap) < maxf(thunder_delay.x, thunder_delay.y) + _longest_sound():
		push_warning("ThunderLayer %s: Min Gap is shorter than the longest Thunder Delay plus the "
				% name + "longest thunder; two thunders may share the panner.")
	if autostart:
		start()


func _process(delta: float) -> void:
	if _coming != null:
		_thunder_in -= delta
		if _thunder_in <= 0.0:
			_play_thunder()
	if _running:
		_time_left -= delta
		if _time_left <= 0.0:
			strike_now()
			_time_left = _next_gap()
	if not _running and _coming == null:
		set_process(false)


## Starts the countdown to the next flash, from a whole gap. A layer already running starts over.
func start() -> void:
	_time_left = _next_gap()
	_running = true
	set_process(true)


## Stops new flashes; a thunder still to come comes, and the one playing ends on its own.
func stop() -> void:
	_running = false


func is_running() -> bool:
	return _running


## Whether a flash has been seen whose thunder is still to come.
func is_thunder_coming() -> bool:
	return _coming != null


## A flash now, on a side picked at random (-1 the left, 1 the right) or on side, and its thunder
## Thunder Delay seconds later. A thunder still to come plays at once, before the new flash. The
## countdown to the next flash goes on as it was.
func strike_now(side: int = 0) -> void:
	var playable: Array[ThunderStrike] = _playable()
	if playable.is_empty():
		return
	if _coming != null:
		_play_thunder()
	var choices: Array[ThunderStrike] = playable
	if avoid_repeats and playable.size() > 1:
		choices = playable.filter(func(option: ThunderStrike) -> bool: return option != _last)
	var strike: ThunderStrike = choices.pick_random()
	_last = strike
	var way: int = signi(side)
	if way == 0:
		way = -1 if randf() < 0.5 else 1
	_coming = strike
	_coming_side = way
	_thunder_in = randf_range(minf(thunder_delay.x, thunder_delay.y),
			maxf(thunder_delay.x, thunder_delay.y))
	set_process(true)
	lightning_struck.emit(strike, way)


func _play_thunder() -> void:
	var strike: ThunderStrike = _coming
	var side: int = _coming_side
	_coming = null
	BusPan.set_pan(player.bus, side * pan)
	player.stream = strike.sound
	player.pitch_scale = pow(maxf(random_pitch, 1.0), randf_range(-1.0, 1.0))
	player.play()
	thunder_played.emit(strike, side)


func _playable() -> Array[ThunderStrike]:
	return strikes.filter(func(strike: ThunderStrike) -> bool:
			return strike != null and strike.sound != null)


## The longest thunder at the lowest pitch, in s.
func _longest_sound() -> float:
	var longest: float = 0.0
	for strike: ThunderStrike in _playable():
		longest = maxf(longest, strike.sound.get_length())
	return longest * maxf(random_pitch, 1.0)


func _next_gap() -> float:
	return randf_range(minf(min_gap, max_gap), maxf(min_gap, max_gap))
