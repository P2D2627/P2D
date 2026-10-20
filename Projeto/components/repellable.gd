class_name Repellable
extends Area2D

## Marks what the crucifix pushes away, such as demons and lost souls. It is used through its scene,
## components/repellable.tscn, which puts it on the repellable physics layer, the one the crucifix
## looks on, and keeps it from looking for anything itself: instance the scene as a child of the
## thing to push, give it a CollisionShape2D child and set Target. It is the only part of that thing
## the crucifix knows: the demon's or the soul's own script only listens to repelled, for an
## animation or to let go of a soul it holds.

## Pushed this physics frame by a crucifix at origin.
signal repelled(origin: Vector2)

## What moves when pushed. A CharacterBody2D moves with move_and_collide(), so it stops at walls;
## any other Node2D just moves.
@export var target: Node2D
## Pushes sideways only, for what walks, such as demons: the crucifix is held above the man's feet,
## so a push aimed straight at a walker's feet points into the floor and stops there. Off for what
## flies, such as lost souls.
@export var along_floor: bool = false


func _ready() -> void:
	assert(target != null, "Repellable: assign the node to push to Target.")


## Pushes target distance px straight away from origin, and says so with repelled. Right at origin,
## it goes up. Along Floor, it goes sideways away from origin instead, and right below it, right.
func push_away_from(origin: Vector2, distance: float) -> void:
	var direction: Vector2 = origin.direction_to(target.global_position)
	if along_floor:
		direction = Vector2.LEFT if target.global_position.x < origin.x else Vector2.RIGHT
	elif direction == Vector2.ZERO:
		direction = Vector2.UP
	var motion: Vector2 = direction * distance
	var body: CharacterBody2D = target as CharacterBody2D
	if body != null:
		body.move_and_collide(motion)
	else:
		target.global_position += motion
	repelled.emit(origin)
