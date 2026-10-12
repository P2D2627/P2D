extends Node

## The game's root scene, loaded for as long as the game runs. It shows the main menu, puts the
## level the player picks into the level slot, and pauses and resumes it. The menus only say what
## was chosen, through their signals, and this script decides what happens. The scene runs Main
## while the game is paused (process mode Always), so Esc can resume it; the level slot is the part
## that pauses.

## The levels the main menu offers, in this order: each one a title and a scene. One left empty, or
## with no scene, stays out of the menu, with a warning.
@export var levels: Array[LevelEntry] = []
## Whether a level pauses when the game's window loses the focus, as with Alt+Tab.
@export var pause_on_focus_loss: bool = true

## The levels the menu shows, in its order: those in levels that have a scene.
var _playable_levels: Array[LevelEntry] = []

@onready var _level_slot: Node = %LevelSlot
@onready var _main_menu: MainMenu = %MainMenu
@onready var _pause_menu: PauseMenu = %PauseMenu


func _ready() -> void:
	var titles: PackedStringArray = []
	for index: int in levels.size():
		var level: LevelEntry = levels[index]
		if level == null or level.scene == null:
			push_warning("Main: entry %d of Levels has no scene, so the menu leaves it out." % index)
			continue
		_playable_levels.append(level)
		titles.append(level.title)
	_main_menu.add_levels(titles)
	_main_menu.level_chosen.connect(_on_level_chosen)
	_main_menu.quit_requested.connect(_on_quit_requested)
	_pause_menu.resume_requested.connect(_resume)
	_pause_menu.main_menu_requested.connect(_on_main_menu_requested)


## The Pause action, Esc or Start, pauses a running level and resumes a paused one.
func _unhandled_input(event: InputEvent) -> void:
	if _has_level() and event.is_action_pressed(&"pause"):
		if get_tree().paused:
			_resume()
		else:
			_pause()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if (what == NOTIFICATION_APPLICATION_FOCUS_OUT and pause_on_focus_loss and _has_level()
			and not get_tree().paused):
		_pause()


## The level goes in before the menu hides, so a level that fails to load leaves the menu on screen.
func _on_level_chosen(index: int) -> void:
	_level_slot.add_child(_playable_levels[index].scene.instantiate())
	_main_menu.hide()


func _on_quit_requested() -> void:
	get_tree().quit()


## The level leaves the tree at once and is freed at the end of the frame, so a level chosen next
## never shares a frame with it.
func _on_main_menu_requested() -> void:
	_resume()
	for level: Node in _level_slot.get_children():
		_level_slot.remove_child(level)
		level.queue_free()
	_main_menu.open()


func _pause() -> void:
	get_tree().paused = true
	_pause_menu.open()


## The game comes back on the next frame, not on this one. Resume and B fire on the frame their key
## comes up, which on a quick tap is also the frame it went down, and Jump and Interact read as just
## pressed all through that frame: the player would jump, or interact, as the game came back.
func _resume() -> void:
	_pause_menu.hide()
	get_tree().set_deferred(&"paused", false)


func _has_level() -> bool:
	return _level_slot.get_child_count() > 0
