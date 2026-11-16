shader_type canvas_item;

// PROTOTYPE (#261): sink.gdshader plus a rim of light, for the man's and the dogs' drawings. Where
// the pixel a few screen px away, towards a light, is empty, this pixel is on the edge that faces
// that light, and it takes Rim Strength more of the light's colour: the fires draw the edges of the
// characters. A light inside the body (the man's own) finds rock-solid body towards itself on the
// outline, so it draws a rim only in hollows, as between an arm and the body. The sinking is
// sink.gdshader's, with the same parameter, so SinkingDrawing still drives it.

uniform float sink_depth = 0.0;
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

void vertex() {
	VERTEX.y += sink_depth;
	below_feet = VERTEX.y;
}

void fragment() {
	uv_per_px_x = dFdx(UV);
	uv_per_px_y = dFdy(UV);
	if (below_feet > 0.0) {
		discard;
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
