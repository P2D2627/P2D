# Checks GrabRules on its own, without a player or a scene (ADR 0021). One demon's grab frees the
# man on the last press it asks for. With no presses he dies on the frame Time To Die runs out, at
# 60 and at 120 Hz, and has sunk halfway at half the time. With no press and no holding, the bar
# stays for Drain Delay, then goes down at Drain Per Second, at 60 and at 120 Hz, and stops at 0;
# a press once per Drain Delay keeps all of it and, with the default values, frees him in time. A
# last press on the frame the time runs out frees him. A second demon asks for more presses and
# keeps the presses and the time; a third can't join. Holding frees him at Hold Time To Escape, at
# 60 and at 120 Hz, and with two demons, with the default values, still before he dies; letting go
# drains what was held, and holding again makes it up. Once he is free or dead, nothing changes him.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_grab_rules.gd
extends "res://tests/support/player_test.gd"

## Physics frames per second the tests advance at, and a fast monitor's rate to compare.
const HZ: int = 60
const FAST_HZ: int = 120
## Physics frames of each hold in the let-go case, and of the let-go between the two, longer than
## Drain Delay.
const HOLD_BURST_FRAMES: int = 36
const LET_GO_FRAMES: int = 30
## Presses before the drain case stops, and the seconds it watches the bar go down after Drain
## Delay.
const IDLE_PRESSES: int = 4
const DRAIN_WATCH_TIME: float = 0.5
## Physics frames the free and dead cases go on for, pressing and holding, to see nothing change.
const AFTER_FRAMES: int = 300
## Physics frames to give up after, well past any Time To Die.
const MOST_FRAMES: int = 2000


func _initialize() -> void:
	var results: Array[bool] = []
	results.append(_one_demon_frees_him_on_the_last_press())
	results.append(_with_no_presses_he_dies_at_time_to_die_at_60_and_120_hz())
	results.append(_idle_the_bar_stays_for_drain_delay_then_drains_at_60_and_120_hz())
	results.append(_a_press_once_per_drain_delay_keeps_the_bar_and_frees_him_in_time())
	results.append(_a_last_press_on_the_last_frame_frees_him())
	results.append(_a_second_demon_asks_for_more_and_keeps_presses_and_time())
	results.append(_a_third_demon_cant_join())
	results.append(_holding_frees_him_at_hold_time_also_with_two_demons())
	results.append(_letting_go_drains_what_was_held_and_holding_makes_it_up())
	results.append(_once_free_or_dead_nothing_changes())
	finish(results)


func _one_demon_frees_him_on_the_last_press() -> bool:
	var rules: GrabRules = GrabRules.new(GrabStats.new())
	var needed: int = rules.get_presses_needed()
	_press(rules, needed - 1)
	var held_one_short: bool = rules.get_state() == GrabRules.State.HELD
	var progress_one_short: float = rules.get_escape_progress()
	_press(rules, 1)
	return report(held_one_short
			and is_equal_approx(progress_one_short, float(needed - 1) / needed)
			and rules.get_state() == GrabRules.State.FREE,
			"%d presses asked: one short held %s, progress %.3f; the last one: %s"
			% [needed, held_one_short, progress_one_short, _state_name(rules)])


## Dies on the frame the time runs out, not one before, and has sunk halfway at half the time.
func _with_no_presses_he_dies_at_time_to_die_at_60_and_120_hz() -> bool:
	var stats: GrabStats = GrabStats.new()
	var passed: bool = true
	var lines: PackedStringArray = []
	for hz: int in [HZ, FAST_HZ]:
		var death_frame: int = roundi(stats.time_to_die * hz)
		var rules: GrabRules = GrabRules.new(stats)
		var frames: int = _frames_until_over(rules, hz, false)
		var halfway: GrabRules = GrabRules.new(stats)
		_wait(halfway, hz, roundi(stats.time_to_die * hz / 2.0))
		passed = (passed and frames == death_frame and rules.get_state() == GrabRules.State.DEAD
				and is_equal_approx(rules.get_sink(), 1.0)
				and is_equal_approx(halfway.get_sink(), 0.5))
		lines.append("%d Hz: %s on frame %d of %d, sink %.3f, at half %.3f" % [hz,
				_state_name(rules), frames, death_frame, rules.get_sink(), halfway.get_sink()])
	return report(passed, "No presses, Time To Die %.1f s: %s" % [stats.time_to_die,
			"; ".join(lines)])


