# Measure (#263). Prints what the brambles' motion costs a frame in level 1, with the camera on its
# widest strip of lethal spikes: the brambles still, as before they moved, and moving, twice each in
# turn, so the noise shows. Each line: the frame time and the render times, in ms. Then the strips'
# own work on one frame of the effects (all of them, on screen or not), timed alone.
# It runs with a window, since a headless run draws nothing: 1920 x 1080 with vsync off, so the frame
# time is what a frame really takes on this PC. The strips are drawn whole, out of the man's sight.
# It checks nothing: the exit code is 1 only if there are no strips to look at.
# Run from the repository root, with a window (no --headless):
# godot --path Projeto --script res://tests/measures/measure_brambles.gd
extends SceneTree

const LEVEL_PATH: String = "res://scenes/levels/lust/level1.tscn"
const WINDOW_SIZE := Vector2i(1920, 1080)
const WARMUP_FRAMES: int = 90
const MEASURED_FRAMES: int = 300
const ROUNDS: int = 2
## Frames of the effects the strips' own work is timed over.
const TIMED_STEPS: int = 200
## The camera sits this far above the strip, so the floor and the brambles fill the view.
const CAMERA_LIFT := Vector2(0.0, -40.0)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	DisplayServer.window_set_size(WINDOW_SIZE)
	var level: Node = (load(LEVEL_PATH) as PackedScene).instantiate()
	root.add_child(level)
	await process_frame
	var strips: Array[LethalSpikes] = []
	var widest: LethalSpikes = null
	for node: Node in level.find_children("*", "Area2D", true, false):
		var spikes := node as LethalSpikes
		if spikes == null:
			continue
		strips.append(spikes)
		if roundi(spikes.global_rotation_degrees) == 0 and (widest == null or spikes.width_tiles > widest.width_tiles):
			widest = spikes
		# Out of the man's sight the strips are hidden (ADR 0064): drawn whole here.
		for child: Node in spikes.get_children():
			if child is SightReveal:
				child.process_mode = Node.PROCESS_MODE_DISABLED
		spikes.modulate.a = 1.0
	if widest == null:
		push_error("measure_brambles: no floor strip in level 1")
		quit(1)
		return
	var camera := Camera2D.new()
	level.add_child(camera)
	camera.global_position = widest.global_position + CAMERA_LIFT
	camera.make_current()
	var viewport: RID = root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(viewport, true)
	await _wait(WARMUP_FRAMES)
	var window: Vector2i = DisplayServer.window_get_size()
	var brambles: int = 0
	for spikes: LethalSpikes in strips:
		brambles += spikes.get_drawn_brambles().size()
	print("Level 1, camera on the widest strip (%d tiles) at %s, window %d x %d, %d strips, %d brambles, %d frames each, vsync off"
			% [widest.width_tiles, widest.global_position, window.x, window.y, strips.size(), brambles, MEASURED_FRAMES])
	print("brambles | frame ms | render CPU ms | render GPU ms")
	for round: int in ROUNDS:
		for moving: bool in [false, true]:
			for spikes: LethalSpikes in strips:
				spikes.set_process(moving and not spikes.get_drawn_brambles().is_empty())
			await _measure("moving" if moving else "still", viewport, camera, widest)
	_time_the_strips(strips)
	quit(0)


## Steps every strip by one frame of the effects at a time, as the game does, and prints how long
## that takes on average: on screen they move and ask to be drawn again; off screen they stop early.
func _time_the_strips(strips: Array[LethalSpikes]) -> void:
	var frame: float = 1.0 / LethalSpikes.DEFAULT_MOTION.frame_rate
	for spikes: LethalSpikes in strips:
		spikes.set_process(false)
	var start: int = Time.get_ticks_usec()
	for step: int in TIMED_STEPS:
		for spikes: LethalSpikes in strips:
			if not spikes.get_drawn_brambles().is_empty():
				spikes._process(frame)
	var each: float = float(Time.get_ticks_usec() - start) / TIMED_STEPS
	print("The strips' own work: %.1f us per frame of the effects (%.0f fps), %.1f us a frame at 60 fps on average"
			% [each, LethalSpikes.DEFAULT_MOTION.frame_rate, each * LethalSpikes.DEFAULT_MOTION.frame_rate / 60.0])


func _wait(frames: int) -> void:
	for i: int in frames:
		await process_frame


func _measure(label: String, viewport: RID, camera: Camera2D, widest: LethalSpikes) -> void:
	await _wait(10)
	var cpu: float = 0.0
	var gpu: float = 0.0
	var start: int = Time.get_ticks_usec()
	for i: int in MEASURED_FRAMES:
		camera.global_position = widest.global_position + CAMERA_LIFT
		await process_frame
		cpu += RenderingServer.viewport_get_measured_render_time_cpu(viewport)
		gpu += RenderingServer.viewport_get_measured_render_time_gpu(viewport)
	var frame_ms: float = float(Time.get_ticks_usec() - start) / 1000.0 / float(MEASURED_FRAMES)
	print("%s | %.3f | %.3f | %.3f" % [label, frame_ms, cpu / MEASURED_FRAMES, gpu / MEASURED_FRAMES])
