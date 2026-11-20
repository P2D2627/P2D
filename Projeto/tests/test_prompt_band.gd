# Checks the tutorial's prompts at the bottom of the screen. A PromptGlyph shows an action's key, or
# its pad button once the pad is the device used last, and goes back to the key with a key press.
# Every pad binding the prompts show has its picture; one with none keeps its name in a key. A
# KeyPrompt in the world follows the device used last too, also with a pad still connected. The
# PromptBand sits at the bottom centre, Bottom Gap above the edge, and its caption reads at 4.5:1 or
# better even over a white screen. With a band, the TutorialHints draw their hints there and not in
# the world, one at a time: the first one on screen that the man has not passed, each kept at least
# Min Show Time, and none once no hint is on screen. While Velvet talks the band hides. Level 1's
# tutorial has its band, which shows the Move hint where the man wakes.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_prompt_band.gd
extends "res://tests/support/base_test.gd"

const GLYPH_SCENE: PackedScene = preload("res://scenes/levels/prompt_glyph.tscn")
const BAND_SCENE: PackedScene = preload("res://scenes/levels/prompt_band.tscn")
const KEY_PROMPT_SCENE: PackedScene = preload("res://scenes/levels/key_prompt.tscn")
const LEVEL_1_PATH: String = "res://scenes/levels/lust/level1.tscn"
const SCREEN: Vector2i = Vector2i(1920, 1080)
## How far the band may be from where it should be, in px: the plate's size is rounded.
const PLACE_TOLERANCE: float = 1.0
## The least contrast of the caption against the plate, as WCAG asks of body text.
const MIN_CONTRAST: float = 4.5
## The hints of the made-up tutorial: x, the actions of their keys, the lines of their caption.
const HINT_A_X: float = 500.0
const HINT_B_X: float = 1500.0
## Off the screen, which starts at x 0 and is 1920 px wide with no camera.
const HINT_C_X: float = 3000.0
const HIDE_MARGIN: float = 300.0
const MIN_SHOW_TIME: float = 0.5
## Physics frames, at 60 per second, against the 0.5 s of Min Show Time: 5 is well short of it, 40
## well past it.
const SHORT_WAIT: int = 5
const LONG_WAIT: int = 40
## Physics frames for the level's camera to settle on the man where he wakes.
const SETTLE_FRAMES: int = 30
## The plate's height: its margins of 12 px and a key of 56 px.
const PLATE_HEIGHT: float = 80.0
const LONG_CAPTION: String = "Demon ahead! Hold to raise the crucifix and drive it away"
## Process frames for the band's fade, of 0.25 s, to end, with room to spare.
const FADE_FRAMES: int = 30
## A hint on screen across but far below the view, which starts at y 0 and is 1080 px tall.
const HINT_D_X: float = 800.0
const HINT_D_Y: float = 5000.0
## The actions whose prompts the tutorial and Velvet show.
const PROMPTED_ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"jump", &"crucifix",
		&"interact"]


func _initialize() -> void:
	await process_frame
	root.size = SCREEN
	await process_frame
	var results: Array[bool] = []
	results.append(await _a_glyph_shows_the_key_then_the_pad_button())
	results.append(await _the_prompted_pad_bindings_show_their_picture())
	results.append(await _a_key_prompt_follows_the_device_used_last())
	results.append(await _the_band_sits_at_the_bottom_centre())
	results.append(await _the_plate_is_drawn_only_with_a_hint_not_held())
	results.append(await _the_caption_reads_over_a_white_screen())
	results.append(await _with_a_band_the_hints_show_there_one_at_a_time())
	results.append(await _the_band_hides_while_velvet_talks())
	results.append(await _level_1_shows_its_hints_in_the_band())
	quit(1 if results.has(false) else 0)


func _report(passed: bool, what: String) -> bool:
	print("%s: %s" % ["PASS" if passed else "FAIL", what])
	return passed


