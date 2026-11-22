# Prints how much of the screen each way of the camera fills with plain rock in level 1, and how far from the
# screen's centre it keeps the man. The stones the level lays along the rock's faces (StoneRim) reach about a tile
# into the rock, so rock with rock all round it, on the 8 sides, shows as the plain fill; the rest of the rock is
# drawn. Rock is read as the camera with one zoom reads it, through RockMap. Each switch of the camera's way is
# timed: the first one onto a map reads the map. The man is put on one tile in SPOT_STEP of every floor he can
# reach from his start (open cells joined to his, with room for his body), floor after nearest floor, and the
# camera settles on him before the screen is read.
# Every way of the level's camera is read over the same spots: its own (Zones) and each CameraBrain child. Then a
# screen centred on him, kept inside the reachable map plus MAP_MARGIN, is read at each zoom from SWEEP_FIRST to
# SWEEP_LAST: how a camera with one zoom frames him standing. The mean fill of the camera's own way is the budget
# that zoom has to keep within. The level goes without its dogs, its cutscenes count as seen, the idle zoom is off
# (the screen is read as while he moves) and he is in god mode, so no spike kills him where he is put.
# It checks nothing: the exit code is 1 only if there is no spot to put him on.
# Run from the repository root:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/measures/measure_camera_space.gd
extends "res://tests/support/player_test.gd"

## A reachable open cell; rock beside an open cell, on one of its 8 sides, which the stones cover; rock with rock
## all round, the fill; and an open cell he cannot reach, or past the map, which shows the backdrop.
enum Cell { OPEN, DRAWN, FILL, OUTSIDE }

const SCENE_PATH: String = "res://scenes/levels/lust/level1_lit.tscn"
## With this event, Velvet does not stop the man to talk as he walks past.
const VELVET_MET: StringName = &"velvet_met"
## He is put on one tile in this many along each floor, and on its last.
const SPOT_STEP: int = 3
## The camera has settled once it moved less than SETTLED_MOVE px and zoomed less than SETTLED_ZOOM on
## SETTLED_FRAMES frames in a row. It gets SETTLE_LIMIT frames at most.
const SETTLED_MOVE: float = 0.5
const SETTLED_ZOOM: float = 0.0005
const SETTLED_FRAMES: int = 10
const SETTLE_LIMIT: int = 480
## Two zooms differ when they are further apart than this.
const ZOOM_CHANGE: float = 0.01
## The zooms a screen with one zoom is read at.
const SWEEP_FIRST: float = 1.0
const SWEEP_LAST: float = 1.6
const SWEEP_STEP: float = 0.1
## How far past the outermost reachable open cell a screen with one zoom may show, in tiles.
const MAP_MARGIN: int = 2
## How far below the screen's centre a screen with one zoom may put him, in shares of its height.
const BELOW_CENTRE: Array[float] = [0.0, 0.2, 0.25, 0.3]
## How far past the rock around him, above, below and to the sides, a screen kept to the open space may show, in
## tiles: about what the stones cover, and more.
const SPACE_MARGINS: Array[float] = [1.0, 3.0]
## The share of spots the high line is over.
const HIGH_SHARE: float = 0.9
## The level's nodes that would make the reading depend on them: the dogs, the demon that blocks the tutorial and
## Asmodeus, who stops him to talk.
const LEFT_OUT: Array[NodePath] = [^"Dogs", ^"Tutorial/BlockerDemon", ^"AsmodeusDirector"]

var _level: Node
var _player: Player
var _camera: GameCamera
var _tiles: TileMapLayer
var _tile: Vector2 = Vector2.ZERO
## The player's body relative to his position.
var _body: Rect2 = Rect2()
## The map's cells, one row of the used rectangle and a cell around it after the other.
var _origin: Vector2i = Vector2i.ZERO
var _size: Vector2i = Vector2i.ZERO
var _cells: PackedByteArray = PackedByteArray()
## Sums of the fill and the outside cells above and to the left of each corner, for any rectangle's count at once.
var _fill_sums: PackedInt32Array = PackedInt32Array()
var _outside_sums: PackedInt32Array = PackedInt32Array()
## The reachable open cells' box, in the world.
var _open_box: Rect2 = Rect2()
var _open_reaches_the_edge: bool = false


