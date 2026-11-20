// The glow of a fire below the bottom left of the menu, by the character: warm light that rises from
// the bottom edge and fades out, uneven along it, added over what is behind it. Across, it gathers
// round the character, like the smoke: brightest within Reach of Around, then thinning out to
// nothing over Thin Out, on both sides, at the bottom edge; higher up it narrows (Rise Narrowing),
// so it opens as a dome from the fire below and never stands as a column. Fire Level, set each
// frame by the menu's backdrop, makes it waver with the same flame as the light on the character.
shader_type canvas_item;
render_mode blend_add;

uniform vec4 glow_color : source_color = vec4(0.85, 0.36, 0.16, 1.0);
// How bright the glow is at the bottom edge.
uniform float strength : hint_range(0.0, 2.0) = 0.32;
// How fast the glow's unevenness drifts along the edge.
uniform float drift : hint_range(0.0, 1.0) = 0.04;
// Where, across the rect, the glow is brightest: the character's middle.
uniform float around : hint_range(0.0, 1.0) = 0.22;
// How far each way from Around, as a share of the rect's width, it stays at its brightest.
uniform float reach : hint_range(0.0, 1.0) = 0.1;
// Over how much more, each way, it thins out to nothing.
uniform float thin_out : hint_range(0.01, 1.0) = 0.25;
// How much narrower the glow is at the top of its rect than at the bottom: 0 keeps it as wide.
uniform float rise_narrowing : hint_range(0.0, 1.0) = 0.5;
uniform float fire_level = 1.0;
uniform sampler2D noise : repeat_enable, filter_linear;

// The narrowest the glow gets, as a share of its width at the bottom: at 0, with Rise Narrowing 1,
// the top row's smoothstep would have both edges at 0 and give NaN.
const float MIN_WIDTH = 0.001;

void fragment() {
	float width = max(1.0 - rise_narrowing * (1.0 - UV.y), MIN_WIDTH);
	float rise = pow(UV.y, 2.2)
			* (1.0 - smoothstep(reach * width, (reach + thin_out) * width, abs(UV.x - around)));
	float uneven = texture(noise, vec2(UV.x * 1.3 + TIME * drift, TIME * drift * 1.7)).r;
	float glow = rise * (0.5 + uneven) * strength * fire_level;
	COLOR = vec4(glow_color.rgb * glow, 1.0);
}
