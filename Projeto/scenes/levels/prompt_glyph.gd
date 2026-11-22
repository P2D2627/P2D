class_name PromptGlyph
extends PanelContainer

## One action's prompt, drawn the same way in the tutorial's band at the bottom of the screen, in
## the world over Velvet, in the grab's prompt and beside the options' Back: on the keyboard, the
## action's first key or mouse button, as the controls screen names it, in a key of our own (a
## reserved key, which the controls screen never offers, by its own name, as Escape for ui_cancel);
## once a pad is the device used last (the autoload LastDevice), the pad's button, stick or trigger
## for the action, as printed on a pad of the family LastDevice gives (Xbox, PlayStation, Nintendo
## Switch or Steam Deck): its picture from Kenney's Input Prompts, tinted in the interface's bone
## colour, or, for a part with no picture, its name in the key. It follows the profile picked in the
## options, which are only reached through the pause, so it reads the Input Map again when the game
## comes back from it. It only shows: it never reads a press.

## Shown while the action has no key or mouse button.
const NO_KEY_TEXT: String = "?"
const LAST_DEVICE_PATH: NodePath = ^"/root/LastDevice"
## Where a family's pictures are: its folder in Kenney's pack, then a file name, at 128 px.
const ICON_PATH: String = "res://assets/ui/prompts/%s/Double/%s.png"
## The pad's parts by Godot's button index. Godot numbers the buttons by place, as on an Xbox pad: "a"
## is the bottom face button on every pad, whatever is printed on it.
const BUTTON_PARTS: Dictionary[int, String] = {
	JOY_BUTTON_A: "a", JOY_BUTTON_B: "b", JOY_BUTTON_X: "x", JOY_BUTTON_Y: "y",
	JOY_BUTTON_BACK: "back", JOY_BUTTON_GUIDE: "guide", JOY_BUTTON_START: "start",
	JOY_BUTTON_LEFT_STICK: "l3", JOY_BUTTON_RIGHT_STICK: "r3",
	JOY_BUTTON_LEFT_SHOULDER: "lb", JOY_BUTTON_RIGHT_SHOULDER: "rb",
	JOY_BUTTON_DPAD_UP: "up", JOY_BUTTON_DPAD_DOWN: "down",
	JOY_BUTTON_DPAD_LEFT: "left", JOY_BUTTON_DPAD_RIGHT: "right",
}
## The pad's sticks and triggers by Godot's axis, each way: [less than 0, more than 0].
const AXIS_PARTS: Dictionary[int, Array] = {
	JOY_AXIS_LEFT_X: ["ls_left", "ls_right"], JOY_AXIS_LEFT_Y: ["ls_up", "ls_down"],
	JOY_AXIS_RIGHT_X: ["rs_left", "rs_right"], JOY_AXIS_RIGHT_Y: ["rs_up", "rs_down"],
	JOY_AXIS_TRIGGER_LEFT: ["lt", "lt"], JOY_AXIS_TRIGGER_RIGHT: ["rt", "rt"],
}
## The parts every family names alike, [name, file name after the family's prefix].
const SHARED_PARTS: Dictionary[String, Array] = {
	"l3": ["L3", "stick_l_press"], "r3": ["R3", "stick_r_press"],
	"up": ["D-pad ↑", "dpad_up"], "down": ["D-pad ↓", "dpad_down"],
	"left": ["D-pad ←", "dpad_left"], "right": ["D-pad →", "dpad_right"],
	"ls_left": ["LS ←", "stick_l_left"], "ls_right": ["LS →", "stick_l_right"],
	"ls_up": ["LS ↑", "stick_l_up"], "ls_down": ["LS ↓", "stick_l_down"],
	"rs_left": ["RS ←", "stick_r_left"], "rs_right": ["RS →", "stick_r_right"],
	"rs_up": ["RS ↑", "stick_r_up"], "rs_down": ["RS ↓", "stick_r_down"],
}
## Each family's folder in the pack and the prefix of its file names.
const FAMILY_FOLDERS: Dictionary[int, String] = {
	GameLastDevice.PadFamily.XBOX: "Xbox Series",
	GameLastDevice.PadFamily.PLAYSTATION: "PlayStation Series",
	GameLastDevice.PadFamily.NINTENDO: "Nintendo Switch",
	GameLastDevice.PadFamily.STEAM_DECK: "Steam Deck",
}
const FAMILY_PREFIXES: Dictionary[int, String] = {
	GameLastDevice.PadFamily.XBOX: "xbox",
	GameLastDevice.PadFamily.PLAYSTATION: "playstation",
	GameLastDevice.PadFamily.NINTENDO: "switch",
	GameLastDevice.PadFamily.STEAM_DECK: "steamdeck",
}
## The parts each family prints its own way, [name, whole file name]; an empty file name has no
## picture in the pack. A Switch pad has its letters the other way round: B at the bottom, A right.
const FAMILY_PARTS: Dictionary[int, Dictionary] = {
	GameLastDevice.PadFamily.XBOX: {
		"a": ["A", "xbox_button_a"], "b": ["B", "xbox_button_b"],
		"x": ["X", "xbox_button_x"], "y": ["Y", "xbox_button_y"],
		"back": ["View", "xbox_button_view"], "start": ["Menu", "xbox_button_menu"],
		"guide": ["Guide", "xbox_guide"],
		"lb": ["LB", "xbox_lb"], "rb": ["RB", "xbox_rb"], "lt": ["LT", "xbox_lt"], "rt": ["RT", "xbox_rt"],
	},
	GameLastDevice.PadFamily.PLAYSTATION: {
		"a": ["Cross", "playstation_button_cross"], "b": ["Circle", "playstation_button_circle"],
		"x": ["Square", "playstation_button_square"], "y": ["Triangle", "playstation_button_triangle"],
		"back": ["Share", "playstation4_button_share"],
		"start": ["Options", "playstation4_button_options"], "guide": ["PS", ""],
		"lb": ["L1", "playstation_trigger_l1"], "rb": ["R1", "playstation_trigger_r1"],
		"lt": ["L2", "playstation_trigger_l2"], "rt": ["R2", "playstation_trigger_r2"],
	},
	GameLastDevice.PadFamily.NINTENDO: {
		"a": ["B", "switch_button_b"], "b": ["A", "switch_button_a"],
		"x": ["Y", "switch_button_y"], "y": ["X", "switch_button_x"],
		"back": ["−", "switch_button_minus"], "start": ["+", "switch_button_plus"],
		"guide": ["Home", "switch_button_home"],
		"lb": ["L", "switch_button_l"], "rb": ["R", "switch_button_r"],
		"lt": ["ZL", "switch_button_zl"], "rt": ["ZR", "switch_button_zr"],
	},
	GameLastDevice.PadFamily.STEAM_DECK: {
		"a": ["A", "steamdeck_button_a"], "b": ["B", "steamdeck_button_b"],
		"x": ["X", "steamdeck_button_x"], "y": ["Y", "steamdeck_button_y"],
		"back": ["View", "steamdeck_button_view"], "start": ["Menu", "steamdeck_button_options"],
		"guide": ["Steam", "steamdeck_button_guide"],
		"lb": ["L1", "steamdeck_button_l1"], "rb": ["R1", "steamdeck_button_r1"],
		"lt": ["L2", "steamdeck_button_l2"], "rt": ["R2", "steamdeck_button_r2"],
	},
}

