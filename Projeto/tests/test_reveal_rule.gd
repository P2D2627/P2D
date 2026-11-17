# Checks RevealRule on its own, without a scene (#253). A new rule draws nothing and has seen
# nothing. Seen, it fades in over Fade In Time, in even steps. Out of sight, it stays drawn for
# Linger Time and then fades out over Fade Out Time; seen again within Linger Time, it never starts
# to fade. What was never seen stays undrawn, however long it waits. One that remembers stays drawn
# once seen, and then has nothing left to change. Show Hidden draws all, but is not seeing: turned
# off, what was never seen fades out again, and one that remembers has nothing to keep. Times of 0
# make each change at once. A negative, infinite or nan time step changes nothing, and the opacity
# never leaves 0 to 1, whatever the step. reveal_now() draws it in full at once and counts it as
# just seen: out of sight, it lingers from then before fading. Seen in part, it fades in only to
# that share and lingers there before fading out; seen in full and then in part, it fades down to
# the share at Fade Out Time's pace, and a share over 1 counts as 1.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_reveal_rule.gd
extends "res://tests/support/player_test.gd"

## The values the cases are written for, so tuning the game changes no case.
const FADE_IN: float = 0.2
const FADE_OUT: float = 0.4
const LINGER: float = 0.25
## A time step that never lands on Linger Time, so rounding cannot move the edge.
const STEP: float = 0.1
## How far apart two opacities can be and still count as the same.
const TOLERANCE: float = 0.0001


func _initialize() -> void:
	var results: Array[bool] = []
	results.append(_a_new_rule_draws_nothing())
	results.append(_seen_it_fades_in_evenly())
	results.append(_out_of_sight_it_lingers_then_fades_out())
	results.append(_seen_again_while_lingering_it_never_fades())
	results.append(_never_seen_stays_undrawn())
	results.append(_one_that_remembers_stays_drawn_and_settles())
	results.append(_show_hidden_draws_all_but_is_not_seeing())
	results.append(_zero_times_change_at_once())
	results.append(_bad_time_steps_change_nothing())
	results.append(_the_opacity_stays_between_0_and_1())
	results.append(_reveal_now_draws_it_at_once_as_just_seen())
	results.append(_seen_in_part_it_fades_in_to_that_share_and_lingers_there())
	results.append(_seen_in_full_then_in_part_it_fades_down_to_the_share())
	finish(results)


func _seen_in_part_it_fades_in_to_that_share_and_lingers_there() -> bool:
	var rule: RevealRule = _rule()
	var halfway: float = rule.step(true, false, FADE_IN / 4.0, 0.5)
	var at_share: float = rule.step(true, false, FADE_IN / 4.0, 0.5)
	var held: float = rule.step(true, false, FADE_IN, 0.5)
	var lingering: float = rule.step(false, false, STEP)
	for i: int in roundi((LINGER + FADE_OUT) / STEP) + 2:
		rule.step(false, false, STEP)
	var gone: float = rule.get_opacity()
	return report(absf(halfway - 0.25) < TOLERANCE and absf(at_share - 0.5) < TOLERANCE
			and absf(held - 0.5) < TOLERANCE and absf(lingering - 0.5) < TOLERANCE
			and is_zero_approx(gone),
			("Seen in half: %s, %s, then %s still seen, %s just out of sight, %s long after "
			+ "(expected 0.25, 0.5, 0.5, 0.5, 0)") % [halfway, at_share, held, lingering, gone])


func _seen_in_full_then_in_part_it_fades_down_to_the_share() -> bool:
	var rule: RevealRule = _seen_rule()
	var falling: float = rule.step(true, false, STEP, 0.5)
	for i: int in roundi(FADE_OUT / STEP):
		rule.step(true, false, STEP, 0.5)
	var settled: float = rule.get_opacity()
	var over_one: float = rule.step(true, false, FADE_IN, 1.5)
	return report(absf(falling - (1.0 - STEP / FADE_OUT)) < TOLERANCE
			and absf(settled - 0.5) < TOLERANCE and absf(over_one - 1.0) < TOLERANCE,
			("Seen in full, then in half: %s after one step, %s once settled; then a share of 1.5: %s "
			+ "(expected %s, 0.5, 1)") % [falling, settled, over_one, 1.0 - STEP / FADE_OUT])


func _reveal_now_draws_it_at_once_as_just_seen() -> bool:
	var rule: RevealRule = _rule()
	var at_once: float = rule.reveal_now()
	var lingering: float = rule.step(false, false, STEP)
	return report(is_equal_approx(at_once, 1.0) and is_equal_approx(lingering, 1.0)
			and rule.has_seen(),
			("reveal_now() on a new rule: %s at once, then %s one step out of sight (expected 1 and "
			+ "1, lingering), seen %s") % [at_once, lingering, rule.has_seen()])


func _a_new_rule_draws_nothing() -> bool:
	var rule: RevealRule = _rule()
	return report(is_zero_approx(rule.get_opacity()) and not rule.has_seen()
			and not rule.is_settled(),
			"A new rule: opacity %s, seen %s, settled %s"
			% [rule.get_opacity(), rule.has_seen(), rule.is_settled()])


func _seen_it_fades_in_evenly() -> bool:
	var rule: RevealRule = _rule()
	var halfway: float = rule.step(true, false, FADE_IN / 2.0)
	var full: float = rule.step(true, false, FADE_IN / 2.0)
	return report(absf(halfway - 0.5) < TOLERANCE and absf(full - 1.0) < TOLERANCE
			and rule.has_seen(),
			"Seen for half and then all of Fade In Time: %s, then %s (expected 0.5, then 1)"
			% [halfway, full])


