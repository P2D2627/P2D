class_name RumbleSustain
extends Resource

## A vibration of the controller held while a state lasts, such as a grab or the crucifix held up,
## where a pulse is a moment's. It runs low, on one motor or both, and throbs Beat Rate times a
## second, dipping by Beat Depth of its level and back, so it does not settle into a flat hum. How
## much of it runs follows the state: Start Share of it as the state begins, all of it at the state's
## worst. ControllerRumble scales it by the Vibration option, lets a pulse read over it on the motors
## the pulse runs, and leaves it out while the Constant Vibration option is off.

## The small fast motor: a sharp buzz.
@export_range(0.0, 1.0, 0.05) var weak: float = 0.0
## The big slow motor: a heavy thud.
@export_range(0.0, 1.0, 0.05) var strong: float = 0.0
## The share of both motors that runs as the state begins; it grows to all of them at its worst.
@export_range(0.0, 1.0, 0.05) var start_share: float = 1.0
## How many times a second it throbs; 0 holds it flat.
@export_range(0.0, 8.0, 0.1, "suffix:Hz") var beat_rate: float = 0.0
## How far each throb dips, as a share of the level: 0 holds it flat, 1 dips to nothing.
@export_range(0.0, 1.0, 0.05) var beat_depth: float = 0.0


func _init(sustain_weak: float = 0.0, sustain_strong: float = 0.0,
		sustain_start_share: float = 1.0, sustain_beat_rate: float = 0.0,
		sustain_beat_depth: float = 0.0) -> void:
	weak = sustain_weak
	strong = sustain_strong
	start_share = sustain_start_share
	beat_rate = sustain_beat_rate
	beat_depth = sustain_beat_depth


## The share of both motors that runs at progress, from 0 as the state begins to 1 at its worst:
## Start Share, growing in a straight line to all of them. A progress out of 0 to 1 is kept in range,
## and one that is not a number counts as 0.
func share_at(progress: float) -> float:
	var kept: float = 0.0 if is_nan(progress) else clampf(progress, 0.0, 1.0)
	return lerpf(start_share, 1.0, kept)
