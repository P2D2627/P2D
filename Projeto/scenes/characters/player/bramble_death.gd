extends Node

## What brambles do to the man as they kill him (#263). They catch him where he touched them: he
## stops there, in the air too. The game freezes for Hitstop while his drawing flashes white. Then,
## with Pulled In on (the default), the hedge pulls him in (BramblePull): on a floor hedge he goes
## under until the screen goes dark, cut at his feet as in a demon's grab, so what goes below the
## floor is behind its rock (with Pull Clips off, he is pulled down Pull Depth whole, drawn over the
## rock and behind the hedge); by a wall or a ceiling he is pulled into the hedge and stays. With
## Vines, thorny vines grow out of the hedge and wrap round him, the parts that go under with him no
## longer drawn; with Jerk Px he jerks. All on the frames of the effects. The vines are made only at
## such a death.
## With Cut Apart on, which goes first, the thorns' slashes cross him during the freeze, and when it
## ends his drawing gives way to pieces of the frame he died on, cut along the slashes (BrambleCut):
## they fly, the top one the way he faces (away from a wall hedge), fall to the floor under him,
## rest and fade into the ink. With both off, he buckles and slumps into them, held to the frame of
## the effects: on a floor hedge he tilts the way he faces and sinks into it, on a wall or a ceiling
## he tilts into it and does not sink. Lethal spikes call catch() as they kill him, which is the one
## way in. The freeze ends on time even with the game paused, and if this node leaves the tree while
## frozen the game's time comes back. The pull and the pose write his sink on each frame, so a sink
## from elsewhere, as a grab's, gives way to them. In the pose, on a floor hedge he sinks only until
## his feet reach the floor it grows from, so walking into it he does not sink at all, and on a wall
## he tilts less (Wall Tilt), so his head stays out of the hedge.

const BrambleDeathPose := preload("res://scenes/characters/player/bramble_death_pose.gd")
const BrambleDeathStats := preload("res://scenes/characters/player/bramble_death_stats.gd")
const BrambleCut := preload("res://scenes/characters/player/bramble_cut.gd")
const BramblePull := preload("res://scenes/characters/player/bramble_pull.gd")
const PIECE_SHADER: Shader = preload("res://scenes/others/shaders/bramble_cut_piece.gdshader")
## A hedge whose up points within this of straight up is a floor; across, a wall.
const FLOOR_UP: float = 0.5
## His body, whose box the slashes are spaced along and whose middle looks for the floor.
const MAN_BODY_PATH := ^"CollisionShape2D"
## The slashes are drawn above the hedge (z 1), the pieces where his drawing was (z 0), behind it.
const SLASH_Z: int = 2
## The most slashes the pieces' shader takes.
const MAX_CUTS: int = 4
## His body's box, from his feet, when the player has no box to read it from.
const FALLBACK_BODY := Rect2(-24.0, -96.0, 48.0, 96.0)
## A vine's leaf is this much as wide as it is long.
const LEAF_WIDTH_SHARE: float = 0.45


## The thorns' slashes across him, drawn in the world: a glow and a bright core along each.
class SlashDrawing:
	extends Node2D

	var points: PackedVector2Array = PackedVector2Array()
	var angles: PackedFloat32Array = PackedFloat32Array()
	## Each slash's slide along itself, as a share of its length.
	var shifts: PackedFloat32Array = PackedFloat32Array()
	var length: float = 0.0
	var strength: float = 1.0
	var stats: BrambleDeathStats

	func _draw() -> void:
		var glow: Color = stats.slash_glow_colour
		glow.a *= strength
		var core: Color = stats.slash_core_colour
		core.a *= strength
		for i: int in points.size():
			var along: Vector2 = Vector2.from_angle(angles[i])
			var middle: Vector2 = points[i] + along * shifts[i] * length
			var half: Vector2 = along * length / 2.0
			draw_line(middle - half, middle + half, glow, stats.slash_glow_width)
			draw_line(middle - half, middle + half, core, stats.slash_core_width)


