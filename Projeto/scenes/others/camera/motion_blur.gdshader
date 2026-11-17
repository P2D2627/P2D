// A streak along the camera's move: each pixel is the mean of the screen along Streak, centred on
// it, as a camera's shutter left open while it pans. Drawn by MotionBlur over the level.
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear, repeat_disable;
// The streak's length and way, as a share of the screen (UV).
uniform vec2 streak = vec2(0.0);
// How many points along the streak are averaged: more is smoother and costs more.
uniform int samples : hint_range(2, 32) = 12;

void fragment() {
	vec3 sum = vec3(0.0);
	for (int i = 0; i < samples; i++) {
		float along = float(i) / float(samples - 1) - 0.5;
		sum += texture(screen_texture, SCREEN_UV + streak * along).rgb;
	}
	COLOR = vec4(sum / float(samples), 1.0);
}
