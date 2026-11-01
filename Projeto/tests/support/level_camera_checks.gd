# The camera checks every level shares: overlapping zones never tie in area, every floor tile is in a
# zone, and every lookout has somewhere to stand in its rectangles and shows only its own way. Each
# check returns [passed, what was found], for the test to report.
extends RefCounted

const TILE: float = 48.0
## A Bottom Margin above this, in px, marks a shaft: it shows the room the shaft leads down to.
const SHAFT_MARGIN: float = 150.0


## The camera zones and lookouts of a level, in the scene's order.
static func zones_of(level: Node) -> Array[CameraZone]:
	var zones: Array[CameraZone] = []
	for node: Node in level.find_children("*", "Area2D", true, false):
		if node is CameraZone:
			zones.append(node as CameraZone)
	return zones


static func lookouts_of(level: Node) -> Array[CameraLookout]:
	var lookouts: Array[CameraLookout] = []
	for node: Node in level.find_children("*", "Area2D", true, false):
		if node is CameraLookout:
			lookouts.append(node as CameraLookout)
	return lookouts


static func overlapping_zones_differ_in_area(zones: Array[CameraZone]) -> Array:
	var overlapping: int = 0
	var ties: Array[String] = []
	for i: int in zones.size():
		for j: int in range(i + 1, zones.size()):
			if not _overlap(zones[i], zones[j]):
				continue
			overlapping += 1
			if is_equal_approx(zones[i].get_area(), zones[j].get_area()):
				ties.append("%s and %s" % [zones[i].name, zones[j].name])
	return [not zones.is_empty() and ties.is_empty(), "%d zones, %d overlapping pairs, pairs of the same area: %s"
			% [zones.size(), overlapping, ties if not ties.is_empty() else "none"]]


## Every air tile with rock right under it, where the player can stand, has a zone. Outside every
## zone the camera falls back to the whole level's limits.
static func every_floor_is_in_a_zone(tiles: TileMapLayer, zones: Array[CameraZone]) -> Array:
	var used: Rect2i = tiles.get_used_rect()
	var floors: int = 0
	var missing: Array[Vector2i] = []
	for y: int in range(used.position.y, used.end.y - 1):
		for x: int in range(used.position.x, used.end.x):
			var cell: Vector2i = Vector2i(x, y)
			if not _is_air(tiles, cell) or _is_air(tiles, cell + Vector2i.DOWN):
				continue
			floors += 1
			var feet: Vector2 = _feet(tiles, cell)
			if not zones.any(func(zone: CameraZone) -> bool: return zone.has_point(feet)):
				missing.append(cell)
	return [floors > 0 and missing.is_empty(), "%d floor tiles, without a zone: %s"
			% [floors, missing if not missing.is_empty() else "none"]]


## Each lookout has a floor tile, or the start of a moving platform, inside its rectangles, and its
## View has no air that is not joined, through air inside the View, to the air of its rectangles: no
## other path shows.
static func every_lookout_has_a_floor_and_shows_only_its_way(tiles: TileMapLayer,
		lookouts: Array[CameraLookout], platforms: Array[Node2D]) -> Array:
	var problems: Array[String] = []
	for lookout: CameraLookout in lookouts:
		var view: Rect2i = _cells_of(tiles, lookout.get_view())
		var start: Array[Vector2i] = []
		var floors: int = 0
		for rect: Rect2 in CameraZone.read_rects(lookout):
			var cells: Rect2i = _cells_of(tiles, rect)
			for y: int in range(cells.position.y, cells.end.y):
				for x: int in range(cells.position.x, cells.end.x):
					var cell: Vector2i = Vector2i(x, y)
					if not _is_air(tiles, cell):
						continue
					start.append(cell)
					if not _is_air(tiles, cell + Vector2i.DOWN) and lookout.has_point(_feet(tiles, cell)):
						floors += 1
		for platform: Node2D in platforms:
			if lookout.has_point(platform.global_position):
				floors += 1
		var joined: Dictionary[Vector2i, bool] = {}
		while not start.is_empty():
			var cell: Vector2i = start.pop_back()
			if joined.has(cell) or not view.has_point(cell) or not _is_air(tiles, cell):
				continue
			joined[cell] = true
			for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				start.append(cell + step)
		var others: int = 0
		for y: int in range(view.position.y, view.end.y):
			for x: int in range(view.position.x, view.end.x):
				if _is_air(tiles, Vector2i(x, y)) and not joined.has(Vector2i(x, y)):
					others += 1
		if floors == 0 or others > 0:
			problems.append("%s: %d places to stand, %d tiles of other paths in the View"
					% [lookout.name, floors, others])
	return [not lookouts.is_empty() and problems.is_empty(), "%d lookouts, problems: %s"
			% [lookouts.size(), problems if not problems.is_empty() else "none"]]


