class_name DemonStats
extends Resource

## What a kind of demon is: how far it sees, how fast it chases, and its attacks. All the demons of
## one level share one file, such as lust_demon_stats.tres, with its attacks inside it, and a new
## level's demons are another file with the same fields. Where a demon is placed and the art it
## shows are not here. Sight Distance and Pack Spacing say when they change, so the demon resizes
## what it sees and the room it keeps at once, also while the game runs and they are changed in the
## Remote tab; the others are read each time they are used.

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
## The share of Sight Distance the demon sees behind it, the way it does not face: at 1 it sees as
## far all round; lower, the man can get past at its back.
@export_range(0.0, 1.0, 0.05) var sight_behind_share: float = 1.0
## On, the demon starts a chase only while its body is on the screen, and gives up as soon as it is
## off it, so no demon the player cannot see comes after him (ADR 0032). With no camera, as in the
## tests, all of the world counts as on the screen.
@export var chases_only_on_screen: bool = false

@export_group("Post")
## Speed, in px/s, at which the demon walks back to its post, where it was put in the level, once it
## gives up. At 0 it stays where it gave up. If the end of its floor or a wall stops it on the way,
## as when a throw took it to another floor, where it stops is its post from then on (ADR 0032).
@export_range(0.0, 1000.0, 10.0, "suffix:px/s") var return_speed: float = 0.0

@export_group("Chase")
## Speed, in px/s, at which the demon drags itself towards the man. Below the man's running speed,
## so running away always works.
@export_range(0.0, 2000.0, 10.0, "suffix:px/s") var chase_speed: float = 560.0

@export_group("Attacks")
## The demon's attacks, in order: of those it can start at the man, it starts the first in the
## list. With none, it only chases.
@export var attacks: Array[DemonAttack] = []

@export_group("Retreat")
## How far from the man, in px, the demon backs off after each attack, landed or not, before it
## chases him again (ADR 0023): past the bite's Attack Range, so it has to come back to bite again
## and never stays on him. 0 never backs off: it chases on after its attacks.
@export_range(0.0, 1000.0, 10.0, "suffix:px") var retreat_distance: float = 0.0
## Speed, in px/s, at which it backs off, facing the man, and steps back to Pack Spacing from a
## demon too near ahead of it. Below Chase Speed, so it reads as backing off. It backs off for at
## most the time Retreat Distance takes at this speed, so a man who follows it, or an edge or a wall
## behind it, never keeps it from coming back.
@export_range(10.0, 2000.0, 10.0, "suffix:px/s") var retreat_speed: float = 400.0

@export_group("Pack")
## How far, in px, the demon keeps its body from the body of another demon that stands between it
## and the man and is not backing off: it keeps that far behind it, or steps back to it, and attacks
## from there, so two demons never look like one (ADR 0024). 0 keeps no distance: they can share a
## spot.
@export_range(0.0, 500.0, 2.0, "suffix:px") var pack_spacing: float = 0.0:
	set(value):
		pack_spacing = value
		emit_changed()
## How much, as a share of each, a demon's Chase Speed, Retreat Speed and Retreat Distance can be
## above or below these: each demon draws its own Chase Speed once, when it is put in the level, and
## its Retreat Speed and Retreat Distance again each time it backs off, so two that come together
## drift apart instead of moving in step (ADR 0024, ADR 0027). 0 makes them all the same.
@export_range(0.0, 0.5, 0.01) var pack_variation: float = 0.0
## Most seconds a demon waits, once it can attack, before it may: each time it becomes able to, as
## when an attack is over or the man stops blinking, it draws a new wait from 0 to this, so demons
## that the same moment sets free do not attack together (ADR 0027). 0 never waits.
@export_range(0.0, 2.0, 0.05, "suffix:s") var max_hesitation: float = 0.0

@export_group("Crucifix")
## Seconds the demon stays still once it lands from the crucifix's throw, before it can chase again.
@export_range(0.0, 5.0, 0.05, "suffix:s") var repelled_time: float = 0.3

@export_group("Thrown")
## How far, in px along the floor, the man throws the demon off when he breaks free of its grab
## (ADR 0021), so he has room before it comes back.
@export_range(0.0, 1000.0, 10.0, "suffix:px") var throw_distance: float = 200.0
## Highest point of the throw, in px above where it was. Below one tile, so a throw never lands the
## demon on a step.
@export_range(1.0, 200.0, 1.0, "suffix:px") var throw_height: float = 40.0
## Seconds from the throw to its highest point; on flat floor, the way down takes as long. The throw
## has its own gravity, worked out from this and Throw Height, as a lunge has, so it can be quick.
@export_range(0.05, 1.0, 0.01, "suffix:s") var throw_time_to_peak: float = 0.15
## Seconds the demon lies stunned once it lands from the man's throw, still and with no attack,
## before it backs off from him or chases him again (ADR 0028), so breaking free gives him time to
## get away. Apart from Repelled Time: the crucifix pushes, breaking free knocks down. 0 goes on at
## once.
@export_range(0.0, 5.0, 0.05, "suffix:s") var stunned_time: float = 0.0


## Downward acceleration while the demon is thrown, in px/s², from Throw Height and Throw Time To
## Peak.
func get_throw_gravity() -> float:
	return 2.0 * throw_height / (throw_time_to_peak * throw_time_to_peak)


## The velocity of a throw going right: it peaks at Throw Height after Throw Time To Peak and lands
## Throw Distance away on flat floor, with the half-frame corrections of a lunge
## (DemonAttack.get_lunge_velocity): half a frame of gravity off the upward speed, and half a frame
## more in the air for the speed across.
func get_throw_velocity() -> Vector2:
	var frame_time: float = 1.0 / Engine.physics_ticks_per_second
	var time_across: float = 2.0 * throw_time_to_peak + frame_time / 2.0
	return Vector2(throw_distance / time_across,
			-get_throw_gravity() * (throw_time_to_peak - frame_time / 2.0))


## give_up_time in whole physics frames, rounded to the nearest one.
func get_give_up_frames() -> int:
	return _to_frames(give_up_time)


## repelled_time in whole physics frames, rounded to the nearest one.
func get_repelled_frames() -> int:
	return _to_frames(repelled_time)


## stunned_time in whole physics frames, rounded to the nearest one.
func get_stunned_frames() -> int:
	return _to_frames(stunned_time)


## The most physics frames a retreat lasts: the time Retreat Distance takes at Retreat Speed, for a
## demon whose own are these times distance_scale and speed_scale, by Pack Variation.
func get_retreat_max_frames(distance_scale: float = 1.0, speed_scale: float = 1.0) -> int:
	return _to_frames(retreat_distance * distance_scale / (retreat_speed * speed_scale))


## A wait of share of Max Hesitation, share from 0 to 1, in whole physics frames.
func get_hesitation_frames(share: float) -> int:
	return _to_frames(max_hesitation * share)


func _to_frames(seconds: float) -> int:
	return roundi(seconds * Engine.physics_ticks_per_second)
