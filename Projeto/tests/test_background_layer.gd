# Test of the background layers (BackgroundLayer, background/background_layer.gd) and of the level
# background template. A FIT picture covers the whole screen with the camera at each corner of its
# limits and at their centre, on the game's 16:9 screen and on a 21:9 one, the widest the game is
# made for, and grows only as much as that needs. FIT waits for a camera that arrives after the
# layer, and covers the screen again when the camera's limits grow. A REPEAT picture smaller than
# the screen grows to
# cover it, sits with its top-left corner on the layer's origin and repeats every picture size. A
# layer's ramp goes to every piece without a material of its own, also to one added later, and
# leaves alone a piece with its own material; removing the ramp takes it back. The template has the
# four layers, Far, Middle, Near and Front, back to front, the farther the slower, with Front drawn
# over the play plane.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_background_layer.gd
extends "res://tests/support/base_test.gd"

const TEMPLATE_SCENE: PackedScene = preload("res://background/level_background.tscn")
const RAMP_SHADER: Shader = preload("res://components/color_ramp.gdshader")
## Camera limits as wide and as tall as the test room's, in px.
const LIMITS: Rect2 = Rect2(0.0, -1164.0, 5824.0, 2244.0)
## The game's screen, 16:9, and the widest the game is made for, 21:9, in px.
const SCREENS: Array = [Vector2i(1920, 1080), Vector2i(2520, 1080)]
## A picture as big as the 16:9 screen, in px.
const PICTURE_SIZE: Vector2i = Vector2i(1920, 1080)
## A picture smaller than the screen, for REPEAT to grow, in px.
const SMALL_PICTURE_SIZE: Vector2i = Vector2i(1000, 600)
## The Scroll Scale of the template's Far layer.
const FAR_SCROLL: float = 0.25
## How far the limits-grow case moves the camera's right limit, in px.
const LIMITS_GROWTH: int = 3000
## Frames for the camera, and the layer after it, to take a new position or screen size.
const SETTLE_FRAMES: int = 3
## How far two scales or sizes may be apart and still count as the same: float error.
const SAME: float = 0.001
const TEMPLATE_LAYERS: PackedStringArray = ["Far", "Middle", "Near", "Front"]


func _initialize() -> void:
	# Without a window the root is 64 × 64 px. A size set before the first frame is undone when the
	# window starts, and a new size takes effect on the next frame.
	await process_frame
	var results: Array[bool] = []
	for screen: Vector2i in SCREENS:
		results.append(await _fit_covers_the_screen_everywhere(screen))
	results.append(await _fit_waits_for_a_late_camera())
	results.append(await _fit_follows_limits_that_grow())
	results.append(await _repeat_grows_to_the_screen_and_repeats())
	results.append(await _the_ramp_goes_to_the_pieces_without_a_material())
	results.append(_the_template_has_the_four_layers())
	quit(1 if results.has(false) else 0)


func _fit_covers_the_screen_everywhere(screen: Vector2i) -> bool:
	await _set_screen(screen)
	var camera: Camera2D = _make_camera()
	var layer: BackgroundLayer = _make_layer(BackgroundLayer.Cover.FIT, PICTURE_SIZE)
	await _settle()
	var picture: Sprite2D = layer.get_child(0) as Sprite2D
	var screen_rect: Rect2 = Rect2(Vector2.ZERO, Vector2(screen))
	var spots: Array[Vector2] = [LIMITS.position, Vector2(LIMITS.end.x, LIMITS.position.y),
			LIMITS.end, Vector2(LIMITS.position.x, LIMITS.end.y), LIMITS.get_center()]
	var covers_everywhere: bool = true
	for spot: Vector2 in spots:
		camera.global_position = spot
		camera.reset_physics_interpolation()
		await _settle()
		covers_everywhere = covers_everywhere and _on_screen(picture).encloses(screen_rect)
	# The picture needs the screen plus how far the layer slides: the limits less the screen, times
	# the Scroll Scale. It grows on the axis that needs most.
	var needed: Vector2 = Vector2(screen) + (LIMITS.size - Vector2(screen)) * FAR_SCROLL
	var expected: float = maxf(needed.x / PICTURE_SIZE.x, needed.y / PICTURE_SIZE.y)
	var grows_as_needed: bool = absf(picture.scale.x - expected) < SAME
	var passed: bool = covers_everywhere and grows_as_needed
	_report(passed, ("FIT on %d × %d: covers the screen at the 4 corners and the centre: %s; "
			+ "grows %.3f×, expected %.3f×") % [screen.x, screen.y, covers_everywhere,
			picture.scale.x, expected])
	camera.queue_free()
	layer.queue_free()
	await process_frame
	return passed


