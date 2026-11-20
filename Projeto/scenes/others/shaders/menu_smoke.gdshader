// One layer of smoke over the fire at the bottom left of the menu: soft, slow and dark, rising and
// curling as it goes, from two readings of a seamless noise, one bending the other. Thickest at the
// bottom edge and gone before the top of its rect; across, it gathers round the character: thickest
// within Reach of Around, then thinning out to nothing over Thin Out, on both sides, so it neither
// fills the screen's corner nor drifts under the menu. The fire's light (Fire Level, set each frame
// by the backdrop) warms it from below. Aspect is the rect's width over its height, so the smoke is
// not stretched. Several layers, each its own size, speed and depth, make the fire's air deep.
shader_type canvas_item;

uniform vec4 smoke_color : source_color = vec4(0.2, 0.21, 0.23, 1.0);
uniform vec4 lit_color : source_color = vec4(0.55, 0.24, 0.13, 1.0);
// How opaque the thickest smoke is.
uniform float density : hint_range(0.0, 1.0) = 0.5;
// How fast it rises, in band heights per second.
uniform float rise_speed : hint_range(0.0, 0.5) = 0.04;
// How big its curls are: higher makes them smaller.
uniform float detail : hint_range(0.2, 6.0) = 0.7;
// How much the first reading bends the second.
uniform float curl : hint_range(0.0, 2.0) = 0.7;
// Where, across the rect, the smoke is thickest: the character's middle.
uniform float around : hint_range(0.0, 1.0) = 0.22;
// How far each way from Around, as a share of the rect's width, it stays at its thickest.
uniform float reach : hint_range(0.0, 1.0) = 0.1;
// Over how much more, each way, it thins out to nothing.
uniform float thin_out : hint_range(0.01, 1.0) = 0.2;
// Where the layer reads the noise, so two layers never curl alike.
uniform vec2 offset = vec2(0.0);
uniform float aspect = 4.0;
uniform float fire_level = 1.0;
uniform sampler2D noise : repeat_enable, filter_linear;

void fragment() {
	vec2 p = vec2(UV.x * aspect, UV.y) * detail + offset;
	float t = TIME * rise_speed;
	vec2 bend = vec2(texture(noise, p * 0.45 + vec2(0.0, t * 0.7)).r,
			texture(noise, p * 0.45 + vec2(0.41, t * 0.6)).r) - 0.5;
	float body = texture(noise, p + bend * curl + vec2(t * 0.25, t)).r;
	float wisps = texture(noise, p * 2.3 + bend * curl * 1.5 + vec2(-t * 0.4, t * 1.6)).r;
	float smoke = smoothstep(0.3, 0.9, body * 0.75 + wisps * 0.25);
	float band = smoothstep(0.0, 0.9, UV.y)
			* (1.0 - smoothstep(reach, reach + thin_out, abs(UV.x - around)));
	vec3 color = mix(smoke_color.rgb, lit_color.rgb, UV.y * UV.y * clamp(fire_level, 0.0, 1.5) * 0.7);
	COLOR = vec4(color, smoke * band * density);
}
