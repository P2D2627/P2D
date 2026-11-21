# Checks the debug key that switches the camera (#282). Debug Camera Next is F10 in the Input Map, and F10 is
# reserved, so no action of the game can take it. In a debug build, F10 goes to the camera's next way of framing
# the man (its own, each CameraBrain child, its own again), also with the overlay's text hidden, and the numbers
# page names the way in use on a line of its own, above the camera's usual line. The way chosen stays in the
# next copy of the level, as after a death: its new overlay gives it to its new camera. The balloon of the lines
# lets F10 through, as the other debug keys. Outside debug builds the overlay frees itself and F10 leaves the
# camera as it was.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_debug_camera_switch.gd
extends "res://tests/support/player_test.gd"

const CAMERA_SCENE: PackedScene = preload("res://scenes/others/camera/game_camera.tscn")
const OVERLAY_SCENE: PackedScene = preload("res://scenes/others/debug/debug_overlay.tscn")
const BALLOON_PATH: String = "res://scenes/screens/dialogue_balloon.tscn"
const START: Vector2 = Vector2(0.0, -2.0)
const ACTION: StringName = &"debug_camera_next"
const BRAIN_NAME: String = "StandIn"
const SETTLE_FRAMES: int = 10

var _camera: GameCamera


## A brain that keeps the screen where it began.
class StandInBrain:
	extends CameraBrain

	var _centre: Vector2 = Vector2.ZERO
	var _zoom: float = 1.0

	func begin(_player: Player, _tiles: TileMapLayer, centre: Vector2, zoom_level: float) -> void:
		_centre = centre
		_zoom = zoom_level

	func advance(_delta: float) -> void:
		pass

	func get_centre() -> Vector2:
		return _centre

	func get_zoom() -> float:
		return _zoom


## The overlay as in a release export.
class ReleaseOverlay extends DebugOverlay:
	func _is_debug_build() -> bool:
		return false


func _initialize() -> void:
	await process_frame
	root.size = Vector2i(int(ProjectSettings.get_setting("display/window/size/viewport_width")),
			int(ProjectSettings.get_setting("display/window/size/viewport_height")))
	await process_frame
	make_platform(-4000.0, 4000.0)
	var results: Array[bool] = []
	var player: Player = await spawn_on_floor(START)
	if player == null:
		results.append(report(false, "The player never landed"))
		finish(results)
		return
	_camera = _new_camera(player)
	root.add_child(_camera)
	await wait_frames(SETTLE_FRAMES)
	results.append(_check_f10_is_the_reserved_key())
	results.append(await _check_f10_cycles_with_the_text_hidden(player))
	results.append(await _check_the_numbers_page_names_the_way(player))
	results.append(await _check_the_way_stays_in_the_next_copy(player))
	results.append(await _check_a_line_lets_f10_through())
	results.append(await _check_release_builds_ignore_f10(player))
	DebugOverlay.camera_mode = ""
	finish(results)


## A camera scene with the stand-in brain, for player.
func _new_camera(player: Player) -> GameCamera:
	var brain: StandInBrain = StandInBrain.new()
	brain.name = BRAIN_NAME
	var camera: GameCamera = CAMERA_SCENE.instantiate() as GameCamera
	camera.player = player
	camera.add_child(brain)
	return camera


func _check_f10_is_the_reserved_key() -> bool:
	var keys: Array[Key] = []
	if InputMap.has_action(ACTION):
		for event: InputEvent in InputMap.action_get_events(ACTION):
			if event is InputEventKey:
				keys.append((event as InputEventKey).physical_keycode)
	return report(keys == [KEY_F10] and InputProfiles.RESERVED_KEYS.has(KEY_F10),
			"Debug Camera Next is %s in the Input Map (expected F10), and F10 reserved: %s"
			% [keys, InputProfiles.RESERVED_KEYS.has(KEY_F10)])


## With the text hidden, F10 goes Zones, the brain, Zones.
func _check_f10_cycles_with_the_text_hidden(player: Player) -> bool:
	var overlay: DebugOverlay = await _spawn(player, DebugOverlay)
	var names: Array[String] = [_camera.get_framing_name()]
	for _press: int in 2:
		_press_key(KEY_F10)
		names.append(_camera.get_framing_name())
	await _remove(overlay)
	var expected: Array[String] = [GameCamera.OWN_FRAMING_NAME, BRAIN_NAME, GameCamera.OWN_FRAMING_NAME]
	return report(names == expected, "F10 with the text hidden goes %s (expected %s)" % [names, expected])


