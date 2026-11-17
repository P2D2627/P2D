shader_type canvas_item;
// PROTOTYPE (#257): the man's sight as a polygon. His field of view, cast exactly to the rock's
// corners, is drawn white on a smaller clear viewport (Mask) and read through a wide blur, so its
// edge fades out. Put on a full-screen ColorRect in a CanvasLayer above the level.
render_mode unshaded;

#include "res://scenes/levels/prototypes/lighting/vision_common.gdshaderinc"

uniform sampler2D mask : filter_linear, repeat_disable;
// The blur's radius, in screen px.
uniform float mask_blur_px = 24.0;

float blurred_mask(vec2 uv, vec2 pixel, float radius_px) {
	float sum = texture(mask, uv).a;
	float weight = 1.0;
	for (int ring = 1; ring <= 2; ring++) {
		for (int k = 0; k < RING_TAPS; k++) {
			sum += texture(mask, uv + ring_tap(ring, k) * radius_px * pixel).a * ring_weight(ring);
			weight += ring_weight(ring);
		}
	}
	return sum / weight;
}

void fragment() {
	float seen = smoothstep(0.0, 1.0, blurred_mask(SCREEN_UV, SCREEN_PIXEL_SIZE, mask_blur_px));
	COLOR = vision_color(seen, SCREEN_UV, SCREEN_PIXEL_SIZE);
}
