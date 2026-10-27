# Smoke test of the gym (ADR 0036). Each station is one screen wide and they sit back to back, in
# order; each has a sign with text and a start, and GymStations lists every start, in the same
# order. The man starts at the first station, lands on its floor, and its sign shows whole on the
# screen. Each station that comes adds its own case.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_gym.gd
extends "res://tests/support/player_test.gd"

const GYM_SCENE: PackedScene = preload("res://levels/gym/gym.tscn")
## How wide each station is, in px: one screen.
const STATION_WIDTH: float = 1920.0
## The top of every station's floor, in its own coordinates.
const FLOOR_TOP: float = 1000.0
## Where the run at the movement station's hole starts, in its coordinates: far enough from the
## edge, at 900, to reach the top speed.
const RUN_START_X: float = 640.0
## The far edge of the movement station's hole, in its coordinates.
const HOLE_RIGHT: float = 1260.0
## Physics frames between the feet leaving the edge and the press of Jump. With the press delay it
## counts 3 frames later, inside the 4 frames of the 0.07 s coyote time at 60 Hz.
const LATE_FRAMES: int = 1
## Physics frames the camera gets to settle on a man put at a station's start: past the idle delay
## and the whole of the idle zoom, which shows the least of the station, as for someone reading.
const SETTLE_FRAMES: int = 300
## How far inside the screen's edges a sign must stay, in px, not to look cut.
const SIGN_MARGIN: float = 24.0
## How far above a floor a placed man starts, in px, so he lands on it. His origin is his feet.
const DROP_HEIGHT: float = 20.0
## How far left of the lone wall's middle the man starts its climb, in px.
const LONE_WALL_RUN_UP: float = 200.0
## Below this speed right, in px/s, a man running right on the floor is held up by something.
const HELD_UP_SPEED: float = 1.0
## How far short of the gym's right end the walk through it must get, in px: a body and a half.
const END_GAP: float = 72.0
## How many times the walk through the gym may take as long as the whole gym at top speed.
const WALK_TIME_SHARE: float = 2.0
## Half the width of the wall station's walls, in px.
const WALL_HALF_WIDTH: float = 32.0
## How far above the bottom of the chimney's walls the man's feet start, in px: in the air, touching
## the right wall, as after a jump into it.
const CHIMNEY_START_ABOVE_BOTTOM: float = 40.0
## Physics frames a climb gets: the tower's height in wall jumps, with room to spare.
const CLIMB_FRAMES: int = 900
## How far inside the fixed room's sides the walk across it starts and ends, in px.
const ROOM_INSET: float = 80.0
## The most the camera may move while the man walks across the fixed room, in px.
const HELD_STILL: float = 1.0

## The highest the feet got in the last _press_jump_on_each_touch, as a y.
var _highest_feet: float = INF


func _initialize() -> void:
	# Without a window the root is 64 × 64 px, and the Expand aspect makes that a 1920 × 1920 screen.
	# A size set before the first frame is undone when the window starts, and a new size takes
	# effect on the next frame.
	await process_frame
	root.size = Vector2i(int(ProjectSettings.get_setting("display/window/size/viewport_width")),
			int(ProjectSettings.get_setting("display/window/size/viewport_height")))
	await process_frame
	var results: Array[bool] = []
	results.append(await _the_stations_sit_back_to_back_in_order())
	results.append(await _each_station_has_a_sign_and_a_listed_start())
	results.append(await _the_man_lands_at_the_first_station())
	results.append(await _the_man_walks_through_every_station())
	results.append(await _each_sign_shows_whole_from_its_start())
	results.append(await _the_last_number_key_takes_the_camera_there())
	results.append(await _the_jump_marks_follow_the_stats())
	results.append(await _only_a_held_jump_reaches_the_one_way_platform())
	results.append(await _a_jump_in_the_coyote_time_clears_the_hole())
	results.append(await _the_lone_wall_cannot_be_climbed())
	results.append(await _the_chimneys_are_climbed_with_jump_alone())
	results.append(await _the_fall_off_the_tower_looks_down())
	results.append(await _the_fixed_zone_holds_the_camera_still())
	finish(results)


