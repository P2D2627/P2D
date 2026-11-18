class_name CrucifixStats
extends Resource

## The crucifix's values. Speed Multiplier and Repel Radius say when they change, so the crucifix
## takes them at once, also while the game runs and they are changed in the Remote tab; the others
## are read each time they are used.

@export_group("Movement")
## Share of the running speed kept while the crucifix is up. Jumping is not possible while it is.
@export_range(0.05, 1.0, 0.05) var speed_multiplier: float = 0.25:
	set(value):
		speed_multiplier = value
		emit_changed()

@export_group("Timing")
## Seconds a press of Crucifix is kept while the crucifix cannot go up, so a press a moment before
## landing, or before the cooldown ends, still raises it then, if Crucifix is still held. Rounded to
## whole physics frames; 0 keeps the press for its own frame only.
@export_range(0.0, 0.5, 0.01, "suffix:s") var raise_buffer_time: float = 0.1
## The crucifix's charge: the longest it stays up from full, in seconds. Each second up spends a
## second of it, and letting go keeps the rest. Rounded to whole physics frames.
@export_range(0.1, 30.0, 0.1, "suffix:s") var max_use_time: float = 5.0
## Seconds the charge takes to fill from empty to full while the crucifix is down, so a second up
## comes back in Cooldown Time / Max Use Time seconds. Run empty, the crucifix stays down this long,
## until it is full. Rounded to whole physics frames.
@export_range(0.0, 60.0, 0.5, "suffix:s") var cooldown_time: float = 15.0
## Seconds the crucifix stays down after it is lowered with charge left, before it can go up again,
## so quick taps raise it fewer than three times a second and its light never flashes faster than
## is safe for players with photosensitive epilepsy. A press in that time is kept until it ends, and
## raises it then if Crucifix is still held. Rounded to whole physics frames.
@export_range(0.0, 1.0, 0.05, "suffix:s") var min_down_time: float = 0.35

@export_group("Warning")
## Seconds of charge left from which the crucifix, while up, warns that it is about to come down: its
## light pulses, deeper as the end comes, and the controller's vibration grows. 0 warns nothing.
@export_range(0.0, 5.0, 0.1, "suffix:s") var warning_time: float = 1.5
## How many times a second the light dims and comes back while it warns: 3 at most, so it never
## flashes faster than is safe for players with photosensitive epilepsy.
@export_range(0.5, 3.0, 0.1, "suffix:Hz") var warning_pulse_rate: float = 2.0
## How far the light dims at the bottom of each pulse as the use ends, out of its brightness: the
## dips grow from nothing as the warning begins to this at its end.
@export_range(0.0, 1.0, 0.05) var warning_dim_depth: float = 0.6

@export_group("Repel")
## Distance from the crucifix, in px, inside which demons and lost souls are pushed out. The light
## shows it.
@export_range(10.0, 1000.0, 10.0, "suffix:px") var repel_radius: float = 200.0:
	set(value):
		repel_radius = value
		emit_changed()
## Speed at which whatever is inside the radius is pushed out of it, in px/s.
@export_range(0.0, 5000.0, 50.0, "suffix:px/s") var repel_speed: float = 1500.0

@export_group("Heal")
## SP given back for every second the crucifix is up.
@export_range(0.0, 100.0, 0.5, "suffix:SP/s") var heal_per_second: float = 5.0


## raise_buffer_time in whole physics frames, rounded to the nearest one.
func get_raise_buffer_frames() -> int:
	return roundi(raise_buffer_time * Engine.physics_ticks_per_second)


## max_use_time in whole physics frames, rounded to the nearest one, at least one.
func get_max_use_frames() -> int:
	return maxi(1, roundi(max_use_time * Engine.physics_ticks_per_second))


## cooldown_time in whole physics frames, rounded to the nearest one.
func get_cooldown_frames() -> int:
	return roundi(cooldown_time * Engine.physics_ticks_per_second)


## min_down_time in whole physics frames, rounded to the nearest one.
func get_min_down_frames() -> int:
	return roundi(min_down_time * Engine.physics_ticks_per_second)
