class_name DemonAnimation
extends Node

## Plays the dog's drawing for the demon's state, as PlayerAnimation does for the man's. Standing
## states show idle; walking states run at Run Min Speed or faster and show idle slower, as when one
## stops at a wall or pauses to bark; leaping states, and any state off the floor, hold the run's
## Leap Frame, the stretched one. It turns the drawing the way the demon faces; the art faces right.
## It only shows: the demon keeps its state, and the stand-in above the drawing still squashes, hops
## and tints it for the warnings and the stun (DemonPlaceholder). Idle is one still drawing for now;
## a bite, a lunge or an idle animation go into the SpriteFrames under their names when they come,
## with a pose here for each.
##
## The run keeps pace with the ground, as the man's walk does: one loop of its frames for every
## Stride Length the demon runs, at any speed, so the paws never slide, patrolling or chasing.

enum Pose { IDLE, RUN, LEAP }

const IDLE: StringName = &"idle"
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
## Least speed across on the floor for the run in a walking state; below it, the demon stands.
@export_range(0.0, 200.0, 1.0, "suffix:px/s") var run_min_speed: float = 20.0
## How far the demon runs in one loop of the run's frames. Longer makes longer, slower strides.
@export_range(20.0, 2000.0, 10.0, "suffix:px") var stride_length: float = 260.0


func _ready() -> void:
	assert(demon != null, "DemonAnimation: assign the Demon to Demon.")
	assert(sprite != null, "DemonAnimation: assign the AnimatedSprite2D to Sprite.")


func _process(_delta: float) -> void:
	sprite.flip_h = demon.get_facing() < 0.0
	var speed: float = demon.velocity.x
	match pose_for(demon.get_state(), demon.is_on_floor(), speed, run_min_speed):
		Pose.RUN:
			if sprite.animation != RUN or not sprite.is_playing():
				sprite.play(RUN)
			sprite.speed_scale = run_speed_scale(speed, stride_length,
					sprite.sprite_frames.get_frame_count(RUN),
					sprite.sprite_frames.get_animation_speed(RUN))
		Pose.LEAP:
			_show_still(RUN, LEAP_FRAME)
		Pose.IDLE:
			_show_still(IDLE, 0)


## The pose for a state, being on the floor or not, and a speed across, + or -. Every state not
## standing nor leaping walks.
static func pose_for(state: Demon.State, on_floor: bool, speed: float,
		min_speed: float) -> Pose:
	if not on_floor or state in LEAPING_STATES:
		return Pose.LEAP
	if state in STANDING_STATES:
		return Pose.IDLE
	return Pose.RUN if absf(speed) >= min_speed else Pose.IDLE


## The Sprite's speed_scale that plays frame_count frames for every stride px run at speed px/s,
## whatever FPS the SpriteFrames gives the run.
static func run_speed_scale(speed: float, stride: float, frame_count: int, fps: float) -> float:
	return absf(speed) / stride * frame_count / fps


## Shows one frame of animation and holds it.
func _show_still(animation: StringName, frame: int) -> void:
	if sprite.animation != animation or sprite.is_playing():
		sprite.play(animation)
		sprite.pause()
	sprite.speed_scale = 1.0
	if sprite.frame != frame:
		sprite.frame = frame
