class_name DeathOfferStats
extends Resource

## The values of the shortcut offers that come after deaths: how much dying it takes before the
## level's demon offers to skip the rest, and how much sooner each next offer comes. Each death in
## a phase with offers adds pressure, more in a zone where he already died; once the pressure
## reaches the threshold, an offer waits for him at that zone. No threshold is a fixed number: each
## is drawn within a range, so the player can never count to it. DeathOfferPacer reads these each
## time, so they can be tuned in the Remote tab while the game runs.

@export_group("Phases")
## The first phase of a level whose deaths can bring an offer: phase 1 is always played through.
@export_range(1, 9) var first_phase_with_offers: int = 2

@export_group("First offer")
## The least pressure the first offer can need: with one death in each zone, that many deaths.
@export_range(1.0, 30.0, 0.5) var first_offer_min: float = 4.0
## The most pressure the first offer can need. Each run draws a value between the two.
@export_range(1.0, 30.0, 0.5) var first_offer_max: float = 7.0

@export_group("Pressure")
## What a death adds on top of 1 for each death he already had in the same zone: the same spot
## brings the offer sooner.
@export_range(0.0, 3.0, 0.05) var same_spot_bonus: float = 0.5

@export_group("Next offers")
## Each next offer needs this share of what the last one needed: below 1, they come ever sooner.
@export_range(0.1, 1.0, 0.05) var gap_shrink: float = 0.7
## The least pressure any offer needs, so they never come at every death.
@export_range(1.0, 10.0, 0.5) var min_gap: float = 1.5
## How far each next threshold is drawn around its value, as a share of it, either way.
@export_range(0.0, 0.5, 0.01) var gap_jitter: float = 0.15
