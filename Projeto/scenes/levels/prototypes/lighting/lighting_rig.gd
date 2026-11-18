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
## particles drawn behind the rock; glow. A stone slab (#263) over each run of one-way tiles and each
## collapsing platform, whose own tile is then drawn clear.
## Depth (#261): a copy of the rock, nudged out of each face (proto_depth.gd), is drawn behind the
## man, the dogs, the spikes, the fires and the backdrop's near rocks, and the rock itself in front
## of them. Copies of some of the backdrop's near rocks, dark and out of focus, frame the screen from
## in front of everything (proto_foreground.gd), off by default. The background takes one colour, the darkest of the
## level's colour ramp, in place of the cave map's coloured areas.
## Shaders (#261), in modes A and B; the current look (F1) keeps none of them: glow from what is near
## full brightness in some channel (most of each flame, and today the white placeholder man); a colour
## grade of the whole frame that takes the hue of level 1's ramp and keeps each colour's brightness;
## the fires' own ramp, each at its own speed; one air for the backdrop's layers, fading into the
## background's colour; a rim of light on the characters (mode A, the only one with lights).
## Keys: F1 mode (current look, A, B), F2 glow, F3 the painted shade, F4 vision (off, SDF, polygon),
## F5/F6 darkness, F7 blur what he does not see, F9 how soft the edge of his sight is, F10/F11 the
## man's light, F12 depth; with Ctrl (Shift raises the crucifix): F1 grade, F2 the fires' ramp, F3 one
## air, F4 rim light, F12 the rocks in front.
## The man in the scene (#261, proto_man_look.gd): his body lit by the scene and not by the light he
## carries (mode A), the scenery's ink round him, a squash as he lands, a short trail of ash (or
## light) as he moves fast, and a contact shadow (off: the stone rim hides it;
## "--lighting-shadow=1"). The crucifix's light on its events (proto_crucifix_fx.gd), smoke off the
## dogs (proto_dog_smoke.gd; the trail and the smoke are proto_smoke.gd), and the effects' ink style
## (proto_puff.gdshaderinc): two flat tones, an ink line, each image held, as the man's drawing is.
## The trail is light leaving his body by default (proto_soul_light.gd, #263); ash and light stay to
## compare.
## Keys, with Ctrl: F5 scene light, F6 outline, F7 trail (off, ash, light, soul), F8 ink style, F9 the
## crucifix's light, F10 the dogs' smoke, F11 squash.

enum Mode { CURRENT, HYBRID, PROPAGATION }

const ProtoFire := preload("res://scenes/levels/prototypes/lighting/proto_fire.gd")
const ProtoContactDust := preload("res://scenes/levels/prototypes/lighting/proto_contact_dust.gd")
const ProtoDepth := preload("res://scenes/levels/prototypes/lighting/proto_depth.gd")
const ProtoForeground := preload("res://scenes/levels/prototypes/lighting/proto_foreground.gd")
const ProtoManLook := preload("res://scenes/levels/prototypes/lighting/proto_man_look.gd")
const ProtoDogSmoke := preload("res://scenes/levels/prototypes/lighting/proto_dog_smoke.gd")
const ProtoCrucifixFx := preload("res://scenes/levels/prototypes/lighting/proto_crucifix_fx.gd")
## The man's trail: off, ash, light or light leaving his body (Ctrl+F7 goes round them).
const TRAIL_OFF: int = 0
const TRAIL_ASH: int = 1
const TRAIL_LIGHT: int = 2
const TRAIL_SOUL: int = 3
const TRAIL_NAMES: Array[String] = ["off", "ash", "light", "soul"]
## The canvas layer of the rocks in front: above the level's, which is 0.
const FOREGROUND_LAYER: int = 1
## The background's one colour: the darkest of level 1's colour ramp, pink and bright red. Each level
## would set its own, from its sin's ramp.
const BACKGROUND_COLOR := Color8(30, 18, 24)
## Glow: only what reaches Threshold in its brightest channel glows, fully from Threshold + HDR
## Scale. 2D never goes past 1.0, so with Godot's default scale (2.0) the most a pixel gave was
## ~0.007 of glow (smoothstep in Godot 4.7.2's drivers/gles3/shaders/effects/glow.glsl).
const GLOW_THRESHOLD: float = 0.9
const GLOW_HDR_SCALE: float = 0.1
const GLOW_INTENSITY: float = 0.8
## The grade: a Lut Size³ table of the whole frame, applied after glow. Each colour takes Grade
## Strength of the hue of level 1's ramp at its brightness, as the tiles' ramp reads it (light on the
## left): the ramp's colour minus its own luma, added to the colour's luma, so brightness and
## contrast stay; the ramp's light end is a deep pink, darker than the colours it lands on.
const GRADE_RAMP_PATH: String = "res://assets/sprites/ramps/lust_ramp.jpg"
const LUT_SIZE: int = 32
const GRADE_STRENGTH: float = 0.3
## Luma weights (Rec. 601), as color_ramp.gdshader reads a gray.
const LUMA := Vector3(0.299, 0.587, 0.114)
## One air: the backdrop's layers, far to near, and how much of the background's colour each takes.
const FOG_LAYERS: PackedStringArray = ["Far", "Mid", "Near"]
const FOG_AMOUNTS: Array[float] = [0.85, 0.65, 0.45]
## Rim light: proto_rim.gdshader in place of each SinkingDrawing's sink.gdshader.
const RIM_SHADER: Shader = preload("res://scenes/levels/prototypes/lighting/proto_rim.gdshader")
## The rim's width in the viewport's px (1920 × 1080), scaled to the window's by the stretch.
const RIM_WIDTH_PX: float = 4.0
const RIM_STRENGTH: float = 2.0
## The man's outline, in the viewport's px like the rim, in the dark ink of the scenery's lines.
const OUTLINE_PX: float = 3.0
const OUTLINE_COLOR := Color(0.1, 0.05, 0.09)
const MOTE_SHADER: Shader = preload("res://scenes/levels/prototypes/lighting/proto_mote.gdshader")
const LightPropagation := preload("res://scenes/levels/prototypes/lighting/light_propagation.gd")
const COMPOSITE_SHADER: Shader = preload("res://scenes/levels/prototypes/lighting/light_composite.gdshader")
const MODE_NAMES: PackedStringArray = ["current look", "A hybrid", "B propagation"]

