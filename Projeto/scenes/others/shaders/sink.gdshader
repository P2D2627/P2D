shader_type canvas_item;

// Sinks a drawing into the floor (ADR 0026): moves it down by sink_depth px and leaves out what
// passes below its feet, which are on the drawing's own y = 0. SinkingDrawing sets sink_depth, and
// flash, which whitens the drawing and keeps its shape (#263).

uniform float sink_depth = 0.0;
uniform float flash : hint_range(0.0, 1.0) = 0.0;

// Px below the feet; above them it is negative.
varying float below_feet;

void vertex() {
	VERTEX.y += sink_depth;
	below_feet = VERTEX.y;
}

void fragment() {
	if (below_feet > 0.0) {
		discard;
	}
	COLOR.rgb = mix(COLOR.rgb, vec3(1.0), flash);
}
