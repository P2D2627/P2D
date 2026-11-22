# Bakes a level's ShelterField: how enclosed each spot of the level is, which the level's
# AmbienceShelter hears to muffle the wind. Run it from the repository root, with the editor closed,
# after moving the level's tiles:
# godot --headless --path Projeto --script res://scenes/others/ambience/bake_shelter.gd -- <level.tscn> <field.res> [preview.png]
# Level 1:
# godot --headless --path Projeto --script res://scenes/others/ambience/bake_shelter.gd -- res://scenes/levels/lust/level1.tscn res://scenes/levels/lust/level1_shelter.res
# With a field already at <field.res>, it bakes with that field's settings (Tiles Path, Reach and the
# chimney's shape) and keeps them; without one, it makes one with the defaults. The preview, an
# image of the level with a square per tile and a line every 50 tiles, shows the field with the
# default values: open air in blue, closed places from yellow to orange as they close in, and
# chimneys in purple as they deepen. The exit code is 0 once the field is saved.
extends SceneTree

## The preview's pixels per tile, and its lines' spacing, in tiles.
const PREVIEW_SCALE: int = 4
const PREVIEW_GRID: int = 50
const ROCK_COLOUR := Color8(34, 32, 36)
const GRID_COLOUR := Color(1.0, 1.0, 1.0, 0.18)
## From open to fully closed, and the purple of a whole chimney.
const OPEN_COLOUR := Color8(150, 205, 235)
const HALF_CLOSED_COLOUR := Color8(245, 205, 110)
const HALF_CLOSED_AT: float = 0.35
const CLOSED_COLOUR := Color8(205, 70, 25)
const CHIMNEY_COLOUR := Color8(150, 40, 200)
## A chimney's colour starts from at least this closed amount's, so its mouth shows as closed.
const CHIMNEY_BASE_CLOSED: float = 0.6
## Below this amount a tile counts as open, and above its complement as fully closed, in the sums.
const COUNT_MARGIN: float = 0.05


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("bake_shelter: give the level scene and the field's path, and a preview if wanted.")
		quit(1)
		return
	var level_path: String = args[0]
	var field_path: String = args[1]
	var scene := load(level_path) as PackedScene
	if scene == null:
		push_error("bake_shelter: %s is not a scene." % level_path)
		quit(1)
		return
	var field := ShelterField.new()
	if ResourceLoader.exists(field_path):
		field = load(field_path) as ShelterField
		if field == null:
			push_error("bake_shelter: %s is not a ShelterField." % field_path)
			quit(1)
			return
	var level: Node = scene.instantiate()
	var tiles := level.get_node_or_null(field.tiles_path) as TileMapLayer
	if tiles == null:
		push_error("bake_shelter: %s has no TileMapLayer at %s." % [level_path, field.tiles_path])
		level.free()
		quit(1)
		return
	var started: int = Time.get_ticks_msec()
	field.bake(tiles)
	var took: int = Time.get_ticks_msec() - started
	level.free()
	var saved: Error = ResourceSaver.save(field, field_path, ResourceSaver.FLAG_COMPRESS)
	if saved != OK:
		push_error("bake_shelter: could not save %s (%s)." % [field_path, error_string(saved)])
		quit(1)
		return
	print("Baked %s into %s in %d ms: %s" % [level_path, field_path, took, _sums(field)])
	if args.size() > 2:
		var written: Error = _preview(field).save_png(args[2])
		print("Preview %s: %s" % [args[2], error_string(written)])
	quit(0)


## The field's shares of air with the default values: open, fully closed and chimney.
func _sums(field: ShelterField) -> String:
	var air: int = 0
	var open: int = 0
	var shut: int = 0
	var chimney: int = 0
	for y: int in field.size.y:
		for x: int in field.size.x:
			var amounts: Vector2 = field.default_amounts_of_tile(x, y)
			if amounts.x < 0.0:
				continue
			air += 1
			if amounts.y > 0.0:
				chimney += 1
			elif amounts.x < COUNT_MARGIN:
				open += 1
			elif amounts.x > 1.0 - COUNT_MARGIN:
				shut += 1
	var share: float = 100.0 / maxi(air, 1)
	return ("grid %d x %d tiles, %d of air: open %.0f%%, fully closed %.0f%%, chimney %.0f%%"
			% [field.size.x, field.size.y, air, open * share, shut * share, chimney * share])


func _preview(field: ShelterField) -> Image:
	var image := Image.create(field.size.x * PREVIEW_SCALE, field.size.y * PREVIEW_SCALE, false,
			Image.FORMAT_RGB8)
	image.fill(ROCK_COLOUR)
	for y: int in field.size.y:
		for x: int in field.size.x:
			var amounts: Vector2 = field.default_amounts_of_tile(x, y)
			if amounts.x < 0.0:
				continue
			var colour: Color = _closed_colour(amounts.x)
			if amounts.y > 0.0:
				colour = _closed_colour(maxf(amounts.x, CHIMNEY_BASE_CLOSED)).lerp(CHIMNEY_COLOUR,
						amounts.y)
			image.fill_rect(Rect2i(x * PREVIEW_SCALE, y * PREVIEW_SCALE, PREVIEW_SCALE,
					PREVIEW_SCALE), colour)
	for line: int in range(0, maxi(field.size.x, field.size.y), PREVIEW_GRID):
		var at: int = line * PREVIEW_SCALE
		for along: int in image.get_height():
			if at < image.get_width():
				image.set_pixel(at, along, image.get_pixel(at, along).blend(GRID_COLOUR))
		for along: int in image.get_width():
			if at < image.get_height():
				image.set_pixel(along, at, image.get_pixel(along, at).blend(GRID_COLOUR))
	return image


func _closed_colour(amount: float) -> Color:
	if amount <= HALF_CLOSED_AT:
		return OPEN_COLOUR.lerp(HALF_CLOSED_COLOUR, amount / HALF_CLOSED_AT)
	return HALF_CLOSED_COLOUR.lerp(CLOSED_COLOUR, (amount - HALF_CLOSED_AT) / (1.0 - HALF_CLOSED_AT))
