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
# freed do not. A scaled zone has the rectangle the editor shows, without its disabled shapes. In a
# zone shorter than the screen, the zone's Vertical Anchor puts the screen's top edge on the zone's
# top at 0, its centre on the zone's centre at 0.5 and its bottom edge on the zone's bottom at 1; in
# a zone taller than the screen it changes nothing. A zone's Bottom Margin lowers the screen's bottom
# edge by as much. A change of zone eases in: the camera's first step is a fraction of its biggest,
# and it never goes past the new zone's range. A zone with Limit Horizontally off keeps its anchor up
# and down but lets the camera follow the player across, where one with it on holds the camera on
# its centre. Where two zones overlap, the one the player came into last counts, or the smaller if
# it came into both at once, and leaving the overlap gives the camera back the zone it is in.
# Running at top speed into a shaft that comes closer, the player's whole body stays on the screen
# while the camera slides in. The
# screen size comes from the camera itself, as the engine takes it: in headless runs the window is
# 64 × 64 and the stretch would make the screen 1920 × 1920, so the test first gives the window the
# game's screen size.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_camera_zones.gd
extends "res://tests/support/player_test.gd"

const TEST_ROOM_SCENE: PackedScene = preload("res://levels/test_room.tscn")
const CAMERA_SCENE: PackedScene = preload("res://camera/game_camera.tscn")
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
## The anchor cases: a zone this tall, much shorter than the 1080 px screen, and the share of its
## height down from its top where the player's feet are in turn, low enough for its 96 px body to be
## inside the zone, since the camera always shows the whole body.
const SHORT_ZONE_HEIGHT: float = 400.0
const SPOTS_DOWN_THE_ZONE: Array[float] = [0.3, 0.9]
## The head case: the player's feet this far under the top of a zone anchored at the top, so its head
## pokes out above the zone.
const FEET_UNDER_THE_TOP: float = 20.0
## The edge margin case: how far up the player is moved in one step, in px.
const SUDDEN_CLIMB: float = 600.0
## The horizontal anchor case: a zone this wide, narrower than the screen.
const NARROW_SHAFT_WIDTH: float = 600.0
## The shaft case: the narrow zone comes this close, as a shaft does, and the player stops this far
## from its far side, as by the column of Lust phase 3's Zone08: two and a half tiles.
const SHAFT_ZOOM: float = 2.0
const SHAFT_STOP_GAP: float = 120.0
## The margin case: how much further below the zone the screen may show, in px.
const BOTTOM_MARGIN: float = 96.0
## The easing case: the spring's reference values, whatever the game's tuning.
const REFERENCE_ZONE_CHANGE_SHARPNESS: float = 6.0
const REFERENCE_ZONE_CHANGE_SPEED: float = 2000.0
## The easing case: the first step of a change may be at most this share of the biggest one.
const FIRST_STEP_SHARE: float = 1.0 / 3.0
## The easing case: a change counts as done at this share of the way.
const MOSTLY_DONE: float = 0.95
## The easing case: a short change of zone, from a zone one screen wide into one lower down by this
## much, in px.
const SHORT_CHANGE: float = 300.0
## The horizontal case: a zone this wide, narrower than the screen, and the player's two spots in it.
const NARROW_ZONE_WIDTH: float = 1200.0
const NARROW_ZONE_START_X: float = 100.0
const NARROW_ZONE_END_X: float = 1100.0
## The edge-turn case's wall, and the floor of the cases with physics.
const WALL_THICKNESS: float = 100.0
const FLOOR_SPAWN_HEIGHT: float = -2.0


func _initialize() -> void:
	# Nodes added before the first frame only get _ready on it, and the cases need the camera ready
	# as soon as it is added.
	await process_frame
	# Without a window the root is 64 × 64 px, and the Expand aspect makes that a 1920 × 1920 screen.
	# The game's screen size takes effect on the next frame.
	root.size = Vector2i(int(ProjectSettings.get_setting("display/window/size/viewport_width")),
			int(ProjectSettings.get_setting("display/window/size/viewport_height")))
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
	results.append(await _in_a_zone_shorter_than_the_screen_the_anchor_places_the_screen())
	results.append(await _in_a_zone_taller_than_the_screen_the_anchor_changes_nothing())
	results.append(await _a_bottom_margin_lets_the_screen_show_more_below())
	results.append(await _a_change_of_zone_eases_in_and_never_goes_past())
	results.append(await _a_short_change_of_zone_is_mostly_done_in_under_a_second())
	results.append(await _a_zone_that_does_not_limit_horizontally_lets_the_camera_follow_across())
	results.append(await _where_zones_overlap_the_one_entered_last_counts())
	results.append(await _the_player_s_head_stays_on_screen_past_a_zone_s_top())
	results.append(await _the_horizontal_anchor_puts_the_screen_s_side_on_the_zone_s_side())
	results.append(await _a_sudden_climb_keeps_the_body_edge_margin_from_the_top())
	results.append(await _into_a_zone_that_limits_across_the_lead_does_not_snap())
	results.append(await _running_into_a_shaft_the_body_stays_on_screen())
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


