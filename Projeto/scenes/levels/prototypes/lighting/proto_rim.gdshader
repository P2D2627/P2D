shader_type canvas_item;

// PROTOTYPE (#261): sink.gdshader plus a rim of light, for the man's and the dogs' drawings. Where
// the pixel a few screen px away, towards a light, is empty, this pixel is on the edge that faces
// that light, and it takes Rim Strength more of the light's colour: the fires draw the edges of the
// characters. A light inside the body (the man's own) finds solid body towards itself on the
// outline, so it draws a rim only in hollows, as between an arm and the body. An outline, Outline Px
// wide, in the scenery's dark ink, can go round the drawing (the man's; 0 leaves it off). The
// sinking is sink.gdshader's, with the same parameter, so SinkingDrawing still drives it.
// A dog's skin can boil (#263, Boil Amount above 0; proto_dog_smoke.gd sets it on each dog, with its
// own seed and a clock that steps at the effects' drawing rate): a few patches a shade darker drift
// up through the skin, now and then a small pale bubble swells on it and pops into a dark fleck, and
// the line boils by a px over a cycle of three drawings, as hand-drawn animation boils. Light
// touches, in screen px, so they read the same on every dog and at every zoom.

// One eighth of a turn, in radians: the step between the eight directions read round a pixel.
const float EIGHTH_TURN = 0.785398;

uniform float sink_depth = 0.0;
// As in sink.gdshader: whitens the drawing, its shape kept (#263).
uniform float flash : hint_range(0.0, 1.0) = 0.0;
// The outline's width in window px (the rig scales it by the stretch) and its colour.
uniform float outline_px : hint_range(0.0, 12.0) = 0.0;
uniform vec4 outline_color : source_color = vec4(0.1, 0.05, 0.09, 1.0);
// How far, in window px, the pixel towards the light is read: the rim's width. The rig scales it by
// the stretch, so it stays the same against the art in any window.
uniform float rim_width_px : hint_range(0.0, 16.0) = 4.0;
// How much of the light's colour the edge takes on top of the usual lighting.
uniform float rim_strength : hint_range(0.0, 8.0) = 2.0;
// The boil: 0 off (the man), 1 full. Seed keeps each dog's apart; Clock is in s, held per drawing,
// and Drawings Per S tells the line's cycle apart.
uniform float boil_amount : hint_range(0.0, 1.0) = 0.0;
uniform float boil_seed = 0.0;
uniform float boil_clock = 0.0;
uniform float boil_drawings_per_s = 12.0;
// Patches: the share of the skin they cover, how much darker they make it, their size and how fast
// they drift up (screen px, px/s). Off (Patch Dark 0): rising from the belly, they read as heat
// coming up from the floor through the dog, not as the dog boiling.
uniform float patch_cover : hint_range(0.0, 1.0) = 0.2;
uniform float patch_dark : hint_range(0.0, 1.0) = 0.0;
uniform float patch_size_px = 10.0;
uniform float patch_rise_px = 14.0;
// Bubbles: one may sit in each cell of Cell Px, in Share of the cells each Cycle s; it swells over
// Grow s to Radius Px, then is a dark fleck for Fleck s.
uniform float bubble_cell_px = 16.0;
uniform float bubble_share : hint_range(0.0, 1.0) = 0.3;
uniform float bubble_cycle = 1.5;
uniform float bubble_grow = 0.45;
uniform float bubble_fleck = 0.12;
uniform float bubble_radius_px = 4.0;
uniform vec4 bubble_color : source_color = vec4(1.0, 0.62, 0.86, 1.0);
uniform vec4 fleck_color : source_color = vec4(0.16, 0.03, 0.11, 1.0);
// How far the line boils, in screen px.
uniform float line_boil_px = 1.0;

// Px below the feet; above them it is negative.
varying float below_feet;
// The node's own px, which the boil measures in (divided by local px per screen px).
varying vec2 local;
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
	local = VERTEX;
	tint = COLOR;
}


float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}


float value_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(cell), hash(cell + vec2(1.0, 0.0)), u.x),
			mix(hash(cell + vec2(0.0, 1.0)), hash(cell + vec2(1.0, 1.0)), u.x), u.y);
}


