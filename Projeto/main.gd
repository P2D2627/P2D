extends Node

## The game's root scene, loaded for as long as the game runs. It shows the main menu, puts the
## level the player picks into the level slot, and pauses and resumes it. The menus only say what
## was chosen, through their signals, and this script decides what happens. The scene runs Main
## while the game is paused (process mode Always), so Esc can resume it; the level slot is the part
## that pauses. When the player walks into a phase's exit, the next phase takes the level's place
## behind a fade to black, and so does the phase an accepted shortcut leads to, with the man at its
## ArrivalPoint. An exit with no next phase ends the level, back to the main menu. Reaching the end of a phase is the game's checkpoint: a new game, each
## phase change and each SavePoint save, the Save Indicator says so, and the menu's Continue comes
## back there. Until the next save, what the man does is as if he had not done it: a death starts
## the phase over from the save, not only the level but GameState too. An accepted upgrade is the
## exception: it can never be taken back, so it saves at once. A level that does not start the game
## plays outside the run, with nothing saved and nothing put back.
## The run's numbers (RunStats: deaths, time) are the other exception, the other way: a death must
## count, so they are never put back on a death. They are written beside the save on each save, on
## each death, and on leaving for the menu or quitting; Continue reads them, and a new game empties
## them.

## The levels the main menu offers, in this order: each one a title and a scene. One left empty, or
## with no scene, stays out of the menu, with a warning.
@export var levels: Array[LevelEntry] = []
## Whether a level pauses when the game's window loses the focus, as with Alt+Tab.
@export var pause_on_focus_loss: bool = true
## The time the screen takes to go black at a phase's exit, and again to come back in the next one.
@export_range(0.0, 2.0, 0.05, "suffix:s") var fade_time: float = 0.25

## The levels the menu shows, in its order: those in levels that have a scene.
var _playable_levels: Array[LevelEntry] = []
## True from a phase's exit until the next phase has faded in. Meanwhile the level is frozen and the
## game does not pause.
var _changing_phase: bool = false
## The game's save.
var _save_file: SaveFile = SaveFile.new()
## True while the level in the slot is part of the saved game: from a new game or from Continue.
var _in_the_run: bool = false

@onready var _level_slot: Node = %LevelSlot
@onready var _main_menu: MainMenu = %MainMenu
@onready var _pause_menu: PauseMenu = %PauseMenu
@onready var _fade: ColorRect = %Fade
@onready var _save_indicator: SaveIndicator = %SaveIndicator
@onready var _progress: GameProgress = get_node(^"/root/GameState") as GameProgress
@onready var _offers: GameOffers = get_node_or_null(^"/root/Offers") as GameOffers
@onready var _run_stats: GameRunStats = get_node_or_null(^"/root/RunStats") as GameRunStats


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
	_main_menu.continue_requested.connect(_on_continue_requested)
	_main_menu.new_game_confirmed.connect(_play_level)
	_main_menu.quit_requested.connect(_on_quit_requested)
	_pause_menu.resume_requested.connect(_resume)
	_pause_menu.main_menu_requested.connect(_on_main_menu_requested)
	_progress.upgrade_granted.connect(_on_upgrade_granted)
	if _offers != null:
		_offers.scene_requested.connect(_on_offer_scene_requested)
		# Deferred, so whoever marks the talk as had on the same answer does it before the save.
		_offers.accepted.connect(_on_offer_answered.bind(true), CONNECT_DEFERRED)
		_offers.refused.connect(_on_offer_answered.bind(false), CONNECT_DEFERRED)
	else:
		push_warning("Main: no autoload Offers, so no offer can change the phase.")
	_main_menu.set_can_continue(_save_file.exists())


## The Pause action, Esc or Start, pauses a running level and resumes a paused one.
func _unhandled_input(event: InputEvent) -> void:
	if _has_level() and not _changing_phase and event.is_action_pressed(&"pause"):
		if get_tree().paused:
			_resume()
		else:
			_pause()
		get_viewport().set_input_as_handled()


## Closing the window keeps the run's numbers, as Quit does.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_the_run()
	if (what == NOTIFICATION_APPLICATION_FOCUS_OUT and pause_on_focus_loss and _has_level()
			and not _changing_phase and not get_tree().paused):
		_pause()


## The level goes in before the menu hides, so a level that fails to load leaves the menu on screen.
func _on_level_chosen(index: int) -> void:
	if _playable_levels[index].starts_game and _save_file.exists():
		_main_menu.ask_to_replace_save(index)
	else:
		_play_level(index)


