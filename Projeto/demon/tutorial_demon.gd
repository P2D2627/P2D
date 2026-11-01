class_name TutorialDemon
extends Node2D

## The tutorial's demon, Velvet, as a stand-in until her art comes: she never attacks. She waits a
## little ahead of where the man wakes up, and the first time he walks into her Talk Area she talks
## to him on her own, from First Cue. After that, Interact near her talks again, from Again Cue, and
## her key shows over her while he is near. While she talks, the man stands still: no run, no jump
## and no crucifix. The lines advance with Jump, which also skips the typing. Having met her stays in
## GameState, so a saved game does not make her repeat the first talk, nor count its answers twice.
## Her States are an enum, as the man's (ADR 0009): she has only three.

## The man walked into her Talk Area for the first time; the S1.06 dialogue can hang from here.
signal player_arrived
## She started talking.
signal talk_started
## She stopped talking, and the man can move again.
signal talk_ended

enum State {
	## Before the man first comes near: he starts her talking just by walking in.
	WAITING,
	## Talking: the balloon is open and the man stands still.
	TALKING,
	## Talked once: Interact near her talks again.
	IDLE,
}

## Name of her change to the man's movement, and of what keeps his crucifix down, while she talks.
const SOURCE: StringName = &"tutorial_demon"
## The event in GameState: the first talk is over.
const MET_EVENT: StringName = &"velvet_met"

## The man she talks to.
@export var player: Player
## The man's crucifix, kept down while she talks.
@export var crucifix: Crucifix
@export var dialogue_resource: DialogueResource
## Where her first talk starts, when he walks in.
@export var first_cue: String = "velvet"
## Where she starts each time he talks to her again.
@export var again_cue: String = "velvet_again"
## The balloon her lines show in.
@export var balloon_scene: PackedScene
## Advances the lines, and skips the typing of one.
@export var next_action: StringName = &"jump"
## Talks to her again, after the first time.
@export var talk_action: StringName = &"interact"

var _state: State = State.WAITING
## True while the man is inside her Talk Area.
var _player_near: bool = false
## The balloon's locals, kept from one talk to the next, so a question asked is not asked again.
var _locals: Dictionary = {}
## No run and no jump while she talks.
var _modifier: MovementModifier = MovementModifier.new(0.0, 1.0, true)

@onready var _talk_area: Area2D = %TalkArea
@onready var _talk_key: KeyPrompt = %TalkKey
@onready var _progress: GameProgress = get_node(^"/root/GameState") as GameProgress


func _ready() -> void:
	assert(player != null, "TutorialDemon: assign the man to Player.")
	assert(crucifix != null, "TutorialDemon: assign the man's Crucifix to Crucifix.")
	assert(dialogue_resource != null, "TutorialDemon: assign a .dialogue file to Dialogue Resource.")
	assert(balloon_scene != null, "TutorialDemon: assign the balloon's scene to Balloon Scene.")
	if _progress.has_event(MET_EVENT):
		_state = State.IDLE
	_talk_area.body_entered.connect(_on_talk_area_body_entered)
	_talk_area.body_exited.connect(_on_talk_area_body_exited)
	_update_talk_key()


func _physics_process(_delta: float) -> void:
	if _state == State.IDLE and _player_near and Input.is_action_just_pressed(talk_action):
		_talk(again_cue)


func get_state() -> State:
	return _state


func _talk(cue: String) -> void:
	_change_state(State.TALKING)
	player.add_movement_modifier(SOURCE, _modifier)
	player.hold_still()
	crucifix.block(SOURCE)
	var balloon: DialogueManagerExampleBalloon = balloon_scene.instantiate()
	balloon.next_action = next_action
	balloon.skip_action = next_action
	balloon.tree_exited.connect(_on_balloon_tree_exited)
	add_child(balloon)
	balloon.locals = _locals
	balloon.start(dialogue_resource, cue)
	talk_started.emit()


func _change_state(state: State) -> void:
	_state = state
	_update_talk_key()


func _update_talk_key() -> void:
	_talk_key.visible = _state == State.IDLE and _player_near


func _on_talk_area_body_entered(body: Node2D) -> void:
	if body != player:
		return
	_player_near = true
	_update_talk_key()
	if _state == State.WAITING:
		player_arrived.emit()
		_talk(first_cue)


func _on_talk_area_body_exited(body: Node2D) -> void:
	if body != player:
		return
	_player_near = false
	_update_talk_key()


## The balloon frees itself after the last line. The man moves again on the next physics frame, so
## the press of Jump that closed it does not also make him jump: his jump is still blocked on the
## frame it counts as just pressed.
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
	_progress.mark_event(MET_EVENT)
	_change_state(State.IDLE)
	talk_ended.emit()
