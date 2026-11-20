# Checks the sound test room. By the rule of the names, a file's event is its name without a last
# "_<number>", and the files of one folder with one event are its versions, in natural order; the
# first folder picks the bus (music, sfx, ambience, textures and ui to Music, SFX, Ambience and UI),
# and a new file with the right name is an event with no change to the code. The real audio folder
# gives the events of the files there: hard_land with its two versions, player_jump with one, and
# every event on one of the four buses, which exist. An event with versions plays through an
# AudioStreamRandomizer that never repeats the last one, with Random Pitch 1.05; one file plays as
# it is. The room lists a button per event; the mouse, Enter and the play by name play an event on
# its bus, by the table in its Inspector; a loop stops when pressed again; Search keeps only the
# events with its text, and a letter typed on the list goes there; Esc stops everything.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_sound_room.gd
extends "res://tests/support/base_test.gd"

const ROOM_PATH: String = "res://scenes/others/debug/sound_room.tscn"
const AUDIO_FOLDER: String = "res://assets/audio"
## The buses the events may play on.
const EVENT_BUSES: Array[StringName] = [&"Music", &"SFX", &"Ambience", &"UI"]
## The room's table, as in its script.
const BUS_BY_FOLDER: Dictionary[String, StringName] = {
	"music": &"Music",
	"sfx": &"SFX",
	"ambience": &"Ambience",
	"textures": &"Ambience",
	"ui": &"UI",
}
const FALLBACK_BUS: StringName = &"SFX"
## Files as a folder could hold them, from the root: a new event with two versions, ten steps out of
## order, one with no number and one with, a name that ends in a number with no "_" before it, one
## event in two folders, a music layer, a UI sound, a folder not in the table and a file that is no
## sound.
const FAKE_FILES: PackedStringArray = [
	"sfx/new_sound_2.wav", "sfx/new_sound_1.wav",
	"sfx/footstep_10.wav", "sfx/footstep_2.wav", "sfx/footstep_1.wav", "sfx/footstep_3.wav",
	"sfx/footstep_4.wav", "sfx/footstep_5.wav", "sfx/footstep_6.wav", "sfx/footstep_7.wav",
	"sfx/footstep_8.wav", "sfx/footstep_9.wav",
	"sfx/hard_land_2.wav", "sfx/hard_land.wav",
	"sfx/mp3.wav",
	"ambience/wind/passing/one_shot_wind_2.wav", "ambience/wind/passing/one_shot_wind_1_bakedpan.wav",
	"textures/fire/crackles/fire_crackle_1.wav", "sfx/fire_crackle_1.wav",
	"music/music_lust_drone.ogg", "ui/menu_move_1.wav",
	"other/thing.wav", "sfx/notes.txt",
]
## What the fake files give: each event's key, bus and how many versions.
const FAKE_EVENTS: Dictionary[String, Array] = {
	"ambience/wind/passing/one_shot_wind": [&"Ambience", 1],
	"ambience/wind/passing/one_shot_wind_1_bakedpan": [&"Ambience", 1],
	"music/music_lust_drone": [&"Music", 1],
	"other/thing": [FALLBACK_BUS, 1],
	"sfx/fire_crackle": [&"SFX", 1],
	"sfx/footstep": [&"SFX", 10],
	"sfx/hard_land": [&"SFX", 2],
	"sfx/mp3": [&"SFX", 1],
	"sfx/new_sound": [&"SFX", 2],
	"textures/fire/crackles/fire_crackle": [&"Ambience", 1],
	"ui/menu_move": [&"UI", 1],
}
## The order of the steps' versions, natural: 2 before 10.
const STEP_ORDER: Array[String] = ["footstep_1", "footstep_2", "footstep_3", "footstep_4",
		"footstep_5", "footstep_6", "footstep_7", "footstep_8", "footstep_9", "footstep_10"]
