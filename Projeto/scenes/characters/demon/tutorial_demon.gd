class_name TutorialDemon
extends Node2D

## The tutorial's demon, Velvet, a dog that never attacks. She waits a little ahead of where the man
## wakes up, strolling Walk Reach each way from where she stands in the level and resting at each
## end. While he is in her Talk Area, or she talks, she stands still, turned to him. The first time
## he walks into her Talk Area she talks to him on her own, from First Cue. After that, Interact near
## her talks again, from Again Cue, and her key shows over her while he is near. While she talks, the
## man stands still: no run, no jump and no crucifix. The lines advance with Jump, which also skips
## the typing. Having met her stays in GameState, so a saved game does not make her repeat the first
## talk, nor count its answers twice. Her States are an enum, as the man's (ADR 0009): she has only
## three; walking or standing is not a state of the talk, so it is kept apart.

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

@export_group("Walk")
## How far she strolls each way from where she stands in the level, in px; 0 keeps her in place.
## She walks without colliding and her Talk Area stays where she stands, so her zone has to be flat
## floor and the reach well inside the Talk Area.
@export_range(0.0, 200.0, 1.0, "suffix:px") var walk_reach: float = 128.0
## Her strolling speed. Her steps follow the ground she covers, so a faster stroll steps faster.
@export_range(10.0, 300.0, 1.0, "suffix:px/s") var walk_speed: float = 88.0
## How long she rests at each end before she turns back.
@export_range(0.0, 5.0, 0.1, "suffix:s") var walk_pause: float = 1.5
## Ground her feet cover from one frame of her walk to the next: 22 px of the art at the sprite's
## scale of 0.5. Smaller makes her feet slide forward; bigger, back.
@export_range(1.0, 40.0, 0.5, "suffix:px") var stride_per_frame: float = 11.0
## The frame of her walk each walk starts from: the one with four feet on the ground.
@export_range(0, 7) var stand_frame: int = 4
## Her walk, a row of Walk Frames, the same as the other dogs'.
@export var walk_texture: Texture2D
@export_range(1, 16) var walk_frames: int = 8
## What she plays while she stands, a row of Idle Frames, the same as the other dogs'.
@export var idle_texture: Texture2D
@export_range(1, 16) var idle_frames: int = 4
@export_range(1.0, 30.0, 0.5, "suffix:fps") var idle_fps: float = 4.0

var _state: State = State.WAITING
## True while the man is inside her Talk Area.
var _player_near: bool = false
## The balloon's locals, kept from one talk to the next, so a question asked is not asked again.
var _locals: Dictionary = {}
## No run and no jump while she talks.
var _modifier: MovementModifier = MovementModifier.new(0.0, 1.0, true)
## Where her body stands in the level: her stroll goes Walk Reach each way from here.
var _home_x: float = 0.0
## The way she strolls: 1.0 to the right, -1.0 to the left.
var _heading: float = 1.0
## Seconds she still rests at the end she reached.
var _rest_left: float = 0.0
## Ground walked since she last stood, which picks her walk frame.
var _walked: float = 0.0
## Seconds she has stood, which picks her idle frame.
var _stood: float = 0.0
var _walking: bool = false

@onready var _talk_area: Area2D = %TalkArea
@onready var _talk_key: KeyPrompt = %TalkKey
@onready var _body: CharacterBody2D = %Body
@onready var _sprite: Sprite2D = %Sprite
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
	_home_x = _body.position.x
	_rest_left = walk_pause


func _physics_process(delta: float) -> void:
	if _state == State.IDLE and _player_near and Input.is_action_just_pressed(talk_action):
		_talk(again_cue)
	if _player_near or _state == State.TALKING:
		_walking = false
		_face(player.global_position.x - _body.global_position.x)
	else:
		_stroll(delta)


func _process(delta: float) -> void:
	if _walking:
		_show_sheet(walk_texture, walk_frames)
		_stood = 0.0
		_sprite.frame = int(_walked / stride_per_frame) % walk_frames
	elif idle_texture != null:
		_show_sheet(idle_texture, idle_frames)
		_stood += delta
		_sprite.frame = int(_stood * idle_fps) % idle_frames
	else:
		_show_sheet(walk_texture, walk_frames)
		_sprite.frame = stand_frame


## Puts the sheet texture, frames across, on her sprite, if it is not there already.
func _show_sheet(texture: Texture2D, frames: int) -> void:
	if texture != null and _sprite.texture != texture:
		_sprite.texture = texture
		_sprite.hframes = frames


func get_state() -> State:
	return _state


func _talk(cue: String) -> void:
	_change_state(State.TALKING)
	player.add_movement_modifier(SOURCE, _modifier)
	player.hold_still()
	crucifix.block(SOURCE)
	var balloon: DialogueBalloon = balloon_scene.instantiate()
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


## Rests at the end she reached, then walks to the other end of her reach, her key over her. Each
## walk starts from her standing frame, so she does not jump into a step.
func _stroll(delta: float) -> void:
	if walk_reach <= 0.0:
		_walking = false
		return
	if _rest_left > 0.0:
		_rest_left -= delta
		_walking = false
		return
	if not _walking:
		_walking = true
		_walked = stand_frame * stride_per_frame
	var end: float = _home_x + _heading * walk_reach
	var x: float = move_toward(_body.position.x, end, walk_speed * delta)
	_walked += absf(x - _body.position.x)
	_body.position.x = x
	_talk_key.position.x = x
	_face(_heading)
	if x == end:
		_heading = -_heading
		_rest_left = walk_pause


## Her art faces right; a negative side turns her left. A side of 0 leaves her as she is.
func _face(side: float) -> void:
	if side != 0.0:
		_sprite.scale.x = absf(_sprite.scale.x) * signf(side)


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
