class_name AmbienceBed
extends Node

## A level's steady ambience: one long sound, played pass after pass under the one-shot layers.
## A level takes two or more beds of different lengths, which play together and rarely line up the
## same way twice. A pass does not loop the file: it runs from Loop Start to Loop End, and the next
## pass starts on the other player Crossfade seconds before that, so the two overlap and cross-fade.
## Loop Start and Loop End skip a file's own fade-in, fade-out and silent tail, so a file needs no
## seamless loop. The bed's volume also drifts slowly between Quiet dB and Loud dB, so it breathes
## instead of sitting at one level.
## It counts in its frame, so the pause holds it too: inside a level, under the LevelSlot. It counts
## in real time, not the game's, because the audio keeps playing through the hitstop of a death.

## The most real time one frame counts for, in seconds. On the frame the game's time scale changes,
## the frame's delta still has the old scale, so delta / Engine.time_scale can come out far too long
## (0.83 s as the hitstop's 0.02 begins, at 60 frames a second).
const MAX_STEP: float = 0.1

## The sound of the bed: a long one, such as wind, ideally an Ogg Vorbis file, which streams from
## disk. It replaces the stream of both players.
@export var sound: AudioStream
## The two players a pass takes turns on, so one can fade out while the next fades in. Their bus is
## set in them; their volume is the bed's.
@export var first_player: AudioStreamPlayer
@export var second_player: AudioStreamPlayer
## The bus both players play on, such as one that a compressor turns down under the gusts; empty,
## their own.
@export var bus: StringName = &""
## Fades the bed in on entering the tree. Without it, the bed waits for start().
@export var autostart: bool = true
## The first pass after start() begins at a random point of the loop, so a level never opens on
## the same second of the sound, and two beds start out of step.
@export var random_start: bool = true

@export_group("Loop")
## Where each pass after the first starts, in seconds from the start of the file: past its fade-in.
@export_range(0.0, 600.0, 0.1, "suffix:s") var loop_start: float = 0.0
## Where each pass ends, in seconds from the start of the file: before its fade-out and silent
## tail. 0, or past the end, is the end of the file.
@export_range(0.0, 600.0, 0.1, "suffix:s") var loop_end: float = 0.0
## How long a pass and the next play together, one fading out as the other fades in. At most half
## of the loop.
@export_range(0.0, 30.0, 0.1, "suffix:s") var crossfade: float = 3.0

@export_group("Volume")
## The lowest and the highest the drift takes the bed's volume.
@export_range(-60.0, 0.0, 0.5, "suffix:dB") var quiet_db: float = -12.0
@export_range(-60.0, 0.0, 0.5, "suffix:dB") var loud_db: float = -4.0
## How fast the volume drifts: about one swell every 1 / Drift Rate seconds. 0 keeps it halfway.
@export_range(0.0, 2.0, 0.005, "suffix:Hz") var drift_rate: float = 0.08
## How long start() takes to bring the bed in, and stop() to take it out.
@export_range(0.0, 30.0, 0.1, "suffix:s") var fade_time: float = 4.0

## The two passes, one on each player; _current is the newest.
var _passes: Array[Pass] = []
var _current: int = 0
## The share of the volume the bed is at, from 0 (out) to 1 (in), and the one it is heading to.
var _share: float = 0.0
var _target_share: float = 0.0
## Real seconds the bed has played, which the drift follows.
var _clock: float = 0.0
var _drift := FastNoiseLite.new()


## One run of the sound on one of the two players, from where it started to Loop End.
class Pass:
	var player: AudioStreamPlayer
	var playing: bool = false
	## Seconds since the pass started, and how long it lasts.
	var age: float = 0.0
	var length: float = 0.0
	## Whether it fades in over Crossfade: every pass but the first after start().
	var fades_in: bool = false

	func _init(on: AudioStreamPlayer) -> void:
		player = on


