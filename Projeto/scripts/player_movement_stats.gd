class_name PlayerMovementStats
extends Resource

@export_group("Run")
## Top running speed, in px/s.
@export_range(0.0, 2000.0, 10.0, "suffix:px/s") var max_run_speed: float = 720.0
## Seconds to go from standing still to top speed.
@export_range(0.01, 1.0, 0.01, "suffix:s") var time_to_max_speed: float = 0.1
## Seconds to stop from top speed after letting go.
@export_range(0.01, 1.0, 0.01, "suffix:s") var time_to_stop: float = 0.15

@export_group("Gravity")
## Downward acceleration while airborne, in px/s².
@export_range(0.0, 20000.0, 10.0, "suffix:px/s²") var fall_gravity: float = 7850.0
## Top falling speed, in px/s.
@export_range(0.0, 5000.0, 10.0, "suffix:px/s") var max_fall_speed: float = 1400.0
