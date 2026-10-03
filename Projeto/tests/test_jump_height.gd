# Checks that a full jump peaks at the Jump Height set in the player's Stats.
# Run from the repository root; the exit code is 0 on pass and 1 on fail:
# godot --headless --fixed-fps 60 --path Projeto --script res://tests/test_jump_height.gd
extends SceneTree

const PLAYER_SCENE: PackedScene = preload("res://scenes/actors/player.tscn")
## How far the measured peak may be from Jump Height, in px.
const TOLERANCE: float = 1.0
## Physics frames to wait for each phase (landing, then the jump) before giving up.
const MAX_FRAMES: int = 300
const GROUND_SIZE: Vector2 = Vector2(2000.0, 100.0)
## A little above the ground, so the player lands on its own before jumping.
const SPAWN_POSITION: Vector2 = Vector2(0.0, -2.0)


func _initialize() -> void:
	root.add_child(_make_ground())
	var player: Player = PLAYER_SCENE.instantiate() as Player
	player.position = SPAWN_POSITION
	root.add_child(player)
	var passed: bool = await _jump_peaks_at_jump_height(player)
	quit(0 if passed else 1)


## Ground with its top edge at y = 0.
func _make_ground() -> StaticBody2D:
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = GROUND_SIZE
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	var ground: StaticBody2D = StaticBody2D.new()
	ground.position.y = GROUND_SIZE.y / 2.0
	ground.add_child(collision)
	return ground


func _jump_peaks_at_jump_height(player: Player) -> bool:
	if not await _wait_until_on_floor(player):
		printerr("FAIL: the player never landed.")
		return false
	var start_y: float = player.position.y
	var peak_y: float = start_y
	var left_floor: bool = false
	Input.action_press(&"jump")
	for _frame: int in MAX_FRAMES:
		await physics_frame
		peak_y = minf(peak_y, player.position.y)
		if not player.is_on_floor():
			left_floor = true
		elif left_floor:
			break
	Input.action_release(&"jump")
	if not left_floor:
		printerr("FAIL: the player did not jump.")
		return false
	var peak_height: float = start_y - peak_y
	var expected: float = player.stats.jump_height
	var passed: bool = absf(peak_height - expected) <= TOLERANCE
	var verdict: String = "PASS" if passed else "FAIL"
	print("%s: peak %.1f px, Jump Height %.1f px, tolerance %.1f px" % [verdict, peak_height, expected, TOLERANCE])
	return passed


func _wait_until_on_floor(player: Player) -> bool:
	for _frame: int in MAX_FRAMES:
		await physics_frame
		if player.is_on_floor():
			return true
	return false
