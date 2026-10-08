# Test of the game camera's setup in the test room. The room has the camera, current and linked to
# the room's player, following it in the physics step and after the player, with physics
# interpolation on. Wherever the room put it, the camera starts where it settles, without sliding
# into place. On a floor with no zones or limits, and with no window, lead or smoothing, it is on
# the player at the end of every physics frame while the player runs and falls, so it reads the
# player after the player moves, on the same step. Its limits are the box
# around the room's walls, floor and ceiling, so the screen never shows past them. Without a player
# the camera stays where it was put, and a player freed while followed leaves the camera where the
# player last was. The window and the smoothing have their own test, test_camera_window.gd.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_game_camera.gd
extends "res://tests/support/player_test.gd"

const TEST_ROOM_SCENE: PackedScene = preload("res://scenes/levels/test_room.tscn")
const CAMERA_SCENE: PackedScene = preload("res://scenes/camera/game_camera.tscn")
## Physics frames the player runs right in the following case: one second.
const RUN_FRAMES: int = 60
## How far the player must get in that second for the case to mean something, in px.
const MIN_RUN_DISTANCE: float = 300.0
## Where a case puts the camera before the room starts, away from the player.
const AWAY_FROM_THE_PLAYER: Vector2 = Vector2(4000.0, -800.0)
## Where the camera sits in the case without a player.
const LONE_CAMERA_SPOT: Vector2 = Vector2(100.0, 200.0)
## Physics frames to watch a camera that has no player to follow.
const WATCH_FRAMES: int = 10
## A smoothing so fast that one step closes the whole distance.
const INSTANT_SHARPNESS: float = 1.0e6
## How close the camera must be to the player to count as on it, in px: the float error of a step.
const SAME_SPOT: float = 0.01
## The floor of the freed-player case goes from -FLOOR_HALF_WIDTH to FLOOR_HALF_WIDTH.
const FLOOR_HALF_WIDTH: float = 500.0
## Physics frames the start case watches the camera after the room starts: 2 s.
const SETTLE_FRAMES: int = 120
## The same-step case: the player starts on a floor that ends at x = 0, and runs off it onto one
## LEDGE_DROP px lower, as high as the test room's raised block.
const LEDGE_START_X: float = -300.0
const LEDGE_DROP: float = 120.0
## Just above the floor, so a player spawned there lands on its first frames.
const FLOOR_SPAWN_HEIGHT: float = -2.0


func _initialize() -> void:
	var results: Array[bool] = []
	results.append(await _the_test_room_has_the_camera_on_its_player())
	results.append(await _the_camera_starts_where_it_settles())
	results.append(await _the_camera_reads_the_player_of_the_same_step())
	results.append(await _the_limits_are_the_box_around_the_room())
	results.append(await _without_a_player_the_camera_stays_where_it_is())
	results.append(await _a_freed_player_leaves_the_camera_where_it_last_was())
	finish(results)


## The test room has the camera, current and linked to the room's player. It follows in the physics
## step, after the player, with physics interpolation on.
func _the_test_room_has_the_camera_on_its_player() -> bool:
	var room: Node = TEST_ROOM_SCENE.instantiate()
	root.add_child(room)
	await physics_frame
	var camera: GameCamera = _find_camera(room)
	var player: Player = room.get_node_or_null(^"Player") as Player
	if camera == null or player == null:
		await _remove(room)
		return report(false, "Test room: camera %s, player %s" % [camera != null, player != null])
	var current: bool = camera.is_current()
	var linked: bool = camera.player == player
	var physics: bool = (camera.process_callback == Camera2D.CAMERA2D_PROCESS_PHYSICS
			and camera.is_physics_processing())
	var after_player: bool = camera.process_physics_priority > player.process_physics_priority
	var interpolated: bool = camera.is_physics_interpolated_and_enabled()
	await _remove(room)
	return report(current and linked and physics and after_player and interpolated,
			"Test room camera: current %s, player linked %s, in the physics step %s, after the player %s, interpolated %s"
			% [current, linked, physics, after_player, interpolated])


## However far from the player the room puts the camera, the camera starts where it settles: the
## room starts on a fixed first screen, and the camera is already there before the first physics
## frame and still there 2 s later, while the player drops onto the raised block.
func _the_camera_starts_where_it_settles() -> bool:
	var room: Node = TEST_ROOM_SCENE.instantiate()
	var camera: GameCamera = _find_camera(room)
	camera.position = AWAY_FROM_THE_PLAYER
	root.add_child(room)
	var at_start: Vector2 = camera.global_position
	for _frame: int in SETTLE_FRAMES:
		await physics_frame
	var shift: float = camera.global_position.distance_to(at_start)
	await _remove(room)
	return report(shift < SAME_SPOT,
			"Camera at %s when the room starts, moved %.3f px in the next 2 s" % [at_start, shift])


