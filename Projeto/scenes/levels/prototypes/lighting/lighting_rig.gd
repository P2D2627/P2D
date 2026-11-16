extends Node2D
## PROTOTYPE (#257): lights level 1 in two ways, to compare by eye and by cost, and is then
## rewritten, never copied. Add it as the level's last child.
## A, hybrid (chosen): the level's dark color (CanvasModulate); soft lights without shadows on the
## world's and the parallax's light masks, smaller ones on the rock's (tiles and stone rim), so rock
## faces glow; a wide, faint fill light on the man.
## B, propagation: no lights; the light spreads through the cave's tiles (light_propagation.gd) and
## one full-screen multiply (light_composite.gdshader) shows only what it reaches.
## Vision: what the man does not see is dimmed, with a soft edge (vision_mask.gdshader), in two ways
## to compare: SDF, a march from each pixel to his eyes through Godot's distance field of the rock,
## as rectangles of occluders; polygon, his field of view cast exactly to the rock's corners and
## blurred. Only the rock blocks his sight: Velvet does not. The dogs, the spikes and the fires show
## only while he sees them, by their SightReveal (#253).
## All: the level's fires on the floors past the start and in the background, with halos, sparks and
## embers (off); dust in the air that only shows where it is lit, blown by the storm's wind in gusts;
## the man's and the dogs' dust where they touch the floor or a wall (proto_contact_dust.gd); all the
## particles drawn behind the rock; glow. Keys: F1 mode (current look, A, B), F2
## glow, F3 the painted shade, F4 vision (off, SDF, polygon), F5/F6 darkness, F7 blur what he does
## not see, F9 how soft the edge of his sight is, F10/F11 the man's light.

enum Mode { CURRENT, HYBRID, PROPAGATION }

const ProtoFire := preload("res://scenes/levels/prototypes/lighting/proto_fire.gd")
const ProtoContactDust := preload("res://scenes/levels/prototypes/lighting/proto_contact_dust.gd")
const MOTE_SHADER: Shader = preload("res://scenes/levels/prototypes/lighting/proto_mote.gdshader")
const LightPropagation := preload("res://scenes/levels/prototypes/lighting/light_propagation.gd")
const COMPOSITE_SHADER: Shader = preload("res://scenes/levels/prototypes/lighting/light_composite.gdshader")
const MODE_NAMES: PackedStringArray = ["current look", "A hybrid", "B propagation"]

