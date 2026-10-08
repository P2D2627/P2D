# Test of the camera zones. A zone's limits are the box around its rectangles, and a point is in the
# zone if it is in one of them. In a zone the size of the screen, the camera stays at its centre. Near
# a zone's edge, the screen stops at the edge, look ahead included, and never shows past it. Turning
# at an edge, the screen moves as soon as the lead does, instead of waiting for a camera that went
# past the edge to come back. Moving into another zone, the camera slides to the new zone's range
# without jumps. The test room's zones cover the room without overlapping, and in the room the
# camera follows the player from the start. A zone freed while the camera has it lets the camera
# go, without an error, and the camera still finds the zones after it. With the real values and the
# physics, running to an inner edge or falling to a zone's bottom, the screen never passes the edge,
# though the smoothing and the look ahead lag behind. A change of zone moves the camera no faster
# than Zone Change Speed. A zone in a sub-scene of the level counts, and the zones of a level being
# freed do not. A scaled zone has the rectangle the editor shows, without its disabled shapes. The
# screen size comes from the camera itself, as the engine takes it: in headless runs the window is
# 64 × 64 and the stretch makes the screen 1920 × 1920.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_camera_zones.gd
extends "res://tests/support/player_test.gd"

const TEST_ROOM_SCENE: PackedScene = preload("res://scenes/levels/test_room.tscn")
const CAMERA_SCENE: PackedScene = preload("res://scenes/camera/game_camera.tscn")
## A smoothing so fast that one step closes the whole distance, to see where the camera heads.
const INSTANT_SHARPNESS: float = 1.0e6
## How close two positions must be to count as the same, in px.
const SAME_SPOT: float = 0.01
## How far a move must go to count as the screen or the lead moving, in px.
const MOVED: float = 1.0
## How many physics frames the screen may move after the lead does, at a turn by an edge.
const SCREEN_AFTER_LEAD_FRAMES: int = 3
## Steps for the camera to settle when called by hand: 4 s.
const SETTLE_STEPS: int = 240
## Physics frames to settle with the physics running: 2 s.
const SETTLE_FRAMES: int = 120
## Physics frames a case waits for something before giving up: 5 s.
const GIVE_UP_FRAMES: int = 300
## The largest share of the distance a slide between zones may cover in one step.
const LARGEST_STEP_SHARE: float = 0.1
## How far from a zone's edge the edge case leaves the player, in px.
const EDGE_GAP: float = 100.0
## How far the freed-zone case moves the player inside the zone before freeing it, in px.
const LATER_MOVE: float = 500.0
## How far the zone-change case moves the player inside the new zone once the change is over, in px.
const JUMP_IN_THE_ZONE: float = 1500.0
## The fall case: a ledge this high above the floor, ending at LEDGE_END_X, with the player starting
## LEDGE_START_GAP before its end; the zone's bottom is ZONE_FLOOR_DEPTH below the floor's top.
const FALL_HEIGHT: float = 2500.0
const LEDGE_END_X: float = 600.0
const LEDGE_START_GAP: float = 200.0
const ZONE_FLOOR_DEPTH: float = 100.0
## The scale case: a 1000 × 500 rectangle centred at (500, 250) in a zone scaled by 2, so the
## editor and the physics show it from (0, 0) to (2000, 1000); and a disabled shape far away.
const SCALED_SHAPE: Rect2 = Rect2(0.0, 0.0, 1000.0, 500.0)
const ZONE_SCALE: float = 2.0
const DISABLED_SHAPE_SPOT: Vector2 = Vector2(5000.0, 5000.0)
## The edge-turn case: the player stops this far from the wall, and starts this far from it.
const STOP_BEFORE_THE_WALL: float = 200.0
const START_FROM_THE_WALL: float = 1500.0
## The edge-turn case's wall, and the floor of the cases with physics.
const WALL_THICKNESS: float = 100.0
const FLOOR_SPAWN_HEIGHT: float = -2.0


