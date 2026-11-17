// PROTOTYPE (#257): what the two vision shaders share (vision_mask.gdshader, the distance field, and
// vision_polygon.gdshader). What the man does not see is multiplied by Outside and, with Unseen Blur
// Px over 0, drawn out of focus. Each is its own shader so the polygon does not pay for the distance
// field: Godot builds it every frame for any shader that calls texture_sdf().

uniform sampler2D screen : hint_screen_texture, filter_linear, repeat_disable;
uniform float outside = 0.35;
// What he does not see, out of focus by this radius in screen px; 0 leaves it sharp.
uniform float unseen_blur_px = 0.0;

// Two rings of eight taps around the centre: the blurs' pattern.
const int RING_TAPS = 8;
const float OUTER_WEIGHT = 0.6;

// Tap k of ring 1 (inner) or 2 (outer), as an offset in units of the blur's radius; the outer ring
// is turned half a tap, so the two do not line up.
vec2 ring_tap(int ring, int k) {
	float angle = (float(k) + 0.5 * float(ring - 1)) * TAU / float(RING_TAPS);
	return vec2(cos(angle), sin(angle)) * float(ring) * 0.5;
}

float ring_weight(int ring) {
	return ring == 1 ? 1.0 : OUTER_WEIGHT;
}

vec3 blurred_screen(vec2 uv, vec2 pixel, float radius_px) {
	vec3 sum = texture(screen, uv).rgb;
	float weight = 1.0;
	for (int ring = 1; ring <= 2; ring++) {
		for (int k = 0; k < RING_TAPS; k++) {
			sum += texture(screen, uv + ring_tap(ring, k) * radius_px * pixel).rgb * ring_weight(ring);
			weight += ring_weight(ring);
		}
	}
	return sum / weight;
}

// The picture at uv, with Seen from 0 (he does not see it) to 1 (he does).
vec4 vision_color(float seen, vec2 uv, vec2 pixel) {
	vec3 sharp = texture(screen, uv).rgb;
	vec3 unseen = sharp;
	if (unseen_blur_px > 0.0 && seen < 0.999) {
		unseen = blurred_screen(uv, pixel, unseen_blur_px);
	}
	return vec4(mix(unseen * outside, sharp, seen), 1.0);
}