## With no window, no lead and no smoothing, the camera is on the player at the end of every physics
## frame while the player runs right, off a floor and down to a lower one: it reads where the player
## is after the player moves, on the same step, and not one step late. The camera comes before the
## player in the tree, so only its Physics Priority makes it run after the player. The floor has no
## zones and the camera no limits, which would hold the camera back from the player.
func _the_camera_reads_the_player_of_the_same_step() -> bool:
	var upper: StaticBody2D = make_platform(-FLOOR_HALF_WIDTH, 0.0)
	var lower: StaticBody2D = make_platform(-FLOOR_HALF_WIDTH, 4.0 * FLOOR_HALF_WIDTH, LEDGE_DROP)
	var player: Player = await spawn_on_floor(Vector2(LEDGE_START_X, FLOOR_SPAWN_HEIGHT))
	if player == null:
		await _remove(upper)
		await _remove(lower)
		return report(false, "Same step: the player never landed")
	var camera: GameCamera = CAMERA_SCENE.instantiate() as GameCamera
	camera.player = player
	camera.stats = _without_window_or_smoothing(camera.stats)
	root.add_child(camera)
	root.move_child(camera, player.get_index())
	var camera_first: bool = camera.get_index() < player.get_index()
	var start_x: float = player.global_position.x
	var largest_gap: float = 0.0
	Input.action_press(&"move_right")
	for _frame: int in RUN_FRAMES:
		await physics_frame
		largest_gap = maxf(largest_gap, camera.global_position.distance_to(player.global_position))
	Input.action_release(&"move_right")
	var run: float = player.global_position.x - start_x
	var dropped: bool = player.global_position.y > LEDGE_DROP / 2.0
	await _remove(camera)
	await _remove(player)
	await _remove(upper)
	await _remove(lower)
	return report(camera_first and largest_gap < SAME_SPOT and run >= MIN_RUN_DISTANCE and dropped,
			"Same step, no window, lead or smoothing, camera first in the tree %s: %d frames, %.0f px run, dropped %s, largest gap to the player %.3f px"
			% [camera_first, RUN_FRAMES, run, dropped, largest_gap])


## The camera's limits are the box around every wall, floor and ceiling of the room, so the screen
## shows the whole room and never past it.
func _the_limits_are_the_box_around_the_room() -> bool:
	var room: Node = TEST_ROOM_SCENE.instantiate()
	root.add_child(room)
	var camera: GameCamera = _find_camera(room)
	var box: Rect2 = _box_around_the_room(room)
	var limits: Rect2 = Rect2(Vector2(camera.limit_left, camera.limit_top),
			Vector2(camera.limit_right - camera.limit_left, camera.limit_bottom - camera.limit_top))
	await _remove(room)
	return report(limits == box, "Limits %s, box around the room %s" % [limits, box])


## A camera with no player stays where it was put, with its physics step off from the moment it
## enters the room.
func _without_a_player_the_camera_stays_where_it_is() -> bool:
	var camera: GameCamera = CAMERA_SCENE.instantiate() as GameCamera
	camera.position = LONE_CAMERA_SPOT
	root.add_child(camera)
	var idle_from_the_start: bool = not camera.is_physics_processing()
	for _frame: int in WATCH_FRAMES:
		await physics_frame
	var stayed: bool = camera.global_position == LONE_CAMERA_SPOT
	var idle: bool = idle_from_the_start and not camera.is_physics_processing()
	await _remove(camera)
	return report(stayed and idle,
			"Camera without a player: stayed %s, physics step off from the start %s" % [stayed, idle])


## A player freed while the camera follows it leaves the camera where the player last was, with the
## camera's physics step off.
func _a_freed_player_leaves_the_camera_where_it_last_was() -> bool:
	var ground: StaticBody2D = make_platform(-FLOOR_HALF_WIDTH, FLOOR_HALF_WIDTH)
	var player: Player = await spawn_on_floor(Vector2(0.0, FLOOR_SPAWN_HEIGHT))
	if player == null:
		await _remove(ground)
		return report(false, "Freed player: the player never landed")
	var camera: GameCamera = CAMERA_SCENE.instantiate() as GameCamera
	camera.player = player
	root.add_child(camera)
	await physics_frame
	var last_spot: Vector2 = player.global_position
	player.queue_free()
	for _frame: int in WATCH_FRAMES:
		await physics_frame
	var stayed: bool = camera.global_position == last_spot
	var idle: bool = not camera.is_physics_processing()
	await _remove(camera)
	await _remove(ground)
	return report(stayed and idle,
			"Freed player: camera stayed where the player last was %s, physics step off %s"
			% [stayed, idle])


## A copy of stats with no window, no look ahead or down and a smoothing so fast that one step closes
## the whole distance, so the camera sits on the player.
func _without_window_or_smoothing(stats: CameraStats) -> CameraStats:
	var copy: CameraStats = stats.duplicate() as CameraStats
	copy.look_ahead_distance = 0.0
	copy.look_down_distance = 0.0
	copy.window_half_width = 0.0
	copy.window_up = 0.0
	copy.window_down = 0.0
	copy.follow_sharpness = INSTANT_SHARPNESS
	return copy


func _find_camera(room: Node) -> GameCamera:
	for child: Node in room.get_children():
		if child is GameCamera:
			return child as GameCamera
	return null


## The smallest box with every rectangle of the room's static bodies inside, in global coordinates.
func _box_around_the_room(room: Node) -> Rect2:
	var rects: Array[Rect2] = []
	for node: Node in room.get_children():
		var body: StaticBody2D = node as StaticBody2D
		if body == null:
			continue
		for child: Node in body.get_children():
			var collision: CollisionShape2D = child as CollisionShape2D
			if collision == null:
				continue
			var rectangle: RectangleShape2D = collision.shape as RectangleShape2D
			if rectangle == null:
				continue
			rects.append(Rect2(collision.global_position - rectangle.size / 2.0, rectangle.size))
	if rects.is_empty():
		return Rect2()
	var box: Rect2 = rects[0]
	for rect: Rect2 in rects:
		box = box.merge(rect)
	return box


func _remove(node: Node) -> void:
	node.queue_free()
	await physics_frame