const MASK_WORLD: int = 1
const MASK_ROCK: int = 2
const MASK_PARALLAX: int = 4
const TILE: int = 48
## The fires: sheet, frames, each frame's brightness over the mean (measured on the GIFs), size.
const FIRE_KINDS: Array[Dictionary] = [
	{"path": "res://assets/sprites/fire/fire_upright_sheet.png", "frames": 10, "scale": 0.45,
	"curve": [0.879, 0.882, 1.086, 1.123, 1.036, 1.162, 1.144, 0.935, 0.864, 0.889]},
	{"path": "res://assets/sprites/fire/fire_low_sheet.png", "frames": 9, "scale": 0.4,
	"curve": [0.939, 0.698, 0.580, 0.783, 1.027, 1.214, 1.170, 1.325, 1.264]},
]
const FIRE_COLOR := Color(1.0, 0.36, 0.78)
const FIRE_ENERGY: float = 0.6
const FIRE_RADIUS: float = 950.0
const FIRE_LIGHT_HEIGHT: float = 50.0
const FIRE_FRAME_TIME: float = 0.13
## Where fires go: floors from Gap tiles past the man's start, one every Spacing tiles, searched
## Height tiles up and down from his floor.
const FIRST_FIRE_GAP: int = 6
const FIRE_SPACING: int = 14
const FIRE_SCAN_WIDTH: int = 110
const FIRE_SCAN_HEIGHT: int = 14
const MAX_FIRES: int = 6
const NO_FLOOR: int = -99999
## Where a recorded run puts the man, from the fire it names.
const NEAR_FIRE_OFFSET := Vector2(-300.0, -10.0)
## Fires far in the background, at the foot of the far layer's rocks within Range of the man's
## start, at least Spacing apart: big, out of focus and dimmed by distance.
## Off until they are placed by hand: placed by the rocks' feet, some sat against the ceiling and read
## as fires in the level that the man's sight does not hide.
const BACKGROUND_FIRES_ON: bool = false
const BLUR_SHADER: Shader = preload("res://scenes/levels/prototypes/lighting/background_fire_blur.gdshader")
const BACKGROUND_LAYERS: PackedStringArray = ["Backdrop/Far", "Backdrop/Mid"]
## A rock stands on the floor when its foot is this close, in px, to the play floor below it.
const STANDING_TOLERANCE: float = 250.0
## Where along the rock's width its fire sits, from its left edge.
const BACKGROUND_FIRE_SIDE: float = 0.3
const BACKGROUND_FIRE_RANGE := Vector2(4500.0, 1200.0)
const BACKGROUND_FIRE_SPACING: float = 900.0
const MAX_BACKGROUND_FIRES: int = 3
const BACKGROUND_FIRE_SCALE: float = 0.6
const BACKGROUND_FIRE_BLUR: float = 5.0
const BACKGROUND_FIRE_TINT := Color(0.85, 0.75, 0.85)
const BACKGROUND_HALO_STRENGTH: float = 0.3
const HALO_SIZE: float = 4.5
const MAN_COLOR := Color(1.0, 0.93, 0.86)
const FILL_COLOR := Color(0.85, 0.6, 0.9)
const MAN_LIGHT_HEIGHT: float = 60.0
## The man's three lights in mode A: with shadows, on the rock, and the fill; radius share, energy.
const MAN_LIGHT_SHARES: Array[float] = [1.0, 0.6, 1.7]
const MAN_LIGHT_ENERGIES: Array[float] = [0.45, 0.35, 0.12]
const LEVEL_COLOR := Color(1.0, 0.68, 1.0)
## Mode B: cell sizes of the fires' map and of the man's aura, the steps entering rock costs, the
## sweeps of the spread, the aura's strength and the time it takes to move to a new cell.
const FIRE_CELL: int = 24
const AURA_CELL: int = 48
const ROCK_COST: float = 7.0
const SPREAD_PASSES: int = 2
const AURA_ENERGY: float = 1.2
const AURA_BLEND_TIME: float = 0.15
## Vision. What he does not see is multiplied by Outside; Unseen Blur puts it out of focus (F7).
## Eye Height: his eyes above his feet when the player has no SightEyes. Softness (F9) scales the
## edge: the SDF's eye disc and the polygon's blur.
const SDF_SHADER: Shader = preload("res://scenes/levels/prototypes/lighting/vision_mask.gdshader")
const POLYGON_SHADER: Shader = preload("res://scenes/levels/prototypes/lighting/vision_polygon.gdshader")
const VISION_NAMES: PackedStringArray = ["off", "SDF", "polygon"]
const VISION_OFF: int = 0
const VISION_SDF: int = 1
const VISION_POLYGON: int = 2
const EYE_HEIGHT: float = 84.0
const VISION_OUTSIDE: float = 0.35
const UNSEEN_BLUR_PX: float = 5.0
const SOFTNESS_STEPS: Array[float] = [0.5, 1.0, 2.0]
## SDF: the eye disc's radius and how deep into rock a face still counts as seen, in world px; the
## distance field at half the screen's resolution, Godot's default: at full, building it cost 2.6 ms
## of GPU a frame on the RTX 5090 Laptop, at half 0.8 ms (measure_lighting.gd).
const SDF_EYE_RADIUS: float = 40.0
const SDF_WALL_DEPTH: float = 24.0
const SDF_SCALE: Viewport.SDFScale = Viewport.SDF_SCALE_50_PERCENT
## Polygon: a ray to each side of every rock corner on the screen, grown by Corner Margin, Corner
## Nudge radians apart, plus Base Rays evenly round, up to Reach; each hit goes Wall Depth into the
## rock, so the faces he sees count as seen. The mask is drawn at Mask Scale of the screen and read
## through a blur of Mask Blur px. Corners are kept in square chunks of Chunk Tiles.
const POLYGON_BASE_RAYS: int = 64
const POLYGON_CORNER_NUDGE: float = 0.0005
const POLYGON_CORNER_MARGIN: float = 200.0
const POLYGON_REACH: float = 2600.0
const POLYGON_WALL_DEPTH: float = 20.0
const POLYGON_MASK_SCALE: float = 0.25
const POLYGON_MASK_BLUR: float = 24.0
const CHUNK_TILES: int = 16
## Bodies one ray goes past before it counts as blocked: someone on the world's layer, as Velvet.
const MOST_LOOKED_PAST: int = 4
## The dust in the air round the man: two layers of soft motes, fine ones and a few big, faint ones,
## as if out of focus. Sizes are pixels on screen, min and max.
const DUST_EXTENTS := Vector2(1100.0, 650.0)
const DUST_LIFETIME: float = 8.0
const DUST_COLOR := Color(1.0, 0.85, 0.92)
const DUST_TEXTURE_SIZE: int = 32
const DUST_FINE_AMOUNT: int = 70
const DUST_FINE_SIZE := Vector2(2.0, 5.0)
const DUST_FINE_ALPHA: float = 0.5
const DUST_BIG_AMOUNT: int = 10
const DUST_BIG_SIZE := Vector2(10.0, 20.0)
const DUST_BIG_ALPHA: float = 0.1
## The storm's wind (prototype of the level's weather): one for the whole level, at Wind Speed px/s;
## played on 16/11, it blows to the right. Every Gust Gap seconds (min, max) a gust raises it to Gust
## Strength times as fast over Gust Rise seconds and lets it fall back over Gust Fall: it changes how
## fast the dust goes, never how bright anything is.
const WIND_DIRECTION := Vector2.RIGHT
const WIND_SPEED: float = 25.0
const GUST_STRENGTH: float = 3.0
const GUST_GAP := Vector2(5.0, 9.0)
const GUST_RISE: float = 1.5
const GUST_FALL: float = 2.5
## Each dust layer's speed in the wind: the big motes are out of focus, so nearer the camera, and
## pass faster. Wind Spread is how far, in degrees, each mote may stray from the wind's direction.
const DUST_SPEED_SHARES: Array[float] = [1.0, 1.3]
const WIND_SPREAD: float = 20.0
## How fast, in px/s², the dust rises as it drifts.
const DUST_RISE: float = 1.5
## For recorded runs: physics frames between the man's jumps, and how long each holds Jump.
const HOP_GAP: int = 60
const HOP_HOLD: int = 9

## The settings outlive the level's restart after a death.
static var mode: Mode = Mode.HYBRID
static var glow_on: bool = true
static var shade_on: bool = true
## Off by default: played, both masks drew the shadow of each rock as a wedge with straight edges,
## and the look is the lights' soft areas alone (ADR 0065).
static var vision: int = VISION_OFF
static var unseen_blur_on: bool = false
static var softness_step: int = 1
static var ambient: float = 0.3
static var man_radius: float = 900.0

var hud_label: Label

var _level: Node2D
var _tiles: TileMapLayer
var _player: Node2D
var _shade: CanvasItem
var _fires: Array[Node2D] = []
var _parallax_fires: Array[Sprite2D] = []
var _unshaded := CanvasItemMaterial.new()
var _additive := CanvasItemMaterial.new()
var _falloff: GradientTexture2D
var _halo: GradientTexture2D
var _darkness: CanvasModulate
var _man_lights: Array[PointLight2D] = []
var _environment: Environment
var _dust: Node2D
var _dust_layers: Array[CPUParticles2D] = []
var _mote: GradientTexture2D
var _wind_speed: float = WIND_SPEED
var _gust_age: float = GUST_RISE + GUST_FALL
var _until_gust: float = 0.0
var _composite_layer: CanvasLayer
var _composite: ShaderMaterial
var _grid: PackedByteArray
var _grid_rect: Rect2i
var _grid_origin: Vector2
var _aura_cell := Vector2i(NO_FLOOR, NO_FLOOR)
var _aura_texture: ImageTexture
var _aura_origin := Vector2.ZERO
var _aura_blend: float = 1.0
var _last_aura_usec: int = 0
var _time: float = 0.0
var _ready_done: bool = false
var _vision_viewport: SubViewport
var _vision_fan: VisionFan
var _vision_layer: CanvasLayer
var _vision_cover: ColorRect
var _sdf_material: ShaderMaterial
var _polygon_material: ShaderMaterial
var _vision_points := PackedVector2Array()
var _angles := PackedFloat32Array()
var _ray := PhysicsRayQueryParameters2D.new()
## The rock's corners, in the world, by chunk of Chunk Tiles.
var _corner_chunks: Dictionary[Vector2i, PackedVector2Array] = {}
var _occluder_count: int = 0
var _last_vision_usec: int = 0


