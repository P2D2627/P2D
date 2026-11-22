# Screenshots of Asmodeus appearing at the spots measure_asmodeus_spots.gd wrote (run it first), with a
# window, a fresh copy of the level for each. godot --path Projeto --script
# res://tests/measures/shoot_asmodeus_spots.gd -- <out dir>
extends "res://tests/support/base_test.gd"

const SCENE_PATH: String = "res://scenes/levels/lust/level1.tscn"
const SPOTS_PATH: String = "user://asmodeus_spots.json"
const CAMERA_FRAMES: int = 150
const LABELS: Dictionary = {
	"front_right": "em frente (virado para a direita)",
	"front_left": "em frente (virado para a esquerda)",
	"behind": "atras (sem sitio a frente: ele vira-se)",
	"none": "SEM SITIO: comportamento de hoje",
}


func _initialize() -> void:
	var out_dir: String = OS.get_cmdline_user_args()[0]
	await process_frame
	(root.get_node(^"GameState") as GameProgress).mark_event(&"velvet_met")
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 100
	var label: Label = Label.new()
	label.position = Vector2(24.0, 24.0)
	label.add_theme_font_size_override(&"font_size", 40)
	label.add_theme_color_override(&"font_outline_color", Color.BLACK)
	label.add_theme_constant_override(&"outline_size", 10)
	layer.add_child(label)
	root.add_child(layer)
	var spots: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SPOTS_PATH))
	for case: String in LABELS:
		var index: int = 0
		for entry: Dictionary in spots[case]:
			index += 1
			await _shoot(out_dir, "%s_%d" % [case, index], LABELS[case], entry, label)
	quit(0)


func _shoot(out_dir: String, shot: String, title: String, entry: Dictionary, label: Label) -> void:
	var level: Level = (load(SCENE_PATH) as PackedScene).instantiate() as Level
	root.add_child(level)
	await physics_frame
	level.get_node(^"AsmodeusDirector").process_mode = Node.PROCESS_MODE_DISABLED
	level.get_node(^"Dogs").process_mode = Node.PROCESS_MODE_DISABLED
	var asmodeus: Asmodeus = level.get_node(^"Asmodeus") as Asmodeus
	var player: Player = level.player
	var died: Array[bool] = [false]
	player.died.connect(func() -> void: died[0] = true)
	var feet: Vector2 = Vector2(float(entry["x"]), float(entry["y"]))
	var facing: float = float(entry["facing"])
	asmodeus.hide()
	player.global_position = feet - Vector2(0.0, 1.0)
	player.velocity = Vector2.ZERO
	player.face(facing)
	player.hold_still()
	label.text = ""
	for i: int in CAMERA_FRAMES:
		await physics_frame
		player.global_position.x = feet.x
		player.velocity.x = 0.0
	await physics_frame
	var at: Vector2 = player.global_position
	var before: String = "ele virado para a %s" % ("direita" if player.get_facing() > 0.0
			else "esquerda")
	asmodeus.appear_at(at)
	asmodeus.show()
	label.text = "%s\n%s, %s em (%d, %d)\ndepois: ela a %d px %s; ele virado para a %s" % [
			title, entry["zone"], before, at.x, at.y,
			roundi(absf(asmodeus.global_position.x - at.x)),
			"a direita" if asmodeus.global_position.x > at.x else "a esquerda",
			"direita" if player.get_facing() > 0.0 else "esquerda"]
	var camera: Camera2D = Camera2D.new()
	camera.global_position = (at + asmodeus.global_position) / 2.0 - Vector2(0.0, 100.0)
	level.add_child(camera)
	camera.make_current()
	for i: int in 4:
		await process_frame
	var image: Image = root.get_texture().get_image()
	image.save_png("%s/%s.png" % [out_dir, shot])
	var to_screen: Transform2D = root.get_final_transform()
	var middle: Vector2 = to_screen * ((player.get_global_transform_with_canvas().origin
			+ asmodeus.get_global_transform_with_canvas().origin) / 2.0)
	var size: Vector2i = Vector2i(480, 270)
	var corner: Vector2i = (Vector2i(middle) - Vector2i(240, 170)).clamp(Vector2i.ZERO,
			image.get_size() - size)
	var zoom: Image = image.get_region(Rect2i(corner, size))
	zoom.resize(size.x * 2, size.y * 2, Image.INTERPOLATE_NEAREST)
	zoom.save_png("%s/%s_zoom.png" % [out_dir, shot])
	print("shot %s%s: %s" % [shot, " (HE DIED)" if died[0] else "", label.text.replace("\n", " | ")])
	level.queue_free()
	await process_frame
