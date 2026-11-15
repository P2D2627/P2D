class_name PhaseExit
extends Area2D

## The way out of one phase of a level into the next. When the player walks in, the exit only says
## so, through reached, and Main, which holds the level in its slot, puts the next phase in its place
## behind a fade to black. A phase run on its own with F6 has no Main listening, so the exit changes
## the scene itself, with no fade. The next phase is named by its path, not held as a scene, so that
## loading this phase does not load the next one too. An exit with no Next Scene Path is the end of
## the level: it says reached with an empty path, and Main ends the level. With Walk In Leads On off,
## walking in only says body_entered, and the exit leads on when something calls lead_on(), as
## Asmodeus's last lines at the end of Lust.

## Emitted once, when the exit leads on, with the path of the next phase's scene; empty at the end of
## the level.
signal reached(next_scene_path: String)

## The group every exit joins, where Main finds them.
const GROUP: StringName = &"phase_exits"

## The scene of the phase that comes next; empty when the level ends here.
@export_file("*.tscn") var next_scene_path: String = ""
## On: walking in leads on. Off: only lead_on() does.
@export var walk_in_leads_on: bool = true

## True once the exit has led on: it leads on only once.
var _used: bool = false


## Joins the group on entering the tree, so Main finds the exit as soon as it adds the level.
func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	body_entered.connect(_on_body_entered)


## Leads on to the next phase, or ends the level; only the first time.
func lead_on() -> void:
	if _used:
		return
	_used = true
	if not reached.get_connections().is_empty():
		reached.emit(next_scene_path)
	elif next_scene_path.is_empty():
		print("PhaseExit %s: the level is over." % name)
	else:
		get_tree().change_scene_to_file.call_deferred(next_scene_path)


func _on_body_entered(_body: Node2D) -> void:
	if walk_in_leads_on:
		lead_on()
