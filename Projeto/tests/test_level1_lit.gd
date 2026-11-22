# Holds level 1's approved look in the game (ADR 0068): the lighting prototype, fenced in. The menu's
# New Game starts level1_lit.tscn, which is level1.tscn with the lighting rig as its last child. It
# runs with no errors; the rig's settings are the approved ones; the rig builds in it what it builds
# in the prototype's own scene (lighting_level1.tscn), where the look was approved: the same nodes,
# drawn in the same order, at the same depth; and when the level starts over through Main, as after
# a death, the new copy has its rig again, set up, with the settings as they were. That the rig's
# keys work only on the debug overlay's lighting page is test_lighting_debug_page.gd's.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_level1_lit.gd
extends "res://tests/support/menu_test.gd"

const LightingRig := preload("res://scenes/levels/prototypes/lighting/lighting_rig.gd")

const LIT_SCENE: String = "res://scenes/levels/lust/level1_lit.tscn"
const PLAIN_SCENE: String = "res://scenes/levels/lust/level1.tscn"
const PROTOTYPE_SCENE: String = "res://scenes/levels/prototypes/lighting/lighting_level1.tscn"
## Lust's shortcut, which takes him from the level to the tent at its end.
const SHORTCUT: StringName = &"lust_shortcut"
## Where the shortcut's case saves, so the player's save is never touched.
const SAVE_TEST_PATH: String = "user://test_level1_lit.cfg"
## Frames the shortcut gets to fade out and bring in the next copy of the level.
const SHORTCUT_FRAMES: int = 600
## Frames the rig gets to set itself up, which it does once the level is in the tree; it is ready
## well before this.
const SETUP_FRAMES: int = 120
## Frames the level runs once the rig is set up, before its errors are counted and its nodes
## compared.
const RUN_FRAMES: int = 60
## The rig's settings as they were approved, played on 18/11 (#263, #266): mode A with the glow, the
## grade, the fires' ramp, one air, the rim light, the scene's light on the man, his outline, depth,
## the ink style, the crucifix's light, the squash and the soul trail; off, what was played and
## turned down: the vision masks, the blur of what he does not see, the rocks in front, his contact
## shadow, the dogs' ash and the fires in the background.
const APPROVED: Dictionary[StringName, Variant] = {
	&"mode": LightingRig.Mode.HYBRID,
	&"glow_on": true,
	&"shade_on": true,
	&"vision": LightingRig.VISION_OFF,
	&"unseen_blur_on": false,
	&"softness_step": 1,
	&"ambient": 0.35,
	&"man_radius": 900.0,
	&"depth_on": true,
	&"foreground_on": false,
	&"grade_on": false,
	&"fire_ramp_on": true,
	&"fog_on": true,
	&"rim_on": true,
	&"scene_light_on": true,
	&"outline_on": false,
	&"shadow_on": false,
	&"trail": LightingRig.TRAIL_SOUL,
	&"ink_on": true,
	&"crucifix_fx_on": true,
	&"dog_smoke_on": false,
	&"squash_on": true,
	&"background_fires_on": false,
}

var _errors: ErrorCounter = ErrorCounter.new()


func _initialize() -> void:
	OS.add_logger(_errors)
	await process_frame
	var results: Array[bool] = []
	results.append(await _new_game_starts_level_1_with_the_light())
	results.append(_the_lit_level_is_level_1_with_the_rig_last())
	results.append(_the_rig_s_settings_are_the_approved_ones())
	results.append(_the_lit_level_counts_as_level_1_in_the_run())
	results.append(await _it_runs_with_no_errors_and_builds_what_the_prototype_builds())
	results.append(await _a_restart_through_main_brings_the_rig_back_with_its_settings())
	results.append(await _lust_s_shortcut_keeps_the_light_and_saves_the_lit_level())
	OS.remove_logger(_errors)
	finish(results)


## Of the main scene's levels, the one that starts the game, the one New Game plays, is the lit one.
func _new_game_starts_level_1_with_the_light() -> bool:
	var main: Node = (await main_scene()).instantiate()
	var starts: Array[String] = []
	for entry: LevelEntry in main.get(&"levels") as Array[LevelEntry]:
		if entry != null and entry.starts_game and entry.in_menu and entry.scene != null:
			starts.append(entry.scene.resource_path)
	main.free()
	return report(starts == [LIT_SCENE], "The levels that start the game: %s" % [starts])