func _initialize() -> void:
	# Nodes added before the first frame only get _ready on it, and the cases need the camera ready
	# as soon as it is added.
	await process_frame
	var results: Array[bool] = []
	results.append(await _a_zone_s_limits_are_the_box_around_its_rectangles())
	results.append(await _in_a_zone_the_size_of_the_screen_the_camera_stays_at_its_centre())
	results.append(await _near_an_edge_the_screen_stops_at_it_even_with_the_lead())
	results.append(await _turning_at_an_edge_the_screen_moves_with_the_lead())
	results.append(await _moving_into_another_zone_the_camera_slides_to_its_range())
	results.append(await _the_test_room_s_zones_cover_it_without_overlapping())
	results.append(await _the_test_room_follows_the_player_from_the_start())
	results.append(await _a_zone_that_goes_away_lets_the_camera_go())
	results.append(await _running_to_an_inner_edge_the_screen_never_passes_it())
	results.append(await _falling_to_a_zone_s_bottom_the_screen_never_passes_it())
	results.append(await _moving_into_another_zone_the_camera_keeps_to_zone_change_speed())
	results.append(await _a_zone_in_a_sub_scene_of_the_level_counts())
	results.append(await _the_zones_of_a_level_being_freed_do_not_count())
	results.append(await _a_zone_s_rectangles_follow_its_scale_and_skip_disabled_shapes())
	finish(results)


## An L-shaped zone of two rectangles: its limits are the box around both, its points are those of
## either rectangle, and the notch of the L and the rectangles' right edges are outside it.
func _a_zone_s_limits_are_the_box_around_its_rectangles() -> bool:
	var zone: CameraZone = _make_zone([Rect2(0.0, 0.0, 400.0, 100.0), Rect2(0.0, 100.0, 100.0, 300.0)])
	var limits: Rect2 = zone.get_limits()
	var inside: bool = zone.has_point(Vector2(300.0, 50.0)) and zone.has_point(Vector2(50.0, 300.0))
	var outside: bool = (not zone.has_point(Vector2(300.0, 300.0))
			and not zone.has_point(Vector2(400.0, 50.0)))
	await _remove_all([zone])
	return report(limits == Rect2(0.0, 0.0, 400.0, 400.0) and inside and outside,
			"L-shaped zone: limits %s, both arms inside %s, notch and right edge outside %s"
			% [limits, inside, outside])


## In a zone exactly the size of the screen, wherever the player goes in it, the camera stays at the
## zone's centre.
func _in_a_zone_the_size_of_the_screen_the_camera_stays_at_its_centre() -> bool:
	var screen: Vector2 = root.get_visible_rect().size
	var zone: CameraZone = _make_zone([Rect2(Vector2.ZERO, screen)])
	var player: Player = _spawn_still_player(screen / 2.0)
	var camera: GameCamera = _spawn_camera_by_hand(player, true)
	var largest_shift: float = 0.0
	for spot: Vector2 in [Vector2(0.1, 0.1), Vector2(0.9, 0.1), Vector2(0.9, 0.9), Vector2(0.1, 0.9)]:
		player.global_position = screen * spot
		_settle_by_hand(camera)
		largest_shift = maxf(largest_shift, camera.global_position.distance_to(screen / 2.0))
	await _remove_all([camera, player, zone])
	return report(largest_shift < SAME_SPOT,
			"Zone the size of the screen %s: largest camera shift from its centre %.3f px"
			% [screen, largest_shift])


## Leading to the right, near the right edge of a wide zone, the screen's right edge stops at the
## zone's edge, and on the way it never goes past it.
func _near_an_edge_the_screen_stops_at_it_even_with_the_lead() -> bool:
	var screen: Vector2 = root.get_visible_rect().size
	var zone_rect: Rect2 = Rect2(Vector2.ZERO, Vector2(4.0, 2.0) * screen)
	var zone: CameraZone = _make_zone([zone_rect])
	var start: Vector2 = zone_rect.get_center()
	var player: Player = _spawn_still_player(start)
	var camera: GameCamera = _spawn_camera_by_hand(player, true)
	player.global_position = Vector2(zone_rect.end.x - EDGE_GAP, start.y)
	var furthest_past: float = -INF
	for _step_index: int in SETTLE_STEPS:
		camera._physics_process(_step())
		furthest_past = maxf(furthest_past, camera.global_position.x + screen.x / 2.0 - zone_rect.end.x)
	var settled_edge: float = camera.global_position.x + screen.x / 2.0
	var lead: float = camera.get_look_ahead()
	await _remove_all([camera, player, zone])
	return report(absf(settled_edge - zone_rect.end.x) < SAME_SPOT and furthest_past < SAME_SPOT,
			"Near the right edge at %.0f: screen edge settles at %.2f, furthest past the edge %.2f px, lead %.1f px"
			% [zone_rect.end.x, settled_edge, furthest_past, lead])


