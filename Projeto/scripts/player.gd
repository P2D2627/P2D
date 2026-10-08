class_name Player
extends CharacterBody2D

## A jump off the floor, or off the air a moment after leaving it. late_frames is how many physics
## frames after leaving the floor it came (0 on the floor), and buffered_frames how many frames the
## press of Jump waited for it (0 when the press counts on the jump's own frame).
signal jumped(late_frames: int, buffered_frames: int)
## A jump off a wall, touched or left a moment ago. late_frames counts from leaving the wall (0 while
## touching it), and buffered_frames as in jumped. A wall jump emits only this signal. A function
## connected to either signal takes both values, or is connected with unbind(2); one that takes
## neither is not called, and the engine logs an error.
signal wall_jumped(late_frames: int, buffered_frames: int)

## Where the player is. Each state runs its own physics, and only _update_state() changes it.
enum State { ON_FLOOR, IN_AIR, ON_WALL }

## Movement values. Every player that uses the same file shares them.
@export var stats: PlayerMovementStats

## In the air until the first move_and_slide() finds the floor.
var _state: State = State.IN_AIR
## Physics frames left in which Jump still works after leaving the floor without jumping.
var _coyote_frames_left: int = 0
## Physics frames left in which Jump still jumps off the last wall touched, after leaving it.
var _wall_coyote_frames_left: int = 0
## The run direction away from the last wall touched: 1 off a wall on the left, -1 on the right.
var _away_from_last_wall: float = 0.0
## Physics frames left in which a press of Jump is kept, waiting for a moment the player can jump.
var _jump_buffer_frames_left: int = 0
## Physics frames left in which the run does nothing after a wall jump.
var _wall_jump_lock_frames_left: int = 0


func _ready() -> void:
	assert(stats != null, "Player: assign a PlayerMovementStats resource to Stats.")
	assert(stats.min_jump_height <= stats.jump_height,
			"Player: Min Jump Height is above Jump Height in Stats, so every jump is a full jump.")


func _physics_process(delta: float) -> void:
	_update_state()
	match _state:
		State.ON_FLOOR:
			_physics_on_floor(delta)
		State.IN_AIR:
			_physics_in_air(delta)
		State.ON_WALL:
			_physics_on_wall(delta)
	move_and_slide()


## Where the player is, for what shows or follows it, such as the debug overlay and, later, the
## animations. It only reads: _update_state() is still the one place that changes the state.
func get_state() -> State:
	return _state


## Changes the state from what the last move_and_slide() found, so the take-off frame still runs
## as on the floor and the landing frame as in the air. The floor comes first. Getting on a wall
## takes a push into it, from the air or from the floor; staying on it does not, so the player
## leaves it when it no longer touches it, or lands.
func _update_state() -> void:
	if is_on_floor():
		_state = State.ON_FLOOR
		return
	match _state:
		State.ON_FLOOR, State.IN_AIR:
			_state = State.ON_WALL if _is_pushing_into_a_wall() else State.IN_AIR
		State.ON_WALL:
			if not is_on_wall():
				_state = State.IN_AIR


## True when the last move_and_slide() touched a wall and the run input points into it.
func _is_pushing_into_a_wall() -> bool:
	if not is_on_wall():
		return false
	var direction: float = signf(Input.get_axis(&"move_left", &"move_right"))
	return direction != 0.0 and direction == -signf(get_wall_normal().x)


## Coyote frames fill up, the wall's coyote frames and a wall jump's lock end, a kept press of Jump
## jumps, and the run has full control.
func _physics_on_floor(delta: float) -> void:
	_coyote_frames_left = stats.get_coyote_frames()
	_wall_coyote_frames_left = 0
	_wall_jump_lock_frames_left = 0
	_keep_jump_press()
	if _jump_buffer_frames_left > 0:
		_jump(delta, 0)
	_apply_run(delta, 1.0)


## Gravity pulls. A kept press of Jump jumps off a wall the player touches, pushing into it or
## not, or left a moment ago, even with coyote frames left; away from walls, it jumps while coyote
## frames are left. Without a jump, the counters run down. The run keeps only the share in
## _air_control().
func _physics_in_air(delta: float) -> void:
	_apply_gravity(delta)
	_keep_jump_press()
	_keep_wall_touch()
	if _jump_buffer_frames_left > 0 and _wall_coyote_frames_left > 0:
		_wall_jump(delta)
	elif _jump_buffer_frames_left > 0 and _coyote_frames_left > 0:
		_jump(delta, _frames_off_the_floor())
	else:
		_run_down_counters()
	_apply_run(delta, _air_control())


## Gravity pulls as in the air, but the fall stops at wall_slide_speed at once; going up is not
## slowed. A kept press of Jump jumps off the wall; without one, the counters run down. The run
## keeps only the share in _air_control().
func _physics_on_wall(delta: float) -> void:
	_apply_gravity(delta)
	velocity.y = minf(velocity.y, stats.wall_slide_speed)
	_keep_jump_press()
	_keep_wall_touch()
	if _jump_buffer_frames_left > 0:
		_wall_jump(delta)
	else:
		_run_down_counters()
	_apply_run(delta, _air_control())


