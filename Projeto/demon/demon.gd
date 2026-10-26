class_name Demon
extends CharacterBody2D

## A demon that chases the man: the one scene of every level's demons (ADR 0019). What kind of
## demon it is comes from Stats, such as lust_demon_stats.tres, and where it lives is where the
## level puts it. It never jumps up nor climbs: it chases along its own floor, stops at an edge, and
## a step stops it, so the level's own shape keeps it in its place. Its Senses (ADR 0032) see the man
## inside Sight Distance with no wall between its eyes and his middle or his head; it notices him,
## and starts the chase, only if he is ahead of it or no further behind than Sight Behind Share of
## that, and with Chases Only On Screen only while it is on the screen. It keeps on chasing him past
## Sight Distance, and stops when he gets past Lose Distance, a wall has hidden him for Give Up Time,
## or, with Chases Only On Screen, it is off the screen. With Return Speed it then walks back to its
## post, where the level put it, facing the way it walks, and there faces the way it was put; the
## end of its floor or a wall on the way makes where it stops its post. A man standing on a floor or
## a wall higher or lower than any of its attacks reaches is out of its reach (ADR 0033): it stands facing
## him, never following him along under him, chases him again once he is back within its reach, and
## gives up after Out Of Reach Wait. With Patrol Width and no man to chase, it walks to and fro
## across that stretch around its post, pausing at each end for a draw of its own, and stands still
## while it is off the screen. With the man inside the Attack Range of one
## of its attacks (ADR 0020), on about its own floor, and the attack's chance coming up, it warns
## for the attack's Warning Time. In a lunge, it aims, as the warning starts, where the man will be
## when it lands, and needs him ahead of it and floor all the way there: it stops to warn, lunges
## where it aimed, and stays where it lands for the attack's Recover Time. In a bite on the run, it
## chases on while it warns, bites where it is, and chases on with no attack for Recover Time. With
## Retreat Distance in Stats, it backs off instead after each attack, once the bite is over or the
## lunge's Recover Time: facing the man, with no attack, until he is that far, and then chases him
## again, so it never stays on him (ADR 0023). While the man's Hurtbox takes no hits, invulnerable
## (ADR 0025) or closed with as many demons holding him as can (ADR 0029), no attack could land, so
## it starts none, a warning under way goes back to the chase, and with Retreat Distance it keeps
## that far from him until he can be hurt again. With Pack Spacing, it keeps that far behind another
## demon between it and the man, or steps back to it, so two never look like one, and attacks from
## there, with a lunge over the other; one backing off does not count, so they cross then (ADR
## 0024); with Pack Variation, its speeds and Retreat Distance are its own, a little off the
## others', so they never move in step. The man's raised crucifix hits it through its Repellable,
## from any state (ADR 0021): it throws the demon off, away from the crucifix, by its Thrown values,
## only across if it is in the air, and once it lands the demon stays still for Repelled Time. Its
## Hitbox is on only while an attack can land (ADR 0021): for a bite's Bite Time from the end of its
## warning, and through a lunge from take-off until it lands, never once thrown off; on, it carries
## the attack's damage and knockback to the man's Hurtbox. When the hit holds him instead, it holds
## on, still and with no attack, until he breaks free; he then throws it off, away from him, by its
## Thrown values, and once it lands it lies stunned for Stunned Time (ADR 0028) and then backs off
## or chases him again. Its body and the man's stop each other, so it never gets on his spot (ADR
## 0022). It only tells what it does, by state_changed, warning_started and attack_landed: the art
## and the sounds listen, and it never touches them.

## The demon changed from previous to current this physics frame.
signal state_changed(previous: State, current: State)
## The demon started warning of attack this physics frame, right after state_changed to WARNING, so
## the art and the sounds can show which attack is coming.
signal warning_started(attack: DemonAttack)
## The demon's attack landed on a Hurtbox this physics frame, so the art and the sounds can show the
## bite or the blow.
signal attack_landed(attack: DemonAttack)

## LUNGE lasts from take-off until the attack's Recover Time after landing. GRAB lasts while its hit
## holds the man, THROWN from his breaking free or the crucifix's touch until it lands, REPELLED
## for Repelled Time from landing after the crucifix's touch, and STUNNED for Stunned Time from
## landing after his breaking free. RETURN lasts from giving up until it is back at its post, or as
## near it as its floor lets it go. OUT_OF_REACH lasts while the man stands out of its reach, up to
## Out Of Reach Wait. With Patrol Width, PATROL lasts from setting off from one end of the patrol to
## getting to the other, and IDLE is the pause in between.
enum State {
	IDLE, CHASE, WARNING, LUNGE, REPELLED, RETREAT, GRAB, THROWN, STUNNED, RETURN, OUT_OF_REACH,
	PATROL,
}