## A level that starts the game is a new run: the state starts over, and so does the save.
func _play_level(index: int) -> void:
	var entry: LevelEntry = _playable_levels[index]
	_in_the_run = entry.starts_game
	if _in_the_run:
		_progress.reset()
		if _run_stats != null:
			_run_stats.reset()
	_progress.arrival_point = &""
	_start_level(entry.scene)
	_main_menu.hide()
	if _save(entry.scene.resource_path):
		_save_indicator.show_saved()


## Back to the saved phase, with the state as it was saved. A save that went bad since the menu
## opened takes Continue away and leaves the menu on screen.
func _on_continue_requested() -> void:
	var saved: Dictionary = _save_file.read()
	if saved.is_empty():
		_main_menu.set_can_continue(false)
		return
	_in_the_run = true
	_progress.from_save(saved["state"])
	if _run_stats != null:
		_run_stats.from_save(_save_file.read_run())
	_start_level(load(saved["scene"]) as PackedScene)
	_main_menu.hide()


## True once the phase at scene_path and the state are on disk. Outside the run, nothing is saved.
func _save(scene_path: String) -> bool:
	if not (_in_the_run and _save_file.write(scene_path, _progress.to_save())):
		return false
	_save_the_run()
	return true


## The run's numbers on disk, beside the save; outside the run, nothing.
func _save_the_run() -> void:
	if _in_the_run and _run_stats != null:
		_save_file.write_run(_run_stats.to_save())


## A save point of the level in the slot was reached.
func _on_save_point_reached() -> void:
	_save_the_current_phase()


## A debug key put the level at a phase, as if he had reached its save point: the save keeps that,
## so the restart that follows, which goes back to the save, brings him there. The level only jumps
## while it runs, so never while a phase change holds it frozen.
func _on_level_jumped_to_phase(_phase: int) -> void:
	_save_the_current_phase()


## An upgrade can never be taken back, so the save keeps it at once: a death before the next
## checkpoint does not undo it. In a phase change, the next phase's save keeps it.
func _on_upgrade_granted(_id: StringName) -> void:
	if not _changing_phase:
		_save_the_current_phase()


## An answer to an offer is a decision, and a decision is kept at once: quitting after it does not
## bring the talk back. An accepted offer with an effect is kept when the effect comes, after the
## lines, by the upgrade's save or the next phase's: kept before, a quit in between would keep the
## yes without what it gives. In a phase change, the next phase's save keeps it.
func _on_offer_answered(offer: OfferData, accepted: bool) -> void:
	if accepted and offer.effect != null:
		return
	if not _changing_phase:
		_save_the_current_phase()


## Saves the phase in the level slot, as it stands; with no level there, nothing.
func _save_the_current_phase() -> void:
	for level: Node in _level_slot.get_children():
		if _save(level.scene_file_path):
			_save_indicator.show_saved()


## A new copy of scene in the level slot. When it asks to start over, another new copy takes its
## place at the end of that frame, so nothing of it runs after its own signal (ADR 0026). A level
## without the Level script at its root can't ask, and the warning says so.
func _start_level(scene: PackedScene) -> void:
	var level: Node = scene.instantiate()
	_place_at_the_arrival(level)
	if level is Level:
		(level as Level).restart_requested.connect(_restart_level.bind(level, scene),
				CONNECT_DEFERRED)
		(level as Level).jumped_to_phase.connect(_on_level_jumped_to_phase)
	else:
		push_warning("Main: %s has no Level script at its root, so it never starts over."
				% scene.resource_path)
	_add_level(level)


## Before level joins the tree, puts its player on the ArrivalPoint GameState names, so the camera
## starts there too. With no point named, he stays at the phase's start; with one the phase lacks,
## too, with a warning.
func _place_at_the_arrival(level: Node) -> void:
	var arrival: StringName = _progress.arrival_point
	if arrival.is_empty() or not level is Level:
		return
	var player: Player = (level as Level).player
	var point: ArrivalPoint = ArrivalPoint.find_in(level, arrival)
	if point == null or player == null:
		push_warning("Main: %s has no ArrivalPoint %s, so he starts at the phase's start."
				% [level.scene_file_path, arrival])
		return
	if player.get_parent() != level:
		push_warning("Main: the player of %s is not a child of its root, so he starts at the start."
				% level.scene_file_path)
		return
	player.position = point.position_in(level)


