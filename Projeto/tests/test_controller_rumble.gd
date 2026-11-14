# Checks the controller's vibration (ADR 0062). The rules on their own: a pulse holds its two motors
# for its time and then ends, and the first advance after it starts, the frame it starts on, takes no
# time off it; pulses that overlap keep the strongest level of each motor, never their sum, and a
# weaker one never cuts a stronger one short; a motor out of 0 to 1 is kept in range, one that is not
# a number counts as 0, and a pulse with both motors at 0, or with no time, a negative one, or one
# that is not a number or never ends, starts nothing; clearing ends every pulse at once; a pulse with
# a fade falls in a straight line over the end of its time. A sustained vibration throbs from the top
# of each throb, takes new levels and keeps its throb, gives each motor the stronger of two, gives
# way to a pulse only on the motors the pulse runs, coming back in step with its fade, has its whole
# level once the pulses end, outlives the pulses being cleared and ends by its key, with both motors
# at 0 or with everything; its values out of range are kept in range. The node: only the controller
# used last vibrates, none after a key or a mouse button, and not one whose stick barely moved; an
# unplugged one is no longer in use, and the next level starts with the one in use; with two nodes,
# each moves its own vibration to the controller in use; no pulse asks nothing; a pulse asks the
# controller for its motors at once and for as long as it lasts, the controller is told to stop when
# it ends, and the node then stops running; an equal pulse that starts while one runs asks again, so fast presses
# vibrate until the last, while the game's own tick, ten presses a second, ends before each next
# press; the controller is asked again only when what the pulses give changes; the Vibration option
# scales both motors, and at 0 the controller is never asked to vibrate; a pause, leaving the window
# and leaving the level stop it at once and drop the pulses, with the window out of focus no pulse
# starts, and back in focus none of those comes back. A sustained vibration asks at once, at its share, and again before its request runs
# out, and ends; Constant Vibration off leaves it out but not the pulses; a pause or leaving the
# window keeps it for later. The Vibration option is 1 with no file, stays in 0 to 1, takes the
# default for a value that is not a number, is saved and read back apart from the screen shake, and
# Reset brings it back; a file with a word, nan, inf or a number out of range gives each strength the
# default or the nearest limit; Constant Vibration is on with no file, is saved, read back and reset,
# and a wrong value gives the default. The options screen shows the Vibration slider under the screen
# shake and changes it, and the Constant vibration switch under it; moving the slider plays a hit's
# pulse on the controller in use, and a real mouse drag plays it once as it ends, on the controller
# used last; closed mid-drag, the screen still plays it at the next change. Which moments and states
# vibrate, and how, is in test_rumble_moments.gd.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_controller_rumble.gd
extends "res://tests/support/player_test.gd"

const OPTIONS_SCENE: PackedScene = preload("res://scenes/screens/options_menu.tscn")
const SETTINGS_SCRIPT: GDScript = preload("res://scenes/autoload/settings.gd")
const RUMBLE_STATS: RumbleStats = preload("res://scenes/others/feedback/rumble_stats.tres")
const TEST_PATH: String = "user://test_controller_rumble.cfg"
## How close two numbers must be to count as the same.
const TOLERANCE: float = 0.0001
## The tests' fixed frames a second.
const FRAMES_PER_SECOND: float = 60.0
## The controller the cases use and a second one: ids no controller plugged into the computer running
## the tests is likely to have, so no real controller vibrates.
const PAD: int = 6
const OTHER_PAD: int = 7
## A button no action uses, pressed to make a controller the one in use.
const SPARE_BUTTON: JoyButton = JOY_BUTTON_PADDLE4
## A key no action uses, pressed to go back to the keyboard.
const SPARE_KEY: Key = KEY_SCROLLLOCK
## A stick movement too small to count, and one that counts.
const RESTING_STICK: float = 0.2
const MOVED_STICK: float = 0.9
## The pulse the node's cases play: both motors, long enough to watch.
const PULSE_WEAK: float = 0.4
const PULSE_STRONG: float = 0.8
const PULSE_TIME: float = 0.25
## Frames past a pulse's end the cases wait for the controller to be told to stop.
const END_MARGIN_FRAMES: int = 3
## The Vibration option in the case that scales it.
const HALF: float = 0.5
## A tick on the weak motor alone, longer than the gap between the fast presses: those come every
## FAST_PRESS_FRAMES frames, FAST_PRESSES of them. Ten presses a second come every
## TEN_A_SECOND_FRAMES frames, SLOW_PRESSES of them.
const TICK_WEAK: float = 0.5
const TICK_TIME: float = 0.1
const FAST_PRESS_FRAMES: int = 4
const FAST_PRESSES: int = 4
const TEN_A_SECOND_FRAMES: int = 6
const SLOW_PRESSES: int = 3
## Two pulses that overlap in the case that watches the requests: a short one on the weak motor and
## a long one on the strong motor. MARKER is written straight to the controller, to see whether the
## node asks it again.
const SHORT_WEAK: Vector3 = Vector3(0.6, 0.0, 0.1)
const LONG_STRONG: Vector3 = Vector3(0.0, 0.8, 0.4)
const MARKER: Vector2 = Vector2(0.123, 0.321)
## A request time far longer than any case.
const MARKER_TIME: float = 9.0
## The sustained vibration the node's cases hold, flat so its level reads the same on every frame,
## and enough frames for its request to come within RENEW_BEFORE of running out.
const HELD_WEAK: float = 0.3
const HELD_STRONG: float = 0.6
const RENEW_FRAMES: int = 12
## The Vibration slider's values in the sample case: one a controller moves it to, and one a mouse
## drags it to.
const SAMPLE_STEPPED: float = 0.5
const SAMPLE_DRAGGED: float = 0.8


func _initialize() -> void:
	await process_frame
	var results: Array[bool] = []
	results.append(_a_pulse_runs_for_its_time())
	results.append(_overlapping_pulses_keep_the_strongest_level_of_each_motor())
	results.append(_a_pulse_out_of_range_is_kept_in_range_or_starts_nothing())
	results.append(_a_pulse_fades_over_the_end_of_its_time())
	results.append(_a_sustained_vibration_throbs_and_gives_way_to_a_pulse())
	results.append(_a_sustained_vibration_out_of_range_is_kept_in_range())
	results.append(await _only_the_controller_used_last_vibrates())
	results.append(await _the_next_level_starts_with_the_controller_in_use())
	results.append(await _every_node_moves_its_vibration_to_the_controller_in_use())
	results.append(await _a_pulse_asks_at_once_and_the_controller_stops_when_it_ends())
	results.append(await _equal_pulses_ask_again_and_ticks_ten_a_second_stay_apart())
	results.append(await _the_controller_is_asked_again_only_when_its_levels_change())
	results.append(await _the_option_scales_the_vibration_and_at_zero_asks_for_none())
	results.append(await _a_pause_leaving_the_window_or_the_level_stops_it())
	results.append(await _a_sustained_vibration_is_asked_for_and_renewed_until_it_ends())
	results.append(await _the_constant_option_leaves_sustained_vibrations_out())
	results.append(await _a_pause_or_leaving_the_window_keeps_a_sustained_vibration_for_later())
	results.append(await _the_constant_option_is_on_by_default_saved_and_read_back())
	results.append(await _the_option_is_one_by_default_kept_in_range_and_saved())
	results.append(await _a_file_with_wrong_values_gives_the_default_or_the_nearest_limit())
	results.append(await _the_options_screen_shows_and_changes_the_option())
	results.append(await _the_options_screen_switches_constant_vibration_and_plays_a_sample())
	results.append(await _the_options_closed_mid_drag_still_play_the_sample())
	Input.stop_joy_vibration(PAD)
	Input.stop_joy_vibration(OTHER_PAD)
	_delete_test_file()
	finish(results)


