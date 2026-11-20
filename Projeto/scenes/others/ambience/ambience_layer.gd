class_name AmbienceLayer
extends Node2D

## One layer of a level's ambience: one-shot sounds, such as thunder, gusts of wind or whispers,
## played one at a time, at random moments and from random places around the screen, so the
## ambience never settles into a loop the ear can learn. A level takes one layer per kind of sound,
## each with its own gaps. The long beds under them, such as a steady wind, are AmbienceBed nodes.
## Some sounds keep their own stereo instead: Unpanned Sounds, such as a gust whose sweep from one
## side to the other is already in the file, or a rumble mixed to the centre, play as they are,
## with no place and no panning of Godot's.
## A placed sound keeps its place on the screen while it plays (Follow Screen), so it neither falls
## behind nor pans away as the camera moves on: the ambience is all round the man, wherever he goes.
## It counts down in its frame, so whatever stops its frame stops it too: inside a level, under the
## LevelSlot, the pause holds both the countdown and the sound playing.

## A sound started to play from position, in the world, travelling across the screen as travel
## says: 1 from left to right, -1 from right to left, 0 neither. An unpanned sound travels as
## Unpanned Travel says, from the centre of the screen; a placed one from its side of the screen
## towards the other, as a gust heard on the left blows to the right. A lightning flash, a camera
## shake or embers in the wind can follow it.
signal sound_played(position: Vector2, travel: int)

## Which way the unpanned sounds travel across the screen, as their own panning carries them.
enum Travel { NONE, LEFT_TO_RIGHT, RIGHT_TO_LEFT }

## The sounds to pick from. An AudioStreamRandomizer with Playback Mode Random (Avoid Repetitions)
## picks a different one each time and varies its pitch and its volume, with Random Pitch and
## Random Volume Offset dB. It replaces the stream of Player.
@export var sounds: AudioStream
## Plays the sounds. Its bus, its Max Distance and its Attenuation are set in it. A new sound moves
## it, so keep Min Gap longer than the longest sound, or the tail of the last one jumps with it.
@export var player: AudioStreamPlayer2D
## A placed sound keeps its place on the screen while it plays, as the camera moves on. Off, it stays
## where it began in the world, and the man leaves it behind.
@export var follow_screen: bool = true
## The bus both players play on, such as one whose sound turns the beds down (the gusts'); empty,
## their own.
@export var bus: StringName = &""
## Starts the countdown to the first sound on entering the tree. Without it, the layer waits for
## start(), from a zone or an event.
@export var autostart: bool = true

@export_group("Unpanned")
## Sounds that keep their own stereo: Godot neither places them nor pans them. An
## AudioStreamRandomizer can hold several. It replaces the stream of Unpanned Player.
@export var unpanned_sounds: AudioStream
## Plays the unpanned sounds, as they are: not a 2D player, so neither the camera nor a distance
## changes them. Its bus and its volume are set in it; -6 dB matches a 2D sound at the centre of
## the screen, which Godot plays at half in each speaker.
@export var unpanned_player: AudioStreamPlayer
## The share of the sounds that come from Unpanned Sounds when there are Sounds too. Two unpanned
## sounds never play in a row, so it goes up to one in two. Without Sounds, every sound is unpanned.
@export_range(0.0, 0.5, 0.01) var unpanned_share: float = 0.33
## Which way the unpanned sounds travel across the screen, told with sound_played.
@export var unpanned_travel: Travel = Travel.NONE
## Pans each unpanned sound to a side picked at random, as far as a pan picked between x and y
## (0 the centre, 1 all in one speaker), through the Panner on Unpanned Player's bus (BusPan): the
## sound keeps its own stereo, moved to that side, and travels from it towards the other. 0 and 0
## leave the unpanned sounds as they are. The panner pans all the bus plays, so keep Min Gap
## longer than the longest sound.
@export var side_pan: Vector2 = Vector2.ZERO

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
## Whether the last sound was an unpanned one, so the next is not.
var _last_unpanned: bool = false
## Whether the countdown runs, and whether a placed sound playing keeps Offset from the centre of
## the screen.
var _running: bool = false
var _following: bool = false
var _offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	set_process(false)
	if player != null and sounds != null:
		player.stream = sounds
	if unpanned_player != null and unpanned_sounds != null:
		unpanned_player.stream = unpanned_sounds
	if bus != &"" and player != null:
		player.bus = bus
	if bus != &"" and unpanned_player != null:
		unpanned_player.bus = bus
	if not _has_placed() and not _has_unpanned():
		push_warning("AmbienceLayer %s: no Sounds or Unpanned Sounds, with their player, to play."
				% name)
	if _side_panned() and BusPan.panner_of(unpanned_player.bus) == null:
		push_warning("AmbienceLayer %s: Side Pan is set, but the bus %s has no Panner."
				% [name, unpanned_player.bus])
	if autostart:
		start()


