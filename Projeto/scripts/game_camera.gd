class_name GameCamera
extends Camera2D

## The game's camera. It sits beside the player in a level, and not inside the player's scene, and
## reads the player without the player knowing it exists. It heads for a focus point, which only
## moves when the player pushes against a window around it, and on every physics step it closes in
## on the focus by a share of the distance that does not depend on the length of the step. When the
## player lands, the focus goes to the new floor. On top of that the camera leads ahead of the
## focus, to the side the player last committed to: the lead only turns once the player goes Turn
## Threshold the other way, and it swings over like a critically damped spring. In a long fall, once
## the player is Look Down Threshold below the last floor, it also leads down, with a spring of its
## own. The values are in Stats. The Camera2D's own Position Smoothing stays off: with
## physics interpolation on, it runs more than once per step. Its scene runs the camera in the
## physics step and after the player (Process Callback set to Physics, Physics Priority above the
## player's), so it reads where the player is on this step and not where it was on the last one.
## The screen shows no further than the camera zone the player is in, or than the camera's own
## limits where there is no zone. The camera only heads for points the screen can show, focus and
## lead included, and keeps their sum there too, so it never goes past an edge and turns back from
## one at once. A change of zone moves it no faster than Zone Change Speed.

## The player the camera follows. Without one, the camera stays where it is.
@export var player: Player
## How the camera follows the player: the window, the smoothing, the look ahead and down, and the
## speed of a change of zone.
@export var stats: CameraStats

## The point the camera heads for. It stays put while the player is inside the window around it.
var _focus: Vector2 = Vector2.ZERO
## How far the camera leads ahead of the focus, in px: x to the side the player last committed to,
## positive to the right; y down into a long fall.
var _lead: Vector2 = Vector2.ZERO
## How fast the lead is moving, in px/s. The swings are springs, so they keep a speed between steps.
var _lead_speed: Vector2 = Vector2.ZERO
## The side the camera leads to: 1 to the right, -1 to the left, 0 until the player first commits.
var _lead_side: float = 0.0
## The x the player must go Turn Threshold past, against the lead, to turn it: the farthest the
## player got to the side the camera leads to, or where the player started.
var _turn_reference_x: float = 0.0
## The y of the last floor the player stood on, for the look down. INF until the camera knows one,
## so a player that appears in the air does not make the camera look down.
var _ground_y: float = INF
## The camera zones of the camera's own level, found once, and the one the player is in; null
## outside every zone.
var _zones: Array[CameraZone] = []
var _zone: CameraZone = null
## True from a change of zone until the camera has moved into the new zone's range, while its steps
## are held to Zone Change Speed.
var _changing_zone: bool = false


func _ready() -> void:
	assert(stats != null, "GameCamera: assign a CameraStats resource to Stats.")
	if not is_instance_valid(player):
		set_physics_process(false)
		return
	_gather_zones()
	_focus = player.global_position
	_turn_reference_x = _focus.x
	if player.get_state() == Player.State.ON_FLOOR:
		_ground_y = _focus.y
	player.landed.connect(_on_player_landed)
	_zone = _zone_of(_focus)
	var centres: Rect2 = _centre_range()
	global_position = _focus.clamp(centres.position, centres.end)
	# The camera jumps from where the level put it to where it should be. Without the reset, the
	# physics interpolation would draw it crossing the room on the first frames.
	reset_physics_interpolation()


## The camera is the smoothed focus plus the lead. The smoothing follows the focus only, so the
## swing of the lead keeps the shape of the spring. Both head for points inside the range the
## screen's centre may take in the zone, and their sum is kept there too.
func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		set_physics_process(false)
		return
	var followed: Vector2 = global_position - _lead
	_focus = _focus_in_window(player.global_position)
	_update_lead_side(player.global_position.x)
	var zone: CameraZone = _zone_of(player.global_position)
	if zone != _zone:
		_changing_zone = true
	_zone = zone
	var centres: Rect2 = _centre_range()
	var focus_target: Vector2 = _focus.clamp(centres.position, centres.end)
	var lead_target: Vector2 = (focus_target + _lead_target()).clamp(centres.position, centres.end)
	_swing_lead(lead_target - focus_target, delta)
	followed += _follow_step(focus_target - followed, delta)
	_keep_in_range(followed, centres)
	global_position = followed + _lead