const MASK_WORLD: int = 1
const MASK_ROCK: int = 2
const MASK_PARALLAX: int = 4
## The man's drawing while the scene lights it: the fires, his fill light and the crucifix reach it,
## his main light does not.
const MASK_MAN: int = 8
const TILE: int = 48
## The fires, taken in turn along the level: sheet, frames, seconds each frame shows and each
## frame's brightness over the mean (both from the GIFs), size.
const FIRE_KINDS: Array[Dictionary] = [
	{"path": "res://assets/sprites/fire/fire_bonfire_sheet.png", "frames": 17, "frame_time": 0.11,
	"scale": 0.45, "curve": [0.985, 0.923, 1.003, 1.046, 1.060, 1.318, 1.127, 1.059, 0.922, 1.004,
	0.823, 0.777, 1.057, 1.038, 0.872, 0.993, 0.993]},
	{"path": "res://assets/sprites/fire/fire_low_sheet.png", "frames": 9, "frame_time": 0.13,
	"scale": 0.4, "curve": [0.939, 0.698, 0.580, 0.783, 1.027, 1.214, 1.170, 1.325, 1.264]},
	{"path": "res://assets/sprites/fire/fire_leaning_sheet.png", "frames": 12, "frame_time": 0.12,
	"scale": 0.5, "curve": [1.058, 1.109, 1.177, 1.384, 0.818, 0.853, 0.922, 1.008, 0.919, 1.047,
	0.830, 0.874]},
	{"path": "res://assets/sprites/fire/fire_creeping_sheet.png", "frames": 16, "frame_time": 0.09,
	"scale": 0.45, "curve": [0.595, 0.667, 0.660, 0.774, 1.090, 1.254, 1.087, 1.285, 1.172, 1.250,
	1.606, 1.295, 1.213, 0.770, 0.658, 0.624]},
]
const FIRE_COLOR := Color(1.0, 0.36, 0.78)
const FIRE_ENERGY: float = 0.6
const FIRE_RADIUS: float = 950.0
const FIRE_LIGHT_HEIGHT: float = 50.0
## Where fires go, over the whole level: in the middle of each floor at least Min Floor tiles wide,
## so on ground he walks and not on a step he jumps to, with Open Above open tiles over it inside the
## map (the rock round the cave has open air above its top row); a long floor gets one every
## Spacing tiles. Never within Spike Margin tiles of a strip of lethal spikes, at least Spacing tiles
## from each other and Start Gap tiles from the man's start. Spacing keeps the fire lights that
## reach one screen under the 15 lights a drawing takes in gl_compatibility (ADR 0065); the set-up
## print says how many reach one.
const FIRE_START_GAP: int = 6
const FIRE_SPACING: int = 20
const FIRE_MIN_FLOOR: int = 5
const OPEN_ABOVE: int = 3
const FIRE_SPIKE_MARGIN: int = 2
const MAX_FIRES: int = 200
## How far up and down from a row the rig looks for the floor a background rock stands on, in tiles.
const FIRE_SCAN_HEIGHT: int = 14
## The platforms' slab: as tall as its drawing's shape makes it up to Slab Height, so a slab
## stretches sideways at most by what a Max Tiles run asks (1.32 at 4 tiles), and wider runs take
## two slabs, mirrored. The stones' mean top, Top In Art of the drawing's height down (measured on
## 17/11: 8 px of 144), sits on the tile's top, where the man stands.
const SLAB_PATH: String = "res://assets/sprites/environment/platform_slab.png"
const SLAB_HEIGHT: float = 96.0
const SLAB_MAX_TILES: int = 4
const SLAB_TOP_IN_ART: float = 8.0 / 144.0
const NO_FLOOR: int = -99999
## Where a recorded run puts the man, from the fire it names.
const NEAR_FIRE_OFFSET := Vector2(-300.0, -10.0)
## And from the dog it names ("--lighting-near-dog=N").
const NEAR_DOG_OFFSET := Vector2(-260.0, -10.0)
## How long a recorded run holds the crucifix ("--lighting-raise=N"): past a whole use (5 s).
const RAISE_HOLD_FRAMES: int = 360
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
static var depth_on: bool = true
## Off by default: not worth it for now (16/11); the code stays, Ctrl+F12 turns them on.
static var foreground_on: bool = false
static var grade_on: bool = true
static var fire_ramp_on: bool = true
static var fog_on: bool = true
static var rim_on: bool = true
static var scene_light_on: bool = true
static var outline_on: bool = true
## Off by default: the stone rim in front of the floor hides his feet and the shadow with them
## (seen in recorded frames, 16/11); it stays for floors without a rim.
static var shadow_on: bool = false
static var trail: int = TRAIL_SOUL
static var ink_on: bool = true
static var crucifix_fx_on: bool = true
## Off by default: the ash on the dogs does not read right yet (17/11); the code stays, Ctrl+F10
## turns it on.
static var dog_smoke_on: bool = false
static var squash_on: bool = true
## The grade's table, built once: a restart after a death keeps it.
static var _grade_table: ImageTexture3D

