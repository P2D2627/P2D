# Checks NumberWords on its own (#284): a whole number in English words, as the lines say it. Zero
# to nineteen have their own words; the tens join their unit with a hyphen, as "twenty-one"; the
# hundreds read "a hundred" and "three hundred", with "and" before what is left, as "a hundred and
# five". Past 999 and below 0 it keeps the digits. opening() gives the same words with the first
# letter in capitals, to start a line: "Three falls on the way to me."
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_number_words.gd
extends "res://tests/support/player_test.gd"

## Each number with the words it must give.
const SPELLED: Dictionary[int, String] = {
	0: "zero",
	1: "one",
	3: "three",
	12: "twelve",
	13: "thirteen",
	19: "nineteen",
	20: "twenty",
	21: "twenty-one",
	40: "forty",
	99: "ninety-nine",
	100: "a hundred",
	105: "a hundred and five",
	112: "a hundred and twelve",
	300: "three hundred",
	342: "three hundred and forty-two",
	999: "nine hundred and ninety-nine",
}


func _initialize() -> void:
	var results: Array[bool] = []
	results.append(_each_number_reads_as_said())
	results.append(_past_999_and_below_0_keep_the_digits())
	results.append(_opening_starts_with_a_capital())
	finish(results)


func _each_number_reads_as_said() -> bool:
	var wrong: Array[String] = []
	for count: int in SPELLED:
		var words: String = NumberWords.spell(count)
		if words != SPELLED[count]:
			wrong.append("%d gave \"%s\"" % [count, words])
	return report(wrong.is_empty(), "Every number from the list in words (wrong: %s)" % [wrong])


func _past_999_and_below_0_keep_the_digits() -> bool:
	var big: String = NumberWords.spell(1000)
	var negative: String = NumberWords.spell(-4)
	return report(big == "1000" and negative == "-4",
			"Past 999 and below 0, the digits (1000 gave \"%s\", -4 gave \"%s\")" % [big, negative])


func _opening_starts_with_a_capital() -> bool:
	var three: String = NumberWords.opening(3)
	var hundred: String = NumberWords.opening(105)
	var big: String = NumberWords.opening(1000)
	return report(three == "Three" and hundred == "A hundred and five" and big == "1000",
			"To open a line: \"%s\", \"%s\", \"%s\"" % [three, hundred, big])
