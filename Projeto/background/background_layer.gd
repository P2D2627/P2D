class_name BackgroundLayer
extends Parallax2D

## One layer of a level's background, at one distance from the camera. The farther the layer, the
## smaller its Scroll Scale and the slower it slides across the screen: about 0.25 far away, 0.5 in
## the middle, 0.75 near, and above 1 in front of the play plane. The art comes painted in grays,
## and the layer's Ramp gives it the level's colors, darker and less saturated the farther away.
##
## A level's background starts from res://background/level_background.tscn, which already has the
## four layers, Far, Middle, Near and Front, back to front: new art goes, as a Sprite2D, into the
## layer of its distance. The README, under "Fundo em camadas", says how, and where a piece must go
## to show up at a given point of the level. tests/test_background_layer.gd checks this script and
## the template.
##
## FIT follows the camera: it covers the screen again when the window, the Scroll Scale, the camera
## or the camera's limits change, and while there is no camera yet it waits for one. Assumes a
## camera without zoom, as the game's.

## How the layer fills the screen.
enum Cover {
	## Loose pieces placed by hand, such as rocks or towers; the layer leaves them where they are.
	NONE,
	## One picture that does not repeat. It grows just enough to cover the screen wherever the
	## camera goes inside its limits.
	FIT,
	## One picture painted to repeat without a seam, across and down. It repeats over the whole
	## level, and grows first if it is smaller than the screen.
	REPEAT,
}

## What a Camera2D limit holds when nobody set it: a camera without limits has no edge to fit to.
const NO_LIMIT: int = 10000000
const RAMP_SHADER: Shader = preload("res://components/color_ramp.gdshader")

## How the layer fills the screen. FIT and REPEAT work on one picture.
@export var cover: Cover = Cover.NONE:
	set(value):
		cover = value
		_cover_pending = true
## The picture FIT and REPEAT work on. Without one, the layer's first Sprite2D. FIT and REPEAT take
## over its Centered, Position and Scale, and this layer's Repeat Size; FIT also takes over the
## layer's Scroll Offset. Changes made to those in the editor are undone when the game runs.
@export var picture: Sprite2D:
	set(value):
		picture = value
		_cover_pending = true
## The camera whose limits a FIT picture covers. Without one, the camera the viewport is using.
@export var camera: Camera2D

@export_group("Color")
## The layer's colors, dark to light from left to right, which replace the grays of every piece in
## the layer that has no material of its own (components/color_ramp.gdshader): a 256 × 1 PNG or a
## GradientTexture1D. Without a ramp, the pieces keep the colors they were painted in.
@export var ramp: Texture2D:
	set(value):
		ramp = value
		if is_node_ready():
			_paint_pieces()
## On for a ramp painted the other way, light on the left and dark on the right.
@export var reverse_ramp: bool = false:
	set(value):
		reverse_ramp = value
		_ramp_material.set_shader_parameter(&"reverse", value)

## One material for all the pieces of the layer, so that a new ramp changes them all at once.
var _ramp_material: ShaderMaterial = ShaderMaterial.new()
## The pieces given the layer's material, to take it back if the ramp is removed.
var _painted: Array[CanvasItem] = []
## Whether the screen still has to be covered: after a change, and while a FIT layer has no camera.
var _cover_pending: bool = true
## The Scroll Scale, the camera and the camera's limits the screen was last covered for.
var _covered_scale: Vector2 = Vector2.ZERO
var _covered_camera: Camera2D = null
var _covered_limits: Rect2 = Rect2()
## Whether this layer already warned about a setting it cannot work with, so that it warns once.
var _warned: bool = false


func _ready() -> void:
	_ramp_material.shader = RAMP_SHADER
	_paint_pieces()
	child_entered_tree.connect(_on_child_entered_tree)
	get_viewport().size_changed.connect(_cover_screen)


func _process(_delta: float) -> void:
	# A change while the game runs, including one made in the Remote tab, covers the screen again.
	if _cover_pending or scroll_scale != _covered_scale or _camera_changed():
		_cover_screen()


## Gives the layer's ramp to every piece without a material of its own, or takes it back from them
## all when the layer has no ramp. Runs when the layer starts and whenever Ramp changes.
func _paint_pieces() -> void:
	_ramp_material.set_shader_parameter(&"ramp", ramp)
	_ramp_material.set_shader_parameter(&"reverse", reverse_ramp)
	for piece: CanvasItem in _painted:
		if is_instance_valid(piece) and piece.material == _ramp_material:
			piece.material = null
	_painted.clear()
	if ramp != null:
		for child: Node in get_children():
			_paint(child)