func _initialize() -> void:
	await process_frame
	(root.get_node(^"GameState") as GameProgress).mark_event(VELVET_MET)
	root.size = Vector2i(int(ProjectSettings.get_setting("display/window/size/viewport_width")),
			int(ProjectSettings.get_setting("display/window/size/viewport_height")))
	await process_frame
	var started: int = Time.get_ticks_msec()
	_level = (load(SCENE_PATH) as PackedScene).instantiate()
	_prepare(_level)
	root.add_child(_level)
	_player = _level.get_node(^"Player") as Player
	_player.god_mode = true
	put_a_stand_in(_player)
	_camera = _level.get_node(^"GameCamera") as GameCamera
	_camera.stats = _camera.stats.duplicate() as CameraStats
	_camera.stats.idle_zoom = 1.0
	_tiles = _level.get_node(^"Tiles") as TileMapLayer
	_tile = Vector2(_tiles.tile_set.tile_size)
	var collision: CollisionShape2D = _player.get_node(^"CollisionShape2D") as CollisionShape2D
	var body_size: Vector2 = (collision.shape as RectangleShape2D).size
	_body = Rect2(collision.position - body_size / 2.0, body_size)
	await wait_frames(SETTLED_FRAMES)

	if not _map(_tiles.local_to_map(_tiles.to_local(_player.global_position - Vector2(0.0, _tile.y / 2.0)))):
		printerr("He starts in rock")
		quit(1)
		return
	var floors: Array[Vector3i] = _ordered_floors(_floors(ceili(_body.size.y / _tile.y)))
	var spots: Array[Vector2i] = []
	var floor_of_spot: PackedInt32Array = PackedInt32Array()
	for index: int in floors.size():
		for spot: Vector2i in _spots_on(floors[index]):
			spots.append(spot)
			floor_of_spot.append(index)
	_print_map(floors.size(), spots.size())
	if spots.is_empty():
		printerr("No floor to put him on")
		quit(1)
		return

	var budget: Vector2 = Vector2.ZERO
	var framings: Array[String] = [_camera.get_framing_name()]
	while true:
		var samples: Array[Dictionary] = await _read(spots)
		var shares: Vector2 = _print_framing(_camera.get_framing_name(), samples, floor_of_spot)
		if framings.size() == 1:
			budget = shares
		var switched: int = Time.get_ticks_usec()
		_camera.cycle_framing()
		if framings.has(_camera.get_framing_name()):
			break
		framings.append(_camera.get_framing_name())
		print("the switch to %s took %.1f ms (the first one on a map reads it)"
				% [_camera.get_framing_name(), (Time.get_ticks_usec() - switched) / 1000.0])
	_print_sweep(spots, budget)
	print("took %.0f s" % ((Time.get_ticks_msec() - started) / 1000.0))
	quit(0)


func _prepare(level: Node) -> void:
	for path: NodePath in LEFT_OUT:
		var node: Node = level.get_node_or_null(path)
		if node != null:
			node.free()
	var view: Node = level.get_node_or_null(^"DemonDebugView")
	if view != null:
		view.set("demons", [] as Array[Demon])
	var progress: GameProgress = root.get_node(^"GameState") as GameProgress
	for node: Node in level.find_children("*", "Node", true, false):
		var cutscene: CameraCutscene = node as CameraCutscene
		if cutscene != null and not cutscene.event.is_empty():
			progress.mark_event(cutscene.event)


## Sorts every cell of the used rectangle, and a cell around it, from the open cells joined to start, reading the
## rock as the camera does (RockMap). Returns false if start is not open.
func _map(start: Vector2i) -> bool:
	var rocks: RockMap = RockMap.new(_tiles)
	var space: RockMap.OpenSpace = rocks.open_space(start)
	if space == null:
		return false
	_origin = rocks.origin
	_size = rocks.size
	_open_reaches_the_edge = space.reaches_edge
	_cells.resize(_size.x * _size.y)
	for y: int in _size.y:
		for x: int in _size.x:
			var cell: Vector2i = _origin + Vector2i(x, y)
			var at: int = rocks.index_of(cell)
			if space.cells[at] == RockMap.REACHED:
				_cells[at] = Cell.OPEN
			elif space.cells[at] == RockMap.OPEN:
				_cells[at] = Cell.OUTSIDE
			else:
				_cells[at] = Cell.FILL if _rock_all_round(rocks, cell) else Cell.DRAWN
	var top_left: Vector2 = _tiles.to_global(_tiles.map_to_local(space.first) - _tile / 2.0)
	var bottom_right: Vector2 = _tiles.to_global(_tiles.map_to_local(space.last) + _tile / 2.0)
	_open_box = Rect2(top_left, bottom_right - top_left)
	_fill_sums = _sums_of(Cell.FILL)
	_outside_sums = _sums_of(Cell.OUTSIDE)
	return true