func _a_glyph_shows_the_key_then_the_pad_button() -> bool:
	await _press(_key(KEY_SPACE))
	var glyph: PromptGlyph = GLYPH_SCENE.instantiate() as PromptGlyph
	glyph.action = &"jump"
	root.add_child(glyph)
	await process_frame
	var key: String = glyph.get_text()
	await _press(_pad_button(JOY_BUTTON_A))
	var pad: String = glyph.get_text()
	var shows_pad: bool = glyph.shows_pad()
	await _press(_key(KEY_SPACE))
	var key_again: String = glyph.get_text()
	var key_framed: bool = glyph.get_theme_stylebox(&"panel") is StyleBoxFlat
	glyph.queue_free()
	await process_frame
	var expected_key: String = PromptGlyph.key_text(&"jump")
	return _report(key == expected_key and pad == "A" and shows_pad and key_again == expected_key
			and key_framed, ("Jump's glyph: %s, after pad A %s (pad %s), after Space %s in its key "
			+ "frame %s (expected %s, A, %s, true)")
			% [key, pad, shows_pad, key_again, key_framed, expected_key, expected_key])


## With the pad used last, each pad binding the prompts show has its picture, and a binding with none,
## as the pause's Menu, keeps its name in a key; on the keyboard no glyph shows a picture.
func _the_prompted_pad_bindings_show_their_picture() -> bool:
	await _press(_pad_button(JOY_BUTTON_A))
	var missing: Array[String] = []
	for action: StringName in PROMPTED_ACTIONS:
		var glyph: PromptGlyph = await _new_glyph(action)
		if not glyph.shows_icon():
			missing.append("%s (%s)" % [action, glyph.get_text()])
		glyph.queue_free()
	var pause: PromptGlyph = await _new_glyph(&"pause")
	var pause_shown: String = "%s, picture %s" % [pause.get_text(), pause.shows_icon()]
	pause.queue_free()
	await _press(_key(KEY_SPACE))
	var jump: PromptGlyph = await _new_glyph(&"jump")
	var key_picture: bool = jump.shows_icon()
	jump.queue_free()
	await process_frame
	return _report(missing.is_empty() and pause_shown == "Menu, picture false" and not key_picture,
			"Pad bindings without a picture %s; pause %s; jump on the keyboard with a picture %s"
			% [missing, pause_shown, key_picture])


## With a pad connected, a key press brings the keys back: the prompts follow the device used last.
## Aligned left, the glyph keeps its left edge on the node whatever its size.
func _a_key_prompt_follows_the_device_used_last() -> bool:
	var prompt: KeyPrompt = KEY_PROMPT_SCENE.instantiate() as KeyPrompt
	prompt.action = &"jump"
	prompt.alignment = HORIZONTAL_ALIGNMENT_LEFT
	root.add_child(prompt)
	await process_frame
	var glyph: PromptGlyph = prompt.get_node(^"%Glyph") as PromptGlyph
	Input.joy_connection_changed.emit(0, true)
	await process_frame
	var connected: String = prompt.get_text()
	var icon_left: float = glyph.position.x
	await _press(_key(KEY_SPACE))
	var key_pressed: String = prompt.get_text()
	var key_left: float = glyph.position.x
	Input.joy_connection_changed.emit(0, false)
	await process_frame
	prompt.queue_free()
	await process_frame
	var expected_key: String = KeyPrompt.key_text(&"jump")
	return _report(connected == "A" and key_pressed == expected_key
			and is_zero_approx(icon_left) and is_zero_approx(key_left),
			("Jump's key in the world: pad connected %s, then Space pressed %s (expected A, %s); "
			+ "left edge at %.1f with the picture and %.1f with the key (expected 0)")
			% [connected, key_pressed, expected_key, icon_left, key_left])


## Long caption, then a short one: the plate shrinks back and stays centred, PLATE_HEIGHT tall.
func _the_band_sits_at_the_bottom_centre() -> bool:
	var band: PromptBand = BAND_SCENE.instantiate() as PromptBand
	root.add_child(band)
	band.show_hint([&"crucifix"] as Array[StringName], LONG_CAPTION)
	await process_frame
	await process_frame
	var long_width: float = band.get_plate_rect().size.x
	band.show_hint([&"jump"] as Array[StringName], "Jump")
	await process_frame
	await process_frame
	var plate: Rect2 = band.get_plate_rect()
	var bottom_gap: float = SCREEN.y - plate.end.y
	var centre_off: float = plate.get_center().x - SCREEN.x / 2.0
	var expected_gap: float = band.bottom_gap
	band.queue_free()
	await process_frame
	return _report(absf(bottom_gap - expected_gap) <= PLACE_TOLERANCE
			and absf(centre_off) <= PLACE_TOLERANCE
			and absf(plate.size.y - PLATE_HEIGHT) <= PLACE_TOLERANCE and plate.size.x < long_width,
			("Band's plate %s: %.1f px above the bottom (expected %.1f), %.1f px off the centre, "
			+ "%.0f px tall (expected %.0f), %.0f px wide after %.0f for a long caption")
			% [plate, bottom_gap, expected_gap, centre_off, plate.size.y, PLATE_HEIGHT, plate.size.x,
			long_width])