## How far apart, in px, the floor is looked for along a lunge: half a tile, so no hole is missed.
const FLOOR_CHECK_STEP: float = 24.0
## How near its post, in px, a demon walking back has to be to be there.
const POST_REACH: float = 1.0
## How much higher than its reach, in px, the man has to stand to be out of it: two bodies on one
## floor can stand a fraction of a px apart, which with no attacks, a reach of 0, would put him out
## of it.
const REACH_TOLERANCE: float = 1.0

@export var stats: DemonStats
## Which way the demon faces at its post: where the level puts it looking, and where it looks again
## once it is back.
@export var faces_left: bool = false

var _state: State = State.IDLE
## The man, while the demon chases him.
var _target: Node2D = null
## The man's body box and half its size, in px, while the demon chases him.
var _target_box: CollisionShape2D = null
var _target_half_size: Vector2 = Vector2.ZERO
## The man's Hurtbox while the demon chases him, or null if he has none.
var _target_hurtbox: Hurtbox = null
## The other demons inside the pack area: about on this one's floor, near enough to keep apart from.
var _packmates: Array[Demon] = []
## Physics frames in a row the demon has chased the man without seeing him.
var _unseen_frames: int = 0
## 1 when the demon goes right, -1 when left. A lunge's warning fixes it until the lunge lands.
var _facing: float = 1.0
## The attack the demon warns for and then makes, chosen when the warning starts.
var _attack: DemonAttack = null
## How far the lunge goes, in px, aimed when its warning starts.
var _lunge_distance: float = 0.0
## The man's x on the last physics frame, and his speed along the floor from it, in px/s, + to the
## right: how far he went, whatever moved him, so a platform that carries him counts too.
var _target_last_x: float = 0.0
var _target_speed: float = 0.0
## Physics frames the demon has warned for, or has stood on the floor since landing a lunge or, when
## repelled or stunned, a throw; thrown, 1 once the throw has started.
var _state_frames: int = 0
## Physics frames left, after a bite on the run, before the demon can attack again.
var _recover_frames_left: int = 0
## Physics frames left in which the bite on the run just made can land.
var _bite_frames_left: int = 0
## True from the end of a bite's warning until its Bite Time is over, when the demon backs off.
var _retreat_after_bite: bool = false
## 1 when the demon is thrown off to the right, -1 to the left.
var _throw_direction: float = 0.0
## True when the crucifix threw the demon off: once it lands, it stays still for Repelled Time.
var _repelled_on_landing: bool = false
## Rolls the attacks' chances. Each demon has its own, seeded from the global generator, which moves
## on with each seed it gives, so demons put in on the same frame do not lunge together.
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Where this demon's Chase Speed, Retreat Speed and Retreat Distance fall within Pack Variation,
## from -1, the lowest, to 1, the highest: kept as draws, not values, so they keep up with a change
## to Pack Variation. Chase Speed is drawn once; the other two again each time it backs off.
var _chase_speed_draw: float = 0.0
var _retreat_speed_draw: float = 0.0
var _retreat_distance_draw: float = 0.0
## Physics frames the demon still waits, able to attack, before it may (Max Hesitation); -1 while it
## can't attack, so it draws a new wait as soon as it can.
var _hesitation_frames_left: int = -1
## Where along the floor the demon walks back to once it gives up: where the level put it, or where
## its floor or a wall last stopped it on the way back.
var _post_x: float = 0.0
## Physics frames the demon still pauses, standing, before it walks across its patrol; -1 until it
## draws one, on its first frame standing, so the draw follows Stats as they are then.
var _pause_frames_left: int = -1
## 1 for right and -1 for left: the way the demon walks its patrol next.
var _patrol_direction: float = 1.0
## True once it gave up on a man out of its reach, until it notices him back within its reach: up
## there, it leaves him alone, instead of starting the chase again on the next frame.
var _gave_up_out_of_reach: bool = false

@onready var _senses: DemonSenses = %Senses
## Finds the other demons within Pack Spacing of this one's body, to either side.
@onready var _pack_area: Area2D = %PackArea
@onready var _pack_shape: CollisionShape2D = %PackShape
## Looks down just ahead of the demon's front. With no floor within its length, the floor ends
## there.
@onready var _ledge_check: RayCast2D = %LedgeCheck
## How far ahead of the demon's middle LedgeCheck looks, in px, set in the scene.
@onready var _ledge_reach: float = absf(_ledge_check.position.x)
@onready var _repellable: Repellable = %Repellable
@onready var _hitbox: Hitbox = %Hitbox
@onready var _box: CollisionShape2D = $CollisionShape2D
@onready var _half_size: Vector2 = _box.shape.get_rect().size / 2.0


