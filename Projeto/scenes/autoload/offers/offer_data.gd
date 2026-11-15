class_name OfferData
extends Resource

## One temptation of the game, as data: who offers it, what, its price, what accepting it does and
## how much it weighs on the man's hidden moral record. The lines name it by Id; the catalog in
## offer_catalog.tres lists them all. A new offer is a new file of these, with no code.

## The id the lines use, as in Offers.accept(&"lust_shortcut").
@export var id: StringName = &""
## Who offers it, as the lines name the speaker.
@export var offerer: String = ""
## What is offered, in a few words, for whoever reads the data.
@export_multiline var what: String = ""
## The price as the offerer tells it. It is told, not taken: anything it really takes away is in
## Effect or in a rule of the game, as the crucifix lost with the first upgrade.
@export_multiline var cost: String = ""
## What accepting does; empty for an offer that only weighs on the record.
@export var effect: OfferEffect
## Points it adds to the moral record once accepted. Each toll stolen in Greed weighs less than a
## shortcut, since that level has three. Read each time the points are added up, so it can be tuned
## in the Remote tab.
@export_range(0.0, 5.0, 0.05) var moral_weight: float = 1.0
