# Checks the camera cutscene, CameraCutscene with CameraShot children, in a small world and in level 1. Walking
# into its Trigger Zone starts it: the camera stops following the man, who stands still, can't raise the
# crucifix and takes no hits. The camera gets to each shot's framing (the View whole, as close as the screen
# allows) in its Travel Time, says arrived once, pulls back half way between two shots too far apart for one
# screen, and ends where it started, given back to the man, who moves again on the next frame. With an Event it marks it once and
# never plays again, also as another cutscene with the same Event. Skip Action does nothing before Skip Delay;
# after it, it ends the cutscene at once, the shots not reached still say arrived, and the press does not make
# the man jump. A shot with Keep Zoom is reached with no zoom at all; with Motion Blur the screen streaks while
# the camera moves, no more than Max Blur, and not while it holds or after; and what the move is about to show
# wakes before the camera comes. An unlocker with a cutscene opens its gates when the camera gets to the first
# shot, and at once when the cutscene was seen. In level 1, phase 1 has no cutscene; phase 2's, a quick look of
# about 3 s, starts when Asmodeus's offer ends, not on walking in nor after another talk, shows gate B open, then
# shut by the end, with no zoom and a streak, and hands the camera back. With the level started over in phase 2,
# it plays again after the first death there, Replay Delay after the start, and not with no death nor after the
# second; unlocker B's look at gate B opening, about 3 s with no zoom, plays at every use, in every new copy.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_camera_cutscene.gd
extends "res://tests/support/player_test.gd"

const CAMERA_SCENE: PackedScene = preload("res://scenes/others/camera/game_camera.tscn")
const GATE_SCENE: PackedScene = preload("res://scenes/objects/gates/gate.tscn")
const UNLOCKER_SCENE: PackedScene = preload("res://scenes/objects/gates/gate_unlocker.tscn")
const LEVEL1_SCENE: String = "res://scenes/levels/lust/level1.tscn"
const START: Vector2 = Vector2(0.0, -2.0)
## The trigger zone, a little to the man's right.
const TRIGGER: Rect2 = Rect2(300.0, -600.0, 600.0, 600.0)
## Two framings far apart: no screen shows both.
const VIEW_A: Rect2 = Rect2(6000.0, -1400.0, 1600.0, 900.0)
const VIEW_B: Rect2 = Rect2(30000.0, -1400.0, 3200.0, 1800.0)
const TRAVEL: float = 1.0
const HOLD: float = 0.5
const RETURN: float = 1.0
## How far the arrival may be from Travel Time, in frames, and the camera from where it should be, in px.
const FRAME_TOLERANCE: int = 2
const PLACE_TOLERANCE: float = 0.5
const EVENT: StringName = &"test_cutscene_seen"
const PAN_EVENT: StringName = &"test_pan_seen"
## Frames the man is held while running against it, and frames given for him to move again.
const HELD_FRAMES: int = 30
const MOVE_FRAMES: int = 10
## Where the man respawns in level 1's phase 2: inside ZoneP2StartRoom.
const PHASE_2_START: Vector2 = Vector2(16872.0, 11856.0)
## How long level 1's quick looks at gate B last in all, phase 2's and unlocker B's, in s, and how far from it
## they may be.
const PHASE_2_TOTAL: float = 3.0
const TOTAL_TOLERANCE: float = 0.05
## The streak for the small world's look with no zoom.
const BLUR: float = 0.5
const MAX_BLUR: float = 30.0

var _camera: GameCamera


## Something far off the screen that the camera's ActivityTracker runs, as a dog.
class FarThing:
	extends Node2D

	func _ready() -> void:
		ActivityTracker.join(self)

	func get_activity_rect() -> Rect2:
		return Rect2(global_position - Vector2(50.0, 50.0), Vector2(100.0, 100.0))


