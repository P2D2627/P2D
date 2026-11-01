class_name Hitbox
extends Area2D

## What causes damage, such as a demon's bite. It is used through its scene, components/hitbox.tscn,
## which puts it on the enemy_hitbox physics layer and keeps it from looking for anything itself:
## the Hurtbox is the one that looks. Instance the scene as a child of what attacks, give it a
## CollisionShape2D child, and keep it on, with activate(), only while the attack can land. Each
## activation lands at most once on each Hurtbox, however long it stays on and overlapping. A hit
## can also hold what it landed on, as a demon's grab holds the man: the side that took the hit
## decides that, and calls start_hold(), sink_hold() and end_hold(); what attacks listens to
## hold_started, hold_sink_changed and hold_ended.

## Landed on hurtbox this physics frame.
signal hit_landed(hurtbox: Hurtbox)
## Its hit holds hurtbox instead of hurting it, until hold_ended.
signal hold_started(hurtbox: Hurtbox)
## What it holds has sunk this far, from 0 to 1, so what attacks sinks with it (ADR 0026).
signal hold_sink_changed(sink: float)
## Hurtbox is no longer held.
signal hold_ended(hurtbox: Hurtbox)

## What the hit does, which the owner sets from its attack before activate(), so they are not in
## the Inspector: SP it takes, and how far, in px along the floor away from the hitbox, and how high
## it throws what it lands on.
var damage: float = 0.0
var knockback_distance: float = 0.0
var knockback_height: float = 0.0

var _active: bool = false
## The Hurtboxes this activation has landed on, so it lands once on each.
var _landed_on: Array[Hurtbox] = []


## Starts an activation, which can land once on each Hurtbox. While on, it does nothing: a new
## activation needs deactivate() first.
func activate() -> void:
	if _active:
		return
	_active = true
	_landed_on.clear()


func deactivate() -> void:
	_active = false


func is_active() -> bool:
	return _active


## True while on and not yet landed on hurtbox in this activation.
func can_land_on(hurtbox: Hurtbox) -> bool:
	return _active and not _landed_on.has(hurtbox)


## Lands this activation on hurtbox and says so. The Hurtbox that takes the hit calls it.
func land_on(hurtbox: Hurtbox) -> void:
	_landed_on.append(hurtbox)
	hit_landed.emit(hurtbox)


## Its hit holds hurtbox, and says so. The side that took the hit calls it, when it holds instead of
## hurting.
func start_hold(hurtbox: Hurtbox) -> void:
	hold_started.emit(hurtbox)


## What it holds has sunk to sink, from 0 to 1, and says so. The side that called start_hold() calls
## it while the hold lasts, and with 0 before end_hold().
func sink_hold(sink: float) -> void:
	hold_sink_changed.emit(sink)


## Hurtbox is free of the hold, and says so. The side that called start_hold() calls it.
func end_hold(hurtbox: Hurtbox) -> void:
	hold_ended.emit(hurtbox)
