# Checks what PlayerMovementStats works out on its own, without a player or a scene.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_player_movement_stats.gd
extends SceneTree

## Min Jump Height as a multiple of Jump Height for the too-high case; anything above 1 is too high.
const TOO_HIGH_MIN_JUMP_RATIO: float = 1.25


func _initialize() -> void:
	var passed: bool = _cut_gravity_never_drops_below_rise_gravity()
	quit(0 if passed else 1)


## A cut gravity weaker than the rise gravity would make letting go of Jump jump higher than
## holding it, so it must not drop below the rise gravity, even with Min Jump Height set too high.
func _cut_gravity_never_drops_below_rise_gravity() -> bool:
	var stats: PlayerMovementStats = PlayerMovementStats.new()
	stats.min_jump_height = stats.jump_height * TOO_HIGH_MIN_JUMP_RATIO
	var cut: float = stats.get_jump_cut_gravity()
	var rise: float = stats.get_rise_gravity()
	var passed: bool = cut > rise or is_equal_approx(cut, rise)
	var verdict: String = "PASS" if passed else "FAIL"
	print("%s: Min Jump Height %.1f px over Jump Height %.1f px, cut %.1f px/s², rise %.1f px/s²"
			% [verdict, stats.min_jump_height, stats.jump_height, cut, rise])
	return passed
