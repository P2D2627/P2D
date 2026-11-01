@tool
class_name GameCamera
extends Camera2D

## The game's camera, beside the player in a level. It heads for a focus that only moves when the
## player pushes against a window around it, leads ahead to the side the player committed to and
## down in long falls, and keeps to the camera zone the player is in. Values are in Stats; each zone
## sets its own limits and zoom. A lookout goes before the zone: it pulls back to show its View until
## the player lands. Runs in the physics step, after the player.
## It is a tool script only so zones and lookouts can preview, in the editor, what the screen will show.

## How close to its target the camera must be for a change of zone to be over, in px.
const ZONE_CHANGE_DONE: float = 0.5
## Below this speed the player counts as standing still, in px/s.
const IDLE_SPEED: float = 1.0
## On the floor, how far out of a lookout's rectangles the body must be for it to let go, in px: a
## tile, so the last steps off a ledge, still on the floor, keep it.
const LOOKOUT_LET_GO: float = 48.0
## A player that went further than this across in one step was placed there, as a test or a respawn
## does, not moved there, in px: the camera eases to it instead of keeping it on the screen. No run,
## wall jump or platform comes near it.
const PLACED_DISTANCE: float = 200.0

## The player the camera follows. Without one, the camera stays where it is.
@export var player: Player
## How the camera follows the player.
@export var stats: CameraStats
## The level's rock, for zones with Auto Zoom. Empty: the first colliding tile layer of the level.
@export var level_tiles: TileMapLayer

## The point the camera heads for.
var _focus: Vector2 = Vector2.ZERO
## How far the camera leads ahead of the focus (x) and down into a fall (y), and how fast it moves.
var _lead: Vector2 = Vector2.ZERO
var _lead_speed: Vector2 = Vector2.ZERO
## 1 leading right, -1 left, 0 before the player first commits.
var _lead_side: float = 0.0
## The x the player must go Turn Threshold past, against the lead, to turn it.
var _turn_reference_x: float = 0.0
## The last floor the player stood on, for the look down. INF until there is one.
var _ground_y: float = INF
var _zones: Array[CameraZone] = []
var _zone: CameraZone = null
var _lookouts: Array[CameraLookout] = []
## The lookout the camera shows, or null.
var _lookout: CameraLookout = null
## The zones the player is in, with the step it came into each.
var _entered: Dictionary[CameraZone, int] = {}
var _steps: int = 0
## True while the camera slides into a new zone's range.
var _changing_zone: bool = false
var _follow_speed: Vector2 = Vector2.ZERO
## The camera's own zoom, from its scene: outside every zone and before the player stands still.
var _base_zoom: float = 1.0
var _zoom_speed: float = 0.0
var _idle_time: float = 0.0
## For each Auto Zoom zone, the bottom of the lowest other passage above it, or -INF.
var _passages: Dictionary[CameraZone, float] = {}
## The player's body relative to its position, which must stay on the screen.
var _body: Rect2 = Rect2()
## Whether the player was between the screen's sides at the end of the last step: its centre, not
## the whole body, since a zone's side may cut off up to half of it before it crosses into the next
## zone.
var _player_on_screen_across: bool = true
## Where the player was across at the last step, to tell a move from a placing.
var _last_player_x: float = 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		set_physics_process(false)
		return
	assert(stats != null, "GameCamera: assign a CameraStats resource to Stats.")
	if not is_instance_valid(player):
		set_physics_process(false)
		return
	_gather_zones()
	if not is_instance_valid(level_tiles):
		level_tiles = _find_level_tiles()
	_focus = player.global_position
	_last_player_x = _focus.x
	_turn_reference_x = _focus.x
	if player.get_state() == Player.State.ON_FLOOR:
		_ground_y = _focus.y
	player.landed.connect(_on_player_landed)
	_body = _find_body()
	_base_zoom = zoom.x
	_zone = _zone_of(_focus)
	_lookout = _next_lookout(_focus)
	zoom = Vector2.ONE * _zoom_target()
	var centres: Rect2 = _centre_range()
	global_position = _focus.clamp(centres.position, centres.end)
	# Without the reset, physics interpolation would draw the jump to the start.
	reset_physics_interpolation()


