class_name ImpactStats
extends Resource

## How hard the screen shakes at each moment that hits the man, as trauma from 0 to 1 (ShakeTrauma):
## the shake is the trauma squared, so 0.5 shakes a quarter as hard as 1. Trauma adds up, so moments
## that come together shake for both, but for the presses to break free and breaking free, which
## raise it to their own level. What puts him in danger shakes the screen; his everyday moves, a
## normal jump or landing, never do.

@export_group("The man")
## A hit from a demon or a hazard.
@export_range(0.0, 1.0, 0.05) var hit_trauma: float = 0.5
## A demon grabs him. A grab always starts with a hit, so this goes on top of Hit Trauma.
@export_range(0.0, 1.0, 0.05) var grab_trauma: float = 0.2
## Each press of Jump that counts towards breaking free raises the trauma to this, and no higher, so
## pressing fast keeps a jolt per press instead of piling up; below Hit Trauma, so a hit still weighs
## more. Holding Jump, with Hold To Escape, shakes nothing.
@export_range(0.0, 1.0, 0.05) var struggle_trauma: float = 0.45
## He breaks free of a grab: the trauma rises to this, whatever the presses left, so the release is
## the grab's strongest jolt, above the hit and the grab together, with presses or with Hold To
## Escape.
@export_range(0.0, 1.0, 0.05) var break_free_trauma: float = 0.9
## He dies: the strongest, all the trauma there is, above even breaking free.
@export_range(0.0, 1.0, 0.05) var death_trauma: float = 1.0
## He lands after a long fall, the landing PlayerSounds hears as hard: the man is heavy.
@export_range(0.0, 1.0, 0.05) var hard_landing_trauma: float = 0.45

@export_group("Crucifix")
## He raises the crucifix: a light pulse, once, and nothing while he holds it up.
@export_range(0.0, 1.0, 0.05) var crucifix_raised_trauma: float = 0.35
## He loses the crucifix.
@export_range(0.0, 1.0, 0.05) var crucifix_lost_trauma: float = 0.5

@export_group("Falling rock")
## A rock that breaks right where he is.
@export_range(0.0, 1.0, 0.05) var rock_trauma: float = 0.55
## How far from him a breaking rock still shakes the screen, less the farther it is, in px.
@export_range(0.0, 4000.0, 10.0, "suffix:px") var rock_reach: float = 900.0


## The trauma of a rock that breaks distance px from the man: all of Rock Trauma where he is, less
## the farther it is, and none from Rock Reach on.
func rock_trauma_at(distance: float) -> float:
	if rock_reach <= 0.0:
		return 0.0
	return rock_trauma * clampf(1.0 - distance / rock_reach, 0.0, 1.0)
