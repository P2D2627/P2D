class_name SoulPointsStats
extends Resource

## The man's Soul Points (SP), the game's health. Max SP and Low Threshold say when they change, so
## the SP component takes them at once, also while the game runs and they are changed in the Remote
## tab; the others are read each time they are used.

@export_group("Amount")
## Most SP the man can have. Healing and regeneration stop here.
@export_range(1.0, 500.0, 1.0, "suffix:SP") var max_sp: float = 100.0:
	set(value):
		max_sp = value
		emit_changed()
## At or below this many SP the man is low, and the warnings start.
@export_range(0.0, 500.0, 1.0, "suffix:SP") var low_threshold: float = 25.0:
	set(value):
		low_threshold = value
		emit_changed()

@export_group("Regeneration")
## Seconds after the last damage before regeneration starts again. Rounded to whole physics frames;
## 0 never stops it.
@export_range(0.0, 30.0, 0.1, "suffix:s") var regen_delay: float = 3.0
## SP per second that come back on their own when regeneration starts again. From there the speed
## rises in a straight line to Regen Top Per Second.
@export_range(0.0, 50.0, 0.1, "suffix:SP/s") var regen_start_per_second: float = 0.5
## SP per second regeneration rises to at the end of Regen Ramp Time, and keeps from then on.
@export_range(0.0, 50.0, 0.1, "suffix:SP/s") var regen_top_per_second: float = 3.0
## Seconds regeneration takes to rise from Regen Start Per Second to Regen Top Per Second. Rounded
## to whole physics frames; 0 starts at the top. With the two speeds the same, it keeps one speed.
@export_range(0.0, 60.0, 0.5, "suffix:s") var regen_ramp_time: float = 10.0


## regen_delay in whole physics frames, rounded to the nearest one.
func get_regen_delay_frames() -> int:
	return roundi(regen_delay * Engine.physics_ticks_per_second)


## regen_ramp_time in whole physics frames, rounded to the nearest one.
func get_regen_ramp_frames() -> int:
	return roundi(regen_ramp_time * Engine.physics_ticks_per_second)


## SP per second regeneration gives on its physics frame number frames since it started again:
## Regen Start Per Second on frame 0, rising in a straight line, and Regen Top Per Second from Regen
## Ramp Time on.
func get_regen_rate(frames: int) -> float:
	var ramp_frames: int = get_regen_ramp_frames()
	if ramp_frames <= 0:
		return regen_top_per_second
	return lerpf(regen_start_per_second, regen_top_per_second,
			minf(float(frames) / ramp_frames, 1.0))
