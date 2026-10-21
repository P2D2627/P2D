class_name Crucifix
extends Node2D

## The crucifix the man holds up. A press of Crucifix raises it, on the floor, and it stays up while
## Crucifix is held, for at most Max Use Time. A press a moment before it can go up, such as just
## before landing, still raises it then (Raise Buffer Time). Only a press made in the game counts:
## Crucifix held down since a menu, the pause or the cooldown raises nothing until it is pressed
## again. Letting go, leaving the floor or running out of time lowers it, and every use, long or
## short, is followed by the same Cooldown Time. Something else, such as the grab, can keep it down
## with block(), without the crucifix knowing what it is. While up, it slows the player down, stops
## it from jumping, pushes every Repellable inside its radius out of it, heals and lights up its
## radius.
## Lost for good, it leaves the game. It goes as a child of the player and reads the player's own
## PlayerInput, so an AI, a cutscene or a test drives it too. The player does not know it exists:
## the crucifix changes it through a MovementModifier.

## The crucifix went up.
signal raised
## The crucifix went down. After a use, cooldown_started follows; when it is lost, lost does. When
## the use ran out of time, ran_out comes just before.
signal lowered
## The use ran out of Max Use Time with Crucifix still held on the floor; lowered follows on the
## same frame. Letting go or leaving the floor on that frame counts as that, and does not say this.
signal ran_out
## A press of Crucifix came during the cooldown, too early for the kept press to raise the crucifix
## when the cooldown ends. Every upgrade with a cooldown says so with a signal of this name, so they
## can share the sound of a refused press.
signal refused
## The cooldown started; it lasts duration seconds.
signal cooldown_started(duration: float)
## The cooldown is over: the crucifix goes up at the next press of Crucifix.
signal cooldown_finished
## The crucifix is gone for good, after the first upgrade accepted. It leaves the game at the end of
## this frame.
signal lost
## SP the crucifix gives back on this physics frame. The player's scene connects it to the man's
## SoulPoints.
signal healed(amount: float)

## What the crucifix is doing. Only _physics_process() changes it.
enum Phase { READY, RAISED, COOLDOWN }

## Name of the crucifix's modifier on the player.
const MODIFIER_SOURCE: StringName = &"crucifix"

## Movement, timing, repel and heal values. Every crucifix that uses the same file shares them. A
## change to the radius or the slowdown takes effect at once, also while the game runs.
@export var stats: CrucifixStats:
	set(value):
		if stats != null and stats.changed.is_connected(_apply_stats):
			stats.changed.disconnect(_apply_stats)
		stats = value
		if stats != null:
			stats.changed.connect(_apply_stats)
		if is_node_ready():
			_apply_stats()
## The player that holds it.
@export var player: Player

var _phase: Phase = Phase.READY
## Physics frames left in the current use, while RAISED.
var _use_frames_left: int = 0
## Physics frames left in the cooldown, while COOLDOWN.
var _cooldown_frames_left: int = 0
## Physics frames left in which a press of Crucifix is kept, waiting for a moment the crucifix can
## go up.
var _raise_buffer_frames_left: int = 0
## Who keeps the crucifix down, such as the grab: while anyone does, it can't go up.
var _blockers: Array[StringName] = []
## The crucifix's change to the player's movement while it is up: slower, and no jumping. The same
## one for the crucifix's whole life, so a new Speed Multiplier reaches the player at once, even
## while the crucifix is up.
var _modifier: MovementModifier = MovementModifier.new(1.0, 1.0, true)

@onready var _repel_area: Area2D = %RepelArea
@onready var _repel_shape: CollisionShape2D = %RepelShape
@onready var _light: PointLight2D = %Light
@onready var _placeholder: Polygon2D = %Placeholder


func _ready() -> void:
	assert(stats != null, "Crucifix: assign a CrucifixStats resource to Stats.")
	assert(player != null, "Crucifix: assign the player that holds it to Player.")
	_apply_stats()
	_show(false)


## Runs after the player's own physics, as its child, so it reads the state of this frame. The
## slowdown and the jump block it puts on the player take effect from the next frame.
func _physics_process(delta: float) -> void:
	if player.input.is_crucifix_just_pressed() and not is_blocked():
		# One frame for the press itself, then Raise Buffer Time's frames.
		_raise_buffer_frames_left = stats.get_raise_buffer_frames() + 1
		if _phase == Phase.COOLDOWN and _cooldown_outlasts_a_press():
			refused.emit()
	var held: bool = player.input.is_crucifix_held()
	match _phase:
		Phase.READY:
			_physics_ready(held)
		Phase.RAISED:
			_physics_raised(delta, held)
		Phase.COOLDOWN:
			_physics_cooldown()
	if _raise_buffer_frames_left > 0:
		_raise_buffer_frames_left -= 1


func _exit_tree() -> void:
	player.remove_movement_modifier(MODIFIER_SOURCE)


func get_phase() -> Phase:
	return _phase


func is_raised() -> bool:
	return _phase == Phase.RAISED