## Only while level is still in the slot: had Main Menu taken it out on the same frame, a level
## would come back behind the menu.
func _restart_level(level: Node, scene: PackedScene) -> void:
	if not is_instance_valid(level) or level.get_parent() != _level_slot:
		return
	_clear_level()
	# The death counts: the numbers go to disk before the save puts the rest back.
	_save_the_run()
	_go_back_to_the_save()
	_start_level(scene)


## What the man did since the save is as if he had not done it.
func _go_back_to_the_save() -> void:
	if not _in_the_run:
		return
	var saved: Dictionary = _save_file.read()
	if not saved.is_empty():
		_progress.from_save(saved["state"])


## The next phase starts loading on another thread as the screen goes black, and is usually loaded
## before it is; if not, the wait happens on the black screen. The level is frozen meanwhile, so the
## player does not move unseen; at the end of the physics step, because the exit says it was reached
## from inside one, and the engine does not let collisions be switched off there. A path that cannot
## load leaves the player in the current phase.
func _on_phase_exit_reached(next_scene_path: String) -> void:
	if next_scene_path.is_empty():
		_finish_level()
	else:
		_change_phase(next_scene_path, &"")


## The level's last exit: behind the fade to black, the level goes and the main menu comes back. The
## run's numbers are written first, and the save keeps what the end marked, as that the level is
## done.
func _finish_level() -> void:
	# Ended while the phase still fades in, as when its lines are skipped at once: it ends after.
	while _changing_phase:
		await get_tree().process_frame
	if not _has_level():
		return
	# What the level's end marked in GameState, as that it is done, is kept.
	_save_the_current_phase()
	_changing_phase = true
	_level_slot.set_deferred(&"process_mode", Node.PROCESS_MODE_DISABLED)
	await _fade_to(1.0)
	_save_the_run()
	_clear_level()
	_level_slot.process_mode = Node.PROCESS_MODE_PAUSABLE
	_main_menu.set_can_continue(_save_file.exists())
	_main_menu.open()
	await _fade_to(0.0)
	_changing_phase = false


## An accepted offer, as Lust's shortcut, takes him to the phase at scene_path, at its ArrivalPoint
## arrival, behind the same fade as a phase's exit.
func _on_offer_scene_requested(scene_path: String, arrival: StringName) -> void:
	_change_phase(scene_path, arrival)


## The phase at next_scene_path takes the current one's place, with the man at its ArrivalPoint
## arrival, or at its start if arrival is empty; the save then brings him back there.
func _change_phase(next_scene_path: String, arrival: StringName) -> void:
	if _changing_phase:
		return
	if ResourceLoader.load_threaded_request(next_scene_path) != OK:
		push_error("Main: the next phase, %s, cannot be loaded." % next_scene_path)
		return
	_changing_phase = true
	_level_slot.set_deferred(&"process_mode", Node.PROCESS_MODE_DISABLED)
	await _fade_to(1.0)
	var next: PackedScene = ResourceLoader.load_threaded_get(next_scene_path) as PackedScene
	var saved: bool = false
	if next == null:
		push_error("Main: the next phase, %s, is not a scene." % next_scene_path)
	else:
		_clear_level()
		_progress.arrival_point = arrival
		_start_level(next)
		saved = _save(next_scene_path)
	_level_slot.process_mode = Node.PROCESS_MODE_PAUSABLE
	if saved:
		_save_indicator.show_saved()
	await _fade_to(0.0)
	_changing_phase = false


func _on_quit_requested() -> void:
	_save_the_run()
	get_tree().quit()


func _on_main_menu_requested() -> void:
	_resume()
	_save_the_run()
	_clear_level()
	_main_menu.set_can_continue(_save_file.exists())
	_main_menu.open()


## Puts level in the slot and listens to the exits of its phases and to its save points.
func _add_level(level: Node) -> void:
	_level_slot.add_child(level)
	for node: Node in get_tree().get_nodes_in_group(PhaseExit.GROUP):
		if level.is_ancestor_of(node):
			(node as PhaseExit).reached.connect(_on_phase_exit_reached)
	for node: Node in get_tree().get_nodes_in_group(SavePoint.GROUP):
		if level.is_ancestor_of(node):
			(node as SavePoint).reached.connect(_on_save_point_reached)


## The level leaves the tree at once and is freed at the end of the frame, so the level that comes
## next never shares a frame with it. The offers waiting on it go too: a balloon is part of the
## level, and one freed half way never says its lines are over.
func _clear_level() -> void:
	for level: Node in _level_slot.get_children():
		_level_slot.remove_child(level)
		level.queue_free()
	if _offers != null:
		_offers.clear()


func _fade_to(alpha: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_fade, ^"color:a", alpha, fade_time)
	await tween.finished


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
