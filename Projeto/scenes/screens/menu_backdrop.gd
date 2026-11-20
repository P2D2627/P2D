@tool
class_name MenuBackdrop
extends Control

## What lies behind a menu: a black background, rays of light from the top right corner, and the
## main character on the left, painted with its light and shade (menu_character.png). Seen in the
## editor too, still: the screen only moves in the game, so the editor never saves a moved frame.
## The screen is never still. The character's painting (Character/Art) breathes, swelling a little
## from his feet, and floats, sinking a little, on two waves of their own periods, so the eye never
## catches a loop; it moves inside Character, which the layout places and which never moves, so a
## change of the screen's size still puts him right. The light comes from the top right (Rays); a
## fire burns below the bottom left, by him: its glow (FireGlow), three layers of smoke, each its own
## size, pace and depth (SmokeFar and SmokeMid behind him, SmokeNear in front of his cut bottom
## edge; the glow and all three gather round him and thin out to nothing on both sides, so they
## neither fill the screen's corner nor drift under the menu), its embers (EmbersFar and the ash
## behind him, EmbersNear and the discs out of focus near the lens, EmbersBokeh, in front), and its
## warm light on him from below (Art/Light: his own painting added over himself, so
## his lit parts brighten most). One flame drives them all: a slow waver and a faint fast flicker,
## kept well under the swing a flash would need. The rays from above breathe on their own, slower,
## and their light falls on him from the top right too (Art/AboveLight), brightening and sweeping
## across his hood as they breathe. Both lights on him move slowly, so they read as living light,
## never as flashes.
## While a screen such as the options is open over him, he steps back, darker (recede()), and the
## fire's layers go left with him, each by its own depth (Depth): those behind him less, those in
## front more, so the scene reads deep. The menu's text sits inside the scene too: the layers behind
## him draw under it and he, the near smoke, the near embers and the rays draw over it (z index 1).
## His painting is cut at its left edge, so it fades into the dark there (Left Fade).

## The noises reach about this far each way; each waver is scaled to it.
const NOISE_REACH: float = 0.6
## One noise step per unit along it, so each speed reads as noise steps per second.
const NOISE_FREQUENCY: float = 1.0
## How far along the fire's noise the fast flicker reads, so it never follows the slow waver.
const FLICKER_NOISE_OFFSET: float = 1000.0
const Embers := preload("res://scenes/screens/menu_embers.gd")

## How opaque the black background is: 1 on the main menu, less over the game when paused.
@export_range(0.0, 1.0, 0.05) var background_alpha: float = 1.0:
	set(value):
		background_alpha = value
		_apply()

@export_group("Idle")
## How much he swells at the top of each breath, as a share of his size, from his feet.
@export_range(0.0, 0.05, 0.001) var breath_scale: float = 0.006
## How long one breath takes.
@export_range(0.5, 10.0, 0.1, "suffix:s") var breath_period: float = 4.2
## How far he sinks at the bottom of each float. He only ever sinks below where he is placed: the
## painting is cut at its bottom edge, and rising would show the cut.
@export_range(0.0, 40.0, 0.5, "suffix:px") var float_depth: float = 8.0
## How long one float takes: not a multiple of the breath, so the two never fall into a loop.
@export_range(0.5, 15.0, 0.1, "suffix:s") var float_period: float = 6.5
## How far in from his cut left edge he fades out of the dark, as a share of his width.
@export_range(0.0, 0.5, 0.01) var left_fade: float = 0.18

@export_group("Fire")
## How much the flame wavers slowly, as a share of its brightness: slow enough never to flash.
@export_range(0.0, 0.6, 0.01) var fire_waver: float = 0.3
## How fast it wavers: the slow noise's steps per second.
@export_range(0.0, 3.0, 0.05) var fire_waver_speed: float = 0.5
## How much it flickers fast, as a share of its brightness: under the 10 % a flash would need.
@export_range(0.0, 0.09, 0.005) var fire_flicker: float = 0.03
## How fast it flickers: the fast noise's steps per second.
@export_range(0.0, 15.0, 0.5) var fire_flicker_speed: float = 8.0
## How bright the fire's light on the character is, added over his painted light.
@export_range(0.0, 1.0, 0.01) var character_glow: float = 0.4
## How far the edge of that light moves up and down with the flame, as a share of his height.
@export_range(0.0, 0.15, 0.001) var light_edge_shift: float = 0.05

