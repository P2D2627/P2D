shader_type canvas_item;
// PROTOTYPE (#257): a fire far in the background, out of focus. Blurs the drawing over two rings of
// samples around each pixel, Blur Px apart in the texture's pixels, and ignores the level's light,
// since a fire makes its own.
render_mode unshaded;

uniform float blur_px = 5.0;

void fragment() {
	vec2 step_uv = TEXTURE_PIXEL_SIZE * blur_px;
	vec4 sum = texture(TEXTURE, UV) * 0.16;
	for (int i = 0; i < 8; i++) {
		float angle = float(i) * 0.785398;
		vec2 direction = vec2(cos(angle), sin(angle));
		sum += texture(TEXTURE, UV + direction * step_uv) * 0.06;
		sum += texture(TEXTURE, UV + direction * step_uv * 2.0) * 0.045;
	}
	COLOR = sum * COLOR;
}
