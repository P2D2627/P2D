# Checks the talk as a scene. TalkShot alone: the zoom fits the figures between the answers' wheel and the
# bottom bar, no closer than Max Zoom and no further than Min Zoom; the centre puts their feet on the room's
# bottom, leaning no further than keeps them in the room; the moves ease in and out, and zoom evenly in scale.
# The drawn rects of the man, Velvet and Asmodeus are as tall as their scenes say. Then TalkFraming, in the
# camera, in a small world: Velvet's first talk brings the bars in to Bar Share of the screen, takes the camera
# to both of them at Max Zoom, with their heads under the wheel and their feet over the bar, and closes the
# man's hurtbox; the shot holds still for Hold Time, then the camera leans Lean Share of the screen to her side
# while she speaks, and to his once the answers show; when the balloon goes the camera is given back, the bars
# slide out and the hurtbox opens. The wheel ends at y 613.6 of a 1080 px screen (its stage is drawn at 0.8),
# and with Max Zoom raised Asmodeus's shot stops where that room fits her 150 px. With Reduce Motion the camera
# is never taken, the bars fade in at full height and the hurtbox still closes; with Show Bars off no bar shows,
# the camera still frames them and the hurtbox closes. A talk while a cutscene has the camera leaves the camera
# and the hurtbox to it; a cutscene that starts as a talk ends comes back to where the camera was on the man
# before the talk, not to the talk's shot; a cutscene that starts during a talk keeps the hurtbox closed after
# the talk ends; and a hurtbox already closed by something else stays closed after a talk.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_talk_framing.gd
extends "res://tests/support/player_test.gd"

const CAMERA_SCENE: PackedScene = preload("res://scenes/others/camera/game_camera.tscn")
const VELVET_SCENE: PackedScene = preload("res://scenes/characters/demon/tutorial_demon.tscn")
const ASMODEUS_SCENE: PackedScene = preload("res://scenes/characters/demon/asmodeus.tscn")
const SCREEN: Vector2 = Vector2(1920.0, 1080.0)
## The room under a wheel that ends at y 767, 8 px of head gap, and a 72 px bar with 16 px of feet gap.
const ROOM: Rect2 = Rect2(96.0, 775.0, 1728.0, 217.0)
## Two figures side by side, as the man and Velvet: 300 px across and 104 px tall, feet 4 px under y 0.
const PAIR: Rect2 = Rect2(-150.0, -100.0, 300.0, 104.0)
const TOLERANCE: float = 0.01
## How far, in px of the screen, a figure may come past the room's edges, for the camera's rounding.
const SCREEN_TOLERANCE: float = 1.5
## The heights the scenes give: the man's 384 px cell at 0.268229, Velvet's 202 px cell and Asmodeus's 300 px
## art at 0.5.
const MAN_HEIGHT: float = 384.0 * 0.268229
const VELVET_HEIGHT: float = 101.0
const ASMODEUS_HEIGHT: float = 150.0
## Where the talkers stand from the man, in px: inside Velvet's Talk Area, and Asmodeus's Appear Offset.
const VELVET_AT: float = 200.0
const ASMODEUS_AT: float = 300.0
const ASMODEUS_CUE: String = "velvet_again"
## A Max Zoom the room never allows the figures, so the wheel is what stops the camera.
const RAISED_MAX_ZOOM: float = 4.0
## The wheel's bottom on a 1080 px screen: its slots end at y 767 of the balloon's stage, drawn at 0.8 from the
## top, and how far from it the measure may be, in px.
const ANSWERS_BOTTOM: float = 767.0 * 0.8
const ANSWERS_TOLERANCE: float = 1.0
## How far the lean may be from Lean Share of the screen, in px of the level.
const LEAN_TOLERANCE: float = 0.5
## How long before Hold Time is up the camera is checked to be still, in s.
const BEFORE_THE_HOLD: float = 0.2
## Where the cutscene after a talk looks, to the man's right: near, as a quick look.
const LOOK_VIEW: Rect2 = Rect2(600.0, -400.0, 400.0, 300.0)
const LOOK_TRAVEL: float = 0.5
const LOOK_HOLD: float = 0.2
const LOOK_RETURN: float = 0.5
## Frames past a time, for the last physics step and the tween's last idle step.
const SLACK_FRAMES: int = 6
## How far the man walks on half way back from a talk, in px.
const MAN_STEP: float = 120.0