## The camera is the smoothed focus plus the lead, both kept inside the range the screen's centre may
## take in the zone.
func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		set_physics_process(false)
		return
	var followed: Vector2 = global_position - _lead
	var placed: bool = absf(player.global_position.x - _last_player_x) > PLACED_DISTANCE
	_last_player_x = player.global_position.x
	_focus = _focus_in_window(player.global_position)
	_update_lead_side(player.global_position.x)
	var zone: CameraZone = _zone_of(player.global_position)
	var lookout: CameraLookout = _next_lookout(player.global_position)
	if zone != _zone or lookout != _lookout:
		_changing_zone = true
	_zone = zone
	_lookout = lookout
	_update_idle(delta)
	_update_zoom(delta)
	var centres: Rect2 = _centre_range()
	var focus_target: Vector2 = _focus.clamp(centres.position, centres.end)
	var screen_target: Vector2 = (_focus + _lead_target()).clamp(centres.position, centres.end)
	_swing_lead(screen_target - focus_target, delta)
	followed += _follow_step(focus_target - followed, delta)
	_keep_in_range(followed, centres)
	if _changing_zone:
		_hold_lead_to_zone_change_speed(followed, delta)
	var at: Vector2 = _push_off_the_edges(followed + _lead, centres)
	global_position = at + _push_to_keep_body_on_screen(at,
			_changing_zone and _player_on_screen_across and not placed and not _is_live(_lookout))
	_player_on_screen_across = (absf(player.global_position.x - global_position.x)
			<= get_viewport_rect().size.x / (2.0 * zoom.x))


## How far the camera leads ahead of the focus, in px. For the tests and the debug overlay.
func get_look_ahead() -> float:
	return _lead.x


## How far below the focus the camera looks, in px. For the tests and the debug overlay.
func get_look_down() -> float:
	return _lead.y


## The zone the player is in, or "none". For the debug overlay.
func get_zone_name() -> String:
	return String(_zone.name) if _is_live(_zone) else "none"


## For the zones' editor preview: what the screen can show in zone with the player moving (no Idle
## Zoom), the zoom and the screen's size in the level. In the editor it reads the zone's shapes and the tiles afresh.
func get_zone_view(zone: CameraZone) -> Dictionary:
	if Engine.is_editor_hint():
		_base_zoom = zoom.x
		_passages.erase(zone)
		if not is_instance_valid(level_tiles):
			level_tiles = _find_level_tiles()
	var level: float = _base_zoom * _zone_zoom(zone)
	return _preview(_centre_range_in(zone, level), level)


## For the lookouts' editor preview, as get_zone_view().
func get_lookout_view(lookout: CameraLookout) -> Dictionary:
	if Engine.is_editor_hint():
		_base_zoom = zoom.x
	var level: float = _base_zoom * _lookout_zoom(lookout)
	return _preview(_range_in_box(_lookout_box(lookout), 0.5, 0.5, level), level)


func _preview(centres: Rect2, level: float) -> Dictionary:
	var half_screen: Vector2 = _screen_size() / (2.0 * level)
	return {"view": Rect2(centres.position - half_screen, centres.size + 2.0 * half_screen),
			"zoom": level, "screen": 2.0 * half_screen}


## While sliding into a new zone, holds the whole step of the screen to Zone Change Speed by keeping
## back the lead.
func _hold_lead_to_zone_change_speed(followed: Vector2, delta: float) -> void:
	var step: Vector2 = followed + _lead - global_position
	var most: float = _change_speed() * delta
	if step.length() > most:
		_lead = global_position + step.limit_length(most) - followed
		_lead_speed = Vector2.ZERO


## Moves the camera just enough to keep the player's body Edge Margin in from the screen's edges,
## within the zone's range. Only up and down while sliding into a new zone.
func _push_off_the_edges(at: Vector2, centres: Rect2) -> Vector2:
	if _body.size == Vector2.ZERO or is_zero_approx(stats.edge_margin):
		return at
	var half_screen: Vector2 = get_viewport_rect().size / (2.0 * zoom)
	var margin: Vector2 = 2.0 * half_screen * stats.edge_margin
	var body: Rect2 = Rect2(player.global_position + _body.position, _body.size)
	var low_edge: Vector2 = at - half_screen + margin
	var high_edge: Vector2 = at + half_screen - margin
	var push: Vector2 = Vector2.ZERO
	for axis: int in [1] if _changing_zone else [0, 1]:
		if body.position[axis] < low_edge[axis]:
			push[axis] = body.position[axis] - low_edge[axis]
		elif body.end[axis] > high_edge[axis]:
			push[axis] = body.end[axis] - high_edge[axis]
	var lowest: Vector2 = centres.position.min(at)
	var highest: Vector2 = centres.end.max(at)
	return (at + push).clamp(lowest, highest)