## The vines round him, drawn in the world: each an inked stem with thorns, one side then the other,
## and leaves on the half nearer the hedge.
class VineDrawing:
	extends Node2D

	## Each vine's line as it shows now, and its whole length's leaves.
	var lines: Array[PackedVector2Array] = []
	var leaves: Array[PackedFloat32Array] = []
	## Each vine's whole length, so its leaves stay where they grew as it goes under.
	var lengths: PackedFloat32Array = PackedFloat32Array()
	var stats: BrambleDeathStats

	func _draw() -> void:
		for k: int in lines.size():
			var line: PackedVector2Array = lines[k]
			if line.size() < 2:
				continue
			draw_polyline(line, stats.ink, stats.vine_width + 2.0 * stats.vine_ink_width)
			draw_polyline(line, stats.vine_colour, stats.vine_width)
			_draw_along(line, k)

	## Thorns every Thorn Spacing px, and the leaves at their shares of the whole length.
	func _draw_along(line: PackedVector2Array, k: int) -> void:
		var walked: float = 0.0
		var next_thorn: float = stats.thorn_spacing / 2.0
		var thorn: int = 0
		for i: int in range(1, line.size()):
			var a: Vector2 = line[i - 1]
			var b: Vector2 = line[i]
			var step: float = a.distance_to(b)
			if step <= 0.0:
				continue
			var along: Vector2 = (b - a) / step
			var out := Vector2(-along.y, along.x)
			while next_thorn <= walked + step:
				var at: Vector2 = a + along * (next_thorn - walked)
				var side: float = 1.0 if thorn % 2 == 0 else -1.0
				var base: Vector2 = at + out * side * stats.vine_width / 2.0
				draw_colored_polygon(PackedVector2Array([base - along * stats.thorn_size / 2.0,
						base + along * stats.thorn_size / 2.0,
						base + out * side * stats.thorn_size + along * stats.thorn_size / 2.0]), stats.ink)
				thorn += 1
				next_thorn += stats.thorn_spacing
			for share: float in leaves[k]:
				var leaf_at: float = share * lengths[k]
				if leaf_at >= walked and leaf_at < walked + step:
					var middle: Vector2 = a + along * (leaf_at - walked) + out * stats.leaf_size
					var long: Vector2 = (along + out).normalized() * stats.leaf_size
					var wide: Vector2 = Vector2(-long.y, long.x) * LEAF_WIDTH_SHARE
					var leaf := PackedVector2Array([middle - long, middle + wide, middle + long,
							middle - wide])
					draw_colored_polygon(leaf, stats.leaf_colour)
					draw_polyline(leaf + PackedVector2Array([leaf[0]]), stats.ink, 1.0)
			walked += step

@export var player: Player
## Sinks and flashes his drawing.
@export var sinking: SinkingDrawing
## How he dies; the rules are made anew from it whenever it changes, as in the Remote tab.
@export var stats: BrambleDeathStats:
	set(value):
		stats = value
		if value != null:
			_pose = BrambleDeathPose.new(value)
			_cut = BrambleCut.new(value)
			_pull = BramblePull.new(value)

