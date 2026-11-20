class_name LightningFlash
extends Node2D

## The light of a ThunderLayer's lightning on the level's backdrop: on each flash the layer tells
## of (lightning_struck), the sky behind the rock lights up in the level's pink, from the side the
## strike is on, as bright as the strike's flash is at each moment. A first, simple look, meant to
## be replaced: the light is a shader (Look) drawn over the screen, last in the level's Backdrop,
## so it lights what the backdrop holds and not the rock, the man or what follows them. Another
## shader with the same uniforms (see lightning_flash.gdshader) changes the look; another node that
## listens to lightning_struck replaces it all, with nothing to change in the sound.
## Between flashes nothing is drawn and nothing runs. It runs in its frame, so the pause holds it.

## A level's backdrop, by its path from the level, as the lighting prototype and WindEmbers find it.
const BACKDROP_PATH: NodePath = ^"Backdrop"
const DEFAULT_SHADER: Shader = preload("res://scenes/others/ambience/lightning_flash.gdshader")

## The thunder layer whose lightning this draws.
@export var thunder_layer: ThunderLayer
## The backdrop the light is drawn in; empty, that of the level it is in (its node Backdrop).
## Without one, it is drawn here, in front of what came before it.
@export var backdrop: Node2D
## The look of the light: a ShaderMaterial whose shader takes the uniforms of
## lightning_flash.gdshader. Empty, that shader.
@export var look: ShaderMaterial

@export_group("Light")
## The colour of the light: the level's pink.
@export var colour: Color = Color(1.0, 0.45, 0.82)
## How bright the light is at a flash's brightest (a strike's Strength of 1), as a multiple of what
## the backdrop shows: 1 doubles it where the light is strongest.
@export_range(0.0, 10.0, 0.05) var brightness: float = 1.5
## How far from the centre of the screen the light comes from, to the strike's side, as a share of
## the screen's width: 0.3 is a fifth of the way in from the edge.
@export_range(0.0, 1.0, 0.01) var side_offset: float = 0.3
## How high the light comes from, as a share of the screen's height from the top: 0 is the top
## edge, below 0 above the screen.
@export_range(-1.0, 1.0, 0.01) var height: float = 0.0
## How far the light reaches, as a share of the screen's width: there it is a tenth as bright.
@export_range(0.05, 3.0, 0.01) var reach: float = 0.7
## The share of the light that reaches the whole screen evenly, wherever it comes from.
@export_range(0.0, 1.0, 0.01) var spill: float = 0.2
## How much light is added flat, as a share of what lights the backdrop's own colours, so the
## darkest of it glows a little too.
@export_range(0.0, 1.0, 0.01) var haze: float = 0.12

## What the light is drawn on: a rect over the screen, in the world's coordinates.
var _rect: ColorRect
## The strike flashing now, its side and how long since its flash began.
var _strike: ThunderStrike = null
var _side: int = 0
var _age: float = 0.0
var _intensity: float = 0.0


func _ready() -> void:
	_rect = ColorRect.new()
	_rect.name = "Flash"
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.color = Color.WHITE
	_rect.visible = false
	if look == null:
		look = ShaderMaterial.new()
		look.shader = DEFAULT_SHADER
	_rect.material = look
	add_child(_rect)
	if backdrop == null:
		backdrop = _level_backdrop()
	# Deferred: the backdrop's level may be still setting up its children.
	_place_rect.call_deferred()
	set_process(false)
	if thunder_layer != null:
		thunder_layer.lightning_struck.connect(flash)


# A rect in the backdrop is not this node's: it goes with it.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and is_instance_valid(_rect) and _rect.get_parent() != self:
		_rect.queue_free()


func _process(delta: float) -> void:
	_age += delta
	if _strike == null or _age > _strike.flash_length:
		_end()
		return
	_intensity = _strike.brightness_at(_age) * brightness
	_draw_light()


## Lights the backdrop with strike's flash, from side: -1 the left of the screen, 1 the right. A
## flash still lit gives way to it.
func flash(strike: ThunderStrike, side: int) -> void:
	if strike == null:
		return
	_strike = strike
	_side = signi(side)
	_age = 0.0
	_intensity = strike.brightness_at(0.0) * brightness
	_rect.visible = true
	_draw_light()
	set_process(true)


func is_flashing() -> bool:
	return _strike != null


## How bright the light is now: the strike's flash times Brightness; 0 between flashes.
func get_intensity() -> float:
	return _intensity


## Where the light comes from now, in the screen's UV (0 to 1 across, from the left).
func get_light_centre() -> Vector2:
	return Vector2(0.5 + _side * side_offset, height)


## Whether the light is drawn in the backdrop.
func is_in_backdrop() -> bool:
	return is_instance_valid(_rect) and _rect.get_parent() != self


func _draw_light() -> void:
	var screen: Rect2 = _screen_rect()
	_rect.global_position = screen.position
	_rect.size = screen.size
	look.set_shader_parameter(&"intensity", _intensity)
	look.set_shader_parameter(&"light_colour", colour)
	look.set_shader_parameter(&"centre", get_light_centre())
	look.set_shader_parameter(&"reach", reach)
	look.set_shader_parameter(&"aspect", screen.size.x / maxf(screen.size.y, 1.0))
	look.set_shader_parameter(&"spill", spill)
	look.set_shader_parameter(&"haze", haze)


func _end() -> void:
	_strike = null
	_intensity = 0.0
	_rect.visible = false
	look.set_shader_parameter(&"intensity", 0.0)
	set_process(false)


## What the camera shows, in the world.
func _screen_rect() -> Rect2:
	var viewport: Viewport = get_viewport()
	return viewport.get_canvas_transform().affine_inverse() * viewport.get_visible_rect()


## Puts the rect last in the backdrop, so drawn after what it holds, or keeps it here without one.
func _place_rect() -> void:
	if not is_instance_valid(backdrop):
		return
	_rect.get_parent().remove_child(_rect)
	backdrop.add_child(_rect)


## The backdrop of the level it is in: among the levels in the tree, the one that holds it.
func _level_backdrop() -> Node2D:
	for node: Node in get_tree().get_nodes_in_group(Level.GROUP):
		if node.is_ancestor_of(self):
			return node.get_node_or_null(BACKDROP_PATH) as Node2D
	return null
