extends Resource

## How the brambles of lethal spikes move (#263): a small sway at rest, a stir when the man comes at
## them, and a thrash and a lean in when he dies on them. Lengths are how far a bramble's top moves
## along its strip, in px; its base never moves. One resource is shared by every strip, so the
## Remote tab tunes them all at once.

@export_group("Drawing")
## How many times a second the brambles' drawing changes, as the game's other effects: in between,
## each holds its pose, as a hand-drawn frame does.
@export_range(1.0, 60.0, 1.0, "suffix:fps") var frame_rate: float = 20.0

@export_group("Sway at rest")
## How far each top sways at rest, at most: a twentieth of a bramble, enough to look alive and too
## little to change the hedge's shape or to look like harmless grass. 0 stops it.
@export_range(0.0, 8.0, 0.1, "suffix:px") var sway_amplitude: float = 2.0
## The shortest and longest time a bramble takes for one sway; each takes its own in between, from
## a start of its own, so no two move together.
@export_range(0.5, 10.0, 0.1, "suffix:s") var sway_period_min: float = 2.5
@export_range(0.5, 10.0, 0.1, "suffix:s") var sway_period_max: float = 4.0

@export_group("Stir")
## How near the man has to come to a bramble's top to stir it: a tile.
@export_range(0.0, 192.0, 1.0, "suffix:px") var stir_radius: float = 48.0
## How fast he must come at a bramble to stir it fully: half his run. Slower stirs it less; still,
## going away or passing it by stirs it not at all.
@export_range(10.0, 1200.0, 10.0, "suffix:px/s") var stir_speed: float = 300.0
## How far a fully stirred top shivers, to a random side each frame.
@export_range(0.0, 8.0, 0.1, "suffix:px") var stir_amplitude: float = 1.5
## How fast a stir fades once he stops coming at it, as the time it takes to fall to about a third;
## at 0.1 s it is gone in about 0.3 s.
@export_range(0.01, 1.0, 0.01, "suffix:s") var stir_fade: float = 0.1

@export_group("Death")
## How far from where he died on them brambles thrash and lean in: three tiles.
@export_range(0.0, 384.0, 1.0, "suffix:px") var thrash_radius: float = 144.0
## How long after his death the nearest brambles start: at once, as they pull him in, big enough to
## show through the screen's shake.
@export_range(0.0, 1.0, 0.01, "suffix:s") var thrash_delay: float = 0.0
## How much later the farthest ones start, so the thrash spreads out from him.
@export_range(0.0, 1.0, 0.01, "suffix:s") var thrash_spread: float = 0.05
## How far the nearest tops thrash, side to side every frame, at first: hard, as they pull him in.
@export_range(0.0, 24.0, 0.5, "suffix:px") var thrash_amplitude: float = 16.0
## How fast the thrash dies down, as the time it takes to fall to about a third; at 0.45 s it lasts
## the pull, until the screen is dark.
@export_range(0.01, 2.0, 0.01, "suffix:s") var thrash_fade: float = 0.45
## How far the nearest tops lean in towards him, and stay, until the room starts over.
@export_range(0.0, 24.0, 0.5, "suffix:px") var lean_amplitude: float = 8.0
## How far to one side of him a bramble must stand to lean in fully; right under him it barely leans.
@export_range(1.0, 96.0, 1.0, "suffix:px") var lean_reach: float = 24.0
## How long the lean takes to settle.
@export_range(0.01, 2.0, 0.01, "suffix:s") var lean_time: float = 0.3
