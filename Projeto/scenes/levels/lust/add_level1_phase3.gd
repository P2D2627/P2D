# Adds level 1's phase 3 to the level as it is now: the scene, levels/lust/level1.tscn, is edited by hand, so it is
# not built again; phase 3 goes into the solid rock above phase 1 and left of phase 2, from its text map,
# level1_phase3.txt (see that file). It carves the air and lays the platforms there, and adds the dogs, the biggest
# dog, the collapsing platforms, the spikes (on the walls too, turned on their side), the three gates, the two
# unlockers, the camera zones and a save point, so that a death in phase 3 starts over at its S. It opens phase 2's F
# room into the new room after it, takes away the rim's stones that would stand across that door, and moves the
# level's way out to phase 3's F. Its art goes where phase 3 opened the rock, and only there, so the art edited by
# hand stays as it is: the rim's stones along the new outline, and the backdrop's loose rocks on the new floors and
# ceilings, as phases 1 and 2 have them. Each tile it carves must be rock, and each gate must slide into rock;
# otherwise it saves nothing. It runs once: with Phase3Save already in the scene, it saves nothing, unless asked
# with --art, which only lays phase 3's art, once, in a scene that has phase 3 and none of its art yet, or with
# --reshape and the path of the map phase 3 was laid from, which changes phase 3 in the scene to the map now where
# the two maps differ, and only there (see _reshape). From the repository root, with the editor closed:
# godot --headless --path Projeto --script res://scenes/levels/lust/add_level1_phase3.gd
# godot --headless --path Projeto --script res://scenes/levels/lust/add_level1_phase3.gd -- --art
# godot --headless --path Projeto --script res://scenes/levels/lust/add_level1_phase3.gd -- --reshape <old map>
# The exit code is 0 when the scene was saved, and 1 when it was not.
extends "res://scenes/levels/lust/build_level1.gd"

## What a character of the map is on the tiles: nothing, rock or a platform.
enum TileKind { EMPTY, ROCK, PLATFORM, OTHER }

const PHASE_3_MAP_PATH: String = "res://scenes/levels/lust/level1_phase3.txt"
const BIGGEST_DOG_SCENE: PackedScene = preload("res://scenes/characters/demon/biggest_demon.tscn")
const PHASE_3_LEGEND: String = "#.-=^[]dG123uvPF"
const WALL_SPIKES_LEFT: String = "["
const WALL_SPIKES_RIGHT: String = "]"
const BIGGEST_DOG: String = "G"
const GATE_DIGITS: String = "123"
const UNLOCKER_LETTERS: String = "uv"
## Every node it adds is named with this in front, so phase 3's pieces are told apart from the rest.
const PREFIX: String = "P3"
const PHASE_3_SAVE: String = "Phase3Save"
const PHASE_3_REACHED_EVENT: StringName = &"lust_phase_3_reached"
const SLIDE_WAYS: Dictionary[String, Gate.SlideWay] = {
	"up": Gate.SlideWay.UP, "left": Gate.SlideWay.LEFT, "right": Gate.SlideWay.RIGHT,
}
## Passed after -- to lay only phase 3's art, in a scene that already has phase 3.
const ART_ARGUMENT: String = "--art"
## Passed after --, then the path of the map phase 3 was laid from, to change phase 3 in the scene to the map now.
const RESHAPE_ARGUMENT: String = "--reshape"
## What --reshape changes where the two maps differ: tiles and floor spikes. Anything else is done by hand.
const RESHAPED: String = "#.-^"
## How far, in px, a loose rock's middle may be from the floor or ceiling it stands on: half the tallest drawing.
const ROCK_REACH: float = 384.0
const RIM_PATH: NodePath = ^"Art/StoneRim"
## The stones of a kind are drawn together, in this order (see levels/stone_rim.gd), so a stone laid goes after
## the last one of its kind. Both corners are one kind: they are laid mixed, after the rest.
const STONE_KINDS: PackedStringArray = ["LeftWall", "RightWall", "Ceiling", "Floor", "Corner"]
## The backdrop's loose rocks: the drawings (512 px squares, the rock in the middle) and, for each of the backdrop's
## layers, how far it is, how big its rocks are and how many go on a run of floor or ceiling of a given length. All
## measured from phases 1 and 2's rocks: "floor" and "ceiling" are (shortest run in tiles, tiles per rock); "fits"
## is how tall a rock may be against the air over its floor (or under its ceiling): the far ones stand behind the
## walls, the near ones fit in the room; "air" is the fewest tiles of air there for a rock at all (the far ones
## only go in tall rooms). Only the first "drawings" drawings are used, as there.
const ROCK_DRAWINGS: PackedStringArray = [
	"res://assets/sprites/environment/rocha1.png", "res://assets/sprites/environment/rocha2.png",
	"res://assets/sprites/environment/rocha3.png", "res://assets/sprites/environment/rocha4.png",
	"res://assets/sprites/environment/rocha5.png", "res://assets/sprites/environment/rocha6.png",
	"res://assets/sprites/environment/rocha7.png", "res://assets/sprites/environment/rocha8.png",
]
const ROCK_LAYERS: Array[Dictionary] = [
	{"layer": ^"Backdrop/Far", "depth": 0.55, "scale": Vector2(0.7, 1.3), "drawings": 8,
			"floor": Vector2i(24, 18), "ceiling": Vector2i(16, 11), "fits": 1.2, "air": 7},
	{"layer": ^"Backdrop/Mid", "depth": 0.8, "scale": Vector2(0.35, 0.8), "drawings": 8,
			"floor": Vector2i(8, 8), "ceiling": Vector2i(8, 7), "fits": 0.6, "air": 0},
	{"layer": ^"Backdrop/Near", "depth": 1.0, "scale": Vector2(0.2, 0.4), "drawings": 6,
			"floor": Vector2i(4, 9), "ceiling": Vector2i(4, 9), "fits": 0.45, "air": 0},
]
## How far a rock sinks past its foot, the lowest drawn pixel, as a share of half its drawing (256 px at scale 1):
## into its floor, or, hanging, into its ceiling (measured there too).
const FLOOR_SINK: Vector2 = Vector2(0.11, 0.43)
const CEILING_SINK: Vector2 = Vector2(0.31, 0.8)
## How far a rock may be from the middle of its share of the run, as a share of that share.
const ROCK_JITTER: float = 0.3
## The same rocks each time the art is laid.
const ROCK_SEED: int = 3

