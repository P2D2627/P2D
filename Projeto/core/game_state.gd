class_name GameProgress
extends Node

## What a run of the game has reached and must outlive the phases, as the autoload GameState, so the
## .dialogue lines reach it by that name: the man's name, whether he still holds the crucifix, and
## the events that happened once and must not happen again, such as meeting Velvet. With the moral
## record, in the autoload Moral, it is all a save keeps; a new phase and a death rebuild the rest
## from the level's scene. Until the next save, it counts for nothing: a death and Continue put back
## what the save holds. Only a new game starts it over. No script names this autoload: they go to
## /root/GameState, so they compile before the autoloads exist.

const DEFAULT_PLAYER_NAME: String = "..."

## The man's name in the lines. The name screen is to set it.
var player_name: String = DEFAULT_PLAYER_NAME
## False once the crucifix is lost for good: the next levels start without it.
var has_crucifix: bool = true

## The events that happened, each once.
var _events: Array[StringName] = []

@onready var _moral: GameMoral = get_node(^"/root/Moral") as GameMoral


func has_event(event: StringName) -> bool:
	return _events.has(event)


func mark_event(event: StringName) -> void:
	if not _events.has(event):
		_events.append(event)


func lose_crucifix() -> void:
	has_crucifix = false


## Back to the start of a new game, moral record included.
func reset() -> void:
	player_name = DEFAULT_PLAYER_NAME
	has_crucifix = true
	_events.clear()
	_moral.reset()


## Everything a save keeps, as plain values.
func to_save() -> Dictionary:
	var events: PackedStringArray = []
	for event: StringName in _events:
		events.append(String(event))
	return {
		"player_name": player_name,
		"has_crucifix": has_crucifix,
		"events": events,
		"moral": _moral.to_save(),
	}


## Puts back what to_save() gave. Anything missing or of the wrong type takes its value of a new
## game, so an older save still loads.
func from_save(data: Dictionary) -> void:
	reset()
	var saved_name: Variant = data.get("player_name")
	if saved_name is String:
		player_name = saved_name
	var saved_crucifix: Variant = data.get("has_crucifix")
	if saved_crucifix is bool:
		has_crucifix = saved_crucifix
	var saved_events: Variant = data.get("events")
	if saved_events is PackedStringArray:
		for event: String in saved_events:
			mark_event(StringName(event))
	var saved_moral: Variant = data.get("moral")
	if saved_moral is Dictionary:
		_moral.from_save(saved_moral)