func _out_of_sight_it_lingers_then_fades_out() -> bool:
	var rule: RevealRule = _seen_rule()
	var lingering: Array[float] = []
	for i: int in 2:
		lingering.append(rule.step(false, false, STEP))
	var fading: float = rule.step(false, false, STEP)
	var steps_to_gone: int = 1
	while rule.get_opacity() > 0.0 and steps_to_gone < 100:
		rule.step(false, false, STEP)
		steps_to_gone += 1
	var expected_steps: int = roundi(FADE_OUT / STEP)
	return report(lingering == [1.0, 1.0] and absf(fading - (1.0 - STEP / FADE_OUT)) < TOLERANCE
			and steps_to_gone == expected_steps,
			("Out of sight: %s while lingering, %s on the first step past Linger Time, gone after %d "
			+ "steps (expected [1, 1], %s, %d)")
			% [lingering, fading, steps_to_gone, 1.0 - STEP / FADE_OUT, expected_steps])


func _seen_again_while_lingering_it_never_fades() -> bool:
	var rule: RevealRule = _seen_rule()
	var lowest: float = 1.0
	for i: int in 10:
		var seen: bool = i % 2 == 1
		lowest = minf(lowest, rule.step(seen, false, STEP))
	return report(is_equal_approx(lowest, 1.0),
			"Seen every other step, under Linger Time apart: lowest opacity %s (expected 1)"
			% lowest)


func _never_seen_stays_undrawn() -> bool:
	var rule: RevealRule = _rule()
	var highest: float = 0.0
	for i: int in 20:
		highest = maxf(highest, rule.step(false, false, STEP))
	return report(is_zero_approx(highest) and not rule.has_seen(),
			"Never seen, for 20 steps: highest opacity %s (expected 0)" % highest)


func _one_that_remembers_stays_drawn_and_settles() -> bool:
	var rule: RevealRule = RevealRule.new(true, FADE_IN, FADE_OUT, LINGER)
	var settled_while_fading_in: bool = false
	rule.step(true, false, FADE_IN / 2.0)
	settled_while_fading_in = rule.is_settled()
	rule.step(true, false, FADE_IN / 2.0)
	var lowest: float = 1.0
	for i: int in 30:
		lowest = minf(lowest, rule.step(false, false, STEP))
	return report(is_equal_approx(lowest, 1.0) and rule.is_settled()
			and not settled_while_fading_in,
			("Remembers, seen and then out of sight for 30 steps: lowest opacity %s (expected 1), "
			+ "settled %s (expected true), settled while fading in %s (expected false)")
			% [lowest, rule.is_settled(), settled_while_fading_in])


func _show_hidden_draws_all_but_is_not_seeing() -> bool:
	var rule: RevealRule = _rule()
	var shown: float = rule.step(false, true, FADE_IN)
	var off: float = rule.step(false, false, FADE_OUT)
	var remembering: RevealRule = RevealRule.new(true, FADE_IN, FADE_OUT, LINGER)
	remembering.step(false, true, FADE_IN)
	var remembering_off: float = remembering.step(false, false, FADE_OUT)
	return report(is_equal_approx(shown, 1.0) and is_zero_approx(off) and not rule.has_seen()
			and is_zero_approx(remembering_off) and not remembering.is_settled(),
			("Show Hidden on, never seen: %s; turned off: %s; one that remembers, turned off: %s "
			+ "(expected 1, 0 and 0, with nothing seen)") % [shown, off, remembering_off])


func _zero_times_change_at_once() -> bool:
	var rule: RevealRule = RevealRule.new(false, 0.0, 0.0, 0.0)
	var shown: float = rule.step(true, false, STEP / 10.0)
	var gone: float = rule.step(false, false, STEP / 10.0)
	return report(is_equal_approx(shown, 1.0) and is_zero_approx(gone),
			"All times 0: %s when seen and %s on the next step out of sight (expected 1, then 0)"
			% [shown, gone])


func _bad_time_steps_change_nothing() -> bool:
	var rule: RevealRule = _rule()
	rule.step(true, false, FADE_IN / 2.0)
	var before: float = rule.get_opacity()
	var after: Array[float] = []
	for bad: float in [-STEP, INF, -INF, NAN]:
		after.append(rule.step(true, false, bad))
	var unchanged: bool = true
	for opacity: float in after:
		unchanged = unchanged and is_equal_approx(opacity, before)
	return report(unchanged, "Time steps -%s, inf, -inf and nan: %s (expected all %s)"
			% [STEP, after, before])


func _the_opacity_stays_between_0_and_1() -> bool:
	var rule: RevealRule = _rule()
	var after_long_sight: float = rule.step(true, false, 1000.0)
	var after_long_dark: float = rule.step(false, false, 1000.0)
	return report(is_equal_approx(after_long_sight, 1.0) and is_zero_approx(after_long_dark),
			"A step of 1000 s seen and then unseen: %s, then %s (expected 1, then 0)"
			% [after_long_sight, after_long_dark])


## A rule that forgets, with the values above.
func _rule() -> RevealRule:
	return RevealRule.new(false, FADE_IN, FADE_OUT, LINGER)


## A rule that forgets and has just been seen in full.
func _seen_rule() -> RevealRule:
	var rule: RevealRule = _rule()
	rule.step(true, false, FADE_IN)
	return rule
