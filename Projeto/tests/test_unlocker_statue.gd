# Checks the gate unlocker's statue. Unused, it shows its unlit cell and stays so. Used, a flame burns
# on it: the lit cells play in turn, Flame Frame Time each, and start over after the last, never back
# to the unlit one.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_unlocker_statue.gd
extends SceneTree

const GATE_SCENE: PackedScene = preload("res://scenes/objects/gates/gate.tscn")
const UNLOCKER_SCENE: PackedScene = preload("res://scenes/objects/gates/gate_unlocker.tscn")
const UNLIT_CELL: int = 0
## Frames watched while unused.
const IDLE_FRAMES: int = 30


func _initialize() -> void:
	var gate: Gate = GATE_SCENE.instantiate() as Gate
	gate.position = Vector2(600.0, 0.0)
	root.add_child(gate)
	var unlocker: GateUnlocker = UNLOCKER_SCENE.instantiate() as GateUnlocker
	unlocker.gates = [gate]
	root.add_child(unlocker)
	await physics_frame
	var statue: Sprite2D = unlocker.get_node(^"%Statue") as Sprite2D
	var results: Array[bool] = []
	results.append(await _unused_it_stays_unlit(statue))
	results.append(await _used_its_flame_plays_round(unlocker, statue))
	var failed: int = results.count(false)
	print("%d of %d passed" % [results.size() - failed, results.size()])
	quit(1 if failed > 0 else 0)


func _unused_it_stays_unlit(statue: Sprite2D) -> bool:
	var cells: Array[int] = []
	for _step: int in IDLE_FRAMES:
		if not cells.has(statue.frame):
			cells.append(statue.frame)
		await physics_frame
	return _report(cells == [UNLIT_CELL], "Unused: cells shown %s" % [cells])


func _used_its_flame_plays_round(unlocker: GateUnlocker, statue: Sprite2D) -> bool:
	unlocker.activate()
	var lit_cells: int = statue.hframes - 1
	# Two rounds of the flame and a bit, one cell change at a time.
	var watch: int = roundi(2.5 * lit_cells * unlocker.flame_frame_time * Engine.physics_ticks_per_second)
	var shown: Array[int] = []
	for _step: int in watch:
		if shown.is_empty() or shown.back() != statue.frame:
			shown.append(statue.frame)
		await physics_frame
	var in_turn: bool = shown.size() > lit_cells + 1 and not shown.has(UNLIT_CELL)
	for k: int in range(1, shown.size()):
		var expected: int = shown[k - 1] % lit_cells + 1
		in_turn = in_turn and shown[k] == expected
	return _report(in_turn, "Used: cells shown %s" % [shown])


func _report(passed: bool, what: String) -> bool:
	print("%s: %s" % ["PASS" if passed else "FAIL", what])
	return passed