func _the_stations_sit_back_to_back_in_order() -> bool:
	var gym: Level = _make_gym()
	var off: Array[String] = []
	var stations: Array[Node] = _stations_of(gym)
	for i: int in stations.size():
		var x: float = (stations[i] as Node2D).position.x
		if not is_equal_approx(x, STATION_WIDTH * i):
			off.append("%s at x %.0f" % [stations[i].name, x])
	var count: int = stations.size()
	gym.free()
	return report(off.is_empty(), "%d stations a screen apart, in order; off: %s" % [count, off])


func _each_station_has_a_sign_and_a_listed_start() -> bool:
	var gym: Level = _make_gym()
	var starts: Array[Marker2D] = (gym.get_node(^"GymStations") as GymStations).starts
	var missing: Array[String] = []
	var stations: Array[Node] = _stations_of(gym)
	for i: int in stations.size():
		var hint: GymHint = stations[i].get_node_or_null(^"GymHint") as GymHint
		if hint == null or hint.text.is_empty():
			missing.append("%s: sign" % stations[i].name)
		var start: Marker2D = stations[i].get_node_or_null(^"Start") as Marker2D
		if start == null or i >= starts.size() or starts[i] != start:
			missing.append("%s: start in Starts, at %d" % [stations[i].name, i])
	var extra: bool = starts.size() != stations.size()
	gym.free()
	return report(missing.is_empty() and not extra,
			"Each station's sign and start, in order: missing %s, %s starts for the stations"
			% [missing, "other" if extra else "as many"])


func _the_man_lands_at_the_first_station() -> bool:
	var gym: Level = _make_gym()
	var player: Player = gym.player
	var landed: bool = await wait_until_on_floor(player)
	var first: Node2D = _stations_of(gym)[0] as Node2D
	var in_first: bool = player.global_position.x >= first.global_position.x \
			and player.global_position.x < first.global_position.x + STATION_WIDTH
	gym.free()
	return report(landed and in_first, "Start: lands %s, in the first station %s"
			% [landed, in_first])


## Running right from the first start, and jumping only when held up on the floor, as out of the
## hole's pit or onto a block, the man gets to End Gap from the gym's right end: nothing in a
## station closes the way on. The demons are switched off, as their bites would end the walk at
## random.
func _the_man_walks_through_every_station() -> bool:
	var gym: Level = _make_gym()
	for node: Node in gym.find_children("*", "", true, false):
		if node is Demon:
			node.process_mode = Node.PROCESS_MODE_DISABLED
	var player: Player = gym.player
	await wait_until_on_floor(player)
	var stations: Array[Node] = _stations_of(gym)
	var last_x: float = (stations[stations.size() - 1] as Node2D).global_position.x \
			+ STATION_WIDTH - END_GAP
	var walk_frames: int = ceili(WALK_TIME_SHARE * last_x / player.stats.max_run_speed
			* Engine.physics_ticks_per_second)
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.run_direction = 1.0
	stand_in.hold_jump = true
	var through: bool = await wait_until(func() -> bool:
		if player.is_on_floor() and player.velocity.x < HELD_UP_SPEED:
			stand_in.press_jump()
		return player.global_position.x > last_x, walk_frames)
	var stopped_at: float = player.global_position.x
	gym.free()
	return report(through, "Walk to the gym's end at x %.0f: got there %s (at x %.0f)"
			% [last_x, through, stopped_at])


## With the man standing at a station's start and the camera settled, the station's sign shows
## whole on the screen, Sign Margin clear of its edges.
func _each_sign_shows_whole_from_its_start() -> bool:
	var gym: Level = _make_gym()
	var camera: GameCamera = gym.get_node(^"GameCamera") as GameCamera
	var cut: Array[String] = []
	for station: Node in _stations_of(gym):
		await _place(gym.player, (station.get_node(^"Start") as Marker2D).global_position)
		await wait_frames(SETTLE_FRAMES)
		var label: Label = (station.get_node(^"GymHint") as GymHint).label
		var sign_rect: Rect2 = Rect2(label.global_position, label.size).grow(SIGN_MARGIN)
		var screen: Rect2 = _screen(camera)
		if not screen.encloses(sign_rect):
			cut.append("%s: sign %s, screen %s" % [station.name, sign_rect, screen])
		for covered: String in _what_covers(station as Node2D, sign_rect):
			cut.append("%s: sign over %s" % [station.name, covered])
	gym.free()
	return report(cut.is_empty(),
			"Each sign whole on the screen from its start, over nothing played with; cut: %s" % [cut])


