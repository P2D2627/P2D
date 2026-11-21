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
## Back on the floor after the air or a wall. Emitted when the state turns to ON_FLOOR, or to
## GRABBED with his feet on the floor, so the state is already one of those for whoever hears it;
## that is on the physics frame after the one that touched the floor. The camera uses it to reframe
## on the new floor.
signal landed
## His head hit a ceiling: once each time it does, on the physics frame after the move that hit it,
## as with landed. The controller's vibration uses it.
signal head_bumped
## He got on a wall: the state turned to ON_WALL, once each time it does, on the physics frame after
## the move that touched it. The controller's vibration uses it.
signal got_on_wall
## The man died: when a grab runs out of time, which the scene passes on from his GrabEscape to
## _on_grab_escape_died(), or when something calls die(), such as spikes. The level listens and starts
## over (ADR 0026). His scene closes his Hurtbox on it, since the room starts over.
signal died

## Where the player is. Each state runs its own physics, and only _update_state() changes it.
## GRABBED is a demon's grab, from grab() to release(): it comes before the other three, on the floor
## or off it.
enum State { ON_FLOOR, IN_AIR, ON_WALL, GRABBED }

## Name of death's modifier on the player.
const DEATH_SOURCE: StringName = &"death"
## What a death is put down to when whatever killed him does not say.
const UNKNOWN_CAUSE: StringName = &"unknown"
## Radians a surface may lean past Floor Max Angle and still count as a floor or a ceiling, as in
## CharacterBody2D, so a wall to _is_a_level_wall() is a wall to is_on_wall().
const FLOOR_ANGLE_THRESHOLD: float = 0.01
## Share of a run step under which the speed counts as on its target. velocity keeps 32-bit floats,
## so a ramp that should end on its last frame can stop a few ten-thousandths of a px/s short, as
## from 600 px/s in 0.15 s, and would take one frame more.
const RAMP_SNAP_SHARE: float = 0.001
## Px a frame the player is moved into a wall of the level beside him while no run input pushes him,
## so every move touches it. Without a push, the engine reads the touch only from the safe margin,
## and from about x = 2048 (measured) the rounding of 32-bit floats makes that touch come and go: he
## missed walls he touched and fell off walls he was on (#263).
const WALL_HUG_STEP: float = 1.0
## The sides a wall beside him may be on: -1 left, 1 right.
const WALL_SIDES: Array[float] = [-1.0, 1.0]
## The brambles' hold on him (ADR 0067).
const Snag := preload("res://scenes/characters/player/snag.gd")
## His death in brambles (#263).
const BrambleDeath := preload("res://scenes/characters/player/bramble_death.gd")
## Noclip Speed until the debug overlay gives its own, in px/s: about twice his top run speed.
const DEFAULT_NOCLIP_SPEED: float = 1200.0

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

## The brambles' hold on him, which the strips catch him with; it puts itself here as it gets ready.
## With none, as in a bare test player, brambles kill him at one touch.
var snag: Snag = null
## How he dies when brambles kill him, which the strips call as they do; it puts itself here as it
## gets ready. With none, he just dies where he is.
var bramble_death: BrambleDeath = null
## Debug only, from the debug overlay's F1 (#273): hits still land, throw him and grab him, but take
## no SP (lose_sp()), and nothing kills him: die() does nothing, and a grab that runs out of time
## lets him go. Nothing in the game sets it, and release builds have no overlay to set it.
var god_mode: bool = false
## Debug only, from the debug overlay's F2 (#273): he flies with the move keys at Noclip Speed, up
## and down too, with no gravity and through everything, and nothing touches him: he is invincible,
## his HitReaction lets no hit in and his GrabEscape lets him go. He keeps his layer, so what senses
## him, as a camera zone or an exit, still does. Turned on or off, he stops where he is, a knockback
## ends and Jump's kept press and coyote frames are forgotten, so turned off in the air he falls.
var noclip: bool = false:
	set(value):
		if value == noclip:
			return
		noclip = value
		velocity = Vector2.ZERO
		_knockback_frames_left = 0
		_coyote_frames_left = 0
		_wall_coyote_frames_left = 0
		_jump_buffer_frames_left = 0
		if noclip:
			_mask_before_noclip = collision_mask
			collision_mask = 0
		else:
			collision_mask = _mask_before_noclip