## Rock on all 8 sides of cell.
func _rock_all_round(rocks: RockMap, cell: Vector2i) -> bool:
	for dy: int in range(-1, 2):
		for dx: int in range(-1, 2):
			if not rocks.is_rock(cell + Vector2i(dx, dy)):
				return false
	return true


func _sums_of(kind: Cell) -> PackedInt32Array:
	var width: int = _size.x + 1
	var sums: PackedInt32Array = PackedInt32Array()
	sums.resize(width * (_size.y + 1))
	for y: int in _size.y:
		for x: int in _size.x:
			sums[(y + 1) * width + x + 1] = (sums[y * width + x + 1] + sums[(y + 1) * width + x]
					- sums[y * width + x] + (1 if _cells[y * _size.x + x] == kind else 0))
	return sums


## Every floor he fits on, as (row, first cell, last cell) in the grid: runs of reachable open cells with a tile
## under them (rock or a platform) and open cells, with no tile, for the height of his body.
func _floors(body_cells: int) -> Array[Vector3i]:
	var floors: Array[Vector3i] = []
	for y: int in range(body_cells, _size.y - 1):
		var first: int = -1
		for x: int in _size.x + 1:
			if x < _size.x and _fits(Vector2i(x, y), body_cells):
				if first < 0:
					first = x
			elif first >= 0:
				floors.append(Vector3i(y, first, x - 1))
				first = -1
	return floors


func _fits(cell: Vector2i, body_cells: int) -> bool:
	if _cells[_index(cell)] != Cell.OPEN or _tiles.get_cell_source_id(_origin + cell + Vector2i.DOWN) == -1:
		return false
	for up: int in body_cells:
		if _tiles.get_cell_source_id(_origin + cell + Vector2i.UP * up) != -1:
			return false
	return true


## The floors from his start on, each next the nearest to the end of the one before, walked from its nearer end;
## (row, from, to), with to before from when it is walked leftwards.
func _ordered_floors(floors: Array[Vector3i]) -> Array[Vector3i]:
	var ordered: Array[Vector3i] = []
	var left: Array[Vector3i] = floors.duplicate()
	var at: Vector2i = _tiles.local_to_map(_tiles.to_local(_player.global_position)) - _origin
	while not left.is_empty():
		var best: int = 0
		var best_distance: float = INF
		var best_reversed: bool = false
		for index: int in left.size():
			var run: Vector3i = left[index]
			var to_first: float = Vector2(at).distance_squared_to(Vector2(run.y, run.x))
			var to_last: float = Vector2(at).distance_squared_to(Vector2(run.z, run.x))
			if minf(to_first, to_last) < best_distance:
				best = index
				best_distance = minf(to_first, to_last)
				best_reversed = to_last < to_first
		var chosen: Vector3i = left[best]
		left.remove_at(best)
		var walked: Vector3i = Vector3i(chosen.x, chosen.z, chosen.y) if best_reversed else chosen
		ordered.append(walked)
		at = Vector2i(walked.z, walked.x)
	return ordered


## One cell in SPOT_STEP along the floor, in the way it is walked, and its last.
func _spots_on(run: Vector3i) -> Array[Vector2i]:
	var spots: Array[Vector2i] = []
	var step: int = SPOT_STEP if run.z >= run.y else -SPOT_STEP
	var x: int = run.y
	while (x - run.z) * signi(step) < 0:
		spots.append(Vector2i(x, run.x))
		x += step
	spots.append(Vector2i(run.z, run.x))
	return spots


## Puts him on each spot and reads the screen once the camera settles there.
func _read(spots: Array[Vector2i]) -> Array[Dictionary]:
	var samples: Array[Dictionary] = []
	for spot: Vector2i in spots:
		_player.velocity = Vector2.ZERO
		_player.global_position = _feet(spot)
		var settled: bool = await _settle()
		samples.append({
			"centre": _camera.get_screen_center_position(),
			"zoom": _camera.zoom.x,
			"man": _player.global_position + _body.get_center(),
			"settled": settled,
			"directed": _camera.is_directed(),
		})
	return samples


