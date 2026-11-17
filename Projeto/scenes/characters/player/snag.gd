extends Node

## What brambles do to the man while he is in them (ADR 0067). They catch him: he keeps Speed
## Multiplier of his run, cannot jump, and loses SP Per Second. Out of every strip before his SP runs
## out, he lives with what is left; once it runs out in them, he dies there, the death put down to
## the strip that holds him. So a foot in at an edge costs SP and the middle of a strip kills. While
## caught he sinks into them as his SP goes, from 0 at the catch to 1 at his death, which his drawing
## shows. The strips call catch() and release(); it never looks for them. It goes as a child of the
## player, who reaches it as Player.snag, and _physics_process() only runs while he is caught. It is
## preloaded where it is needed, with no class_name, so a new copy of the project runs its tests with
## no editor to index it first.

## Brambles caught him, from free.
signal caught
## He is out of every strip that held him, alive.
signal freed
## How far he has sunk, from 0 at the catch to 1 at his death: on each physics frame he is caught,
## and 0 on the one he gets out.
signal sink_changed(sink: float)

## Name of the snag's modifier on the player.
const MODIFIER_SOURCE: StringName = &"snag"

## The player it holds.
@export var player: Player
## Share of the running speed kept while he is caught: low, so only a man caught near an edge gets
## out before his SP runs out. He cannot jump while caught.
@export_range(0.02, 1.0, 0.01) var speed_multiplier: float = 0.1
## SP lost each second he is in brambles: with Max SP 100, a man caught with all of it has two thirds
## of a second.
@export_range(1.0, 1000.0, 1.0, "suffix:SP/s") var sp_per_second: float = 150.0

## The strips that hold him now, in the order they caught him.
var _holders: Array[Node] = []
## What a death in them is put down to, as the last strip to catch him said.
var _cause: StringName = &""
## His SP as he was caught, from which the sinking is measured.
var _sp_at_catch: float = 0.0
## The same modifier for the whole game, so a new Speed Multiplier reaches him at once.
var _modifier: MovementModifier = MovementModifier.new(1.0, 1.0, true)


func _ready() -> void:
	assert(player != null, "Snag: assign the player it holds to Player.")
	player.snag = self
	set_physics_process(false)


## Runs after the player's own physics, as its child: the SP he loses on this frame counts from the
## next move.
func _physics_process(delta: float) -> void:
	if player.is_dead():
		set_physics_process(false)
		return
	# Only on a change: each one makes the player combine his modifiers again.
	if _modifier.speed_multiplier != speed_multiplier:
		_modifier.speed_multiplier = speed_multiplier
	player.soul_points.take_damage(sp_per_second * delta)
	# A demon's grab sinks his drawing at its own pace; the brambles do not fight it for the drawing.
	if not player.is_grabbed():
		sink_changed.emit(get_sink())
	if player.soul_points.is_depleted():
		player.die(_cause, _death_source())


## The strip holder catches him, a death in it put down to cause. Caught already, it only joins the
## others, so two strips at once take SP once. Dead, nothing happens.
func catch(holder: Node, cause: StringName) -> void:
	if player.is_dead() or holder in _holders:
		return
	_holders.append(holder)
	_cause = cause
	if _holders.size() > 1:
		return
	_sp_at_catch = player.soul_points.get_sp()
	_modifier.speed_multiplier = speed_multiplier
	player.add_movement_modifier(MODIFIER_SOURCE, _modifier)
	set_physics_process(true)
	caught.emit()


## The strip holder lets go. Out of every one, alive, he runs and jumps in full again.
func release(holder: Node) -> void:
	if holder not in _holders:
		return
	_holders.erase(holder)
	if is_caught() or player.is_dead():
		return
	player.remove_movement_modifier(MODIFIER_SOURCE)
	set_physics_process(false)
	sink_changed.emit(0.0)
	freed.emit()


func is_caught() -> bool:
	return not _holders.is_empty()


## How far he has sunk: 0 when free or at the catch, 1 when his SP runs out.
func get_sink() -> float:
	if not is_caught() or _sp_at_catch <= 0.0:
		return 0.0
	return clampf(1.0 - player.soul_points.get_sp() / _sp_at_catch, 0.0, 1.0)


## The name of the strip that holds him, the last to catch him, for the run's numbers.
func _death_source() -> StringName:
	for index: int in range(_holders.size() - 1, -1, -1):
		if is_instance_valid(_holders[index]):
			return _holders[index].name
	return &""