## The pictures loaded so far, by path; null for a path with none. Shared by every glyph.
static var _icons: Dictionary[String, Texture2D] = {}

## The action whose key it shows, such as &"jump".
@export var action: StringName = &"":
	set(value):
		action = value
		if is_node_ready():
			refresh()

## Whether it shows the pad's button now, rather than the key.
var _shows_pad: bool = false
## No frame, for a picture, which has its own; the key's frame is the theme's PromptKey.
var _no_box: StyleBoxEmpty = StyleBoxEmpty.new()

@onready var _label: Label = %Label
@onready var _icon: TextureRect = %Icon
@onready var _last_device: GameLastDevice = get_node_or_null(LAST_DEVICE_PATH) as GameLastDevice


func _ready() -> void:
	# The picture takes the key's name colour from the theme, so the colour lives in one place.
	_icon.self_modulate = _label.get_theme_color(&"font_color")
	if _last_device != null:
		_last_device.device_changed.connect(_on_device_changed)
		_last_device.pad_changed.connect(refresh)
	refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_UNPAUSED and is_node_ready():
		refresh()


## The text it shows now: the key's or the pad button's name, or NO_KEY_TEXT.
func get_text() -> String:
	return _label.text


func shows_pad() -> bool:
	return _shows_pad


## Whether it shows a picture now, rather than a name in a key.
func shows_icon() -> bool:
	return _icon.visible


