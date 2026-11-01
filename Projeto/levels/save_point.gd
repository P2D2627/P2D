class_name SavePoint
extends Area2D

## A save inside a phase, for a stretch that counts as a phase of its own, such as the tutorial. The
## first time the man walks in, it marks Event in GameState and says so through reached, and Main,
## which holds the level in its slot, saves. From then on, the level starts with the man at Respawn:
## it goes before GameCamera in the scene, so the camera starts there too. Run on its own with F6,
## nothing saves, but GameState keeps the event until the game closes.

## The man walked in for the first time.
signal reached

## The group every save point joins, where Main finds them.
const GROUP: StringName = &"save_points"

## The event in GameState that says this stretch is over.
@export var event: StringName = &""
@export var player: Player
## Where the man starts once this stretch is over.
@export var respawn: Marker2D

@onready var _progress: GameProgress = get_node(^"/root/GameState") as GameProgress


## Joins the group on entering the tree, so Main finds the point as soon as it adds the level.
func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	assert(not event.is_empty(), "SavePoint: name the Event.")
	assert(player != null, "SavePoint: assign the man to Player.")
	assert(respawn != null, "SavePoint: assign a Marker2D to Respawn.")
	body_entered.connect(_on_body_entered)
	if _progress.has_event(event):
		player.global_position = respawn.global_position


func _on_body_entered(_body: Node2D) -> void:
	if _progress.has_event(event):
		return
	_progress.mark_event(event)
	reached.emit()
