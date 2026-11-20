class_name EmberLook
extends RefCounted

## The look of the glowing embers that fly in the game: the gusts' (WindEmbers), and the main menu's
## (MenuEmbers) once it can share it. A core coloured by its heat, which cools towards deep red and
## goes out, drawn as a streak as long as it moves while a film camera's shutter is open, with a
## faint halo, flickering as it tumbles. They give light, so they are drawn added and unshaded. The
## textures and the material are made once and shared by every node that draws embers. The fires'
## embers (RisingEmbers) are drawn flat instead, as the flame is, with only the halo as their bloom
## (draw_glow), and take Blackbody Ramp when no colours of their own are set.

## A halo's size, as a multiple of its core.
const HALO_SIZE: float = 4.0
## The dots' texture size, in px.
const DOT_SIZE: int = 64
## How far out from its heart a core stays solid before it fades, as a share of its radius: the
## main menu's spark.
const CORE_SOLID_SHARE: float = 0.35
## The flicker's second wave runs at these shares of the first's phase and pace: not whole numbers,
## so the two never fall into step.
const SECOND_WAVE_PHASE: float = 1.7
const SECOND_WAVE_PACE: float = 0.63
## The heats over which the flicker deepens, from a cooled red (x) to a hot ember (y).
const FLICKER_HEAT: Vector2 = Vector2(0.1, 0.4)

static var _core: GradientTexture2D
static var _halo: GradientTexture2D
static var _material: CanvasItemMaterial


## What a node that draws embers takes as its material: added, so they give light, and unshaded,
## so the level's lights neither light nor shade them.
static func light_material() -> CanvasItemMaterial:
	if _material == null:
		_material = CanvasItemMaterial.new()
		_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	return _material


## Draws one ember on canvas, at a point of the canvas: its core, size core across, coloured by
## colour's rgb, as bright as light (an alpha), stretched along velocity into a streak as long as it
## moves in shutter seconds, and its halo, halo_share as bright as the core.
static func draw(canvas: CanvasItem, at: Vector2, velocity: Vector2, core: float, colour: Color,
		light: float, halo_share: float, shutter: float) -> void:
	_make_dots()
	var tint := Color(colour.r, colour.g, colour.b, 1.0)
	var streak: float = maxf(core, velocity.length() * shutter)
	var halo: float = core * HALO_SIZE
	canvas.draw_set_transform(at)
	canvas.draw_texture_rect(_halo, Rect2(Vector2(-halo, -halo) * 0.5, Vector2(halo, halo)), false,
			Color(tint, light * halo_share))
	# A streak spreads the same light along its length, so each of its pixels is dimmer: by the
	# square root of how much longer it is, as the main menu's, or the fastest vanish.
	canvas.draw_set_transform(at, velocity.angle())
	canvas.draw_texture_rect(_core, Rect2(Vector2(-streak, -core) * 0.5, Vector2(streak, core)), false,
			Color(tint, light * sqrt(core / streak)))
	canvas.draw_set_transform(Vector2.ZERO)


## The tumble's flicker, as a share of the brightness: two waves at an ember's own phase and pace
## (seconds of its flicker times its rate, in turns), depth deep, weaker as it cools to a saturated
## red, down to cooled of depth, as the main menu's.
static func flicker(phase: float, pace: float, heat: float, depth: float, cooled: float) -> float:
	var turns: float = pace * TAU
	var wave: float = ((0.5 + 0.5 * sin(phase + turns))
			* (0.5 + 0.5 * sin(phase * SECOND_WAVE_PHASE + turns * SECOND_WAVE_PACE)))
	var deep: float = depth * lerpf(cooled, 1.0, smoothstep(FLICKER_HEAT.x, FLICKER_HEAT.y, heat))
	return 1.0 - deep + deep * wave


## A wood ember's light by heat, the main menu's: the colours of a black body from about 1000 K to
## a core the camera saturates, with the brightness squeezed into what a screen can show.
static func blackbody_ramp() -> Gradient:
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.1, 0.25, 0.45, 0.65, 0.85, 1.0])
	ramp.colors = PackedColorArray([Color(0.7, 0.14, 0.01, 0.0), Color(0.7, 0.14, 0.01, 0.05),
			Color(0.9, 0.22, 0.01, 0.15), Color(1.0, 0.32, 0.02, 0.35), Color(1.0, 0.44, 0.06, 0.6),
			Color(1.0, 0.62, 0.2, 0.85), Color(1.0, 0.88, 0.62, 1.0)])
	return ramp


## Draws a soft round glow on canvas, at a point of the canvas, diameter across, coloured by colour's
## rgb, as bright as light (an alpha): the halo of the embers, alone, such as the bloom round the
## fires' flat embers (RisingEmbers). The canvas takes Light Material.
static func draw_glow(canvas: CanvasItem, at: Vector2, diameter: float, colour: Color,
		light: float) -> void:
	_make_dots()
	var tint := Color(colour.r, colour.g, colour.b, light)
	canvas.draw_texture_rect(_halo, Rect2(at - Vector2(diameter, diameter) * 0.5,
			Vector2(diameter, diameter)), false, tint)


static func _make_dots() -> void:
	if _core == null:
		_core = _dot(PackedFloat32Array([0.0, CORE_SOLID_SHARE, 1.0]),
				PackedFloat32Array([1.0, 1.0, 0.0]))
		_halo = _dot(PackedFloat32Array([0.0, 1.0]), PackedFloat32Array([1.0, 0.0]))


## A round white dot, its alpha falling from its heart outwards as given.
static func _dot(offsets: PackedFloat32Array, alphas: PackedFloat32Array) -> GradientTexture2D:
	var colours := PackedColorArray()
	for alpha: float in alphas:
		colours.append(Color(1.0, 1.0, 1.0, alpha))
	var gradient := Gradient.new()
	gradient.offsets = offsets
	gradient.colors = colours
	var dot := GradientTexture2D.new()
	dot.gradient = gradient
	dot.width = DOT_SIZE
	dot.height = DOT_SIZE
	dot.fill = GradientTexture2D.FILL_RADIAL
	dot.fill_from = Vector2(0.5, 0.5)
	dot.fill_to = Vector2(1.0, 0.5)
	return dot
