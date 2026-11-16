# PROTOTYPE measure (#257). Prints what lighting costs a frame in level 1, at the man's
# start, with the lighting rig of the prototype: the current look, mode A with glow and no vision,
# and A with each technique of the man's sight (SDF, polygon), sharp and with what he does not see
# blurred; and what one update of each technique costs on the CPU. Then #261's shaders, each alone
# and all together, and what feeds the glow (pixels bright enough, and how many sit in a flame).
# "-- --lighting-near-fire=0" measures it all a little before the first fire.
# It runs with a window, since a headless run draws nothing: it asks for 1920 x 1080 with vsync off,
# so the frame time is what a frame really takes on this PC; the game's settings may make the window
# full screen, and the size printed is the window's real one. Render times come from the
# rendering server's own measure (the GPU one may read 0 if the driver does not give it). It checks
# nothing: the exit code is 1 only if the level fails to load.
# Run from the repository root, with a window (no --headless):
# godot --path Projeto --script res://tests/measures/measure_lighting.gd
extends SceneTree

const LightingLevel1 := preload("res://scenes/levels/prototypes/lighting/lighting_level1.gd")
const LightingRig := preload("res://scenes/levels/prototypes/lighting/lighting_rig.gd")
const ROOM_PATH: String = "res://scenes/levels/prototypes/lighting/lighting_level1.tscn"
const UPDATE_REPEATS: int = 20
const WINDOW_SIZE := Vector2i(1920, 1080)
const WARMUP_FRAMES: int = 90
const MEASURED_FRAMES: int = 300
const SDF_SCALE_NAMES: PackedStringArray = ["100%", "50%", "25%"]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	DisplayServer.window_set_size(WINDOW_SIZE)
	var packed := load(ROOM_PATH) as PackedScene
	if packed == null:
		push_error("measure_lighting: cannot load %s" % ROOM_PATH)
		quit(1)
		return
	var room := packed.instantiate() as LightingLevel1
	root.add_child(room)
	var viewport: RID = root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(viewport, true)
	await _wait(WARMUP_FRAMES)
	var rig: LightingRig = room.get_rig()
	if rig == null or not rig.is_ready():
		push_error("measure_lighting: the lighting rig did not start")
		quit(1)
		return
	var lights: int = room.find_children("*", "PointLight2D", true, false).size()
	print("Level 1: %d point lights in the tree" % lights)
	print("Vision: %d occluder rectangles for the SDF" % rig.get_occluder_count())
	print("Rim light: %d drawings; smoke on %d dogs" % [rig.get_rim_count(), rig.get_smoking_dog_count()])
	# The rows up to the SDF scales measure as before #261: without its shaders.
	_set_shaders(false, false, false, false)
	_set_man(false, false, false, false)
	rig.set_mode(LightingRig.Mode.HYBRID)
	for vision: int in [LightingRig.VISION_SDF, LightingRig.VISION_POLYGON]:
		LightingRig.vision = vision
		rig.set_mode(LightingRig.Mode.HYBRID)
		print("Vision %s, one update on the CPU: %.2f ms (average of %d)" % [LightingRig.VISION_NAMES[vision],
				rig.measure_vision_update(UPDATE_REPEATS) / 1000.0, UPDATE_REPEATS])
	var window: Vector2i = DisplayServer.window_get_size()
	print("Level 1 at the start, window %d x %d, %d frames each, vsync off" % [window.x, window.y, MEASURED_FRAMES])
	print("set-up | frame ms | render CPU ms | render GPU ms")
	LightingRig.glow_on = false
	LightingRig.vision = LightingRig.VISION_OFF
	rig.set_mode(LightingRig.Mode.CURRENT)
	await _measure("current look (+ fire sprites)", viewport)
	LightingRig.glow_on = true
	rig.set_mode(LightingRig.Mode.HYBRID)
	await _measure("A, glow, no vision", viewport)
	LightingRig.vision = LightingRig.VISION_SDF
	rig.set_mode(LightingRig.Mode.HYBRID)
	await _measure("A, glow, vision SDF", viewport)
	LightingRig.vision = LightingRig.VISION_POLYGON
	rig.set_mode(LightingRig.Mode.HYBRID)
	await _measure("A, glow, vision polygon", viewport)
	LightingRig.unseen_blur_on = true
	LightingRig.vision = LightingRig.VISION_SDF
	rig.set_mode(LightingRig.Mode.HYBRID)
	await _measure("A, glow, vision SDF, unseen blurred", viewport)
	LightingRig.vision = LightingRig.VISION_POLYGON
	rig.set_mode(LightingRig.Mode.HYBRID)
	await _measure("A, glow, vision polygon, unseen blurred", viewport)
	LightingRig.unseen_blur_on = false
	# The rig builds the distance field at its SDF Scale; these rows try the other two.
	LightingRig.vision = LightingRig.VISION_SDF
	rig.set_mode(LightingRig.Mode.HYBRID)
	var rig_scale: Viewport.SDFScale = root.sdf_scale
	for scale: Viewport.SDFScale in [Viewport.SDF_SCALE_100_PERCENT, Viewport.SDF_SCALE_25_PERCENT]:
		root.sdf_scale = scale
		await _measure("A, glow, vision SDF, field at %s" % SDF_SCALE_NAMES[scale], viewport)
	root.sdf_scale = rig_scale
	# #261's shaders, on A with glow and no vision: none, each alone, all.
	LightingRig.vision = LightingRig.VISION_OFF
	var shader_rows: Array[Array] = [
		["A, glow, no vision, none of #261's shaders", false, false, false, false],
		["  + grade", true, false, false, false],
		["  + fires' ramp", false, true, false, false],
		["  + one air", false, false, true, false],
		["  + rim light", false, false, false, true],
		["A, glow, no vision, all of #261's shaders", true, true, true, true],
	]
	for row: Array in shader_rows:
		_set_shaders(row[1], row[2], row[3], row[4])
		rig.set_mode(LightingRig.Mode.HYBRID)
		await _measure(String(row[0]), viewport)
	# The man in the scene and the dogs' smoke, on top of the five shaders. The event effects (the
	# crucifix's light, squash, ghosts) cost nothing until their event; their row measures the ink
	# style on the idle effects.
	var man_rows: Array[Array] = [
		["  all shaders, no man's look", false, false, false, false],
		["  + man lit by the scene", true, false, false, false],
		["  + outline", false, true, false, false],
		["  + dogs' smoke", false, false, true, false],
		["  + event effects, ink style", false, false, false, true],
		["A, glow, no vision, all of #261", true, true, true, true],
	]
	for row: Array in man_rows:
		_set_man(row[1], row[2], row[3], row[4])
		rig.set_mode(LightingRig.Mode.HYBRID)
		await _measure(String(row[0]), viewport)
	await _measure_glow_sources(rig)
	quit(0)


