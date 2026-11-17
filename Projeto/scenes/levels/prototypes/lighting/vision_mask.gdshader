shader_type canvas_item;
// PROTOTYPE (#257): the man's sight by distance field, soft and with no rays to leave streaks. Put
// on a full-screen ColorRect in a CanvasLayer above the level. From each pixel, a march towards his
// eyes through Godot's SDF of the rock's occluders.
// His eyes count as a disc of Eye Radius: the closer the rock comes to the line, the less of the disc
// the pixel sees, so the edge of his sight is a penumbra that widens away from the rock that casts
// it. A pixel inside the rock counts if it is within Wall Depth of a face he looks at, so he sees the
// rock's faces and not what is behind them.
render_mode unshaded;

#include "res://scenes/levels/prototypes/lighting/vision_common.gdshaderinc"

// The eyes, in screen UV, and screen UV per world px; the disc's radius and how deep into rock a
// face still counts, in world px.
uniform vec2 eye_uv = vec2(0.5);
uniform float uv_per_world = 0.0005;
uniform float eye_radius = 40.0;
uniform float wall_depth = 24.0;

// Most march steps per pixel, and the least step, in SDF px, plus a share of the distance gone.
const int MARCH_STEPS = 72;
const float LEAST_STEP = 1.0;
const float STEP_GROWTH = 0.01;
// SDF px past the rock's face before the march starts, so the face does not shade itself.
const float FACE_GAP = 2.0;

// The march stays in fragment(): in the Compatibility renderer (4.7.2), texture_sdf() and
// screen_uv_to_sdf() are not defined for a shader's own functions.
void fragment() {
	float seen = 1.0;
	vec2 from = screen_uv_to_sdf(SCREEN_UV);
	vec2 eye = screen_uv_to_sdf(eye_uv);
	float sdf_per_world = (screen_uv_to_sdf(vec2(uv_per_world, 0.0)) - screen_uv_to_sdf(vec2(0.0))).x;
	vec2 to_eye = eye - from;
	float dist = length(to_eye);
	if (dist >= 1.0) {
		vec2 dir = to_eye / dist;
		// Out of the rock first, towards the eyes: past Wall Depth, it is behind the face.
		float t = 0.0;
		float h = texture_sdf(from);
		float wall = wall_depth * sdf_per_world;
		for (int i = 0; i < 16 && h < 0.0 && t <= wall; i++) {
			t += max(-h, LEAST_STEP);
			h = texture_sdf(from + dir * t);
		}
		if (h < 0.0) {
			seen = 0.0;
		} else {
			// The disc shrinks when the eyes are closer than its radius to the rock.
			float radius = min(eye_radius * sdf_per_world, max(texture_sdf(eye), LEAST_STEP));
			float origin = t;
			float span = max(dist - origin, 1.0);
			float res = 1.0;
			t += FACE_GAP;
			for (int i = 0; i < MARCH_STEPS && t < dist; i++) {
				h = texture_sdf(from + dir * t);
				float cone = max(radius * (t - origin) / span, 0.5);
				res = min(res, h / cone);
				if (res <= -1.0) {
					break;
				}
				t += max(abs(h), LEAST_STEP + t * STEP_GROWTH);
			}
			seen = smoothstep(-1.0, 1.0, clamp(res, -1.0, 1.0));
		}
	}
	COLOR = vision_color(seen, SCREEN_UV, SCREEN_PIXEL_SIZE);
}
