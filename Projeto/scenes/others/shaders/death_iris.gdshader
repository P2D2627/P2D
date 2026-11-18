// The dark of a restart (#263): ink everywhere outside a circle around Centre, whose edge wanders
// in and out by Wobble px in Lobes bumps, so it reads drawn by hand, as strong as Fade. Phase turns
// the bumps; the level changes it on each frame of the effects, as the rest of the hand-drawn
// effects step. A radius of 0 leaves no circle, so Fade alone darkens the whole screen. All lengths
// are in the rect's own px: Size is the rect's size.
shader_type canvas_item;

uniform vec2 centre = vec2(0.0);
uniform float radius = 0.0;
uniform vec2 size = vec2(1920.0, 1080.0);
uniform float wobble = 0.0;
uniform float lobes = 7.0;
uniform float phase = 0.0;
uniform vec4 ink : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float fade : hint_range(0.0, 1.0) = 1.0;

// The edge's bumps: a big wave of Lobes round it and a smaller, faster one that turns the other way,
// so the outline is not a regular star. The two shares add up to 1, so Wobble is the most it moves.
const float BIG_WAVE = 0.6;
const float SMALL_WAVE = 0.4;
const float SMALL_WAVE_TURN = 1.7;

void fragment() {
	vec2 offset = UV * size - centre;
	float angle = atan(offset.y, offset.x);
	float bumps = BIG_WAVE * sin(angle * lobes + phase)
			+ SMALL_WAVE * sin(angle * (2.0 * lobes + 1.0) - SMALL_WAVE_TURN * phase);
	float edge = radius + wobble * bumps;
	// Closed, it covers every pixel, its centre too.
	float outside = radius <= 0.0 ? 1.0 : smoothstep(edge - 1.0, edge + 1.0, length(offset));
	COLOR = vec4(ink.rgb, ink.a * outside * fade);
}