func _initialize() -> void:
	# Without a window the root is 64 x 64 px and the Expand aspect makes it 1920 x 1920: set the screen first.
	await process_frame
	root.size = Vector2i(int(ProjectSettings.get_setting("display/window/size/viewport_width")),
			int(ProjectSettings.get_setting("display/window/size/viewport_height")))
	await process_frame
	make_platform(-4000.0, 40000.0)
	var results: Array[bool] = []
	var player: Player = await spawn_on_floor(START)
	if player == null:
		results.append(report(false, "The player never landed"))
		finish(results)
		return
	_camera = CAMERA_SCENE.instantiate() as GameCamera
	_camera.player = player
	root.add_child(_camera)
	_camera.make_current()
	await physics_frame
	var stand_in: StandInInput = put_a_stand_in(player)
	results.append(await _walking_in_plays_it_and_the_camera_comes_back(player, stand_in))
	results.append(await _with_its_event_seen_it_never_plays_again(player))
	results.append(await _skip_waits_its_delay_then_ends_it_and_does_not_jump(player, stand_in))
	results.append(await _keep_zoom_streaks_the_move_and_wakes_the_way(player))
	results.append(await _an_unlocker_opens_its_gates_when_the_camera_gets_there(player))
	await remove_player(player)
	_camera.queue_free()
	await physics_frame
	results.append(await _level_1_has_its_cutscenes_and_phase_2_locks_gate_b())
	results.append(await _level_1_replays_phase_2_once_and_pans_to_gate_b_every_time())
	finish(results)


func _walking_in_plays_it_and_the_camera_comes_back(player: Player, stand_in: StandInInput) -> bool:
	var zone: CameraZone = _make_zone(TRIGGER)
	var cutscene: CameraCutscene = _make_cutscene(player, zone, EVENT)
	var arrivals: Array[int] = [-1, -1, 0]
	var marks: Array[int] = [0]
	cutscene.event_marked.connect(func() -> void: marks[0] += 1)
	for index: int in 2:
		var shot: CameraShot = cutscene.get_child(index) as CameraShot
		shot.arrived.connect(func() -> void:
				arrivals[index] = Engine.get_physics_frames()
				arrivals[2] += 1)
	var end_pose: Array = []
	cutscene.finished.connect(func() -> void: end_pose.append_array([_camera.global_position, _camera.zoom.x,
			_camera.is_directed()]))
	stand_in.run_direction = 1.0
	var started: bool = await wait_until(cutscene.is_playing, MAX_FRAMES)
	var start_frame: int = Engine.get_physics_frames()
	var home: Vector2 = _camera.global_position
	var home_zoom: float = _camera.zoom.x
	var held_at: float = player.position.x
	await wait_frames(HELD_FRAMES)
	var hurtbox: Hurtbox = player.get_node(^"Hurtbox") as Hurtbox
	var crucifix: Crucifix = player.get_node(^"Crucifix") as Crucifix
	var held: bool = (absf(player.position.x - held_at) <= 1.0 and not hurtbox.takes_hits() and crucifix.is_blocked()
			and _camera.is_directed())
	await wait_until(func() -> bool: return arrivals[0] >= 0, MAX_FRAMES)
	var at_a: bool = _shows(VIEW_A)
	var a_frames: int = arrivals[0] - start_frame
	var closest_between: Array[float] = [INF]
	var watch: Callable = func() -> void: closest_between[0] = minf(closest_between[0], _camera.zoom.x)
	physics_frame.connect(watch)
	await wait_until(func() -> bool: return arrivals[1] >= 0, MAX_FRAMES)
	physics_frame.disconnect(watch)
	var at_b: bool = _shows(VIEW_B)
	var pulled_back: bool = closest_between[0] < minf(_zoom_for(VIEW_A), _zoom_for(VIEW_B)) * 0.9
	var finished: bool = await wait_until(func() -> bool: return not cutscene.is_playing(), MAX_FRAMES)
	var back: bool = (end_pose.size() == 3 and (end_pose[0] as Vector2).distance_to(home) <= PLACE_TOLERANCE
			and absf(end_pose[1] - home_zoom) < 0.001 and not end_pose[2])
	var moving_from: float = player.position.x
	await wait_frames(MOVE_FRAMES)
	var free_again: bool = (player.position.x > moving_from + 1.0 and hurtbox.takes_hits() and not crucifix.is_blocked())
	stand_in.run_direction = 0.0
	var expected: int = roundi(TRAVEL * Engine.physics_ticks_per_second)
	var progress: GameProgress = root.get_node(^"GameState") as GameProgress
	return report(started and held and at_a and absi(a_frames - expected) <= FRAME_TOLERANCE and at_b and pulled_back
			and finished and back and free_again and arrivals[2] == 2 and marks[0] == 1 and progress.has_event(EVENT),
			("Walking in: started %s, man held %s, shot A shown %s after %d frames (%d expected), shot B shown %s, "
			+ "pulled back to zoom %.3f between (ends %.3f, %.3f) %s, finished %s, camera back and released %s, "
			+ "man free again %s, %d arrival(s), event marked %d time(s)")
			% [started, held, at_a, a_frames, expected, at_b, closest_between[0], _zoom_for(VIEW_A), _zoom_for(VIEW_B),
			pulled_back, finished, back, free_again, arrivals[2], marks[0]])


