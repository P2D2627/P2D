class_name SinkingDrawing
extends Node

## Sinks a character's drawing into the floor while the rest stays where it is: the body, its
## collision and what else it carries (ADR 0026). The drawing goes down by a share of Depth and
## what passes below its feet is not drawn, so it sinks into any floor, thick or thin, with no rule
## for the levels. The drawing's feet must be on its own y = 0, as with the stand-ins; the art's
## too. It gives the drawing its own material, with sink.gdshader, so each character sinks on its
## own; a shader the art needs later joins that one.

const SHADER: Shader = preload("res://components/sink.gdshader")
const DEPTH_PARAMETER: StringName = &"sink_depth"

@export var drawing: CanvasItem
## Px the drawing goes down when fully sunk: its height, so none of it shows.
@export_range(0.0, 400.0, 1.0, "suffix:px") var depth: float = 96.0

var _material: ShaderMaterial = ShaderMaterial.new()


func _ready() -> void:
	assert(drawing != null, "SinkingDrawing: assign the drawing to Drawing.")
	_material.shader = SHADER
	drawing.material = _material
	set_sink(0.0)


## Sinks the drawing, from 0 (all of it shows) to 1 (Depth down). It shows on the next frame drawn,
## with no easing, since the physics interpolation moves transforms, not this.
func set_sink(sink: float) -> void:
	_material.set_shader_parameter(DEPTH_PARAMETER, clampf(sink, 0.0, 1.0) * depth)
