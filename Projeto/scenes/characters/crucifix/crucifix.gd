class_name Crucifix
extends Node2D

## The crucifix the man holds up. A press of Crucifix raises it, on the floor, and it stays up while
## Crucifix is held and it has charge. The charge is Max Use Time: each second up spends a second of
## it, and down it fills back from empty to full in Cooldown Time, so a short use costs only its own
## time. A press a moment before it can go up, such as just before landing, still raises it then
## (Raise Buffer Time). Only a press made in the game counts: Crucifix held down since a menu, the
## pause or the cooldown raises nothing until it is pressed again. Letting go or leaving the floor
## lowers it with the rest of its charge, and it stays down at least Min Down Time, so quick taps
## never flash its light; running the charge out lowers it and locks it, the cooldown, until the
## charge is full again. Something else, such as the grab, can keep it down with block(), without
## the crucifix knowing what it is. While up, it slows the player down, stops it from jumping,
## pushes every Repellable inside its radius out of it, saying struck as something it pushes comes
## in, heals and lights up its radius. For the last Warning Time of its charge, the light
## pulses, deeper as the end comes, to warn that it is about to come down; the vibration and the
## sound read the same warning. _process() only runs while it is up.
## Lost for good, it leaves the game. It goes as a child of the player and reads the player's own
## PlayerInput, so an AI, a cutscene or a test drives it too. The player does not know it exists:
## the crucifix changes it through a MovementModifier.

## The crucifix went up.
signal raised
## The crucifix went down. When its charge ran out, ran_out comes just before and cooldown_started
## follows; when it is lost, lost does.
signal lowered
## The charge ran out, also on a frame that lets go or leaves the floor, so the cooldown it starts is
## always heard; lowered follows on the same frame.
signal ran_out
## A press of Crucifix came during the cooldown, too early for the kept press to raise the crucifix
## when the cooldown ends. Every upgrade with a cooldown says so with a signal of this name, so they
## can share the sound of a refused press.
signal refused
## The charge ran out: the crucifix is locked for duration seconds, until the charge is full again.
signal cooldown_started(duration: float)
## The charge is full again after running out: the crucifix goes up at the next press of Crucifix.
signal cooldown_finished
## The crucifix is gone for good, after the first upgrade accepted. It leaves the game at the end of
## this frame.
signal lost
## SP the crucifix gives back on this physics frame. The player's scene connects it to the man's
## SoulPoints.
signal healed(amount: float)
## Something it pushes, such as a demon or a lost soul, came into its radius while it is up: once a
## physics frame, however many come in on it, and not on every frame they are pushed. What is inside
## as it goes up says so then, just after raised. A Repellable it reaches but does not move, with no
## Target, such as a gate's unlocker, says nothing.
signal struck

## What the crucifix is doing: down with charge, up, or locked after running its charge out.
## _physics_process() changes it, and so do block() and lose() as they lower it.
enum Phase { READY, RAISED, COOLDOWN }

## Name of the crucifix's modifier on the player.
const MODIFIER_SOURCE: StringName = &"crucifix"
## No physics frame yet.
const NO_FRAME: int = -1

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
## The charge, in units that keep it exact in whole frames: a physics frame up spends
## _spend_per_frame() of them and a frame down gives back _fill_per_frame(), so a full charge lasts
## exactly Max Use Time and fills from empty in exactly Cooldown Time, with no rounding. Full when
## the crucifix is ready.
var _charge: int = 0
## What a frame up spent when the charge was last looked at: a new Cooldown Time, set while the game
## runs, changes the units, and the charge is scaled to keep the same seconds of use.
var _spent_per_frame: int = 1
## Physics frames left of Min Down Time, after it was lowered with charge left.
var _down_frames_left: int = 0
## Physics frames left in which a press of Crucifix is kept, waiting for a moment the crucifix can
## go up.
var _raise_buffer_frames_left: int = 0
## Who keeps the crucifix down, such as the grab: while anyone does, it can't go up.
var _blockers: Array[StringName] = []
## The crucifix's change to the player's movement while it is up: slower, and no jumping. The same
## one for the crucifix's whole life, so a new Speed Multiplier reaches the player at once, even
## while the crucifix is up.
var _modifier: MovementModifier = MovementModifier.new(1.0, 1.0, true)
## The light's brightness in the scene, which the warning dips from and goes back to.
var _light_energy: float = 1.0
## The physics frame struck was last said on, so it is said once a frame.
var _struck_frame: int = NO_FRAME