## A pulse holds its two motors while it runs, says how long it has left, and ends once its time is
## up: both motors are back to 0. The first advance after it starts, the frame it starts on, takes no
## time off it.
func _a_pulse_runs_for_its_time() -> bool:
	var rules: RumbleRules = RumbleRules.new()
	rules.add(0.3, 0.6, 0.2)
	var at_start: Vector2 = _levels(rules)
	rules.advance(0.15)
	var whole: float = rules.get_time_left()
	rules.advance(0.15)
	var running: Vector2 = _levels(rules)
	var time_left: float = rules.get_time_left()
	rules.advance(0.1)
	var after: Vector2 = _levels(rules)
	var expected: Vector2 = Vector2(0.3, 0.6)
	return report(at_start.is_equal_approx(expected) and is_equal_approx(whole, 0.2)
			and running.is_equal_approx(expected) and absf(time_left - 0.05) < TOLERANCE
			and after == Vector2.ZERO and not rules.is_running() and rules.get_time_left() == 0.0,
			("a pulse of (0.3, 0.6) for 0.2 s: at the start %s; the first advance takes nothing off: %.3f s "
			+ "left (0.2); 0.15 s later %s with %.3f s left (0.05); 0.1 s after that %s, still running: %s")
			% [at_start, whole, running, time_left, after, rules.is_running()])


## Pulses that overlap: each motor runs at the strongest running level, never at the sum, so the same
## pulse twice is no stronger than once; a weaker pulse that comes later does not cut a stronger one
## short, and once the stronger ends, the weaker goes on alone until its own time is up. An advance
## of 0 after each start stands for the frame the pulses start on.
func _overlapping_pulses_keep_the_strongest_level_of_each_motor() -> bool:
	var rules: RumbleRules = RumbleRules.new()
	rules.add(0.0, 0.8, 0.3)
	rules.add(0.5, 0.2, 0.1)
	var together: Vector2 = _levels(rules)
	rules.add(0.5, 0.8, 0.1)
	var twice: Vector2 = _levels(rules)
	rules.advance(0.0)
	rules.advance(0.15)
	var long_alone: Vector2 = _levels(rules)
	rules.add(0.2, 0.1, 0.25)
	var weaker_later: Vector2 = _levels(rules)
	rules.advance(0.0)
	rules.advance(0.2)
	var weaker_goes_on: Vector2 = _levels(rules)
	rules.advance(0.1)
	var all_over: Vector2 = _levels(rules)
	return report(together.is_equal_approx(Vector2(0.5, 0.8)) and twice.is_equal_approx(Vector2(0.5, 0.8))
			and long_alone.is_equal_approx(Vector2(0.0, 0.8))
			and weaker_later.is_equal_approx(Vector2(0.2, 0.8))
			and weaker_goes_on.is_equal_approx(Vector2(0.2, 0.1)) and all_over == Vector2.ZERO,
			("(0, 0.8) for 0.3 s with (0.5, 0.2) for 0.1 s: %s (0.5, 0.8); with (0.5, 0.8) on top: %s (the "
			+ "same); at 0.15 s: %s (0, 0.8); (0.2, 0.1) for 0.25 s then: %s (0.2, 0.8); at 0.35 s: %s "
			+ "(0.2, 0.1); at 0.45 s: %s (0, 0)")
			% [together, twice, long_alone, weaker_later, weaker_goes_on, all_over])


## A motor above 1 or below 0 is kept in range, one that is not a number counts as 0, and clear()
## ends every pulse at once. A pulse with both motors at 0, or with no time, a negative one, or one
## that is not a number or never ends, starts nothing.
func _a_pulse_out_of_range_is_kept_in_range_or_starts_nothing() -> bool:
	var rules: RumbleRules = RumbleRules.new()
	rules.add(2.0, -1.0, 0.1)
	var kept: Vector2 = _levels(rules)
	rules.clear()
	var cleared: bool = _levels(rules) == Vector2.ZERO and not rules.is_running()
	rules.add(NAN, 0.5, 0.1)
	var not_a_number: Vector2 = _levels(rules)
	rules.clear()
	var started: Array[String] = []
	for duration: float in [0.0, -1.0, NAN, INF]:
		rules.add(0.5, 0.5, duration)
		if rules.is_running():
			started.append("for %s s" % duration)
			rules.clear()
	for motors: Vector2 in [Vector2.ZERO, Vector2(NAN, NAN), Vector2(-1.0, -1.0)]:
		rules.add(motors.x, motors.y, 0.1)
		if rules.is_running():
			started.append("of %s" % motors)
			rules.clear()
	return report(kept.is_equal_approx(Vector2(1.0, 0.0)) and cleared
			and not_a_number.is_equal_approx(Vector2(0.0, 0.5)) and started.is_empty(),
			("(2, -1) is kept as %s (1, 0); clear() ends it: %s; (nan, 0.5) gives %s (0, 0.5); pulses that "
			+ "started but should not: %s") % [kept, cleared, not_a_number, started])


## A pulse with a fade holds its levels until the fade begins and then falls in a straight line, to
## nothing as its time runs out; one with a fade of 1 falls from the start. The first advance, the
## frame it starts on, takes no time off it.
func _a_pulse_fades_over_the_end_of_its_time() -> bool:
	var rules: RumbleRules = RumbleRules.new()
	rules.add(0.8, 0.4, 1.0, 0.5)
	rules.advance(0.0)
	var at_start: Vector2 = _levels(rules)
	rules.advance(0.4)
	var before_fade: Vector2 = _levels(rules)
	rules.advance(0.35)
	var halfway_down: Vector2 = _levels(rules)
	rules.advance(0.3)
	var after: Vector2 = _levels(rules)
	rules.add(0.6, 0.0, 0.2, 1.0)
	rules.advance(0.0)
	rules.advance(0.05)
	var from_start: Vector2 = _levels(rules)
	return report(at_start.is_equal_approx(Vector2(0.8, 0.4))
			and before_fade.is_equal_approx(Vector2(0.8, 0.4))
			and halfway_down.is_equal_approx(Vector2(0.4, 0.2)) and after == Vector2.ZERO
			and from_start.is_equal_approx(Vector2(0.45, 0.0)),
			("(0.8, 0.4) for 1 s, fading over its last half: %s at the start, %s at 0.4 s (the same), "
			+ "%s at 0.75 s (half), %s at 1.05 s (0); (0.6, 0) for 0.2 s fading from the start: %s at "
			+ "0.05 s (0.45, 0)") % [at_start, before_fade, halfway_down, after, from_start])


