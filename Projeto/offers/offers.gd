class_name GameOffers
extends Node

## Every temptation of the game, as the autoload Offers, so the .dialogue lines reach it by that
## name: $> Offers.present(&"lust_shortcut") as the offer is made, then Offers.accept or
## Offers.refuse with his answer. What each offer is, who makes it and what it does, is data, in
## offer_catalog.tres; a new offer needs a file there and its lines, and no code.
## Accepting counts the temptation in Moral, once however often he says yes, says accepted, and
## applies the offer's effect once the lines are over, so a shortcut never changes the phase under
## an open balloon. Refusing counts the refusal and how long he listened, and says refused. Whoever
## cares listens to these signals, as Main for a shortcut and the level for the crucifix; Offers
## knows nothing of them. Each answer also adds a line to a log on disk, for playtests. No script
## names this autoload: they go to /root/Offers, so they compile before the autoloads exist.

## The offer was made and waits for his answer.
signal presented(offer: OfferData)
## He accepted the offer, for the first time; its effect comes when the lines are over.
signal accepted(offer: OfferData)
## He refused the offer.
signal refused(offer: OfferData)
## An accepted offer takes him to the phase at scene_path, at its ArrivalPoint arrival, or at its
## start if arrival is empty.
signal scene_requested(scene_path: String, arrival: StringName)

## Loaded with load() when asked for, not preloaded: the effects in it name this script, so a
## preload here would need this script compiled to compile itself.
const CATALOG_PATH: String = "res://offers/offer_catalog.tres"
const MS_PER_SECOND: float = 1000.0
const LOG_HEADER: String = "time,offer,choice,listened_s,run_s"

## The log every new Offers writes the answers to; empty keeps none. tests/support/base_test.gd
## empties it, so the tests never write to the playtests' log.
static var default_log_path: String = "user://offers_log.csv"

## The last offer made, for the debug keys; null until one is.
var last_presented: OfferData
## What gives the time, in ms since the game started: real time, since what counts is how long the
## player hesitates, paused or not. A test puts a clock of its own here.
var clock: Callable = Time.get_ticks_msec

## When each offer that waits for an answer was made, in ms since the game started.
var _presented_at: Dictionary[StringName, int] = {}
## The offers accepted while a balloon showed, to apply when it closes.
var _pending: Array[OfferData] = []
## True while a balloon shows lines.
var _in_dialogue: bool = false
var _log_path: String = default_log_path

@onready var _moral: GameMoral = get_node(^"/root/Moral") as GameMoral
@onready var _progress: GameProgress = get_node(^"/root/GameState") as GameProgress


func _ready() -> void:
	var dialogue_manager: Node = get_node_or_null(^"/root/DialogueManager")
	if dialogue_manager == null:
		push_warning("Offers: no DialogueManager, so effects apply as soon as an offer is accepted.")
		return
	dialogue_manager.dialogue_started.connect(_on_dialogue_started)
	dialogue_manager.dialogue_ended.connect(_on_dialogue_ended)


## The offer id is made: the time he listens starts now.
func present(id: StringName) -> void:
	var offer: OfferData = _find(id)
	if offer == null:
		return
	_presented_at[id] = clock.call()
	last_presented = offer
	presented.emit(offer)


## He accepted the offer id. Accepted before, it does nothing: it counted the first time. An id
## missing from the catalog still counts in Moral, as an unknown temptation, but says nothing and
## does nothing more.
func accept(id: StringName) -> void:
	var offer: OfferData = _find(id)
	if offer != null and _moral.has_taken(id):
		return
	var listened: float = _listened(id)
	_moral.take_temptation(id)
	_log(id, &"accepted", listened)
	if offer == null:
		return
	accepted.emit(offer)
	if offer.effect == null:
		return
	if _in_dialogue:
		_pending.append(offer)
	else:
		offer.effect.apply(self)


## He refused the offer id: it counts once more, and, if it was presented, so does how long he
## listened.
func refuse(id: StringName) -> void:
	var offer: OfferData = _find(id)
	var was_presented: bool = _presented_at.has(id)
	var listened: float = _listened(id)
	if was_presented:
		_moral.record_listening(id, listened)
	_moral.record_refusal(id)
	_log(id, &"refused", listened)
	if offer != null:
		refused.emit(offer)


## Whether he accepted the offer id; the lines ask Moral.has_taken() the same.
func has_accepted(id: StringName) -> bool:
	return _moral.has_taken(id)


## For the effects: gives him the upgrade id, through GameState, which keeps the rule of the
## crucifix.
func grant_upgrade(id: StringName) -> void:
	_progress.grant_upgrade(id)


## For the effects: asks whoever listens, Main, to take him to the phase at scene_path, at its
## ArrivalPoint arrival, or at its start if arrival is empty.
func request_scene(scene_path: String, arrival: StringName) -> void:
	scene_requested.emit(scene_path, arrival)


## Forgets the offers waiting for an answer or for their effect. Main calls it each time a level
## leaves the slot, since a balloon freed with its level never says its lines are over.
func clear() -> void:
	_presented_at.clear()
	_pending.clear()
	_in_dialogue = false
	last_presented = null


## Every offer of the game. load() keeps it in its cache, so asking again costs nothing.
static func get_catalog() -> OfferCatalog:
	return load(CATALOG_PATH) as OfferCatalog


## Where the answers are logged, as CSV; empty keeps none.
func set_log_path(path: String) -> void:
	_log_path = path


func _find(id: StringName) -> OfferData:
	var offer: OfferData = get_catalog().find(id)
	if offer == null:
		push_warning("Offers: %s is not in the offer catalog, offers/offer_catalog.tres." % id)
	return offer


## Seconds since the offer id was made, and it stops waiting; 0 if it never was.
func _listened(id: StringName) -> float:
	if not _presented_at.has(id):
		return 0.0
	var seconds: float = (clock.call() - _presented_at[id]) / MS_PER_SECOND
	_presented_at.erase(id)
	return seconds


func _log(id: StringName, choice: StringName, listened: float) -> void:
	if _log_path.is_empty():
		return
	var is_new: bool = not FileAccess.file_exists(_log_path)
	var file: FileAccess = FileAccess.open(_log_path,
			FileAccess.WRITE if is_new else FileAccess.READ_WRITE)
	if file == null:
		push_warning("Offers: the log %s cannot be written (%s)."
				% [_log_path, error_string(FileAccess.get_open_error())])
		return
	if is_new:
		file.store_line(LOG_HEADER)
	file.seek_end()
	file.store_line("%s,%s,%s,%.2f,%.1f" % [Time.get_datetime_string_from_system(), id, choice,
			listened, clock.call() / MS_PER_SECOND])


func _on_dialogue_started(_resource: DialogueResource) -> void:
	_in_dialogue = true


func _on_dialogue_ended(_resource: DialogueResource) -> void:
	_in_dialogue = false
	var due: Array[OfferData] = _pending.duplicate()
	_pending.clear()
	for offer: OfferData in due:
		offer.effect.apply(self)
