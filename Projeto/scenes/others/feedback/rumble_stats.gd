class_name RumbleStats
extends Resource

## How the controller vibrates at each moment and in each state the man's body feels, on a ladder of
## four steps, one group each, by how often each comes and how much it matters: the most frequent
## stay short and the rare, serious ones stand out. Ticks, the most frequent, last 0.1 s at most. The
## moves' ticks thump on the strong motor, below Hit, with a little of the weak one for an edge: the
## strong motor takes a moment to turn, and a tick on the weak motor alone, near where it is felt at
## all, felt like a tickle in play and then not at all. The ticks that come over a held vibration run
## the weak motor higher, and the held vibration ducks under them (RumbleRules), as it would hide
## them otherwise. Blows, a few a minute, run both motors, the strong one below a half, and fade
## fast. Grave moments, rare and with consequences, are the only ones that run the strong motor at a
## half or more, and they fade slowly; his death is the strongest on both motors
## and the longest. Held states run low, 0.4 at most on each motor, and throb while they last; they
## start where a motor is still felt, as one asked for less barely turns, and a pulse reads over them
## on the motors it runs. Pulses that come together do not add up, as each motor runs at the
## strongest (RumbleRules). The screen shakes only for the blows and the grave moments (ImpactStats).

@export_group("Ticks")
## A jump, off the floor or off a wall: a short thump, mostly on the strong motor, that fades in its
## second half, so it lands as a thud and not as a buzz.
@export var jump: RumblePulse = RumblePulse.new(0.2, 0.4, 0.1, 0.5)
## The shortest landing PlayerSounds hears: a softer thud than a jump, as he lands all the time. A
## longer fall lands harder, along Landing Growth, up to Hard Landing.
@export var landing: RumblePulse = RumblePulse.new(0.15, 0.3, 0.08, 0.5)
## How a landing grows from Landing to Hard Landing as the fall gets longer: 1 in a straight line;
## more than 1 slowly over the short falls of everyday jumps and fast near Hard Land Height
## (PlayerSounds), so only a long fall lands near Hard Landing.
@export_range(1.0, 4.0, 0.1) var landing_growth: float = 2.0
## His head hits a ceiling: a bump on both motors.
@export var head_bump: RumblePulse = RumblePulse.new(0.4, 0.3, 0.08, 0.5)
## He gets on a wall: a soft contact on both motors.
@export var on_wall: RumblePulse = RumblePulse.new(0.25, 0.25, 0.07, 0.5)
## Each press of Jump that counts towards breaking free. It comes over the grab's held vibration,
## whose strong motor hides a light tick, so it is the firmest tick, as strong as his death on the
## weak motor at most; short, so even ten presses a second stay ticks apart. It runs at Struggle
## Start Share of its level while he has made no headway and grows to all of it as he gets close to
## breaking free. Holding Jump, with Hold To Escape, gives none.
@export var struggle: RumblePulse = RumblePulse.new(0.7, 0.0, 0.08)
## The share of Struggle's level while he has made no headway towards breaking free.
@export_range(0.0, 1.0, 0.05) var struggle_start_share: float = 0.8
## Something the crucifix pushes comes into its light, such as a demon running at it: a knock in the
## hands. It comes over Crucifix Held, so it runs the weak motor higher than the moves' ticks.
@export var crucifix_struck: RumblePulse = RumblePulse.new(0.5, 0.0, 0.08)

@export_group("Blows")
## A hit from a demon or a hazard: the blow felt most often, so the options play it as a sample. No
## tick runs the strong motor as high as it, nor for as much over its time, so a hit always weighs
## more than a move.
@export var hit: RumblePulse = RumblePulse.new(0.5, 0.45, 0.16, 0.8)
## A demon grabs him, right after the hit that grabs; Grab Sink then holds while he is held.
@export var grab: RumblePulse = RumblePulse.new(0.3, 0.35, 0.2, 0.7)
## He breaks free: a light snap, as the relief comes from Grab Sink stopping.
@export var break_free: RumblePulse = RumblePulse.new(0.45, 0.15, 0.12, 0.6)
## A landing after a fall of Hard Land Height (PlayerSounds) or more: the top of the landings.
@export var hard_landing: RumblePulse = RumblePulse.new(0.35, 0.45, 0.16, 0.8)
## He raises the crucifix; Crucifix Held then holds while it is up.
@export var crucifix_raised: RumblePulse = RumblePulse.new(0.4, 0.1, 0.12, 0.6)
## The crucifix's use runs out with Crucifix still held: from a blow's level down to nothing over its
## whole time, as its power gives out, so Crucifix Held does not just stop. Let go before that, it
## stops without one.
@export var crucifix_ran_out: RumblePulse = RumblePulse.new(0.5, 0.15, 0.5, 1.0)

@export_group("Grave")
## He dies: the strongest on both motors and the longest.
@export var death: RumblePulse = RumblePulse.new(0.7, 1.0, 0.6, 0.9)
## His death on lethal spikes, on top of Death: a sharp, short stab on the weak motor, above Death's
## own there, so the spikes are felt before the strong motor fills in. It is part of his death, so it
## is the one pulse that may run above Death.
@export var spike_death: RumblePulse = RumblePulse.new(1.0, 0.0, 0.06)
## He loses the crucifix, for good.
@export var crucifix_lost: RumblePulse = RumblePulse.new(0.35, 0.75, 0.45, 0.85)
## A rock that breaks right where he is. Farther away it is weaker, as far as Rock Reach in
## ImpactStats, by the same share as the shake's trauma, so a far one runs as a blow or a tick.
@export var rock: RumblePulse = RumblePulse.new(0.3, 0.7, 0.3, 0.8)

@export_group("Held")
## While a demon holds him, mostly on the strong motor, so the ticks of his presses, on the weak one,
## do not hide it: Start Share of it as he is grabbed, growing to all of it as he sinks to his death.
@export var grab_sink: RumbleSustain = RumbleSustain.new(0.2, 0.4, 0.6, 2.0, 0.5)
## While the crucifix is up, his hands shaking with the effort, on the weak motor: Start Share of it
## until the crucifix warns it is about to come down (Warning Time, in its CrucifixStats), then
## growing to all of it as it comes down, with its light.
@export var crucifix_held: RumbleSustain = RumbleSustain.new(0.35, 0.0, 0.6, 3.0, 0.4)


## The share of Struggle's level for a press at progress towards breaking free, from 0 to 1: Struggle
## Start Share at 0, growing in a straight line to all of it at 1. A progress out of 0 to 1 is kept
## in range, and one that is not a number counts as 0.
func struggle_share(progress: float) -> float:
	var kept: float = 0.0 if is_nan(progress) else clampf(progress, 0.0, 1.0)
	return lerpf(struggle_start_share, 1.0, kept)


## The pulse of a landing share of the way from the shortest PlayerSounds hears, at 0, to a hard one,
## at 1: Landing blended towards Hard Landing by share raised to Landing Growth. A share out of 0 to 1
## is kept in range, and one that is not a number counts as 0.
func landing_at(share: float) -> RumblePulse:
	var kept: float = 0.0 if is_nan(share) else clampf(share, 0.0, 1.0)
	return landing.blended_with(hard_landing, pow(kept, landing_growth))