## How fast he flies in noclip, in px/s. The debug overlay gives its own.
var noclip_speed: float = DEFAULT_NOCLIP_SPEED
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
## True from grab() to release(): the next _update_state() puts him in GRABBED.
var _grabbed: bool = false
## True when the last _update_state() found him on the floor, so landing is heard once, grabbed or
## not.
var _was_on_floor: bool = false
## True when the last _update_state() found his head against a ceiling, so a bump is heard once.
var _was_on_ceiling: bool = false
## True once he has died, so he dies once.
var _is_dead: bool = false
## True from pin(): he stays exactly where he is, in the air too.
var _pinned: bool = false
## What he died of, as die() was told; empty while alive.
var _death_cause: StringName = &""
## Which one killed him, when that matters, as the strip of spikes; empty while alive or when it
## does not, as for the dogs, a pack.
var _death_source: StringName = &""
## What the next step would hit, for _assist_onto_a_ledge(): one, kept, so no frame makes a new one.
var _ledge_hit: KinematicCollision2D = KinematicCollision2D.new()
## What a hug's step would hit, for _hug_a_wall(), kept in the same way.
var _wall_hit: KinematicCollision2D = KinematicCollision2D.new()
## True from _hug_a_wall() moving him into a wall to the end of that frame's move.
var _hugging: bool = false
## True when this physics frame began with him going up, for _assist_onto_a_ledge().
var _was_rising: bool = false
## His collision mask before noclip emptied it, given back when noclip ends.
var _mask_before_noclip: int = 0

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
## body he can't stand on doesn't count: it shoves him off instead. Just before moving, a fall into
## a ledge a little below its top lifts him onto it (ADR 0059); a hug into a wall ends with the move.
func _physics_process(delta: float) -> void:
	if _pinned:
		velocity = Vector2.ZERO
		return
	# Dead, the body stays where it is until the room starts over: with noclip's empty mask, the
	# fall of a death held still would take it through the floor.
	if noclip:
		if not _is_dead:
			_fly()
		return
	_was_rising = velocity.y < 0.0
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
			State.GRABBED:
				_physics_grabbed(delta)
	_assist_onto_a_ledge(delta)
	move_and_slide()
	_end_the_hug()
	_update_facing()


## Where the player is, for what shows or follows it, such as the debug overlay and the
## animations. It only reads: _update_state() is still the one place that changes the state.
func get_state() -> State:
	return _state


## True standing on a floor: ON_FLOOR, or GRABBED with his feet on it. For what only asks whether
## he stands, such as the camera, which treats a man held on the floor as one standing there.
func is_standing() -> bool:
	return _state == State.ON_FLOOR or (_state == State.GRABBED and _was_on_floor)


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


## True while a shove carries him off a body he can't stand on (ADR 0022), as of his last physics
## frame.
func is_shoved_off() -> bool:
	return _knock_off.is_shoving()


## A demon's grab (ADR 0021): from the next physics frame he is GRABBED until release(). He stops
## at once and a knockback under way ends; in that state he can't run or jump, in the air he rises
## no more and comes down straight, no faster than Grabbed Fall Speed, against a wall too, and nothing shoves
## him off what he stands on. The animations show him trying to escape.
func grab() -> void:
	_grabbed = true
	velocity = Vector2(0.0, clampf(velocity.y, 0.0, stats.grabbed_fall_speed))
	_knockback_frames_left = 0


## Ends grab(): on the next physics frame he is on the floor, in the air or on a wall again.
func release() -> void:
	_grabbed = false


## True from grab() to release(), before the state turns to GRABBED on the next physics frame too.
func is_grabbed() -> bool:
	return _grabbed


## Holds the player where he is for something that is not a grab, such as Velvet's talk or his
## death: he stops at once, a knockback under way ends, and in the air he rises no more and falls
## straight down at the full fall speed, since gravity still pulls; against a wall too, as in the air. Until let_go(),
## nothing shoves him off what he stands on. Keeping him from running and jumping is the holder's,
## with a MovementModifier. His state stays on the floor or in the air, so he does not look grabbed.
func hold_still() -> void:
	_held_still = true
	velocity = Vector2(0.0, maxf(velocity.y, 0.0))
	_knockback_frames_left = 0


