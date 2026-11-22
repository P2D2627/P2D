@abstract
class_name CameraBrain
extends Node

## Another way for its GameCamera parent to frame the player than the camera's own, with its zones. While
## the camera uses a brain, each physics step it asks the brain where the screen's centre goes and at what
## zoom, and keeps the rest to itself: cutscenes, the shake, the motion blur and what stays awake by the
## screen. The camera begins a brain from where the screen is, when it switches to it and when a cutscene
## gives the screen back, so the brain glides from there instead of jumping; each begin() but the last has
## its end(). Freed while in use, a brain sends the camera back to its own way.
## Keep the player's body inside the camera's Edge Margin: back to its own way, the camera keeps his body on
## the screen up and down at once, as after a cutscene, and only glides across.

## The camera's own limits (its limit_left and the rest), which the camera sets before each begin().
var camera_limits: Rect2 = Rect2()


## Starts framing player from centre at zoom_level, where the screen is now. tiles is the level's rock, or
## null.
@abstract func begin(player: Player, tiles: TileMapLayer, centre: Vector2, zoom_level: float) -> void


## One physics step; get_centre() and get_zoom() then say where the screen goes.
@abstract func advance(delta: float) -> void


## Where the screen's centre goes, in the level.
@abstract func get_centre() -> Vector2


## The zoom the screen goes to.
@abstract func get_zoom() -> float


## The camera stops using the brain, for good or until a cutscene gives the screen back: lets go of what
## begin() took hold of.
func end() -> void:
	pass


## Right after begin(), when a new copy of the level starts with the brain already chosen: frames the player at
## once, so get_centre() and get_zoom() say where the screen settles instead of where it was. A brain that only
## glides need not do anything.
func cut_to_framing() -> void:
	pass


## True after a step in which the screen jumped instead of moving, as when the player is put far away: the camera
## then resets its physics interpolation, which would otherwise draw the jump.
func has_cut() -> bool:
	return false
