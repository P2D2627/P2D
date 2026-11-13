# Test of the tutorial's hints (TutorialHints, scenes/levels/tutorial_hints.gd). A hint shows while the man
# is before it or less than Hide Margin past it; once he is farther, it fades out and stays hidden
# when he walks back. A child without a KeyPrompt is never hidden. Level 1's tutorial has the script,
# follows the level's Player, and counts its four hints: Move, Jump, WallJump and Crucifix, and not
# Velvet (TutorialDemon), who has a KeyPrompt of her own but must never fade.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_tutorial_hints.gd
extends "res://tests/support/base_test.gd"

const KEY_PROMPT_SCENE: PackedScene = preload("res://scenes/levels/key_prompt.tscn")
const LEVEL_1_PATH: String = "res://scenes/levels/lust/level1.tscn"
const HINT_X: float = 1000.0
const MARGIN: float = 300.0
const FADE: float = 0.2
## Physics frames for the fade to end, with room to spare.
const FADE_FRAMES: int = 30
const LEVEL_1_HINTS: PackedStringArray = ["Move", "Jump", "WallJump", "Crucifix"]


func _initialize() -> void:
	# The autoloads join the tree on the first frame.
	await process_frame
	var results: Array[bool] = []
	results.append(await _a_hint_hides_once_he_is_past_it())
	results.append(await _level_1_has_the_hints())
	quit(1 if results.has(false) else 0)


func _a_hint_hides_once_he_is_past_it() -> bool:
	var player: Node2D = Node2D.new()
	var tutorial: TutorialHints = TutorialHints.new()
	tutorial.player = player
	tutorial.hide_margin = MARGIN
	tutorial.fade_time = FADE
	var hint: Node2D = Node2D.new()
	hint.position.x = HINT_X
	var key: KeyPrompt = KEY_PROMPT_SCENE.instantiate() as KeyPrompt
	key.action = &"jump"
	hint.add_child(key)
	tutorial.add_child(hint)
	var marker: Node2D = Node2D.new()
	marker.position.x = HINT_X
	tutorial.add_child(marker)
	root.add_child(player)
	root.add_child(tutorial)

	player.position.x = HINT_X + MARGIN - 10.0
	await _wait(FADE_FRAMES)
	var shown_before: bool = hint.visible and is_equal_approx(hint.modulate.a, 1.0)
	player.position.x = HINT_X + MARGIN + 10.0
	await _wait(FADE_FRAMES)
	var hidden_after: bool = not hint.visible and is_zero_approx(hint.modulate.a)
	player.position.x = 0.0
	await _wait(FADE_FRAMES)
	var stays_hidden: bool = not hint.visible
	var marker_shown: bool = marker.visible and is_equal_approx(marker.modulate.a, 1.0)
	var passed: bool = shown_before and hidden_after and stays_hidden and marker_shown
	_report(passed, ("hint: shown short of the margin %s, hidden past it %s, stays hidden going back %s, "
			+ "child without a KeyPrompt shown %s") % [shown_before, hidden_after, stays_hidden, marker_shown])
	tutorial.queue_free()
	player.queue_free()
	await process_frame
	return passed


func _level_1_has_the_hints() -> bool:
	var level: Node = (load(LEVEL_1_PATH) as PackedScene).instantiate()
	var tutorial: TutorialHints = level.get_node_or_null(^"Tutorial") as TutorialHints
	var names: PackedStringArray = []
	var follows_player: bool = false
	if tutorial != null:
		root.add_child(level)
		for hint: Node2D in tutorial.get_shown():
			names.append(hint.name)
		follows_player = tutorial.player == level.get_node_or_null(^"Player")
	names.sort()
	var expected: PackedStringArray = LEVEL_1_HINTS.duplicate()
	expected.sort()
	var passed: bool = tutorial != null and follows_player and names == expected
	_report(passed, "level 1: Tutorial has the script %s, follows the Player %s, hints %s" % [
			tutorial != null, follows_player, names])
	level.queue_free()
	await process_frame
	return passed


func _wait(frames: int) -> void:
	for i: int in frames:
		await physics_frame


func _report(passed: bool, text: String) -> void:
	print("%s %s" % ["PASS" if passed else "FAIL", text])