## Ends hold_still(): what he stands on can shove him off again.
func let_go() -> void:
	_held_still = false


## Holds him exactly where he is, in the air too, with nothing moving him, gravity included, until
## the room starts over: for a death that catches him, as in brambles (#263). Unlike hold_still(),
## he does not fall.
func pin() -> void:
	_pinned = true
	velocity = Vector2.ZERO


## The way he faces, as his drawing shows: 1 right, -1 left.
func get_facing() -> float:
	return 1.0 if _sprite.flip_h else -1.0


## Turns his drawing to direction's side (positive right), as a run that way would; 0 leaves it.
## For whoever talks to him, so he faces them.
func face(direction: float) -> void:
	if direction != 0.0:
		_sprite.flip_h = direction > 0.0


## The man dies at once, as on spikes, whatever his SP: he stops where he is, with no run and no jump,
## and says so with died, once. The level listens and starts over, and reads get_death_cause() to
## count the death: cause names what killed him, as spikes or the demon that held him, and source
## which one, when that matters, as the strip of spikes he fell on. Invincible, he does not die.
func die(cause: StringName = UNKNOWN_CAUSE, source: StringName = &"") -> void:
	if _is_dead or is_invincible():
		return
	_is_dead = true
	_death_cause = cause if not cause.is_empty() else UNKNOWN_CAUSE
	_death_source = source
	add_movement_modifier(DEATH_SOURCE, MovementModifier.new(0.0, 1.0, true))
	hold_still()
	died.emit()


func is_dead() -> bool:
	return _is_dead


## SP the game takes from him, as a hit or brambles do: none while he is invincible. The debug
## overlay's F4 goes straight to his SoulPoints, so it still takes SP in god mode.
func lose_sp(amount: float) -> void:
	if not is_invincible():
		soul_points.take_damage(amount)


## True in god mode and in noclip, the debug cheats (#273): nothing takes his SP or kills him.
func is_invincible() -> bool:
	return god_mode or noclip


## What he died of, as die() was told; empty while alive.
func get_death_cause() -> StringName:
	return _death_cause


## Which one killed him, as die() was told: the strip of spikes; empty when it does not matter.
func get_death_source() -> StringName:
	return _death_source


## The grab ran out of time: he dies of what held him.
func _on_grab_escape_died() -> void:
	var grab_escape: GrabEscape = get_node_or_null(^"GrabEscape") as GrabEscape
	die(grab_escape.get_hold_cause() if grab_escape != null else UNKNOWN_CAUSE)


## Changes the state from what the last move_and_slide() found, so the take-off frame still runs
## as on the floor and the landing frame as in the air. A grab comes first, then the floor. Off the
## floor, touching a wall puts the player on it unless he pushes away from it; a demon's side takes
## a push into it (ADR 0058). Staying on it takes neither, so he leaves it when it no longer touches
## it, or lands. Held still, he is off it, so he falls as in the air. Touching the floor is heard as
## landed once, grabbed or not; hitting a ceiling as head_bumped once, and getting on a wall as
## got_on_wall.
func _update_state() -> void:
	var on_floor: bool = is_on_floor()
	var touched_down: bool = on_floor and not _was_on_floor
	_was_on_floor = on_floor
	var on_ceiling: bool = is_on_ceiling()
	var bumped_head: bool = on_ceiling and not _was_on_ceiling
	_was_on_ceiling = on_ceiling
	var was_on_wall: bool = _state == State.ON_WALL
	if _grabbed:
		_state = State.GRABBED
	elif on_floor:
		_state = State.ON_FLOOR
	elif _held_still:
		_state = State.IN_AIR
	else:
		match _state:
			State.ON_FLOOR, State.IN_AIR, State.GRABBED:
				_state = State.ON_WALL if _is_holding_a_wall() else State.IN_AIR
			State.ON_WALL:
				if not is_on_wall():
					_state = State.IN_AIR
	if touched_down:
		landed.emit()
	if bumped_head:
		head_bumped.emit()
	if _state == State.ON_WALL and not was_on_wall:
		got_on_wall.emit()


## Turns the drawing to the last run direction; standing still keeps the last one.
func _update_facing() -> void:
	var direction: float = input.get_run_direction()
	if direction != 0.0:
		_sprite.flip_h = direction > 0.0
