class_name GrantUpgradeEffect
extends OfferEffect

## Gives the man an upgrade, such as Lust's charm. GameState keeps it, and the first upgrade of the
## game costs him the crucifix, whichever it is.

## The upgrade's id, as GameState.has_upgrade() asks for it.
@export var upgrade: StringName = &""


func apply(offers: GameOffers) -> void:
	if upgrade.is_empty():
		push_warning("GrantUpgradeEffect: %s has no Upgrade, so nothing is given." % resource_path)
		return
	offers.grant_upgrade(upgrade)