## The lit level is level 1 itself, the same root and children in the same order, with the rig added
## as the last child, so the rig sets itself up after the whole level, as in the prototype.
func _the_lit_level_is_level_1_with_the_rig_last() -> bool:
	var lit: Node = (load(LIT_SCENE) as PackedScene).instantiate()
	var plain: Node = (load(PLAIN_SCENE) as PackedScene).instantiate()
	var lit_names: Array[StringName] = []
	for child: Node in lit.get_children():
		lit_names.append(child.name)
	var plain_names: Array[StringName] = []
	for child: Node in plain.get_children():
		plain_names.append(child.name)
	var last: Node = lit.get_child(-1) if lit.get_child_count() > 0 else null
	var rig_last: bool = last != null and last.name == &"LightingRig" and last.get_script() == LightingRig
	var same_level: bool = (lit is Level and lit.name == plain.name
			and lit_names.slice(0, -1) == plain_names)
	lit.free()
	plain.free()
	return report(same_level and rig_last,
			"Lit level: level 1's root and children %s, the rig last %s" % [same_level, rig_last])


func _the_rig_s_settings_are_the_approved_ones() -> bool:
	var now: Dictionary[StringName, Variant] = _rig_settings()
	var differ: Array[String] = []
	for setting: StringName in APPROVED:
		if now[setting] != APPROVED[setting]:
			differ.append("%s %s (approved %s)" % [setting, now[setting], APPROVED[setting]])
	return report(differ.is_empty(), "The rig's settings that are not the approved ones: %s"
			% [differ])


## The lit level, and then the prototype's own scene, each run until the rig is set up and a little
## more. The lit level logs no error, and the rig leaves the same nodes in both.
func _it_runs_with_no_errors_and_builds_what_the_prototype_builds() -> bool:
	_errors.clear()
	var lit: Node = (load(LIT_SCENE) as PackedScene).instantiate()
	root.add_child(lit)
	# Each verdict on a node is taken while it is in the tree: once freed, it can no longer be told
	# from null.
	var lit_rig: LightingRig = await _rig_in(lit)
	var lit_set_up: bool = lit_rig != null
	await wait_frames(RUN_FRAMES)
	var errors: PackedStringArray = _errors.take()
	var lit_nodes: Array[String] = _nodes_of(lit)
	lit.queue_free()
	await process_frame
	var prototype: Node = (load(PROTOTYPE_SCENE) as PackedScene).instantiate()
	root.add_child(prototype)
	var prototype_rig: LightingRig = await _rig_in(prototype)
	var prototype_set_up: bool = prototype_rig != null
	await wait_frames(RUN_FRAMES)
	var prototype_level: Node = prototype_rig.get_parent() if prototype_set_up else null
	var prototype_nodes: Array[String] = _nodes_of(prototype_level)
	prototype.queue_free()
	await process_frame
	var both_set_up: bool = lit_set_up and prototype_set_up
	var same: bool = lit_nodes == prototype_nodes
	var first_difference: String = ""
	for index: int in mini(lit_nodes.size(), prototype_nodes.size()):
		if lit_nodes[index] != prototype_nodes[index]:
			first_difference = "at %d, lit %s, prototype %s" % [index, lit_nodes[index],
					prototype_nodes[index]]
			break
	return report(both_set_up and errors.is_empty() and same and not lit_nodes.is_empty(),
			("Lit level: rigs set up %s; errors %s; the same %d nodes as the prototype's %d %s %s")
			% [both_set_up, errors, lit_nodes.size(), prototype_nodes.size(), same,
			first_difference])


