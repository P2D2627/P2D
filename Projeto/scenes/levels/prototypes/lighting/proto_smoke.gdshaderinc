// PROTOTYPE (#261): proto_smoke.gd's group. The CanvasGroup drew its stamps into the buffer read
// here, one over another; their alpha together (1 minus the product of 1 minus each, close to their
// sum while they are thin) is how much smoke there is. Only where it passes Threshold is there
// smoke, with a soft edge Softness wide; thin near the edge and dense inside, so it has a body; and
// its opacity is applied once, over the whole, so the smoke crossing itself does not darken.

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform vec4 edge_color : source_color = vec4(0.5, 0.46, 0.48, 1.0);
uniform vec4 core_color : source_color = vec4(0.32, 0.28, 0.31, 1.0);
uniform float threshold : hint_range(0.0, 1.0) = 0.3;
uniform float softness : hint_range(0.0, 0.5) = 0.14;
uniform float opacity : hint_range(0.0, 1.0) = 0.6;

void fragment() {
	float density = textureLod(screen_texture, SCREEN_UV, 0.0).a;
	float body = smoothstep(threshold - softness, threshold + softness, density);
	float dense = smoothstep(threshold, 1.0, density);
	COLOR = vec4(mix(edge_color.rgb, core_color.rgb, dense), body * opacity);
}