@export_group("Recede")
## How bright he stays while a screen such as the options is open over him, as a share.
@export_range(0.0, 1.0, 0.05) var receded_brightness: float = 0.4
## How far he slides away, to the left, while it is open.
@export_range(0.0, 400.0, 1.0, "suffix:px") var receded_slide: float = 115.0
## How long he takes to step back, ease out.
@export_range(0.0, 1.0, 0.01, "suffix:s") var recede_time: float = 0.3
## How long he takes to come forward again, ease in, as a share of Recede Time: a little faster.
@export_range(0.1, 2.0, 0.05) var return_share: float = 0.8

@export_group("Depth")
## How far each layer of the fire goes left as he steps back, as a share of his own slide: under 1
## lies behind him, over 1 in front of him.
@export_range(0.0, 2.0, 0.05) var smoke_far_depth: float = 0.35
@export_range(0.0, 2.0, 0.05) var fire_glow_depth: float = 0.55
@export_range(0.0, 2.0, 0.05) var smoke_mid_depth: float = 0.7
@export_range(0.0, 2.0, 0.05) var embers_far_depth: float = 0.8
@export_range(0.0, 2.0, 0.05) var smoke_near_depth: float = 1.4
@export_range(0.0, 2.0, 0.05) var embers_near_depth: float = 1.25
@export_range(0.0, 2.0, 0.05) var ash_depth: float = 0.85
@export_range(0.0, 3.0, 0.05) var embers_bokeh_depth: float = 1.8

@export_group("Rays")
## How much the rays from above breathe, as a share of their brightness.
@export_range(0.0, 0.5, 0.01) var rays_breath: float = 0.2
## How fast they breathe: their noise's steps per second.
@export_range(0.0, 2.0, 0.05) var rays_breath_speed: float = 0.35
## How fast the rays sway.
@export_range(0.0, 2.0, 0.01) var rays_sway_speed: float = 0.35
## How bright the rays' light on him is, added over his painted light from the top right.
@export_range(0.0, 1.0, 0.01) var above_glow: float = 0.5
## How much that light swells and fades as the rays breathe, as a share of its brightness.
@export_range(0.0, 1.0, 0.01) var above_waver: float = 0.7
## How far its edge sweeps across him as they breathe, as a share of his size.
@export_range(0.0, 0.4, 0.005) var above_sweep: float = 0.2

var _time: float = 0.0
## How far he has stepped back: 0 in front, 1 receded.
var _receded: float = 0.0
## How far back the fire's layers were last put, so they move only while he steps.
var _layers_receded: float = 0.0
var _recede_tween: Tween
var _fire_noise: FastNoiseLite = FastNoiseLite.new()
var _rays_noise: FastNoiseLite = FastNoiseLite.new()
var _rays_material: ShaderMaterial
var _rays_strength: float = 0.0
var _rays_glow: float = 0.0
var _light_material: ShaderMaterial
var _above_material: ShaderMaterial
var _glow_material: ShaderMaterial
var _smoke_materials: Array[ShaderMaterial] = []

@onready var _background: ColorRect = $Background
@onready var _fire_glow: ColorRect = $FireGlow
@onready var _art: TextureRect = $Character/Art
@onready var _art_light: TextureRect = $Character/Art/Light
@onready var _art_above_light: TextureRect = $Character/Art/AboveLight
@onready var _smokes: Array[ColorRect] = [$SmokeFar, $SmokeMid, $SmokeNear]
@onready var _embers: Array[Embers] = [$EmbersFar, $Ash, $EmbersNear, $EmbersBokeh]
## Each of the fire's layers and the property that holds its depth, read each time the layers
## slide, so a change in the Inspector shows.
@onready var _layers: Dictionary[Control, StringName] = {
	$SmokeFar: &"smoke_far_depth",
	$FireGlow: &"fire_glow_depth",
	$SmokeMid: &"smoke_mid_depth",
	$EmbersFar: &"embers_far_depth",
	$Ash: &"ash_depth",
	$SmokeNear: &"smoke_near_depth",
	$EmbersNear: &"embers_near_depth",
	$EmbersBokeh: &"embers_bokeh_depth",
}
@onready var _rays: ColorRect = $Rays


