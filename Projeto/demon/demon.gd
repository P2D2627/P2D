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
## or, with Chases Only On Screen, it is off the screen; with Return Speed it then walks back to its
## post, where the level put it. What it does in each State is that state's own DemonState, in
## states/ (ADR 0034): the demon makes one of each, changes between them only through change_state,
## and keeps for them what they share, its body, its Senses, the man it chases, its attacks and its
## pack, behind the methods whose doc starts "For its states"; nothing else calls those. With the
## man inside the Attack Range of one of its attacks (ADR 0020), on about its own floor, and the
## attack's chance coming up, it warns of the attack; a lunge needs him ahead of it and floor all the
## way to where it lands. While the man's Hurtbox takes no hits, invulnerable (ADR 0025) or closed
## with as many demons holding him as can (ADR 0029), no attack could land, so it starts none, and
## with Retreat Distance it keeps that far from him until he can be hurt again. With Pack Spacing,
## it keeps that far behind another demon between it and the man, or steps back to it, so two never
## look like one, and attacks from there, with a lunge over the other; one backing off does not
## count, so they cross then (ADR 0024); with Pack Variation, its speeds and Retreat Distance are its
## own, a little off the others', so they never move in step. The man's raised crucifix hits it
## through its Repellable, from any state (ADR 0021), and throws it off, away from the crucifix. Its
## Hitbox is on only while an attack can land (ADR 0021): for a bite's Bite Time from the end of its
## warning, and through a lunge from take-off until it lands, never once thrown off; on, it carries
## the attack's damage and knockback to the man's Hurtbox. When the hit holds him instead, it holds
## on until he breaks free and throws it off, away from him (ADR 0028). Its body and the man's stop
## each other, so it never gets on his spot (ADR 0022). It only tells what it does, by
## state_changed, warning_started and attack_landed: the art and the sounds listen, and it never
## touches them.

## The demon changed from previous to current this physics frame.
signal state_changed(previous: State, current: State)
## The demon started warning of attack this physics frame, right after state_changed to WARNING, so
## the art and the sounds can show which attack is coming.
signal warning_started(attack: DemonAttack)
## The demon's attack landed on a Hurtbox this physics frame, so the art and the sounds can show the
## bite or the blow.
signal attack_landed(attack: DemonAttack)

