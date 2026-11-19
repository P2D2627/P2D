class_name MenuFeedback
extends Node

## What a menu sounds and feels like as the player uses it: a click as the selection moves (arrow
## keys, stick, d-pad or mouse), a heavy blow as an option is chosen, a dull thud as a screen is
## left, and the controller in use answering each with a pulse (through ControllerRumble, so the
## Vibration option scales it and only the controller in use vibrates). It only listens: it never
## handles the input. It sounds while Menu shows; in the main scene the main menu and the pause have
## one each, and only one shows at a time. A selection the game moves itself, as a panel opens,
## makes no sound: a move counts only right after the player's own input. A switch clicks; a slider
## ticks at a pitch that follows its value. With no stream of their own, both are the selection's
## click, the switch's higher. A list (an OptionButton) clicks as a switch as it opens; inside it, a
## move of its selection clicks, an item picked blows, and the list closed with nothing picked
## thuds. A key that remaps an action on the controls screen (ControlsMenu) blows; a key or a gamepad
## button it refuses sounds the refusal, two thuds, so it never sounds as Esc, which stops its wait
## with one. A dialog's buttons sound only through its answer, never as buttons, so No is a thud
## alone. Its scene sets recorded sounds (assets/audio/ui/, made by tools/audio/make_menu_sounds.py,
## with their credits in the README), the click's and the choice's as random sets that never play
## the same one twice in a row; a sound left empty is made in code (MenuSoundSynth), once a run, and
## played with its own mix (MADE_MIX_DB) on top of the scene's volume, as the made sounds all come
## out at one peak.

## A sound was played: &"move", &"switch", &"slider", &"confirm", &"back" or &"refuse".
signal played(sound: StringName)

const Synth := preload("res://scenes/screens/menu_sound_synth.gd")
## How long after the player's input a change of the selection still counts as theirs, in ms.
const INPUT_WINDOW_MS: int = 150
const MOVE_VARIANTS: int = 4
const CONFIRM_VARIANTS: int = 2
const BACK_VARIANTS: int = 2
const NAVIGATION: Array[StringName] = [&"ui_up", &"ui_down", &"ui_left", &"ui_right",
		&"ui_focus_next", &"ui_focus_prev"]
## The audio bus the menus play on, the one the Interface volume sets.
const BUS: StringName = &"UI"
## How many of each sound may ring at once: the clicks overlap in a fast run, a choice may follow a
## choice, and neither the way back nor the refusal ever stacks.
const MOVE_POLYPHONY: int = 3
const SWITCH_POLYPHONY: int = 2
const CONFIRM_POLYPHONY: int = 2
const BACK_POLYPHONY: int = 1
const REFUSE_POLYPHONY: int = 1
## A time long before the first input, in ms, so no gap holds back the first sound.
const LONG_AGO_MS: int = -1000
## The mix of the sounds made in code, added to the scene's volumes, which suit the recorded files:
## the made ones all come out at one peak, and this keeps the move about 11 dB under the choice.
const MADE_MIX_DB: Dictionary[StringName, float] = {&"move": -14.0, &"confirm": -3.0, &"back": -8.0}

## The menu this one serves: it sounds only while that shows, and only for what lies under it.
@export var menu: CanvasLayer

