# Checks level 1's phase 3 in the scene against its text map, level1_phase3.txt: the pieces it holds (dogs, the
# biggest dog, spikes on floors and walls, collapsing platforms, three gates, two unlockers); which gate each
# unlocker opens, and that the biggest dog opens gate 3; that with the gates shut no gate can be skipped (from S the
# air joins unlocker 1 and gate 2 only, past gate 2 it joins unlocker 2 and gate 1 only, past gate 1 it joins F); that
# each gate slides onto rock; that each wall's spikes have rock behind them; that the man near the biggest dog opens
# gate 3; and that the level's one way out is at phase 3's F.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_level1_phase3.gd
extends "res://tests/test_lust_phase_2.gd"

const LEVEL_PATH: String = "res://scenes/levels/lust/level1.tscn"
const PHASE_3_MAP: String = "res://scenes/levels/lust/level1_phase3.txt"
const PREFIX: String = "P3"
## Physics frames for the ring to see the man put inside it, and for nothing to happen while he is far.
const AREA_FRAMES: int = 5
## How far left of the biggest dog's middle the man is put, in px: inside the ring.
const NEAR_THE_BIGGEST: float = 600.0

var _offset: Vector2i = Vector2i.ZERO
var _map: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	await process_frame
	(root.get_node(^"GameState") as GameProgress).reset()
	_read_map()
	var level: Node = (load(LEVEL_PATH) as PackedScene).instantiate()
	root.add_child(level)
	await process_frame
	var tiles: TileMapLayer = level.get_node("Tiles") as TileMapLayer
	var results: Array[bool] = []
	results.append(_the_scene_holds_what_phase_3s_map_says(level))
	results.append(_each_gate_has_its_opener(level))
	results.append(_phase_3s_gates_cannot_be_skipped(level, tiles))
	results.append(_each_gate_slides_onto_rock(level, tiles))
	results.append(_wall_spikes_have_rock_behind(level, tiles))
	results.append(_the_way_out_is_at_phase_3s_f(level))
	results.append(await _the_man_near_the_biggest_dog_opens_gate_3(level))
	level.queue_free()
	finish(results)


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


func _count(text: String) -> int:
	var total: int = 0
	for character: String in text:
		total += _cells(character).size()
	return total


func _phase_3_children(level: Node, group: String) -> Array[Node]:
	var found: Array[Node] = []
	for node: Node in level.get_node(group).get_children():
		if String(node.name).begins_with(PREFIX):
			found.append(node)
	return found


func _the_scene_holds_what_phase_3s_map_says(level: Node) -> bool:
	var dogs: int = 0
	var biggest: int = 0
	for node: Node in _phase_3_children(level, "Dogs"):
		if node is BiggestDemon:
			biggest += 1
		else:
			dogs += 1
	var spike_tiles: int = 0
	for node: Node in _phase_3_children(level, "Spikes"):
		spike_tiles += (node as LethalSpikes).width_tiles
	var collapsing_tiles: int = 0
	for node: Node in _phase_3_children(level, "CollapsingPlatforms"):
		collapsing_tiles += (node as CollapsingPlatform).width_tiles
	var found: Array[int] = [dogs, biggest, spike_tiles, collapsing_tiles, _phase_3_children(level, "Gates").size(),
			_phase_3_children(level, "GateUnlockers").size()]
	var expected: Array[int] = [_count("d"), _count("G"), _count("^[]"), _count("="), 3, 2]
	return report(found == expected, "Phase 3's contents: dogs, biggest, spike tiles, collapsing tiles, gates, unlockers %s, the map says %s"
			% [found, expected])


func _each_gate_has_its_opener(level: Node) -> bool:
	var gate_1: Gate = level.get_node("Gates/P3Gate1") as Gate
	var gate_2: Gate = level.get_node("Gates/P3Gate2") as Gate
	var gate_3: Gate = level.get_node("Gates/P3Gate3") as Gate
	var unlocker_1: GateUnlocker = level.get_node("GateUnlockers/P3Unlocker1") as GateUnlocker
	var unlocker_2: GateUnlocker = level.get_node("GateUnlockers/P3Unlocker2") as GateUnlocker
	var biggest: BiggestDemon = level.get_node("Dogs/P3BiggestDog") as BiggestDemon
	var ok: bool = unlocker_1.gates == [gate_2] and unlocker_2.gates == [gate_1] and biggest.opens == [gate_3]
	return report(ok, "Openers: unlocker 1 opens %s, unlocker 2 opens %s, the biggest dog opens %s"
			% [unlocker_1.gates, unlocker_2.gates, biggest.opens])