## On every frame he stands on a body on Knock Off Layers, shoves the player off it the way KnockOff
## says: along its top at Knock Off Speed, as a knockback that lasts until he lands on something
## else. Landing is not the only way onto one: a shove that is stopped, or a demon that gets under
## him, leaves him there too (ADR 0022). Held still, he is not shoved: he falls through it (ADR
## 0056). On a demon in KnockOff's Stand On Group, as a dog whose back bites, he is not shoved
## either: its bites keep at him until he walks or jumps off (#271).
func _shove_off_what_cannot_be_stood_on() -> void:
	var direction: float = _knock_off.update(knock_off_layers, _held_still or _grabbed,
			KnockOff.STAND_ON_GROUP)
	if direction == 0.0:
		return
	velocity = Vector2(direction * stats.knock_off_speed, 0.0)
	_knockback_frames_left = stats.get_knockback_max_frames()


## True when the last move_and_slide() touched a wall the player can get on (ADR 0058): pushing
## into it, or with no run input and a wall off Knock Off Layers among the ones touched, so a
## demon's side still takes a push. Pushing away from it never gets him on.
func _is_holding_a_wall() -> bool:
	if not is_on_wall():
		return false
	var direction: float = input.get_run_direction()
	if direction != 0.0:
		return direction == -signf(get_wall_normal().x)
	return _touches_a_wall_off_knock_off_layers()


## True when one of the walls the last move_and_slide() touched is a wall of the level.
func _touches_a_wall_off_knock_off_layers() -> bool:
	for index: int in get_slide_collision_count():
		if _is_a_level_wall(get_slide_collision(index)):
			return true
	return false


## True for a collision with a wall, not a floor nor a ceiling, on none of Knock Off Layers: the
## level's own, a body or tiles, never a demon. The layers come from the physics server, since a
## TileMapLayer is no CollisionObject2D. A collider freed since the last move, such as a demon gone,
## is no wall.
func _is_a_level_wall(collision: KinematicCollision2D) -> bool:
	var limit: float = floor_max_angle + FLOOR_ANGLE_THRESHOLD
	if collision.get_angle(up_direction) <= limit or collision.get_angle(-up_direction) <= limit:
		return false
	if collision.get_collider() == null:
		return false
	var layers: int = PhysicsServer2D.body_get_collision_layer(collision.get_collider_rid())
	return layers & knock_off_layers == 0


## Lifts the player onto a ledge he falls into with his feet a little below its top (ADR 0059). Off
## the floor, at the top of a jump or falling, moving toward a wall of the level, a hug included, or
## touching one with no speed across, that the next step would hit, he goes up by the fewest whole
## px, at most Ledge Assist Height, that let the step carry him over it, and a px across, onto its
## edge, and stops falling, so he lands on it even with no speed across, which would leave him
## hanging by the face. Like the wall slide, it takes no push, but with no push and no speed of his
## own toward the face, only the top of a rise along it lifts him: coming down along a face from
## above, as past a gap in a wall, he is never stopped on its corner (#263). A one-way platform has
## no side for the step to hit.
## Up there, off its face, the wall's coyote frames end, as on landing, so Jump jumps from the
## ledge, not off the face. He is never lifted onto a demon, nor while he pushes away, is grabbed,
## held still or in a knockback. Never through a ceiling either, with no check of its own: he is
## taller than any lift, so a lift into a ceiling leaves him inside it, and test_move() pushes him
## back out, below it, where the wall still stops the step. With Ledge Assist Height under 1, no
## lift is tried.
func _assist_onto_a_ledge(delta: float) -> void:
	if (velocity.y < 0.0 or _held_still or is_knocked_back()
			or (_state != State.IN_AIR and _state != State.ON_WALL)):
		return
	var side: float = signf(velocity.x)
	# get_wall_normal() only holds while is_on_wall().
	if side == 0.0 and is_on_wall():
		side = -signf(get_wall_normal().x)
	if side == 0.0 or input.get_run_direction() == -side:
		return
	if (input.get_run_direction() == 0.0 and (_hugging or velocity.x == 0.0)
			and not _was_rising):
		return
	var step: Vector2 = Vector2(side * maxf(absf(velocity.x) * delta, 1.0), 0.0)
	if not test_move(global_transform, step, _ledge_hit) or not _is_a_level_wall(_ledge_hit):
		return
	for lift: int in range(1, floori(stats.ledge_assist_height) + 1):
		var up: Vector2 = up_direction * lift
		if not test_move(global_transform.translated(up), step):
			global_position += up + Vector2(side, 0.0)
			velocity.y = 0.0
			_wall_coyote_frames_left = 0
			_end_the_hug()
			return


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
## _air_control(). Unless held still, he hugs a wall of the level right beside him, so he gets on it
## with no push, as the engine's touch alone lets him only near the origin (ADR 0058).
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
	if _held_still:
		return
	for side: float in WALL_SIDES:
		_hug_a_wall(delta, side)
		if _hugging:
			return


