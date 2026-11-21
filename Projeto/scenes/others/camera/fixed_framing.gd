class_name FixedFraming
extends CameraBrain
## Frames the man with one zoom: centred across, and Below Centre under the screen's middle, as the floor under him
## is rock. The screen frames a focus that moves only when he leaves a dead zone around it, which in the air takes
## in a whole jump and on the floor closes on him. A critically damped spring, never faster than Max Speed, takes
## the screen there; while he drags the focus it aims ahead by the spring's own lag, so at an even speed it neither
## trails him nor overshoots. Running, it leads a little to his side; after Fall Delay of falling, it looks down.
## Once his body is on the screen it stays inside the Edge Margin, unless the limits stop the screen first. Put far
## away, as the debug tools do, he is framed at once; so is he when a new copy of the level starts with this way
## already chosen (cut_to_framing()).
## The limits come from the map, not from shapes drawn in the level: the box of the open cells he can reach from
## where he is when it first begins on a map (read through RockMap), Map Margin tiles further out and inside the
## camera's own limits, which the camera gives it, so a new or changed map needs nothing set by hand. With no map,
## or a map open to the outside, the camera's own limits alone hold the screen. In a chimney, a way up no wider than
## Chimney Width and at least Chimney Height high between rock, the screen holds its axis.

## A man that went further than this in one step was placed there, not moved, in px: as for the camera's own way.
const PLACED_DISTANCE: float = GameCamera.PLACED_DISTANCE

@export var stats: FixedFramingStats

var _player: Player
## The player's body relative to his position.
var _body: Rect2 = Rect2()
var _centre: Vector2 = Vector2.ZERO
var _speed: Vector2 = Vector2.ZERO
var _zoom: float = 1.0
## The point the screen frames him from: it moves only when he leaves the dead zone around it.
var _focus: Vector2 = Vector2.ZERO
## How far the screen leads, as a share of its width, and how far under its middle his middle sits, as a share of
## its height.
var _lead: float = 0.0
var _below: float = 0.0
var _fall_time: float = 0.0
## Where his middle was at the last step, to tell a move from a placing.
var _last_man: Vector2 = Vector2.ZERO
## Whether his body has been inside the Edge Margin since the brain began: until then the screen glides to him.
var _holding_body: bool = false
## Whether the screen jumped on the last step.
var _cut: bool = false
## How far above where the screen frames him he may go in the air before it follows, in px: a whole jump and
## Jump Room.
var _jump_up: float = 0.0
## The map read from the tiles last begun with, the camera's limits last begun with, and the box the screen keeps
## to. While he is in rock the box waits.
var _mapped: TileMapLayer = null
var _mapped_limits: Rect2 = Rect2()
var _rocks: RockMap = null
var _limits: Rect2 = Rect2()
var _has_limits: bool = false
var _limits_pending: bool = false


func begin(player: Player, tiles: TileMapLayer, centre: Vector2, zoom_level: float) -> void:
	assert(stats != null, "FixedFraming: assign a FixedFramingStats resource to Stats.")
	_player = player
	_centre = centre
	_speed = Vector2.ZERO
	_zoom = zoom_level
	_body = _find_body()
	_last_man = _man()
	_focus = _last_man
	_lead = 0.0
	_below = stats.below_centre
	_fall_time = 0.0
	_holding_body = false
	_cut = false
	_jump_up = (player.stats.jump_height if player.stats != null else 0.0) + stats.jump_room
	if tiles != _mapped:
		_mapped = tiles
		_rocks = RockMap.new(tiles) if is_instance_valid(tiles) else null
		_has_limits = false
		_limits_pending = true
	if camera_limits != _mapped_limits:
		_limits_pending = true
	if _limits_pending:
		_find_limits()


