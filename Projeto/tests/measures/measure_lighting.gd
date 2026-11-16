# PROTOTYPE measure (#257). Prints what lighting costs a frame in level 1, at the man's
# start, with the lighting rig of the prototype: the current look, mode A with glow and no vision,
# and A with each technique of the man's sight (SDF, polygon), sharp and with what he does not see
# blurred; and what one update of each technique costs on the CPU.
# It runs with a window, since a headless run draws nothing: the window is 1920 x 1080 and vsync is
# off, so the frame time is what a frame really takes on this PC. Render times come from the
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
	rig.set_mode(LightingRig.Mode.HYBRID)
	for vision: int in [LightingRig.VISION_SDF, LightingRig.VISION_POLYGON]:
		LightingRig.vision = vision
		rig.set_mode(LightingRig.Mode.HYBRID)
		print("Vision %s, one update on the CPU: %.2f ms (average of %d)" % [LightingRig.VISION_NAMES[vision],
				rig.measure_vision_update(UPDATE_REPEATS) / 1000.0, UPDATE_REPEATS])
	print("Level 1 at the start, %d x %d, %d frames each, vsync off" % [WINDOW_SIZE.x, WINDOW_SIZE.y, MEASURED_FRAMES])
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
	quit(0)


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
