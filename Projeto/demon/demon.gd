class_name Demon
extends CharacterBody2D

## A demon that chases the man: the one scene of every level's demons (ADR 0019). What kind of
## demon it is comes from Stats, such as lust_demon_stats.tres, and where it lives is where the
## level puts it. It never jumps up nor climbs: it chases along its own floor, stops at an edge, and
## a step stops it, so the level's own shape keeps it in its place. It sees the man inside Sight
## Distance with no wall in between, keeps on chasing him past it, and stops when he gets past Lose
## Distance or a wall has hidden him for Give Up Time. With the man inside the Attack Range of one
## of its attacks (ADR 0020), on about its own floor, and the attack's chance coming up, it warns
## for the attack's Warning Time. In a lunge, it aims, as the warning starts, where the man will be
## when it lands, and needs him ahead of it and floor all the way there: it stops to warn, lunges
## where it aimed, and stays where it lands for the attack's Recover Time. In a bite on the run, it
## chases on while it warns, bites where it is, and chases on with no attack for Recover Time. The
## man's raised crucifix pushes it out of its radius through its Repellable, from any state; the
## demon then stays still until Repelled Time after the last push. It only tells what it does, by
## state_changed and warning_started: the art and the sounds listen, and it never touches them.

## The demon changed from previous to current this physics frame.
signal state_changed(previous: State, current: State)
## The demon started warning of attack this physics frame, right after state_changed to WARNING, so
## the art and the sounds can show which attack is coming.
signal warning_started(attack: DemonAttack)

## LUNGE lasts from take-off until the attack's Recover Time after landing.
enum State { IDLE, CHASE, WARNING, LUNGE, REPELLED }

## How far apart, in px, the floor is looked for along a lunge: half a tile, so no hole is missed.
const FLOOR_CHECK_STEP: float = 24.0

@export var stats: DemonStats

var _state: State = State.IDLE
## The man, while the demon chases him.
var _target: Node2D = null
## The man, while he is inside the sight area, seen or not.
var _in_sight_area: Node2D = null
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
## Physics frames the demon has warned for, or has stood on the floor since landing a lunge.
var _state_frames: int = 0
## Physics frames left, after a bite on the run, before the demon can attack again.
var _recover_frames_left: int = 0
## The physics frame the crucifix last pushed the demon in.
var _pushed_frame: int = 0
## The physics frame the game paused in, while it is paused.
var _paused_frame: int = 0
## Rolls the attacks' chances. Each demon has its own, seeded from the global generator, which moves
## on with each seed it gives, so demons put in on the same frame do not lunge together.
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var _sight_area: Area2D = %SightArea
@onready var _sight_shape: CollisionShape2D = %SightShape
## Looks from the demon's eyes to the man's, at the same height on him, since both are about the
## same size. Only the world blocks it: one-way platforms do not hide him.
@onready var _line_of_sight: RayCast2D = %LineOfSight
## Looks down just ahead of the demon's front. With no floor within its length, the floor ends
## there.
@onready var _ledge_check: RayCast2D = %LedgeCheck
## How far ahead of the demon's middle LedgeCheck looks, in px, set in the scene.
@onready var _ledge_reach: float = absf(_ledge_check.position.x)
@onready var _repellable: Repellable = %Repellable


func _ready() -> void:
	assert(stats != null, "Demon: assign a DemonStats to Stats.")
	for attack: DemonAttack in stats.attacks:
		assert(attack != null and attack.animation in DemonAttack.ANIMATIONS,
				"Demon: every attack in Attacks needs a DemonAttack with one of its ANIMATIONS.")
		assert(attack.lunge_min_distance <= attack.lunge_distance,
				"Demon: an attack's Lunge Min Distance must be no more than its Lunge Distance.")
	_rng.seed = randi()
	_sight_area.body_entered.connect(_on_sight_area_body_entered)
	_sight_area.body_exited.connect(_on_sight_area_body_exited)
	_repellable.repelled.connect(_on_repellable_repelled)
	stats.changed.connect(_apply_stats)
	_apply_stats()


func _physics_process(delta: float) -> void:
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
	move_and_slide()


## The physics frames go on counting through a pause, so the frame of the last push moves on as many
## frames as the pause lasted, and a pause never shortens Repelled Time.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED:
		_paused_frame = Engine.get_physics_frames()
	elif what == NOTIFICATION_UNPAUSED:
		_pushed_frame += Engine.get_physics_frames() - _paused_frame


func get_state() -> State:
	return _state


## The world's gravity, or the lunge's own while the demon is on a lunge: a quick, low arc needs
## more gravity than the world's.
func _get_current_gravity() -> Vector2:
	if _state == State.LUNGE:
		return Vector2.DOWN * _attack.get_lunge_gravity()
	return get_gravity()


func _physics_idle() -> void:
	velocity.x = 0.0
	if is_instance_valid(_in_sight_area) and _can_see(_in_sight_area):
		_target = _in_sight_area
		_target_last_x = _target.global_position.x
		_target_speed = 0.0
		_unseen_frames = 0
		_change_state(State.CHASE)


func _physics_chase(delta: float) -> void:
	if not _keeps_after_target():
		return
	_recover_frames_left = maxi(_recover_frames_left - 1, 0)
	var gap: float = _target.global_position.x - global_position.x
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