## Where phase 3's grid goes on level 1's, in tiles.
var _offset: Vector2i = Vector2i.ZERO
## Phase 3's gates by their digit, once made.
var _gates: Dictionary[String, Gate] = {}
var _problems: PackedStringArray = PackedStringArray()
## What --reshape changed, for its last line.
var _summary: String = ""


func _init() -> void:
	super()
	_map_path = PHASE_3_MAP_PATH


func _initialize() -> void:
	if not _load_phase_3():
		quit(1)
		return
	var level: Node2D = (load(_scene_path) as PackedScene).instantiate(EDIT_STATE) as Node2D
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	var art_only: bool = arguments.has(ART_ARGUMENT)
	var reshape_at: int = arguments.find(RESHAPE_ARGUMENT)
	if level.has_node(PHASE_3_SAVE) and not art_only and reshape_at < 0:
		printerr("add_level1_phase3.gd: %s already has phase 3 (%s), so nothing was added. Lay only its art with -- %s."
				% [_scene_path, PHASE_3_SAVE, ART_ARGUMENT])
		level.free()
		quit(1)
		return
	if reshape_at >= 0:
		if not level.has_node(PHASE_3_SAVE) or reshape_at + 1 >= arguments.size():
			_problems.append("-- %s needs a scene with phase 3 and the old map's path after it" % RESHAPE_ARGUMENT)
		else:
			_reshape(level, arguments[reshape_at + 1])
	elif art_only:
		_lay_art_only(level)
	else:
		_add_phase_3(level)
	if not _problems.is_empty():
		for problem: String in _problems:
			printerr("add_level1_phase3.gd: %s" % problem)
		printerr("add_level1_phase3.gd: nothing was saved.")
		level.free()
		quit(1)
		return
	var packed: PackedScene = PackedScene.new()
	var error: Error = packed.pack(level)
	if error == OK:
		error = ResourceSaver.save(packed, _scene_path)
	level.free()
	if error != OK:
		printerr("add_level1_phase3.gd: not saved (%s)" % error_string(error))
		quit(1)
		return
	if reshape_at >= 0:
		print("Reshaped phase 3 in %s: %s" % [_scene_path, _summary])
	elif art_only:
		print("Laid phase 3's art in %s" % _scene_path)
	else:
		print("Added phase 3 to %s: %d x %d tiles at %s" % [_scene_path, _width, _height, _offset])
	quit(0)


## Reads level1_phase3.txt: its "key: value" lines, then its grid after the --- line.
func _load_phase_3() -> bool:
	if not FileAccess.file_exists(_map_path):
		printerr("add_level1_phase3.gd: no file at %s" % _map_path)
		return false
	var in_grid: bool = false
	for line: String in FileAccess.get_file_as_string(_map_path).split("\n"):
		line = line.strip_edges(false, true)
		if not in_grid:
			if line.strip_edges() == GRID_START:
				in_grid = true
			elif line.contains(":") and not line.get_slice(":", 0).contains(" "):
				_entries.append(PackedStringArray([line.get_slice(":", 0).strip_edges(),
						line.substr(line.find(":") + 1).strip_edges()]))
		elif not line.is_empty():
			for character: String in line:
				if not PHASE_3_LEGEND.contains(character):
					printerr("add_level1_phase3.gd: '%s' is not in the legend %s" % [character, PHASE_3_LEGEND])
					return false
			_rows.append(line)
			_width = maxi(_width, line.length())
	_height = _rows.size()
	var offset: PackedStringArray = _value_of("offset").split(" ", false)
	if _height == 0 or offset.size() != 2:
		printerr("add_level1_phase3.gd: needs an offset line and a grid after a %s line" % GRID_START)
		return false
	_offset = Vector2i(offset[0].to_int(), offset[1].to_int())
	return true