var _camera: GameCamera
var _framing: TalkFraming


func _initialize() -> void:
	# Without a window the root is 64 x 64 px and the Expand aspect makes it 1920 x 1920: set the screen first.
	await process_frame
	root.size = Vector2i(SCREEN)
	await process_frame
	var results: Array[bool] = []
	results.append(_the_zoom_fits_the_figures_in_the_room())
	results.append(_the_centre_puts_the_feet_on_the_room_bottom_and_leans_within_it())
	results.append(_the_moves_ease_in_and_out_and_zoom_evenly())
	make_platform(-4000.0, 4000.0)
	var player: Player = await spawn_on_floor(Vector2(0.0, -2.0))
	if player == null:
		results.append(report(false, "The man never landed"))
		finish(results)
		return
	_camera = CAMERA_SCENE.instantiate() as GameCamera
	_camera.player = player
	root.add_child(_camera)
	_camera.make_current()
	_framing = _camera.get_node(^"TalkFraming") as TalkFraming
	await physics_frame
	put_a_stand_in(player)
	results.append(_the_drawn_rects_are_as_tall_as_the_scenes_say(player))
	results.append(await _velvet_s_talk_is_a_scene_and_ends_as_one(player))
	results.append(await _asmodeus_s_shot_stops_at_the_wheel(player))
	results.append(await _reduce_motion_leaves_the_camera_and_fades_the_bars(player))
	results.append(await _without_bars_the_camera_still_frames(player))
	results.append(await _a_cutscene_keeps_the_camera_and_the_hurtbox(player))
	results.append(await _a_cutscene_after_a_talk_comes_back_to_the_man(player))
	results.append(await _a_cutscene_during_a_talk_keeps_the_hurtbox_closed(player))
	results.append(await _a_hurtbox_closed_before_the_talk_stays_closed(player))
	results.append(await _a_cutscene_during_the_return_takes_the_camera_from_there(player))
	results.append(await _a_talk_during_the_return_comes_back_to_where_the_man_went(player))
	finish(results)


func _the_zoom_fits_the_figures_in_the_room() -> bool:
	var small: float = TalkShot.zoom_to_fit(PAIR, ROOM, 2.0, 0.5)
	var tall: float = TalkShot.zoom_to_fit(Rect2(-150.0, -150.0, 300.0, 154.0), ROOM, 2.0, 0.5)
	var wide: float = TalkShot.zoom_to_fit(Rect2(-1000.0, -100.0, 2000.0, 104.0), ROOM, 2.0, 0.5)
	var cramped: float = TalkShot.zoom_to_fit(PAIR, Rect2(96.0, 775.0, 1728.0, 20.0), 2.0, 0.5)
	return report(is_equal_approx(small, 2.0) and absf(tall - 217.0 / 154.0) < TOLERANCE
			and absf(wide - 1728.0 / 2000.0) < TOLERANCE and is_equal_approx(cramped, 0.5),
			"The zoom fits the room: %.3f for two small figures (2.0), %.3f for a 154 px one (%.3f), %.3f for 2000 px across (%.3f), %.3f in a 20 px room (0.5)"
			% [small, tall, 217.0 / 154.0, wide, 1728.0 / 2000.0, cramped])