## From the first station, the number key of the last one puts the man at its start, and once the
## camera has settled, as for the signs, it shows that station's sign whole: the longest jump the
## keys make, eased across.
func _the_last_number_key_takes_the_camera_there() -> bool:
	var gym: Level = _make_gym()
	var camera: GameCamera = gym.get_node(^"GameCamera") as GameCamera
	await wait_until_on_floor(gym.player)
	var stations: Array[Node] = _stations_of(gym)
	var last: Node2D = stations[stations.size() - 1] as Node2D
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = KEY_1 + stations.size() - 1 as Key
	event.pressed = true
	root.push_input(event)
	var at_start: bool = gym.player.global_position.is_equal_approx(
			(last.get_node(^"Start") as Marker2D).global_position)
	await wait_frames(SETTLE_FRAMES)
	var label: Label = (last.get_node(^"GymHint") as GymHint).label
	var shown: bool = _screen(camera).encloses(
			Rect2(label.global_position, label.size).grow(SIGN_MARGIN))
	var last_name: StringName = last.name
	gym.free()
	return report(at_start and shown, "Key %d: the man at %s's start %s, its sign whole on the screen %s"
			% [stations.size(), last_name, at_start, shown])


## The movement station's marks sit at the tap's and the full jump's heights above its floor.
func _the_jump_marks_follow_the_stats() -> bool:
	var gym: Level = _make_gym()
	var station: Node2D = _movement_station(gym)
	var stats: PlayerMovementStats = gym.player.stats
	var short_y: float = (station.get_node(^"ShortJumpMark") as Line2D).points[0].y
	var full_y: float = (station.get_node(^"FullJumpMark") as Line2D).points[0].y
	var short_ok: bool = is_equal_approx(FLOOR_TOP - short_y, stats.min_jump_height)
	var full_ok: bool = is_equal_approx(FLOOR_TOP - full_y, stats.jump_height)
	gym.free()
	return report(short_ok and full_ok, "Jump marks: tap at %.0f px %s, full at %.0f px %s"
			% [FLOOR_TOP - short_y, short_ok, FLOOR_TOP - full_y, full_ok])


## Under the one-way platform, a tap lands back on the floor and a held jump lands on top of it.
func _only_a_held_jump_reaches_the_one_way_platform() -> bool:
	var landed_y: Array[float] = []
	var halfway: float = 0.0
	for held: bool in [false, true]:
		var gym: Level = _make_gym()
		var station: Node2D = _movement_station(gym)
		var platform: StaticBody2D = station.get_node(^"OneWayPlatform") as StaticBody2D
		var player: Player = gym.player
		var floor_y: float = station.global_position.y + FLOOR_TOP
		halfway = (_top_of(platform) + floor_y) / 2.0
		await _place(player, Vector2(platform.global_position.x, floor_y - DROP_HEIGHT))
		var stand_in: StandInInput = put_a_stand_in(player)
		stand_in.hold_jump = held
		stand_in.press_jump()
		await wait_until(func() -> bool: return not player.is_on_floor())
		await wait_until_on_floor(player)
		landed_y.append(player.global_position.y)
		gym.free()
	var tap_on_floor: bool = landed_y[0] > halfway
	var held_on_top: bool = landed_y[1] < halfway
	return report(tap_on_floor and held_on_top,
			"One-way platform: a tap lands below its top %s, a held jump on it %s"
			% [tap_on_floor, held_on_top])


## Running at the hole, a jump pressed just after the feet leave the edge, in the coyote time, still
## jumps and lands on the far side.
func _a_jump_in_the_coyote_time_clears_the_hole() -> bool:
	var gym: Level = _make_gym()
	var station: Node2D = _movement_station(gym)
	var player: Player = gym.player
	await _place(player, station.global_position + Vector2(RUN_START_X, FLOOR_TOP - DROP_HEIGHT))
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.run_direction = 1.0
	stand_in.hold_jump = true
	await wait_until(func() -> bool: return not player.is_on_floor())
	var left_at: float = player.global_position.x
	await wait_frames(LATE_FRAMES)
	stand_in.press_jump()
	await wait_frames(PRESS_DELAY_FRAMES + 1)
	var jumped: bool = player.velocity.y < 0.0
	await wait_until_on_floor(player)
	var far_edge: float = station.global_position.x + HOLE_RIGHT
	var cleared: bool = player.global_position.x > far_edge \
			and player.global_position.y < station.global_position.y + FLOOR_TOP
	gym.free()
	return report(jumped and cleared,
			"Hole: left the edge at x %.0f, pressed %d frames later, jumped %s, landed past x %.0f %s"
			% [left_at, LATE_FRAMES, jumped, far_edge, cleared])


