# Checks Asmodeus as a node, with the man on a floor. She starts hidden. talk() shows her, says
# talk_started with its cue, keeps the man from running and jumping and his crucifix down, and
# opens the game's balloon; a second talk() meanwhile does nothing. Once her last line goes, on the
# next physics frame, the man runs, jumps and can raise the crucifix again, she hides, and she says
# talk_ended with the same cue. appear_at() puts her Appear Offset away from a point.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_asmodeus.gd
extends "res://tests/support/player_test.gd"

const ASMODEUS_SCENE: PackedScene = preload("res://scenes/characters/demon/asmodeus.tscn")
## A cue with no answers, so a skip runs it to the end.
const CUE: String = "stairs"
## Frames to wait for a line to come, or for the talk to end.
const LINE_FRAMES: int = 60


func _initialize() -> void:
	# The autoloads' @onready values are set only after the first frame.
	await process_frame
	make_platform(-2000.0, 2000.0)
	var results: Array[bool] = []
	results.append(await _a_talk_holds_the_man_and_lets_him_go_after())
	results.append(await _appear_at_puts_her_beside_a_point())
	finish(results)


func _a_talk_holds_the_man_and_lets_him_go_after() -> bool:
	var player: Player = await spawn_on_floor(Vector2(0.0, -100.0))
	var asmodeus: Asmodeus = _add_asmodeus(player)
	var crucifix: Crucifix = player.get_node(^"Crucifix") as Crucifix
	var started: Array[String] = []
	var ended: Array[String] = []
	asmodeus.talk_started.connect(func(cue: String) -> void: started.append(cue))
	asmodeus.talk_ended.connect(func(cue: String) -> void: ended.append(cue))
	await wait_frames(2)
	var hidden_first: bool = not asmodeus.visible
	asmodeus.talk(CUE)
	asmodeus.talk(CUE)
	var balloon: DialogueBalloon = await _balloon_of(asmodeus)
	var balloons: int = asmodeus.find_children("*", "CanvasLayer", false, false).size()
	var held: bool = (asmodeus.visible and asmodeus.is_talking() and player.get_speed_multiplier() == 0.0
			and player.is_jump_blocked() and crucifix.is_blocked() and balloon != null and balloons == 1)
	if balloon != null:
		balloon.skip_to_the_next_choice()
	var over: bool = await wait_until(func() -> bool: return not ended.is_empty(), LINE_FRAMES)
	var let_go: bool = (player.get_speed_multiplier() == 1.0 and not player.is_jump_blocked()
			and not crucifix.is_blocked() and not asmodeus.visible and not asmodeus.is_talking())
	asmodeus.queue_free()
	await remove_player(player)
	return report(hidden_first and held and over and let_go and started == [CUE] and ended == [CUE],
			("Talk: hidden at first %s; while talking shown, the man held, the crucifix down, one "
			+ "balloon %s; after the last line it ended %s, the man let go and she hid %s; started %s, "
			+ "ended %s") % [hidden_first, held, over, let_go, started, ended])


func _appear_at_puts_her_beside_a_point() -> bool:
	var player: Player = await spawn_on_floor(Vector2(0.0, -100.0))
	var asmodeus: Asmodeus = _add_asmodeus(player)
	var point: Vector2 = Vector2(500.0, -40.0)
	asmodeus.appear_at(point)
	var at: Vector2 = asmodeus.global_position
	var expected: Vector2 = point + asmodeus.appear_offset
	asmodeus.queue_free()
	await remove_player(player)
	return report(at.is_equal_approx(expected), "appear_at(%s) puts her at %s (expected %s)"
			% [point, at, expected])


func _add_asmodeus(player: Player) -> Asmodeus:
	var asmodeus: Asmodeus = ASMODEUS_SCENE.instantiate() as Asmodeus
	asmodeus.player = player
	root.add_child(asmodeus)
	return asmodeus


## Her balloon once it shows its first line; null if it never does.
func _balloon_of(asmodeus: Asmodeus) -> DialogueBalloon:
	var found: Array[DialogueBalloon] = []
	await wait_until(func() -> bool:
		for child: Node in asmodeus.get_children():
			if child is DialogueBalloon and (child as DialogueBalloon).dialogue_line != null:
				found.append(child)
				return true
		return false, LINE_FRAMES)
	return found[0] if not found.is_empty() else null
