// A painted character fading into the dark at his rect's left edge, where the painting is cut: from
// nothing at the edge to whole a Left Fade of his width in, smoothly, so he comes out of the dark
// instead of ending in a straight line.
shader_type canvas_item;

// How far in from his left edge he is whole, as a share of his width.
uniform float left_fade : hint_range(0.0, 0.5) = 0.18;

void fragment() {
	float whole = clamp(UV.x / max(left_fade, 0.0001), 0.0, 1.0);
	COLOR = texture(TEXTURE, UV);
	COLOR.a *= whole * whole * (3.0 - 2.0 * whole);
}
