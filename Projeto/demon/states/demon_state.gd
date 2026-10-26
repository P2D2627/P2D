class_name DemonState
extends RefCounted

## One of a Demon's states (ADR 0034): what the demon does in it on each physics frame, what it sets
## up as it starts it and what it tidies as it leaves it. The demon makes one of each in _ready and
## keeps them while it lives, so changing state makes nothing new. It changes between them only
## through its change_state, which emits state_changed with the Demon.State that the art, the sounds
## and the tests read. A state is part of its demon: it moves the demon's body, and asks it about the
## man, its floor and its attacks through the methods the demon keeps for its states.

var _demon: Demon


func _init(demon: Demon) -> void:
	_demon = demon


## The demon starts this state, right after leaving the one it was in, and before state_changed.
func enter() -> void:
	pass


## The demon leaves this state, right before it starts the next one.
func exit() -> void:
	pass


## What the demon does in this state on a physics frame of delta seconds: after the gravity pulls
## it, and before it moves.
func physics_update(_delta: float) -> void:
	pass


## What pulls the demon down in this state while it is in the air: the world's gravity, unless the
## state has its own.
func get_gravity() -> Vector2:
	return _demon.get_gravity()


## True while an attack in this state can land, so the demon's Hitbox is on.
func can_land_hit() -> bool:
	return false
