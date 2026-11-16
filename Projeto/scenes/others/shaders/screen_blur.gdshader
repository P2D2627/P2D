shader_type canvas_item;

// Blurs and darkens what is drawn behind, so the text there can no longer be read: behind a
// question that pops up over a menu. A cheap blur, by rings of samples around each pixel.

uniform sampler2D screen: hint_screen_texture, filter_linear_mipmap;
// How far the blur reaches, in px.
uniform float radius: hint_range(0.0, 60.0) = 32.0;
// How much darker the blurred screen gets: 0 keeps it, 1 is black.
uniform float darken: hint_range(0.0, 1.0) = 0.55;

const int RINGS = 4;
const int PER_RING = 12;

void fragment() {
	vec3 sum = texture(screen, SCREEN_UV).rgb;
	float count = 1.0;
	for (int ring = 1; ring <= RINGS; ring++) {
		float distance_px = radius * float(ring) / float(RINGS);
		for (int i = 0; i < PER_RING; i++) {
			float angle = 6.2831853 * (float(i) + 0.5 * float(ring)) / float(PER_RING);
			vec2 offset = vec2(cos(angle), sin(angle)) * distance_px * SCREEN_PIXEL_SIZE;
			sum += texture(screen, SCREEN_UV + offset).rgb;
			count += 1.0;
		}
	}
	COLOR = vec4(sum / count * (1.0 - darken), 1.0);
}
