# Checks SinkingDrawing on its own and in the demon's scene (ADR 0026). The drawing goes down by a
# share of Depth, never above its feet nor past Depth, while its node stays where it is. In
# demon.tscn, how far the man sank comes through the demon's Hitbox and sinks its drawing, and 0
# brings it back; each demon has its own material, so one sinking leaves the others up.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_sinking_drawing.gd
extends "res://tests/support/player_test.gd"

const DEMON_SCENE: PackedScene = preload("res://demon/demon.tscn")
## The floor runs from FLOOR_LEFT to FLOOR_RIGHT with its top at y = 0; the two demons start just
## above it, apart.
const FLOOR_LEFT: float = -2000.0
const FLOOR_RIGHT: float = 2000.0
const FIRST_DEMON_START: Vector2 = Vector2(-300.0, -2.0)
const SECOND_DEMON_START: Vector2 = Vector2(300.0, -2.0)
## Physics frames for the demons to land.
const SETTLE_FRAMES: int = 10
## Shares of the way down the cases ask for: half, past the whole way, and above the feet.
const HALF: float = 0.5
const PAST_FULL: float = 2.0
const ABOVE_THE_FEET: float = -1.0


func _initialize() -> void:
	# Before the first frame the root is not ready yet, and a node added to it only runs _ready()
	# when the root does.
	await process_frame
	make_platform(FLOOR_LEFT, FLOOR_RIGHT)
	var results: Array[bool] = []
	results.append(_it_sinks_by_a_share_of_depth_and_no_further())
	results.append(await _a_demon_s_drawing_sinks_with_its_hold_alone())
	finish(results)


## A stand-in drawing with its SinkingDrawing: at HALF, HALF of Depth down; past the whole way, Depth;
## above the feet, 0. The drawing's node never moves.
func _it_sinks_by_a_share_of_depth_and_no_further() -> bool:
	var drawing: Polygon2D = Polygon2D.new()
	var sinking: SinkingDrawing = SinkingDrawing.new()
	sinking.drawing = drawing
	root.add_child(drawing)
	root.add_child(sinking)
	sinking.set_sink(HALF)
	var half_down: float = _depth_of(drawing)
	sinking.set_sink(PAST_FULL)
	var past_full_down: float = _depth_of(drawing)
	sinking.set_sink(ABOVE_THE_FEET)
	var above_down: float = _depth_of(drawing)
	var passed: bool = (is_equal_approx(half_down, HALF * sinking.depth)
			and past_full_down == sinking.depth and above_down == 0.0
			and drawing.position == Vector2.ZERO)
	var verdict: bool = report(passed,
			("On its own, Depth %.1f: at %.1f %.1f px down, at %.1f %.1f, at %.1f %.1f; node at %s")
			% [sinking.depth, HALF, half_down, PAST_FULL, past_full_down, ABOVE_THE_FEET,
			above_down, drawing.position])
	sinking.queue_free()
	drawing.queue_free()
	return verdict


## Two demons on the floor. HALF, through the first one's Hitbox, sinks its drawing HALF of its
## Depth, and 0 brings it back; the second one's drawing stays up all along.
func _a_demon_s_drawing_sinks_with_its_hold_alone() -> bool:
	var first: Demon = _spawn_demon(FIRST_DEMON_START)
	var second: Demon = _spawn_demon(SECOND_DEMON_START)
	await wait_frames(SETTLE_FRAMES)
	var hitbox: Hitbox = first.get_node(^"Hitbox") as Hitbox
	var depth: float = (first.get_node(^"SinkingDrawing") as SinkingDrawing).depth
	hitbox.sink_hold(HALF)
	var first_down: float = _depth_of(first.get_node(^"Placeholder") as CanvasItem)
	var second_down: float = _depth_of(second.get_node(^"Placeholder") as CanvasItem)
	hitbox.sink_hold(0.0)
	var first_back: float = _depth_of(first.get_node(^"Placeholder") as CanvasItem)
	var passed: bool = (is_equal_approx(first_down, HALF * depth) and second_down == 0.0
			and first_back == 0.0)
	var verdict: bool = report(passed,
			("Demons, Depth %.1f: the first at %.1f %.1f px down, the second %.1f; the first at 0 "
			+ "%.1f") % [depth, HALF, first_down, second_down, first_back])
	first.queue_free()
	second.queue_free()
	return verdict


func _spawn_demon(start: Vector2) -> Demon:
	var demon: Demon = DEMON_SCENE.instantiate() as Demon
	demon.position = start
	root.add_child(demon)
	return demon


## Px the drawing is down now, as its shader has it.
func _depth_of(drawing: CanvasItem) -> float:
	return float((drawing.material as ShaderMaterial).get_shader_parameter(
			SinkingDrawing.DEPTH_PARAMETER))
