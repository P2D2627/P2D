extends Resource

## How the man dies in brambles (#263): the freeze as they catch him, then the hedge pulls him in
## (Pulled In, the default), about half a second, as long as the body shows in the deaths the
## research measured. Two looks tried and turned down stay, off: the thorns cut him apart (Cut
## Apart), and vines wrap round him (Vines); with Cut Apart and Pulled In off, he buckles and slumps
## into them. Angles in degrees, lengths in the world's px, speeds in px/s.

## How long the game freezes as the brambles catch him, while his drawing flashes white: the one
## freeze in the game, long enough to see, short enough not to hold the restart back.
@export_range(0.0, 0.5, 0.01, "suffix:s") var hitstop: float = 0.1
## How fast the game runs during the freeze, as a share of its speed: slow enough to look stopped,
## never 0, since a stopped clock gives every script a delta of 0 and some divide by it (the
## camera's follow speed, the dogs' chase).
@export_range(0.001, 1.0, 0.001) var hitstop_time_scale: float = 0.02
## How many times a second his pose changes, as the game's other effects: in between, he holds it,
## as a hand-drawn frame does.
@export_range(1.0, 60.0, 1.0, "suffix:fps") var frame_rate: float = 20.0
## On, the thorns slash across him during the freeze and he falls apart along the slashes. Off by
## default: tried and turned down. It goes before Pulled In.
@export var cut_apart: bool = false
## On, the hedge pulls him in (the group Pull): on a floor hedge he goes straight under, fast, as a
## demon's grab sinks him; off, he buckles and slumps (the groups Buckle and Slump).
@export var pulled_in: bool = true

@export_group("Pull")
## How many thorny vines grow out of the hedge and wrap round him, from his legs up, as it pulls.
## None by default: tried and turned down.
@export_range(0, 5) var vines: int = 0
## Where the lowest and the highest vine wrap round him, as a share of his height from his feet; the
## others evenly in between. Below his head, which goes under last.
@export_range(0.0, 1.0, 0.01) var vine_first: float = 0.18
@export_range(0.0, 1.0, 0.01) var vine_last: float = 0.7
## When, after the freeze, the vines have grown all the way round him. At 0 they are round him in the
## freeze already, the frame of the hit: one touch kills, so the grab is the hit.
@export_range(0.0, 1.0, 0.01, "suffix:s") var grab_time: float = 0.0
## When, after the freeze, the hedge has pulled him all the way in: as the screen goes dark, so he is
## seen going under until the fade. The pull speeds up as it goes, as if sucked in.
@export_range(0.05, 2.0, 0.01, "suffix:s") var pull_end: float = 0.6
## On, he is cut at his feet as he goes under, as in a demon's grab: what goes below the floor is
## behind its rock, and he is all gone by Pull End; off, he stays drawn whole as he is pulled down
## Pull Depth, over the floor's rock.
@export var pull_clips: bool = true
## How far down a floor hedge pulls him, with Pull Clips off: his height and a quarter.
@export_range(0.0, 400.0, 1.0, "suffix:px") var pull_depth: float = 120.0
## His drawing's z while pulled, with Pull Clips off: above the floor's rock and its rim (0), and,
## later in the tree, still behind the hedge (1).
@export_range(-10, 10) var pull_z: int = 1
## How long the vines take to draw back into the hedge once he has gone under.
@export_range(0.0, 1.0, 0.01, "suffix:s") var retract_time: float = 0.1
## How far a vine's root is out from under the side of him it climbs, along the hedge.
@export_range(0.0, 60.0, 1.0, "suffix:px") var vine_spread: float = 10.0
## How far a vine bows out on its way from the hedge to him.
@export_range(0.0, 60.0, 1.0, "suffix:px") var vine_bend: float = 14.0
## How far a vine sags across the front of him, as a rope does.
@export_range(0.0, 30.0, 1.0, "suffix:px") var wrap_sag: float = 6.0
## How far each vine's bend writhes, at most, on each frame of the effects.
@export_range(0.0, 20.0, 0.5, "suffix:px") var vine_writhe: float = 3.0
## How much of his body's width a vine crosses, and how much lower or higher its far end is.
@export_range(0.1, 1.5, 0.05) var wrap_share: float = 0.85
@export_range(0.0, 30.0, 1.0, "suffix:px") var wrap_tilt: float = 6.0
## How long the curl at a vine's end is, going round behind him.
@export_range(0.0, 30.0, 1.0, "suffix:px") var vine_hook: float = 8.0
## A vine's stem, and the ink round it, as wide as these.
@export_range(0.5, 10.0, 0.5, "suffix:px") var vine_width: float = 2.0
@export_range(0.0, 5.0, 0.5, "suffix:px") var vine_ink_width: float = 1.0
@export var vine_colour: Color = Color(0.72, 0.68, 0.72)
## Thorns along each vine, every Thorn Spacing px, one side then the other.
@export_range(0.5, 10.0, 0.5, "suffix:px") var thorn_size: float = 3.0
@export_range(2.0, 40.0, 1.0, "suffix:px") var thorn_spacing: float = 9.0
## Leaves on each vine, on the half nearer the hedge.
@export_range(0, 4) var leaves_per_vine: int = 2
@export_range(0.5, 12.0, 0.5, "suffix:px") var leaf_size: float = 4.0
@export var leaf_colour: Color = Color(0.75, 0.15, 0.5)
## While it pulls, he jerks this far to either side and tilts this much, a new way each frame of the
## effects, as if struggling. None by default: he goes straight under, as in a demon's grab.
@export_range(0.0, 10.0, 0.5, "suffix:px") var jerk_px: float = 0.0
@export_range(0.0, 20.0, 0.5, "suffix:deg") var jerk_tilt: float = 0.0
## By a wall or a ceiling, where he does not go under, how far they pull him into the hedge.
@export_range(0.0, 60.0, 1.0, "suffix:px") var wall_pull: float = 10.0