// Where the line boils to at Seeded (the node's px in screen px, offset by the seed), in screen px:
// a 1 px drift that changes over a cycle of three drawings.
vec2 line_boil(vec2 seeded) {
	float cycle = mod(floor(boil_clock * boil_drawings_per_s + 0.5), 3.0);
	vec2 wobble = vec2(value_noise(seeded / 11.0 + cycle * 7.3),
			value_noise(seeded / 11.0 + cycle * 7.3 + 19.1)) * 2.0 - 1.0;
	return wobble * line_boil_px * boil_amount;
}


// The skin of the drawing's Color at Seeded boiling: darkened in drifting patches, and with a
// bubble or its fleck on top. (The drawing is read in fragment(): the compatibility renderer
// cannot pass TEXTURE to a function.)
vec4 boil_skin(vec4 color, vec2 seeded, vec4 modulate) {
	// Patches: two octaves of noise drifting up, cut flat with an edge of about a px.
	if (patch_dark > 0.0) {
		vec2 drifting = (seeded + vec2(0.0, patch_rise_px * boil_clock)) / patch_size_px;
		float clumps = 0.7 * value_noise(drifting) + 0.3 * value_noise(drifting * 2.3 + 5.0);
		float patched = smoothstep(1.0 - patch_cover - 0.02, 1.0 - patch_cover + 0.02, clumps);
		color.rgb *= 1.0 - patch_dark * patched * boil_amount;
	}
	// A bubble per cell, now and then, only on the skin (the ink's dark keeps none).
	if (dot(color.rgb, vec3(0.3, 0.5, 0.2)) < 0.2) {
		return color;
	}
	vec2 cell = floor(seeded / bubble_cell_px);
	float offset = hash(cell + 3.1) * bubble_cycle;
	float turn = floor((boil_clock + offset) / bubble_cycle);
	if (hash(cell + turn * 1.7 + 11.0) > bubble_share * boil_amount) {
		return color;
	}
	float since = boil_clock + offset - turn * bubble_cycle;
	vec2 middle = (cell + 0.25 + 0.5 * vec2(hash(cell + 5.0), hash(cell + 7.0))) * bubble_cell_px;
	float away = distance(seeded, middle);
	if (since < bubble_grow) {
		float radius = bubble_radius_px * (0.4 + 0.6 * since / bubble_grow);
		if (away < radius - 1.0) {
			color.rgb = bubble_color.rgb * modulate.rgb;
		} else if (away < radius) {
			color.rgb = mix(color.rgb, fleck_color.rgb, 0.6);
		}
	} else if (since < bubble_grow + bubble_fleck && away < bubble_radius_px * 0.5) {
		color.rgb = fleck_color.rgb;
	}
	return color;
}


void fragment() {
	uv_per_px_x = dFdx(UV);
	uv_per_px_y = dFdy(UV);
	float local_per_px = length(dFdx(local));
	if (below_feet > 0.0) {
		discard;
	}
	if (boil_amount > 0.0) {
		vec2 seeded = local / max(local_per_px, 1e-4) + boil_seed * 37.0;
		vec2 wobble = line_boil(seeded);
		COLOR = texture(TEXTURE, UV + wobble.x * uv_per_px_x + wobble.y * uv_per_px_y) * tint;
		if (COLOR.a >= 0.5) {
			COLOR = boil_skin(COLOR, seeded, tint);
		}
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
	COLOR.rgb = mix(COLOR.rgb, vec3(1.0), flash);
}

void light() {
	vec2 toward = LIGHT_DIRECTION.xy * rim_width_px;
	float beside = texture(TEXTURE, UV + toward.x * uv_per_px_x + toward.y * uv_per_px_y).a;
	float edge = COLOR.a * (1.0 - beside);
	// The default lighting, COLOR times the light, plus the rim in the light's own colour.
	vec3 lit = COLOR.rgb * LIGHT_COLOR.rgb * LIGHT_ENERGY;
	LIGHT = vec4(lit + edge * rim_strength * LIGHT_COLOR.rgb * LIGHT_ENERGY, LIGHT_COLOR.a);
}