func _ready() -> void:
	_setup.call_deferred()


func _process(delta: float) -> void:
	if not _ready_done:
		return
	_time += delta
	for k: int in _parallax_fires.size():
		var sprite: Sprite2D = _parallax_fires[k]
		sprite.frame = (int(_time / FIRE_FRAME_TIME) + k * 3) % sprite.hframes
	_update_wind(delta)
	if mode == Mode.PROPAGATION:
		_update_propagation(delta)
	if vision != VISION_OFF and mode != Mode.CURRENT:
		_update_vision()
	_update_hud()


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or not _ready_done:
		return
	match key.physical_keycode:
		KEY_F1:
			mode = ((int(mode) + 1) % MODE_NAMES.size()) as Mode
		KEY_F2:
			glow_on = not glow_on
		KEY_F3:
			shade_on = not shade_on
		KEY_F4:
			vision = (vision + 1) % VISION_NAMES.size()
		KEY_F5:
			ambient = clampf(ambient - 0.05, 0.0, 1.0)
		KEY_F6:
			ambient = clampf(ambient + 0.05, 0.0, 1.0)
		KEY_F7:
			unseen_blur_on = not unseen_blur_on
		KEY_F9:
			softness_step = (softness_step + 1) % SOFTNESS_STEPS.size()
		KEY_F10:
			man_radius = maxf(man_radius - 50.0, 100.0)
		KEY_F11:
			man_radius += 50.0
		_:
			return
	_apply()
	get_viewport().set_input_as_handled()


func set_mode(new_mode: Mode) -> void:
	mode = new_mode
	_apply()


func is_ready() -> bool:
	return _ready_done


## For the measure: the average cost of recomputing the man's aura, in microseconds.
func measure_aura_update(times: int) -> float:
	var start: int = Time.get_ticks_usec()
	for i: int in times:
		_aura_cell = Vector2i(NO_FLOOR, NO_FLOOR)
		_update_aura(_man_aura_cell())
	return float(Time.get_ticks_usec() - start) / float(times)


## For the measure: the rectangles of occluders the SDF is made from.
func get_occluder_count() -> int:
	return _occluder_count


## For the measure: the average cost of one update of the man's sight with the current technique,
## in microseconds.
func measure_vision_update(times: int) -> float:
	var start: int = Time.get_ticks_usec()
	for i: int in times:
		_update_vision()
	return float(Time.get_ticks_usec() - start) / float(times)


func _setup() -> void:
	_level = get_parent() as Node2D
	_tiles = _level.get_node("Tiles") as TileMapLayer
	_player = _level.get_node("Player") as Node2D
	_shade = _level.get_node_or_null("Backdrop/Shade") as CanvasItem
	_unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_additive.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_falloff = _make_radial(PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0]),
			PackedFloat32Array([1.0, 0.8, 0.45, 0.17, 0.0]))
	_halo = _make_radial(PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0]),
			PackedFloat32Array([1.0, 0.6, 0.25, 0.07, 0.0]))
	_set_light_masks()
	_hide_marks()
	_add_fires()
	if BACKGROUND_FIRES_ON:
		_add_background_fires()
	_add_hybrid()
	_add_propagation()
	_add_dust()
	_add_contact_dust()
	_add_glow()
	_add_vision()
	# For recorded runs: "-- --lighting-mode=0" (current look), 1 (A) or 2 (B); "--lighting-vision=0"
	# (off), 1 (SDF) or 2 (polygon); "--lighting-blur-unseen"; "--lighting-near-fire=N" puts the man
	# a little before fire N, to record a spot with more rock; "--lighting-fire-gap=PX" sets how far;
	# "--lighting-drop=PX" lifts him PX, to record a landing.
	var near_fire: int = -1
	var fire_offset: Vector2 = NEAR_FIRE_OFFSET
	var drop: float = 0.0
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--lighting-near-fire="):
			near_fire = argument.get_slice("=", 1).to_int()
		elif argument.begins_with("--lighting-fire-gap="):
			fire_offset.x = -argument.get_slice("=", 1).to_float()
		elif argument.begins_with("--lighting-drop="):
			drop = argument.get_slice("=", 1).to_float()
		elif argument.begins_with("--lighting-hops="):
			_hop.call_deferred(argument.get_slice("=", 1).to_int())
	if near_fire >= 0 and near_fire < _fires.size():
		_player.global_position = _fires[near_fire].global_position + fire_offset
	_player.global_position.y -= drop
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--lighting-mode="):
			mode = clampi(argument.get_slice("=", 1).to_int(), 0, MODE_NAMES.size() - 1) as Mode
		elif argument.begins_with("--lighting-vision="):
			vision = clampi(argument.get_slice("=", 1).to_int(), 0, VISION_NAMES.size() - 1)
		elif argument == "--lighting-blur-unseen":
			unseen_blur_on = true
	_ready_done = true
	_apply()


## For recorded runs ("--lighting-hops=N"): the man walks right and jumps N times, Hop Gap physics
## frames apart, holding Jump for Hop Hold frames, to record his dust.
func _hop(times: int) -> void:
	Input.action_press(&"move_right")
	for k: int in times:
		await _physics_frames(HOP_GAP)
		Input.action_press(&"jump")
		await _physics_frames(HOP_HOLD)
		Input.action_release(&"jump")
	Input.action_release(&"move_right")


func _physics_frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame


func _set_light_masks() -> void:
	_tiles.light_mask = MASK_ROCK
	var rim: Node = _level.get_node_or_null("Art/StoneRim")
	if rim != null:
		_set_mask_deep(rim, MASK_ROCK)
	var backdrop: Node = _level.get_node_or_null("Backdrop")
	if backdrop != null:
		_set_mask_deep(backdrop, MASK_PARALLAX)
	# The crucifix's light lit everything when everything sat on mask 1; with the rock and the
	# parallax moved off it, it would light only the characters and lose its shield of light.
	var crucifix_light := _player.get_node_or_null("Crucifix/Light") as PointLight2D
	if crucifix_light != null:
		crucifix_light.range_item_cull_mask = MASK_WORLD | MASK_ROCK | MASK_PARALLAX


