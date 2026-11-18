# Measure (#263). Prints what level 1 costs to start over, as Main does it after a death: the old
# copy goes and a new one is made and added on the same frame. Each round prints the time to
# instantiate and to add the new copy, in ms, and the length of the frames around the swap, so a
# hitch shows next to an ordinary frame. Five rounds, the first one cold.
# It runs with a window, since a headless run draws nothing: 1920 x 1080 with vsync off, so the frame
# time is what a frame really takes on this PC.
# It checks nothing.
# Run from the repository root, with a window (no --headless):
# godot --path Projeto --script res://tests/measures/measure_restart.gd
extends SceneTree

const LEVEL_PATH: String = "res://scenes/levels/lust/level1.tscn"
const WINDOW_SIZE := Vector2i(1920, 1080)
const ROUNDS: int = 5
const SETTLE_FRAMES: int = 60
## Frames timed after each swap.
const AFTER_FRAMES: int = 4


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	DisplayServer.window_set_size(WINDOW_SIZE)
	var scene: PackedScene = load(LEVEL_PATH) as PackedScene
	var level: Node = scene.instantiate()
	root.add_child(level)
	for round_index: int in ROUNDS:
		var settled: float = 0.0
		for i: int in SETTLE_FRAMES:
			var before: int = Time.get_ticks_usec()
			await process_frame
			settled = (Time.get_ticks_usec() - before) / 1000.0
		level.queue_free()
		if OS.get_cmdline_user_args().has("--split"):
			var freed_from: int = Time.get_ticks_usec()
			await process_frame
			print("  freeing the old copy: a frame of %.1f ms" % ((Time.get_ticks_usec() - freed_from)
					/ 1000.0))
		var start: int = Time.get_ticks_usec()
		level = scene.instantiate()
		var made: int = Time.get_ticks_usec()
		root.add_child(level)
		var added: int = Time.get_ticks_usec()
		var frames: PackedStringArray = []
		var last: int = added
		for i: int in AFTER_FRAMES:
			await process_frame
			var now: int = Time.get_ticks_usec()
			frames.append("%.1f" % ((now - last) / 1000.0))
			last = now
		print("round %d: instantiate %.1f ms, add %.1f ms; frames after %s ms (a settled frame %.1f ms)"
				% [round_index, (made - start) / 1000.0, (added - made) / 1000.0, ", ".join(frames),
				settled])
	quit(0)