## A sustained vibration starts at the top of a throb and dips by its depth halfway through it, 2
## throbs a second here; called again, it takes the new levels and keeps the throb where it was. Two
## of them give each motor the stronger. A pulse makes it give way only on the motors the pulse runs:
## there it keeps duck_share of its level and each motor runs at the stronger of the two, while on a
## motor the pulse leaves alone it runs whole, so a tick on the weak motor does not hide a strong
## one. As a pulse fades, it comes back in step: halfway down a pulse that fades from its start, it
## keeps halfway between duck_share and all of it. Without sustains, only the pulses count; once they
## end, it is back to its whole level. Clearing the pulses leaves it running; end_sustain(), both
## motors at 0 and clear() end it.
func _a_sustained_vibration_throbs_and_gives_way_to_a_pulse() -> bool:
	var rules: RumbleRules = RumbleRules.new()
	rules.duck_share = 0.25
	rules.sustain(&"held", 0.4, 0.8, 2.0, 0.5)
	var at_start: Vector2 = _levels(rules)
	rules.advance(0.25)
	var at_dip: Vector2 = _levels(rules)
	rules.sustain(&"held", 0.2, 0.4, 2.0, 0.5)
	var changed: Vector2 = _levels(rules)
	rules.advance(0.25)
	var back_on_top: Vector2 = _levels(rules)
	rules.sustain(&"other", 0.3, 0.1, 0.0, 0.0)
	var two: Vector2 = _levels(rules)
	rules.end_sustain(&"other")
	rules.end_sustain(&"held")
	rules.sustain(&"flat", 0.2, 0.4, 0.0, 0.0)
	rules.add(0.1, 0.0, 0.2)
	var under_weak_pulse: Vector2 = _levels(rules)
	var pulse_only: Vector2 = rules.get_levels(false)
	rules.add(0.0, 0.05, 0.2)
	var under_both: Vector2 = _levels(rules)
	rules.advance(0.0)
	rules.advance(0.5)
	var after_pulses: Vector2 = _levels(rules)
	rules.add(0.1, 0.1, 0.2, 1.0)
	rules.advance(0.0)
	rules.advance(0.1)
	var half_faded: Vector2 = _levels(rules)
	rules.add(0.1, 0.0, 0.2)
	rules.clear_pulses()
	var pulses_cleared: Vector2 = _levels(rules)
	var still_sustaining: bool = rules.is_sustaining()
	rules.end_sustain(&"flat")
	var ended: bool = _levels(rules) == Vector2.ZERO and not rules.is_running()
	rules.sustain(&"held", 0.3, 0.3, 0.0, 0.0)
	rules.sustain(&"held", 0.0, 0.0, 1.0, 1.0)
	var zero_ends: bool = not rules.is_sustaining()
	rules.sustain(&"held", 0.3, 0.3, 0.0, 0.0)
	rules.sustain(&"other", 0.3, 0.3, 0.0, 0.0)
	rules.clear()
	var cleared: bool = not rules.is_running()
	return report(at_start.is_equal_approx(Vector2(0.4, 0.8)) and at_dip.is_equal_approx(Vector2(0.2, 0.4))
			and changed.is_equal_approx(Vector2(0.1, 0.2))
			and back_on_top.is_equal_approx(Vector2(0.2, 0.4)) and two.is_equal_approx(Vector2(0.3, 0.4))
			and under_weak_pulse.is_equal_approx(Vector2(0.1, 0.4))
			and pulse_only.is_equal_approx(Vector2(0.1, 0.0))
			and under_both.is_equal_approx(Vector2(0.1, 0.1))
			and after_pulses.is_equal_approx(Vector2(0.2, 0.4))
			and half_faded.is_equal_approx(Vector2(0.125, 0.25))
			and pulses_cleared.is_equal_approx(Vector2(0.2, 0.4)) and still_sustaining and ended
			and zero_ends and cleared,
			("(0.4, 0.8) at 2 throbs a second, half deep: %s at the start, %s at 0.25 s (half); as "
			+ "(0.2, 0.4): %s (0.1, 0.2), %s at 0.5 s (0.2, 0.4); with (0.3, 0.1) too: %s (0.3, 0.4); "
			+ "flat (0.2, 0.4) under a pulse of (0.1, 0) with a quarter kept: %s (0.1, 0.4), without "
			+ "sustains %s (0.1, 0); with one of (0, 0.05) too: %s (0.1, 0.1); after them: %s (0.2, 0.4); "
			+ "halfway down a pulse of (0.1, 0.1) that fades from its start: %s (0.125, 0.25); pulses "
			+ "cleared: %s (0.2, 0.4), still sustaining: %s; ended by end_sustain(): %s, by both motors "
			+ "at 0: %s, by clear(): %s")
			% [at_start, at_dip, changed, back_on_top, two, under_weak_pulse, pulse_only, under_both,
			after_pulses, half_faded, pulses_cleared, still_sustaining, ended, zero_ends, cleared])


## A sustained vibration's motors above 1 or below 0 are kept in range and one that is not a number
## counts as 0; a depth above 1 dips to nothing, and a rate that is negative, not a number or
## infinite holds it flat.
func _a_sustained_vibration_out_of_range_is_kept_in_range() -> bool:
	var rules: RumbleRules = RumbleRules.new()
	rules.sustain(&"held", 2.0, NAN, 2.0, 3.0)
	rules.advance(0.25)
	var deepest: Vector2 = _levels(rules)
	var flat: Array[String] = []
	for rate: float in [-1.0, NAN, INF]:
		rules.clear()
		rules.sustain(&"held", 0.5, 0.5, rate, 0.5)
		rules.advance(0.25)
		if not _levels(rules).is_equal_approx(Vector2(0.5, 0.5)):
			flat.append("a rate of %s gives %s" % [rate, _levels(rules)])
	return report(deepest.is_equal_approx(Vector2.ZERO) and flat.is_empty(),
			("(2, nan) with a depth of 3, halfway through a throb: %s (0, 0, as (1, 0) dips to nothing); "
			+ "rates that should hold it flat but do not: %s") % [deepest, flat])


## Only the controller used last vibrates. With the keyboard in use, a pulse asks nothing of any
## controller. After a press on PAD, PAD vibrates; a stick that barely moves on OTHER_PAD changes
## nothing, and one that moves well makes OTHER_PAD the one in use: PAD stops, and OTHER_PAD takes the
## running pulse. After a key, OTHER_PAD stops and a new pulse asks nothing of either; a mouse button
## does the same to PAD. Unplugged while in use, PAD stops and is no longer in use.
func _only_the_controller_used_last_vibrates() -> bool:
	var rumble: ControllerRumble = _new_rumble()
	await process_frame
	var pulse: Vector2 = Vector2(PULSE_WEAK, PULSE_STRONG)
	rumble.play(_pulse())
	var keyboard_asks_none: bool = (rumble.get_device() == ControllerRumble.NO_DEVICE
			and _asked_of(PAD) == Vector2.ZERO and _asked_of(OTHER_PAD) == Vector2.ZERO)
	rumble.stop()
	_press_on(PAD)
	rumble.play(_pulse())
	var on_pad: Vector2 = _asked_of(PAD)
	_move_stick_on(OTHER_PAD, RESTING_STICK)
	var after_resting_stick: int = rumble.get_device()
	_move_stick_on(OTHER_PAD, MOVED_STICK)
	var after_moved_stick: int = rumble.get_device()
	var pad_after_move: Vector2 = _asked_of(PAD)
	var other_after_move: Vector2 = _asked_of(OTHER_PAD)
	_press_key()
	var after_key: int = rumble.get_device()
	var other_after_key: Vector2 = _asked_of(OTHER_PAD)
	rumble.play(_pulse())
	var key_asks_none: bool = _asked_of(PAD) == Vector2.ZERO and _asked_of(OTHER_PAD) == Vector2.ZERO
	_press_on(PAD)
	var pad_again: Vector2 = _asked_of(PAD)
	_press_mouse_button()
	var after_mouse: int = rumble.get_device()
	var pad_after_mouse: Vector2 = _asked_of(PAD)
	_press_on(PAD)
	Input.joy_connection_changed.emit(PAD, false)
	var after_unplug: int = rumble.get_device()
	var pad_after_unplug: Vector2 = _asked_of(PAD)
	rumble.queue_free()
	await process_frame
	return report(keyboard_asks_none and on_pad.is_equal_approx(pulse) and after_resting_stick == PAD
			and after_moved_stick == OTHER_PAD and pad_after_move == Vector2.ZERO
			and other_after_move.is_equal_approx(pulse) and after_key == ControllerRumble.NO_DEVICE
			and other_after_key == Vector2.ZERO and key_asks_none and pad_again.is_equal_approx(pulse)
			and after_mouse == ControllerRumble.NO_DEVICE and pad_after_mouse == Vector2.ZERO
			and after_unplug == ControllerRumble.NO_DEVICE and pad_after_unplug == Vector2.ZERO,
			("with the keyboard in use, none asked: %s; after a press on %d: %s (%s); a resting stick on %d "
			+ "leaves %d in use; a moved one gives %d, with %s on %d and %s on %d; after a key: %d in use, "
			+ "%s on %d, and a new pulse asks none: %s; a press on %d again: %s; after a mouse button: %d "
			+ "in use, %s on %d; unplugged: %d in use, %s on it")
			% [keyboard_asks_none, PAD, on_pad, pulse, OTHER_PAD, after_resting_stick, after_moved_stick,
			pad_after_move, PAD, other_after_move, OTHER_PAD, after_key, other_after_key, OTHER_PAD,
			key_asks_none, PAD, pad_again, after_mouse, pad_after_mouse, PAD, after_unplug,
			pad_after_unplug])