var _pose: BrambleDeathPose
## His own clock since he was caught, in s: it barely moves while the game is frozen (Hitstop Time
## Scale), less than a frame of the effects, and stands still while it is paused.
var _clock: float = 0.0
var _caught: bool = false
var _frozen: bool = false
var _time_scale_before: float = 1.0
## Which way his top tilts: 1 to the right, -1 to the left.
var _side: float = 1.0
var _sinks: bool = true
## How far his feet were from the ground the brambles grow from, as they caught him.
var _height: float = 0.0
var _drawing: Node2D
var _rest_scale: Vector2 = Vector2.ONE
var _rest_rotation: float = 0.0
var _cut: BrambleCut
## The frame he died on, as the cut takes it: its sheet, its region on the sheet, its mirror and
## where it was drawn.
var _cut_sheet: Texture2D
var _cut_region: Rect2 = Rect2()
var _cut_flipped: bool = false
var _cut_drawn_at: Transform2D = Transform2D.IDENTITY
var _cuts: Array[BrambleCut.Cut] = []
## The way the top piece is thrown: 1 to the right.
var _throw_side: float = 1.0
var _slashes: SlashDrawing
var _pieces: Array[Polygon2D] = []
var _starts: PackedVector2Array = PackedVector2Array()
var _throws: PackedVector2Array = PackedVector2Array()
var _spins: PackedFloat32Array = PackedFloat32Array()
var _rests: PackedFloat32Array = PackedFloat32Array()
## The frame of the effects the pieces, or the vines, were last moved on.
var _moved_frame: int = -1
var _pull: BramblePull
var _pulling: bool = false
var _vines: VineDrawing
var _vine_plans: Array[BramblePull.Vine] = []
## The hedge's base line, through this point, along the hedge; Up away from it.
var _hedge_base: Vector2 = Vector2.ZERO
var _hedge_up: Vector2 = Vector2.UP
var _rest_position: Vector2 = Vector2.ZERO
var _chance: int = 0


func _ready() -> void:
	assert(player != null, "BrambleDeath: assign the player to Player.")
	assert(sinking != null, "BrambleDeath: assign the player's SinkingDrawing to Sinking.")
	assert(stats != null, "BrambleDeath: assign a bramble death resource to Stats.")
	player.bramble_death = self
	_drawing = sinking.drawing as Node2D
	set_process(false)


func _exit_tree() -> void:
	_thaw()


func _process(delta: float) -> void:
	_clock += delta
	if _slashes != null:
		_move_the_pieces()
	elif _pulling:
		_pull_him()
	else:
		_show_the_pose()


## Brambles caught and killed him; Up points away from them, in the world, so a floor hedge's is
## straight up and a wall's points out of the wall, and Height is how far his feet are from the
## ground they grow from, along Up. Once only, and only in the tree: a level with no wait may have
## started over already, in the frame he died.
func catch(up: Vector2, height: float = 0.0) -> void:
	if _caught or not is_inside_tree():
		return
	_caught = true
	player.pin()
	_sinks = up.y < -FLOOR_UP
	_height = height
	_side = -signf(up.x) if absf(up.x) > FLOOR_UP else player.get_facing()
	if _drawing != null:
		_rest_scale = _drawing.scale
		_rest_rotation = _drawing.rotation
		_rest_position = _drawing.position
	_clock = 0.0
	if stats.cut_apart and _drawing is AnimatedSprite2D:
		_throw_side = signf(up.x) if absf(up.x) > FLOOR_UP else player.get_facing()
		_slash_him()
	elif stats.pulled_in and _drawing != null:
		_grab_him(up, height)
	_freeze()
	if _slashes != null and not _frozen:
		_cut_him_apart.call_deferred()
	set_process(_drawing != null)


func is_caught() -> bool:
	return _caught


## Whether the game is slowed for the hitstop now.
func is_frozen() -> bool:
	return _frozen


## The pieces he was cut into, from the top down; none until the freeze is over.
func get_pieces() -> Array[Polygon2D]:
	return _pieces


## The slashes across him; null unless brambles cut him.
func get_slashes() -> Node2D:
	return _slashes


## The vines round him, as they show now; empty unless brambles pull him in.
func get_vine_lines() -> Array[PackedVector2Array]:
	if _vines != null:
		return _vines.lines
	var none: Array[PackedVector2Array] = []
	return none


## The hedge's base line that caught him: a point on it, and Up away from it.
func get_hedge_base() -> Vector2:
	return _hedge_base


