class_name Player
extends CharacterBody2D

## Movement values. Every player that uses the same file shares them.
@export var stats: PlayerMovementStats

## Physics frames left in which Jump still works after leaving the floor without jumping.
var _coyote_frames_left: int = 0
## Physics frames left in which a press of Jump is kept, waiting for a moment the player can jump.
var _jump_buffer_frames_left: int = 0


func _ready() -> void:
	assert(stats != null, "Player: assign a PlayerMovementStats resource to Stats.")
	assert(stats.min_jump_height <= stats.jump_height,
			"Player: Min Jump Height is above Jump Height in Stats, so every jump is a full jump.")


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_apply_jump(delta)
	_apply_run(delta)
	move_and_slide()


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y = move_toward(velocity.y, stats.max_fall_speed, _current_gravity() * delta)


## Falling uses fall_gravity. Going up uses the jump's own gravity while Jump is held, and a
## stronger one once it is let go, which makes the jump lower.
func _current_gravity() -> float:
	if velocity.y >= 0.0:
		return stats.fall_gravity
	if Input.is_action_pressed(&"jump"):
		return stats.get_rise_gravity()
	return stats.get_jump_cut_gravity()


## Jumps when a kept press of Jump meets a moment the player can jump: on the floor, or in the air
## while coyote frames are left. Coyote frames fill up on the floor and run down in the air; a
## press is kept on its own frame and for Jump Buffer's frames after it.
func _apply_jump(delta: float) -> void:
	if is_on_floor():
		_coyote_frames_left = stats.get_coyote_frames()
	if Input.is_action_just_pressed(&"jump"):
		# One frame for the press itself, then Jump Buffer's frames.
		_jump_buffer_frames_left = stats.get_jump_buffer_frames() + 1
	if _jump_buffer_frames_left > 0 and (is_on_floor() or _coyote_frames_left > 0):
		_jump(delta)
		return
	if _jump_buffer_frames_left > 0:
		_jump_buffer_frames_left -= 1
	if not is_on_floor() and _coyote_frames_left > 0:
		_coyote_frames_left -= 1


## Uses the kept press and the coyote frames up, so one press makes one jump and a later press in
## the air can only jump on a landing, then leaves at the take-off speed.
func _jump(delta: float) -> void:
	_jump_buffer_frames_left = 0
	_coyote_frames_left = 0
	# Physics moves the player at its speed at the start of each frame, which overshoots
	# the peak. Half a frame of gravity off the take-off speed puts it on jump_height.
	var half_frame_of_gravity: float = stats.get_rise_gravity() * delta / 2.0
	velocity.y = -(stats.get_jump_velocity() - half_frame_of_gravity)


## Speeds up and slows down with the times in Stats. In the air both take longer, because only the
## share in air_control is kept. is_on_floor() comes from the last move_and_slide(), so the take-off
## frame still runs as on the floor and the landing frame as in the air.
func _apply_run(delta: float) -> void:
	var direction: float = signf(Input.get_axis(&"move_left", &"move_right"))
	var ramp_time: float = stats.time_to_max_speed if direction != 0.0 else stats.time_to_stop
	var target_speed: float = direction * stats.max_run_speed
	var control: float = 1.0 if is_on_floor() else stats.air_control
	var step: float = stats.max_run_speed / ramp_time * control * delta
	velocity.x = move_toward(velocity.x, target_speed, step)