var hud_label: Label

var _level: Node2D
var _tiles: TileMapLayer
var _player: Node2D
var _shade: CanvasItem
## The stone rim's parent, drawn in front of the man with the tiles while depth is on.
var _art: CanvasItem
var _depth: Node2D
var _foreground: Node2D
var _fires: Array[Node2D] = []
var _parallax_fires: Array[Sprite2D] = []
## Seconds each frame of each background fire shows, by its index in Parallax Fires.
var _parallax_frame_times: Array[float] = []
var _unshaded := CanvasItemMaterial.new()
var _additive := CanvasItemMaterial.new()
var _falloff: GradientTexture2D
var _halo: GradientTexture2D
var _darkness: CanvasModulate
var _man_lights: Array[PointLight2D] = []
var _environment: Environment
var _fire_ramp: ShaderMaterial
## One air: each backdrop layer's haze material, this level's own copy, with the colour and amount
## level1.tscn gave it.
var _fog_materials: Array[ShaderMaterial] = []
var _haze_colors: Array[Color] = []
var _haze_amounts: Array[float] = []
## Rim light: the characters' own materials, which SinkingDrawing made; the man's among them.
var _rim_materials: Array[ShaderMaterial] = []
var _man_material: ShaderMaterial
var _man_look: ProtoManLook
var _dog_smoke: ProtoDogSmoke
var _crucifix_fx: ProtoCrucifixFx
var _contact_dust: ProtoContactDust
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
		sprite.frame = (int(_time / _parallax_frame_times[k]) + k * 3) % sprite.hframes
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
			if key.ctrl_pressed:
				grade_on = not grade_on
			else:
				mode = ((int(mode) + 1) % MODE_NAMES.size()) as Mode
		KEY_F2:
			if key.ctrl_pressed:
				fire_ramp_on = not fire_ramp_on
			else:
				glow_on = not glow_on
		KEY_F3:
			if key.ctrl_pressed:
				fog_on = not fog_on
			else:
				shade_on = not shade_on
		KEY_F4:
			if key.ctrl_pressed:
				rim_on = not rim_on
			else:
				vision = (vision + 1) % VISION_NAMES.size()
		KEY_F5:
			if key.ctrl_pressed:
				scene_light_on = not scene_light_on
			else:
				ambient = clampf(ambient - 0.05, 0.0, 1.0)
		KEY_F6:
			if key.ctrl_pressed:
				outline_on = not outline_on
			else:
				ambient = clampf(ambient + 0.05, 0.0, 1.0)
		KEY_F7:
			if key.ctrl_pressed:
				trail = (trail + 1) % TRAIL_NAMES.size()
			else:
				unseen_blur_on = not unseen_blur_on
		KEY_F8:
			# Without Ctrl, F8 is the game's own debug key (and stops a run from the editor): left alone.
			if not key.ctrl_pressed:
				return
			ink_on = not ink_on
		KEY_F9:
			if key.ctrl_pressed:
				crucifix_fx_on = not crucifix_fx_on
			else:
				softness_step = (softness_step + 1) % SOFTNESS_STEPS.size()
		KEY_F10:
			if key.ctrl_pressed:
				dog_smoke_on = not dog_smoke_on
			else:
				man_radius = maxf(man_radius - 50.0, 100.0)
		KEY_F11:
			if key.ctrl_pressed:
				squash_on = not squash_on
			else:
				man_radius += 50.0
		KEY_F12:
			if key.ctrl_pressed:
				foreground_on = not foreground_on
			else:
				depth_on = not depth_on
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


## For the measure: how many drawings take the rim light.
func get_rim_count() -> int:
	return _rim_materials.size()


## For the measure: how many dogs carry smoke.
func get_smoking_dog_count() -> int:
	return _dog_smoke.get_dog_count()


