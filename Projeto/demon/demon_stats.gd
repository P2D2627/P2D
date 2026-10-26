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
## Seconds the demon keeps chasing a man it cannot see, behind a wall, before it gives up, or with
## Search Time goes to look for him where it last saw him.
@export_range(0.0, 10.0, 0.1, "suffix:s") var give_up_time: float = 1.5
## Seconds the demon stands, turned to the man, once it notices him and before it chases him: the
## alert, which the art and the sounds show with a bark (ADR 0035). At 0 it chases him at once.
@export_range(0.0, 2.0, 0.05, "suffix:s") var alert_time: float = 0.0
## Seconds the demon sniffs where it last saw the man, turning round halfway, once a wall has hidden
## him for Give Up Time; then it gives up (ADR 0035). At 0 it gives up at once.
@export_range(0.0, 10.0, 0.1, "suffix:s") var search_time: float = 0.0
## Speed, in px/s, at which it walks to where it last saw the man: slower than the chase.
@export_range(10.0, 1000.0, 10.0, "suffix:px/s") var search_speed: float = 300.0
## Seconds the demon stands facing a man out of its reach before it gives up (ADR 0033): him on a
## floor or a wall higher above or lower below its own than the Max Height Difference of any of its
## attacks. It never follows him along under him or over him.
@export_range(0.0, 10.0, 0.1, "suffix:s") var out_of_reach_wait: float = 2.0
## Width, in px, of the stretch the demon paces to and fro across at Patrol Speed, around where it
## stopped, while the man is out of its reach, so it never stands stiff (ADR 0039). At 0 it stands
## facing him.
@export_range(0.0, 1000.0, 10.0, "suffix:px") var out_of_reach_pace_width: float = 0.0
## Shortest pause, in seconds, where it stops and at each end of that stretch, where it barks turned
## to the man: each demon draws its own every time, so two demons below one man fall out of step.
@export_range(0.0, 5.0, 0.1, "suffix:s") var out_of_reach_pause_min: float = 0.6
## Longest of those pauses, in seconds.
@export_range(0.0, 5.0, 0.1, "suffix:s") var out_of_reach_pause_max: float = 1.2
## The share of Sight Distance the demon sees behind it, the way it does not face: at 1 it sees as
## far all round; lower, the man can get past at its back.
@export_range(0.0, 1.0, 0.05) var sight_behind_share: float = 1.0
## On, the demon starts a chase only while its body is on the screen, and gives up as soon as it is
## off it, so no demon the player cannot see comes after him (ADR 0032). With no camera, as in the
## tests, all of the world counts as on the screen.
@export var chases_only_on_screen: bool = false
## With Chases Only On Screen, how far off the screen, in px, a demon after the man or searching for
## him still goes on. It starts a chase only on the screen but gives up only past this, so a demon by
## the edge of the screen never keeps switching between the chase and the walk back (ADR 0038).
@export_range(0.0, 960.0, 8.0, "suffix:px") var screen_margin: float = 0.0

@export_group("Post")
## Speed, in px/s, at which the demon walks back to its post, where it was put in the level, once it
## gives up. At 0 it stays where it gave up, or with Patrol Width walks its patrol back to around its
## post at Patrol Speed. If the end of its floor or a wall stops it on the way,
## as when a throw took it to another floor, where it stops is its post from then on (ADR 0032).
@export_range(0.0, 1000.0, 10.0, "suffix:px/s") var return_speed: float = 0.0
## Width, in px, of the stretch of its floor the demon walks to and fro across, centred on its post,
## while it has no man to chase (ADR 0033). At 0 it stands at its post. The end of its floor and a
## wall turn it back before the stretch ends.
@export_range(0.0, 2000.0, 10.0, "suffix:px") var patrol_width: float = 0.0
## Speed, in px/s, at which it walks its patrol: a walk, slower than the chase.
@export_range(10.0, 1000.0, 10.0, "suffix:px/s") var patrol_speed: float = 150.0
## Shortest and longest pause, in seconds, before each walk across its patrol: each demon draws its
## own every time, so two demons put together soon drift apart.
@export_range(0.0, 10.0, 0.1, "suffix:s") var patrol_pause_min: float = 0.8
@export_range(0.0, 10.0, 0.1, "suffix:s") var patrol_pause_max: float = 2.0

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


## alert_time in whole physics frames, rounded to the nearest one.
func get_alert_frames() -> int:
	return _to_frames(alert_time)


## search_time in whole physics frames, rounded to the nearest one.
func get_search_frames() -> int:
	return _to_frames(search_time)


## out_of_reach_wait in whole physics frames, rounded to the nearest one.
func get_out_of_reach_frames() -> int:
	return _to_frames(out_of_reach_wait)


## A pause of share of the way from Out Of Reach Pause Min to Max, share from 0 to 1, in whole
## physics frames, and never under one, so pauses at 0 never make a demon bark on every frame.
func get_out_of_reach_pause_frames(share: float) -> int:
	return maxi(_to_frames(lerpf(out_of_reach_pause_min, out_of_reach_pause_max, share)), 1)


## How far above or below the demon's floor, in px, the man is still in its reach: the most Max
## Height Difference of its attacks; 0 with none.
func get_reach_height() -> float:
	var reach: float = 0.0
	for attack: DemonAttack in attacks:
		reach = maxf(reach, attack.max_height_difference)
	return reach


## A pause of share of the way from Patrol Pause Min to Max, share from 0 to 1, in whole physics
## frames.
func get_patrol_pause_frames(share: float) -> int:
	return _to_frames(lerpf(patrol_pause_min, patrol_pause_max, share))


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
