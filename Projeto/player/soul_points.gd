class_name SoulPoints
extends Node

## The man's Soul Points (SP), the game's health. It keeps the SP between 0 and Max SP, takes damage
## and healing, and says what happened by signals: the bar, the sounds, the warnings and death
## listen to them, and it knows none of them. The SP comes back on its own, but not for Regen Delay
## after each hit; then slowly at first, at Regen Start Per Second, and faster the longer no hit
## comes, up to Regen Top Per Second. Once the SP runs out, damage, healing and regeneration do
## nothing. It goes as a child of the player, and stops with it when the game is paused.

## The SP or Max SP changed. Also when Max SP or Low Threshold change in Stats, so the bar takes a
## new maximum at once.
signal sp_changed(current: float, maximum: float)
## The man lost amount SP to damage: what he lost, never more than he had. sp_changed follows.
signal damaged(amount: float)
## The SP reached Low Threshold or went under it (is_low true), or went back above it (false).
signal low_changed(is_low: bool)
## The SP ran out. Comes last, and only once.
signal depleted

## Max SP, Low Threshold and regeneration. A change to Max SP or Low Threshold takes effect at once,
## also while the game runs, and so does a new file put here.
@export var stats: SoulPointsStats:
	set(value):
		if stats != null and stats.changed.is_connected(_apply_stats):
			stats.changed.disconnect(_apply_stats)
		stats = value
		if stats != null:
			stats.changed.connect(_apply_stats)
		_apply_stats()

var _sp: float = 0.0
var _is_low: bool = false
## Physics frames left before regeneration starts again, after a hit.
var _regen_wait_frames: int = 0
## Physics frames regeneration has run since it last started again: how far up the ramp it is. A hit
## sets it back to 0. It only grows; a 64-bit int would take billions of years to run out.
var _regen_frames: int = 0


func _ready() -> void:
	assert(stats != null, "SoulPoints: assign a SoulPointsStats resource to Stats.")
	_sp = stats.max_sp
	_is_low = _sp <= stats.low_threshold


## Counts the pause after a hit down, one physics frame at a time, and then regenerates, a little
## faster on every frame until the top of the ramp.
func _physics_process(delta: float) -> void:
	if _regen_wait_frames > 0:
		_regen_wait_frames -= 1
		return
	heal(stats.get_regen_rate(_regen_frames) * delta)
	_regen_frames += 1


func get_sp() -> float:
	return _sp


func get_max_sp() -> float:
	return stats.max_sp


## True at or below Low Threshold, and so also once the SP has run out.
func is_low() -> bool:
	return _is_low


func is_depleted() -> bool:
	return _sp <= 0.0


## SP per second regeneration gives on the next physics frame: nothing when full, during the pause
## after a hit or once run out.
func get_regen_rate() -> float:
	if _regen_wait_frames > 0 or _sp >= stats.max_sp or is_depleted():
		return 0.0
	return stats.get_regen_rate(_regen_frames)


## Takes amount SP away, down to 0. A negative, infinite or nan amount is an error and changes
## nothing; so does any damage once the SP has run out.
func take_damage(amount: float) -> void:
	if not _is_valid_amount(amount) or amount == 0.0 or is_depleted():
		return
	var lost: float = minf(amount, _sp)
	_sp -= lost
	_regen_wait_frames = stats.get_regen_delay_frames()
	_regen_frames = 0
	damaged.emit(lost)
	sp_changed.emit(_sp, stats.max_sp)
	_update_low()
	if is_depleted():
		depleted.emit()


## Gives amount SP back, up to Max SP. A negative, infinite or nan amount is an error and changes
## nothing; so does any healing once the SP has run out.
func heal(amount: float) -> void:
	if not _is_valid_amount(amount) or is_depleted():
		return
	var before: float = _sp
	_sp = minf(_sp + amount, stats.max_sp)
	if _sp == before:
		return
	sp_changed.emit(_sp, stats.max_sp)
	_update_low()


## Brings the SP down to a lower Max SP and says what changed. Stats says when Max SP or Low
## Threshold change, so this runs again then; before the node is ready, _ready() starts it full.
func _apply_stats() -> void:
	if not is_node_ready():
		return
	_sp = minf(_sp, stats.max_sp)
	sp_changed.emit(_sp, stats.max_sp)
	_update_low()


## Says low_changed only when the SP crosses Low Threshold, not on every change.
func _update_low() -> void:
	var is_low_now: bool = _sp <= stats.low_threshold
	if is_low_now == _is_low:
		return
	_is_low = is_low_now
	low_changed.emit(_is_low)


## 0 is valid: a heal of 0 SP per second gives 0 every frame.
func _is_valid_amount(amount: float) -> bool:
	if is_finite(amount) and amount >= 0.0:
		return true
	push_error("SoulPoints: %s is not a valid amount of SP." % amount)
	return false