## For the measure: the flames drawn now, on the screen, in the window's px (the stretch's final
## transform after the camera's).
func get_flame_screen_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	var viewport: Viewport = get_viewport()
	var to_screen: Transform2D = viewport.get_final_transform() * viewport.get_canvas_transform()
	var screen := Rect2(Vector2.ZERO, Vector2(viewport.get_window().size) if viewport.get_window() != null
			else viewport.get_visible_rect().size)
	for fire: Node2D in _fires:
		if not fire.is_visible_in_tree() or fire.modulate.a <= 0.0:
			continue
		var rect: Rect2 = to_screen * (fire as ProtoFire).get_flame_rect()
		if rect.intersects(screen):
			rects.append(rect)
	return rects


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
	_add_platform_slabs()
	if BACKGROUND_FIRES_ON:
		_add_background_fires()
	_add_hybrid()
	_add_propagation()
	_add_dust()
	_add_contact_dust()
	_add_depth()
	_add_foreground()
	_set_background()
	_add_glow()
	_add_fog()
	_add_rim()
	_add_man_look()
	_add_vision()
	# For recorded runs: "-- --lighting-mode=0" (current look), 1 (A) or 2 (B); "--lighting-vision=0"
	# (off), 1 (SDF) or 2 (polygon); "--lighting-blur-unseen"; "--lighting-near-fire=N" puts the man
	# a little before fire N, to record a spot with more rock; "--lighting-fire-gap=PX" sets how far;
	# "--lighting-near-dog=N" puts him a little before dog N (the camera takes ~7 s to get there);
	# "--lighting-drop=PX" lifts him PX, to record a landing; "--lighting-hops=N" and
	# "--lighting-raise=N" (frames before he raises the crucifix) move him. Each toggle has its own
	# "--lighting-<name>=0|1" (glow, grade, fire-ramp, fog, rim, scene-light, outline, shadow, ink,
	# crucifix-fx, dog-smoke, squash); "--lighting-trail=0|1|2|3" (off, ash, light, soul).
	var near_fire: int = -1
	var near_dog: int = -1
	var fire_offset: Vector2 = NEAR_FIRE_OFFSET
	var drop: float = 0.0
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--lighting-near-fire="):
			near_fire = argument.get_slice("=", 1).to_int()
		elif argument.begins_with("--lighting-near-dog="):
			near_dog = argument.get_slice("=", 1).to_int()
		elif argument.begins_with("--lighting-fire-gap="):
			fire_offset.x = -argument.get_slice("=", 1).to_float()
		elif argument.begins_with("--lighting-drop="):
			drop = argument.get_slice("=", 1).to_float()
		elif argument.begins_with("--lighting-hops="):
			_hop.call_deferred(argument.get_slice("=", 1).to_int())
		elif argument.begins_with("--lighting-raise="):
			_raise_crucifix.call_deferred(argument.get_slice("=", 1).to_int())
	if near_fire >= 0 and near_fire < _fires.size():
		_player.global_position = _fires[near_fire].global_position + fire_offset
	var dogs: Array[Demon] = _find_dogs()
	if near_dog >= 0 and near_dog < dogs.size():
		_player.global_position = dogs[near_dog].global_position + NEAR_DOG_OFFSET
	_player.global_position.y -= drop
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--lighting-mode="):
			mode = clampi(argument.get_slice("=", 1).to_int(), 0, MODE_NAMES.size() - 1) as Mode
		elif argument.begins_with("--lighting-vision="):
			vision = clampi(argument.get_slice("=", 1).to_int(), 0, VISION_NAMES.size() - 1)
		elif argument == "--lighting-blur-unseen":
			unseen_blur_on = true
		elif argument.begins_with("--lighting-depth="):
			depth_on = argument.get_slice("=", 1).to_int() != 0
		elif argument.begins_with("--lighting-foreground="):
			foreground_on = argument.get_slice("=", 1).to_int() != 0
		elif argument.begins_with("--lighting-glow="):
			glow_on = argument.get_slice("=", 1).to_int() != 0
		elif argument.begins_with("--lighting-grade="):
			grade_on = argument.get_slice("=", 1).to_int() != 0
		elif argument.begins_with("--lighting-fire-ramp="):
			fire_ramp_on = argument.get_slice("=", 1).to_int() != 0
		elif argument.begins_with("--lighting-fog="):
			fog_on = argument.get_slice("=", 1).to_int() != 0
		elif argument.begins_with("--lighting-rim="):
			rim_on = argument.get_slice("=", 1).to_int() != 0
		elif argument.begins_with("--lighting-scene-light="):
			scene_light_on = argument.get_slice("=", 1).to_int() != 0
		elif argument.begins_with("--lighting-outline="):
			outline_on = argument.get_slice("=", 1).to_int() != 0
		elif argument.begins_with("--lighting-shadow="):
			shadow_on = argument.get_slice("=", 1).to_int() != 0
		elif argument.begins_with("--lighting-trail="):
			trail = clampi(argument.get_slice("=", 1).to_int(), 0, TRAIL_NAMES.size() - 1)
		elif argument.begins_with("--lighting-ink="):
			ink_on = argument.get_slice("=", 1).to_int() != 0
		elif argument.begins_with("--lighting-crucifix-fx="):
			crucifix_fx_on = argument.get_slice("=", 1).to_int() != 0
		elif argument.begins_with("--lighting-dog-smoke="):
			dog_smoke_on = argument.get_slice("=", 1).to_int() != 0
		elif argument.begins_with("--lighting-squash="):
			squash_on = argument.get_slice("=", 1).to_int() != 0
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


## For recorded runs ("--lighting-raise=N"): after N physics frames the man raises the crucifix and
## holds it for Raise Hold Frames, past the end of a use, to record its raise, warning and end.
func _raise_crucifix(after: int) -> void:
	await _physics_frames(after)
	if not is_inside_tree():
		return
	Input.action_press(&"crucifix")
	await _physics_frames(RAISE_HOLD_FRAMES)
	Input.action_release(&"crucifix")


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
		crucifix_light.range_item_cull_mask = MASK_WORLD | MASK_ROCK | MASK_PARALLAX | MASK_MAN


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
	var started_usec: int = Time.get_ticks_usec()
	var spots: Array[Vector2] = _find_fire_spots()
	var placed_ms: float = float(Time.get_ticks_usec() - started_usec) / 1000.0
	_fire_ramp = ProtoFire.make_ramp_material()
	for n: int in spots.size():
		var kind: Dictionary = FIRE_KINDS[n % FIRE_KINDS.size()]
		var sheet: Texture2D = _load_texture(String(kind["path"]))
		var fire := ProtoFire.new()
		fire.position = spots[n]
		holder.add_child(fire)
		fire.setup(sheet, int(kind["frames"]), float(kind["frame_time"]),
				PackedFloat32Array(kind["curve"]), float(kind["scale"]), FIRE_COLOR, _unshaded,
				_additive, _halo, particles)
		fire.add_lights(_falloff, FIRE_COLOR, FIRE_ENERGY, FIRE_RADIUS, FIRE_LIGHT_HEIGHT,
				MASK_WORLD | MASK_PARALLAX | MASK_MAN, MASK_ROCK)
		fire.hide_when_unseen()
		_fires.append(fire)
	var screen: Vector2 = _screen_in_world()
	var densest: Vector2i = _densest_screen(spots, screen)
	print("ProtoFires: %d fires, placed in %.0f ms; at most %d light one %d x %d screen, from fire %d"
			% [spots.size(), placed_ms, densest.x, screen.x, screen.y, densest.y])


