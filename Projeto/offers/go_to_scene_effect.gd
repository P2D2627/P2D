class_name GoToSceneEffect
extends OfferEffect

## Takes the man to another phase, as a shortcut does: Offers asks for it with request_scene(), and
## Main changes the phase behind the same fade to black as a phase's exit.

## The phase he goes to.
@export_file("*.tscn") var scene_path: String = ""
## The id of the ArrivalPoint in that phase where he comes in; empty for the phase's own start.
@export var arrival: StringName = &""


func apply(offers: GameOffers) -> void:
	if scene_path.is_empty():
		push_warning("GoToSceneEffect: %s has no Scene Path, so he stays where he is."
				% resource_path)
		return
	offers.request_scene(scene_path, arrival)
