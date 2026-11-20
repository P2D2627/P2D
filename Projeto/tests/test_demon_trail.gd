# Checks DemonTrail, the man's trail that a dog with Follows Trail goes by (#271, phase C), on its own, with no
# scene: a landing on a floor at another height than the one he left is a step, from his last spot on the floor
# he left to where he landed; walking along a floor, a hop back onto it and a landing within the tolerance are
# none; the steps keep their order, and letting go of the first moves on to the next; clearing drops the steps
# but keeps his last spot, so his next landing is a step from there; past the most steps it keeps, the first is
# forgotten; and going to a floor takes the next step ahead that leaves it, or takes back the last step taken
# that leaves it, as after a throw back down the trail, but never past a step taken that lands on it, as when
# he went up and came back down, or changes nothing when no step does.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_demon_trail.gd
extends "res://tests/support/base_test.gd"

const FLOOR: Vector2 = Vector2(100.0, 0.0)
const LEDGE: Vector2 = Vector2(400.0, -192.0)
const TOP: Vector2 = Vector2(250.0, -384.0)
const IN_THE_AIR: Vector2 = Vector2(300.0, -300.0)


func _initialize() -> void:
	var results: Array[bool] = []
	results.append(_a_landing_on_another_floor_is_a_step())
	results.append(_walking_and_hopping_on_one_floor_are_no_steps())
	results.append(_steps_keep_their_order())
	results.append(_clearing_keeps_his_last_spot())
	results.append(_past_the_most_steps_the_first_is_forgotten())
	results.append(_going_to_a_floor())
	results.append(_landings_count_every_step_ever_kept())
	var passed: bool = not results.has(false)
	print("test_demon_trail: %s" % ("PASS" if passed else "FAIL"))
	quit(0 if passed else 1)


func _a_landing_on_another_floor_is_a_step() -> bool:
	var trail: DemonTrail = DemonTrail.new()
	trail.update(FLOOR, true)
	trail.update(FLOOR + Vector2(40.0, 0.0), true)
	trail.update(IN_THE_AIR, false)
	trail.update(LEDGE, true)
	var ok: bool = trail.size() == 1 and trail.get_first_from() == FLOOR + Vector2(40.0, 0.0) \
			and trail.get_first_to() == LEDGE
	return _report(ok, "A landing on another floor: %d step(s) (1), from %s to %s" % [trail.size(),
			trail.get_first_from() if not trail.is_empty() else Vector2.INF,
			trail.get_first_to() if not trail.is_empty() else Vector2.INF])


func _walking_and_hopping_on_one_floor_are_no_steps() -> bool:
	var trail: DemonTrail = DemonTrail.new()
	trail.update(FLOOR, true)
	trail.update(FLOOR + Vector2(200.0, 0.0), true)
	trail.update(IN_THE_AIR, false)
	trail.update(FLOOR + Vector2(300.0, 0.0), true)
	trail.update(IN_THE_AIR, false)
	trail.update(FLOOR + Vector2(320.0, DemonTrail.SAME_FLOOR_TOLERANCE), true)
	return _report(trail.is_empty(), "Walking, a hop back onto the floor and a landing within %.0f px: %d step(s) (0)"
			% [DemonTrail.SAME_FLOOR_TOLERANCE, trail.size()])


func _steps_keep_their_order() -> bool:
	var trail: DemonTrail = DemonTrail.new()
	_walk_up(trail)
	var first_ok: bool = trail.size() == 2 and trail.get_first_to() == LEDGE
	trail.drop_first()
	var second_ok: bool = trail.size() == 1 and trail.get_first_from() == LEDGE and trail.get_first_to() == TOP
	trail.drop_first()
	return _report(first_ok and second_ok and trail.is_empty(),
			"Steps in order: first to the ledge %s, then from it to the top %s, then none %s"
			% [first_ok, second_ok, trail.is_empty()])


