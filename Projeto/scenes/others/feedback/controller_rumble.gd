class_name ControllerRumble
extends Node

## Makes the player's controller vibrate: for a moment, with play(), and while a state lasts, with
## sustain() until end_sustain(). The rules are in RumbleRules, which keeps each motor at the
## strongest running pulse and lets a pulse read over a sustained vibration. Only the controller used
## last vibrates, and none while the last input came from the keyboard or the mouse, so a controller
## left on the desk stays still; with Keeps Last Controller on, as for the options screen's sample,
## the controller used last vibrates even then. The controller in use is kept from one level to the
## next, as after a death or at the next phase, so it vibrates before any new input. Each node moves
## its own vibration when the controller in use changes, whichever node sees the input first, so the
## level's node and the options screens' samples can share the tree. The Vibration option of the
## autoload Settings scales everything, and at 0 the controller is never asked to vibrate; the
## Constant Vibration option leaves the sustained vibrations out. A pause and leaving the window stop
## the controller at once and drop the pulses that were running, while the sustained vibrations wait
## and go on once the game does, as their states do; with the window out of focus no pulse starts.
## Leaving the level stops everything. _process() only runs while something vibrates; _input() looks
## at every input event for the controller in use.

## Where the autoload Settings is in the tree. Looked up there instead of named in the code, as the
## options screen does, so this script compiles before the autoloads exist.
const SETTINGS_PATH: NodePath = ^"/root/Settings"
## No controller in use: the last input came from the keyboard or the mouse, or there was none yet.
const NO_DEVICE: int = -1
## How far a stick must move for its controller to count as the one in use: some sticks rest a
## little off centre, and that must not take the vibration away from the keyboard.
const STICK_IN_USE: float = 0.5
## How long each request lasts while a vibration is sustained, in s: the node asks again before it
## runs out, and if the game stops running, the motors stop on their own soon after.
const SUSTAIN_REQUEST_TIME: float = 0.25
## How long before a sustained vibration's request runs out the node asks again, in s.
const RENEW_BEFORE: float = 0.1

## The share of its level a sustained vibration keeps on the motors a pulse runs, while that pulse
## runs at all of its own, so the pulse reads over it (RumbleRules).
@export_range(0.0, 1.0, 0.05) var sustain_duck_share: float = 0.3:
	set(value):
		sustain_duck_share = value
		_rules.duck_share = value
## On, the node vibrates the controller used last even while the keyboard or the mouse is in use, as
## the options screen's sample does: the player may set the strength with the mouse and feel it on
## the controller in their hands. Off, as in the game, it vibrates none while they are in use.
@export var keeps_last_controller: bool = false

## The controller in use, or NO_DEVICE. Shared by every instance, so the next level's starts with it.
static var _device: int = NO_DEVICE
## The controller used last, kept while the keyboard or the mouse is in use; NO_DEVICE before any is
## used, or once it is unplugged. Shared by every instance too.
static var _last_controller: int = NO_DEVICE

var _rules: RumbleRules = RumbleRules.new()
var _settings: GameSettings
## The controller this node last asked to vibrate, or NO_DEVICE: once another is the one to vibrate,
## the node stops this one and moves its vibration there.
var _asked_device: int = NO_DEVICE
## What _asked_device was last asked for, the weak motor in x and the strong one in y, so it is
## asked again only when that changes, a pulse starts or a sustained vibration's request runs out.
var _asked: Vector2 = Vector2.ZERO
## How long the last request to the controller has left, in s.
var _request_left: float = 0.0
## False while the game's window is out of focus: then no pulse starts and nothing vibrates.
var _window_focused: bool = true
## True while the game is paused: nothing vibrates until it goes on.
var _paused: bool = false


func _ready() -> void:
	_settings = get_node_or_null(SETTINGS_PATH) as GameSettings
	if _settings == null:
		push_warning("ControllerRumble: no Settings at %s, so the vibration ignores the Vibration option."
				% SETTINGS_PATH)
	_rules.duck_share = sustain_duck_share
	_paused = not can_process()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	set_process(false)


## Sees every input before anything uses it, for which controller, if any, is in use. It leaves the
## input to the rest of the game.
func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion
			and absf((event as InputEventJoypadMotion).axis_value) >= STICK_IN_USE):
		_use_device(event.device)
	elif (event is InputEventKey or event is InputEventMouseButton) and event.is_pressed():
		_use_device(NO_DEVICE)


func _process(delta: float) -> void:
	_rules.advance(delta)
	_request_left -= delta
	_ask_controller(_rules.is_sustaining() and _request_left <= RENEW_BEFORE)
	if not _rules.is_running():
		set_process(false)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			_window_focused = false
			_rules.clear_pulses()
			_ask_controller()
		NOTIFICATION_APPLICATION_FOCUS_IN:
			_window_focused = true
			_resume()
		NOTIFICATION_PAUSED:
			_paused = true
			_rules.clear_pulses()
			_ask_controller()
		NOTIFICATION_UNPAUSED:
			_paused = false
			_resume()
		NOTIFICATION_EXIT_TREE:
			stop()