## Events of the real folder: one with two versions, one of one file, one that loops by its import,
## and the least number of versions of the steps.
const TWO_VERSIONS: String = "hard_land"
const ONE_VERSION: String = "player_jump"
const LOOPING: String = "crucifix_hold_loopable"
const STEPS: String = "footstep"
const MIN_STEP_VERSIONS: int = 3
const RANDOM_PITCH: float = 1.05
## A table for the room that sends the sfx folder to UI, to see the table pick the bus.
const OTHER_TABLE: Dictionary[String, StringName] = {"sfx": &"UI"}
## The search typed, and the letter typed on the list.
const SEARCH_TEXT: String = "hard"
const TYPED_LETTER: String = "f"
const SCREEN_SIZE: Vector2i = Vector2i(1920, 1080)
const SETTLE_FRAMES: int = 3
## Real milliseconds the audio server is given to let go of the sounds stopped.
const AUDIO_RELEASE_MS: int = 150


func _initialize() -> void:
	var results: Array[bool] = []
	results.append(_names_make_the_events())
	results.append(_real_folder_gives_its_events())
	results.append(_versions_play_at_random())
	var room_scene := load(ROOM_PATH) as PackedScene
	_report(room_scene != null, "%s loads as a scene" % ROOM_PATH)
	if room_scene == null:
		_finish([false])
		return
	# Without a window, the root takes the game's viewport only after a frame (see the commands'
	# notes).
	await process_frame
	root.size = SCREEN_SIZE
	await process_frame
	results.append(await _room_plays_each_event(room_scene))
	results.append(await _table_picks_the_bus(room_scene))
	_finish(results)


## The rule of the names, on files as a folder could hold them.
func _names_make_the_events() -> bool:
	var events := SoundCatalog.group("res://fake", FAKE_FILES, BUS_BY_FOLDER, FALLBACK_BUS)
	var ok := true
	var keys: Array[String] = []
	for event: SoundCatalog.Event in events:
		keys.append(event.get_key())
	var wanted: Array[String] = []
	wanted.assign(FAKE_EVENTS.keys())
	ok = _report(keys == wanted, "the fake files give the events %s, sorted (got %s)" % [wanted, keys]) and ok
	for event: SoundCatalog.Event in events:
		if not FAKE_EVENTS.has(event.get_key()):
			continue
		var bus: StringName = FAKE_EVENTS[event.get_key()][0]
		var count: int = FAKE_EVENTS[event.get_key()][1]
		ok = _report(event.bus == bus and event.paths.size() == count,
				"%s plays on %s with %d version(s) (got %s, %d)" % [event.get_key(), bus, count,
				event.bus, event.paths.size()]) and ok
		ok = _report(event.paths[0].begins_with("res://fake/" + event.folder + "/"),
				"%s's files are under its folder from the root (%s)" % [event.get_key(),
				event.paths[0]]) and ok
	var steps := _event_with_key(events, "sfx/footstep")
	if steps != null:
		var order: Array[String] = []
		for path: String in steps.paths:
			order.append(path.get_file().get_basename())
		ok = _report(order == STEP_ORDER, "the steps' versions are in natural order (got %s)"
				% [order]) and ok
	var landing := _event_with_key(events, "sfx/hard_land")
	if landing != null:
		ok = _report(landing.paths[0].get_file() == "hard_land.wav",
				"hard_land.wav, with no number, is hard_land's first version") and ok
	return ok


## The events of the real audio folder.
func _real_folder_gives_its_events() -> bool:
	var events := SoundCatalog.scan(AUDIO_FOLDER, BUS_BY_FOLDER, FALLBACK_BUS)
	var ok := _report(not events.is_empty(), "%s has sound events" % AUDIO_FOLDER)
	for event: SoundCatalog.Event in events:
		ok = _report(event.bus in EVENT_BUSES and AudioServer.get_bus_index(event.bus) != -1,
				"%s plays on %s, one of %s, which exists" % [event.get_key(), event.bus,
				EVENT_BUSES]) and ok
		for path: String in event.paths:
			ok = _report(SoundCatalog.event_name_of(path.get_file()) == event.name,
					"%s belongs to %s" % [path, event.get_key()]) and ok
	var landing := _event_with_key(events, "sfx/" + TWO_VERSIONS)
	ok = _report(landing != null and landing.paths.size() == 2 and landing.bus == &"SFX",
			"sfx/%s has 2 versions, on SFX" % TWO_VERSIONS) and ok
	var jump := _event_with_key(events, "sfx/" + ONE_VERSION)
	ok = _report(jump != null and jump.paths.size() == 1, "sfx/%s has 1 version" % ONE_VERSION) and ok
	var steps := _event_with_key(events, "sfx/" + STEPS)
	ok = _report(steps != null and steps.paths.size() >= MIN_STEP_VERSIONS,
			"sfx/%s has %d versions or more" % [STEPS, MIN_STEP_VERSIONS]) and ok
	var looping := _event_with_key(events, "sfx/" + LOOPING)
	ok = _report(looping != null and looping.loops(), "sfx/%s loops by its import" % LOOPING) and ok
	return ok