## Readies the pull, and plans the vines from the hedge round his body, if there are any.
func _grab_him(up: Vector2, height: float) -> void:
	_pulling = true
	_hedge_up = up.normalized()
	_hedge_base = player.global_position - _hedge_up * height
	_chance = Engine.get_physics_frames()
	_moved_frame = -1
	if _sinks and not stats.pull_clips:
		_drawing.z_index = stats.pull_z
	if stats.vines <= 0:
		return
	var body: Rect2 = _body_rect()
	_vine_plans = _pull.vines(body, _hedge_base, _hedge_up, _sinks, _chance)
	_vines = VineDrawing.new()
	_vines.stats = stats
	_vines.z_index = SLASH_Z
	for plan: BramblePull.Vine in _vine_plans:
		_vines.lines.append(PackedVector2Array())
		_vines.leaves.append(plan.leaves)
		var length: float = 0.0
		for i: int in range(1, plan.points.size()):
			length += plan.points[i - 1].distance_to(plan.points[i])
		_vines.lengths.append(length)
	add_child(_vines)
	_moved_frame = -1


## On each new frame of the effects: the hedge pulls him, on a floor hedge under, by a wall or a
## ceiling into it; he jerks while pulled, with Jerk Px; the vines, if any, grow and writhe.
func _pull_him() -> void:
	var frame: int = _pull.frame_of(_clock)
	if frame == _moved_frame:
		return
	_moved_frame = frame
	var pulled: float = _pull.pulled(_clock)
	var along_hedge := Vector2(-_hedge_up.y, _hedge_up.x)
	var jerk: float = _pull.jerk(_clock, _chance)
	var shift: Vector2 = along_hedge * jerk * stats.jerk_px
	if _sinks and stats.pull_clips:
		sinking.set_sink(pulled)
		shift += Vector2(0.0, pulled * sinking.depth)
		_drawing.position = _rest_position + along_hedge * jerk * stats.jerk_px
	elif _sinks:
		var down := Vector2(0.0, pulled * stats.pull_depth)
		shift += down
		_drawing.position = _rest_position + down + along_hedge * jerk * stats.jerk_px
	else:
		var into: Vector2 = -_hedge_up * stats.wall_pull * pulled
		shift += into
		_drawing.position = _rest_position + into + along_hedge * jerk * stats.jerk_px
	_drawing.rotation = _rest_rotation + deg_to_rad(stats.jerk_tilt) * jerk
	if _vines != null:
		var grown: float = _pull.grown(_clock)
		for k: int in _vine_plans.size():
			var points: PackedVector2Array = _vine_plans[k].points.duplicate()
			points[1] += _pull.writhe(_clock, k, _chance)
			for i: int in range(BramblePull.ON_HIM, points.size()):
				points[i] += shift
			_vines.lines[k] = BramblePull.above(BramblePull.part(points, grown), _hedge_base, _hedge_up)
		_vines.queue_redraw()
	if pulled >= 1.0 and frame > _pull.frame_of(stats.pull_end) + 1:
		set_process(false)


## His body's box in the world.
func _body_rect() -> Rect2:
	var body: CollisionShape2D = player.get_node_or_null(MAN_BODY_PATH) as CollisionShape2D
	var box: RectangleShape2D = body.shape as RectangleShape2D if body != null else null
	if box == null:
		return Rect2(player.global_position + FALLBACK_BODY.position, FALLBACK_BODY.size)
	return Rect2(body.global_position - box.size / 2.0, box.size)


## Where, on its sheet, the frame he was cut from is.
func get_cut_region() -> Rect2:
	return _cut_region


## Takes the frame he dies on and draws the slashes across his body, evenly spaced along it.
func _slash_him() -> void:
	var sprite: AnimatedSprite2D = _drawing as AnimatedSprite2D
	var frame: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if frame == null:
		return
	_cut_sheet = frame
	_cut_region = Rect2(Vector2.ZERO, frame.get_size())
	if frame is AtlasTexture:
		_cut_sheet = (frame as AtlasTexture).atlas
		_cut_region = (frame as AtlasTexture).region
	_cut_flipped = sprite.flip_h
	_cut_drawn_at = sprite.global_transform
	var top: float = _body_top()
	_cuts = _cut.cuts(top, 0.0, 0.0, Engine.get_physics_frames())
	_slashes = SlashDrawing.new()
	_slashes.stats = stats
	_slashes.z_index = SLASH_Z
	var turn: float = _cut_drawn_at.get_rotation()
	for cut: BrambleCut.Cut in _cuts:
		_slashes.points.append(_cut_drawn_at * cut.point)
		_slashes.angles.append(turn + cut.angle)
		_slashes.shifts.append(cut.shift)
	_slashes.length = _cut.slash_length(0.0, _body_width())
	add_child(_slashes)


