# Checks the gate's art. A door (Slide Way up) is drawn as wide as the gate, at one scale, with the
# still door's bottom middle on the gate's origin. Unlocked, its art stays where it barred the passage
# while the gate's body slides into the rock: the opening cells play in order and the door is gone when
# the gate says it is open, while its frame stays. Put out of the way at once, it shows no door; locked
# back, the closing cells play in order and it ends on the still door when the gate says it is shut.
# While it stays in place, its layers draw as the gate does, under what comes after the gate in the
# level, as the man and the rock. A trapdoor (left or right) is the still door laid on its side, as
# long as the gate is wide, its top on the gate's top, where the man stands, sliding with it, and with
# no frame.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_gate_art.gd
extends SceneTree

const GATE_SCENE: PackedScene = preload("res://scenes/objects/gates/gate.tscn")
const TILE: float = 48.0
## How far a drawn point or length may be from where it belongs, in px.
const TOLERANCE: float = 0.5
## Frames of slack on the slide's length.
const SLACK_FRAMES: int = 6


func _initialize() -> void:
	var results: Array[bool] = []
	results.append(await _a_door_fits_its_gate())
	results.append(await _unlocked_the_door_opens_in_place())
	results.append(await _locked_back_the_door_closes_in_place())
	results.append(await _a_door_in_place_draws_under_what_comes_after_its_gate())
	results.append(await _a_trapdoor_is_the_door_on_its_side(Gate.SlideWay.LEFT))
	results.append(await _a_trapdoor_is_the_door_on_its_side(Gate.SlideWay.RIGHT))
	var failed: int = results.count(false)
	print("%d of %d passed" % [results.size() - failed, results.size()])
	quit(1 if failed > 0 else 0)


func _make_gate(width_tiles: int, height_tiles: int, way: Gate.SlideWay) -> Gate:
	var gate: Gate = GATE_SCENE.instantiate() as Gate
	gate.position = Vector2(300.0, 600.0)
	gate.width_tiles = width_tiles
	gate.height_tiles = height_tiles
	gate.slide_way = way
	root.add_child(gate)
	return gate


func _a_door_fits_its_gate() -> bool:
	var gate: Gate = _make_gate(2, 4, Gate.SlideWay.UP)
	await physics_frame
	var art: GateArt = gate.get_node(^"%Art") as GateArt
	var door: Sprite2D = art.get_door()
	var at: Vector2 = door.global_transform * (door.offset + art.door_bottom_middle_in_cell)
	var width: float = art.door_width_in_cell * door.global_scale.x
	var problems: Array[String] = []
	if not is_equal_approx(door.global_scale.x, door.global_scale.y):
		problems.append("stretched %s" % door.global_scale)
	if at.distance_to(gate.global_position) > TOLERANCE:
		problems.append("bottom middle at %s, gate at %s" % [at, gate.global_position])
	if absf(width - 2 * TILE) > TOLERANCE:
		problems.append("%.1f px wide" % width)
	if door.frame != 0 or not door.visible:
		problems.append("shows cell %d, visible %s" % [door.frame, door.visible])
	gate.queue_free()
	await physics_frame
	return _report(problems.is_empty(), "Door fits: %s" % ("yes" if problems.is_empty() else ", ".join(problems)))


func _unlocked_the_door_opens_in_place() -> bool:
	var gate: Gate = _make_gate(2, 5, Gate.SlideWay.UP)
	await physics_frame
	var art: GateArt = gate.get_node(^"%Art") as GateArt
	var door: Sprite2D = art.get_door()
	var opened: Array[bool] = [false]
	gate.opened.connect(func() -> void: opened[0] = true)
	var art_at: Vector2 = art.global_position
	var shut_at: Vector2 = gate.global_position
	gate.unlock()
	var cells: Array[int] = []
	var watch: int = roundi(gate.slide_time * Engine.physics_ticks_per_second) + SLACK_FRAMES
	for _step: int in watch:
		if opened[0]:
			break
		if cells.is_empty() or cells.back() != door.frame:
			cells.append(door.frame)
		await physics_frame
	var expected: Array[int] = []
	for cell: int in range(art.opening_first, art.opening_first + art.opening_count):
		expected.append(cell)
	var slid: float = shut_at.y - gate.global_position.y
	var frame_shows: bool = art.get_frame_layers().all(func(layer: Sprite2D) -> bool: return layer.visible)
	var door_hidden: bool = not door.visible
	var art_moved: float = art.global_position.distance_to(art_at)
	var ok: bool = opened[0] and cells == expected and door_hidden and frame_shows \
			and art_moved <= TOLERANCE and is_equal_approx(slid, 5 * TILE)
	gate.queue_free()
	await physics_frame
	return _report(ok, "Opens in place: opened %s, cells %s, door hidden %s, frame %s, art moved %.1f px, body rose %.1f px"
			% [opened[0], cells, door_hidden, frame_shows, art_moved, slid])


