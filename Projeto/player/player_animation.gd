class_name PlayerAnimation
extends Node

## Plays the man's animation for where he is and how he moves: on the floor idle or walk, in the air
## jump going up and fall coming down, on a wall wall_slide, or jump while still going up it, and
## hurt while a knockback carries him. It only shows; the player keeps the state. An animation the
## Sprite has no frames for yet falls back to idle, so new art only has to go into the SpriteFrames
## under its name.
##
## The walk keeps pace with the ground: it plays one step for every Step Length he runs, at any
## speed, so the feet never slide. Each time it reaches one of Contact Frames, where a foot is
## planted, it emits stepped, and the footstep sound plays on it.

## A foot was planted: the walk reached one of Contact Frames.
signal stepped

const IDLE: StringName = &"idle"
const WALK: StringName = &"walk"
const JUMP: StringName = &"jump"
const FALL: StringName = &"fall"
const WALL_SLIDE: StringName = &"wall_slide"
const HURT: StringName = &"hurt"
## What _last_walk_frame holds while he is not walking.
const NOT_WALKING: int = -1

@export var player: Player
@export var sprite: AnimatedSprite2D
## Least speed across on the floor for walk; below it, idle. Above 0, so the last moment of a stop
## after the run is let go already shows him standing.
@export_range(0.0, 200.0, 1.0, "suffix:px/s") var walk_min_speed: float = 20.0

@export_group("Walk cycle")
## How far he runs in one step, from one planted foot to the next. The walk plays faster or slower
## to keep to it; longer makes longer, slower strides.
@export_range(20.0, 1000.0, 10.0, "suffix:px") var step_length: float = 220.0
## The walk's frames where a foot is planted, one per step, in order. Measured on the art: 0 and 6
## are the lowest frames, with the foot on the ground line. New walk art needs its own.
@export var contact_frames: Array[int] = [0, 6]

## The walk frame shown on the last frame, NOT_WALKING when it was another animation.
var _last_walk_frame: int = NOT_WALKING
## The animation chosen on the last frame, before falling back to idle for missing art.
var _last_choice: StringName = IDLE


func _ready() -> void:
	assert(player != null, "PlayerAnimation: assign the Player to Player.")
	assert(sprite != null, "PlayerAnimation: assign the AnimatedSprite2D to Sprite.")
	assert(not contact_frames.is_empty(), "PlayerAnimation: add the walk's planted frames.")


func _process(_delta: float) -> void:
	var choice: StringName = animation_for(player.get_state(), player.velocity,
			player.is_knocked_back(), walk_min_speed)
	var animation: StringName = choice
	if not sprite.sprite_frames.has_animation(animation):
		animation = IDLE
	if sprite.animation != animation:
		sprite.play(animation)
		# Off the floor into the walk, the stride starts halfway to the next planted foot, so the
		# first step does not crowd the landing's sound. From standing, it starts on a planted foot.
		if animation == WALK and _last_choice != IDLE:
			sprite.frame = _mid_step_frame()
	_last_choice = choice
	if animation == WALK:
		sprite.speed_scale = walk_speed_scale(absf(player.velocity.x))
		_emit_steps_passed()
		_last_walk_frame = sprite.frame
	else:
		sprite.speed_scale = 1.0
		_last_walk_frame = NOT_WALKING


## The animation for a state, a velocity and a knockback, whether the SpriteFrames has it or not. Up
## is a negative velocity.y, so the top of a jump, at 0, already falls.
static func animation_for(state: Player.State, velocity: Vector2, knocked_back: bool,
		walk_min_speed: float) -> StringName:
	if knocked_back:
		return HURT
	match state:
		Player.State.ON_FLOOR:
			return WALK if absf(velocity.x) >= walk_min_speed else IDLE
		Player.State.ON_WALL:
			return JUMP if velocity.y < 0.0 else WALL_SLIDE
	return JUMP if velocity.y < 0.0 else FALL


## The Sprite's speed_scale that makes the walk play one step per step_length at speed px/s,
## whatever Speed the SpriteFrames gives the walk.
func walk_speed_scale(speed: float) -> float:
	var frames_per_step: float = (float(sprite.sprite_frames.get_frame_count(WALK))
			/ contact_frames.size())
	var frames_per_second: float = speed / step_length * frames_per_step
	return frames_per_second / sprite.sprite_frames.get_animation_speed(WALK)


## Emits stepped for each planted frame reached since the last frame, once each, even if a slow
## frame skipped over it. Starting the walk on a planted frame counts as reaching it.
func _emit_steps_passed() -> void:
	var count: int = sprite.sprite_frames.get_frame_count(WALK)
	var frame: int = sprite.frame
	if _last_walk_frame == NOT_WALKING:
		if frame in contact_frames:
			stepped.emit()
		return
	var passed: int = posmod(frame - _last_walk_frame, count)
	for offset: int in range(1, passed + 1):
		if posmod(_last_walk_frame + offset, count) in contact_frames:
			stepped.emit()


## The frame halfway from the first planted frame to the next.
func _mid_step_frame() -> int:
	var count: int = sprite.sprite_frames.get_frame_count(WALK)
	var half_step: int = floori(float(count) / contact_frames.size() / 2.0)
	return posmod(contact_frames[0] + half_step, count)
