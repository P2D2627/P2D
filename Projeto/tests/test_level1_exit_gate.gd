# Checks the gate that shuts level 1's way out until the man has gone the way back round (#271, phase C): gate 4,
# under the pillar between the biggest dog's post and F, as the map lays it, shut at the start; with it shut, the
# map's air from the dog's post never reaches F, and with it open it does, so there is no way round it; its
# unlocker stands on the floor of the corridor behind gate 3, between the well and the chimney, as the map lays
# it, and opens gate 4 only; and using it opens the gate.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_level1_exit_gate.gd
extends "res://tests/support/player_test.gd"

const LEVEL_PATH: String = "res://scenes/levels/lust/level1.tscn"
const PHASE_3_MAP: String = "res://scenes/levels/lust/builders/level1_phase3.txt"
const GATE_PATH: NodePath = ^"Gates/P3Gate4"
const UNLOCKER_PATH: NodePath = ^"GateUnlockers/P3Unlocker3"
const DOG_PATH: NodePath = ^"Dogs/P3BiggestDog"
const TILE: float = 48.0
## The map's characters for the exit gate, its unlocker, the biggest dog, the way out and rock.
const GATE: String = "4"
const UNLOCKER: String = "w"
const BIGGEST: String = "G"
const WAY_OUT: String = "F"
const ROCK: String = "#"
## The corridor behind gate 3 between the well and the chimney: its floor's top, and the x of the well's east
## wall and of the chimney's west side.
const CORRIDOR_FLOOR: float = 8832.0
const WELL_EAST: float = 5664.0
const CHIMNEY_WEST: float = 6912.0
## Frames for the gate to open once the unlocker is used.
const OPEN_FRAMES: int = 120
const SETTLE_FRAMES: int = 5

var _offset: Vector2i = Vector2i.ZERO
var _map: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	_read_map()
	var level: Node = (load(LEVEL_PATH) as PackedScene).instantiate()
	root.add_child(level)
	await wait_frames(SETTLE_FRAMES)
	var results: Array[bool] = []
	results.append(_the_exit_gate_shuts_the_way_between_the_post_and_f(level))
	results.append(_there_is_no_way_round_it())
	results.append(_its_unlocker_is_in_the_corridor_behind_gate_3(level))
	results.append(await _using_the_unlocker_opens_it(level))
	level.queue_free()
	await wait_frames(2)
	finish(results)


func _the_exit_gate_shuts_the_way_between_the_post_and_f(level: Node) -> bool:
	var gate: Gate = level.get_node_or_null(GATE_PATH) as Gate
	if gate == null:
		return report(false, "Exit gate: %s is in the scene false" % GATE_PATH)
	var cells: Array[Vector2i] = _cells(GATE)
	var box: Rect2i = Rect2i(cells[0], Vector2i.ONE)
	for cell: Vector2i in cells:
		box = box.expand(cell).expand(cell + Vector2i.ONE)
	var laid: Vector2 = Vector2((box.position.x + box.size.x / 2.0) * TILE, box.end.y * TILE)
	var post_x: float = (level.get_node(DOG_PATH) as Node2D).global_position.x
	var out_x: float = (Vector2(_cells(WAY_OUT)[0]) * TILE).x
	var ok: bool = gate.position == laid and gate.width_tiles == box.size.x and gate.height_tiles == box.size.y \
			and post_x < gate.position.x and gate.position.x < out_x and not gate.is_unlocked()
	return report(ok, ("Exit gate: at %s, %d x %d tiles (the map: %s, %d x %d), between the post x %.0f and F x %.0f, "
			+ "shut %s") % [gate.position, gate.width_tiles, gate.height_tiles, laid, box.size.x, box.size.y,
			post_x, out_x, not gate.is_unlocked()])


func _there_is_no_way_round_it() -> bool:
	var start: Vector2i = _cells(BIGGEST)[0]
	var out: Vector2i = _cells(WAY_OUT)[0]
	var shut: bool = _flood(start, true).has(out)
	var open: bool = _flood(start, false).has(out)
	return report(not shut and open, "No way round: F reached from the post with gate 4 shut %s (false), open %s (true)"
			% [shut, open])


func _its_unlocker_is_in_the_corridor_behind_gate_3(level: Node) -> bool:
	var unlocker: GateUnlocker = level.get_node_or_null(UNLOCKER_PATH) as GateUnlocker
	var gate: Gate = level.get_node_or_null(GATE_PATH) as Gate
	if unlocker == null or gate == null:
		return report(false, "Exit gate's unlocker: %s and %s are in the scene false" % [UNLOCKER_PATH, GATE_PATH])
	var cell: Vector2i = _cells(UNLOCKER)[0]
	var laid: Vector2 = Vector2((cell.x + 0.5) * TILE, (cell.y + 1) * TILE)
	var at: Vector2 = unlocker.position
	var ok: bool = at == laid and is_equal_approx(at.y, CORRIDOR_FLOOR) and at.x > WELL_EAST and at.x < CHIMNEY_WEST \
			and unlocker.gates == [gate]
	return report(ok, ("Exit gate's unlocker: at %s (the map: %s), on the corridor's floor between the well and the "
			+ "chimney, opens %s (gate 4 only)") % [at, laid, unlocker.gates])


func _using_the_unlocker_opens_it(level: Node) -> bool:
	var unlocker: GateUnlocker = level.get_node_or_null(UNLOCKER_PATH) as GateUnlocker
	var gate: Gate = level.get_node_or_null(GATE_PATH) as Gate
	if unlocker == null or gate == null:
		return report(false, "Using the unlocker: %s and %s are in the scene false" % [UNLOCKER_PATH, GATE_PATH])
	unlocker.activate()
	var opened: bool = await wait_until(gate.is_unlocked, OPEN_FRAMES)
	return report(opened, "Using the unlocker: gate 4 open within %d frames %s" % [OPEN_FRAMES, opened])


func _read_map() -> void:
	var in_grid: bool = false
	for line: String in FileAccess.get_file_as_string(PHASE_3_MAP).split("\n"):
		line = line.strip_edges(false, true)
		if in_grid:
			if not line.is_empty():
				_map.append(line)
		elif line == "---":
			in_grid = true
		elif line.begins_with("offset:"):
			var words: PackedStringArray = line.get_slice(":", 1).split(" ", false)
			_offset = Vector2i(words[0].to_int(), words[1].to_int())


## Where the map has character, on level 1's grid.
func _cells(character: String) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for row: int in _map.size():
		for column: int in _map[row].length():
			if _map[row][column] == character:
				found.append(Vector2i(column, row) + _offset)
	return found


## The map's air reached from start, on level 1's grid, going across and up and down: anything but rock, and
## but gate 4 when gate_shut.
func _flood(start: Vector2i, gate_shut: bool) -> Dictionary[Vector2i, bool]:
	var reached: Dictionary[Vector2i, bool] = {start: true}
	var next: Array[Vector2i] = [start]
	while not next.is_empty():
		var cell: Vector2i = next.pop_back()
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var near: Vector2i = cell + step
			if reached.has(near):
				continue
			var at: Vector2i = near - _offset
			if at.y < 0 or at.y >= _map.size() or at.x < 0 or at.x >= _map[at.y].length():
				continue
			var character: String = _map[at.y][at.x]
			if character == ROCK or (gate_shut and character == GATE):
				continue
			reached[near] = true
			next.append(near)
	return reached
