extends Node2D
## PROTOTYPE (#257, ADR 0065): answers four questions and is then rewritten, never copied. Can a dog
## be seen in time in the dark? Do the tiles' shadows help or confuse? What does lighting cost a
## frame? Do unshaded eyes and marks show through the darkness?
## It builds the room's rock from rectangles and gives the tiles a copy of the tile set with
## occluders taken from their collision shapes. At run time it adds the darkness, the man's aura,
## the dogs' eyes and the fires, so no shared scene changes. Keys in the corner of the screen.

const TILE: int = 48
const ROOM_SIZE := Vector2i(90, 20)
## Air carved out of the solid room, in tiles.
const AIR: Array[Rect2i] = [
	Rect2i(1, 1, 20, 13), # start hall, floor on row 14
	Rect2i(21, 1, 7, 16), # the drop, floor on row 17
	Rect2i(28, 10, 61, 7), # long corridor, floor on row 17
]
## Rock put back inside the air: the low wall a dog hides behind.
const ROCK: Array[Rect2i] = [Rect2i(40, 15, 2, 2)]
const ROCK_TILE := Vector2i(0, 0)
const ROCK_COLOR := Color(0.16, 0.16, 0.17)
## How far the rock color reaches past the room, so the camera never shows the clear color.
const OUTSIDE_MARGIN: float = 4000.0
const HUD_POSITION := Vector2(16.0, 60.0)
## The light texture's radius at Texture Scale 1, in px.
const LIGHT_TEXTURE_RADIUS: float = 128.0
## Share of the light's radius where it still gives half its strength (the gradient below).
const READABLE_SHARE: float = 0.72
const FIRE_ENERGY: float = 1.3
const FIRE_RADIUS: float = 320.0
## lust_demon_stats.tres on dev, 2026-11-16: the window between seeing a dog and its bite.
const DOG_CHASE_SPEED: float = 510.0
const DOG_ATTACK_RANGE: float = 100.0
const DOG_WARNING_TIME: float = 0.1

## The settings outlive the level's restart after a death.
static var lighting_on: bool = true
static var shadows_on: bool = true
static var eyes_on: bool = true
static var ambient: float = 0.25
static var aura_radius: float = 440.0

@export var tiles: TileMapLayer
@export var player: Node2D
@export var dogs: Node2D
@export var fires: Node2D
@export var hud_label: Label
## The level's color in the dark; Ambient scales it.
@export var level_color: Color = Color(1.0, 0.68, 1.0)
@export var aura_color: Color = Color(1.0, 0.95, 0.85)
## Height of the aura above the man's feet, in px.
@export var aura_height: float = 60.0
## Where the eyes sit on a dog facing right, from its feet, in px.
@export var eye_offset: Vector2 = Vector2(80.0, -68.0)
@export var eye_color: Color = Color(1.0, 0.3, 0.15)

var _darkness: CanvasModulate
var _aura: PointLight2D
var _lights: Array[PointLight2D] = []
var _fire_lights: Array[PointLight2D] = []
var _eyes: Array[Node2D] = []
var _eye_dogs: Array[Demon] = []
var _unshaded := CanvasItemMaterial.new()
var _light_texture: GradientTexture2D
var _time: float = 0.0


func _ready() -> void:
	_unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_add_outside()
	if hud_label != null:
		hud_label.position = HUD_POSITION
	_build_tiles()
	_darkness = CanvasModulate.new()
	add_child(_darkness)
	_setup_actors.call_deferred()


func _process(delta: float) -> void:
	_time += delta
	# Two slow waves, 1.3 and 2.1 Hz, ±8 % at most: well under three strong changes a second.
	for i: int in _fire_lights.size():
		var phase: float = float(i)
		_fire_lights[i].energy = FIRE_ENERGY * (1.0 + 0.05 * sin(TAU * 1.3 * _time + phase)
				+ 0.03 * sin(TAU * 2.1 * _time + 2.0 * phase))
	for k: int in _eyes.size():
		if is_instance_valid(_eye_dogs[k]):
			_eyes[k].scale.x = _eye_dogs[k].get_facing()


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.physical_keycode:
		KEY_F1:
			shadows_on = not shadows_on
		KEY_F2:
			lighting_on = not lighting_on
		KEY_F5:
			ambient = clampf(ambient - 0.05, 0.0, 1.0)
		KEY_F6:
			ambient = clampf(ambient + 0.05, 0.0, 1.0)
		KEY_F10:
			aura_radius = maxf(aura_radius - 40.0, 40.0)
		KEY_F11:
			aura_radius += 40.0
		KEY_F12:
			eyes_on = not eyes_on
		_:
			return
	_apply()
	get_viewport().set_input_as_handled()


func set_lighting(on: bool) -> void:
	lighting_on = on
	_apply()


func set_shadows(on: bool) -> void:
	shadows_on = on
	_apply()


## For the measure: count more fires in a row above center, all on screen.
func add_fires_around(center: Vector2, count: int) -> void:
	for i: int in count:
		var spot := Node2D.new()
		spot.position = center + Vector2(-700.0 + 200.0 * float(i), -120.0)
		fires.add_child(spot)
		_make_fire(spot)
	_apply()


## Rock-colored ground behind the whole room and around it, drawn first.
func _add_outside() -> void:
	var size := Vector2(ROOM_SIZE * TILE)
	var outside := Polygon2D.new()
	outside.polygon = PackedVector2Array([Vector2(-OUTSIDE_MARGIN, -OUTSIDE_MARGIN),
			Vector2(size.x + OUTSIDE_MARGIN, -OUTSIDE_MARGIN), size + Vector2(OUTSIDE_MARGIN, OUTSIDE_MARGIN),
			Vector2(-OUTSIDE_MARGIN, size.y + OUTSIDE_MARGIN)])
	outside.color = ROCK_COLOR
	add_child(outside)