## IDLE_PRESSES presses, then nothing: the bar stays for Drain Delay, goes down by Drain Per Second
## times DRAIN_WATCH_TIME in the DRAIN_WATCH_TIME after it, and stops at 0 with the man still held.
func _idle_the_bar_stays_for_drain_delay_then_drains_at_60_and_120_hz() -> bool:
	var stats: GrabStats = GrabStats.new()
	var passed: bool = true
	var lines: PackedStringArray = []
	for hz: int in [HZ, FAST_HZ]:
		var rules: GrabRules = GrabRules.new(stats)
		for _press: int in IDLE_PRESSES:
			rules.advance(1.0 / hz, true, false)
		var pressed: float = rules.get_escape_progress()
		_wait(rules, hz, roundi(stats.drain_delay * hz))
		var after_delay: float = rules.get_escape_progress()
		_wait(rules, hz, roundi(DRAIN_WATCH_TIME * hz))
		var drained: float = rules.get_escape_progress()
		var expected: float = pressed - stats.drain_per_second * DRAIN_WATCH_TIME
		_wait(rules, hz, roundi(pressed / stats.drain_per_second * hz))
		var emptied: float = rules.get_escape_progress()
		passed = (passed and is_equal_approx(after_delay, pressed)
				and is_equal_approx(drained, expected) and emptied == 0.0
				and rules.get_state() == GrabRules.State.HELD)
		lines.append("%d Hz: %.3f after %d presses, %.3f after Drain Delay, %.3f of %.3f %.1f s later, then %.3f, %s"
				% [hz, pressed, IDLE_PRESSES, after_delay, drained, expected, DRAIN_WATCH_TIME,
				emptied, _state_name(rules)])
	return report(passed, "Drain Delay %.2f s, Drain Per Second %.2f: %s" % [stats.drain_delay,
			stats.drain_per_second, "; ".join(lines)])


## A press every Drain Delay, 4 a second with the default values: just before each press the bar is
## where the last one left it, and the last press asked frees him before Time To Die.
func _a_press_once_per_drain_delay_keeps_the_bar_and_frees_him_in_time() -> bool:
	var stats: GrabStats = GrabStats.new()
	var rules: GrabRules = GrabRules.new(stats)
	var needed: int = rules.get_presses_needed()
	var gap_frames: int = roundi(stats.drain_delay * HZ)
	var kept: bool = true
	var frames: int = 0
	for press: int in needed:
		if press > 0:
			_wait(rules, HZ, gap_frames - 1)
			frames += gap_frames - 1
			kept = kept and is_equal_approx(rules.get_escape_progress(), float(press) / needed)
		_press(rules, 1)
		frames += 1
	var death_frame: int = roundi(stats.time_to_die * HZ)
	return report(kept and rules.get_state() == GrabRules.State.FREE and frames < death_frame,
			"A press every %d frames: bar kept between presses %s; %s on frame %d, death on %d"
			% [gap_frames, kept, _state_name(rules), frames, death_frame])


