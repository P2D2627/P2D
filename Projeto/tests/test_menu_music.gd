# Checks the menus' music, through the main scene. The main menu's theme plays on the Music bus
# while the main menu shows, and comes up to full within Fade In Time. Starting a level fades it out
# and pauses it where it was, and it stays there while the level runs. The pause brings it back
# while the game is paused, from where it was left, not from the top, and Resume fades it out and
# pauses it again. Main Menu, from the pause, goes from one menu to the other with no dip in the
# music. At its end, the song starts again from the top.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_menu_music.gd
extends "res://tests/support/menu_test.gd"

const MUSIC_BUS: StringName = &"Music"
const THEME_PATH: String = "res://assets/audio/music/main_menu_theme.ogg"
## Short fades, so the cases do not wait long; the first fade-in, at the start, keeps the scene's.
const TEST_FADE_TIME: float = 0.2
## Frames past a fade's end, for its tween to finish.
const SPARE_FRAMES: int = 20
## Where in the song the cases put it, in seconds: well past the start.
const SONG_SPOT: float = 60.0
## How far past SONG_SPOT the song may be, in seconds: it plays in real time meanwhile.
const POSITION_TOLERANCE: float = 3.0
## Real time the level runs with the music paused, in ms, to see that it stays where it was.
const HELD_WAIT_MS: int = 500
## How far a paused song may move, in seconds.
const HELD_TOLERANCE: float = 0.05
## How close to full or to silent the volume must be, as a linear gain.
const VOLUME_TOLERANCE: float = 0.01
## The softest the music may get going from the pause to the main menu, as a share of full.
const MIN_SWAP_SHARE: float = 0.99
## Frames to watch the volume after Main Menu is pressed.
const SWAP_FRAMES: int = 30
## Seconds before the song's end to put it, to see it start again.
const BEFORE_THE_END: float = 0.3
## Real time to wait for the end, at most, in ms, and each frame's share of it.
const END_WAIT_MS: int = 3000
const FRAME_WAIT_MS: int = 10
## Where the song must be, at most, once it has started again, in seconds.
const RESTART_TOLERANCE: float = 1.0

## The softest the music got while it was watched, as a linear gain.
var _softest: float = INF


func _initialize() -> void:
	var results: Array[bool] = []
	results.append(await _in_the_main_menu_the_theme_plays_on_the_music_bus())
	results.append(await _a_level_pauses_it_and_the_pause_goes_on_from_there())
	results.append(await _main_menu_from_the_pause_keeps_it_playing())
	results.append(await _at_its_end_the_song_starts_again())
	finish(results)


func _in_the_main_menu_the_theme_plays_on_the_music_bus() -> bool:
	var main: Node = await new_main()
	var music: MenuMusic = _music_in(main)
	if music == null:
		await remove_main(main)
		return report(false, "The main scene has a MenuMusic")
	await wait_frames(_fade_frames(music.fade_in_time))
	var theme: bool = music.stream != null and music.stream.resource_path == THEME_PATH
	var bus_right: bool = music.bus == MUSIC_BUS
	var playing: bool = music.playing and not music.stream_paused
	var volume: float = music.volume_linear
	var full_volume: float = music.full_volume()
	var full: bool = absf(volume - full_volume) < VOLUME_TOLERANCE
	await remove_main(main)
	return report(theme and bus_right and playing and full,
			"In the main menu: the theme %s, on Music %s, playing %s, volume %.3f of %.3f"
			% [theme, bus_right, playing, volume, full_volume])


