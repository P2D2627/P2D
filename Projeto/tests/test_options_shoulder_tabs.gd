# Checks the pad's shoulder buttons in the settings screen. Open, it is on its first tab; R1 goes to
# the next tab and L1 back, round from the first to the last, with the focus on the tab, from
# wherever the focus was in the page.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_options_shoulder_tabs.gd
extends "res://tests/support/player_test.gd"

const OPTIONS_SCENE: PackedScene = preload("res://scenes/screens/options_menu.tscn")


func _initialize() -> void:
	await process_frame
	var results: Array[bool] = []
	results.append(await _the_shoulders_step_through_the_tabs())
	finish(results)


func _the_shoulders_step_through_the_tabs() -> bool:
	var menu: OptionsMenu = OPTIONS_SCENE.instantiate()
	root.add_child(menu)
	await wait_frames(2)
	menu.open()
	await wait_frames(2)
	var tabs: Container = menu.get_node(^"%Tabs") as Container
	var count: int = tabs.get_child_count()
	var first: Control = tabs.get_child(0) as Control
	var second: Control = tabs.get_child(1) as Control
	var last: Control = tabs.get_child(count - 1) as Control
	var visited: Array[String] = [_focused()]
	_press(OptionsMenu.NEXT_TAB_ACTION)
	await wait_frames(1)
	visited.append(_focused())
	_press(OptionsMenu.PREVIOUS_TAB_ACTION)
	await wait_frames(1)
	visited.append(_focused())
	_press(OptionsMenu.PREVIOUS_TAB_ACTION)
	await wait_frames(1)
	visited.append(_focused())
	var expected: Array[String] = [first.name, second.name, first.name, last.name]
	menu.queue_free()
	await wait_frames(2)
	return report(visited == expected, "focus on open, R1, L1, L1: %s (expected %s)" % [visited, expected])


func _focused() -> String:
	var owner: Control = root.gui_get_focus_owner()
	return String(owner.name) if owner != null else "none"


func _press(action: StringName) -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	var release: InputEventAction = InputEventAction.new()
	release.action = action
	Input.parse_input_event(release)
	Input.flush_buffered_events()