## In a wide zone 400 px tall, with the player near its top and then near its bottom, the screen's
## top edge sits on the zone's top at Vertical Anchor 0, its centre on the zone's centre at 0.5 and
## its bottom edge on the zone's bottom at 1.
func _in_a_zone_shorter_than_the_screen_the_anchor_places_the_screen() -> bool:
	var screen: Vector2 = root.get_visible_rect().size
	var zone_rect: Rect2 = Rect2(0.0, 0.0, 3.0 * screen.x, SHORT_ZONE_HEIGHT)
	var zone: CameraZone = _make_zone([zone_rect])
	var player: Player = _spawn_still_player(zone_rect.get_center())
	var camera: GameCamera = _spawn_camera_by_hand(player, true)
	var expected: Dictionary[float, float] = {
		0.0: zone_rect.position.y + screen.y / 2.0,
		0.5: zone_rect.get_center().y,
		1.0: zone_rect.end.y - screen.y / 2.0,
	}
	var largest_miss: float = 0.0
	var found: String = ""
	for anchor: float in expected:
		zone.vertical_anchor = anchor
		for share: float in SPOTS_DOWN_THE_ZONE:
			player.global_position = Vector2(zone_rect.get_center().x,
					zone_rect.position.y + share * zone_rect.size.y)
			_settle_by_hand(camera)
			largest_miss = maxf(largest_miss, absf(camera.global_position.y - expected[anchor]))
		found += " anchor %.1f: centre at y %.1f (expected %.1f);" % [anchor,
				camera.global_position.y, expected[anchor]]
	await _remove_all([camera, player, zone])
	return report(largest_miss < SAME_SPOT,
			"Zone %.0f px tall, screen %.0f px tall:%s largest miss %.3f px"
			% [SHORT_ZONE_HEIGHT, screen.y, found, largest_miss])


## In a zone taller than the screen, with Vertical Anchor 1, the camera follows the player in the
## middle of the zone, and near the zone's bottom the screen stops at it, as with any anchor.
func _in_a_zone_taller_than_the_screen_the_anchor_changes_nothing() -> bool:
	var screen: Vector2 = root.get_visible_rect().size
	var zone_rect: Rect2 = Rect2(Vector2.ZERO, 3.0 * screen)
	var zone: CameraZone = _make_zone([zone_rect])
	zone.vertical_anchor = 1.0
	var middle: Vector2 = zone_rect.get_center()
	var player: Player = _spawn_still_player(middle)
	var camera: GameCamera = _spawn_camera_by_hand(player, true)
	_settle_by_hand(camera)
	var middle_miss: float = absf(camera.global_position.y - middle.y)
	player.global_position = Vector2(middle.x, zone_rect.end.y - EDGE_GAP)
	_settle_by_hand(camera)
	var bottom_edge: float = camera.global_position.y + screen.y / 2.0
	await _remove_all([camera, player, zone])
	return report(middle_miss < SAME_SPOT and absf(bottom_edge - zone_rect.end.y) < SAME_SPOT,
			"Zone %.0f px tall with anchor 1: in the middle the camera is %.3f px off the player; near the bottom the screen's bottom edge is at %.1f, the zone's at %.1f"
			% [zone_rect.size.y, middle_miss, bottom_edge, zone_rect.end.y])


## In a zone 400 px tall with Vertical Anchor 1 and Bottom Margin 96, the screen's bottom edge sits
## 96 px below the zone's bottom.
func _a_bottom_margin_lets_the_screen_show_more_below() -> bool:
	var screen: Vector2 = root.get_visible_rect().size
	var zone_rect: Rect2 = Rect2(0.0, 0.0, 3.0 * screen.x, SHORT_ZONE_HEIGHT)
	var zone: CameraZone = _make_zone([zone_rect])
	zone.vertical_anchor = 1.0
	zone.bottom_margin = BOTTOM_MARGIN
	var player: Player = _spawn_still_player(zone_rect.get_center())
	var camera: GameCamera = _spawn_camera_by_hand(player, true)
	_settle_by_hand(camera)
	var bottom_edge: float = camera.global_position.y + screen.y / 2.0
	var expected: float = zone_rect.end.y + BOTTOM_MARGIN
	await _remove_all([camera, player, zone])
	return report(absf(bottom_edge - expected) < SAME_SPOT,
			"Zone with its bottom at %.0f and Bottom Margin %.0f: the screen's bottom edge at %.1f (expected %.1f)"
			% [zone_rect.end.y, BOTTOM_MARGIN, bottom_edge, expected])


