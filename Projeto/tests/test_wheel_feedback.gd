# Checks how the dialogue wheel feels (#284): its answers answer as the menus do, through the
# balloon's own MenuFeedback (AnswerFeedback), which has no menu and plays only what the balloon asks
# (Only Asked), with no warning. Pointing at another answer clicks with the menus' move pulse; the
# stick back in the middle is silent; a click within the feedback's Move Gap of the last is not
# heard, one at the gap is; confirming blows with the confirm pulse. The pulses come from the scene,
# as the script makes none, so an exported game keeps them. The wheel holds the answer pointed at
# until the stick comes back past its Aim Release Margin: a stick resting on the deadzone's edge or
# on the line between two answers points once, not every frame, while a clear push still moves on.
# The real input path, a move key held while the wheel shows, points and clicks too.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_wheel_feedback.gd
extends "res://tests/support/player_test.gd"

const BALLOON_SCENE: PackedScene = preload("res://scenes/screens/dialogue_balloon.tscn")
const LEFT: Vector2 = Vector2(-1.0, 0.0)
const RIGHT: Vector2 = Vector2(1.0, 0.0)
## How far the test's clock moves between two calm moves, in ms: past every gap.
const CALM_MS: int = 500
## Times the stick goes back and forth over a line in the resting cases.
const WOBBLES: int = 20
## How far each wobble goes past the line, as a part of the stick's length: inside the margin.
const WOBBLE: float = 0.02
## The stick's length in the case on the line between two rows.
const ROW_CASE_LENGTH: float = 0.8
## Frames the move key is held in the real input case.
const HELD_FRAMES: int = 3

var _now_ms: int = 10000


func _initialize() -> void:
	await process_frame
	var balloon: DialogueBalloon = BALLOON_SCENE.instantiate() as DialogueBalloon
	root.add_child(balloon)
	await process_frame
	var feedback: MenuFeedback = balloon.get_node_or_null(^"%AnswerFeedback") as MenuFeedback
	var wheel: DialogueWheel = balloon.get_node_or_null(^"%Wheel") as DialogueWheel
	var results: Array[bool] = []
	if feedback == null or wheel == null:
		results.append(report(false, "The balloon has no AnswerFeedback or no Wheel"))
	else:
		feedback.clock = func() -> int: return _now_ms
		results.append(_the_feedback_asks_no_menu_and_its_pulses_come_from_the_scene(feedback))
		results.append(_the_wheel_clicks_and_blows_as_the_menus(feedback, wheel))
		results.append(_a_resting_stick_points_once(wheel))
		results.append(await _a_held_move_key_points_and_clicks(balloon, feedback, wheel))
	balloon.queue_free()
	await wait_frames(2)
	finish(results)


func _the_feedback_asks_no_menu_and_its_pulses_come_from_the_scene(feedback: MenuFeedback) -> bool:
	var bare: MenuFeedback = MenuFeedback.new()
	var script_makes_none: bool = bare.move_pulse == null and bare.confirm_pulse == null
	bare.free()
	var passed: bool = (feedback.menu == null and feedback.only_asked and script_makes_none
			and feedback.move_pulse != null and feedback.confirm_pulse != null)
	return report(passed, ("AnswerFeedback: no menu %s, Only Asked %s, pulses from the scene %s "
			+ "(the script makes none %s)") % [feedback.menu == null, feedback.only_asked,
			feedback.move_pulse != null and feedback.confirm_pulse != null, script_makes_none])


func _the_wheel_clicks_and_blows_as_the_menus(feedback: MenuFeedback, wheel: DialogueWheel) -> bool:
	var heard: Array[StringName] = []
	var listen: Callable = func(sound: StringName) -> void: heard.append(sound)
	feedback.played.connect(listen)
	wheel.responses = [_answer("No."), _answer("Yes.")]
	wheel.point(LEFT)
	var pointed: Array[StringName] = heard.duplicate()
	_now_ms += CALM_MS
	wheel.point(Vector2.ZERO)
	var centred: Array[StringName] = heard.duplicate()
	_now_ms += CALM_MS
	wheel.point(RIGHT)
	var clicked_at: int = _now_ms
	_now_ms = clicked_at + feedback.move_gap_ms - 1
	wheel.point(LEFT)
	var within_gap: Array[StringName] = heard.duplicate()
	_now_ms = clicked_at + feedback.move_gap_ms
	wheel.point(RIGHT)
	var at_gap: Array[StringName] = heard.duplicate()
	_now_ms += CALM_MS
	wheel.confirm()
	feedback.played.disconnect(listen)
	var passed: bool = (pointed == [&"move"] and centred == [&"move"]
			and within_gap == [&"move", &"move"] and at_gap == [&"move", &"move", &"move"]
			and heard == [&"move", &"move", &"move", &"confirm"])
	return report(passed, ("The wheel's sounds: pointing %s, back to the middle %s, within the gap "
			+ "%s, at the gap %s, confirming %s") % [pointed, centred, within_gap, at_gap, heard])


func _a_resting_stick_points_once(wheel: DialogueWheel) -> bool:
	wheel.responses = [_answer("1"), _answer("2"), _answer("3"), _answer("4")]
	var times: Array[int] = []
	var count: Callable = func(index: int) -> void: times.append(index)
	wheel.pointed.connect(count)
	var edge: float = wheel.aim_deadzone
	for wobble: int in WOBBLES:
		var length: float = edge + (WOBBLE if wobble % 2 == 0 else -WOBBLE)
		wheel.point(Vector2(-length, 0.0))
	var on_the_edge: int = times.size()
	var share: float = ROW_CASE_LENGTH * wheel.aim_axis_share
	for wobble: int in WOBBLES:
		var y: float = share + ROW_CASE_LENGTH * (WOBBLE if wobble % 2 == 0 else -WOBBLE)
		wheel.point(Vector2(-sqrt(ROW_CASE_LENGTH * ROW_CASE_LENGTH - y * y), y))
	var on_the_line: int = times.size()
	wheel.point(Vector2(-0.6, 0.6))
	var pushed_on: bool = wheel.selected == 2 and times.size() == on_the_line + 1
	wheel.pointed.disconnect(count)
	return report(on_the_edge == 1 and on_the_line == 1 and pushed_on, ("A resting stick: pointed %d "
			+ "time(s) on the deadzone's edge, %d in all after the line between rows, a clear push "
			+ "down-left moves on %s") % [on_the_edge, on_the_line, pushed_on])


func _a_held_move_key_points_and_clicks(balloon: DialogueBalloon, feedback: MenuFeedback,
		wheel: DialogueWheel) -> bool:
	wheel.responses = [_answer("No."), _answer("Yes.")]
	(balloon.get_node(^"%Balloon") as Control).show()
	wheel.show()
	_now_ms += CALM_MS
	var heard: Array[StringName] = []
	var listen: Callable = func(sound: StringName) -> void: heard.append(sound)
	feedback.played.connect(listen)
	Input.action_press(&"move_right")
	for frame: int in HELD_FRAMES:
		await process_frame
	var selected: int = wheel.selected
	Input.action_release(&"move_right")
	await process_frame
	feedback.played.disconnect(listen)
	return report(selected == 1 and heard == [&"move"],
			"Move Right held while the wheel shows: points at %d, heard %s" % [selected, heard])


static func _answer(text: String) -> DialogueResponse:
	var response: DialogueResponse = DialogueResponse.new()
	response.text = text
	return response
