@tool
class_name ProximityUnlocker
extends Area2D

## A ring that opens one or more gates the first time the man comes inside it: no crucifix, no key, only being
## near. Put it inside whatever should open them when reached, such as level 1's biggest dog, so the ring goes
## where it goes; its origin is the ring's middle. Only the man is on its mask, and it works once. List the gates
## it opens in Gates.

## The man came inside the ring and its gates started to open.
signal activated

## The gates it opens.
@export var gates: Array[Gate] = []
## How far from its middle the man must come, in px.
@export_range(48.0, 4000.0, 8.0, "suffix:px") var reach: float = 288.0:
	set(value):
		reach = value
		_apply_reach()

var _is_activated: bool = false

@onready var _shape: CollisionShape2D = %Shape


func _ready() -> void:
	_apply_reach()
	if Engine.is_editor_hint():
		return
	body_entered.connect(_on_body_entered)


func is_activated() -> bool:
	return _is_activated


func _on_body_entered(body: Node2D) -> void:
	if _is_activated or not body is Player:
		return
	_is_activated = true
	for gate: Gate in gates:
		gate.unlock()
	activated.emit()


func _apply_reach() -> void:
	if not is_node_ready():
		return
	(_shape.shape as CircleShape2D).radius = reach
