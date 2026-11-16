shader_type canvas_item;

// PROTOTYPE (#261): sink.gdshader plus a rim of light, for the man's and the dogs' drawings. Where
// the pixel a few screen px away, towards a light, is empty, this pixel is on the edge that faces
// that light, and it takes Rim Strength more of the light's colour: the fires draw the edges of the
// characters. A light inside the body (the man's own) finds solid body towards itself on the
// outline, so it draws a rim only in hollows, as between an arm and the body. An outline, Outline Px
// wide, in the scenery's dark ink, can go round the drawing (the man's; 0 leaves it off). The
// sinking is sink.gdshader's, with the same parameter, so SinkingDrawing still drives it.

// One eighth of a turn, in radians: the step between the eight directions read round a pixel.
const float EIGHTH_TURN = 0.785398;

uniform float sink_depth = 0.0;
// The outline's width in window px (the rig scales it by the stretch) and its colour.
uniform float outline_px : hint_range(0.0, 12.0) = 0.0;
uniform vec4 outline_color : source_color = vec4(0.1, 0.05, 0.09, 1.0);
// How far, in window px, the pixel towards the light is read: the rim's width. The rig scales it by
// the stretch, so it stays the same against the art in any window.
uniform float rim_width_px : hint_range(0.0, 16.0) = 4.0;
// How much of the light's colour the edge takes on top of the usual lighting.
uniform float rim_strength : hint_range(0.0, 8.0) = 2.0;

// Px below the feet; above them it is negative.
varying float below_feet;
// How far UV moves for one window px across and down (the UV's Jacobian), so the read follows the
// drawing's scale, flip and atlas region. Taken in fragment(), before any discard: derivatives need
// the four pixels of a quad running the same code, which the loop over the lights does not keep.
varying vec2 uv_per_px_x;
varying vec2 uv_per_px_y;
// The vertex colour: the node's Modulate, whose alpha the outline keeps (a blink, a fade).
varying vec4 tint;

void vertex() {
	VERTEX.y += sink_depth;
	below_feet = VERTEX.y;
	tint = COLOR;
}


void fragment() {
	uv_per_px_x = dFdx(UV);
	uv_per_px_y = dFdy(UV);
	if (below_feet > 0.0) {
		discard;
	}
	// Outline: an empty pixel with drawing within Outline Px, in eight directions, takes the ink.
	if (outline_px > 0.0 && texture(TEXTURE, UV).a < 0.5) {
		float nearby = 0.0;
		for (int k = 0; k < 8; k++) {
			float angle = float(k) * EIGHTH_TURN;
			vec2 step_px = vec2(cos(angle), sin(angle)) * outline_px;
			nearby = max(nearby, texture(TEXTURE, UV + step_px.x * uv_per_px_x + step_px.y * uv_per_px_y).a);
		}
		if (nearby >= 0.5) {
			COLOR = vec4(outline_color.rgb, outline_color.a * tint.a);
		}
	}
}

void light() {
	vec2 toward = LIGHT_DIRECTION.xy * rim_width_px;
	float beside = texture(TEXTURE, UV + toward.x * uv_per_px_x + toward.y * uv_per_px_y).a;
	float edge = COLOR.a * (1.0 - beside);
	// The default lighting, COLOR times the light, plus the rim in the light's own colour.
	vec3 lit = COLOR.rgb * LIGHT_COLOR.rgb * LIGHT_ENERGY;
	LIGHT = vec4(lit + edge * rim_strength * LIGHT_COLOR.rgb * LIGHT_ENERGY, LIGHT_COLOR.a);
}
