class_name PromptBand
extends CanvasLayer

## The tutorial's band at the bottom of the screen. It shows one hint at a time: the keys of its
## actions, a PromptGlyph each, so they follow the device used last, and its caption, on a dark
## see-through plate. The plate sits at the bottom centre, Bottom Gap above the edge, which in the
## 1920 × 1080 view kept it 41 to 82 px below the man's feet in every zone of the tutorial, in two
## captures. It fades in when a hint comes and out when none is left, and hides while held, as while
## Velvet talks; one hint replaces another at once. TutorialHints says what it shows; the band only
## draws. Its layer is above the level's light and below the pause menu.

const GLYPH_SCENE: PackedScene = preload("res://scenes/levels/prompt_glyph.tscn")

## Space between the plate and the bottom of the screen, in px of the 1920 × 1080 view.
@export_range(0.0, 400.0, 1.0, "suffix:px") var bottom_gap: float = 40.0:
	set(value):
		bottom_gap = value
		if is_node_ready():
			_place_plate()
## How long the band takes to fade in or out, in s.
@export_range(0.0, 2.0, 0.05, "suffix:s") var fade_time: float = 0.25

## The actions of the hint it shows; empty with none.
var _actions: Array[StringName] = []
var _held: bool = false
var _fade: Tween

@onready var _plate: PanelContainer = %Plate
@onready var _row: HBoxContainer = %Row
@onready var _caption: Label = %Caption


func _ready() -> void:
	_place_plate()
	_plate.modulate.a = 0.0
	_plate.hide()


## Shows a hint: a key for each of actions, in that order, and then caption. While held, it waits
## hidden until let go.
func show_hint(actions: Array[StringName], caption: String) -> void:
	for glyph: Node in _row.get_children():
		if glyph is PromptGlyph:
			glyph.queue_free()
	for action: StringName in actions:
		var glyph: PromptGlyph = GLYPH_SCENE.instantiate() as PromptGlyph
		glyph.action = action
		_row.add_child(glyph)
		_row.move_child(glyph, _caption.get_index())
	_actions = actions.duplicate()
	_caption.text = caption
	_fade_to(not _held)


## Fades the hint out.
func clear() -> void:
	_actions.clear()
	_fade_to(false)


## Held, the band hides, and comes back with the same hint when let go.
func set_held(held: bool) -> void:
	_held = held
	_fade_to(not held and not _actions.is_empty())


## Whether a hint shows, or is fading in, and the band is not held.
func is_showing() -> bool:
	return not _actions.is_empty() and not _held


## The actions of the hint it shows.
func get_actions() -> Array[StringName]:
	return _actions.duplicate()


func get_caption() -> String:
	return _caption.text


## How opaque the plate is drawn now, from 0, hidden, to 1.
func get_drawn_alpha() -> float:
	return _plate.modulate.a if _plate.visible else 0.0


## Where the plate is on the screen.
func get_plate_rect() -> Rect2:
	return _plate.get_global_rect()


## The plate's colour, see-through.
func get_plate_color() -> Color:
	return (_plate.get_theme_stylebox(&"panel") as StyleBoxFlat).bg_color


func get_caption_color() -> Color:
	return _caption.get_theme_color(&"font_color")


## The plate grows up from Bottom Gap above the bottom edge, as wide as its hint.
func _place_plate() -> void:
	_plate.offset_top = -bottom_gap
	_plate.offset_bottom = -bottom_gap


func _fade_to(shown: bool) -> void:
	if _fade != null:
		_fade.kill()
	if shown:
		_plate.show()
	_fade = create_tween()
	_fade.tween_property(_plate, ^"modulate:a", 1.0 if shown else 0.0, fade_time)
	if not shown:
		_fade.tween_callback(_plate.hide)