@onready var _repel_area: Area2D = %RepelArea
@onready var _repel_shape: CollisionShape2D = %RepelShape
@onready var _light: PointLight2D = %Light
@onready var _placeholder: Polygon2D = %Placeholder


func _ready() -> void:
	assert(stats != null, "Crucifix: assign a CrucifixStats resource to Stats.")
	assert(player != null, "Crucifix: assign the player that holds it to Player.")
	_light_energy = _light.energy
	_repel_area.area_entered.connect(_on_repel_area_entered)
	_spent_per_frame = _spend_per_frame()
	_charge = _full_charge()
	_apply_stats()
	_show(false)
	set_process(false)


## While it is up, the light follows the warning: all of its brightness until the warning begins.
func _process(_delta: float) -> void:
	_light.energy = _light_energy * get_warning_pulse()


## Runs after the player's own physics, as its child, so it reads the state of this frame. The
## slowdown and the jump block it puts on the player take effect from the next frame.
func _physics_process(delta: float) -> void:
	# Stats changed while the game runs: the same seconds of use in the new units, and no more than
	# a new, shorter Max Use Time.
	var spend: int = _spend_per_frame()
	if spend != _spent_per_frame:
		_charge = roundi(float(_charge) * spend / _spent_per_frame)
		_spent_per_frame = spend
	_charge = mini(_charge, _full_charge())
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
## it is up, it goes down with the rest of its charge, as when Crucifix is let go. While any source
## keeps it down, a press of Crucifix is not kept, so Crucifix held since then raises nothing until
## it is pressed again. Blocking twice for the same source is the same as once. After lose(), it does nothing.
func block(source: StringName) -> void:
	if is_queued_for_deletion():
		return
	if source not in _blockers:
		_blockers.append(source)
	_raise_buffer_frames_left = 0
	if _phase == Phase.RAISED:
		_lower()


## Lets the crucifix go up again for source. It stays down while another source keeps it there,
## and nothing happens if source kept nothing down.
func unblock(source: StringName) -> void:
	_blockers.erase(source)


## True while any source keeps the crucifix down.
func is_blocked() -> bool:
	return not _blockers.is_empty()


## Seconds of charge left while the crucifix is up; 0 unless it is up. For the warning.
func get_use_time_left() -> float:
	return get_charge() if _phase == Phase.RAISED else 0.0


## Seconds the crucifix can stay up on its charge now, up or down: Max Use Time when full. For the
## HUD.
func get_charge() -> float:
	return float(_charge) / _spend_per_frame() / Engine.physics_ticks_per_second


## How far the warning that it is about to come down has gone, from 0 to 1: 0 while it is down, as it
## comes down, or while more than Warning Time of charge is left, then up in a straight line to 1 as
## the charge runs out; raised with less than that, it starts part of the way. For the light and the
## vibration.
func get_warning_progress() -> float:
	if _phase != Phase.RAISED or _charge <= 0 or stats.warning_time <= 0.0:
		return 0.0
	return clampf(1.0 - get_use_time_left() / stats.warning_time, 0.0, 1.0)


## The share of its brightness the light has now: all of it unless it warns; while it warns, it dips
## Warning Pulse Rate times a second along a cosine, by Warning Dim Depth at most, deeper as the
## warning goes on, timed from the end of the use, so the deepest dip comes as the use runs out. The
## light and the hold sound (CrucifixSounds) follow it.
func get_warning_pulse() -> float:
	var progress: float = get_warning_progress()
	if progress <= 0.0:
		return 1.0
	var dip: float = 0.5 + 0.5 * cos(TAU * stats.warning_pulse_rate * get_use_time_left())
	return 1.0 - stats.warning_dim_depth * progress * dip


## Seconds left in the cooldown, until the charge is full; 0 unless it is locked. For the HUD.
func get_cooldown_left() -> float:
	if _phase != Phase.COOLDOWN:
		return 0.0
	return float(_cooldown_frames_left()) / Engine.physics_ticks_per_second


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