## The controller in use is kept for the next level: a node made after the first one has gone starts
## with it, and its first pulse vibrates it before any new input.
func _the_next_level_starts_with_the_controller_in_use() -> bool:
	var first: ControllerRumble = _new_rumble()
	await process_frame
	_press_on(PAD)
	first.queue_free()
	await process_frame
	var second: ControllerRumble = ControllerRumble.new()
	root.add_child(second)
	await process_frame
	var kept: int = second.get_device()
	second.play(_pulse())
	var asked: Vector2 = _asked_of(PAD)
	second.queue_free()
	await process_frame
	var pulse: Vector2 = Vector2(PULSE_WEAK, PULSE_STRONG)
	return report(kept == PAD and asked.is_equal_approx(pulse),
			"the next node starts with %d in use (%d), and its first pulse asks %s of it (%s)"
			% [kept, PAD, asked, pulse])


## Each node moves its own vibration to the controller in use, whichever node sees the input first,
## as in the game, where the level's node and the options screens' samples are in the tree together.
## With two nodes, a pulse on the first and a press on OTHER_PAD: PAD stops and OTHER_PAD takes the
## pulse at once; a pulse on the second and a press on PAD: the same the other way round. A key stops
## the controller at once, a sustained vibration too.
func _every_node_moves_its_vibration_to_the_controller_in_use() -> bool:
	var first: ControllerRumble = _new_rumble()
	var second: ControllerRumble = ControllerRumble.new()
	root.add_child(second)
	await process_frame
	var pulse: Vector2 = Vector2(PULSE_WEAK, PULSE_STRONG)
	_press_on(PAD)
	first.play(_pulse())
	_press_on(OTHER_PAD)
	var first_on_pad: Vector2 = _asked_of(PAD)
	var first_on_other: Vector2 = _asked_of(OTHER_PAD)
	first.stop()
	second.play(_pulse())
	_press_on(PAD)
	var second_on_other: Vector2 = _asked_of(OTHER_PAD)
	var second_on_pad: Vector2 = _asked_of(PAD)
	second.stop()
	first.sustain(&"held", RumbleSustain.new(HELD_WEAK, HELD_STRONG))
	var held: Vector2 = _asked_of(PAD)
	_press_key()
	var held_after_key: Vector2 = _asked_of(PAD)
	first.queue_free()
	second.queue_free()
	await process_frame
	return report(first_on_pad == Vector2.ZERO and first_on_other.is_equal_approx(pulse)
			and second_on_other == Vector2.ZERO and second_on_pad.is_equal_approx(pulse)
			and held.is_equal_approx(Vector2(HELD_WEAK, HELD_STRONG)) and held_after_key == Vector2.ZERO,
			("the first node's pulse after a press on %d: %s on %d, %s on %d (%s); the second's after a "
			+ "press on %d: %s on %d, %s on %d; the first's held vibration %s, after a key %s")
			% [OTHER_PAD, first_on_pad, PAD, first_on_other, OTHER_PAD, pulse, PAD, second_on_other,
			OTHER_PAD, second_on_pad, PAD, held, held_after_key])


## Idle, the node does not run, and no pulse asks nothing. A pulse asks the controller in use for its
## two motors at once, for as long as it lasts, and the node runs; once its time is up, the controller
## is told to stop and the node stops running.
func _a_pulse_asks_at_once_and_the_controller_stops_when_it_ends() -> bool:
	var rumble: ControllerRumble = _new_rumble()
	await process_frame
	_press_on(PAD)
	rumble.play(null)
	var idle_before: bool = not rumble.is_processing() and _asked_of(PAD) == Vector2.ZERO
	rumble.play(_pulse())
	var asked: Vector2 = _asked_of(PAD)
	var asked_for: float = Input.get_joy_vibration_duration(PAD)
	var running: bool = rumble.is_processing()
	await _frames(ceili(PULSE_TIME * FRAMES_PER_SECOND) + END_MARGIN_FRAMES)
	var after: Vector2 = _asked_of(PAD)
	var idle_after: bool = not rumble.is_processing()
	rumble.queue_free()
	await process_frame
	return report(idle_before and asked.is_equal_approx(Vector2(PULSE_WEAK, PULSE_STRONG))
			and is_equal_approx(asked_for, PULSE_TIME) and running and after == Vector2.ZERO and idle_after,
			("idle and asking nothing after no pulse: %s; a pulse of (%.2f, %.2f) for %.2f s asks %s for "
			+ "%.2f s, and the node runs: %s; after it: %s, and the node is idle: %s")
			% [idle_before, PULSE_WEAK, PULSE_STRONG, PULSE_TIME, asked, asked_for, running, after,
			idle_after])


## A pulse equal to one that runs, started later, asks the controller again for the whole of its
## time, so presses every FAST_PRESS_FRAMES frames with a tick longer than that keep the controller
## vibrating from the first press until the last tick ends: MARKER, written straight to the
## controller before each press, gives way to the tick's motors and time at every press. The game's
## own tick for a press to break free, at ten presses a second, ends before each next press: the
## controller is told to stop between them.
func _equal_pulses_ask_again_and_ticks_ten_a_second_stay_apart() -> bool:
	var rumble: ControllerRumble = _new_rumble()
	await process_frame
	_press_on(PAD)
	var tick: RumblePulse = RumblePulse.new(TICK_WEAK, 0.0, TICK_TIME)
	var asked_again: bool = true
	var stopped_between: bool = false
	for press: int in FAST_PRESSES:
		Input.start_joy_vibration(PAD, MARKER.x, MARKER.y, MARKER_TIME)
		rumble.play(tick)
		asked_again = (asked_again and _asked_of(PAD).is_equal_approx(Vector2(TICK_WEAK, 0.0))
				and is_equal_approx(Input.get_joy_vibration_duration(PAD), TICK_TIME))
		for frame: int in FAST_PRESS_FRAMES:
			await process_frame
			stopped_between = stopped_between or _asked_of(PAD) == Vector2.ZERO
	await _frames(ceili(TICK_TIME * FRAMES_PER_SECOND) + END_MARGIN_FRAMES)
	var stopped_after: bool = _asked_of(PAD) == Vector2.ZERO
	var apart: int = 0
	for press: int in SLOW_PRESSES:
		rumble.play(RUMBLE_STATS.struggle)
		var went_still: bool = false
		for frame: int in TEN_A_SECOND_FRAMES:
			await process_frame
			went_still = went_still or _asked_of(PAD) == Vector2.ZERO
		if went_still:
			apart += 1
	rumble.queue_free()
	await process_frame
	return report(asked_again and not stopped_between and stopped_after and apart == SLOW_PRESSES,
			("%d presses every %d frames, each asking again for %.2f s: %s; the controller stopped between "
			+ "them: %s, and after the last tick: %s; the game's tick ten times a second went still "
			+ "before %d of %d presses")
			% [FAST_PRESSES, FAST_PRESS_FRAMES, TICK_TIME, asked_again, stopped_between, stopped_after,
			apart, SLOW_PRESSES])


