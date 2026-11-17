shader_type canvas_item;
// PROTOTYPE (#257, mode B): multiplies the whole picture by the spread light, so only what the light
// reaches is seen. Put on a full-screen ColorRect in a CanvasLayer above the level. The light comes
// from two maps in world space: the fires', over the whole level, and the man's aura, a patch that
// moves with him and fades from its last place to its new one. Both are read with a smooth (bicubic
// B-spline) filter, so the cells never show, and a little noise breaks the bands in the dark.
render_mode unshaded, blend_mul;

uniform sampler2D fire_map : filter_linear, repeat_disable;
uniform vec2 fire_map_cells = vec2(1.0);
uniform vec2 fire_map_origin;
uniform float fire_cell = 24.0;
uniform sampler2D aura_map : filter_linear, repeat_disable;
uniform sampler2D aura_map_old : filter_linear, repeat_disable;
uniform vec2 aura_cells = vec2(1.0);
uniform vec2 aura_origin;
uniform vec2 aura_origin_old;
uniform float aura_cell = 48.0;
uniform float aura_blend = 1.0;
uniform vec3 aura_color = vec3(1.0);
uniform float aura_energy = 1.0;
uniform vec3 ambient = vec3(0.3);
// The canvas transform, world to screen: screen = world * canvas_scale + canvas_origin.
uniform vec2 canvas_origin;
uniform float canvas_scale = 1.0;
uniform vec2 view_size = vec2(1920.0, 1080.0);

vec4 cubic(float v) {
	vec4 n = vec4(1.0, 2.0, 3.0, 4.0) - v;
	vec4 s = n * n * n;
	float x = s.x;
	float y = s.y - 4.0 * s.x;
	float z = s.z - 4.0 * s.y + 6.0 * s.x;
	float w = 6.0 - x - y - z;
	return vec4(x, y, z, w) * (1.0 / 6.0);
}

vec3 bicubic(sampler2D map, vec2 uv, vec2 cells) {
	vec2 st = uv * cells - 0.5;
	vec2 base = floor(st);
	vec2 f = st - base;
	vec4 xc = cubic(f.x);
	vec4 yc = cubic(f.y);
	vec4 c = vec4(base.x - 0.5, base.x + 1.5, base.y - 0.5, base.y + 1.5);
	vec4 s = vec4(xc.x + xc.y, xc.z + xc.w, yc.x + yc.y, yc.z + yc.w);
	vec4 offset = (c + vec4(xc.y, xc.w, yc.y, yc.w) / s) / vec4(cells.x, cells.x, cells.y, cells.y);
	vec3 s0 = texture(map, offset.xz).rgb;
	vec3 s1 = texture(map, offset.yz).rgb;
	vec3 s2 = texture(map, offset.xw).rgb;
	vec3 s3 = texture(map, offset.yw).rgb;
	float sx = s.x / (s.x + s.y);
	float sy = s.z / (s.z + s.w);
	return mix(mix(s3, s2, sx), mix(s1, s0, sx), sy);
}

void fragment() {
	vec2 screen = SCREEN_UV * view_size;
	vec2 world = (screen - canvas_origin) / canvas_scale;
	vec3 fires = bicubic(fire_map, (world - fire_map_origin) / fire_cell / fire_map_cells, fire_map_cells);
	float aura_new = bicubic(aura_map, (world - aura_origin) / aura_cell / aura_cells, aura_cells).r;
	float aura_old = bicubic(aura_map_old, (world - aura_origin_old) / aura_cell / aura_cells, aura_cells).r;
	vec3 light = ambient + fires + aura_color * aura_energy * mix(aura_old, aura_new, aura_blend);
	float noise = fract(sin(dot(screen, vec2(12.9898, 78.233))) * 43758.5453);
	COLOR = vec4(min(light, vec3(1.0)) + (noise - 0.5) / 255.0, 1.0);
}
