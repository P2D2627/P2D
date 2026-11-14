class_name DemonBackBite
extends Area2D

## The bite on a demon's back (ADR 0056): it bites whoever lands on the demon, as a dog bites in an
## attack, so the man can't ride a pack. Its hit is a bite's: it takes its SP and throws him off or,
## with his SP low, grabs him, and the demon holds him while he falls through it, to sink on the
## floor below and never on a back (KnockOff). It throws him away from the demon's middle, as any
## hit, but to the other side when a wall on Wall Layers leaves him no room beside the demon on that
## side, so he is never thrown against the wall and back onto the demon. It lands within any
## invulnerability of his, even the one after he breaks free of a grab, so every landing bites. It
## looks for him in the space just above the demon's top, tall enough that he is found before he
## lands however fast he falls, and arms its Hitbox on each frame he lands on the demon: the frame
## the demon becomes the floor of his move, also when he is shoved onto it from the next back. So it
## never bites one who only passes through the demon (ADR 0047) or brushes it from the side or from
## below. One who walks onto it from a floor as high as its top is found only once the shove has
## taken him back off, so he is not bitten, but he never stands on it either. Each landing bites
## once: the first bite to land puts away the others armed for him, as on two demons side by side,
## and no other arms for him until he is off the floor, as when a grab drops him through the demon
## onto the next one's back. The Hitbox takes what its hit does from Stats as it arms, as an
## attack's does, and is in the physics only while armed; off, the whole bite is out of the
## physics, so a demon without it pays nothing for it. Give it a CollisionShape2D child for the
## space above the top, as wide as the demon, looking on the man's body layer, and a Hitbox child
## with the same shape; it and its Hitbox start Disabled in the scene.

## Its Hitbox's hit holds the man, and he broke free: the demon hears these as its own Hitbox's.
signal hold_started(hurtbox: Hurtbox)
signal hold_ended(hurtbox: Hurtbox)

## How much shorter than the man, in px at his head and at his feet, the room he needs beside the
## demon is, so a floor or a ceiling that only touches that room does not take it.
const ROOM_MARGIN: float = 1.0

@export var hitbox: Hitbox
## The demon whose back it is.
@export var body: PhysicsBody2D
## The physics layers of the walls that can leave the man no room beside the demon, so the bite
## throws him to its other side.
@export_flags_2d_physics var wall_layers: int = 1

## The bites armed now, of every demon, so the first to land on a man puts away the others armed for
## him.
static var _armed: Array[DemonBackBite] = []
## The men a bite landed on since they were last off the floor: their landing is bitten, so a back
## they come onto without leaving the floor is no new landing.
static var _bitten: Array[CharacterBody2D] = []

## What the bite does: the demon's stats, which the demon gives it.
var stats: DemonStats = null
## The body in the space above the demon's top, or null.
var _rider: CharacterBody2D = null
## True while the rider stood on the demon after his last move: a landing is the frame this turns
## true.
var _standing: bool = false
## The room the man needs beside the demon, as asked of the physics when the bite arms.
var _room: RectangleShape2D = RectangleShape2D.new()
var _room_query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()


func _ready() -> void:
	assert(hitbox != null, "DemonBackBite: assign its Hitbox child to Hitbox.")
	assert(body != null, "DemonBackBite: assign the demon to Body.")
	set_physics_process(false)
	hitbox.pierces_any_invulnerability = true
	_room_query.shape = _room
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	hitbox.hit_landed.connect(_on_hitbox_hit_landed)
	hitbox.hold_started.connect(hold_started.emit)
	hitbox.hold_ended.connect(hold_ended.emit)


## Runs only while a body is above the demon's top: arms the bite on each frame he lands on the
## demon, unless his landing was bitten already. The man moves before the demons, so this sees his
## move of this frame.
func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_rider):
		_disarm()
		return
	if not _rider.is_on_floor():
		_bitten.erase(_rider)
	var standing: bool = KnockOff.floor_body_of(_rider) == body
	if standing and not _standing and not _bitten.has(_rider):
		_arm()
	_standing = standing


