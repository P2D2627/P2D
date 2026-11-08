class_name GameMoral
extends Node

## The man's hidden moral record (#169), as the autoload Moral, so the .dialogue lines and the
## offers reach it by that name. It only exposes a MoralRecord with the values in moral_stats.tres
## and the temptations' weights in the offer catalog; the rules, and their tests, are there.
## Nothing on screen reads it.

## The stage his speech takes went up, or back to 0 on reset(); for portraits or sounds that react.
signal stage_changed(stage: int)

const STATS: MoralStats = preload("res://core/moral_stats.tres")
var _record: MoralRecord = MoralRecord.new(STATS, GameOffers.get_catalog())


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


## He refused the offer id once more. Offers calls it on a refusal.
func record_refusal(id: StringName) -> void:
	_record.record_refusal(id)


func get_refusal_count(id: StringName) -> int:
	return _record.get_refusal_count(id)


## The longest he listened to offer_id before refusing it, in seconds; 0 if he never did.
func get_listening_seconds(offer_id: StringName) -> float:
	return _record.get_listening_seconds(offer_id)


func has_taken(id: StringName) -> bool:
	return _record.has_taken(id)


## 0, 1 or 2: the variant of his lines, worse as it goes up.
func stage() -> int:
	return _record.stage()


## Back to an empty record, for a new game.
func reset() -> void:
	_record.reset()


## Everything he did, as plain values a save can keep.
func to_save() -> Dictionary:
	return _record.to_save()


## Puts back what to_save() gave.
func from_save(data: Dictionary) -> void:
	_record.from_save(data)
