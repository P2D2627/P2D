## A level's map written as text (decision F of docs/nivel1_desenho.md): free lines and
## "key: value" lines, a line with ---, then the grid, top row first, one character per tile. A key
## may come more than once, as section and shaft do. No class_name, so the headless builder and the
## tests can preload it before the editor has indexed it.
extends RefCounted

const ROCK: String = "#"
const AIR: String = "."
const START: String = "P"
const END: String = "F"
const DOG_FACING_LEFT: String = "<"
const DOG_FACING_RIGHT: String = ">"
const MURAL: String = "+"
const LEGEND: String = "#.PF<>+"
const GRID_START: String = "---"

## The "key: value" lines, in their order, as [key, value] pairs.
var entries: Array[PackedStringArray] = []
## The grid, top row first, every row padded with rock to the widest one.
var rows: PackedStringArray = PackedStringArray()
var width: int = 0
var height: int = 0
## Why the text could not be read; empty when it was.
var error: String = ""


## Reads the file at path; false, with error set, if it cannot.
func load_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		error = "no file at %s" % path
		return false
	return parse(FileAccess.get_file_as_string(path))


## Reads the text; false, with error set, if it has no grid or a character outside LEGEND.
func parse(text: String) -> bool:
	var in_grid: bool = false
	var grid: PackedStringArray = PackedStringArray()
	for line: String in text.split("\n"):
		line = line.strip_edges(false, true)
		if not in_grid:
			if line.strip_edges() == GRID_START:
				in_grid = true
			elif line.contains(":") and not line.get_slice(":", 0).contains(" "):
				entries.append(PackedStringArray([line.get_slice(":", 0).strip_edges(),
						line.substr(line.find(":") + 1).strip_edges()]))
		elif not line.is_empty():
			grid.append(line)
	if grid.is_empty():
		error = "no grid after a %s line" % GRID_START
		return false
	for line: String in grid:
		width = maxi(width, line.length())
	for line: String in grid:
		for character: String in line:
			if not LEGEND.contains(character):
				error = "'%s' is not in the legend %s" % [character, LEGEND]
				return false
		rows.append(line + ROCK.repeat(width - line.length()))
	height = rows.size()
	return true


## The character at column, row (row 0 the top one); rock outside the grid.
func at(column: int, row: int) -> String:
	if column < 0 or column >= width or row < 0 or row >= height:
		return ROCK
	return rows[row][column]


func is_rock(column: int, row: int) -> bool:
	return at(column, row) == ROCK


## Every cell holding one of characters, as Vector2i(column, row), top row first.
func find(characters: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for row: int in height:
		for column: int in width:
			if characters.contains(rows[row][column]):
				cells.append(Vector2i(column, row))
	return cells


## The value of the first line with key, or default.
func get_value(key: String, default: String = "") -> String:
	for entry: PackedStringArray in entries:
		if entry[0] == key:
			return entry[1]
	return default


## The values of every line with key, in their order.
func values_of(key: String) -> PackedStringArray:
	var values: PackedStringArray = PackedStringArray()
	for entry: PackedStringArray in entries:
		if entry[0] == key:
			values.append(entry[1])
	return values


## A "first column, first row, last column, last row" value, after any words before the numbers, as
## a rectangle of cells.
static func rect_of(value: String) -> Rect2i:
	var numbers: PackedStringArray = value.split(" ", false)
	var count: int = numbers.size()
	var first: Vector2i = Vector2i(numbers[count - 4].to_int(), numbers[count - 3].to_int())
	var last: Vector2i = Vector2i(numbers[count - 2].to_int(), numbers[count - 1].to_int())
	return Rect2i(first, last - first + Vector2i.ONE)


## The words before the four numbers of a section or shaft value: its name.
static func name_of(value: String) -> String:
	var words: PackedStringArray = value.split(" ", false)
	return " ".join(words.slice(0, words.size() - 4))