## The man is still in the trigger zone: the cutscene does not start again, nor does another with the same Event.
func _with_its_event_seen_it_never_plays_again(player: Player) -> bool:
	var first: CameraCutscene = root.get_node(^"Cutscene") as CameraCutscene
	player.global_position = TRIGGER.get_center()
	await wait_frames(MOVE_FRAMES)
	var again: bool = first.is_playing()
	var other: CameraCutscene = _make_cutscene(player, null, EVENT)
	var played: bool = other.play()
	var seen: bool = other.was_seen()
	other.queue_free()
	first.queue_free()
	player.global_position = START
	await wait_frames(MOVE_FRAMES)
	return report(not again and not played and seen,
			"Seen: plays again in its zone %s, another with the same event plays %s, says seen %s" % [again, played, seen])


func _skip_waits_its_delay_then_ends_it_and_does_not_jump(player: Player, stand_in: StandInInput) -> bool:
	var cutscene: CameraCutscene = _make_cutscene(player, null, &"")
	var arrivals: Array[int] = [0]
	for shot: Node in cutscene.get_children():
		(shot as CameraShot).arrived.connect(func() -> void: arrivals[0] += 1)
	var home: Vector2 = _camera.global_position
	var end_pose: Array = []
	cutscene.finished.connect(func() -> void: end_pose.append_array([_camera.global_position, _camera.is_directed()]))
	cutscene.play()
	await wait_frames(PRESS_DELAY_FRAMES)
	await _press_jump(stand_in)
	var early_skip: bool = not cutscene.is_playing()
	await wait_frames(roundi(cutscene.skip_delay * Engine.physics_ticks_per_second))
	var floor_y: float = player.position.y
	var ended: Array[int] = [-1]
	cutscene.finished.connect(func() -> void: ended[0] = Engine.get_physics_frames())
	await _press_jump(stand_in)
	var skipped: bool = not cutscene.is_playing() and ended[0] >= 0
	var highest: float = floor_y
	for _frame: int in MOVE_FRAMES * 3:
		await physics_frame
		highest = minf(highest, player.position.y)
	var jumped: bool = highest < floor_y - 1.0
	var back: bool = (end_pose.size() == 2 and (end_pose[0] as Vector2).distance_to(home) <= PLACE_TOLERANCE
			and not end_pose[1])
	cutscene.queue_free()
	return report(not early_skip and skipped and arrivals[0] == 2 and back and not jumped,
			"Skip: before the delay %s, after it %s, %d shot(s) said arrived, camera back %s, the man jumped %s"
			% [early_skip, skipped, arrivals[0], back, jumped])


