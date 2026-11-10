# Checks level 1 as one scene. Its text map, level1.txt, made the first version; since then the scene is edited by
# hand and is the level, so these checks look at the scene alone: every kind of piece is in it; the tutorial with its prompts,
# Velvet and the corridor's demon; the camera zones, by the checks every level shares; the three parts joined only
# by their passages, with one way out, at the end; and the save points, which hold where a death starts over.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_level1.gd
extends "res://tests/test_lust_phase_2.gd"

const LEVEL_PATH: String = "res://levels/lust/level1.tscn"
## A tile of air in phase 1's start room, in F's room and in phase 2's start room.
const S_ROOM_CELL: Vector2i = Vector2i(112, 365)
const F_ROOM_CELL: Vector2i = Vector2i(349, 260)
const PHASE_2_ROOM_CELL: Vector2i = Vector2i(351, 246)
## Where the man's feet are at each of the level's three starts.
const WAKE_FEET: Vector2 = Vector2(216.0, 17568.0)
const S_FEET: Vector2 = Vector2(5400.0, 17568.0)
const PHASE_2_FEET: Vector2 = Vector2(16872.0, 11856.0)
## The prompts of the tutorial: move left, move right, jump, wall jump, crucifix, and Velvet's talk key.
const TUTORIAL_PROMPTS: int = 6
const TUTORIAL_SAVE: String = "TutorialSave"
const PHASE_2_SAVE: String = "Phase2Save"
const TUTORIAL_DONE_EVENT: StringName = &"tutorial_done"
const PHASE_2_REACHED_EVENT: StringName = &"lust_phase_2_reached"
## Physics frames for an area to see the man put inside it.
const AREA_FRAMES: int = 3
## Physics frames the dogs patrol for, and how far they may end from their floor's height, in px.
const PATROL_FRAMES: int = 300
const ON_ITS_FLOOR: float = 2.0


func _initialize() -> void:
	# The headless window is 64 x 64, which the stretch makes a 1920 x 1920 screen.
	await process_frame
	root.size = Vector2i(int(ProjectSettings.get_setting("display/window/size/viewport_width")),
			int(ProjectSettings.get_setting("display/window/size/viewport_height")))
	await process_frame
	_progress().reset()
	var level: Node = (load(LEVEL_PATH) as PackedScene).instantiate()
	root.add_child(level)
	await process_frame
	var results: Array[bool] = []
	results.append(_the_scene_holds_every_kind_of_piece(level))
	results.append(_big_dogs_are_black_and_dogs_are_not(level))
	results.append(_each_gate_has_its_own_unlocker(level))
	results.append(_the_gates_cannot_be_skipped(level))
	var tiles: TileMapLayer = level.get_node("Tiles") as TileMapLayer
	var zones: Array[CameraZone] = Checks.zones_of(level)
	var camera: GameCamera = level.get_node("GameCamera") as GameCamera
	for check: Array in [Checks.overlapping_zones_differ_in_area(zones),
			Checks.every_floor_is_in_a_zone(tiles, zones),
			Checks.no_zone_shows_another_path(tiles, zones, camera),
			Checks.every_zone_shows_wall_past_its_sides(tiles, zones, camera),
			Checks.every_floor_is_the_lower_limit(tiles, zones)]:
		results.append(report(check[0], check[1]))
	results.append(_the_player_starts_in_a_zone_anchored_at_the_bottom(level, zones))
	results.append(_the_tutorial_is_all_there(level))
	results.append(_the_parts_join_by_their_passages(level))
	results.append(_there_is_one_way_out(level))
	results.append(await _the_dogs_stay_on_their_floors(level))
	level.queue_free()
	await process_frame
	results.append(await _each_start_is_where_the_saves_say())
	results.append(await _walking_into_a_save_point_marks_it())
	_progress().reset()
	finish(results)


func _progress() -> GameProgress:
	return root.get_node(^"GameState") as GameProgress


## Dogs, big dogs, spikes and collapsing platforms are each in the scene at least once. The scene is edited by
## hand, so how many of each is the scene's to say, not the text map's.
func _the_scene_holds_every_kind_of_piece(level: Node) -> bool:
	var dogs: int = 0
	var big_dogs: int = 0
	for node: Node in level.get_node("Dogs").get_children():
		if String(node.name).begins_with("BigDog"):
			big_dogs += 1
		else:
			dogs += 1
	var spike_tiles: int = 0
	for node: Node in level.get_node("Spikes").get_children():
		spike_tiles += (node as LethalSpikes).width_tiles
	var collapsing_tiles: int = 0
	for node: Node in level.get_node("CollapsingPlatforms").get_children():
		collapsing_tiles += (node as CollapsingPlatform).width_tiles
	var found: Array[int] = [dogs, big_dogs, spike_tiles, collapsing_tiles]
	return report(not found.has(0), "Contents: dogs, big dogs, spike tiles, collapsing tiles %s" % [found])


