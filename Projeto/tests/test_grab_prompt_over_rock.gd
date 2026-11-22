# Checks that the grab's prompt ("Press Jump!") always shows: in the lit level, where the man is drawn
# behind the rock, the prompt still draws over the rock and its stone rim.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_grab_prompt_over_rock.gd
extends SceneTree

const LIGHTING_LEVEL_PATH: String = "res://scenes/levels/lust/level1_lit.tscn"
## Frames for the rig to set the level up.
const LEVEL_FRAMES: int = 10


func _initialize() -> void:
	var level: Node = (load(LIGHTING_LEVEL_PATH) as PackedScene).instantiate()
	root.add_child(level)
	for _frame: int in LEVEL_FRAMES:
		await process_frame
	var prompt := level.find_child("GrabPrompt", true, false) as CanvasItem
	var rock := level.get_node_or_null(^"Tiles") as CanvasItem
	var rim := level.get_node_or_null(^"Art") as CanvasItem
	var passed: bool = false
	var what: String = "missing: prompt %s, rock %s" % [prompt != null, rock != null]
	if prompt != null and rock != null:
		var over: int = _z_of(rock) if rim == null else maxi(_z_of(rock), _z_of(rim))
		passed = _z_of(prompt) > over
		what = "prompt at z %d, rock and rim up to %d" % [_z_of(prompt), over]
	print("%s: the grab's prompt draws over the rock: %s" % ["PASS" if passed else "FAIL", what])
	quit(0 if passed else 1)


## The z a canvas item is drawn at, adding its parents' while it is relative to them.
func _z_of(item: CanvasItem) -> int:
	var z: int = item.z_index
	var node: Node = item
	while (node as CanvasItem).z_as_relative and node.get_parent() is CanvasItem:
		node = node.get_parent()
		z += (node as CanvasItem).z_index
	return z