## Gives the layer's material to a piece without a material of its own, and to the pieces inside it.
func _paint(node: Node) -> void:
	var piece: CanvasItem = node as CanvasItem
	if piece != null and piece.material == null:
		piece.material = _ramp_material
		_painted.append(piece)
	for child: Node in node.get_children():
		_paint(child)


## A piece added while the game runs takes the ramp too.
func _on_child_entered_tree(node: Node) -> void:
	if ramp != null:
		_paint(node)


## Whether a FIT layer's camera, or that camera's limits, changed since the screen was covered.
func _camera_changed() -> bool:
	if cover != Cover.FIT:
		return false
	var watched: Camera2D = _watched_camera()
	return watched != _covered_camera \
			or (watched != null and _limits_of(watched) != _covered_limits)


## Scales and places the picture so that it covers the screen as Cover asks. Runs on the first
## frame, when the window changes size, since a wider screen shows more, and after any change to
## Cover, Picture, Scroll Scale, the camera or its limits.
func _cover_screen() -> void:
	_cover_pending = false
	_covered_scale = scroll_scale
	if cover == Cover.NONE:
		return
	var shown: Sprite2D = picture if picture != null else _first_sprite()
	if shown == null or shown.texture == null:
		_warn_once("FIT and REPEAT need a picture, a Sprite2D with a texture")
		return
	var screen: Vector2 = get_viewport_rect().size
	if cover == Cover.FIT:
		# Without a camera there is nothing to fit to yet: the next frames try again.
		_cover_pending = not _fit(shown, screen)
	else:
		_repeat(shown, screen)


## FIT: the screen's top-left corner travels the camera's limits less the screen, and the layer
## slides that far times Scroll Scale, so the picture needs the screen plus that slide. Returns
## false if there is no camera yet.
func _fit(shown: Sprite2D, screen: Vector2) -> bool:
	var watched: Camera2D = _watched_camera()
	_covered_camera = watched
	if watched == null:
		return false
	var limits: Rect2 = _limits_of(watched)
	_covered_limits = limits
	if watched.limit_right >= NO_LIMIT or watched.limit_bottom >= NO_LIMIT:
		_warn_once("the camera has no limits, so FIT has no edge to cover up to")
		return true
	var slide: Vector2 = (limits.size - screen).max(Vector2.ZERO) * scroll_scale.abs()
	var needed: Vector2 = screen + slide
	var grow: float = _place(shown, needed)
	repeat_size = Vector2.ZERO
	# With the camera at its top-left limit, what is left over is split evenly between both sides.
	var spare: Vector2 = shown.texture.get_size() * grow - needed
	scroll_offset = limits.position * scroll_scale - spare / 2.0
	return true


## REPEAT: the picture, at least as big as the screen, repeats every picture size. Repeat Size
## ignores the picture's scale, so it takes the size the picture grew to.
func _repeat(shown: Sprite2D, screen: Vector2) -> void:
	var grow: float = _place(shown, screen)
	repeat_size = shown.texture.get_size() * grow


## Puts the picture's top-left corner on the layer's origin and grows it, keeping its proportions,
## until it is at least at_least big; it never shrinks it. Returns how much it grew.
func _place(shown: Sprite2D, at_least: Vector2) -> float:
	var texture_size: Vector2 = shown.texture.get_size()
	var grow: float = maxf(1.0, maxf(at_least.x / texture_size.x, at_least.y / texture_size.y))
	shown.centered = false
	shown.position = Vector2.ZERO
	shown.scale = Vector2(grow, grow)
	return grow


func _watched_camera() -> Camera2D:
	return camera if camera != null else get_viewport().get_camera_2d()


func _limits_of(watched: Camera2D) -> Rect2:
	return Rect2(Vector2(watched.limit_left, watched.limit_top),
			Vector2(watched.limit_right - watched.limit_left,
			watched.limit_bottom - watched.limit_top))


func _first_sprite() -> Sprite2D:
	for child: Node in get_children():
		if child is Sprite2D:
			return child as Sprite2D
	return null


func _warn_once(problem: String) -> void:
	if _warned:
		return
	_warned = true
	push_warning("BackgroundLayer %s: %s." % [name, problem])
