class_name DemonAnimation
extends Node

## Plays the dog's drawing for the demon's state, as PlayerAnimation does for the man's. Standing
## states play idle; moving states walk at Run Min Speed or faster, run at Walk Max Speed or faster,
## and play idle slower, as when one stops at a wall or pauses to bark; leaping states, and any state
## off the floor, hold the run's Leap Frame, the stretched one. So the patrol and the pacing walk, and
## the chase runs. It turns the drawing the way the demon faces; the art faces right. It only shows:
## the demon keeps its state, and the stand-in above the drawing still squashes, hops and tints it for
## the warnings and the stun (DemonPlaceholder). A bite or a lunge go into the SpriteFrames under their
## names when they come, with a pose here for each.
##
## The walk and the run keep pace with the ground, as the man's walk does: one loop of their frames
## for every Walk Stride Length or Stride Length the demon moves, at any speed, so the paws never
## slide.

enum Pose { IDLE, WALK, RUN, LEAP }

const IDLE: StringName = &"idle"
const WALK: StringName = &"walk"
const RUN: StringName = &"run"
## The run's frame shown in the air: the body stretched out.
const LEAP_FRAME: int = 5
## States in which the demon stands, whatever moves it, such as a pack's push.
const STANDING_STATES: Array[Demon.State] = [Demon.State.IDLE, Demon.State.ALERT,
		Demon.State.WARNING, Demon.State.REPELLED, Demon.State.STUNNED, Demon.State.GRAB]
## States in which it leaps or is thrown, on the floor or not.
const LEAPING_STATES: Array[Demon.State] = [Demon.State.LUNGE, Demon.State.THROWN,
		Demon.State.JUMP, Demon.State.DROP]

@export var demon: Demon
@export var sprite: AnimatedSprite2D
## Least speed across on the floor for the walk in a moving state; below it, the demon stands.
@export_range(0.0, 200.0, 1.0, "suffix:px/s") var run_min_speed: float = 20.0
## Least speed across on the floor for the run; below it, down to Run Min Speed, the demon walks.
## Over the patrol's speed and under the chase's.
@export_range(0.0, 2000.0, 10.0, "suffix:px/s") var walk_max_speed: float = 250.0
## How far the demon runs in one loop of the run's frames. Longer makes longer, slower strides.
@export_range(20.0, 2000.0, 10.0, "suffix:px") var stride_length: float = 260.0
## How far the demon walks in one loop of the walk's frames, two steps of each pair of legs.
@export_range(20.0, 2000.0, 10.0, "suffix:px") var walk_stride_length: float = 180.0


func _ready() -> void:
	assert(demon != null, "DemonAnimation: assign the Demon to Demon.")
	assert(sprite != null, "DemonAnimation: assign the AnimatedSprite2D to Sprite.")


func _process(_delta: float) -> void:
	sprite.flip_h = demon.get_facing() < 0.0
	var speed: float = demon.velocity.x
	match pose_for(demon.get_state(), demon.is_on_floor(), speed, run_min_speed, walk_max_speed):
		Pose.RUN:
			_play_in_pace(RUN, speed, stride_length)
		Pose.WALK:
			_play_in_pace(WALK, speed, walk_stride_length)
		Pose.LEAP:
			_show_still(RUN, LEAP_FRAME)
		Pose.IDLE:
			if sprite.animation != IDLE or not sprite.is_playing():
				sprite.play(IDLE)
			sprite.speed_scale = 1.0


## The pose for a state, being on the floor or not, and a speed across, + or -. Every state not
## standing nor leaping moves: it walks from min_speed and runs from run_from.
static func pose_for(state: Demon.State, on_floor: bool, speed: float, min_speed: float,
		run_from: float) -> Pose:
	if not on_floor or state in LEAPING_STATES:
		return Pose.LEAP
	if state in STANDING_STATES:
		return Pose.IDLE
	if absf(speed) >= run_from:
		return Pose.RUN
	return Pose.WALK if absf(speed) >= min_speed else Pose.IDLE


## The Sprite's speed_scale that plays frame_count frames for every stride px moved at speed px/s,
## whatever FPS the SpriteFrames gives the animation.
static func run_speed_scale(speed: float, stride: float, frame_count: int, fps: float) -> float:
	return absf(speed) / stride * frame_count / fps


## Plays animation at the pace of speed: one loop of its frames every stride px.
func _play_in_pace(animation: StringName, speed: float, stride: float) -> void:
	if sprite.animation != animation or not sprite.is_playing():
		sprite.play(animation)
	sprite.speed_scale = run_speed_scale(speed, stride,
			sprite.sprite_frames.get_frame_count(animation),
			sprite.sprite_frames.get_animation_speed(animation))


## Shows one frame of animation and holds it.
func _show_still(animation: StringName, frame: int) -> void:
	if sprite.animation != animation or sprite.is_playing():
		sprite.play(animation)
		sprite.pause()
	sprite.speed_scale = 1.0
	if sprite.frame != frame:
		sprite.frame = frame