func _apply_gravity(delta: float) -> void:
	velocity.y = move_toward(velocity.y, stats.max_fall_speed, _current_gravity() * delta)


## Falling uses fall_gravity. Going up uses the jump's own gravity while Jump is held, and a
## stronger one once it is let go, which makes the jump lower.
func _current_gravity() -> float:
	if velocity.y >= 0.0:
		return stats.fall_gravity
	if Input.is_action_pressed(&"jump"):
		return stats.get_rise_gravity()
	return stats.get_jump_cut_gravity()


## Keeps a press of Jump on its own frame and for Jump Buffer's frames after it, so a press made a
## little before the player can jump still jumps.
func _keep_jump_press() -> void:
	if Input.is_action_just_pressed(&"jump"):
		# One frame for the press itself, then Jump Buffer's frames.
		_jump_buffer_frames_left = stats.get_jump_buffer_frames() + 1


## Keeps a touch of a wall on its own frame and for Coyote Time's frames after it, with the side
## the wall was on, so a press of Jump a little after leaving the wall still jumps off it.
func _keep_wall_touch() -> void:
	if is_on_wall():
		# One frame for the touch itself, then Coyote Time's frames.
		_wall_coyote_frames_left = stats.get_coyote_frames() + 1
		_away_from_last_wall = signf(get_wall_normal().x)


## One frame less for a kept press of Jump, both kinds of coyote frames and a wall jump's lock,
## never below 0.
func _run_down_counters() -> void:
	if _jump_buffer_frames_left > 0:
		_jump_buffer_frames_left -= 1
	if _coyote_frames_left > 0:
		_coyote_frames_left -= 1
	if _wall_coyote_frames_left > 0:
		_wall_coyote_frames_left -= 1
	if _wall_jump_lock_frames_left > 0:
		_wall_jump_lock_frames_left -= 1


## A jump off the floor, late_frames after leaving it (0 on it). Says so with jumped, reading how
## long the press waited before the take-off uses it up.
func _jump(delta: float, late_frames: int) -> void:
	var buffered_frames: int = _frames_the_press_waited()
	_take_off(delta)
	jumped.emit(late_frames, buffered_frames)


## Jumps as from the floor, and also away from the last wall touched at top running speed. The
## run then does nothing for wall_jump_lock_time, so the jump carries the player away from the
## wall; that lock is what keeps a single wall from being climbed. Says so with wall_jumped only.
func _wall_jump(delta: float) -> void:
	var late_frames: int = _frames_off_the_wall()
	var buffered_frames: int = _frames_the_press_waited()
	_take_off(delta)
	velocity.x = _away_from_last_wall * stats.max_run_speed
	_wall_jump_lock_frames_left = stats.get_wall_jump_lock_frames()
	wall_jumped.emit(late_frames, buffered_frames)


## Uses the kept press and both kinds of coyote frames up, so one press makes one jump and a later
## press in the air waits for a landing or a wall. Then leaves at the take-off speed.
func _take_off(delta: float) -> void:
	_jump_buffer_frames_left = 0
	_coyote_frames_left = 0
	_wall_coyote_frames_left = 0
	# Physics moves the player at its speed at the start of each frame, which overshoots
	# the peak. Half a frame of gravity off the take-off speed puts it on jump_height.
	var half_frame_of_gravity: float = stats.get_rise_gravity() * delta / 2.0
	velocity.y = -(stats.get_jump_velocity() - half_frame_of_gravity)


## How many physics frames ago the player left the floor, while coyote frames are left. The floor
## fills them up to Coyote Time's frames, so the first frame in the air gives 1.
func _frames_off_the_floor() -> int:
	return stats.get_coyote_frames() + 1 - _coyote_frames_left


## How many physics frames ago the player last touched a wall, while the wall's coyote frames are
## left. A touch fills them up to one more than Coyote Time's, so a frame touching it gives 0.
func _frames_off_the_wall() -> int:
	return stats.get_coyote_frames() + 1 - _wall_coyote_frames_left


## How many physics frames the kept press of Jump has waited. A press fills the buffer up to one
## more than Jump Buffer's frames, so the frame of the press itself gives 0.
func _frames_the_press_waited() -> int:
	return stats.get_jump_buffer_frames() + 1 - _jump_buffer_frames_left


## The share of the floor's run control kept off the floor: none while a wall jump's lock lasts,
## air_control otherwise.
func _air_control() -> float:
	return 0.0 if _wall_jump_lock_frames_left > 0 else stats.air_control


## Speeds up and slows down with the times in Stats. control is the share of the floor's
## acceleration and braking that is kept: 1 on the floor, _air_control() off it.
func _apply_run(delta: float, control: float) -> void:
	var direction: float = signf(Input.get_axis(&"move_left", &"move_right"))
	var ramp_time: float = stats.time_to_max_speed if direction != 0.0 else stats.time_to_stop
	var target_speed: float = direction * stats.max_run_speed
	var step: float = stats.max_run_speed / ramp_time * control * delta
	velocity.x = move_toward(velocity.x, target_speed, step)