## The fire spots, left to right (see Fire Start Gap).
func _find_fire_spots() -> Array[Vector2]:
	var start: Vector2i = _tiles.local_to_map(_tiles.to_local(_player.global_position))
	var by_spikes: Dictionary[Vector2i, bool] = _floor_by_spikes()
	var map_top: int = _tiles.get_used_rect().position.y
	var floors: Array[Vector2i] = []
	for cell: Vector2i in _tiles.get_used_cells():
		if cell.y - OPEN_ABOVE >= map_top and _is_open_floor(cell) and not by_spikes.has(cell):
			floors.append(cell)
	var candidates: Array[Vector2i] = []
	for run: Rect2i in _runs_of(floors):
		_add_floor_spots(run.position, run.size.x, candidates)
	candidates.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x < b.x)
	var chosen: Array[Vector2i] = []
	for cell: Vector2i in candidates:
		if chosen.size() >= MAX_FIRES:
			break
		if Vector2(cell - start).length() >= FIRE_START_GAP \
				and not _has_cell_within(chosen, cell, FIRE_SPACING):
			chosen.append(cell)
	var spots: Array[Vector2] = []
	for cell: Vector2i in chosen:
		spots.append(_tiles.to_global(_tiles.map_to_local(cell) - Vector2(0.0, TILE * 0.5)))
	return spots


func _by_row_then_column(a: Vector2i, b: Vector2i) -> bool:
	return a.y < b.y or (a.y == b.y and a.x < b.x)


## Cells side by side in a row, as rects one tile tall, row by row and left to right.
func _runs_of(cells: Array[Vector2i]) -> Array[Rect2i]:
	var sorted: Array[Vector2i] = cells.duplicate()
	sorted.sort_custom(_by_row_then_column)
	var runs: Array[Rect2i] = []
	var start: int = 0
	for k: int in range(1, sorted.size() + 1):
		if k < sorted.size() and sorted[k].y == sorted[k - 1].y \
				and sorted[k].x == sorted[k - 1].x + 1:
			continue
		runs.append(Rect2i(sorted[start], Vector2i(k - start, 1)))
		start = k
	return runs


func _add_platform_slabs() -> void:
	var slab: Texture2D = _load_texture(SLAB_PATH)
	var holder := Node2D.new()
	holder.name = "ProtoSlabs"
	_level.add_child(holder)
	_level.move_child(holder, _player.get_index())
	var one_way: Array[Vector2i] = []
	for cell: Vector2i in _tiles.get_used_cells():
		if _tiles.get_cell_alternative_tile(cell) == CollapsingPlatform.ONE_WAY_ALTERNATIVE:
			one_way.append(cell)
	var runs: Array[Rect2i] = _runs_of(one_way)
	for run: Rect2i in runs:
		var corner: Vector2 = _tiles.map_to_local(run.position) - Vector2.ONE * TILE * 0.5
		_add_slabs(holder, slab, holder.to_local(_tiles.to_global(corner)), run.size.x,
				run.position.x)
	var platforms: int = 0
	for node: Node in _level.find_children("*", "Node2D", true, false):
		var platform := node as CollapsingPlatform
		if platform == null:
			continue
		# Beside its tiles, not under them: they blink, unseen now, while the slab fades out over the
		# platform's Collapse Time, gone as it goes, and shows again as it comes back.
		var layer := platform.get_node("%Tiles") as TileMapLayer
		var slabs := Node2D.new()
		slabs.position = layer.position
		platform.add_child(slabs)
		var column: int = _tiles.local_to_map(_tiles.to_local(layer.global_position)).x
		_add_slabs(slabs, slab, Vector2.ZERO, platform.width_tiles, column)
		platform.collapsing.connect(_fade_out.bind(slabs, platform.collapse_time))
		platform.came_back.connect(func() -> void: slabs.modulate.a = 1.0)
		platforms += 1
	_clear_one_way_tile()
	print("ProtoSlabs: %d runs of one-way tiles, %d collapsing platforms" % [runs.size(), platforms])


## Slabs over a platform Width Tiles wide whose top left corner is Corner, in Parent's space;
## Column, the tile column of its left end, mirrors every other slab along the level.
func _add_slabs(parent: Node2D, slab: Texture2D, corner: Vector2, width_tiles: int,
		column: int) -> void:
	var count: int = ceili(float(width_tiles) / float(SLAB_MAX_TILES))
	var width: float = width_tiles * TILE / float(count)
	var shape: float = float(slab.get_width()) / float(slab.get_height())
	var height: float = minf(SLAB_HEIGHT, width / shape)
	for k: int in count:
		var sprite := Sprite2D.new()
		sprite.texture = slab
		sprite.centered = false
		sprite.flip_h = (column + k) % 2 == 1
		sprite.scale = Vector2(width / float(slab.get_width()), height / float(slab.get_height()))
		sprite.position = corner + Vector2(k * width, -SLAB_TOP_IN_ART * height)
		sprite.light_mask = MASK_ROCK
		parent.add_child(sprite)


func _fade_out(item: CanvasItem, seconds: float) -> void:
	item.create_tween().tween_property(item, "modulate:a", 0.0, seconds)