## Running into a wall at the end of a zone, then running back: the screen, which the camera's own
## limits clamp as the engine does, starts to move within 3 frames of the lead turning, because the
## camera never went past what the zone lets the screen show.
func _turning_at_an_edge_the_screen_moves_with_the_lead() -> bool:
	var screen: Vector2 = root.get_visible_rect().size
	var width: float = 3.0 * screen.x
	var box: Rect2 = Rect2(0.0, -screen.y, width, screen.y + 100.0)
	var ground: StaticBody2D = make_platform(0.0, width)
	var wall: StaticBody2D = make_wall(width, width + WALL_THICKNESS, box.position.y)
	var zone: CameraZone = _make_zone([box])
	var player: Player = await spawn_on_floor(Vector2(width - START_FROM_THE_WALL, FLOOR_SPAWN_HEIGHT))
	if player == null:
		await _remove_all([zone, wall, ground])
		return report(false, "Turn at an edge: the player never landed")
	var camera: GameCamera = _spawn_camera(player)
	camera.limit_left = int(box.position.x)
	camera.limit_top = int(box.position.y)
	camera.limit_right = int(box.end.x)
	camera.limit_bottom = int(box.end.y)
	Input.action_press(&"move_right")
	for _frame: int in GIVE_UP_FRAMES:
		await physics_frame
		if player.global_position.x >= width - STOP_BEFORE_THE_WALL:
			break
	Input.action_release(&"move_right")
	for _frame: int in SETTLE_FRAMES:
		await physics_frame
	var screen_at_turn: float = _screen_centre_x(camera)
	var lead_at_turn: float = camera.get_look_ahead()
	var lead_moved_frame: int = NEVER_REACHED
	var screen_moved_frame: int = NEVER_REACHED
	Input.action_press(&"move_left")
	for frame: int in GIVE_UP_FRAMES:
		await physics_frame
		if lead_moved_frame == NEVER_REACHED and absf(camera.get_look_ahead() - lead_at_turn) > MOVED:
			lead_moved_frame = frame
		if screen_moved_frame == NEVER_REACHED and absf(_screen_centre_x(camera) - screen_at_turn) > MOVED:
			screen_moved_frame = frame
		if lead_moved_frame != NEVER_REACHED and screen_moved_frame != NEVER_REACHED:
			break
	Input.action_release(&"move_left")
	await _remove_all([camera, player, zone, wall, ground])
	var with_the_lead: bool = (lead_moved_frame != NEVER_REACHED
			and screen_moved_frame != NEVER_REACHED
			and screen_moved_frame - lead_moved_frame <= SCREEN_AFTER_LEAD_FRAMES)
	return report(with_the_lead,
			"Turn at the edge: the lead moved on frame %d, the screen on frame %d (at most %d after)"
			% [lead_moved_frame, screen_moved_frame, SCREEN_AFTER_LEAD_FRAMES])


## With the player standing in a zone one screen wide, moving it into the zone on its right: the
## camera slides to the new zone's range, where it lets the screen go no further left, never covering
## more than a tenth of the way in one step.
func _moving_into_another_zone_the_camera_slides_to_its_range() -> bool:
	var screen: Vector2 = root.get_visible_rect().size
	var left_zone: CameraZone = _make_zone([Rect2(Vector2.ZERO, screen)])
	var right_zone: CameraZone = _make_zone([Rect2(screen.x, 0.0, 3.0 * screen.x, screen.y)])
	var player: Player = _spawn_still_player(screen / 2.0)
	var camera: GameCamera = _spawn_camera_by_hand(player, false)
	camera.stats.look_ahead_distance = 0.0
	_settle_by_hand(camera)
	var before: Vector2 = camera.global_position
	player.global_position = Vector2(screen.x + EDGE_GAP, screen.y / 2.0)
	var expected_x: float = screen.x + screen.x / 2.0
	var distance: float = absf(expected_x - before.x)
	var largest_step: float = 0.0
	var previous: Vector2 = before
	for _step_index: int in SETTLE_STEPS:
		camera._physics_process(_step())
		largest_step = maxf(largest_step, camera.global_position.distance_to(previous))
		previous = camera.global_position
	var settled_x: float = camera.global_position.x
	await _remove_all([camera, player, left_zone, right_zone])
	return report(absf(settled_x - expected_x) < SAME_SPOT and largest_step <= LARGEST_STEP_SHARE * distance,
			"Into the right zone: camera x from %.1f to %.2f (expected %.1f), largest step %.1f px of %.0f"
			% [before.x, settled_x, expected_x, largest_step, distance])