func _the_centre_puts_the_feet_on_the_room_bottom_and_leans_within_it() -> bool:
	var level: float = 2.0
	var centre: Vector2 = TalkShot.centre_for(PAIR, ROOM, SCREEN, level, 0.0)
	var feet: Vector2 = (Vector2(PAIR.get_center().x, PAIR.end.y) - centre) * level + SCREEN / 2.0
	var leaned: Vector2 = TalkShot.centre_for(PAIR, ROOM, SCREEN, level, 192.0)
	var too_far: Vector2 = TalkShot.centre_for(PAIR, ROOM, SCREEN, level, 5000.0)
	var spare: float = (ROOM.size.x - PAIR.size.x * level) / 2.0
	var other_way: Vector2 = TalkShot.centre_for(PAIR, ROOM, SCREEN, level, -5000.0)
	return report(feet.distance_to(Vector2(ROOM.get_center().x, ROOM.end.y)) < TOLERANCE
			and is_equal_approx(leaned.x - centre.x, 192.0 / level)
			and is_equal_approx(too_far.x - centre.x, spare / level)
			and is_equal_approx(other_way.x - centre.x, -spare / level),
			"The feet land at %s (%s); a lean of 192 px moves the camera %.1f (96), 5000 px only %.1f and -5000 px %.1f (%.1f each way)"
			% [feet, Vector2(ROOM.get_center().x, ROOM.end.y), leaned.x - centre.x, too_far.x - centre.x,
			other_way.x - centre.x, spare / level])


func _the_moves_ease_in_and_out_and_zoom_evenly() -> bool:
	var quarter: float = TalkShot.ease_along(0.25)
	var ends: bool = is_zero_approx(TalkShot.ease_along(0.0)) and is_equal_approx(TalkShot.ease_along(1.0), 1.0)
	var past: bool = is_equal_approx(TalkShot.ease_along(1.5), 1.0)
	var middle_zoom: float = TalkShot.zoom_along(1.0, 4.0, 0.5)
	return report(absf(quarter - (0.5 - 0.5 * cos(PI / 4.0))) < TOLERANCE and quarter < 0.25 and ends and past
			and is_equal_approx(middle_zoom, 2.0),
			"A quarter of the time is %.3f of the way (slower than 0.25), the ends 0 and 1 %s, past the end 1 %s; half way from zoom 1 to 4 is %.3f (2.0)"
			% [quarter, ends, past, middle_zoom])


func _the_drawn_rects_are_as_tall_as_the_scenes_say(player: Player) -> bool:
	var velvet: TutorialDemon = _add_velvet(player, 3000.0)
	var asmodeus: Asmodeus = _add_asmodeus(player, 3000.0)
	var man: float = TalkFraming.drawn_rect(player.get_node(^"Sprite") as Node2D).size.y
	var her: float = TalkFraming.drawn_rect(velvet.get_figure()).size.y
	var boss: float = TalkFraming.drawn_rect(asmodeus.get_figure()).size.y
	velvet.queue_free()
	asmodeus.queue_free()
	return report(absf(man - MAN_HEIGHT) < TOLERANCE and absf(her - VELVET_HEIGHT) < TOLERANCE
			and absf(boss - ASMODEUS_HEIGHT) < TOLERANCE,
			"Drawn heights: the man %.2f (%.2f), Velvet %.2f (%.0f), Asmodeus %.2f (%.0f)"
			% [man, MAN_HEIGHT, her, VELVET_HEIGHT, boss, ASMODEUS_HEIGHT])


