class_name Hazard
extends Area2D

## Something in a level that hurts the player on touch: spikes, a trap, a falling rock. There is no
## health system yet, so a hazard only says that it hit, through player_hit, with the share of the
## player's health the hit takes, and plays its hit sound. A health system can later find every
## hazard in the group and listen to them. While the player stays inside, it hits again every
## Rehit Interval.

## The player touched the hazard. health_fraction is the share of the player's full health it takes.
signal player_hit(player: Node2D, health_fraction: float)

## The group every hazard joins, where a health system can find them.
const GROUP: StringName = &"hazards"

## The share of the player's full health one hit takes: 1 is all of it.
@export_range(0.0, 1.0, 0.05) var health_fraction: float = 0.25
## How often the hazard hits again while the player stays inside it.
@export_range(0.1, 5.0, 0.1, "suffix:s") var rehit_interval: float = 1.0
## Played on every hit. Optional.
@export var hit_sound: AudioStreamPlayer2D

## Time left until the player, still inside, is hit again.
var _time_to_rehit: float = 0.0


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# _physics_process only counts down to the next hit while the player is inside.
	set_physics_process(false)


## A hazard switched off, such as a broken rock, stops hitting at once.
func _physics_process(delta: float) -> void:
	if not monitoring:
		set_physics_process(false)
		return
	var bodies: Array[Node2D] = get_overlapping_bodies()
	if bodies.is_empty():
		set_physics_process(false)
		return
	_time_to_rehit -= delta
	if _time_to_rehit <= 0.0:
		_hit(bodies[0])


func _on_body_entered(body: Node2D) -> void:
	_hit(body)
	set_physics_process(true)


func _hit(body: Node2D) -> void:
	_time_to_rehit = rehit_interval
	if hit_sound != null:
		hit_sound.play()
	player_hit.emit(body, health_fraction)