## One shot at A with Keep Zoom and Motion Blur, and something by A, far off the screen, asleep before it starts.
func _keep_zoom_streaks_the_move_and_wakes_the_way(player: Player) -> bool:
	var tracker: ActivityTracker = _camera.get_node(^"%ActivityTracker") as ActivityTracker
	var blur: MotionBlur = _camera.get_node(^"%MotionBlur") as MotionBlur
	var thing: FarThing = FarThing.new()
	thing.position = VIEW_A.get_center()
	root.add_child(thing)
	var slept: bool = await wait_until(tracker.is_asleep.bind(thing), MAX_FRAMES)
	var only_a: Array[Rect2] = [VIEW_A]
	var cutscene: CameraCutscene = _make_cutscene(player, null, &"", only_a)
	cutscene.zoom_out_to_travel = false
	cutscene.motion_blur = BLUR
	cutscene.max_blur = MAX_BLUR
	var shot: CameraShot = cutscene.get_child(0) as CameraShot
	shot.keep_zoom = true
	var home_zoom: float = _camera.zoom.x
	var arrived: Array[bool] = [false]
	shot.arrived.connect(func() -> void: arrived[0] = true)
	cutscene.play()
	await wait_frames(2)
	var woke_early: bool = not tracker.is_asleep(thing) and not arrived[0]
	var widest: Array[float] = [0.0, 0.0]
	var zoom_off: Array[float] = [0.0]
	var watch: Callable = func() -> void:
		zoom_off[0] = maxf(zoom_off[0], absf(_camera.zoom.x - home_zoom))
		if not arrived[0]:
			widest[0] = maxf(widest[0], blur.get_streak().length())
	physics_frame.connect(watch)
	await wait_until(func() -> bool: return arrived[0], MAX_FRAMES)
	var centred: bool = (_camera.global_position.distance_to(_camera.centre_to_show(VIEW_A, home_zoom))
			<= PLACE_TOLERANCE)
	await wait_frames(roundi(HOLD * Engine.physics_ticks_per_second / 2.0))
	widest[1] = blur.get_streak().length()
	await wait_until(func() -> bool: return not cutscene.is_playing(), MAX_FRAMES)
	physics_frame.disconnect(watch)
	var cleared: bool = blur.get_streak() == Vector2.ZERO and tracker.extra_views.is_empty()
	cutscene.queue_free()
	thing.queue_free()
	await wait_frames(MOVE_FRAMES)
	return report(slept and woke_early and zoom_off[0] < 0.001 and centred and widest[0] > 1.0
			and widest[0] <= MAX_BLUR + 0.001 and widest[1] == 0.0 and cleared,
			("Keep Zoom: far thing asleep first %s, awake before the camera got there %s, zoom moved %.4f, centred on "
			+ "A %s, widest streak moving %.1f px (max %.0f), streak holding %.1f, streak and way cleared after %s")
			% [slept, woke_early, zoom_off[0], centred, widest[0], MAX_BLUR, widest[1], cleared])


func _an_unlocker_opens_its_gates_when_the_camera_gets_there(player: Player) -> bool:
	var cutscene: CameraCutscene = _make_cutscene(player, null, PAN_EVENT)
	var gate: Gate = _make_gate(Vector2(2000.0, 0.0))
	var unlocker: GateUnlocker = _make_unlocker(Vector2(200.0, 0.0), gate, cutscene)
	var shut_on_start: Array[bool] = [false]
	var open_on_arrival: Array[bool] = [false]
	cutscene.started.connect(func() -> void: shut_on_start[0] = not gate.is_unlocked())
	var first_shot: CameraShot = cutscene.get_child(0) as CameraShot
	first_shot.arrived.connect(func() -> void: open_on_arrival[0] = gate.is_unlocked(), CONNECT_DEFERRED)
	player.global_position = Vector2(200.0, -2.0)
	await wait_frames(MOVE_FRAMES)
	await _press_interact()
	var playing: bool = cutscene.is_playing() and unlocker.is_activated()
	await wait_until(func() -> bool: return not cutscene.is_playing(), MAX_FRAMES)
	var other_gate: Gate = _make_gate(Vector2(2400.0, 0.0))
	var other: GateUnlocker = _make_unlocker(Vector2(200.0, 0.0), other_gate, cutscene)
	await wait_frames(MOVE_FRAMES)
	unlocker.queue_free()
	await _press_interact()
	var at_once: bool = other.is_activated() and other_gate.is_unlocked() and not cutscene.is_playing()
	for node: Node in [cutscene, gate, other_gate, other]:
		node.queue_free()
	player.global_position = START
	await wait_frames(MOVE_FRAMES)
	return report(playing and shut_on_start[0] and open_on_arrival[0] and at_once,
			"Unlocker: Interact plays its cutscene %s, gate shut as it starts %s, opening once the camera is there %s, "
			% [playing, shut_on_start[0], open_on_arrival[0]] + "seen, the next one opens at once %s" % at_once)