## An event with versions plays through a randomizer; one file plays as it is.
func _versions_play_at_random() -> bool:
	var events := SoundCatalog.scan(AUDIO_FOLDER, BUS_BY_FOLDER, FALLBACK_BUS)
	var ok := true
	var landing := _event_with_key(events, "sfx/" + TWO_VERSIONS)
	if landing != null:
		var randomizer := landing.make_stream(RANDOM_PITCH) as AudioStreamRandomizer
		ok = _report(randomizer != null, "%s plays through an AudioStreamRandomizer" % TWO_VERSIONS) and ok
		if randomizer != null:
			ok = _report(randomizer.streams_count == 2, "it holds its 2 versions (got %d)"
					% randomizer.streams_count) and ok
			ok = _report(randomizer.playback_mode == AudioStreamRandomizer.PLAYBACK_RANDOM_NO_REPEATS,
					"it never repeats the version before") and ok
			ok = _report(is_equal_approx(randomizer.random_pitch, RANDOM_PITCH),
					"its Random Pitch is %.2f (got %.3f)" % [RANDOM_PITCH, randomizer.random_pitch]) and ok
	var jump := _event_with_key(events, "sfx/" + ONE_VERSION)
	if jump != null:
		var stream := jump.make_stream(RANDOM_PITCH)
		ok = _report(stream != null and stream.resource_path == jump.paths[0],
				"%s plays its one file as it is" % ONE_VERSION) and ok
	return ok


## The room: a button per event, played with the mouse, Enter and by name, on its bus.
func _room_plays_each_event(room_scene: PackedScene) -> bool:
	var room := room_scene.instantiate() as SoundRoom
	root.add_child(room)
	for i: int in SETTLE_FRAMES:
		await process_frame
	var ok := true
	var buttons := _event_buttons(room)
	ok = _report(buttons.size() == room.get_events().size(),
			"the room has a button per event (%d buttons, %d events)" % [buttons.size(),
			room.get_events().size()]) and ok
	ok = _report(buttons.size() > 0 and buttons[0].has_focus(),
			"the first event has the focus, for the keyboard") and ok
	# The mouse.
	var landing_button := _button_of(room, TWO_VERSIONS)
	if landing_button != null:
		landing_button.grab_focus()
		await process_frame
		_click(landing_button)
		await process_frame
		var player := room.get_player(TWO_VERSIONS)
		ok = _report(player != null and player.playing and player.bus == &"SFX"
				and player.stream is AudioStreamRandomizer,
				"a click plays %s at random, on SFX" % TWO_VERSIONS) and ok
	# Enter on the focused event.
	var jump_button := _button_of(room, ONE_VERSION)
	if jump_button != null:
		jump_button.grab_focus()
		await process_frame
		_press_action(&"ui_accept")
		await process_frame
		var player := room.get_player(ONE_VERSION)
		ok = _report(player != null and player.playing and player.bus == &"SFX",
				"Enter plays %s, on SFX" % ONE_VERSION) and ok
	# By name, and a loop pressed again.
	ok = _report(room.play_by_name(LOOPING), "%s plays by name" % LOOPING) and ok
	await process_frame
	var loop_player := room.get_player(LOOPING)
	ok = _report(loop_player != null and loop_player.playing, "%s plays" % LOOPING) and ok
	room.play_by_name(LOOPING)
	await process_frame
	ok = _report(loop_player != null and not loop_player.playing,
			"%s stops when pressed again" % LOOPING) and ok
	ok = _report(not room.play_by_name("no_such_sound"), "a name with no event plays nothing") and ok
	# Esc.
	room.play_by_name(TWO_VERSIONS)
	room.play_by_name(LOOPING)
	await process_frame
	_press_action(&"ui_cancel")
	await process_frame
	var still_playing: Array[String] = []
	for event_name: String in [TWO_VERSIONS, ONE_VERSION, LOOPING]:
		var player := room.get_player(event_name)
		if player != null and player.playing:
			still_playing.append(event_name)
	ok = _report(still_playing.is_empty(), "Esc stops everything (still playing: %s)" % [still_playing]) and ok
	# Search, and a letter typed on the list.
	var search := room.get_node("%Search") as LineEdit
	search.text = SEARCH_TEXT
	search.text_changed.emit(SEARCH_TEXT)
	await process_frame
	var shown: Array[String] = []
	for button: Button in buttons:
		if button.visible:
			shown.append(button.text.get_slice(" ", 0))
	ok = _report(shown == [TWO_VERSIONS], "Search \"%s\" keeps only %s (got %s)" % [SEARCH_TEXT,
			TWO_VERSIONS, shown]) and ok
	search.text = ""
	search.text_changed.emit("")
	await process_frame
	buttons[0].grab_focus()
	await process_frame
	var key := InputEventKey.new()
	key.pressed = true
	key.unicode = TYPED_LETTER.unicode_at(0)
	key.keycode = OS.find_keycode_from_string(TYPED_LETTER.to_upper())
	root.push_input(key)
	await process_frame
	ok = _report(search.has_focus() and search.text == TYPED_LETTER,
			"a letter typed on the list goes to Search (text \"%s\")" % search.text) and ok
	await _free_room(room)
	return ok


