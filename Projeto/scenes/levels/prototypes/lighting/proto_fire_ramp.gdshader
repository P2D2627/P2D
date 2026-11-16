shader_type canvas_item;
render_mode unshaded;

// PROTOTYPE (#261): the flame's own colour ramp. Each pixel's brightness picks a colour from the
// fire's ramp, which starts at a deep wine near the cave's darkest colour and ends in a warm core
// close to white, so the flame's edges belong to the cave and its core stays the brightest thing
// on screen. Unshaded, as the flame was before, so it shows in the dark.

// The fire's ramp, dark on the left and light on the right.
uniform sampler2D ramp : source_color, filter_linear, repeat_disable;
// The flame art's brightest luminance, which takes the ramp's light end: the drawn fires are flat
// pinks and magentas, far from white.
uniform float brightest : hint_range(0.05, 1.0) = 1.0;

// The vertex colour carries the node's Modulate, whose alpha hides the fire out of the man's sight.
varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec4 texel = texture(TEXTURE, UV);
	float luminance = dot(texel.rgb, vec3(0.299, 0.587, 0.114));
	float along = clamp(luminance / brightest, 0.0, 1.0);
	COLOR = vec4(texture(ramp, vec2(along, 0.5)).rgb * tint.rgb, texel.a * tint.a);
}