func _add_phase_3(level: Node2D) -> void:
	var tiles: TileMapLayer = level.get_node(^"Tiles") as TileMapLayer
	var player: Player = level.get_node(^"Player") as Player
	var before: TileMapLayer = tiles.duplicate() as TileMapLayer
	_carve(tiles)
	_open_the_room_after_phase_2(tiles)
	_take_away_stones_across(level, _box_of("door"))
	_lay_rim(level, before)
	_add_rocks(level, before)
	before.free()
	_add_gates(level.get_node(^"Gates"), tiles)
	_add_collapsing_platforms(level.get_node(^"CollapsingPlatforms"))
	_add_spikes(level.get_node(^"Spikes"))
	var dogs: Array[Demon] = _add_dogs(level.get_node(^"Dogs"))
	_add_unlockers(level.get_node(^"GateUnlockers"))
	for value: String in _values_of("zone"):
		var zone: Area2D = _zone(value)
		level.get_node(^"CameraZones").add_child(zone)
		_own(zone, level)
	var view: Node = level.get_node(^"DemonDebugView")
	var shown: Array[Demon] = view.get("demons")
	shown.append_array(dogs)
	view.set("demons", shown)
	var save: PackedStringArray = _value_of("save").split(" ", false)
	var point: Area2D = _save_point(PHASE_3_SAVE, PHASE_3_REACHED_EVENT, Vector2i(save[0].to_int(), save[1].to_int()),
			Vector2i(save[2].to_int(), save[3].to_int()), _find("P")[0] + _offset, player)
	level.add_child(point)
	# Before the camera, as the other save points, so the camera starts where the man does.
	level.move_child(point, level.get_node(^"GameCamera").get_index())
	_own(point, level)
	(level.get_node(^"PhaseExit") as Node2D).position = _feet(_find("F")[0] + _offset)


## Phase 3's air and platforms, each over a tile of rock.
func _carve(tiles: TileMapLayer) -> void:
	for row: int in _height:
		var line: String = _rows[row]
		for column: int in line.length():
			var character: String = line[column]
			if character == ROCK:
				continue
			var cell: Vector2i = Vector2i(column, row) + _offset
			if not _is_rock(tiles, cell):
				_problems.append("phase 3's tile %s would take level 1's %s, which is not rock" % [Vector2i(column, row), cell])
				continue
			if character == PLATFORM:
				tiles.set_cell(cell, TILE_SOURCE, TILE_ATLAS, ONE_WAY_ALTERNATIVE)
			else:
				tiles.erase_cell(cell)


## The new room at the end of phase 2, the door from phase 2's F room into it and the corridor on to phase 3's S.
func _open_the_room_after_phase_2(tiles: TileMapLayer) -> void:
	for key: String in ["room", "door", "corridor"]:
		var box: Rect2i = _box_of(key)
		for row: int in range(box.position.y, box.end.y):
			for column: int in range(box.position.x, box.end.x):
				var cell: Vector2i = Vector2i(column, row)
				if _is_rock(tiles, cell):
					tiles.erase_cell(cell)
				elif key != "door":
					_problems.append("the %s's tile %s is not rock" % [key, cell])


## A line "first_column first_row end_column end_row" as a box of tiles on level 1's grid.
func _box_of(key: String) -> Rect2i:
	var words: PackedStringArray = _value_of(key).split(" ", false)
	var first: Vector2i = Vector2i(words[0].to_int(), words[2].to_int())
	var end: Vector2i = Vector2i(words[1].to_int(), words[3].to_int())
	return Rect2i(first, end - first)


func _is_rock(tiles: TileMapLayer, cell: Vector2i) -> bool:
	return tiles.get_cell_source_id(cell) == TILE_SOURCE and tiles.get_cell_alternative_tile(cell) == ROCK_ALTERNATIVE


## The rim's stones that would stand across box, a door cut through a wall that had them: taken away.
func _take_away_stones_across(level: Node, box: Rect2i) -> void:
	var rim: Node = level.get_node_or_null(^"Art/StoneRim")
	if rim == null:
		return
	var door: Rect2 = Rect2(Vector2(box.position) * TILE, Vector2(box.size) * TILE)
	for stone: Node in rim.get_children():
		var sprite: Sprite2D = stone as Sprite2D
		if sprite != null and (sprite.get_transform() * sprite.get_rect()).intersects(door):
			rim.remove_child(sprite)
			sprite.free()


## Phase 3's art, in a scene that already has phase 3. The tiles before it are the ones now with phase 3's air and
## platforms, the room, the door and the corridor back to rock, as they all were when phase 3 was added.
func _lay_art_only(level: Node) -> void:
	var rim: Node = level.get_node_or_null(RIM_PATH)
	if rim == null:
		_problems.append("the scene has no %s" % RIM_PATH)
		return
	var art: Array[Node] = rim.get_children()
	for layer: Dictionary in ROCK_LAYERS:
		art.append_array(level.get_node(layer["layer"] as NodePath).get_children())
	for piece: Node in art:
		if piece.name.begins_with(PREFIX):
			_problems.append("phase 3's art is already laid (%s)" % piece.name)
			return
	var tiles: TileMapLayer = level.get_node(^"Tiles") as TileMapLayer
	var before: TileMapLayer = tiles.duplicate() as TileMapLayer
	for row: int in _height:
		var line: String = _rows[row]
		for column: int in line.length():
			if line[column] != ROCK:
				before.set_cell(Vector2i(column, row) + _offset, TILE_SOURCE, TILE_ATLAS, ROCK_ALTERNATIVE)
	for key: String in ["room", "door", "corridor"]:
		var box: Rect2i = _box_of(key)
		for row: int in range(box.position.y, box.end.y):
			for column: int in range(box.position.x, box.end.x):
				before.set_cell(Vector2i(column, row), TILE_SOURCE, TILE_ATLAS, ROCK_ALTERNATIVE)
	_lay_rim(level, before)
	_add_rocks(level, before)
	before.free()


