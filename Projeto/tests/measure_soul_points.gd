# Prints how long the man takes to get over a hit, with the regeneration in soul_points_stats.tres
# and with a few others to compare it with. Each one runs the real SoulPoints: a hit leaves the man
# with HIT_LEAVES SP, and the measure counts the time from the hit until the SP is no longer low and
# until it is full, and the SP regeneration gives in as many seconds as Regen Delay, from the end of
# the pause on. Max SP, Low Threshold and Regen Delay come from the file in every row. It also
# prints what the crucifix heals during the pause, from crucifix_stats.tres. It checks nothing: the
# exit code is 1 only if a regeneration never fills the man up. The README quotes the result in
# "SP", and in "Testes e medidas".
# Run from the repository root:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/measure_soul_points.gd
extends "res://tests/support/base_test.gd"

const STATS: SoulPointsStats = preload("res://player/soul_points_stats.tres")
const CRUCIFIX_STATS: CrucifixStats = preload("res://crucifix/crucifix_stats.tres")
## The SP a hit leaves the man with: below the file's Low Threshold of 25.
const HIT_LEAVES: float = 20.0
## The regenerations compared with the file's: start and top speed in SP/s, and ramp time in s. The
## last one is a single speed, with no ramp.
const OTHER_REGENERATIONS: Array[Vector3] = [
	Vector3(0.5, 2.0, 10.0),
	Vector3(0.5, 3.0, 20.0),
	Vector3(1.0, 4.0, 5.0),
	Vector3(2.0, 2.0, 0.0),
]
## Longest a regeneration may take to fill the man up before the measure gives up on it, in s.
const GIVE_UP_SECONDS: float = 600.0


func _initialize() -> void:
	# Before the first frame the root is not ready yet, and a node added to it only runs _ready()
	# when the root does.
	await process_frame
	print("Max SP %.0f, Low Threshold %.0f, Regen Delay %.1f s; the hit leaves %.0f SP."
			% [STATS.max_sp, STATS.low_threshold, STATS.regen_delay, HIT_LEAVES])
	print("The crucifix heals %.1f SP during the pause, at %.1f SP/s."
			% [CRUCIFIX_STATS.heal_per_second * STATS.regen_delay, CRUCIFIX_STATS.heal_per_second])
	var all_filled: bool = await _measure(Vector3(STATS.regen_start_per_second,
			STATS.regen_top_per_second, STATS.regen_ramp_time), "the file's")
	for regeneration: Vector3 in OTHER_REGENERATIONS:
		var filled: bool = await _measure(regeneration, "to compare")
		all_filled = all_filled and filled
	quit(0 if all_filled else 1)


## Hits a SoulPoints with the file's values and this regeneration, and prints the times and the SP
## right after the pause. False if it never fills up.
func _measure(regeneration: Vector3, which: String) -> bool:
	var stats: SoulPointsStats = STATS.duplicate()
	stats.regen_start_per_second = regeneration.x
	stats.regen_top_per_second = regeneration.y
	stats.regen_ramp_time = regeneration.z
	var soul_points: SoulPoints = SoulPoints.new()
	soul_points.stats = stats
	root.add_child(soul_points)
	await physics_frame
	soul_points.take_damage(stats.max_sp - HIT_LEAVES)
	var delay_frames: int = stats.get_regen_delay_frames()
	var give_up_frames: int = roundi(GIVE_UP_SECONDS * Engine.physics_ticks_per_second)
	var frames: int = 0
	var low_frames: int = -1
	var full_frames: int = -1
	var sp_after_the_pause: float = 0.0
	# After each frame waited, the SoulPoints has run that many frames since the hit.
	while (full_frames < 0 or frames < 2 * delay_frames) and frames < give_up_frames:
		await physics_frame
		frames += 1
		if low_frames < 0 and not soul_points.is_low():
			low_frames = frames
		if full_frames < 0 and soul_points.get_sp() >= stats.max_sp:
			full_frames = frames
		if frames == 2 * delay_frames:
			sp_after_the_pause = soul_points.get_sp() - HIT_LEAVES
	soul_points.queue_free()
	var ticks: float = Engine.physics_ticks_per_second
	print("%.1f to %.1f SP/s in %.1f s (%s): no longer low after %.2f s, full after %.2f s; %.2f SP"
			% [regeneration.x, regeneration.y, regeneration.z, which, low_frames / ticks,
			full_frames / ticks, sp_after_the_pause]
			+ " in the %.1f s after the pause" % stats.regen_delay)
	return full_frames >= 0