@export_group("Cut")
## How many slashes cross him; he falls apart into one piece more.
@export_range(1, 4) var cuts: int = 3
## Where the first and the last slash cross him, as a share of his height from the top of his body;
## the others are evenly in between. Above a little over half his height, so on a floor hedge, which
## hides the rest of him, the cuts show: through his head, his neck and his chest.
@export_range(0.0, 1.0, 0.01) var cut_first: float = 0.18
@export_range(0.0, 1.0, 0.01) var cut_last: float = 0.52
## How far the slashes tilt from level, all the same way, the side and each amount new each death,
## as claw marks. Two slashes next to each other must not cross within the pieces' box: with three
## slashes between the shares above, the tilts may differ by about 12 at most.
@export_range(0.0, 40.0, 1.0, "suffix:deg") var cut_tilt_min: float = 12.0
@export_range(0.0, 40.0, 1.0, "suffix:deg") var cut_tilt_max: float = 24.0
## How far each slash's middle slides along it, at most, as a share of its length, so the marks are
## not stacked.
@export_range(0.0, 0.5, 0.01) var slash_stagger: float = 0.25
## How much of his frame's width the pieces cover, centred: every frame of his drawing stays inside
## this share (a quarter of the frame free on each side was measured on all his sheets).
@export_range(0.1, 1.0, 0.01) var cut_box_share: float = 0.68
## How long a slash is drawn, as a share of his body's width: past him on both sides, so it reads.
@export_range(1.0, 5.0, 0.1) var slash_length: float = 2.4
## The slash's bright core and its glow, as wide as these in px.
@export_range(0.5, 10.0, 0.5, "suffix:px") var slash_core_width: float = 2.0
@export_range(0.5, 20.0, 0.5, "suffix:px") var slash_glow_width: float = 5.0
@export var slash_core_colour: Color = Color(1.0, 0.89, 0.96)
@export var slash_glow_colour: Color = Color(0.91, 0.27, 0.67, 0.6)
## How long the slashes take to fade once the freeze is over; they also grow by Slash Growth times
## their length a second meanwhile.
@export_range(0.01, 1.0, 0.01, "suffix:s") var slash_fade: float = 0.1
@export_range(0.0, 10.0, 0.5) var slash_growth: float = 3.0
## The ink drawn along the cut on each piece, in px.
@export_range(0.0, 6.0, 0.5, "suffix:px") var cut_ink_width: float = 1.5
## The top piece is thrown this fast to the side, and the others less the lower they are; every other
## piece goes the other way, at Counter Push of the speed.
## About 1.5 to 2 of his heights a second for the top piece, within the 2 to 8 the research measured
## for pieces and spray.
@export_range(0.0, 600.0, 1.0, "suffix:px/s") var push_speed: float = 140.0
@export_range(0.0, 1.0, 0.05) var counter_push: float = 0.7
## The top piece is thrown up this fast, and the others less the lower they are.
@export_range(0.0, 600.0, 1.0, "suffix:px/s") var pop_speed: float = 200.0
## The top piece spins this fast, and the others less the lower they are.
@export_range(0.0, 1440.0, 1.0, "suffix:deg/s") var spin_speed: float = 300.0
## How high above the floor a piece's middle comes to rest, as a share of its own height: at a half,
## its bottom is on the floor, inside the hedge drawn in front of it.
@export_range(0.0, 1.0, 0.05) var rest_share: float = 0.5
## The farthest a piece falls when there is no floor under him, as by a wall.
@export_range(0.0, 2000.0, 10.0, "suffix:px") var fall_reach: float = 400.0
## When, after the freeze, the pieces start fading into the ink, and how long they take.
@export_range(0.0, 2.0, 0.05, "suffix:s") var fade_start: float = 0.3
@export_range(0.05, 2.0, 0.05, "suffix:s") var fade_time: float = 0.3
## How dark, towards the ink, a piece is when it has faded.
@export_range(0.0, 1.0, 0.05) var fade_ink: float = 0.6
@export var ink: Color = Color(0.07, 0.03, 0.05)

@export_group("Buckle")
## How long after the freeze his knees give: he squashes and starts to tilt.
@export_range(0.01, 1.0, 0.01, "suffix:s") var buckle_time: float = 0.12
## His height at the buckle, as a share of his own; his width grows by half of what he loses.
@export_range(0.5, 1.0, 0.01) var buckle_squash: float = 0.88
## How far he tilts at the buckle.
@export_range(0.0, 90.0, 1.0, "suffix:deg") var buckle_tilt: float = 6.0

@export_group("Slump")
## When, after the freeze, he has slumped all the way and stays.
@export_range(0.02, 2.0, 0.01, "suffix:s") var slump_time: float = 0.45
## His height once slumped, as a share of his own.
@export_range(0.5, 1.0, 0.01) var slump_squash: float = 0.95
## How far he tilts once slumped on a floor hedge, the way he faces.
@export_range(0.0, 90.0, 1.0, "suffix:deg") var slump_tilt: float = 20.0
## How far he tilts once slumped on a wall or a ceiling hedge, into it: less, since the hedge is
## drawn in front of him and more would hide his head in it.
@export_range(0.0, 90.0, 1.0, "suffix:deg") var wall_tilt: float = 8.0
## The most he sinks into a floor hedge. He sinks until his feet reach the floor it grows from, so
## falling into it he settles in it, and walking into it, his feet already on the floor, he does
## not sink into the rock beside it. The part that kills is 24 px tall, so he is never caught higher.
@export_range(0.0, 96.0, 1.0, "suffix:px") var sink_px: float = 24.0
