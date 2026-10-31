shader_type canvas_item;
uniform float clock = 0.0;
uniform vec3 engine_color : source_color = vec3(0.2, 0.8, 1.0);
uniform vec4 flame_region_0 = vec4(0.08, 0.36, 0.155, 0.45);
uniform vec4 flame_region_1 = vec4(0.075, 0.52, 0.145, 0.61);
uniform vec4 flame_region_2 = vec4(0.0);
float flame_mask(vec2 uv, vec4 region) {
	return smoothstep(region.x, region.x + 0.004, uv.x) * (1.0 - smoothstep(region.z - 0.004, region.z, uv.x))
		* smoothstep(region.y, region.y + 0.004, uv.y) * (1.0 - smoothstep(region.w - 0.004, region.w, uv.y));
}
void fragment() {
	// Never offset texture coordinates: the hull and nozzle remain pixel-stable.
	vec4 color = texture(TEXTURE, UV);
	float flame = max(flame_mask(UV, flame_region_0), max(flame_mask(UV, flame_region_1), flame_mask(UV, flame_region_2)));
	float wave = 0.5 + 0.5 * sin(clock * 28.0 - UV.x * 110.0 + UV.y * 24.0);
	color.rgb *= 1.0 + flame * (wave * 0.32 - 0.12);
	color.rgb += engine_color * flame * wave * 0.07;
	// Travelling brightness/opacity makes the flame flicker without bending metal.
	color.a *= 1.0 - flame * (1.0 - wave) * 0.22;
	COLOR = color * COLOR;
}
