shader_type canvas_item;
render_mode unshaded;

// PROTOTYPE (#261): a ghost of the man's drawing (proto_man_look.gd), in one flat tone, eaten away
// by noise held in the world, so each ghost breaks up in its own pattern and the noise does not slide
// with it. Age, 0 to 1 over its life, comes from the script (held in steps in ink style). Ink style
// draws a dark line along the edge being eaten, like the effects of proto_puff.gdshaderinc.

// Whole until this share of its life; from then eaten, from a little under the noise's lowest
// value to its highest; and at the end of its life its tone is this share fainter.
const float WHOLE_UNTIL = 0.2;
const float ERODE_FROM = -0.05;
const float ERODE_TO = 1.0;
const float FADE_BY = 0.5;

uniform sampler2D noise_texture : repeat_enable, filter_linear;
uniform vec4 ghost_color : source_color = vec4(0.42, 0.28, 0.4, 0.6);
// The noise's scale per world px: smaller, larger clumps.
uniform float noise_scale = 0.006;
uniform bool ink_style = true;
uniform vec4 ink_color : source_color = vec4(0.1, 0.05, 0.09, 1.0);
// How far past the eaten edge, in noise units, the ink line reaches.
uniform float ink_width : hint_range(0.0, 0.3) = 0.05;
instance uniform float age = 0.0;

varying vec2 world;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float drawing = texture(TEXTURE, UV).a;
	float noise = texture(noise_texture, world * noise_scale).r;
	// Whole at first, so it reads as his shape; then eaten until gone at 1, eased in and out.
	float threshold = mix(ERODE_FROM, ERODE_TO, smoothstep(WHOLE_UNTIL, 1.0, age));
	float inside = noise - threshold;
	float px = max(fwidth(noise), 0.0001);
	float keep = smoothstep(-px, px, inside);
	float ink = ink_style ? 1.0 - smoothstep(ink_width - px, ink_width + px, inside) : 0.0;
	vec3 rgb = mix(ghost_color.rgb, ink_color.rgb, ink * ink_color.a);
	// The older the ghost, the fainter, so the newest leads.
	COLOR = vec4(rgb, ghost_color.a * (1.0 - FADE_BY * age) * drawing * keep);
}
