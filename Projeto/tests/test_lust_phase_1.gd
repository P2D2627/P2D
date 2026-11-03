# Checks Lust phase 1 as levels/text_map/build_map.gd builds it from levels/lust/lust_phase_1.txt:
# - the scene holds the text's rock, the man starts at its P, every floor is in a camera zone and
#   overlapping zones differ in area;
# - in each crucifix corridor (the text's crucifix_dog lines), with the man put on the refuge step
#   at the corridor's mouth:
#   - the crucifix throws the dog back with no hit on him (showing it with no risk);
#   - once the dog walks off, he steps down and raises the crucifix on the corridor's floor, pushes
#     the dog off the far end into the pit before the crucifix runs out, takes no hit, and jumps the
#     pit, from its edge or from the tile before it;
#   - without the crucifix, running and jumping at the dog, he never gets past it nor across the
#     pit. Taking bites, he can herd it to the edge: while he blinks after a bite, a dog waits about
#     130 px off; the tile before the edge leaves no room to jump over it there.
# The dogs' pauses and attacks are random, so the push runs with several seeds and with the man
# setting off at several moments. Every place is read from the text, not typed in. A dog only chases
# on the screen, and the headless window is 64 × 64, so the test first gives it the game's size.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_lust_phase_1.gd
extends "res://tests/support/player_test.gd"

const Checks = preload("res://tests/support/level_camera_checks.gd")
const MapText = preload("res://levels/text_map/map_text.gd")
const MAP_TEXT: String = "res://levels/lust/lust_phase_1.txt"
const MAP_SCENE: PackedScene = preload("res://levels/lust/lust_phase_1.tscn")
const TILE: float = 48.0
const SEEDS: Array[int] = [1, 2, 3]
## Seconds the man stands on the step before waiting for the dog to walk off, so the dog is
## elsewhere on its patrol each time.
const SET_OFF_DELAYS: Array[float] = [0.0, 1.6, 3.2]
## Seconds the man has, once the dog is in the pit, to jump it.
const JUMP_TIME: float = 4.0
## Seconds the man runs and jumps at the dog without the crucifix: long enough to herd it to the edge.
const NO_CRUCIFIX_TIME: float = 10.0
## Seconds the man waits on the refuge step for the dog: to come to the step, or to walk off.
const STEP_WAIT_TIME: float = 12.0
## How far from the step, in tiles past the crucifix's reach, the dog has walked off.
const WALKED_OFF_TILES: float = 1.0
## How near, in px, feet count as on a floor: the physics leaves them a fraction of a px above it.
const SAME_HEIGHT: float = 1.0


## One crucifix corridor, read from the text: where its dog's post is, which way the pit lies, and
## its places in px.
class Corridor:
	var name: String = ""
	var post: Vector2i = Vector2i.ZERO
	## 1 when the pit lies to the right of the dog's floor, -1 when to the left.
	var way: float = 0.0
	## The dog's floor: its top, and its ends on the step's side and on the pit's side.
	var floor_y: float = 0.0
	var mouth_x: float = 0.0
	var edge_x: float = 0.0
	## Where the man stands on the refuge step: its middle, on its top.
	var step: Vector2 = Vector2.ZERO
	## The side facing the corridor of the tile before the edge, whose ceiling rises: with his middle
	## half a tile past it, the man's whole body is under that higher ceiling.
	var high_x: float = 0.0
	## The far side of the pit, and its bottom.
	var far_x: float = 0.0
	var pit_y: float = 0.0


var _map: MapText = MapText.new()
var _corridors: Array[Corridor] = []


func _initialize() -> void:
	await process_frame
	root.size = Vector2i(int(ProjectSettings.get_setting("display/window/size/viewport_width")),
			int(ProjectSettings.get_setting("display/window/size/viewport_height")))
	await process_frame
	var read: bool = _map.load_file(MAP_TEXT) and _read_corridors()
	var found: PackedStringArray = PackedStringArray()
	for corridor: Corridor in _corridors:
		found.append("corridor %s, the pit to the %s" % [corridor.name, "right" if corridor.way > 0.0 else "left"])
	if not report(read, "Read %s: %s" % [MAP_TEXT, _map.error if not read else ", ".join(found)]):
		finish([false])
		return
	var results: Array[bool] = []
	results.append_array(await _the_scene_matches_the_text())
	for corridor: Corridor in _corridors:
		for game_seed: int in SEEDS:
			results.append(await _on_the_step_the_crucifix_throws_the_dog_back(corridor, game_seed))
		for game_seed: int in SEEDS:
			for delay: float in SET_OFF_DELAYS:
				results.append(await _the_crucifix_pushes_the_dog_into_the_pit(corridor, game_seed, delay, false))
			results.append(await _the_crucifix_pushes_the_dog_into_the_pit(corridor, game_seed, 0.0, true))
		for game_seed: int in SEEDS:
			results.append(await _without_the_crucifix_the_dog_keeps_him_out(corridor, game_seed))
	finish(results)