## The controller is asked again only when what the pulses give changes. With a short pulse on the
## weak motor and a long one on the strong motor running, MARKER written straight to the controller
## stays there for frames in which neither ends; once the short one ends, the node asks for the long
## one's motors in its place.
func _the_controller_is_asked_again_only_when_its_levels_change() -> bool:
	var rumble: ControllerRumble = _new_rumble()
	await process_frame
	_press_on(PAD)
	rumble.play(RumblePulse.new(SHORT_WEAK.x, SHORT_WEAK.y, SHORT_WEAK.z))
	rumble.play(RumblePulse.new(LONG_STRONG.x, LONG_STRONG.y, LONG_STRONG.z))
	var both: Vector2 = _asked_of(PAD)
	Input.start_joy_vibration(PAD, MARKER.x, MARKER.y, MARKER_TIME)
	await _frames(FAST_PRESS_FRAMES)
	var marker_kept: bool = _asked_of(PAD).is_equal_approx(MARKER)
	await _frames(ceili(SHORT_WEAK.z * FRAMES_PER_SECOND) + END_MARGIN_FRAMES)
	var after_short: Vector2 = _asked_of(PAD)
	rumble.queue_free()
	await process_frame
	var long_alone: Vector2 = Vector2(LONG_STRONG.x, LONG_STRONG.y)
	return report(both.is_equal_approx(Vector2(SHORT_WEAK.x, LONG_STRONG.y)) and marker_kept
			and after_short.is_equal_approx(long_alone),
			("both pulses ask %s; the marker stays while neither ends: %s; once the short one ends, the "
			+ "node asks %s (%s)") % [both, marker_kept, after_short, long_alone])


## The Vibration option scales both motors: at a half, the controller is asked for half of each; at
## 0 it is never asked to vibrate.
func _the_option_scales_the_vibration_and_at_zero_asks_for_none() -> bool:
	var settings: GameSettings = root.get_node_or_null(^"Settings") as GameSettings
	if settings == null:
		return report(false, "the autoload Settings is missing")
	var rumble: ControllerRumble = _new_rumble()
	await process_frame
	_press_on(PAD)
	settings.set_vibration(HALF)
	rumble.play(_pulse())
	var at_half: Vector2 = _asked_of(PAD)
	rumble.stop()
	settings.set_vibration(0.0)
	rumble.play(_pulse())
	var at_zero: Vector2 = _asked_of(PAD)
	var at_zero_for: float = Input.get_joy_vibration_duration(PAD)
	settings.set_vibration(GameSettings.DEFAULT_VIBRATION)
	rumble.queue_free()
	await process_frame
	var half_pulse: Vector2 = Vector2(PULSE_WEAK, PULSE_STRONG) * HALF
	return report(at_half.is_equal_approx(half_pulse) and at_zero == Vector2.ZERO and at_zero_for == 0.0,
			"at %.1f the controller is asked for %s (%s); at 0, for %s over %.2f s (none)"
			% [HALF, at_half, half_pulse, at_zero, at_zero_for])


## A pause, leaving the window and leaving the level each stop the controller at once and drop the
## running pulses: after the pause it stays still, and the node does not run. While the window is out
## of focus a pulse starts nothing; back in focus, neither the pulse that was running as it left nor
## the one played meanwhile comes back, and new pulses vibrate again.
func _a_pause_leaving_the_window_or_the_level_stops_it() -> bool:
	var rumble: ControllerRumble = _new_rumble()
	await process_frame
	_press_on(PAD)
	rumble.play(_pulse())
	var before_pause: Vector2 = _asked_of(PAD)
	paused = true
	await process_frame
	var in_pause: Vector2 = _asked_of(PAD)
	paused = false
	await process_frame
	var after_pause: Vector2 = _asked_of(PAD)
	var idle_after_pause: bool = not rumble.is_processing()
	rumble.play(_pulse())
	rumble.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	var after_focus_out: Vector2 = _asked_of(PAD)
	rumble.play(_pulse())
	var out_of_focus: Vector2 = _asked_of(PAD)
	rumble.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	var back_in_focus: Vector2 = _asked_of(PAD)
	rumble.play(_pulse())
	var before_leaving: Vector2 = _asked_of(PAD)
	root.remove_child(rumble)
	var after_leaving: Vector2 = _asked_of(PAD)
	rumble.queue_free()
	await process_frame
	return report(before_pause != Vector2.ZERO and in_pause == Vector2.ZERO and after_pause == Vector2.ZERO
			and idle_after_pause and after_focus_out == Vector2.ZERO and out_of_focus == Vector2.ZERO
			and back_in_focus == Vector2.ZERO and before_leaving != Vector2.ZERO
			and after_leaving == Vector2.ZERO,
			("before the pause %s, in it %s, after it %s, with the node idle: %s; leaving the window: %s, "
			+ "and a pulse out of focus asks %s; back in focus %s, and a new pulse, before leaving the "
			+ "level %s, after %s") % [before_pause, in_pause, after_pause, idle_after_pause,
			after_focus_out, out_of_focus, back_in_focus, before_leaving, after_leaving])


## A sustained vibration asks the controller in use at once, at the share its progress gives, for
## SUSTAIN_REQUEST_TIME; called again at its worst, it asks for all of it. With nothing changed, the
## next frame asks nothing, but before the request runs out the node asks again, so the controller
## never stops while the state lasts. Ended, the controller is told to stop and the node goes idle.
func _a_sustained_vibration_is_asked_for_and_renewed_until_it_ends() -> bool:
	var rumble: ControllerRumble = _new_rumble()
	await process_frame
	_press_on(PAD)
	var held: RumbleSustain = RumbleSustain.new(HELD_WEAK, HELD_STRONG, HALF)
	var full: Vector2 = Vector2(HELD_WEAK, HELD_STRONG)
	rumble.sustain(&"held", held)
	var at_start: Vector2 = _asked_of(PAD)
	var asked_for: float = Input.get_joy_vibration_duration(PAD)
	rumble.sustain(&"held", held, 1.0)
	var at_worst: Vector2 = _asked_of(PAD)
	Input.start_joy_vibration(PAD, MARKER.x, MARKER.y, MARKER_TIME)
	await process_frame
	var next_frame: Vector2 = _asked_of(PAD)
	await _frames(RENEW_FRAMES)
	var renewed: Vector2 = _asked_of(PAD)
	var running: bool = rumble.is_processing()
	rumble.end_sustain(&"held")
	var ended: Vector2 = _asked_of(PAD)
	await process_frame
	var idle: bool = not rumble.is_processing()
	rumble.queue_free()
	await process_frame
	return report(at_start.is_equal_approx(full * HALF)
			and is_equal_approx(asked_for, ControllerRumble.SUSTAIN_REQUEST_TIME)
			and at_worst.is_equal_approx(full) and next_frame.is_equal_approx(MARKER)
			and renewed.is_equal_approx(full) and running and ended == Vector2.ZERO and idle,
			("%s at a half share: asked %s (%s) for %.2f s (%.2f); at its worst %s (%s); a frame later, "
			+ "the marker %s is left alone: %s; %d frames later, asked again: %s, still running: %s; "
			+ "ended: %s, then idle: %s") % [full, at_start, full * HALF, asked_for,
			ControllerRumble.SUSTAIN_REQUEST_TIME, at_worst, full, MARKER, next_frame, RENEW_FRAMES,
			renewed, running, ended, idle])