func _level_1_has_its_cutscenes_and_phase_2_locks_gate_b() -> bool:
	var level: Node2D = (load(LEVEL1_SCENE) as PackedScene).instantiate() as Node2D
	root.add_child(level)
	await physics_frame
	var overview_gone: bool = level.get_node_or_null(^"Cutscenes/Phase1Overview") == null
	var intro: CameraCutscene = level.get_node(^"Cutscenes/Phase2Intro") as CameraCutscene
	var opening: CameraCutscene = level.get_node(^"Cutscenes/GateBOpening") as CameraCutscene
	var unlocker: GateUnlocker = level.get_node(^"GateUnlockers/UnlockerB") as GateUnlocker
	var gate: Gate = level.get_node(^"Gates/GateB") as Gate
	var player: Player = level.get_node(^"Player") as Player
	var asmodeus: Asmodeus = level.get_node(^"Asmodeus") as Asmodeus
	var camera: GameCamera = level.get_node(^"GameCamera") as GameCamera
	var blur: MotionBlur = camera.get_node(^"%MotionBlur") as MotionBlur
	var wired: bool = (overview_gone and intro.trigger_zone == null and intro.talk_cue == "asmodeus_offer"
			and asmodeus.talk_ended.is_connected(intro.play_after_talk) and not intro.event.is_empty()
			and intro.replay_phase == 2 and not intro.replay_event.is_empty()
			and opening.trigger_zone == null and unlocker.cutscene == opening and opening.event.is_empty())
	var quick: bool = _is_quick_look(intro, PHASE_2_TOTAL) and _is_quick_look(opening, PHASE_2_TOTAL)
	# Walking into phase 2's start room no longer starts it, nor does the end of another talk.
	player.global_position = PHASE_2_START
	player.reset_physics_interpolation()
	await wait_frames(MOVE_FRAMES * 3)
	var on_walking_in: bool = intro.is_playing()
	asmodeus.talk_ended.emit("asmodeus_deaths")
	var after_other_talk: bool = intro.is_playing()
	var shut_at: Vector2 = gate.position
	var open_seen: Array[bool] = [false]
	intro.started.connect(func() -> void: open_seen[0] = gate.is_unlocked(), CONNECT_DEFERRED)
	var home_zoom: float = camera.zoom.x
	var zoom_off: Array[float] = [0.0]
	var widest: Array[float] = [0.0]
	var watch: Callable = func() -> void:
		zoom_off[0] = maxf(zoom_off[0], absf(camera.zoom.x - home_zoom))
		widest[0] = maxf(widest[0], blur.get_streak().length())
	physics_frame.connect(watch)
	asmodeus.talk_ended.emit("asmodeus_offer")
	var started: bool = intro.is_playing()
	var start_frame: int = Engine.get_physics_frames()
	var finished: bool = await wait_until(func() -> bool: return not intro.is_playing(), MAX_FRAMES * 3)
	var seconds: float = float(Engine.get_physics_frames() - start_frame) / Engine.physics_ticks_per_second
	physics_frame.disconnect(watch)
	await wait_frames(MOVE_FRAMES)
	var shut: bool = not gate.is_unlocked() and gate.position.is_equal_approx(shut_at)
	var released: bool = not camera.is_directed() and blur.get_streak() == Vector2.ZERO
	level.queue_free()
	await physics_frame
	return report(wired and quick and not on_walking_in and not after_other_talk and started and open_seen[0]
			and finished and absf(seconds - PHASE_2_TOTAL) <= 2.0 / Engine.physics_ticks_per_second
			and zoom_off[0] < 0.001 and widest[0] > 1.0 and shut and released,
			("Level 1: no phase 1 cutscene and the others wired %s, phase 2's and gate B's quick looks of %.1f s "
			+ "with no zoom %s, phase 2's starts on walking in %s, after another talk %s, after the offer %s, gate B "
			+ "open as it starts %s, finished %s after %.2f s, zoom moved %.4f, widest streak %.1f px, gate B shut at "
			+ "its place %s, camera released %s")
			% [wired, PHASE_2_TOTAL, quick, on_walking_in, after_other_talk, started, open_seen[0],
			finished, seconds, zoom_off[0], widest[0], shut, released])