## With the player anywhere in a zone's air and the camera leading either way, every air tile the
## screen shows is joined, through air it also shows, to the zone's own air: no zone shows another
## path, not across a thin wall nor past its sides.
static func no_zone_shows_another_path(tiles: TileMapLayer, zones: Array[CameraZone],
		camera: GameCamera) -> Array:
	var problems: Array[String] = []
	var used: Rect2i = tiles.get_used_rect()
	var screen_size: Vector2 = camera.get_viewport_rect().size
	for zone: CameraZone in zones:
		var level: float = camera.get_zone_view(zone)["zoom"]
		var centres: Rect2 = camera._centre_range_in(zone, level)
		var half: Vector2 = screen_size / (2.0 * level)
		var ahead: float = camera.stats.look_ahead_distance / level
		var shown: Dictionary[Vector2i, bool] = {}
		var own: Array[Vector2i] = []
		var box: Rect2i = _cells_of(tiles, zone.get_limits())
		for y: int in range(box.position.y, box.end.y):
			for x: int in range(box.position.x, box.end.x):
				var cell: Vector2i = Vector2i(x, y)
				var at_cell: Vector2 = tiles.to_global(tiles.map_to_local(cell))
				if not _is_air(tiles, cell) or not zone.has_point(at_cell):
					continue
				own.append(cell)
				for lead: float in [-ahead, 0.0, ahead]:
					var at: Vector2 = (at_cell + Vector2(lead, 0.0)).clamp(centres.position, centres.end)
					var first: Vector2i = Vector2i(((at - half) / TILE).floor())
					var last: Vector2i = Vector2i(((at + half) / TILE).ceil())
					for sy: int in range(maxi(first.y, used.position.y), mini(last.y, used.end.y)):
						for sx: int in range(maxi(first.x, used.position.x), mini(last.x, used.end.x)):
							shown[Vector2i(sx, sy)] = true
		var joined: Dictionary[Vector2i, bool] = {}
		while not own.is_empty():
			var cell: Vector2i = own.pop_back()
			if joined.has(cell) or not shown.has(cell) or not _is_air(tiles, cell):
				continue
			joined[cell] = true
			for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				own.append(cell + step)
		var others: int = 0
		for cell: Vector2i in shown:
			if _is_air(tiles, cell) and not joined.has(cell):
				others += 1
		if others > 0:
			problems.append("%s: %d tiles of other paths" % [zone.name, others])
	return [not zones.is_empty() and problems.is_empty(), "%d zones, showing other paths: %s"
			% [zones.size(), problems if not problems.is_empty() else "none"]]


## A zone that limits the screen across and is narrower than it keeps the screen's edge on the side
## of the level's inside, so the rest of the screen falls on wall: past the zone's sides, the screen
## shows no more air with its Horizontal Anchor than with the mirrored one.
static func every_zone_shows_wall_past_its_sides(tiles: TileMapLayer, zones: Array[CameraZone],
		camera: GameCamera) -> Array:
	var problems: Array[String] = []
	var limited: int = 0
	for zone: CameraZone in zones:
		if not zone.limit_horizontally or not zone.get_limits().has_area():
			continue
		limited += 1
		var anchor: float = zone.horizontal_anchor
		var air: int = _air_past_the_sides(tiles, zone, camera)
		zone.horizontal_anchor = 1.0 - anchor
		var mirrored: int = _air_past_the_sides(tiles, zone, camera)
		zone.horizontal_anchor = anchor
		if mirrored < air:
			problems.append("%s: %d tiles of air past its sides, %d with the anchor at %.2f"
					% [zone.name, air, mirrored, 1.0 - anchor])
	return [limited > 0 and problems.is_empty(), "%d zones limited across, showing the level's inside past their sides: %s"
			% [limited, problems if not problems.is_empty() else "none"]]