## With Constant Vibration off, a sustained vibration asks nothing, while a pulse over it still asks
## for its own levels alone; on again, the sustained vibration is back on its next request.
func _the_constant_option_leaves_sustained_vibrations_out() -> bool:
	var settings: GameSettings = root.get_node_or_null(^"Settings") as GameSettings
	if settings == null:
		return report(false, "the autoload Settings is missing")
	var rumble: ControllerRumble = _new_rumble()
	await process_frame
	_press_on(PAD)
	var held: RumbleSustain = RumbleSustain.new(HELD_WEAK, HELD_STRONG)
	settings.set_constant_vibration(false)
	rumble.sustain(&"held", held)
	var held_off: Vector2 = _asked_of(PAD)
	rumble.play(_pulse())
	var pulse_off: Vector2 = _asked_of(PAD)
	rumble.stop()
	settings.set_constant_vibration(true)
	rumble.sustain(&"held", held)
	var held_on: Vector2 = _asked_of(PAD)
	settings.set_constant_vibration(GameSettings.DEFAULT_CONSTANT_VIBRATION)
	rumble.queue_free()
	await process_frame
	return report(held_off == Vector2.ZERO
			and pulse_off.is_equal_approx(Vector2(PULSE_WEAK, PULSE_STRONG))
			and held_on.is_equal_approx(Vector2(HELD_WEAK, HELD_STRONG)),
			("with the option off, a sustained vibration asks %s (none) and a pulse over it %s (%s); "
			+ "on again, the sustained vibration asks %s (%s)") % [held_off, pulse_off,
			Vector2(PULSE_WEAK, PULSE_STRONG), held_on, Vector2(HELD_WEAK, HELD_STRONG)])


## A pause and leaving the window stop the controller at once and drop the pulses, but a sustained
## vibration waits: once the game goes on, it vibrates again, and so it does once the window is back
## in focus, even after its state changed meanwhile. Leaving the level ends it.
func _a_pause_or_leaving_the_window_keeps_a_sustained_vibration_for_later() -> bool:
	var rumble: ControllerRumble = _new_rumble()
	await process_frame
	_press_on(PAD)
	var held: RumbleSustain = RumbleSustain.new(HELD_WEAK, HELD_STRONG, HALF)
	var full: Vector2 = Vector2(HELD_WEAK, HELD_STRONG)
	rumble.sustain(&"held", held, 1.0)
	rumble.play(_pulse())
	paused = true
	await process_frame
	var in_pause: Vector2 = _asked_of(PAD)
	paused = false
	await process_frame
	var after_pause: Vector2 = _asked_of(PAD)
	rumble.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	var out_of_focus: Vector2 = _asked_of(PAD)
	rumble.sustain(&"held", held)
	var changed_out_of_focus: Vector2 = _asked_of(PAD)
	rumble.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	var back_in_focus: Vector2 = _asked_of(PAD)
	root.remove_child(rumble)
	var after_leaving: Vector2 = _asked_of(PAD)
	rumble.queue_free()
	await process_frame
	return report(in_pause == Vector2.ZERO and after_pause.is_equal_approx(full)
			and out_of_focus == Vector2.ZERO and changed_out_of_focus == Vector2.ZERO
			and back_in_focus.is_equal_approx(full * HALF) and after_leaving == Vector2.ZERO,
			("held at %s under a pulse: in the pause %s, after it %s (%s, the pulse dropped); out of "
			+ "focus %s, and %s after its state changed; back in focus %s (%s); after leaving the "
			+ "level %s") % [full, in_pause, after_pause, full, out_of_focus, changed_out_of_focus,
			back_in_focus, full * HALF, after_leaving])


func _the_option_is_one_by_default_kept_in_range_and_saved() -> bool:
	_delete_test_file()
	var settings: GameSettings = await _new_settings()
	var with_no_file: float = settings.get_vibration()
	settings.set_vibration(2.0)
	var above: float = settings.get_vibration()
	settings.set_vibration(-1.0)
	var below: float = settings.get_vibration()
	settings.set_vibration(NAN)
	var not_a_number: float = settings.get_vibration()
	settings.set_vibration(0.3)
	var shake_alone: bool = settings.get_screen_shake() == GameSettings.DEFAULT_SCREEN_SHAKE
	settings.queue_free()
	var again: GameSettings = await _new_settings()
	var read_back: float = again.get_vibration()
	again.reset_to_defaults()
	var after_reset: float = again.get_vibration()
	again.queue_free()
	await process_frame
	var default_vibration: float = GameSettings.DEFAULT_VIBRATION
	return report(with_no_file == default_vibration and above == 1.0 and below == 0.0
			and not_a_number == default_vibration and shake_alone and is_equal_approx(read_back, 0.3)
			and after_reset == default_vibration,
			("with no file %.2f (%.2f); 2 gives %.2f, -1 gives %.2f, nan gives %.2f; the screen shake stays "
			+ "as it was: %s; 0.3 is read back as %.2f; Reset gives %.2f")
			% [with_no_file, default_vibration, above, below, not_a_number, shake_alone, read_back,
			after_reset])


## A file written by hand with a word, nan, inf, a number above 1 or one below 0 for both the screen
## shake and the vibration: each strength takes its default for the word, nan and inf, and the
## nearest limit for the numbers out of range.
func _a_file_with_wrong_values_gives_the_default_or_the_nearest_limit() -> bool:
	# What the file says, whether each strength must take its default, and otherwise the limit.
	var cases: Array[Array] = [
		["\"loud\"", true, 0.0],
		["nan", true, 0.0],
		["inf", true, 0.0],
		["3", false, 1.0],
		["-1", false, 0.0],
	]
	var wrong: Array[String] = []
	for case: Array in cases:
		_write_test_file(case[0])
		var settings: GameSettings = await _new_settings()
		var shake_wanted: float = GameSettings.DEFAULT_SCREEN_SHAKE if case[1] else float(case[2])
		var vibration_wanted: float = GameSettings.DEFAULT_VIBRATION if case[1] else float(case[2])
		if settings.get_screen_shake() != shake_wanted or settings.get_vibration() != vibration_wanted:
			wrong.append("%s gives %.2f and %.2f (%.2f and %.2f)" % [case[0], settings.get_screen_shake(),
					settings.get_vibration(), shake_wanted, vibration_wanted])
		settings.queue_free()
		await process_frame
	_delete_test_file()
	return report(wrong.is_empty(),
			"a file with a word, nan, inf, 3 or -1 for both strengths; wrong: %s" % [wrong])


