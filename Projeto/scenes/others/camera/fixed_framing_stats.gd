class_name FixedFramingStats
extends Resource
## How FixedFraming frames the man: one zoom, centred across and a little under the screen's centre, a dead zone
## that takes in a jump, a capped critically damped follow, a short lead when he runs, a look down when he falls,
## the screen kept inside the level's outline and a chimney's axis held. With the zoom fixed, the dead zone is in
## px of the world; what is about the screen's shape is in shares of the screen.

@export_group("Framing")
## The one zoom. At 1.4, with the man at Below Centre, a screen in level 1 shows on average about as much plain
## rock as the zones camera (tests/measures/measure_camera_space.gd).
@export_range(1.0, 2.5, 0.01) var zoom_level: float = 1.4
## How far under the screen's centre the man's middle sits when he stands, as a share of the screen's height: the
## floor under him is rock, so a screen with him lower shows less of it.
@export_range(0.0, 0.4, 0.01) var below_centre: float = 0.25
## How close to the screen's edges his body may ever come, as a share of the screen: at least the camera's own
## Edge Margin, so the way back to it never has to push the screen.
@export_range(0.0, 0.45, 0.01) var edge_margin: float = 0.1

@export_group("Dead Zone")
## How far he moves to either side, in px of the world, before the screen follows: about 2 % of the screen's width.
@export_range(0.0, 200.0, 1.0, "suffix:px") var dead_zone_across: float = 28.0
## In the air, how far above where the screen frames him he may go before it follows: a whole jump (his Stats'
## Jump Height, read when the brain begins) and this much more, in px of the world, so no jump moves the screen
## whatever the zoom. On the floor the screen frames him again.
@export_range(0.0, 100.0, 1.0, "suffix:px") var jump_room: float = 8.0
## In the air, how far below where the screen frames him he may go before it follows, in px of the world.
@export_range(0.0, 300.0, 1.0, "suffix:px") var dead_zone_down: float = 40.0

@export_group("Follow")
## How fast the screen closes on where it should be, per second: a critically damped spring. While he moves at
## an even speed the spring would lag 2 / sharpness s behind him, so the screen aims that far ahead of him.
@export_range(0.5, 30.0, 0.1, "suffix:1/s") var follow_sharpness: float = 8.0
## The screen never moves faster than this, in px/s: the zones camera's Zone Change Speed.
@export_range(100.0, 10000.0, 10.0, "suffix:px/s") var max_speed: float = 2000.0
## How fast the zoom eases to Zoom Level after a switch, per second, on a log scale.
@export_range(0.5, 20.0, 0.1, "suffix:1/s") var zoom_sharpness: float = 2.5

@export_group("Look Ahead")
## How far the screen leads to the side he runs, as a share of its width; back to nothing when he stops.
@export_range(0.0, 0.3, 0.01) var look_ahead: float = 0.05
## Above this speed across he counts as running, in px/s.
@export_range(0.0, 1000.0, 10.0, "suffix:px/s") var look_ahead_speed: float = 100.0
@export_range(0.5, 20.0, 0.1, "suffix:1/s") var look_ahead_sharpness: float = 3.0

@export_group("Look Down")
## After falling this long, in s, the screen shows what is under him. A whole jump comes back down to its floor in
## about 0.28 s, so a jump never looks down.
@export_range(0.0, 2.0, 0.01, "suffix:s") var fall_delay: float = 0.35
## Where his middle sits while he falls, as a share of the screen's height under the centre: negative, above it.
@export_range(-0.4, 0.4, 0.01) var fall_below_centre: float = -0.15
@export_range(0.5, 30.0, 0.1, "suffix:1/s") var look_down_sharpness: float = 7.0

@export_group("Map")
## How far past the outermost open cell he can reach the screen may show, in tiles.
@export_range(0, 20, 1, "suffix:tiles") var map_margin: int = 2
## The widest open space across, in tiles, between rock on both sides of his middle, that counts as a chimney:
## there the screen holds the chimney's axis and does not lead, so wall jumps do not swing it.
@export_range(0, 20, 1, "suffix:tiles") var chimney_width: int = 6
## How many rows, in tiles, that narrow space must run up and down for a chimney: a niche or a pit is lower.
@export_range(1, 30, 1, "suffix:tiles") var chimney_height: int = 6
