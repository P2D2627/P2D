class_name OfferEffect
extends Resource

## What an accepted offer does, applied by Offers once the lines are over, never half way through
## them. Each kind of effect is a subclass that overrides apply() and hands the work to whoever does
## it through Offers, so a new kind of offer is a new subclass and its data, and nothing else learns
## that it exists.


## Does what the offer gave. This base does nothing, with a warning: an offer with no effect leaves
## Effect empty instead.
func apply(_offers: GameOffers) -> void:
	push_warning("OfferEffect: %s does not say what it does; give it a subclass of OfferEffect."
			% resource_path)
