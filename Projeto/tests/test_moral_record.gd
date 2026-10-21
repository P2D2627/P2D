# Checks MoralRecord on its own, without the autoload or any line (#169). A new record is at stage 0
# with nothing taken. In the stats file, every temptation id the .dialogue files name has its
# points, each toll weighs less than a shortcut, and one shortcut is enough for stage 1. A
# temptation adds its points once, however often it is taken; one missing from Temptation Points
# counts Unknown Temptation Points. An arrogant answer adds points and a humble one only counts;
# any other tone changes nothing. Listening adds nothing within the grace, then points per second,
# up to the most an offer can add; the same offer heard again keeps only its longest time, and
# negative, infinite and nan seconds change nothing. stage_changed says each new stage once, in
# order, and nothing when the stage stays. A total that lands on a threshold reaches it, though
# sums like 0.7 + 0.1 come out a hair short; with Stage 2 Points below Stage 1 Points, stage 2
# starts at Stage 1 Points. Values tuned in the stats count at once. reset() empties the record and
# says stage 0 once, and nothing if it was already there. Six warnings are printed on purpose: an
# unknown temptation taken and asked about, an unknown tone, and negative, infinite and nan
# listening.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_moral_record.gd
extends "res://tests/support/player_test.gd"

const STATS: MoralStats = preload("res://core/moral_stats.tres")
const DIALOGUE_FOLDER: String = "res://dialogue/"
## How the lines name a temptation: an offer accepted, or one asked about.
const TEMPTATION_PATTERN: String = ("(?:Offers\\.accept|Moral\\.has_taken|Moral\\.take_temptation)"
		+ "\\(&\"(\\w+)\"\\)")
const TOLLS: Array[StringName] = [&"greed_toll_1", &"greed_toll_2", &"greed_toll_3"]
## The values the cases are written for, on stats of their own, so tuning the file changes no case.
const SHORTCUT: StringName = &"test_shortcut"
const TOLL: StringName = &"test_toll"
const SHORTCUT_POINTS: float = 1.0
const TOLL_POINTS: float = 0.25
const UNKNOWN_POINTS: float = 0.5
const ARROGANT_POINTS: float = 0.2
const GRACE: float = 2.0
const POINTS_PER_SECOND: float = 0.5
const MOST_LISTENING_POINTS: float = 1.0
const STAGE_1_POINTS: float = 1.0
const STAGE_2_POINTS: float = 2.0
## How far apart two point totals can be and still count as the same.
const TOLERANCE: float = 0.0001


func _initialize() -> void:
	var results: Array[bool] = []
	results.append(_a_new_record_is_empty_at_stage_0())
	results.append(_the_stats_file_has_every_id_and_a_shortcut_reaches_stage_1())
	results.append(_a_temptation_counts_once())
	results.append(_an_unknown_temptation_counts_unknown_points())
	results.append(_arrogant_adds_humble_only_counts_and_others_change_nothing())
	results.append(_listening_has_a_grace_a_rate_and_a_cap())
	results.append(_the_same_offer_keeps_its_longest_time())
	results.append(_bad_listening_times_change_nothing())
	results.append(_each_new_stage_is_said_once_in_order())
	results.append(_a_total_on_a_threshold_reaches_it_despite_rounding())
	results.append(_stage_2_below_stage_1_starts_with_stage_1())
	results.append(_tuned_values_count_at_once())
	results.append(_reset_empties_the_record_and_says_stage_0_once())
	finish(results)


func _a_new_record_is_empty_at_stage_0() -> bool:
	var record: MoralRecord = MoralRecord.new(_test_stats())
	return report(record.stage() == 0 and is_zero_approx(record.get_points())
			and not record.has_taken(SHORTCUT)
			and record.get_tone_count(MoralRecord.HUMBLE) == 0
			and record.get_tone_count(MoralRecord.ARROGANT) == 0,
			"A new record: stage %d, %s points, nothing taken or answered"
			% [record.stage(), record.get_points()])


func _the_stats_file_has_every_id_and_a_shortcut_reaches_stage_1() -> bool:
	var used: Array[StringName] = _temptations_in_the_lines()
	var missing: Array[StringName] = []
	for id: StringName in used:
		if not STATS.temptation_points.has(id):
			missing.append(id)
	var shortcut: float = STATS.temptation_points.get(&"lust_shortcut", 0.0)
	var tolls_lighter: bool = TOLLS.all(func(toll: StringName) -> bool:
			return STATS.temptation_points.get(toll, shortcut) < shortcut)
	var record: MoralRecord = MoralRecord.new(STATS)
	record.take_temptation(&"lust_shortcut")
	return report(not used.is_empty() and missing.is_empty() and tolls_lighter
			and record.stage() == 1,
			"The stats file: %d ids in the lines, missing %s; tolls lighter %s; a shortcut: stage %d"
			% [used.size(), missing, tolls_lighter, record.stage()])