## Nothing until the frames left are the presses asked, then a press on each: the last lands on the
## frame the time runs out and frees him. One press short, he dies on that frame.
func _a_last_press_on_the_last_frame_frees_him() -> bool:
	var stats: GrabStats = GrabStats.new()
	var death_frame: int = roundi(stats.time_to_die * HZ)
	var pressed: GrabRules = GrabRules.new(stats)
	var not_pressed: GrabRules = GrabRules.new(stats)
	var needed: int = pressed.get_presses_needed()
	for rules: GrabRules in [pressed, not_pressed]:
		_wait(rules, HZ, death_frame - needed)
		_press(rules, needed - 1)
	var held_till_then: bool = pressed.get_state() == GrabRules.State.HELD
	_press(pressed, 1)
	_wait(not_pressed, HZ, 1)
	return report(held_till_then and pressed.get_state() == GrabRules.State.FREE
			and not_pressed.get_state() == GrabRules.State.DEAD,
			("Nothing until frame %d, then a press on each frame: held before the last %s; the "
			+ "last, on frame %d: %s; none then: %s") % [death_frame - needed, held_till_then,
			death_frame, _state_name(pressed), _state_name(not_pressed)])


## Joins one press short of breaking free from one demon, after Drain Delay, so the bar has not
## gone down yet: the presses so far count towards the new number, the sink stays, and the last
## press asked for frees him.
func _a_second_demon_asks_for_more_and_keeps_presses_and_time() -> bool:
	var stats: GrabStats = GrabStats.new()
	var rules: GrabRules = GrabRules.new(stats)
	var pressed_before: int = rules.get_presses_needed() - 1
	_press(rules, pressed_before)
	_wait(rules, HZ, roundi(stats.drain_delay * HZ))
	var sink_before: float = rules.get_sink()
	var joined: bool = rules.join()
	var needed: int = rules.get_presses_needed()
	var sink_after: float = rules.get_sink()
	var asks_more: bool = (rules.get_demons() == 2
			and needed == stats.presses_to_escape + stats.extra_presses_per_demon
			and is_equal_approx(rules.get_escape_progress(), float(pressed_before) / needed)
			and is_equal_approx(sink_after, sink_before))
	_press(rules, needed - pressed_before - 1)
	var held_one_short: bool = rules.get_state() == GrabRules.State.HELD
	_press(rules, 1)
	return report(joined and asks_more and held_one_short
			and rules.get_state() == GrabRules.State.FREE,
			("Joined %s after %d presses and %.2f s: %d demons, %d presses asked, progress %.3f, "
			+ "sink %.3f before and %.3f after; one short held %s; the last one: %s") % [joined,
			pressed_before, stats.drain_delay, rules.get_demons(), needed,
			float(pressed_before) / needed,
			sink_before, sink_after, held_one_short, _state_name(rules)])


func _a_third_demon_cant_join() -> bool:
	var rules: GrabRules = GrabRules.new(GrabStats.new())
	var second: bool = rules.join()
	var needed_by_two: int = rules.get_presses_needed()
	var third: bool = rules.join()
	return report(second and not third and rules.get_demons() == GrabRules.MAX_DEMONS
			and rules.get_presses_needed() == needed_by_two,
			"Second joined %s, third joined %s: %d demons, %d presses asked, %d with two"
			% [second, third, rules.get_demons(), rules.get_presses_needed(), needed_by_two])


## Holding from the grab on frees him on the frame Hold Time To Escape is reached, at 60 and at 120
## Hz. With two demons, the default values must still free him, not let him die.
func _holding_frees_him_at_hold_time_also_with_two_demons() -> bool:
	var stats: GrabStats = GrabStats.new()
	var passed: bool = true
	var lines: PackedStringArray = []
	for setup: Array in [[HZ, 1], [FAST_HZ, 1], [HZ, 2]]:
		var hz: int = setup[0]
		var rules: GrabRules = GrabRules.new(stats)
		if setup[1] == 2:
			rules.join()
		var free_frame: int = roundi(rules.get_hold_time_needed() * hz)
		var frames: int = _frames_until_over(rules, hz, true)
		passed = passed and frames == free_frame and rules.get_state() == GrabRules.State.FREE
		lines.append("%d Hz, demons %d: %s on frame %d of %d" % [hz, rules.get_demons(),
				_state_name(rules), frames, free_frame])
	return report(passed, "Holding, Time To Die %.1f s: %s" % [stats.time_to_die,
			"; ".join(lines)])