## A zone's floor is its lower limit: in each of its columns, under the zone's lowest air, what the
## box and its Bottom Margin show is rock, or air that goes straight on down from the zone's own air
## (an opening). Air after some rock would be the level below, seen through the floor. Shafts, whose
## margin is there to show the room they lead down to, are left out.
static func every_floor_is_the_lower_limit(tiles: TileMapLayer, zones: Array[CameraZone]) -> Array:
	var problems: Array[String] = []
	var level: Rect2i = tiles.get_used_rect()
	for zone: CameraZone in zones:
		if zone.bottom_margin > SHAFT_MARGIN:
			continue
		# Past the level's tiles there is nothing to see: the camera's own limits stop there.
		var cells: Rect2i = _cells_of(tiles, zone.get_limits().grow_side(SIDE_BOTTOM, zone.bottom_margin)).intersection(level)
		var below: int = 0
		for x: int in range(cells.position.x, cells.end.x):
			var lowest: int = -1
			for y: int in range(cells.position.y, cells.end.y):
				var cell: Vector2i = Vector2i(x, y)
				if _is_air(tiles, cell) and zone.has_point(tiles.to_global(tiles.map_to_local(cell))):
					lowest = y
			if lowest < 0:
				continue
			var rock_seen: bool = false
			for y: int in range(lowest + 1, cells.end.y):
				if not _is_air(tiles, Vector2i(x, y)):
					rock_seen = true
				elif rock_seen:
					below += 1
		if below > 0:
			problems.append("%s: %d tiles of the level below" % [zone.name, below])
	return [not zones.is_empty() and problems.is_empty(), "%d zones, showing the level below: %s"
			% [zones.size(), problems if not problems.is_empty() else "none"]]


static func _overlap(first: CameraZone, second: CameraZone) -> bool:
	for a: Rect2 in CameraZone.read_rects(first):
		for b: Rect2 in CameraZone.read_rects(second):
			if a.intersects(b):
				return true
	return false


## The air tiles the screen shows past the zone's sides, at every height the camera takes in the
## zone. A screen that would pass the camera's own limits is pushed back inside them, as in the game.
static func _air_past_the_sides(tiles: TileMapLayer, zone: CameraZone, camera: GameCamera) -> int:
	var level: float = camera.get_zone_view(zone)["zoom"]
	var centres: Rect2 = camera._centre_range_in(zone, level)
	var screen: Vector2 = camera.get_viewport_rect().size / level
	var own: Rect2 = camera._own_limits()
	var first: Vector2 = (centres.position - screen / 2.0).clamp(own.position, own.end - screen)
	var last: Vector2 = (centres.end - screen / 2.0).clamp(own.position, own.end - screen)
	var shown: Rect2i = _cells_of(tiles, Rect2(first, last - first + screen))
	var inside: Rect2i = _cells_of(tiles, zone.get_limits())
	var air: int = 0
	for y: int in range(shown.position.y, shown.end.y):
		for x: int in range(shown.position.x, shown.end.x):
			if (x < inside.position.x or x >= inside.end.x) and _is_air(tiles, Vector2i(x, y)):
				air += 1
	return air


static func _is_air(tiles: TileMapLayer, cell: Vector2i) -> bool:
	return tiles.get_cell_source_id(cell) == -1


## Where the feet of a player standing in cell are: just above the floor under it.
static func _feet(tiles: TileMapLayer, cell: Vector2i) -> Vector2:
	return tiles.to_global(tiles.map_to_local(cell)) + Vector2(0.0, TILE / 2.0 - 1.0)


## The tiles whose centres are inside rect.
static func _cells_of(tiles: TileMapLayer, rect: Rect2) -> Rect2i:
	var first: Vector2i = tiles.local_to_map(tiles.to_local(rect.position + Vector2.ONE * TILE / 2.0))
	var last: Vector2i = tiles.local_to_map(tiles.to_local(rect.end - Vector2.ONE * TILE / 2.0))
	return Rect2i(first, last - first + Vector2i.ONE)