func _locked_back_the_door_closes_in_place() -> bool:
	var gate: Gate = _make_gate(2, 6, Gate.SlideWay.UP)
	await physics_frame
	var art: GateArt = gate.get_node(^"%Art") as GateArt
	var door: Sprite2D = art.get_door()
	var art_at: Vector2 = art.global_position
	gate.open_now()
	await physics_frame
	var hidden_when_open: bool = not door.visible
	var shut: Array[bool] = [false]
	gate.shut.connect(func() -> void: shut[0] = true)
	gate.lock()
	var cells: Array[int] = []
	var watch: int = roundi(gate.slide_time * Engine.physics_ticks_per_second) + SLACK_FRAMES
	for _step: int in watch:
		if shut[0]:
			break
		if door.visible and (cells.is_empty() or cells.back() != door.frame):
			cells.append(door.frame)
		await physics_frame
	var expected: Array[int] = []
	for cell: int in range(art.closing_first, art.closing_first + art.closing_count):
		expected.append(cell)
	var last_cell: int = door.frame
	var shows_door: bool = door.visible
	var art_moved: float = art.global_position.distance_to(art_at)
	var ok: bool = hidden_when_open and shut[0] and cells == expected and shows_door and last_cell == 0 \
			and art_moved <= TOLERANCE
	gate.queue_free()
	await physics_frame
	return _report(ok, "Closes in place: hidden when open %s, shut %s, cells %s, ends on cell %d, art moved %.1f px"
			% [hidden_when_open, shut[0], cells, last_cell, art_moved])


func _a_door_in_place_draws_under_what_comes_after_its_gate() -> bool:
	var gate: Gate = _make_gate(2, 5, Gate.SlideWay.UP)
	var man := Node2D.new()
	root.add_child(man)
	await physics_frame
	var art: GateArt = gate.get_node(^"%Art") as GateArt
	var layers: Array[Sprite2D] = [art.get_door()]
	layers.append_array(art.get_frame_layers())
	var shut_over: Array[String] = _drawn_over(layers, man)
	gate.unlock()
	for _step: int in roundi(gate.slide_time * Engine.physics_ticks_per_second / 2.0):
		await physics_frame
	var sliding_over: Array[String] = _drawn_over(layers, man)
	gate.queue_free()
	man.queue_free()
	await physics_frame
	return _report(shut_over.is_empty() and sliding_over.is_empty(),
			"Draws under what comes after: layers over it when shut %s, mid-slide %s" % [shut_over, sliding_over])


## The names of the layers drawn over Other, as Godot orders a canvas: an item that is Top Level, or
## under one, over every item that is not; then by Z Index; then the later in the tree over the
## earlier.
func _drawn_over(layers: Array[Sprite2D], other: CanvasItem) -> Array[String]:
	var over: Array[String] = []
	for layer: Sprite2D in layers:
		var layer_top: bool = _is_under_top_level(layer)
		var other_top: bool = _is_under_top_level(other)
		var z: int = _effective_z(layer)
		var other_z: int = _effective_z(other)
		var is_over: bool = (layer_top and not other_top) \
				or (layer_top == other_top and (z > other_z or (z == other_z and layer.is_greater_than(other))))
		if is_over:
			over.append("%s (top level %s, z %d)" % [layer.texture.resource_path.get_file(), layer_top, z])
	return over


func _is_under_top_level(item: CanvasItem) -> bool:
	var node: Node = item
	while node != null:
		if node is CanvasItem and (node as CanvasItem).top_level:
			return true
		node = node.get_parent()
	return false


func _effective_z(item: CanvasItem) -> int:
	var z: int = 0
	var node: Node = item
	while node is CanvasItem:
		z += (node as CanvasItem).z_index
		if not (node as CanvasItem).z_as_relative:
			break
		node = node.get_parent()
	return z


func _a_trapdoor_is_the_door_on_its_side(way: Gate.SlideWay) -> bool:
	var gate: Gate = _make_gate(5, 1, way)
	await physics_frame
	var art: GateArt = gate.get_node(^"%Art") as GateArt
	var door: Sprite2D = art.get_door()
	var middle := Vector2(art.door_bottom_middle_in_cell.x,
			art.door_bottom_middle_in_cell.y - art.door_height_in_cell / 2.0)
	var centre: Vector2 = door.global_transform * (door.offset + middle)
	# Laid on its side, the door's width is its thickness: its top is half that above its middle.
	var top: Vector2 = centre - Vector2(0.0, art.door_width_in_cell * door.global_scale.y / 2.0)
	var box_top: Vector2 = gate.global_position + Vector2(0.0, -TILE)
	var length: float = art.door_height_in_cell * door.global_scale.x
	var quarter: bool = is_equal_approx(absf(door.global_rotation), PI / 2.0)
	var no_frame: bool = art.get_frame_layers().all(func(layer: Sprite2D) -> bool: return not layer.visible)
	var gap: Vector2 = door.global_position - gate.global_position
	gate.unlock()
	var watch: int = roundi(gate.slide_time * Engine.physics_ticks_per_second) + SLACK_FRAMES
	for _step: int in watch:
		await physics_frame
	var moved_with_it: bool = (door.global_position - gate.global_position).is_equal_approx(gap) \
			and door.visible and door.frame == 0
	var ok: bool = quarter and top.distance_to(box_top) <= TOLERANCE and absf(length - 5 * TILE) <= TOLERANCE \
			and no_frame and moved_with_it
	gate.queue_free()
	await physics_frame
	return _report(ok, "Trapdoor %s: on its side %s, top off the gate's top by %s px, %.1f px long, no frame %s, slid with it %s"
			% [Gate.SlideWay.keys()[way], quarter, top - box_top, length, no_frame, moved_with_it])


func _report(passed: bool, what: String) -> bool:
	print("%s: %s" % ["PASS" if passed else "FAIL", what])
	return passed