## Changes phase 3, already in the scene, from the map it was laid from (old_map_path: level1_phase3.txt as it was
## then) to the map now, where the two differ and only there: the tiles, the floor spikes and the camera zones, each
## only while it is still as the old map laid it; then the rim's stones and the loose rocks where the rock's outline
## changed, as when phase 3 was added. What was edited by hand anywhere else stays as it is. Where the maps differ in
## anything else, such as a dog or a gate, it changes nothing, and nothing is saved.
func _reshape(level: Node2D, old_map_path: String) -> void:
	var old_rows: PackedStringArray = PackedStringArray()
	var old_zones: Dictionary[String, String] = {}
	if not FileAccess.file_exists(old_map_path):
		_problems.append("no old map at %s" % old_map_path)
		return
	var in_grid: bool = false
	for line: String in FileAccess.get_file_as_string(old_map_path).split("\n"):
		line = line.strip_edges(false, true)
		if line.strip_edges() == GRID_START:
			in_grid = true
		elif in_grid:
			if not line.is_empty():
				old_rows.append(line)
		elif line.begins_with("zone:"):
			var old_value: String = line.substr(line.find(":") + 1).strip_edges()
			old_zones[old_value.get_slice(" ", 0)] = old_value
	if old_rows.size() != _height:
		_problems.append("the old map has %d rows, the map now %d" % [old_rows.size(), _height])
		return
	var tiles: TileMapLayer = level.get_node(^"Tiles") as TileMapLayer
	var before: TileMapLayer = tiles.duplicate() as TileMapLayer
	var tiles_changed: int = 0
	for row: int in _height:
		for column: int in _width:
			var was: String = old_rows[row][column]
			var now: String = _rows[row][column]
			if was == now:
				continue
			if not RESHAPED.contains(was) or not RESHAPED.contains(now):
				_problems.append("the maps differ at %s ('%s', now '%s'): only tiles and floor spikes are reshaped"
						% [Vector2i(column, row), was, now])
				continue
			if _map_kind(was) == _map_kind(now):
				continue
			var cell: Vector2i = Vector2i(column, row) + _offset
			if _tile_kind(tiles, cell) != _map_kind(was):
				_problems.append("level 1's tile %s is no longer as the old map laid it" % cell)
				continue
			if _map_kind(now) == TileKind.EMPTY:
				tiles.erase_cell(cell)
			else:
				tiles.set_cell(cell, TILE_SOURCE, TILE_ATLAS,
						ROCK_ALTERNATIVE if _map_kind(now) == TileKind.ROCK else ONE_WAY_ALTERNATIVE)
			tiles_changed += 1
	var spikes_changed: int = _reshape_floor_spikes(level.get_node(^"Spikes"), old_rows)
	var zones_changed: int = _reshape_zones(level, old_zones)
	var stones: Vector2i = _lay_rim(level, before)
	var rocks: Vector2i = _redo_rocks(level, before)
	before.free()
	_summary = ("%d tiles, %d floor spikes and %d camera zones changed; %d rim stones taken away and %d laid; "
			+ "%d loose rocks taken away and %d laid") % [tiles_changed, spikes_changed, zones_changed, stones.x,
			stones.y, rocks.x, rocks.y]


## TileKind of a character of the map.
func _map_kind(character: String) -> TileKind:
	if character == ROCK:
		return TileKind.ROCK
	if character == PLATFORM:
		return TileKind.PLATFORM
	return TileKind.EMPTY


## TileKind of level 1's tile at cell.
func _tile_kind(tiles: TileMapLayer, cell: Vector2i) -> TileKind:
	if tiles.get_cell_source_id(cell) == -1:
		return TileKind.EMPTY
	if tiles.get_cell_source_id(cell) != TILE_SOURCE:
		return TileKind.OTHER
	match tiles.get_cell_alternative_tile(cell):
		ROCK_ALTERNATIVE:
			return TileKind.ROCK
		ONE_WAY_ALTERNATIVE:
			return TileKind.PLATFORM
	return TileKind.OTHER


## The floor spikes of the old map's grid (old_rows) that the map now no longer has, made into the ones it has
## instead, each only while it is still as the old map laid it. How many strips changed.
func _reshape_floor_spikes(group: Node, old_rows: PackedStringArray) -> int:
	var rows_now: PackedStringArray = _rows
	# _runs reads _rows: the old grid for a moment.
	_rows = old_rows
	var old_runs: Array[Rect2i] = _runs(SPIKES)
	_rows = rows_now
	var new_runs: Array[Rect2i] = _runs(SPIKES)
	var spare: Array[LethalSpikes] = []
	for run: Rect2i in old_runs:
		if new_runs.has(run):
			continue
		var found: LethalSpikes = null
		for child: Node in group.get_children():
			var spikes: LethalSpikes = child as LethalSpikes
			if spikes != null and spikes.width_tiles == run.size.x and is_zero_approx(spikes.rotation) \
					and spikes.position.is_equal_approx(_floor_spikes_position(run)):
				found = spikes
		if found == null:
			_problems.append("the floor spikes at %s are no longer as the old map laid them" % run)
		else:
			spare.append(found)
	var changed: int = 0
	for run: Rect2i in new_runs:
		if old_runs.has(run):
			continue
		var spikes: LethalSpikes = spare.pop_front() if not spare.is_empty() else _spikes(group, run.size.x)
		spikes.width_tiles = run.size.x
		spikes.position = _floor_spikes_position(run)
		changed += 1
	for spikes: LethalSpikes in spare:
		group.remove_child(spikes)
		spikes.free()
		changed += 1
	return changed


## Where floor spikes over run, on phase 3's grid, stand on level 1's: the middle of the floor under them.
func _floor_spikes_position(run: Rect2i) -> Vector2:
	return Vector2((run.position.x + _offset.x + run.size.x / 2.0) * TILE, (run.position.y + _offset.y + 1) * TILE)


