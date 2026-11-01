class_name HitReaction
extends Node

## What a demon's hit does to the man (ADR 0021), heard from his Hurtbox. With SP above Low
## Threshold, the hit takes its damage, throws him back and leaves him invulnerable for a moment.
## With SP low, or when the hit would take his SP to 0, it takes nothing and says so with grab_hit
## instead: a demon never kills with a hit, it grabs. While the man is held, every hit grabs, whatever
## his SP, so none takes SP or throws him then.

## A hit that grabs instead of hurting, from the Hitbox that landed it.
signal grab_hit(hitbox: Hitbox)

@export var player: Player
@export var hurtbox: Hurtbox
## Seconds after a hit in which no other hit lands, so two demons together take SP once.
@export_range(0.0, 3.0, 0.05, "suffix:s") var invulnerable_time: float = 1.0

## True from hold() until release().
var _held: bool = false


func _ready() -> void:
	assert(player != null, "HitReaction: assign the Player to Player.")
	assert(hurtbox != null, "HitReaction: assign the player's Hurtbox to Hurtbox.")
	hurtbox.hit_received.connect(_on_hurtbox_hit_received)


func _on_hurtbox_hit_received(hitbox: Hitbox) -> void:
	var soul_points: SoulPoints = player.soul_points
	if _held or soul_points.is_low() or hitbox.damage >= soul_points.get_sp():
		grab_hit.emit(hitbox)
		return
	soul_points.take_damage(hitbox.damage)
	player.knock_back(_away_from(hitbox), hitbox.knockback_distance, hitbox.knockback_height)
	hurtbox.start_invulnerability(invulnerable_time)


## A demon holds the man: until release(), every hit grabs, also once the regeneration takes his SP
## above Low Threshold. The grab calls it.
func hold() -> void:
	_held = true


## The man is free: a hit hurts or grabs by his SP again.
func release() -> void:
	_held = false


## 1 when the Hitbox is on the man's left, or right on him, so the hit throws him right; -1 when it
## is on his right.
func _away_from(hitbox: Hitbox) -> float:
	return 1.0 if player.global_position.x >= hitbox.global_position.x else -1.0