## The one-way tile drawn clear, so only the slab shows: a change to the level's TileSet in memory,
## for this run only, which the collapsing platforms share.
func _clear_one_way_tile() -> void:
	var source := _tiles.tile_set.get_source(CollapsingPlatform.ONE_WAY_SOURCE) \
			as TileSetAtlasSource
	var data: TileData = source.get_tile_data(CollapsingPlatform.ONE_WAY_ATLAS,
			CollapsingPlatform.ONE_WAY_ALTERNATIVE)
	data.modulate = Color(data.modulate, 0.0)


## The spots on a floor of Length tiles from First: none if it is narrower than Min Floor, else one
## every Spacing tiles, spread evenly and away from its ends.
func _add_floor_spots(first: Vector2i, length: int, into: Array[Vector2i]) -> void:
	if length < FIRE_MIN_FLOOR:
		return
	var count: int = maxi(1, floori(float(length) / float(FIRE_SPACING)))
	for i: int in count:
		into.append(first + Vector2i(floori((float(i) + 0.5) * float(length) / float(count)), 0))


## The floor tiles under each strip of lethal spikes and Spike Margin tiles to each side of it: a
## fire there would hide the teeth.
func _floor_by_spikes() -> Dictionary[Vector2i, bool]:
	var cells: Dictionary[Vector2i, bool] = {}
	for node: Node in _level.find_children("*", "Area2D", true, false):
		var spikes := node as LethalSpikes
		if spikes == null:
			continue
		var base: Vector2i = _tiles.local_to_map(_tiles.to_local(
				spikes.global_position + Vector2(0.0, TILE * 0.5)))
		var reach: int = ceili(float(spikes.width_tiles) * 0.5) + FIRE_SPIKE_MARGIN
		for dx: int in range(-reach, reach + 1):
			cells[base + Vector2i(dx, 0)] = true
	return cells


func _has_cell_within(cells: Array[Vector2i], cell: Vector2i, distance: int) -> bool:
	for other: Vector2i in cells:
		if Vector2(cell - other).length() < float(distance):
			return true
	return false


## The size of one screen in the world: the visible rect over the camera's zoom.
func _screen_in_world() -> Vector2:
	var camera: Camera2D = _level.get_viewport().get_camera_2d()
	var zoom: Vector2 = camera.zoom if camera != null else Vector2.ONE
	return _level.get_viewport().get_visible_rect().size / zoom


## The screen whose light comes from the most fires, wherever it is: x is how many fires light it
## and y the index of the fire on its left edge. A fire lights a screen when its spot falls in the
## screen grown by the light's radius on each side; the fullest such box has a fire on its left edge
## and one on its top edge, so those are the boxes it tries. Spots come left to right.
func _densest_screen(spots: Array[Vector2], screen: Vector2) -> Vector2i:
	var box: Vector2 = screen + Vector2.ONE * FIRE_RADIUS * 2.0
	var densest := Vector2i.ZERO
	for left: int in spots.size():
		var last: int = left
		while last + 1 < spots.size() and spots[last + 1].x <= spots[left].x + box.x:
			last += 1
		for top: int in range(left, last + 1):
			var count: int = 0
			for k: int in range(left, last + 1):
				if spots[k].y >= spots[top].y and spots[k].y <= spots[top].y + box.y:
					count += 1
			if count > densest.x:
				densest = Vector2i(count, left)
	return densest


## The floor nearest to row Around in column X with Open Above open tiles over it, or No Floor.
func _floor_near(x: int, around: int) -> int:
	for k: int in FIRE_SCAN_HEIGHT * 2:
		var y: int = around + (k + 1) / 2 * (1 if k % 2 == 1 else -1)
		if _is_open_floor(Vector2i(x, y)):
			return y
	return NO_FLOOR


## A solid tile with Open Above open tiles over it.
func _is_open_floor(cell: Vector2i) -> bool:
	if not _is_solid(cell):
		return false
	for k: int in range(1, OPEN_ABOVE + 1):
		if _is_solid(cell + Vector2i.UP * k):
			return false
	return true


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
		_parallax_frame_times.append(float(kind["frame_time"]))
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
	# His main light leaves his own drawing out while the scene lights it (MASK_MAN); the fill reaches it.
	var masks: Array[int] = [MASK_WORLD | MASK_PARALLAX, MASK_ROCK, MASK_WORLD | MASK_PARALLAX | MASK_MAN]
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
	_contact_dust = ProtoContactDust.new()
	_contact_dust.name = "ProtoContactDust"
	_level.add_child(_contact_dust)
	_level.move_child(_contact_dust, _tiles.get_index())
	_contact_dust.setup(_player as Player, _find_dogs(), _mote)


## Every dog in the level, not only those under Dogs: the crucifix tutorial's dog is under Tutorial.
func _find_dogs() -> Array[Demon]:
	var dogs: Array[Demon] = []
	for node: Node in _level.find_children("*", "CharacterBody2D", true, false):
		if node is Demon:
			dogs.append(node as Demon)
	return dogs


## The rock's far copy goes just before the gates, so they and everything after them stand in front
## of it; the air's dust goes before it, and the backdrop's near rocks right after it, between the
## two copies like the man. The rock and its rim come to the front in _apply.
func _add_depth() -> void:
	var depth := ProtoDepth.new()
	depth.name = "ProtoDepth"
	_level.add_child(depth)
	var gates: Node = _level.get_node_or_null(^"Gates")
	_level.move_child(depth, gates.get_index() if gates != null else _tiles.get_index())
	_level.move_child(_dust, depth.get_index())
	var near: Node = _level.get_node_or_null(^"Backdrop/Near")
	if near != null:
		near.reparent(_level)
		_level.move_child(near, depth.get_index() + 1)
	_art = _level.get_node_or_null(^"Art") as CanvasItem
	depth.setup(_tiles, _level.get_node_or_null(^"Art/StoneRim") as Node2D, MASK_ROCK)
	_depth = depth