## Stops the room's sounds and frees it once the audio server has let go of them, so nothing is
## left in use at exit. The server lets go in its own thread, in real time, and the frames of a
## headless run take far less than their 1/60 s, so it waits real time.
func _free_room(room: SoundRoom) -> void:
	room.stop_all()
	var until := Time.get_ticks_msec() + AUDIO_RELEASE_MS
	while Time.get_ticks_msec() < until:
		await process_frame
	room.queue_free()
	for i: int in SETTLE_FRAMES:
		await process_frame


## The table in the room's Inspector picks the bus: with sfx sent to UI, an sfx event plays on UI.
func _table_picks_the_bus(room_scene: PackedScene) -> bool:
	var room := room_scene.instantiate() as SoundRoom
	room.bus_by_folder = OTHER_TABLE
	root.add_child(room)
	await process_frame
	var played := room.play_by_name(TWO_VERSIONS)
	var player := room.get_player(TWO_VERSIONS)
	var ok := _report(played and player != null and player.bus == &"UI",
			"with sfx sent to UI in Bus By Folder, %s plays on UI" % TWO_VERSIONS)
	await _free_room(room)
	return ok


func _event_with_key(events: Array[SoundCatalog.Event], key: String) -> SoundCatalog.Event:
	for event: SoundCatalog.Event in events:
		if event.get_key() == key:
			return event
	return null


## The room's event buttons, in the order of its list.
func _event_buttons(room: SoundRoom) -> Array[Button]:
	var buttons: Array[Button] = []
	for child: Node in room.get_node("%List").get_children():
		if child is Button and not child.is_queued_for_deletion():
			buttons.append(child as Button)
	return buttons


## The button of the event called Event Name.
func _button_of(room: SoundRoom, event_name: String) -> Button:
	var events := room.get_events()
	var buttons := _event_buttons(room)
	for index: int in mini(events.size(), buttons.size()):
		if events[index].name == event_name:
			return buttons[index]
	return null


## A left click, pressed and let go, at the middle of Button.
func _click(button: Button) -> void:
	var at := button.get_global_rect().get_center()
	for pressed: bool in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		click.position = at
		click.global_position = at
		root.push_input(click)


## An action pressed and let go, as a key of the Input Map does.
func _press_action(action: StringName) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		root.push_input(event)


func _report(passed: bool, what: String) -> bool:
	print("%s: %s" % ["PASS" if passed else "FAIL", what])
	return passed


func _finish(results: Array[bool]) -> void:
	quit(0 if not results.has(false) else 1)