func _ready() -> void:
	assert(stats != null, "Demon: assign a DemonStats to Stats.")
	for attack: DemonAttack in stats.attacks:
		assert(attack != null and attack.animation in DemonAttack.ANIMATIONS,
				"Demon: every attack in Attacks needs a DemonAttack with one of its ANIMATIONS.")
		assert(attack.lunge_min_distance <= attack.lunge_distance,
				"Demon: an attack's Lunge Min Distance must be no more than its Lunge Distance.")
	assert(stats.patrol_pause_min <= stats.patrol_pause_max,
			"Demon: Patrol Pause Min must be no more than Patrol Pause Max.")
	_rng.seed = randi()
	_chase_speed_draw = _rng.randf_range(-1.0, 1.0)
	_retreat_speed_draw = _rng.randf_range(-1.0, 1.0)
	_retreat_distance_draw = _rng.randf_range(-1.0, 1.0)
	_post_x = global_position.x
	_facing = _post_facing()
	_patrol_direction = _facing
	_pack_area.body_entered.connect(_on_pack_area_body_entered)
	_pack_area.body_exited.connect(_on_pack_area_body_exited)
	_repellable.repelled.connect(_on_repellable_repelled)
	_hitbox.hit_landed.connect(_on_hitbox_hit_landed)
	_hitbox.hold_started.connect(_on_hitbox_hold_started)
	_hitbox.hold_ended.connect(_on_hitbox_hold_ended)
	stats.changed.connect(_apply_stats)
	_apply_stats()


func _physics_process(delta: float) -> void:
	_bite_frames_left = maxi(_bite_frames_left - 1, 0)
	_track_target(delta)
	if not is_on_floor():
		velocity += _get_current_gravity() * delta
	match _state:
		State.IDLE:
			_physics_idle()
		State.CHASE:
			_physics_chase(delta)
		State.WARNING:
			_physics_warning(delta)
		State.LUNGE:
			_physics_lunge()
		State.REPELLED:
			_physics_repelled()
		State.RETREAT:
			_physics_retreat()
		State.GRAB:
			velocity.x = 0.0
		State.THROWN:
			_physics_thrown()
		State.STUNNED:
			_physics_stunned()
		State.RETURN:
			_physics_return(delta)
		State.OUT_OF_REACH:
			_physics_out_of_reach()
		State.PATROL:
			_physics_patrol(delta)
	_stop_at_the_man(delta)
	move_and_slide()
	_update_hitbox()


func get_state() -> State:
	return _state


## 1 when the demon looks right, -1 when left, for what shows it, such as the art. It looks at the
## man while it chases him and backs off from him.
func get_facing() -> float:
	return _facing


## The world's gravity, or the lunge's own while the demon is on a lunge: a quick, low arc needs
## more gravity than the world's.
func _get_current_gravity() -> Vector2:
	if _state == State.LUNGE:
		return Vector2.DOWN * _attack.get_lunge_gravity()
	if _state == State.THROWN:
		return Vector2.DOWN * stats.get_throw_gravity()
	return get_gravity()


## Stands. With Patrol Width, it pauses a draw between Patrol Pause Min and Max, and then sets off
## across its patrol (ADR 0033).
func _physics_idle() -> void:
	velocity.x = 0.0
	if _chase_if_it_notices_the_man() or stats.patrol_width <= 0.0:
		return
	if _pause_frames_left < 0:
		_pause_frames_left = stats.get_patrol_pause_frames(_rng.randf())
	_pause_frames_left -= 1
	if _pause_frames_left > 0:
		return
	_facing = _patrol_direction
	_change_state(State.PATROL)


## Walks across its patrol at Patrol Speed, facing the way it walks, up to the end of Patrol Width
## around its post, and there pauses and turns back; the end of its floor and a wall of the world
## turn it back sooner (ADR 0033). Off the screen it stands where it is, so no demon wanders where
## the player cannot see it, and in the air it only falls.
func _physics_patrol(delta: float) -> void:
	velocity.x = 0.0
	if _chase_if_it_notices_the_man() or not is_on_floor() or not _senses.is_on_screen():
		return
	var gap: float = _post_x + _patrol_direction * stats.patrol_width / 2.0 - global_position.x
	if absf(gap) <= POST_REACH or signf(gap) != _patrol_direction \
			or _is_edge_ahead(_patrol_direction) or _is_against_a_wall(_patrol_direction):
		_patrol_direction = -_patrol_direction
		_change_state(State.IDLE)
		return
	_facing = _patrol_direction
	velocity.x = _patrol_direction * minf(stats.patrol_speed, absf(gap) / delta)


