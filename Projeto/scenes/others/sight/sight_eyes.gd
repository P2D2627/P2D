class_name SightEyes
extends Marker2D

## Where the man looks from, for what only shows while he sees it (#253): a spot on his head. There
## is one man, so the eyes in the tree are kept where every SightReveal finds them, with no group to
## search on each look. With two in the tree, the last to come in counts. He sees no further than
## the screen, grown by Screen Margin: found once a physics frame here, so each reveal off it skips
## its rays, which in level 1 cost over 2 ms a frame when all of them looked.

## The eyes in the tree; null when there are none, as in a scene played on its own.
static var current: SightEyes = null

## Px past each side of the screen still in sight, so what comes onto the screen is drawn already.
@export_range(0.0, 960.0, 1.0, "suffix:px") var screen_margin: float = 192.0

## What the screen shows, in the world, grown by Screen Margin, as of the last physics frame.
var _screen: Rect2 = Rect2()
## Whether there is a camera, and so a screen; with none, as in the tests, all the world is in sight.
var _has_screen: bool = false


func _enter_tree() -> void:
	current = self


func _exit_tree() -> void:
	if current == self:
		current = null


## The screen from what is drawn, shake and all: the margin takes in the few px that moves it.
func _physics_process(_delta: float) -> void:
	var viewport: Viewport = get_viewport()
	_has_screen = viewport.get_camera_2d() != null
	if _has_screen:
		_screen = (viewport.get_canvas_transform().affine_inverse()
				* viewport.get_visible_rect()).grow(screen_margin)


## True when some of area, in the world, is in sight: on the screen or within Screen Margin of it.
func can_see_area(area: Rect2) -> bool:
	return not _has_screen or _screen.intersects(area)


## The man these eyes belong to: the node they hang from.
func get_man() -> Node2D:
	return get_parent() as Node2D
