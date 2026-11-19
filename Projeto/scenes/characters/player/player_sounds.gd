class_name PlayerSounds
extends Node2D

## The sounds the player makes. It only reads the player, as the debug overlay does, so the player's
## script never touches the audio. Its physics frame runs after the player's, because it is a child
## of it, so it reads the state and the velocity the player's last move_and_slide() left. It is a
## Node2D so that its 2D sound players follow the player: under a plain Node they stay at the world
## origin and go silent past their Max Distance.

## A step was heard: sound_index is its place in footstep_sounds. Dust or a camera bob can follow it.
signal footstep_played(sound_index: int)
## A jump, off the floor or off a wall, was heard.
signal jump_played
## A landing was heard: hard after a fall of hard_land_height or more, soft after a shorter one.
## get_last_landing_share() says how hard, from 0 to 1.
signal land_played(hard: bool)

## The player whose sounds these are.
@export var player: Player
## How far every sound's pitch can move from the normal, either way, each time it plays: 0.05 is 5%
## up or down. Without it, the same sound over and over sounds mechanical.
@export_range(0.0, 0.5, 0.005) var pitch_variation: float = 0.05
## Plays over and over while the player slides down a wall.
@export var wall_slide: AudioStreamPlayer2D

@export_group("Footsteps")
## Plays the footsteps. Its own stream is replaced by one of Footstep Sounds on each step.
@export var footstep: AudioStreamPlayer2D
## Where the steps come from: a step plays each time its walk plants a foot, so the sound lands with
## the drawing. How far apart they are, and where the first one falls, is the walk cycle's, there.
@export var animation: PlayerAnimation
## The step sounds. Each step picks one at random, never the same as the step before. Each file
## holds one impact, and all are as loud as each other: a second impact in a file sounds as an extra
## step between the drawn ones, and a quieter file is lost under the ambience while the rest are
## heard.
@export var footstep_sounds: Array[AudioStream] = []
## The steps' volume. Set here and not on Footstep, whose own volume each step replaces with this
## one and its variation. Measured in level 1, a step reaches the SFX bus 8 to 13 dB below its file:
## the distance to the middle of the screen takes 2 to 5 dB, and the 2D panning about 6 more, since
## Godot plays a centred 2D sound at half its level in each speaker.
@export_range(-24.0, 12.0, 0.5, "suffix:dB") var footstep_volume_db: float = 0.0
## How far each step's amplitude can move from Footstep Volume, either way: 0.01 is 1% up or down.
@export_range(0.0, 0.5, 0.005) var footstep_volume_variation: float = 0.01

@export_group("Jump and landing")
## Plays the jump, off the floor and off a wall, with the stream set in it.
@export var jump: AudioStreamPlayer2D
## How far into its file the jump starts. The file rises for 60 ms to its loudest (its first 10 ms
## are 23 dB below it), so from 0 the loud part comes after he has left the floor. 0 plays it whole.
@export_range(0.0, 0.2, 0.005, "suffix:s") var jump_start: float = 0.03
## Plays the landings. Its own stream is replaced by the soft or a hard landing each time.
@export var land: AudioStreamPlayer2D
## The landing after a short fall, such as a normal jump.
@export var soft_land_sound: AudioStream
## The landings after a long fall. Each picks one at random.
@export var hard_land_sounds: Array[AudioStream] = []
## How far the player must fall, from the highest point in the air or from the wall it left, for a
## hard landing. The fall height, not the speed: the fall reaches Max Fall Speed after about 125 px,
## so a normal jump (240 px) already lands at full speed.
@export_range(0.0, 3000.0, 10.0, "suffix:px") var hard_land_height: float = 480.0
## Falls shorter than this land without a sound, such as the first frames of a level. Coming down
## off a wall always lands with a sound, however short the last drop.
@export_range(0.0, 200.0, 1.0, "suffix:px") var min_land_height: float = 16.0

## The index in footstep_sounds of the last step played, -1 before the first.
var _last_footstep_index: int = -1
## The highest y of the current fall: the player's y on the floor or on a wall, and the smallest y
## reached in the air since (y grows downwards).
var _fall_top_y: float = 0.0
## True while the current fall came off a wall: the player was on one and has not touched the floor.
var _fall_from_wall: bool = false
## How hard the last landing heard was, from 0 to 1 (get_last_landing_share()).
var _last_landing_share: float = 0.0


