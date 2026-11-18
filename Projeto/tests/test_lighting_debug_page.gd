# Checks the lighting prototype through the debug overlay, with the real rig on level 1. The
# prototype puts no text of its own on the screen: its settings are on the overlay's lighting page.
# There, Ctrl+F10 (the dogs' ash) changes the rig's setting; on the numbers page, the same key does
# nothing to it. On the lighting page, Ctrl+F3 and Alt+F3 are the rig's, F3 alone turns the page,
# and F8 alone is not the rig's, so it goes on to the debug action. The page chosen with F3 stays
# when the level starts over. The rig keeps its settings in static variables, so a restart keeps
# them; the test puts back the ones it changes.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_lighting_debug_page.gd
extends "res://tests/support/player_test.gd"

const LightingRig := preload("res://scenes/levels/prototypes/lighting/lighting_rig.gd")

const PROTOTYPE_SCENE: String = "res://scenes/levels/prototypes/lighting/lighting_level1.tscn"
## Frames the rig gets to set itself up, which it does once the level is in the tree; it is ready
## well before this.
const SETUP_FRAMES: int = 120
## Frames for the overlay to write its text, which it does in _process.
const TEXT_FRAMES: int = 2


func _initialize() -> void:
	await process_frame
	var results: Array[bool] = []
	var prototype: Node = (load(PROTOTYPE_SCENE) as PackedScene).instantiate()
	root.add_child(prototype)
	var rig: LightingRig = await _rig_of(prototype)
	if rig == null:
		results.append(report(false, "The prototype's rig did not set itself up in %d frames"
				% SETUP_FRAMES))
	else:
		var overlay: DebugOverlay = prototype.find_child("DebugOverlay", true, false) as DebugOverlay
		results.append(_the_prototype_puts_no_text_of_its_own_on_the_screen(prototype))
		results.append(await _the_lighting_page_shows_the_rig_s_settings(overlay))
		results.append(_ctrl_f10_changes_the_rig_only_on_the_lighting_page(overlay))
		results.append(_the_f3_keys_on_the_lighting_page(overlay, rig))
		results.append(await _the_page_chosen_with_f3_stays_through_a_restart(prototype, overlay))
	prototype.queue_free()
	await process_frame
	finish(results)


func _the_prototype_puts_no_text_of_its_own_on_the_screen(prototype: Node) -> bool:
	var labels: PackedStringArray = []
	for child: Node in prototype.get_children():
		if child is CanvasLayer:
			for label: Node in child.find_children("*", "Label", true, false):
				labels.append(String(label.get_path()))
	return report(labels.is_empty(), "Prototype's own labels on the screen: %s" % [labels])


func _the_lighting_page_shows_the_rig_s_settings(overlay: DebugOverlay) -> bool:
	overlay.show_page(DebugOverlay.Page.LIGHTING)
	for _frame: int in TEXT_FRAMES:
		await process_frame
	var text: String = (overlay.get_node(^"%Label") as Label).text
	overlay.show_page(DebugOverlay.Page.HIDDEN)
	return report(text.begins_with("F1 mode:") and text.contains("Ctrl+F10 dogs' ash"),
			"Lighting page, first line: \"%s\"" % text.get_slice("\n", 0))


func _ctrl_f10_changes_the_rig_only_on_the_lighting_page(overlay: DebugOverlay) -> bool:
	var before: bool = LightingRig.dog_smoke_on
	overlay.show_page(DebugOverlay.Page.NUMBERS)
	_press_ctrl_f10()
	var on_numbers: bool = LightingRig.dog_smoke_on
	overlay.show_page(DebugOverlay.Page.LIGHTING)
	_press_ctrl_f10()
	var on_lighting: bool = LightingRig.dog_smoke_on
	overlay.show_page(DebugOverlay.Page.HIDDEN)
	LightingRig.dog_smoke_on = before
	return report(on_numbers == before and on_lighting != before,
			"Ctrl+F10, dogs' ash %s: on the numbers page %s, on the lighting page %s"
			% [before, on_numbers, on_lighting])


