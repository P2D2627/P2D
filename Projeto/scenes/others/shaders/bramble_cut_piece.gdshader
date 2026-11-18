// A piece of the man as brambles cut him apart (#263): his frame, with the ink drawn along each cut,
// as the art outlines its shapes, and darkened towards the ink as it fades. Cuts holds up to four
// cuts, each a point and its normal, in the sheet's px; Sheet Size turns UV into those px.
shader_type canvas_item;

uniform vec2 sheet_size = vec2(1.0);
uniform vec4 cuts[4];
uniform int cut_count = 0;
uniform float ink_width = 4.0;
uniform vec4 ink : source_color = vec4(0.07, 0.03, 0.05, 1.0);
uniform float darken : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 at = UV * sheet_size;
	float nearest = 1e6;
	for (int i = 0; i < 4; i++) {
		if (i < cut_count) {
			nearest = min(nearest, abs(dot(at - cuts[i].xy, cuts[i].zw)));
		}
	}
	float on_the_cut = 1.0 - smoothstep(0.5 * ink_width, ink_width, nearest);
	COLOR.rgb = mix(COLOR.rgb, ink.rgb, max(on_the_cut, darken));
}
