class_name DialogueWheel
extends Control

## The answers to a line, on up to four platforms under the dialogue box, in the order the lines give
## them: 1 top left, 2 top right, 3 bottom left, 4 bottom right. Each hangs from its own link. The
## third's, with the stem, comes in two drawings: alone, when there are three answers, and drawn to
## join the fourth's, when there are four. Everything is drawn white with a black outline, to read on
## any background.
## The player holds the left stick, or the movement keys, towards one and confirms with Next Action,
## as the X on a PS5 pad; the mouse does nothing here. Left alone, the stick back in the middle,
## nothing is pointed at and Next Action does nothing, so a stray press never answers. Pointing:
## left or right alone picks the top row, down and a side the bottom one, and down alone the only
## bottom answer when there are three. The answer pointed at shows inverted, black with a white
## outline: its platform, its text and its link, drawn over the other links. The whole wheel hangs
## behind the dialogue box. The wheel never suggests an
## answer. It only shows and says which was chosen; the balloon goes on from there.

## He confirmed the answer response.
signal response_selected(response: DialogueResponse)

## How many answers the wheel has room for; more are left out, with a warning.
const SLOTS: int = 4
## Answers per row.
const COLUMNS: int = 2

## Confirms the answer pointed at.
@export var next_action: StringName = &"ui_accept"
@export_group("Aim")
@export var aim_left: StringName = &"move_left"
@export var aim_right: StringName = &"move_right"
@export var aim_up: StringName = &"move_up"
@export var aim_down: StringName = &"move_down"
## How far the stick goes before it points, from 0 (resting) to 1 (all the way).
@export_range(0.1, 0.9, 0.05) var aim_deadzone: float = 0.5
## How much of the stick's push must go along an axis for that axis to count, as a part of its
## length: under this, pushing left with a little down is still just left.
@export_range(0.1, 0.7, 0.01) var aim_axis_share: float = 0.38
@export_group("Text")
## The answer's text size, as large as fits on its platform in Max Text Lines lines.
@export_range(12, 48, 1, "suffix:px") var max_font_size: int = 26
## The smallest it may shrink to; below this, the text is cut with an ellipsis.
@export_range(12, 48, 1, "suffix:px") var min_font_size: int = 18
@export_range(1, 4, 1) var max_text_lines: int = 2
@export_group("Parts")
## The four places, in answer order; each holds a Platform and a Text.
@export var slots: Array[Control] = []
## The link each place hangs from when all four show, in the same order; the third's and the
## fourth's are drawn to join each other.
@export var links: Array[CanvasItem] = []
## The third place's link, stem and all, when it is the last.
@export var link_3_alone: CanvasItem
## What every drawing of the wheel is drawn with; each gets its own copy, to light on its own.
@export var art_material: ShaderMaterial

## The answers on show, as the dialogue line gives them, less the ones not allowed, as the questions
## already asked.
var responses: Array = []:
	set(value):
		responses = value.filter(func(response: DialogueResponse) -> bool: return response.is_allowed)
		if is_node_ready():
			_build()
## The index of the answer pointed at, or -1 while nothing is.
var selected: int = -1

var _count: int = 0


func _ready() -> void:
	for part: CanvasItem in _drawings():
		part.material = art_material.duplicate()
	_build()


func _process(_delta: float) -> void:
	if not is_visible_in_tree() or _count == 0:
		return
	point(Input.get_vector(aim_left, aim_right, aim_up, aim_down))


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or _count == 0 or selected < 0:
		return
	if event.is_action_pressed(next_action) and not event.is_echo():
		get_viewport().set_input_as_handled()
		response_selected.emit(responses[selected])


## Points where aim goes, a direction like the stick's, as it is now: in the middle, or towards no
## answer, nothing is pointed at.
func point(aim: Vector2) -> void:
	var index: int = answer_towards(aim)
	if index != selected:
		selected = index
		_refresh()


## The answer aim points at, or -1. Up alone, or towards an empty place, points at none.
func answer_towards(aim: Vector2) -> int:
	if aim.length() < aim_deadzone:
		return -1
	var share: float = aim.length() * aim_axis_share
	var row: int = 1 if aim.y > share else 0
	var index: int = -1
	if aim.x < -share:
		index = row * COLUMNS
	elif aim.x > share:
		index = row * COLUMNS + 1
	elif row == 1 and _count == COLUMNS + 1:
		index = COLUMNS
	return index if index < _count else -1


## Confirms the answer pointed at, as Next Action does; nothing if none is.
func confirm() -> void:
	if selected >= 0 and selected < _count:
		response_selected.emit(responses[selected])


func _build() -> void:
	if responses.size() > SLOTS:
		push_warning("DialogueWheel: %d answers, room for %d; the rest are left out." % [responses.size(), SLOTS])
	_count = mini(responses.size(), mini(slots.size(), SLOTS))
	for i: int in slots.size():
		var shown: bool = i < _count
		slots[i].visible = shown
		if shown:
			_fit_text(slots[i].get_node(^"Text") as Label, (responses[i] as DialogueResponse).text)
	for i: int in links.size():
		links[i].visible = i < _count and not (i == COLUMNS and _count == COLUMNS + 1)
	link_3_alone.visible = _count == COLUMNS + 1
	selected = -1
	_refresh()


## Writes text on label as large as fits in Max Text Lines lines across the platform.
func _fit_text(label: Label, text: String) -> void:
	label.text = text
	var font: Font = label.get_theme_font(&"font")
	var width: float = label.size.x
	var font_size: int = max_font_size
	while font_size > min_font_size:
		var lines: int = roundi(font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, width,
				font_size, -1, TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND).y / font.get_height(font_size))
		if lines <= max_text_lines:
			break
		font_size -= 1
	label.add_theme_font_size_override(&"font_size", font_size)


## Whether the drawing part shows lit, as the wheel shows it now.
func is_lit(part: CanvasItem) -> bool:
	return (part.material as ShaderMaterial).get_shader_parameter(&"lit") == true


## The link the answer at index hangs from, as the wheel shows it now.
func link_of(index: int) -> CanvasItem:
	return link_3_alone if index == COLUMNS and _count == COLUMNS + 1 else links[index]


func _drawings() -> Array[CanvasItem]:
	var drawings: Array[CanvasItem] = []
	drawings.append_array(links)
	drawings.append(link_3_alone)
	for slot: Control in slots:
		drawings.append(slot.get_node(^"Platform") as CanvasItem)
	return drawings


func _light(part: CanvasItem, lit: bool) -> void:
	(part.material as ShaderMaterial).set_shader_parameter(&"lit", lit)


## Draws link over the other links, so a stem two links share shows lit. It moves among the wheel's
## children rather than up in z, which would put it over the box the wheel hangs behind.
func _bring_forward(link: CanvasItem) -> void:
	var last: int = link_3_alone.get_index()
	for other: CanvasItem in links:
		last = maxi(last, other.get_index())
	move_child(link, last)


func _refresh() -> void:
	for link: CanvasItem in links:
		_light(link, false)
	_light(link_3_alone, false)
	if selected >= 0:
		_light(link_of(selected), true)
		_bring_forward(link_of(selected))
	for i: int in slots.size():
		var on: bool = i == selected
		_light(slots[i].get_node(^"Platform") as CanvasItem, on)
		var label: Label = slots[i].get_node(^"Text") as Label
		label.add_theme_color_override(&"font_color", Color.BLACK if on else Color.WHITE)
		label.add_theme_color_override(&"font_outline_color", Color.WHITE if on else Color.BLACK)