## Puts pieces of his frame where its parts were drawn, hides his drawing and lets them fly: called
## once the freeze is over, outside the physics step, since it looks for the floor under him.
func _cut_him_apart() -> void:
	if _cut_sheet == null or not is_inside_tree():
		return
	var half: Vector2 = Vector2(_cut_region.size.x * stats.cut_box_share, _cut_region.size.y) / 2.0
	var offset: Vector2 = (_drawing as AnimatedSprite2D).offset
	var box := PackedVector2Array([offset - half, offset + Vector2(half.x, -half.y), offset + half,
			offset + Vector2(-half.x, half.y)])
	var polygons: Array[PackedVector2Array] = _cut.split(box, _cuts)
	var floor_y: float = _floor_under_him()
	var scale_y: float = absf(_cut_drawn_at.get_scale().y)
	for rank: int in polygons.size():
		var polygon: PackedVector2Array = polygons[rank]
		var middle: Vector2 = BrambleCut.centre(polygon)
		var piece := Polygon2D.new()
		piece.texture = _cut_sheet
		var points := PackedVector2Array()
		var uvs := PackedVector2Array()
		var lowest: float = -INF
		var highest: float = INF
		for point: Vector2 in polygon:
			points.append(point - middle)
			uvs.append(_cut_region.position + BrambleCut.frame_point(point, _cut_region.size, offset,
					_cut_flipped))
			lowest = maxf(lowest, point.y)
			highest = minf(highest, point.y)
		piece.polygon = points
		piece.uv = uvs
		piece.transform = _cut_drawn_at * Transform2D(0.0, middle)
		piece.light_mask = _drawing.light_mask
		piece.visibility_layer = _drawing.visibility_layer
		piece.material = _piece_material(offset)
		add_child(piece)
		_pieces.append(piece)
		_starts.append(piece.position)
		_throws.append(_cut.throw(rank, polygons.size(), _throw_side))
		_spins.append(_cut.spin(rank, polygons.size(), _throw_side))
		_rests.append(floor_y - (lowest - highest) * scale_y * stats.rest_share)
	_drawing.visible = false
	_moved_frame = -1


## The ink along the cuts, in the sheet's px, for a piece's shader.
func _piece_material(offset: Vector2) -> ShaderMaterial:
	var cut_lines := PackedVector4Array()
	for cut: BrambleCut.Cut in _cuts.slice(0, MAX_CUTS):
		var at: Vector2 = _cut_region.position + BrambleCut.frame_point(cut.point, _cut_region.size,
				offset, _cut_flipped)
		var normal: Vector2 = cut.get_normal()
		if _cut_flipped:
			normal.x = -normal.x
		cut_lines.append(Vector4(at.x, at.y, normal.x, normal.y))
	while cut_lines.size() < MAX_CUTS:
		cut_lines.append(Vector4.ZERO)
	var shader_material := ShaderMaterial.new()
	shader_material.shader = PIECE_SHADER
	shader_material.set_shader_parameter(&"sheet_size", _cut_sheet.get_size())
	shader_material.set_shader_parameter(&"cuts", cut_lines)
	shader_material.set_shader_parameter(&"cut_count", mini(_cuts.size(), MAX_CUTS))
	shader_material.set_shader_parameter(&"ink_width",
			stats.cut_ink_width / maxf(absf(_cut_drawn_at.get_scale().y), 0.0001))
	shader_material.set_shader_parameter(&"ink", stats.ink)
	return shader_material


