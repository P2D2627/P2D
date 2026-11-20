class_name SoundRoom
extends Control

## The sound test room: lists the sound events under Audio Folder by name and plays each one, with
## its versions at random and on its bus, so whoever makes the sound hears it in Godot without a
## programmer. The names follow the rule in SoundCatalog, so a new file with the right name shows up
## the next time the room starts, or at Rescan, without a change to the code. Run it with F6.
##
## With the mouse, a click plays an event. With the keyboard or a controller, the arrows move
## between the events and Enter (A) plays the one with the focus; typing a letter writes in Search,
## which keeps only the events whose name has the text, and Enter there plays the first of them.
## Esc (B) stops everything. An event plays over its last play, up to Max Polyphony at once, so a
## run of presses hears the versions one after the other; an event that loops by its import plays
## until it is pressed again.
##
## The sounds play as they are, through their bus, with no position: a 2D sound at the middle of the
## screen is heard about 6 dB lower in the game, at half its level in each speaker, and lower still
## further away.

## Where the sounds are. Each file under it, in any subfolder, is a version of an event.
@export_dir var audio_folder: String = "res://assets/audio"
## The bus of each first folder under Audio Folder, so each event plays where it plays in the game.
## A folder not here, and a file straight in Audio Folder, play on Fallback Bus.
@export var bus_by_folder: Dictionary[String, StringName] = {
	"music": &"Music",
	"sfx": &"SFX",
	"ambience": &"Ambience",
	"textures": &"Ambience",
	"ui": &"UI",
}
## The bus of the folders that are not in Bus By Folder.
@export var fallback_bus: StringName = &"SFX"
## How far an event with versions moves its pitch, either way, each time it plays: 1.05 is 5% up or
## down, as the game's new sounds do (docs/som_e_musica.md, section 4). An event of one file plays
## at its own pitch.
@export_range(1.0, 2.0, 0.005) var random_pitch: float = 1.05
## How many plays of one event sound at once: a press while it plays adds one, up to this, and past
## it the oldest is cut.
@export_range(1, 16, 1) var max_polyphony: int = 4

## The events, in the order of the list.
var _events: Array[SoundCatalog.Event] = []
## The button of each event, in the order of _events.
var _buttons: Array[Button] = []
## The heading of each folder, by folder, hidden while none of its events shows.
var _headings: Dictionary[String, Label] = {}
## The player of each event, by its key, made the first time it plays.
var _players: Dictionary[String, AudioStreamPlayer] = {}
## Whether each event loops, by its key, found when its player is made.
var _loops: Dictionary[String, bool] = {}

@onready var _search: LineEdit = %Search
@onready var _stop_all_button: Button = %StopAll
@onready var _rescan_button: Button = %Rescan
@onready var _list: VBoxContainer = %List
@onready var _status: Label = %Status


func _ready() -> void:
	_search.text_changed.connect(_on_search_changed)
	_search.text_submitted.connect(_on_search_submitted)
	_stop_all_button.pressed.connect(stop_all)
	_rescan_button.pressed.connect(rescan)
	rescan()
	if not _buttons.is_empty():
		_buttons[0].grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		stop_all()
		get_viewport().set_input_as_handled()
		return
	# Typing a letter with the focus on the list writes it in Search. It reads the text typed, not
	# a key of the game, so no action of the Input Map stands for it.
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or key.unicode < 32 or _search.has_focus():
		return
	_search.grab_focus()
	_search.edit()
	_search.insert_text_at_caret(char(key.unicode))
	get_viewport().set_input_as_handled()


## Reads Audio Folder again and makes the list anew, so a file added while the room runs shows up
## once Godot has imported it. Stops what plays.
func rescan() -> void:
	stop_all()
	for player: AudioStreamPlayer in _players.values():
		player.queue_free()
	_players.clear()
	_loops.clear()
	for child: Node in _list.get_children():
		child.queue_free()
	_buttons.clear()
	_headings.clear()
	_events = SoundCatalog.scan(audio_folder, bus_by_folder, fallback_bus)
	for event: SoundCatalog.Event in _events:
		if not _headings.has(event.folder):
			var heading := Label.new()
			heading.text = event.folder if not event.folder.is_empty() else audio_folder
			heading.add_theme_color_override(&"font_color", Color(0.65, 0.65, 0.7))
			_list.add_child(heading)
			_headings[event.folder] = heading
		if AudioServer.get_bus_index(event.bus) == -1:
			push_warning("SoundRoom: %s plays on the bus %s, which does not exist; it plays on Master."
					% [event.get_key(), event.bus])
		var button := Button.new()
		button.text = _row_text(event)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_on_event_pressed.bind(event))
		_list.add_child(button)
		_buttons.append(button)
	_apply_search(_search.text)
	_status.text = "%d sound events in %s." % [_events.size(), audio_folder]


