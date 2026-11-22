# Checks that the menus' music fades evenly to the ear (#284). Loudness follows decibels, not the gain: a
# straight ramp of the gain brings most of the loudness in the first moments of a fade-in, and keeps it until
# the last moments of a fade-out, where it drops at once. So halfway through either fade the gain is at most a
# quarter of the full one (-12 dB), and it still moves: above zero halfway in, below full halfway out. Each
# fade ends where it should, at the full volume and at silence, and the fades take at least 1.5 s.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_menu_music_fade.gd
extends "res://tests/support/base_test.gd"

const THEME_PATH: String = "res://assets/audio/music/main_menu_theme.ogg"
## The most of the full gain halfway through a fade: -12 dB.
const HALFWAY_MOST: float = 0.25
## The shortest fade, so it is heard as a fade.
const SHORTEST_FADE: float = 1.5
## Frames past a fade's end, for its tween to finish.
const SPARE_FRAMES: int = 10
const FRAME_RATE: float = 60.0

var _failed: bool = false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var menu := CanvasLayer.new()
	menu.visible = false
	root.add_child(menu)
	var music := MenuMusic.new()
	music.stream = load(THEME_PATH) as AudioStream
	music.menus = [menu]
	root.add_child(music)
	await process_frame
	var full: float = music.full_volume()
	_check(music.fade_in_time >= SHORTEST_FADE and music.fade_out_time >= SHORTEST_FADE,
			"The fades take at least %.1f s: in %.2f s, out %.2f s"
			% [SHORTEST_FADE, music.fade_in_time, music.fade_out_time])

	menu.visible = true
	await _frames(_frames_of(music.fade_in_time * 0.5))
	var halfway_in: float = music.volume_linear / full
	_check(halfway_in > 0.0 and halfway_in <= HALFWAY_MOST,
			"Halfway through a fade-in, %.3f of the full gain (%.1f dB): above 0, at most %.2f"
			% [halfway_in, linear_to_db(halfway_in), HALFWAY_MOST])
	await _frames(_frames_of(music.fade_in_time * 0.5) + SPARE_FRAMES)
	_check(is_equal_approx(music.volume_linear, full), "At the end of the fade-in, the full volume: %.3f of %.3f"
			% [music.volume_linear, full])

	menu.visible = false
	await _frames(_frames_of(music.fade_out_time * 0.5))
	var halfway_out: float = music.volume_linear / full
	_check(halfway_out < 1.0 and halfway_out <= HALFWAY_MOST,
			"Halfway through a fade-out, %.3f of the full gain (%.1f dB): at most %.2f"
			% [halfway_out, linear_to_db(maxf(halfway_out, 0.0001)), HALFWAY_MOST])
	await _frames(_frames_of(music.fade_out_time * 0.5) + SPARE_FRAMES)
	_check(is_zero_approx(music.volume_linear) and music.stream_paused,
			"At the end of the fade-out, silent %.3f and paused %s" % [music.volume_linear, music.stream_paused])

	music.free()
	menu.free()
	quit(1 if _failed else 0)


## Frames a span of time takes, at the 60 frames a second the test runs at (--fixed-fps 60).
func _frames_of(seconds: float) -> int:
	return roundi(seconds * FRAME_RATE)


func _frames(count: int) -> void:
	for i: int in count:
		await process_frame


func _check(passed: bool, what: String) -> void:
	print("%s %s" % ["PASS" if passed else "FAIL", what])
	_failed = _failed or not passed
