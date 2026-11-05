# Plays level 1 as one scene with the real man, without the dogs: the tutorial, phase 1 by its short way, the
# chimney into phase 2, phase 2 with its gates and the way out, and then phase 1's long way, along the moves the
# paper check found (support/level1_route.json, made by verificar_nivel1.py). See support/route_test.gd.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_level1_route.gd
extends "res://tests/support/route_test.gd"

const SCENE_PATH: String = "res://levels/lust/level1.tscn"
const ROUTE_PATH: String = "res://tests/support/level1_route.json"
## With this event, Velvet does not stop the man to talk as he walks past.
const VELVET_MET: StringName = &"velvet_met"


func _initialize() -> void:
	# The GameState autoload joins the tree on the first frame.
	await process_frame
	(root.get_node(^"GameState") as GameProgress).mark_event(VELVET_MET)
	await replay(SCENE_PATH, ROUTE_PATH)


func prepare_level(level: Node) -> void:
	super(level)
	level.get_node("Tutorial/BlockerDemon").free()