func _ready() -> void:
	_apply()
	if Engine.is_editor_hint():
		set_process(false)
		return
	for noise: FastNoiseLite in [_fire_noise, _rays_noise]:
		noise.seed = randi()
		noise.frequency = NOISE_FREQUENCY
	# The main menu's backdrop and the pause's share the scene's materials: each takes its own, so
	# neither sets the other's flame.
	_rays_material = _own_material(_rays)
	_light_material = _own_material(_art_light)
	_above_material = _own_material(_art_above_light)
	for painted: ShaderMaterial in [_own_material(_art), _light_material, _above_material]:
		painted.set_shader_parameter(&"left_fade", left_fade)
	_glow_material = _own_material(_fire_glow)
	for smoke: ColorRect in _smokes:
		_smoke_materials.append(_own_material(smoke))
		smoke.resized.connect(_set_the_smoke_aspect.bind(smoke))
		_set_the_smoke_aspect(smoke)
	# The scene's material sets both, so the light breathes round what it shows in the editor.
	_rays_strength = _rays_material.get_shader_parameter(&"strength")
	_rays_glow = _rays_material.get_shader_parameter(&"glow")
	_rays_material.set_shader_parameter(&"sway_speed", rays_sway_speed)
	_art.resized.connect(_set_the_pivot)
	_set_the_pivot()


## Nothing moves while the menu is hidden: the pause's stays in the tree through the whole game.
func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	var inhale: float = 0.5 + 0.5 * sin(TAU * _time / breath_period)
	var floated: float = 0.5 + 0.5 * sin(TAU * _time / float_period)
	_art.position = Vector2(-receded_slide * _receded, float_depth * (1.0 - floated))
	_art.scale = Vector2.ONE * (1.0 + breath_scale * inhale)
	var brightness: float = lerpf(1.0, receded_brightness, _receded)
	_art.modulate = Color(brightness, brightness, brightness, 1.0)
	var slow: float = _wave(_fire_noise, _time * fire_waver_speed)
	var fast: float = _wave(_fire_noise, FLICKER_NOISE_OFFSET + _time * fire_flicker_speed)
	var fire: float = 1.0 + fire_waver * slow + fire_flicker * fast
	_light_material.set_shader_parameter(&"strength", character_glow * fire)
	_light_material.set_shader_parameter(&"shift", light_edge_shift * slow)
	_glow_material.set_shader_parameter(&"fire_level", fire)
	for smoke: ShaderMaterial in _smoke_materials:
		smoke.set_shader_parameter(&"fire_level", fire)
	for embers: Embers in _embers:
		embers.fire_level = fire
	if _receded != _layers_receded:
		_slide_the_layers()
	var breath: float = _wave(_rays_noise, _time * rays_breath_speed)
	var rays: float = 1.0 + rays_breath * breath
	_rays_material.set_shader_parameter(&"strength", _rays_strength * rays)
	_rays_material.set_shader_parameter(&"glow", _rays_glow * rays)
	_above_material.set_shader_parameter(&"strength", above_glow * (1.0 + above_waver * breath))
	_above_material.set_shader_parameter(&"shift", above_sweep * breath)


## He steps back, darker, while a screen such as the options is open over him, so the two do not
## fight for the eye, and comes forward again as it closes; at once, with instantly, as a menu opens.
func recede(back: bool, instantly: bool = false) -> void:
	if _recede_tween != null:
		_recede_tween.kill()
	var target: float = 1.0 if back else 0.0
	if instantly or Engine.is_editor_hint():
		_receded = target
		return
	_recede_tween = create_tween()
	_recede_tween.tween_property(self, ^"_receded", target,
			recede_time if back else recede_time * return_share) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT if back else Tween.EASE_IN)


func _apply() -> void:
	if is_node_ready():
		_background.color = Color(0.0, 0.0, 0.0, background_alpha)


## The fire's layers go left with him, each by its depth. Through their offsets, which stay
## measured from their anchors, so a change of the screen's size still puts them right.
func _slide_the_layers() -> void:
	_layers_receded = _receded
	for layer: Control in _layers:
		var slide: float = -receded_slide * _receded * float(get(_layers[layer]))
		layer.offset_left = slide
		layer.offset_right = slide


## The breath swells him from his feet: his pivot is the middle of his bottom edge.
func _set_the_pivot() -> void:
	_art.pivot_offset = Vector2(_art.size.x / 2.0, _art.size.y)


## A smoke layer's curls keep their shape whatever its rect's width.
func _set_the_smoke_aspect(smoke: ColorRect) -> void:
	(smoke.material as ShaderMaterial).set_shader_parameter(&"aspect",
			smoke.size.x / maxf(1.0, smoke.size.y))


## The noise at x, scaled to about -1 to 1.
static func _wave(noise: FastNoiseLite, x: float) -> float:
	return clampf(noise.get_noise_1d(x) / NOISE_REACH, -1.0, 1.0)


## A copy of item's shader material, put on item, so this backdrop's settings are its own.
static func _own_material(item: CanvasItem) -> ShaderMaterial:
	var own: ShaderMaterial = (item.material as ShaderMaterial).duplicate() as ShaderMaterial
	item.material = own
	return own
