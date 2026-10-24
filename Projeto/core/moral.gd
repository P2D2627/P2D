class_name GameMoral
extends Node

## The man's hidden moral record (#169), as the autoload Moral, so the .dialogue lines and the
## offers reach it by that name. It only exposes a MoralRecord with the values in moral_stats.tres;
## the rules, and their tests, are there. Nothing on screen reads it.

## The stage his speech takes went up, or back to 0 on reset(); for portraits or sounds that react.
signal stage_changed(stage: int)

const STATS: MoralStats = preload("res://core/moral_stats.tres")

var _record: MoralRecord = MoralRecord.new(STATS)


func _init() -> void:
	_record.stage_changed.connect(stage_changed.emit)


## He accepted the temptation id. Offers calls it on an accept; the lines never do.
func take_temptation(id: StringName) -> void:
	_record.take_temptation(id)


## He answered in tone, &"humble" or &"arrogant".
func record_tone(tone: StringName) -> void:
	_record.record_tone(tone)


## He refused offer_id after listening to it for seconds.
func record_listening(offer_id: StringName, seconds: float) -> void:
	_record.record_listening(offer_id, seconds)


func has_taken(id: StringName) -> bool:
	return _record.has_taken(id)


## 0, 1 or 2: the variant of his lines, worse as it goes up.
func stage() -> int:
	return _record.stage()


## Back to an empty record, for a new game. Saving it waits for the saves.
func reset() -> void:
	_record.reset()
