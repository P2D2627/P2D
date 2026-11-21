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
