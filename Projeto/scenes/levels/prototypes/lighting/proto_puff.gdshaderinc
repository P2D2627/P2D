// PROTOTYPE (#257, ink style #261): a puff of dust or smoke, or a shard of light, for CPUParticles2D.
// A shape broken up by noise that erodes from its thin edges inwards as it ages (alpha erosion),
// instead of a blob that only fades. Each particle reads its own patch of the noise from its random
// anim offset (INSTANCE_CUSTOM.z, 0 to 1). The particle's texture only gives the quad its size.
// Soft style: a soft edge, a little lighter on top. Ink style: drawn like the characters, in two flat
// tones with a dark ink line where the shape is eaten; the emitter holds each image for a few frames
// (its Fixed FPS), so the effect moves like a drawing and not like a simulation.

uniform sampler2D noise_texture : repeat_enable, filter_linear;
// The share of the noise texture one particle covers: smaller, smoother shapes.
uniform float noise_scale = 0.8;
// How much of the shape is eaten by the end of its life, and how wide the eroding edge is: a narrow
// edge gives clumps with a soft rim; a wide one, a blur.
uniform float erosion = 0.75;
uniform float edge_softness = 0.15;
// How much lighter the top of the puff is than its bottom (soft style).
uniform float top_light = 0.3;
// The shape: a cloud (a disc), or a shard (a diamond that fills the quad, long when the quad is).
uniform bool shard = false;
uniform bool ink_style = false;
// Ink style: how far into the shape, in shape units, the ink line reaches from the eaten edge (0 for
// none, as on light), its colour (the characters' outline), where the light tone starts, and the two
// tones, times the particle's colour.
uniform float ink_width : hint_range(0.0, 0.5) = 0.07;
uniform vec4 ink_color : source_color = vec4(0.1, 0.05, 0.09, 1.0);
uniform float core_from : hint_range(0.0, 1.0) = 0.3;
uniform float core_tone : hint_range(0.0, 2.0) = 1.2;
uniform float body_tone : hint_range(0.0, 2.0) = 0.8;

#ifdef SPRITE_INSTANCE
// A Sprite2D that a script moves, not a particle: its share of life and its seed come as instance
// uniforms.
instance uniform float life_share = 0.0;
instance uniform float seed = 0.0;
#endif

varying vec2 noise_offset;
varying float age;

void vertex() {
#ifdef SPRITE_INSTANCE
	float random = seed;
	age = life_share;
#else
	float random = INSTANCE_CUSTOM.z;
	// The share of its own life: .y counts against the emitter's Lifetime and .w is this particle's
	// share of it, below 1 with Lifetime Randomness, so .y alone may never reach 1.
	age = INSTANCE_CUSTOM.w > 0.0 ? clamp(INSTANCE_CUSTOM.y / INSTANCE_CUSTOM.w, 0.0, 1.0) : INSTANCE_CUSTOM.y;
#endif
	noise_offset = vec2(fract(random * 7.13), fract(random * 3.71 + 0.37));
}

void fragment() {
	vec2 centered = UV * 2.0 - 1.0;
	float mask = shard
			? clamp(1.0 - abs(centered.x) - abs(centered.y), 0.0, 1.0) * 2.0
			: 1.0 - smoothstep(0.1, 1.0, length(centered));
	float noise = texture(noise_texture, UV * noise_scale + noise_offset).r;
	// A cloud is mostly noise; a shard keeps its diamond and the noise only chips its edges.
	float shape = shard ? mask * (0.55 + 0.7 * noise) : mask * (0.15 + 1.1 * noise);
	float threshold = 0.1 + erosion * age;
	if (ink_style) {
		// One screen px of smoothing on every hard edge, so the flat tones do not stair-step.
		float px = max(fwidth(shape), 0.0001);
		float inside = shape - threshold;
		float alpha = smoothstep(-px, px, inside);
		float core = smoothstep(core_from - px, core_from + px, inside);
		float ink = ink_width > 0.0 ? 1.0 - smoothstep(ink_width - px, ink_width + px, inside) : 0.0;
		vec3 tone = COLOR.rgb * mix(body_tone, core_tone, core);
		COLOR = vec4(mix(tone, ink_color.rgb, ink * ink_color.a), COLOR.a * alpha);
	} else {
		float alpha = smoothstep(threshold, threshold + edge_softness, shape);
		float light = 1.0 + top_light * (0.5 - UV.y);
		COLOR = vec4(COLOR.rgb * light, COLOR.a * alpha);
	}
}
