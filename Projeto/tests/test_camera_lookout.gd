# Test of the camera lookouts. In a lookout's rectangles the camera pulls back until the screen fills
# the View, and the screen never shows past the View, whatever its shape. Out of the rectangles but
# still in the air and in the View, the lookout holds; out of the View it lets go. With the physics,
# a player that runs off a lookout's ledge keeps the lookout through the fall and loses it on
# landing. A View bigger than Min Lookout Zoom allows is followed inside it, still never passed.
# Walking into a lookout whose View lies to the side, the screen goes all the way into the View.
# The headless window is 64 × 64, so the test first gives it the game's screen size.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_camera_lookout.gd
extends "res://tests/support/player_test.gd"

const CAMERA_SCENE: PackedScene = preload("res://camera/game_camera.tscn")
const INSTANT_SHARPNESS: float = 1.0e6
## Steps for the camera to settle when called by hand: 10 s, so the zoom settles too.
const SETTLE_STEPS: int = 600
const SAME_SPOT: float = 0.5
## A View shaped like the screen, 1.25 times its size: the camera should settle at zoom 0.8.
const SCREEN_SHAPED_VIEW: Rect2 = Rect2(-1200.0, -1000.0, 2400.0, 1350.0)
const SCREEN_SHAPED_ZOOM: float = 0.8
## A View wider than the screen's shape: the screen fills its height and is followed across.
const WIDE_VIEW: Rect2 = Rect2(-1500.0, -1000.0, 4000.0, 1350.0)
## A View too big for Min Lookout Zoom.
const HUGE_VIEW: Rect2 = Rect2(-3000.0, -3000.0, 6000.0, 5000.0)
const TRIGGER: Rect2 = Rect2(-200.0, -200.0, 400.0, 200.0)
## The platform case: a platform this wide carries the player this far, at this speed (px, px/s).
const PLATFORM_WIDTH: float = 192.0
const RIDE_DISTANCE: float = 1200.0
const RIDE_SPEED: float = 300.0
## How soon a lookout must be mostly shown, in s, and what mostly is. 2 s, so the move into the View
## reads as a pull back rather than a jump.
const QUICK_TIME: float = 2.0
const MOSTLY_DONE: float = 0.95
## The side View case, as Lust phase 3's LookoutRamp: a View that starts 1000 px to the right of the
## trigger, as tall as the screen at zoom 1.5, and the player's step into the trigger, short of a
## placing.
const SIDE_VIEW: Rect2 = Rect2(1200.0, -700.0, 2125.0, 720.0)
const STEP_IN: float = 100.0
## The fall case: a ledge ending at x 0 with its top at y 0, the floor FALL_HEIGHT below it.
const FALL_HEIGHT: float = 600.0
const LEDGE_LEFT: float = -800.0
const FLOOR_RIGHT: float = 1200.0


func _initialize() -> void:
	await process_frame
	root.size = Vector2i(int(ProjectSettings.get_setting("display/window/size/viewport_width")),
			int(ProjectSettings.get_setting("display/window/size/viewport_height")))
	await process_frame
	var results: Array[bool] = []
	results.append(await _in_the_trigger_the_screen_fills_the_view())
	results.append(await _a_view_wider_than_the_screen_is_never_passed())
	results.append(await _in_the_air_in_the_view_the_lookout_holds_and_out_of_it_lets_go())
	results.append(await _running_off_the_ledge_the_lookout_holds_until_landing())
	results.append(await _walking_back_out_of_the_trigger_lets_go())
	results.append(await _riding_a_moving_platform_out_of_the_trigger_holds())
	results.append(await _a_huge_view_stops_at_min_lookout_zoom_and_is_never_passed())
	results.append(await _into_a_lookout_the_camera_is_quick_and_out_of_it_as_before())
	results.append(await _walking_into_a_lookout_with_its_view_aside_the_screen_reaches_the_view())
	finish(results)


func _in_the_trigger_the_screen_fills_the_view() -> bool:
	var player: Player = _spawn_still_player(Vector2(0.0, -10.0))
	var lookout: CameraLookout = _make_lookout(TRIGGER, SCREEN_SHAPED_VIEW)
	var camera: GameCamera = _spawn_camera_by_hand(player)
	_settle_by_hand(camera)
	var screen: Rect2 = _screen_of(camera)
	var zoom_level: float = camera.zoom.x
	await _remove_all([player, lookout, camera])
	return report(absf(zoom_level - SCREEN_SHAPED_ZOOM) < 0.001 and _inside(screen, SCREEN_SHAPED_VIEW),
			"In the trigger: zoom %.3f (expected %.3f), screen %s, View %s"
			% [zoom_level, SCREEN_SHAPED_ZOOM, screen, SCREEN_SHAPED_VIEW])


