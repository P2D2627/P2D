# Plays Lust phase 2 from start to finish with the real man in the real scene, without the dogs, along the way the
# paper check found (support/lust_phase_2_route.json, made by verificar_fase2.py). See support/route_test.gd.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_lust_phase_2_route.gd
extends "res://tests/support/route_test.gd"

const SCENE_PATH: String = "res://levels/lust/lust_phase_2.tscn"
const ROUTE_PATH: String = "res://tests/support/lust_phase_2_route.json"


func _initialize() -> void:
	await replay(SCENE_PATH, ROUTE_PATH)