## Through Main, with the lit level as the menu's only level, outside the run, so nothing is saved:
## a setting changed before the restart is still the same after it, and the new copy's rig, set up
## again, shows it.
func _a_restart_through_main_brings_the_rig_back_with_its_settings() -> bool:
	var entry: LevelEntry = LevelEntry.new()
	entry.title = "Level 1, lit"
	entry.scene = load(LIT_SCENE) as PackedScene
	var levels: Array[LevelEntry] = [entry]
	var main: Node = await new_main(levels)
	(main.get_node(^"%MainMenu") as MainMenu).level_chosen.emit(0)
	var first: Node = level_in(main)
	var first_rig: LightingRig = null
	if first != null:
		first_rig = await _rig_in(first)
	var first_set_up: bool = first_rig != null
	var glow_before: bool = LightingRig.glow_on
	LightingRig.glow_on = not glow_before
	if first is Level:
		(first as Level).restart_requested.emit()
	var next: Node = null
	for _frame: int in SETUP_FRAMES:
		await process_frame
		next = level_in(main)
		if next != null and next != first:
			break
	var is_new: bool = next != null and next != first
	var next_rig: LightingRig = null
	if is_new:
		next_rig = await _rig_in(next)
	var next_set_up: bool = next_rig != null
	await wait_frames(2)
	var glow_shown: Variant = _glow_shown_in(next) if is_new else null
	var path: String = next.scene_file_path if is_new and is_instance_valid(next) else ""
	var kept: bool = LightingRig.glow_on != glow_before
	LightingRig.glow_on = glow_before
	await remove_main(main)
	return report(first_set_up and next_set_up and path == LIT_SCENE and kept
			and glow_shown == (not glow_before),
			("Restart through Main: first rig %s, a new lit copy %s with its rig %s, the glow setting "
			+ "kept %s and shown %s") % [first_set_up, path == LIT_SCENE, next_set_up, kept,
			glow_shown])


## RunStats files deaths and times by the level's run id, and a new id starts the level's numbers
## over and opens its death offers again. The lit level is level 1, so its id is the plain level's:
## a run that goes from one to the other, as an old save's Continue and then the shortcut, keeps
## its numbers and keeps the offers closed once he took the shortcut.
func _the_lit_level_counts_as_level_1_in_the_run() -> bool:
	var ids: Array[StringName] = []
	for path: String in [PLAIN_SCENE, LIT_SCENE]:
		var level: Level = (load(path) as PackedScene).instantiate() as Level
		ids.append(level.get_run_id() if level != null else &"(not a Level)")
		if level != null:
			level.free()
	return report(ids[0] == ids[1], "Run ids, plain and lit: %s" % [ids])


## In a new game on the lit level, Lust's shortcut, accepted with no balloon showing, takes him to
## the lit level again, at the tent, with its rig set up, and the save holds the lit level, so
## Continue brings the light back too. The save goes to a test file, deleted before and after.
func _lust_s_shortcut_keeps_the_light_and_saves_the_lit_level() -> bool:
	var progress: GameProgress = root.get_node(^"GameState") as GameProgress
	var offers: GameOffers = root.get_node(^"Offers") as GameOffers
	var default_save_path: String = SaveFile.default_path
	SaveFile.default_path = SAVE_TEST_PATH
	_delete_test_save()
	progress.reset()
	offers.clear()
	var entry: LevelEntry = LevelEntry.new()
	entry.title = "Level 1, lit"
	entry.scene = load(LIT_SCENE) as PackedScene
	entry.starts_game = true
	var levels: Array[LevelEntry] = [entry]
	var main: Node = await new_main(levels)
	await tap(KEY_ENTER)
	await tap(KEY_ENTER)
	var first: Node = level_in(main)
	var first_rig: LightingRig = await _rig_in(first) if first != null else null
	var first_set_up: bool = first_rig != null
	offers.accept(SHORTCUT)
	var next: Node = null
	for _frame: int in SHORTCUT_FRAMES:
		await process_frame
		next = level_in(main)
		if next != null and next != first:
			break
	var moved: bool = next != null and next != first
	var path: String = next.scene_file_path if moved else ""
	var next_rig: LightingRig = await _rig_in(next) if moved else null
	var next_set_up: bool = next_rig != null
	var saved: Dictionary = SaveFile.new().read()
	var saved_path: String = saved.get("scene", "")
	await remove_main(main)
	progress.reset()
	offers.clear()
	_delete_test_save()
	SaveFile.default_path = default_save_path
	return report(first_set_up and path == LIT_SCENE and next_set_up and saved_path == LIT_SCENE,
			("Lust's shortcut from the lit level: first rig %s; it goes to %s with its rig %s; the save "
			+ "holds %s") % [first_set_up, path, next_set_up, saved_path])