## Finds each crucifix corridor's places from the text. False, with the map's error set, if a
## crucifix_dog line names no dog or its floor has no step at one end and no pit at the other.
func _read_corridors() -> bool:
	for value: String in _map.values_of("crucifix_dog"):
		var numbers: PackedStringArray = value.split(" ", false)
		var corridor: Corridor = Corridor.new()
		corridor.post = Vector2i(numbers[0].to_int(), numbers[1].to_int())
		if not (MapText.DOG_FACING_LEFT + MapText.DOG_FACING_RIGHT).contains(_map.at(corridor.post.x, corridor.post.y)):
			_map.error = "no dog at the crucifix_dog cell %s" % corridor.post
			return false
		corridor.name = _section_of(corridor.post)
		var row: int = corridor.post.y
		var left: int = corridor.post.x
		while _is_floor(left - 1, row):
			left -= 1
		var right: int = corridor.post.x
		while _is_floor(right + 1, row):
			right += 1
		var pit_on_right: bool = not _map.is_rock(right + 1, row + 1)
		var pit_on_left: bool = not _map.is_rock(left - 1, row + 1)
		if pit_on_right == pit_on_left:
			_map.error = "corridor %s needs a pit at one end of the dog's floor and a step at the other" % corridor.name
			return false
		corridor.way = 1.0 if pit_on_right else -1.0
		corridor.floor_y = (row + 1) * TILE
		var step_column: int = left - 1 if pit_on_right else right + 1
		var edge_column: int = right + 1 if pit_on_right else left - 1
		corridor.mouth_x = (right + 1) * TILE if not pit_on_right else left * TILE
		corridor.edge_x = (right + 1) * TILE if pit_on_right else left * TILE
		var step_top: int = row
		while _map.is_rock(step_column, step_top - 1):
			step_top -= 1
		var step_end: int = step_column
		while _map.is_rock(step_end - int(corridor.way), step_top) and not _map.is_rock(step_end - int(corridor.way), step_top - 1):
			step_end -= int(corridor.way)
		corridor.step = Vector2((step_column + step_end + 1) / 2.0 * TILE, step_top * TILE)
		var high: int = corridor.post.x
		while _headroom(high, row) <= _headroom(corridor.post.x, row) and _is_floor(high, row):
			high += int(corridor.way)
		corridor.high_x = (high + (0 if pit_on_right else 1)) * TILE
		var far: int = edge_column
		while not _map.is_rock(far, row + 1):
			far += int(corridor.way)
		corridor.far_x = (far if pit_on_right else far + 1) * TILE
		var pit_row: int = row + 1
		while not _map.is_rock(edge_column, pit_row):
			pit_row += 1
		corridor.pit_y = pit_row * TILE
		_corridors.append(corridor)
	if _corridors.is_empty():
		_map.error = "no crucifix_dog line"
		return false
	return true


func _is_floor(column: int, row: int) -> bool:
	return not _map.is_rock(column, row) and _map.is_rock(column, row + 1)


## Tiles of air over the floor at column, row, up to the first rock.
func _headroom(column: int, row: int) -> int:
	var air: int = 0
	while row - air >= 0 and not _map.is_rock(column, row - air):
		air += 1
	return air


func _section_of(cell: Vector2i) -> String:
	for value: String in _map.values_of("section"):
		if MapText.rect_of(value).has_point(cell):
			return MapText.name_of(value)
	return "?"


