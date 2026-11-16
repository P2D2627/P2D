// PROTOTYPE (#257): a mote of the air's dust that sways as the wind carries it, each on its own beat
// and at its own pace, so the air never moves in straight lines. The seed is the mote's random anim
// offset (INSTANCE_CUSTOM.z, 0 to 1); the sway is in px on screen, whatever the mote's scale.
shader_type canvas_item;

uniform float sway_px = 10.0;
// Radians per second of the slowest mote; the fastest goes Pace Range times as fast.
uniform float sway_speed = 0.5;
uniform float pace_range = 1.8;

void vertex() {
	float seed = INSTANCE_CUSTOM.z;
	float pace = sway_speed * mix(1.0, pace_range, fract(seed * 5.31));
	float phase = seed * 6.2832;
	vec2 sway = vec2(sin(TIME * pace + phase), sin(TIME * pace * 1.37 + phase * 2.1)) * sway_px;
	VERTEX += sway / max(length(MODEL_MATRIX[0].xy), 0.0001);
}
