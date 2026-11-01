class_name Hurtbox
extends Area2D

## What takes damage, such as the man. It is used through its scene, components/hurtbox.tscn, which
## puts it on the player_hurtbox physics layer, looking on enemy_hitbox. Instance the scene as a
## child of what gets hurt, give it a CollisionShape2D child and listen to hit_received: the Hurtbox
## only says it was hit, and its owner decides what the hit does, and for how long no other hit
## lands, with start_invulnerability(). In each physics frame, every active Hitbox it overlaps lands
## once per activation, unless it is invulnerable, also when an earlier hit of the same frame made
## it so, or closed. Closed, with set_closed(), no hit lands for as long as its owner says, as with
## the man held by as many demons as can hold him (ADR 0029), but it is not invulnerable, so nothing
## blinks; opened again, a Hitbox that overlapped all along lands at once.

## Hit by hitbox this physics frame.
signal hit_received(hitbox: Hitbox)

## The Hitboxes it overlaps, kept up to date by area_entered and area_exited, so no list is made in
## each frame.
var _overlapping: Array[Hitbox] = []
## Physics frames left in which no hit lands. They run down in the physics frames only, so the
## pause never shortens them.
var _invulnerable_frames_left: int = 0
## True while its owner keeps it closed: no hit lands.
var _closed: bool = false


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


## The hits land first and the invulnerability runs down after them, so one started from
## hit_received or before this frame lasts the same number of frames.
func _physics_process(_delta: float) -> void:
	for i: int in range(_overlapping.size() - 1, -1, -1):
		if not is_instance_valid(_overlapping[i]):
			_overlapping.remove_at(i)
			continue
		var hitbox: Hitbox = _overlapping[i]
		if takes_hits() and hitbox.can_land_on(self):
			hitbox.land_on(self)
			hit_received.emit(hitbox)
	if _invulnerable_frames_left > 0:
		_invulnerable_frames_left -= 1


## No hit lands for the next seconds, in whole physics frames. A shorter time never cuts a longer
## one short.
func start_invulnerability(seconds: float) -> void:
	var frames: int = roundi(seconds * Engine.physics_ticks_per_second)
	_invulnerable_frames_left = maxi(_invulnerable_frames_left, frames)


func is_invulnerable() -> bool:
	return _invulnerable_frames_left > 0


## Closed, no hit lands until it is opened again; it does not count as invulnerable meanwhile.
func set_closed(closed: bool) -> void:
	_closed = closed


## True while a hit can land: neither invulnerable nor closed. What attacks reads it, so it starts
## no attack that could do nothing.
func takes_hits() -> bool:
	return not _closed and not is_invulnerable()


func _on_area_entered(area: Area2D) -> void:
	var hitbox: Hitbox = area as Hitbox
	if hitbox != null and not _overlapping.has(hitbox):
		_overlapping.append(hitbox)


func _on_area_exited(area: Area2D) -> void:
	var hitbox: Hitbox = area as Hitbox
	if hitbox != null:
		_overlapping.erase(hitbox)
