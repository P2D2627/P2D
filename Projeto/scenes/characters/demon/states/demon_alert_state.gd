class_name DemonAlertState
extends DemonState

## ALERT: with Alert Time, from noticing the man until the chase starts (ADR 0035). The demon stands
## where it is, turned to him, for Alert Time, which DemonMark shows with a "!" and DemonSounds with
## a beep (ADR 0040), and then chases him. It loses him as the chase does, and in the air it only falls.

## Physics frames the demon has stood alerted.
var _frames: int = 0


func enter() -> void:
	_frames = 0
	_demon.turn_to(_demon.get_gap_to_target())


func physics_update(_delta: float) -> void:
	_demon.velocity.x = 0.0
	if not _demon.keeps_after_target():
		return
	_demon.turn_to(_demon.get_gap_to_target())
	_frames += 1
	if _frames >= _demon.stats.get_alert_frames():
		_demon.change_state(Demon.State.CHASE)