## Walks back to its post at Return Speed, facing the way it walks, and once there stands facing the
## way it was put. The end of its floor or a wall of the world on the way stops it where it is, which
## is its post from then on, so a demon thrown to another floor never stays trying to get back (ADR
## 0032). In the air, it only falls.
func _physics_return(delta: float) -> void:
	if _chase_if_it_notices_the_man():
		return
	if not is_on_floor():
		velocity.x = 0.0
		return
	var gap: float = _post_x - global_position.x
	var direction: float = signf(gap)
	if absf(gap) <= POST_REACH or _is_edge_ahead(direction) or _is_against_a_wall(direction):
		_post_x = global_position.x
		velocity.x = 0.0
		_facing = _post_facing()
		_change_state(State.IDLE)
		return
	_facing = direction
	velocity.x = direction * minf(stats.return_speed, absf(gap) / delta)


## Starts the chase when the man is inside the sight area and the demon notices him: sees him, and
## he is not further behind it than Sight Behind Share of Sight Distance. With Chases Only On
## Screen, only while it is on the screen. True when it started.
func _chase_if_it_notices_the_man() -> bool:
	var man: Node2D = _senses.get_man_in_sight_area()
	if man == null or not _may_chase_from_here() or not _senses.can_notice(
			man, _facing, stats.sight_distance * stats.sight_behind_share):
		return false
	if _gave_up_out_of_reach:
		if _height_of(man) > stats.get_reach_height():
			return false
		_gave_up_out_of_reach = false
	_target = man
	var target_body: CollisionObject2D = _target as CollisionObject2D
	_target_box = target_body.shape_owner_get_owner(
			target_body.get_shape_owners()[0]) as CollisionShape2D
	_target_half_size = _target_box.shape.get_rect().size / 2.0
	_target_hurtbox = _hurtbox_of(_target)
	_target_last_x = _target.global_position.x
	_target_speed = 0.0
	_unseen_frames = 0
	_change_state(State.CHASE)
	return true


## True when the last move left the demon against a wall of the world, a static body or tiles, going
## in direction. A body that moves, such as the man's, does not count: it would make a post of a spot
## that is free a moment later. Only read while it walks back or patrols, on the frames it touches a
## wall.
func _is_against_a_wall(direction: float) -> bool:
	if not is_on_wall():
		return false
	for index: int in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(index)
		var collider: Object = collision.get_collider()
		if signf(collision.get_normal().x) == -direction \
				and (collider is StaticBody2D or collider is TileMapLayer):
			return true
	return false


## With Chases Only On Screen, only while the demon is on the screen; otherwise always.
func _may_chase_from_here() -> bool:
	return not stats.chases_only_on_screen or _senses.is_on_screen()


## 1 for right and -1 for left: the way the demon faces at its post.
func _post_facing() -> float:
	return -1.0 if faces_left else 1.0


func _physics_chase(delta: float) -> void:
	if not _keeps_after_target():
		return
	var gap: float = _target.global_position.x - global_position.x
	if _is_man_out_of_reach():
		_turn_to(gap)
		velocity.x = 0.0
		_state_frames = 0
		_change_state(State.OUT_OF_REACH)
		return
	if _retreat_after_bite and _bite_frames_left == 0:
		_back_off_or_chase()
		return
	_recover_frames_left = maxi(_recover_frames_left - 1, 0)
	_turn_to(gap)
	var attack: DemonAttack = _attack_to_start(gap, delta)
	if attack != null:
		_attack = attack
		_state_frames = 0
		_change_state(State.WARNING)
		warning_started.emit(attack)
		if not attack.keeps_chasing:
			_lunge_distance = _lunge_distance_to(attack, gap)
			velocity.x = 0.0
			return
	_go_after(gap, delta)


## Stands facing the man out of its reach (ADR 0033), never following him along under him, and
## chases him again as soon as he is back within its reach, on a floor or in the air. It gives up as
## the chase does, and after Out Of Reach Wait also while it still sees him.
func _physics_out_of_reach() -> void:
	velocity.x = 0.0
	if not _keeps_after_target():
		return
	if _height_of(_target) <= stats.get_reach_height():
		_change_state(State.CHASE)
		return
	_turn_to(_target.global_position.x - global_position.x)
	_state_frames += 1
	if _state_frames >= stats.get_out_of_reach_frames():
		_gave_up_out_of_reach = true
		_stop_chasing()