## The player walks across the trigger of a wide View: the screen keeps the View's height and never
## passes its sides.
func _a_view_wider_than_the_screen_is_never_passed() -> bool:
	var player: Player = _spawn_still_player(Vector2(-1400.0, -10.0))
	var lookout: CameraLookout = _make_lookout(Rect2(WIDE_VIEW.position.x, -200.0, WIDE_VIEW.size.x, 200.0),
			WIDE_VIEW)
	var camera: GameCamera = _spawn_camera_by_hand(player)
	var worst: float = 0.0
	for x: float in range(-1400, 2401, 100):
		player.global_position.x = x
		_settle_by_hand(camera)
		worst = maxf(worst, _distance_past(_screen_of(camera), WIDE_VIEW))
	var zoom_level: float = camera.zoom.x
	await _remove_all([player, lookout, camera])
	return report(worst < SAME_SPOT and absf(zoom_level - SCREEN_SHAPED_ZOOM) < 0.001,
			"Wide View: zoom %.3f, the screen went %.2f px past the View at most" % [zoom_level, worst])


func _in_the_air_in_the_view_the_lookout_holds_and_out_of_it_lets_go() -> bool:
	var player: Player = _spawn_still_player(Vector2(0.0, -10.0))
	var lookout: CameraLookout = _make_lookout(TRIGGER, SCREEN_SHAPED_VIEW)
	var camera: GameCamera = _spawn_camera_by_hand(player)
	_settle_by_hand(camera)
	player.global_position = Vector2(600.0, -500.0)
	_settle_by_hand(camera)
	var held: bool = camera._lookout == lookout and absf(camera.zoom.x - SCREEN_SHAPED_ZOOM) < 0.001
	player.global_position = Vector2(5000.0, -500.0)
	_settle_by_hand(camera)
	var zoom_level: float = camera.zoom.x
	var let_go: bool = camera._lookout == null and absf(zoom_level - 1.0) < 0.001
	await _remove_all([player, lookout, camera])
	return report(held and let_go, "In the air, out of the trigger but in the View: held %s; out of the View: let go %s, zoom %.3f"
			% [held, let_go, zoom_level])


func _running_off_the_ledge_the_lookout_holds_until_landing() -> bool:
	var ledge: StaticBody2D = make_platform(LEDGE_LEFT, 0.0, 0.0)
	var ground: StaticBody2D = make_platform(LEDGE_LEFT, FLOOR_RIGHT, FALL_HEIGHT)
	var lookout: CameraLookout = _make_lookout(Rect2(-300.0, -200.0, 300.0, 200.0),
			Rect2(LEDGE_LEFT, -600.0, FLOOR_RIGHT - LEDGE_LEFT, FALL_HEIGHT + 700.0))
	var player: Player = await spawn_on_floor(Vector2(-150.0, -2.0))
	var camera: GameCamera = CAMERA_SCENE.instantiate() as GameCamera
	camera.player = player
	camera.stats = camera.stats.duplicate() as CameraStats
	camera.stats.idle_delay = INF
	root.add_child(camera)
	await wait_frames(2)
	var at_start: bool = camera._lookout == lookout
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.run_direction = 1.0
	var held_in_the_fall: bool = true
	var fell: bool = false
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if player.global_position.y > 10.0 and player.get_state() != Player.State.ON_FLOOR:
			fell = true
			held_in_the_fall = held_in_the_fall and camera._lookout == lookout
		if fell and player.get_state() == Player.State.ON_FLOOR:
			break
	stand_in.run_direction = 0.0
	await physics_frame
	var after_landing: bool = camera._lookout == null
	await _remove_all([player, lookout, camera, ledge, ground])
	return report(at_start and fell and held_in_the_fall and after_landing,
			"Off the ledge: lookout at the start %s, fell %s, held through the fall %s, gone after landing %s"
			% [at_start, fell, held_in_the_fall, after_landing])


