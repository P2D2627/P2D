shader_type canvas_item;

// Rim fade: darkens the part of a rim piece that lies inside the rock, from the rock's surface inwards, so the
// stones sink into the dark ground wherever the rim runs: floors, ceilings, walls and corners. It works in the
// drawing's own pixels, so it follows each piece however it is turned or flipped. 2D lights still act on the result.

// 0: a strip, whose rock surface is the row surface_row. 1: an outer corner. 2: an inner corner. Corners are drawn
// open up and left, with the tiles' corner on corner_point.
uniform int mode = 0;
uniform float surface_row = 34.0;
uniform vec2 corner_point = vec2(0.0);
// How many of the drawing's pixels past the surface the color takes to reach min_brightness.
uniform float fade_length = 50.0;
// Brightness at the end of the fade: 0 is black, 1 turns the fade off.
uniform float min_brightness : hint_range(0.0, 1.0) = 0.35;

void fragment() {
	vec2 pixel = UV / TEXTURE_PIXEL_SIZE;
	float depth;
	if (mode == 0) {
		depth = pixel.y - surface_row;
	} else {
		vec2 inside = pixel - corner_point;
		// Outer corner: rock only past both edges. Inner corner: rock past either edge.
		depth = mode == 1 ? min(inside.x, inside.y) : max(inside.x, inside.y);
	}
	// COLOR already holds the texture times Modulate; sampling TEXTURE again would square the gray.
	COLOR.rgb *= mix(1.0, min_brightness, clamp(depth / fade_length, 0.0, 1.0));
}
