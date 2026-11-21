# Checks that the GameCamera frames the player another way through a CameraBrain child and comes back to its
# own. With a brain in use, each physics step the camera goes where the brain says, at its zoom, and the brain
# starts from where the screen was. Back to its own way, the camera glides to the man no faster than Zone Change
# Speed and ends where it framed him before; what it knew of him from before the brain starts afresh: from the
# middle of the idle zoom, no jump of the zoom and no idle zoom until he stands still again; after a turn, the
# lead from nothing and the glide towards him; after he ran far, his body kept on the screen, as a man who moved
# and was not placed. A cutscene stops the brain while it directs the camera, and on release the brain ends and
# begins again from where the cutscene left the screen. A brain freed while in use sends the camera back to its
# own way and leaves the cycle, which goes own way, each brain in order, own way; an unknown name changes
# nothing, with brains or none.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_camera_brains.gd
extends "res://tests/support/player_test.gd"

const CAMERA_SCENE: PackedScene = preload("res://scenes/others/camera/game_camera.tscn")
const START: Vector2 = Vector2(0.0, -2.0)
## How far across the stand-in brain puts the screen from where the camera framed the man, and at what zoom.
const AWAY: Vector2 = Vector2(3000.0, 0.0)
const AWAY_ZOOM: float = 0.8
## Where a cutscene leaves the screen, from where the camera framed the man.
const CUTSCENE_OFFSET: Vector2 = Vector2(-500.0, 0.0)
## How far the camera may be from where it should be, in px, and how much faster than Zone Change Speed a step
## may go, in px per step, for rounding.
const PLACE_TOLERANCE: float = 0.5
const SPEED_TOLERANCE: float = 1.0
const ZOOM_TOLERANCE: float = 0.001
## Frames for the camera to settle on the man before each case: past Idle Delay, with the idle zoom near its
## end. Frames with a brain, and frames to glide back.
const SETTLE_FRAMES: int = 360
const BRAIN_FRAMES: int = 10
const GLIDE_FRAMES: int = 360
## The camera scene's own zoom, with no zone and the man not standing still.
const BASE_ZOOM: float = 1.0
## The most the zoom may change in the first step back, from rest: a spring that starts still moves it about
## 0.0001; one left with the speed it had before the brain, or set at once, moves it far more.
const FIRST_ZOOM_STEP: float = 0.001
## How long after the way back the zoom must stay at the base, with the man standing still: under Idle Delay.
const NO_IDLE_FRAMES: int = 72
## How long the man runs right before he turns, and how far the lead must have swung back before the brain
## takes over, as a share of where it was: mid-swing, with the lead and its speed far from rest.
const RUN_FRAMES: int = 60
const SWING_SHARE: float = 0.7
## Where the brain puts the screen in the turn case, from where the camera was: left of the man, who ran left,
## so the glide back goes right, against the speed the camera had.
const TURN_OFFSET: Vector2 = Vector2(-600.0, 0.0)
## The most the lead may be after the first step back, in px: from nothing, a spring moves it under 1 px.
const FIRST_LEAD: float = 3.0
## How far inside the screen's right edge the brain leaves the man's middle, in px, and below what speed he
## counts as stopped, in px/s.
const EDGE_INSET: float = 10.0
const STILL_SPEED: float = 1.0

var _camera: GameCamera


## A brain that frames a fixed point at a fixed zoom, and counts its steps, begins and ends.
class StandInBrain:
	extends CameraBrain

	var target: Vector2 = Vector2.ZERO
	var target_zoom: float = 1.0
	var began_at: Vector2 = Vector2.INF
	var began_zoom: float = 0.0
	var steps: int = 0
	var begins: int = 0
	var ends: int = 0
	var ended: bool = false

	func begin(_player: Player, _tiles: TileMapLayer, centre: Vector2, zoom_level: float) -> void:
		began_at = centre
		began_zoom = zoom_level
		begins += 1
		ended = false

	func advance(_delta: float) -> void:
		steps += 1

	func get_centre() -> Vector2:
		return target

	func get_zoom() -> float:
		return target_zoom

	func end() -> void:
		ends += 1
		ended = true