func _the_tutorial_is_all_there(level: Node) -> bool:
	var player: Player = level.get_node("Player") as Player
	var velvet: TutorialDemon = level.get_node("Tutorial/TutorialDemon") as TutorialDemon
	var blocker: Demon = level.get_node("Tutorial/BlockerDemon") as Demon
	var prompts: int = level.get_node("Tutorial").find_children("*", "KeyPrompt", true, false).size()
	var ok: bool = (velvet.player == player and velvet.crucifix == player.get_node("Crucifix") and blocker != null
			and prompts == TUTORIAL_PROMPTS)
	return report(ok, "Tutorial: Velvet talks to the man %s, %d prompts" % [velvet.player == player, prompts])


## With the gates shut, the air joins the tutorial, S, F's room and phase 2's start.
func _the_parts_join_by_their_passages(level: Node) -> bool:
	var tiles: TileMapLayer = level.get_node("Tiles") as TileMapLayer
	var shut: Dictionary[Vector2i, bool] = {}
	for gate: Gate in [level.get_node("Gates/GateA") as Gate, level.get_node("Gates/GateB") as Gate]:
		for cell: Vector2i in _cells_of_gate(tiles, gate):
			shut[cell] = true
	var start: Vector2i = _standing_cell(tiles, (level.get_node("Player") as Node2D).global_position)
	var air: Dictionary[Vector2i, bool] = _flood(tiles, shut, start)
	return report(air.has(S_ROOM_CELL) and air.has(F_ROOM_CELL) and air.has(PHASE_2_ROOM_CELL),
			"Joins: the tutorial reaches S %s, F's room %s, phase 2's start %s" % [air.has(S_ROOM_CELL),
			air.has(F_ROOM_CELL), air.has(PHASE_2_ROOM_CELL)])


func _there_is_one_way_out(level: Node) -> bool:
	var exits: Array[Node] = level.find_children("*", "PhaseExit", true, false)
	return report(exits.size() == 1, "Way out: %d in the scene" % exits.size())


## With the man far away, the dogs patrol for a while, and none falls off the floor it started on, not even those on
## a one-way platform: a dog never goes down.
func _the_dogs_stay_on_their_floors(level: Node) -> bool:
	var dogs: Array[Node] = level.get_node("Dogs").get_children()
	var heights: Array[float] = []
	for dog: Node in dogs:
		heights.append((dog as Node2D).global_position.y)
	for _frame: int in PATROL_FRAMES:
		await physics_frame
	var fallen: Array[String] = []
	for index: int in dogs.size():
		var dog: Node2D = dogs[index] as Node2D
		if absf(dog.global_position.y - heights[index]) > ON_ITS_FLOOR:
			fallen.append("%s from %.0f to %.0f" % [dog.name, heights[index], dog.global_position.y])
	return report(fallen.is_empty(), "Dogs: %d patrolled, fallen: %s" % [dogs.size(), fallen])


## Where the man and the camera are as a new copy of the level starts with these events in GameState.
func _start_with(events: Array[StringName]) -> Array[Vector2]:
	_progress().reset()
	for event: StringName in events:
		_progress().mark_event(event)
	var level: Node = (load(LEVEL_PATH) as PackedScene).instantiate()
	root.add_child(level)
	await process_frame
	var at: Array[Vector2] = [(level.get_node("Player") as Node2D).global_position,
			(level.get_node("GameCamera") as Node2D).global_position]
	level.queue_free()
	await process_frame
	return at


func _each_start_is_where_the_saves_say() -> bool:
	var fresh: Array[Vector2] = await _start_with([])
	var past_tutorial: Array[Vector2] = await _start_with([TUTORIAL_DONE_EVENT])
	var in_phase_2: Array[Vector2] = await _start_with([TUTORIAL_DONE_EVENT, PHASE_2_REACHED_EVENT])
	var ok: bool = (fresh[0].is_equal_approx(WAKE_FEET) and past_tutorial[0].is_equal_approx(S_FEET)
			and in_phase_2[0].is_equal_approx(PHASE_2_FEET))
	return report(ok, "Starts: new game %s, past the tutorial %s, inside phase 2 %s" % [fresh[0], past_tutorial[0],
			in_phase_2[0]])


## The man put inside each save point, in the game's order, marks its event and says so.
func _walking_into_a_save_point_marks_it() -> bool:
	_progress().reset()
	var level: Node = (load(LEVEL_PATH) as PackedScene).instantiate()
	root.add_child(level)
	await process_frame
	var player: Player = level.get_node("Player") as Player
	var marked: Array[bool] = []
	for point_name: String in [TUTORIAL_SAVE, PHASE_2_SAVE]:
		var point: SavePoint = level.get_node(point_name) as SavePoint
		var said: Array[bool] = [false]
		point.reached.connect(func() -> void: said[0] = true)
		player.global_position = point.global_position
		for _frame: int in AREA_FRAMES:
			await physics_frame
		marked.append(said[0] and _progress().has_event(point.event))
	level.queue_free()
	await process_frame
	return report(marked == [true, true], "Save points: marked %s" % [marked])
