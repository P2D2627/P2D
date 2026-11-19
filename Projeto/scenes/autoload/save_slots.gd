class_name SaveSlots
extends RefCounted

## The game's three saves, read side by side for the menu. Slot 1 is the save the game always had,
## at SaveFile's Default Path, so a save from before the slots is slot 1; slots 2 and 3 sit beside
## it, with their number in the name. Each slot is a SaveFile of its own, with its run's numbers
## beside it, so one that is damaged hides none of the others. It only reads: what each slot holds,
## which was played last and which is the first empty. Main decides which slot to write.

enum State {
	## No save file.
	EMPTY,
	## A save that can be continued.
	READY,
	## A file that can't be used: damaged, of a later version or of a scene that is gone.
	DAMAGED,
}

const COUNT: int = 3


## What the menu shows of a slot. Only a Ready slot fills in more than its slot and state.
class Summary:
	var slot: int = 0
	var state: State = State.EMPTY
	## The phase scene's path, to find the level's title.
	var scene: String = ""
	## 0 when the save does not say, as one from before the slots.
	var phase: int = 0
	var seconds: float = 0.0
	var deaths: int = 0
	## In Unix seconds, as SaveFile.last_played() gives it.
	var last_played: float = 0.0


## Slot's file path, slot from 1 to Count; empty when the saves keep nothing, and, with an error,
## for a slot that does not exist, so nothing is ever written where the menu does not look.
static func path_of(slot: int) -> String:
	if slot < 1 or slot > COUNT:
		push_error("SaveSlots: there is no slot %d." % slot)
		return ""
	var first: String = SaveFile.default_path
	if first.is_empty() or slot == 1:
		return first
	return "%s_%d.%s" % [first.get_basename(), slot, first.get_extension()]


static func file_of(slot: int) -> SaveFile:
	var file: SaveFile = SaveFile.new()
	file.path = path_of(slot)
	return file


static func summary_of(slot: int) -> Summary:
	var summary: Summary = Summary.new()
	summary.slot = slot
	if not _has_file(slot):
		return summary
	var file: SaveFile = file_of(slot)
	var saved: Dictionary = file.read()
	if saved.is_empty():
		summary.state = State.DAMAGED
		return summary
	summary.state = State.READY
	summary.scene = saved["scene"]
	summary.phase = saved["phase"]
	var record: RunRecord = RunRecord.new()
	record.from_save(file.read_run())
	summary.seconds = record.total_seconds()
	summary.deaths = record.total_deaths()
	summary.last_played = file.last_played()
	return summary


## Every slot's summary, slot 1 first.
static func summaries() -> Array[Summary]:
	var all: Array[Summary] = []
	for slot: int in range(1, COUNT + 1):
		all.append(summary_of(slot))
	return all


## The Ready slot played last, for Continue; the lower one on a tie, and 0 with none.
static func last_played() -> int:
	return latest_of(summaries())


## The first slot with no file, for a new game; 0 when every slot has one.
static func first_empty() -> int:
	return first_empty_of(summaries())


## Of the slots in all, the Ready one played last; the lower one on a tie, and 0 with none. The menu
## asks this of the summaries it was given, so it never reads the files.
static func latest_of(all: Array[Summary]) -> int:
	var latest_slot: int = 0
	var latest: float = -1.0
	for summary: Summary in all:
		if summary.state == State.READY and summary.last_played > latest:
			latest_slot = summary.slot
			latest = summary.last_played
	return latest_slot


## Of the slots in all, the first Empty one; 0 when none is.
static func first_empty_of(all: Array[Summary]) -> int:
	for summary: Summary in all:
		if summary.state == State.EMPTY:
			return summary.slot
	return 0


## Whether any slot has a file, even one that can't be used.
static func has_any() -> bool:
	for slot: int in range(1, COUNT + 1):
		if _has_file(slot):
			return true
	return false


static func _has_file(slot: int) -> bool:
	var path: String = path_of(slot)
	return not path.is_empty() and FileAccess.file_exists(path)