## Level 1 started over in phase 2, as after a death there, with her offer answered and phase 2's cutscene seen:
## with no death in phase 2 the cutscene does not play again; after the first death it does, Replay Delay after
## the start, marks its Replay Event and shows gate B open, then shut; after the second, it does not. Unlocker
## B's look at gate B plays in each of the three copies, as every use after a death.
func _level_1_replays_phase_2_once_and_pans_to_gate_b_every_time() -> bool:
	var progress: GameProgress = root.get_node(^"GameState") as GameProgress
	var stats: GameRunStats = root.get_node(^"RunStats") as GameRunStats
	progress.reset()
	for event: StringName in [&"lust_phase_2_reached", &"answered_asmodeus_offer", &"lust_phase_2_intro_seen"]:
		progress.mark_event(event)
	var scene: PackedScene = load(LEVEL1_SCENE) as PackedScene
	var pans: Array[bool] = []

	# No death in phase 2 yet: it does not play again.
	var level: Node2D = scene.instantiate() as Node2D
	root.add_child(level)
	var intro: CameraCutscene = level.get_node(^"Cutscenes/Phase2Intro") as CameraCutscene
	var replay_frames: int = roundi(intro.replay_delay * Engine.physics_ticks_per_second)
	await wait_frames(replay_frames + MOVE_FRAMES)
	var with_no_death: bool = intro.is_playing()
	var in_phase_2: bool = stats.get_phase() == 2
	pans.append(await _unlocker_b_pans(level))
	level.queue_free()
	await physics_frame

	# His first death in phase 2: it plays again, once the screen is back.
	stats.record_death(&"test_phase_2_death")
	level = scene.instantiate() as Node2D
	intro = level.get_node(^"Cutscenes/Phase2Intro") as CameraCutscene
	var gate: Gate = level.get_node(^"Gates/GateB") as Gate
	var added_at: int = Engine.get_physics_frames()
	var started_at: Array[int] = [-1]
	var open_seen: Array[bool] = [false]
	var on_start: Callable = func() -> void:
		started_at[0] = Engine.get_physics_frames()
		open_seen[0] = gate.is_unlocked()
	intro.started.connect(on_start, CONNECT_DEFERRED)
	root.add_child(level)
	var replayed: bool = await wait_until(intro.is_playing, replay_frames + MOVE_FRAMES)
	var waited: int = started_at[0] - added_at
	var marked: bool = progress.has_event(intro.replay_event)
	var finished: bool = await wait_until(func() -> bool: return not intro.is_playing(), MAX_FRAMES * 3)
	await wait_frames(MOVE_FRAMES)
	var shut: bool = not gate.is_unlocked()
	pans.append(await _unlocker_b_pans(level))
	level.queue_free()
	await physics_frame

	# His second death there: no more.
	stats.record_death(&"test_phase_2_death")
	level = scene.instantiate() as Node2D
	root.add_child(level)
	intro = level.get_node(^"Cutscenes/Phase2Intro") as CameraCutscene
	await wait_frames(replay_frames + MOVE_FRAMES)
	var after_second: bool = intro.is_playing()
	pans.append(await _unlocker_b_pans(level))
	level.queue_free()
	await physics_frame
	return report(in_phase_2 and not with_no_death and replayed and absi(waited - replay_frames) <= FRAME_TOLERANCE
			and marked and open_seen[0] and finished and shut and not after_second and pans.size() == 3
			and not pans.has(false),
			("Level 1 started over in phase 2 %s: plays again with no death %s; after the first %s, %d frames after "
			+ "the start (%d expected), marked %s, gate B open as it starts %s, finished %s, gate B shut %s; after "
			+ "the second %s; unlocker B's look in each copy %s")
			% [in_phase_2, with_no_death, replayed, waited, replay_frames, marked, open_seen[0], finished, shut,
			after_second, pans])


