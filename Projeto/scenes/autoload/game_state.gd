class_name GameProgress
extends Node

## What a run of the game has reached and must outlive the phases, as the autoload GameState, so the
## .dialogue lines reach it by that name: the man's name, whether he still holds the crucifix, the
## upgrades he accepted, the events that happened once and must not happen again, such as meeting
## Velvet, and where in the saved phase he comes in. With the moral record, in the autoload Moral,
## it is all a save keeps; a new phase and a death rebuild the rest from the level's scene. Until
## the next save, it counts for nothing: a death and Continue put back what the save holds. Only a
## new game starts it over. No script names this autoload: they go to /root/GameState, so they
## compile before the autoloads exist.

## He was given the upgrade id, with the crucifix already taken away if it was his first.
signal upgrade_granted(id: StringName)

const DEFAULT_PLAYER_NAME: String = "..."

## The man's name in the lines. The name screen is to set it.
var player_name: String = DEFAULT_PLAYER_NAME
## False once the crucifix is lost for good: the next levels start without it.
var has_crucifix: bool = true
## The id of the ArrivalPoint where he comes into the phase, as after a shortcut; empty for the
## phase's own start. Main sets it before each save, so a death and Continue bring him back there.
var arrival_point: StringName = &""

## The events that happened, each once.
var _events: Array[StringName] = []
## The upgrades he accepted, each once, in the order he took them.
var _upgrades: Array[StringName] = []

@onready var _moral: GameMoral = get_node(^"/root/Moral") as GameMoral


func has_event(event: StringName) -> bool:
	return _events.has(event)


func mark_event(event: StringName) -> void:
	if not _events.has(event):
		_events.append(event)


func lose_crucifix() -> void:
	has_crucifix = false


## Gives him the upgrade id, once. The first upgrade of the game, whichever it is, costs him the
## crucifix: the cross will not stay with a demon's gift.
func grant_upgrade(id: StringName) -> void:
	if id.is_empty() or _upgrades.has(id):
		return
	_upgrades.append(id)
	if has_crucifix:
		lose_crucifix()
	upgrade_granted.emit(id)


func has_upgrade(id: StringName) -> bool:
	return _upgrades.has(id)


## Back to the start of a new game, moral record included.
func reset() -> void:
	player_name = DEFAULT_PLAYER_NAME
	has_crucifix = true
	arrival_point = &""
	_events.clear()
	_upgrades.clear()
	_moral.reset()


## Everything a save keeps, as plain values.
func to_save() -> Dictionary:
	var events: PackedStringArray = []
	for event: StringName in _events:
		events.append(String(event))
	var upgrades: PackedStringArray = []
	for upgrade: StringName in _upgrades:
		upgrades.append(String(upgrade))
	return {
		"player_name": player_name,
		"has_crucifix": has_crucifix,
		"arrival_point": String(arrival_point),
		"events": events,
		"upgrades": upgrades,
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
	var saved_arrival: Variant = data.get("arrival_point")
	if saved_arrival is String:
		arrival_point = StringName(saved_arrival)
	var saved_events: Variant = data.get("events")
	if saved_events is PackedStringArray:
		for event: String in saved_events:
			mark_event(StringName(event))
	var saved_upgrades: Variant = data.get("upgrades")
	if saved_upgrades is PackedStringArray:
		for upgrade: String in saved_upgrades:
			_upgrades.append(StringName(upgrade))
	var saved_moral: Variant = data.get("moral")
	if saved_moral is Dictionary:
		_moral.from_save(saved_moral)
