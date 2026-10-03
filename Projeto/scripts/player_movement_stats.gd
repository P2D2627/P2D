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
## Downward acceleration while falling, in px/s².
@export_range(0.0, 20000.0, 10.0, "suffix:px/s²") var fall_gravity: float = 7850.0
## Top falling speed, in px/s.
@export_range(0.0, 5000.0, 10.0, "suffix:px/s") var max_fall_speed: float = 1400.0

@export_group("Jump")
## Height of a full jump, from the floor to the top, in px.
@export_range(0.0, 1000.0, 1.0, "suffix:px") var jump_height: float = 240.0
## Seconds from leaving the floor to the top of a full jump.
@export_range(0.05, 1.0, 0.01, "suffix:s") var time_to_peak: float = 0.35


## Upward speed when leaving the floor, in px/s. Comes from jump_height and time_to_peak.
func get_jump_velocity() -> float:
	return 2.0 * jump_height / time_to_peak


## Downward acceleration while going up, in px/s². Comes from jump_height and time_to_peak.
func get_rise_gravity() -> float:
	return 2.0 * jump_height / (time_to_peak * time_to_peak)
