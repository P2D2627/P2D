class_name OfferCatalog
extends Resource

## Every offer of the game, in one list, so the moral record and Offers find each one by its id.

@export var offers: Array[OfferData] = []


## The offer with that id, or null if there is none.
func find(id: StringName) -> OfferData:
	for offer: OfferData in offers:
		if offer != null and offer.id == id:
			return offer
	return null


func has(id: StringName) -> bool:
	return find(id) != null
