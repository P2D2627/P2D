class_name DemonAttack
extends Resource

## One of a demon's attacks (ADR 0020): when the demon starts it, how long it warns, the lunge it
## makes, and the animation the art shows for it. A demon's DemonStats lists its attacks, so a new
## level's demons can have other attacks without new code. The values are read each time they are
## used, so they can be tuned in the Remote tab while the game runs.

## The animations the demon's art is to have for its attacks. A new one goes here, with its art.
const ANIMATIONS: Array[StringName] = [&"bite", &"lunge"]
## The fewest physics frames a warning lasts: the demon shows one even at a Warning Time of 0.
const LEAST_WARNING_FRAMES: int = 1

## The animation the art plays while the demon warns of this attack and lunges in it; the sound of
## the warning goes by it too. One of ANIMATIONS: the demon checks it when it starts.
@export var animation: StringName = &"lunge"
## On, the demon keeps chasing the man while it warns, and then bites where it is, with no lunge: a
## bite on the run. The lunge's distances, Lead, Lunge Height and Lunge Time To Peak are then not
## used, nor is floor looked for along a lunge, since the chase already stops at an edge; Recover
## Time is how long the demon chases on before it can attack again.
@export var keeps_chasing: bool = false
## Distance, in px along the floor, under which the demon starts its warning before this attack. 0
## turns the attack off.
@export_range(0.0, 1000.0, 10.0, "suffix:px") var attack_range: float = 360.0
## Most height difference, in px, between the demon's feet and the man's for it to attack, so it
## only attacks a man on about its own floor. Below one tile, so a man on a step is safe.
@export_range(0.0, 200.0, 1.0, "suffix:px") var max_height_difference: float = 24.0
## Seconds the demon shows its warning before it attacks. At 0 it still warns for one physics frame.
@export_range(0.0, 3.0, 0.05, "suffix:s") var warning_time: float = 0.35
## Most distance, in px, the lunge covers from take-off to landing on flat floor: it lands where the
## man will be, but no further than this.
@export_range(0.0, 1000.0, 10.0, "suffix:px") var lunge_distance: float = 420.0
## Least distance, in px, the lunge covers, so it is never a little hop: at a man who will be
## nearer, it lands past him. No more than Lunge Distance: the demon checks it as it starts, and a
## lunge never goes past Lunge Distance even so.
@export_range(0.0, 1000.0, 10.0, "suffix:px") var lunge_min_distance: float = 200.0
## How much of the man's going the lunge's aim takes in, from 0 to 1: at 0 it lands where he is as
## the demon starts warning, at 1 where he will be when it lands, if he keeps the speed he had then.
## The aim is kept from then on, like the lunge's direction, so a man who changes pace or turns
## while the demon warns makes it miss.
@export_range(0.0, 1.0, 0.05) var lead: float = 1.0
## Highest point, in px above take-off, of a lunge of Lunge Distance; a shorter one rises less, in
## step with its distance. Below one tile, so a step of one tile stops a demon even when it lunges.
@export_range(1.0, 200.0, 1.0, "suffix:px") var lunge_height: float = 32.0
## Seconds from take-off to the highest point of a lunge of Lunge Distance; on flat floor, the way
## down takes as long. The lunge has its own gravity, worked out from this and Lunge Height, so a
## lunge can be quick and low, like a pounce, without the world's gravity tying its speed to its
## height. Every lunge of the attack has that gravity and the same angle, like a jump with less
## force, so a shorter one is lower and quicker.
@export_range(0.05, 1.0, 0.01, "suffix:s") var lunge_time_to_peak: float = 0.15
## Seconds the demon stays still after landing the lunge, before it can chase again; with Keeps
## Chasing, seconds it chases on after the bite before it can attack again.
@export_range(0.0, 3.0, 0.05, "suffix:s") var recover_time: float = 0.35
## Chance, from 0 to 1, that the demon starts this attack within any one second the man stays where
## it could: 1 starts it at once, 0 never. It is rolled on every physics frame and comes to the same
## at any frame rate. Below 1, a lunge can come at any distance inside its range, so it can be read
## but not foreseen.
@export_range(0.0, 1.0, 0.05) var chance_per_second: float = 1.0


## warning_time in whole physics frames, rounded to the nearest one, and never fewer than the one
## frame the demon always warns for, so the aim counts the warning the demon shows.
func get_warning_frames() -> int:
	return maxi(roundi(warning_time * Engine.physics_ticks_per_second), LEAST_WARNING_FRAMES)


