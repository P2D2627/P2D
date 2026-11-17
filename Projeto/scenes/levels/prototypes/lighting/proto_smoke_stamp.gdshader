shader_type canvas_item;
render_mode unshaded;

// PROTOTYPE (#261): one stamp of proto_smoke.gd. It writes only how much smoke there is, in alpha:
// its soft round (the texture) eaten by noise held in the world, times its weight, which the script
// puts in the stamp's modulate alpha: it takes no slot in the global buffer instance uniforms share
// (with a pool per dog, an instance uniform per stamp ran it out in a recording: "Too many instances
// using shader instance variables"). The group lays the stamps one over another, keeps what passes
// its threshold and colours it, so a thinning stamp erodes along the same noise as its neighbours and
// the smoke's edge reads as one.

uniform sampler2D noise_texture : repeat_enable, filter_linear;
// The noise's scale per world px: smaller, larger clumps.
uniform float noise_scale = 0.008;
// How much of the round the noise can eat: 0 none, 1 all of it where the noise is lowest.
uniform float noise_share = 0.65;
// Set by the group each frame: how far the noise has rolled, in world px.
uniform vec2 drift = vec2(0.0);

varying vec2 world;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	// COLOR comes in as the texture times the modulate: its alpha is the round times the weight.
	float noise = texture(noise_texture, (world + drift) * noise_scale).r;
	COLOR = vec4(1.0, 1.0, 1.0, COLOR.a * mix(1.0, noise, noise_share));
}