func _fit_waits_for_a_late_camera() -> bool:
	await _set_screen(SCREENS[0])
	var layer: BackgroundLayer = _make_layer(BackgroundLayer.Cover.FIT, PICTURE_SIZE)
	await _settle()
	var camera: Camera2D = _make_camera()
	camera.global_position = LIMITS.end
	camera.reset_physics_interpolation()
	await _settle()
	var picture: Sprite2D = layer.get_child(0) as Sprite2D
	var covers: bool = _on_screen(picture).encloses(Rect2(Vector2.ZERO, Vector2(SCREENS[0])))
	_report(covers, ("FIT with the camera arriving %d frames after the layer: covers the screen "
			+ "at the bottom-right limit: %s; grows %.3f×") % [SETTLE_FRAMES, covers,
			picture.scale.x])
	camera.queue_free()
	layer.queue_free()
	await process_frame
	return covers


func _fit_follows_limits_that_grow() -> bool:
	await _set_screen(SCREENS[0])
	var camera: Camera2D = _make_camera()
	var layer: BackgroundLayer = _make_layer(BackgroundLayer.Cover.FIT, PICTURE_SIZE)
	await _settle()
	camera.limit_right = int(LIMITS.end.x + LIMITS_GROWTH)
	camera.global_position = Vector2(camera.limit_right, LIMITS.end.y)
	camera.reset_physics_interpolation()
	await _settle()
	var picture: Sprite2D = layer.get_child(0) as Sprite2D
	var covers: bool = _on_screen(picture).encloses(Rect2(Vector2.ZERO, Vector2(SCREENS[0])))
	_report(covers, ("FIT after the right limit grows %d px: covers the screen at the new limit: "
			+ "%s; grows %.3f×") % [LIMITS_GROWTH, covers, picture.scale.x])
	camera.queue_free()
	layer.queue_free()
	await process_frame
	return covers


func _repeat_grows_to_the_screen_and_repeats() -> bool:
	var screen: Vector2 = Vector2(SCREENS[0])
	await _set_screen(SCREENS[0])
	var layer: BackgroundLayer = _make_layer(BackgroundLayer.Cover.REPEAT, SMALL_PICTURE_SIZE)
	await _settle()
	var picture: Sprite2D = layer.get_child(0) as Sprite2D
	var grown: Vector2 = Vector2(SMALL_PICTURE_SIZE) * picture.scale
	var covers: bool = grown.x >= screen.x - SAME and grown.y >= screen.y - SAME
	var at_origin: bool = not picture.centered and picture.position == Vector2.ZERO
	var repeats_every_picture: bool = layer.repeat_size.is_equal_approx(grown)
	var passed: bool = covers and at_origin and repeats_every_picture
	_report(passed, ("REPEAT: a %d × %d picture grows to %s, at least the screen: %s; top-left "
			+ "on the origin: %s; Repeat Size %s, the grown picture: %s") % [SMALL_PICTURE_SIZE.x,
			SMALL_PICTURE_SIZE.y, grown, covers, at_origin, layer.repeat_size,
			repeats_every_picture])
	layer.queue_free()
	await process_frame
	return passed


