shader_type canvas_item;

// Sinks a drawing into the floor (ADR 0026): moves it down by sink_depth px and leaves out what
// passes below its feet, which are on the drawing's own y = 0. SinkingDrawing sets sink_depth.

uniform float sink_depth = 0.0;

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
}
