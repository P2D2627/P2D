class_name Asmodeus
extends Node2D

## Asmodeus, the boss of Lust, drawn with her figure from the visual novel: she never fights. The level
## calls talk() with a cue of lust.dialogue, at the start of a phase, when his deaths bring an offer
## or at the end of the level, and she appears, talks and goes. While she talks the man stands
## still, with no run, no jump and no crucifix, as with Velvet; he moves again on the physics frame
## after her last line, so the press that closed it does not make him jump. What Stills names (the
## dogs) stands still while she talks, so nothing bites the man she holds. When she talks is up to
## the level's AsmodeusDirector. appear_at() puts her
## next to where he is, for the offer that waits at the entrance of a zone. Only Visible While
## Talking off keeps her on screen between talks. She never decides what happens after a talk: the
## lines accept or refuse through Offers, and whoever called talk() hears talk_ended.

## She started talking from cue.
signal talk_started(cue: String)
## The talk from cue is over, and the man can move again.
signal talk_ended(cue: String)

## Name of her change to the man's movement, and of what keeps his crucifix down, while she talks.
const SOURCE: StringName = &"asmodeus"
## Px her figure is taken in all round when checked for rock (see Appear Clear Of).
const CLEAR_MARGIN: float = 4.0

## The man she talks to.
@export var player: Player
## The man's crucifix, kept down while she talks; empty takes the one under Player.
@export var crucifix: Crucifix
@export var dialogue_resource: DialogueResource
## The balloon her lines show in.
@export var balloon_scene: PackedScene
## Advances the lines; held, skips them up to the next answers.
@export var next_action: StringName = &"jump"
## Whether she shows only while she talks, as if she came and went.
@export var visible_while_talking_only: bool = true
## Where she stands from the man when appear_at() puts her next to him: 300 px apart, so in the talk's shot
## the two read as two, not as one figure (#284).
@export var appear_offset: Vector2 = Vector2(300.0, 0.0)
## The physics layers she never appears inside: the world's rock. Where Appear Offset puts her figure in
## them, as at the bottom of phase 2's shaft, she appears as far on his other side, mirrored to face him, if
## that side is clear; with both sides in rock she keeps Appear Offset's side.
@export_flags_2d_physics var appear_clear_of: int = 1
## What stands still while she talks, as the level's dogs, so none bites the man she holds: each
## one is switched off, its children too, and back on after.
@export var stills: Array[Node] = []

var _talking_cue: String = ""
## The process mode each of Stills had before she talked.
var _modes_before: Dictionary[Node, ProcessMode] = {}
## No run and no jump while she talks.
var _modifier: MovementModifier = MovementModifier.new(0.0, 1.0, true)

@onready var _sprite: Sprite2D = $Sprite as Sprite2D


func _ready() -> void:
	assert(player != null, "Asmodeus: assign the man to Player.")
	assert(dialogue_resource != null, "Asmodeus: assign lust.dialogue to Dialogue Resource.")
	assert(balloon_scene != null, "Asmodeus: assign the balloon's scene to Balloon Scene.")
	if crucifix == null:
		crucifix = player.get_node_or_null(^"Crucifix") as Crucifix
	if visible_while_talking_only:
		hide()


func is_talking() -> bool:
	return not _talking_cue.is_empty()


## The cue she is talking from; empty when she is not talking.
func get_talking_cue() -> String:
	return _talking_cue


## Her drawing, for what frames her, as the camera in a talk.
func get_figure() -> Node2D:
	return _sprite


## Puts her next to point, on the side Appear Offset says, or on the other if hers is in rock (Appear Clear Of).
func appear_at(point: Vector2) -> void:
	var mirrored: Vector2 = point + Vector2(-appear_offset.x, appear_offset.y)
	global_position = point + appear_offset
	_sprite.flip_h = false
	if _in_rock(global_position) and not _in_rock(mirrored):
		global_position = mirrored
		_sprite.flip_h = true


## She talks from cue. Nothing happens while she is already talking.
func talk(cue: String) -> void:
	if is_talking():
		return
	_talking_cue = cue
	show()
	player.add_movement_modifier(SOURCE, _modifier)
	player.hold_still()
	if is_instance_valid(crucifix):
		crucifix.block(SOURCE)
	_still_the_stills()
	var balloon: DialogueBalloon = balloon_scene.instantiate()
	balloon.next_action = next_action
	balloon.skip_action = next_action
	balloon.tree_exited.connect(_on_balloon_tree_exited)
	add_child(balloon)
	balloon.start(dialogue_resource, cue)
	talk_started.emit(cue)


## The balloon frees itself after the last line. The man moves again on the next physics frame,
## so the press of Jump that closed it does not also make him jump.
func _on_balloon_tree_exited() -> void:
	# The level going away takes the balloon with it: nothing to let go of then.
	if not is_inside_tree() or is_queued_for_deletion():
		return
	await get_tree().physics_frame
	if not is_instance_valid(player):
		return
	player.remove_movement_modifier(SOURCE)
	player.let_go()
	if is_instance_valid(crucifix):
		crucifix.unblock(SOURCE)
	_wake_the_stills()
	var cue: String = _talking_cue
	_talking_cue = ""
	if visible_while_talking_only:
		hide()
	talk_ended.emit(cue)


## Whether her figure, standing at spot, overlaps what Appear Clear Of names. The figure is taken in by
## Clear Margin all round, so her feet on the floor do not count as in it.
func _in_rock(spot: Vector2) -> bool:
	var figure: Rect2 = TalkFraming.drawn_rect(_sprite).grow(-CLEAR_MARGIN)
	figure.position += spot - global_position
	var box := RectangleShape2D.new()
	box.size = figure.size
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = box
	query.transform = Transform2D(0.0, figure.get_center())
	query.collision_mask = appear_clear_of
	return not get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


func _still_the_stills() -> void:
	for node: Node in stills:
		if is_instance_valid(node):
			_modes_before[node] = node.process_mode
			node.process_mode = Node.PROCESS_MODE_DISABLED


func _wake_the_stills() -> void:
	for node: Node in _modes_before:
		if is_instance_valid(node):
			node.process_mode = _modes_before[node]
	_modes_before.clear()
