# Demon senses a test sets by hand: can_see says Sees, whatever stands between, so a case can check
# what SightReveal does with a demon that sees the man without building the spot where it would.
# It needs only a Body Box, which the senses read as they come in; it has no sight area.
extends DemonSenses

## What can_see says.
var sees: bool = false


func _ready() -> void:
	pass


func can_see(_man: Node2D) -> bool:
	return sees