func _set_shaders(grade: bool, fire_ramp: bool, fog: bool, rim: bool) -> void:
	LightingRig.grade_on = grade
	LightingRig.fire_ramp_on = fire_ramp
	LightingRig.fog_on = fog
	LightingRig.rim_on = rim


## The contact shadow stays off, as by default.
func _set_man(scene_light: bool, outline: bool, dog_smoke: bool, effects: bool) -> void:
	LightingRig.scene_light_on = scene_light
	LightingRig.outline_on = outline
	LightingRig.shadow_on = false
	LightingRig.dog_smoke_on = dog_smoke
	LightingRig.crucifix_fx_on = effects
	LightingRig.squash_on = effects
	LightingRig.ghosts_on = effects
	LightingRig.ink_on = effects


## What feeds the glow, a stand-in for comparing frames with glow on and off: with glow, grade and rim
## light off and the HUD hidden, the pixels whose brightest channel reaches the glow's threshold, and
## the share of them inside a flame on the screen. The glow should come from the flames, not from the
## lit rock. It counts full-size pixels, while the glow's threshold works on a half-size average of
## the frame (its first pass downsamples as it filters), so thin bright lines (text) weigh more here
## than in the glow.
func _measure_glow_sources(rig: LightingRig) -> void:
	LightingRig.glow_on = false
	_set_shaders(false, true, true, false)
	rig.set_mode(LightingRig.Mode.HYBRID)
	if rig.hud_label != null:
		rig.hud_label.visible = false
	await _wait(10)
	var image: Image = root.get_texture().get_image()
	image.convert(Image.FORMAT_RGBA8)
	var data: PackedByteArray = image.get_data()
	var width: int = image.get_width()
	var flames: Array[Rect2] = rig.get_flame_screen_rects()
	var level: int = ceili(LightingRig.GLOW_THRESHOLD * 255.0)
	var sources: int = 0
	var inside: int = 0
	for y: int in image.get_height():
		for x: int in width:
			var i: int = (y * width + x) * 4
			if maxi(data[i], maxi(data[i + 1], data[i + 2])) < level:
				continue
			sources += 1
			var pixel := Vector2(float(x) + 0.5, float(y) + 0.5)
			for flame: Rect2 in flames:
				if flame.has_point(pixel):
					inside += 1
					break
	if rig.hud_label != null:
		rig.hud_label.visible = true
	var share: float = 100.0 * float(inside) / float(sources) if sources > 0 else 0.0
	print("Glow sources, frame %d x %d: %d px at or above %.2f, %.1f %% inside the %d flames on screen %s"
			% [width, image.get_height(), sources, LightingRig.GLOW_THRESHOLD, share, flames.size(), flames])


func _wait(frames: int) -> void:
	for i: int in frames:
		await process_frame


func _measure(label: String, viewport: RID) -> void:
	await _wait(10)
	var cpu: float = 0.0
	var gpu: float = 0.0
	var start: int = Time.get_ticks_usec()
	for i: int in MEASURED_FRAMES:
		await process_frame
		cpu += RenderingServer.viewport_get_measured_render_time_cpu(viewport)
		gpu += RenderingServer.viewport_get_measured_render_time_gpu(viewport)
	var frame_ms: float = float(Time.get_ticks_usec() - start) / 1000.0 / float(MEASURED_FRAMES)
	print("%s | %.3f | %.3f | %.3f" % [label, frame_ms, cpu / MEASURED_FRAMES, gpu / MEASURED_FRAMES])