## Start a level from the song's SONG_SPOT, wait in the level, then pause, then resume.
func _a_level_pauses_it_and_the_pause_goes_on_from_there() -> bool:
	var main: Node = await new_main()
	var music: MenuMusic = _music_in(main)
	if music == null:
		await remove_main(main)
		return report(false, "The main scene has a MenuMusic")
	await wait_frames(_fade_frames(music.fade_in_time))
	_shorten_the_fades(music)
	music.seek(SONG_SPOT)
	await tap(KEY_ENTER)
	await tap(KEY_ENTER)
	await wait_frames(_fade_frames(TEST_FADE_TIME))
	var in_a_level: bool = levels_in(main) == 1
	var paused_in_the_level: bool = music.stream_paused
	var silent_in_the_level: float = music.volume_linear
	var left_at: float = music.get_playback_position()
	OS.delay_msec(HELD_WAIT_MS)
	await wait_frames(SPARE_FRAMES)
	var held: float = absf(music.get_playback_position() - left_at)
	await tap(KEY_ESCAPE)
	await wait_frames(_fade_frames(TEST_FADE_TIME))
	var game_paused: bool = paused
	var playing_in_the_pause: bool = music.playing and not music.stream_paused
	var volume_in_the_pause: float = music.volume_linear
	var pause_from: float = music.get_playback_position()
	await tap(KEY_ESCAPE)
	await wait_frames(_fade_frames(TEST_FADE_TIME))
	var paused_after_resume: bool = music.stream_paused and not paused
	var silent_after_resume: float = music.volume_linear
	var full: float = music.full_volume()
	await remove_main(main)
	var level_right: bool = (in_a_level and paused_in_the_level
			and silent_in_the_level < VOLUME_TOLERANCE and held < HELD_TOLERANCE
			and left_at >= SONG_SPOT and left_at < SONG_SPOT + POSITION_TOLERANCE)
	var pause_right: bool = (game_paused and playing_in_the_pause
			and absf(volume_in_the_pause - full) < VOLUME_TOLERANCE
			and pause_from >= left_at and pause_from < left_at + POSITION_TOLERANCE)
	var resume_right: bool = paused_after_resume and silent_after_resume < VOLUME_TOLERANCE
	return report(level_right and pause_right and resume_right,
			("In a level: paused %s at %.2f s of %.0f, volume %.3f, moved %.3f s while held; "
			+ "in the pause (game paused %s): playing %s from %.2f s, volume %.3f of %.3f; "
			+ "after Resume: paused %s, volume %.3f")
			% [paused_in_the_level, left_at, SONG_SPOT, silent_in_the_level, held, game_paused,
			playing_in_the_pause, pause_from, volume_in_the_pause, full, paused_after_resume,
			silent_after_resume])


## The volume is watched on every frame from the press of Main Menu on.
func _main_menu_from_the_pause_keeps_it_playing() -> bool:
	var main: Node = await new_main_in_a_level()
	var music: MenuMusic = _music_in(main)
	if music == null:
		await remove_main(main)
		return report(false, "The main scene has a MenuMusic")
	_shorten_the_fades(music)
	await tap(KEY_ESCAPE)
	await wait_frames(_fade_frames(TEST_FADE_TIME))
	music.seek(SONG_SPOT)
	await process_frame
	var at_the_press: float = music.get_playback_position()
	_softest = INF
	var note_the_volume: Callable = _note_the_volume.bind(music)
	process_frame.connect(note_the_volume)
	await press_on(main.get_node(^"%PauseMenu"), ^"%MainMenuButton", KEY_ENTER)
	await wait_frames(SWAP_FRAMES)
	process_frame.disconnect(note_the_volume)
	var menu_shows: bool = (main.get_node(^"%MainMenu") as CanvasLayer).visible
	var no_level: bool = levels_in(main) == 0
	var playing: bool = music.playing and not music.stream_paused and music.is_wanted()
	var after: float = music.get_playback_position()
	var share: float = _softest / music.full_volume()
	await remove_main(main)
	return report(menu_shows and no_level and playing and share >= MIN_SWAP_SHARE
			and at_the_press >= SONG_SPOT and after >= at_the_press,
			("Main Menu from the pause: menu shows %s, no level %s, playing %s, softest %.3f of "
			+ "full, from %.2f s to %.2f s") % [menu_shows, no_level, playing, share, at_the_press,
			after])


func _at_its_end_the_song_starts_again() -> bool:
	var main: Node = await new_main()
	var music: MenuMusic = _music_in(main)
	if music == null or music.stream == null:
		await remove_main(main)
		return report(false, "The main scene has a MenuMusic with a song")
	var length: float = music.stream.get_length()
	music.seek(length - BEFORE_THE_END)
	var restarted: bool = false
	var waited: int = 0
	while waited < END_WAIT_MS and not restarted:
		await process_frame
		OS.delay_msec(FRAME_WAIT_MS)
		waited += FRAME_WAIT_MS
		restarted = music.playing and music.get_playback_position() < RESTART_TOLERANCE
	await remove_main(main)
	return report(restarted, ("Put %.1f s before the end of %.1f s, it starts again from the top "
			+ "within %d ms: %s") % [BEFORE_THE_END, length, waited, restarted])


func _music_in(main: Node) -> MenuMusic:
	return main.get_node_or_null(^"%MenuMusic") as MenuMusic


func _shorten_the_fades(music: MenuMusic) -> void:
	music.fade_in_time = TEST_FADE_TIME
	music.fade_out_time = TEST_FADE_TIME


## The frames a fade of fade_time seconds takes, with --fixed-fps 60, and some to spare.
func _fade_frames(fade_time: float) -> int:
	return ceili(fade_time * Engine.physics_ticks_per_second) + SPARE_FRAMES


func _note_the_volume(music: MenuMusic) -> void:
	_softest = minf(_softest, music.volume_linear)