## How far the camera must move for the whole body to be on the screen. Goes before the zone's
## limits. Up and down always, so the player's head is never cut off; across only when asked: while
## the camera slides into a new zone, for a player that was on the screen and moved, not placed, and
## never into a lookout, whose View may lie aside from the player. A player running into a shaft that
## comes closer stays on the screen, one placed far off is still eased into, and in a zone the screen
## keeps to the zone's sides.
func _push_to_keep_body_on_screen(at: Vector2, across: bool) -> Vector2:
	if _body.size == Vector2.ZERO:
		return Vector2.ZERO
	var half_screen: Vector2 = get_viewport_rect().size / (2.0 * zoom)
	var body: Rect2 = Rect2(player.global_position + _body.position, _body.size)
	var push: Vector2 = ((body.position - (at - half_screen)).min(Vector2.ZERO)
			+ (body.end - (at + half_screen)).max(Vector2.ZERO))
	if not across:
		push.x = 0.0
	return push


## The player's first rectangle collision shape, relative to its position.
func _find_body() -> Rect2:
	for child: Node in player.get_children():
		var collision: CollisionShape2D = child as CollisionShape2D
		if collision != null and collision.shape is RectangleShape2D:
			var size: Vector2 = (collision.shape as RectangleShape2D).size
			return Rect2(collision.position - size / 2.0, size)
	return Rect2()


func _focus_in_window(player_position: Vector2) -> Vector2:
	return Vector2(
			clampf(_focus.x, player_position.x - stats.window_half_width,
					player_position.x + stats.window_half_width),
			clampf(_focus.y, player_position.y - stats.window_down,
					player_position.y + stats.window_up))


## On landing the focus goes to the new floor, unless it is the same floor within the safe margin.
func _on_player_landed() -> void:
	_ground_y = player.global_position.y
	if absf(_ground_y - _focus.y) > player.safe_margin:
		_focus.y = _ground_y


func _is_falling_far() -> bool:
	return player.velocity.y > 0.0 and player.global_position.y > _ground_y + stats.look_down_threshold


## Turns the lead once the player goes Turn Threshold against it, past the farthest point reached.
func _update_lead_side(player_x: float) -> void:
	if _lead_side > 0.0:
		_turn_reference_x = maxf(_turn_reference_x, player_x)
	elif _lead_side < 0.0:
		_turn_reference_x = minf(_turn_reference_x, player_x)
	var moved: float = player_x - _turn_reference_x
	if absf(moved) > stats.turn_threshold and signf(moved) != _lead_side:
		_lead_side = signf(moved)
		_turn_reference_x = player_x


## The lead with nothing in the way, divided by the zoom so it stays the same share of the screen.
## None ahead once the player stands still.
func _lead_target() -> Vector2:
	var ahead: float = 0.0 if _is_idle() else _lead_side * stats.look_ahead_distance
	return Vector2(ahead, stats.look_down_distance if _is_falling_far() else 0.0) / zoom.x


func _is_idle() -> bool:
	return _idle_time >= stats.idle_delay


## Still means on a floor, not asking to run and not moving.
func _update_idle(delta: float) -> void:
	var still: bool = (player.get_state() == Player.State.ON_FLOOR
			and player.velocity.length() < IDLE_SPEED
			and (not is_instance_valid(player.input) or player.input.get_run_direction() == 0.0))
	_idle_time = _idle_time + delta if still else 0.0


## The camera's own zoom, times the zone's, times Idle Zoom once the player stands still. In a
## lookout, the camera's own zoom times the lookout's, with no Idle Zoom, so standing at the edge to
## look does not close in.
func _zoom_target() -> float:
	if _is_live(_lookout):
		return _base_zoom * _lookout_zoom(_lookout)
	var level: float = _base_zoom
	if _is_live(_zone):
		level *= _zone_zoom(_zone)
	if _is_idle():
		level *= stats.idle_zoom
	return level