func _clearing_keeps_his_last_spot() -> bool:
	var trail: DemonTrail = DemonTrail.new()
	_walk_up(trail)
	trail.clear()
	var cleared: bool = trail.is_empty()
	trail.update(IN_THE_AIR, false)
	trail.update(LEDGE, true)
	var ok: bool = cleared and trail.size() == 1 and trail.get_first_from() == TOP and trail.get_first_to() == LEDGE
	return _report(ok, "Cleared: no steps %s, then the next landing is one step from his last spot %s"
			% [cleared, ok])


func _past_the_most_steps_the_first_is_forgotten() -> bool:
	var trail: DemonTrail = DemonTrail.new()
	trail.update(Vector2.ZERO, true)
	for step: int in DemonTrail.MAX_STEPS + 1:
		trail.update(IN_THE_AIR, false)
		trail.update(Vector2(0.0, -100.0 * (step + 1)), true)
	var ok: bool = trail.size() == DemonTrail.MAX_STEPS and trail.get_first_from() == Vector2(0.0, -100.0) \
			and trail.get_landings() == DemonTrail.MAX_STEPS + 1
	return _report(ok, "Past %d steps: %d kept (%d), the first from %s ((0, -100)), landings %d (%d)"
			% [DemonTrail.MAX_STEPS, trail.size(), DemonTrail.MAX_STEPS, trail.get_first_from(), trail.get_landings(),
			DemonTrail.MAX_STEPS + 1])


func _going_to_a_floor() -> bool:
	var trail: DemonTrail = DemonTrail.new()
	_walk_up(trail)
	var none: bool = not trail.go_to_floor(-1000.0) and trail.size() == 2 and trail.get_first_from() == FLOOR
	var ahead: bool = trail.go_to_floor(LEDGE.y + DemonTrail.SAME_FLOOR_TOLERANCE) and trail.size() == 1 \
			and trail.get_first_from() == LEDGE
	trail.drop_first()
	var back: bool = trail.go_to_floor(FLOOR.y) and trail.size() == 2 and trail.get_first_from() == FLOOR \
			and trail.get_first_to() == LEDGE
	var down: DemonTrail = DemonTrail.new()
	down.update(FLOOR, true)
	down.update(IN_THE_AIR, false)
	down.update(LEDGE, true)
	down.update(IN_THE_AIR, false)
	down.update(FLOOR + Vector2(80.0, 0.0), true)
	down.drop_first()
	down.drop_first()
	var came_down: bool = not down.go_to_floor(FLOOR.y) and down.is_empty()
	return _report(none and ahead and back and came_down, ("Go to a floor: one no step leaves, nothing changes "
			+ "%s; the ledge's, ahead, the step before counts as taken %s; back on the floor, both steps count as "
			+ "not taken %s; on the floor a step taken lands on, none goes back %s") % [none, ahead, back, came_down])


## Landings go up by one with each step, and taking or clearing steps never takes them back down, so
## the demon tells a new landing from the count alone.
func _landings_count_every_step_ever_kept() -> bool:
	var trail: DemonTrail = DemonTrail.new()
	var before: int = trail.get_landings()
	_walk_up(trail)
	var walked_up: int = trail.get_landings()
	trail.drop_first()
	trail.clear()
	var cleared: int = trail.get_landings()
	trail.update(IN_THE_AIR, false)
	trail.update(LEDGE, true)
	trail.update(LEDGE + Vector2(60.0, 0.0), true)
	var ok: bool = before == 0 and walked_up == 2 and cleared == 2 and trail.get_landings() == 3
	return _report(ok, "Landings: %d (0), up two floors %d (2), after a step taken and a clear %d (2), one more "
			% [before, walked_up, cleared] + "landing and a walk %d (3)" % trail.get_landings())


## The man stands on FLOOR, jumps onto LEDGE, then onto TOP.
func _walk_up(trail: DemonTrail) -> void:
	trail.update(FLOOR, true)
	trail.update(IN_THE_AIR, false)
	trail.update(LEDGE, true)
	trail.update(IN_THE_AIR, false)
	trail.update(TOP, true)


func _report(passed: bool, what: String) -> bool:
	print("%s: %s" % ["PASS" if passed else "FAIL", what])
	return passed
