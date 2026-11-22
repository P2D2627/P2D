class_name NumberWords
extends RefCounted

## A whole number in English words, as the lines say it (#284): the demons count the run's falls
## and minutes, and a number in digits at the start of a line reads as a counter, not a voice.
## Zero to nineteen have their own words; the tens join their unit with a hyphen ("twenty-one");
## the hundreds read "a hundred" and "three hundred", with "and" before what is left ("a hundred
## and five"). Past 999 and below 0 it keeps the digits: no run gets there, and a wrong word would
## be worse than a number.

const ONES: PackedStringArray = ["zero", "one", "two", "three", "four", "five", "six", "seven",
		"eight", "nine", "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen",
		"seventeen", "eighteen", "nineteen"]
## By the tens digit; 0 and 1 are never read here, ONES has them.
const TENS: PackedStringArray = ["", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy",
		"eighty", "ninety"]
## The largest number written in words.
const MOST_IN_WORDS: int = 999


## count in words, in small letters: "twenty-one".
static func spell(count: int) -> String:
	if count < 0 or count > MOST_IN_WORDS:
		return str(count)
	if count < 100:
		return _below_100(count)
	var hundreds: int = floori(count / 100.0)
	var words: String = ("a" if hundreds == 1 else ONES[hundreds]) + " hundred"
	var rest: int = count % 100
	return words if rest == 0 else words + " and " + _below_100(rest)


## count in words with the first letter in capitals, to start a line: "Three".
static func opening(count: int) -> String:
	var words: String = spell(count)
	return words.left(1).to_upper() + words.substr(1)


static func _below_100(count: int) -> String:
	if count < ONES.size():
		return ONES[count]
	var unit: int = count % 10
	return TENS[floori(count / 10.0)] +("" if unit == 0 else "-" + ONES[unit])