## Constant Vibration is on with no file; turned off, it is saved and read back off, apart from the
## Vibration option; Reset turns it back on; a file with a word or a number for it gives the default.
func _the_constant_option_is_on_by_default_saved_and_read_back() -> bool:
	_delete_test_file()
	var settings: GameSettings = await _new_settings()
	var with_no_file: bool = settings.is_constant_vibration_on()
	settings.set_constant_vibration(false)
	var vibration_alone: bool = settings.get_vibration() == GameSettings.DEFAULT_VIBRATION
	settings.queue_free()
	var again: GameSettings = await _new_settings()
	var read_back: bool = again.is_constant_vibration_on()
	again.reset_to_defaults()
	var after_reset: bool = again.is_constant_vibration_on()
	again.queue_free()
	await process_frame
	var wrong_values: Array[String] = []
	for value: String in ["\"no\"", "0"]:
		var file: FileAccess = FileAccess.open(TEST_PATH, FileAccess.WRITE)
		file.store_string("[accessibility]\n\nconstant_vibration=%s\n" % value)
		file.close()
		var from_file: GameSettings = await _new_settings()
		if from_file.is_constant_vibration_on() != GameSettings.DEFAULT_CONSTANT_VIBRATION:
			wrong_values.append(value)
		from_file.queue_free()
		await process_frame
	_delete_test_file()
	var default_on: bool = GameSettings.DEFAULT_CONSTANT_VIBRATION
	return report(with_no_file == default_on and vibration_alone and not read_back
			and after_reset == default_on and wrong_values.is_empty(),
			("with no file %s (%s); turned off, the Vibration option stays as it was: %s; read back: %s "
			+ "(false); after Reset: %s; values in the file that did not give the default: %s")
			% [with_no_file, default_on, vibration_alone, read_back, after_reset, wrong_values])


## The options screen on its own, opened with Vibration at 0.3: its slider is the accessibility
## grid's second, under the screen shake's, with its title before it; it goes from 0 to 1 in steps of
## the screen's own step and shows 0.3 and "30 %"; moving it to 0.6 hands 0.6 to Settings, shows
## "60 %" and leaves the screen shake alone; Reset brings back the default on both.
func _the_options_screen_shows_and_changes_the_option() -> bool:
	var settings: GameSettings = root.get_node_or_null(^"Settings") as GameSettings
	if settings == null:
		return report(false, "the autoload Settings is missing")
	settings.set_vibration(0.3)
	var options: OptionsMenu = OPTIONS_SCENE.instantiate() as OptionsMenu
	root.add_child(options)
	options.open()
	var sliders: Array[HSlider] = _accessibility_sliders(options)
	var passed: bool = sliders.size() == 2
	var what: String = "the accessibility grid has %d sliders (2)" % sliders.size()
	if passed:
		var slider: HSlider = sliders[1]
		var titled: bool = _text_before(slider) == OptionsMenu.VIBRATION_TITLE
		var steps_right: bool = (slider.min_value == 0.0 and slider.max_value == 1.0
				and is_equal_approx(slider.step, OptionsMenu.VIBRATION_STEP))
		var shown: bool = is_equal_approx(slider.value, 0.3) and _text_after(slider) == "30 %"
		slider.value = 0.6
		var changed: bool = (is_equal_approx(settings.get_vibration(), 0.6) and _text_after(slider) == "60 %"
				and settings.get_screen_shake() == GameSettings.DEFAULT_SCREEN_SHAKE)
		(options.get_node(^"%ResetButton") as Button).pressed.emit()
		var default_vibration: float = GameSettings.DEFAULT_VIBRATION
		var reset: bool = (is_equal_approx(settings.get_vibration(), default_vibration)
				and is_equal_approx(slider.value, default_vibration)
				and _text_after(slider) == "%d %%" % roundi(default_vibration * 100.0))
		passed = titled and steps_right and shown and changed and reset
		what = ("the second slider is titled %s: %s; it goes from 0 to 1 in steps of %.2f: %s; it shows "
				+ "0.3 as 30 %%: %s; moved to 0.6, it hands 0.6 to Settings, shows 60 %% and leaves the "
				+ "screen shake alone: %s; Reset brings back the default on both: %s") % [
				OptionsMenu.VIBRATION_TITLE, titled, OptionsMenu.VIBRATION_STEP, steps_right, shown,
				changed, reset]
	options.queue_free()
	settings.set_vibration(GameSettings.DEFAULT_VIBRATION)
	await process_frame
	return report(passed, what)


## The options screen on its own, opened with Constant Vibration off: the accessibility grid's switch
## sits under the Vibration slider, with its title before it, and shows the option off; pressed, it
## hands the option on to Settings. With PAD in use, moving the Vibration slider as a controller does
## plays a hit's pulse at the new strength on PAD at once. The mouse then drags it, with real mouse
## events, which also take the game off the controller: nothing plays while it drags, and as the drag
## ends the pulse plays once on PAD, the controller used last, at the strength it ended on.
func _the_options_screen_switches_constant_vibration_and_plays_a_sample() -> bool:
	var settings: GameSettings = root.get_node_or_null(^"Settings") as GameSettings
	if settings == null:
		return report(false, "the autoload Settings is missing")
	settings.set_constant_vibration(false)
	Input.stop_joy_vibration(PAD)
	var options: OptionsMenu = OPTIONS_SCENE.instantiate() as OptionsMenu
	root.add_child(options)
	options.open()
	await process_frame
	var toggle: CheckButton = _accessibility_switch(options)
	var sliders: Array[HSlider] = _accessibility_sliders(options)
	var passed: bool = toggle != null and sliders.size() == 2
	var what: String = ("the accessibility grid has a switch: %s, and %d sliders (2)"
			% [toggle != null, sliders.size()])
	if passed:
		var slider: HSlider = sliders[1]
		var under_the_slider: bool = toggle.get_index() > slider.get_index()
		var titled: bool = _text_before(toggle) == OptionsMenu.CONSTANT_VIBRATION_TITLE
		var shown_off: bool = not toggle.button_pressed
		toggle.button_pressed = true
		var handed_on: bool = settings.is_constant_vibration_on()
		_press_on(PAD)
		slider.value = SAMPLE_STEPPED
		var stepped: Vector2 = _asked_of(PAD)
		Input.start_joy_vibration(PAD, MARKER.x, MARKER.y, MARKER_TIME)
		_mouse_press_on(slider, SAMPLE_STEPPED)
		_mouse_drag_to(slider, SAMPLE_DRAGGED)
		var while_dragging: Vector2 = _asked_of(PAD)
		var dragged_to: float = slider.value
		_mouse_release_on(slider, SAMPLE_DRAGGED)
		var dragged: Vector2 = _asked_of(PAD)
		var hit_pulse: RumblePulse = RUMBLE_STATS.hit
		var hit: Vector2 = Vector2(hit_pulse.weak, hit_pulse.strong)
		passed = (under_the_slider and titled and shown_off and handed_on
				and stepped.is_equal_approx(hit * SAMPLE_STEPPED)
				and is_equal_approx(dragged_to, SAMPLE_DRAGGED) and while_dragging.is_equal_approx(MARKER)
				and dragged.is_equal_approx(hit * SAMPLE_DRAGGED))
		what = ("the switch is under the slider: %s, titled %s: %s, shown off: %s; pressed, Settings has "
				+ "it on: %s; the slider moved to %.1f asks %s (%s); the mouse drags it to %.2f (%.1f), "
				+ "leaving the marker %s alone: %s; as the drag ends, %s (%s)") % [under_the_slider,
				OptionsMenu.CONSTANT_VIBRATION_TITLE, titled, shown_off, handed_on, SAMPLE_STEPPED,
				stepped, hit * SAMPLE_STEPPED, dragged_to, SAMPLE_DRAGGED, MARKER, while_dragging,
				dragged, hit * SAMPLE_DRAGGED]
	options.queue_free()
	settings.set_vibration(GameSettings.DEFAULT_VIBRATION)
	settings.set_constant_vibration(GameSettings.DEFAULT_CONSTANT_VIBRATION)
	Input.stop_joy_vibration(PAD)
	await process_frame
	return report(passed, what)


