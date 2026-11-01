class_name DebugOverlay
extends CanvasLayer

## Text in a corner of the screen with the numbers that help tune the game while playing. The
## Toggle Debug Overlay action shows and hides it, and Debug Damage hurts the player. Outside debug
## builds it frees itself, so a release export never shows it and nothing hurts through it. Its
## scene sets the process mode to Always, so it keeps working while the game is paused.

const TOGGLE_ACTION: StringName = &"toggle_debug_overlay"
const DAMAGE_ACTION: StringName = &"debug_damage"
const MS_PER_SECOND: float = 1000.0

## Whether the text shows when the scene starts.
@export var start_visible: bool = true
## SP a press of Debug Damage takes from the player, as a hit would, so the regeneration and the
## warnings can be tried before anything in the game hurts.
@export_range(0.0, 100.0, 1.0, "suffix:SP") var debug_damage: float = 10.0
## The player whose state, velocity, SP and jumps the text shows. Without one, the text has only the
## frame rate and frame times.
@export var player: Player
## The camera whose zone, look ahead and look down the text shows. Without one, there is no camera
## line.
@export var camera: GameCamera

## The last jump, as text, kept until the next one: what it jumped off and the tolerance frames it
## used. Empty until the first jump.
var _last_jump: String = ""
## The y the last jump took off from, and the smallest y it has reached since, in px.
var _take_off_y: float = 0.0
var _peak_y: float = 0.0

@onready var _label: Label = %Label


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	_set_shown(start_visible)
	# _physics_process only follows a jump up, so it starts off.
	set_physics_process(false)
	if is_instance_valid(player):
		player.jumped.connect(_on_jumped)
		player.wall_jumped.connect(_on_wall_jumped)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(TOGGLE_ACTION):
		_set_shown(not visible)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(DAMAGE_ACTION):
		_hurt_player()
		get_viewport().set_input_as_handled()


## Rewrites the text on every frame while it shows, with new strings each time, which only debug
## builds pay for. Each section is its own function. The player's sections need a player that still
## exists, and the camera's a camera: none may be linked, or it may have been freed.
func _process(_delta: float) -> void:
	var text: String = _performance_section()
	if is_instance_valid(player):
		text += "\n" + _player_section()
	if is_instance_valid(player) and is_instance_valid(player.soul_points):
		text += "\n" + _soul_points_section()
	if is_instance_valid(camera):
		text += "\n" + _camera_section()
	if is_instance_valid(player) and not _last_jump.is_empty():
		text += "\n" + _jump_section()
	_label.text = text


## Follows the last jump up, one physics frame at a time, and stops once it no longer rises: its
## peak is the smallest y on the way.
func _physics_process(_delta: float) -> void:
	if not is_instance_valid(player):
		set_physics_process(false)
		return
	_peak_y = minf(_peak_y, player.global_position.y)
	if player.velocity.y >= 0.0:
		set_physics_process(false)


## Takes Debug Damage SP from the player, as a hit would, unless the game is paused. Works with the
## text hidden too.
func _hurt_player() -> void:
	if get_tree().paused or not is_instance_valid(player) or not is_instance_valid(player.soul_points):
		return
	player.soul_points.take_damage(debug_damage)


## While hidden, _process does not run, so the text costs nothing per frame. Jumps are still
## followed up, so the text is right as soon as it shows again.
func _set_shown(shown: bool) -> void:
	visible = shown
	set_process(shown)


## Frames per second, and the slowest process step and slowest physics step, all over the last
## second. The engine updates the two times once a second, so a single slow frame shows for a
## whole second. At 60 FPS a frame has 16.6 ms.
func _performance_section() -> String:
	return "%d FPS   worst process %.2f ms   worst physics %.2f ms" % [
			roundi(Engine.get_frames_per_second()),
			_monitor_ms(Performance.TIME_PROCESS),
			_monitor_ms(Performance.TIME_PHYSICS_PROCESS)]


## The player's state, by its name in Player.State, and its velocity in px/s. In Godot, y grows
## downwards, so a fall has a positive y and a rise a negative one.
func _player_section() -> String:
	return "state %s   velocity (%+.0f, %+.0f) px/s" % [
			Player.State.find_key(player.get_state()), player.velocity.x, player.velocity.y]


## The man's SP out of Max SP, with a tenth so regeneration shows, the speed regeneration gives, so
## its ramp shows, and whether it is low or has run out.
func _soul_points_section() -> String:
	var soul_points: SoulPoints = player.soul_points
	var status: String = ""
	if soul_points.is_depleted():
		status = "   run out"
	elif soul_points.is_low():
		status = "   low"
	return "SP %.1f / %.0f   regen %.1f SP/s%s" % [soul_points.get_sp(),
			soul_points.get_max_sp(), soul_points.get_regen_rate(), status]


## The camera zone the player is in, or none, and how far the camera leads ahead and down, in px.
func _camera_section() -> String:
	return "camera zone %s   look ahead %+.0f px   look down %+.0f px" % [
			camera.get_zone_name(), camera.get_look_ahead(), camera.get_look_down()]


## The last jump and its peak, in px above where it took off. The peak grows while the jump rises
## and stays once it stops.
func _jump_section() -> String:
	return "%s   peak %.0f px" % [_last_jump, _take_off_y - _peak_y]


## One of the engine's time monitors, in ms instead of seconds.
func _monitor_ms(monitor: Performance.Monitor) -> float:
	return Performance.get_monitor(monitor) * MS_PER_SECOND


func _on_jumped(late_frames: int, buffered_frames: int) -> void:
	_remember_jump("the floor", late_frames, buffered_frames)


func _on_wall_jumped(late_frames: int, buffered_frames: int) -> void:
	_remember_jump("a wall", late_frames, buffered_frames)


## Keeps what the jump was for the text and starts following it up from where it took off. Each
## tolerance shows as the frames it used out of the frames Stats gives it.
func _remember_jump(jumped_off: String, late_frames: int, buffered_frames: int) -> void:
	var tolerances: PackedStringArray = []
	if late_frames > 0:
		tolerances.append("coyote %d/%d frames late"
				% [late_frames, player.stats.get_coyote_frames()])
	if buffered_frames > 0:
		tolerances.append("buffer %d/%d frames early"
				% [buffered_frames, player.stats.get_jump_buffer_frames()])
	if tolerances.is_empty():
		tolerances.append("on time")
	_last_jump = "jump off %s   %s" % [jumped_off, "   ".join(tolerances)]
	_take_off_y = player.global_position.y
	_peak_y = _take_off_y
	set_physics_process(true)
