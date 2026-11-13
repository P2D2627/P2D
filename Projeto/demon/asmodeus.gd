class_name Asmodeus
extends Node2D

## Asmodeus, the boss of Lust, as a stand-in until her art comes (S3): she never fights. The level
## calls talk() with a cue of lust.dialogue, at the start of a phase, when his deaths bring an offer
## or at the end of the level, and she appears, talks and goes. While she talks the man stands
## still, with no run, no jump and no crucifix, as with Velvet; he moves again on the physics frame
## after her last line, so the press that closed it does not make him jump. appear_at() puts her
## next to where he is, for the offer that waits at the entrance of a zone. Only Visible While
## Talking off keeps her on screen between talks. She never decides what happens after a talk: the
## lines accept or refuse through Offers, and whoever called talk() hears talk_ended.

## She started talking from cue.
signal talk_started(cue: String)
## The talk from cue is over, and the man can move again.
signal talk_ended(cue: String)

## Name of her change to the man's movement, and of what keeps his crucifix down, while she talks.
const SOURCE: StringName = &"asmodeus"

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
## Where she stands from the man when appear_at() puts her next to him.
@export var appear_offset: Vector2 = Vector2(180.0, 0.0)

var _talking_cue: String = ""
## No run and no jump while she talks.
var _modifier: MovementModifier = MovementModifier.new(0.0, 1.0, true)


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


## Puts her next to point, on the man's side Appear Offset says.
func appear_at(point: Vector2) -> void:
	global_position = point + appear_offset


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
	var cue: String = _talking_cue
	_talking_cue = ""
	if visible_while_talking_only:
		hide()
	talk_ended.emit(cue)