## On the floor, the lookout goes once the body is wholly out of the trigger, though still in the View.
func _walking_back_out_of_the_trigger_lets_go() -> bool:
	var ledge: StaticBody2D = make_platform(LEDGE_LEFT, 0.0, 0.0)
	var lookout: CameraLookout = _make_lookout(Rect2(-300.0, -200.0, 300.0, 200.0),
			Rect2(LEDGE_LEFT, -600.0, FLOOR_RIGHT - LEDGE_LEFT, FALL_HEIGHT + 700.0))
	var player: Player = await spawn_on_floor(Vector2(-150.0, -2.0))
	var camera: GameCamera = CAMERA_SCENE.instantiate() as GameCamera
	camera.player = player
	camera.stats = camera.stats.duplicate() as CameraStats
	camera.stats.idle_delay = INF
	root.add_child(camera)
	await wait_frames(2)
	var at_start: bool = camera._lookout == lookout
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.run_direction = -1.0
	var let_go: bool = await wait_until(func() -> bool: return camera._lookout == null)
	var x: float = player.global_position.x
	await _remove_all([player, lookout, camera, ledge])
	return report(at_start and let_go and x < -300.0 - GameCamera.LOOKOUT_LET_GO,
			"Walking back on the floor: lookout at the start %s, let go %s, at x %.0f (trigger from -300, let go a tile out)"
			% [at_start, let_go, x])


## A platform carries the player out of the trigger: the lookout holds while it moves, though the
## player is on its floor, and goes once it stops.
func _riding_a_moving_platform_out_of_the_trigger_holds() -> bool:
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(PLATFORM_WIDTH, 24.0)
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	var platform: AnimatableBody2D = AnimatableBody2D.new()
	platform.add_child(collision)
	platform.position = Vector2(0.0, 12.0)
	root.add_child(platform)
	var lookout: CameraLookout = _make_lookout(Rect2(-150.0, -200.0, 300.0, 200.0),
			Rect2(-500.0, -800.0, 3000.0, 1500.0))
	var player: Player = await spawn_on_floor(Vector2(0.0, -2.0))
	var camera: GameCamera = CAMERA_SCENE.instantiate() as GameCamera
	camera.player = player
	camera.stats = camera.stats.duplicate() as CameraStats
	camera.stats.idle_delay = INF
	root.add_child(camera)
	await wait_frames(2)
	var at_start: bool = camera._lookout == lookout
	var held: bool = true
	while platform.position.x < RIDE_DISTANCE:
		await physics_frame
		platform.position.x += RIDE_SPEED / Engine.physics_ticks_per_second
		if player.global_position.x > 150.0 + GameCamera.LOOKOUT_LET_GO + PLATFORM_WIDTH:
			held = held and camera._lookout == lookout
	var x: float = player.global_position.x
	await wait_frames(5)
	var after_stop: bool = camera._lookout == null
	await _remove_all([player, lookout, camera, platform])
	return report(at_start and held and after_stop and x > RIDE_DISTANCE - PLATFORM_WIDTH,
			"Riding a platform to x %.0f: lookout at the start %s, held while moving %s, gone once it stopped %s"
			% [x, at_start, held, after_stop])


func _a_huge_view_stops_at_min_lookout_zoom_and_is_never_passed() -> bool:
	var player: Player = _spawn_still_player(Vector2(-2900.0, -10.0))
	var lookout: CameraLookout = _make_lookout(Rect2(-3000.0, -200.0, 6000.0, 200.0), HUGE_VIEW)
	var camera: GameCamera = _spawn_camera_by_hand(player)
	var worst: float = 0.0
	for x: float in [-2900.0, 0.0, 2900.0]:
		player.global_position.x = x
		_settle_by_hand(camera)
		worst = maxf(worst, _distance_past(_screen_of(camera), HUGE_VIEW))
	var zoom_level: float = camera.zoom.x
	var expected: float = camera.stats.min_lookout_zoom
	await _remove_all([player, lookout, camera])
	return report(absf(zoom_level - expected) < 0.001 and worst < SAME_SPOT,
			"Huge View: zoom %.3f (Min Lookout Zoom %.3f), the screen went %.2f px past it at most"
			% [zoom_level, expected, worst])