## How far the camera leads ahead of the focus right now, in px: positive to the right. Read by the
## tests and the debug overlay.
func get_look_ahead() -> float:
	return _lead.x


## How far below the focus the camera looks right now, in px. Read by the tests and the debug
## overlay.
func get_look_down() -> float:
	return _lead.y


## The name of the camera zone the player is in, or "none" outside every zone. Read by the debug
## overlay.
func get_zone_name() -> String:
	return String(_zone.name) if _is_live(_zone) else "none"


## The focus moved just enough for the player to be inside the window around it: up to Window Half
## Width to each side, Window Up above and Window Down below.
func _focus_in_window(player_position: Vector2) -> Vector2:
	return Vector2(
			clampf(_focus.x, player_position.x - stats.window_half_width,
					player_position.x + stats.window_half_width),
			clampf(_focus.y, player_position.y - stats.window_down,
					player_position.y + stats.window_up))


## The player is on a floor again: the focus goes to it, and it is the floor the look down counts
## from. Inside the window the focus would not move up, so without this a higher floor would leave
## the player near the top of the screen. Two landings on the same floor can rest a fraction of a px
## apart, within the physics' safe margin; that is not a new floor, so the focus stays.
func _on_player_landed() -> void:
	_ground_y = player.global_position.y
	if absf(_ground_y - _focus.y) > player.safe_margin:
		_focus.y = _ground_y


## True while the player falls and is more than Look Down Threshold below the last floor it stood on.
func _is_falling_far() -> bool:
	return player.velocity.y > 0.0 and player.global_position.y > _ground_y + stats.look_down_threshold


## Turns the lead once the player goes Turn Threshold against it, past the farthest point reached
## to the side it leads to. Before the first turn there is no lead, and the start counts as that
## point.
func _update_lead_side(player_x: float) -> void:
	if _lead_side > 0.0:
		_turn_reference_x = maxf(_turn_reference_x, player_x)
	elif _lead_side < 0.0:
		_turn_reference_x = minf(_turn_reference_x, player_x)
	var moved: float = player_x - _turn_reference_x
	if absf(moved) > stats.turn_threshold and signf(moved) != _lead_side:
		_lead_side = signf(moved)
		_turn_reference_x = player_x


## Where the lead would go with nothing in the way: Look Ahead Distance to its side, and Look Down
## Distance down in a long fall.
func _lead_target() -> Vector2:
	return Vector2(_lead_side * stats.look_ahead_distance,
			stats.look_down_distance if _is_falling_far() else 0.0)


## Moves the lead one step towards target, each axis as a critically damped spring with its own
## sharpness. It uses the exact solution of the spring over the step, so the swing does not depend
## on the length of the step: with x the distance still to go and v the speed, after t seconds x is
## (x + (v + k x) t) e^(-k t) and v is (v - k (v + k x) t) e^(-k t), for k the sharpness.
func _swing_lead(target: Vector2, delta: float) -> void:
	var sharpness: Vector2 = Vector2(stats.look_ahead_sharpness, stats.look_down_sharpness)
	var to_go: Vector2 = _lead - target
	var drift: Vector2 = (_lead_speed + sharpness * to_go) * delta
	var decay: Vector2 = Vector2(exp(-sharpness.x * delta), exp(-sharpness.y * delta))
	_lead = target + (to_go + drift) * decay
	_lead_speed = (_lead_speed - sharpness * drift) * decay


