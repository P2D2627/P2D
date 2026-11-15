@tool
class_name GateUnlocker
extends Node2D

## What opens one or more gates: the man raises the crucifix next to it. Its origin is the middle of
## its base, on the floor. It reaches the crucifix through a CrucifixSensor, so the crucifix does not
## know it exists, and it works once. List the gates it opens in Gates. For now it is a green block,
## until its art arrives.

## The crucifix reached it and its gates started to open.
signal activated

## The gates it opens.
@export var gates: Array[Gate] = []
## Its colour until it is used.
@export var idle_color: Color = Color(0.09, 0.69, 0.29):
	set(value):
		idle_color = value
		_show_state()
## Its colour once used, much darker, so it shows also to whom does not tell the colours apart well.
@export var used_color: Color = Color(0.05, 0.27, 0.13):
	set(value):
		used_color = value
		_show_state()

var _is_activated: bool = false

@onready var _sensor: CrucifixSensor = %CrucifixSensor
@onready var _drawing: Polygon2D = %Drawing


func _ready() -> void:
	_show_state()
	if Engine.is_editor_hint():
		return
	assert(not gates.is_empty(), "GateUnlocker %s: list the gates it opens in Gates." % name)
	_sensor.repelled.connect(_on_sensor_repelled)


func is_activated() -> bool:
	return _is_activated


func _on_sensor_repelled(_origin: Vector2) -> void:
	if _is_activated:
		return
	_is_activated = true
	_show_state()
	for gate: Gate in gates:
		gate.unlock()
	activated.emit()


func _show_state() -> void:
	if is_node_ready():
		_drawing.color = used_color if _is_activated else idle_color