## From a zone one screen wide into the zone on its right, with the real smoothing: the camera's
## first step is at most a third of its biggest, it never goes past the new zone's range, and it
## settles there.
func _a_change_of_zone_eases_in_and_never_goes_past() -> bool:
	var screen: Vector2 = root.get_visible_rect().size
	var left_zone: CameraZone = _make_zone([Rect2(Vector2.ZERO, screen)])
	var right_zone: CameraZone = _make_zone([Rect2(screen.x, 0.0, 3.0 * screen.x, screen.y)])
	var player: Player = _spawn_still_player(screen / 2.0)
	var camera: GameCamera = _spawn_camera_by_hand(player, false)
	camera.stats.look_ahead_distance = 0.0
	# The shape of the spring, not the game's tuning: the reference values the README describes.
	camera.stats.zone_change_sharpness = REFERENCE_ZONE_CHANGE_SHARPNESS
	camera.stats.zone_change_speed = REFERENCE_ZONE_CHANGE_SPEED
	_settle_by_hand(camera)
	var start_x: float = camera.global_position.x
	player.global_position = Vector2(screen.x + EDGE_GAP, screen.y / 2.0)
	var expected_x: float = screen.x + screen.x / 2.0
	var steps: Array[float] = []
	var furthest_x: float = start_x
	var previous_x: float = start_x
	for _step_index: int in SETTLE_STEPS:
		camera._physics_process(_step())
		steps.append(camera.global_position.x - previous_x)
		previous_x = camera.global_position.x
		furthest_x = maxf(furthest_x, previous_x)
	var biggest: float = steps.max()
	await _remove_all([camera, player, left_zone, right_zone])
	return report(steps[0] <= FIRST_STEP_SHARE * biggest and furthest_x <= expected_x + SAME_SPOT
			and absf(previous_x - expected_x) < SAME_SPOT,
			"Change of zone from x %.0f to %.0f: first step %.1f px, biggest %.1f px, furthest x %.2f, settled at %.2f"
			% [start_x, expected_x, steps[0], biggest, furthest_x, previous_x])


## From a low zone, one screen wide and anchored at the bottom, into the one under it, 300 px tall
## and anchored at the bottom too, as when the player drops to a floor 300 px lower, with the real
## smoothing: the camera moves 300 px down, 95 % of the way in under a second, and settles.
func _a_short_change_of_zone_is_mostly_done_in_under_a_second() -> bool:
	var screen: Vector2 = root.get_visible_rect().size
	var upper_zone: CameraZone = _make_zone([Rect2(0.0, 0.0, screen.x, SHORT_ZONE_HEIGHT)])
	var lower_zone: CameraZone = _make_zone([Rect2(0.0, SHORT_ZONE_HEIGHT, screen.x, SHORT_CHANGE)])
	upper_zone.vertical_anchor = 1.0
	lower_zone.vertical_anchor = 1.0
	var player: Player = _spawn_still_player(Vector2(screen.x / 2.0, SHORT_ZONE_HEIGHT / 2.0))
	var camera: GameCamera = _spawn_camera_by_hand(player, false)
	_settle_by_hand(camera)
	var start_y: float = camera.global_position.y
	player.global_position = Vector2(screen.x / 2.0, SHORT_ZONE_HEIGHT + SHORT_CHANGE / 2.0)
	var expected_y: float = SHORT_ZONE_HEIGHT + SHORT_CHANGE - screen.y / 2.0
	var mostly_done_frame: int = NEVER_REACHED
	for step_index: int in SETTLE_STEPS:
		camera._physics_process(_step())
		var done: float = (camera.global_position.y - start_y) / (expected_y - start_y)
		if mostly_done_frame == NEVER_REACHED and done >= MOSTLY_DONE:
			mostly_done_frame = step_index + 1
	var settled_y: float = camera.global_position.y
	var mostly_done_time: float = mostly_done_frame * _step()
	await _remove_all([camera, player, upper_zone, lower_zone])
	return report(mostly_done_frame != NEVER_REACHED and mostly_done_time < 1.0
			and absf(settled_y - expected_y) < SAME_SPOT,
			"Change of zone of %.0f px down: 95 %% done in %.2f s, settled at %.2f (expected %.1f)"
			% [expected_y - start_y, mostly_done_time, settled_y, expected_y])