## The zone's Zoom, raised by Fit Height and Auto Zoom, those two up to Max Zone Zoom.
func _zone_zoom(zone: CameraZone) -> float:
	var level: float = zone.zoom
	var screen_height: float = _screen_size().y / _base_zoom
	if zone.fit_height:
		var height: float = zone.get_limits().size.y + zone.bottom_margin + stats.fit_headroom
		level = maxf(level, clampf(screen_height / height, 1.0, stats.max_zone_zoom))
	if zone.auto_zoom and is_instance_valid(level_tiles):
		level = maxf(level, clampf(screen_height / _tallest_without_passages(zone), 1.0,
				stats.max_zone_zoom))
	return level


## The zoom at which the screen fills the lookout's View without passing it on either side, so
## nothing outside the View shows; no further back than Min Lookout Zoom, no closer than Max Zone
## Zoom. Past Min Lookout Zoom the camera follows the player inside the View.
func _lookout_zoom(lookout: CameraLookout) -> float:
	var view: Vector2 = lookout.get_view().size
	var screen: Vector2 = _screen_size() / _base_zoom
	return clampf(maxf(screen.x / view.x, screen.y / view.y), stats.min_lookout_zoom,
			stats.max_zone_zoom)


## How tall the screen may be in zone before it shows another passage above it. With the screen
## taller than the zone, Vertical Anchor a puts a × the extra above the zone's top.
func _tallest_without_passages(zone: CameraZone) -> float:
	if not _passages.has(zone):
		_passages[zone] = _passage_above(zone)
	var passage: float = _passages[zone]
	if passage == -INF or is_zero_approx(zone.vertical_anchor):
		return INF
	var box: Rect2 = zone.get_limits()
	return box.size.y + zone.bottom_margin + (box.position.y - passage) / zone.vertical_anchor


## The bottom of the lowest other passage above zone, or -INF. Going up each column from the zone's
## air, air after some rock is another passage; air right after the zone's air is an opening out of
## it, which the player should see.
func _passage_above(zone: CameraZone) -> float:
	var box: Rect2 = zone.get_limits()
	var first: Vector2i = level_tiles.local_to_map(level_tiles.to_local(box.position))
	var last: Vector2i = level_tiles.local_to_map(level_tiles.to_local(box.end - Vector2.ONE))
	var top_row: int = level_tiles.get_used_rect().position.y
	var tile_height: float = level_tiles.tile_set.tile_size.y
	var lowest: float = -INF
	for x: int in range(first.x, last.x + 1):
		var in_zone: bool = false
		var rock_seen: bool = false
		for y: int in range(last.y, top_row - 1, -1):
			var cell: Vector2i = Vector2i(x, y)
			var rock: bool = level_tiles.get_cell_source_id(cell) != -1
			var centre: Vector2 = level_tiles.map_to_local(cell)
			if not rock and zone.has_point(level_tiles.to_global(centre)):
				in_zone = true
				rock_seen = false
			elif not in_zone:
				continue
			elif rock:
				rock_seen = true
			else:
				if rock_seen:
					lowest = maxf(lowest, level_tiles.to_global(centre + Vector2(0.0, tile_height / 2.0)).y)
				break
	return lowest


## Eases the zoom to its target as a critically damped spring, faster into a lookout.
func _update_zoom(delta: float) -> void:
	var target: float = _zoom_target()
	var sharpness: float = stats.lookout_zoom_sharpness if _is_live(_lookout) else stats.zoom_sharpness
	var to_go: float = zoom.x - target
	var drift: float = (_zoom_speed + sharpness * to_go) * delta
	var decay: float = exp(-sharpness * delta)
	var level: float = target + (to_go + drift) * decay
	_zoom_speed = (_zoom_speed - sharpness * drift) * decay
	zoom = Vector2(level, level)