func _initialize() -> void:
	# Without a window the root is 64 x 64 px and the Expand aspect makes it 1920 x 1920: set the screen first.
	await process_frame
	root.size = Vector2i(int(ProjectSettings.get_setting("display/window/size/viewport_width")),
			int(ProjectSettings.get_setting("display/window/size/viewport_height")))
	await process_frame
	make_platform(-4000.0, 8000.0)
	var results: Array[bool] = []
	var player: Player = await spawn_on_floor(START)
	if player == null:
		results.append(report(false, "The player never landed"))
		finish(results)
		return
	var first: StandInBrain = StandInBrain.new()
	first.name = "StandInFirst"
	var second: StandInBrain = StandInBrain.new()
	second.name = "StandInSecond"
	var doomed: StandInBrain = StandInBrain.new()
	doomed.name = "StandInFreed"
	_camera = CAMERA_SCENE.instantiate() as GameCamera
	_camera.player = player
	_camera.add_child(first)
	_camera.add_child(second)
	_camera.add_child(doomed)
	root.add_child(_camera)
	await wait_frames(SETTLE_FRAMES)
	results.append(await _check_a_brain_moves_the_camera(first))
	results.append(await _check_the_way_back_glides(first))
	results.append(await _check_a_cutscene_pauses_the_brain(first))
	var stand_in: StandInInput = put_a_stand_in(player)
	results.append(await _check_the_way_back_from_the_idle_zoom(first, stand_in))
	results.append(await _check_the_way_back_after_a_turn(first, stand_in))
	results.append(await _check_the_way_back_after_moving_far(first, stand_in, player))
	results.append(await _check_a_freed_brain_sends_the_camera_back(doomed))
	results.append(_check_cycling(first, second))
	results.append(await _check_no_brains(player))
	finish(results)


## The brain starts from the screen, and from the next step the camera is where the brain says.
func _check_a_brain_moves_the_camera(brain: StandInBrain) -> bool:
	var own: Vector2 = _camera.global_position
	var own_zoom: float = _camera.zoom.x
	brain.target = own + AWAY
	brain.target_zoom = AWAY_ZOOM
	_camera.use_brain(brain)
	var began_right: bool = (brain.began_at.distance_to(own) <= PLACE_TOLERANCE
			and absf(brain.began_zoom - own_zoom) <= ZOOM_TOLERANCE)
	var steps_before: int = brain.steps
	await wait_frames(BRAIN_FRAMES)
	var followed: bool = (_camera.global_position.distance_to(brain.target) <= PLACE_TOLERANCE
			and absf(_camera.zoom.x - AWAY_ZOOM) <= ZOOM_TOLERANCE)
	var stepped: bool = brain.steps - steps_before >= BRAIN_FRAMES - 1
	return report(began_right and followed and stepped and _camera.get_framing_name() == String(brain.name),
			("A brain starts from the screen (%s at %.3f, began %s at %.3f) and the camera follows it: "
			+ "at %s, zoom %.3f, %d steps, %s")
			% [own, own_zoom, brain.began_at, brain.began_zoom, _camera.global_position, _camera.zoom.x,
			brain.steps - steps_before, _camera.get_framing_name()])


## Back to its own way, no step is faster than Zone Change Speed, and the camera ends where it framed the man.
func _check_the_way_back_glides(brain: StandInBrain) -> bool:
	var own: Vector2 = brain.target - AWAY
	_camera.use_brain(null)
	var most: float = _camera.stats.zone_change_speed / Engine.physics_ticks_per_second + SPEED_TOLERANCE
	var fastest: float = 0.0
	var previous: Vector2 = _camera.global_position
	for _frame: int in GLIDE_FRAMES:
		await physics_frame
		fastest = maxf(fastest, _camera.global_position.distance_to(previous))
		previous = _camera.global_position
	var back: bool = _camera.global_position.distance_to(own) <= PLACE_TOLERANCE
	return report(brain.ended and fastest <= most and back
			and _camera.get_framing_name() == GameCamera.OWN_FRAMING_NAME,
			("Back to its own way the brain ends (%s), the fastest step is %.1f px (at most %.1f) and the "
			+ "camera ends at %s (framed the man at %s)")
			% [brain.ended, fastest, most, _camera.global_position, own])