## The camera zones whose line changed from the old map (old_zones, each line by the zone's name) laid again from the
## map now, in their place, each only while it is still as its old line laid it. How many changed.
func _reshape_zones(level: Node, old_zones: Dictionary[String, String]) -> int:
	var group: Node = level.get_node(^"CameraZones")
	var changed: int = 0
	var names: Dictionary[String, bool] = {}
	for value: String in _values_of("zone"):
		var zone_name: String = value.get_slice(" ", 0)
		names[zone_name] = true
		var old_value: String = old_zones.get(zone_name, "")
		if old_value == value:
			continue
		var zone: Area2D = _zone(value)
		var saved: Area2D = group.get_node_or_null(NodePath(zone.name)) as Area2D
		if old_value.is_empty() or saved == null or not _zone_is_as(saved, old_value):
			_problems.append("the camera zone %s is new or no longer as the old map laid it" % zone.name)
			zone.free()
			continue
		var index: int = saved.get_index()
		group.remove_child(saved)
		saved.free()
		group.add_child(zone)
		group.move_child(zone, index)
		_own(zone, level)
		changed += 1
	for zone_name: String in old_zones:
		if not names.has(zone_name):
			_problems.append("the camera zone %s is gone from the map: take it away by hand" % zone_name)
	return changed


## Whether zone is still as the zone line value lays it: its rectangle and each value the line sets.
func _zone_is_as(zone: Area2D, value: String) -> bool:
	var laid: Area2D = _zone(value)
	var shape: CollisionShape2D = zone.get_node_or_null(^"CollisionShape2D") as CollisionShape2D
	var laid_shape: CollisionShape2D = laid.get_node(^"CollisionShape2D") as CollisionShape2D
	var same: bool = shape != null and shape.shape is RectangleShape2D \
			and shape.position.is_equal_approx(laid_shape.position) \
			and (shape.shape as RectangleShape2D).size.is_equal_approx((laid_shape.shape as RectangleShape2D).size)
	for word: String in value.split(" ", false).slice(5):
		var key: String = word.get_slice("=", 0)
		same = same and is_equal_approx(float(zone.get(key)), float(laid.get(key)))
	laid.free()
	return same


## Phase 3's loose rocks again where its floors and ceilings changed: the rocks of a run of floor or ceiling that is no
## longer there, with the same row and ends, are taken away, and each run there now that was not gets rocks as
## _add_rocks lays them. How many were taken away and how many laid.
func _redo_rocks(level: Node, before: TileMapLayer) -> Vector2i:
	var tiles: TileMapLayer = level.get_node(^"Tiles") as TileMapLayer
	var box: Rect2i = Rect2i(_offset, Vector2i(_width, _height))
	var new_only: Array[Array] = []
	var taken: int = 0
	for hanging: bool in [false, true]:
		var old_runs: Array[Vector3i] = _surface_runs(before, box, hanging)
		var new_runs: Array[Vector3i] = _surface_runs(tiles, box, hanging)
		var come: Array[Vector3i] = []
		for run: Vector3i in new_runs:
			if not old_runs.has(run):
				come.append(run)
		new_only.append(come)
		for run: Vector3i in old_runs:
			if new_runs.has(run):
				continue
			for layer: Dictionary in ROCK_LAYERS:
				var group: Node = level.get_node(layer["layer"] as NodePath)
				for child: Node in group.get_children():
					var rock: ParallaxSprite = child as ParallaxSprite
					if rock != null and rock.flip_v == hanging and _sits_on(rock, run, hanging):
						group.remove_child(rock)
						rock.free()
						taken += 1
	var floors: Array[Vector3i] = []
	floors.assign(new_only[0])
	var ceilings: Array[Vector3i] = []
	ceilings.assign(new_only[1])
	return Vector2i(taken, _lay_rocks(level, floors, ceilings))


## Every run of rock in box with air over it, or, hanging, under it, as (row, first column, last column).
func _surface_runs(layer: TileMapLayer, box: Rect2i, hanging: bool) -> Array[Vector3i]:
	var toward_air: Vector2i = Vector2i.DOWN if hanging else Vector2i.UP
	var runs: Array[Vector3i] = []
	for row: int in range(box.position.y, box.end.y):
		var first: int = -1
		for column: int in range(box.position.x, box.end.x + 1):
			var cell: Vector2i = Vector2i(column, row)
			var surface: bool = column < box.end.x and _is_rock(layer, cell) and not _is_rock(layer, cell + toward_air)
			if surface and first < 0:
				first = column
			elif not surface and first >= 0:
				runs.append(Vector3i(row, first, column - 1))
				first = -1
	return runs


## Whether rock was laid on run: its ends are the run's and it is near the run's floor, or, hanging, its ceiling.
func _sits_on(rock: ParallaxSprite, run: Vector3i, hanging: bool) -> bool:
	var surface: float = (run.x + 1) * TILE if hanging else run.x * TILE
	return is_equal_approx(rock.min_x, run.y * TILE) and is_equal_approx(rock.max_x, (run.z + 1) * TILE) \
			and absf(rock.position.y - surface) < ROCK_REACH


## wanted, or, when parent already has a child by that name, the name with the number after the highest there.
func _free_name(parent: Node, wanted: String) -> String:
	if not parent.has_node(NodePath(wanted)):
		return wanted
	var base: String = wanted.rstrip("0123456789")
	return "%s%d" % [base, _last_number(parent, base) + 1]


