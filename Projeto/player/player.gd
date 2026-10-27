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
## Back on the floor after the air or a wall. Emitted when the state turns to ON_FLOOR, so the state
## is already ON_FLOOR for whoever hears it; that is on the physics frame after the one that touched
## the floor. The camera uses it to reframe on the new floor.
signal landed
## The man died; today only when a grab runs out of time, which the scene passes on from his
## GrabEscape to _on_grab_escape_died(). The level listens and starts over (ADR 0026).
signal died

## Where the player is. Each state runs its own physics, and only _update_state() changes it.
enum State { ON_FLOOR, IN_AIR, ON_WALL }

## Movement values. Every player that uses the same file shares them.
@export var stats: PlayerMovementStats
## Where the run and the jump come from. The scene's own PlayerInput reads the keyboard; an AI, a
## cutscene or a test can put another PlayerInput here.
@export var input: PlayerInput
## The man's Soul Points (SP), the game's health. Whatever hurts or heals him reaches them here.
@export var soul_points: SoulPoints
## Bodies on these physics layers can't be stood on: standing on one shoves the player off it
## sideways, at Knock Off Speed in Stats. The scene puts the demons' layer here, so a demon's top,
## where its attacks don't reach, is never a safe spot (ADR 0022).
@export_flags_2d_physics var knock_off_layers: int = 0

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
## What changes the movement now, by who put it there, such as &"crucifix".
var _movement_modifiers: Dictionary[StringName, MovementModifier] = {}
## Every modifier's speed_multiplier, multiplied together; 1 with none.
var _speed_multiplier: float = 1.0
## Every modifier's jump_height_multiplier, multiplied together; 1 with none.
var _jump_height_multiplier: float = 1.0
## True while any modifier blocks jumping.
var _jump_blocked: bool = false
## Physics frames left of a hit's knockback, which landing ends sooner.
var _knockback_frames_left: int = 0
## Says which way to shove the player off a body on Knock Off Layers. Being on that floor doesn't
## end the knockback, leaving it does.
var _knock_off: KnockOff = KnockOff.new(self)
## True from hold_still() to let_go(): nothing shoves the player off what he stands on, and off the
## floor he is in the air, never on a wall.
var _held_still: bool = false

## The drawing faces left; it is mirrored while the player faces right.
@onready var _sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	assert(stats != null, "Player: assign a PlayerMovementStats resource to Stats.")
	assert(input != null, "Player: assign a PlayerInput node to Input.")
	assert(soul_points != null, "Player: assign a SoulPoints node to Soul Points.")
	assert(stats.min_jump_height <= stats.jump_height,
			"Player: Min Jump Height is above Jump Height in Stats, so every jump is a full jump.")


## A knockback runs instead of the state's own physics until it ends. Landing ends it: on the floor
## and no longer going up, so the frame it takes off from the floor on still counts. The top of a
## body he can't stand on doesn't count: it shoves him off instead.
func _physics_process(delta: float) -> void:
	_update_state()
	_shove_off_what_cannot_be_stood_on()
	if is_on_floor() and velocity.y >= 0.0 and not _knock_off.is_shoving():
		_knockback_frames_left = 0
	if is_knocked_back():
		_physics_knocked_back(delta)
	else:
		match _state:
			State.ON_FLOOR:
				_physics_on_floor(delta)
			State.IN_AIR:
				_physics_in_air(delta)
			State.ON_WALL:
				_physics_on_wall(delta)
	move_and_slide()
	_update_facing()


## Where the player is, for what shows or follows it, such as the debug overlay and, later, the
## animations. It only reads: _update_state() is still the one place that changes the state.
func get_state() -> State:
	return _state


## Puts a change to the movement on the player under source, replacing the one source had. The
## player never asks who put it: the crucifix and, later, the sloth level slow it the same way. It
## listens to the modifier, so a value changed while it is on takes effect at once.
func add_movement_modifier(source: StringName, modifier: MovementModifier) -> void:
	assert(modifier != null, "Player: %s put no MovementModifier on the player." % source)
	remove_movement_modifier(source)
	_movement_modifiers[source] = modifier
	if not modifier.changed.is_connected(_combine_movement_modifiers):
		modifier.changed.connect(_combine_movement_modifiers)
	_combine_movement_modifiers()


