class_name DialogueBalloon
extends CanvasLayer

## The game's dialogue balloon, made from Dialogue Manager's example balloon, as the plugin asks, so
## the addon stays as it came. Besides the example's lines, answers and typing, it shows who speaks
## in a portrait, for now a stand-in of the speaker's colour and initial until the art comes (S3),
## and lets the player skip: holding Next Action for Skip Hold Time runs through the lines up to the
## next one with answers, or to the end, without ever answering for him. The skipped lines still do
## what they do (an offer presented, an event marked), only unseen. How many lines he skipped goes
## to RunStats; it counts for the judgment's numbers, never for the moral record. It frees itself
## after the last line.

## He held the key long enough and count lines went by unseen.
signal lines_skipped(count: int)

## A Color for the stand-in portrait of a speaker the Portrait Colors do not name.
const DEFAULT_PORTRAIT_COLOR: Color = Color(0.35, 0.35, 0.4)

@export var dialogue_resource: DialogueResource
## Where the lines start when it starts on its own, with Auto Start.
@export var start_from_cue: String = ""
@export var auto_start: bool = false
## Whether nothing else gets the input while the balloon shows, but for Lets Through.
@export var will_block_other_input: bool = true
## The actions that still reach the rest of the game while the balloon shows: the pause, so a talk
## can be paused, and the debug keys.
@export var lets_through: Array[StringName] = [&"pause", &"toggle_debug_overlay", &"debug_damage",
		&"debug_accept_offer", &"debug_refuse_offer", &"debug_reset_run"]
## Advances the lines; held, skips them.
@export var next_action: StringName = &"ui_accept"
## Shows a line whole at once while it is still being typed.
@export var skip_action: StringName = &"ui_cancel"
@export_group("Skip")
## Seconds Next Action is held before the lines skip.
@export_range(0.1, 3.0, 0.05, "suffix:s") var skip_hold_time: float = 0.6
## Seconds held before the bar shows, so a tap to advance does not flash it.
@export_range(0.0, 1.0, 0.05, "suffix:s") var skip_bar_delay: float = 0.15
@export_group("Portraits")
## Each speaker's portrait, by the name the lines give them. A speaker missing here gets a stand-in.
@export var portraits: Dictionary[String, Texture2D] = {}
## The stand-in portrait's colour for each speaker, by name.
@export var portrait_colors: Dictionary[String, Color] = {
	"Asmodeus": Color(0.62, 0.12, 0.3),
	"Velvet": Color(0.45, 0.2, 0.55),
}
## The stand-in portrait's colour for the man, whatever name he was given.
@export var player_portrait_color: Color = Color(0.55, 0.45, 0.3)

## Values the lines can read and change for as long as the balloon shows, as {{locals.x}}.
var locals: Dictionary = {}
## Where the lines look for names, the balloon first.
var temporary_game_states: Array = []
var is_waiting_for_input: bool = false
## A long mutation hides the balloon until the next line.
var will_hide_balloon: bool = false
## The line on screen; null closes the balloon.
var dialogue_line: DialogueLine:
	set(value):
		if value:
			dialogue_line = value
			_apply_dialogue_line()
		else:
			if owner == null:
				queue_free()
			else:
				hide()
	get:
		return dialogue_line

var _mutation_cooldown: Timer = Timer.new()
var _locale: String = TranslationServer.get_locale()
## Seconds Next Action has been held.
var _held: float = 0.0
## True once a hold skipped, until the key comes up: one hold skips once.
var _hold_spent: bool = false
var _skipping: bool = false

@onready var _balloon: Control = %Balloon
@onready var _character_label: RichTextLabel = %CharacterLabel
@onready var _dialogue_label: DialogueLabel = %DialogueLabel
@onready var _responses_menu: DialogueResponsesMenu = %ResponsesMenu
@onready var _progress: Polygon2D = %Progress
@onready var _audio_stream_player: AudioStreamPlayer = %AudioStreamPlayer
@onready var _portrait: TextureRect = %Portrait
@onready var _portrait_stand_in: ColorRect = %PortraitStandIn
@onready var _portrait_initial: Label = %PortraitInitial
@onready var _skip_bar: ProgressBar = %SkipBar
@onready var _progress_state: GameProgress = get_node_or_null(^"/root/GameState") as GameProgress
@onready var _run_stats: GameRunStats = get_node_or_null(^"/root/RunStats") as GameRunStats


func _ready() -> void:
	_balloon.hide()
	_skip_bar.hide()
	Engine.get_singleton("DialogueManager").mutated.connect(_on_mutated)
	if _responses_menu.next_action.is_empty():
		_responses_menu.next_action = next_action
	_mutation_cooldown.timeout.connect(_on_mutation_cooldown_timeout)
	add_child(_mutation_cooldown)
	if auto_start:
		assert(is_instance_valid(dialogue_resource), "DialogueBalloon: Auto Start needs a Dialogue Resource.")
		start()