func _the_ramp_goes_to_the_pieces_without_a_material() -> bool:
	var layer: BackgroundLayer = BackgroundLayer.new()
	var ramp: GradientTexture1D = GradientTexture1D.new()
	ramp.gradient = Gradient.new()
	layer.ramp = ramp
	var plain: Sprite2D = Sprite2D.new()
	layer.add_child(plain)
	var own_material: CanvasItemMaterial = CanvasItemMaterial.new()
	var with_own: Sprite2D = Sprite2D.new()
	with_own.material = own_material
	layer.add_child(with_own)
	var group: Node2D = Node2D.new()
	var inside: Sprite2D = Sprite2D.new()
	group.add_child(inside)
	layer.add_child(group)
	root.add_child(layer)
	await process_frame
	var added: Sprite2D = Sprite2D.new()
	layer.add_child(added)

	var ramp_material: ShaderMaterial = plain.material as ShaderMaterial
	var painted: bool = ramp_material != null and ramp_material.shader == RAMP_SHADER \
			and ramp_material.get_shader_parameter(&"ramp") == ramp
	var shared: bool = painted and inside.material == ramp_material \
			and added.material == ramp_material
	var own_kept: bool = with_own.material == own_material
	layer.reverse_ramp = true
	var reverses: bool = painted and ramp_material.get_shader_parameter(&"reverse") == true
	layer.ramp = null
	var taken_back: bool = plain.material == null and inside.material == null \
			and added.material == null and with_own.material == own_material
	var passed: bool = painted and shared and own_kept and reverses and taken_back
	_report(passed, ("ramp: the pieces without a material take it: %s; inside a group and added "
			+ "later too: %s; a piece with its own material keeps it: %s; Reverse reaches the "
			+ "shader: %s; removing the ramp takes it back: %s") % [painted, shared, own_kept,
			reverses, taken_back])
	layer.queue_free()
	await process_frame
	return passed


func _the_template_has_the_four_layers() -> bool:
	var template: Node = TEMPLATE_SCENE.instantiate()
	var names: PackedStringArray = []
	var layers: Array[BackgroundLayer] = []
	for child: Node in template.get_children():
		names.append(child.name)
		if child is BackgroundLayer:
			layers.append(child as BackgroundLayer)
	var in_order: bool = names == TEMPLATE_LAYERS and layers.size() == TEMPLATE_LAYERS.size()
	var farther_slower: bool = in_order and layers[0].scroll_scale.x < layers[1].scroll_scale.x \
			and layers[1].scroll_scale.x < layers[2].scroll_scale.x \
			and layers[2].scroll_scale.x < 1.0 and layers[3].scroll_scale.x > 1.0
	var front_over_the_play_plane: bool = in_order and layers[3].z_index > 0
	var far_fits: bool = in_order and layers[0].cover == BackgroundLayer.Cover.FIT \
			and is_equal_approx(layers[0].scroll_scale.x, FAR_SCROLL)
	var passed: bool = in_order and farther_slower and front_over_the_play_plane and far_fits
	_report(passed, ("template: layers %s, all BackgroundLayer: %s; the farther the slower, "
			+ "Front above 1: %s; Front over the play plane: %s; Far FIT at %.2f: %s") % [names,
			in_order, farther_slower, front_over_the_play_plane, FAR_SCROLL, far_fits])
	template.queue_free()
	return passed


func _set_screen(screen: Vector2i) -> void:
	root.size = screen
	await process_frame


func _make_camera() -> Camera2D:
	var camera: Camera2D = Camera2D.new()
	# In the physics step, as the game's camera: with physics interpolation, Godot moves it there
	# anyway, with a warning.
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	camera.limit_left = int(LIMITS.position.x)
	camera.limit_top = int(LIMITS.position.y)
	camera.limit_right = int(LIMITS.end.x)
	camera.limit_bottom = int(LIMITS.end.y)
	root.add_child(camera)
	camera.make_current()
	return camera


## A layer at the template's Far distance, with one gray picture of the given size.
func _make_layer(cover: BackgroundLayer.Cover, picture_size: Vector2i) -> BackgroundLayer:
	var layer: BackgroundLayer = BackgroundLayer.new()
	layer.scroll_scale = Vector2(FAR_SCROLL, FAR_SCROLL)
	layer.cover = cover
	var picture: Sprite2D = Sprite2D.new()
	picture.texture = ImageTexture.create_from_image(
			Image.create_empty(picture_size.x, picture_size.y, false, Image.FORMAT_L8))
	layer.add_child(picture)
	root.add_child(layer)
	return layer


## Where a picture is on the screen, in px.
func _on_screen(picture: Sprite2D) -> Rect2:
	var xform: Transform2D = picture.get_global_transform_with_canvas()
	return Rect2(xform.origin, picture.texture.get_size() * xform.get_scale())


func _settle() -> void:
	for _frame: int in SETTLE_FRAMES:
		await physics_frame
		await process_frame


func _report(passed: bool, what: String) -> void:
	print("%s: %s" % ["PASS" if passed else "FAIL", what])
