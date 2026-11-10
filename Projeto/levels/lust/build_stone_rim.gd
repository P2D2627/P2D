# Lays level 1's stone rim from its tiles once and saves the stones into the scene, as ordinary nodes under
# Art/StoneRim: each straight run of floor, ceiling or wall one strip, each turn of the outline one corner piece (see
# levels/stone_rim.gd). From then on the stones are edited by hand in the editor, stone by stone, and the rim no
# longer follows the tiles by itself. So it never lays them over stones already saved, unless asked with --force,
# which throws the hand edits to the stones away. From the repository root, with the editor closed:
# godot --headless --path Projeto --script res://levels/lust/build_stone_rim.gd
# godot --headless --path Projeto --script res://levels/lust/build_stone_rim.gd -- --force
# The exit code is 0 when the scene was saved, and 1 when it was not, stones already there included.
extends SceneTree

const SCENE_PATH: String = "res://levels/lust/level1.tscn"
const RIM_PATH: NodePath = ^"Art/StoneRim"
## Passed after -- to lay the stones again over the ones saved.
const FORCE_ARGUMENT: String = "--force"


func _initialize() -> void:
	quit(0 if _build() == OK else 1)


func _build() -> Error:
	var packed: PackedScene = load(SCENE_PATH) as PackedScene
	if packed == null:
		printerr("build_stone_rim.gd: no scene at %s" % SCENE_PATH)
		return ERR_FILE_NOT_FOUND
	# As in the editor: the saved scene keeps only what differs from the scenes placed in it.
	var level: Node = packed.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	var rim: StoneRim = level.get_node_or_null(RIM_PATH) as StoneRim
	if rim == null:
		level.free()
		printerr("build_stone_rim.gd: %s has no %s" % [SCENE_PATH, RIM_PATH])
		return ERR_DOES_NOT_EXIST
	var saved_stones: int = rim.get_child_count()
	if saved_stones > 0 and not OS.get_cmdline_user_args().has(FORCE_ARGUMENT):
		level.free()
		printerr("build_stone_rim.gd: %s already has %d stones, edited by hand, so none were laid. Lay them again, "
				% [SCENE_PATH, saved_stones] + "throwing the hand edits away, with -- %s." % FORCE_ARGUMENT)
		return ERR_ALREADY_EXISTS
	# Off first, so the stones saved are not laid again when the level opens.
	rim.auto_build = false
	for old: Node in rim.get_children():
		rim.remove_child(old)
		old.free()
	rim.rebuild()
	for stone: Node in rim.get_children():
		stone.owner = level
	var out: PackedScene = PackedScene.new()
	var packed_error: Error = out.pack(level)
	var stones: int = rim.get_child_count()
	level.free()
	if packed_error != OK:
		printerr("build_stone_rim.gd: could not pack the scene (%s)" % error_string(packed_error))
		return packed_error
	var saved: Error = ResourceSaver.save(out, SCENE_PATH)
	if saved == OK:
		print("Laid %d stones into %s" % [stones, SCENE_PATH])
	else:
		printerr("build_stone_rim.gd: not saved (%s)" % error_string(saved))
	return saved