## The events of the list, in its order.
func get_events() -> Array[SoundCatalog.Event]:
	return _events


## The event called Event Name, as in its files (footstep), or with its folder (sfx/footstep) when
## two folders have one of the same name; null if there is none.
func find_event(event_name: String) -> SoundCatalog.Event:
	for event: SoundCatalog.Event in _events:
		if event.get_key() == event_name:
			return event
	for event: SoundCatalog.Event in _events:
		if event.name == event_name:
			return event
	return null


## Plays the event called Event Name (find_event()), as a press of its button does. False if there
## is no such event or none of its files loads.
func play_by_name(event_name: String) -> bool:
	var event := find_event(event_name)
	return event != null and play(event)


## Plays Event over its last play; an event that loops and plays is stopped instead. False if none
## of its files loads.
func play(event: SoundCatalog.Event) -> bool:
	var player := _player_of(event)
	if player == null:
		_status.text = "%s: none of its files loads." % event.get_key()
		return false
	if _loops[event.get_key()] and player.playing:
		player.stop()
		_status.text = "Stopped %s." % event.get_key()
		return true
	player.play()
	_status.text = "Playing %s: %s, on %s.%s" % [event.get_key(), _versions_text(event), player.bus,
			_silence_note(player.bus)]
	return true


## The player of the event called Event Name, null before it first plays: for the tests.
func get_player(event_name: String) -> AudioStreamPlayer:
	var event := find_event(event_name)
	return _players.get(event.get_key()) if event != null else null


## Stops every sound the room plays.
func stop_all() -> void:
	for player: AudioStreamPlayer in _players.values():
		player.stop()
	if _status != null:
		_status.text = "Stopped all."


## Shows only the events whose name, or folder and name, has Text, without case, and the
## headings of their folders. Empty, it shows them all.
func _apply_search(text: String) -> void:
	var wanted := text.strip_edges().to_lower()
	var shown_folders: Dictionary[String, bool] = {}
	for index: int in _events.size():
		var event := _events[index]
		var shown := wanted.is_empty() or event.get_key().to_lower().contains(wanted)
		_buttons[index].visible = shown
		if shown:
			shown_folders[event.folder] = true
	for folder: String in _headings:
		_headings[folder].visible = shown_folders.has(folder)


## The player of Event, made the first time it plays, on its bus; null if none of its files loads.
func _player_of(event: SoundCatalog.Event) -> AudioStreamPlayer:
	var key := event.get_key()
	if _players.has(key):
		return _players[key]
	var stream := event.make_stream(random_pitch)
	if stream == null:
		return null
	var player := AudioStreamPlayer.new()
	player.name = key.validate_node_name()
	player.stream = stream
	player.bus = event.bus
	player.max_polyphony = max_polyphony
	add_child(player)
	_players[key] = player
	_loops[key] = event.loops()
	return player


## A row of the list: the name, how many versions, the bus, and whether it loops.
func _row_text(event: SoundCatalog.Event) -> String:
	var text := "%s   ·   %s   ·   %s" % [event.name, _versions_text(event), event.bus]
	return text + "   ·   loop" if event.loops() else text


func _versions_text(event: SoundCatalog.Event) -> String:
	var count := event.paths.size()
	return "1 version" if count == 1 else "%d versions at random" % count


## A note for the status line when Bus, or a bus it sends to, is muted or turned all the way down,
## as the volumes in the options can leave them; empty when it is heard.
func _silence_note(bus: StringName) -> String:
	var index := AudioServer.get_bus_index(bus)
	while index != -1:
		var bus_name := AudioServer.get_bus_name(index)
		if AudioServer.is_bus_mute(index) or AudioServer.get_bus_volume_linear(index) <= 0.0:
			return " The bus %s is muted: turn it up in the options." % bus_name
		if index == 0:
			break
		index = AudioServer.get_bus_index(AudioServer.get_bus_send(index))
	return ""


func _on_event_pressed(event: SoundCatalog.Event) -> void:
	play(event)


func _on_search_changed(text: String) -> void:
	_apply_search(text)


func _on_search_submitted(_text: String) -> void:
	for index: int in _events.size():
		if _buttons[index].visible:
			play(_events[index])
			_buttons[index].grab_focus()
			return
