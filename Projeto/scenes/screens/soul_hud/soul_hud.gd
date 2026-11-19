class_name SoulHud
extends CanvasLayer

## The soul bar in the top left corner: the man's soul (his SP, the life of the game) in the bar, the
## aura in its frame always moving, and the power he has under it, between the arrows that will one
## day choose between powers. For now the power is the crucifix: gold while it can go up, blue with
## the seconds left in red while it cools down. Once it is lost, after the first upgrade, a
## placeholder holds its place until the upgrades have their own art. It only shows: it reads the
## SoulPoints and the Crucifix and changes neither.

## The art's own size, in px: every piece of it is drawn on a canvas of this size, in place.
const ART_SIZE: Vector2 = Vector2(1024.0, 512.0)
## The part of the canvas the art takes, in its px: from the frame's left edge to the bar's end.
const ART_USED: Rect2 = Rect2(38.0, 60.0, 867.0, 395.0)

@export var player: Player
## The crucifix it shows. Without one, or once it is lost, the placeholder shows instead.
@export var crucifix: Crucifix

@export_group("Layout")
## How wide the whole soul bar is on the 1920 px wide screen, in px.
@export_range(200.0, 900.0, 4.0, "suffix:px") var width: float = 440.0:
	set(value):
		width = value
		_lay_out()
## Gap between the soul bar and the screen's top and left edges, in px.
@export var margin: Vector2 = Vector2(32.0, 32.0):
	set(value):
		margin = value
		_lay_out()

@export_group("Look")
## The life, in the middle cyan of the aura.
@export var fill_color: Color = Color("2ee6df"):
	set(value):
		fill_color = value
		if is_node_ready():
			_fill.color = value
## The life missing, behind the filled part of the bar.
@export var empty_color: Color = Color.BLACK:
	set(value):
		empty_color = value
		if is_node_ready():
			_back.color = value
## How fast the aura moves, in frames per second.
@export_range(1.0, 30.0, 1.0, "suffix:fps") var aura_fps: float = 12.0
## The aura's drawings, in order; it loops through them.
@export var aura_frames: Array[Texture2D] = []
@export var cross_ready: Texture2D
@export var cross_spent: Texture2D

var _aura_time: float = 0.0
var _aura_index: int = 0
## The seconds shown in the cooldown, so the text is only rewritten when they change.
var _shown_seconds: int = -1

@onready var _art: Control = %Art
@onready var _back: ColorRect = %BarBack
@onready var _fill: ColorRect = %BarFill
@onready var _aura: TextureRect = %Aura
@onready var _cross: TextureRect = %Cross
@onready var _cooldown: Label = %Cooldown
@onready var _placeholder: Control = %Placeholder


func _ready() -> void:
	_lay_out()
	_back.color = empty_color
	_fill.color = fill_color
	if not aura_frames.is_empty():
		_aura.texture = aura_frames[0]
	if is_instance_valid(player) and is_instance_valid(player.soul_points):
		player.soul_points.sp_changed.connect(_on_sp_changed)
		_on_sp_changed(player.soul_points.get_sp(), player.soul_points.get_max_sp())
	_update_power()


func _process(delta: float) -> void:
	_step_aura(delta)
	_update_power()


## The share of the bar filled, from 0 to 1. For the tests.
func get_fill_ratio() -> float:
	return _fill.size.x / _back.size.x


## True while the gold cross shows: the crucifix is there and may go up.
func is_cross_ready() -> bool:
	return _cross.visible and _cross.texture == cross_ready


## The cooldown's text, empty unless the crucifix is cooling down. For the tests.
func get_cooldown_text() -> String:
	return _cooldown.text if _cooldown.visible else ""


func is_placeholder_shown() -> bool:
	return _placeholder.visible


## Scales the art's canvas so its used part is Width wide and puts that part Margin from the corner.
func _lay_out() -> void:
	if not is_node_ready():
		return
	var scale: float = width / ART_USED.size.x
	_art.size = ART_SIZE
	_art.scale = Vector2.ONE * scale
	_art.position = margin - ART_USED.position * scale


func _step_aura(delta: float) -> void:
	if aura_frames.is_empty():
		return
	_aura_time += delta
	var frame_time: float = 1.0 / aura_fps
	if _aura_time < frame_time:
		return
	_aura_time = fmod(_aura_time, frame_time)
	_aura_index = (_aura_index + 1) % aura_frames.size()
	_aura.texture = aura_frames[_aura_index]


## The power's slot: the crucifix while there is one, gold or blue with its seconds; else the placeholder.
func _update_power() -> void:
	var has_crucifix: bool = is_instance_valid(crucifix) and not crucifix.is_queued_for_deletion()
	_placeholder.visible = not has_crucifix
	_cross.visible = has_crucifix
	var cooling: bool = has_crucifix and crucifix.get_phase() == Crucifix.Phase.COOLDOWN
	_cross.texture = cross_spent if cooling else cross_ready
	_cooldown.visible = cooling
	if not cooling:
		_shown_seconds = -1
		return
	var seconds: int = ceili(crucifix.get_cooldown_left())
	if seconds != _shown_seconds:
		_shown_seconds = seconds
		_cooldown.text = str(seconds)


func _on_sp_changed(current: float, maximum: float) -> void:
	var ratio: float = clampf(current / maximum, 0.0, 1.0) if maximum > 0.0 else 0.0
	_fill.size.x = _back.size.x * ratio