## While a cutscene directs the camera the brain does not step; on release it ends and begins again from where
## the cutscene left the screen, so each begin but the last has its end.
func _check_a_cutscene_pauses_the_brain(brain: StandInBrain) -> bool:
	var own: Vector2 = _camera.global_position
	brain.target = own + AWAY
	_camera.use_brain(brain)
	await wait_frames(BRAIN_FRAMES)
	_camera.direct()
	var steps_before: int = brain.steps
	await wait_frames(BRAIN_FRAMES)
	var directed_steps: int = brain.steps - steps_before
	var left_at: Vector2 = own + CUTSCENE_OFFSET
	_camera.global_position = left_at
	var begins_before: int = brain.begins
	var ends_before: int = brain.ends
	_camera.release()
	var began_there: bool = brain.began_at.distance_to(left_at) <= PLACE_TOLERANCE
	var paired: bool = brain.begins == begins_before + 1 and brain.ends == ends_before + 1
	await wait_frames(BRAIN_FRAMES)
	var resumed: bool = (brain.steps > steps_before
			and _camera.global_position.distance_to(brain.target) <= PLACE_TOLERANCE)
	_camera.use_brain(null)
	return report(directed_steps == 0 and began_there and paired and resumed,
			("A cutscene pauses the brain (%d steps while directed); on release it ends and begins (%s) again "
			+ "from %s (left at %s) and frames %s again")
			% [directed_steps, paired, brain.began_at, left_at, _camera.global_position])


## The man stands still until the idle zoom is under way (moving, and Idle Delay past), and the brain takes over
## then. Back to the camera's own way, with him still standing: the zoom starts from rest, as no jump and no
## speed left from before the brain, and heads for the base zoom, as the time he stood still starts afresh.
func _check_the_way_back_from_the_idle_zoom(brain: StandInBrain, stand_in: StandInInput) -> bool:
	# Settled first, with the idle zoom in; a short run takes it back out, and once he has stood still for Idle
	# Delay it turns and comes in again: the zoom falls, then rises.
	await wait_frames(SETTLE_FRAMES)
	stand_in.run_direction = 1.0
	await wait_frames(RUN_FRAMES / 2)
	stand_in.run_direction = 0.0
	var previous: float = _camera.zoom.x
	var fell: bool = false
	var rising: bool = false
	for _frame: int in SETTLE_FRAMES:
		await physics_frame
		fell = fell or _camera.zoom.x < previous
		if fell and _camera.zoom.x > previous:
			rising = true
			break
		previous = _camera.zoom.x
	await wait_frames(RUN_FRAMES / 2)
	var zoom_before: float = _camera.zoom.x
	brain.target = _camera.global_position
	brain.target_zoom = AWAY_ZOOM
	_camera.use_brain(brain)
	await wait_frames(BRAIN_FRAMES)
	_camera.use_brain(null)
	await physics_frame
	var first_step: float = absf(_camera.zoom.x - AWAY_ZOOM)
	var highest: float = _camera.zoom.x
	for _frame: int in NO_IDLE_FRAMES:
		await physics_frame
		highest = maxf(highest, _camera.zoom.x)
	await wait_frames(SETTLE_FRAMES)
	return report(rising and first_step <= FIRST_ZOOM_STEP and highest <= BASE_ZOOM + ZOOM_TOLERANCE,
			("Back from mid idle zoom (%.3f, rising %s): first zoom step %.5f (at most %.4f), highest zoom "
			+ "in the next %d frames %.4f (at most %.3f)")
			% [zoom_before, rising, first_step, FIRST_ZOOM_STEP, NO_IDLE_FRAMES, highest, BASE_ZOOM])


## The man runs right, turns, and the brain takes over while the lead swings back, with the camera following him
## left; the brain puts the screen further left, and he stops. Back to the camera's own way, the lead starts
## from nothing and the first step goes right, towards him, not on with the speed the camera had.
func _check_the_way_back_after_a_turn(brain: StandInBrain, stand_in: StandInInput) -> bool:
	stand_in.run_direction = 1.0
	await wait_frames(RUN_FRAMES)
	var lead_right: float = _camera.get_look_ahead()
	stand_in.run_direction = -1.0
	var swinging: bool = false
	for _frame: int in SETTLE_FRAMES:
		await physics_frame
		if _camera.get_look_ahead() < lead_right * SWING_SHARE:
			swinging = true
			break
	brain.target = _camera.global_position + TURN_OFFSET
	brain.target_zoom = BASE_ZOOM
	_camera.use_brain(brain)
	stand_in.run_direction = 0.0
	await wait_frames(BRAIN_FRAMES)
	var from: float = _camera.global_position.x
	_camera.use_brain(null)
	await physics_frame
	var first_step: float = _camera.global_position.x - from
	var lead: float = _camera.get_look_ahead()
	await wait_frames(SETTLE_FRAMES)
	return report(swinging and first_step > 0.0 and absf(lead) <= FIRST_LEAD,
			("Back after a turn (lead %.0f px before it, swinging %s): first step %+.2f px (towards the man, "
			+ "right), lead after it %.2f px (at most %.1f)")
			% [lead_right, swinging, first_step, lead, FIRST_LEAD])


