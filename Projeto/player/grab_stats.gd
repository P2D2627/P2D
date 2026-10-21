class_name GrabStats
extends Resource

## The values of the grab (ADR 0021): how long the man has before he dies, how many presses, or how
## long holding, break him free of one demon and of each one that joins, and how the bar goes down
## when he stops. GrabRules reads them each time it uses them, so they can be tuned in the Remote
## tab while the game runs.

@export_group("Time")
## Seconds from the grab to the man's death, if he has not broken free by then. The drawing sinks
## at this pace. A second demon joining leaves it as it is.
@export_range(0.5, 10.0, 0.1, "suffix:s") var time_to_die: float = 3.0

@export_group("Presses")
## Presses that break the man free of one demon. At least 1, so a grab never ends at once.
@export_range(1, 50, 1) var presses_to_escape: int = 8
## Presses added for each demon that joins the grab. What the man pressed before stays.
@export_range(0, 50, 1) var extra_presses_per_demon: int = 6

@export_group("Hold")
## Seconds of holding that break the man free of one demon, when the Options ask for holding. They
## add up, but letting go for longer than Drain Delay takes some back.
@export_range(0.1, 10.0, 0.1, "suffix:s") var hold_time_to_escape: float = 1.2
## Seconds of holding added for each demon that joins the grab. Two demons should still fit in Time
## To Die, or holding never breaks free.
@export_range(0.0, 10.0, 0.1, "suffix:s") var extra_hold_time_per_demon: float = 0.9

@export_group("Drain")
## Seconds with no press and no holding before the bar starts to go down. Pressing at least this
## often keeps all of it: 0.25 s is 4 presses a second.
@export_range(0.0, 2.0, 0.05, "suffix:s") var drain_delay: float = 0.25
## Share of the full bar that goes each second once Drain Delay has passed. At 0 it never drains.
@export_range(0.0, 2.0, 0.05, "suffix:/s") var drain_per_second: float = 0.5