func _settle() -> bool:
	var still: int = 0
	var last_at: Vector2 = _camera.get_screen_center_position()
	var last_zoom: float = _camera.zoom.x
	for _frame: int in SETTLE_LIMIT:
		await physics_frame
		var at: Vector2 = _camera.get_screen_center_position()
		var moved: bool = (at.distance_to(last_at) >= SETTLED_MOVE
				or absf(_camera.zoom.x - last_zoom) >= SETTLED_ZOOM)
		still = 0 if moved else still + 1
		if still >= SETTLED_FRAMES:
			return true
		last_at = at
		last_zoom = _camera.zoom.x
	return false


## Where his feet go on the floor under cell: just above it.
func _feet(cell: Vector2i) -> Vector2:
	return _tiles.to_global(_tiles.map_to_local(_origin + cell)) + Vector2(0.0, _tile.y / 2.0 - 0.1)


## The shares of the screen centred at centre, at zoom, that are fill (x) and outside the reachable map (y),
## counting the cells whose middles it shows. Cells past the grid are outside.
func _shares(centre: Vector2, zoom_level: float) -> Vector2:
	var half: Vector2 = root.get_visible_rect().size / (2.0 * zoom_level)
	var near: Vector2 = _tiles.to_local(centre - half) / _tile - Vector2.ONE * 0.5
	var far: Vector2 = _tiles.to_local(centre + half) / _tile - Vector2.ONE * 0.5
	var first: Vector2i = Vector2i(ceili(near.x), ceili(near.y)) - _origin
	var past: Vector2i = Vector2i(ceili(far.x), ceili(far.y)) - _origin
	var total: int = (past.x - first.x) * (past.y - first.y)
	if total <= 0:
		return Vector2.ZERO
	var inside_first: Vector2i = first.clamp(Vector2i.ZERO, _size)
	var inside_past: Vector2i = past.clamp(Vector2i.ZERO, _size)
	var inside: int = (inside_past.x - inside_first.x) * (inside_past.y - inside_first.y)
	var fill: int = _count(_fill_sums, inside_first, inside_past)
	var outside: int = _count(_outside_sums, inside_first, inside_past) + total - inside
	return Vector2(float(fill) / total, float(outside) / total)


func _count(sums: PackedInt32Array, first: Vector2i, past: Vector2i) -> int:
	var width: int = _size.x + 1
	return (sums[past.y * width + past.x] - sums[first.y * width + past.x] - sums[past.y * width + first.x]
			+ sums[first.y * width + first.x])


func _print_map(floors: int, spots: int) -> void:
	var counts: PackedInt32Array = PackedInt32Array([0, 0, 0, 0])
	for kind: int in _cells:
		counts[kind] += 1
	var total: float = _cells.size() / 100.0
	print(("map: %d x %d tiles; open and reachable %.0f %%, rock drawn %.0f %%, fill %.0f %%, open and out of reach "
			+ "%.0f %%; %d floors, %d spots (one tile in %d)%s")
			% [_size.x, _size.y, counts[Cell.OPEN] / total, counts[Cell.DRAWN] / total, counts[Cell.FILL] / total,
			counts[Cell.OUTSIDE] / total, floors, spots, SPOT_STEP,
			"; THE OPEN CELLS REACH THE MAP'S EDGE" if _open_reaches_the_edge else ""])