func _velvet_s_talk_is_a_scene_and_ends_as_one(player: Player) -> bool:
	var hurtbox: Hurtbox = player.get_node(^"Hurtbox") as Hurtbox
	var velvet: TutorialDemon = _add_velvet(player, player.global_position.x + VELVET_AT)
	var home: Array = []
	velvet.talk_started.connect(func() -> void: home.append_array([_camera.global_position, _camera.zoom.x]))
	var started: bool = await wait_until(func() -> bool: return _balloon_of(velvet) != null, 30)
	var balloon: DialogueBalloon = _balloon_of(velvet)
	await wait_frames(_frames(maxf(_framing.enter_time, _framing.bars_in_time)))
	var bar: float = _framing.get_bar_height()
	var zoom: float = _camera.zoom.x
	var closed: bool = not hurtbox.takes_hits()
	var framed: bool = (started and _camera.is_directed() and _framing.is_framing()
			and is_equal_approx(zoom, _framing.max_zoom) and closed
			and absf(bar - _framing.bar_share * SCREEN.y) < TOLERANCE)
	var figures: Array[Node2D] = [player.get_node(^"Sprite") as Node2D, velvet.get_figure()]
	var in_room: bool = started and _in_the_room(balloon, figures)
	var centred_x: float = _camera.global_position.x
	# The shot began holding SLACK_FRAMES ago: still until BEFORE_THE_HOLD before Hold Time is up.
	var still_frames: int = ceili((_framing.hold_time - BEFORE_THE_HOLD) * Engine.physics_ticks_per_second) - SLACK_FRAMES
	await wait_frames(still_frames)
	var held_still: float = absf(_camera.global_position.x - centred_x)
	await wait_frames(_frames(BEFORE_THE_HOLD + _framing.lean_time))
	var leaned_to_her: float = _camera.global_position.x - centred_x
	balloon.skip_to_the_next_choice()
	await wait_until(balloon.is_at_a_choice, 60)
	await wait_frames(_frames(_framing.hold_time + _framing.lean_time))
	var leaned_to_him: float = _camera.global_position.x - centred_x
	var lean: float = _framing.lean_share * SCREEN.x / zoom
	balloon.queue_free()
	await wait_frames(_frames(_framing.bars_out_time))
	var ended: bool = (not _camera.is_directed() and not _framing.is_framing() and hurtbox.takes_hits()
			and _framing.get_bar_height() < TOLERANCE)
	# Half way back, the zoom is between the talk's and the one before; at Return Time, it is that one.
	var back_frames: int = ceili(_framing.return_time * Engine.physics_ticks_per_second)
	await wait_frames(back_frames - _frames(_framing.bars_out_time))
	var back: bool = (not home.is_empty() and (home[0] as Vector2).distance_to(_camera.global_position) < 1.0
			and absf((home[1] as float) - _camera.zoom.x) < TOLERANCE)
	velvet.queue_free()
	await wait_frames(60)
	return report(framed and in_room and held_still < TOLERANCE and absf(leaned_to_her - lean) < LEAN_TOLERANCE
			and absf(leaned_to_him + lean) < LEAN_TOLERANCE and ended and back,
			"Velvet's talk: started %s, framed %s (zoom %.2f, bar %.1f px, hurtbox closed %s), both in the room %s; moved %.3f px in the first %.1f s of the shot; leaned %.1f px to her and %.1f to him (%.1f); ended %s; back at %s, zoom %.3f after %.1f s (%s)"
			% [started, framed, zoom, bar, closed, in_room, held_still, _framing.hold_time - BEFORE_THE_HOLD,
			leaned_to_her, leaned_to_him, lean, ended, _camera.global_position, _camera.zoom.x,
			_framing.return_time, home])