## The test room's zones together are the box the camera's own limits give, and no two of their
## rectangles overlap.
func _the_test_room_s_zones_cover_it_without_overlapping() -> bool:
	var room: Node = TEST_ROOM_SCENE.instantiate()
	root.add_child(room)
	var camera: GameCamera = room.get_node(^"GameCamera") as GameCamera
	var room_box: Rect2 = Rect2(Vector2(camera.limit_left, camera.limit_top),
			Vector2(camera.limit_right - camera.limit_left, camera.limit_bottom - camera.limit_top))
	var rects: Array[Rect2] = []
	var zones: int = 0
	for child: Node in room.get_children():
		if child is CameraZone:
			zones += 1
			rects.append_array(_rects_of(child as CameraZone))
	var union: Rect2 = rects[0] if not rects.is_empty() else Rect2()
	var area: float = 0.0
	var overlap: float = 0.0
	for i: int in rects.size():
		union = union.merge(rects[i])
		area += rects[i].get_area()
		for j: int in range(i + 1, rects.size()):
			overlap += rects[i].intersection(rects[j]).get_area()
	await _remove_all([room])
	var covers: bool = zones > 0 and union == room_box and is_equal_approx(area, room_box.get_area())
	return report(covers and overlap == 0.0,
			"Room zones: %d zones, %d rectangles, union %s against the room %s, overlap %.0f px²"
			% [zones, rects.size(), union, room_box, overlap])


## In the test room the camera follows the player from the start: with the player walking right
## from where it starts, the camera moves before the player leaves the first screen.
func _the_test_room_follows_the_player_from_the_start() -> bool:
	var room: Node = TEST_ROOM_SCENE.instantiate()
	root.add_child(room)
	var camera: GameCamera = room.get_node(^"GameCamera") as GameCamera
	var player: Player = room.get_node(^"Player") as Player
	for _frame: int in SETTLE_FRAMES:
		await physics_frame
	var first_screen_end: float = camera.limit_left + camera.get_viewport_rect().size.x / camera.zoom.x
	var at_start: float = camera.global_position.x
	var moved: float = 0.0
	var player_x: float = player.global_position.x
	Input.action_press(&"move_right")
	for _frame: int in GIVE_UP_FRAMES:
		await physics_frame
		moved = camera.global_position.x - at_start
		player_x = player.global_position.x
		if moved > MOVED or player_x > first_screen_end:
			break
	Input.action_release(&"move_right")
	await _remove_all([room])
	return report(moved > MOVED and player_x <= first_screen_end,
			"Room start: walking right, the camera moved %.1f px with the player at x %.0f (first screen to x %.0f)"
			% [moved, player_x, first_screen_end])


## Two zones one screen wide, side by side. The left one holds the camera at its centre, then goes
## with queue_free() while the camera still has it: the camera lets go of it on the same frame. Once
## it is freed, on the next frame, the player moves into the right zone, and the camera, looking past
## the freed zone without stopping on an error, settles at the right zone's centre.
func _a_zone_that_goes_away_lets_the_camera_go() -> bool:
	var screen: Vector2 = root.get_visible_rect().size
	var left_zone: CameraZone = _make_zone([Rect2(Vector2.ZERO, screen)])
	var right_zone: CameraZone = _make_zone([Rect2(Vector2(screen.x, 0.0), screen)])
	var player: Player = _spawn_still_player(screen / 2.0)
	var camera: GameCamera = _spawn_camera_by_hand(player, true)
	player.global_position = screen / 2.0 + Vector2(LATER_MOVE, 0.0)
	_settle_by_hand(camera)
	var held_x: float = camera.global_position.x
	left_zone.queue_free()
	_settle_by_hand(camera)
	var let_go_x: float = camera.global_position.x
	await physics_frame
	var right_centre_x: float = screen.x + screen.x / 2.0
	player.global_position = Vector2(right_centre_x, screen.y / 2.0)
	_settle_by_hand(camera)
	var in_the_right_zone_x: float = camera.global_position.x
	await _remove_all([camera, player, right_zone])
	return report(absf(held_x - screen.x / 2.0) < SAME_SPOT and let_go_x > held_x + LATER_MOVE / 2.0
			and absf(in_the_right_zone_x - right_centre_x) < SAME_SPOT,
			"Left zone gone: camera x %.1f while held (centre %.1f), %.1f once queued for freeing, %.1f in the right zone after the left one was freed (centre %.1f)"
			% [held_x, screen.x / 2.0, let_go_x, in_the_right_zone_x, right_centre_x])


