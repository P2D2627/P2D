class_name TalkShot
extends RefCounted

## The camera's shot in a talk, worked out from what has to show and where. The figures are the union of the
## drawn rects of the man and of who talks to him, in the level. The room is the part of the screen they may
## take: under the answers' wheel and over the bottom bar, with a gap on each side. Pure, so the tests check
## it alone; TalkFraming measures the figures and the room, and moves the camera.


## The zoom that puts the figures whole inside the room: Max Zoom, or less where the room is too short or too
## narrow for them, and never less than Min Zoom.
static func zoom_to_fit(figures: Rect2, room: Rect2, max_zoom: float, min_zoom: float) -> float:
	var level: float = max_zoom
	if figures.size.y > 0.0:
		level = minf(level, room.size.y / figures.size.y)
	if figures.size.x > 0.0:
		level = minf(level, room.size.x / figures.size.x)
	return maxf(level, min_zoom)


## Where the camera's centre goes, in the level, for a screen of screen size at zoom level: the figures' feet
## on the room's bottom and their middle across on the room's middle, with the camera moved lean px of the
## screen to the right (to the left below 0). The lean is cut short where it would push them out of the room.
static func centre_for(figures: Rect2, room: Rect2, screen: Vector2, level: float, lean: float) -> Vector2:
	var spare: float = maxf(0.0, (room.size.x - figures.size.x * level) / 2.0)
	var feet_on_screen: Vector2 = Vector2(room.get_center().x - clampf(lean, -spare, spare), room.end.y)
	var feet_in_level: Vector2 = Vector2(figures.get_center().x, figures.end.y)
	return feet_in_level - (feet_on_screen - screen / 2.0) / level


## How far along a move the camera is when done (0 to 1) of its time went by: a sine ease in and out, the
## cutscenes' curve.
static func ease_along(done: float) -> float:
	return 0.5 - 0.5 * cos(PI * clampf(done, 0.0, 1.0))


## The zoom eased of the way from one level to another, evenly in scale, as the cutscenes', so a zoom in does
## not rush at the end.
static func zoom_along(from: float, to: float, eased: float) -> float:
	return exp(lerpf(log(from), log(to), eased))