## The highest number after base in the names of parent's children, or 0.
func _last_number(parent: Node, base: String) -> int:
	var highest: int = 0
	for child: Node in parent.get_children():
		var child_name: String = child.name
		if child_name.begins_with(base) and child_name.trim_prefix(base).is_valid_int():
			highest = maxi(highest, child_name.trim_prefix(base).to_int())
	return highest


## Lays the rim's stones where phase 3 changed the rock's outline, and only there: the stones a rim laid from the
## tiles now has and one laid from the tiles before would not, named with P3 in front, each after the last stone of
## its kind. The stones only the rim before would have, such as a wall's across the door, are taken away when they
## are still as it laid them. The rest, edited by hand, stay as they are. How many were taken away and how many laid.
func _lay_rim(level: Node, before: TileMapLayer) -> Vector2i:
	var rim: StoneRim = level.get_node_or_null(RIM_PATH) as StoneRim
	if rim == null:
		return Vector2i.ZERO
	var taken: int = 0
	var laid_count: int = 0
	var old_keys: Dictionary[String, bool] = {}
	for stone: Sprite2D in _stones_laid_from(rim, before):
		old_keys[_stone_key(stone)] = true
		stone.free()
	var laid: Array[Sprite2D] = _stones_laid_from(rim, level.get_node(^"Tiles") as TileMapLayer)
	var new_keys: Dictionary[String, bool] = {}
	for stone: Sprite2D in laid:
		new_keys[_stone_key(stone)] = true
	# The fade materials the saved stones share, so a new stone alike shares one instead of bringing its own.
	var materials: Dictionary[String, ShaderMaterial] = {}
	for child: Node in rim.get_children():
		var saved: Sprite2D = child as Sprite2D
		if saved == null:
			continue
		if saved.material is ShaderMaterial:
			materials[_material_key(saved.material as ShaderMaterial)] = saved.material as ShaderMaterial
		var key: String = _stone_key(saved)
		if old_keys.has(key) and not new_keys.has(key):
			rim.remove_child(saved)
			saved.free()
			taken += 1
	var by_kind: Dictionary[String, Array] = {}
	for stone: Sprite2D in laid:
		if old_keys.has(_stone_key(stone)):
			stone.free()
			continue
		var fade: ShaderMaterial = stone.material as ShaderMaterial
		var material_key: String = _material_key(fade)
		if materials.has(material_key):
			stone.material = materials[material_key]
		else:
			materials[material_key] = fade
		var kind: String = _kind_of(stone)
		if not by_kind.has(kind):
			by_kind[kind] = []
		by_kind[kind].append(stone)
	for kind: String in STONE_KINDS:
		if not by_kind.has(kind):
			continue
		var after: Node = _last_of_kind(rim, kind)
		for stone: Sprite2D in by_kind[kind]:
			stone.name = _free_name(rim, PREFIX + stone.name)
			if after == null:
				rim.add_child(stone)
			else:
				after.add_sibling(stone)
			stone.owner = level
			after = stone
			laid_count += 1
	return Vector2i(taken, laid_count)


## The stones a rim set as the level's would lay from layer's tiles, laid out of the tree and handed over.
func _stones_laid_from(rim: StoneRim, layer: TileMapLayer) -> Array[Sprite2D]:
	var model: StoneRim = StoneRim.new()
	for property: Dictionary in rim.get_property_list():
		var usage: int = property["usage"]
		if usage & PROPERTY_USAGE_SCRIPT_VARIABLE and usage & PROPERTY_USAGE_STORAGE:
			model.set(property["name"], rim.get(property["name"]))
	model.auto_build = false
	model.tiles = layer
	model.rebuild()
	var stones: Array[Sprite2D] = []
	for child: Node in model.get_children():
		model.remove_child(child)
		stones.append(child as Sprite2D)
	model.free()
	return stones


## What a stone looks like and where: the same for a stone laid from the same outline, laid now or before.
func _stone_key(stone: Sprite2D) -> String:
	var region: Rect2 = stone.region_rect if stone.region_enabled else Rect2()
	return "%s %.2f %.2f %.4f %.4f %.2f %.2f %.2f %.2f %.2f %.2f %s" % [stone.texture.resource_path,
			stone.position.x, stone.position.y, stone.rotation, stone.scale.x, stone.offset.x, stone.offset.y,
			region.position.x, region.position.y, region.size.x, region.size.y, stone.flip_v]


func _material_key(fade: ShaderMaterial) -> String:
	if fade == null:
		return ""
	var corner: Vector2 = fade.get_shader_parameter(&"corner_point")
	return "%d %.3f %.3f %.3f %.3f %.3f" % [int(fade.get_shader_parameter(&"mode")),
			float(fade.get_shader_parameter(&"surface_row")), corner.x, corner.y,
			float(fade.get_shader_parameter(&"fade_length")), float(fade.get_shader_parameter(&"min_brightness"))]


## LeftWall, RightWall, Ceiling, Floor or Corner, from the name the rim gave the stone.
func _kind_of(stone: Node) -> String:
	var kind: String = String(stone.name).trim_prefix(PREFIX).rstrip("0123456789")
	return "Corner" if kind.ends_with("Corner") else kind


func _last_of_kind(rim: Node, kind: String) -> Node:
	for index: int in range(rim.get_child_count() - 1, -1, -1):
		var stone: Node = rim.get_child(index)
		if _kind_of(stone) == kind:
			return stone
	return null


