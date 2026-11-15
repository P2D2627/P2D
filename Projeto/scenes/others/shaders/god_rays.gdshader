// Rays of light from a corner of the screen, for the menus: soft beams that sway slowly, brightest
// at their source and fading as they reach across, added over what is behind them.
shader_type canvas_item;
render_mode blend_add;

// The colour of the light: white with a warm touch.
uniform vec4 ray_color : source_color = vec4(1.0, 0.96, 0.82, 1.0);
// How bright the rays are.
uniform float strength : hint_range(0.0, 3.0) = 0.6;
// Where the light comes from, in screen UV: past the top right corner.
uniform vec2 origin = vec2(1.04, -0.08);
// Which way the rays go, in radians from the screen's right, clockwise (y goes down).
uniform float direction : hint_range(-3.1416, 3.1416) = 2.6;
// How wide the fan of rays is, in radians.
uniform float fan_width : hint_range(0.1, 3.1416) = 1.1;
// How far the rays reach, as a share of the screen's height.
uniform float reach : hint_range(0.05, 3.0) = 0.8;
// How many beams there are across the fan.
uniform float beams : hint_range(1.0, 60.0) = 7.0;
// How fast the beams sway.
uniform float sway_speed : hint_range(0.0, 2.0) = 0.12;
// The glow around the source.
uniform float glow : hint_range(0.0, 3.0) = 0.55;
// How far the glow spreads, as a share of the screen's height.
uniform float glow_size : hint_range(0.01, 1.0) = 0.3;

void fragment() {
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 p = (SCREEN_UV - origin) * vec2(aspect, 1.0);
	float dist = length(p);
	float angle = atan(p.y, p.x);
	float off = angle - direction;
	off = atan(sin(off), cos(off));
	float fan = smoothstep(fan_width * 0.5, 0.0, abs(off));
	float t = TIME * sway_speed;
	float a = off * beams;
	float rays = 0.5 + 0.5 * sin(a + t * 3.1);
	rays *= 0.6 + 0.4 * sin(a * 1.73 - t * 2.3 + 1.7);
	rays *= 0.7 + 0.3 * sin(a * 0.47 + t * 1.3 + 4.1);
	float falloff = exp(-dist / reach);
	float light = strength * fan * falloff * (0.45 + 0.55 * rays);
	light += glow * exp(-dist / glow_size);
	COLOR = vec4(ray_color.rgb * light, 1.0);
}
