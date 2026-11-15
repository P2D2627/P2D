class_name ShakeTrauma
extends RefCounted

## The rules of the screen shake, apart from any node, so the tests can run them on their own. Each
## impact adds trauma, from 0 to 1, which falls back to 0 at Decay per second, or raises it to a
## level, for a moment that repeats fast and must not pile up. The shake is the trauma to the power
## Exponent, so light knocks barely show and several knocks in a row add up to a strong one. The
## screen's offset follows smooth noise, so it trembles instead of jumping about, and is never more
## than Max Offset times the shake to each side.

## Where the second axis reads the noise: far enough from the first for the two to move apart.
const SECOND_AXIS_ROW: float = 100.0

var _stats: CameraShakeStats
var _noise: FastNoiseLite = FastNoiseLite.new()
var _trauma: float = 0.0
## How long the noise has run, in s.
var _time: float = 0.0


func _init(stats: CameraShakeStats, noise_seed: int = 0) -> void:
	_stats = stats
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	_noise.frequency = 1.0
	_noise.seed = noise_seed


func get_trauma() -> float:
	return _trauma


## Adds amount, keeping the trauma at 1 at most. A negative amount adds nothing.
func add(amount: float) -> void:
	_trauma = minf(_trauma + maxf(amount, 0.0), 1.0)


## Raises the trauma to level, at 1 at most, and leaves a higher one alone: however often it comes,
## it never piles up past level.
func raise_to(level: float) -> void:
	_trauma = maxf(_trauma, minf(level, 1.0))


## Lets delta seconds go by: the noise runs on and the trauma falls.
func advance(delta: float) -> void:
	_time += delta
	_trauma = maxf(_trauma - _stats.decay * delta, 0.0)


## How hard the screen shakes now, from 0 to 1.
func get_shake() -> float:
	return pow(_trauma, _stats.exponent)


## The screen's offset now, in px on the screen, with the shake scaled by strength, as the Screen
## shake option gives it: 1 is the full shake and 0 none.
func get_offset(strength: float) -> Vector2:
	var reach: float = _stats.max_offset * get_shake() * clampf(strength, 0.0, 1.0)
	if reach <= 0.0:
		return Vector2.ZERO
	var at: float = _time * _stats.speed
	return Vector2(clampf(_noise.get_noise_2d(at, 0.0), -1.0, 1.0),
			clampf(_noise.get_noise_2d(at, SECOND_AXIS_ROW), -1.0, 1.0)) * reach