## In a zone 1200 px wide and 400 px tall, anchored at the bottom, with the player moved from near
## its left side to near its right side: with Limit Horizontally on, the camera stays on the zone's
## centre across; with it off, it follows the player across, to Window Half Width behind it, while
## the screen's bottom edge stays on the zone's bottom.
func _a_zone_that_does_not_limit_horizontally_lets_the_camera_follow_across() -> bool:
	var screen: Vector2 = root.get_visible_rect().size
	var zone_rect: Rect2 = Rect2(0.0, 0.0, NARROW_ZONE_WIDTH, SHORT_ZONE_HEIGHT)
	var found: Dictionary[bool, Vector2] = {}
	var window: float = 0.0
	for limits: bool in [true, false]:
		var zone: CameraZone = _make_zone([zone_rect])
		zone.vertical_anchor = 1.0
		zone.limit_horizontally = limits
		var player: Player = _spawn_still_player(Vector2(NARROW_ZONE_START_X, zone_rect.get_center().y))
		var camera: GameCamera = _spawn_camera_by_hand(player, true)
		camera.stats.look_ahead_distance = 0.0
		window = camera.stats.window_half_width
		_settle_by_hand(camera)
		player.global_position.x = NARROW_ZONE_END_X
		_settle_by_hand(camera)
		found[limits] = camera.global_position
		await _remove_all([camera, player, zone])
	var bottom_y: float = zone_rect.end.y - screen.y / 2.0
	var held: bool = (absf(found[true].x - zone_rect.get_center().x) < SAME_SPOT
			and absf(found[true].y - bottom_y) < SAME_SPOT)
	var follows: bool = (absf(found[false].x - (NARROW_ZONE_END_X - window)) < SAME_SPOT
			and absf(found[false].y - bottom_y) < SAME_SPOT)
	return report(held and follows,
			"Zone %.0f px wide, player at x %.0f: limiting across, the camera at %s (zone centre x %.0f); not limiting, at %s (expected x %.0f, y %.0f)"
			% [NARROW_ZONE_WIDTH, NARROW_ZONE_END_X, found[true], zone_rect.get_center().x, found[false],
			NARROW_ZONE_END_X - window, bottom_y])


## A big zone four screens wide and a small one two screens wide that overlaps its last screen. With
## the player walking from the big zone into the overlap, the camera takes the small zone there, the
## one it came into last; back in the big zone alone, the big one; walking from the small zone alone
## into the overlap, the big one, which it came into last; starting in the overlap, in both at once,
## the smaller.
func _where_zones_overlap_the_one_entered_last_counts() -> bool:
	var screen: Vector2 = root.get_visible_rect().size
	var big: CameraZone = _make_zone([Rect2(Vector2.ZERO, Vector2(4.0, 1.0) * screen)])
	big.name = &"Big"
	var small: CameraZone = _make_zone([Rect2(Vector2(3.0, 0.0) * screen, Vector2(2.0, 1.0) * screen)])
	small.name = &"Small"
	var in_big: Vector2 = Vector2(1.5, 0.5) * screen
	var in_overlap: Vector2 = Vector2(3.5, 0.5) * screen
	var in_small: Vector2 = Vector2(4.5, 0.5) * screen
	var found: Array[String] = []
	for path: Array in [[in_big, in_overlap, in_big], [in_small, in_overlap], [in_overlap]]:
		var player: Player = _spawn_still_player(path[0])
		var camera: GameCamera = _spawn_camera_by_hand(player, true)
		var names: Array[String] = [camera.get_zone_name()]
		for spot: Vector2 in path.slice(1):
			player.global_position = spot
			camera._physics_process(_step())
			names.append(camera.get_zone_name())
		found.append(" > ".join(names))
		await _remove_all([camera, player])
	await _remove_all([big, small])
	return report(found == ["Big > Small > Big", "Small > Big", "Small"],
			"Overlapping zones, Small inside the last screen of Big: from Big into the overlap and back %s; from Small into the overlap %s; starting in the overlap %s"
			% [found[0], found[1], found[2]])


