shader_type canvas_item;
uniform float damage_fraction = 0.0;
uniform float impact_flash = 0.0;
uniform float clock = 0.0;
uniform vec3 impact_color : source_color = vec3(0.5, 0.85, 1.0);
uniform float blink = 0.0;
uniform float jaw = 0.0;
uniform int species = 0;
// 0: organic, 1: mechanical/crustacean, 2: crystalline,
// 3: soft body/tentacles, 4: wings/tail.
uniform int motion_kind = 0;
uniform float attack_charge = 0.0;
uniform float attack_recoil = 0.0;
uniform vec4 mouth_region = vec4(0.3, 0.65, 0.12, 0.1);
uniform vec4 part_0 = vec4(0.0);
uniform vec4 part_1 = vec4(0.0);
uniform vec4 part_2 = vec4(0.0);
uniform vec4 part_3 = vec4(0.0);
uniform vec4 part_4 = vec4(0.0);
uniform vec4 part_5 = vec4(0.0);
uniform vec4 part_6 = vec4(0.0);
uniform vec4 part_7 = vec4(0.0);
uniform vec4 eye_0 = vec4(0.0);
uniform vec4 eye_1 = vec4(0.0);
uniform vec4 eye_2 = vec4(0.0);
uniform vec4 eye_3 = vec4(0.0);
uniform vec4 eye_4 = vec4(0.0);
uniform vec4 eye_5 = vec4(0.0);
uniform vec3 skin_color : source_color = vec3(0.25, 0.05, 0.4);
vec4 eyelid(vec4 color, vec2 uv, vec4 region, float offset, vec4 brow) {
	if (region.z <= 0.0) { return color; }
	vec2 eye = (uv - region.xy) / region.zw;
	float boundary = 1.0 - smoothstep(0.86, 1.0, length(eye));
	float cycle = mod(clock + float(species) * 0.37 + offset * 0.035, 3.2 + float(species % 3) * 0.4);
	float closure = max(blink, 1.0 - smoothstep(0.0, 0.115, abs(cycle - 0.18)));
	float cover = smoothstep(1.0 - closure, 1.055 - closure, abs(eye.y));
	vec3 lid_color = brow.a > 0.5 ? brow.rgb : skin_color;
	lid_color *= 0.8 + 0.2 * (1.0 - abs(eye.y));
	color.rgb = mix(color.rgb, lid_color, boundary * cover * smoothstep(0.0, 0.07, closure));
	return color;
}
float crack_distance(vec2 point, vec2 start, vec2 finish) {
	vec2 line = finish - start;
	float distance_along = clamp(dot(point - start, line) / dot(line, line), 0.0, 1.0);
	return length(point - start - line * distance_along);
}
float part_mask(vec2 uv, vec4 region) {
	if (region.z <= 0.0) { return 0.0; }
	return 1.0 - smoothstep(0.65, 1.0, length((uv - region.xy) / region.zw));
}
vec2 articulate(vec2 uv, vec4 region, float phase) {
	float mask = part_mask(uv, region);
	if (mask == 0.0) { return vec2(0.0); }
	float amplitude = motion_kind == 1 ? 0.10 : (motion_kind == 2 ? 0.065 : 0.20);
	float angle = sin(phase) * amplitude * (1.0 + attack_charge * 0.35);
	vec2 pivot = region.xy;
	if (region.y > 0.65) { pivot.y -= region.w * 0.8; }
	else { pivot.x += region.x < 0.5 ? region.z * 0.75 : -region.z * 0.75; }
	vec2 point = uv - pivot;
	vec2 rotated = vec2(cos(angle) * point.x + sin(angle) * point.y, -sin(angle) * point.x + cos(angle) * point.y);
	return (rotated - point) * mask;
}
void fragment() {
	vec2 uv = UV;
	float phase = clock * (2.4 + float(species % 4) * 0.27) + float(species) * 0.73;
	// Hinged movement is local to each limb; head and torso stay anchored.
	uv += articulate(UV, part_0, phase * 0.85 + 0.00);
	uv += articulate(UV, part_1, phase * 1.08 + 1.70);
	uv += articulate(UV, part_2, phase * 1.31 + 3.40);
	uv += articulate(UV, part_3, phase * 0.85 + 5.10);
	uv += articulate(UV, part_4, phase * 1.08 + 6.80);
	uv += articulate(UV, part_5, phase * 1.31 + 8.50);
	uv += articulate(UV, part_6, phase * 0.85 + 10.20);
	uv += articulate(UV, part_7, phase * 1.08 + 11.90);
	float mouth = part_mask(UV, mouth_region);
	uv.y -= mouth * (jaw * 0.028 + sin(phase) * 0.004);
	uv.x += mouth * (attack_charge * 0.009 - attack_recoil * 0.022);
	uv.y += mouth * sin(clock * 60.0) * impact_flash * 0.006;
	vec4 color = texture(TEXTURE, uv);
	color = eyelid(color, UV, eye_0, 0.0, texture(TEXTURE, eye_0.xy + vec2(0.0, -eye_0.w * 1.12)));
	color = eyelid(color, UV, eye_1, 1.0, texture(TEXTURE, eye_1.xy + vec2(0.0, -eye_1.w * 1.12)));
	color = eyelid(color, UV, eye_2, 2.0, texture(TEXTURE, eye_2.xy + vec2(0.0, -eye_2.w * 1.12)));
	color = eyelid(color, UV, eye_3, 3.0, texture(TEXTURE, eye_3.xy + vec2(0.0, -eye_3.w * 1.12)));
	color = eyelid(color, UV, eye_4, 4.0, texture(TEXTURE, eye_4.xy + vec2(0.0, -eye_4.w * 1.12)));
	color = eyelid(color, UV, eye_5, 5.0, texture(TEXTURE, eye_5.xy + vec2(0.0, -eye_5.w * 1.12)));
	color.rgb *= 1.0 - damage_fraction * 0.16;
	// Scorch marks and branching fissures accumulate with lost HP.
	for (int scar = 0; scar < 6; scar++) {
		vec2 center = vec2(0.56 + sin(float(scar) * 2.4) * 0.19, 0.5 + cos(float(scar) * 2.1) * 0.22);
		float active = step(float(scar) * 0.14 + 0.05, damage_fraction);
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
