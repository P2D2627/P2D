shader_type canvas_item;

// The dialogue wheel's drawings, white with a black outline as drawn, so they read on any
// background. Lit, the answer pointed at, they show the inverse: black with a white outline.

uniform bool lit = false;

void fragment() {
	vec4 drawing = texture(TEXTURE, UV);
	if (lit) {
		drawing.rgb = vec3(1.0) - drawing.rgb;
	}
	// COLOR already holds the texture's colour: only the alpha it brings is kept, so a fade still
	// fades the drawing, and the colour is the drawing's own, inverted or not.
	COLOR = vec4(drawing.rgb, COLOR.a);
}