func advance(delta: float) -> void:
	_cut = false
	if not is_instance_valid(_player) or delta <= 0.0:
		return
	if _limits_pending:
		_find_limits()
	_zoom = exp(lerpf(log(_zoom), log(stats.zoom_level), 1.0 - exp(-stats.zoom_sharpness * delta)))
	var view: Vector2 = _view()
	var man: Vector2 = _man()
	var placed: bool = man.distance_to(_last_man) > PLACED_DISTANCE
	_last_man = man
	var falling: bool = _update_fall(delta)
	var axis: float = _chimney_axis(man)
	var drag: Vector2 = Vector2.ZERO
	if placed:
		_focus = man
		_lead = 0.0
		_below = stats.below_centre
	else:
		drag = _move_focus(man, delta)
		_ease_lead(axis, delta)
		_ease_below(falling, delta)
	var aim: Vector2 = _aim(view, axis, drag * 2.0 / stats.follow_sharpness)
	if placed:
		_centre = aim
		_speed = Vector2.ZERO
		_cut = true
	else:
		_follow(aim, delta)
	_keep_body_on_screen(view)
	_keep_inside_limits(view)


func get_centre() -> Vector2:
	return _centre


func get_zoom() -> float:
	return _zoom


func cut_to_framing() -> void:
	_zoom = stats.zoom_level
	_focus = _man()
	_last_man = _focus
	_lead = 0.0
	_below = stats.below_centre
	_speed = Vector2.ZERO
	_centre = _aim(_view(), _chimney_axis(_focus), Vector2.ZERO)
	_holding_body = true
	_cut = true


func has_cut() -> bool:
	return _cut


## Where the screen goes, kept inside the limits: on the chimney's axis across, or the focus, the lead and lag;
## and the focus with him Below Centre under the middle, and lag, up and down.
func _aim(view: Vector2, axis: float, lag: Vector2) -> Vector2:
	var aim: Vector2 = Vector2(axis if not is_nan(axis) else _focus.x + _lead * view.x + lag.x,
			_focus.y - _below * view.y + lag.y)
	return _inside_limits(aim, view)


## Moves the focus as he leaves the dead zone around it, and gives back how fast he dragged it, in px/s. On the
## floor it frames him up and down at once, which is not a drag: the landing is where the screen settles, and a
## jump never moves it.
func _move_focus(man: Vector2, delta: float) -> Vector2:
	var drag: Vector2 = Vector2.ZERO
	var x: float = clampf(_focus.x, man.x - stats.dead_zone_across, man.x + stats.dead_zone_across)
	drag.x = (x - _focus.x) / delta
	_focus.x = x
	if _player.is_on_floor():
		_focus.y = man.y
	else:
		var y: float = clampf(_focus.y, man.y - stats.dead_zone_down, man.y + _jump_up)
		drag.y = (y - _focus.y) / delta
		_focus.y = y
	return drag


## Leads to the side he runs, unless he is in a chimney, and back to nothing when he stops.
func _ease_lead(axis: float, delta: float) -> void:
	var side: float = 0.0
	if is_nan(axis) and absf(_player.velocity.x) > stats.look_ahead_speed:
		side = signf(_player.velocity.x)
	_lead = lerpf(_lead, side * stats.look_ahead, 1.0 - exp(-stats.look_ahead_sharpness * delta))


func _ease_below(falling: bool, delta: float) -> void:
	var target: float = stats.fall_below_centre if falling else stats.below_centre
	_below = lerpf(_below, target, 1.0 - exp(-stats.look_down_sharpness * delta))


## True once he has been falling for Fall Delay. A slide down a wall is no fall: he holds on to it, and on a climb
## up a chimney the screen would swing up and down at each slide.
func _update_fall(delta: float) -> bool:
	if _player.is_on_floor() or _player.is_on_wall() or _player.velocity.y <= 0.0:
		_fall_time = 0.0
	else:
		_fall_time += delta
	return _fall_time >= stats.fall_delay


## One step of a critically damped spring towards target, solved exactly for the step, and never faster than Max
## Speed.
func _follow(target: Vector2, delta: float) -> void:
	var omega: float = stats.follow_sharpness
	var offset: Vector2 = _centre - target
	var decay: float = exp(-omega * delta)
	var change: Vector2 = (_speed + omega * offset) * delta
	var step: Vector2 = target + (offset + change) * decay - _centre
	_speed = (_speed - omega * change) * decay
	var most: float = stats.max_speed * delta
	if step.length() > most:
		step = step.limit_length(most)
		_speed = _speed.limit_length(stats.max_speed)
	_centre += step


