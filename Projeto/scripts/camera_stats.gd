class_name CameraStats
extends Resource

## How the game camera follows the player. The camera heads for a focus point, which only moves when
## the player pushes against a window around it, and closes in on the focus a little on every
## physics step.

@export_group("Window")
## How far the player can go to each side of the focus before the focus follows, in px. In a 120 px
## chimney the player crosses 72 px, so a window 128 px wide keeps the camera still while climbing.
@export_range(0.0, 480.0, 1.0, "suffix:px") var window_half_width: float = 64.0
## How far above the focus the player can rise before the focus follows, in px. The full jump height
## and a 10 px margin, so a jump from the floor does not move the camera: from where the player
## stands, a full jump peaks a fraction of a px above Jump Height.
@export_range(0.0, 540.0, 1.0, "suffix:px") var window_up: float = 250.0
## How far below the focus the player can go before the focus follows, in px. At 0, the camera
## follows any drop at once.
@export_range(0.0, 540.0, 1.0, "suffix:px") var window_down: float = 0.0

@export_group("Smoothing")
## How fast the camera closes in on the focus, per second. After t seconds, exp(-sharpness × t) of
## the distance is left, whatever the length of a physics step: at 6, 95 % closes in half a second.
@export_range(0.5, 30.0, 0.1, "suffix:1/s") var follow_sharpness: float = 6.0

@export_group("Look Ahead")
## How far ahead of the focus the camera leads, to the side the player last committed to, in px.
## At 300, at full run the screen shows 1.5 s of run ahead of the player (1080 px at 720 px/s).
@export_range(0.0, 960.0, 1.0, "suffix:px") var look_ahead_distance: float = 300.0
## How far the player must go against the lead before the camera turns to the other side, in px.
## Above the 174 px the player crosses in the widest chimney climbed tapping Jump (222 px), so a
## chimney never turns the camera.
@export_range(0.0, 960.0, 1.0, "suffix:px") var turn_threshold: float = 180.0
## How fast the lead swings to its new side, per second. The swing is a critically damped spring:
## it starts slowly, speeds up and stops without going past. At 4, a turn from one side to the
## other peaks at 1.2 times the run speed and is 95 % done in 1.2 s.
@export_range(0.5, 20.0, 0.1, "suffix:1/s") var look_ahead_sharpness: float = 4.0

@export_group("Look Down")
## How far below the last floor it stood on the player must fall before the camera looks down, in
## px. Above the full jump height, so neither a jump nor a short drop moves the camera down.
@export_range(0.0, 2000.0, 1.0, "suffix:px") var look_down_threshold: float = 250.0
## How far below the focus the camera looks in a long fall, in px. At 400, at top falling speed the
## screen shows 0.5 s of fall below the player's feet (718 px at 1400 px/s).
@export_range(0.0, 540.0, 1.0, "suffix:px") var look_down_distance: float = 400.0
## How fast the camera swings down into a long fall and back up after it, per second, as a
## critically damped spring: at 10, the swing is 95 % done in about half a second.
@export_range(0.5, 30.0, 0.1, "suffix:1/s") var look_down_sharpness: float = 10.0

@export_group("Zones")
## How fast, at most, the camera moves into a new zone's range, in px/s. Above the top falling speed
## (1400 px/s), so a fall into another zone never loses the player; at 2000, a change of zone that
## moves the camera 900 px takes about half a second instead of whipping the screen across.
@export_range(100.0, 10000.0, 10.0, "suffix:px/s") var zone_change_speed: float = 2000.0
