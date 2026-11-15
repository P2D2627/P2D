@tool
class_name MenuBackdrop
extends Control

## What lies behind a menu: a black background, rays of light from the top right corner, and the
## main character on the left, painted with its light and shade (menu_character.png). Seen in the
## editor too.

## How opaque the black background is: 1 on the main menu, less over the game when paused.
@export_range(0.0, 1.0, 0.05) var background_alpha: float = 1.0:
	set(value):
		background_alpha = value
		_apply()

@onready var _background: ColorRect = $Background


func _ready() -> void:
	_apply()


func _apply() -> void:
	if is_node_ready():
		_background.color = Color(0.0, 0.0, 0.0, background_alpha)