## The plate is drawn only with a hint and while not held: no empty plate after a talk, and none
## while Velvet talks.
func _the_plate_is_drawn_only_with_a_hint_not_held() -> bool:
	var band: PromptBand = BAND_SCENE.instantiate() as PromptBand
	root.add_child(band)
	var drawn: Array[float] = []
	band.show_hint([&"jump"] as Array[StringName], "Jump")
	drawn.append(await _alpha_after_fade(band))
	band.set_held(true)
	drawn.append(await _alpha_after_fade(band))
	band.set_held(false)
	drawn.append(await _alpha_after_fade(band))
	band.clear()
	drawn.append(await _alpha_after_fade(band))
	band.set_held(true)
	band.set_held(false)
	drawn.append(await _alpha_after_fade(band))
	band.queue_free()
	await process_frame
	return _report(drawn == ([1.0, 0.0, 1.0, 0.0, 0.0] as Array[float]),
			("Plate drawn at: a hint %s, held %s, let go %s, cleared %s, held and let go with no "
			+ "hint %s (expected 1, 0, 1, 0, 0)") % drawn)


## The plate is see-through: over a white screen it is at its lightest. The key's name against
## its key's frame, see-through too, likewise.
func _the_caption_reads_over_a_white_screen() -> bool:
	var band: PromptBand = BAND_SCENE.instantiate() as PromptBand
	root.add_child(band)
	var plate: Color = band.get_plate_color()
	var ratio: float = _contrast(band.get_caption_color(), Color.WHITE.lerp(Color(plate, 1.0), plate.a))
	var glyph: PromptGlyph = await _new_glyph(&"jump")
	var frame: Color = (glyph.get_theme_stylebox(&"panel") as StyleBoxFlat).bg_color
	var key_name: Color = (glyph.get_node(^"%Label") as Label).get_theme_color(&"font_color")
	var key_ratio: float = _contrast(key_name, Color.WHITE.lerp(Color(frame, 1.0), frame.a))
	band.queue_free()
	glyph.queue_free()
	await process_frame
	return _report(ratio >= MIN_CONTRAST and key_ratio >= MIN_CONTRAST,
			"Over white: caption against the plate %.2f:1, key's name against its frame %.2f:1 (at least %.1f:1)"
			% [ratio, key_ratio, MIN_CONTRAST])


func _with_a_band_the_hints_show_there_one_at_a_time() -> bool:
	var player: Node2D = Node2D.new()
	var band: PromptBand = BAND_SCENE.instantiate() as PromptBand
	var tutorial: TutorialHints = TutorialHints.new()
	tutorial.player = player
	tutorial.band = band
	tutorial.hide_margin = HIDE_MARGIN
	tutorial.min_show_time = MIN_SHOW_TIME
	var hint_a: Node2D = _hint(HINT_A_X, [&"move_left", &"move_right"], ["Move"])
	var hint_b: Node2D = _hint(HINT_B_X, [&"jump"], ["Jump", "high"])
	var hint_c: Node2D = _hint(HINT_C_X, [&"crucifix"], ["Crucifix"])
	var hint_d: Node2D = _hint(HINT_D_X, [&"interact"], ["Far below"])
	hint_d.position.y = HINT_D_Y
	# Out of order, as a level's children may be: the band goes by x.
	for hint: Node2D in [hint_c, hint_b, hint_d, hint_a]:
		tutorial.add_child(hint)
	root.add_child(player)
	root.add_child(band)
	root.add_child(tutorial)
	await _wait(SHORT_WAIT)
	var start: String = _shown(band)
	var world_hidden: bool = not hint_a.visible and not hint_b.visible and not hint_c.visible
	player.position.x = HINT_A_X + HIDE_MARGIN + 100.0
	await _wait(SHORT_WAIT)
	var a_just_passed: String = _shown(band)
	await _wait(LONG_WAIT)
	var a_long_passed: String = _shown(band)
	player.position.x = HINT_B_X + HIDE_MARGIN + 100.0
	await _wait(SHORT_WAIT)
	var b_just_passed: String = _shown(band)
	await _wait(LONG_WAIT)
	var none_on_screen: String = _shown(band)
	tutorial.queue_free()
	band.queue_free()
	player.queue_free()
	await process_frame
	var found: Array[String] = [start, a_just_passed, a_long_passed, b_just_passed, none_on_screen]
	var expected: Array[String] = ["move_left move_right: Move", "move_left move_right: Move",
			"jump: Jump high", "jump: Jump high", "(none)"]
	return _report(world_hidden and found == expected, ("Hints in the world hidden %s; band at the "
			+ "start, just past A, long past A, just past B, long past B: %s (expected %s)")
			% [world_hidden, found, expected])