## On each new frame of the effects: the pieces fly, rest and fade, and the slashes fade; once all
## have faded, they hide and this stops.
func _move_the_pieces() -> void:
	var frame: int = _pull.frame_of(_clock)
	if frame == _moved_frame:
		return
	_moved_frame = frame
	_slashes.strength = _cut.slash_strength(_clock)
	_slashes.length = _cut.slash_length(_clock, _body_width())
	_slashes.visible = _slashes.strength > 0.0
	_slashes.queue_redraw()
	if _pieces.is_empty():
		return
	var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
	var turn: float = _cut_drawn_at.get_rotation()
	var faded: float = _cut.fade(_clock)
	for k: int in _pieces.size():
		var piece: Polygon2D = _pieces[k]
		piece.position = _cut.place(_starts[k], _throws[k], gravity, _rests[k], _clock)
		piece.rotation = turn + _cut.turn(_spins[k], _starts[k], _throws[k], gravity, _rests[k], _clock)
		piece.modulate.a = 1.0 - faded
		(piece.material as ShaderMaterial).set_shader_parameter(&"darken", faded * stats.fade_ink)
		piece.visible = faded < 1.0
	if faded >= 1.0 and not _slashes.visible:
		set_process(false)


## The top of his body, in his drawing's own px: the slashes are spaced from there to his feet.
func _body_top() -> float:
	var body: CollisionShape2D = player.get_node_or_null(MAN_BODY_PATH) as CollisionShape2D
	var box: RectangleShape2D = body.shape as RectangleShape2D if body != null else null
	if box == null:
		return -_cut_region.size.y / 2.0
	var top_in_player: Vector2 = body.position - Vector2(0.0, box.size.y / 2.0)
	return (_drawing.transform.affine_inverse() * top_in_player).y


## His body's width in the world, as long as the slashes are long by Slash Length.
func _body_width() -> float:
	var body: CollisionShape2D = player.get_node_or_null(MAN_BODY_PATH) as CollisionShape2D
	var box: RectangleShape2D = body.shape as RectangleShape2D if body != null else null
	return box.size.x if box != null else _cut_region.size.x * absf(_cut_drawn_at.get_scale().x)


## The floor under his middle, as the world under him stops a ray; Fall Reach below it if none does.
func _floor_under_him() -> float:
	var body: Node2D = player.get_node_or_null(MAN_BODY_PATH) as Node2D
	var from: Vector2 = body.global_position if body != null else player.global_position
	var query := PhysicsRayQueryParameters2D.create(from, from + Vector2(0.0, stats.fall_reach),
			player.collision_mask, [player.get_rid()])
	var hit: Dictionary = player.get_world_2d().direct_space_state.intersect_ray(query)
	return (hit["position"] as Vector2).y if not hit.is_empty() else from.y + stats.fall_reach


func _show_the_pose() -> void:
	_drawing.scale = _rest_scale * _pose.squash(_clock)
	_drawing.rotation = _rest_rotation + deg_to_rad(_pose.tilt(_clock, _sinks)) * _side
	if _sinks and sinking.depth > 0.0:
		sinking.set_sink(_pose.sink(_clock, _height) / sinking.depth)


## Freezes the game for Hitstop, with his drawing white, on a timer that runs in real time and while
## paused.
func _freeze() -> void:
	if stats.hitstop <= 0.0:
		return
	_time_scale_before = Engine.time_scale
	Engine.time_scale = stats.hitstop_time_scale
	_frozen = true
	sinking.set_flash(1.0)
	get_tree().create_timer(stats.hitstop, true, false, true).timeout.connect(_end_the_freeze)


func _end_the_freeze() -> void:
	_thaw()
	if _slashes != null:
		_cut_him_apart.call_deferred()


func _thaw() -> void:
	if not _frozen:
		return
	_frozen = false
	Engine.time_scale = _time_scale_before
	if is_instance_valid(sinking):
		sinking.set_flash(0.0)