## Takes source's change off the movement; nothing happens if source has none on. The player stops
## listening to the modifier, unless another source put the same one on.
func remove_movement_modifier(source: StringName) -> void:
	var modifier: MovementModifier = _movement_modifiers.get(source)
	if modifier == null:
		return
	_movement_modifiers.erase(source)
	if (modifier not in _movement_modifiers.values()
			and modifier.changed.is_connected(_combine_movement_modifiers)):
		modifier.changed.disconnect(_combine_movement_modifiers)
	_combine_movement_modifiers()


## Share of the running speed kept by every modifier together: 1 with none.
func get_speed_multiplier() -> float:
	return _speed_multiplier


## Share of the jump's height kept by every modifier together: 1 with none.
func get_jump_height_multiplier() -> float:
	return _jump_height_multiplier


## True while any modifier stops the player from jumping.
func is_jump_blocked() -> bool:
	return _jump_blocked


## Throws the player as a hit does (ADR 0021): height px up, landing distance px away on flat floor,
## to the right with direction 1 and to the left with -1. The run and the jump do nothing until he
## lands, or for Knockback Max Time at most. A new knockback replaces one under way.
func knock_back(direction: float, distance: float, height: float) -> void:
	var launch: Vector2 = stats.get_knockback_velocity(distance, height)
	velocity = Vector2(direction * launch.x, launch.y)
	_knockback_frames_left = stats.get_knockback_max_frames()


## True while a hit's knockback carries the player, for what shows it, such as the animations.
func is_knocked_back() -> bool:
	return _knockback_frames_left > 0


## Holds the player where he is, as a demon's grab does (ADR 0021): he stops at once, a knockback
## under way ends, and in the air he rises no more and falls straight down, since gravity still
## pulls; against a wall too, as in the air. Until let_go(), nothing shoves him off what he stands
## on. Keeping him from running and jumping is the holder's, with a MovementModifier.
func hold_still() -> void:
	_held_still = true
	velocity = Vector2(0.0, maxf(velocity.y, 0.0))
	_knockback_frames_left = 0


## Ends hold_still(): what he stands on can shove him off again.
func let_go() -> void:
	_held_still = false


func _on_grab_escape_died() -> void:
	died.emit()


## Changes the state from what the last move_and_slide() found, so the take-off frame still runs
## as on the floor and the landing frame as in the air. The floor comes first. Getting on a wall
## takes a push into it, from the air or from the floor; staying on it does not, so the player
## leaves it when it no longer touches it, or lands. Held still, he is off it, so he falls as in
## the air.
func _update_state() -> void:
	if is_on_floor():
		var was_off_the_floor: bool = _state != State.ON_FLOOR
		_state = State.ON_FLOOR
		if was_off_the_floor:
			landed.emit()
		return
	if _held_still:
		_state = State.IN_AIR
		return
	match _state:
		State.ON_FLOOR, State.IN_AIR:
			_state = State.ON_WALL if _is_pushing_into_a_wall() else State.IN_AIR
		State.ON_WALL:
			if not is_on_wall():
				_state = State.IN_AIR


## Turns the drawing to the last run direction; standing still keeps the last one.
func _update_facing() -> void:
	var direction: float = input.get_run_direction()
	if direction != 0.0:
		_sprite.flip_h = direction > 0.0
## On every frame he stands on a body on Knock Off Layers, shoves the player off it the way KnockOff
## says: along its top at Knock Off Speed, as a knockback that lasts until he lands on something
## else. Landing is not the only way onto one: a shove that is stopped, or a demon that gets under
## him, leaves him there too (ADR 0022). Held still, he is not shoved.
func _shove_off_what_cannot_be_stood_on() -> void:
	var direction: float = _knock_off.update(knock_off_layers, _held_still)
	if direction == 0.0:
		return
	velocity = Vector2(direction * stats.knock_off_speed, 0.0)
	_knockback_frames_left = stats.get_knockback_max_frames()


## True when the last move_and_slide() touched a wall and the run input points into it.
func _is_pushing_into_a_wall() -> bool:
	if not is_on_wall():
		return false
	var direction: float = input.get_run_direction()
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