## With Max Zoom raised past what the room allows her, so the wheel is what stops the camera.
func _asmodeus_s_shot_stops_at_the_wheel(player: Player) -> bool:
	var max_zoom: float = _framing.max_zoom
	_framing.max_zoom = RAISED_MAX_ZOOM
	var asmodeus: Asmodeus = _add_asmodeus(player, player.global_position.x + ASMODEUS_AT)
	asmodeus.talk(ASMODEUS_CUE)
	var balloon: DialogueBalloon = _balloon_of(asmodeus)
	var answers_at_start: Rect2 = balloon.get_answers_rect()
	await wait_frames(_frames(_framing.enter_time))
	var zoom: float = _camera.zoom.x
	var figures: Array[Node2D] = [player.get_node(^"Sprite") as Node2D, asmodeus.get_figure()]
	var in_room: bool = _in_the_room(balloon, figures)
	var answers: Rect2 = balloon.get_answers_rect()
	var room_height: float = SCREEN.y * (1.0 - _framing.bar_share) - _framing.feet_gap - answers.end.y - _framing.head_gap
	var tallest: float = TalkFraming.drawn_rect(figures[0]).merge(TalkFraming.drawn_rect(figures[1])).size.y
	await _end_talk(asmodeus)
	_framing.max_zoom = max_zoom
	return report(absf(zoom - room_height / tallest) < TOLERANCE and in_room and answers_at_start == answers
			and absf(answers.end.y - ANSWERS_BOTTOM) < ANSWERS_TOLERANCE,
			"Asmodeus's shot: zoom %.3f (%.0f px of room for %.0f px of figures: %.3f), both in the room %s; the wheel ends at y %.1f (%.1f), the same at the start %s"
			% [zoom, room_height, tallest, room_height / tallest, in_room, answers.end.y, ANSWERS_BOTTOM,
			answers_at_start == answers])


func _reduce_motion_leaves_the_camera_and_fades_the_bars(player: Player) -> bool:
	_framing.reduce_motion = true
	var asmodeus: Asmodeus = _add_asmodeus(player, player.global_position.x + ASMODEUS_AT)
	asmodeus.talk(ASMODEUS_CUE)
	var ever_taken: Array[bool] = [false]
	var watch: Callable = func() -> void:
			ever_taken[0] = ever_taken[0] or _camera.is_directed() or _framing.is_framing()
	physics_frame.connect(watch)
	# Half the fade, with no slack: the bars are on their way in.
	await wait_frames(ceili(_framing.bars_fade_time / 2.0 * Engine.physics_ticks_per_second))
	var mid_height: float = _framing.get_bar_height()
	var mid_alpha: float = _framing.get_bar_alpha()
	await wait_frames(_frames(maxf(_framing.enter_time, _framing.bars_fade_time)))
	var end_alpha: float = _framing.get_bar_alpha()
	var closed: bool = not (player.get_node(^"Hurtbox") as Hurtbox).takes_hits()
	await _end_talk(asmodeus)
	physics_frame.disconnect(watch)
	_framing.reduce_motion = false
	var full: float = _framing.bar_share * SCREEN.y
	return report(not ever_taken[0] and absf(mid_height - full) < TOLERANCE and mid_alpha > 0.0
			and mid_alpha < 1.0 and is_equal_approx(end_alpha, 1.0) and closed,
			"Reduce Motion: camera taken %s; half way the bars %.1f px (%.1f) at alpha %.2f, then %.2f; hurtbox closed %s"
			% [ever_taken[0], mid_height, full, mid_alpha, end_alpha, closed])


func _without_bars_the_camera_still_frames(player: Player) -> bool:
	_framing.show_bars = false
	var asmodeus: Asmodeus = _add_asmodeus(player, player.global_position.x + ASMODEUS_AT)
	asmodeus.talk(ASMODEUS_CUE)
	var tallest_bar: Array[float] = [0.0]
	var watch: Callable = func() -> void: tallest_bar[0] = maxf(tallest_bar[0], _framing.get_bar_height())
	physics_frame.connect(watch)
	await wait_frames(_frames(_framing.enter_time))
	var directed: bool = _camera.is_directed()
	var closed: bool = not (player.get_node(^"Hurtbox") as Hurtbox).takes_hits()
	await _end_talk(asmodeus)
	physics_frame.disconnect(watch)
	_framing.show_bars = true
	return report(tallest_bar[0] == 0.0 and directed and closed,
			"Show Bars off: tallest bar %.1f px (0), camera framing %s, hurtbox closed %s"
			% [tallest_bar[0], directed, closed])


