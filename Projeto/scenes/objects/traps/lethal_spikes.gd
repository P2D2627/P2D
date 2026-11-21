@tool
class_name LethalSpikes
extends Area2D

## Spikes that kill the man at one touch, whatever his SP. With Catches on, they catch him instead
## (ADR 0067): his Snag slows him, stops his jumps and takes his SP fast, and he dies there when it
## runs out; out in time, he lives with what is left. Its origin is the middle of their base, on the
## floor, so a strip of any width sits on the tile grid when its width and position agree. Only the
## man is on its mask: demons walk over spikes unharmed. They are drawn as brambles, the Art drawing
## Brambles Per Tile times a tile, evenly spaced, as tall as the teeth and a little wider than a
## tile, so they join into one thick hedge over the part that kills, drawn in front of the man; with
## no Art, as teeth. In the game the brambles move by Motion Stats
## (#263): each tilts from its foot, with a small sway at rest, a shiver when the man comes at it,
## and a thrash and a lean in towards him when he dies on spikes near it. The part that kills never
## moves. A strip senses him within reach with an area of its own and works only while it is on
## screen, he is near or he died near it.

const BrambleMotion := preload("res://scenes/objects/traps/bramble_motion.gd")
const BrambleMotionStats := preload("res://scenes/objects/traps/bramble_motion_stats.gd")
const DEFAULT_MOTION: BrambleMotionStats = preload("res://scenes/objects/traps/bramble_motion_stats.tres")
const TILE: float = 48.0
## What a death on spikes is put down to, in the run's numbers.
const CAUSE: StringName = &"spikes"
## The group every strip joins in the game, so who must keep off them can find them, as Asmodeus.
const GROUP: StringName = &"lethal_spikes"
## Added to a strip's seed for its brambles' sway, so the sway's chance never changes their look.
const SWAY_SEED: int = 7919
## The man's body, which he is stirred and dies by.
const MAN_BODY_PATH: NodePath = ^"CollisionShape2D"

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
		_rebuild_brambles()
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
## The bramble drawn in place of the teeth; with none, the teeth are drawn.
@export var art: Texture2D:
	set(value):
		art = value
		_rebuild_brambles()
		queue_redraw()
## How much each bramble's height varies at random, as a share of Tooth Height. With the drawing as
## wide as it is, 0.1 keeps neighbours overlapping and the ends over the part that kills; more would
## leave gaps in the hedge, so it is the most it takes.
@export_range(0.0, 0.1, 0.01) var art_size_spread: float = 0.1:
	set(value):
		art_size_spread = value
		_rebuild_brambles()
		queue_redraw()
## How many brambles stand on each tile, on average: one per tile left the hedge thin (18/11), so
## half as many again. A strip has this times its width, rounded, at least one.
@export_range(1.0, 3.0, 0.25) var brambles_per_tile: float = 1.5:
	set(value):
		brambles_per_tile = value
		_rebuild_brambles()
		queue_redraw()
## How the brambles move; one resource for every strip.
@export var motion_stats: BrambleMotionStats = DEFAULT_MOTION

## The brambles as the game draws them, with how each moves; built in _ready(), and empty in the
## editor, which draws them anew each time.
var _brambles: Array[Bramble] = []
var _motion: BrambleMotion
## The strip's own clock, in s: it stops while the game is paused.
var _clock: float = 0.0
## The frame of the effects the brambles last moved on, -1 before the first.
var _moved_frame: int = -1
## The man while he is within the brambles' reach, and his body; null otherwise.
var _man: Player
var _man_body: CollisionShape2D
## Where he died on spikes near the strip, in its space, and the clock then; x is NAN until then.
var _death_at: Vector2 = Vector2(NAN, NAN)
var _death_clock: float = 0.0
## What senses him within reach, and what says whether the strip is on screen.
var _sense: Area2D
var _sense_shape: RectangleShape2D
var _on_screen: VisibleOnScreenNotifier2D

@onready var _shape: CollisionShape2D = %Shape


func _ready() -> void:
	_apply_size()
	if Engine.is_editor_hint():
		set_process(false)
		return
	assert(motion_stats != null, "LethalSpikes: assign a bramble motion resource to Motion Stats.")
	add_to_group(GROUP)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_set_up_motion()


