shader_type canvas_item;
uniform float blink = 0.0;
uniform float jaw = 0.0;
uniform int species = 0;
uniform vec3 skin_color : source_color = vec3(0.25, 0.05, 0.4);
vec4 eyelid(vec4 color, vec2 uv, vec2 center, vec2 radius) {
	vec2 eye = (uv - center) / radius;
	float boundary = (1.0 - smoothstep(0.88, 1.0, length(eye)));
	float lid = smoothstep(1.0 - blink, 1.06 - blink, abs(eye.y));
	color.rgb = mix(color.rgb, skin_color * (0.7 + 0.3 * (1.0 - abs(eye.y))), boundary * lid * step(0.01, blink));
	return color;
}
void fragment() {
	vec2 uv = UV;
	// Deform only the lower jaw; the eye and skull stay anchored.
	float lower = smoothstep(0.63, 0.85, uv.y) * (1.0 - smoothstep(0.68, 0.9, uv.x));
	if (species != 1) { uv.y -= jaw * 0.035 * lower; uv.x += jaw * 0.012 * lower; }
	else { uv.x += jaw * 0.008 * (1.0 - smoothstep(0.2, 0.5, uv.x)); }
	vec4 color = texture(TEXTURE, uv);
	if (species == 0) { color = eyelid(color, uv, vec2(0.33, 0.43), vec2(0.13, 0.16)); }
	if (species == 1) { color = eyelid(color, uv, vec2(0.40, 0.50), vec2(0.115, 0.15)); }
	if (species == 2) {
		color = eyelid(color, uv, vec2(0.38, 0.46), vec2(0.10, 0.12));
		color = eyelid(color, uv, vec2(0.65, 0.36), vec2(0.07, 0.09));
		color = eyelid(color, uv, vec2(0.56, 0.55), vec2(0.055, 0.07));
		color = eyelid(color, uv, vec2(0.61, 0.68), vec2(0.055, 0.07));
	}
	COLOR = color * COLOR;
}
