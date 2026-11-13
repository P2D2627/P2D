class_name PlatformCycle
extends Node

## The timing of a crossing of four platforms. All four loop on one clock for as long as the level
## runs, the player there or not, each going from its Point A to its Point B and back without
## stopping: every trip takes Travel Time, so each platform goes as fast as its path is long, and
## the platforms that meet always get there together, neither waiting for the other. A jump missed
## is only a wait for the next loop:
## 1. First and Second get to the middle together. At the same moment Lift gets to the top and
##    Ferry beside it.
## 2. Second goes back to the wall and Lift comes down to meet it there, while Ferry goes back to its
##    end, where the way on starts.
## 3. Second goes back to the middle, Lift back up to the top and Ferry to meet it, as in 1.
## Second, Lift and Ferry wait Hold Time at each end. First wobbles over the last Wobble Time before
## the middle, as a warning, flips over once there, dropping whoever is still on it, goes back to
## its end and waits there for the rest of the loop, for the player to step on. After a fall, the
## player climbs back and waits for First at its end.

@export var first: CyclePlatform
@export var second: CyclePlatform
@export var lift: CyclePlatform
@export var ferry: CyclePlatform

@export_group("Timing")
## How long every platform takes to go from one end to the other; First takes it to the middle.
@export_range(0.5, 10.0, 0.1, "suffix:s") var travel_time: float = 3.0
## How long Second, Lift and Ferry wait at each end, side by side with the platform they meet there,
## for the player to jump across. A loop lasts two trips and two waits.
@export_range(0.0, 5.0, 0.05, "suffix:s") var hold_time: float = 1.0

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
## The loop must leave it time to wait there: see get_first_wait.
@export_range(0.0, 5.0, 0.05, "suffix:s") var flipped_time: float = 0.6
@export_range(0.5, 10.0, 0.1, "suffix:s") var first_return_time: float = 2.0

## Seconds since the level started: the four platforms loop on it.
var _clock: float = 0.0


func _ready() -> void:
	assert(first != null and second != null and lift != null and ferry != null,
			"PlatformCycle: assign the four platforms.")
	if get_first_wait() < 0.0:
		push_warning("PlatformCycle: First's trip takes %.2f s longer than the loop; raise Travel Time or Hold Time, or shorten First's."
				% -get_first_wait())
	_place_all()


func _physics_process(delta: float) -> void:
	_clock += delta
	_place_all()


func get_clock() -> float:
	return _clock


## How long one loop lasts: two trips and two waits.
func get_loop_time() -> float:
	return 2.0 * (travel_time + hold_time)


## The first time on the clock, at or after time, when First and Second get to the middle. They
## set off from their ends when the level starts, so the first meeting is a trip later.
func get_next_meeting(time: float) -> float:
	var loop: float = get_loop_time()
	return travel_time + ceilf((time - travel_time) / loop) * loop


## When First starts flipping, after meeting Second in the middle at meeting.
func get_flip_after(meeting: float) -> float:
	return meeting + flip_delay


## When Lift is down beside Second, back at the wall, after Second was in the middle at meeting.
func get_lift_meeting_after(meeting: float) -> float:
	return meeting + hold_time + travel_time


## When Ferry is beside Lift, back up at the top, after Second was in the middle at meeting: a loop
## later, as First and Second meet again.
func get_ferry_meeting_after(meeting: float) -> float:
	return get_lift_meeting_after(meeting) + hold_time + travel_time


## How long First waits at its end in each loop, for the player to step on. Below 0, the loop is too
## short for First's trip and First jumps from its way back to its way out.
func get_first_wait() -> float:
	return get_loop_time() - travel_time - _first_return_start() - first_return_time


func _place_all() -> void:
	var meeting: float = get_next_meeting(0.0)
	second.place(_shuttle(meeting), 0.0)
	lift.place(_shuttle(get_lift_meeting_after(meeting)), 0.0)
	ferry.place(_shuttle(meeting), 0.0)
	var since_meeting: float = _since(meeting)
	first.place(_first_progress(since_meeting), _first_tilt(since_meeting))


## How far into its loop the clock is, for a loop that starts at time.
func _since(time: float) -> float:
	return fposmod(_clock - time, get_loop_time())


## Where a shuttling platform is when it gets to its Point B at arrival, and every loop after: it
## waits there, goes back to Point A, waits there and comes back.
func _shuttle(arrival: float) -> float:
	var time: float = _since(arrival)
	if time <= hold_time:
		return 1.0
	time -= hold_time
	if time <= travel_time:
		return 1.0 - CyclePlatform.smooth(time / travel_time)
	time -= travel_time + hold_time
	if time <= 0.0:
		return 0.0
	return CyclePlatform.smooth(time / travel_time)


## Where First is, time into the loop that starts when it meets Second in the middle: there until it
## has flipped and stayed flipped, then back to its end, waiting there and out again to the middle.
func _first_progress(time: float) -> float:
	var set_off: float = get_loop_time() - travel_time
	if time >= set_off:
		return CyclePlatform.smooth((time - set_off) / travel_time)
	var return_start: float = _first_return_start()
	if time <= return_start:
		return 1.0
	return 1.0 - CyclePlatform.smooth((time - return_start) / first_return_time)


## First's tilt, time into the same loop: level on the way out, then wobbling harder and harder over
## the last Wobble Time before the middle and on until the flip, then the flip, then level again on
## the way back.
func _first_tilt(time: float) -> float:
	var wobble_start: float = get_loop_time() - wobble_time
	if time >= wobble_start:
		var strength: float = (time - wobble_start) / maxf(wobble_time, 0.001)
		return wobble_angle * strength * sin(TAU * wobble_frequency * _clock)
	if time < flip_delay:
		return wobble_angle * sin(TAU * wobble_frequency * _clock)
	var return_start: float = _first_return_start()
	if time < return_start:
		return flip_angle * CyclePlatform.smooth((time - flip_delay) / flip_time)
	return flip_angle * (1.0 - CyclePlatform.smooth((time - return_start) / flip_time))


## How long after meeting Second in the middle First sets off back to its end.
func _first_return_start() -> float:
	return flip_delay + flip_time + flipped_time