## On the lighting page: Ctrl+F3 is the rig's one air and Alt+F3 its painted shade, while F3 alone
## turns the page and changes neither. F8 alone is not the rig's, so it goes on to the debug action.
func _the_f3_keys_on_the_lighting_page(overlay: DebugOverlay, rig: LightingRig) -> bool:
	var fog_before: bool = LightingRig.fog_on
	var shade_before: bool = LightingRig.shade_on
	overlay.show_page(DebugOverlay.Page.LIGHTING)
	_press(KEY_F3, KEY_MASK_CTRL)
	var fog_changed: bool = LightingRig.fog_on != fog_before
	_press(KEY_F3, KEY_MASK_ALT)
	var shade_changed: bool = LightingRig.shade_on != shade_before
	LightingRig.fog_on = fog_before
	LightingRig.shade_on = shade_before
	_press(KEY_F3)
	var turned: bool = overlay.get_page() == DebugOverlay.Page.HIDDEN
	var f3_left_them: bool = LightingRig.fog_on == fog_before and LightingRig.shade_on == shade_before
	var f8_not_the_rig_s: bool = not rig.handle_debug_key(_key(KEY_F8, 0, true))
	return report(fog_changed and shade_changed and turned and f3_left_them and f8_not_the_rig_s,
			("Lighting page: Ctrl+F3 one air %s, Alt+F3 painted shade %s, F3 turns the page %s and "
			+ "leaves both %s, F8 not the rig's %s")
			% [fog_changed, shade_changed, turned, f3_left_them, f8_not_the_rig_s])


## The page chosen with F3 stays when the level starts over, as after a death: the prototype puts a
## new copy of the level in, with a new overlay, on the same page.
func _the_page_chosen_with_f3_stays_through_a_restart(prototype: Node,
		overlay: DebugOverlay) -> bool:
	overlay.show_page(DebugOverlay.Page.NUMBERS)
	_press(KEY_F3)
	var chosen: DebugOverlay.Page = overlay.get_page()
	(overlay.owner as Level).restart_requested.emit()
	var next: DebugOverlay = null
	for _frame: int in SETUP_FRAMES:
		await process_frame
		next = prototype.find_child("DebugOverlay", true, false) as DebugOverlay
		if next != null and next != overlay and next.is_node_ready():
			break
	var page: String = DebugOverlay.Page.find_key(next.get_page()) if next != null else "none"
	return report(chosen == DebugOverlay.Page.LIGHTING and next != overlay and page == "LIGHTING",
			"Restart: chosen %s, a new overlay %s, on %s" % [DebugOverlay.Page.find_key(chosen),
			next != overlay, page])


## The rig once it has set itself up; null if it has not in Setup Frames.
func _rig_of(prototype: Node) -> LightingRig:
	for _frame: int in SETUP_FRAMES:
		await process_frame
		var rig: LightingRig = prototype.find_child("LightingRig", true, false) as LightingRig
		if rig != null and rig.is_ready():
			return rig
	return null


func _press_ctrl_f10() -> void:
	_press(KEY_F10, KEY_MASK_CTRL)


## A press and release of keycode, with the modifiers in mask held, through the viewport.
func _press(keycode: Key, mask: int = 0) -> void:
	root.push_input(_key(keycode, mask, true))
	root.push_input(_key(keycode, mask, false))


func _key(keycode: Key, mask: int, pressed: bool) -> InputEventKey:
	var key: InputEventKey = InputEventKey.new()
	key.keycode = keycode
	key.physical_keycode = keycode
	key.ctrl_pressed = mask & KEY_MASK_CTRL != 0
	key.alt_pressed = mask & KEY_MASK_ALT != 0
	key.pressed = pressed
	return key
