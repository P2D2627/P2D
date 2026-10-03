class_name Player
extends CharacterBody2D

## Movement values. Every player that uses the same file shares them.
@export var stats: PlayerMovementStats


func _ready() -> void:
	assert(stats != null, "Player: assign a PlayerMovementStats resource to Stats.")


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_apply_jump(delta)
	_apply_run(delta)
	move_and_slide()


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		var gravity: float = stats.get_rise_gravity() if velocity.y < 0.0 else stats.fall_gravity
		velocity.y = move_toward(velocity.y, stats.max_fall_speed, gravity * delta)


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