## The case's save, its copy and its run file go; global paths, as DirAccess needs them.
func _delete_test_save() -> void:
	var save: SaveFile = SaveFile.new()
	for path: String in [save.path, save.path + SaveFile.COPY_SUFFIX, save.get_run_path()]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## The rig's settings, as the APPROVED table names them.
func _rig_settings() -> Dictionary[StringName, Variant]:
	return {
		&"mode": LightingRig.mode,
		&"glow_on": LightingRig.glow_on,
		&"shade_on": LightingRig.shade_on,
		&"vision": LightingRig.vision,
		&"unseen_blur_on": LightingRig.unseen_blur_on,
		&"softness_step": LightingRig.softness_step,
		&"ambient": LightingRig.ambient,
		&"man_radius": LightingRig.man_radius,
		&"depth_on": LightingRig.depth_on,
		&"foreground_on": LightingRig.foreground_on,
		&"grade_on": LightingRig.grade_on,
		&"fire_ramp_on": LightingRig.fire_ramp_on,
		&"fog_on": LightingRig.fog_on,
		&"rim_on": LightingRig.rim_on,
		&"scene_light_on": LightingRig.scene_light_on,
		&"outline_on": LightingRig.outline_on,
		&"shadow_on": LightingRig.shadow_on,
		&"trail": LightingRig.trail,
		&"ink_on": LightingRig.ink_on,
		&"crucifix_fx_on": LightingRig.crucifix_fx_on,
		&"dog_smoke_on": LightingRig.dog_smoke_on,
		&"squash_on": LightingRig.squash_on,
		&"background_fires_on": LightingRig.BACKGROUND_FIRES_ON,
	}


## The rig under node once it has set itself up; null if it has not in Setup Frames.
func _rig_in(node: Node) -> LightingRig:
	for _frame: int in SETUP_FRAMES:
		await process_frame
		if not is_instance_valid(node):
			return null
		var rig: LightingRig = node.find_child("LightingRig", true, false) as LightingRig
		if rig != null and rig.is_ready():
			return rig
	return null


## Whether the glow of the rig's environment under level is on; null with no environment.
func _glow_shown_in(level: Node) -> Variant:
	if level == null or not is_instance_valid(level):
		return null
	var found: Array[Node] = level.find_children("*", "WorldEnvironment", true, false)
	if found.is_empty() or (found[0] as WorldEnvironment).environment == null:
		return null
	return (found[0] as WorldEnvironment).environment.glow_enabled


## The nodes under level, in the tree's order, which is the order they are drawn in: each by class
## and name, and those that draw with their depth and whether they show. A name the engine made up
## (@Node2D@123) differs from one copy to the next, so it counts as its class alone.
func _nodes_of(level: Node) -> Array[String]:
	var nodes: Array[String] = []
	if level == null:
		return nodes
	for node: Node in level.find_children("*", "", true, false):
		var name_part: String = "" if String(node.name).begins_with("@") else String(node.name)
		var line: String = "%s %s" % [node.get_class(), name_part]
		if node is CanvasItem:
			line += " z%d %s" % [(node as CanvasItem).z_index, (node as CanvasItem).visible]
		elif node is CanvasLayer:
			line += " layer%d %s" % [(node as CanvasLayer).layer, (node as CanvasLayer).visible]
		nodes.append(line)
	return nodes


## Counts what the engine logs as an error, script and shader errors included; warnings do not
## count. The engine may log from any thread, so the list is locked.
class ErrorCounter extends Logger:
	var _mutex: Mutex = Mutex.new()
	var _errors: PackedStringArray = []

	func _log_error(_function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_WARNING:
			return
		_mutex.lock()
		_errors.append("%s:%d %s" % [file, line, rationale if not rationale.is_empty() else code])
		_mutex.unlock()

	func _log_message(_message: String, _error: bool) -> void:
		pass

	func clear() -> void:
		_mutex.lock()
		_errors.clear()
		_mutex.unlock()

	## The errors logged since the last clear, and a clear.
	func take() -> PackedStringArray:
		_mutex.lock()
		var taken: PackedStringArray = _errors.duplicate()
		_errors.clear()
		_mutex.unlock()
		return taken
