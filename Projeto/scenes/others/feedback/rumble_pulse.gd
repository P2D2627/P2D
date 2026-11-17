class_name RumblePulse
extends Resource

## One vibration of the controller for a moment: how hard each of its two motors runs, from 0 to 1,
## for how long, and over what share of that time, at its end, it fades to nothing. The weak motor is
## the small fast one, a sharp buzz; the strong motor is the big slow one, a heavy thud. In each motor
## the strength and the speed of the vibration go together, so a motor run too low turns slowly, soft,
## or not at all. ControllerRumble scales both by the Vibration option.

## The small fast motor: a sharp buzz.
@export_range(0.0, 1.0, 0.05) var weak: float = 0.0
## The big slow motor: a heavy thud.
@export_range(0.0, 1.0, 0.05) var strong: float = 0.0
## How long it lasts.
@export_range(0.0, 1.0, 0.01, "suffix:s") var duration: float = 0.0
## The share of its time, at the end, over which it fades to nothing, in a straight line: 0 keeps it
## level to the end, as a tick; 1 fades it from the start, as a blow that dies away.
@export_range(0.0, 1.0, 0.05) var fade: float = 0.0


func _init(pulse_weak: float = 0.0, pulse_strong: float = 0.0, pulse_duration: float = 0.0,
		pulse_fade: float = 0.0) -> void:
	weak = pulse_weak
	strong = pulse_strong
	duration = pulse_duration
	fade = pulse_fade


## A new pulse weight of the way from this one to other, each value in a straight line: 0 gives this
## one's values and 1 other's. A weight out of 0 to 1 is kept in range, and one that is not a number
## counts as 0.
func blended_with(other: RumblePulse, weight: float) -> RumblePulse:
	var kept: float = 0.0 if is_nan(weight) else clampf(weight, 0.0, 1.0)
	return RumblePulse.new(lerpf(weak, other.weak, kept), lerpf(strong, other.strong, kept),
			lerpf(duration, other.duration, kept), lerpf(fade, other.fade, kept))
