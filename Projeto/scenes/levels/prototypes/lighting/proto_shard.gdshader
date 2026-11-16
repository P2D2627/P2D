// PROTOTYPE (#261): proto_puff.gdshaderinc for a Sprite2D a script moves (proto_crucifix_fx.gd),
// unshaded, since its shards are light.
shader_type canvas_item;
render_mode unshaded;

#define SPRITE_INSTANCE
#include "res://scenes/levels/prototypes/lighting/proto_puff.gdshaderinc"