func _set_mask_deep(node: Node, mask: int) -> void:
	if node is CanvasItem:
		(node as CanvasItem).light_mask = mask
	for child: Node in node.get_children():
		_set_mask_deep(child, mask)


func _add_fires() -> void:
	var holder := Node2D.new()
	holder.name = "ProtoFires"
	_level.add_child(holder)
	_level.move_child(holder, _player.get_index())
	# The sparks and embers go before the tiles, so the rock hides those that drift into it.
	var particles := Node2D.new()
	particles.name = "ProtoFireParticles"
	_level.add_child(particles)
	_level.move_child(particles, _tiles.get_index())
	var spots: Array[Vector2] = _find_fire_spots()
	for n: int in spots.size():
		var kind: Dictionary = FIRE_KINDS[n % FIRE_KINDS.size()]
		var sheet: Texture2D = _load_texture(String(kind["path"]))
		var fire := ProtoFire.new()
		fire.position = spots[n]
		holder.add_child(fire)
		fire.setup(sheet, int(kind["frames"]), PackedFloat32Array(kind["curve"]), float(kind["scale"]),
				FIRE_COLOR, _unshaded, _additive, _halo, particles)
		fire.add_lights(_falloff, FIRE_COLOR, FIRE_ENERGY, FIRE_RADIUS, FIRE_LIGHT_HEIGHT,
				MASK_WORLD | MASK_PARALLAX, MASK_ROCK)
		fire.hide_when_unseen()
		_fires.append(fire)


func _find_fire_spots() -> Array[Vector2]:
	var start: Vector2i = _tiles.local_to_map(_tiles.to_local(_player.global_position))
	var spots: Array[Vector2] = []
	var x: int = start.x + FIRST_FIRE_GAP
	while x < start.x + FIRE_SCAN_WIDTH and spots.size() < MAX_FIRES:
		var floor_y: int = _floor_near(x, start.y)
		if floor_y == NO_FLOOR:
			x += 1
			continue
		var top: Vector2 = _tiles.map_to_local(Vector2i(x, floor_y)) - Vector2(0.0, TILE * 0.5)
		spots.append(_tiles.to_global(top))
		x += FIRE_SPACING
	return spots


## The floor nearest to row Around in column X with three open tiles above it, or No Floor.
func _floor_near(x: int, around: int) -> int:
	for k: int in FIRE_SCAN_HEIGHT * 2:
		var y: int = around + (k + 1) / 2 * (1 if k % 2 == 1 else -1)
		if _is_solid(Vector2i(x, y)) and not _is_solid(Vector2i(x, y - 1)) \
				and not _is_solid(Vector2i(x, y - 2)) and not _is_solid(Vector2i(x, y - 3)):
			return y
	return NO_FLOOR


func _is_solid(cell: Vector2i) -> bool:
	return _tiles.get_cell_source_id(cell) != -1 and _tiles.get_cell_alternative_tile(cell) == 0


## The man and the fires keep their light, but the dogs show no "!" or "?" over their heads.
func _hide_marks() -> void:
	for mark: Node in _level.find_children("Mark", "", true, false):
		mark.set("alert_text", "")
		mark.set("search_text", "")


func _add_background_fires() -> void:
	var start: Vector2 = _player.global_position
	var start_row: int = _tiles.local_to_map(_tiles.to_local(start)).y
	var rocks: Array[Sprite2D] = []
	for layer_path: String in BACKGROUND_LAYERS:
		var layer: Node = _level.get_node_or_null(layer_path)
		if layer == null:
			continue
		for child: Node in layer.get_children():
			var rock := child as Sprite2D
			if rock != null and rock.texture != null \
					and absf(rock.global_position.x - start.x) < BACKGROUND_FIRE_RANGE.x \
					and absf(rock.global_position.y - start.y) < BACKGROUND_FIRE_RANGE.y \
					and _stands_on_floor(rock, start_row):
				rocks.append(rock)
	rocks.sort_custom(func(a: Sprite2D, b: Sprite2D) -> bool: return a.global_position.x < b.global_position.x)
	var blur := ShaderMaterial.new()
	blur.shader = BLUR_SHADER
	blur.set_shader_parameter("blur_px", BACKGROUND_FIRE_BLUR)
	var last_x: float = -INF
	for rock: Sprite2D in rocks:
		if _parallax_fires.size() >= MAX_BACKGROUND_FIRES:
			break
		if rock.global_position.x - last_x < BACKGROUND_FIRE_SPACING:
			continue
		var kind: Dictionary = FIRE_KINDS[_parallax_fires.size() % FIRE_KINDS.size()]
		_parallax_fires.append(_add_background_fire(rock, _load_texture(String(kind["path"])),
				int(kind["frames"]), blur))
		last_x = rock.global_position.x


## True when the rock's foot is near the play floor below it: a rock that stands, not one that hangs.
func _stands_on_floor(rock: Sprite2D, around_row: int) -> bool:
	var column: int = _tiles.local_to_map(_tiles.to_local(rock.global_position)).x
	var floor_row: int = _floor_near(column, around_row)
	if floor_row == NO_FLOOR:
		return false
	var floor_y: float = _tiles.to_global(_tiles.map_to_local(Vector2i(column, floor_row))).y - TILE * 0.5
	return absf(rock.to_global(_rock_foot(rock)).y - floor_y) < STANDING_TOLERANCE


## The middle of the rock's bottom edge, in its own coordinates.
func _rock_foot(rock: Sprite2D) -> Vector2:
	var size := Vector2(rock.texture.get_size())
	var top_left: Vector2 = rock.offset - (size * 0.5 if rock.centered else Vector2.ZERO)
	return top_left + Vector2(size.x * 0.5, size.y)


