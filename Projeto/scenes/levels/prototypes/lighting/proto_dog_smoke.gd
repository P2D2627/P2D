extends Node
## PROTOTYPE (#261): smoke at the edge of each dog's drawing (proto_rim.gdshader's smoke), more while
## it runs, so its movement reads in the dark without eyes or marks. It is in the drawing: the dog's
## SightReveal hides it with the dog, and it leaves no trail where a hidden dog went. It is lit as the
## dog is (the fires tint it, the cave's dark eats it). It carries information, so an option that
## reduces effects keeps it.

const ProtoContactDust := preload("res://scenes/levels/prototypes/lighting/proto_contact_dust.gd")
## How much smoke a dog standing still has, and one running at Run Speed px/s or faster; in between,
## by its speed.
const SMOKE_IDLE: float = 0.3
const SMOKE_RUN: float = 0.75
const RUN_SPEED: float = 300.0
## How fast the smoke follows the speed (1/s): a dog that stops does not stop smoking at once.
const SMOKE_SHARPNESS: float = 6.0
## How deep into the drawing the smoke reaches at full, in px of a 1920 px wide window (the rig
## passes the stretch, as for the rim).
const SMOKE_PX: float = 8.0
## A dark grey-violet, a little lighter than the cave's darkest colour, so it shows where it is lit.
const SMOKE_COLOR := Color(0.2, 0.13, 0.18)
const DRAWING_PATH := ^"Sprite"

var _dogs: Array[Demon] = []
var _materials: Array[ShaderMaterial] = []
var _amounts: Array[float] = []
var _noise: NoiseTexture2D
var _on: bool = false


## Finds every dog under Level and its drawing's own material (SinkingDrawing gives each one its own).
func setup(level: Node) -> void:
	_noise = _make_noise()
	for node: Node in level.find_children("*", "CharacterBody2D", true, false):
		var dog := node as Demon
		if dog == null:
			continue
		var drawing := dog.get_node_or_null(DRAWING_PATH) as CanvasItem
		var material: ShaderMaterial = drawing.material as ShaderMaterial if drawing != null else null
		if material == null:
			continue
		_dogs.append(dog)
		_materials.append(material)
		_amounts.append(0.0)


## The drawings must already have proto_rim.gdshader; Stretch is the window's over 1920 px.
func set_on(on: bool, stretch: float) -> void:
	_on = on
	for k: int in _materials.size():
		var material: ShaderMaterial = _materials[k]
		material.set_shader_parameter(&"smoke_noise", _noise)
		material.set_shader_parameter(&"smoke_color", SMOKE_COLOR)
		material.set_shader_parameter(&"smoke_px", SMOKE_PX * stretch)
		material.set_shader_parameter(&"smoke_fps", float(ProtoContactDust.INK_FPS))
		_amounts[k] = SMOKE_IDLE if on else 0.0
		material.set_shader_parameter(&"smoke_amount", _amounts[k])


func get_dog_count() -> int:
	return _dogs.size()


func _process(delta: float) -> void:
	if not _on:
		return
	var follow: float = 1.0 - exp(-SMOKE_SHARPNESS * delta)
	for k: int in _dogs.size():
		var dog: Demon = _dogs[k]
		if not is_instance_valid(dog):
			continue
		var running: float = clampf(absf(dog.velocity.x) / RUN_SPEED, 0.0, 1.0)
		_amounts[k] = lerpf(_amounts[k], lerpf(SMOKE_IDLE, SMOKE_RUN, running), follow)
		_materials[k].set_shader_parameter(&"smoke_amount", _amounts[k])


func _make_noise() -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.06
	noise.fractal_octaves = 3
	var texture := NoiseTexture2D.new()
	texture.width = 128
	texture.height = 128
	texture.seamless = true
	texture.noise = noise
	return texture