## Prints what the way named framing showed over the samples, and hands back its mean fill and its high fill.
func _print_framing(framing: String, samples: Array[Dictionary], floor_of_spot: PackedInt32Array) -> Vector2:
	var fills: PackedFloat32Array = PackedFloat32Array()
	var outsides: PackedFloat32Array = PackedFloat32Array()
	var across: PackedFloat32Array = PackedFloat32Array()
	var up_down: PackedFloat32Array = PackedFloat32Array()
	var zooms: Dictionary[String, int] = {}
	var changes: int = 0
	var tiles_walked: int = 0
	var unsettled: int = 0
	var directed: int = 0
	var worst: int = 0
	for index: int in samples.size():
		var sample: Dictionary = samples[index]
		var zoom_level: float = sample["zoom"]
		var shares: Vector2 = _shares(sample["centre"], zoom_level)
		fills.append(shares.x)
		outsides.append(shares.y)
		if shares.x > fills[worst]:
			worst = index
		var off: Vector2 = (Vector2(sample["man"]) - Vector2(sample["centre"])) * zoom_level
		across.append(absf(off.x))
		up_down.append(absf(off.y))
		var zoom_name: String = "%.2f" % zoom_level
		zooms[zoom_name] = zooms.get(zoom_name, 0) + 1
		unsettled += 0 if sample["settled"] else 1
		directed += 1 if sample["directed"] else 0
		if index > 0 and floor_of_spot[index] == floor_of_spot[index - 1]:
			tiles_walked += SPOT_STEP
			if absf(zoom_level - float(samples[index - 1]["zoom"])) > ZOOM_CHANGE:
				changes += 1
	var shares_of_zooms: Array[String] = []
	var names: Array[String] = []
	names.assign(zooms.keys())
	names.sort()
	for zoom_name: String in names:
		shares_of_zooms.append("%s %.0f %%" % [zoom_name, 100.0 * zooms[zoom_name] / samples.size()])
	print(("%s: fill mean %.1f %%, %.0fth %.1f %%, highest %.1f %% at %s; outside mean %.1f %%, highest %.1f %%; "
			+ "the man from the screen's centre in screen px, across mean %.0f, %.0fth %.0f, up and down mean %.0f, "
			+ "%.0fth %.0f; zooms %s; %.1f zoom changes per 100 tiles walked; %d never settled, %d in a cutscene")
			% [framing, 100.0 * _mean(fills), 100.0 * HIGH_SHARE, 100.0 * _high(fills), 100.0 * fills[worst],
			_feet_of(samples[worst]), 100.0 * _mean(outsides), 100.0 * _high(outsides, 1.0), _mean(across),
			100.0 * HIGH_SHARE, _high(across), _mean(up_down), 100.0 * HIGH_SHARE, _high(up_down),
			", ".join(shares_of_zooms), 100.0 * changes / maxi(tiles_walked, 1), unsettled, directed])
	return Vector2(_mean(fills), _high(fills))


func _feet_of(sample: Dictionary) -> Vector2:
	return (Vector2(sample["man"]) - _body.get_center()).round()


## Screens with one zoom, kept inside the reachable map and MAP_MARGIN, read at each zoom of the sweep: with him
## at each height of BELOW_CENTRE under the centre, kept to the open space around him, and kept to it only up and
## down, centred across. For each, the widest zoom whose mean fill, and whose high fill, keep within budget's.
func _print_sweep(spots: Array[Vector2i], budget: Vector2) -> void:
	for below: float in BELOW_CENTRE:
		_print_framer("%.0f %% of the screen under the centre" % (100.0 * below), spots, budget,
				func(_spot: Vector2i, man: Vector2, view: Vector2) -> Vector2:
					return man - Vector2(0.0, below * view.y))
	for margin: float in SPACE_MARGINS:
		_print_framer("kept to the open space around him, %.0f tiles past it" % margin, spots, budget,
				_kept_to_the_space.bind(margin, true))
		_print_framer("kept to the floor and the rock above, %.0f tiles past them, centred across" % margin, spots,
				budget, _kept_to_the_space.bind(margin, false))


## Reads the screen centred where framer(spot, man, view) says, kept inside the map, at each zoom of the sweep.
func _print_framer(framing: String, spots: Array[Vector2i], budget: Vector2, framer: Callable) -> void:
	var limits: Rect2 = _open_box.grow(MAP_MARGIN * _tile.x)
	var within_mean: float = NAN
	var within_high: float = NAN
	var steps: int = roundi((SWEEP_LAST - SWEEP_FIRST) / SWEEP_STEP)
	for step: int in steps + 1:
		var zoom_level: float = SWEEP_FIRST + step * SWEEP_STEP
		var view: Vector2 = root.get_visible_rect().size / zoom_level
		var fills: PackedFloat32Array = PackedFloat32Array()
		var across: PackedFloat32Array = PackedFloat32Array()
		var up_down: PackedFloat32Array = PackedFloat32Array()
		for spot: Vector2i in spots:
			var man: Vector2 = _feet(spot) + _body.get_center()
			var centre: Vector2 = _inside(framer.call(spot, man, view), view, limits)
			fills.append(_shares(centre, zoom_level).x)
			across.append(absf(man.x - centre.x) * zoom_level)
			up_down.append(absf(man.y - centre.y) * zoom_level)
		if is_nan(within_mean) and _mean(fills) <= budget.x:
			within_mean = zoom_level
		if is_nan(within_high) and _high(fills) <= budget.y:
			within_high = zoom_level
		print(("one zoom, %s, %.1f (%.1f x %.1f tiles): fill mean %.1f %%, %.0fth %.1f %%; the man from the "
				+ "centre in screen px, across mean %.0f, %.0fth %.0f, up and down mean %.0f, %.0fth %.0f")
				% [framing, zoom_level, view.x / _tile.x, view.y / _tile.y, 100.0 * _mean(fills),
				100.0 * HIGH_SHARE, 100.0 * _high(fills), _mean(across), 100.0 * HIGH_SHARE, _high(across),
				_mean(up_down), 100.0 * HIGH_SHARE, _high(up_down)])
	print(("  within the camera's own way (fill mean %.1f %%, %.0fth %.1f %%): widest zoom within the mean %s, "
			+ "within the %.0fth %s")
			% [100.0 * budget.x, 100.0 * HIGH_SHARE, 100.0 * budget.y,
			"none" if is_nan(within_mean) else "%.1f" % within_mean, 100.0 * HIGH_SHARE,
			"none" if is_nan(within_high) else "%.1f" % within_high])