func _exit_tree() -> void:
	_armed.erase(self)


## On, it bites whoever lands on the demon; off, it is out of the physics.
func set_on(on: bool) -> void:
	set_deferred(&"process_mode", PROCESS_MODE_INHERIT if on else PROCESS_MODE_DISABLED)
	if not on:
		_disarm()


## The body above the demon's top, as the one on its back, or null.
func get_rider() -> Node2D:
	return _rider if is_instance_valid(_rider) else null


## Into the physics at the end of this frame's scripts, as out of it, so the last asked for wins;
## its overlap is found in this frame's step and it lands on the next. Still armed from a landing
## whose bite has not landed, it stays as it is.
func _arm() -> void:
	if hitbox.is_active():
		return
	hitbox.damage = stats.get_back_bite_damage()
	hitbox.knockback_distance = stats.back_bite_knockback_distance
	hitbox.knockback_height = stats.back_bite_knockback_height
	hitbox.knockback_side = _open_side()
	hitbox.set_deferred(&"process_mode", PROCESS_MODE_INHERIT)
	hitbox.activate()
	_armed.append(self)


## The rider left: no one to bite until the next one comes.
func _disarm() -> void:
	set_physics_process(false)
	_rider = null
	_standing = false
	_put_away()


## Out of the physics at the end of this frame's scripts, since a body leaving can't change it while
## the physics reports it.
func _put_away() -> void:
	_armed.erase(self)
	hitbox.deactivate()
	hitbox.set_deferred(&"process_mode", PROCESS_MODE_DISABLED)


## The way to throw the rider: 0 away from the demon's middle, as any hit, unless that side has no
## room for him beside the demon, as by a wall: then the other side, 1 to the right or -1 to the
## left. With room on neither, as in a hole, he falls back onto the demon either way, and a grab
## ends the bites.
func _open_side() -> float:
	var away: float = 1.0 if _rider.global_position.x >= hitbox.global_position.x else -1.0
	return 0.0 if _has_room(away) else -away


## True when the rider's body fits beside the demon on side, 1 to the right or -1 to the left, from
## the demon's face out and from its top up, with his safe margin on each side: no wall on Wall
## Layers takes any of that room.
func _has_room(side: float) -> bool:
	var demon_box: Rect2 = KnockOff.box_of(body)
	var man_size: Vector2 = KnockOff.box_of(_rider).size
	_room.size = Vector2(man_size.x + 2.0 * _rider.safe_margin, man_size.y - 2.0 * ROOM_MARGIN)
	var face: float = demon_box.end.x if side > 0.0 else demon_box.position.x
	var middle: Vector2 = body.global_position + Vector2(face + side * _room.size.x / 2.0,
			demon_box.position.y - man_size.y / 2.0)
	_room_query.transform = Transform2D(0.0, middle)
	_room_query.collision_mask = wall_layers
	return get_world_2d().direct_space_state.intersect_shape(_room_query, 1).is_empty()


## Its bite landed on the rider: it and those armed for him by other demons are put away, and his
## landing is bitten, so each landing bites once, also on two demons at once. Men gone from the
## scene are forgotten here.
func _on_hitbox_hit_landed(_hurtbox: Hurtbox) -> void:
	for index: int in range(_armed.size() - 1, -1, -1):
		var armed: DemonBackBite = _armed[index]
		if armed != self and armed._rider == _rider:
			armed._put_away()
	_put_away()
	for index: int in range(_bitten.size() - 1, -1, -1):
		if not is_instance_valid(_bitten[index]):
			_bitten.remove_at(index)
	if is_instance_valid(_rider) and not _bitten.has(_rider):
		_bitten.append(_rider)


func _on_body_entered(entered: Node2D) -> void:
	var rider: CharacterBody2D = entered as CharacterBody2D
	if rider == null or is_instance_valid(_rider):
		return
	_rider = rider
	set_physics_process(true)


func _on_body_exited(exited: Node2D) -> void:
	if exited == _rider:
		_disarm()