## Keeps the crucifix down for source, such as the grab, until unblock() with the same source. If
## it is up, it goes down and the cooldown starts, as after any use. While any source keeps it down,
## a press of Crucifix is not kept, so Crucifix held since then raises nothing until it is pressed
## again. Blocking twice for the same source is the same as once. After lose(), it does nothing.
func block(source: StringName) -> void:
	if is_queued_for_deletion():
		return
	if source not in _blockers:
		_blockers.append(source)
	_raise_buffer_frames_left = 0
	if _phase == Phase.RAISED:
		_lower()
		_start_cooldown()


## Lets the crucifix go up again for source. It stays down while another source keeps it there,
## and nothing happens if source kept nothing down.
func unblock(source: StringName) -> void:
	_blockers.erase(source)


## True while any source keeps the crucifix down.
func is_blocked() -> bool:
	return not _blockers.is_empty()


## Seconds left in the current use; 0 unless the crucifix is up. For the HUD.
func get_use_time_left() -> float:
	return float(_use_frames_left) / Engine.physics_ticks_per_second


## Seconds left in the cooldown; 0 unless it is cooling down. For the HUD.
func get_cooldown_left() -> float:
	return float(_cooldown_frames_left) / Engine.physics_ticks_per_second


## Takes the crucifix away for good: it goes down, if it was up, says so with lost and leaves the
## game at the end of this frame. It does nothing more until then, not even on this frame's physics,
## and calling it again does nothing.
func lose() -> void:
	if is_queued_for_deletion():
		return
	set_physics_process(false)
	if _phase == Phase.RAISED:
		_lower()
	lost.emit()
	queue_free()


## Goes up with a kept press, on the floor, while Crucifix is still held.
func _physics_ready(held: bool) -> void:
	if _raise_buffer_frames_left > 0 and held and _is_on_floor():
		_raise()


## Counts the use down; letting go, leaving the floor or running out of time lowers it and starts
## the cooldown. Otherwise it repels and heals.
func _physics_raised(delta: float, held: bool) -> void:
	_use_frames_left -= 1
	var on_floor: bool = _is_on_floor()
	if held and on_floor and _use_frames_left <= 0:
		ran_out.emit()
	if not held or not on_floor or _use_frames_left <= 0:
		_lower()
		_start_cooldown()
		return
	_repel(delta)
	_heal(delta)


func _physics_cooldown() -> void:
	_cooldown_frames_left -= 1
	if _cooldown_frames_left <= 0:
		_cooldown_frames_left = 0
		_phase = Phase.READY
		cooldown_finished.emit()


## True while the cooldown lasts longer than a press made now is kept, so that press will not raise
## the crucifix when the cooldown ends. Read before this frame's count of the cooldown.
func _cooldown_outlasts_a_press() -> bool:
	return _cooldown_frames_left > stats.get_raise_buffer_frames()


## On the floor by both the player's state and the last move_and_slide(), so a jump taken on this
## very frame, which leaves the state on the floor until the next one, does not count.
func _is_on_floor() -> bool:
	return player.get_state() == Player.State.ON_FLOOR and player.is_on_floor()


## Puts the values of Stats that stay in place where they act: the radius, the light that shows it
## and the slowdown. Stats says when they change, so this runs again then; before the crucifix is
## ready, _ready() does it.
func _apply_stats() -> void:
	if not is_node_ready():
		return
	var shape: CircleShape2D = _repel_shape.shape as CircleShape2D
	if shape == null:
		shape = CircleShape2D.new()
		_repel_shape.shape = shape
	shape.radius = stats.repel_radius
	# The light's texture fades out at its edge, half its width from the middle.
	_light.texture_scale = 2.0 * stats.repel_radius / _light.texture.get_width()
	_modifier.speed_multiplier = stats.speed_multiplier


func _raise() -> void:
	_phase = Phase.RAISED
	_raise_buffer_frames_left = 0
	_use_frames_left = stats.get_max_use_frames()
	player.add_movement_modifier(MODIFIER_SOURCE, _modifier)
	_show(true)
	raised.emit()


func _lower() -> void:
	_use_frames_left = 0
	player.remove_movement_modifier(MODIFIER_SOURCE)
	_show(false)
	lowered.emit()


func _start_cooldown() -> void:
	_phase = Phase.COOLDOWN
	_cooldown_frames_left = stats.get_cooldown_frames()
	cooldown_started.emit(stats.cooldown_time)


func _show(value: bool) -> void:
	_light.enabled = value
	_placeholder.visible = value


## Pushes every Repellable inside the radius away from the crucifix, at repel_speed, until it is
## out.
func _repel(delta: float) -> void:
	var distance: float = stats.repel_speed * delta
	for area: Area2D in _repel_area.get_overlapping_areas():
		var repellable: Repellable = area as Repellable
		if repellable != null:
			repellable.push_away_from(global_position, distance)


## Gives back heal_per_second SP for every second the crucifix is up. The crucifix only says how
## much: the player's scene connects healed to the man's SoulPoints, which heal.
func _heal(delta: float) -> void:
	var amount: float = stats.heal_per_second * delta
	healed.emit(amount)