## Fills the charge, and goes up with a kept press, on the floor, while Crucifix is still held, once
## Min Down Time is over. A press made during it is kept: its Raise Buffer Time only starts then.
func _physics_ready(held: bool) -> void:
	_fill()
	if _down_frames_left > 0:
		_down_frames_left -= 1
		if _raise_buffer_frames_left > 0:
			# Undoes this frame's count of the kept press, at the end of _physics_process().
			_raise_buffer_frames_left += 1
		return
	if _raise_buffer_frames_left > 0 and held and _is_on_floor():
		_raise()


## Spends a frame of the charge; letting go or leaving the floor lowers it with the rest, and running
## the charge out lowers it and starts the cooldown. Otherwise it repels and heals.
func _physics_raised(delta: float, held: bool) -> void:
	_charge = maxi(_charge - _spend_per_frame(), 0)
	var on_floor: bool = _is_on_floor()
	var empty: bool = _charge == 0
	if empty:
		ran_out.emit()
	if not held or not on_floor or empty:
		_lower()
		if empty:
			_start_cooldown()
		return
	_repel(delta)
	_heal(delta)


## Fills the charge; once it is full, the crucifix is ready again.
func _physics_cooldown() -> void:
	_fill()
	if _charge >= _full_charge():
		_phase = Phase.READY
		cooldown_finished.emit()


## True while the cooldown lasts longer than a press made now is kept, so that press will not raise
## the crucifix when the cooldown ends. Read before this frame's filling of the charge.
func _cooldown_outlasts_a_press() -> bool:
	return _cooldown_frames_left() > stats.get_raise_buffer_frames()


## Physics frames the charge takes to be full from where it is, while it fills.
func _cooldown_frames_left() -> int:
	return ceili(float(_full_charge() - _charge) / _fill_per_frame())


## Units of a full charge: Max Use Time's frames, each worth what a frame up spends.
func _full_charge() -> int:
	return stats.get_max_use_frames() * _spend_per_frame()


## Units a physics frame up spends: Cooldown Time's frames, at least one, so a frame down, which
## gives back Max Use Time's frames, fills an empty charge in exactly Cooldown Time.
func _spend_per_frame() -> int:
	return maxi(1, stats.get_cooldown_frames())


## Units a physics frame down gives back.
func _fill_per_frame() -> int:
	return stats.get_max_use_frames()


func _fill() -> void:
	_charge = mini(_charge + _fill_per_frame(), _full_charge())


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
	player.add_movement_modifier(MODIFIER_SOURCE, _modifier)
	_show(true)
	set_process(true)
	raised.emit()
	if _repel_area.get_overlapping_areas().any(_is_pushed):
		_strike()


## Down with the rest of its charge, ready to go up again after Min Down Time; the cooldown, if it
## ran out, comes after.
func _lower() -> void:
	_phase = Phase.READY
	_down_frames_left = stats.get_min_down_frames()
	player.remove_movement_modifier(MODIFIER_SOURCE)
	_show(false)
	set_process(false)
	_light.energy = _light_energy
	lowered.emit()


## Locked until the charge is full; Min Down Time does not add to that.
func _start_cooldown() -> void:
	_phase = Phase.COOLDOWN
	_down_frames_left = 0
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


## The repel area senses all the time, and the physics engine says when something comes in, so
## telling what comes in costs nothing on the frames it does not. What comes in while the crucifix
## is down says nothing.
func _on_repel_area_entered(area: Area2D) -> void:
	if _phase == Phase.RAISED and _is_pushed(area):
		_strike()


## True for a Repellable with a Target, which the crucifix moves; false for one it only reaches.
func _is_pushed(area: Area2D) -> bool:
	var repellable: Repellable = area as Repellable
	return repellable != null and repellable.target != null


## Says struck, once a physics frame however many come in on it.
func _strike() -> void:
	var frame: int = Engine.get_physics_frames()
	if frame != _struck_frame:
		_struck_frame = frame
		struck.emit()


## Gives back heal_per_second SP for every second the crucifix is up. The crucifix only says how
## much: the player's scene connects healed to the man's SoulPoints, which heal.
func _heal(delta: float) -> void:
	var amount: float = stats.heal_per_second * delta
	healed.emit(amount)
