class_name DemonLungeState
extends DemonState

## LUNGE: from take-off until the attack's Recover Time after landing. In the air, the lunge keeps
## its speed across, pulled down by the lunge's own gravity, since a quick, low arc needs more than
## the world's, and its hit can land on the man (ADR 0021). On the floor, the demon stays put for the
## attack's Recover Time, and then backs off or chases.

## Physics frames the demon has stood on the floor since it landed.
var _frames: int = 0
## True for a leap at a man on another floor (Demon.leap, #284): its arc is the demon's jump, so the
## world's jump gravity pulls it down rather than the lunge's. Off again on every lunge.
var leaping: bool = false


func enter() -> void:
	_frames = 0
	leaping = false


func physics_update(delta: float) -> void:
	if not _demon.is_on_floor():
		return
	_demon.velocity.x = 0.0
	_frames += 1
	if _frames >= _demon.get_attack().get_recover_frames():
		_demon.back_off_or_chase(delta)


func get_gravity() -> Vector2:
	if leaping:
		return Vector2.DOWN * _demon.stats.get_jump_gravity()
	return Vector2.DOWN * _demon.get_attack().get_lunge_gravity()


func can_land_hit() -> bool:
	return not _demon.is_on_floor()