## A fire at the foot of a rock, as its child, so it slides with the rock.
func _add_background_fire(rock: Sprite2D, sheet: Texture2D, frames: int, blur: Material) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = sheet
	sprite.hframes = frames
	sprite.material = blur
	sprite.modulate = BACKGROUND_FIRE_TINT
	sprite.offset = Vector2(0.0, -float(sheet.get_height()) * 0.5)
	sprite.scale = Vector2.ONE * BACKGROUND_FIRE_SCALE / rock.scale
	var width: float = float(rock.texture.get_width())
	sprite.position = _rock_foot(rock) + Vector2(width * (BACKGROUND_FIRE_SIDE - 0.5), 0.0)
	var halo := Sprite2D.new()
	halo.texture = _halo
	halo.material = _additive
	halo.modulate = Color(FIRE_COLOR, BACKGROUND_HALO_STRENGTH)
	halo.scale = Vector2.ONE * (float(sheet.get_height()) * HALO_SIZE / float(_halo.get_height()))
	halo.position = Vector2(0.0, -float(sheet.get_height()) * 0.45)
	sprite.add_child(halo)
	rock.add_child(sprite)
	return sprite


func _add_hybrid() -> void:
	_darkness = CanvasModulate.new()
	add_child(_darkness)
	var colors: Array[Color] = [MAN_COLOR, MAN_COLOR, FILL_COLOR]
	var masks: Array[int] = [MASK_WORLD | MASK_PARALLAX, MASK_ROCK, MASK_WORLD | MASK_PARALLAX]
	for k: int in MAN_LIGHT_SHARES.size():
		var light := PointLight2D.new()
		light.texture = _falloff
		light.color = colors[k]
		light.energy = MAN_LIGHT_ENERGIES[k]
		light.range_item_cull_mask = masks[k]
		light.position = Vector2(0.0, -MAN_LIGHT_HEIGHT)
		_player.add_child(light)
		_man_lights.append(light)


func _add_propagation() -> void:
	var built: Dictionary = LightPropagation.build_grid(_tiles)
	_grid = built["grid"]
	_grid_rect = built["rect"]
	_grid_origin = _tiles.to_global(Vector2(_grid_rect.position * TILE))
	var factor: int = TILE / FIRE_CELL
	var cells: Vector2i = _grid_rect.size * factor
	var bytes := PackedByteArray()
	bytes.resize(cells.x * cells.y * 3)
	var radius: int = int(FIRE_RADIUS / float(FIRE_CELL))
	for fire: Node2D in _fires:
		var center: Vector2i = _world_to_cell(fire.global_position - Vector2(0.0, FIRE_LIGHT_HEIGHT), FIRE_CELL)
		var light: PackedFloat32Array = LightPropagation.spread(_grid, _grid_rect.size, factor, center, radius,
				ROCK_COST, SPREAD_PASSES)
		_add_patch(bytes, cells, center, radius, light)
	var image := Image.create_from_data(cells.x, cells.y, false, Image.FORMAT_RGB8, bytes)
	_composite = ShaderMaterial.new()
	_composite.shader = COMPOSITE_SHADER
	_composite.set_shader_parameter("fire_map", ImageTexture.create_from_image(image))
	_composite.set_shader_parameter("fire_map_cells", Vector2(cells))
	_composite.set_shader_parameter("fire_map_origin", _grid_origin)
	_composite.set_shader_parameter("fire_cell", float(FIRE_CELL))
	_composite.set_shader_parameter("aura_cell", float(AURA_CELL))
	_composite.set_shader_parameter("aura_color", Vector3(MAN_COLOR.r, MAN_COLOR.g, MAN_COLOR.b))
	_composite.set_shader_parameter("aura_energy", AURA_ENERGY)
	_composite_layer = CanvasLayer.new()
	_composite_layer.layer = 1
	var cover := ColorRect.new()
	cover.material = _composite
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	_composite_layer.add_child(cover)
	add_child(_composite_layer)


## Adds a fire's spread light, in its color, to the fires' map (three bytes a cell).
func _add_patch(bytes: PackedByteArray, cells: Vector2i, center: Vector2i, radius: int,
		light: PackedFloat32Array) -> void:
	var size: int = radius * 2 + 1
	var tint: Array[float] = [FIRE_COLOR.r * FIRE_ENERGY, FIRE_COLOR.g * FIRE_ENERGY, FIRE_COLOR.b * FIRE_ENERGY]
	for py: int in size:
		var cy: int = center.y - radius + py
		if cy < 0 or cy >= cells.y:
			continue
		for px: int in size:
			var cx: int = center.x - radius + px
			var value: float = light[py * size + px]
			if cx < 0 or cx >= cells.x or value <= 0.0:
				continue
			var at: int = (cy * cells.x + cx) * 3
			for c: int in 3:
				bytes[at + c] = mini(255, bytes[at + c] + int(value * tint[c] * 255.0))


func _update_propagation(delta: float) -> void:
	var cell: Vector2i = _man_aura_cell()
	if cell != _aura_cell:
		_update_aura(cell)
	_aura_blend = minf(_aura_blend + delta / AURA_BLEND_TIME, 1.0)
	var canvas: Transform2D = get_viewport().get_canvas_transform()
	_composite.set_shader_parameter("canvas_origin", canvas.origin)
	_composite.set_shader_parameter("canvas_scale", canvas.x.x)
	_composite.set_shader_parameter("view_size", get_viewport().get_visible_rect().size)
	_composite.set_shader_parameter("aura_blend", _aura_blend)


func _man_aura_cell() -> Vector2i:
	return _world_to_cell(_player.global_position - Vector2(0.0, MAN_LIGHT_HEIGHT), AURA_CELL)


func _update_aura(cell: Vector2i) -> void:
	var start: int = Time.get_ticks_usec()
	var radius: int = int(man_radius / float(AURA_CELL))
	var light: PackedFloat32Array = LightPropagation.spread(_grid, _grid_rect.size, TILE / AURA_CELL, cell,
			radius, ROCK_COST, SPREAD_PASSES)
	var size: int = radius * 2 + 1
	var bytes := PackedByteArray()
	bytes.resize(size * size)
	for i: int in size * size:
		bytes[i] = int(light[i] * 255.0)
	var texture := ImageTexture.create_from_image(Image.create_from_data(size, size, false, Image.FORMAT_L8, bytes))
	var origin: Vector2 = _grid_origin + Vector2(cell - Vector2i(radius, radius)) * float(AURA_CELL)
	var first: bool = _aura_texture == null
	_composite.set_shader_parameter("aura_map_old", texture if first else _aura_texture)
	_composite.set_shader_parameter("aura_origin_old", origin if first else _aura_origin)
	_composite.set_shader_parameter("aura_map", texture)
	_composite.set_shader_parameter("aura_origin", origin)
	_composite.set_shader_parameter("aura_cells", Vector2(size, size))
	_aura_texture = texture
	_aura_origin = origin
	_aura_blend = 1.0 if first else 0.0
	_aura_cell = cell
	_last_aura_usec = Time.get_ticks_usec() - start