## Gravity pulls as in the air, but the fall stops at wall_slide_speed at once; going up is not
## slowed. A kept press of Jump jumps off the wall; without one, the counters run down and he hugs
## the wall, so he stays on it with no push. The run keeps only the share in _air_control().
func _physics_on_wall(delta: float) -> void:
	_apply_gravity(delta)
	velocity.y = minf(velocity.y, stats.wall_slide_speed)
	_keep_jump_press()
	_keep_wall_touch()
	var jumps: bool = _jump_buffer_frames_left > 0
	if jumps:
		_wall_jump(delta)
	else:
		_run_down_counters()
	_apply_run(delta, _air_control())
	if not jumps:
		_hug_a_wall(delta, -_away_from_last_wall)


## With no run input and no speed away from side (-1 left, 1 right), moves the player WALL_HUG_STEP
## px toward a wall of the level on that side, so the move touches it. Only a wall of the level,
## never a demon's side, which still takes a push (ADR 0058), and only one that is that close both
## where he is and where this frame's rise or fall takes him: past a wall's end he gets no push, so
## he never drifts under it or over its top, nor onto the corner of a wall whose top he falls past.
func _hug_a_wall(delta: float, side: float) -> void:
	if side == 0.0 or input.get_run_direction() != 0.0 or velocity.x * side < 0.0:
		return
	# His own speed already carries him a step a frame into it: the hug would only take its place.
	if velocity.x * side * delta >= WALL_HUG_STEP:
		return
	var step: Vector2 = Vector2(side * WALL_HUG_STEP, 0.0)
	var after_this_frame: Transform2D = global_transform.translated(Vector2(0.0, velocity.y * delta))
	if (_is_a_level_wall_within(global_transform, step)
			and _is_a_level_wall_within(after_this_frame, step)):
		velocity.x = step.x / delta
		_hugging = true


## True if a step from where would hit a wall of the level.
func _is_a_level_wall_within(where: Transform2D, step: Vector2) -> bool:
	return test_move(where, step, _wall_hit) and _is_a_level_wall(_wall_hit)


## A hug's speed lasts its own move: once the move has put him against the wall, or a lift has put
## him on a ledge, he keeps no speed across, as with no hug, landing included.
func _end_the_hug() -> void:
	if _hugging:
		velocity.x = 0.0
		_hugging = false


## Noclip's flight: the move keys set his velocity at Noclip Speed, in eight directions, with no
## gravity, ramp or modifier, and the move hits nothing, as his mask is empty. The state still
## follows each move, so the flight is in the air, and the grab a flight starts in ends there.
func _fly() -> void:
	_update_state()
	var direction: Vector2 = Vector2(input.get_run_direction(), input.get_vertical_direction())
	velocity = direction.limit_length(1.0) * noclip_speed
	move_and_slide()
	_update_facing()


## Held by a demon: gravity pulls off the floor, up to Grabbed Fall Speed, and nothing else moves
## him, so he comes down slowly and straight. No press of Jump is kept and every counter empties, so breaking free never jumps by
## itself, nor off a wall touched before the grab.
func _physics_grabbed(delta: float) -> void:
	if not is_on_floor():
		_apply_gravity(delta)
		velocity.y = minf(velocity.y, stats.grabbed_fall_speed)
	velocity.x = 0.0
	_jump_buffer_frames_left = 0
	_coyote_frames_left = 0
	_wall_coyote_frames_left = 0
	_wall_jump_lock_frames_left = 0


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
	if absf(velocity.x - target_speed) < step * RAMP_SNAP_SHARE:
		velocity.x = target_speed


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
