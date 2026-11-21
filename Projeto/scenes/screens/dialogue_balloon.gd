class_name DialogueBalloon
extends CanvasLayer

## The game's dialogue balloon, made from Dialogue Manager's example balloon, as the plugin asks, so
## the addon stays as it came. The box hangs at the top of the screen, with who speaks in its
## vignette: the demons on the right, the man on the left, the whole box mirrored. A portrait taller
## than the vignette breaks out of it at the top, its head drawn over the frame. Without a picture,
## a stand-in of the speaker's colour and initial holds the vignette. The answers show under the box
## in the DialogueWheel. Holding Next Action for Skip Hold Time runs through the lines up to the
## next one with answers, or to the end, without ever answering for him. The skipped lines still do
## what they do (an offer presented, an event marked), only unseen. How many lines he skipped goes
## to RunStats; it counts for the judgment's numbers, never for the moral record. While it talks,
## what is in the group Hidden During Dialogue, as the soul bar under the box, hides. It frees
## itself after the last line.

## He held the key long enough and count lines went by unseen.
signal lines_skipped(count: int)

## A Color for the stand-in portrait of a speaker the Portrait Colors do not name.
const DEFAULT_PORTRAIT_COLOR: Color = Color(0.35, 0.35, 0.4)
## What hides while the balloon talks: whatever the box would cover.
const HIDDEN_DURING_DIALOGUE: StringName = &"hidden_during_dialogue"
## The width the layout is drawn for, which the box mirrors across.
const STAGE_WIDTH: float = 1920.0

@export var dialogue_resource: DialogueResource
## Where the lines start when it starts on its own, with Auto Start.
@export var start_from_cue: String = ""
@export var auto_start: bool = false
## Whether nothing else gets the input while the balloon shows, but for Lets Through.
@export var will_block_other_input: bool = true
## The actions that still reach the rest of the game while the balloon shows: the pause, so a talk
## can be paused, and the debug keys.
@export var lets_through: Array[StringName] = [&"pause", &"toggle_debug_overlay", &"debug_damage",
		&"debug_god_mode", &"debug_noclip", &"debug_accept_offer", &"debug_refuse_offer",
		&"debug_reset_run", &"debug_phase_1", &"debug_phase_2", &"debug_phase_3", &"debug_camera_next"]
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
## The man's portrait, whatever name he was given; empty gives him a stand-in.
@export var player_portrait: Texture2D
## Whether the man's portrait looks to the left as drawn.
@export var player_portrait_faces_left: bool = true
## The speakers whose portraits look to the left as drawn; the rest look to the right. Each picture
## is mirrored as needed to look towards the text.
@export var portraits_facing_left: Array[String] = []
## The stand-in portrait's colour for the man, whatever name he was given.
@export var player_portrait_color: Color = Color(0.55, 0.45, 0.3)
## Whether the answer he picks is then written in the box as his line, before the lines go on.
@export var write_the_answer: bool = true
@export_group("Text")
## The size the lines are written in, when they fit the box.
@export_range(16, 48, 1, "suffix:px") var max_text_size: int = 34
## The smallest a long line may shrink to, so it still fits the box.
@export_range(16, 48, 1, "suffix:px") var min_text_size: int = 26

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
				_hide_others(false)
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

## The x each mirrored part has with the speaker on the right, as laid out in the scene.
var _right_x: Dictionary[Control, float] = {}
## How far the arrow that asks for the next line sits from the text's right end; it stays at the end
## of the text on either side, away from the vignette.
var _next_inset: float = 0.0
var _on_left: bool = false

@onready var _balloon: Control = %Balloon
@onready var _box: TextureRect = %Box
@onready var _vignette: Control = %Vignette
@onready var _pop_out: Control = %PopOut
@onready var _text_area: Control = %TextArea
@onready var _next: Control = %Next
@onready var _character_label: RichTextLabel = %CharacterLabel
@onready var _dialogue_label: DialogueLabel = %DialogueLabel
@onready var _wheel: DialogueWheel = %Wheel
@onready var _progress: CanvasItem = %Progress
@onready var _audio_stream_player: AudioStreamPlayer = %AudioStreamPlayer
@onready var _portrait: TextureRect = %Portrait
@onready var _portrait_pop: TextureRect = %PortraitPop
@onready var _portrait_stand_in: ColorRect = %PortraitStandIn
@onready var _portrait_initial: Label = %PortraitInitial
## The small bar beside the arrow that fills while Next Action is held.
@onready var _skip_bar: ProgressBar = %SkipBar
@onready var _progress_state: GameProgress = get_node_or_null(^"/root/GameState") as GameProgress
@onready var _run_stats: GameRunStats = get_node_or_null(^"/root/RunStats") as GameRunStats