func _a_temptation_counts_once() -> bool:
	var record: MoralRecord = MoralRecord.new(_test_stats())
	record.take_temptation(TOLL)
	record.take_temptation(TOLL)
	record.take_temptation(TOLL)
	return report(is_equal_approx(record.get_points(), TOLL_POINTS) and record.has_taken(TOLL)
			and not record.has_taken(SHORTCUT),
			"The same toll taken three times: %s points, %s for one; taken %s, shortcut %s"
			% [record.get_points(), TOLL_POINTS, record.has_taken(TOLL),
			record.has_taken(SHORTCUT)])


func _an_unknown_temptation_counts_unknown_points() -> bool:
	print("Two warnings about test_unknown follow, on purpose: taken, then asked about.")
	var record: MoralRecord = MoralRecord.new(_test_stats())
	record.take_temptation(&"test_unknown")
	return report(is_equal_approx(record.get_points(), UNKNOWN_POINTS)
			and record.has_taken(&"test_unknown"),
			"An id missing from Temptation Points: %s points, expected %s"
			% [record.get_points(), UNKNOWN_POINTS])


func _arrogant_adds_humble_only_counts_and_others_change_nothing() -> bool:
	print("A warning about the tone test_proud follows, on purpose.")
	var record: MoralRecord = MoralRecord.new(_test_stats())
	record.record_tone(MoralRecord.HUMBLE)
	record.record_tone(MoralRecord.HUMBLE)
	var after_humble: float = record.get_points()
	record.record_tone(MoralRecord.ARROGANT)
	record.record_tone(&"test_proud")
	return report(is_zero_approx(after_humble)
			and is_equal_approx(record.get_points(), ARROGANT_POINTS)
			and record.get_tone_count(MoralRecord.HUMBLE) == 2
			and record.get_tone_count(MoralRecord.ARROGANT) == 1
			and record.get_tone_count(&"test_proud") == 0,
			"Two humble: %s points; one arrogant, one unknown: %s, expected %s; %d humble, %d arrogant"
			% [after_humble, record.get_points(), ARROGANT_POINTS,
			record.get_tone_count(MoralRecord.HUMBLE), record.get_tone_count(MoralRecord.ARROGANT)])


func _listening_has_a_grace_a_rate_and_a_cap() -> bool:
	var record: MoralRecord = MoralRecord.new(_test_stats())
	record.record_listening(&"test_within", GRACE)
	var within: float = record.get_points()
	record.record_listening(&"test_past", GRACE + 1.0)
	var past: float = record.get_points()
	record.record_listening(&"test_long", GRACE + 100.0)
	var capped: float = record.get_points() - past
	return report(is_zero_approx(within) and is_equal_approx(past, POINTS_PER_SECOND)
			and is_equal_approx(capped, MOST_LISTENING_POINTS),
			"Listening the grace: %s points; 1 s past: %s, expected %s; far past: %s, expected %s"
			% [within, past, POINTS_PER_SECOND, capped, MOST_LISTENING_POINTS])


func _the_same_offer_keeps_its_longest_time() -> bool:
	var record: MoralRecord = MoralRecord.new(_test_stats())
	record.record_listening(&"test_offer", GRACE + 1.0)
	record.record_listening(&"test_offer", GRACE + 0.5)
	record.record_listening(&"test_offer", GRACE + 1.0)
	return report(is_equal_approx(record.get_points(), POINTS_PER_SECOND)
			and is_equal_approx(record.get_listening_seconds(&"test_offer"), GRACE + 1.0),
			"One offer heard three times, at most 1 s past the grace: %s points, expected %s, %s s"
			% [record.get_points(), POINTS_PER_SECOND,
			record.get_listening_seconds(&"test_offer")])


func _bad_listening_times_change_nothing() -> bool:
	print("Three warnings about listening times follow, on purpose.")
	var record: MoralRecord = MoralRecord.new(_test_stats())
	record.record_listening(&"test_offer", -GRACE - 10.0)
	record.record_listening(&"test_offer", INF)
	record.record_listening(&"test_offer", NAN)
	return report(is_zero_approx(record.get_points())
			and is_zero_approx(record.get_listening_seconds(&"test_offer")),
			"Negative, infinite and nan listening: %s points, %s s kept"
			% [record.get_points(), record.get_listening_seconds(&"test_offer")])


func _each_new_stage_is_said_once_in_order() -> bool:
	var record: MoralRecord = MoralRecord.new(_test_stats())
	var said: Array[int] = []
	record.stage_changed.connect(func(stage: int) -> void: said.append(stage))
	record.take_temptation(TOLL)
	record.record_tone(MoralRecord.HUMBLE)
	var before_any: int = said.size()
	record.take_temptation(SHORTCUT)
	record.take_temptation(SHORTCUT)
	record.record_tone(MoralRecord.ARROGANT)
	var at_one: Array[int] = said.duplicate()
	record.record_listening(&"test_offer", GRACE + 100.0)
	var only_one: Array[int] = [1]
	var one_then_two: Array[int] = [1, 2]
	return report(before_any == 0 and at_one == only_one and said == one_then_two
			and record.stage() == 2,
			"stage_changed: %d before stage 1, %s up to %s points, %s in all; stage %d"
			% [before_any, at_one, SHORTCUT_POINTS + TOLL_POINTS + ARROGANT_POINTS, said,
			record.stage()])