## The backdrop's loose rocks on the floors and ceilings phase 3 opened.
func _add_rocks(level: Node, before: TileMapLayer) -> void:
	var tiles: TileMapLayer = level.get_node(^"Tiles") as TileMapLayer
	_lay_rocks(level, _opened_runs(tiles, before, false), _opened_runs(tiles, before, true))


## The backdrop's loose rocks on floors and on ceilings, runs as (row, first column, last column). Each layer cuts a
## run into even shares, one rock a little off the middle of each, sunk a little into the rock, and lets each slide
## only between the run's ends. Each is named with the number after the last of its kind in its layer. How many.
func _lay_rocks(level: Node, floors: Array[Vector3i], ceilings: Array[Vector3i]) -> int:
	var tiles: TileMapLayer = level.get_node(^"Tiles") as TileMapLayer
	var laid: int = 0
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = ROCK_SEED
	var drawings: Array[Texture2D] = []
	# From each drawing's middle down to the rock's foot, and the rock's own height, in the drawing's px.
	var feet: PackedFloat32Array = PackedFloat32Array()
	var heights: PackedFloat32Array = PackedFloat32Array()
	for path: String in ROCK_DRAWINGS:
		drawings.append(load(path) as Texture2D)
		var image: Image = Image.load_from_file(ProjectSettings.globalize_path(path))
		var used: Rect2i = image.get_used_rect()
		feet.append(used.end.y - image.get_height() / 2.0)
		heights.append(used.size.y)
	var numbers: Dictionary[String, int] = {}
	for hanging: bool in [false, true]:
		var away: Vector2i = Vector2i.DOWN if hanging else Vector2i.UP
		var sink: Vector2 = CEILING_SINK if hanging else FLOOR_SINK
		var kind: String = "CeilingRock" if hanging else "Rock"
		for run: Vector3i in ceilings if hanging else floors:
			var length: int = run.z - run.y + 1
			var surface: float = (run.x + 1) * TILE if hanging else run.x * TILE
			for layer: Dictionary in ROCK_LAYERS:
				var limits: Vector2i = layer["ceiling" if hanging else "floor"]
				if length < limits.x:
					continue
				var group: Node = level.get_node(layer["layer"] as NodePath)
				var size: Vector2 = layer["scale"]
				var count: int = maxi(1, roundi(float(length) / limits.y))
				var share: float = length * TILE / count
				for index: int in count:
					var x: float = run.y * TILE + share * (index + 0.5 + random.randf_range(-ROCK_JITTER, ROCK_JITTER))
					var drawing: int = random.randi_range(0, int(layer["drawings"]) - 1)
					var air: int = _air_from(tiles, Vector2i(floori(x / TILE), run.x), away)
					if air < int(layer["air"]):
						continue
					var rock_scale: float = minf(random.randf_range(size.x, size.y),
							float(layer["fits"]) * air * TILE / heights[drawing])
					var foot: float = feet[drawing] * rock_scale
					var sunk: float = random.randf_range(sink.x, sink.y) * drawings[drawing].get_height() / 2.0 * rock_scale
					var rock: ParallaxSprite = ParallaxSprite.new()
					rock.texture = drawings[drawing]
					rock.use_parent_material = true
					rock.flip_h = random.randf() < 0.5
					# Hanging, the drawing is turned upside down, so its foot is at the top, in the ceiling.
					rock.flip_v = hanging
					rock.scale = Vector2(rock_scale, rock_scale)
					rock.position = Vector2(x, surface + foot - sunk if hanging else surface - foot + sunk)
					rock.depth = layer["depth"]
					rock.min_x = run.y * TILE
					rock.max_x = (run.z + 1) * TILE
					var key: String = "%s %s" % [layer["layer"], kind]
					if not numbers.has(key):
						numbers[key] = _last_number(group, PREFIX + kind)
					numbers[key] += 1
					rock.name = "%s%s%d" % [PREFIX, kind, numbers[key]]
					group.add_child(rock)
					rock.owner = level
					laid += 1
	return laid


## Runs of rock, as (row, first column, last column), under air phase 3 opened, or, hanging, over it.
func _opened_runs(tiles: TileMapLayer, before: TileMapLayer, hanging: bool) -> Array[Vector3i]:
	var toward_rock: Vector2i = Vector2i.UP if hanging else Vector2i.DOWN
	var by_row: Dictionary[int, Array] = {}
	for cell: Vector2i in before.get_used_cells():
		if not _is_rock(before, cell) or _is_rock(tiles, cell) or not _is_rock(tiles, cell + toward_rock):
			continue
		if not by_row.has(cell.y + toward_rock.y):
			by_row[cell.y + toward_rock.y] = []
		by_row[cell.y + toward_rock.y].append(cell.x)
	var runs: Array[Vector3i] = []
	for row: int in by_row:
		var columns: Array = by_row[row]
		columns.sort()
		var first: int = columns[0]
		for index: int in range(1, columns.size() + 1):
			if index == columns.size() or columns[index] != columns[index - 1] + 1:
				runs.append(Vector3i(row, first, columns[index - 1]))
				if index < columns.size():
					first = columns[index]
	runs.sort()
	return runs


## How many tiles of air there are from cell, rock, going away from it, up to the height of a tall room.
func _air_from(tiles: TileMapLayer, cell: Vector2i, away: Vector2i) -> int:
	const TALLEST: int = 40
	var air: int = 0
	var next: Vector2i = cell + away
	while air < TALLEST and not _is_rock(tiles, next):
		air += 1
		next += away
	return air