func _world_to_cell(world: Vector2, cell_size: int) -> Vector2i:
	return Vector2i(((world - _grid_origin) / float(cell_size)).floor())


## Drawn before the tiles, so the rock hides what drifts into it, and so behind the man and the dogs;
## shaded, so it shows only where a light reaches.
func _add_dust() -> void:
	_dust = Node2D.new()
	_dust.name = "ProtoDust"
	_level.add_child(_dust)
	_level.move_child(_dust, _tiles.get_index())
	# Where the man is before the layers join: they preprocess their first Dust Lifetime seconds where
	# they stand, so the air round him is full from the first frame.
	_dust.global_position = _dust_origin()
	# Moved by hand every frame, never by physics: not interpolated (project.godot interpolates).
	_dust.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_mote = _make_radial(PackedFloat32Array([0.0, 0.35, 1.0]), PackedFloat32Array([1.0, 0.55, 0.0]),
			DUST_TEXTURE_SIZE)
	_dust_layers.append(_make_dust_layer(_mote, DUST_FINE_AMOUNT, DUST_FINE_SIZE, DUST_FINE_ALPHA,
			DUST_SPEED_SHARES[0]))
	_dust_layers.append(_make_dust_layer(_mote, DUST_BIG_AMOUNT, DUST_BIG_SIZE, DUST_BIG_ALPHA,
			DUST_SPEED_SHARES[1]))
	# Each mote sways on its own beat (proto_mote.gdshader), seeded by its random anim offset.
	var sway := ShaderMaterial.new()
	sway.shader = MOTE_SHADER
	for layer: CPUParticles2D in _dust_layers:
		layer.material = sway
		layer.anim_offset_max = 1.0
		_dust.add_child(layer)
	_until_gust = randf_range(GUST_GAP.x, GUST_GAP.y)


## The man's and the dogs' dust where they touch the floor or a wall (proto_contact_dust.gd), before
## the tiles like the air's dust.
func _add_contact_dust() -> void:
	var contact := ProtoContactDust.new()
	contact.name = "ProtoContactDust"
	_level.add_child(contact)
	_level.move_child(contact, _tiles.get_index())
	var dogs: Array[Demon] = []
	var dogs_root: Node = _level.get_node_or_null(^"Dogs")
	if dogs_root != null:
		for node: Node in dogs_root.find_children("*", "CharacterBody2D", true, false):
			if node is Demon:
				dogs.append(node as Demon)
	contact.setup(_player as Player, dogs, _mote)


## Each mote is born at the wind's speed of the moment, and the layer's gravity is how fast the wind
## changes, so every mote alive keeps the wind's speed through a gust (born at w0, it gains w - w0).
func _update_wind(delta: float) -> void:
	if delta <= 0.0:
		return
	_until_gust -= delta
	if _until_gust <= 0.0:
		_gust_age = 0.0
		_until_gust = GUST_RISE + GUST_FALL + randf_range(GUST_GAP.x, GUST_GAP.y)
	_gust_age += delta
	var gust: float = 0.0
	if _gust_age < GUST_RISE:
		gust = smoothstep(0.0, GUST_RISE, _gust_age)
	elif _gust_age < GUST_RISE + GUST_FALL:
		gust = 1.0 - smoothstep(GUST_RISE, GUST_RISE + GUST_FALL, _gust_age)
	var speed: float = WIND_SPEED * (1.0 + (GUST_STRENGTH - 1.0) * gust)
	var change: float = (speed - _wind_speed) / delta
	_wind_speed = speed
	for k: int in _dust_layers.size():
		var layer: CPUParticles2D = _dust_layers[k]
		var share: float = DUST_SPEED_SHARES[k]
		layer.gravity = WIND_DIRECTION * change * share + Vector2(0.0, -DUST_RISE)
		layer.initial_velocity_min = speed * share * 0.8
		layer.initial_velocity_max = speed * share * 1.2
	_dust.global_position = _dust_origin()


## The motes drift downwind over their life: born half that drift upwind of the man, they fill the
## screen round him.
func _dust_origin() -> Vector2:
	return _player.global_position - WIND_DIRECTION * WIND_SPEED * DUST_LIFETIME * 0.5


func _make_dust_layer(texture: Texture2D, amount: int, size_px: Vector2, alpha: float,
		speed_share: float) -> CPUParticles2D:
	var layer := CPUParticles2D.new()
	layer.texture = texture
	layer.amount = amount
	layer.lifetime = DUST_LIFETIME
	layer.preprocess = DUST_LIFETIME
	layer.lifetime_randomness = 0.4
	layer.local_coords = false
	layer.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	layer.emission_rect_extents = DUST_EXTENTS
	layer.direction = WIND_DIRECTION
	layer.spread = WIND_SPREAD
	layer.gravity = Vector2(0.0, -DUST_RISE)
	layer.initial_velocity_min = WIND_SPEED * speed_share * 0.8
	layer.initial_velocity_max = WIND_SPEED * speed_share * 1.2
	layer.scale_amount_min = size_px.x / float(texture.get_width())
	layer.scale_amount_max = size_px.y / float(texture.get_width())
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.2, 0.8, 1.0])
	ramp.colors = PackedColorArray([Color(DUST_COLOR, 0.0), Color(DUST_COLOR, alpha),
			Color(DUST_COLOR, alpha), Color(DUST_COLOR, 0.0)])
	layer.color_ramp = ramp
	return layer


