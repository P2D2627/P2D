class_name ThunderStrike
extends Resource

## One thunder of a ThunderLayer: its sound and the lightning flash that comes before it. The flash
## is drawn from the sound's own waveform, sped up (by .claude/propostas/thunder/flash_curve.py):
## each strong peak of the thunder is a stroke of light, and its slow roll a dimmer glow under the
## strokes, so a loud, sharp crack flashes bright and short and a soft, rolling one dimmer and
## longer. Any flash may be drawn by hand instead, in the Flash curve.

## The sound of the thunder.
@export var sound: AudioStream
## How bright the flash is over its length: time from 0 (the flash starts) to 1 (it ends), and
## brightness from 0 (dark) to 1 (its brightest). No more than three flashes in any one second
## (the WCAG rule for photosensitivity): a rise and a fall of a tenth or more count as one.
@export var flash: Curve
## How long the flash lasts, in s.
@export_range(0.05, 10.0, 0.01, "suffix:s") var flash_length: float = 1.0
## How bright the flash is at its brightest, as a share of the brightest strike's: the loudest
## thunder gives 1.
@export_range(0.0, 1.0, 0.01) var strength: float = 1.0


## How bright the flash is time seconds after it starts, from 0 to Strength; 0 before and after it.
func brightness_at(time: float) -> float:
	if flash == null or flash_length <= 0.0 or time < 0.0 or time > flash_length:
		return 0.0
	return clampf(flash.sample_baked(time / flash_length), 0.0, 1.0) * strength