## With the real values and the physics, the player runs right from inside a zone towards the zone
## next to it. While the player is still in the first zone, the screen never shows past its edge,
## though the smoothing and the look ahead each lag behind where they head.
func _running_to_an_inner_edge_the_screen_never_passes_it() -> bool:
	var screen: Vector2 = root.get_visible_rect().size
	var edge: float = 2.0 * screen.x
	var top: float = -2.0 * screen.y
	var height: float = 2.0 * screen.y + ZONE_FLOOR_DEPTH
	var ground: StaticBody2D = make_platform(0.0, 2.0 * edge)
	var first: CameraZone = _make_zone([Rect2(0.0, top, edge, height)])
	var second: CameraZone = _make_zone([Rect2(edge, top, edge, height)])
	var player: Player = await spawn_on_floor(Vector2(screen.x, FLOOR_SPAWN_HEIGHT))
	if player == null:
		await _remove_all([first, second, ground])
		return report(false, "Inner edge: the player never landed")
	var camera: GameCamera = _spawn_camera(player)
	var furthest_past: float = -INF
	Input.action_press(&"move_right")
	for _frame: int in GIVE_UP_FRAMES:
		await physics_frame
		if player.global_position.x >= edge:
			break
		furthest_past = maxf(furthest_past, camera.global_position.x + screen.x / 2.0 - edge)
	Input.action_release(&"move_right")
	await _remove_all([camera, player, first, second, ground])
	return report(furthest_past <= SAME_SPOT,
			"Running to the inner edge at %.0f: the screen went %.2f px past it at most"
			% [edge, furthest_past])


## With the real values and the physics, the player walks off a 2500 px ledge and falls to the
## floor of a zone whose bottom is just below the floor: the screen never shows past the bottom,
## though the camera looks down into the fall.
func _falling_to_a_zone_s_bottom_the_screen_never_passes_it() -> bool:
	var screen: Vector2 = root.get_visible_rect().size
	var top: float = -FALL_HEIGHT - screen.y
	var zone: CameraZone = _make_zone([Rect2(0.0, top, 3.0 * screen.x, ZONE_FLOOR_DEPTH - top)])
	var ledge: StaticBody2D = make_platform(0.0, LEDGE_END_X, -FALL_HEIGHT)
	var ground: StaticBody2D = make_platform(0.0, 3.0 * screen.x)
	var player: Player = await _spawn_standing(Vector2(LEDGE_END_X - LEDGE_START_GAP,
			-FALL_HEIGHT + FLOOR_SPAWN_HEIGHT))
	if player == null:
		await _remove_all([zone, ledge, ground])
		return report(false, "Fall to the bottom: the player never landed on the ledge")
	var camera: GameCamera = _spawn_camera(player)
	var furthest_past: float = -INF
	var most_look_down: float = 0.0
	var landed: bool = false
	Input.action_press(&"move_right")
	for _frame: int in GIVE_UP_FRAMES:
		await physics_frame
		furthest_past = maxf(furthest_past,
				camera.global_position.y + screen.y / 2.0 - ZONE_FLOOR_DEPTH)
		most_look_down = maxf(most_look_down, camera.get_look_down())
		if player.get_state() == Player.State.ON_FLOOR and absf(player.global_position.y) < 1.0:
			landed = true
			break
	Input.action_release(&"move_right")
	await _remove_all([camera, player, zone, ledge, ground])
	return report(landed and most_look_down > 0.0 and furthest_past <= SAME_SPOT,
			"Fall of %.0f px to a zone's bottom: landed %s, looked down %.0f px, the screen went %.2f px past the bottom at most"
			% [FALL_HEIGHT, landed, most_look_down, furthest_past])