## The man's sight: one full-screen pass above the level (vision_mask.gdshader), fed by the SDF of
## the rock's occluders or by the polygon drawn white on a small clear viewport that follows the
## camera.
func _add_vision() -> void:
	_ray.collision_mask = _tiles.tile_set.get_physics_layer_collision_layer(0)
	_add_occluders()
	_find_corners()
	get_viewport().sdf_scale = SDF_SCALE
	_vision_viewport = SubViewport.new()
	_vision_viewport.disable_3d = true
	_vision_viewport.transparent_bg = true
	_vision_viewport.size = Vector2i(get_viewport().get_visible_rect().size * POLYGON_MASK_SCALE)
	_vision_fan = VisionFan.new()
	_vision_viewport.add_child(_vision_fan)
	add_child(_vision_viewport)
	_sdf_material = ShaderMaterial.new()
	_sdf_material.shader = SDF_SHADER
	_sdf_material.set_shader_parameter("wall_depth", SDF_WALL_DEPTH)
	_polygon_material = ShaderMaterial.new()
	_polygon_material.shader = POLYGON_SHADER
	_polygon_material.set_shader_parameter("mask", _vision_viewport.get_texture())
	for material: ShaderMaterial in [_sdf_material, _polygon_material]:
		material.set_shader_parameter("outside", VISION_OUTSIDE)
	_vision_layer = CanvasLayer.new()
	_vision_layer.layer = 2
	_vision_cover = ColorRect.new()
	_vision_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vision_cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vision_layer.add_child(_vision_cover)
	add_child(_vision_layer)


## The rock as few occluder rectangles as it takes, made once: each run of solid tiles along a row,
## grown down while the rows below match. Godot draws the ones on the screen into its distance field
## each frame; with no light casting shadows, that is all they do.
func _add_occluders() -> void:
	var holder := Node2D.new()
	holder.name = "ProtoOccluders"
	holder.top_level = true
	add_child(holder)
	var size: Vector2i = _grid_rect.size
	var taken := PackedByteArray()
	taken.resize(size.x * size.y)
	for y: int in size.y:
		var x: int = 0
		while x < size.x:
			var at: int = y * size.x + x
			if _grid[at] == 0 or taken[at] == 1:
				x += 1
				continue
			var width: int = 1
			while x + width < size.x and _grid[at + width] == 1 and taken[at + width] == 0:
				width += 1
			var height: int = 1
			while y + height < size.y and _is_free_run(x, y + height, width, taken):
				height += 1
			for row: int in height:
				for column: int in width:
					taken[(y + row) * size.x + x + column] = 1
			var corner: Vector2 = _grid_origin + Vector2(x, y) * float(TILE)
			var end: Vector2 = corner + Vector2(width, height) * float(TILE)
			var shape := OccluderPolygon2D.new()
			shape.polygon = PackedVector2Array([corner, Vector2(end.x, corner.y), end, Vector2(corner.x, end.y)])
			var occluder := LightOccluder2D.new()
			occluder.occluder = shape
			holder.add_child(occluder)
			_occluder_count += 1
			x += width


## True when the Width tiles from (X, Y) are all solid and none is in a rectangle yet.
func _is_free_run(x: int, y: int, width: int, taken: PackedByteArray) -> bool:
	var at: int = y * _grid_rect.size.x + x
	for column: int in width:
		if _grid[at + column] == 0 or taken[at + column] == 1:
			return false
	return true


## The rock's corners: the grid points where one or three of the four tiles round them are solid, or
## two on a diagonal. Outside the grid counts as rock.
func _find_corners() -> void:
	for y: int in _grid_rect.size.y + 1:
		for x: int in _grid_rect.size.x + 1:
			var top_left: bool = _is_grid_solid(x - 1, y - 1)
			var top_right: bool = _is_grid_solid(x, y - 1)
			var bottom_left: bool = _is_grid_solid(x - 1, y)
			var bottom_right: bool = _is_grid_solid(x, y)
			var solid: int = int(top_left) + int(top_right) + int(bottom_left) + int(bottom_right)
			if solid == 1 or solid == 3 or (solid == 2 and top_left == bottom_right):
				var chunk := Vector2i(x / CHUNK_TILES, y / CHUNK_TILES)
				if not _corner_chunks.has(chunk):
					_corner_chunks[chunk] = PackedVector2Array()
				_corner_chunks[chunk].append(_grid_origin + Vector2(x, y) * float(TILE))