## Floods the air from phase 3's S with its three gates shut, then from past gate 2, then from past gate 1.
func _phase_3s_gates_cannot_be_skipped(level: Node, tiles: TileMapLayer) -> bool:
	var gates: Array[Gate] = []
	var shut: Dictionary[Vector2i, bool] = {}
	for digit: String in "123":
		var gate: Gate = level.get_node("Gates/P3Gate%s" % digit) as Gate
		gates.append(gate)
		for cell: Vector2i in _cells_of_gate(tiles, gate):
			shut[cell] = true
	var unlocker_1: Vector2i = _cells("u")[0]
	var unlocker_2: Vector2i = _cells("v")[0]
	var finish_cell: Vector2i = _cells("F")[0]
	var from_s: Dictionary[Vector2i, bool] = _flood(tiles, shut, _cells("P")[0])
	var past_2: Dictionary[Vector2i, bool] = _flood(tiles, shut, _under(tiles, gates[1]))
	var past_1: Dictionary[Vector2i, bool] = _flood(tiles, shut, _under(tiles, gates[0]))
	var ok: bool = (from_s.has(unlocker_1) and _touches_above(from_s, tiles, gates[1]) and not from_s.has(unlocker_2)
			and not from_s.has(finish_cell) and past_2.has(unlocker_2) and _touches_above(past_2, tiles, gates[0])
			and not past_2.has(finish_cell) and past_1.has(finish_cell) and past_1.has(_cells("G")[0]))
	return report(ok, "Order: from S unlocker 1 %s, gate 2 %s, unlocker 2 %s, F %s; past gate 2 unlocker 2 %s, gate 1 %s, F %s; past gate 1 F %s"
			% [from_s.has(unlocker_1), _touches_above(from_s, tiles, gates[1]), from_s.has(unlocker_2), from_s.has(finish_cell),
			past_2.has(unlocker_2), _touches_above(past_2, tiles, gates[0]), past_2.has(finish_cell), past_1.has(finish_cell)])


## The tile right under a trapdoor's middle.
func _under(tiles: TileMapLayer, gate: Gate) -> Vector2i:
	return tiles.local_to_map(tiles.to_local(gate.global_position + Vector2(0.0, TILE / 2.0)))


## True when air holds a tile right over one of gate's tiles: the gate is reached from above.
func _touches_above(air: Dictionary[Vector2i, bool], tiles: TileMapLayer, gate: Gate) -> bool:
	for cell: Vector2i in _cells_of_gate(tiles, gate):
		if air.has(cell + Vector2i.UP) or air.has(cell + Vector2i.LEFT) or air.has(cell + Vector2i.RIGHT):
			return true
	return false


func _each_gate_slides_onto_rock(level: Node, tiles: TileMapLayer) -> bool:
	var wrong: Array[String] = []
	for node: Node in _phase_3_children(level, "Gates"):
		var gate: Gate = node as Gate
		var step: Vector2i = Vector2i(gate.slide_offset() / TILE)
		for cell: Vector2i in _cells_of_gate(tiles, gate):
			var to: Vector2i = cell + step
			if tiles.get_cell_source_id(to) == -1 or tiles.get_cell_alternative_tile(to) != 0:
				wrong.append("%s onto %s" % [gate.name, to])
				break
	return report(wrong.is_empty(), "Gates slide onto rock: wrong %s" % [wrong])


func _wall_spikes_have_rock_behind(level: Node, tiles: TileMapLayer) -> bool:
	var checked: int = 0
	var wrong: Array[String] = []
	for node: Node in _phase_3_children(level, "Spikes"):
		var spikes: LethalSpikes = node as LethalSpikes
		if is_zero_approx(spikes.rotation):
			continue
		checked += 1
		# The strip's base is on the wall: half a tile behind it, along the strip, is rock.
		var behind: Vector2 = spikes.global_position + Vector2.DOWN.rotated(spikes.rotation) * (TILE / 2.0)
		for step: int in spikes.width_tiles:
			var along: float = (step + 0.5 - spikes.width_tiles / 2.0) * TILE
			var cell: Vector2i = tiles.local_to_map(tiles.to_local(behind + Vector2.RIGHT.rotated(spikes.rotation) * along))
			if tiles.get_cell_source_id(cell) == -1:
				wrong.append("%s at %s" % [spikes.name, cell])
				break
	return report(checked > 0 and wrong.is_empty(), "Wall spikes: %d strips, with no rock behind %s" % [checked, wrong])


func _the_way_out_is_at_phase_3s_f(level: Node) -> bool:
	var exits: Array[Node] = level.find_children("*", "PhaseExit", true, false)
	var f: Vector2i = _cells("F")[0]
	var feet: Vector2 = Vector2((f.x + 0.5) * TILE, (f.y + 1) * TILE)
	var at: Vector2 = (exits[0] as Node2D).global_position if exits.size() == 1 else Vector2.INF
	return report(exits.size() == 1 and at.is_equal_approx(feet), "Way out: %d, at %s, phase 3's F at %s" % [exits.size(), at, feet])


func _the_man_near_the_biggest_dog_opens_gate_3(level: Node) -> bool:
	var gate: Gate = level.get_node("Gates/P3Gate3") as Gate
	var biggest: Node2D = level.get_node("Dogs/P3BiggestDog") as Node2D
	var player: Player = level.get_node("Player") as Player
	for _frame: int in AREA_FRAMES:
		await physics_frame
	var shut_while_far: bool = not gate.is_unlocked()
	player.global_position = biggest.global_position - Vector2(NEAR_THE_BIGGEST, 0.1)
	for _frame: int in AREA_FRAMES:
		await physics_frame
	return report(shut_while_far and gate.is_unlocked(), "Biggest dog: gate 3 shut while the man is far %s, open once he is near %s"
			% [shut_while_far, gate.is_unlocked()])
