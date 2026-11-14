class_name AsmodeusDirector
extends Node

## When Asmodeus talks in a level, and from which cue; what she says is all in the .dialogue file.
## - The first time the man reaches a save point whose Starts Phase is in Phase Cues, she talks from
##   that phase's cue: Lust's shortcut, at the start of phases 2 and 3.
## - When RunStats holds an offer for his deaths, she talks from Death Cue as soon as he stands in
##   the zone it is for: at once if he comes back to life inside it, or as he walks in, before he
##   tries it again. While no offer waits, nothing is checked.
## - At the level's Exit, she talks from each of Ending Cues in turn (the gift, then the stairs), and
##   only then does the exit lead on. Exit must have Walk In Leads On off.
## A talk counts as had once he answers its offer, not when it starts: the answer marks it in
## GameState, as ANSWERED_PREFIX and the cue, and Main saves at once. Left before the answer, as by
## quitting, nothing of it is kept, and the talk comes again: a phase's cue as soon as he stands in
## the phase, a death offer once he walks into its zone, an ending cue at the exit.
## Once he accepts Shortcut, RunStats makes no more offers for his deaths.

## Before a cue, the GameState event that says its offer was answered.
const ANSWERED_PREFIX: String = "answered_"

## The Asmodeus who talks.
@export var asmodeus: Asmodeus
@export var level: Level
## The cue for the start of each phase, by the phase's number.
@export var phase_cues: Dictionary[int, String] = {2: "asmodeus_offer", 3: "asmodeus_second_offer"}
## The cue for an offer his deaths brought.
@export var death_cue: String = "asmodeus_deaths"
## The level's last exit, which leads on only after the Ending Cues.
@export var exit: PhaseExit
## The cues at the exit, in this order.
@export var ending_cues: Array[String] = ["asmodeus_gift", "stairs"]
## The offer that, accepted, ends the offers for his deaths.
@export var shortcut: StringName = &"lust_shortcut"

## True once the ending started, so walking in again does nothing.
var _ending: bool = false
## A phase's cue he reached and has not answered, said once he stands on the floor; empty for none.
var _due_cue: String = ""
var _run_stats: GameRunStats
var _progress: GameProgress


func _ready() -> void:
	assert(asmodeus != null, "AsmodeusDirector: assign Asmodeus.")
	assert(level != null, "AsmodeusDirector: assign the Level.")
	_run_stats = get_node(^"/root/RunStats") as GameRunStats
	_progress = get_node(^"/root/GameState") as GameProgress
	var offers: GameOffers = get_node_or_null(^"/root/Offers") as GameOffers
	if offers != null:
		offers.accepted.connect(_on_offer_answered.bind(true))
		offers.refused.connect(_on_offer_answered.bind(false))
	var due_phase: int = 0
	for node: Node in get_tree().get_nodes_in_group(SavePoint.GROUP):
		var save_point: SavePoint = node as SavePoint
		if save_point == null or not level.is_ancestor_of(save_point):
			continue
		var phase: int = save_point.starts_phase
		if not phase_cues.has(phase) or is_answered(phase_cues[phase]):
			continue
		if not save_point.is_reached():
			save_point.reached.connect(_say.bind(phase_cues[phase]))
		elif phase > due_phase:
			# Reached in the save, and left before the answer: it comes again.
			due_phase = phase
	if due_phase > 0:
		_due_cue = phase_cues[due_phase]
	if exit != null:
		if exit.walk_in_leads_on:
			push_warning("AsmodeusDirector: %s has Walk In Leads On, so it may lead on before the "
					% exit.name + "ending's lines.")
		exit.body_entered.connect(_on_exit_entered)


## Only while a phase's cue is due or an offer for his deaths waits: once he stands on the floor,
## or in the offer's zone, she talks.
func _physics_process(_delta: float) -> void:
	if _due_cue.is_empty() and not _run_stats.has_death_offer():
		return
	if asmodeus.is_talking() or _ending:
		return
	var player: Player = level.player
	if player.is_dead() or not player.is_on_floor():
		return
	if not _due_cue.is_empty():
		var cue: String = _due_cue
		_due_cue = ""
		_say(cue)
	elif level.zone_at(player.global_position) == _run_stats.get_death_offer_zone():
		_say(death_cue)


## Whether the offer of cue was answered, in GameState.
func is_answered(cue: String) -> bool:
	return _progress.has_event(StringName(ANSWERED_PREFIX + cue))


## She comes next to the man and talks from cue.
func _say(cue: String) -> void:
	asmodeus.appear_at(level.player.global_position)
	asmodeus.talk(cue)


func _on_exit_entered(_body: Node2D) -> void:
	if _ending:
		return
	_ending = true
	for cue: String in ending_cues:
		if is_answered(cue):
			continue
		if asmodeus.is_talking():
			await asmodeus.talk_ended
		if not is_inside_tree():
			return
		_say(cue)
		await asmodeus.talk_ended
		if not is_inside_tree():
			return
	exit.lead_on()


## He answered an offer in her talk: the talk was had. Main saves on the same answer, after this.
func _on_offer_answered(offer: OfferData, accepted: bool) -> void:
	if accepted and offer.id == shortcut:
		_run_stats.close_death_offers()
	var cue: String = asmodeus.get_talking_cue()
	if cue.is_empty():
		return
	if cue == death_cue:
		_run_stats.take_death_offer()
	else:
		_progress.mark_event(StringName(ANSWERED_PREFIX + cue))