## True when the man stands out of the demon's reach: on a floor, or sliding down or holding on to a
## wall, higher above or lower below the demon's floor than the Max Height Difference of any of its
## attacks, with the demon on its floor too. In the air, or grazing a wall on the way up, he does not
## count, since he can only come down, so a jump never stops the chase nor cuts a bite short; nor
## does a demon in the air, which is still falling to its floor.
func _is_man_out_of_reach() -> bool:
	var man: CharacterBody2D = _target as CharacterBody2D
	return man != null and is_on_floor() \
			and (man.is_on_floor() or (man.is_on_wall() and man.velocity.y >= 0.0)) \
			and _height_of(man) > stats.get_reach_height() + REACH_TOLERANCE


## How far apart, in px, the man's feet and the demon's are in height, above it or below it.
func _height_of(man: Node2D) -> float:
	return absf(global_position.y - man.global_position.y)


## Before a lunge, still, since the chase stopped the demon when the warning started; before a bite
## on the run, chasing on. With the man taking no more hits, as when another demon's attack has just
## landed on him, the warning ends and the demon chases on from this same frame.
func _physics_warning(delta: float) -> void:
	if _target_takes_no_hits():
		_change_state(State.CHASE)
		_physics_chase(delta)
		return
	if _attack.keeps_chasing:
		_physics_bite_on_the_run(delta)
		return
	_state_frames += 1
	if _state_frames >= _attack.get_warning_frames():
		velocity = _attack.get_lunge_velocity(_lunge_distance) * Vector2(_facing, 1.0)
		_state_frames = 0
		_change_state(State.LUNGE)


## Chases on while it warns, and at the end bites where it is, for the bite's Bite Time, and goes
## back to the chase, where it cannot attack for the bite's Recover Time. With Retreat Distance, it
## backs off once Bite Time is over.
func _physics_bite_on_the_run(delta: float) -> void:
	if not _keeps_after_target():
		return
	var gap: float = _target.global_position.x - global_position.x
	_turn_to(gap)
	_go_after(gap, delta)
	_state_frames += 1
	if _state_frames >= _attack.get_warning_frames():
		_recover_frames_left = _attack.get_recover_frames()
		_bite_frames_left = _attack.get_bite_frames()
		_change_state(State.CHASE)
		_retreat_after_bite = stats.retreat_distance > 0.0


## In the air, the lunge keeps its speed across; on the floor, the demon stays put for the attack's
## Recover Time, and then backs off or chases.
func _physics_lunge() -> void:
	if not is_on_floor():
		return
	velocity.x = 0.0
	_state_frames += 1
	if _state_frames >= _attack.get_recover_frames():
		_back_off_or_chase()


## After an attack: backs off from the man with Retreat Distance in Stats, and starts on this same
## frame; with none, or with him already that far, chases him again. Each time, it draws its Retreat
## Distance and Retreat Speed anew, so two demons that attacked together back off apart.
func _back_off_or_chase() -> void:
	_retreat_after_bite = false
	_retreat_distance_draw = _rng.randf_range(-1.0, 1.0)
	_retreat_speed_draw = _rng.randf_range(-1.0, 1.0)
	if stats.retreat_distance > 0.0 and is_instance_valid(_target) \
			and absf(_target.global_position.x - global_position.x) < _retreat_distance():
		_recover_frames_left = 0
		_state_frames = 0
		_change_state(State.RETREAT)
		_physics_retreat()
	elif _state != State.CHASE:
		_change_state(State.CHASE)


## Backs off from the man at Retreat Speed, facing him, with no attack, until he is Retreat Distance
## away or it has backed off for as long as that takes, and then chases him again. An edge behind it
## stops it where it is, and a wall stops its body.
func _physics_retreat() -> void:
	if not _keeps_after_target():
		return
	var gap: float = _target.global_position.x - global_position.x
	_turn_to(gap)
	if absf(gap) >= _retreat_distance() or _state_frames >= stats.get_retreat_max_frames(
			_varied(_retreat_distance_draw), _varied(_retreat_speed_draw)):
		velocity.x = 0.0
		_change_state(State.CHASE)
		return
	_state_frames += 1
	var away: float = -_facing
	velocity.x = 0.0 if is_on_floor() and _is_edge_ahead(away) else away * _retreat_speed()


## Still for Repelled Time after landing from the crucifix's throw. Only its own physics frames
## count, so a pause never shortens it.
func _physics_repelled() -> void:
	_state_frames += 1
	if _state_frames < stats.get_repelled_frames():
		return
	if is_instance_valid(_target):
		_change_state(State.CHASE)
	else:
		_stand_or_return()


