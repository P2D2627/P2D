extends CanvasLayer

## The dark a level draws over the screen at a restart (#263), above the level and its own overlays
## and below the pause menu, so a pause during a death still shows. It only draws what the level
## asks for: the whole screen at some darkness (cover), an iris of some radius around a point on the
## screen (draw_at), or nothing. Hidden, it costs nothing.

const SHADER: Shader = preload("res://scenes/others/shaders/death_iris.gdshader")
const DeathIrisStats := preload("res://scenes/levels/death_iris_stats.gd")
## Above the level's overlays, below the pause menu (layer 10).
const LAYER: int = 5
## A turn of the edge's bumps on each new frame of the effects, in radians.
const PHASE_STEP: float = 2.4

var _cover: ColorRect = ColorRect.new()
var _material: ShaderMaterial = ShaderMaterial.new()
var _centre: Vector2 = Vector2.ZERO
var _radius: float = -1.0
var _darkness: float = 0.0
var _frame: int = -1


func _init() -> void:
	layer = LAYER
	_material.shader = SHADER
	_cover.material = _material
	_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cover.visible = false
	add_child(_cover)


## Draws the iris: ink outside Radius px around Centre, a point on the screen, in Stats' look. Frame
## is the frame of the effects it is on: a new one turns the edge's bumps.
func draw_at(centre: Vector2, radius: float, frame: int, stats: DeathIrisStats) -> void:
	_centre = centre
	_radius = maxf(radius, 0.0)
	if frame != _frame:
		_frame = frame
		_material.set_shader_parameter(&"phase", PHASE_STEP * frame)
	_material.set_shader_parameter(&"centre", centre)
	_material.set_shader_parameter(&"radius", _radius)
	_material.set_shader_parameter(&"size", _cover.size)
	_material.set_shader_parameter(&"wobble", minf(stats.wobble_px, _radius * stats.wobble_share))
	_material.set_shader_parameter(&"lobes", float(stats.wobble_lobes))
	_material.set_shader_parameter(&"ink", stats.ink)
	_material.set_shader_parameter(&"fade", 1.0)
	_darkness = 1.0
	_cover.visible = true


## Darkens the whole screen with Stats' ink, from 0 (clear) to 1 (all dark).
func cover(darkness: float, stats: DeathIrisStats) -> void:
	_radius = 0.0
	_darkness = clampf(darkness, 0.0, 1.0)
	_material.set_shader_parameter(&"radius", 0.0)
	_material.set_shader_parameter(&"wobble", 0.0)
	_material.set_shader_parameter(&"ink", stats.ink)
	_material.set_shader_parameter(&"fade", _darkness)
	_cover.visible = true


## Draws nothing.
func clear() -> void:
	_radius = -1.0
	_darkness = 0.0
	_cover.visible = false


## How dark it makes the screen where it is dark: 1 for an iris, the fade's darkness for a cover, 0
## when nothing is drawn.
func get_darkness() -> float:
	return _darkness


func is_drawn() -> bool:
	return _cover.visible


## The radius drawn, in px; -1 when nothing is.
func get_radius() -> float:
	return _radius


## The point on the screen it is drawn around.
func get_centre() -> Vector2:
	return _centre


## The size of the screen it covers, in px.
func get_screen_size() -> Vector2:
	return _cover.size