## A knockback carries the player at the speed across it threw him at: gravity pulls off the floor,
## and the run and the jump do nothing. A press of Jump is still kept, so one made just before
## landing jumps as he lands, and the counters run down as in the air.
func _physics_knocked_back(delta: float) -> void:
	if not is_on_floor():
		_apply_gravity(delta)
	_keep_jump_press()
	_run_down_counters()
	_knockback_frames_left -= 1


func _apply_gravity(delta: float) -> void:
	velocity.y = move_toward(velocity.y, stats.max_fall_speed, _current_gravity() * delta)


## Falling, and a knockback all the way, use fall_gravity. Going up uses the jump's own gravity
## while Jump is held, and a stronger one once it is let go, which makes the jump lower.
func _current_gravity() -> float:
	if velocity.y >= 0.0 or is_knocked_back():
		return stats.fall_gravity
	if input.is_jump_held():
		return stats.get_rise_gravity()
	return stats.get_jump_cut_gravity()


## Keeps a press of Jump on its own frame and for Jump Buffer's frames after it, so a press made a
## little before the player can jump still jumps. While a modifier blocks jumping, no press is kept,
## and one kept from before is dropped, so lifting the block never jumps by itself.
func _keep_jump_press() -> void:
	if _jump_blocked:
		_jump_buffer_frames_left = 0
		return
	if input.is_jump_just_pressed():
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


## Jumps as from the floor, and also away from the last wall touched at top running speed, as the
## modifiers leave it. The run then does nothing for wall_jump_lock_time, so the jump carries the
## player away from the wall; that lock is what keeps a single wall from being climbed. Says so
## with wall_jumped only.
func _wall_jump(delta: float) -> void:
	var late_frames: int = _frames_off_the_wall()
	var buffered_frames: int = _frames_the_press_waited()
	_take_off(delta)
	velocity.x = _away_from_last_wall * _top_run_speed()
	_wall_jump_lock_frames_left = stats.get_wall_jump_lock_frames()
	wall_jumped.emit(late_frames, buffered_frames)


## Uses the kept press and both kinds of coyote frames up, so one press makes one jump and a later
## press in the air waits for a landing or a wall. Then leaves at the take-off speed, which the
## modifiers scale by the square root of their share of the height: with the same gravity, the
## height goes with the square of the take-off speed.
func _take_off(delta: float) -> void:
	_jump_buffer_frames_left = 0
	_coyote_frames_left = 0
	_wall_coyote_frames_left = 0
	# Physics moves the player at its speed at the start of each frame, which overshoots
	# the peak. Half a frame of gravity off the take-off speed puts it on jump_height.
	var half_frame_of_gravity: float = stats.get_rise_gravity() * delta / 2.0
	var jump_velocity: float = stats.get_jump_velocity() * sqrt(_jump_height_multiplier)
	velocity.y = -(jump_velocity - half_frame_of_gravity)


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


## Speeds up and slows down with the times in Stats, up to the top speed the modifiers leave.
## control is the share of the floor's acceleration and braking that is kept: 1 on the floor,
## _air_control() off it.
func _apply_run(delta: float, control: float) -> void:
	var direction: float = input.get_run_direction()
	var ramp_time: float = stats.time_to_max_speed if direction != 0.0 else stats.time_to_stop
	var top_speed: float = _top_run_speed()
	var target_speed: float = direction * top_speed
	var step: float = top_speed / ramp_time * control * delta
	velocity.x = move_toward(velocity.x, target_speed, step)


## Max Run Speed, as the modifiers leave it.
func _top_run_speed() -> float:
	return stats.max_run_speed * _speed_multiplier


## Multiplies every modifier's shares together, and blocks jumping if any of them does, once per
## change, when a modifier is put on, taken off or changed, instead of once per frame.
func _combine_movement_modifiers() -> void:
	_speed_multiplier = 1.0
	_jump_height_multiplier = 1.0
	_jump_blocked = false
	for modifier: MovementModifier in _movement_modifiers.values():
		_speed_multiplier *= modifier.speed_multiplier
		_jump_height_multiplier *= modifier.jump_height_multiplier
		_jump_blocked = _jump_blocked or modifier.blocks_jump
