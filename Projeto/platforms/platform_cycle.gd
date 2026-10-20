class_name PlatformCycle
extends Node

## The timing of a crossing of four platforms. Second, Lift and Ferry loop on one clock for as long
## as the level runs, so their meetings always line up, and a jump missed is only a wait for the
## next loop:
## 1. Second goes to the middle, waits a moment and comes back to its end.
## 2. Lift comes down to meet Second there, waits for the jump and rises back to its end.
## 3. Ferry comes to meet Lift there, waits for the jump and goes back to its end, where the way on
##    starts.
## Each one rests at its Point A and goes to its Point B and back, and rests Rest Time between
## loops. First moves only for the player: once the player stands on it, it sets off at once and
## reaches the middle in Approach Time, as Second does. If Second is not there yet, First waits for
## it in the middle. It wobbles over the last Wobble Time before Second arrives, as a warning, flips
## over once they meet, dropping whoever is still on it, and goes back to its end. After a fall, the
## player climbs back and stands on First again.

## First set off with the player, and when it went back to its end.
signal first_set_off
signal first_returned

@export var first: CyclePlatform
@export var second: CyclePlatform
@export var lift: CyclePlatform
@export var ferry: CyclePlatform

@export_group("Timing")
## How long First and Second take to reach the middle.
@export_range(0.5, 10.0, 0.1, "suffix:s") var approach_time: float = 3.0
## How long Second waits in the middle before it goes back, and how long it takes to go back.
@export_range(0.0, 5.0, 0.05, "suffix:s") var meet_hold_time: float = 0.6
@export_range(0.5, 10.0, 0.1, "suffix:s") var second_return_time: float = 2.0
## How long two platforms wait side by side for the player to jump across.
@export_range(0.0, 5.0, 0.05, "suffix:s") var transfer_time: float = 1.0
## How long Lift and Ferry take to go from one end to the other.
@export_range(0.5, 10.0, 0.1, "suffix:s") var lift_time: float = 3.0
@export_range(0.5, 10.0, 0.1, "suffix:s") var ferry_time: float = 3.0
## How long Second, Lift and Ferry rest at their end between loops. The loop lasts as long as the
## longest of their trips there and back, plus this.
@export_range(0.0, 10.0, 0.1, "suffix:s") var rest_time: float = 1.5

@export_group("First")
## How long First wobbles before it reaches the middle, how far and how fast.
@export_range(0.0, 5.0, 0.05, "suffix:s") var wobble_time: float = 1.0
@export_range(0.0, 30.0, 0.5, "suffix:°") var wobble_angle: float = 6.0
@export_range(0.5, 20.0, 0.5, "suffix:Hz") var wobble_frequency: float = 7.0
## How long First stays in the middle before it flips, how long the flip takes and how far it turns.
@export_range(0.0, 2.0, 0.05, "suffix:s") var flip_delay: float = 0.15
@export_range(0.05, 2.0, 0.05, "suffix:s") var flip_time: float = 0.3
@export_range(45.0, 180.0, 1.0, "suffix:°") var flip_angle: float = 100.0
## How long First stays flipped, and how long it takes to go back to its end, levelling out first.
@export_range(0.0, 5.0, 0.05, "suffix:s") var flipped_time: float = 0.6
@export_range(0.5, 10.0, 0.1, "suffix:s") var first_return_time: float = 2.0

## Seconds since the level started: Second, Lift and Ferry loop on it.
var _clock: float = 0.0
## While First is out: the clock when it set off and when it meets Second. -1 while it rests.
var _first_start: float = -1.0
var _first_meeting: float = -1.0


func _ready() -> void:
	assert(first != null and second != null and lift != null and ferry != null,
			"PlatformCycle: assign the four platforms.")
	_place_all()


func _physics_process(delta: float) -> void:
	_clock += delta
	if _first_start < 0.0 and first.has_rider():
		_first_start = _clock
		_first_meeting = get_next_meeting(_clock + approach_time)
		first_set_off.emit()
	elif _first_start >= 0.0 and _clock >= _first_return_start() + first_return_time:
		_first_start = -1.0
		_first_meeting = -1.0
		first_returned.emit()
	_place_all()