func _ready() -> void:
	assert(player != null, "PlayerSounds: assign the Player to Player.")
	assert(wall_slide != null, "PlayerSounds: assign an AudioStreamPlayer2D to Wall Slide.")
	assert(footstep != null, "PlayerSounds: assign an AudioStreamPlayer2D to Footstep.")
	assert(animation != null, "PlayerSounds: assign the PlayerAnimation to Animation.")
	assert(not footstep_sounds.is_empty(), "PlayerSounds: add the step sounds to Footstep Sounds.")
	assert(jump != null, "PlayerSounds: assign an AudioStreamPlayer2D to Jump.")
	assert(land != null, "PlayerSounds: assign an AudioStreamPlayer2D to Land.")
	assert(soft_land_sound != null, "PlayerSounds: assign the soft landing to Soft Land Sound.")
	assert(not hard_land_sounds.is_empty(), "PlayerSounds: add the hard landings to Hard Land Sounds.")
	# The file is not imported as a loop, so the sound starts again each time it ends while the
	# slide goes on.
	wall_slide.finished.connect(_on_wall_slide_finished)
	# Both signals also give how late and how buffered the jump was, which the sound does not need.
	player.jumped.connect(_on_jumped.unbind(2))
	player.wall_jumped.connect(_on_jumped.unbind(2))
	player.landed.connect(_on_landed)
	animation.stepped.connect(_play_footstep)
	_fall_top_y = player.global_position.y


func _physics_process(_delta: float) -> void:
	_update_fall_top()
	_update_wall_slide()


## On the floor or on a wall the fall starts again from where the player is, so sliding down a wall
## and landing is a short fall; in the air it keeps the highest point. Grabbed, he is on the floor
## or in the air by where his feet are.
func _update_fall_top() -> void:
	var y: float = player.global_position.y
	var state: Player.State = player.get_state()
	if state == Player.State.GRABBED:
		state = Player.State.ON_FLOOR if player.is_standing() else Player.State.IN_AIR
	match state:
		Player.State.IN_AIR:
			_fall_top_y = minf(_fall_top_y, y)
		Player.State.ON_WALL:
			_fall_top_y = y
			_fall_from_wall = true
		Player.State.ON_FLOOR:
			_fall_top_y = y
			_fall_from_wall = false


func _update_wall_slide() -> void:
	if _is_sliding_down_a_wall():
		if not wall_slide.playing:
			_play(wall_slide)
	elif wall_slide.playing:
		wall_slide.stop()


## One of the step sounds at random, never the last one again, with its pitch and amplitude moved a
## little at random so the repetition does not tire.
func _play_footstep() -> void:
	var index: int = _next_footstep_index()
	footstep.stream = footstep_sounds[index]
	footstep.volume_linear = db_to_linear(footstep_volume_db) * (1.0
			+ randf_range(-footstep_volume_variation, footstep_volume_variation))
	_play(footstep)
	footstep_played.emit(index)


## A random index in footstep_sounds other than the last one played, when there are two or more.
func _next_footstep_index() -> int:
	var count: int = footstep_sounds.size()
	if count == 1:
		return 0
	# Picks among the others, then skips over the last one.
	var index: int = randi_range(0, count - 2)
	if _last_footstep_index >= 0 and index >= _last_footstep_index:
		index += 1
	_last_footstep_index = index
	return index


## Plays a sound from from_position s into its file, with its pitch moved a little at random.
func _play(sound: AudioStreamPlayer2D, from_position: float = 0.0) -> void:
	sound.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	sound.play(from_position)


## How hard the last landing heard was: 1 for a hard one, and for a soft one its fall's share of the
## way from min_land_height, 0, to hard_land_height, in a straight line. A landing off a wall shorter
## than min_land_height counts as 0. 0 before the first landing heard.
func get_last_landing_share() -> float:
	return _last_landing_share


## On a wall and going down it. Going up along a wall after a jump is not a slide.
func _is_sliding_down_a_wall() -> bool:
	return player.get_state() == Player.State.ON_WALL and player.velocity.y > 0.0


func _on_wall_slide_finished() -> void:
	if _is_sliding_down_a_wall():
		_play(wall_slide)


func _on_jumped() -> void:
	_play(jump, jump_start)
	jump_played.emit()


## The player emits landed at the start of its frame, before this node's frame, so _fall_top_y still
## holds the top of the fall that just ended.
func _on_landed() -> void:
	var fall_height: float = player.global_position.y - _fall_top_y
	var from_wall: bool = _fall_from_wall
	_fall_top_y = player.global_position.y
	_fall_from_wall = false
	if fall_height < min_land_height and not from_wall:
		return
	var hard: bool = fall_height >= hard_land_height
	_last_landing_share = (1.0 if hard else clampf(inverse_lerp(min_land_height, hard_land_height,
			fall_height), 0.0, 1.0))
	var sound: AudioStream = soft_land_sound
	if hard:
		sound = hard_land_sounds.pick_random() as AudioStream
	else:
		# A short jump lands while its sound still plays; the landing cuts it off so they do not
		# overlap.
		jump.stop()
	land.stream = sound
	_play(land)
	land_played.emit(hard)