@export_group("Sounds")
## The selection's click; empty, it is made in code.
@export var move_stream: AudioStream
## The choice's blow; empty, it is made in code.
@export var confirm_stream: AudioStream
## The way back's thud; empty, it is made in code.
@export var back_stream: AudioStream
## A slider's tick; empty, the selection's click.
@export var tick_stream: AudioStream
## A switch's click; empty, the selection's click at Switch Pitch.
@export var switch_stream: AudioStream
## The refusal's two thuds, for a key or a gamepad button the controls screen refuses; empty, the way
## back's thud.
@export var refuse_stream: AudioStream
@export_range(-40.0, 6.0, 0.5, "suffix:dB") var move_volume_db: float = -14.0
@export_range(-40.0, 6.0, 0.5, "suffix:dB") var confirm_volume_db: float = -3.0
@export_range(-40.0, 6.0, 0.5, "suffix:dB") var back_volume_db: float = -8.0
@export_range(-40.0, 6.0, 0.5, "suffix:dB") var tick_volume_db: float = -14.0
@export_range(-40.0, 6.0, 0.5, "suffix:dB") var switch_volume_db: float = -10.0
## Only for a Refuse Stream of its own, which holds its mix, as the recorded files do.
@export_range(-40.0, 6.0, 0.5, "suffix:dB") var refuse_volume_db: float = 0.0
## How far each click made in code strays in pitch, up or down, so a run of them never sounds the
## same. A Move Stream of its own strays as its Random Pitch says.
@export_range(0.0, 2.0, 0.05, "suffix:semitones") var move_pitch_spread: float = 0.6
## How far each click made in code strays in loudness, up or down.
@export_range(0.0, 6.0, 0.5, "suffix:dB") var move_volume_spread_db: float = 1.0
## A switch's click with no stream of its own: the selection's, at this share of its pitch.
@export_range(0.5, 2.0, 0.05) var switch_pitch: float = 1.3
## A slider's click: its pitch at the lowest value (x) and at the highest (y), as shares.
@export var slider_pitch: Vector2 = Vector2(0.85, 1.3)
## The shortest time between two clicks, so a list run through fast stays clicks, not a buzz.
@export_range(0, 200, 5, "suffix:ms") var move_gap_ms: int = 35

@export_group("Vibration")
@export var move_pulse: RumblePulse
@export var confirm_pulse: RumblePulse
@export var back_pulse: RumblePulse
## The shortest time between two move pulses: the motors take about this long to start and stop,
## so closer ones would run together into a buzz.
@export_range(0, 300, 5, "suffix:ms") var move_pulse_gap_ms: int = 90

## The streams made in code, shared by every menu, so they are made once a run. The last menu to
## leave the tree lets them go, so none is still held as the game closes.
static var _made: Dictionary[StringName, AudioStream] = {}
## How many MenuFeedback nodes are in the tree.
static var _in_tree: int = 0

## What gives the time, in ms: real time, as the gaps are felt in it. A test puts a clock of its own.
var clock: Callable = Time.get_ticks_msec

var _input_msec: int = -INPUT_WINDOW_MS - 1
var _cancel_msec: int = -INPUT_WINDOW_MS - 1
var _last_click_msec: int = LONG_AGO_MS
var _last_move_pulse_msec: int = LONG_AGO_MS
var _confirm_msec: int = LONG_AGO_MS
## True once an item of the open list is picked, so its closing does not thud.
var _list_picked: bool = false
var _move_player: AudioStreamPlayer
var _tick_player: AudioStreamPlayer
var _switch_player: AudioStreamPlayer
var _confirm_player: AudioStreamPlayer
var _back_player: AudioStreamPlayer
## The refusal's own player, or the way back's when there is no Refuse Stream.
var _refuse_player: AudioStreamPlayer
var _rumble: ControllerRumble


func _enter_tree() -> void:
	_in_tree += 1


func _exit_tree() -> void:
	_in_tree -= 1
	if _in_tree == 0:
		_made.clear()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var move: AudioStream = move_stream if move_stream else _made_stream(&"move")
	var move_db: float = move_volume_db + (0.0 if move_stream else MADE_MIX_DB[&"move"])
	_move_player = _new_player(move, move_db, MOVE_POLYPHONY)
	_tick_player = (_new_player(tick_stream, tick_volume_db, MOVE_POLYPHONY) if tick_stream
			else _new_player(move, move_db, MOVE_POLYPHONY))
	_switch_player = (_new_player(switch_stream, switch_volume_db, SWITCH_POLYPHONY) if switch_stream
			else _new_player(move, move_db, SWITCH_POLYPHONY))
	_confirm_player = (_new_player(confirm_stream, confirm_volume_db, CONFIRM_POLYPHONY)
			if confirm_stream else _new_player(_made_stream(&"confirm"),
			confirm_volume_db + MADE_MIX_DB[&"confirm"], CONFIRM_POLYPHONY))
	_back_player = (_new_player(back_stream, back_volume_db, BACK_POLYPHONY) if back_stream
			else _new_player(_made_stream(&"back"), back_volume_db + MADE_MIX_DB[&"back"],
			BACK_POLYPHONY))
	_refuse_player = (_new_player(refuse_stream, refuse_volume_db, REFUSE_POLYPHONY) if refuse_stream
			else _back_player)
	_rumble = ControllerRumble.new()
	add_child(_rumble)
	if menu == null:
		push_warning("MenuFeedback: no menu set, so it never sounds.")
		return
	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	for node: Node in menu.find_children("*", "", true, false):
		_listen_to(node)
	get_tree().node_added.connect(_on_node_added)


