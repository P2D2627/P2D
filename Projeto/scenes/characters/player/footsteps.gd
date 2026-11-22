class_name Footsteps
extends AudioStreamPlayer

## The man's footsteps. A step plays each time the walk reaches one of Step Frames, so the sound
## lands with the drawing: the walk keeps pace with the ground (see PlayerAnimation) and the steps
## keep pace with the walk. Each step is one of the files of the set Double Layer picks, at random,
## with its pitch moved up to Pitch Variation either way.
##
## A plain AudioStreamPlayer, not a 2D one: the steps are the man's own, with no panning and no
## distance. Their volume is this node's Volume dB. It plays an AudioStreamPolyphonic, so a step's
## tail goes on under the next one and each step keeps its own pitch. It plays only while steps
## sound: the first step starts it, and it stops once the last step's file is over, so a run that
## quits standing still leaves nothing playing.

## A step was heard: stream is its file and pitch_scale its pitch. Dust or a camera bob can follow
## it.
signal step_played(stream: AudioStream, pitch_scale: float)

## What _last_frame holds while the walk is not playing.
const NOT_WALKING: int = -1

## The drawing whose walk the steps follow.
@export var sprite: AnimatedSprite2D
## The walk's name in the Sprite's SpriteFrames.
@export var walk_animation: StringName = &"walk"
## The walk's frames where a step plays, counted from 0, as the Sprite's Frame. 3 and 9 are the
## widest strides of the 12-frame walk, one per foot. Read on every frame, so it can be changed
## while the game runs (Remote tab).
@export var step_frames: Array[int] = [3, 9]

@export_group("Sounds")
## On: the double steps, the front of the foot and then the heel on the floor (the _d files). Off:
## the single steps. Read on every step, so it can be changed while the game runs.
@export var double_layer: bool = false
## The single steps, one impact each.
@export var single_sounds: Array[AudioStream] = []
## The double steps, the front of the foot and then the heel.
@export var double_sounds: Array[AudioStream] = []
## How far each step's pitch can move from the normal, either way: 0.04 is 4% up or down.
@export_range(0.0, 0.2, 0.005) var pitch_variation: float = 0.04
## Steps that can sound at once. A file lasts up to 0.7 s and a step comes every 0.37 s at top
## speed, so two overlap; a step past Voices is not heard.
@export_range(1, 8, 1) var voices: int = 4

## The walk frame shown on the last frame, NOT_WALKING while the walk was not playing.
var _last_frame: int = NOT_WALKING
## The voices of the AudioStreamPolyphonic this node plays, null while it is stopped.
var _playback: AudioStreamPlaybackPolyphonic
## Seconds since the last step.
var _since_last_step: float = 0.0
## The longest file of both sets, in seconds at its own pitch.
var _longest_file: float = 0.0


func _ready() -> void:
	assert(sprite != null, "Footsteps: assign the AnimatedSprite2D to Sprite.")
	assert(not single_sounds.is_empty(), "Footsteps: add the single steps to Single Sounds.")
	assert(not double_sounds.is_empty(), "Footsteps: add the double steps to Double Sounds.")
	var polyphonic: AudioStreamPolyphonic = AudioStreamPolyphonic.new()
	polyphonic.polyphony = voices
	stream = polyphonic
	for sound: AudioStream in single_sounds + double_sounds:
		_longest_file = maxf(_longest_file, sound.get_length())


## Runs after PlayerAnimation, which comes before it in the player, so it reads the frame this
## frame shows.
func _process(delta: float) -> void:
	_since_last_step += delta
	# The lowest pitch plays a file slowest, so its end comes latest.
	if _playback != null and _since_last_step > _longest_file / (1.0 - pitch_variation):
		stop()
		_playback = null
	if sprite.animation != walk_animation or not sprite.is_playing():
		_last_frame = NOT_WALKING
		return
	var frame: int = sprite.frame
	if reached_step_frame(_last_frame, frame, sprite.sprite_frames.get_frame_count(walk_animation),
			step_frames):
		play_step()
	_last_frame = frame


## True when going from last_frame to frame, forwards in a loop of frame_count frames, reaches one
## of steps, also when a slow frame skipped over it. From NOT_WALKING, only when frame is
## one: starting the walk on a step frame counts as reaching it. Staying on a frame reaches nothing.
static func reached_step_frame(last_frame: int, frame: int, frame_count: int,
		steps: Array[int]) -> bool:
	if last_frame == NOT_WALKING:
		return frame in steps
	var passed: int = posmod(frame - last_frame, frame_count)
	for offset: int in range(1, passed + 1):
		if posmod(last_frame + offset, frame_count) in steps:
			return true
	return false


## Plays one step now: a file of the set Double Layer picks, at random, at a pitch within Pitch
## Variation. Gives back its voice, AudioStreamPlaybackPolyphonic.INVALID_ID when all Voices are
## taken.
func play_step() -> int:
	if _playback == null:
		play()
		_playback = get_stream_playback() as AudioStreamPlaybackPolyphonic
	_since_last_step = 0.0
	var sounds: Array[AudioStream] = double_sounds if double_layer else single_sounds
	var step: AudioStream = sounds.pick_random() as AudioStream
	var pitch: float = 1.0 + randf_range(-pitch_variation, pitch_variation)
	# The bus only counts for sample playback, as on the web; it is this node's own, so the steps
	# keep to it either way.
	var voice: int = _playback.play_stream(step, 0.0, 0.0, pitch,
			AudioServer.PLAYBACK_TYPE_DEFAULT, bus)
	step_played.emit(step, pitch)
	return voice