## Lies still for Stunned Time after landing from the man's throw (ADR 0028), and then backs off
## from him or chases him again. Only its own physics frames count, so a pause never shortens it.
func _physics_stunned() -> void:
	_state_frames += 1
	if _state_frames >= stats.get_stunned_frames():
		_back_off_or_chase()


## Keeps the man's speed along the floor up to date while the demon is after him.
func _track_target(delta: float) -> void:
	if not is_instance_valid(_target):
		return
	var x: float = _target.global_position.x
	_target_speed = (x - _target_last_x) / delta
	_target_last_x = x


## True while the man is still there to chase: not past Lose Distance, nor hidden by a wall for Give
## Up Time, and, with Chases Only On Screen, the demon still on the screen. Otherwise the demon stops
## chasing him.
func _keeps_after_target() -> bool:
	if not is_instance_valid(_target) or not _may_chase_from_here() \
			or global_position.distance_to(_target.global_position) > stats.lose_distance:
		_stop_chasing()
		return false
	_unseen_frames = 0 if _senses.can_see(_target) else _unseen_frames + 1
	if _unseen_frames >= stats.get_give_up_frames():
		_stop_chasing()
		return false
	return true


## Faces the man, gap px away along the floor, + to the right. Right below him, it keeps its facing.
func _turn_to(gap: float) -> void:
	if gap != 0.0:
		_facing = signf(gap)


## Goes the man's way at Chase Speed, and stops at the end of the floor. Never further than the gap,
## so a demon right below the man stands still instead of shaking, and a bite on the run never takes
## it past him; nor nearer than Pack Spacing to the body of a demon ahead of it. Nearer, as after it
## crossed that one on its way back, it steps back at its Retreat Speed, still facing the man, until
## it is that far. While the man takes no hits, it comes no nearer to him than Retreat Distance,
## and steps back to it the same way.
func _go_after(gap: float, delta: float) -> void:
	var direction: float = signf(gap)
	var room: float = absf(gap)
	if _target_takes_no_hits():
		room -= _retreat_distance()
	var ahead: Demon = _packmate_ahead(gap)
	if ahead != null:
		var apart: float = absf(ahead.global_position.x - global_position.x)
		room = minf(room, apart - 2.0 * _half_size.x - stats.pack_spacing)
	var speed: float = clampf(room / delta, -_retreat_speed(), _chase_speed())
	if is_on_floor() and _is_edge_ahead(direction * signf(speed)):
		velocity.x = 0.0
		return
	velocity.x = direction * speed


## This demon's own Chase Speed, Retreat Speed and Retreat Distance, by its draws of Pack Variation.
func _chase_speed() -> float:
	return stats.chase_speed * _varied(_chase_speed_draw)


func _retreat_speed() -> float:
	return stats.retreat_speed * _varied(_retreat_speed_draw)


func _retreat_distance() -> float:
	return stats.retreat_distance * _varied(_retreat_distance_draw)


## The share of a value this demon has for a draw from -1 to 1 within Pack Variation.
func _varied(draw: float) -> float:
	return 1.0 + draw * stats.pack_variation


## With Pack Spacing, the nearest other demon between this one and the man, gap px away along the
## floor, that is not backing off from him; otherwise null. A demon past the man is on his other
## side, not between, so two demons can come at him from both sides. Every demon is this scene, so
## their bodies are the same size. Of two on one spot, the one put in the scene first is ahead.
func _packmate_ahead(gap: float) -> Demon:
	if stats.pack_spacing <= 0.0:
		return null
	var nearest: Demon = null
	var nearest_apart: float = INF
	for mate: Demon in _packmates:
		if not is_instance_valid(mate) or mate.get_state() == State.RETREAT:
			continue
		var apart: float = mate.global_position.x - global_position.x
		var is_ahead: bool = absf(apart) < absf(gap) and (signf(apart) == signf(gap)
				if apart != 0.0 else mate.get_instance_id() < get_instance_id())
		if is_ahead and absf(apart) < nearest_apart:
			nearest = mate
			nearest_apart = absf(apart)
	return nearest


func _stop_chasing() -> void:
	_target = null
	_target_box = null
	_target_hurtbox = null
	velocity.x = 0.0
	_stand_or_return()


## With Return Speed, walks back to its post; with none, or already there, stands where it is.
func _stand_or_return() -> void:
	if stats.return_speed > 0.0 and absf(_post_x - global_position.x) > POST_REACH:
		_change_state(State.RETURN)
	else:
		_change_state(State.IDLE)