func get_clock() -> float:
	return _clock


## How long one loop of Second, Lift and Ferry lasts.
func get_loop_time() -> float:
	var longest: float = maxf(_second_trip(), maxf(2.0 * lift_time, 2.0 * ferry_time) + transfer_time)
	return longest + rest_time


## The first time on the clock, at or after time, when Second is in the middle to meet First.
func get_next_meeting(time: float) -> float:
	var loop: float = get_loop_time()
	return approach_time + ceilf((time - approach_time) / loop) * loop


## When First meets Second in the middle on its current trip, or -1 while First rests.
func get_first_meeting() -> float:
	return _first_meeting


func is_first_out() -> bool:
	return _first_start >= 0.0


## When First starts flipping, after meeting Second in the middle at meeting.
func get_flip_after(meeting: float) -> float:
	return meeting + flip_delay


## When Lift is down beside Second, back at its end, after Second was in the middle at meeting.
func get_lift_meeting_after(meeting: float) -> float:
	return meeting + meet_hold_time + second_return_time


## When Ferry is beside Lift, back up at its end, after Second was in the middle at meeting.
func get_ferry_meeting_after(meeting: float) -> float:
	return get_lift_meeting_after(meeting) + transfer_time + lift_time


func _place_all() -> void:
	var loop: float = get_loop_time()
	var lift_meeting: float = get_lift_meeting_after(approach_time)
	var ferry_meeting: float = get_ferry_meeting_after(approach_time)
	second.place(_looped(0.0, approach_time, meet_hold_time, second_return_time, loop), 0.0)
	lift.place(_looped(lift_meeting - lift_time, lift_time, transfer_time, lift_time, loop), 0.0)
	ferry.place(_looped(ferry_meeting - ferry_time, ferry_time, transfer_time, ferry_time, loop),
			0.0)
	first.place(_first_progress(), _first_tilt())


func _second_trip() -> float:
	return approach_time + meet_hold_time + second_return_time


## Where a looping platform is on its trip: it sets off at start in every loop, gets to its far end
## over out_time, waits hold_time and comes back over back_time, then rests until the next loop.
func _looped(start: float, out_time: float, hold_time: float, back_time: float,
		loop: float) -> float:
	var time: float = fposmod(_clock - start, loop)
	if time <= out_time:
		return CyclePlatform.smooth(time / out_time)
	if time <= out_time + hold_time:
		return 1.0
	return 1.0 - CyclePlatform.smooth((time - out_time - hold_time) / back_time)


func _first_progress() -> float:
	if _first_start < 0.0:
		return 0.0
	if _clock <= _first_meeting:
		return CyclePlatform.smooth((_clock - _first_start) / approach_time)
	return 1.0 - CyclePlatform.smooth((_clock - _first_return_start()) / first_return_time)


## Level, also while it waits for Second in the middle, then wobbling harder and harder over Wobble
## Time before Second arrives, then the flip, then level again on the way back.
func _first_tilt() -> float:
	if _first_start < 0.0:
		return 0.0
	var wobble_start: float = maxf(_first_meeting - wobble_time, _first_start)
	var flip_start: float = get_flip_after(_first_meeting)
	if _clock < wobble_start:
		return 0.0
	if _clock < flip_start:
		var strength: float = clampf((_clock - wobble_start) / maxf(_first_meeting - wobble_start,
				0.001), 0.0, 1.0)
		return wobble_angle * strength * sin(TAU * wobble_frequency * _clock)
	if _clock < _first_return_start():
		return flip_angle * CyclePlatform.smooth((_clock - flip_start) / flip_time)
	return flip_angle * (1.0 - CyclePlatform.smooth((_clock - _first_return_start()) / flip_time))


func _first_return_start() -> float:
	return get_flip_after(_first_meeting) + flip_time + flipped_time