## man, kept to the open space around spot: between the rock above him and the rock under the floor (through
## platforms) and, if across, between the walls at his feet, each margin tiles further out, as far as a screen of
## size view reaches. A screen that does not fit in that space is centred on it.
func _kept_to_the_space(spot: Vector2i, man: Vector2, view: Vector2, margin_tiles: float, across: bool) -> Vector2:
	var reach: Vector2i = Vector2i(ceili(view.x / _tile.x), ceili(view.y / _tile.y))
	var up: int = _open_run(spot, Vector2i.UP, reach.y)
	var down: int = _open_run(spot, Vector2i.DOWN, reach.y)
	var left: int = _open_run(spot, Vector2i.LEFT, reach.x)
	var right: int = _open_run(spot, Vector2i.RIGHT, reach.x)
	var cell_top_left: Vector2 = _tiles.to_global(_tiles.map_to_local(_origin + spot) - _tile / 2.0)
	var margin: Vector2 = _tile * margin_tiles
	var low: Vector2 = cell_top_left - Vector2(left, up) * _tile - margin
	var high: Vector2 = cell_top_left + Vector2(right + 1, down + 1) * _tile + margin
	return Vector2(
			_kept_between(man.x, low.x if left < reach.x else -INF, high.x if right < reach.x else INF, view.x)
			if across else man.x,
			_kept_between(man.y, low.y if up < reach.y else -INF, high.y if down < reach.y else INF, view.y))


## How many cells past spot, going way, are open before rock or the grid's edge, counting up to reach.
func _open_run(spot: Vector2i, way: Vector2i, reach: int) -> int:
	var count: int = 0
	var cell: Vector2i = spot + way
	while count < reach and _in_grid(cell) and _cells[_index(cell)] in [Cell.OPEN, Cell.OUTSIDE]:
		count += 1
		cell += way
	return count


## value, moved so a screen of size length around it stays between low and high; their middle if it does not fit.
func _kept_between(value: float, low: float, high: float, length: float) -> float:
	if high - low <= length:
		return (low + high) / 2.0
	return clampf(value, low + length / 2.0, high - length / 2.0)


## centre, moved so a screen of size view stays inside limits; centred on limits on an axis it does not fit.
func _inside(centre: Vector2, view: Vector2, limits: Rect2) -> Vector2:
	var low: Vector2 = limits.position + view / 2.0
	var high: Vector2 = limits.end - view / 2.0
	return Vector2(
			clampf(centre.x, low.x, high.x) if low.x <= high.x else limits.get_center().x,
			clampf(centre.y, low.y, high.y) if low.y <= high.y else limits.get_center().y)


func _mean(values: PackedFloat32Array) -> float:
	var total: float = 0.0
	for value: float in values:
		total += value
	return total / maxi(values.size(), 1)


## The value HIGH_SHARE of the values are at or under, or share's.
func _high(values: PackedFloat32Array, share: float = HIGH_SHARE) -> float:
	var sorted: PackedFloat32Array = values.duplicate()
	sorted.sort()
	return sorted[clampi(ceili(share * sorted.size()) - 1, 0, sorted.size() - 1)]


func _index(cell: Vector2i) -> int:
	return cell.y * _size.x + cell.x


func _in_grid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < _size.x and cell.y < _size.y
