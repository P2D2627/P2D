class_name LevelEntry
extends Resource

## A level in the list the main menu offers: the name on its button and the scene that runs.

## The name on the level's button.
@export var title: String = ""
## The level's scene.
@export var scene: PackedScene
## On, this level is the start of the game: choosing it starts a new game, and the save follows it
## from there. Off, as in a test room, it plays with nothing saved.
@export var starts_game: bool = false
