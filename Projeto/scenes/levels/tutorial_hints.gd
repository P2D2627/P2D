class_name TutorialHints
extends Node2D

## The tutorial's node: it hides each of its hints once the man is past it. A hint is a plain Node2D
## child, with no script, holding at least one KeyPrompt and the Labels of its caption. Once the man
## is Hide Margin to the right of it, it fades out and stays hidden, even if he walks back. Other
## children, such as Velvet, who shows her own key, or the markers, are left alone. With every hint
## hidden, it stops checking.
## With a Band, the hints are not drawn in the world but in the band at the bottom of the screen, one
## at a time: the leftmost hint whose first key the camera sees and that the man has not passed. Each
## stays at least Min Show Time, even once he is past it, so a quick run does not flash it, and the
## band empties when no hint is on screen. While Velvet talks the band hides, so it never sits under
## her balloon.

## The man whose position it follows.
@export var player: Node2D
## How far to the right of a hint the man has to be for it to hide, in px.
@export_range(0.0, 2000.0, 10.0, "suffix:px") var hide_margin: float = 300.0
## How long a hint takes to fade out, in s.
@export_range(0.0, 3.0, 0.05, "suffix:s") var fade_time: float = 0.4
## The band at the bottom of the screen the hints show in; with none, they show in the world.
@export var band: PromptBand
## With a band, the least time a hint stays in it, in s: a guess, to check in a playtest.
@export_range(0.0, 10.0, 0.1, "suffix:s") var min_show_time: float = 2.0

## The hints the man has not passed, from left to right.
var _shown: Array[Node2D] = []
## Each hint's first key, where the band looks for it on screen.
var _first_keys: Dictionary[Node2D, KeyPrompt] = {}
## The hint in the band; null with none.
var _band_hint: Node2D = null
## Seconds the band has shown its hint.
var _band_time: float = 0.0


func _ready() -> void:
	for child: Node in get_children():
		# A child with a script of its own, such as Velvet, shows its keys itself.
		if child is Node2D and child.get_script() == null and _has_key_prompt(child):
			_shown.append(child as Node2D)
	_shown.sort_custom(func(a: Node2D, b: Node2D) -> bool:
			return a.global_position.x < b.global_position.x)
	if band != null:
		assert(player != null, "TutorialHints: a Band needs the Player, or no hint ever shows.")
		for hint: Node2D in _shown:
			hint.hide()
			_first_keys[hint] = _first_key_of(hint)
		for child: Node in get_children():
			var demon: TutorialDemon = child as TutorialDemon
			if demon != null:
				demon.talk_started.connect(band.set_held.bind(true))
				demon.talk_ended.connect(band.set_held.bind(false))
	set_physics_process(player != null and not _shown.is_empty())


func _physics_process(delta: float) -> void:
	var player_x: float = player.global_position.x
	# Backwards, so that hiding one does not skip the next.
	for i: int in range(_shown.size() - 1, -1, -1):
		if player_x > _shown[i].global_position.x + hide_margin:
			_hide(_shown[i])
	if band != null:
		_update_band(delta)
	if _shown.is_empty() and _band_hint == null:
		set_physics_process(false)


## The hints the man has not passed yet, from left to right.
func get_shown() -> Array[Node2D]:
	return _shown.duplicate()


## Puts in the band the leftmost hint on screen, once the one there has had Min Show Time.
func _update_band(delta: float) -> void:
	_band_time += delta
	var next: Node2D = _first_on_screen()
	if next == _band_hint or (_band_hint != null and _band_time < min_show_time):
		return
	_band_hint = next
	_band_time = 0.0
	if next == null:
		band.clear()
	else:
		band.show_hint(_actions_of(next), _caption_of(next))


## The leftmost hint not passed whose first key is inside the camera's view; null with none.
func _first_on_screen() -> Node2D:
	var view: Rect2 = get_canvas_transform().affine_inverse() * get_viewport_rect()
	for hint: Node2D in _shown:
		if view.has_point(_first_keys[hint].global_position):
			return hint
	return null


func _hide(hint: Node2D) -> void:
	_shown.erase(hint)
	if band != null:
		return
	var tween: Tween = hint.create_tween()
	tween.tween_property(hint, ^"modulate:a", 0.0, fade_time)
	tween.tween_callback(hint.hide)


static func _has_key_prompt(node: Node) -> bool:
	return _first_key_of(node) != null


static func _first_key_of(node: Node) -> KeyPrompt:
	for child: Node in node.get_children():
		var key: KeyPrompt = child as KeyPrompt
		if key != null:
			return key
	return null


## The actions of a hint's keys, in the order of its children.
static func _actions_of(hint: Node2D) -> Array[StringName]:
	var actions: Array[StringName] = []
	for child: Node in hint.get_children():
		var key: KeyPrompt = child as KeyPrompt
		if key != null:
			actions.append(key.action)
	return actions


## A hint's caption on one line: its Labels in the order of its children, line breaks as spaces.
static func _caption_of(hint: Node2D) -> String:
	var lines: PackedStringArray = []
	for child: Node in hint.get_children():
		var label: Label = child as Label
		if label != null:
			lines.append(label.text.replace("\n", " "))
	return " ".join(lines)