func _a_cutscene_keeps_the_camera_and_the_hurtbox(player: Player) -> bool:
	var hurtbox: Hurtbox = player.get_node(^"Hurtbox") as Hurtbox
	_camera.direct()
	var asmodeus: Asmodeus = _add_asmodeus(player, player.global_position.x + ASMODEUS_AT)
	asmodeus.talk(ASMODEUS_CUE)
	await wait_frames(_frames(_framing.enter_time))
	var during: bool = not _framing.is_framing() and hurtbox.takes_hits()
	await _end_talk(asmodeus)
	var after: bool = _camera.is_directed()
	_camera.release()
	return report(during and after,
			"A talk in a cutscene: framing and hurtbox left alone %s, camera still the cutscene's after %s"
			% [during, after])


## As phase 2's look at gate B after Asmodeus's offer: the cutscene starts on the physics frame after the
## talk ends, from the talk's shot, and comes back to where the camera was on the man before the talk.
func _a_cutscene_after_a_talk_comes_back_to_the_man(player: Player) -> bool:
	await wait_frames(120)
	var asmodeus: Asmodeus = _add_asmodeus(player, player.global_position.x + ASMODEUS_AT)
	var cutscene: CameraCutscene = _make_look(player)
	asmodeus.talk_ended.connect(cutscene.play_after_talk)
	var home: Vector2 = _camera.global_position
	var home_zoom: float = _camera.zoom.x
	asmodeus.talk(ASMODEUS_CUE)
	await wait_frames(_frames(_framing.enter_time))
	var talk_zoom: float = _camera.zoom.x
	var end_pose: Array = []
	cutscene.finished.connect(func() -> void: end_pose.append_array([_camera.global_position, _camera.zoom.x]))
	_balloon_of(asmodeus).queue_free()
	var played: bool = await wait_until(cutscene.is_playing, 10)
	await wait_until(func() -> bool: return not end_pose.is_empty())
	asmodeus.queue_free()
	cutscene.queue_free()
	await wait_frames(60)
	var back: bool = (played and not end_pose.is_empty() and (end_pose[0] as Vector2).distance_to(home) < TOLERANCE
			and absf((end_pose[1] as float) - home_zoom) < TOLERANCE)
	return report(back and talk_zoom > home_zoom + 0.1,
			"A cutscene after a talk: played %s; zoom %.3f before the talk, %.3f in it; the cutscene ended at %s, zoom %s (%s, %.3f)"
			% [played, home_zoom, talk_zoom, end_pose[0] if not end_pose.is_empty() else "-",
			end_pose[1] if not end_pose.is_empty() else "-", home, home_zoom])


## With Reduce Motion the camera stays free, so a cutscene can start during the talk: the talk ending
## before it does not open the hurtbox under it; the cutscene's end does.
func _a_cutscene_during_a_talk_keeps_the_hurtbox_closed(player: Player) -> bool:
	var hurtbox: Hurtbox = player.get_node(^"Hurtbox") as Hurtbox
	_framing.reduce_motion = true
	var asmodeus: Asmodeus = _add_asmodeus(player, player.global_position.x + ASMODEUS_AT)
	var cutscene: CameraCutscene = _make_look(player)
	asmodeus.talk(ASMODEUS_CUE)
	await wait_frames(SLACK_FRAMES)
	var played: bool = cutscene.play()
	_balloon_of(asmodeus).queue_free()
	await wait_frames(SLACK_FRAMES)
	var closed_after_talk: bool = cutscene.is_playing() and not hurtbox.takes_hits()
	await wait_until(func() -> bool: return not cutscene.is_playing())
	await wait_frames(SLACK_FRAMES)
	var open_after_cutscene: bool = hurtbox.takes_hits()
	asmodeus.queue_free()
	cutscene.queue_free()
	_framing.reduce_motion = false
	await wait_frames(60)
	return report(played and closed_after_talk and open_after_cutscene,
			"A cutscene during a talk: played %s, hurtbox closed after the talk with the cutscene on %s, open after the cutscene %s"
			% [played, closed_after_talk, open_after_cutscene])