## Notes the player's own input, so the selection's next move counts as theirs. It never handles it.
func _input(event: InputEvent) -> void:
	if not _is_showing():
		return
	var now: int = _now()
	if event is InputEventMouseMotion:
		_input_msec = now
	elif event.is_action_pressed(&"ui_cancel"):
		_cancel_msec = now
	else:
		for action: StringName in NAVIGATION:
			if event.is_action_pressed(action, true):
				_input_msec = now
				return


func _is_showing() -> bool:
	return menu != null and menu.visible


func _on_node_added(node: Node) -> void:
	if menu != null and menu.is_ancestor_of(node):
		_listen_to(node)


## Buttons sound when pressed, a list's items too, sliders when the player moves them, a dialog when
## answered (its own buttons only through the answer), and the controls screen when a key remaps an
## action or Esc stops its wait.
func _listen_to(node: Node) -> void:
	if (node is BaseButton and not _answers_a_dialog(node)
			and not (node as BaseButton).pressed.is_connected(_on_pressed.bind(node))):
		(node as BaseButton).pressed.connect(_on_pressed.bind(node))
		if node is OptionButton:
			_listen_to_the_list((node as OptionButton).get_popup())
	elif node is Range and not (node as Range).value_changed.is_connected(_on_slid.bind(node)):
		(node as Range).value_changed.connect(_on_slid.bind(node))
	elif node is ConfirmationDialog:
		var dialog: ConfirmationDialog = node as ConfirmationDialog
		if not dialog.confirmed.is_connected(_play_confirm):
			dialog.confirmed.connect(_play_confirm)
			dialog.canceled.connect(_play_back)
			dialog.gui_focus_changed.connect(_on_focus_changed)
	elif node is ControlsMenu and not (node as ControlsMenu).rebound.is_connected(_on_rebound):
		(node as ControlsMenu).rebound.connect(_on_rebound)
		(node as ControlsMenu).wait_cancelled.connect(_on_wait_cancelled)
		(node as ControlsMenu).input_refused.connect(_on_input_refused)


## Whether button belongs to a dialog (its OK and Cancel are its own internal children), which
## answers with confirmed or canceled: a sound for the press too would play two at once.
func _answers_a_dialog(button: Node) -> bool:
	var node: Node = button.get_parent()
	while node != null and node != menu:
		if node is AcceptDialog:
			return true
		node = node.get_parent()
	return false


## A list's own window: the player's moves inside it come as its focused item changing, since its
## keys never reach the menu (_input); picking an item and closing it sound too.
func _listen_to_the_list(list: PopupMenu) -> void:
	list.about_to_popup.connect(_on_list_opening)
	list.id_focused.connect(_on_list_moved.unbind(1))
	list.index_pressed.connect(_on_list_picked.unbind(1))
	list.popup_hide.connect(_on_list_closed)


## A move of the selection right after the player's input is theirs: a click, or the thud of the
## way back if that input was Back. A move the game makes itself is silent.
func _on_focus_changed(_control: Control) -> void:
	if not _is_showing():
		return
	var now: int = _now()
	if now - _cancel_msec <= INPUT_WINDOW_MS:
		_cancel_msec = -INPUT_WINDOW_MS - 1
		_play_back()
	elif now - _input_msec <= INPUT_WINDOW_MS and now - _confirm_msec > INPUT_WINDOW_MS:
		_play_move(_move_player, 1.0, &"move")


