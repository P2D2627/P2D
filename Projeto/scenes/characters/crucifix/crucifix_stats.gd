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
## Longest the crucifix stays up in one use, in seconds. Letting go earlier ends the use. Rounded to
## whole physics frames.
@export_range(0.1, 30.0, 0.1, "suffix:s") var max_use_time: float = 5.0
## Seconds after every use, long or short, before the crucifix can go up again. Rounded to whole
## physics frames.
@export_range(0.0, 60.0, 0.5, "suffix:s") var cooldown_time: float = 15.0

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