## As while a demon holds the man: a hurtbox closed by something else before the talk stays closed after it.
func _a_hurtbox_closed_before_the_talk_stays_closed(player: Player) -> bool:
	var hurtbox: Hurtbox = player.get_node(^"Hurtbox") as Hurtbox
	hurtbox.set_closed(true)
	var asmodeus: Asmodeus = _add_asmodeus(player, player.global_position.x + ASMODEUS_AT)
	asmodeus.talk(ASMODEUS_CUE)
	await wait_frames(_frames(_framing.enter_time))
	await _end_talk(asmodeus)
	var still_closed: bool = not hurtbox.takes_hits()
	hurtbox.set_closed(false)
	return report(still_closed, "A hurtbox closed before the talk is still closed after it %s" % still_closed)


## Half way back to the man, a cutscene takes the camera: the way back stops there, and the cutscene
## ends on the camera's pose from before the talk, not on the talk's shot nor where it was taken.
func _a_cutscene_during_the_return_takes_the_camera_from_there(player: Player) -> bool:
	await wait_frames(120)
	var asmodeus: Asmodeus = _add_asmodeus(player, player.global_position.x + ASMODEUS_AT)
	var cutscene: CameraCutscene = _make_look(player)
	var home: Vector2 = _camera.global_position
	var home_zoom: float = _camera.zoom.x
	asmodeus.talk(ASMODEUS_CUE)
	await wait_frames(_frames(_framing.enter_time))
	_balloon_of(asmodeus).queue_free()
	await wait_frames(ceili(_framing.return_time * 0.5 * Engine.physics_ticks_per_second))
	var returning: bool = _framing.is_returning()
	var taken_at: float = _camera.zoom.x
	var end_pose: Array = []
	cutscene.finished.connect(func() -> void: end_pose.append_array([_camera.global_position, _camera.zoom.x]))
	var played: bool = cutscene.play()
	await wait_frames(1)
	var stopped: bool = not _framing.is_returning() and _camera.is_directed()
	await wait_until(func() -> bool: return not end_pose.is_empty())
	asmodeus.queue_free()
	cutscene.queue_free()
	await wait_frames(60)
	var back: bool = (not end_pose.is_empty() and (end_pose[0] as Vector2).distance_to(home) < TOLERANCE
			and absf((end_pose[1] as float) - home_zoom) < TOLERANCE)
	return report(returning and played and stopped and back and taken_at > home_zoom + TOLERANCE,
			"A cutscene half way back: returning %s, played %s, the way back stopped %s; taken at zoom %.3f; ended at %s, zoom %s (%s, %.3f)"
			% [returning, played, stopped, taken_at, end_pose[0] if not end_pose.is_empty() else "-",
			end_pose[1] if not end_pose.is_empty() else "-", home, home_zoom])


## Half way back to the man, he walks on and another talk starts: when it ends, the camera comes back to
## its pose from before the first talk, moved as far as he moved since, so it is given back with no slide.
func _a_talk_during_the_return_comes_back_to_where_the_man_went(player: Player) -> bool:
	await wait_frames(120)
	var asmodeus: Asmodeus = _add_asmodeus(player, player.global_position.x + ASMODEUS_AT)
	var home: Vector2 = _camera.global_position
	var home_zoom: float = _camera.zoom.x
	asmodeus.talk(ASMODEUS_CUE)
	await wait_frames(_frames(_framing.enter_time))
	_balloon_of(asmodeus).queue_free()
	await wait_frames(ceili(_framing.return_time * 0.5 * Engine.physics_ticks_per_second))
	var returning: bool = _framing.is_returning()
	player.global_position.x += MAN_STEP
	await wait_frames(SLACK_FRAMES)
	asmodeus.talk(ASMODEUS_CUE)
	await wait_frames(_frames(_framing.enter_time))
	var framed_again: bool = _framing.is_framing()
	_balloon_of(asmodeus).queue_free()
	await wait_frames(ceili(_framing.return_time * Engine.physics_ticks_per_second) + 1)
	var expected: Vector2 = home + Vector2(MAN_STEP, 0.0)
	var landed: Vector2 = _camera.global_position
	var given_back: bool = not _camera.is_directed()
	asmodeus.queue_free()
	await wait_frames(60)
	return report(returning and framed_again and given_back and landed.distance_to(expected) < 1.0
			and absf(_camera.zoom.x - home_zoom) < TOLERANCE,
			"A talk half way back: returning %s, framed again %s, given back %s at %s (%s: before the talk, moved %.0f px as he did)"
			% [returning, framed_again, given_back, landed, expected, MAN_STEP])