## Copies of some of the backdrop's near rocks in front of everything, framing the screen
## (proto_foreground.gd). The near ones stand on the floors and hang from the ceilings the man
## sees; the far ones stand far below them, behind the rock. Run after _add_depth, which moves them.
func _add_foreground() -> void:
	# A canvas of its own, which follows the camera like the level: the cave's darkness
	# (CanvasModulate) and the level's lights stay in the level's canvas.
	var layer := CanvasLayer.new()
	layer.name = "ProtoForegroundLayer"
	layer.layer = FOREGROUND_LAYER
	layer.follow_viewport_enabled = true
	_level.add_child(layer)
	var foreground := ProtoForeground.new()
	foreground.name = "ProtoForeground"
	layer.add_child(foreground)
	var near := _level.get_node_or_null(^"Near") as Node2D
	if near == null:
		near = _level.get_node_or_null(^"Backdrop/Near") as Node2D
	if near != null:
		foreground.setup(near)
	_foreground = foreground


## The background in one colour: the cave map's coloured areas are hidden and the plain backing under
## them takes Background Color. The painted shade by the rock stays.
func _set_background() -> void:
	var cave_map := _level.get_node_or_null(^"Backdrop/CaveMap") as CanvasItem
	if cave_map != null:
		cave_map.visible = false
	var backing := _level.get_node_or_null(^"Background") as Polygon2D
	if backing != null:
		backing.color = BACKGROUND_COLOR


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


## Glow and the grade, in the environment's one pass over the frame. Canvas layers up to the first
## one at or above Background Canvas Max Layer take them; the HUD, on layer 10, does not.
func _add_glow() -> void:
	_environment = Environment.new()
	_environment.background_mode = Environment.BG_CANVAS
	_environment.background_canvas_max_layer = 1
	_environment.glow_hdr_threshold = GLOW_THRESHOLD
	_environment.glow_hdr_scale = GLOW_HDR_SCALE
	_environment.glow_intensity = GLOW_INTENSITY
	if _grade_table == null:
		_grade_table = _make_grade()
	_environment.adjustment_color_correction = _grade_table
	var world_environment := WorldEnvironment.new()
	world_environment.environment = _environment
	add_child(world_environment)


## The grade's table: the environment reads it at the frame's sRGB colour, so each cell holds what
## the colour at its centre becomes (the outermost half cells read the edge cell). Null if the table
## cannot be made; the grade then does nothing.
func _make_grade() -> ImageTexture3D:
	var ramp: Image = _load_texture(GRADE_RAMP_PATH).get_image()
	if ramp.is_compressed():
		ramp.decompress()
	var last: int = ramp.get_width() - 1
	var row: int = ramp.get_height() >> 1
	var slices: Array[Image] = []
	for b: int in LUT_SIZE:
		var slice := Image.create_empty(LUT_SIZE, LUT_SIZE, false, Image.FORMAT_RGB8)
		for g: int in LUT_SIZE:
			for r: int in LUT_SIZE:
				var color := Color((r + 0.5) / LUT_SIZE, (g + 0.5) / LUT_SIZE, (b + 0.5) / LUT_SIZE)
				var luma: float = LUMA.dot(Vector3(color.r, color.g, color.b))
				var ramp_color: Color = ramp.get_pixel(roundi((1.0 - luma) * last), row)
				var hue_shift: float = luma - LUMA.dot(Vector3(ramp_color.r, ramp_color.g, ramp_color.b))
				var target := Color(clampf(ramp_color.r + hue_shift, 0.0, 1.0),
						clampf(ramp_color.g + hue_shift, 0.0, 1.0), clampf(ramp_color.b + hue_shift, 0.0, 1.0))
				slice.set_pixel(r, g, color.lerp(target, GRADE_STRENGTH))
		slices.append(slice)
	var table := ImageTexture3D.new()
	if table.create(Image.FORMAT_RGB8, LUT_SIZE, LUT_SIZE, LUT_SIZE, false, slices) != OK:
		push_error("lighting_rig: the grade's table could not be made")
		return null
	return table


## One air: the backdrop layers' haze materials (Near sits in the level once depth has moved it).
## Each layer gets its own copy: the scene's materials are shared by every instance of the level,
## so writing to them would leave the next level, after a death, with this one's fog as "original".
func _add_fog() -> void:
	for layer_name: String in FOG_LAYERS:
		var layer := _level.get_node_or_null(NodePath("Backdrop/" + layer_name)) as CanvasItem
		if layer == null:
			layer = _level.get_node_or_null(NodePath(layer_name)) as CanvasItem
		if layer == null or not layer.material is ShaderMaterial:
			continue
		var haze := layer.material.duplicate() as ShaderMaterial
		layer.material = haze
		_fog_materials.append(haze)
		_haze_colors.append(haze.get_shader_parameter(&"haze_color") as Color)
		_haze_amounts.append(float(haze.get_shader_parameter(&"haze_amount")))


