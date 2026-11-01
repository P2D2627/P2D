class_name PhaseExit
extends Area2D

## The way out of one phase of a level into the next. When the player walks in, the exit only says
## so, through reached, and Main, which holds the level in its slot, puts the next phase in its place
## behind a fade to black. A phase run on its own with F6 has no Main listening, so the exit changes
## the scene itself, with no fade. The next phase is named by its path, not held as a scene, so that
## loading this phase does not load the next one too.

## Emitted once, the first time the player walks in, with the path of the next phase's scene.
signal reached(next_scene_path: String)

## The group every exit joins, where Main finds them.
const GROUP: StringName = &"phase_exits"

## The scene of the phase that comes next.
@export_file("*.tscn") var next_scene_path: String = ""

## True once the player has walked in: the exit leads on only once.
var _used: bool = false


## Joins the group on entering the tree, so Main finds the exit as soon as it adds the level.
func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if next_scene_path.is_empty():
		push_warning("PhaseExit %s has no Next Scene Path, so it leads nowhere." % name)


func _on_body_entered(_body: Node2D) -> void:
	if _used or next_scene_path.is_empty():
		return
	_used = true
	if reached.get_connections().is_empty():
		get_tree().change_scene_to_file.call_deferred(next_scene_path)
	else:
		reached.emit(next_scene_path)