func _add_gates(group: Node, tiles: TileMapLayer) -> void:
	var ways: Dictionary[String, Gate.SlideWay] = {}
	for value: String in _values_of("gate"):
		ways[value.get_slice(" ", 0)] = SLIDE_WAYS[value.get_slice(" ", 1)]
	for digit: String in GATE_DIGITS:
		var cells: Array[Vector2i] = _find(digit)
		var box: Rect2i = Rect2i(cells[0], Vector2i.ONE)
		for cell: Vector2i in cells:
			box = box.expand(cell).expand(cell + Vector2i.ONE)
		box.position += _offset
		var gate: Gate = GATE_SCENE.instantiate(EDIT_STATE) as Gate
		gate.name = "%sGate%s" % [PREFIX, digit]
		gate.position = Vector2((box.position.x + box.size.x / 2.0) * TILE, box.end.y * TILE)
		gate.width_tiles = box.size.x
		gate.height_tiles = box.size.y
		gate.slide_way = ways[digit]
		var slid: Rect2i = Rect2i(box.position + Vector2i(gate.slide_offset() / TILE), box.size)
		for row: int in range(slid.position.y, slid.end.y):
			for column: int in range(slid.position.x, slid.end.x):
				if not _is_rock(tiles, Vector2i(column, row)):
					_problems.append("%s would slide onto %s, which is not rock" % [gate.name, Vector2i(column, row)])
		group.add_child(gate)
		gate.owner = group.owner
		_gates[digit] = gate


func _add_collapsing_platforms(group: Node) -> void:
	for run: Rect2i in _runs(COLLAPSING):
		var platform: CollapsingPlatform = COLLAPSING_SCENE.instantiate(EDIT_STATE) as CollapsingPlatform
		platform.name = "%sCollapsing%d" % [PREFIX, group.get_child_count() + 1]
		platform.position = Vector2(run.position + _offset) * TILE
		platform.width_tiles = run.size.x
		group.add_child(platform)
		platform.owner = group.owner


## Spikes on floors, as everywhere, and on walls: the same strip turned a quarter round, its base on the wall.
func _add_spikes(group: Node) -> void:
	for run: Rect2i in _runs(SPIKES):
		var spikes: LethalSpikes = _spikes(group, run.size.x)
		spikes.position = _floor_spikes_position(run)
	for character: String in [WALL_SPIKES_LEFT, WALL_SPIKES_RIGHT]:
		var rock_on_the_left: bool = character == WALL_SPIKES_LEFT
		for run: Rect2i in _column_runs(character):
			var spikes: LethalSpikes = _spikes(group, run.size.y)
			var face: float = (run.position.x + _offset.x + (0 if rock_on_the_left else 1)) * TILE
			spikes.position = Vector2(face, (run.position.y + _offset.y + run.size.y / 2.0) * TILE)
			# The teeth point up; a quarter round to the right points them right, away from rock on the left.
			spikes.rotation = PI / 2.0 if rock_on_the_left else -PI / 2.0


func _spikes(group: Node, width: int) -> LethalSpikes:
	var spikes: LethalSpikes = SPIKES_SCENE.instantiate(EDIT_STATE) as LethalSpikes
	spikes.name = _free_name(group, "%sSpikes%d" % [PREFIX, group.get_child_count() + 1])
	spikes.width_tiles = width
	group.add_child(spikes)
	spikes.owner = group.owner
	return spikes


func _add_dogs(group: Node) -> Array[Demon]:
	var added: Array[Demon] = []
	for post: Vector2i in _find(DOG + BIGGEST_DOG):
		var is_biggest: bool = _rows[post.y][post.x] == BIGGEST_DOG
		var dog: Demon = (BIGGEST_DOG_SCENE if is_biggest else DOG_SCENE).instantiate(EDIT_STATE) as Demon
		dog.name = "%sBiggestDog" % PREFIX if is_biggest else "%sDog%d" % [PREFIX, added.size() + 1]
		dog.position = _feet(post + _offset)
		# Each faces phase 3's middle; the biggest faces the way the man comes, from the left.
		dog.faces_left = is_biggest or post.x > _width / 2
		if is_biggest:
			var opens: Array[Gate] = [_gates[_value_of("biggest")]]
			dog.set("opens", opens)
		group.add_child(dog)
		dog.owner = group.owner
		added.append(dog)
	return added


func _add_unlockers(group: Node) -> void:
	for value: String in _values_of("unlocker"):
		var letter: String = value.get_slice(" ", 0)
		var opens: Array[Gate] = [_gates[value.get_slice(" ", 1)]]
		var unlocker: GateUnlocker = UNLOCKER_SCENE.instantiate(EDIT_STATE) as GateUnlocker
		unlocker.name = "%sUnlocker%d" % [PREFIX, UNLOCKER_LETTERS.find(letter) + 1]
		unlocker.position = _feet(_find(letter)[0] + _offset)
		unlocker.gates = opens
		group.add_child(unlocker)
		unlocker.owner = group.owner


## The runs of character down each column, one tile wide.
func _column_runs(character: String) -> Array[Rect2i]:
	var runs: Array[Rect2i] = []
	for column: int in _width:
		var row: int = 0
		while row < _height:
			if column >= _rows[row].length() or _rows[row][column] != character:
				row += 1
				continue
			var first: int = row
			while row < _height and column < _rows[row].length() and _rows[row][column] == character:
				row += 1
			runs.append(Rect2i(column, first, 1, row - first))
	return runs