## On each new frame of the effects, the brambles move, and are drawn again if they are seen.
func _process(delta: float) -> void:
	_clock += delta
	var frame: int = _motion.frame_of(_clock)
	if frame == _moved_frame:
		return
	var step: float = (frame - _moved_frame) / motion_stats.frame_rate if _moved_frame >= 0 else 0.0
	_moved_frame = frame
	var seen: bool = _on_screen.is_on_screen() and modulate.a > 0.0
	if not seen and _man == null and is_nan(_death_at.x):
		return
	_move_brambles(step)
	if seen:
		queue_redraw()


func _draw() -> void:
	if art == null:
		_draw_teeth()
		return
	var brambles: Array[Bramble] = _brambles if not _brambles.is_empty() else get_brambles()
	for bramble: Bramble in brambles:
		var middle := Vector2(bramble.rect.get_center().x, 0.0)
		draw_set_transform_matrix(BrambleMotion.tilt(middle, bramble.rect.size.y, bramble.mirrored,
				bramble.offset))
		draw_texture_rect(art, Rect2(bramble.rect.position - middle, bramble.rect.size), false)
	draw_set_transform(Vector2.ZERO)


## The brambles as the game draws them, each with its sway, its stir and how far its top is off now.
## Empty in the editor and before _ready().
func get_drawn_brambles() -> Array[Bramble]:
	return _brambles


## The strip's brambles from the left, in its own space, Brambles Per Tile to a tile and evenly
## spaced: each stands on the floor, Tooth Height tall give or take Art Size Spread, as wide as the
## drawing's shape makes it, and mirrored or not. The chance comes from the strip's position, so a
## strip looks the same every time it is built, and two strips differ. None with no Art.
func get_brambles() -> Array[Bramble]:
	var brambles: Array[Bramble] = []
	if art == null:
		return brambles
	var chance := RandomNumberGenerator.new()
	chance.seed = hash(Vector2i((global_position if is_inside_tree() else position).round()))
	var shape: float = float(art.get_width()) / float(art.get_height())
	var half_width: float = width_tiles * TILE / 2.0
	var count: int = maxi(roundi(width_tiles * brambles_per_tile), 1)
	var spacing: float = 2.0 * half_width / count
	for slot: int in count:
		var height: float = tooth_height * (1.0 + chance.randf_range(-art_size_spread, art_size_spread))
		var middle: float = -half_width + (slot + 0.5) * spacing
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
		return
	# A man something else killed can still fall in: the brambles do not kill him a second time. Nor
	# do they catch one die() leaves alive, as in god mode, a debug cheat (#273).
	var was_dead: bool = player.is_dead()
	player.die(CAUSE, name)
	if player.is_dead() and not was_dead and player.bramble_death != null:
		# Up, away from the brambles: the strip's own up, turned with it; his feet's height above
		# the ground they grow from, along it.
		var up: Vector2 = -global_transform.y.normalized()
		player.bramble_death.catch(up, maxf((player.global_position - global_position).dot(up), 0.0))


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
	_rebuild_brambles()
	queue_redraw()


## The area that senses the man within the brambles' reach and the notice of being on screen, both
## sized by _rebuild_brambles().
func _set_up_motion() -> void:
	_motion = BrambleMotion.new(motion_stats)
	_sense = Area2D.new()
	_sense.collision_layer = 0
	_sense.collision_mask = collision_mask
	_sense.monitorable = false
	_sense_shape = RectangleShape2D.new()
	var sense_shape := CollisionShape2D.new()
	sense_shape.shape = _sense_shape
	_sense.add_child(sense_shape)
	add_child(_sense, false, INTERNAL_MODE_BACK)
	_sense.body_entered.connect(_on_man_near)
	_sense.body_exited.connect(_on_man_gone)
	_on_screen = VisibleOnScreenNotifier2D.new()
	add_child(_on_screen, false, INTERNAL_MODE_BACK)
	_rebuild_brambles()


