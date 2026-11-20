class_name MainMenu
extends CanvasLayer

## The first screen, over the MenuBackdrop (the character in the light), with the crosses marking
## the selected option. The main panel has Continue and Load while a save slot holds a game to come
## back to, New Game (PlayButton), Settings (OptionsButton) and Quit; the first of them is always
## the biggest. The game's name is kept in Title, hidden. New Game starts the level at once when
## there is only one, and otherwise opens the level panel, with a button for each level and Back;
## Settings opens the options screen. The slot panel lists the three save slots, each in two lines,
## for Load or, when the scene asks, for a new game. The
## menu only says what was chosen, through its signals, and the scene it is in decides what that
## does. Each panel opens with a button selected, its first one or, on the slot panel, the slot most
## likely wanted, so the arrow keys and Enter work without the mouse; Esc on the level or slot panel
## goes back, and coming back selects the button the player left from. The panels sit on the right third of the screen, across from the character,
## centred from top to bottom.

signal level_chosen(index: int)
signal continue_requested
## Load: the player picked slot, which holds a game that can be continued.
signal load_slot_chosen(slot: int)
## The player picked slot for the new game of the level at index.
signal new_game_slot_chosen(index: int, slot: int)
## The player agreed to replace slot's file with the new game of the level at index.
signal new_game_confirmed(index: int, slot: int)
signal quit_requested

## What the slot panel is open for.
enum SlotsFor { LOAD, NEW_GAME }

## The theme's look for the main panel's first option, the biggest, for the others, and for a save
## slot's two lines.
const FIRST_OPTION: StringName = &"MenuFirstOption"
const OPTION: StringName = &"MenuOption"
const SLOT: StringName = &"MenuSlot"
const LOAD_HEADING: String = "Load a game"
const NEW_GAME_HEADING: String = "Choose a slot for the new game"
const EMPTY_SLOT_TEXT: String = "Empty"
const DAMAGED_SLOT_TEXT: String = "Can't be read"
## A save's level when its scene is no level's in the menu.
const UNNAMED_LEVEL: String = "Saved game"
const REPLACE_TEXT: String = "Starting a new game in slot %d replaces its saved game."
const REPLACE_DAMAGED_TEXT: String = "Slot %d can't be read. A new game there replaces it."

## The level the new game is for, while the slots show for it and while the question shows.
var _asked_level: int = 0
## The slot the replace-save question is about.
var _asked_slot: int = 0
## What each slot holds, slot 1 first, as set_slots() got it.
var _slots: Array[SaveSlots.Summary] = []
var _slots_for: SlotsFor = SlotsFor.LOAD
## The button that opened the slot panel, selected again when it closes.
var _slots_opener: Button = null

@onready var _title: Label = %Title
@onready var _main_panel: Control = %MainPanel
@onready var _continue_button: Button = %ContinueButton
@onready var _load_button: Button = %LoadButton
@onready var _play_button: Button = %PlayButton
@onready var _options_button: Button = %OptionsButton
@onready var _quit_button: Button = %QuitButton
@onready var _level_panel: Control = %LevelPanel
@onready var _level_buttons: Container = %LevelButtons
@onready var _back_button: Button = %BackButton
@onready var _slot_panel: Control = %SlotPanel
@onready var _slot_heading: Label = %SlotHeading
@onready var _slot_buttons: Container = %SlotButtons
## Named BackButton, as every menu's way back, so MenuFeedback sounds it as going back.
@onready var _slot_back_button: Button = $Center/SlotPanel/BackButton
@onready var _options_menu: OptionsMenu = %OptionsMenu
@onready var _backdrop: MenuBackdrop = $MenuBackdrop
@onready var _replace_save_dialog: ConfirmationDialog = %ReplaceSaveDialog
@onready var _crosses: MenuCrosses = $Crosses
@onready var _blur: ColorRect = $Blur


func _ready() -> void:
	_title.text = ProjectSettings.get_setting("application/config/name") as String
	_continue_button.pressed.connect(continue_requested.emit)
	_load_button.pressed.connect(_open_slots.bind(SlotsFor.LOAD))
	_slot_back_button.pressed.connect(_close_slots)
	for slot: int in range(1, SaveSlots.COUNT + 1):
		var button: Button = Button.new()
		button.theme_type_variation = SLOT
		button.pressed.connect(_on_slot_pressed.bind(slot))
		_slot_buttons.add_child(button)
	_play_button.pressed.connect(_on_play_pressed)
	_options_button.pressed.connect(_show_options)
	_quit_button.pressed.connect(quit_requested.emit)
	_back_button.pressed.connect(_show_main_panel.bind(_play_button))
	_options_menu.closed.connect(_show_main_panel.bind(_options_button))
	_replace_save_dialog.confirmed.connect(_on_replace_save_confirmed)
	_replace_save_dialog.canceled.connect(_on_replace_save_canceled)
	_replace_save_dialog.get_label().horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_replace_save_dialog.visibility_changed.connect(_on_replace_save_visibility_changed)
	_size_options()
	_show_main_panel(_play_button)


