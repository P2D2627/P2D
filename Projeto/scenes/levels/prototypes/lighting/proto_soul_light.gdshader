shader_type canvas_item;
render_mode blend_add, unshaded;

// PROTOTYPE (#263): proto_soul_light.gd's ribbon, light leaving the man's body. It is added to the
// scene, so it lights what is behind it and is never grey or opaque. Across the ribbon (UV.y) it is
// full in the middle and soft out to Body Share of the half width, which flames push further as the
// light ages: blobs of noise rolling up through the world and tongues running back along the ribbon.
// Age (vertex red, 0 new to 1 gone) dims it along the same noise, softly (a hard cut left dark
// specks in recordings), so the tail breaks into wisps before it is gone. Along the ribbon (UV.x,
// the distance he had gone) a stretched noise draws fine streaks in the direction he moved. It is
// cut into Bands flat tones with crisp edges, as the level's drawn flames, in the level's pinks: the
// core in the strongest band, the halo colour outside. The strength of his momentum comes in the
// vertex green. The clock steps at the prototype's ink rate, so the flames move in held drawings.

uniform sampler2D noise_texture : repeat_enable, filter_linear;
uniform vec4 core_color : source_color = vec4(1.0, 0.92, 0.96, 1.0);
uniform vec4 halo_color : source_color = vec4(1.0, 0.45, 0.78, 1.0);
uniform float intensity : hint_range(0.0, 3.0) = 1.0;
// How much of the light is added at most: it is there, but does not take over.
uniform float opacity : hint_range(0.0, 1.0) = 0.3;
// The flat bands of tone it is cut into.
uniform float bands : hint_range(1.0, 6.0) = 3.0;
uniform float body_share : hint_range(0.1, 1.0) = 0.55;
// How far the flame tongues reach past the body, as a share of the half width.
uniform float feather : hint_range(0.0, 1.0) = 0.55;
// The flames' noise: its scale per world px, and how it rolls through the world, in px/s.
uniform float flame_scale = 0.006;
uniform vec2 flame_flow = vec2(0.0, 150.0);
// The tongues: their length (noise per 100 px of his path; smaller, longer) and how fast they run
// back along the ribbon.
uniform float tongue_length = 0.3;
uniform float tongue_speed = 0.9;
// Streaks: how many across the ribbon, and how strongly they show.
uniform float streak_count = 7.0;
uniform float streak_amount : hint_range(0.0, 1.0) = 0.45;
// Set by the script each frame: its own clock, so the flames stop with the game's pause.
uniform float clock = 0.0;

varying vec2 world;
varying float life;
varying float strength;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	life = COLOR.r;
	strength = COLOR.g;
}

void fragment() {
	float across = abs(UV.y * 2.0 - 1.0);
	// Blobs rolling up through the world, and tongues running back along the ribbon.
	float rising = texture(noise_texture, (world + flame_flow * clock) * flame_scale).r;
	float tongues = texture(noise_texture,
			vec2(UV.x * tongue_length - clock * tongue_speed, UV.y * 0.8)).r;
	float flame = 0.5 * rising + 0.5 * tongues;
	// Full in the middle and soft to the edge, which the flames push out, further as it ages.
	float reach = body_share + (flame - 0.5) * feather * (0.6 + life);
	float shape = 1.0 - smoothstep(reach * 0.45, reach, across);
	// Age dims the light where the flames are lowest first, softly: the tail comes apart in wisps.
	float kept = smoothstep(life - 0.3, life + 0.2, flame);
	// Slow along (UV.x is px gone / 100) and fast across: lines in the direction he moved.
	float streak = texture(noise_texture, vec2(UV.x * 0.06, UV.y * streak_count * 0.13)).r;
	float bright = mix(1.0, 0.6 + 0.8 * streak, streak_amount);
	float fade = pow(max(1.0 - life, 0.0), 1.3) * strength;
	float amount = clamp(shape * kept * fade * bright, 0.0, 1.0);
	// Flat bands of tone with crisp edges, as the level's drawn flames: the halo colour outside,
	// the core in the strongest band.
	float scaled = amount * bands;
	float banded = (floor(scaled) + smoothstep(0.45, 0.55, fract(scaled))) / bands;
	vec3 color = mix(halo_color.rgb, core_color.rgb, banded * banded);
	COLOR = vec4(color * intensity, banded * opacity);
}
