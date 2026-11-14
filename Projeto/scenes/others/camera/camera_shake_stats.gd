class_name CameraShakeStats
extends Resource

## How the screen shakes after an impact (ShakeTrauma). How much trauma each impact adds is the
## impacts' own, in ImpactStats; this is how a given trauma looks.

## The farthest the screen moves from where the camera puts it, to each side and up and down, at
## full trauma, in px on the screen. Small, so a shake next to a level's edge shows little past it.
@export_range(0.0, 64.0, 1.0, "suffix:px") var max_offset: float = 32.0
## How much trauma goes away each second. From 2 up, even full trauma is gone half a second after the
## last impact, so no shake lasts longer than that (ADR 0061); hence the floor of the range.
@export_range(2.0, 10.0, 0.1, "suffix:1/s") var decay: float = 2.0
## The shake is the trauma to this power. At 2, half the trauma shakes a quarter as much, so light
## knocks stay light and only the big ones shake hard.
@export_range(1.0, 4.0, 0.1) var exponent: float = 2.0
## How fast the screen trembles. Each unit makes it pass its resting place about 1.35 times a second,
## so about 13 at 10: a heavy jolt rather than a buzz (measured at 60 frames a second).
@export_range(1.0, 40.0, 0.5) var speed: float = 10.0