## Before a lunge, still, since the chase stopped the demon when the warning started; before a bite
## on the run, chasing on.
func _physics_warning(delta: float) -> void:
	if _attack.keeps_chasing:
		_physics_bite_on_the_run(delta)
		return
	_state_frames += 1
	if _state_frames >= _attack.get_warning_frames():
		velocity = _attack.get_lunge_velocity(_lunge_distance) * Vector2(_facing, 1.0)
		_state_frames = 0
		_change_state(State.LUNGE)


## Chases on while it warns, and at the end bites where it is and goes back to the chase, where it
## cannot attack for the bite's Recover Time.
func _physics_bite_on_the_run(delta: float) -> void:
	if not _keeps_after_target():
		return
	var gap: float = _target.global_position.x - global_position.x
	_turn_to(gap)
	_go_after(gap, delta)
	_state_frames += 1
	if _state_frames >= _attack.get_warning_frames():
		_recover_frames_left = _attack.get_recover_frames()
		_change_state(State.CHASE)


## In the air, the lunge keeps its speed across; on the floor, the demon stays put for the attack's
## Recover Time.
func _physics_lunge() -> void:
	if not is_on_floor():
		return
	velocity.x = 0.0
	_state_frames += 1
	if _state_frames >= _attack.get_recover_frames():
		_change_state(State.CHASE)


## Still, since the push stopped the demon. It counts from the frame of the last push, which the
## crucifix makes in its own physics step, so the count is the same whichever of the two runs first.
func _physics_repelled() -> void:
	if Engine.get_physics_frames() - _pushed_frame >= stats.get_repelled_frames():
		_change_state(State.CHASE if is_instance_valid(_target) else State.IDLE)


## Keeps the man's speed along the floor up to date while the demon is after him.
func _track_target(delta: float) -> void:
	if not is_instance_valid(_target):
		return
	var x: float = _target.global_position.x
	_target_speed = (x - _target_last_x) / delta
	_target_last_x = x


## True while the man is still there to chase: not past Lose Distance, nor hidden by a wall for Give
## Up Time. Otherwise the demon stops chasing him.
func _keeps_after_target() -> bool:
	if not is_instance_valid(_target) \
			or global_position.distance_to(_target.global_position) > stats.lose_distance:
		_stop_chasing()
		return false
	_unseen_frames = 0 if _can_see(_target) else _unseen_frames + 1
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
## it past him.
func _go_after(gap: float, delta: float) -> void:
	var direction: float = signf(gap)
	if is_on_floor() and _is_edge_ahead(direction):
		velocity.x = 0.0
		return
	velocity.x = direction * minf(stats.chase_speed, absf(gap) / delta)


func _stop_chasing() -> void:
	_target = null
	velocity.x = 0.0
	_change_state(State.IDLE)


## The first of the demon's attacks it starts at the man on this physics frame of delta seconds, or
## null. It only attacks from its floor, at a man it sees this frame, once a bite on the run's
## Recover Time is over, and when the attack's chance comes up. The chance is rolled before the
## lunge is aimed and the floor is looked for, which takes many rays: the odds are the same either
## way.
func _attack_to_start(gap: float, delta: float) -> DemonAttack:
	if not is_on_floor() or _unseen_frames != 0 or _recover_frames_left > 0:
		return null
	for attack: DemonAttack in stats.attacks:
		if _has_man_in_range(attack, gap) and _rolls(attack, delta) \
				and (attack.keeps_chasing or _can_lunge(attack, gap)):
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


## True when no wall stands between the demon's eyes and the man's.
func _can_see(man: Node2D) -> bool:
	_line_of_sight.target_position = _line_of_sight.to_local(
			man.global_position + _line_of_sight.position)
	_line_of_sight.force_raycast_update()
	return not _line_of_sight.is_colliding()


## True when the floor ends just ahead of the demon's front, going in direction.
func _is_edge_ahead(direction: float) -> bool:
	return not _has_floor_at(_ledge_reach * direction)


## True when LedgeCheck finds floor offset_x px from the demon's middle, + to the right.
func _has_floor_at(offset_x: float) -> bool:
	_ledge_check.position.x = offset_x
	_ledge_check.force_raycast_update()
	return _ledge_check.is_colliding()


func _apply_stats() -> void:
	(_sight_shape.shape as CircleShape2D).radius = stats.sight_distance


func _change_state(new_state: State) -> void:
	var previous: State = _state
	_state = new_state
	state_changed.emit(previous, new_state)


func _on_sight_area_body_entered(body: Node2D) -> void:
	_in_sight_area = body


func _on_sight_area_body_exited(body: Node2D) -> void:
	if body == _in_sight_area:
		_in_sight_area = null


## The push stops the demon: it no longer goes across nor up. In the air, it falls with the world's
## gravity from where it was, so a push in the middle of a lunge never takes it above Lunge Height.
func _on_repellable_repelled(_origin: Vector2) -> void:
	_pushed_frame = Engine.get_physics_frames()
	velocity.x = 0.0
	velocity.y = maxf(velocity.y, 0.0)
	if _state != State.REPELLED:
		_change_state(State.REPELLED)