func _the_scene_matches_the_text() -> Array[bool]:
	var level: Node = MAP_SCENE.instantiate()
	root.add_child(level)
	var tiles: TileMapLayer = level.get_node(^"Tiles") as TileMapLayer
	var wrong: Array[Vector2i] = []
	for row: int in _map.height:
		for column: int in _map.width:
			var cell: Vector2i = Vector2i(column, row)
			if (tiles.get_cell_source_id(cell) != -1) != _map.is_rock(column, row):
				wrong.append(cell)
	var start: Vector2i = _map.find(MapText.START)[0]
	var player: Player = level.get_node(^"Player") as Player
	var expected_start: Vector2 = Vector2((start.x + 0.5) * TILE, (start.y + 1) * TILE)
	var results: Array[bool] = [report(wrong.is_empty() and player.position.is_equal_approx(expected_start),
			"The scene's tiles match the text's rock, %d × %d tiles, built from an older text at: %s; the man starts at %s, expected %s"
			% [_map.width, _map.height, wrong if not wrong.is_empty() else "none", player.position, expected_start])]
	var zones: Array[CameraZone] = Checks.zones_of(level)
	for check: Array in [Checks.overlapping_zones_differ_in_area(zones),
			Checks.every_floor_is_in_a_zone(tiles, zones)]:
		results.append(report(check[0], check[1]))
	level.queue_free()
	await physics_frame
	return results


## The phase's level, with seed fixed, the man put on the corridor's refuge step and a stand-in
## for his input; hits on him are counted in hits.
func _level_at_the_step(corridor: Corridor, game_seed: int, hits: Array[float]) -> Array:
	seed(game_seed)
	var level: Node = MAP_SCENE.instantiate()
	root.add_child(level)
	var player: Player = level.get_node(^"Player") as Player
	player.global_position = corridor.step
	player.velocity = Vector2.ZERO
	var stand_in: StandInInput = put_a_stand_in(player)
	(player.get_node(^"SoulPoints") as SoulPoints).damaged.connect(
			func(amount: float) -> void: hits.append(amount))
	var dog: Demon = null
	for node: Node in level.get_children():
		if node is Demon and (node as Demon).position.is_equal_approx(
				Vector2((corridor.post.x + 0.5) * TILE, (corridor.post.y + 1) * TILE)):
			dog = node as Demon
	await wait_until_on_floor(player)
	return [level, player, dog, stand_in]


## True when a lies further than b the way the pit lies.
func _past(a: float, b: float, way: float) -> bool:
	return (a - b) * way > 0.0


## The man waits on the refuge step for the dog to come; then he raises the crucifix there. The dog
## is thrown back along its floor, and the man takes no hit.
func _on_the_step_the_crucifix_throws_the_dog_back(corridor: Corridor, game_seed: int) -> bool:
	var hits: Array[float] = []
	var parts: Array = await _level_at_the_step(corridor, game_seed, hits)
	var level: Node = parts[0]
	var player: Player = parts[1]
	var dog: Demon = parts[2]
	var stand_in: StandInInput = parts[3]
	var crucifix: Crucifix = player.get_node(^"Crucifix") as Crucifix
	var ticks: int = Engine.physics_ticks_per_second
	var on_step: bool = _at(player.position.y, corridor.step.y)
	var came: bool = await wait_until(func() -> bool:
			return absf(player.position.x - dog.position.x) < crucifix.stats.repel_radius,
			roundi(STEP_WAIT_TIME * ticks))
	var dog_before: float = dog.position.x
	stand_in.crucifix_held = true
	var thrown: bool = await wait_until(func() -> bool:
			return dog.get_state() == Demon.State.THROWN, roundi(crucifix.stats.max_use_time * ticks))
	await wait_until(func() -> bool: return dog.get_state() != Demon.State.THROWN)
	var dog_after: float = dog.position.x
	stand_in.crucifix_held = false
	level.queue_free()
	await physics_frame
	return report(on_step and came and thrown and _past(dog_after, dog_before, corridor.way) and hits.is_empty(),
			"Corridor %s, seed %d, on the step: on it %s; the dog came %s, to x %.0f; thrown %s, to x %.0f; hits on the man %s"
			% [corridor.name, game_seed, on_step, came, dog_before, thrown, dog_after, hits])