func _on_pressed(button: BaseButton) -> void:
	if not _is_showing():
		return
	if button is CheckButton or button is CheckBox or button is OptionButton:
		_play_move(_switch_player, 1.0 if switch_stream else switch_pitch, &"switch")
	elif button.name == &"BackButton":
		_play_back()
	else:
		_play_confirm()


## Only a slider the player is on, and only right after their input: the options screen sets its
## sliders itself as it opens, silently.
func _on_slid(value: float, slider: Range) -> void:
	var now: int = _now()
	if not _is_showing() or not slider.has_focus() or now - _input_msec > INPUT_WINDOW_MS:
		return
	var share: float = inverse_lerp(slider.min_value, slider.max_value, value)
	_play_move(_tick_player, lerpf(slider_pitch.x, slider_pitch.y, share), &"slider")


func _on_list_opening() -> void:
	_list_picked = false


func _on_list_moved() -> void:
	if _is_showing():
		_play_move(_move_player, 1.0, &"move")


func _on_list_picked() -> void:
	_list_picked = true
	if _is_showing():
		_play_confirm()


## The list hides as an item is picked too, and that may come before the pick's signal, so the
## answer waits for the end of the frame: a thud only if nothing was picked.
func _on_list_closed() -> void:
	_answer_the_closed_list.call_deferred()


func _answer_the_closed_list() -> void:
	if not _list_picked and _is_showing():
		_play_back()
	_list_picked = false


func _on_rebound(_action: StringName) -> void:
	if _is_showing():
		_play_confirm()


## A key or a gamepad button the controls screen cannot take: the refusal, while its button says
## why. It pulses as the way back does.
func _on_input_refused() -> void:
	if _is_showing():
		_refuse_player.play()
		_rumble.play(back_pulse)
		played.emit(&"refuse")


## The thud of the way back; the Esc that stopped the wait no longer counts as a way back for the
## selection's next move.
func _on_wait_cancelled() -> void:
	_cancel_msec = -INPUT_WINDOW_MS - 1
	if _is_showing():
		_play_back()


func _play_move(player: AudioStreamPlayer, pitch: float, sound: StringName) -> void:
	var now: int = _now()
	if now - _last_click_msec < move_gap_ms:
		return
	_last_click_msec = now
	player.pitch_scale = pitch
	player.play()
	if (now - _last_move_pulse_msec >= move_pulse_gap_ms
			and now - _confirm_msec >= _pulse_ms(confirm_pulse)):
		_last_move_pulse_msec = now
		_rumble.play(move_pulse)
	played.emit(sound)


func _play_confirm() -> void:
	_confirm_msec = _now()
	_confirm_player.play()
	_rumble.play(confirm_pulse)
	played.emit(&"confirm")


func _play_back() -> void:
	_back_player.play()
	_rumble.play(back_pulse)
	played.emit(&"back")


func _new_player(stream: AudioStream, volume_db: float, polyphony: int) -> AudioStreamPlayer:
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.max_polyphony = polyphony
	player.bus = BUS
	add_child(player)
	return player


## A sound made in code, with its variants picked at random and never twice in a row, the move's
## each a little off in pitch and loudness.
func _made_stream(sound: StringName) -> AudioStream:
	if _made.has(sound):
		return _made[sound]
	var randomizer: AudioStreamRandomizer = AudioStreamRandomizer.new()
	match sound:
		&"move":
			for variant: int in MOVE_VARIANTS:
				randomizer.add_stream(-1, Synth.move(variant, MOVE_VARIANTS))
			randomizer.random_pitch = pow(2.0, move_pitch_spread / 12.0)
			randomizer.random_volume_offset_db = move_volume_spread_db
		&"confirm":
			for variant: int in CONFIRM_VARIANTS:
				randomizer.add_stream(-1, Synth.confirm(variant))
		&"back":
			for variant: int in BACK_VARIANTS:
				randomizer.add_stream(-1, Synth.back(variant))
	_made[sound] = randomizer
	return randomizer


func _now() -> int:
	return clock.call()


static func _pulse_ms(pulse: RumblePulse) -> int:
	return int(pulse.duration * 1000.0) if pulse != null else 0