## Moves the lead towards target as a critically damped spring, solved exactly over the step:
## x' = (x + (v + k x) t) e^(-k t), v' = (v - k (v + k x) t) e^(-k t).
func _swing_lead(target: Vector2, delta: float) -> void:
	var sharpness: Vector2 = Vector2(stats.look_ahead_sharpness, stats.look_down_sharpness)
	var to_go: Vector2 = _lead - target
	var drift: Vector2 = (_lead_speed + sharpness * to_go) * delta
	var decay: Vector2 = Vector2(exp(-sharpness.x * delta), exp(-sharpness.y * delta))
	_lead = target + (to_go + drift) * decay
	_lead_speed = (_lead_speed - sharpness * drift) * decay


## One step of the smoothing towards the focus. While changing zone, a spring with Zone Change
## Sharpness from the current speed, held to Zone Change Speed; into a lookout, with the faster
## lookout values.
func _follow_step(to_go: Vector2, delta: float) -> Vector2:
	var step: Vector2
	if _changing_zone:
		var sharpness: float = (stats.lookout_change_sharpness if _is_live(_lookout)
				else stats.zone_change_sharpness)
		var drift: Vector2 = (_follow_speed - sharpness * to_go) * delta
		var decay: float = exp(-sharpness * delta)
		step = to_go + (drift - to_go) * decay
		var speed: Vector2 = (_follow_speed - sharpness * drift) * decay
		var most: float = _change_speed() * delta
		if step.length() > most:
			step = step.limit_length(most)
			speed = step / delta
		_follow_speed = speed
		if (to_go - step).length() <= ZONE_CHANGE_DONE:
			_changing_zone = false
		return step
	step = to_go * (1.0 - exp(-stats.follow_sharpness * delta))
	_follow_speed = step / delta
	return step


## The fastest a change may move the camera, in px/s: faster into a lookout.
func _change_speed() -> float:
	return stats.lookout_change_speed if _is_live(_lookout) else stats.zone_change_speed


## Keeps the focus plus the lead inside the centre range, cutting the lead where they would pass it.
## The range widens to where the camera is while it slides into a new zone.
func _keep_in_range(followed: Vector2, centres: Rect2) -> void:
	var low: Vector2 = centres.position.min(followed)
	var high: Vector2 = centres.end.max(followed)
	if _changing_zone:
		low = low.min(global_position)
		high = high.max(global_position)
	var at: Vector2 = followed + _lead
	if at.x < low.x or at.x > high.x:
		_lead.x = clampf(at.x, low.x, high.x) - followed.x
		_lead_speed.x = 0.0
	if at.y < low.y or at.y > high.y:
		_lead.y = clampf(at.y, low.y, high.y) - followed.y
		_lead_speed.y = 0.0


## The zones and lookouts inside the camera's level, leaving out those of a level being freed.
func _gather_zones() -> void:
	var level: Node = owner if owner != null else get_parent()
	var elsewhere: int = 0
	for node: Node in get_tree().get_nodes_in_group(CameraZone.GROUP):
		if _is_leaving(node):
			continue
		if level.is_ancestor_of(node):
			_zones.append(node as CameraZone)
		else:
			elsewhere += 1
	for node: Node in get_tree().get_nodes_in_group(CameraLookout.GROUP):
		var lookout: CameraLookout = node as CameraLookout
		if _is_leaving(node) or not level.is_ancestor_of(node):
			continue
		if lookout.get_view().has_area():
			_lookouts.append(lookout)
		else:
			push_warning("GameCamera: lookout %s has no View (ReferenceRect child), so it is left out."
					% lookout.name)
	if _zones.is_empty() and elsewhere > 0:
		push_warning(("GameCamera: none of the %d camera zones is in this camera's level, so the "
				+ "camera keeps to its own limits.") % elsewhere)


## The first tile layer of the level whose tiles collide, or null.
func _find_level_tiles() -> TileMapLayer:
	var level: Node = owner if owner != null else get_parent()
	if level == null:
		return null
	for node: Node in level.find_children("*", "TileMapLayer", true, false):
		var tiles: TileMapLayer = node as TileMapLayer
		if (tiles.collision_enabled and tiles.tile_set != null
				and tiles.tile_set.get_physics_layers_count() > 0):
			return tiles
	return null


func _is_leaving(node: Node) -> bool:
	var at: Node = node
	while at != null:
		if at.is_queued_for_deletion():
			return true
		at = at.get_parent()
	return false