## A quick look to the man's right that keeps the zoom, as phase 2's look at gate B.
func _make_look(player: Player) -> CameraCutscene:
	var cutscene: CameraCutscene = CameraCutscene.new()
	cutscene.camera = _camera
	cutscene.player = player
	cutscene.return_time = LOOK_RETURN
	var shot: CameraShot = CameraShot.new()
	shot.travel_time = LOOK_TRAVEL
	shot.hold_time = LOOK_HOLD
	shot.keep_zoom = true
	var frame: ReferenceRect = ReferenceRect.new()
	frame.position = LOOK_VIEW.position
	frame.size = LOOK_VIEW.size
	shot.add_child(frame)
	cutscene.add_child(shot)
	root.add_child(cutscene)
	return cutscene


func _add_velvet(player: Player, x: float) -> TutorialDemon:
	var velvet: TutorialDemon = VELVET_SCENE.instantiate() as TutorialDemon
	velvet.player = player
	velvet.crucifix = player.get_node(^"Crucifix") as Crucifix
	velvet.walk_reach = 0.0
	velvet.position = Vector2(x, 0.0)
	root.add_child(velvet)
	return velvet


func _add_asmodeus(player: Player, x: float) -> Asmodeus:
	var asmodeus: Asmodeus = ASMODEUS_SCENE.instantiate() as Asmodeus
	asmodeus.player = player
	asmodeus.position = Vector2(x, 0.0)
	root.add_child(asmodeus)
	return asmodeus


## Frees the balloon, waits for the bars to go and the man to be let go, and takes Asmodeus out.
func _end_talk(talker: Node) -> void:
	var balloon: DialogueBalloon = _balloon_of(talker)
	if balloon != null:
		balloon.queue_free()
	await wait_frames(_frames(_framing.bars_out_time))
	talker.queue_free()
	await wait_frames(60)


func _balloon_of(talker: Node) -> DialogueBalloon:
	for child: Node in talker.get_children():
		if child is DialogueBalloon:
			return child as DialogueBalloon
	return null


## Whether every figure shows between the wheel's bottom, with Head Gap, and the bottom bar, with Feet Gap,
## and inside the screen across.
func _in_the_room(balloon: DialogueBalloon, figures: Array[Node2D]) -> bool:
	var top: float = balloon.get_answers_rect().end.y + _framing.head_gap
	var bottom: float = SCREEN.y * (1.0 - _framing.bar_share) - _framing.feet_gap
	for figure: Node2D in figures:
		var rect: Rect2 = TalkFraming.drawn_rect(figure)
		var head: Vector2 = (rect.position - _camera.global_position) * _camera.zoom.x + SCREEN / 2.0
		var feet: Vector2 = (rect.end - _camera.global_position) * _camera.zoom.x + SCREEN / 2.0
		if (head.y < top - SCREEN_TOLERANCE or feet.y > bottom + SCREEN_TOLERANCE or head.x < 0.0
				or feet.x > SCREEN.x):
			print("  %s: head at %s, feet at %s; room from y %.1f to %.1f" % [figure.name, head, feet, top, bottom])
			return false
	return true


func _frames(seconds: float) -> int:
	return ceili(seconds * Engine.physics_ticks_per_second) + SLACK_FRAMES
