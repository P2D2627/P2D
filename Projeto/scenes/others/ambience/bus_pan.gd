class_name BusPan
extends RefCounted

## Pans what plays on an audio bus, through the first Panner effect (AudioEffectPanner) on it: how
## a sound that keeps its own stereo, on a player that is not 2D, comes from one side. A panner
## moves part of one channel into the other instead of turning one down, so a stereo sound keeps
## its width, its reverb and its loudness; at 0 it leaves the sound as it is. It pans all the bus
## plays at once, so the sounds that share a panned bus must not overlap.


## Sets the pan of the first enabled panner on bus, from -1 (all to the left) to 1 (all to the
## right). False, and nothing changes, if the bus does not exist or has no panner.
static func set_pan(bus: StringName, pan: float) -> bool:
	var panner: AudioEffectPanner = panner_of(bus)
	if panner == null:
		return false
	panner.pan = clampf(pan, -1.0, 1.0)
	return true


## The pan of the first enabled panner on bus; 0 without one.
static func get_pan(bus: StringName) -> float:
	var panner: AudioEffectPanner = panner_of(bus)
	return panner.pan if panner != null else 0.0


## The first enabled panner on bus, or null.
static func panner_of(bus: StringName) -> AudioEffectPanner:
	var index: int = AudioServer.get_bus_index(bus)
	if index < 0:
		return null
	for effect: int in AudioServer.get_bus_effect_count(index):
		var panner := AudioServer.get_bus_effect(index, effect) as AudioEffectPanner
		if panner != null and AudioServer.is_bus_effect_enabled(index, effect):
			return panner
	return null
