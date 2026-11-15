class_name TutorialHints
extends Node2D

## The tutorial's node: it hides each of its hints once the man is past it. A hint is a plain Node2D
## child, with no script, holding at least one KeyPrompt: the key and its caption together. Once the
## man is Hide Margin to the right of it, it fades out and stays hidden, even if he walks back. Other
## children, such as Velvet, who shows her own key, or the markers, are left alone. With every hint
## hidden, it stops checking.

## The man whose position it follows.
@export var player: Node2D
## How far to the right of a hint the man has to be for it to hide, in px.
@export_range(0.0, 2000.0, 10.0, "suffix:px") var hide_margin: float = 300.0
## How long a hint takes to fade out, in s.
@export_range(0.0, 3.0, 0.05, "suffix:s") var fade_time: float = 0.4

var _shown: Array[Node2D] = []


func _ready() -> void:
	for child: Node in get_children():
		# A child with a script of its own, such as Velvet, shows its keys itself.
		if child is Node2D and child.get_script() == null and _has_key_prompt(child):
			_shown.append(child as Node2D)
	set_physics_process(player != null and not _shown.is_empty())


func _physics_process(_delta: float) -> void:
	var player_x: float = player.global_position.x
	# Backwards, so that hiding one does not skip the next.
	for i: int in range(_shown.size() - 1, -1, -1):
		if player_x > _shown[i].global_position.x + hide_margin:
			_hide(_shown[i])
	if _shown.is_empty():
		set_physics_process(false)


## The hints still showing.
func get_shown() -> Array[Node2D]:
	return _shown.duplicate()


func _hide(hint: Node2D) -> void:
	_shown.erase(hint)
	var tween: Tween = hint.create_tween()
	tween.tween_property(hint, ^"modulate:a", 0.0, fade_time)
	tween.tween_callback(hint.hide)


static func _has_key_prompt(node: Node) -> bool:
	for child: Node in node.get_children():
		if child is KeyPrompt:
			return true
	return false
