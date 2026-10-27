class_name DemonChaseState
extends DemonState

## CHASE: the demon goes after the man at its Chase Speed, along its own floor, facing him. With him
## standing out of its reach, it stops and faces him (OUT_OF_REACH); with Jump Height and him above
## it, only once nothing more takes it nearer him, and a step it can jump up onto takes it there
## (JUMP, ADR 0042). With him inside the Attack
## Range of one of its attacks, on about its own floor, and the attack's chance coming up, it warns
## of the attack (WARNING); a lunge's warning stops it, a bite's goes on with the chase. Once a bite
## on the run is over, it backs off with Retreat Distance in Stats (RETREAT).


## Leaving the chase ends a bite under way, and the backing off after it.
func exit() -> void:
	_demon.end_bite()


func physics_update(delta: float) -> void:
	if not _demon.keeps_after_target():
		return
	var gap: float = _demon.get_gap_to_target()
	if _demon.is_man_out_of_reach():
		_demon.turn_to(gap)
		if not _demon.climbs_after_target(gap, delta):
			_demon.velocity.x = 0.0
			_demon.change_state(Demon.State.OUT_OF_REACH)
		return
	if _demon.should_back_off_after_bite():
		_demon.back_off_or_chase(delta)
		return
	_demon.turn_to(gap)
	var attack: DemonAttack = _demon.attack_to_start(gap, delta)
	if attack != null:
		_demon.warn_of(attack)
		if not attack.keeps_chasing:
			_demon.velocity.x = 0.0
			return
	_demon.go_after(gap, delta)
