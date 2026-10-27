# Test of the gym's sign (ADR 0036). The sign scene is linked to its label and hidden with no text;
# its text shows on the label and shows the sign, and an empty one hides it again; a long text wraps
# inside the sign's width instead of widening it; and the text stands out from the panel by at least
# the 4.5:1 contrast of WCAG AA, so it reads on any background.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_gym_hint.gd
extends "res://tests/support/player_test.gd"

const HINT_SCENE: PackedScene = preload("res://levels/gym/gym_hint.tscn")
## WCAG 2 AA, for normal text.
const MIN_CONTRAST: float = 4.5
## Long enough to need more than one line at the sign's width.
const LONG_TEXT: String = "Salta para o buraco e carrega no salto logo depois de sair da borda: ainda saltas, porque o coyote time te dá uns frames de folga."


func _initialize() -> void:
	var results: Array[bool] = []
	results.append(await _the_sign_is_linked_and_hidden_with_no_text())
	results.append(await _its_text_shows_and_an_empty_one_hides_it())
	results.append(await _a_long_text_wraps_inside_the_sign())
	results.append(await _the_text_stands_out_from_the_panel())
	finish(results)


func _the_sign_is_linked_and_hidden_with_no_text() -> bool:
	var hint: GymHint = await _make_hint("")
	var linked: bool = hint.label != null
	var hidden: bool = not hint.visible
	hint.free()
	return report(linked and hidden, "Sign scene: linked %s, hidden with no text %s"
			% [linked, hidden])


func _its_text_shows_and_an_empty_one_hides_it() -> bool:
	var hint: GymHint = await _make_hint("Movimento")
	var shown: bool = hint.visible and hint.label.text == "Movimento"
	hint.text = ""
	var hidden: bool = not hint.visible
	hint.free()
	return report(shown and hidden, "Text: shown on the label %s, hidden once empty %s"
			% [shown, hidden])


func _a_long_text_wraps_inside_the_sign() -> bool:
	var hint: GymHint = await _make_hint("")
	var width: float = hint.label.size.x
	hint.text = LONG_TEXT
	await wait_frames(1)
	var lines: int = hint.label.get_line_count()
	var same_width: bool = is_equal_approx(hint.label.size.x, width)
	hint.free()
	return report(lines > 1 and same_width, "Long text: %d lines, width kept at %.0f px %s"
			% [lines, width, same_width])


func _the_text_stands_out_from_the_panel() -> bool:
	var hint: GymHint = await _make_hint("Movimento")
	var panel: StyleBoxFlat = hint.label.get_theme_stylebox(&"normal") as StyleBoxFlat
	var opaque: bool = panel != null and is_equal_approx(panel.bg_color.a, 1.0)
	var ratio: float = 0.0
	if panel != null:
		ratio = _contrast(hint.label.get_theme_color(&"font_color"), panel.bg_color)
	hint.free()
	return report(opaque and ratio >= MIN_CONTRAST,
			"Contrast: opaque panel %s, text against it %.1f:1 (at least %.1f:1)"
			% [opaque, ratio, MIN_CONTRAST])


func _make_hint(text: String) -> GymHint:
	var hint: GymHint = HINT_SCENE.instantiate() as GymHint
	hint.text = text
	root.add_child(hint)
	await wait_frames(1)
	return hint


## The WCAG 2 contrast ratio between two colours, from 1:1 to 21:1.
func _contrast(a: Color, b: Color) -> float:
	var la: float = _luminance(a)
	var lb: float = _luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


## WCAG 2 relative luminance of an sRGB colour.
func _luminance(c: Color) -> float:
	return 0.2126 * _linear(c.r) + 0.7152 * _linear(c.g) + 0.0722 * _linear(c.b)


func _linear(channel: float) -> float:
	if channel <= 0.04045:
		return channel / 12.92
	return pow((channel + 0.055) / 1.055, 2.4)