## Reads the action's key again from the Input Map: the pad's button when a pad is the device used
## last and the action has one, and the key otherwise.
func refresh() -> void:
	if action.is_empty():
		return
	assert(InputMap.has_action(action), "PromptGlyph: Action %s is not in the Input Map." % action)
	var on_pad: bool = _last_device != null and _last_device.is_pad()
	var family: GameLastDevice.PadFamily = (_last_device.get_pad_family() if on_pad
			else GameLastDevice.PadFamily.XBOX)
	var pad: String = pad_text(action, family) if on_pad else ""
	_shows_pad = not pad.is_empty()
	_label.text = pad if _shows_pad else key_text(action)
	var picture: Texture2D = pad_icon(action, family) if _shows_pad else null
	_icon.texture = picture
	_icon.visible = picture != null
	_label.visible = picture == null
	if picture == null:
		remove_theme_stylebox_override(&"panel")
	else:
		add_theme_stylebox_override(&"panel", _no_box)
	reset_size()


## The name of the first key or mouse button the Input Map has for action, as the controls screen
## shows it; with none it can show, the first key by its own name, as a reserved key such as Escape
## has no binding; NO_KEY_TEXT with no key at all.
static func key_text(for_action: StringName) -> String:
	var first_key: InputEventKey = null
	for event: InputEvent in InputMap.action_get_events(for_action):
		var binding: String = InputProfiles.binding_from_event(event)
		if not binding.is_empty():
			return InputProfiles.binding_title(binding)
		if first_key == null:
			first_key = event as InputEventKey
	if first_key != null:
		return OS.get_keycode_string(InputProfiles.keycode_of(first_key))
	return NO_KEY_TEXT


## The name of the first pad button, stick or trigger the Input Map has for action, as printed on a
## pad of family; empty with none.
static func pad_text(for_action: StringName,
		family: GameLastDevice.PadFamily = GameLastDevice.PadFamily.XBOX) -> String:
	var part: String = pad_part(for_action)
	if part.is_empty():
		return ""
	var looks: Array = _looks_of(part, family)
	return looks[0] if not looks.is_empty() else part.capitalize()


## The picture of the first pad button, stick or trigger the Input Map has for action, as drawn for
## a pad of family; null with none, or with no picture in the pack.
static func pad_icon(for_action: StringName,
		family: GameLastDevice.PadFamily = GameLastDevice.PadFamily.XBOX) -> Texture2D:
	var looks: Array = _looks_of(pad_part(for_action), family)
	if looks.is_empty() or (looks[1] as String).is_empty():
		return null
	var path: String = ICON_PATH % [FAMILY_FOLDERS[family], looks[1]]
	if not _icons.has(path):
		_icons[path] = load(path) as Texture2D if ResourceLoader.exists(path) else null
	return _icons[path]


## The part of the pad the first pad binding of action is, as BUTTON_PARTS or AXIS_PARTS name it;
## empty with none, and "button 15" or "axis 6" for one they do not name.
static func pad_part(for_action: StringName) -> String:
	for event: InputEvent in InputMap.action_get_events(for_action):
		var button: InputEventJoypadButton = event as InputEventJoypadButton
		if button != null:
			return BUTTON_PARTS.get(button.button_index, "button %d" % button.button_index)
		var motion: InputEventJoypadMotion = event as InputEventJoypadMotion
		if motion != null:
			if not AXIS_PARTS.has(motion.axis):
				return "axis %d" % motion.axis
			return AXIS_PARTS[motion.axis][0 if motion.axis_value < 0.0 else 1]
	return ""


## [name, file name] of part on a pad of family; empty for a part no table names.
static func _looks_of(part: String, family: GameLastDevice.PadFamily) -> Array:
	var own: Dictionary = FAMILY_PARTS[family]
	if own.has(part):
		return own[part]
	if SHARED_PARTS.has(part):
		var shared: Array = SHARED_PARTS[part]
		return [shared[0], "%s_%s" % [FAMILY_PREFIXES[family], shared[1]]]
	return []


func _on_device_changed(_device: GameLastDevice.Device) -> void:
	refresh()