## In the game, builds the brambles again, each with a sway of its own from the strip's position, and
## fits the sensing area and the on-screen notice to them. Nothing in the editor or before _ready().
func _rebuild_brambles() -> void:
	if _motion == null:
		return
	_brambles = get_brambles()
	var chance := RandomNumberGenerator.new()
	chance.seed = hash(Vector2i(global_position.round())) + SWAY_SEED
	for bramble: Bramble in _brambles:
		bramble.sway_period = chance.randf_range(motion_stats.sway_period_min, motion_stats.sway_period_max)
		bramble.sway_start = chance.randf()
	var half_width: float = width_tiles * TILE / 2.0
	var tallest: float = tooth_height * (1.0 + art_size_spread)
	var reach: float = maxf(motion_stats.stir_radius, motion_stats.thrash_radius)
	_sense_shape.size = Vector2(2.0 * (half_width + reach), tallest + 2.0 * reach)
	(_sense.get_child(0) as CollisionShape2D).position = Vector2(0.0, -tallest / 2.0)
	# Brambles are a little wider than a tile and lean a few px: a tile around covers both.
	_on_screen.rect = Rect2(-half_width - TILE, -tallest - TILE, 2.0 * (half_width + TILE), tallest + TILE)
	set_process(not _brambles.is_empty())


## Each bramble's top: its sway, plus the man's stir while he comes at it, plus, after his death on
## spikes near the strip, the thrash and the lean in. Step is the time since they last moved.
func _move_brambles(step: float) -> void:
	var man_here: bool = is_instance_valid(_man) and not _man.is_dead()
	var body: Rect2 = _man_body_rect() if man_here else Rect2()
	var velocity: Vector2 = _man.velocity if man_here else Vector2.ZERO
	var to_world: Transform2D = get_global_transform()
	var died: bool = not is_nan(_death_at.x)
	var since: float = _clock - _death_clock
	for index: int in _brambles.size():
		var bramble: Bramble = _brambles[index]
		var target: float = _motion.stir_target(to_world * bramble.get_top(), body, velocity) \
				if man_here else 0.0
		bramble.stir = _motion.stir_after(bramble.stir, target, step)
		var offset: float = _motion.sway(_clock, bramble.sway_period, bramble.sway_start) \
				+ _motion.shiver(bramble.stir, index, _clock)
		if died:
			var foot := Vector2(bramble.rect.get_center().x, 0.0)
			offset += _motion.thrash(foot, _death_at, since, index) + _motion.lean(foot, _death_at, since)
		bramble.offset = offset


## The man came within reach: the brambles follow him and hear of his death.
func _on_man_near(body: Node2D) -> void:
	var player: Player = body as Player
	if player == null or player == _man:
		return
	_forget_the_man()
	_man = player
	_man_body = player.get_node_or_null(MAN_BODY_PATH) as CollisionShape2D
	_man.died.connect(_on_man_died)


func _on_man_gone(body: Node2D) -> void:
	if body == _man:
		_forget_the_man()


func _forget_the_man() -> void:
	if is_instance_valid(_man) and _man.died.is_connected(_on_man_died):
		_man.died.disconnect(_on_man_died)
	_man = null
	_man_body = null


## His death on spikes, these or others, is where the brambles near it thrash and lean in: the point
## of his body nearest the strip's foot, in its space. A death by anything else moves nothing.
func _on_man_died() -> void:
	if not is_instance_valid(_man) or _man.get_death_cause() != CAUSE:
		return
	var body: Rect2 = get_global_transform().affine_inverse() * _man_body_rect()
	var half_width: float = width_tiles * TILE / 2.0
	_death_at = Vector2(clampf(body.get_center().x, -half_width, half_width),
			clampf(0.0, body.position.y, body.end.y))
	_death_clock = _clock


## The man's body in the world, or a point where he stands if it is not a rectangle.
func _man_body_rect() -> Rect2:
	var shape: RectangleShape2D = _man_body.shape as RectangleShape2D if _man_body != null else null
	if shape == null:
		return Rect2(_man.global_position, Vector2.ZERO)
	return Rect2(_man_body.global_position - shape.size / 2.0, shape.size)


## One bramble of a strip, in the strip's space: where the drawing goes, whether it is mirrored and,
## in the game, how it moves.
class Bramble:
	var rect: Rect2
	var mirrored: bool
	## Its sway at rest: the seconds one sway takes, and where in it the bramble starts, 0 to 1.
	var sway_period: float = 0.0
	var sway_start: float = 0.0
	## How much the man stirs it now, 0 to 1.
	var stir: float = 0.0
	## How far its top is now from where it is at rest, in px along the strip.
	var offset: float = 0.0

	func _init(at: Rect2, flipped: bool) -> void:
		rect = at
		mirrored = flipped

	## The middle of its top, in the strip's space.
	func get_top() -> Vector2:
		return Vector2(rect.get_center().x, rect.position.y)