func _is_grid_solid(x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= _grid_rect.size.x or y >= _grid_rect.size.y:
		return true
	return _grid[y * _grid_rect.size.x + x] == 1


func _update_vision() -> void:
	var start: int = Time.get_ticks_usec()
	var eye: Vector2 = _eye()
	var viewport: Viewport = get_viewport()
	var canvas: Transform2D = viewport.get_canvas_transform()
	var view_size: Vector2 = viewport.get_visible_rect().size
	if vision == VISION_SDF:
		_sdf_material.set_shader_parameter("eye_uv", (canvas * eye) / view_size)
		_sdf_material.set_shader_parameter("uv_per_world", canvas.x.x / view_size.x)
	elif vision == VISION_POLYGON:
		_cast_polygon(eye, canvas.affine_inverse() * viewport.get_visible_rect())
		_vision_viewport.canvas_transform = Transform2D(canvas.x * POLYGON_MASK_SCALE,
				canvas.y * POLYGON_MASK_SCALE, canvas.origin * POLYGON_MASK_SCALE)
	_last_vision_usec = Time.get_ticks_usec() - start


## The player's SightEyes when he has them, so the dogs and the dimming agree; else Eye Height up.
func _eye() -> Vector2:
	var eyes: SightEyes = SightEyes.current
	if eyes != null and is_instance_valid(eyes):
		return eyes.global_position
	return _player.global_position - Vector2(0.0, EYE_HEIGHT)


## His field of view, exact: rays sorted by angle to each side of every rock corner near the screen,
## plus a few evenly round and to the screen's corners, so two neighbours that hit the same face
## draw it straight, with no streaks.
func _cast_polygon(eye: Vector2, screen: Rect2) -> void:
	var near: Rect2 = screen.grow(POLYGON_CORNER_MARGIN)
	_angles.resize(0)
	for i: int in POLYGON_BASE_RAYS:
		_angles.append(TAU * float(i) / float(POLYGON_BASE_RAYS) - PI)
	for corner: Vector2 in [near.position, Vector2(near.end.x, near.position.y), near.end,
			Vector2(near.position.x, near.end.y)]:
		_angles.append((corner - eye).angle())
	var first: Vector2i = _chunk_at(near.position)
	var last: Vector2i = _chunk_at(near.end)
	for chunk_y: int in range(first.y, last.y + 1):
		for chunk_x: int in range(first.x, last.x + 1):
			var chunk := Vector2i(chunk_x, chunk_y)
			if not _corner_chunks.has(chunk):
				continue
			for corner: Vector2 in _corner_chunks[chunk]:
				if near.has_point(corner):
					var angle: float = (corner - eye).angle()
					_angles.append(angle - POLYGON_CORNER_NUDGE)
					_angles.append(angle + POLYGON_CORNER_NUDGE)
	_angles.sort()
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	_ray.from = eye
	_vision_points.resize(_angles.size())
	for i: int in _angles.size():
		var direction := Vector2.from_angle(_angles[i])
		_ray.to = eye + direction * POLYGON_REACH
		var hit: Dictionary = _cast_past_bodies(space)
		_vision_points[i] = _ray.to if hit.is_empty() \
				else (hit["position"] as Vector2) + direction * POLYGON_WALL_DEPTH
	_vision_fan.set_fan(eye, _vision_points)


func _chunk_at(world: Vector2) -> Vector2i:
	return Vector2i(((world - _grid_origin) / float(TILE * CHUNK_TILES)).floor())


## The first thing the ray hits that is not someone's body on the world's layer, as Velvet's; a body
## once gone past stays left out of every later ray.
func _cast_past_bodies(space: PhysicsDirectSpaceState2D) -> Dictionary:
	var hit: Dictionary = {}
	for i: int in MOST_LOOKED_PAST + 1:
		hit = space.intersect_ray(_ray)
		if hit.is_empty() or not hit["collider"] is CharacterBody2D:
			return hit
		var left_out: Array[RID] = _ray.exclude
		left_out.append(hit["rid"] as RID)
		_ray.exclude = left_out
	return hit


## The field of view drawn as a fan of triangles from the eye, which needs no triangulation.
class VisionFan extends Node2D:
	var _points := PackedVector2Array()
	var _indices := PackedInt32Array()
	var _colors := PackedColorArray()

	func set_fan(eye: Vector2, rim: PackedVector2Array) -> void:
		var count: int = rim.size()
		if _indices.size() != count * 3:
			_indices.resize(count * 3)
			for i: int in count:
				_indices[i * 3] = 0
				_indices[i * 3 + 1] = i + 1
				_indices[i * 3 + 2] = (i + 1) % count + 1
			_colors.resize(count + 1)
			_colors.fill(Color.WHITE)
		_points.resize(count + 1)
		_points[0] = eye
		for i: int in count:
			_points[i + 1] = rim[i]
		queue_redraw()

	func _draw() -> void:
		if _points.size() > 2:
			RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), _indices, _points, _colors)


func _add_glow() -> void:
	_environment = Environment.new()
	_environment.background_mode = Environment.BG_CANVAS
	_environment.background_canvas_max_layer = 1
	_environment.glow_hdr_threshold = 0.9
	_environment.glow_intensity = 0.8
	var world_environment := WorldEnvironment.new()
	world_environment.environment = _environment
	add_child(world_environment)


func _apply() -> void:
	if not _ready_done:
		return
	var hybrid: bool = mode == Mode.HYBRID
	var propagation: bool = mode == Mode.PROPAGATION
	var dark := Color(LEVEL_COLOR.r * ambient, LEVEL_COLOR.g * ambient, LEVEL_COLOR.b * ambient)
	_darkness.visible = hybrid
	_darkness.color = dark
	for k: int in _man_lights.size():
		_man_lights[k].enabled = hybrid
		_man_lights[k].texture_scale = man_radius * MAN_LIGHT_SHARES[k] / (float(_falloff.width) * 0.5)
	for fire: Node2D in _fires:
		(fire as ProtoFire).set_lights_enabled(hybrid)
	_composite_layer.visible = propagation
	_composite.set_shader_parameter("ambient", Vector3(dark.r, dark.g, dark.b))
	_aura_cell = Vector2i(NO_FLOOR, NO_FLOOR)
	_dust.visible = mode != Mode.CURRENT
	_environment.glow_enabled = glow_on
	var seeing: bool = vision != VISION_OFF and mode != Mode.CURRENT
	_vision_layer.visible = seeing
	_vision_viewport.render_target_update_mode = (SubViewport.UPDATE_ALWAYS
			if seeing and vision == VISION_POLYGON else SubViewport.UPDATE_DISABLED)
	_vision_cover.material = _sdf_material if vision == VISION_SDF else _polygon_material
	var softness: float = SOFTNESS_STEPS[softness_step]
	_sdf_material.set_shader_parameter("eye_radius", SDF_EYE_RADIUS * softness)
	_polygon_material.set_shader_parameter("mask_blur_px", POLYGON_MASK_BLUR * softness)
	for material: ShaderMaterial in [_sdf_material, _polygon_material]:
		material.set_shader_parameter("unseen_blur_px", UNSEEN_BLUR_PX if unseen_blur_on else 0.0)
	if _shade != null:
		_shade.visible = shade_on


func _update_hud() -> void:
	if hud_label == null:
		return
	hud_label.text = ("LIGHTING (#257)    F1 mode: %s    F2 glow: %s    F3 painted shade: %s    F4 vision: %s\n"
			% [MODE_NAMES[mode], _on(glow_on), _on(shade_on), VISION_NAMES[vision]]
			+ "F7 blur unseen: %s    F9 soft edge: x%.1f    F5/F6 darkness: %.2f    F10/F11 man's light: %d px\n"
			% [_on(unseen_blur_on), SOFTNESS_STEPS[softness_step], ambient, man_radius]
			+ "vision CPU: %.2f ms    B aura: %.2f ms    dogs, spikes, fires: line of sight (#253)"
			% [_last_vision_usec / 1000.0, _last_aura_usec / 1000.0])


func _on(value: bool) -> String:
	return "ON" if value else "off"


func _make_radial(offsets: PackedFloat32Array, alphas: PackedFloat32Array, size: int = 256) -> GradientTexture2D:
	var gradient := Gradient.new()
	var colors := PackedColorArray()
	for alpha: float in alphas:
		colors.append(Color(1.0, 1.0, 1.0, alpha))
	gradient.offsets = offsets
	gradient.colors = colors
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = size
	texture.height = size
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	return texture


## The sheet through the import when the editor has made it, else straight from the PNG.
func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var imported := load(path) as Texture2D
		if imported != null:
			return imported
	return ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path(path)))
