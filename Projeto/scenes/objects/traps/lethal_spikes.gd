@tool
class_name LethalSpikes
extends Area2D

## Spikes that kill the man at one touch, whatever his SP. With Catches on, they catch him instead
## (ADR 0067): his Snag slows him, stops his jumps and takes his SP fast, and he dies there when it
## runs out; out in time, he lives with what is left. Its origin is the middle of their base, on the
## floor, so a strip of any width sits on the tile grid when its width and position agree. Only the
## man is on its mask: demons walk over spikes unharmed. They are drawn as brambles, the Art drawing
## once per tile, as tall as the teeth and a little wider than a tile, so they join into one hedge
## over the part that kills; with no Art, as teeth.

const TILE: float = 48.0
## What a death on spikes is put down to, in the run's numbers.
const CAUSE: StringName = &"spikes"

## Off: a touch kills at once. On: the man's Snag catches him and he dies once his SP runs out in
## them (ADR 0067). Tried and set aside on 17/11, so off; the code stays to compare.
@export var catches: bool = false
## How wide the strip is, in tiles.
@export_range(1, 128) var width_tiles: int = 2:
	set(value):
		width_tiles = value
		_apply_size()
## How many teeth each tile has, when there is no Art.
@export_range(1, 4) var teeth_per_tile: int = 2:
	set(value):
		teeth_per_tile = value
		queue_redraw()
## How tall the spikes are drawn, in px: the teeth, or each bramble on average.
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
## The teeth's colour, when there is no Art.
@export var color: Color = Color(0.48, 0.17, 0.85):
	set(value):
		color = value
		queue_redraw()
## The bramble drawn once per tile in place of the teeth; with none, the teeth are drawn.
@export var art: Texture2D:
	set(value):
		art = value
		queue_redraw()
## How much each bramble's height varies at random, as a share of Tooth Height. With the drawing as
## wide as it is, 0.1 keeps neighbours overlapping and the ends over the part that kills; more would
## leave gaps in the hedge, so it is the most it takes.
@export_range(0.0, 0.1, 0.01) var art_size_spread: float = 0.1:
	set(value):
		art_size_spread = value
		queue_redraw()

@onready var _shape: CollisionShape2D = %Shape


func _ready() -> void:
	_apply_size()
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)


func _draw() -> void:
	if art == null:
		_draw_teeth()
		return
	for bramble: Bramble in get_brambles():
		var middle := Vector2(bramble.rect.get_center().x, 0.0)
		draw_set_transform(middle, 0.0, Vector2(-1.0 if bramble.mirrored else 1.0, 1.0))
		draw_texture_rect(art, Rect2(bramble.rect.position - middle, bramble.rect.size), false)
	draw_set_transform(Vector2.ZERO)


## The strip's brambles, one per tile from the left, in its own space: each stands on the floor,
## Tooth Height tall give or take Art Size Spread, as wide as the drawing's shape makes it, and
## mirrored or not. The chance comes from the strip's position, so a strip looks the same every time
## it is built, and two strips differ. None with no Art.
func get_brambles() -> Array[Bramble]:
	var brambles: Array[Bramble] = []
	if art == null:
		return brambles
	var chance := RandomNumberGenerator.new()
	chance.seed = hash(Vector2i((global_position if is_inside_tree() else position).round()))
	var shape: float = float(art.get_width()) / float(art.get_height())
	var half_width: float = width_tiles * TILE / 2.0
	for tile: int in width_tiles:
		var height: float = tooth_height * (1.0 + chance.randf_range(-art_size_spread, art_size_spread))
		var middle: float = -half_width + (tile + 0.5) * TILE
		var rect := Rect2(middle - height * shape / 2.0, -height, height * shape, height)
		brambles.append(Bramble.new(rect, chance.randf() < 0.5))
	return brambles


func _draw_teeth() -> void:
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
	if player == null:
		return
	# Each strip counts as its own spot: one jump is harder than another.
	if catches and player.snag != null:
		player.snag.catch(self, CAUSE)
	else:
		player.die(CAUSE, name)


func _on_body_exited(body: Node2D) -> void:
	var player: Player = body as Player
	# Always: Catches turned off while he is in them must still let him go.
	if player != null and player.snag != null:
		player.snag.release(self)


func _apply_size() -> void:
	if not is_node_ready():
		return
	var rectangle: RectangleShape2D = _shape.shape as RectangleShape2D
	rectangle.size = Vector2(maxf(width_tiles * TILE - 2.0 * side_inset, 1.0), hit_height)
	_shape.position = Vector2(0.0, -hit_height / 2.0)
	queue_redraw()


## One bramble of a strip, in the strip's space: where the drawing goes and whether it is mirrored.
class Bramble:
	var rect: Rect2
	var mirrored: bool

	func _init(at: Rect2, flipped: bool) -> void:
		rect = at
		mirrored = flipped