## One step of the smoothing, to_go being the distance to the focus target: the share
## 1 - exp(-sharpness × delta) of the way. While the camera moves into a new zone's range, a step
## goes no further than Zone Change Speed allows; the change is over once the smoothing alone moves
## slower than that.
func _follow_step(to_go: Vector2, delta: float) -> Vector2:
	var step: Vector2 = to_go * (1.0 - exp(-stats.follow_sharpness * delta))
	if _changing_zone:
		var most: float = stats.zone_change_speed * delta
		if step.length() > most:
			return step.limit_length(most)
		_changing_zone = false
	return step


## Keeps followed plus the lead inside the centre range. Each of the two lags behind where it heads,
## so near an edge their sum could pass it. The range widens to followed, so a slide into a new zone
## is not cut short. Where the sum would pass, the lead becomes what fits and its speed on that axis
## 0, so it springs on from rest: the camera stops at the edge, as the engine's limits make it stop.
func _keep_in_range(followed: Vector2, centres: Rect2) -> void:
	var low: Vector2 = centres.position.min(followed)
	var high: Vector2 = centres.end.max(followed)
	var at: Vector2 = followed + _lead
	if at.x < low.x or at.x > high.x:
		_lead.x = clampf(at.x, low.x, high.x) - followed.x
		_lead_speed.x = 0.0
	if at.y < low.y or at.y > high.y:
		_lead.y = clampf(at.y, low.y, high.y) - followed.y
		_lead_speed.y = 0.0


## Finds the camera zones of the camera's level: those inside its scene, under its owner, or under
## its parent for a camera with no owner, so the zones of a sub-scene of the level count. Zones under
## a node being freed are left out: an old level stays in the tree until the end of the frame, and
## only its root is queued, not the zones in it. If there are zones but none in this level, it warns.
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
	if _zones.is_empty() and elsewhere > 0:
		push_warning(("GameCamera: none of the %d camera zones is in this camera's level, so the "
				+ "camera keeps to its own limits.") % elsewhere)


## True if node, or a node above it, is queued for freeing.
func _is_leaving(node: Node) -> bool:
	var at: Node = node
	while at != null:
		if at.is_queued_for_deletion():
			return true
		at = at.get_parent()
	return false


## The zone point is in: the current one while it still has the point, or else the first that has
## it. null if no zone has it.
func _zone_of(point: Vector2) -> CameraZone:
	if _is_live(_zone) and _zone.has_point(point):
		return _zone
	for zone: CameraZone in _zones:
		if _is_live(zone) and zone.has_point(point):
			return zone
	return null


## False for a zone that is gone, or that was itself queued for freeing: a zone freed with
## queue_free() stays in the tree until the end of the frame. The zones of a whole level being freed
## are left out earlier, in _gather_zones(). The argument is a Variant because GDScript refuses a
## freed object for a CameraZone argument before the check runs.
func _is_live(zone: Variant) -> bool:
	return is_instance_valid(zone) and not (zone as Object).is_queued_for_deletion()


## Where the centre of the screen may go: the zone's box, or the camera's own limits outside every
## zone, less half the screen on each side. On an axis where the box is narrower than the screen, the
## only place is the box's centre, as the engine does with limits.
func _centre_range() -> Rect2:
	var box: Rect2 = _zone.get_limits() if _is_live(_zone) else _own_limits()
	var half_screen: Vector2 = get_viewport_rect().size / (2.0 * zoom)
	var low: Vector2 = box.position + half_screen
	var high: Vector2 = box.end - half_screen
	if low.x > high.x:
		low.x = box.get_center().x
		high.x = low.x
	if low.y > high.y:
		low.y = box.get_center().y
		high.y = low.y
	return Rect2(low, high - low)


## The box the camera's own limits give, which the engine also keeps the screen in.
func _own_limits() -> Rect2:
	return Rect2(Vector2(limit_left, limit_top),
			Vector2(limit_right - limit_left, limit_bottom - limit_top))
