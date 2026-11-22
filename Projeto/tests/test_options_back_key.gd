# Checks the key beside the options' Back (#284): a PromptGlyph for ui_cancel, right before the BACK
# button and in the same row as it, apart from Reset to defaults. On the keyboard it names Escape,
# though Escape is a reserved key, one the controls screen never offers, so it has no binding; once a
# pad is the device used last, it shows the pad's B.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_options_back_key.gd
extends "res://tests/support/player_test.gd"

const OPTIONS_SCENE: PackedScene = preload("res://scenes/screens/options_menu.tscn")
## What the glyph must name on each device.
const KEYBOARD_TEXT: String = "Escape"
const PAD_TEXT: String = "B"


func _initialize() -> void:
	# The autoloads' @onready values are set only after the first frame.
	await process_frame
	var results: Array[bool] = []
	var options: OptionsMenu = OPTIONS_SCENE.instantiate() as OptionsMenu
	root.add_child(options)
	options.open()
	await process_frame
	results.append(_the_key_sits_right_before_back(options))
	results.append(await _it_names_escape_then_the_pad_s_b(options))
	options.queue_free()
	await process_frame
	finish(results)


func _the_key_sits_right_before_back(options: OptionsMenu) -> bool:
	var glyph: PromptGlyph = options.find_child("BackGlyph", true, false) as PromptGlyph
	var back: Button = options.get_node_or_null(^"%BackButton") as Button
	var reset: Button = options.get_node_or_null(^"%ResetButton") as Button
	var beside: bool = (glyph != null and back != null and reset != null
			and glyph.get_parent() == back.get_parent() and back.get_index() == glyph.get_index() + 1
			and reset.get_parent() != back.get_parent())
	return report(beside, "The key sits right before BACK, in a row of their own (found key %s)"
			% [glyph != null])


func _it_names_escape_then_the_pad_s_b(options: OptionsMenu) -> bool:
	var glyph: PromptGlyph = options.find_child("BackGlyph", true, false) as PromptGlyph
	if glyph == null:
		return report(false, "The key's name: no BackGlyph")
	var keyboard: String = glyph.get_text()
	var on_keyboard: bool = not glyph.shows_pad() and keyboard == KEYBOARD_TEXT
	await _press(_pad_button(JOY_BUTTON_DPAD_DOWN))
	var pad: String = glyph.get_text()
	var on_pad: bool = glyph.shows_pad() and pad == PAD_TEXT
	return report(on_keyboard and on_pad, "The key's name: \"%s\" on the keyboard %s, \"%s\" on the pad %s"
			% [keyboard, on_keyboard, pad, on_pad])


## Sends a press and its release through Input, and waits until both reached the window.
func _press(event: InputEvent) -> void:
	Input.parse_input_event(event)
	var release: InputEvent = event.duplicate()
	release.set(&"pressed", false)
	Input.parse_input_event(release)
	await process_frame
	await process_frame


static func _pad_button(index: JoyButton) -> InputEventJoypadButton:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = index
	event.pressed = true
	return event