## Once his body is inside the Edge Margin, keeps it there, moving the screen with him on an axis it stops.
func _keep_body_on_screen(view: Vector2) -> void:
	var room: Vector2 = view / 2.0 - view * stats.edge_margin
	var body: Rect2 = Rect2(_player.global_position + _body.position, _body.size)
	var low: Vector2 = body.end - room
	var high: Vector2 = body.position + room
	var inside: bool = (_centre.x >= low.x and _centre.x <= high.x and _centre.y >= low.y and _centre.y <= high.y)
	_holding_body = _holding_body or inside
	if not _holding_body:
		return
	for axis: int in 2:
		var kept: float = body.get_center()[axis]
		if low[axis] <= high[axis]:
			kept = clampf(_centre[axis], low[axis], high[axis])
		if kept != _centre[axis]:
			_centre[axis] = kept
			_speed[axis] = _player.velocity[axis]


## Keeps the screen inside the limits, which win over the Edge Margin: his open cells are inside them, so by the
## map's outline his body stays Map Margin tiles from the screen's edge, if the camera's own limits allow it.
func _keep_inside_limits(view: Vector2) -> void:
	var kept: Vector2 = _inside_limits(_centre, view)
	for axis: int in 2:
		if kept[axis] != _centre[axis]:
			_speed[axis] = 0.0
	_centre = kept


## centre, moved so the screen stays inside the limits; centred on them on an axis it does not fit.
func _inside_limits(centre: Vector2, view: Vector2) -> Vector2:
	if not _has_limits:
		return centre
	var low: Vector2 = _limits.position + view / 2.0
	var high: Vector2 = _limits.end - view / 2.0
	return Vector2(
			clampf(centre.x, low.x, high.x) if low.x <= high.x else _limits.get_center().x,
			clampf(centre.y, low.y, high.y) if low.y <= high.y else _limits.get_center().y)


## The x of the middle of the chimney around man, or NAN if he is in none or there is no map.
func _chimney_axis(man: Vector2) -> float:
	if _rocks == null or not is_instance_valid(_rocks.tiles):
		return NAN
	return _rocks.chimney_axis(man, stats.chimney_width, stats.chimney_height)


## The box of the open cells joined to his, Map Margin tiles further out and inside the camera's own limits; with
## no map, or with the open cells reaching past it, the camera's own limits alone. While he is in rock it waits for
## a later step.
func _find_limits() -> void:
	var box: Rect2 = camera_limits
	if _rocks != null and is_instance_valid(_rocks.tiles):
		var space: RockMap.OpenSpace = _rocks.open_space(_rocks.cell_at(_man()))
		if space == null:
			return
		if not space.reaches_edge:
			var outline: Rect2 = _outline_of(space)
			box = outline.intersection(camera_limits) if outline.intersects(camera_limits) else outline
	_limits = box
	_has_limits = box.has_area()
	_mapped_limits = camera_limits
	_limits_pending = false


## The box around space, Map Margin tiles further out, in the level.
func _outline_of(space: RockMap.OpenSpace) -> Rect2:
	var tiles: TileMapLayer = _rocks.tiles
	var tile: Vector2 = Vector2(tiles.tile_set.tile_size)
	var top_left: Vector2 = tiles.to_global(tiles.map_to_local(space.first) - tile / 2.0)
	var bottom_right: Vector2 = tiles.to_global(tiles.map_to_local(space.last) + tile / 2.0)
	var margin: Vector2 = tile * stats.map_margin
	return Rect2(top_left, bottom_right - top_left).grow_individual(margin.x, margin.y, margin.x, margin.y)


func _man() -> Vector2:
	return _player.global_position + _body.get_center()


func _view() -> Vector2:
	return get_viewport().get_visible_rect().size / _zoom


func _find_body() -> Rect2:
	for child: Node in _player.get_children():
		var collision: CollisionShape2D = child as CollisionShape2D
		if collision != null and collision.shape is RectangleShape2D:
			var size: Vector2 = (collision.shape as RectangleShape2D).size
			return Rect2(collision.position - size / 2.0, size)
	return Rect2()
