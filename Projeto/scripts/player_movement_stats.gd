class_name PlayerMovementStats
extends Resource

@export_group("Run")
## Top running speed, in px/s.
@export_range(0.0, 2000.0, 10.0, "suffix:px/s") var max_run_speed: float = 720.0
## Seconds to go from standing still to top speed.
@export_range(0.01, 1.0, 0.01, "suffix:s") var time_to_max_speed: float = 0.1
## Seconds to stop from top speed after letting go.
@export_range(0.01, 1.0, 0.01, "suffix:s") var time_to_stop: float = 0.15
## Share of the running acceleration and braking kept in the air: 1 is the same as on the floor, 0
## keeps the speed the player left the floor with.
@export_range(0.0, 1.0, 0.05) var air_control: float = 0.7

@export_group("Gravity")
## Downward acceleration while falling, in px/s².
@export_range(0.0, 20000.0, 10.0, "suffix:px/s²") var fall_gravity: float = 7850.0
## Top falling speed, in px/s.
@export_range(0.0, 5000.0, 10.0, "suffix:px/s") var max_fall_speed: float = 1400.0

@export_group("Jump")
## Height of a full jump, from the floor to the top, in px.
@export_range(1.0, 1000.0, 1.0, "suffix:px") var jump_height: float = 240.0
## Seconds from leaving the floor to the top of a full jump. Rounded to whole physics frames, so
## the jump peaks exactly at Jump Height.
@export_range(0.05, 1.0, 0.01, "suffix:s") var time_to_peak: float = 0.35
## Height of the lowest jump, from a quick tap on Jump, in px. A tap peaks a few px above it,
## because the take-off frame always rises at full take-off speed.
@export_range(1.0, 1000.0, 1.0, "suffix:px") var min_jump_height: float = 80.0
## Seconds after leaving the floor without jumping in which Jump still works as on the floor.
## Rounded to whole physics frames; 0 turns it off.
@export_range(0.0, 0.2, 0.01, "suffix:s") var coyote_time: float = 0.07
## Seconds a press of Jump is kept while the player cannot jump, so it still jumps on landing.
## Rounded to whole physics frames; 0 keeps the press for its own frame only.
@export_range(0.0, 0.2, 0.01, "suffix:s") var jump_buffer_time: float = 0.07

@export_group("Wall")
## Top falling speed while sliding down a wall, in px/s. Going up along a wall is not slowed.
@export_range(0.0, 2000.0, 10.0, "suffix:px/s") var wall_slide_speed: float = 350.0
## Seconds after a wall jump in which the run does nothing, so the jump carries the player away from
## the wall. Too short, and the player gets back to the same wall higher up, which climbs a single
## wall; test_wall_jump.gd checks that it cannot. Rounded to whole physics frames.
@export_range(0.0, 0.5, 0.01, "suffix:s") var wall_jump_lock_time: float = 0.2


## Upward speed when leaving the floor, in px/s. Comes from jump_height and time_to_peak.
func get_jump_velocity() -> float:
	return 2.0 * jump_height / _get_rounded_time_to_peak()


## Downward acceleration while going up, in px/s². Comes from jump_height and time_to_peak.
func get_rise_gravity() -> float:
	var time: float = _get_rounded_time_to_peak()
	return 2.0 * jump_height / (time * time)


## Downward acceleration while going up after letting go of Jump, in px/s². A third of the height
## takes three times the gravity. Never below get_rise_gravity(), so letting go can't jump higher.
func get_jump_cut_gravity() -> float:
	return get_rise_gravity() * jump_height / minf(min_jump_height, jump_height)


## coyote_time in whole physics frames, rounded to the nearest one.
func get_coyote_frames() -> int:
	return roundi(coyote_time * Engine.physics_ticks_per_second)


## jump_buffer_time in whole physics frames, rounded to the nearest one.
func get_jump_buffer_frames() -> int:
	return roundi(jump_buffer_time * Engine.physics_ticks_per_second)


## wall_jump_lock_time in whole physics frames, rounded to the nearest one.
func get_wall_jump_lock_frames() -> int:
	return roundi(wall_jump_lock_time * Engine.physics_ticks_per_second)


## time_to_peak rounded to the nearest whole physics frame, at least one. The half-frame correction
## in Player lands exactly on jump_height only when the rise takes a whole number of frames.
func _get_rounded_time_to_peak() -> float:
	var ticks_per_second: int = Engine.physics_ticks_per_second
	var frames: int = maxi(1, roundi(time_to_peak * ticks_per_second))
	return float(frames) / ticks_per_second