## The options screen closed while the mouse drags the Vibration slider, as Esc or B can do, and the
## button let go once it is closed: when it opens again, a move of the slider with the controller
## plays the sample at once, as before the drag.
func _the_options_closed_mid_drag_still_play_the_sample() -> bool:
	var settings: GameSettings = root.get_node_or_null(^"Settings") as GameSettings
	if settings == null:
		return report(false, "the autoload Settings is missing")
	var options: OptionsMenu = OPTIONS_SCENE.instantiate() as OptionsMenu
	root.add_child(options)
	options.open()
	await process_frame
	var sliders: Array[HSlider] = _accessibility_sliders(options)
	var passed: bool = sliders.size() == 2
	var what: String = "the accessibility grid has %d sliders (2)" % sliders.size()
	if passed:
		var slider: HSlider = sliders[1]
		_press_on(PAD)
		var start: float = slider.value
		_mouse_press_on(slider, start)
		(options.get_node(^"%BackButton") as Button).pressed.emit()
		_mouse_release_on(slider, start)
		options.open()
		await process_frame
		_press_on(PAD)
		Input.stop_joy_vibration(PAD)
		slider.value = SAMPLE_STEPPED
		var stepped: Vector2 = _asked_of(PAD)
		var hit_pulse: RumblePulse = RUMBLE_STATS.hit
		var hit: Vector2 = Vector2(hit_pulse.weak, hit_pulse.strong)
		passed = stepped.is_equal_approx(hit * SAMPLE_STEPPED)
		what = ("closed mid-drag and opened again, the slider moved to %.1f asks %s (%s)"
				% [SAMPLE_STEPPED, stepped, hit * SAMPLE_STEPPED])
	options.queue_free()
	settings.set_vibration(GameSettings.DEFAULT_VIBRATION)
	Input.stop_joy_vibration(PAD)
	await process_frame
	return report(passed, what)


## Both motors' levels, the weak one in x and the strong one in y.
func _levels(rules: RumbleRules) -> Vector2:
	return rules.get_levels()


## A ControllerRumble of its own, in the tree, with both of the cases' controllers at rest and the
## keyboard in use: the controller in use is kept from one node to the next, as from one level to the
## next, so a key makes each case start from none.
func _new_rumble() -> ControllerRumble:
	Input.stop_joy_vibration(PAD)
	Input.stop_joy_vibration(OTHER_PAD)
	var rumble: ControllerRumble = ControllerRumble.new()
	root.add_child(rumble)
	_press_key()
	return rumble


func _pulse() -> RumblePulse:
	return RumblePulse.new(PULSE_WEAK, PULSE_STRONG, PULSE_TIME)


## What device is asked to vibrate with now, the weak motor in x and the strong one in y.
func _asked_of(device: int) -> Vector2:
	return Input.get_joy_vibration_strength(device)


## Makes device the controller in use, as a press of a button no action uses does.
func _press_on(device: int) -> void:
	var press: InputEventJoypadButton = InputEventJoypadButton.new()
	press.device = device
	press.button_index = SPARE_BUTTON
	press.pressed = true
	root.push_input(press)


## Moves a stick of device by amount, out of 1.
func _move_stick_on(device: int, amount: float) -> void:
	var motion: InputEventJoypadMotion = InputEventJoypadMotion.new()
	motion.device = device
	motion.axis = JOY_AXIS_RIGHT_X
	motion.axis_value = amount
	root.push_input(motion)


## Presses a key no action uses.
func _press_key() -> void:
	var key: InputEventKey = InputEventKey.new()
	key.physical_keycode = SPARE_KEY
	key.keycode = SPARE_KEY
	key.pressed = true
	root.push_input(key)


## Presses a mouse button no action uses.
func _press_mouse_button() -> void:
	var click: InputEventMouseButton = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_XBUTTON2
	click.pressed = true
	root.push_input(click)


## Presses the left mouse button on slider where its value is ratio, as a person grabbing it does.
func _mouse_press_on(slider: HSlider, ratio: float) -> void:
	var click: InputEventMouseButton = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.button_mask = MOUSE_BUTTON_MASK_LEFT
	click.pressed = true
	click.position = _point_on(slider, ratio)
	click.global_position = click.position
	root.push_input(click, true)


## Moves the mouse, its left button held, to where slider's value is ratio.
func _mouse_drag_to(slider: HSlider, ratio: float) -> void:
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	motion.position = _point_on(slider, ratio)
	motion.global_position = motion.position
	root.push_input(motion, true)


## Lets the left mouse button go where slider's value is ratio.
func _mouse_release_on(slider: HSlider, ratio: float) -> void:
	var release: InputEventMouseButton = InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = _point_on(slider, ratio)
	release.global_position = release.position
	root.push_input(release, true)


## Where slider's value is ratio, out of its range of 0 to 1, halfway down it: the grabber's middle
## travels the slider's width less the grabber's own.
func _point_on(slider: HSlider, ratio: float) -> Vector2:
	var grabber_width: float = slider.get_theme_icon(&"grabber").get_width()
	var area: Rect2 = slider.get_global_rect()
	return area.position + Vector2(grabber_width / 2.0 + ratio * (area.size.x - grabber_width),
			area.size.y / 2.0)


func _frames(count: int) -> void:
	for frame: int in count:
		await process_frame


func _accessibility_sliders(options: OptionsMenu) -> Array[HSlider]:
	var sliders: Array[HSlider] = []
	var grid: Node = options.get_node_or_null(^"%Accessibility")
	if grid != null:
		for child: Node in grid.get_children():
			if child is HSlider:
				sliders.append(child as HSlider)
	return sliders


## The accessibility grid's switch, or null.
func _accessibility_switch(options: OptionsMenu) -> CheckButton:
	var grid: Node = options.get_node_or_null(^"%Accessibility")
	if grid != null:
		for child: Node in grid.get_children():
			if child is CheckButton:
				return child as CheckButton
	return null


## The text of the label before control in its grid.
func _text_before(control: Control) -> String:
	var before: int = control.get_index() - 1
	if before < 0:
		return ""
	var label: Node = control.get_parent().get_child(before)
	return (label as Label).text if label is Label else ""


## The text of the label after slider in its grid.
func _text_after(slider: HSlider) -> String:
	var next: int = slider.get_index() + 1
	if next >= slider.get_parent().get_child_count():
		return ""
	var label: Node = slider.get_parent().get_child(next)
	return (label as Label).text if label is Label else ""


func _new_settings() -> GameSettings:
	var settings: GameSettings = SETTINGS_SCRIPT.new() as GameSettings
	settings.path = TEST_PATH
	root.add_child(settings)
	await process_frame
	return settings


## Writes the test's settings file with value for both strengths, as a person might by hand.
func _write_test_file(value: String) -> void:
	var file: FileAccess = FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string("[accessibility]\n\nscreen_shake=%s\nvibration=%s\n" % [value, value])
	file.close()


func _delete_test_file() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