## Velvet, in level 1, says when she starts and stops talking; the band hides for the talk.
func _the_band_hides_while_velvet_talks() -> bool:
	var level: Node = (load(LEVEL_1_PATH) as PackedScene).instantiate()
	root.add_child(level)
	await _wait(SETTLE_FRAMES)
	var band: PromptBand = (level.get_node(^"Tutorial") as TutorialHints).band
	var velvet: TutorialDemon = level.get_node(^"Tutorial/TutorialDemon") as TutorialDemon
	var before: bool = band.is_showing()
	velvet.talk_started.emit()
	await process_frame
	var talking: bool = band.is_showing()
	velvet.talk_ended.emit()
	await process_frame
	var after: bool = band.is_showing()
	level.queue_free()
	await process_frame
	return _report(before and not talking and after,
			"Band showing before Velvet talks %s, while she talks %s, after %s (expected true, false, true)"
			% [before, talking, after])


func _level_1_shows_its_hints_in_the_band() -> bool:
	var level: Node = (load(LEVEL_1_PATH) as PackedScene).instantiate()
	root.add_child(level)
	await _wait(SETTLE_FRAMES)
	var tutorial: TutorialHints = level.get_node(^"Tutorial") as TutorialHints
	var band: PromptBand = tutorial.band
	var shown: String = _shown(band) if band != null else "(no band)"
	var world_hidden: bool = true
	for hint: Node2D in tutorial.get_shown():
		world_hidden = world_hidden and not hint.visible
	level.queue_free()
	await process_frame
	return _report(shown == "move_left move_right: Move" and world_hidden,
			"Level 1 where he wakes: band %s, hints hidden in the world %s" % [shown, world_hidden])


## A hint as the level has one: a plain Node2D with a KeyPrompt for each action and a Label for
## each line of its caption.
func _hint(x: float, actions: Array[StringName], lines: Array[String]) -> Node2D:
	var hint: Node2D = Node2D.new()
	hint.position.x = x
	for action: StringName in actions:
		var key: KeyPrompt = KEY_PROMPT_SCENE.instantiate() as KeyPrompt
		key.action = action
		hint.add_child(key)
	var caption: Label = Label.new()
	caption.text = "\n".join(lines)
	hint.add_child(caption)
	return hint


## How opaque the band's plate is drawn once its fade is over; 0 when hidden.
func _alpha_after_fade(band: PromptBand) -> float:
	for i: int in FADE_FRAMES:
		await process_frame
	return band.get_drawn_alpha()


func _new_glyph(action: StringName) -> PromptGlyph:
	var glyph: PromptGlyph = GLYPH_SCENE.instantiate() as PromptGlyph
	glyph.action = action
	root.add_child(glyph)
	await process_frame
	return glyph


## What the band shows, as "actions: caption", or "(none)".
static func _shown(band: PromptBand) -> String:
	if not band.is_showing():
		return "(none)"
	var actions: PackedStringArray = []
	for action: StringName in band.get_actions():
		actions.append(action)
	return "%s: %s" % [" ".join(actions), band.get_caption()]


## WCAG's contrast ratio between two opaque sRGB colours; get_luminance wants them linear.
static func _contrast(a: Color, b: Color) -> float:
	var la: float = a.srgb_to_linear().get_luminance()
	var lb: float = b.srgb_to_linear().get_luminance()
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


func _wait(frames: int) -> void:
	for i: int in frames:
		await physics_frame


## Sends a press and its release through Input, and waits until both reached the window.
func _press(event: InputEvent) -> void:
	Input.parse_input_event(event)
	var release: InputEvent = event.duplicate()
	release.set(&"pressed", false)
	Input.parse_input_event(release)
	await process_frame
	await process_frame


static func _key(keycode: Key) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = true
	return event


static func _pad_button(index: JoyButton) -> InputEventJoypadButton:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = index
	event.pressed = true
	return event