## At the lone wall, with the best input (run held into it, Jump pressed on each touch and held on
## the way up), the feet never get above its top.
func _the_lone_wall_cannot_be_climbed() -> bool:
	var gym: Level = _make_gym()
	var station: Node2D = gym.get_node(^"Stations/WallStation") as Node2D
	var wall: StaticBody2D = station.get_node(^"LoneWall") as StaticBody2D
	var player: Player = gym.player
	var top: float = _top_of(wall)
	await _place(player, Vector2(wall.global_position.x - LONE_WALL_RUN_UP,
			station.global_position.y + FLOOR_TOP - DROP_HEIGHT))
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.run_direction = 1.0
	stand_in.hold_jump = true
	stand_in.press_jump()
	var kicks: int = await _press_jump_on_each_touch(player, stand_in, CLIMB_FRAMES,
			func() -> bool: return false)
	var highest: float = _highest_feet
	gym.free()
	var below: bool = highest > top
	return report(kicks > 0 and below,
			"Lone wall: %d wall jumps, feet at best %.0f px below its top %s"
			% [kicks, highest - top, below])


## In the wall station's chimney and in the camera station's tower, from against the right wall,
## above the way in under the walls, pressing only Jump on each touch of a wall, with no direction,
## the man climbs out of the top.
func _the_chimneys_are_climbed_with_jump_alone() -> bool:
	var notes: Array[String] = []
	var all_out: bool = true
	for chimney: Array in [["WallStation", ^"ChimneyLeft", ^"ChimneyRight"],
			["CameraStation", ^"TowerLeft", ^"TowerRight"]]:
		var gym: Level = _make_gym()
		var station: Node2D = gym.get_node(NodePath("Stations/" + chimney[0])) as Node2D
		var left: StaticBody2D = station.get_node(chimney[1]) as StaticBody2D
		var right: StaticBody2D = station.get_node(chimney[2]) as StaticBody2D
		var player: Player = gym.player
		var top: float = _top_of(left)
		var right_face: float = right.global_position.x - WALL_HALF_WIDTH
		player.global_position = Vector2(right_face - body_size(player).x / 2.0,
				_bottom_of(right) - CHIMNEY_START_ABOVE_BOTTOM)
		player.reset_physics_interpolation()
		var stand_in: StandInInput = put_a_stand_in(player)
		stand_in.hold_jump = true
		var kicks: int = await _press_jump_on_each_touch(player, stand_in, CLIMB_FRAMES,
				func() -> bool: return player.global_position.y < top)
		var out: bool = player.global_position.y < top
		all_out = all_out and out
		notes.append("%s %d wall jumps, out %s" % [chimney[0], kicks, out])
		gym.free()
	return report(all_out, "Chimneys with Jump alone: %s" % ", ".join(notes))


## Running off the tower's top, the man falls to the floor, and on the way down the camera looks
## down: its centre gets at least half of Look Down Distance below his feet.
func _the_fall_off_the_tower_looks_down() -> bool:
	var gym: Level = _make_gym()
	var station: Node2D = gym.get_node(^"Stations/CameraStation") as Node2D
	var top: StaticBody2D = station.get_node(^"TowerTop") as StaticBody2D
	var camera: GameCamera = gym.get_node(^"GameCamera") as GameCamera
	var player: Player = gym.player
	await _place(player, Vector2(top.global_position.x, _top_of(top) - DROP_HEIGHT))
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.run_direction = 1.0
	await wait_until(func() -> bool: return not player.is_on_floor())
	stand_in.run_direction = 0.0
	var below: float = -INF
	for _frame: int in MAX_FRAMES:
		await physics_frame
		below = maxf(below, camera.global_position.y - player.global_position.y)
		if player.is_on_floor():
			break
	var landed: bool = player.is_on_floor()
	var wanted: float = camera.stats.look_down_distance / 2.0
	gym.free()
	return report(landed and below >= wanted,
			"Fall off the tower: landed %s, camera at most %.0f px below the feet (at least %.0f)"
			% [landed, below, wanted])