func _process(delta: float) -> void:
	if is_instance_valid(dialogue_line):
		_progress.visible = (not _dialogue_label.is_typing and dialogue_line.responses.is_empty()
				and not dialogue_line.has_tag("voice"))
	_follow_the_hold(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not will_block_other_input:
		return
	for action: StringName in lets_through:
		if InputMap.has_action(action) and event.is_action(action):
			return
	get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if (what == NOTIFICATION_TRANSLATION_CHANGED and _locale != TranslationServer.get_locale()
			and is_instance_valid(_dialogue_label)):
		_locale = TranslationServer.get_locale()
		var visible_ratio: float = _dialogue_label.visible_ratio
		await dialogue_line.refresh()
		if visible_ratio < 1.0:
			_dialogue_label.skip_typing()


## Starts the lines of with_dialogue_resource at cue; with neither, those of the exported values.
func start(with_dialogue_resource: DialogueResource = null, cue: String = "",
		extra_game_states: Array = []) -> void:
	temporary_game_states = [self] + extra_game_states
	is_waiting_for_input = false
	if is_instance_valid(with_dialogue_resource):
		dialogue_resource = with_dialogue_resource
	if not cue.is_empty():
		start_from_cue = cue
	dialogue_line = await dialogue_resource.get_next_dialogue_line(start_from_cue, temporary_game_states)
	show()


## Goes to the line next_id.
func next(next_id: String) -> void:
	dialogue_line = await dialogue_resource.get_next_dialogue_line(next_id, temporary_game_states)


## Whether the speaker's name shows over the line.
func is_speaker_shown() -> bool:
	return _character_label.visible


## Whether the line on screen has answers to choose: then there is nothing to skip.
func is_at_a_choice() -> bool:
	return is_instance_valid(dialogue_line) and not dialogue_line.responses.is_empty()


## Runs through the lines up to the next one with answers, or to the end, and says how many went by.
## The mutations on the way run as they would have; no answer is ever chosen.
func skip_to_the_next_choice() -> void:
	if _skipping or not is_instance_valid(dialogue_line) or is_at_a_choice():
		return
	_skipping = true
	var line: DialogueLine = dialogue_line
	var skipped: int = 0
	while line != null and line.responses.is_empty():
		line = await dialogue_resource.get_next_dialogue_line(line.next_id, temporary_game_states)
		skipped += 1
	_skipping = false
	lines_skipped.emit(skipped)
	if _run_stats != null:
		_run_stats.record_skip(skipped)
	dialogue_line = line


## The portrait for speaker: their picture if there is one, or else the stand-in.
func show_portrait(speaker: String) -> void:
	var texture: Texture2D = portraits.get(speaker)
	_portrait.texture = texture
	_portrait.visible = texture != null
	_portrait_stand_in.visible = texture == null and not speaker.is_empty()
	_portrait_stand_in.color = _stand_in_color(speaker)
	_portrait_initial.text = speaker.left(1).to_upper()


func _stand_in_color(speaker: String) -> Color:
	if _progress_state != null and speaker == _progress_state.player_name:
		return player_portrait_color
	return portrait_colors.get(speaker, DEFAULT_PORTRAIT_COLOR)


func _follow_the_hold(delta: float) -> void:
	if not Input.is_action_pressed(next_action):
		_held = 0.0
		_hold_spent = false
		_skip_bar.hide()
		return
	if _hold_spent or _skipping or not is_instance_valid(dialogue_line) or is_at_a_choice():
		_skip_bar.hide()
		return
	_held += delta
	_skip_bar.visible = _held >= skip_bar_delay
	_skip_bar.value = clampf(_held / skip_hold_time, 0.0, 1.0)
	if _held >= skip_hold_time:
		_hold_spent = true
		_skip_bar.hide()
		skip_to_the_next_choice()


func _apply_dialogue_line() -> void:
	_mutation_cooldown.stop()
	_progress.hide()
	is_waiting_for_input = false
	_balloon.focus_mode = Control.FOCUS_ALL
	_balloon.grab_focus()
	_character_label.visible = not dialogue_line.character.is_empty()
	_character_label.text = tr(dialogue_line.character, "dialogue")
	show_portrait(dialogue_line.character)
	_dialogue_label.hide()
	_dialogue_label.dialogue_line = dialogue_line
	_responses_menu.hide()
	_responses_menu.responses = dialogue_line.responses
	_balloon.show()
	will_hide_balloon = false
	_dialogue_label.show()
	if not dialogue_line.text.is_empty():
		_dialogue_label.type_out()
		await _dialogue_label.finished_typing
	if dialogue_line.has_tag("voice"):
		_audio_stream_player.stream = load(dialogue_line.get_tag_value("voice"))
		_audio_stream_player.play()
		await _audio_stream_player.finished
		next(dialogue_line.next_id)
	elif not dialogue_line.responses.is_empty():
		_balloon.focus_mode = Control.FOCUS_NONE
		_responses_menu.show()
	elif dialogue_line.time != "":
		var time: float = (dialogue_line.text.length() * 0.02 if dialogue_line.time == "auto"
				else dialogue_line.time.to_float())
		await get_tree().create_timer(time).timeout
		next(dialogue_line.next_id)
	else:
		is_waiting_for_input = true
		_balloon.focus_mode = Control.FOCUS_ALL
		_balloon.grab_focus()


func _on_mutation_cooldown_timeout() -> void:
	if will_hide_balloon:
		will_hide_balloon = false
		_balloon.hide()


func _on_mutated(mutation: Dictionary) -> void:
	if not mutation.is_inline:
		is_waiting_for_input = false
		will_hide_balloon = true
		_mutation_cooldown.start(0.1)


func _on_balloon_gui_input(event: InputEvent) -> void:
	if _skipping:
		return
	if _dialogue_label.is_typing:
		var mouse_was_clicked: bool = (event is InputEventMouseButton
				and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT and event.is_pressed())
		if mouse_was_clicked or event.is_action_pressed(skip_action):
			get_viewport().set_input_as_handled()
			_dialogue_label.skip_typing()
			return
	if not is_waiting_for_input or is_at_a_choice():
		return
	get_viewport().set_input_as_handled()
	if (event is InputEventMouseButton and event.is_pressed()
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT):
		next(dialogue_line.next_id)
	elif event.is_action_pressed(next_action) and get_viewport().gui_get_focus_owner() == _balloon:
		next(dialogue_line.next_id)


func _on_responses_menu_response_selected(response: DialogueResponse) -> void:
	next(response.next_id)
