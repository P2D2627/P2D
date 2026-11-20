class_name DemonBackBite
extends Area2D

## The bite on a demon's back (ADR 0056): it bites whoever stands on the demon, as a dog bites in an
## attack, so the man can't ride a pack. Its hit is a bite's: it takes its SP and knocks him back
## by the Back Bite values of Stats, by default a hop in place, or, with his SP low, grabs him, and
## the demon holds him while he falls through it, to sink on the floor below and never on a back
## (KnockOff). A throw along the floor goes away from the demon's middle, as any hit, but to the
## other side when a wall on Wall Layers leaves him no room beside the demon on that side, so he is
## never thrown against the wall and back onto the demon. It lands within any
## invulnerability of his, even the one after he breaks free of a grab. It looks for him in the
## space just above the demon's top, tall enough that he is found before he lands however fast he
## falls, and arms its Hitbox on each frame he stands on the demon, the demon the floor of his move,
## once Back Bite Interval has passed since a bite on a back last took him, this demon's or any
## other's, or at once if none has (#271). So he is bitten as he lands, and again every Back Bite
## Interval he stays, never more often, also going from back to back, so the flashes stay under
## three a second. While its bite is on, the demon is in KnockOff's Stand On Group: nothing shoves
## him off its top, and he stays until he walks or jumps off. It never bites one who only passes
## through the demon (ADR 0047) or brushes it from the side or from below. The first bite to land
## puts away the others armed for him, as on two demons side by side. The Hitbox takes what its hit
## does from Stats as it arms, as an attack's does, and is in the physics only while armed; off,
## the whole bite is out of the physics, so a demon without it pays nothing for it. Give it a
## CollisionShape2D child for the space above the top, as wide as the demon, looking on the man's
## body layer, and a Hitbox child with the same shape; it and its Hitbox start Disabled in the
## scene.

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
## The physics frame on which a bite on a back, of any demon, last landed on each man, by his
## instance ID: none bites him again until Back Bite Interval has passed.
static var _last_bite_frames: Dictionary[int, int] = {}

## What the bite does: the demon's stats, which the demon gives it.
var stats: DemonStats = null
## The body in the space above the demon's top, or null.
var _rider: CharacterBody2D = null
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


## Runs only while a body is above the demon's top: arms the bite on each frame he stands on the
## demon, once Back Bite Interval has passed since a bite on a back last took him. The man moves
## before the demons, so this sees his move of this frame.
func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_rider):
		_disarm()
		return
	if KnockOff.floor_body_of(_rider) == body and _may_bite(_rider):
		_arm()


func _exit_tree() -> void:
	_armed.erase(self)


## On, it bites whoever stands on the demon, and the demon is in KnockOff's Stand On Group, so the
## man is not shoved off it; off, it is out of the physics, and the demon shoves him off as before.
func set_on(on: bool) -> void:
	set_deferred(&"process_mode", PROCESS_MODE_INHERIT if on else PROCESS_MODE_DISABLED)
	if on:
		body.add_to_group(KnockOff.STAND_ON_GROUP)
	else:
		body.remove_from_group(KnockOff.STAND_ON_GROUP)
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


## True when no bite on a back has landed on man yet, or Back Bite Interval has passed since the
## last one did.
func _may_bite(man: CharacterBody2D) -> bool:
	var id: int = man.get_instance_id()
	if not _last_bite_frames.has(id):
		return true
	return Engine.get_physics_frames() - _last_bite_frames[id] \
			>= stats.get_back_bite_interval_frames()


## Its bite landed on the rider: it and those armed for him by other demons are put away, so only
## one bites, also on two demons at once, and the frame is kept for him, so none bites him again
## before Back Bite Interval. Men gone from the scene are forgotten here.
func _on_hitbox_hit_landed(_hurtbox: Hurtbox) -> void:
	for index: int in range(_armed.size() - 1, -1, -1):
		var armed: DemonBackBite = _armed[index]
		if armed != self and armed._rider == _rider:
			armed._put_away()
	_put_away()
	for id: int in _last_bite_frames.keys():
		if not is_instance_id_valid(id):
			_last_bite_frames.erase(id)
	if is_instance_valid(_rider):
		_last_bite_frames[_rider.get_instance_id()] = Engine.get_physics_frames()


func _on_body_entered(entered: Node2D) -> void:
	var rider: CharacterBody2D = entered as CharacterBody2D
	if rider == null or is_instance_valid(_rider):
		return
	_rider = rider
	set_physics_process(true)


func _on_body_exited(exited: Node2D) -> void:
	if exited == _rider:
		_disarm()
