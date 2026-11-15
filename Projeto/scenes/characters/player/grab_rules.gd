class_name GrabRules
extends RefCounted

## The rules of the grab (ADR 0021), with no nodes, so they can be tested on their own. One demon
## grabs the man and a second can join while he is held; each asks for more presses, or more time
## holding, before he breaks free. If he stops, with no press and no holding for longer than Drain
## Delay, the bar goes down. If Time To Die runs out first, he dies. The node that holds the man
## calls advance() once per physics frame, with that frame's press and hold; the rules count both
## and never ask which way the Options chose.

enum State { HELD, FREE, DEAD }

## Most demons in one grab: the art draws the man held by one or by two.
const MAX_DEMONS: int = 2

var _stats: GrabStats
var _state: State = State.HELD
var _demons: int = 1
## Presses and seconds held, less what the drain took back.
var _presses: float = 0.0
var _held_time: float = 0.0
## Seconds since the last press or hold.
var _idle_time: float = 0.0
var _elapsed: float = 0.0


## Starts a grab by one demon, with the values in stats.
func _init(stats: GrabStats) -> void:
	assert(stats != null, "GrabRules: give it the GrabStats to use.")
	_stats = stats


## One physics frame of the grab: pressed on a frame the escape button went down, holding on a
## frame it is held down. With neither, once Drain Delay has passed, the bar goes down by Drain Per
## Second for the time past it, so the drain is the same at any frame rate. The man breaks free
## before the time is counted, so a last press on the frame the time runs out frees him. Once he is
## free or dead, nothing changes.
func advance(delta: float, pressed: bool, holding: bool) -> void:
	assert(delta >= 0.0, "GrabRules: delta can't be negative.")
	if _state != State.HELD:
		return
	if pressed:
		_presses += 1.0
	if holding:
		_held_time += delta
	if pressed or holding:
		_idle_time = 0.0
	else:
		_idle_time += delta
		_drain(minf(delta, _idle_time - _stats.drain_delay) * _stats.drain_per_second)
	if _reached(get_escape_progress(), 1.0):
		_state = State.FREE
		return
	_elapsed += delta
	if _reached(_elapsed, _stats.time_to_die):
		_state = State.DEAD


## A second demon joins the grab, which then asks for more presses or more time holding; what the
## man did so far and the time left stay. False, and nothing changes, if MAX_DEMONS already hold
## him or he is free or dead.
func join() -> bool:
	if _state != State.HELD or _demons >= MAX_DEMONS:
		return false
	_demons += 1
	return true


## Whether the man is still held, broke free or died.
func get_state() -> State:
	return _state


## Demons holding the man, 1 or 2.
func get_demons() -> int:
	return _demons


## Presses that break the man free of the demons holding him now.
func get_presses_needed() -> int:
	return _stats.presses_to_escape + _stats.extra_presses_per_demon * (_demons - 1)


## Seconds of holding that break the man free of the demons holding him now.
func get_hold_time_needed() -> float:
	return _stats.hold_time_to_escape + _stats.extra_hold_time_per_demon * (_demons - 1)


## How near the man is to breaking free, from 0 to 1. Presses and time held fill it together, so
## the prompt can show one bar; a demon joining lowers it, since it asks for more.
func get_escape_progress() -> float:
	return minf(float(_presses) / get_presses_needed() + _held_time / get_hold_time_needed(), 1.0)


## How far the man has sunk, from 0 at the grab to 1 at his death, at the pace of Time To Die. Dead,
## it is 1 even when the frame times add up to a hair short of Time To Die, as _reached allows.
func get_sink() -> float:
	if _state == State.DEAD:
		return 1.0
	return clampf(_elapsed / _stats.time_to_die, 0.0, 1.0)


## Takes amount off the bar, never below 0. Presses and time held lose the same share, so a demon
## joining still weighs on both.
func _drain(amount: float) -> void:
	var progress: float = get_escape_progress()
	if amount <= 0.0 or progress <= 0.0:
		return
	var kept: float = maxf(progress - amount, 0.0) / progress
	_presses *= kept
	_held_time *= kept


## Whether amount has come to goal, with room for the rounding in adding up frame times.
func _reached(amount: float, goal: float) -> bool:
	return amount > goal or is_equal_approx(amount, goal)
