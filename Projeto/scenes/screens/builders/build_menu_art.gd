# Brings the menu art into the project from the drawings as they were sent (3840 x 2160, transparent
# around the drawing): the cross that marks the selected option and the main character, already
# painted with its light and shade, each cut to its drawing. From the repository root:
# godot --headless --path Projeto --script res://scenes/screens/builders/build_menu_art.gd -- \
#     --cross=<cross.png> --character=<character.png>
# The exit code is 0 when every image was saved.
extends SceneTree

const OUT_DIR: String = "res://assets/sprites/menu/"


func _initialize() -> void:
	var args: Dictionary = {}
	for argument: String in OS.get_cmdline_user_args():
		var pair: PackedStringArray = argument.trim_prefix("--").split("=", true, 1)
		args[pair[0]] = pair[1] if pair.size() > 1 else ""
	if not args.has("cross") or not args.has("character"):
		printerr("build_menu_art.gd: give --cross=<png> and --character=<png>")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var ok: bool = _save(_cut(Image.load_from_file(args["cross"])), "menu_cross.png")
	ok = _save(_cut(Image.load_from_file(args["character"])), "menu_character.png") and ok
	quit(0 if ok else 1)


## The image cut to the box around what is not transparent.
func _cut(image: Image) -> Image:
	image.convert(Image.FORMAT_RGBA8)
	return image.get_region(image.get_used_rect())


func _save(image: Image, file: String) -> bool:
	var error: Error = image.save_png(ProjectSettings.globalize_path(OUT_DIR + file))
	print("%s %s %s" % [file, image.get_size(), error_string(error)])
	return error == OK