func _ready() -> void:
	set_process(false)
	# Smooth swells with no finer detail: the sound itself already has its gusts.
	_drift.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_drift.fractal_type = FastNoiseLite.FRACTAL_NONE
	_drift.frequency = 1.0
	_drift.seed = randi()
	if first_player == null or second_player == null:
		push_warning("AmbienceBed %s: it needs both players." % name)
		return
	_passes = [Pass.new(first_player), Pass.new(second_player)]
	for run: Pass in _passes:
		run.player.volume_linear = 0.0
		run.player.stream = sound
		if bus != &"":
			run.player.bus = bus
	if sound == null:
		push_warning("AmbienceBed %s: no Sound to play." % name)
		return
	if autostart:
		start()


func _process(delta: float) -> void:
	var step: float = minf(delta / Engine.time_scale, MAX_STEP) if Engine.time_scale > 0.0 else 0.0
	_clock += step
	if fade_time > 0.0:
		_share = move_toward(_share, _target_share, step / fade_time)
	else:
		_share = _target_share
	for run: Pass in _passes:
		if run.playing:
			run.age += step
			if run.age >= run.length:
				_end_pass(run)
	var newest: Pass = _passes[_current]
	var overlap: float = _crossfade()
	if newest.playing and newest.age >= newest.length - overlap:
		var next: int = 1 - _current
		_begin_pass(next, loop_start, true)
		# It starts as far into its fade-in as the last one is into its fade-out, so the two match.
		_passes[next].age = newest.age - (newest.length - overlap)
	var drift: float = db_to_linear(_drift_db())
	for run: Pass in _passes:
		if run.playing:
			run.player.volume_linear = drift * _share * _pass_share(run, overlap)
	if _target_share == 0.0 and _share == 0.0:
		for run: Pass in _passes:
			_end_pass(run)
		set_process(false)


## Fades the bed in, from a random point of the loop if Random Start is on. A bed fading out comes
## back from where it is.
func start() -> void:
	if _passes.is_empty() or sound == null:
		return
	if get_pass_period() <= 0.0:
		push_warning("AmbienceBed %s: Loop End must come after Loop Start." % name)
		return
	_target_share = 1.0
	if not _passes[0].playing and not _passes[1].playing:
		var from: float = loop_start
		if random_start:
			from = randf_range(loop_start, _loop_end() - _crossfade())
		_begin_pass(0, from, false)
	set_process(true)


## Fades the bed out over Fade Time, then silences it.
func stop() -> void:
	_target_share = 0.0


## Whether the bed is in, or fading in: false from stop() on.
func is_running() -> bool:
	return _target_share > 0.0 and is_processing()


## Seconds from the start of one pass to the start of the next: what decides how often the bed
## repeats, and how rarely two beds line up. 0 without a sound.
func get_pass_period() -> float:
	if sound == null:
		return 0.0
	return _loop_end() - loop_start - _crossfade()


func _begin_pass(index: int, from: float, fades_in: bool) -> void:
	var run: Pass = _passes[index]
	run.age = 0.0
	run.length = _loop_end() - from
	run.fades_in = fades_in
	run.playing = true
	run.player.volume_linear = 0.0
	run.player.play(from)
	_current = index


func _end_pass(run: Pass) -> void:
	run.playing = false
	run.player.stop()


## A pass's share of the volume: rising over its first Crossfade seconds if it fades in, and
## falling over its last. Sine and cosine, so two overlapping passes keep the power steady.
func _pass_share(run: Pass, overlap: float) -> float:
	if overlap <= 0.0:
		return 1.0
	var share: float = cos(clampf((run.age - (run.length - overlap)) / overlap, 0.0, 1.0) * PI * 0.5)
	if run.fades_in:
		share *= sin(clampf(run.age / overlap, 0.0, 1.0) * PI * 0.5)
	return share


func _drift_db() -> float:
	var weight: float = (_drift.get_noise_1d(_clock * drift_rate) + 1.0) * 0.5
	return lerpf(quiet_db, loud_db, weight)


func _loop_end() -> float:
	var length: float = sound.get_length()
	if loop_end <= 0.0 or loop_end > length:
		return length
	return loop_end


func _crossfade() -> float:
	return minf(crossfade, maxf(_loop_end() - loop_start, 0.0) * 0.5)
