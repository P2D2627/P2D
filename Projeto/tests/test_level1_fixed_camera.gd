# Checks that level 1's camera frames the man with the fixed framing (FixedFraming, the Fixed brain) from the
# start (#284), after the playtest of 22/11, where the zones' camera gave some players headaches; and that the
# debug overlay's choice of framing (F10) still goes over it in a new copy of the level.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_level1_fixed_camera.gd
extends "res://tests/support/base_test.gd"

const LEVEL1: PackedScene = preload("res://scenes/levels/lust/level1.tscn")
const FIXED: String = "Fixed"
## Frames for the level, the camera and the overlay's deferred call to set up.
const SETUP_FRAMES: int = 3


func _initialize() -> void:
	var results: Array[bool] = []
	DebugOverlay.camera_mode = ""
	var framing: String = await _framing_of_a_new_level()
	results.append(report(framing == FIXED, "Level 1 starts framed by %s (%s)" % [framing, FIXED]))
	DebugOverlay.camera_mode = GameCamera.OWN_FRAMING_NAME
	framing = await _framing_of_a_new_level()
	results.append(report(framing == GameCamera.OWN_FRAMING_NAME,
			"With the overlay's choice on %s, level 1 starts framed by %s"
			% [GameCamera.OWN_FRAMING_NAME, framing]))
	DebugOverlay.camera_mode = ""
	quit(0 if not results.has(false) else 1)


func _framing_of_a_new_level() -> String:
	var level: Node = LEVEL1.instantiate()
	root.add_child(level)
	for _frame: int in SETUP_FRAMES:
		await process_frame
	var framing: String = (level.get_node(^"GameCamera") as GameCamera).get_framing_name()
	level.queue_free()
	await process_frame
	return framing


func report(passed: bool, what: String) -> bool:
	print(("PASS: " if passed else "FAIL: ") + what)
	return passed