## The man in the scene (his light, outline, shadow, squash and trail), the crucifix's light on its
## events and the dogs' smoke.
func _add_man_look() -> void:
	var drawing := _player.get_node_or_null(^"Sprite") as CanvasItem
	if drawing != null:
		_man_material = drawing.material as ShaderMaterial
	_man_look = ProtoManLook.new()
	_man_look.name = "ProtoManLook"
	add_child(_man_look)
	_man_look.setup(_player as CharacterBody2D, drawing if drawing != null else _player as CanvasItem)
	_dog_smoke = ProtoDogSmoke.new()
	_dog_smoke.name = "ProtoDogSmoke"
	add_child(_dog_smoke)
	_dog_smoke.setup(_find_dogs(), _player)
	var crucifix := _player.get_node_or_null(^"Crucifix") as Crucifix
	if crucifix != null:
		# In the level, so its camera draws it; last and on the rock's z, so the light is in front of
		# the man, the dogs and the rock.
		_crucifix_fx = ProtoCrucifixFx.new()
		_crucifix_fx.name = "ProtoCrucifixFx"
		_crucifix_fx.z_index = 1
		_level.add_child(_crucifix_fx)
		_crucifix_fx.setup(crucifix, _find_dogs())


## Rim light: every drawing in the level that SinkingDrawing gave its own sink.gdshader material.
func _add_rim() -> void:
	for node: Node in _level.find_children("*", "CanvasItem", true, false):
		var drawing_material := (node as CanvasItem).material as ShaderMaterial
		if drawing_material != null and drawing_material.shader == SinkingDrawing.SHADER:
			_rim_materials.append(drawing_material)


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
	# The current look keeps none of #261's shaders, for the A/B; the rim needs mode A's lights.
	var styled: bool = mode != Mode.CURRENT
	_environment.glow_enabled = glow_on and styled
	_environment.adjustment_enabled = grade_on and styled and _grade_table != null
	for fire: Node2D in _fires:
		(fire as ProtoFire).set_look(_fire_ramp, fire_ramp_on and styled)
	var fog: bool = fog_on and styled
	for k: int in _fog_materials.size():
		_fog_materials[k].set_shader_parameter(&"haze_color", BACKGROUND_COLOR if fog else _haze_colors[k])
		_fog_materials[k].set_shader_parameter(&"haze_amount", FOG_AMOUNTS[k] if fog else _haze_amounts[k])
	# proto_rim.gdshader draws the rim (mode A) and the man's outline; without either, sink.gdshader.
	var rim: bool = rim_on and hybrid
	var outline: bool = outline_on and styled
	var stretch: float = get_viewport().get_final_transform().get_scale().x
	for drawing_material: ShaderMaterial in _rim_materials:
		var outlined: bool = outline and drawing_material == _man_material
		var wanted: Shader = RIM_SHADER if rim or outlined else SinkingDrawing.SHADER
		if drawing_material.shader != wanted:
			drawing_material.shader = wanted
		if wanted == RIM_SHADER:
			drawing_material.set_shader_parameter(&"rim_width_px", RIM_WIDTH_PX * stretch)
			drawing_material.set_shader_parameter(&"rim_strength", RIM_STRENGTH if rim else 0.0)
			drawing_material.set_shader_parameter(&"outline_px", OUTLINE_PX * stretch if outlined else 0.0)
			drawing_material.set_shader_parameter(&"outline_color", OUTLINE_COLOR)
	_man_look.set_scene_light(scene_light_on and hybrid, MASK_MAN, MASK_WORLD)
	_man_look.set_shadow(shadow_on and styled)
	_man_look.set_squash(squash_on and styled)
	_man_look.set_trail((trail == TRAIL_ASH or trail == TRAIL_LIGHT) and styled, trail == TRAIL_LIGHT)
	_man_look.set_soul_trail(trail == TRAIL_SOUL and styled)
	_dog_smoke.set_on(dog_smoke_on and styled)
	var ink: bool = ink_on and styled
	_man_look.set_ink(ink)
	_contact_dust.set_ink(ink)
	if _crucifix_fx != null:
		_crucifix_fx.set_on(crucifix_fx_on and styled)
		_crucifix_fx.set_ink(ink)
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
	_depth.visible = depth_on
	var front: int = 1 if depth_on else 0
	_tiles.z_index = front
	if _art != null:
		_art.z_index = front
	_foreground.visible = foreground_on
	_foreground.set_process(foreground_on)


func _update_hud() -> void:
	if hud_label == null:
		return
	hud_label.text = ("LIGHTING (#257)    F1 mode: %s    F2 glow: %s    F3 painted shade: %s    F4 vision: %s\n"
			% [MODE_NAMES[mode], _on(glow_on), _on(shade_on), VISION_NAMES[vision]]
			+ "F7 blur unseen: %s    F9 soft edge: x%.1f    F5/F6 darkness: %.2f    F10/F11 man's light: %d px"
			% [_on(unseen_blur_on), SOFTNESS_STEPS[softness_step], ambient, man_radius]
			+ "    F12 depth: %s    Ctrl+F12 rocks in front: %s\n" % [_on(depth_on), _on(foreground_on)]
			+ "Ctrl+F1 grade: %s    Ctrl+F2 fires' ramp: %s    Ctrl+F3 one air: %s    Ctrl+F4 rim light: %s%s\n"
			% [_on(grade_on), _on(fire_ramp_on), _on(fog_on), _on(rim_on),
			"    (current look: none of these)" if mode == Mode.CURRENT else ""]
			+ "Ctrl+F5 man lit by the scene: %s    Ctrl+F6 outline: %s    Ctrl+F7 trail: %s    Ctrl+F8 ink style: %s\n"
			% [_on(scene_light_on), _on(outline_on), TRAIL_NAMES[trail], _on(ink_on)]
			+ "Ctrl+F9 crucifix's light: %s    Ctrl+F10 dogs' ash: %s    Ctrl+F11 squash: %s\n"
			% [_on(crucifix_fx_on), _on(dog_smoke_on), _on(squash_on)]
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