## From a zone one screen wide into the zone on its right, the camera moves no faster than Zone
## Change Speed until it reaches the new zone's range, instead of whipping the screen across, and it
## still settles there. Once the change is over, a big jump of the player inside the same zone is no
## longer held to that speed.
func _moving_into_another_zone_the_camera_keeps_to_zone_change_speed() -> bool:
	var screen: Vector2 = root.get_visible_rect().size
	var left_zone: CameraZone = _make_zone([Rect2(Vector2.ZERO, screen)])
	var right_zone: CameraZone = _make_zone([Rect2(screen.x, 0.0, 3.0 * screen.x, screen.y)])
	var player: Player = _spawn_still_player(screen / 2.0)
	var camera: GameCamera = _spawn_camera_by_hand(player, false)
	camera.stats.look_ahead_distance = 0.0
	_settle_by_hand(camera)
	player.global_position = Vector2(screen.x + EDGE_GAP, screen.y / 2.0)
	var most_per_step: float = camera.stats.zone_change_speed * _step()
	var largest_step: float = 0.0
	var previous: Vector2 = camera.global_position
	for _step_index: int in SETTLE_STEPS:
		camera._physics_process(_step())
		largest_step = maxf(largest_step, camera.global_position.distance_to(previous))
		previous = camera.global_position
	var expected_x: float = screen.x + screen.x / 2.0
	var settled_x: float = camera.global_position.x
	player.global_position.x += JUMP_IN_THE_ZONE
	var before_jump: Vector2 = camera.global_position
	camera._physics_process(_step())
	var step_after_jump: float = camera.global_position.distance_to(before_jump)
	await _remove_all([camera, player, left_zone, right_zone])
	return report(largest_step <= most_per_step + SAME_SPOT and absf(settled_x - expected_x) < SAME_SPOT
			and step_after_jump > most_per_step,
			"Into the right zone: largest step %.1f px (Zone Change Speed allows %.1f), settled at %.2f (expected %.1f); then a %.0f px jump in the zone moves it %.1f px in one step"
			% [largest_step, most_per_step, settled_x, expected_x, JUMP_IN_THE_ZONE, step_after_jump])


## A level built with a sub-scene: the zone belongs to the sub-scene (its owner), not to the level,
## and the camera, in the level, still uses it.
func _a_zone_in_a_sub_scene_of_the_level_counts() -> bool:
	var screen: Vector2 = root.get_visible_rect().size
	var player: Player = _spawn_still_player(screen / 2.0)
	var level: Node2D = Node2D.new()
	var room: Node2D = Node2D.new()
	level.add_child(room)
	room.owner = level
	var zone: CameraZone = _make_zone_under(room, [Rect2(Vector2.ZERO, screen)])
	zone.name = &"RoomZone"
	var camera: GameCamera = CAMERA_SCENE.instantiate() as GameCamera
	camera.player = player
	level.add_child(camera)
	camera.owner = level
	root.add_child(level)
	var zone_name: String = camera.get_zone_name()
	await _remove_all([level, player])
	return report(zone_name == "RoomZone",
			"Zone owned by a sub-scene of the level: the camera is in zone \"%s\"" % zone_name)


## A camera with no owner, added in the same frame as an old level is freed: the old level's zones,
## which stay in the tree until the end of the frame, do not count.
func _the_zones_of_a_level_being_freed_do_not_count() -> bool:
	var screen: Vector2 = root.get_visible_rect().size
	var old_level: Node2D = Node2D.new()
	root.add_child(old_level)
	_make_zone_under(old_level, [Rect2(Vector2.ZERO, screen)])
	old_level.queue_free()
	var player: Player = _spawn_still_player(screen / 2.0)
	var camera: GameCamera = _spawn_camera_by_hand(player, true)
	var zone_name: String = camera.get_zone_name()
	await _remove_all([camera, player])
	return report(zone_name == "none",
			"Old level being freed: the new camera is in zone \"%s\" (expected none)" % zone_name)


