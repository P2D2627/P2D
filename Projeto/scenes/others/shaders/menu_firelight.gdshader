// A light on a painted character from one side (From Side): the fire's from below, the rays' from
// the top right. His own painting added over himself, strongest at that side and gone a Reach of
// his size in, so his lit parts brighten most and his painted light and shade stay. Strength and
// Shift are set each frame by the menu's backdrop: the light wavers with its source, and its edge
// moves across him with it.
shader_type canvas_item;
render_mode blend_add;

uniform vec4 light_color : source_color = vec4(1.0, 0.55, 0.32, 1.0);
uniform float strength = 0.0;
// The side the light comes from, in his rect: (0, 1) below, (1, 0) the right, (0.7, -0.7) the top
// right.
uniform vec2 from_side = vec2(0.0, 1.0);
// How far in from that side the light reaches, as a share of his size.
uniform float reach : hint_range(0.05, 1.0) = 0.6;
// How far the light's edge has moved in (above 0) or out (below 0), as a share of his size.
uniform float shift = 0.0;
// The same fade into the dark at his left edge as his painting's (menu_paint_fade), so the light
// ends where he does.
uniform float left_fade : hint_range(0.0, 0.5) = 0.18;

void fragment() {
	vec4 painted = texture(TEXTURE, UV);
	float toward = dot(UV - vec2(0.5), normalize(from_side)) + 0.5;
	float lit = smoothstep(1.0 - reach, 1.0, toward + shift);
	float whole = clamp(UV.x / max(left_fade, 0.0001), 0.0, 1.0);
	lit *= whole * whole * (3.0 - 2.0 * whole);
	COLOR = vec4(painted.rgb * light_color.rgb * lit * strength, painted.a);
}