## The man stands delay seconds on the refuge step, waits for the dog to walk off, steps down and
## raises the crucifix on the corridor's floor, walking on at the crucifix's pace. The dog must fall
## into the pit before the crucifix's Max Use Time ends, with no hit on the man; then he jumps the
## pit, from the floor's last tile or, with jump_early, from the tile before it, once his whole body
## is under its higher ceiling, and lands across it.
func _the_crucifix_pushes_the_dog_into_the_pit(corridor: Corridor, game_seed: int, delay: float,
		jump_early: bool) -> bool:
	var hits: Array[float] = []
	var parts: Array = await _level_at_the_step(corridor, game_seed, hits)
	var level: Node = parts[0]
	var player: Player = parts[1]
	var dog: Demon = parts[2]
	var stand_in: StandInInput = parts[3]
	var crucifix: Crucifix = player.get_node(^"Crucifix") as Crucifix
	var use_time: float = crucifix.stats.max_use_time
	var reach: float = crucifix.stats.repel_radius
	var ticks: int = Engine.physics_ticks_per_second
	await wait_frames(roundi(delay * ticks))
	var walked_off: bool = await wait_until(func() -> bool:
			return _past(dog.position.x, corridor.mouth_x + corridor.way * (reach + WALKED_OFF_TILES * TILE), corridor.way),
			roundi(STEP_WAIT_TIME * ticks))
	stand_in.run_direction = corridor.way
	var in_corridor: bool = await wait_until(func() -> bool:
			return player.is_on_floor() and _past(player.position.x, corridor.mouth_x, corridor.way) \
					and _at(player.position.y, corridor.floor_y))
	stand_in.crucifix_held = true
	var raised_at: int = Engine.get_physics_frames()
	var pushed: bool = await wait_until(func() -> bool:
			return dog.is_on_floor() and _at(dog.position.y, corridor.pit_y), roundi(use_time * ticks))
	var push_time: float = float(Engine.get_physics_frames() - raised_at) / ticks
	var dog_x: float = dog.position.x
	stand_in.crucifix_held = false
	stand_in.hold_jump = true
	# Early, his whole body is past the low ceiling: a jump with part of it still under it bumps the
	# ceiling and drops him into the pit, which is for the playtest, not this check.
	var take_off_x: float = corridor.high_x + corridor.way * TILE / 2.0 if jump_early \
			else corridor.edge_x - corridor.way * TILE
	var took_off: bool = await wait_until(func() -> bool:
			if player.is_on_floor() and _past(player.position.x, take_off_x, corridor.way):
				stand_in.press_jump()
			return not player.is_on_floor() and _past(player.position.x, corridor.high_x, corridor.way),
			roundi(JUMP_TIME * ticks))
	var landed: bool = await wait_until_on_floor(player)
	# Across the pit: on the floor past it, or on a step further on, but not down in it.
	var across: bool = landed and _past(player.position.x, corridor.far_x, corridor.way) \
			and player.position.y < corridor.floor_y + SAME_HEIGHT
	var dog_stayed: bool = _at(dog.position.y, corridor.pit_y)
	level.queue_free()
	await physics_frame
	return report(walked_off and in_corridor and pushed and hits.is_empty() and took_off and across and dog_stayed,
			"Corridor %s, seed %d, setting off after %.1f s, jumping %s: the dog walked off %s; dog in the pit %s after %.2f s of crucifix (it lasts %.1f s), at x %.0f; hits on the man %s; jumped the pit %s, landed across %s; the dog still in the pit %s"
			% [corridor.name, game_seed, delay, "a tile early" if jump_early else "at the edge", walked_off,
			pushed, push_time, use_time, dog_x, hits, took_off, across, dog_stayed])


## From the refuge step, the man runs at the dog with no crucifix for NO_CRUCIFIX_TIME, jumping
## whenever he is on a floor, as one trying to get over it: he is never past it, nor across the pit.
func _without_the_crucifix_the_dog_keeps_him_out(corridor: Corridor, game_seed: int) -> bool:
	var hits: Array[float] = []
	var parts: Array = await _level_at_the_step(corridor, game_seed, hits)
	var level: Node = parts[0]
	var player: Player = parts[1]
	var dog: Demon = parts[2]
	var stand_in: StandInInput = parts[3]
	stand_in.run_direction = corridor.way
	stand_in.hold_jump = true
	var got_past: bool = false
	var got_across: bool = false
	for _frame: int in roundi(NO_CRUCIFIX_TIME * Engine.physics_ticks_per_second):
		if player.is_on_floor():
			stand_in.press_jump()
		await physics_frame
		got_past = got_past or _past(player.position.x, dog.position.x, corridor.way)
		got_across = got_across or (player.is_on_floor() and _past(player.position.x, corridor.far_x, corridor.way))
	var man_x: float = player.position.x
	var dog_x: float = dog.position.x
	level.queue_free()
	await physics_frame
	return report(not got_past and not got_across,
			"Corridor %s, seed %d, no crucifix, running and jumping for %.0f s: past the dog %s, across the pit %s; the man ended at x %.0f, the dog at x %.0f (the floor ends at x %.0f); hits on him %s"
			% [corridor.name, game_seed, NO_CRUCIFIX_TIME, got_past, got_across, man_x, dog_x, corridor.edge_x, hits])


## True when feet at y stand on a floor whose top is at floor_y.
func _at(y: float, floor_y: float) -> bool:
	return absf(y - floor_y) < SAME_HEIGHT
