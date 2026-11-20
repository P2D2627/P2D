class_name MenuCrosses
extends Control

## The two crosses that mark the selected option of a menu, one on each side of its text, the right
## one mirrored. They follow the focus: whatever button inside Menu has it, by keys, pad or mouse,
## gets the crosses, which glide to it; on a switch, a list, a slider, inside the options screen or
## away from the menu, they hide, as those show their own selection. Pointing at a button
## with the mouse gives it the focus, so the mouse and the keys always show the same option; a
## button in the group NO_HOVER_FOCUS takes it only with a click. The
## crosses grow with the option's text.

const CROSS: Texture2D = preload("res://assets/sprites/menu/menu_cross.png")
## The group of the nodes whose buttons, their own and those inside them, never get the crosses.
const NO_CROSSES: StringName = &"menu_no_crosses"
## The group of the buttons the mouse selects only with a click, not by pointing at them: the
## options screen's tabs, where selecting one changes the page.
const NO_HOVER_FOCUS: StringName = &"menu_no_hover_focus"

## The menu whose options get the crosses; only controls inside it count. It can be a window, as
## the replace-save question, whose buttons are its own internal children.
@export var menu: Node
## How tall a cross is, as a share of the option's font size.
@export_range(0.2, 2.0, 0.05) var height_share: float = 0.75
## The gap, in px, between a cross and the text.
@export_range(0.0, 200.0, 1.0, "suffix:px") var gap: float = 28.0
## How fast the crosses glide to a new option: higher is quicker.
@export_range(1.0, 60.0, 0.5) var glide_sharpness: float = 22.0

var _left: TextureRect
var _right: TextureRect
## The control the crosses stood by on the last frame, so they jump to the first one and glide after.
var _last: Control
## The control last asked about, and whether it is one of the menu's options: asked again only as
## the focus moves, as the answer walks up the tree.
var _checked: Control
var _checked_is_option: bool = false


func _ready() -> void:
	assert(menu != null, "MenuCrosses: assign the Menu whose options get the crosses.")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_left = _make_cross(false)
	_right = _make_cross(true)
	get_tree().node_added.connect(_on_node_added)
	_hook_buttons(menu)


func _process(delta: float) -> void:
	var focused: Control = get_viewport().gui_get_focus_owner()
	if focused != _checked:
		_checked = focused
		_checked_is_option = _is_option(focused) and menu.is_ancestor_of(focused)
	if not _checked_is_option or not focused.is_visible_in_tree():
		_left.hide()
		_right.hide()
		_last = null
		return
	var font_size: int = focused.get_theme_font_size(&"font_size")
	var text_width: float = _text_width(focused, font_size)
	var cross_size: Vector2 = Vector2(CROSS.get_width(), CROSS.get_height()) \
			* (font_size * height_share / CROSS.get_height())
	var box: Rect2 = focused.get_global_rect()
	var middle: Vector2 = box.get_center()
	var left: Vector2 = Vector2(middle.x - text_width / 2.0 - gap - cross_size.x, middle.y - cross_size.y / 2.0)
	var right: Vector2 = Vector2(middle.x + text_width / 2.0 + gap, middle.y - cross_size.y / 2.0)
	var weight: float = 1.0 if focused != _last else 1.0 - exp(-glide_sharpness * delta)
	_place(_left, left, cross_size, weight)
	_place(_right, right, cross_size, weight)
	_last = focused


## The width of what the option shows: its text for a button, the whole control otherwise.
func _text_width(control: Control, font_size: int) -> float:
	var button: Button = control as Button
	if button == null or button.text.is_empty():
		return control.size.x
	var font: Font = control.get_theme_font(&"font")
	return font.get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x


func _place(cross: TextureRect, at: Vector2, cross_size: Vector2, weight: float) -> void:
	cross.size = cross_size
	cross.global_position = cross.global_position.lerp(at, weight) if cross.visible else at
	cross.show()


func _make_cross(mirrored: bool) -> TextureRect:
	var cross: TextureRect = TextureRect.new()
	cross.texture = CROSS
	cross.flip_h = mirrored
	cross.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cross.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cross.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cross.top_level = true
	cross.hide()
	add_child(cross)
	return cross


## Every button under node, the internal ones included (a dialog's OK and Cancel), takes the focus
## on hover.
func _hook_buttons(node: Node) -> void:
	for child: Node in node.get_children(true):
		if child is BaseButton:
			_take_focus_on_hover(child as BaseButton)
		_hook_buttons(child)


## Buttons added later, as the level list's, take the focus on hover too.
func _on_node_added(node: Node) -> void:
	if node is BaseButton and menu.is_ancestor_of(node):
		_take_focus_on_hover(node as BaseButton)


func _take_focus_on_hover(button: BaseButton) -> void:
	if not button.mouse_entered.is_connected(_on_button_hovered.bind(button)):
		button.mouse_entered.connect(_on_button_hovered.bind(button))


func _on_button_hovered(button: BaseButton) -> void:
	if (button.focus_mode != Control.FOCUS_NONE and button.is_visible_in_tree()
			and not button.is_in_group(NO_HOVER_FOCUS)):
		button.grab_focus()


## Whether control is one of the menu's options: a plain button, not a switch, a box or a list, nor
## one in the group NO_CROSSES or inside a node in it, as the options screen, which marks its
## selection with its own band.
func _is_option(control: Control) -> bool:
	if not (control is Button and not control is CheckButton and not control is CheckBox
			and not control is OptionButton):
		return false
	var node: Node = control
	while node != null:
		if node.is_in_group(NO_CROSSES):
			return false
		node = node.get_parent()
	return true
