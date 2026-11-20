extends Node2D
## PROTOTYPE (#257): runs level 1 as it is, with the lighting rig added at run time, so level1.tscn
## never changes. Run this scene with F6. When the man dies, the level asks to start over; as Main
## does in the game, this puts a new copy in its place, and the rig's settings carry over. The rig's
## settings and keys are on the lighting page of the level's debug overlay (F3).

const LightingRig := preload("res://scenes/levels/prototypes/lighting/lighting_rig.gd")

@export var level_scene: PackedScene

var _level: Level


func get_rig() -> LightingRig:
	return _level.get_node_or_null("LightingRig") as LightingRig


func _ready() -> void:
	_load_level()


func _load_level() -> void:
	_level = level_scene.instantiate() as Level
	add_child(_level)
	_level.restart_requested.connect(_on_restart_requested)
	var rig := LightingRig.new()
	rig.name = "LightingRig"
	_level.add_child(rig)


func _on_restart_requested() -> void:
	_swap_level.call_deferred()


func _swap_level() -> void:
	remove_child(_level)
	_level.queue_free()
	_load_level()
