class_name CyclePlatform
extends AnimatableBody2D

## A platform that moves between two marked points and can tilt, placed by a PlatformCycle. At
## progress 0 it is on Point A, where it rests, and at 1 on Point B. It is an AnimatableBody2D synced
## to physics, so a player standing on it is carried along, and slides off when it tilts too far.
## Its RiderSensor, just above its top, tells whether the player stands on it.

## Where the platform rests, at progress 0.
@export var point_a: Marker2D
## The other end of its path, at progress 1.
@export var point_b: Marker2D

@onready var _rider_sensor: Area2D = %RiderSensor


func _ready() -> void:
	assert(point_a != null and point_b != null,
			"CyclePlatform %s: assign the Marker2D of both ends to Point A and Point B." % name)
	place(0.0, 0.0)


## Puts the platform at progress along its path, from Point A (0) to Point B (1), tilted by
## tilt_degrees (clockwise). The whole transform is set at once: synced to physics, the body sends
## each change to the physics server and goes back to its last position until the physics step, so
## setting the position and then the rotation would send the old position with the new rotation.
func place(progress: float, tilt_degrees: float) -> void:
	global_transform = Transform2D(deg_to_rad(tilt_degrees),
			point_a.global_position.lerp(point_b.global_position, progress))


func has_rider() -> bool:
	return _rider_sensor.has_overlapping_bodies()


## The share of a trip done after fraction of its time, starting and stopping smoothly; fraction is
## clamped to 0..1. What drives a platform uses it, so every platform moves the same way.
static func smooth(fraction: float) -> float:
	var x: float = clampf(fraction, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)
