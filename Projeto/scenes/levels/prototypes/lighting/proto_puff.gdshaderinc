// PROTOTYPE (#257): a puff of dust or smoke for CPUParticles2D. A soft disc broken up by noise, a
// little lighter on top, that erodes from its thin edges inwards as it ages (alpha erosion), instead
// of a round blob that only fades. Each particle reads its own patch of the noise from its random
// anim offset (INSTANCE_CUSTOM.z, 0 to 1) and its age from INSTANCE_CUSTOM.y (0 to 1 over its life).
// The particle's texture only gives the quad its size.

uniform sampler2D noise_texture : repeat_enable, filter_linear;
// The share of the noise texture one particle covers: smaller, smoother shapes.
uniform float noise_scale = 0.8;
// How much of the shape is eaten by the end of its life, and how wide the eroding edge is: a narrow
// edge gives clumps with a soft rim; a wide one, a blur.
uniform float erosion = 0.75;
uniform float edge_softness = 0.15;
// How much lighter the top of the puff is than its bottom.
uniform float top_light = 0.3;

varying vec2 noise_offset;
varying float age;

void vertex() {
	float seed = INSTANCE_CUSTOM.z;
	noise_offset = vec2(fract(seed * 7.13), fract(seed * 3.71 + 0.37));
	age = INSTANCE_CUSTOM.y;
}

void fragment() {
	vec2 centered = UV * 2.0 - 1.0;
	float disc = 1.0 - smoothstep(0.1, 1.0, length(centered));
	float noise = texture(noise_texture, UV * noise_scale + noise_offset).r;
	float shape = disc * (0.15 + 1.1 * noise);
	float threshold = 0.1 + erosion * age;
	float alpha = smoothstep(threshold, threshold + edge_softness, shape);
	float light = 1.0 + top_light * (0.5 - UV.y);
	COLOR = vec4(COLOR.rgb * light, COLOR.a * alpha);
}