## Into a lookout, zoom and position are 95 % done within QUICK_TIME; leaving it, the zoom eases back
## with Zoom Sharpness, slower, so it is not.
func _into_a_lookout_the_camera_is_quick_and_out_of_it_as_before() -> bool:
	var outside: Vector2 = Vector2(4000.0, -10.0)
	var player: Player = _spawn_still_player(outside)
	var lookout: CameraLookout = _make_lookout(TRIGGER, SCREEN_SHAPED_VIEW)
	var camera: GameCamera = _spawn_camera_by_hand(player)
	_settle_by_hand(camera)
	var start_position: Vector2 = camera.global_position
	player.global_position = Vector2(0.0, -10.0)
	_step_by_hand(camera, QUICK_TIME)
	var zoom_in: float = (1.0 - camera.zoom.x) / (1.0 - SCREEN_SHAPED_ZOOM)
	var target: Vector2 = SCREEN_SHAPED_VIEW.get_center()
	var moved: float = 1.0 - camera.global_position.distance_to(target) / start_position.distance_to(target)
	_settle_by_hand(camera)
	player.global_position = outside
	_step_by_hand(camera, QUICK_TIME)
	var zoom_out: float = (camera.zoom.x - SCREEN_SHAPED_ZOOM) / (1.0 - SCREEN_SHAPED_ZOOM)
	await _remove_all([player, lookout, camera])
	return report(zoom_in >= MOSTLY_DONE and moved >= MOSTLY_DONE and zoom_out < MOSTLY_DONE,
			"In %.2f s: into the lookout, zoom %.0f %% and position %.0f %% done; out of it, zoom %.0f %% done"
			% [QUICK_TIME, zoom_in * 100.0, moved * 100.0, zoom_out * 100.0])


## A lookout with these trigger rectangle and View, at the origin.
## The player walks into the trigger of a lookout whose View lies to the side, without the player in
## it: the screen goes all the way into the View, though that leaves the player off the screen,
## instead of stopping where the player would reach the screen's edge.
func _walking_into_a_lookout_with_its_view_aside_the_screen_reaches_the_view() -> bool:
	var player: Player = _spawn_still_player(Vector2(TRIGGER.position.x - STEP_IN / 2.0, -10.0))
	var lookout: CameraLookout = _make_lookout(TRIGGER, SIDE_VIEW)
	var camera: GameCamera = _spawn_camera_by_hand(player)
	_settle_by_hand(camera)
	player.global_position.x += STEP_IN
	_settle_by_hand(camera)
	var screen: Rect2 = _screen_of(camera)
	await _remove_all([player, lookout, camera])
	return report(_inside(screen, SIDE_VIEW),
			"Walking into a lookout whose View is aside: screen %s, View %s, %.1f px past it"
			% [screen, SIDE_VIEW, _distance_past(screen, SIDE_VIEW)])


func _make_lookout(trigger: Rect2, view: Rect2) -> CameraLookout:
	var lookout: CameraLookout = CameraLookout.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = trigger.size
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	collision.position = trigger.get_center()
	lookout.add_child(collision)
	var rect: ReferenceRect = ReferenceRect.new()
	rect.position = view.position
	rect.size = view.size
	lookout.add_child(rect)
	root.add_child(lookout)
	return lookout


## What the screen shows, in the level.
func _screen_of(camera: GameCamera) -> Rect2:
	var size: Vector2 = camera.get_viewport_rect().size / camera.zoom
	return Rect2(camera.global_position - size / 2.0, size)


func _inside(screen: Rect2, view: Rect2) -> bool:
	return _distance_past(screen, view) < SAME_SPOT


## How far the screen goes past the View on its worst side, in px; 0 if it stays inside.
func _distance_past(screen: Rect2, view: Rect2) -> float:
	return maxf(0.0, maxf(maxf(view.position.x - screen.position.x, screen.end.x - view.end.x),
			maxf(view.position.y - screen.position.y, screen.end.y - view.end.y)))


func _spawn_still_player(at: Vector2) -> Player:
	var player: Player = spawn_player(at)
	player.set_physics_process(false)
	return player


func _spawn_camera_by_hand(player: Player) -> GameCamera:
	var camera: GameCamera = CAMERA_SCENE.instantiate() as GameCamera
	camera.player = player
	camera.stats = camera.stats.duplicate() as CameraStats
	camera.stats.follow_sharpness = INSTANT_SHARPNESS
	camera.stats.idle_delay = INF
	root.add_child(camera)
	camera.set_physics_process(false)
	return camera


func _step_by_hand(camera: GameCamera, seconds: float) -> void:
	for _step_index: int in roundi(seconds * Engine.physics_ticks_per_second):
		camera._physics_process(1.0 / Engine.physics_ticks_per_second)


func _settle_by_hand(camera: GameCamera) -> void:
	for _step_index: int in SETTLE_STEPS:
		camera._physics_process(1.0 / Engine.physics_ticks_per_second)


func _remove_all(nodes: Array) -> void:
	for node: Node in nodes:
		node.queue_free()
	await physics_frame
