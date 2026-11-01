class_name CameraStats
extends Resource

## How the game camera follows the player.

@export_group("Window")
## How far the player can go to each side of the focus before the camera follows, in px.
@export_range(0.0, 480.0, 1.0, "suffix:px") var window_half_width: float = 64.0
## How far the player can rise above the focus before the camera follows, in px. Above a full jump.
@export_range(0.0, 540.0, 1.0, "suffix:px") var window_up: float = 250.0
## How far the player can drop below the focus before the camera follows, in px.
@export_range(0.0, 540.0, 1.0, "suffix:px") var window_down: float = 0.0
## How close to the screen's edges the player may come, as a share of the screen, before the camera
## moves at once. 0: only the whole body is kept on the screen.
@export_range(0.0, 0.45, 0.01) var edge_margin: float = 0.17

@export_group("Smoothing")
## How fast the camera closes in on the focus, per second. At 6, 95 % in half a second.
@export_range(0.5, 30.0, 0.1, "suffix:1/s") var follow_sharpness: float = 6.0

@export_group("Look Ahead")
## How far ahead the camera leads, to the side the player is going, in px.
@export_range(0.0, 960.0, 1.0, "suffix:px") var look_ahead_distance: float = 300.0
## How far the player must go back before the lead turns, in px. Above a chimney's width.
@export_range(0.0, 960.0, 1.0, "suffix:px") var turn_threshold: float = 180.0
## How fast the lead swings to its new side, per second.
@export_range(0.5, 20.0, 0.1, "suffix:1/s") var look_ahead_sharpness: float = 4.0

@export_group("Look Down")
## How far below the last floor the player must fall before the camera looks down, in px.
@export_range(0.0, 2000.0, 1.0, "suffix:px") var look_down_threshold: float = 250.0
## How far below the focus the camera looks in a long fall, in px.
@export_range(0.0, 540.0, 1.0, "suffix:px") var look_down_distance: float = 400.0
## How fast the camera swings down into a fall and back, per second.
@export_range(0.5, 30.0, 0.1, "suffix:1/s") var look_down_sharpness: float = 10.0

@export_group("Zones")
## The fastest the camera moves into a new zone, in px/s. Above the top falling speed (1400).
@export_range(100.0, 10000.0, 10.0, "suffix:px/s") var zone_change_speed: float = 2000.0
## How fast the camera eases into a new zone, per second.
@export_range(0.5, 30.0, 0.1, "suffix:1/s") var zone_change_sharpness: float = 6.0

@export_group("Zoom")
## How long the player must stand still before the camera closes in, in s.
@export_range(0.0, 10.0, 0.1, "suffix:s") var idle_delay: float = 1.5
## How much closer the camera comes while the player stands still. 1: never.
@export_range(1.0, 2.0, 0.01) var idle_zoom: float = 1.25
## How fast the zoom eases to a new value, per second.
@export_range(0.5, 20.0, 0.1, "suffix:1/s") var zoom_sharpness: float = 2.5
## Space kept above a Fit Height zone, in px: the player's height, so a jump keeps its head on screen.
@export_range(0.0, 540.0, 1.0, "suffix:px") var fit_headroom: float = 96.0
## The closest Fit Height or Auto Zoom may bring the camera. A zone's own Zoom is not held to it.
@export_range(1.0, 4.0, 0.05) var max_zone_zoom: float = 2.0

@export_group("Lookouts")
## The furthest a lookout may pull the camera back. At 0.7 the screen shows 2743 × 1543 px; a bigger
## View is followed inside it.
@export_range(0.3, 1.0, 0.05) var min_lookout_zoom: float = 0.7
## How fast the zoom eases into a lookout, per second: faster than Zoom Sharpness, so a player in a
## hurry still sees the way. At 4, 95 % in 1.2 s. Leaving a lookout uses Zoom Sharpness.
@export_range(0.5, 30.0, 0.1, "suffix:1/s") var lookout_zoom_sharpness: float = 4.0
## How fast the camera moves into a lookout, per second, as Zone Change Sharpness does into a zone.
## At 7, a move of 300 px is 95 % done in 0.7 s.
@export_range(0.5, 30.0, 0.1, "suffix:1/s") var lookout_change_sharpness: float = 7.0
## The fastest the camera moves into a lookout, in px/s.
@export_range(100.0, 20000.0, 10.0, "suffix:px/s") var lookout_change_speed: float = 3500.0