## What the demon is doing, as the art, the sounds and the tests read it. Each has its own
## DemonState in states/, whose doc says when it starts and how long it lasts.
enum State {
	IDLE, CHASE, WARNING, LUNGE, REPELLED, RETREAT, GRAB, THROWN, STUNNED, RETURN, OUT_OF_REACH,
	PATROL, ALERT, SEARCH,
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
## One DemonState of each State, at its State's index (ADR 0034), made in _ready, and the one the
## demon is in.
var _states: Array[DemonState] = []
var _current: DemonState = null
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
## The man's x the last time the demon saw him, where it looks for him once he is hidden, and the
## physics frame it saw him on.
var _last_seen_x: float = 0.0
var _seen_on_frame: int = -2
## 1 when the demon goes right, -1 when left. A lunge's warning fixes it until the lunge lands.
var _facing: float = 1.0
## The attack the demon warns for and then makes, chosen when the warning starts.
var _attack: DemonAttack = null
## The man's x on the last physics frame, and his speed along the floor from it, in px/s, + to the
## right: how far he went, whatever moved him, so a platform that carries him counts too.
var _target_last_x: float = 0.0
var _target_speed: float = 0.0
## Physics frames left, after a bite on the run, before the demon can attack again.
var _recover_frames_left: int = 0
## Physics frames left in which the bite on the run just made can land.
var _bite_frames_left: int = 0
## True from the end of a bite's warning until its Bite Time is over, when the demon backs off.
var _retreat_after_bite: bool = false
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
	_facing = post_facing()
	_make_states()
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
		velocity += _current.get_gravity() * delta
	_current.physics_update(delta)
	_stop_at_the_man(delta)
	move_and_slide()
	_update_hitbox()


func get_state() -> State:
	return _state


func _make_states() -> void:
	_states.resize(State.size())
	_states[State.IDLE] = DemonIdleState.new(self)
	_states[State.CHASE] = DemonChaseState.new(self)
	_states[State.WARNING] = DemonWarningState.new(self)
	_states[State.LUNGE] = DemonLungeState.new(self)
	_states[State.REPELLED] = DemonRepelledState.new(self)
	_states[State.RETREAT] = DemonRetreatState.new(self)
	_states[State.GRAB] = DemonGrabState.new(self)
	_states[State.THROWN] = DemonThrownState.new(self)
	_states[State.STUNNED] = DemonStunnedState.new(self)
	_states[State.RETURN] = DemonReturnState.new(self)
	_states[State.OUT_OF_REACH] = DemonOutOfReachState.new(self)
	_states[State.PATROL] = DemonPatrolState.new(self)
	_states[State.ALERT] = DemonAlertState.new(self)
	_states[State.SEARCH] = DemonSearchState.new(self)
	assert(not _states.has(null), "Demon: every State needs its object in _make_states.")
	_current = _states[_state]


## 1 when the demon looks right, -1 when left, for what shows it, such as the art. It looks at the
## man while it chases him and backs off from him.
func get_facing() -> float:
	return _facing


## True while the demon is after the man and saw him on this physics frame or the one before, for
## what shows it, such as the test room's debug view. In a lunge, a grab or a throw it does not
## look, so there it is false.
func sees_target() -> bool:
	return is_instance_valid(_target) and Engine.get_physics_frames() - _seen_on_frame <= 1


## For its states: where along the floor the demon walks back to once it gives up.
func get_post_x() -> float:
	return _post_x


## For its states: makes where the demon stands its post from now on.
func make_post_here() -> void:
	_post_x = global_position.x


## For its states: true while the demon is on the screen.
func is_on_screen() -> bool:
	return _senses.is_on_screen()


## For its states: a draw from 0 to 1 from the demon's own generator, so a seed repeats it.
func random_share() -> float:
	return _rng.randf()


## For its states: starts the chase when the man is inside the sight area and the demon notices
## him: sees him, and he is not further behind it than Sight Behind Share of Sight Distance. With
## Chases Only On Screen, only while it is on the screen. With Alert Time, the chase starts with the
## alert (ADR 0035). True when it started.
func chase_if_it_notices_the_man() -> bool:
	var man: Node2D = _senses.get_man_in_sight_area()
	if man == null or not may_chase_from_here() or not _senses.can_notice(
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
	_last_seen_x = _target_last_x
	_target_speed = 0.0
	_unseen_frames = 0
	change_state(State.ALERT if stats.alert_time > 0.0 else State.CHASE)
	return true


## For its states: true when the last move left the demon against a wall of the world, a static
## body or tiles, going in direction. A body that moves, such as the man's, does not count: it would
## make a post of a spot that is free a moment later. Only read while it walks back, patrols or
## searches, on the frames it touches a wall.
func is_against_a_wall(direction: float) -> bool:
	if not is_on_wall():
		return false
	for index: int in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(index)
		var collider: Object = collision.get_collider()
		if signf(collision.get_normal().x) == -direction \
				and (collider is StaticBody2D or collider is TileMapLayer):
			return true
	return false


## For its states: with Chases Only On Screen, only while the demon is on the screen; otherwise
## always.
func may_chase_from_here() -> bool:
	return not stats.chases_only_on_screen or _senses.is_on_screen()


## For its states: 1 for right and -1 for left, the way the demon faces at its post.
func post_facing() -> float:
	return -1.0 if faces_left else 1.0


## For its states: how far the man is along the floor, in px, + to the right.
func get_gap_to_target() -> float:
	return _target.global_position.x - global_position.x


## For its states: how far apart, in px, the man's feet and the demon's are in height.
func get_target_height() -> float:
	return _height_of(_target)


## For its states: warns of attack, chosen by attack_to_start, which it makes once the warning is
## over.
func warn_of(attack: DemonAttack) -> void:
	_attack = attack
	change_state(State.WARNING)
	warning_started.emit(attack)


## For its states: the attack the demon warns of, makes, or made last.
func get_attack() -> DemonAttack:
	return _attack


## For its states: bites where the demon is, at the end of a bite on the run's warning, for the
## bite's Bite Time, and goes back to the chase, where it cannot attack for the bite's Recover Time.
## With Retreat Distance, it backs off once Bite Time is over.
func bite() -> void:
	_recover_frames_left = _attack.get_recover_frames()
	_bite_frames_left = _attack.get_bite_frames()
	_retreat_after_bite = stats.retreat_distance > 0.0
	change_state(State.CHASE)


## For its states: true once the Bite Time of a bite on the run is over, with Retreat Distance in
## Stats, so the demon backs off.
func should_back_off_after_bite() -> bool:
	return _retreat_after_bite and _bite_frames_left == 0


## For its states: ends a bite under way, and the backing off after it.
func end_bite() -> void:
	_bite_frames_left = 0
	_retreat_after_bite = false


## For its states: gives up on a man out of its reach (ADR 0033), and leaves him alone up there
## until it notices him back within its reach.
func give_up_out_of_reach() -> void:
	_gave_up_out_of_reach = true
	_stop_chasing()


## For its states: changes to new_state, and lets it act on this same physics frame of delta
## seconds, as when a warning ends and the chase goes on at once.
func change_state_and_act(new_state: State, delta: float) -> void:
	change_state(new_state)
	_current.physics_update(delta)


## For its states: true when the man stands out of the demon's reach, on a floor, or sliding down or
## holding on to a wall, higher above or lower below the demon's floor than the Max Height
## Difference of any of its attacks, with the demon on its floor too. In the air, or grazing a wall
## on the way up, he does not count, since he can only come down, so a jump never stops the chase
## nor cuts a bite short; nor does a demon in the air, which is still falling to its floor.
func is_man_out_of_reach() -> bool:
	var man: CharacterBody2D = _target as CharacterBody2D
	return man != null and is_on_floor() \
			and (man.is_on_floor() or (man.is_on_wall() and man.velocity.y >= 0.0)) \
			and _height_of(man) > stats.get_reach_height() + REACH_TOLERANCE


## How far apart, in px, the man's feet and the demon's are in height, above it or below it.
func _height_of(man: Node2D) -> float:
	return absf(global_position.y - man.global_position.y)


## For its states, after an attack: backs off from the man with Retreat Distance in Stats, and
## starts on this same physics frame of delta seconds; with none, or with him already that far,
## chases him again. Each time, it draws its Retreat Distance and Retreat Speed anew, so two demons
## that attacked together back off apart.
func back_off_or_chase(delta: float) -> void:
	_retreat_after_bite = false
	_retreat_distance_draw = _rng.randf_range(-1.0, 1.0)
	_retreat_speed_draw = _rng.randf_range(-1.0, 1.0)
	if stats.retreat_distance > 0.0 and is_instance_valid(_target) \
			and absf(get_gap_to_target()) < retreat_distance():
		_recover_frames_left = 0
		change_state_and_act(State.RETREAT, delta)
	elif _state != State.CHASE:
		change_state(State.CHASE)


## For its states: true while the demon is after the man.
func has_target() -> bool:
	return is_instance_valid(_target)


## Keeps the man's speed along the floor up to date while the demon is after him.
func _track_target(delta: float) -> void:
	if not is_instance_valid(_target):
		return
	var x: float = _target.global_position.x
	_target_speed = (x - _target_last_x) / delta
	_target_last_x = x


## For its states: true while the man is still there to chase, not past Lose Distance, nor hidden
## by a wall for Give Up Time, and, with Chases Only On Screen, the demon still on the screen.
## Otherwise the demon stops chasing him; hidden by a wall, with Search Time, it goes to look for
## him where it last saw him (ADR 0035).
func keeps_after_target() -> bool:
	if not is_instance_valid(_target) or not may_chase_from_here() \
			or global_position.distance_to(_target.global_position) > stats.lose_distance:
		_stop_chasing()
		return false
	if _senses.can_see(_target):
		_unseen_frames = 0
		_last_seen_x = _target.global_position.x
		_seen_on_frame = Engine.get_physics_frames()
	else:
		_unseen_frames += 1
	if _unseen_frames >= stats.get_give_up_frames():
		if stats.search_time > 0.0:
			_forget_target()
			change_state(State.SEARCH)
		else:
			_stop_chasing()
		return false
	return true


## For its states: the man's x the last time the demon saw him.
func get_last_seen_x() -> float:
	return _last_seen_x


## For its states: faces the man, or a spot, gap px away along the floor, + to the right. Right
## below him, it keeps its facing.
func turn_to(gap: float) -> void:
	if gap != 0.0:
		_facing = signf(gap)


## For its states: goes the man's way at Chase Speed, and stops at the end of the floor. Never
## further than the gap, so a demon right below the man stands still instead of shaking, and a bite
## on the run never takes it past him; nor nearer than Pack Spacing to the body of a demon ahead of
## it. Nearer, as after it crossed that one on its way back, it steps back at its Retreat Speed,
## still facing the man, until it is that far. While the man takes no hits, it comes no nearer to
## him than Retreat Distance, and steps back to it the same way.
func go_after(gap: float, delta: float) -> void:
	var direction: float = signf(gap)
	var room: float = absf(gap)
	if target_takes_no_hits():
		room -= retreat_distance()
	var ahead: Demon = _packmate_ahead(gap)
	if ahead != null:
		var apart: float = absf(ahead.global_position.x - global_position.x)
		room = minf(room, apart - 2.0 * _half_size.x - stats.pack_spacing)
	var speed: float = clampf(room / delta, -retreat_speed(), _chase_speed())
	if is_on_floor() and is_edge_ahead(direction * signf(speed)):
		velocity.x = 0.0
		return
	velocity.x = direction * speed


## This demon's own Chase Speed, by its draw of Pack Variation.
func _chase_speed() -> float:
	return stats.chase_speed * _varied(_chase_speed_draw)


## For its states: this demon's own Retreat Speed, by its draw of Pack Variation.
func retreat_speed() -> float:
	return stats.retreat_speed * _varied(_retreat_speed_draw)


## For its states: this demon's own Retreat Distance, by its draw of Pack Variation.
func retreat_distance() -> float:
	return stats.retreat_distance * _varied(_retreat_distance_draw)


## For its states: the longest, in physics frames, this demon backs off for, by its own Retreat
## Distance and Retreat Speed.
func retreat_max_frames() -> int:
	return stats.get_retreat_max_frames(
			_varied(_retreat_distance_draw), _varied(_retreat_speed_draw))


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
	_forget_target()
	stand_or_return()


## Lets go of the man, and stops.
func _forget_target() -> void:
	_target = null
	_target_box = null
	_target_hurtbox = null
	velocity.x = 0.0


## For its states: with Return Speed, walks back to its post; with none, or already there, stands
## where it is.
func stand_or_return() -> void:
	if stats.return_speed > 0.0 and absf(_post_x - global_position.x) > POST_REACH:
		change_state(State.RETURN)
	else:
		change_state(State.IDLE)


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


## For its states, on each physics frame of delta seconds of the chase: the first of the demon's
## attacks it starts at the man, or null. It only attacks from its floor, at a man it sees this
## frame and who takes hits, once a bite on the run's Recover Time is over, which this counts down,
## and when the attack's chance comes up. Each time it becomes able to, it first waits a new draw of
## up to Max Hesitation (ADR 0027). The chance is rolled before the lunge is aimed and the floor is
## looked for, which takes many rays: the odds are the same either way.
func attack_to_start(gap: float, delta: float) -> DemonAttack:
	_recover_frames_left = maxi(_recover_frames_left - 1, 0)
	if not is_on_floor() or _unseen_frames != 0 or _recover_frames_left > 0 \
			or target_takes_no_hits():
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
	var distance: float = lunge_distance_to(attack, gap)
	return distance > 0.0 and _has_floor_along_lunge(attack, distance)


## For its states: how far the attack's lunge goes from here, in px, to land where the man, gap px
## away along the floor, + to the right, will be.
func lunge_distance_to(attack: DemonAttack, gap: float) -> float:
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


## For its states: true while the man's Hurtbox lets no hit land, so an attack now could do nothing
## to him.
func target_takes_no_hits() -> bool:
	return is_instance_valid(_target_hurtbox) and not _target_hurtbox.takes_hits()


## The first Hurtbox among the man's children, where its scene puts it, or null. Looked for once,
## when the chase starts, by index, so no list is made.
func _hurtbox_of(man: Node2D) -> Hurtbox:
	for index: int in man.get_child_count():
		var hurtbox: Hurtbox = man.get_child(index) as Hurtbox
		if hurtbox != null:
			return hurtbox
	return null


## For its states: true when the floor ends just ahead of the demon's front, going in direction.
func is_edge_ahead(direction: float) -> bool:
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


## For its states, and the only way the demon changes state: the state it leaves tidies up, the new
## one sets up, and the Hitbox follows the new state at once, so a push from the crucifix stops the
## attack in the same frame. Changing to the state it is in starts that state again.
func change_state(new_state: State) -> void:
	var previous: State = _state
	_current.exit()
	_state = new_state
	_current = _states[new_state]
	_current.enter()
	_update_hitbox()
	state_changed.emit(previous, new_state)


## Keeps the Hitbox on only while the attack under way can land: a bite on the run for its Bite
## Time after its warning, a lunge from take-off until it lands. Turned on, it takes the attack's
## damage and knockback.
func _update_hitbox() -> void:
	var can_land: bool = _bite_frames_left > 0 or _current.can_land_hit()
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
	change_state(State.GRAB)


## The man broke free and throws it off, away from him, facing him all the way.
func _on_hitbox_hold_ended(hurtbox: Hurtbox) -> void:
	if _state != State.GRAB:
		return
	_throw_off(hurtbox.global_position, false)


## Throws the demon off along the floor, away from from; right on it, the way it faces away from.
## With repelled_on_landing, it stays still for Repelled Time once it lands.
func _throw_off(from: Vector2, repelled_on_landing: bool) -> void:
	var direction: float = signf(global_position.x - from.x)
	if direction == 0.0:
		direction = -_facing
	(_states[State.THROWN] as DemonThrownState).aim(direction, repelled_on_landing)
	change_state(State.THROWN)


## The touch of the crucifix is a hit (ADR 0021): it throws the demon off, away from the crucifix.
## While thrown, a push only moves it, so the crucifix pushing on in the first frames of the throw
## does not start the throw again.
func _on_repellable_repelled(origin: Vector2) -> void:
	if _state != State.THROWN:
		_throw_off(origin, true)
