class_name ArrivalPoint
extends Marker2D

## A spot in a phase where the man can come in other than at its start, as at the end of Lust after
## Asmodeus's shortcut. A GoToSceneEffect names it by Id; Main puts the player on it before the phase
## joins the tree, so the camera starts there too. Put it on the floor, with room for him to stand.

@export var id: StringName = &""


## The ArrivalPoint of level with that id, or null if there is none. It also works before level is
## in the tree.
static func find_in(level: Node, point_id: StringName) -> ArrivalPoint:
	for node: Node in level.find_children("*", "Marker2D", true, false):
		if node is ArrivalPoint and (node as ArrivalPoint).id == point_id:
			return node as ArrivalPoint
	return null


## Where it is, relative to level, an ancestor of it. Works before level is in the tree, when
## global_position cannot be read.
func position_in(level: Node) -> Vector2:
	var at: Transform2D = transform
	var node: Node = get_parent()
	while node != null and node != level:
		if node is Node2D:
			at = (node as Node2D).transform * at
		node = node.get_parent()
	return at.origin
