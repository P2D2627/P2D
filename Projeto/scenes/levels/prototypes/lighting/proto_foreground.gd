extends Node2D
## PROTOTYPE (#261): rocks in front of everything, as if right before the camera, framing the screen
## from its edges. Each is a copy of one of the backdrop's rocks, hazy and out of focus (the
## backdrop's own distance haze), sized to about Height px, and sunk below the floor line its rock
## stands on, or above the ceiling it hangs from, so only an edge of it shows. It slides sideways
## past the camera faster than the level, so it reads as near: in place when the camera is on it,
## further out the further the camera is. Up and down it stays with its floor or ceiling: sliding
## that way too pushed the sunk rocks off the screen, since they always sit away from its middle.

const HAZE_SHADER: Shader = preload("res://scenes/others/shaders/distance_haze.gdshader")
## One rock in this many gets a copy, so they stay few.
const EVERY: int = 2
## Each copy's height, in px, give or take Height Spread of it.
const HEIGHT: float = 420.0
const HEIGHT_SPREAD: float = 0.25
## The share of each copy hidden below its floor line, or above its ceiling.
const SINK: float = 0.55
## Fixed, so the same rocks get the same sizes and flips on every run.
const SEED: int = 261
## How fast it slides past the camera against the level: 1 is the level's own pace.
const PARALLAX: float = 1.35
## Out of focus, in px of each rock's drawing (the shader's most is 16).
const BLUR_PX: float = 10.0
## A dim, hazy rose. The rig draws this on a canvas layer of its own, above the level, so the cave's
## darkness and the level's lights leave it as it is: in the level's own canvas, any haze turned
## near-black wherever no light reached and the rocks vanished against the dark.
const HAZE_COLOR := Color(0.22, 0.15, 0.21)
const HAZE_AMOUNT: float = 0.7
## Drawn above the level's other items, which sit at 0 and 1.
const DRAW_ORDER: int = 10

var _copies: Array[Sprite2D] = []
## Where each copy sits when the camera is on it: its rock's place in the background.
var _anchors := PackedVector2Array()


## Copies one in Every rocks of a backdrop layer, which stays as it is; call it once this node is in
## the tree. A rock whose name says Ceiling hangs from a ceiling; any other stands on a floor.
func setup(layer: Node2D) -> void:
	z_index = DRAW_ORDER
	# Moved by hand every frame, never by physics: not interpolated (project.godot interpolates).
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var haze := ShaderMaterial.new()
	haze.shader = HAZE_SHADER
	haze.set_shader_parameter("haze_color", HAZE_COLOR)
	haze.set_shader_parameter("haze_amount", HAZE_AMOUNT)
	haze.set_shader_parameter("blur_radius", BLUR_PX)
	var random := RandomNumberGenerator.new()
	random.seed = SEED
	var count: int = 0
	for child: Node in layer.get_children():
		var rock := child as Sprite2D
		if rock == null:
			continue
		count += 1
		if count % EVERY != 0:
			continue
		var rock_rect: Rect2 = rock.global_transform * rock.get_rect()
		if rock_rect.size.y <= 0.0:
			continue
		var copy := rock.duplicate(0) as Sprite2D
		copy.use_parent_material = false
		copy.material = haze
		copy.flip_h = random.randf() < 0.5
		add_child(copy)
		copy.global_transform = rock.global_transform
		var height: float = HEIGHT * random.randf_range(1.0 - HEIGHT_SPREAD, 1.0 + HEIGHT_SPREAD)
		copy.scale *= height / rock_rect.size.y
		var copy_rect: Rect2 = copy.global_transform * copy.get_rect()
		var shift: float
		if String(rock.name).contains("Ceiling"):
			shift = (rock_rect.position.y - height * SINK) - copy_rect.position.y
		else:
			shift = (rock_rect.end.y + height * SINK) - copy_rect.end.y
		copy.global_position.y += shift
		_copies.append(copy)
		_anchors.append(copy.global_position)
	print("ProtoForeground: %d of %d rocks of %s" % [_copies.size(), count, layer.name])


func _process(_delta: float) -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return
	var center: Vector2 = camera.get_screen_center_position()
	for k: int in _copies.size():
		_copies[k].global_position.x = _anchors[k].x + (_anchors[k].x - center.x) * (PARALLAX - 1.0)