func _a_total_on_a_threshold_reaches_it_despite_rounding() -> bool:
	var stats: MoralStats = _test_stats()
	var points: Dictionary[StringName, float] = {&"test_most": 0.7, &"test_rest": 0.1}
	stats.temptation_points = points
	stats.stage_1_points = 0.8
	var record: MoralRecord = MoralRecord.new(stats)
	record.take_temptation(&"test_most")
	record.take_temptation(&"test_rest")
	var from_file: MoralRecord = MoralRecord.new(STATS)
	for toll: StringName in TOLLS:
		from_file.take_temptation(toll)
	var answers: int = ceili((STATS.stage_2_points - from_file.get_points())
			/ STATS.arrogant_answer_points)
	for answer: int in answers:
		from_file.record_tone(MoralRecord.ARROGANT)
	return report(record.stage() == 1 and from_file.stage() == 2,
			"0.7 + 0.1 against 0.8: stage %d; the file's tolls and %d arrogant answers: stage %d (%s)"
			% [record.stage(), answers, from_file.stage(), from_file.get_points()])


func _stage_2_below_stage_1_starts_with_stage_1() -> bool:
	var stats: MoralStats = _test_stats()
	stats.stage_2_points = STAGE_1_POINTS - TOLL_POINTS
	var record: MoralRecord = MoralRecord.new(stats)
	record.take_temptation(TOLL)
	var below_both: int = record.stage()
	record.take_temptation(SHORTCUT)
	return report(below_both == 0 and record.stage() == 2,
			"Stage 2 Points below Stage 1 Points: stage %d below both, %d at Stage 1 Points"
			% [below_both, record.stage()])


func _tuned_values_count_at_once() -> bool:
	var stats: MoralStats = _test_stats()
	var record: MoralRecord = MoralRecord.new(stats)
	record.take_temptation(TOLL)
	var before: int = record.stage()
	stats.stage_1_points = TOLL_POINTS
	stats.temptation_points[TOLL] = STAGE_2_POINTS
	return report(before == 0 and is_equal_approx(record.get_points(), STAGE_2_POINTS)
			and record.stage() == 2,
			"A toll: stage %d; with the toll worth %s, %s points and stage %d"
			% [before, STAGE_2_POINTS, record.get_points(), record.stage()])


func _reset_empties_the_record_and_says_stage_0_once() -> bool:
	var record: MoralRecord = MoralRecord.new(_test_stats())
	var said: Array[int] = []
	record.stage_changed.connect(func(stage: int) -> void: said.append(stage))
	record.reset()
	var at_zero: int = said.size()
	record.take_temptation(SHORTCUT)
	record.record_tone(MoralRecord.ARROGANT)
	record.record_tone(MoralRecord.HUMBLE)
	record.record_listening(&"test_offer", GRACE + 1.0)
	said.clear()
	record.reset()
	var only_zero: Array[int] = [0]
	return report(at_zero == 0 and said == only_zero and record.stage() == 0
			and is_zero_approx(record.get_points()) and not record.has_taken(SHORTCUT)
			and record.get_tone_count(MoralRecord.HUMBLE) == 0
			and record.get_tone_count(MoralRecord.ARROGANT) == 0
			and is_zero_approx(record.get_listening_seconds(&"test_offer")),
			"reset(): at stage 0 it said %d; from stage 1 it said %s, and left stage %d with %s points"
			% [at_zero, said, record.stage(), record.get_points()])


## Every temptation id the .dialogue files name, each once.
func _temptations_in_the_lines() -> Array[StringName]:
	var pattern: RegEx = RegEx.create_from_string(TEMPTATION_PATTERN)
	var ids: Array[StringName] = []
	for file: String in DirAccess.get_files_at(DIALOGUE_FOLDER):
		if file.get_extension() != "dialogue":
			continue
		var text: String = FileAccess.get_file_as_string(DIALOGUE_FOLDER + file)
		for found: RegExMatch in pattern.search_all(text):
			var id: StringName = StringName(found.get_string(1))
			if not ids.has(id):
				ids.append(id)
	return ids


## Stats of the cases' own, with the values in the constants above.
func _test_stats() -> MoralStats:
	var stats: MoralStats = MoralStats.new()
	var points: Dictionary[StringName, float] = {SHORTCUT: SHORTCUT_POINTS, TOLL: TOLL_POINTS}
	stats.temptation_points = points
	stats.unknown_temptation_points = UNKNOWN_POINTS
	stats.arrogant_answer_points = ARROGANT_POINTS
	stats.listening_grace = GRACE
	stats.listening_points_per_second = POINTS_PER_SECOND
	stats.most_listening_points = MOST_LISTENING_POINTS
	stats.stage_1_points = STAGE_1_POINTS
	stats.stage_2_points = STAGE_2_POINTS
	return stats
