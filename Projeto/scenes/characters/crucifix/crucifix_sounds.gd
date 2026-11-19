class_name CrucifixSounds
extends Node2D

## The crucifix's sounds. It only listens to the crucifix's signals, as PlayerSounds only reads the
## player, so the crucifix's script never touches the audio. It is a Node2D so that its 2D sound
## players follow the crucifix. An empty sound slot plays nothing, so the sounds not made yet only
## need their file dropped in. Lost, the crucifix takes these sounds with it. While the crucifix
## warns that it is about to come down, the hold wavers with its light: its volume follows the
## light's share of its brightness (Crucifix.get_warning_pulse()), about 8 dB lower at the deepest
## dip. _process() only runs while the crucifix is up. The light comes on and goes out at once, so
## the raise, the holster and the available sound start a little into their files, where they are
## already loud.

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
## How far into its file the raise starts. The file swells for 120 ms to its loudest and is still
## 12 dB below it at 70 ms. 0 plays it whole.
@export_range(0.0, 0.3, 0.005, "suffix:s") var raise_start: float = 0.07
## The crucifix going down when Crucifix is let go or the player leaves the floor.
@export var holster_sound: AudioStream
## How far into its file the holster starts. The file rises for 80 ms, from 23 dB below its
## loudest, and is 13 dB below it at 30 ms. 0 plays it whole.
@export_range(0.0, 0.3, 0.005, "suffix:s") var holster_start: float = 0.03
## The crucifix going down because its charge ran out, instead of Holster Sound. It is loud from
## its first millisecond, so it plays whole.
@export var cooldown_sound: AudioStream
## The cooldown ending: the crucifix can go up again.
@export var available_sound: AudioStream
## How far into its file the available sound starts. The file stays below -50 dBFS, near-silent,
## for its first 107 ms. 0 plays it whole.
@export_range(0.0, 0.3, 0.005, "suffix:s") var available_start: float = 0.1
## A press of Crucifix during the cooldown. Meant to be the same file for every upgrade with a
## cooldown.
@export var unavailable_sound: AudioStream

## True from the raise until its sound ends, or the crucifix goes down first.
var _raise_playing: bool = false
## True from ran_out until the lowered that follows it on the same frame.
var _ran_out: bool = false
## The hold's volume as the crucifix went up, which the warning wavers down from and goes back to.
## Read then, so a volume set in the Remote tab while it is down counts.
var _hold_volume_db: float = 0.0


func _ready() -> void:
	assert(crucifix != null, "CrucifixSounds: assign the Crucifix to Crucifix.")
	assert(cue != null, "CrucifixSounds: assign an AudioStreamPlayer2D to Cue.")
	assert(hold != null, "CrucifixSounds: assign an AudioStreamPlayer2D to Hold.")
	set_process(false)
	crucifix.raised.connect(_on_raised)
	crucifix.ran_out.connect(_on_ran_out)
	crucifix.lowered.connect(_on_lowered)
	crucifix.cooldown_finished.connect(_on_cooldown_finished)
	crucifix.refused.connect(_on_refused)
	cue.finished.connect(_on_cue_finished)
	hold.finished.connect(_on_hold_finished)


## While the crucifix is up, the hold's volume follows its light: all of it until the warning.
func _process(_delta: float) -> void:
	hold.volume_db = _hold_volume_db + linear_to_db(crucifix.get_warning_pulse())


## Plays sound on the cue from from_position s into its file, with its pitch moved a little at
## random. With no sound, the cue keeps playing what it was.
func _play_cue(sound: AudioStream, from_position: float = 0.0) -> void:
	if sound == null:
		return
	cue.stream = sound
	cue.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	cue.play(from_position)


## The hold starts with no raise sound at once; otherwise when the raise ends.
func _on_raised() -> void:
	_hold_volume_db = hold.volume_db
	set_process(true)
	hold.stop()
	_raise_playing = raise_sound != null
	if _raise_playing:
		_play_cue(raise_sound, raise_start)
	else:
		hold.play()


func _on_ran_out() -> void:
	_ran_out = true


## Going down cuts the raise and the hold off, then plays the holster, or the cooldown's sound when
## the use ran out of time.
func _on_lowered() -> void:
	set_process(false)
	hold.volume_db = _hold_volume_db
	_raise_playing = false
	cue.stop()
	hold.stop()
	if _ran_out:
		_play_cue(cooldown_sound)
	else:
		_play_cue(holster_sound, holster_start)
	_ran_out = false


func _on_cooldown_finished() -> void:
	_play_cue(available_sound, available_start)


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
