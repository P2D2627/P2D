@tool
class_name GateUnlocker
extends Node2D

## What opens one or more gates: the man stands by it and presses Use Action (E, Interact). Its origin
## is the middle of its base, on the floor. While he is inside its Use Area and it is still unused,
## its key shows over it, as a character's does. It works once. List the gates it opens in Gates.
## With a Cutscene, it plays it first, and the gates open when the cutscene's camera gets to its first
## shot, so the player sees them open; without one, or when the cutscene does not play (one that plays
## once in the game and was seen), they open at once. For now it is a green block, until its art
## arrives.

## The man used it and its gates started to open, or will when its cutscene's camera gets there.
signal activated

## The gates it opens.
@export var gates: Array[Gate] = []
## What the man presses next to it to use it.
@export var use_action: StringName = &"interact"
## Plays when it is used, to show the gates opening. Empty: they open at once.
@export var cutscene: CameraCutscene
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
## True while the man is inside its Use Area.
var _player_near: bool = false

@onready var _use_area: Area2D = %UseArea
@onready var _use_key: KeyPrompt = %UseKey
@onready var _drawing: Polygon2D = %Drawing


func _ready() -> void:
	_show_state()
	if Engine.is_editor_hint():
		set_physics_process(false)
		return
	assert(not gates.is_empty(), "GateUnlocker %s: list the gates it opens in Gates." % name)
	assert(InputMap.has_action(use_action), "GateUnlocker %s: Use Action %s is not in the Input Map."
			% [name, use_action])
	_use_area.body_entered.connect(_on_use_area_body_entered)
	_use_area.body_exited.connect(_on_use_area_body_exited)


func _physics_process(_delta: float) -> void:
	if _player_near and not _is_activated and Input.is_action_just_pressed(use_action):
		activate()


func is_activated() -> bool:
	return _is_activated


## True while the man is close enough to use it, so its key shows.
func is_player_near() -> bool:
	return _player_near


## Uses it, as the man's press of Use Action next to it does: once, its gates open, after its
## Cutscene's camera gets to them when it has one that plays.
func activate() -> void:
	if _is_activated:
		return
	_is_activated = true
	_show_state()
	activated.emit()
	if cutscene != null and cutscene.play():
		cutscene.shot_reached.connect(_unlock_gates.unbind(1), CONNECT_ONE_SHOT)
	else:
		_unlock_gates()


func _unlock_gates() -> void:
	for gate: Gate in gates:
		if is_instance_valid(gate):
			gate.unlock()


func _on_use_area_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_near = true
		_show_state()


func _on_use_area_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_near = false
		_show_state()


func _show_state() -> void:
	if not is_node_ready():
		return
	_drawing.color = used_color if _is_activated else idle_color
	_use_key.visible = _player_near and not _is_activated
