// The light of a lightning flash on a level's backdrop, drawn over the whole screen, last in the
// backdrop: it lights what the backdrop has drawn behind it, in the flash's colour, most where the
// light comes from (Centre) and less further off, and adds a faint haze, so even the darkest of
// the backdrop glows a little. Added to what is there (blend_add), never darkening it. The rock
// and the man, drawn after the backdrop, are not lit.
// LightningFlash sets the uniforms each frame; another shader with the same uniforms can take its
// place, in LightningFlash's Look.
shader_type canvas_item;
render_mode blend_add, unshaded;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
// How bright the light is now: the strike's flash, times LightningFlash's Brightness.
uniform float intensity = 0.0;
uniform vec4 light_colour : source_color = vec4(1.0, 0.45, 0.82, 1.0);
// Where the light comes from, in the screen's UV (0 to 1 across, 0 to 1 down).
uniform vec2 centre = vec2(0.2, 0.0);
// How far it reaches, as a share of the screen's width: at Reach, it is about a tenth as bright.
uniform float reach = 0.7;
// The screen's width over its height, so the light is round.
uniform float aspect = 1.7777778;
// The share of the light that reaches the whole screen evenly, wherever it comes from.
uniform float spill = 0.2;
// How much light is added flat, as a share of what lights the backdrop's own colours.
uniform float haze = 0.12;

void fragment() {
	vec2 away = UV - centre;
	away.y /= aspect;
	float distance_share = length(away) / max(reach, 0.0001);
	float falloff = exp(-2.3 * distance_share * distance_share);
	float glow = mix(spill, 1.0, falloff) * intensity;
	vec3 behind = texture(screen_texture, SCREEN_UV).rgb;
	COLOR = vec4((behind + haze) * light_colour.rgb * glow, 1.0);
}
