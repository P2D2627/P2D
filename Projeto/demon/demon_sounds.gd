class_name DemonSounds
extends Node2D

## The demon's sounds (ADR 0040). It only listens to the demon's signals, as CrucifixSounds does the
## crucifix's, so the demon's script never touches the audio. It is a Node2D so that its 2D sound
## player follows the demon. An empty sound slot plays nothing, so the sounds not made yet only need
## their file dropped in. Each sound has a picture that goes with it, for a man who does not hear:
## DemonMark's for the alert and the search, the placeholder's hop for the bark, and its stretch
## and squash for the take-off and the landing (ADR 0042).

## What a sound tells, for the limits on how many start on one physics step.
enum Kind { NOTICE, BARK, LEAP }

## The demon whose sounds these are.
@export var demon: Demon
## How far this demon's voice is from the normal pitch, either way, picked once for each demon so
## that two of them never sound the same: 0.08 is up to 8% up or down.
@export_range(0.0, 0.5, 0.005) var voice_spread: float = 0.08
## How far each sound's pitch can move from the demon's voice, either way, each time it plays.
@export_range(0.0, 0.5, 0.005) var pitch_variation: float = 0.02
## The most alert and search sounds all the demons together start on one physics step; the others
## play none. A pack that notices the man at once is heard as one, and its marks still show which
## ones saw him; starting 50 sound players on one step cost about 2 ms on the steps after it (ADR
## 0040). Counted in physics steps, not in frames drawn: at 120 physics steps a second, or with the
## game slow enough to run two steps a frame, one frame drawn can start twice as many.
@export_range(1, 50, 1) var max_notice_sounds_per_step: int = 3
## The most barks all the demons together start on one physics step, counted apart from the alert
## and search sounds, so that barks, which only tell the man is out of reach, never silence a demon
## that has just noticed him.
@export_range(0, 50, 1) var max_barks_per_step: int = 2
## The most take-off and landing sounds all the demons together start on one physics step, counted
## apart from the others, so that a pack leaping down together is heard as one and never silences
## a demon that has just noticed the man.
@export_range(0, 50, 1) var max_leap_sounds_per_step: int = 2
## Plays the sounds. Its own stream is replaced by the sound of each moment.
@export var cue: AudioStreamPlayer2D

@export_group("Sounds")
## The demon noticing the man, with the "!".
@export var alert_sound: AudioStream
## The demon starting to search for the man, with the "?".
@export var search_sound: AudioStream
## The demon barking at a man out of its reach (ADR 0039).
@export var bark_sound: AudioStream
## The demon leaving its floor, up a step or down off its end (ADR 0042).
@export var take_off_sound: AudioStream
## The demon landing from a take-off.
@export var land_sound: AudioStream

## Shared by every demon: the physics step the last sound started on, and how many alert and search
## sounds, how many barks, and how many take-off and landing sounds started on it.
static var _sound_step: int = -1
static var _notices_on_step: int = 0
static var _barks_on_step: int = 0
static var _leaps_on_step: int = 0

## This demon's pitch, picked in _ready.
var _voice: float = 1.0
## Its own, so the sounds never take numbers from the global one, from which each demon seeds its
## own: a sound must never change what a demon does, nor a test with a fixed seed.
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	assert(demon != null, "DemonSounds: assign the Demon to Demon.")
	assert(cue != null, "DemonSounds: assign an AudioStreamPlayer2D to Cue.")
	_rng.randomize()
	_voice = 1.0 + _rng.randf_range(-voice_spread, voice_spread)
	demon.state_changed.connect(_on_demon_state_changed)
	demon.barked.connect(_on_demon_barked)
	demon.took_off.connect(_on_demon_took_off)
	demon.landed.connect(_on_demon_landed)


## The pitch this demon plays its next sound at.
func get_voice() -> float:
	return _voice


## Plays sound on the cue from the start, at the demon's voice moved a little at random, counted
## with the sounds of kind. With no sound, or with as many of its kind as its limit already started
## on this physics step, the cue keeps playing what it was.
func _play_cue(sound: AudioStream, kind: Kind) -> void:
	if sound == null:
		return
	var step: int = Engine.get_physics_frames()
	if step != _sound_step:
		_sound_step = step
		_notices_on_step = 0
		_barks_on_step = 0
		_leaps_on_step = 0
	match kind:
		Kind.NOTICE:
			if _notices_on_step >= max_notice_sounds_per_step:
				return
			_notices_on_step += 1
		Kind.BARK:
			if _barks_on_step >= max_barks_per_step:
				return
			_barks_on_step += 1
		Kind.LEAP:
			if _leaps_on_step >= max_leap_sounds_per_step:
				return
			_leaps_on_step += 1
	cue.stream = sound
	cue.pitch_scale = _voice * (1.0 + _rng.randf_range(-pitch_variation, pitch_variation))
	cue.play()


func _on_demon_state_changed(_previous: Demon.State, current: Demon.State) -> void:
	match current:
		Demon.State.ALERT:
			_play_cue(alert_sound, Kind.NOTICE)
		Demon.State.SEARCH:
			_play_cue(search_sound, Kind.NOTICE)


func _on_demon_barked(_hops: bool) -> void:
	_play_cue(bark_sound, Kind.BARK)


func _on_demon_took_off() -> void:
	_play_cue(take_off_sound, Kind.LEAP)


func _on_demon_landed() -> void:
	_play_cue(land_sound, Kind.LEAP)