## A zone scaled by 2 has the rectangle the editor and the physics show, and a disabled shape is not
## part of it.
func _a_zone_s_rectangles_follow_its_scale_and_skip_disabled_shapes() -> bool:
	var zone: CameraZone = CameraZone.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = SCALED_SHAPE.size
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	collision.position = SCALED_SHAPE.get_center()
	zone.add_child(collision)
	var off_shape: RectangleShape2D = RectangleShape2D.new()
	off_shape.size = SCALED_SHAPE.size
	var off: CollisionShape2D = CollisionShape2D.new()
	off.shape = off_shape
	off.position = DISABLED_SHAPE_SPOT
	off.disabled = true
	zone.add_child(off)
	zone.scale = Vector2(ZONE_SCALE, ZONE_SCALE)
	root.add_child(zone)
	var expected: Rect2 = Rect2(SCALED_SHAPE.position * ZONE_SCALE, SCALED_SHAPE.size * ZONE_SCALE)
	var limits: Rect2 = zone.get_limits()
	var off_counts: bool = zone.has_point(DISABLED_SHAPE_SPOT * ZONE_SCALE)
	await _remove_all([zone])
	return report(limits == expected and not off_counts,
			"Zone scaled by %.0f: limits %s (expected %s), disabled shape counts %s"
			% [ZONE_SCALE, limits, expected, off_counts])


## A zone with these rectangles, in global coordinates, already in the scene.
func _make_zone(rects: Array) -> CameraZone:
	return _make_zone_under(root, rects)


## A zone with these rectangles, under parent at the origin. Unless parent is the root, the zone is
## owned by parent, as the nodes of a scene are owned by the scene's root.
func _make_zone_under(parent: Node, rects: Array) -> CameraZone:
	var zone: CameraZone = CameraZone.new()
	for rect: Rect2 in rects:
		var shape: RectangleShape2D = RectangleShape2D.new()
		shape.size = rect.size
		var collision: CollisionShape2D = CollisionShape2D.new()
		collision.shape = shape
		collision.position = rect.get_center()
		zone.add_child(collision)
	parent.add_child(zone)
	if parent != root:
		zone.owner = parent
	return zone


## spawn_on_floor, then waits for the state to turn ON_FLOOR too, which comes a frame after the
## touch, so a camera added then knows the floor. Returns null if the player never lands.
func _spawn_standing(at: Vector2) -> Player:
	var player: Player = await spawn_on_floor(at)
	if player == null:
		return null
	for _frame: int in MAX_FRAMES:
		if player.get_state() == Player.State.ON_FLOOR:
			return player
		await physics_frame
	player.queue_free()
	return null


## A zone's rectangles, read from its shapes, in global coordinates.
func _rects_of(zone: CameraZone) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for child: Node in zone.get_children():
		var collision: CollisionShape2D = child as CollisionShape2D
		if collision == null:
			continue
		var rectangle: RectangleShape2D = collision.shape as RectangleShape2D
		if rectangle != null:
			rects.append(Rect2(collision.global_position - rectangle.size / 2.0, rectangle.size))
	return rects


## The x of the screen's centre as the engine shows it: the camera, clamped by its own limits.
func _screen_centre_x(camera: GameCamera) -> float:
	var half: float = camera.get_viewport_rect().size.x / 2.0
	return clampf(camera.global_position.x, camera.limit_left + half, camera.limit_right - half)


## A player that does not move on its own: its physics step is off, so only the case moves it.
func _spawn_still_player(at: Vector2) -> Player:
	var player: Player = spawn_player(at)
	player.set_physics_process(false)
	return player


## A camera following player with its own copy of Stats, physics step off so that the case calls
## it by hand. An instant camera closes the whole distance in one step, so it sits where it heads.
func _spawn_camera_by_hand(player: Player, instant: bool) -> GameCamera:
	var camera: GameCamera = CAMERA_SCENE.instantiate() as GameCamera
	camera.player = player
	camera.stats = camera.stats.duplicate() as CameraStats
	if instant:
		camera.stats.follow_sharpness = INSTANT_SHARPNESS
	root.add_child(camera)
	camera.set_physics_process(false)
	return camera


func _spawn_camera(player: Player) -> GameCamera:
	var camera: GameCamera = CAMERA_SCENE.instantiate() as GameCamera
	camera.player = player
	root.add_child(camera)
	return camera


func _settle_by_hand(camera: GameCamera) -> void:
	for _step_index: int in SETTLE_STEPS:
		camera._physics_process(_step())


## The length of one physics step, in seconds.
func _step() -> float:
	return 1.0 / Engine.physics_ticks_per_second


func _remove_all(nodes: Array) -> void:
	for node: Node in nodes:
		node.queue_free()
	await physics_frame