## In a zone 400 px tall anchored at the top, with the player's feet 20 px under its top, so its
## head pokes out above the zone: the camera moves up past the zone's top just enough for the head
## to be on the screen's top edge.
func _the_player_s_head_stays_on_screen_past_a_zone_s_top() -> bool:
	var screen: Vector2 = root.get_visible_rect().size
	var zone: CameraZone = _make_zone([Rect2(0.0, 0.0, 3.0 * screen.x, SHORT_ZONE_HEIGHT)])
	zone.vertical_anchor = 0.0
	var player: Player = _spawn_still_player(Vector2(1.5 * screen.x, FEET_UNDER_THE_TOP))
	var camera: GameCamera = _spawn_camera_by_hand(player, true)
	_settle_by_hand(camera)
	var head: float = player.global_position.y - body_size(player).y
	var top_edge: float = camera.global_position.y - screen.y / 2.0
	await _remove_all([camera, player, zone])
	return report(absf(top_edge - head) < SAME_SPOT,
			"Head %.0f px above a zone's top: the screen's top edge at y %.1f, the head at y %.1f"
			% [-head, top_edge, head])


## A zone 600 px wide, limiting the screen across, with Horizontal Anchor 1 and then 0: the screen's
## right edge sits on the zone's right edge, and then its left edge on the zone's left edge.
func _the_horizontal_anchor_puts_the_screen_s_side_on_the_zone_s_side() -> bool:
	var screen: Vector2 = root.get_visible_rect().size
	var zone_rect: Rect2 = Rect2(screen.x, 0.0, NARROW_SHAFT_WIDTH, 3.0 * screen.y)
	var zone: CameraZone = _make_zone([zone_rect])
	var player: Player = _spawn_still_player(zone_rect.get_center())
	var camera: GameCamera = _spawn_camera_by_hand(player, true)
	zone.horizontal_anchor = 1.0
	_settle_by_hand(camera)
	var right_edge: float = camera.global_position.x + screen.x / 2.0
	zone.horizontal_anchor = 0.0
	_settle_by_hand(camera)
	var left_edge: float = camera.global_position.x - screen.x / 2.0
	await _remove_all([camera, player, zone])
	return report(absf(right_edge - zone_rect.end.x) < SAME_SPOT and absf(left_edge - zone_rect.position.x) < SAME_SPOT,
			"Zone %.0f px wide from x %.0f to %.0f: anchor 1, the screen's right edge at %.1f; anchor 0, its left edge at %.1f"
			% [NARROW_SHAFT_WIDTH, zone_rect.position.x, zone_rect.end.x, right_edge, left_edge])


## Outside every zone, with the real smoothing, the player moved 600 px up in one step: on that very
## step the camera already keeps the top of its body Edge Margin of the screen from the top edge,
## instead of letting the smoothing catch up.
func _a_sudden_climb_keeps_the_body_edge_margin_from_the_top() -> bool:
	var screen: Vector2 = root.get_visible_rect().size
	var player: Player = _spawn_still_player(Vector2.ZERO)
	var camera: GameCamera = _spawn_camera_by_hand(player, false)
	_settle_by_hand(camera)
	player.global_position.y -= SUDDEN_CLIMB
	camera._physics_process(_step())
	var head: float = player.global_position.y - body_size(player).y
	var from_top: float = head - (camera.global_position.y - screen.y / 2.0)
	var margin: float = camera.stats.edge_margin * screen.y
	await _remove_all([camera, player])
	return report(from_top >= margin - SAME_SPOT,
			"A sudden climb of %.0f px: one step later the head is %.1f px from the screen's top edge (Edge Margin %.1f px)"
			% [SUDDEN_CLIMB, from_top, margin])