## Esc goes back only while the level or the slot panel shows: the menu is a node that stays in the
## tree while it is hidden, and its input callbacks run then too. The options screen handles its own
## Esc.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"ui_cancel"):
		return
	if _slot_panel.is_visible_in_tree():
		_close_slots()
		get_viewport().set_input_as_handled()
	elif _level_panel.is_visible_in_tree():
		_show_main_panel(_play_button)
		get_viewport().set_input_as_handled()


## Adds a button to the level panel for each title, in order. Pressing one sends its index with
## level_chosen.
func add_levels(titles: PackedStringArray) -> void:
	for index: int in titles.size():
		var button: Button = Button.new()
		button.text = titles[index]
		button.theme_type_variation = OPTION
		button.pressed.connect(level_chosen.emit.bind(index))
		_level_buttons.add_child(button)


## Opens the slots for the new game of the level at index, with the first empty one selected, or
## slot 1 when every slot holds a file.
func choose_new_game_slot(index: int) -> void:
	_asked_level = index
	_open_slots(SlotsFor.NEW_GAME)


## Asks before the new game replaces slot's file, with No selected, so a press too many keeps it.
## A file that can't be read is called so.
func ask_to_replace_save(slot: int) -> void:
	_asked_slot = slot
	var damaged: bool = (slot >= 1 and slot <= _slots.size()
			and _slots[slot - 1].state == SaveSlots.State.DAMAGED)
	_replace_save_dialog.dialog_text = (REPLACE_DAMAGED_TEXT if damaged else REPLACE_TEXT) % slot
	_replace_save_dialog.popup_centered()
	_replace_save_dialog.get_cancel_button().grab_focus()


## What each slot holds, slot 1 first, with the title of the level each one is in, empty when no
## level in the menu has its scene. Continue and Load show while a slot holds a game that can be
## continued, and Continue is then selected, as what most players want next. Given while the slots
## show, as when a file went bad, they take it in at once.
func set_slots(summaries: Array[SaveSlots.Summary], titles: PackedStringArray) -> void:
	_slots = summaries
	for index: int in mini(summaries.size(), _slot_buttons.get_child_count()):
		var title: String = titles[index] if index < titles.size() else ""
		(_slot_buttons.get_child(index) as Button).text = slot_text(summaries[index], title)
	var can_continue: bool = SaveSlots.latest_of(summaries) != 0
	_continue_button.visible = can_continue
	_load_button.visible = can_continue
	_size_options()
	if _slot_panel.visible:
		_refresh_open_slots()
	elif _main_panel.is_visible_in_tree():
		_first_button().grab_focus()


## A save slot's text: the slot and what it holds, then, for a game, its play time, its deaths and
## the date it was last played, on this computer's clock. title is its level's; empty, Unnamed Level.
## The offset from UTC is today's, so a date on the other side of a change to or from summer time
## shows an hour off.
static func slot_text(summary: SaveSlots.Summary, title: String) -> String:
	match summary.state:
		SaveSlots.State.EMPTY:
			return "Slot %d\n%s" % [summary.slot, EMPTY_SLOT_TEXT]
		SaveSlots.State.DAMAGED:
			return "Slot %d\n%s" % [summary.slot, DAMAGED_SLOT_TEXT]
	var where: String = title if not title.is_empty() else UNNAMED_LEVEL
	if summary.phase > 0:
		where += " · Phase %d" % summary.phase
	return "Slot %d · %s\n%s · %s · %s" % [summary.slot, where, _play_time(summary.seconds),
			_deaths(summary.deaths), date_text(summary.last_played,
			utc_offset(Time.get_datetime_dict_from_system(), Time.get_unix_time_from_system()))]


## unix as a date and time offset_seconds away from UTC, year first, as 2026-11-19 17:40, which
## reads the same in every country.
static func date_text(unix: float, offset_seconds: int) -> String:
	var local: Dictionary = Time.get_datetime_dict_from_unix_time(int(unix) + offset_seconds)
	return "%04d-%02d-%02d %02d:%02d" % [local.year, local.month, local.day, local.hour,
			local.minute]


## How far local is from UTC, in seconds, to the minute: local is a date and time on a clock, as
## Time gives it, and unix the same moment in UTC.
static func utc_offset(local: Dictionary, unix: float) -> int:
	return roundi((Time.get_unix_time_from_datetime_dict(local) - unix) / 60.0) * 60


## Shows the menu again, on the main panel with its first button selected.
func open() -> void:
	show()
	_show_main_panel(_first_button())


## While the question shows, what lies behind its box is blurred, and the menu's crosses, by the
## level button, hide: the question has its own.
func _on_replace_save_visibility_changed() -> void:
	var showing: bool = _replace_save_dialog.visible
	_crosses.visible = not showing
	_blur.visible = showing
	if showing:
		_blur.position = Vector2(_replace_save_dialog.position)
		_blur.size = Vector2(_replace_save_dialog.size)