func _ready() -> void:
	_balloon.hide()
	_skip_bar.hide()
	_wheel.hide()
	# The scene's sample text and initial never show: a talk that opens on answers alone has no line
	# before them to keep.
	_character_label.hide()
	_dialogue_label.text = ""
	_portrait_stand_in.hide()
	for part: Control in [_box, _vignette, _pop_out, _text_area]:
		_right_x[part] = part.position.x
	_next_inset = _text_area.position.x + _text_area.size.x - _next.position.x
	Engine.get_singleton("DialogueManager").mutated.connect(_on_mutated)
	_wheel.next_action = next_action
	tree_exiting.connect(_hide_others.bind(false))
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
	_hide_others(true)
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


## The portrait for speaker: their picture if there is one, or else the stand-in. The part of the
## picture above the vignette shows over the frame.
func show_portrait(speaker: String) -> void:
	var texture: Texture2D = player_portrait if is_player_speaking(speaker) else portraits.get(speaker)
	var faces_left: bool = (player_portrait_faces_left if is_player_speaking(speaker)
			else portraits_facing_left.has(speaker))
	# The text is on the right of a vignette on the left, and the other way round.
	var flip: bool = faces_left == _on_left
	for picture: TextureRect in [_portrait, _portrait_pop]:
		picture.texture = texture
		picture.visible = texture != null
		picture.flip_h = flip
	_portrait_stand_in.visible = texture == null and not speaker.is_empty()
	_portrait_stand_in.color = _stand_in_color(speaker)
	_portrait_initial.text = speaker.left(1).to_upper()


## Whether speaker is the man: his lines carry the name he typed, or none before he has typed it.
func is_player_speaking(speaker: String) -> bool:
	return speaker.is_empty() or (_progress_state != null and speaker == _progress_state.player_name)


## Whether the box is mirrored, with the vignette on the left, as when the man speaks.
func is_on_left() -> bool:
	return _on_left


func _stand_in_color(speaker: String) -> Color:
	if _progress_state != null and speaker == _progress_state.player_name:
		return player_portrait_color
	return portrait_colors.get(speaker, DEFAULT_PORTRAIT_COLOR)


## Puts the vignette on the left, the box mirrored, or back on the right as laid out in the scene.
func _place_side(on_left: bool) -> void:
	_on_left = on_left
	_box.flip_h = on_left
	(_vignette.get_child(0) as TextureRect).flip_h = on_left
	for part: Control in _right_x:
		var x: float = _right_x[part]
		part.position.x = STAGE_WIDTH - x - part.size.x if on_left else x
	_next.position.x = _text_area.position.x + _text_area.size.x - _next_inset


## Hides, or shows again, what the box would cover, as the soul bar.
func _hide_others(hidden: bool) -> void:
	if is_inside_tree():
		get_tree().call_group(HIDDEN_DURING_DIALOGUE, &"set_visible", not hidden)


## Whether the line only brings answers, with no speaker and no text: the lines before stay on show.
func _only_answers(line: DialogueLine) -> bool:
	return line.character.is_empty() and line.text.is_empty() and not line.responses.is_empty()


## Writes the line as large as fits the box, from Max Text Size down to Min Text Size.
func _fit_text() -> void:
	var plain: String = _strip_bbcode(dialogue_line.text)
	var font: Font = _dialogue_label.get_theme_font(&"normal_font")
	var width: float = _text_area.size.x
	var name_height: float = (_character_label.get_content_height() if _character_label.visible else 0.0)
	var room: float = _text_area.size.y - name_height - _text_area.get_theme_constant(&"separation")
	var size: int = max_text_size
	while size > min_text_size and font.get_multiline_string_size(plain, HORIZONTAL_ALIGNMENT_LEFT, width,
			size).y > room:
		size -= 1
	_dialogue_label.add_theme_font_size_override(&"normal_font_size", size)
	_dialogue_label.add_theme_font_size_override(&"italics_font_size", size)
	_dialogue_label.add_theme_font_size_override(&"bold_font_size", size)


static func _strip_bbcode(text: String) -> String:
	var tags: RegEx = RegEx.create_from_string("\\[[^\\]]*\\]")
	return tags.sub(text, "", true)


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
	if not _only_answers(dialogue_line):
		_character_label.visible = not dialogue_line.character.is_empty()
		_character_label.text = tr(dialogue_line.character, "dialogue")
		_place_side(is_player_speaking(dialogue_line.character))
		show_portrait(dialogue_line.character)
		_dialogue_label.hide()
		_fit_text()
		_dialogue_label.dialogue_line = dialogue_line
	_wheel.hide()
	_wheel.responses = dialogue_line.responses
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
		_wheel.show()
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


## Goes on from the answer he picked: first, with Write The Answer, his line saying it, in the box
## as any other; the lines after the answer come once he moves on from it.
func _on_responses_menu_response_selected(response: DialogueResponse) -> void:
	if not write_the_answer:
		next(response.next_id)
		return
	var speaker: String = _progress_state.player_name if _progress_state != null else ""
	dialogue_line = DialogueLine.new({
		id = response.id, next_id = response.next_id, type = DMConstants.TYPE_DIALOGUE,
		character = speaker, text = response.text,
	})