## The player leads the camera to the right in a wide zone that does not limit across, then steps
## into a narrow zone on its right that does, anchored on its right side: the camera slides into the
## new range with no step longer than Zone Change Speed allows, the lead included, instead of
## dropping the lead in one step.
func _into_a_zone_that_limits_across_the_lead_does_not_snap() -> bool:
	var screen: Vector2 = root.get_visible_rect().size
	var wide: CameraZone = _make_zone([Rect2(Vector2.ZERO, Vector2(3.0, 1.0) * screen)])
	wide.limit_horizontally = false
	var narrow: CameraZone = _make_zone([Rect2(Vector2(3.0 * screen.x, 0.0), Vector2(NARROW_SHAFT_WIDTH, screen.y))])
	narrow.horizontal_anchor = 1.0
	var player: Player = _spawn_still_player(Vector2(1.5, 0.5) * screen)
	var camera: GameCamera = _spawn_camera_by_hand(player, false)
	player.global_position.x = 3.0 * screen.x - EDGE_GAP
	_settle_by_hand(camera)
	var lead_before: float = camera.get_look_ahead()
	player.global_position.x = 3.0 * screen.x + NARROW_SHAFT_WIDTH / 2.0
	var most_per_step: float = camera.stats.zone_change_speed * _step()
	var largest_step: float = 0.0
	var previous: Vector2 = camera.global_position
	for _step_index: int in SETTLE_STEPS:
		camera._physics_process(_step())
		largest_step = maxf(largest_step, camera.global_position.distance_to(previous))
		previous = camera.global_position
	var expected_x: float = 3.0 * screen.x + NARROW_SHAFT_WIDTH - screen.x / 2.0
	await _remove_all([camera, player, wide, narrow])
	return report(largest_step <= most_per_step + SAME_SPOT and absf(previous.x - expected_x) < SAME_SPOT,
			"Into a narrow zone limiting across, leading %.0f px: largest step %.1f px (Zone Change Speed allows %.1f), settled at x %.1f (expected %.1f)"
			% [lead_before, largest_step, most_per_step, previous.x, expected_x])


## The player runs at top speed out of a wide zone into a narrow one beside it, as into a shaft: it
## limits across, is anchored on its far side and comes closer, at Zoom 2. The player stops Shaft Stop
## Gap from that side. From the step the player is in the shaft, while the camera slides into the new
## range and closes in, the player's whole body stays on the screen. Before, the wide zone's side may
## cut off up to half of it, as at any inner edge.
func _running_into_a_shaft_the_body_stays_on_screen() -> bool:
	var screen: Vector2 = root.get_visible_rect().size
	var wide: CameraZone = _make_zone([Rect2(Vector2.ZERO, Vector2(3.0, 3.0) * screen)])
	var shaft_rect: Rect2 = Rect2(3.0 * screen.x, 0.0, NARROW_SHAFT_WIDTH, 3.0 * screen.y)
	var shaft: CameraZone = _make_zone([shaft_rect])
	shaft.horizontal_anchor = 1.0
	shaft.zoom = SHAFT_ZOOM
	shaft.auto_zoom = false
	var player: Player = _spawn_still_player(Vector2(3.0 * screen.x - EDGE_GAP, 1.5 * screen.y))
	var camera: GameCamera = _spawn_camera_by_hand(player, false)
	_settle_by_hand(camera)
	var stop_x: float = shaft_rect.end.x - SHAFT_STOP_GAP
	var speed: float = player.stats.max_run_speed
	var run: float = speed * _step()
	var half_body: float = body_size(player).x / 2.0
	var worst: float = 0.0
	for _step_index: int in SETTLE_STEPS:
		player.global_position.x = minf(player.global_position.x + run, stop_x)
		camera._physics_process(_step())
		if player.global_position.x < shaft_rect.position.x:
			continue
		var half: float = screen.x / (2.0 * camera.zoom.x)
		worst = maxf(worst, maxf(camera.global_position.x - half - (player.global_position.x - half_body),
				player.global_position.x + half_body - (camera.global_position.x + half)))
	await _remove_all([camera, player, wide, shaft])
	return report(worst <= SAME_SPOT,
			"Running at %.0f px/s into a shaft at Zoom %.1f, stopping %.0f px from its far side: the body at worst %.1f px past the screen's side"
			% [speed, SHAFT_ZOOM, SHAFT_STOP_GAP, maxf(worst, 0.0)])


## A zone with these rectangles, in global coordinates, already in the scene.
func _make_zone(rects: Array) -> CameraZone:
	return _make_zone_under(root, rects)


## A zone with these rectangles, under parent at the origin, that limits the screen on all four
## sides, as the cases here need. Unless parent is the root, the zone is owned by parent, as the
## nodes of a scene are owned by the scene's root.
func _make_zone_under(parent: Node, rects: Array) -> CameraZone:
	var zone: CameraZone = CameraZone.new()
	zone.limit_horizontally = true
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


## A camera following player with the real values, except that it never closes in on a player
## standing still: the cases here stop the player at walls and floors, and test_camera_zoom.gd checks
## that on its own.
func _spawn_camera(player: Player) -> GameCamera:
	var camera: GameCamera = CAMERA_SCENE.instantiate() as GameCamera
	camera.player = player
	camera.stats = camera.stats.duplicate() as CameraStats
	camera.stats.idle_delay = INF
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