## The man runs further than a placing while the brain frames him, and the brain then leaves his middle just
## inside the right edge of the screen, his body across it. Back to the camera's own way he counts as moved, not
## placed, so on the first step the camera keeps his whole body on the screen, as for any man who moves.
func _check_the_way_back_after_moving_far(brain: StandInBrain, stand_in: StandInInput, player: Player) -> bool:
	brain.target = _camera.global_position
	brain.target_zoom = BASE_ZOOM
	_camera.use_brain(brain)
	var from_x: float = player.global_position.x
	stand_in.run_direction = 1.0
	await wait_frames(RUN_FRAMES)
	stand_in.run_direction = 0.0
	await wait_until(func() -> bool: return absf(player.velocity.x) < STILL_SPEED, SETTLE_FRAMES)
	var moved: float = player.global_position.x - from_x
	var half_width: float = root.get_visible_rect().size.x / (2.0 * BASE_ZOOM)
	brain.target = Vector2(player.global_position.x - half_width + EDGE_INSET, _camera.global_position.y)
	await wait_frames(2)
	_camera.use_brain(null)
	await physics_frame
	var body_right: float = player.global_position.x + body_size(player).x / 2.0
	var screen_right: float = _camera.global_position.x + root.get_visible_rect().size.x / (2.0 * _camera.zoom.x)
	await wait_frames(SETTLE_FRAMES)
	return report(moved > GameCamera.PLACED_DISTANCE and body_right <= screen_right + PLACE_TOLERANCE,
			("Back after he ran %.0f px with the brain (more than %.0f): on the first step his body ends at "
			+ "x %.1f, the screen at %.1f")
			% [moved, GameCamera.PLACED_DISTANCE, body_right, screen_right])


## A brain freed while in use sends the camera back to its own way, and the cycle goes on without it.
func _check_a_freed_brain_sends_the_camera_back(brain: StandInBrain) -> bool:
	brain.target = _camera.global_position
	_camera.use_brain(brain)
	await wait_frames(BRAIN_FRAMES)
	var name_in_use: String = _camera.get_framing_name()
	brain.queue_free()
	await physics_frame
	await physics_frame
	var back: bool = _camera.get_framing_name() == GameCamera.OWN_FRAMING_NAME
	var gone_from_cycle: bool = true
	for _turn: int in 4:
		_camera.cycle_framing()
		gone_from_cycle = gone_from_cycle and _camera.get_framing_name() != name_in_use
	_camera.use_framing(GameCamera.OWN_FRAMING_NAME)
	return report(name_in_use == "StandInFreed" and back and gone_from_cycle,
			"A freed brain in use (%s) sends the camera back to %s, and the cycle never names it again: %s"
			% [name_in_use, _camera.get_framing_name(), gone_from_cycle])


## Cycling goes own way, each brain child in order (the scene's own and the two stand-ins), own way.
func _check_cycling(first: StandInBrain, second: StandInBrain) -> bool:
	var expected: Array[String] = [GameCamera.OWN_FRAMING_NAME]
	for child: Node in _camera.get_children():
		if child is CameraBrain:
			expected.append(String(child.name))
	expected.append(GameCamera.OWN_FRAMING_NAME)
	var names: Array[String] = [_camera.get_framing_name()]
	for _turn: int in expected.size() - 1:
		_camera.cycle_framing()
		names.append(_camera.get_framing_name())
	_camera.use_framing("NoSuchBrain")
	var after_unknown: String = _camera.get_framing_name()
	return report(names == expected and expected.has(String(first.name)) and expected.has(String(second.name))
			and after_unknown == GameCamera.OWN_FRAMING_NAME,
			"Cycling goes %s (expected %s); an unknown name leaves %s" % [names, expected, after_unknown])


## A camera with no brains stays on its own way when cycled or given an unknown name.
func _check_no_brains(player: Player) -> bool:
	var plain: GameCamera = CAMERA_SCENE.instantiate() as GameCamera
	plain.player = player
	root.add_child(plain)
	await physics_frame
	var names: Array[String] = []
	plain.cycle_framing()
	names.append(plain.get_framing_name())
	plain.use_framing("NoSuchBrain")
	names.append(plain.get_framing_name())
	plain.queue_free()
	await process_frame
	var expected: Array[String] = [GameCamera.OWN_FRAMING_NAME, GameCamera.OWN_FRAMING_NAME]
	return report(names == expected, "With no brains, cycling and an unknown name leave %s" % [names])
