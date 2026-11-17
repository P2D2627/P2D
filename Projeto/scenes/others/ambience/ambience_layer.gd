class_name AmbienceLayer
extends Node2D

## One layer of a level's ambience: one-shot sounds, such as thunder, gusts of wind or whispers,
## played one at a time, at random moments and from random places around the screen, so the
## ambience never settles into a loop the ear can learn. A level takes one layer per kind of sound,
## each with its own gaps. The long beds under them, such as a steady wind, are plain looping sound
## players on the Ambience bus and need no script.
## It counts down in its frame, so whatever stops its frame stops it too: inside a level, under the
## LevelSlot, the pause holds both the countdown and the sound playing.

## A sound started to play from position, in the world. A lightning flash or a camera shake can
## follow it.
signal sound_played(position: Vector2)

## The sounds to pick from. An AudioStreamRandomizer with Playback Mode Random (Avoid Repetitions)
## picks a different one each time and varies its pitch and its volume, with Random Pitch and
## Random Volume Offset dB. It replaces the stream of Player.
@export var sounds: AudioStream
## Plays the sounds. Its bus, its Max Distance and its Attenuation are set in it. A new sound moves
## it, so keep Min Gap longer than the longest sound, or the tail of the last one jumps with it.
@export var player: AudioStreamPlayer2D
## Starts the countdown to the first sound on entering the tree. Without it, the layer waits for
## start(), from a zone or an event.
@export var autostart: bool = true

@export_group("Timing")
## The shortest wait from the start of one sound to the start of the next, and from start() to the
## first.
@export_range(0.5, 300.0, 0.5, "suffix:s") var min_gap: float = 8.0
## The longest wait from the start of one sound to the start of the next. Each wait is picked at
## random between the two.
@export_range(0.5, 300.0, 0.5, "suffix:s") var max_gap: float = 25.0

@export_group("Placement")
## How far to either side of the centre of the screen a sound can come from. Further to a side is
## further into that speaker, and quieter; past Player's Max Distance it is silent.
@export_range(0.0, 3000.0, 10.0, "suffix:px") var horizontal_spread: float = 900.0
## How far above or below the centre of the screen a sound can come from. It only changes how far
## away the sound is, and so how loud.
@export_range(0.0, 3000.0, 10.0, "suffix:px") var vertical_spread: float = 300.0

## Seconds until the next sound plays.
var _time_left: float = 0.0


func _ready() -> void:
	set_process(false)
	if player == null:
		push_warning("AmbienceLayer %s: no Player to play the sounds." % name)
		return
	if sounds == null:
		push_warning("AmbienceLayer %s: no Sounds to play." % name)
	else:
		player.stream = sounds
	if autostart:
		start()


func _process(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		_play_one()
		_time_left = _next_gap()


## Starts the countdown to the next sound, from a whole gap. A layer already playing starts over.
func start() -> void:
	_time_left = _next_gap()
	set_process(true)


## Stops new sounds; the one playing ends on its own.
func stop() -> void:
	set_process(false)


func is_running() -> bool:
	return is_processing()


func _play_one() -> void:
	if player == null or sounds == null:
		return
	var offset := Vector2(randf_range(-horizontal_spread, horizontal_spread),
			randf_range(-vertical_spread, vertical_spread))
	player.global_position = _screen_centre() + offset
	player.play()
	sound_played.emit(player.global_position)


func _next_gap() -> float:
	return randf_range(minf(min_gap, max_gap), maxf(min_gap, max_gap))


## The centre of what the camera shows, where the sounds are heard from; without a camera, the
## layer itself.
func _screen_centre() -> Vector2:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return global_position
	return camera.get_screen_center_position()
