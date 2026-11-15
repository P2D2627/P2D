class_name SavePoint
extends Area2D

## A save inside a phase, for a stretch that counts as a phase of its own, such as the tutorial. The
## first time the man walks in, it marks Event in GameState and says so through reached, and Main,
## which holds the level in its slot, saves. From then on, the level starts with the man at Respawn:
## it goes before GameCamera in the scene, so the camera starts there too. Run on its own with F6,
## nothing saves, but GameState keeps the event until the game closes. When GameState names an
## ArrivalPoint, the man starts there instead.

## The man walked in for the first time.
signal reached

## The group every save point joins, where Main finds them.
const GROUP: StringName = &"save_points"

## The event in GameState that says this stretch is over.
@export var event: StringName = &""
@export var player: Player
## Where the man starts once this stretch is over.
@export var respawn: Marker2D
## The phase of the level that starts here, for RunStats; 0 when the stretch starts no phase.
@export_range(0, 9) var starts_phase: int = 0

@onready var _progress: GameProgress = get_node(^"/root/GameState") as GameProgress


## Joins the group on entering the tree, so Main finds the point as soon as it adds the level.
func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	assert(not event.is_empty(), "SavePoint: name the Event.")
	assert(player != null, "SavePoint: assign the man to Player.")
	assert(respawn != null, "SavePoint: assign a Marker2D to Respawn.")
	body_entered.connect(_on_body_entered)
	# Brought in at an ArrivalPoint, as by Lust's shortcut, he starts there, not at Respawn.
	if _progress.has_event(event) and _progress.arrival_point.is_empty():
		player.global_position = respawn.global_position


## Whether the man got here, in this run or before the save the level started from.
func is_reached() -> bool:
	return _progress.has_event(event)


func _on_body_entered(_body: Node2D) -> void:
	if _progress.has_event(event):
		return
	_progress.mark_event(event)
	reached.emit()
