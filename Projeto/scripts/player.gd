class_name Player
extends CharacterBody2D

## Movement values. Every player that uses the same file shares them.
@export var stats: PlayerMovementStats


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


func _apply_jump(delta: float) -> void:
	if Input.is_action_just_pressed(&"jump") and is_on_floor():
		# Physics moves the player at its speed at the start of each frame, which overshoots
		# the peak. Half a frame of gravity off the take-off speed puts it on jump_height.
		var half_frame_of_gravity: float = stats.get_rise_gravity() * delta / 2.0
		velocity.y = -(stats.get_jump_velocity() - half_frame_of_gravity)


func _apply_run(delta: float) -> void:
	var direction: float = signf(Input.get_axis(&"move_left", &"move_right"))
	var ramp_time: float = stats.time_to_max_speed if direction != 0.0 else stats.time_to_stop
	var target_speed: float = direction * stats.max_run_speed
	var step: float = stats.max_run_speed / ramp_time * delta
	velocity.x = move_toward(velocity.x, target_speed, step)
