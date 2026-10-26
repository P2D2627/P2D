class_name DemonWarningState
extends DemonState

## WARNING: the demon warns of the attack it is about to make, for the attack's Warning Time (ADR
## 0020). Before a lunge, it stands still, since the chase stopped it when the warning started, and
## aims as the warning starts where the man will be when it lands; at the end it lunges there
## (LUNGE). Before a bite on the run, it chases on, and at the end bites where it is, and goes back
## to the chase. With the man taking no more hits, as when another demon's attack has just landed on
## him, the warning ends and the demon chases on from this same frame.

## Physics frames the demon has warned for.
var _frames: int = 0
## How far the lunge goes, in px, aimed as the warning starts.
var _lunge_distance: float = 0.0


func enter() -> void:
	_frames = 0
	var attack: DemonAttack = _demon.get_attack()
	if not attack.keeps_chasing:
		_lunge_distance = _demon.lunge_distance_to(attack, _demon.get_gap_to_target())


func physics_update(delta: float) -> void:
	if _demon.target_takes_no_hits():
		_demon.change_state_and_act(Demon.State.CHASE, delta)
		return
	var attack: DemonAttack = _demon.get_attack()
	if attack.keeps_chasing:
		_bite_on_the_run(attack, delta)
		return
	_frames += 1
	if _frames >= attack.get_warning_frames():
		_demon.velocity = attack.get_lunge_velocity(_lunge_distance) \
				* Vector2(_demon.get_facing(), 1.0)
		_demon.change_state(Demon.State.LUNGE)


func _bite_on_the_run(attack: DemonAttack, delta: float) -> void:
	if not _demon.keeps_after_target():
		return
	var gap: float = _demon.get_gap_to_target()
	_demon.turn_to(gap)
	_demon.go_after(gap, delta)
	_frames += 1
	if _frames >= attack.get_warning_frames():
		_demon.bite()