## The chance the demon starts this attack on one physics frame of delta seconds: over the frames of
## one second, the chance that it never does comes to 1 - Chance Per Second.
func get_chance_in(delta: float) -> float:
	return 1.0 - pow(1.0 - chance_per_second, delta)


## recover_time in whole physics frames, rounded to the nearest one.
func get_recover_frames() -> int:
	return roundi(recover_time * Engine.physics_ticks_per_second)


## Downward acceleration during the lunge, in px/s², the same for every lunge of the attack. Comes
## from lunge_height and lunge_time_to_peak.
func get_lunge_gravity() -> float:
	assert(lunge_time_to_peak > 0.0, "DemonAttack: Lunge Time To Peak must be above 0.")
	return 2.0 * lunge_height / (lunge_time_to_peak * lunge_time_to_peak)


## How far the lunge goes, in px, to land where the man will be: ahead px in front of the demon as
## it starts warning, going away from it at speed px/s, or towards it below 0, times Lead, until the
## lunge lands. A shorter lunge lands sooner, so with u the distance's square root, he is where it
## lands when u² = soonest + per_root × u: soonest, how far ahead he will be when a lunge of 0 px
## would land, and per_root, how much further for each unit of u. The distance is that equation's
## greater root, squared. Never nearer than Lunge Min Distance nor further than Lunge Distance; 0
## when he will be level with the demon or behind it as the lunge lands, with nothing to lunge at.
func get_lunge_distance_to(ahead: float, speed: float) -> float:
	if lunge_distance <= 0.0:
		return 0.0
	var going: float = speed * lead
	var soonest: float = ahead + going * get_time_to_landing(0.0)
	var per_root: float = going * 2.0 * lunge_time_to_peak / sqrt(lunge_distance)
	var discriminant: float = per_root * per_root + 4.0 * soonest
	if discriminant < 0.0:
		return 0.0
	var root: float = (per_root + sqrt(discriminant)) / 2.0
	var distance: float = clampf(root * root, minf(lunge_min_distance, lunge_distance),
			lunge_distance)
	if ahead + going * get_time_to_landing(distance) <= 0.0:
		return 0.0
	return distance


## Seconds from the start of the warning to landing on flat floor after a lunge of distance px: the
## warning, in whole physics frames, and the lunge's time across.
func get_time_to_landing(distance: float) -> float:
	return float(get_warning_frames()) / Engine.physics_ticks_per_second + get_lunge_time(distance)


## Seconds across, take-off to landing on flat floor, that the speed across of a lunge of distance
## px is worked out for: twice its time to peak, and half a frame more. The floor only stops the
## demon at the end of the frame it gets there in, from none to one frame late, so it then lands
## within half a frame's move of where it was aimed.
func get_lunge_time(distance: float) -> float:
	return 2.0 * get_lunge_time_to_peak(distance) + 0.5 / Engine.physics_ticks_per_second


## Seconds from take-off to the highest point of a lunge of distance px: Lunge Time To Peak for one
## of Lunge Distance, times the square root of its share of it. With get_lunge_height, every lunge
## of the attack has the lunge's gravity and the same angle.
func get_lunge_time_to_peak(distance: float) -> float:
	return lunge_time_to_peak * sqrt(distance / lunge_distance)


## Highest point, in px above take-off, of a lunge of distance px: Lunge Height for one of Lunge
## Distance, and in step with its distance for a shorter one.
func get_lunge_height(distance: float) -> float:
	return lunge_height * distance / lunge_distance


## The take-off velocity of a lunge of distance px, going right: up as fast as the lunge's gravity
## slows down to nothing in its time to peak, so it peaks at its height then, and across fast enough
## to land distance away on flat floor after its time across. The physics moves in whole frames and
## the first one rises at full speed, so half a frame of the lunge's gravity comes off the upward
## speed to keep the peak on its height.
func get_lunge_velocity(distance: float) -> Vector2:
	var frame_time: float = 1.0 / Engine.physics_ticks_per_second
	return Vector2(distance / get_lunge_time(distance),
			-get_lunge_gravity() * (get_lunge_time_to_peak(distance) - frame_time / 2.0))


## The farthest, in px from take-off, the demon's middle can land on flat floor in a lunge of
## distance px: that and half a frame's move more, since the floor stops it up to a frame late.
func get_lunge_reach(distance: float) -> float:
	return distance + get_lunge_velocity(distance).x / (2.0 * Engine.physics_ticks_per_second)