func _on_replace_save_confirmed() -> void:
	new_game_confirmed.emit(_asked_level, _asked_slot)


## Back to the slot the question came from; New Game when no slot shows.
func _on_replace_save_canceled() -> void:
	if _slot_panel.visible and _asked_slot >= 1 and _asked_slot <= _slot_buttons.get_child_count():
		(_slot_buttons.get_child(_asked_slot - 1) as Control).grab_focus()
	else:
		_play_button.grab_focus()


func _on_slot_pressed(slot: int) -> void:
	if _slots_for == SlotsFor.LOAD:
		load_slot_chosen.emit(slot)
	else:
		new_game_slot_chosen.emit(_asked_level, slot)


## The slot panel alone, for slots_for, with the slot most likely wanted selected. It remembers the
## button that opened it, to select it again on the way back.
func _open_slots(slots_for: SlotsFor) -> void:
	_slots_for = slots_for
	_slots_opener = get_viewport().gui_get_focus_owner() as Button
	_slot_heading.text = LOAD_HEADING if slots_for == SlotsFor.LOAD else NEW_GAME_HEADING
	_apply_slot_states()
	_main_panel.hide()
	_level_panel.hide()
	_slot_panel.show()
	_select_likely_slot()


## A slot Load can't open can't be selected or pressed; for a new game, every slot can.
func _apply_slot_states() -> void:
	for index: int in mini(_slots.size(), _slot_buttons.get_child_count()):
		var button: Button = _slot_buttons.get_child(index) as Button
		var usable: bool = (_slots_for == SlotsFor.NEW_GAME
				or _slots[index].state == SaveSlots.State.READY)
		button.disabled = not usable
		button.focus_mode = Control.FOCUS_ALL if usable else Control.FOCUS_NONE


## For Load, the slot played last; for a new game, the first empty one, or slot 1.
func _select_likely_slot() -> void:
	var selected: int = (SaveSlots.latest_of(_slots) if _slots_for == SlotsFor.LOAD
			else SaveSlots.first_empty_of(_slots))
	(_slot_buttons.get_child(maxi(selected, 1) - 1) as Control).grab_focus()


## The slots changed while they show, as when a file went bad on disk: a slot Load can no longer
## open can't be picked, and if it was selected, the slot most likely wanted is. With nothing left
## to load, the main panel comes back.
func _refresh_open_slots() -> void:
	if _slots_for == SlotsFor.LOAD and SaveSlots.latest_of(_slots) == 0:
		_show_main_panel(_first_button())
		return
	_apply_slot_states()
	var focused: Control = get_viewport().gui_get_focus_owner()
	if focused == null or focused.focus_mode == Control.FOCUS_NONE:
		_select_likely_slot()


## Back to the button that opened the slots: Load or New Game on the main panel, or a level's on
## the level panel. Load can't have gone meanwhile: with nothing left to load, the slots close at
## once, in _refresh_open_slots().
func _close_slots() -> void:
	_slot_panel.hide()
	if _slots_opener != null and _level_buttons.is_ancestor_of(_slots_opener):
		_level_panel.show()
		_slots_opener.grab_focus()
	else:
		_show_main_panel(_slots_opener if _slots_opener != null else _first_button())


## With a single level there is nothing to choose: New Game starts it, as the list would.
func _on_play_pressed() -> void:
	if _level_buttons.get_child_count() == 1:
		level_chosen.emit(0)
	else:
		_show_level_panel()


func _first_button() -> Button:
	return _continue_button if _continue_button.visible else _play_button


## The first option shown is the biggest; the others are all the same size.
func _size_options() -> void:
	var first: Button = _first_button()
	for button: Button in [_continue_button, _load_button, _play_button, _options_button,
			_quit_button]:
		button.theme_type_variation = FIRST_OPTION if button == first else OPTION


## The main panel alone, with the given button selected, and the character in front again. The
## options screen hides itself when it closes.
func _show_main_panel(selected: Button) -> void:
	_level_panel.hide()
	_slot_panel.hide()
	_backdrop.recede(false)
	_main_panel.show()
	selected.grab_focus()


## With no levels, Back gets the focus, so the keyboard still has a button to press.
func _show_level_panel() -> void:
	_main_panel.hide()
	_level_panel.show()
	if _level_buttons.get_child_count() > 0:
		(_level_buttons.get_child(0) as Control).grab_focus()
	else:
		_back_button.grab_focus()


## The character steps back while the options show, so the two do not fight for the eye.
func _show_options() -> void:
	_main_panel.hide()
	_backdrop.recede(true)
	_options_menu.open()


## seconds as hours and minutes, as 1h 02m, or minutes alone under an hour, as 45m.
static func _play_time(seconds: float) -> String:
	var minutes: int = floori(seconds / 60.0)
	if minutes < 60:
		return "%dm" % minutes
	return "%dh %02dm" % [floori(minutes / 60.0), minutes % 60]


static func _deaths(deaths: int) -> String:
	return "1 death" if deaths == 1 else "%d deaths" % deaths
