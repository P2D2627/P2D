class_name MoralStats
extends Resource

## The values of the man's hidden moral record (#169): what each thing he does adds to one total of
## points, and the totals at which his speech gets worse. What each temptation weighs is in its
## offer, in offers/; only what an unknown one weighs is here. MoralRecord reads them each time it
## adds the points up, so they can be tuned in the Remote tab while the game runs; the stage then
## changes with the next thing he does.

@export_group("Temptations")
## Points a temptation missing from the offer catalog adds. It still counts, with a warning, so a
## new offer is never free while its file waits to be made.
@export_range(0.0, 5.0, 0.05) var unknown_temptation_points: float = 1.0

@export_group("Tone")
## Points each arrogant answer adds. A humble answer adds none and takes none away: if it did, the
## player could learn to clean his speech by trial and error.
@export_range(0.0, 1.0, 0.01) var arrogant_answer_points: float = 0.15

@export_group("Listening")
## Seconds he can listen to an offer before refusing it with nothing counted.
@export_range(0.0, 30.0, 0.5, "suffix:s") var listening_grace: float = 3.0
## Points for each second he listens past Listening Grace.
@export_range(0.0, 1.0, 0.01, "suffix:/s") var listening_points_per_second: float = 0.1
## The most points one offer can add by listening, however long he stays.
@export_range(0.0, 5.0, 0.05) var most_listening_points: float = 0.5

@export_group("Stages")
## Points from which his speech takes the first worse variant (stage 1).
@export_range(0.0, 20.0, 0.05) var stage_1_points: float = 1.0
## Points from which it takes the worst (stage 2). Below Stage 1 Points, stage 2 starts there too.
@export_range(0.0, 20.0, 0.05) var stage_2_points: float = 3.0