## Holds, lets go for longer than Drain Delay, and holds again: the let-go takes back Drain Per
## Second for the time past Drain Delay, and he breaks free once holding again makes up the rest.
func _letting_go_drains_what_was_held_and_holding_makes_it_up() -> bool:
	var stats: GrabStats = GrabStats.new()
	var rules: GrabRules = GrabRules.new(stats)
	_hold(rules, HOLD_BURST_FRAMES)
	var progress_held: float = rules.get_escape_progress()
	_wait(rules, HZ, LET_GO_FRAMES)
	var progress_after: float = rules.get_escape_progress()
	var expected: float = (progress_held
			- stats.drain_per_second * (float(LET_GO_FRAMES) / HZ - stats.drain_delay))
	var free_frame: int = (HOLD_BURST_FRAMES + LET_GO_FRAMES
			+ roundi((1.0 - expected) * rules.get_hold_time_needed() * HZ))
	var frames: int = HOLD_BURST_FRAMES + LET_GO_FRAMES + _frames_until_over(rules, HZ, true)
	return report(is_equal_approx(progress_after, expected) and frames == free_frame
			and rules.get_state() == GrabRules.State.FREE,
			("Held %d frames, progress %.3f, let go %d, %.3f of %.3f; held again: %s on frame %d "
			+ "of %d") % [HOLD_BURST_FRAMES, progress_held, LET_GO_FRAMES, progress_after,
			expected, _state_name(rules), frames, free_frame])


## Once free, and once dead, pressing, holding and a demon joining change neither the state, the
## progress nor the sink.
func _once_free_or_dead_nothing_changes() -> bool:
	var stats: GrabStats = GrabStats.new()
	var free: GrabRules = GrabRules.new(stats)
	_press(free, free.get_presses_needed())
	var dead: GrabRules = GrabRules.new(stats)
	_frames_until_over(dead, HZ, false)
	var passed: bool = true
	var lines: PackedStringArray = []
	for rules: GrabRules in [free, dead]:
		var state: GrabRules.State = rules.get_state()
		var progress: float = rules.get_escape_progress()
		var sink: float = rules.get_sink()
		for _frame: int in AFTER_FRAMES:
			rules.advance(1.0 / HZ, true, true)
		var joined: bool = rules.join()
		passed = (passed and not joined and rules.get_state() == state
				and rules.get_demons() == 1 and is_equal_approx(rules.get_escape_progress(), progress)
				and is_equal_approx(rules.get_sink(), sink))
		lines.append("%s: after %d frames %s, joined %s, progress %.3f, sink %.3f" % [
				GrabRules.State.keys()[state], AFTER_FRAMES, _state_name(rules), joined,
				rules.get_escape_progress(), rules.get_sink()])
	return report(passed, "; ".join(lines))


## Advances rules at hz with no presses, holding or not, until the grab is over, and gives the
## frames that took; MOST_FRAMES if it never ended.
func _frames_until_over(rules: GrabRules, hz: int, holding: bool) -> int:
	for frame: int in range(1, MOST_FRAMES + 1):
		rules.advance(1.0 / hz, false, holding)
		if rules.get_state() != GrabRules.State.HELD:
			return frame
	return MOST_FRAMES


## Advances rules times frames at HZ, with a press on each.
func _press(rules: GrabRules, times: int) -> void:
	for _frame: int in times:
		rules.advance(1.0 / HZ, true, false)


## Advances rules frames frames at HZ, holding on each.
func _hold(rules: GrabRules, frames: int) -> void:
	for _frame: int in frames:
		rules.advance(1.0 / HZ, false, true)


## Advances rules frames frames at hz, with no press and no hold.
func _wait(rules: GrabRules, hz: int, frames: int) -> void:
	for _frame: int in frames:
		rules.advance(1.0 / hz, false, false)


func _state_name(rules: GrabRules) -> String:
	return GrabRules.State.keys()[rules.get_state()]
