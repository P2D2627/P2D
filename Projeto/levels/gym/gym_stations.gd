class_name GymStations
extends Node

## Where the man starts in the gym (ADR 0036). The gym restarts as any level does, as a new copy of
## itself, so nothing from the death carries over; this only changes where the new man stands: at the
## start of the station he died in, not of the whole gym. It is the gym's alone, not the game's
## checkpoint. The station is kept in a static, which lasts past the reload, and only once the level
## asks to start over: a gym left for the menu after a death starts at the first station next time.
## It must come before the GameCamera in the gym's tree, so the camera starts on the man where he
## was put.
## The number keys 1 to 9, and 0 for the tenth, put the man at a station's start, as he is, with
## his SP. Not while he is
## held, as the grab goes on between him and the demon, nor once he is dead, and not a key the
## controls give to an action, as a Custom profile can.

## The station the 0 key takes the man to, from 0.
const TENTH_STATION: int = 9

## The gym's man.
@export var player: Player
## The gym's root, whose restart keeps the station the man died in.
@export var level: Level
## The man's GrabEscape, so the number keys do nothing while he is held. Empty: they always work.
@export var grab_escape: GrabEscape
## Each station's start, left to right. Each station runs from its start to the next one.
@export var starts: Array[Marker2D] = []

## The station the man died in, for the next copy of the gym; -1 when he has not died.
static var _died_in: int = -1

## The station the man died in, until the level asks to start over; -1 while he lives.
var _dying_in: int = -1


func _ready() -> void:
	assert(player != null, "GymStations: assign the gym's Player to Player.")
	assert(level != null, "GymStations: assign the gym's root Level to Level.")
	assert(not starts.is_empty(), "GymStations: add each station's start to Starts.")
	var station: int = clampi(_died_in, 0, starts.size() - 1)
	_died_in = -1
	player.global_position = starts[station].global_position
	player.reset_physics_interpolation()
	player.died.connect(_on_player_died)
	level.restart_requested.connect(_on_level_restart_requested)


func _unhandled_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo or _is_an_action(key):
		return
	var station: int = station_of_key(key.physical_keycode)
	if station < 0 or station >= starts.size():
		return
	get_viewport().set_input_as_handled()
	if _dying_in >= 0 or (grab_escape != null and grab_escape.is_held()):
		return
	player.global_position = starts[station].global_position
	player.velocity = Vector2.ZERO
	player.reset_physics_interpolation()


## The station a number key takes the man to, from 0, with 0 as the tenth, after 9 on the keyboard;
## -1 for any other key.
static func station_of_key(keycode: Key) -> int:
	if keycode >= KEY_1 and keycode <= KEY_9:
		return keycode - KEY_1
	if keycode == KEY_0:
		return TENTH_STATION
	return -1


## The station x is in: the last one whose start is at or left of x, and the first before them all.
func station_at(x: float) -> int:
	var station: int = 0
	for i: int in starts.size():
		if starts[i].global_position.x <= x:
			station = i
	return station


func _is_an_action(key: InputEventKey) -> bool:
	for action: StringName in InputMap.get_actions():
		if key.is_action(action, true):
			return true
	return false


func _on_player_died() -> void:
	_dying_in = station_at(player.global_position.x)


func _on_level_restart_requested() -> void:
	_died_in = _dying_in
