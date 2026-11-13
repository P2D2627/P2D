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
## Once he accepts Shortcut, RunStats makes no more offers for his deaths.

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
var _run_stats: GameRunStats


func _ready() -> void:
	assert(asmodeus != null, "AsmodeusDirector: assign Asmodeus.")
	assert(level != null, "AsmodeusDirector: assign the Level.")
	_run_stats = get_node(^"/root/RunStats") as GameRunStats
	var offers: GameOffers = get_node_or_null(^"/root/Offers") as GameOffers
	if offers != null:
		offers.accepted.connect(_on_offer_accepted)
	for node: Node in get_tree().get_nodes_in_group(SavePoint.GROUP):
		var save_point: SavePoint = node as SavePoint
		if (save_point != null and level.is_ancestor_of(save_point)
				and phase_cues.has(save_point.starts_phase) and not save_point.is_reached()):
			save_point.reached.connect(_say.bind(phase_cues[save_point.starts_phase]))
	if exit != null:
		if exit.walk_in_leads_on:
			push_warning("AsmodeusDirector: %s has Walk In Leads On, so it may lead on before the "
					% exit.name + "ending's lines.")
		exit.body_entered.connect(_on_exit_entered)


## Only while an offer for his deaths waits: once he stands in its zone, she makes it.
func _physics_process(_delta: float) -> void:
	if not _run_stats.has_death_offer() or asmodeus.is_talking() or _ending:
		return
	var player: Player = level.player
	if player.is_dead() or not player.is_on_floor():
		return
	if level.zone_at(player.global_position) != _run_stats.get_death_offer_zone():
		return
	_run_stats.take_death_offer()
	_say(death_cue)


## She comes next to the man and talks from cue.
func _say(cue: String) -> void:
	asmodeus.appear_at(level.player.global_position)
	asmodeus.talk(cue)


func _on_exit_entered(_body: Node2D) -> void:
	if _ending:
		return
	_ending = true
	for cue: String in ending_cues:
		if asmodeus.is_talking():
			await asmodeus.talk_ended
		if not is_inside_tree():
			return
		_say(cue)
		await asmodeus.talk_ended
		if not is_inside_tree():
			return
	exit.lead_on()


func _on_offer_accepted(offer: OfferData) -> void:
	if offer.id == shortcut:
		_run_stats.close_death_offers()
