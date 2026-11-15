shader_type canvas_item;

// Distance haze: tints a drawing toward the air's color and softens it, so it reads as far away. Put it in a
// ShaderMaterial on a layer's parent node and turn on Use Parent Material in each drawing of the layer.

// The color the drawing fades toward, and how much of it: 0 keeps the drawing's colors, 1 is all haze.
uniform vec3 haze_color : source_color = vec3(0.36, 0.16, 0.35);
uniform float haze_amount : hint_range(0.0, 1.0) = 0.5;
// Blur radius in the drawing's own pixels: 0 keeps it sharp.
uniform float blur_radius : hint_range(0.0, 16.0) = 0.0;
// On: the haze takes the color of the area the drawing stands in, read from the level's color map, instead of
// haze_color, so each area's rocks melt into that area's wall.
uniform bool use_area_map = false;
uniform sampler2D area_map : source_color, filter_linear, repeat_disable;
// World px per pixel of the color map.
uniform float area_map_scale = 8.0;

const int TAPS = 12;

varying vec4 vertex_color;
varying vec2 world_position;

void vertex() {
	vertex_color = COLOR;
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	if (blur_radius > 0.0) {
		// A ring of taps around the pixel, plus the pixel itself.
		vec4 sum = color;
		for (int i = 0; i < TAPS; i++) {
			float angle = float(i) * 6.2831853 / float(TAPS);
			float reach = (i % 2 == 0) ? 1.0 : 0.5;
			sum += texture(TEXTURE, UV + vec2(cos(angle), sin(angle)) * blur_radius * reach * TEXTURE_PIXEL_SIZE);
		}
		color = sum / float(TAPS + 1);
	}
	vec3 haze = haze_color;
	if (use_area_map) {
		haze = texture(area_map, world_position / (vec2(textureSize(area_map, 0)) * area_map_scale)).rgb;
	}
	color.rgb = mix(color.rgb, haze, haze_amount);
	// Keeps each drawing's own Modulate, so one rock can still be tinted by hand.
	COLOR = color * vertex_color;
}
