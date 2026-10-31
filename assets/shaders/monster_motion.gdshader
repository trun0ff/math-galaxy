shader_type canvas_item;
uniform float damage_fraction = 0.0;
uniform float impact_flash = 0.0;
uniform float clock = 0.0;
uniform vec3 impact_color : source_color = vec3(0.5, 0.85, 1.0);
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
float crack_distance(vec2 point, vec2 start, vec2 finish) {
	vec2 line = finish - start;
	float distance_along = clamp(dot(point - start, line) / dot(line, line), 0.0, 1.0);
	return length(point - start - line * distance_along);
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
	// Scorch marks and branching fissures accumulate with lost HP.
	for (int scar = 0; scar < 3; scar++) {
		vec2 center = vec2(0.56 + float(scar) * 0.06, 0.52 - float(scar) * 0.13);
		float active = step(float(scar) * 0.3 + 0.05, damage_fraction);
		float scorch = exp(-length((uv - center) / vec2(0.048, 0.07)) * 1.6) * active;
		color.rgb = mix(color.rgb, vec3(0.025, 0.018, 0.045), scorch * 0.8);
		float fissure = min(crack_distance(uv, center + vec2(-0.03,-0.06), center), crack_distance(uv,center,center + vec2(-0.02,0.05)));
		fissure = min(fissure, crack_distance(uv,center,center+vec2(0.04,0.018)));
		float glow = (1.0-smoothstep(0.003,0.011,fissure)) * active;
		color.rgb = mix(color.rgb,vec3(1.0,0.45,0.14),glow*(0.55+0.18*sin(clock*12.0+float(scar))));
	}
	color.rgb = mix(color.rgb, impact_color * 0.65 + vec3(0.45), impact_flash * 0.35);
	COLOR = color * COLOR;
}