## Starts pulse on the controller this node vibrates, with both motors scaled by scale, as a rock
## that breaks farther away asks. No pulse, or a window out of focus, starts nothing.
func play(pulse: RumblePulse, scale: float = 1.0) -> void:
	if pulse == null or not _window_focused:
		return
	_rules.add(pulse.weak * scale, pulse.strong * scale, pulse.duration, pulse.fade)
	_ask_controller(true)
	set_process(_rules.is_running())


## Holds sustained's vibration for key while its state lasts, until end_sustain(key), at the share
## progress gives it: from 0 as the state begins to 1 at its worst (RumbleSustain.share_at()). Called
## again for the same key, as the state changes, it changes the level and keeps the throb where it
## was. No sustained vibration ends key's.
func sustain(key: StringName, sustained: RumbleSustain, progress: float = 0.0) -> void:
	if sustained == null:
		end_sustain(key)
		return
	var share: float = sustained.share_at(progress)
	_rules.sustain(key, sustained.weak * share, sustained.strong * share, sustained.beat_rate,
			sustained.beat_depth)
	_ask_controller()
	set_process(_rules.is_running())


## Ends key's sustained vibration, as its state ends; nothing happens if key holds none.
func end_sustain(key: StringName) -> void:
	_rules.end_sustain(key)
	_ask_controller()
	set_process(_rules.is_running())


## Stops the controller this node vibrates now and drops the pulses and the sustained vibrations.
func stop() -> void:
	_rules.clear()
	_ask_controller()
	set_process(false)


## The controller in use, or NO_DEVICE.
func get_device() -> int:
	return _device


## Another controller is in use, or none. Every node sees the same input, in its own turn, and moves
## its own vibration: the controller it was vibrating stops, and its pulses and sustained vibrations
## go on, on the one it vibrates now.
func _use_device(device: int) -> void:
	_device = device
	if device != NO_DEVICE:
		_last_controller = device
	if _target_device() != _asked_device:
		_ask_controller()


## The controller this node vibrates: the one in use or, with Keeps Last Controller, the one used
## last; NO_DEVICE for none.
func _target_device() -> int:
	return _last_controller if keeps_last_controller else _device


## After a pause or with the window back in focus: the sustained vibrations go on.
func _resume() -> void:
	_ask_controller(true)
	set_process(_rules.is_running())


## Asks the controller this node vibrates for what the running pulses and the sustained vibrations
## give now, scaled by the Vibration option, without the sustained ones while Constant Vibration is
## off, and for nothing while the game is paused or out of focus. If that is another controller than
## the one it last asked, that one stops first. The request lasts as long as the last pulse has left,
## or SUSTAIN_REQUEST_TIME while a vibration is sustained, so the motors stop on their own even if the
## game stops running. It asks when that changes and, with renew, also when it stays the same: a
## pulse that has just started may end later than the controller was told, and a sustained
## vibration's request must not run out. It never asks for nothing twice.
func _ask_controller(renew: bool = false) -> void:
	var device: int = _target_device()
	if device != _asked_device:
		_silence()
		_asked_device = device
	if device == NO_DEVICE:
		return
	var with_sustains: bool = _settings == null or _settings.is_constant_vibration_on()
	var wanted: Vector2 = Vector2.ZERO
	if _window_focused and not _paused:
		var strength: float = _settings.get_vibration() if _settings != null else 1.0
		wanted = _rules.get_levels(with_sustains) * clampf(strength, 0.0, 1.0)
	if wanted == _asked and (not renew or wanted == Vector2.ZERO):
		return
	if wanted == Vector2.ZERO:
		Input.stop_joy_vibration(device)
		_request_left = 0.0
	else:
		_request_left = _rules.get_time_left()
		if with_sustains and _rules.is_sustaining():
			_request_left = maxf(_request_left, SUSTAIN_REQUEST_TIME)
		Input.start_joy_vibration(device, wanted.x, wanted.y, _request_left)
	_asked = wanted


## Stops the controller this node last asked to vibrate, if it did.
func _silence() -> void:
	if _asked_device != NO_DEVICE and _asked != Vector2.ZERO:
		Input.stop_joy_vibration(_asked_device)
	_asked = Vector2.ZERO
	_request_left = 0.0


## A controller that is unplugged is no longer in use, nor the one used last; each node stops it, if
## it was vibrating it.
func _on_joy_connection_changed(device: int, connected: bool) -> void:
	if connected:
		return
	if device == _device:
		_device = NO_DEVICE
	if device == _last_controller:
		_last_controller = NO_DEVICE
	_ask_controller()
