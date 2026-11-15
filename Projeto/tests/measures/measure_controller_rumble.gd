# Prints what the controller's vibration (ADR 0062) costs. A drawn frame while something vibrates:
# ControllerRumble's _process(), which moves the pulses and the sustained vibrations on and asks the
# controller again when what they give changes, called many times in a row with RUNNING_PULSES pulses
# fading over a time too long to end within the calls and RUNNING_SUSTAINS sustained vibrations
# throbbing: their levels change on every frame, so it asks the controller on every frame, the worst
# case. On frames with nothing vibrating, _process() does not run. An input event: _input(),
# which looks at every one for the controller in use, pulses or not, with a stick moved on the
# controller already in use. A moment: a pulse started and stopped again, each a call to the
# controller. Calls made before the measured ones warm the processor's cache up. It checks nothing:
# the exit code is 1 only if the pulses never reached the controller. The README quotes the result
# in the camera's section.
# Run from the repository root:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/measures/measure_controller_rumble.gd
extends "res://tests/support/base_test.gd"

## A controller id that no controller plugged into the computer is likely to have, so no real one
## vibrates.
const PAD: int = 6
## One drawn frame at 60 frames a second, in s.
const FRAME: float = 1.0 / 60.0
## Pulses running at once in the frame measure: more than the moments of the game ever overlap.
const RUNNING_PULSES: int = 3
## Sustained vibrations at once in the frame measure: the grab's and the crucifix's.
const RUNNING_SUSTAINS: int = 2
## How many times a second the measure's sustained vibrations throb, and how deep.
const BEAT_RATE: float = 2.0
const BEAT_DEPTH: float = 0.5
## A pulse time no run of the measure gets to the end of, in s.
const LONG_TIME: float = 1000000.0
## How far the stick of the input measure moves, out of 1: enough to count as the controller in use.
const MOVED_STICK: float = 0.9
## Calls made before the measured ones, so the first calls' setup does not count.
const WARM_UP_CALLS: int = 1000
## Calls in a row in each measure; the result is their average.
const CALLS: int = 100000
## A drawn frame's whole time at 60 frames a second, in µs.
const FRAME_TIME: float = 1000000.0 / 60.0


func _initialize() -> void:
	Input.stop_joy_vibration(PAD)
	var rumble: ControllerRumble = ControllerRumble.new()
	root.add_child(rumble)
	await process_frame
	var press: InputEventJoypadButton = InputEventJoypadButton.new()
	press.device = PAD
	press.button_index = JOY_BUTTON_PADDLE4
	press.pressed = true
	root.push_input(press)
	var frame_cost: float = _frame_cost(rumble)
	var reached: bool = Input.get_joy_vibration_strength(PAD) != Vector2.ZERO
	rumble.stop()
	var input_cost: float = _input_cost(rumble)
	var moment_cost: float = _moment_cost(rumble)
	print(("ControllerRumble._process(): %.2f µs a frame with %d pulses fading and %d sustained "
			+ "vibrations throbbing (%.3f %% of a frame at 60 FPS), not run with nothing vibrating; "
			+ "_input(): %.2f µs an input event; a pulse started and stopped: %.2f µs")
			% [frame_cost, RUNNING_PULSES, RUNNING_SUSTAINS, frame_cost / FRAME_TIME * 100.0,
			input_cost, moment_cost])
	rumble.queue_free()
	await process_frame
	Input.stop_joy_vibration(PAD)
	quit(0 if reached else 1)


## The average cost, in µs, of one frame of rumble's _process() with RUNNING_PULSES pulses fading
## and RUNNING_SUSTAINS sustained vibrations throbbing.
func _frame_cost(rumble: ControllerRumble) -> float:
	for index: int in RUNNING_PULSES:
		rumble.play(RumblePulse.new(0.2 * (index + 1), 0.3, LONG_TIME, 1.0))
	for index: int in RUNNING_SUSTAINS:
		rumble.sustain(StringName("held_%d" % index),
				RumbleSustain.new(0.1 * (index + 1), 0.2, 1.0, BEAT_RATE, BEAT_DEPTH))
	for index: int in WARM_UP_CALLS:
		rumble._process(FRAME)
	var start: int = Time.get_ticks_usec()
	for index: int in CALLS:
		rumble._process(FRAME)
	return float(Time.get_ticks_usec() - start) / CALLS


## The average cost, in µs, of one call of rumble's _input() with a stick moved on the controller
## already in use.
func _input_cost(rumble: ControllerRumble) -> float:
	var motion: InputEventJoypadMotion = InputEventJoypadMotion.new()
	motion.device = PAD
	motion.axis = JOY_AXIS_LEFT_X
	motion.axis_value = MOVED_STICK
	for index: int in WARM_UP_CALLS:
		rumble._input(motion)
	var start: int = Time.get_ticks_usec()
	for index: int in CALLS:
		rumble._input(motion)
	return float(Time.get_ticks_usec() - start) / CALLS


## The average cost, in µs, of a pulse started on the controller in use and stopped again.
func _moment_cost(rumble: ControllerRumble) -> float:
	var pulse: RumblePulse = RumblePulse.new(0.5, 0.5, 0.2)
	for index: int in WARM_UP_CALLS:
		rumble.play(pulse)
		rumble.stop()
	var start: int = Time.get_ticks_usec()
	for index: int in CALLS:
		rumble.play(pulse)
		rumble.stop()
	return float(Time.get_ticks_usec() - start) / CALLS
