shader_type canvas_item;

// Gradient map: scenery is painted in grays, and this shader swaps each gray for a color of the
// level's ramp. Near white takes the ramp's left color, near black its right one.
// Put it in a ShaderMaterial on any CanvasItem (Sprite2D, TileMapLayer, Parallax2D layer); a
// BackgroundLayer gives it to its pieces through its Ramp.

// The ramp, light on the left and black on the right, as the art paints them: a strip painted by
// the art (a 256 × 1 PNG) or a GradientTexture1D. Only the middle row is read.
uniform sampler2D ramp : source_color, filter_linear, repeat_disable;
// On for a ramp painted the other way, black on the left and light on the right.
uniform bool reverse = false;

// The vertex color, which carries the node's Modulate and Self Modulate.
varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	// Read the texture itself, not COLOR, so a node's Modulate does not shift the gray.
	vec4 gray = texture(TEXTURE, UV);
	float luminance = dot(gray.rgb, vec3(0.299, 0.587, 0.114));
	float along = reverse ? luminance : 1.0 - luminance;
	// The ramp's color, tinted by Modulate as any sprite is; the alpha keeps the PNG's transparency
	// and Modulate's alpha.
	COLOR = vec4(texture(ramp, vec2(along, 0.5)).rgb * tint.rgb, gray.a * tint.a);
}
