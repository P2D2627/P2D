class_name RevealRule
extends RefCounted

## How much of something the man may not see is drawn, step by step (#253): nothing until he first
## sees it; fading in while he sees it and for Linger Time after he last did; fading out after that.
## One that remembers stays drawn for good once he has seen it, as the spikes do. Show Hidden, the
## player's option, draws everything, but is not seeing: nothing is remembered from it. Pure rules,
## with no scene, so tests check them on their own.

## Stays drawn once the man has seen it, however long he looks away.
var remembers: bool
## Seconds from undrawn to fully drawn; 0 draws it at once.
var fade_in_time: float
## Seconds from fully drawn to undrawn; 0 hides it at once.
var fade_out_time: float
## Seconds it stays drawn after the man last saw it, so the edge of a wall does not make it flicker.
var linger_time: float

var _opacity: float = 0.0
var _has_seen: bool = false
## Seconds since the man last saw it; only counts once he has.
var _unseen_for: float = 0.0


func _init(remembers_once_seen: bool, fade_in_seconds: float, fade_out_seconds: float,
		linger_seconds: float) -> void:
	remembers = remembers_once_seen
	fade_in_time = fade_in_seconds
	fade_out_time = fade_out_seconds
	linger_time = linger_seconds


## Moves the opacity on by delta seconds, with the man seeing it or not and the player's Show Hidden
## on or off, and hands it back. A negative, infinite or nan delta changes nothing.
func step(seen: bool, show_hidden: bool, delta: float) -> float:
	if delta < 0.0 or not is_finite(delta):
		return _opacity
	if seen:
		_has_seen = true
		_unseen_for = 0.0
	elif _has_seen:
		_unseen_for += delta
	var shown: bool = (show_hidden or seen
			or (_has_seen and (remembers or _unseen_for < linger_time)))
	if shown:
		_opacity = _approach(_opacity, 1.0, fade_in_time, delta)
	else:
		_opacity = _approach(_opacity, 0.0, fade_out_time, delta)
	return _opacity


## Draws it in full at once and counts it as just seen, and hands back the opacity: for a moment the
## man must not miss, such as a demon's warning, with no fade in between.
func reveal_now() -> float:
	_has_seen = true
	_unseen_for = 0.0
	_opacity = 1.0
	return _opacity


## From 0, undrawn, to 1, fully drawn.
func get_opacity() -> float:
	return _opacity


## True once the man has seen it, Show Hidden aside.
func has_seen() -> bool:
	return _has_seen


## True when nothing can change any more: it remembers, the man has seen it, and it is fully drawn.
func is_settled() -> bool:
	return remembers and _has_seen and _opacity >= 1.0


## From value towards target, so that a whole change takes time seconds; time 0 gets there at once.
static func _approach(value: float, target: float, time: float, delta: float) -> float:
	if time <= 0.0:
		return target
	return move_toward(value, target, delta / time)