## Never steps into the man's body from the side while their bodies collide. The man moves before
## every demon in a physics frame (player.tscn), but the physics still has his body where the frame
## started, so on its own it would let the demon into the room he just took, and the two bodies
## would shove each other apart frame after frame (ADR 0022).
func _stop_at_the_man(delta: float) -> void:
	if (not is_instance_valid(_target_box) or velocity.x == 0.0
			or collision_mask & (_target as CollisionObject2D).collision_layer == 0):
		return
	var apart: Vector2 = _target_box.global_position - _box.global_position
	var touching: Vector2 = _target_half_size + _half_size
	if absf(apart.y) >= touching.y or signf(apart.x) != signf(velocity.x):
		return
	var room: float = maxf(absf(apart.x) - touching.x, 0.0)
	velocity.x = signf(velocity.x) * minf(absf(velocity.x), room / delta)


## The first of the demon's attacks it starts at the man on this physics frame of delta seconds, or
## null. It only attacks from its floor, at a man it sees this frame and who takes hits,
## once a bite on the run's Recover Time is over, and when the attack's chance comes up. Each time
## it becomes able to, it first waits a new draw of up to Max Hesitation (ADR 0027). The chance is
## rolled before the lunge is aimed and the floor is looked for, which takes many rays: the odds are
## the same either way.
func _attack_to_start(gap: float, delta: float) -> DemonAttack:
	if not is_on_floor() or _unseen_frames != 0 or _recover_frames_left > 0 \
			or _target_takes_no_hits():
		_hesitation_frames_left = -1
		return null
	if _hesitation_frames_left < 0:
		_hesitation_frames_left = stats.get_hesitation_frames(_rng.randf()) \
				if stats.max_hesitation > 0.0 else 0
	if _hesitation_frames_left > 0:
		_hesitation_frames_left -= 1
		return null
	for attack: DemonAttack in stats.attacks:
		if _has_man_in_range(attack, gap) and _rolls(attack, delta) \
				and (attack.keeps_chasing or _can_lunge(attack, gap)):
			_hesitation_frames_left = -1
			return attack
	return null


## True when the attack's lunge, aimed now, has the man ahead to land on and floor all the way to
## where it lands, so the demon never lunges into a hole.
func _can_lunge(attack: DemonAttack, gap: float) -> bool:
	var distance: float = _lunge_distance_to(attack, gap)
	return distance > 0.0 and _has_floor_along_lunge(attack, distance)


## How far the attack's lunge goes from here, in px, to land where the man, gap px away along the
## floor, + to the right, will be.
func _lunge_distance_to(attack: DemonAttack, gap: float) -> float:
	return attack.get_lunge_distance_to(gap * _facing, _target_speed * _facing)


## True when the man is inside the attack's Attack Range and at about the demon's own height.
func _has_man_in_range(attack: DemonAttack, gap: float) -> bool:
	return absf(gap) < attack.attack_range \
			and absf(_target.global_position.y - global_position.y) \
					<= attack.max_height_difference


## True when the attack's chance comes up on this physics frame of delta seconds. A chance of 1
## always does, with no roll.
func _rolls(attack: DemonAttack, delta: float) -> bool:
	var chance: float = attack.get_chance_in(delta)
	return chance >= 1.0 or _rng.randf() < chance


## Looks for floor up to where the attack's lunge of distance px can land at the farthest, so a
## quick lunge, which the floor stops further on, never lands past the end of the floor.
func _has_floor_along_lunge(attack: DemonAttack, distance: float) -> bool:
	var reach: float = attack.get_lunge_reach(distance)
	var offset: float = _ledge_reach
	while offset < reach:
		if not _has_floor_at(offset * _facing):
			return false
		offset += FLOOR_CHECK_STEP
	return _has_floor_at(reach * _facing)


## True while the man's Hurtbox lets no hit land, so an attack now could do nothing to him.
func _target_takes_no_hits() -> bool:
	return is_instance_valid(_target_hurtbox) and not _target_hurtbox.takes_hits()


## The first Hurtbox among the man's children, where its scene puts it, or null. Looked for once,
## when the chase starts, by index, so no list is made.
func _hurtbox_of(man: Node2D) -> Hurtbox:
	for index: int in man.get_child_count():
		var hurtbox: Hurtbox = man.get_child(index) as Hurtbox
		if hurtbox != null:
			return hurtbox
	return null


## True when the floor ends just ahead of the demon's front, going in direction.
func _is_edge_ahead(direction: float) -> bool:
	return not _has_floor_at(_ledge_reach * direction)