func _process(delta: float) -> void:
	# Before the countdown: a sound started on this frame is not playing yet (a 2D player starts it in
	# its physics step), and must not end the following.
	if _following:
		if player.playing:
			player.global_position = _screen_centre() + _offset
		else:
			_following = false
	if _running:
		_time_left -= delta
		if _time_left <= 0.0:
			_play_one()
			_time_left = _next_gap()
	if not _running and not _following:
		set_process(false)


## Starts the countdown to the next sound, from a whole gap. A layer already playing starts over.
func start() -> void:
	_time_left = _next_gap()
	_running = true
	set_process(true)


## Stops new sounds; the one playing ends on its own.
func stop() -> void:
	_running = false


func is_running() -> bool:
	return _running


func _play_one() -> void:
	if _next_is_unpanned():
		_last_unpanned = true
		var travel: int = _unpanned_travel_sign()
		if _side_panned():
			var side: float = -1.0 if randf() < 0.5 else 1.0
			BusPan.set_pan(unpanned_player.bus, side * randf_range(minf(side_pan.x, side_pan.y),
					maxf(side_pan.x, side_pan.y)))
			# From its side towards the other, as a placed sound.
			travel = -int(side)
		unpanned_player.play()
		sound_played.emit(_screen_centre(), travel)
		return
	if not _has_placed():
		return
	_last_unpanned = false
	var offset := Vector2(randf_range(-horizontal_spread, horizontal_spread),
			randf_range(-vertical_spread, vertical_spread))
	player.global_position = _screen_centre() + offset
	player.play()
	_offset = offset
	_following = follow_screen
	# From its side towards the other: heard on the left (offset below 0), it travels to the right.
	sound_played.emit(player.global_position, -int(signf(offset.x)))


## Whether the next sound comes from Unpanned Sounds. After a placed one, at odds of
## share / (1 - share), and never after an unpanned one: in the long run, Unpanned Share of the
## sounds, since q / (1 + q) is share for q = share / (1 - share).
func _next_is_unpanned() -> bool:
	if not _has_unpanned():
		return false
	if not _has_placed():
		return true
	if _last_unpanned:
		return false
	var share: float = clampf(unpanned_share, 0.0, 0.5)
	return randf() < share / (1.0 - share)


func _has_placed() -> bool:
	return player != null and sounds != null


func _has_unpanned() -> bool:
	return unpanned_player != null and unpanned_sounds != null


## Whether the unpanned sounds are panned to a side: Side Pan is not 0 and 0.
func _side_panned() -> bool:
	return _has_unpanned() and maxf(side_pan.x, side_pan.y) > 0.0


func _unpanned_travel_sign() -> int:
	match unpanned_travel:
		Travel.LEFT_TO_RIGHT:
			return 1
		Travel.RIGHT_TO_LEFT:
			return -1
	return 0


func _next_gap() -> float:
	return randf_range(minf(min_gap, max_gap), maxf(min_gap, max_gap))


## The centre of what the camera shows, where the sounds are heard from; without a camera, the
## layer itself.
func _screen_centre() -> Vector2:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return global_position
	return camera.get_screen_center_position()
