# Checks DemonPath on its own, without a demon (ADR 0042): walking along one floor adds no step;
# landing on another floor adds one, with where it last stood on the floor it left; landing back on
# the same floor, as after a lunge, adds none; landing back on a floor it left on the way cuts the
# way there, down to none on its post's floor; past MAX_STEPS it forgets the first step; and the
# first floor it stands on, after falling from where it was put, is no step.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_demon_path.gd
extends "res://tests/support/base_test.gd"

const TILE: float = 48.0
## Where the demon stands on its post's floor, and how far it walks along a floor in one frame.
const POST: Vector2 = Vector2(100.0, 0.0)
const WALK: float = 5.0


func _initialize() -> void:
	var results: Array[bool] = [
		_walking_along_its_floor_adds_no_step(),
		_landing_on_another_floor_adds_a_step(),
		_landing_back_on_the_same_floor_adds_no_step(),
		_landing_back_on_a_floor_it_left_cuts_the_way(),
		_past_max_steps_it_forgets_the_first(),
		_the_first_floor_it_stands_on_is_no_step(),
	]
	quit(0 if not results.has(false) else 1)


func _report(passed: bool, text: String) -> bool:
	print("%s: %s" % ["PASS" if passed else "FAIL", text])
	return passed


## A path that has stood at POST, on its post's floor.
func _path_at_post() -> DemonPath:
	var path: DemonPath = DemonPath.new()
	path.update(POST, true)
	return path


## Leaves the floor at path's last spot, one frame in the air, and lands at at.
func _hop(path: DemonPath, at: Vector2) -> void:
	path.update(at + Vector2.UP * TILE, false)
	path.update(at, true)


func _walking_along_its_floor_adds_no_step() -> bool:
	var path: DemonPath = _path_at_post()
	for frame: int in 10:
		path.update(POST + Vector2.RIGHT * WALK * frame, true)
	return _report(path.is_empty(), "Walking along its floor: %d steps" % path.size())


func _landing_on_another_floor_adds_a_step() -> bool:
	var path: DemonPath = _path_at_post()
	var left_from: Vector2 = POST + Vector2.RIGHT * WALK
	path.update(left_from, true)
	var landed: Vector2 = Vector2(POST.x + 3.0 * TILE, POST.y + 2.0 * TILE)
	_hop(path, landed)
	return _report(path.size() == 1 and path.get_from(0) == left_from
			and path.get_to(0) == landed and path.get_last_from() == left_from,
			"Down two tiles: %d steps, from %s, to %s" % [path.size(), path.get_from(0),
			path.get_to(0)])


func _landing_back_on_the_same_floor_adds_no_step() -> bool:
	var path: DemonPath = _path_at_post()
	_hop(path, POST + Vector2(2.0 * TILE, DemonPath.SAME_FLOOR_TOLERANCE / 2.0))
	return _report(path.is_empty(), "Lunge along its floor: %d steps" % path.size())


func _landing_back_on_a_floor_it_left_cuts_the_way() -> bool:
	var path: DemonPath = _path_at_post()
	_hop(path, POST + Vector2(TILE, -TILE))
	_hop(path, POST + Vector2(2.0 * TILE, -2.0 * TILE))
	_hop(path, POST + Vector2(3.0 * TILE, -3.0 * TILE))
	var up_three: int = path.size()
	_hop(path, POST + Vector2(4.0 * TILE, -TILE))
	var back_on_the_first: int = path.size()
	var first_from: Vector2 = path.get_last_from()
	_hop(path, POST + Vector2(5.0 * TILE, 0.0))
	return _report(up_three == 3 and back_on_the_first == 1 and first_from == POST
			and path.is_empty(),
			"Up three floors: %d steps; dropped back to the first: %d, from %s; down home: %d"
			% [up_three, back_on_the_first, first_from, path.size()])


func _past_max_steps_it_forgets_the_first() -> bool:
	var path: DemonPath = _path_at_post()
	for floor: int in range(1, DemonPath.MAX_STEPS + 2):
		_hop(path, POST + Vector2(floor * TILE, -floor * TILE))
	var first_kept: Vector2 = POST + Vector2(TILE, -TILE)
	return _report(path.size() == DemonPath.MAX_STEPS and path.get_from(0) == first_kept,
			"Up %d floors: %d steps, the first from %s" % [DemonPath.MAX_STEPS + 1, path.size(),
			path.get_from(0)])


func _the_first_floor_it_stands_on_is_no_step() -> bool:
	var path: DemonPath = DemonPath.new()
	path.update(POST + Vector2.UP * TILE, false)
	path.update(POST, true)
	return _report(path.is_empty(), "Fell from where it was put onto its floor: %d steps"
			% path.size())