## True when LedgeCheck finds floor offset_x px from the demon's middle, + to the right.
func _has_floor_at(offset_x: float) -> bool:
	_ledge_check.position.x = offset_x
	_ledge_check.force_raycast_update()
	return _ledge_check.is_colliding()


## The pack area reaches a body width and Pack Spacing past this demon's body, so it finds a demon
## as soon as its body is that near.
func _apply_stats() -> void:
	_senses.set_sight_distance(stats.sight_distance)
	(_pack_shape.shape as RectangleShape2D).size = Vector2(
			2.0 * (3.0 * _half_size.x + stats.pack_spacing), 2.0 * _half_size.y)


## Any state but the chase ends a bite under way, and the backing off after it, and the Hitbox
## follows the new state at once, so a push from the crucifix stops the attack in the same frame.
func _change_state(new_state: State) -> void:
	var previous: State = _state
	_state = new_state
	if new_state != State.CHASE:
		_bite_frames_left = 0
		_retreat_after_bite = false
	if new_state == State.IDLE:
		_pause_frames_left = -1
	_update_hitbox()
	state_changed.emit(previous, new_state)


## Keeps the Hitbox on only while the attack under way can land: a bite on the run for its Bite
## Time after its warning, a lunge from take-off until it lands. Turned on, it takes the attack's
## damage and knockback.
func _update_hitbox() -> void:
	var can_land: bool = _bite_frames_left > 0 or (_state == State.LUNGE and not is_on_floor())
	if not can_land:
		_hitbox.deactivate()
	elif not _hitbox.is_active():
		_hitbox.damage = _attack.damage
		_hitbox.knockback_distance = _attack.knockback_distance
		_hitbox.knockback_height = _attack.knockback_height
		_hitbox.activate()


func _on_pack_area_body_entered(body: Node2D) -> void:
	var mate: Demon = body as Demon
	if mate != null and mate != self:
		_packmates.append(mate)


func _on_pack_area_body_exited(body: Node2D) -> void:
	_packmates.erase(body as Demon)


func _on_hitbox_hit_landed(_hurtbox: Hurtbox) -> void:
	attack_landed.emit(_attack)


## Its hit holds the man: it stops where it is, falling from there in the middle of a lunge, and
## starts no attack while it holds on. GRAB turns its Hitbox off.
func _on_hitbox_hold_started(_hurtbox: Hurtbox) -> void:
	velocity.x = 0.0
	velocity.y = maxf(velocity.y, 0.0)
	_change_state(State.GRAB)


## The man broke free and throws it off, away from him, facing him all the way.
func _on_hitbox_hold_ended(hurtbox: Hurtbox) -> void:
	if _state != State.GRAB:
		return
	_throw_off(hurtbox.global_position, false)


## Throws the demon off along the floor, away from from; right on it, the way it faces away from.
## With repelled_on_landing, it stays still for Repelled Time once it lands.
func _throw_off(from: Vector2, repelled_on_landing: bool) -> void:
	_throw_direction = signf(global_position.x - from.x)
	if _throw_direction == 0.0:
		_throw_direction = -_facing
	_repelled_on_landing = repelled_on_landing
	_state_frames = 0
	_change_state(State.THROWN)


## The throw starts on the first physics frame in THROWN, with its velocity put in after that
## frame's gravity, as a lunge takes off, so it peaks at Throw Height. In the air, it only goes
## across and falls from where it is, so a throw in the middle of a lunge never takes it above
## Lunge Height. It is in the air from then until it lands, with no attack. Thrown by the crucifix,
## it then stays still for Repelled Time; by the man breaking free, it lies stunned for Stunned
## Time, or with none backs off from him or chases him again at once, as after an attack.
func _physics_thrown() -> void:
	if _state_frames == 0:
		var fall: float = maxf(velocity.y, 0.0)
		velocity = stats.get_throw_velocity() * Vector2(_throw_direction, 1.0)
		if not is_on_floor():
			velocity.y = fall
		_state_frames = 1
	elif is_on_floor():
		velocity.x = 0.0
		if _repelled_on_landing:
			_state_frames = 0
			_change_state(State.REPELLED)
		elif stats.get_stunned_frames() > 0:
			_state_frames = 0
			_change_state(State.STUNNED)
		else:
			_back_off_or_chase()


## The touch of the crucifix is a hit (ADR 0021): it throws the demon off, away from the crucifix.
## While thrown, a push only moves it, so the crucifix pushing on in the first frames of the throw
## does not start the throw again.
func _on_repellable_repelled(origin: Vector2) -> void:
	if _state != State.THROWN:
		_throw_off(origin, true)
