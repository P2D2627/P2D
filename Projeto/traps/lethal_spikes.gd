@tool
class_name LethalSpikes
extends Area2D

## Spikes that kill the man at one touch, whatever his SP. Its origin is the middle of their base, on
## the floor, so a strip of any width sits on the tile grid when its width and position agree. Only the
## man is on its mask: demons walk over spikes unharmed. For now they are drawn teeth, until the art
## arrives.

const TILE: float = 48.0

## How wide the strip is, in tiles.
@export_range(1, 128) var width_tiles: int = 2:
	set(value):
		width_tiles = value
		_apply_size()
## How many teeth each tile has.
@export_range(1, 4) var teeth_per_tile: int = 2:
	set(value):
		teeth_per_tile = value
		queue_redraw()
## How tall the teeth are drawn, in px.
@export_range(8.0, 96.0, 1.0, "suffix:px") var tooth_height: float = 40.0:
	set(value):
		tooth_height = value
		queue_redraw()
## How tall the part that kills is, in px: lower than the teeth, so a jump that clears them by eye
## clears them for real.
@export_range(4.0, 96.0, 1.0, "suffix:px") var hit_height: float = 24.0:
	set(value):
		hit_height = value
		_apply_size()
## How far inside each end the part that kills starts, in px, for the same reason.
@export_range(0.0, 24.0, 1.0, "suffix:px") var side_inset: float = 4.0:
	set(value):
		side_inset = value
		_apply_size()
## Their colour until the art arrives.
@export var color: Color = Color(0.48, 0.17, 0.85):
	set(value):
		color = value
		queue_redraw()

@onready var _shape: CollisionShape2D = %Shape


func _ready() -> void:
	_apply_size()
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)


func _draw() -> void:
	var half_width: float = width_tiles * TILE / 2.0
	var tooth_width: float = TILE / teeth_per_tile
	var teeth: PackedVector2Array = PackedVector2Array([Vector2(-half_width, 0.0)])
	for tooth: int in width_tiles * teeth_per_tile:
		var left: float = -half_width + tooth * tooth_width
		teeth.append(Vector2(left + tooth_width / 2.0, -tooth_height))
		teeth.append(Vector2(left + tooth_width, 0.0))
	draw_colored_polygon(teeth, color)


func _on_body_entered(body: Node2D) -> void:
	var player: Player = body as Player
	if player != null:
		player.die()


func _apply_size() -> void:
	if not is_node_ready():
		return
	var rectangle: RectangleShape2D = _shape.shape as RectangleShape2D
	rectangle.size = Vector2(maxf(width_tiles * TILE - 2.0 * side_inset, 1.0), hit_height)
	_shape.position = Vector2(0.0, -hit_height / 2.0)
	queue_redraw()