func _build_tiles() -> void:
	var tile_set: TileSet = tiles.tile_set.duplicate(true)
	tile_set.add_occlusion_layer()
	tile_set.set_occlusion_layer_light_mask(0, 1)
	var source_id: int = tile_set.get_source_id(0)
	var source := tile_set.get_source(source_id) as TileSetAtlasSource
	for i: int in source.get_tiles_count():
		var coords: Vector2i = source.get_tile_id(i)
		for j: int in source.get_alternative_tiles_count(coords):
			var data: TileData = source.get_tile_data(coords, source.get_alternative_tile_id(coords, j))
			data.modulate = ROCK_COLOR
			var shapes: int = data.get_collision_polygons_count(0)
			data.set_occluder_polygons_count(0, shapes)
			for k: int in shapes:
				var occluder := OccluderPolygon2D.new()
				occluder.polygon = data.get_collision_polygon_points(0, k)
				data.set_occluder_polygon(0, k, occluder)
	tiles.tile_set = tile_set
	for x: int in ROOM_SIZE.x:
		for y: int in ROOM_SIZE.y:
			var cell := Vector2i(x, y)
			if _is_rock(cell):
				tiles.set_cell(cell, source_id, ROCK_TILE, 0)


func _is_rock(cell: Vector2i) -> bool:
	for rect: Rect2i in ROCK:
		if rect.has_point(cell):
			return true
	for rect: Rect2i in AIR:
		if rect.has_point(cell):
			return false
	return true


func _setup_actors() -> void:
	_aura = _make_light(aura_color, 1.0, aura_radius)
	_aura.position = Vector2(0.0, -aura_height)
	player.add_child(_aura)
	for spot: Node in fires.get_children():
		_make_fire(spot as Node2D)
	for child: Node in dogs.get_children():
		var dog := child as Demon
		if dog == null:
			continue
		_eyes.append(_make_eyes(dog))
		_eye_dogs.append(dog)
		var mark := dog.get_node_or_null("Mark") as CanvasItem
		if mark != null:
			mark.material = _unshaded
			for part: Node in mark.get_children():
				if part is CanvasItem:
					(part as CanvasItem).material = _unshaded
	_apply()


func _apply() -> void:
	if _aura == null:
		return
	_darkness.visible = lighting_on
	_darkness.color = Color(level_color.r * ambient, level_color.g * ambient, level_color.b * ambient)
	for light: PointLight2D in _lights:
		light.enabled = lighting_on
		light.shadow_enabled = shadows_on
	_aura.texture_scale = aura_radius / LIGHT_TEXTURE_RADIUS
	for eyes: Node2D in _eyes:
		eyes.visible = lighting_on and eyes_on
	_update_hud()


func _update_hud() -> void:
	if hud_label == null:
		return
	var readable: float = aura_radius * READABLE_SHARE
	var window: float = maxf(readable - DOG_ATTACK_RANGE, 0.0) / DOG_CHASE_SPEED + DOG_WARNING_TIME
	hud_label.text = ("LIGHTING PROTOTYPE (#257)\n"
			+ "F1 shadows: %s    F2 lighting: %s    F12 eyes: %s\n" % [_on(shadows_on), _on(lighting_on), _on(eyes_on)]
			+ "F5/F6 darkness: %.2f    F10/F11 aura: %d px (half light at %d px)\n" % [ambient, aura_radius, readable]
			+ "Dog window at half light: %.2f s (goal 0.50 s)" % window)


func _on(value: bool) -> String:
	return "ON" if value else "off"


func _make_light(color: Color, energy: float, radius: float) -> PointLight2D:
	var light := PointLight2D.new()
	light.texture = _get_light_texture()
	light.color = color
	light.energy = energy
	light.texture_scale = radius / LIGHT_TEXTURE_RADIUS
	light.shadow_filter = Light2D.SHADOW_FILTER_PCF5
	light.shadow_filter_smooth = 1.0
	_lights.append(light)
	return light


func _get_light_texture() -> GradientTexture2D:
	if _light_texture == null:
		var gradient := Gradient.new()
		gradient.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
		gradient.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.8), Color(1, 1, 1, 0)])
		_light_texture = GradientTexture2D.new()
		_light_texture.gradient = gradient
		_light_texture.width = 256
		_light_texture.height = 256
		_light_texture.fill = GradientTexture2D.FILL_RADIAL
		_light_texture.fill_from = Vector2(0.5, 0.5)
		_light_texture.fill_to = Vector2(0.5, 0.0)
	return _light_texture


func _make_fire(spot: Node2D) -> void:
	var flame := Polygon2D.new()
	flame.polygon = PackedVector2Array([Vector2(-18, 0), Vector2(18, 0), Vector2(10, -30),
			Vector2(0, -64), Vector2(-10, -30)])
	flame.color = Color(1.0, 0.55, 0.15)
	flame.material = _unshaded
	spot.add_child(flame)
	var light := _make_light(Color(1.0, 0.62, 0.32), FIRE_ENERGY, FIRE_RADIUS)
	light.position = Vector2(0.0, -32.0)
	spot.add_child(light)
	_fire_lights.append(light)


func _make_eyes(dog: Demon) -> Node2D:
	var eyes := Node2D.new()
	for side: float in [-5.0, 5.0]:
		var eye := Polygon2D.new()
		var points := PackedVector2Array()
		for step: int in 8:
			points.append(Vector2.from_angle(TAU * float(step) / 8.0) * 3.0)
		eye.polygon = points
		eye.position = Vector2(eye_offset.x + side, eye_offset.y)
		eye.color = eye_color
		eye.material = _unshaded
		eyes.add_child(eye)
	dog.add_child(eyes)
	return eyes