## Unlocker B used in level: its cutscene plays, with no zoom, gate B is open by its end, and the camera is
## handed back.
func _unlocker_b_pans(level: Node2D) -> bool:
	var opening: CameraCutscene = level.get_node(^"Cutscenes/GateBOpening") as CameraCutscene
	var unlocker: GateUnlocker = level.get_node(^"GateUnlockers/UnlockerB") as GateUnlocker
	var gate: Gate = level.get_node(^"Gates/GateB") as Gate
	var camera: GameCamera = level.get_node(^"GameCamera") as GameCamera
	var home_zoom: float = camera.zoom.x
	var zoom_off: Array[float] = [0.0]
	var watch: Callable = func() -> void: zoom_off[0] = maxf(zoom_off[0], absf(camera.zoom.x - home_zoom))
	physics_frame.connect(watch)
	unlocker.activate()
	var playing: bool = opening.is_playing()
	var finished: bool = await wait_until(func() -> bool: return not opening.is_playing(), MAX_FRAMES * 3)
	physics_frame.disconnect(watch)
	return playing and finished and zoom_off[0] < 0.001 and gate.is_unlocked() and not camera.is_directed()


## Whether cutscene is one shot with Keep Zoom and no pull back, lasting total seconds in all, with a streak.
func _is_quick_look(cutscene: CameraCutscene, total: float) -> bool:
	var shots: Array[Node] = cutscene.get_children()
	if shots.size() != 1:
		return false
	var shot: CameraShot = shots[0] as CameraShot
	return (shot.keep_zoom and not cutscene.zoom_out_to_travel and cutscene.motion_blur > 0.0
			and absf(shot.travel_time + shot.hold_time + cutscene.return_time - total) <= TOTAL_TOLERANCE)


func _make_zone(rect: Rect2) -> CameraZone:
	var zone: CameraZone = CameraZone.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = rect.size
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	collision.position = rect.get_center()
	zone.add_child(collision)
	zone.monitoring = false
	zone.monitorable = false
	root.add_child(zone)
	return zone


## A cutscene with a shot for each of views (two shots, A then B, by default), named Cutscene.
func _make_cutscene(player: Player, zone: CameraZone, event: StringName,
		views: Array[Rect2] = [VIEW_A, VIEW_B]) -> CameraCutscene:
	var cutscene: CameraCutscene = CameraCutscene.new()
	cutscene.name = &"Cutscene"
	cutscene.camera = _camera
	cutscene.player = player
	cutscene.trigger_zone = zone
	cutscene.event = event
	cutscene.return_time = RETURN
	for view: Rect2 in views:
		var shot: CameraShot = CameraShot.new()
		shot.travel_time = TRAVEL
		shot.hold_time = HOLD
		var frame: ReferenceRect = ReferenceRect.new()
		frame.position = view.position
		frame.size = view.size
		shot.add_child(frame)
		cutscene.add_child(shot)
	root.add_child(cutscene)
	return cutscene


func _make_gate(at: Vector2) -> Gate:
	var gate: Gate = GATE_SCENE.instantiate() as Gate
	gate.position = at
	root.add_child(gate)
	return gate


func _make_unlocker(at: Vector2, gate: Gate, cutscene: CameraCutscene) -> GateUnlocker:
	var unlocker: GateUnlocker = UNLOCKER_SCENE.instantiate() as GateUnlocker
	unlocker.position = at
	unlocker.gates = [gate] as Array[Gate]
	unlocker.cutscene = cutscene
	root.add_child(unlocker)
	return unlocker


## Whether the camera shows view as a shot frames it: as close as the screen allows, in the middle.
func _shows(view: Rect2) -> bool:
	var level: float = _zoom_for(view)
	return (absf(_camera.zoom.x - level) < 0.001
			and _camera.global_position.distance_to(_camera.centre_to_show(view, level)) <= PLACE_TOLERANCE)


func _zoom_for(view: Rect2) -> float:
	return _camera.zoom_to_show(view)


## Jump pressed for the cutscene, which reads the Input Map, and for the man, who reads the stand-in, on the
## same frame, then let go.
func _press_jump(stand_in: StandInInput) -> void:
	Input.action_press(&"jump")
	stand_in.press_jump()
	stand_in.hold_jump = true
	await physics_frame
	Input.action_release(&"jump")
	stand_in.hold_jump = false
	await physics_frame


func _press_interact() -> void:
	Input.action_press(&"interact")
	await wait_frames(PRESS_DELAY_FRAMES)
	Input.action_release(&"interact")
	await physics_frame