## The zone point is in. Where zones overlap, the one entered last wins; entered together, the
## smallest. Call once per step.
func _zone_of(point: Vector2) -> CameraZone:
	_steps += 1
	var still_in: Dictionary[CameraZone, int] = {}
	var best: CameraZone = null
	for zone: CameraZone in _zones:
		if not _is_live(zone) or not zone.has_point(point):
			continue
		still_in[zone] = _entered.get(zone, _steps)
		if (best == null or still_in[zone] > still_in[best]
				or (still_in[zone] == still_in[best] and zone.get_area() < best.get_area())):
			best = zone
	_entered = still_in
	return best


## The lookout for point: the smallest whose rectangles have it; else the one already shown, while
## the player is in its View and either off the floor (a jump, a fall, hanging on a wall), riding a
## moving platform, or within LOOKOUT_LET_GO of the rectangles; else null.
func _next_lookout(point: Vector2) -> CameraLookout:
	var best: CameraLookout = null
	for lookout: CameraLookout in _lookouts:
		if (_is_live(lookout) and lookout.has_point(point)
				and (best == null or lookout.get_area() < best.get_area())):
			best = lookout
	if best != null:
		return best
	if not _is_live(_lookout) or not _lookout.get_view().has_point(point):
		return null
	var body: Rect2 = Rect2(point + _body.position, _body.size).grow(LOOKOUT_LET_GO)
	if (player.get_state() != Player.State.ON_FLOOR or not player.get_platform_velocity().is_zero_approx()
			or _lookout.touches(body)):
		return _lookout
	return null


## Variant argument: GDScript rejects a freed object for a typed one before the check runs.
func _is_live(zone: Variant) -> bool:
	return is_instance_valid(zone) and not (zone as Object).is_queued_for_deletion()


func _centre_range() -> Rect2:
	if _is_live(_lookout):
		return _range_in_box(_lookout_box(_lookout), 0.5, 0.5, zoom.x)
	return _centre_range_in(_zone if _is_live(_zone) else null, zoom.x)


## Where the screen's centre may go at zoom level in zone (null: no zone): the zone's box, lowered by
## Bottom Margin and only across with Limit Horizontally, inside the camera's own limits.
func _centre_range_in(zone: CameraZone, level: float) -> Rect2:
	var box: Rect2 = _own_limits()
	var across: float = 0.5
	var down: float = 0.5
	if zone != null:
		var zone_box: Rect2 = zone.get_limits().grow_side(SIDE_BOTTOM, zone.bottom_margin)
		if zone.limit_horizontally:
			across = zone.horizontal_anchor
		else:
			zone_box = Rect2(box.position.x, zone_box.position.y, box.size.x, zone_box.size.y)
		box = zone_box.intersection(box) if zone_box.intersects(box) else zone_box
		down = zone.vertical_anchor
	return _range_in_box(box, across, down, level)


## The lookout's View inside the camera's own limits.
func _lookout_box(lookout: CameraLookout) -> Rect2:
	var view: Rect2 = lookout.get_view()
	var own: Rect2 = _own_limits()
	return view.intersection(own) if view.intersects(own) else view


## Where the screen's centre may go at zoom level for the screen to stay inside box. On a box
## smaller than the screen, the anchors place it: 0 its left (top) edge on the box's, 1 its right
## (bottom) edge on the box's.
func _range_in_box(box: Rect2, across: float, down: float, level: float) -> Rect2:
	var half_screen: Vector2 = _screen_size() / (2.0 * level)
	var low: Vector2 = box.position + half_screen
	var high: Vector2 = box.end - half_screen
	if low.x > high.x:
		low.x = lerpf(low.x, high.x, across)
		high.x = low.x
	if low.y > high.y:
		low.y = lerpf(low.y, high.y, down)
		high.y = low.y
	return Rect2(low, high - low)


func _own_limits() -> Rect2:
	return Rect2(Vector2(limit_left, limit_top),
			Vector2(limit_right - limit_left, limit_bottom - limit_top))


## The game's screen size; in the editor the viewport is the editor's, so it comes from the project.
func _screen_size() -> Vector2:
	if Engine.is_editor_hint():
		return Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"),
				ProjectSettings.get_setting("display/window/size/viewport_height"))
	return get_viewport_rect().size
