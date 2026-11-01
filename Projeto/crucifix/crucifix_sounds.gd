class_name CrucifixSounds
extends Node2D

## The crucifix's sounds. It only listens to the crucifix's signals, as PlayerSounds only reads the
## player, so the crucifix's script never touches the audio. It is a Node2D so that its 2D sound
## players follow the crucifix. An empty sound slot plays nothing, so the sounds not made yet only
## need their file dropped in. Lost, the crucifix takes these sounds with it.

## The crucifix whose sounds these are.
@export var crucifix: Crucifix
## How far each one-off sound's pitch can move from the normal, either way, each time it plays:
## 0.05 is 5% up or down. The hold keeps its pitch.
@export_range(0.0, 0.5, 0.005) var pitch_variation: float = 0.0015
## Plays the one-off sounds. Its own stream is replaced by the sound of each moment.
@export var cue: AudioStreamPlayer2D
## Plays its stream over and over while the crucifix is up, from the end of Raise Sound. Seamless
## when the file is imported with Loop Mode Forward; otherwise it starts again each time it ends.
@export var hold: AudioStreamPlayer2D

@export_group("Sounds")
## The crucifix going up. The hold follows once it ends.
@export var raise_sound: AudioStream
## The crucifix going down when Crucifix is let go or the player leaves the floor.
@export var holster_sound: AudioStream
## The crucifix going down because the use ran out of Max Use Time, instead of Holster Sound.
@export var cooldown_sound: AudioStream
## The cooldown ending: the crucifix can go up again.
@export var available_sound: AudioStream
## A press of Crucifix during the cooldown. Meant to be the same file for every upgrade with a
## cooldown.
@export var unavailable_sound: AudioStream

## True from the raise until its sound ends, or the crucifix goes down first.
var _raise_playing: bool = false
## True from ran_out until the lowered that follows it on the same frame.
var _ran_out: bool = false


func _ready() -> void:
	assert(crucifix != null, "CrucifixSounds: assign the Crucifix to Crucifix.")
	assert(cue != null, "CrucifixSounds: assign an AudioStreamPlayer2D to Cue.")
	assert(hold != null, "CrucifixSounds: assign an AudioStreamPlayer2D to Hold.")
	crucifix.raised.connect(_on_raised)
	crucifix.ran_out.connect(_on_ran_out)
	crucifix.lowered.connect(_on_lowered)
	crucifix.cooldown_finished.connect(_on_cooldown_finished)
	crucifix.refused.connect(_on_refused)
	cue.finished.connect(_on_cue_finished)
	hold.finished.connect(_on_hold_finished)


## Plays sound on the cue from the start, with its pitch moved a little at random. With no sound,
## the cue keeps playing what it was.
func _play_cue(sound: AudioStream) -> void:
	if sound == null:
		return
	cue.stream = sound
	cue.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	cue.play()


## The hold starts with no raise sound at once; otherwise when the raise ends.
func _on_raised() -> void:
	hold.stop()
	_raise_playing = raise_sound != null
	if _raise_playing:
		_play_cue(raise_sound)
	else:
		hold.play()


func _on_ran_out() -> void:
	_ran_out = true


## Going down cuts the raise and the hold off, then plays the holster, or the cooldown's sound when
## the use ran out of time.
func _on_lowered() -> void:
	_raise_playing = false
	cue.stop()
	hold.stop()
	var sound: AudioStream = cooldown_sound if _ran_out else holster_sound
	_ran_out = false
	_play_cue(sound)


func _on_cooldown_finished() -> void:
	_play_cue(available_sound)


func _on_refused() -> void:
	_play_cue(unavailable_sound)


func _on_cue_finished() -> void:
	if _raise_playing:
		_raise_playing = false
		if crucifix.is_raised():
			hold.play()


## Only called when the file is not imported as a loop.
func _on_hold_finished() -> void:
	if crucifix.is_raised():
		hold.play()