## Walking across the fixed room, once the camera has settled in it, the camera does not move.
func _the_fixed_zone_holds_the_camera_still() -> bool:
	var gym: Level = _make_gym()
	var station: Node2D = gym.get_node(^"Stations/CameraZoneStation") as Node2D
	var zone: CameraZone = station.get_node(^"FixedZone") as CameraZone
	var room: Rect2 = zone.get_limits()
	var camera: GameCamera = gym.get_node(^"GameCamera") as GameCamera
	var player: Player = gym.player
	await _place(player, Vector2(room.position.x + ROOM_INSET, station.global_position.y + FLOOR_TOP
			- DROP_HEIGHT))
	await wait_frames(SETTLE_FRAMES)
	var held_at: Vector2 = camera.global_position
	var stand_in: StandInInput = put_a_stand_in(player)
	stand_in.run_direction = 1.0
	var moved: float = 0.0
	await wait_until(func() -> bool:
		moved = maxf(moved, camera.global_position.distance_to(held_at))
		return player.global_position.x > room.end.x - ROOM_INSET)
	gym.free()
	return report(moved <= HELD_STILL, "Fixed room: the camera moved at most %.2f px (at most %.1f)"
			% [moved, HELD_STILL])


## Presses Jump on the first frame of each touch of a wall, for up to frames physics frames or until
## done, keeping the highest the feet got in _highest_feet. Hands back the presses on a wall.
func _press_jump_on_each_touch(player: Player, stand_in: StandInInput, frames: int,
		done: Callable) -> int:
	var kicks: int = 0
	var was_on_wall: bool = false
	_highest_feet = INF
	for _frame: int in frames:
		await physics_frame
		_highest_feet = minf(_highest_feet, player.global_position.y)
		var on_wall: bool = player.is_on_wall() and not player.is_on_floor()
		if on_wall and not was_on_wall:
			stand_in.press_jump()
			kicks += 1
		was_on_wall = on_wall
		if done.call():
			break
	return kicks


func _movement_station(gym: Level) -> Node2D:
	return gym.get_node(^"Stations/MovementStation") as Node2D


## The names of the station's bodies and marks that the rectangle overlaps.
func _what_covers(station: Node2D, rect: Rect2) -> Array[String]:
	var covered: Array[String] = []
	for child: Node in station.get_children():
		var area: Rect2 = Rect2()
		if child is StaticBody2D:
			var shape: RectangleShape2D = (child.get_node(^"CollisionShape2D") as CollisionShape2D) \
					.shape as RectangleShape2D
			area = Rect2((child as Node2D).global_position - shape.size / 2.0, shape.size)
		elif child is Line2D:
			var line: Line2D = child as Line2D
			area = Rect2(line.to_global(line.points[0]), Vector2.ZERO).expand(
					line.to_global(line.points[line.points.size() - 1]))
		else:
			continue
		if rect.intersects(area, true):
			covered.append(child.name)
	return covered


## The top of a rectangle body, in global coordinates.
func _top_of(body: StaticBody2D) -> float:
	var shape: RectangleShape2D = (body.get_node(^"CollisionShape2D") as CollisionShape2D).shape \
			as RectangleShape2D
	return body.global_position.y - shape.size.y / 2.0


## The bottom of a rectangle body, in global coordinates.
func _bottom_of(body: StaticBody2D) -> float:
	var shape: RectangleShape2D = (body.get_node(^"CollisionShape2D") as CollisionShape2D).shape \
			as RectangleShape2D
	return body.global_position.y + shape.size.y / 2.0


## Puts the man at, standing, and waits for him to be on the floor there.
func _place(player: Player, at: Vector2) -> void:
	player.global_position = at
	player.velocity = Vector2.ZERO
	player.reset_physics_interpolation()
	await wait_until_on_floor(player)


func _make_gym() -> Level:
	var gym: Level = GYM_SCENE.instantiate() as Level
	root.add_child(gym)
	return gym


func _stations_of(gym: Level) -> Array[Node]:
	return gym.get_node(^"Stations").get_children()


## The screen as the engine shows it: around the camera, clamped by the camera's own limits.
func _screen(camera: GameCamera) -> Rect2:
	var half: Vector2 = camera.get_viewport_rect().size / (2.0 * camera.zoom)
	var centre: Vector2 = Vector2(
			clampf(camera.global_position.x, camera.limit_left + half.x, camera.limit_right - half.x),
			clampf(camera.global_position.y, camera.limit_top + half.y, camera.limit_bottom - half.y))
	return Rect2(centre - half, half * 2.0)
