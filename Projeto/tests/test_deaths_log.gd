# Checks the playtests' log of the deaths, which RunStats writes as CSV. A new file starts with its
# header; each death adds a line with the time, the level, the phase, the zone, what killed him
# (as spikes; unknown when nothing said), the spot (the strip of spikes, as Spikes2, or else the
# cause), where he died, the deaths at that spot so far, and whether it brought a shortcut offer,
# which the line of the death that did says. An empty path writes nothing. The test writes to a log
# of its own and deletes it.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_deaths_log.gd
extends "res://tests/support/player_test.gd"

const LOG_PATH: String = "user://test_deaths_log.csv"
## A line after the header: the time, then the rest as the test can foresee it.
const LINE: String = "^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2},%s$"
## Deaths in one zone at most to bring an offer.
const MAX_DEATHS: int = 40


func _initialize() -> void:
	# The autoloads join the tree on the first frame.
	await process_frame
	var results: Array[bool] = []
	results.append(_each_death_adds_a_line())
	results.append(_an_empty_path_writes_nothing())
	_stats().set_log_path("")
	_stats().reset()
	DirAccess.remove_absolute(LOG_PATH)
	finish(results)


func _each_death_adds_a_line() -> bool:
	DirAccess.remove_absolute(LOG_PATH)
	_stats().reset()
	_stats().set_log_path(LOG_PATH)
	_stats().enter(&"level1", 1)
	_stats().record_death(&"ZoneA", Vector2(120.4, -35.6), &"spikes", &"Spikes2")
	_stats().enter(&"level1", 2)
	var deaths: int = 0
	while not _stats().has_death_offer() and deaths < MAX_DEATHS:
		_stats().record_death(&"pit", Vector2(10.0, 20.0))
		deaths += 1
	var lines: PackedStringArray = FileAccess.get_file_as_string(LOG_PATH).strip_edges().split("\n")
	var header: bool = lines.size() > 0 and lines[0] == GameRunStats.LOG_HEADER
	var first: bool = lines.size() > 1 and _matches(lines[1], "level1,1,ZoneA,spikes,Spikes2,120,-36,1,false")
	var rows: bool = lines.size() == deaths + 2
	var before_offer: bool = deaths < 2 or _matches(lines[lines.size() - 2],
			"level1,2,pit,unknown,unknown,10,20,%d,false" % (deaths - 1))
	var offer: bool = lines.size() > 2 and _matches(lines[lines.size() - 1],
			"level1,2,pit,unknown,unknown,10,20,%d,true" % deaths)
	return report(header and first and rows and before_offer and offer,
			("Each death a line: the header %s, phase 1's death %s, %d deaths in phase 2 under it %s, "
			+ "the one before the offer says false %s, the one that brought it true %s")
			% [header, first, deaths, rows, before_offer, offer])


func _an_empty_path_writes_nothing() -> bool:
	DirAccess.remove_absolute(LOG_PATH)
	_stats().set_log_path("")
	_stats().record_death(&"pit", Vector2.ZERO)
	var nothing: bool = not FileAccess.file_exists(LOG_PATH)
	return report(nothing, "An empty path writes nothing %s" % nothing)


func _matches(line: String, rest: String) -> bool:
	return RegEx.create_from_string(LINE % rest).search(line) != null


func _stats() -> GameRunStats:
	return root.get_node(^"RunStats") as GameRunStats