## The numbers page has a line with the way in use and F10, and keeps the camera's usual line.
func _check_the_numbers_page_names_the_way(player: Player) -> bool:
	var overlay: DebugOverlay = await _spawn(player, DebugOverlay)
	overlay.show_page(DebugOverlay.Page.NUMBERS)
	await process_frame
	var own_text: String = _text(overlay)
	_press_key(KEY_F10)
	await process_frame
	var brain_text: String = _text(overlay)
	_press_key(KEY_F10)
	await _remove(overlay)
	var usual: RegEx = RegEx.create_from_string(
			"(?m)^camera zone \\S+   look ahead [+-]\\d+ px   look down [+-]\\d+ px$")
	var shows_own: bool = own_text.contains("camera mode %s   (F10: next)" % GameCamera.OWN_FRAMING_NAME)
	var shows_brain: bool = brain_text.contains("camera mode %s   (F10: next)" % BRAIN_NAME)
	return report(shows_own and shows_brain and usual.search(own_text) != null,
			"The numbers page names the way: own %s, brain %s, usual line kept %s"
			% [shows_own, shows_brain, usual.search(own_text) != null])


## F10 picks the brain; the level starts over as a new copy, with a new camera and a new overlay, added in the
## level's order (camera first, overlay after, as in level 1), and the new camera frames the man with the brain
## too. Back to the camera's own way, the next copy keeps that.
func _check_the_way_stays_in_the_next_copy(player: Player) -> bool:
	DebugOverlay.camera_mode = ""
	var overlay: DebugOverlay = await _spawn(player, DebugOverlay)
	_press_key(KEY_F10)
	var chosen: String = DebugOverlay.camera_mode
	await _remove(overlay)
	var next_camera: GameCamera = _new_camera(player)
	root.add_child(next_camera)
	var next_overlay: DebugOverlay = OVERLAY_SCENE.instantiate() as DebugOverlay
	next_overlay.start_visible = false
	next_overlay.player = player
	next_overlay.camera = next_camera
	root.add_child(next_overlay)
	await process_frame
	await process_frame
	var kept: String = next_camera.get_framing_name()
	_press_key(KEY_F10)
	await _remove(next_overlay)
	next_camera.queue_free()
	_camera.use_framing(GameCamera.OWN_FRAMING_NAME)
	await process_frame
	return report(chosen == BRAIN_NAME and kept == BRAIN_NAME
			and DebugOverlay.camera_mode == GameCamera.OWN_FRAMING_NAME,
			"F10 picks %s, the next copy's camera frames with %s, and F10 there goes back to %s"
			% [chosen, kept, DebugOverlay.camera_mode])


## With a line on screen the balloon gets the keys before the overlay, and lets Debug Camera Next through.
func _check_a_line_lets_f10_through() -> bool:
	var balloon: DialogueBalloon = (load(BALLOON_PATH) as PackedScene).instantiate() as DialogueBalloon
	root.add_child(balloon)
	var lets_through: bool = balloon.lets_through.has(DebugOverlay.CAMERA_NEXT_ACTION)
	balloon.queue_free()
	await process_frame
	return report(lets_through, "A line lets F10 through: %s" % lets_through)


## Outside debug builds the overlay is gone, and F10 leaves the camera on its own way.
func _check_release_builds_ignore_f10(player: Player) -> bool:
	var overlay: DebugOverlay = await _spawn(player, ReleaseOverlay)
	var freed: bool = not is_instance_valid(overlay)
	_press_key(KEY_F10)
	var untouched: bool = _camera.get_framing_name() == GameCamera.OWN_FRAMING_NAME
	if not freed:
		await _remove(overlay)
	return report(freed and untouched, "Release build: overlay freed %s, camera still on %s"
			% [freed, _camera.get_framing_name()])


## An overlay with the text hidden, linked to the man and the camera, with script in place of its own.
func _spawn(player: Player, script: GDScript) -> DebugOverlay:
	var overlay: DebugOverlay = OVERLAY_SCENE.instantiate() as DebugOverlay
	if script != DebugOverlay:
		overlay.set_script(script)
	overlay.start_visible = false
	overlay.player = player
	overlay.camera = _camera
	root.add_child(overlay)
	await process_frame
	await process_frame
	return overlay


func _remove(overlay: DebugOverlay) -> void:
	overlay.queue_free()
	await process_frame


func _text(overlay: DebugOverlay) -> String:
	return (overlay.get_node(^"%Label") as Label).text


func _press_key(keycode: Key) -> void:
	root.push_input(_key_event(keycode, true))
	root.push_input(_key_event(keycode, false))


func _key_event(keycode: Key, pressed: bool) -> InputEventKey:
	var key: InputEventKey = InputEventKey.new()
	key.keycode = keycode
	key.physical_keycode = keycode
	key.pressed = pressed
	return key
