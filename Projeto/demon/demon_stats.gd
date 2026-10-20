class_name DemonStats
extends Resource

## What a kind of demon is: how far it sees, how fast it chases, and its attacks. All the demons of
## one level share one file, such as lust_demon_stats.tres, with its attacks inside it, and a new
## level's demons are another file with the same fields. Where a demon is placed and the art it
## shows are not here. Sight Distance says when it changes, so the demon resizes what it sees at
## once, also while the game runs and it is changed in the Remote tab; the others are read each time
## they are used.

@export_group("Senses")
## How near, in px, the man has to come for the demon to see him, with no wall in between.
@export_range(0.0, 2000.0, 10.0, "suffix:px") var sight_distance: float = 480.0:
	set(value):
		sight_distance = value
		emit_changed()
## How far, in px, the man has to get for the demon to stop chasing him at once. Above Sight
## Distance, so a man right at the edge does not start and stop the chase every frame.
@export_range(0.0, 3000.0, 10.0, "suffix:px") var lose_distance: float = 720.0
## Seconds the demon keeps chasing a man it cannot see, behind a wall, before it gives up.
@export_range(0.0, 10.0, 0.1, "suffix:s") var give_up_time: float = 1.5

@export_group("Chase")
## Speed, in px/s, at which the demon drags itself towards the man. Below the man's running speed,
## so running away always works.
@export_range(0.0, 2000.0, 10.0, "suffix:px/s") var chase_speed: float = 560.0

@export_group("Attacks")
## The demon's attacks, in order: of those it can start at the man, it starts the first in the
## list. With none, it only chases.
@export var attacks: Array[DemonAttack] = []

@export_group("Crucifix")
## Seconds the demon keeps away after the crucifix last pushed it, before it can chase again.
@export_range(0.0, 5.0, 0.05, "suffix:s") var repelled_time: float = 0.8


## give_up_time in whole physics frames, rounded to the nearest one.
func get_give_up_frames() -> int:
	return _to_frames(give_up_time)


## repelled_time in whole physics frames, rounded to the nearest one.
func get_repelled_frames() -> int:
	return _to_frames(repelled_time)


func _to_frames(seconds: float) -> int:
	return roundi(seconds * Engine.physics_ticks_per_second)
