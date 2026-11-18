extends Resource

## The values of the dark that covers a restart (#263): how long it takes to cover the screen at the
## end of the wait after the man's death and to uncover it in the new copy, and how it is drawn. By
## default the whole screen fades out and in; with Iris on, it closes as an iris on his body and
## opens on him instead, at the rate of the effects.

## On, an iris closes on his body and opens on him; off, the whole screen fades out and in.
@export var iris: bool = false
## Seconds the dark takes to cover the screen, at the end of the wait after a death.
@export_range(0.05, 1.0, 0.05, "suffix:s") var close_time: float = 0.3
## Seconds the dark takes to uncover the screen in the new copy. He plays from its first frame, so a
## longer one only softens it.
@export_range(0.05, 1.0, 0.05, "suffix:s") var open_time: float = 0.35
## How much the fade eases at its quiet end: the dark grows as time to this power, so it starts
## faint, while the death still shows, and closes firmly; the new copy lightens the other way round,
## most of it at once and the last of it slowly. 1 is even throughout.
@export_range(1.0, 4.0, 0.1) var fade_ease: float = 2.0
## Frames a second the iris moves at: the rate of the game's effects, as a hand-drawn wipe steps. The
## fade is smooth; it is all dark for the last of these frames too, so the swap happens on black.
@export_range(1.0, 60.0, 1.0, "suffix:fps") var frame_rate: float = 20.0
## How far its edge wanders in and out of a circle, in px, so it reads drawn by hand.
@export_range(0.0, 40.0, 1.0, "suffix:px") var wobble_px: float = 8.0
## How many bumps its edge has around the circle.
@export_range(1, 16) var wobble_lobes: int = 7
## The share of the radius the wobble never passes, so a small iris stays round.
@export_range(0.0, 0.5, 0.01) var wobble_share: float = 0.15
## Its colour: pure black, so the cut away from the level carries none of the level's tint.
@export var ink: Color = Color.BLACK
