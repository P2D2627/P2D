shader_type canvas_item;

// Depth fade: darkens scenery the further below a world height it sits, so a stone floor sinks
// into the dark ground under it. Put it in a ShaderMaterial on the parent node and turn on
// Use Parent Material in each child. 2D lights still act on the result.

// World Y where the darkening starts; everything above it keeps its own color.
uniform float fade_start_y = 0.0;
// How many pixels below fade_start_y the color takes to reach min_brightness.
uniform float fade_length : hint_range(1.0, 1000.0) = 100.0;
// Brightness at the end of the fade: 0 is black, 1 turns the fade off.
uniform float min_brightness : hint_range(0.0, 1.0) = 0.0;

varying float world_y;

void vertex() {
	world_y = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).y;
}

void fragment() {
	// COLOR already holds the texture times Modulate; sampling TEXTURE again would square the gray.
	float depth = clamp((world_y - fade_start_y) / fade_length, 0.0, 1.0);
	COLOR.rgb *= mix(1.0, min_brightness, depth);
}
