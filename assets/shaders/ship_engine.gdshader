shader_type canvas_item;
uniform float clock = 0.0;
uniform vec3 engine_color : source_color = vec3(0.2, 0.8, 1.0);
void fragment() {
	vec2 uv = UV;
	// All hulls have painted exhaust on the left, but at different heights.
	// Follow bright saturated flame pixels instead of assuming two fixed nozzles.
	vec4 original = texture(TEXTURE, uv);
	float bright = max(original.r, max(original.g, original.b));
	float saturation = bright - min(original.r, min(original.g, original.b));
	float plume = (1.0 - smoothstep(0.23, 0.43, uv.x)) * smoothstep(0.4, 0.85, bright) * smoothstep(0.15, 0.5, saturation);
	uv.x += plume * (sin(uv.y * 130.0 + clock * 34.0) * 0.008 + sin(clock * 27.0) * 0.012);
	uv.y += plume * sin(uv.x * 150.0 - clock * 29.0) * 0.006;
	vec4 sample_color = texture(TEXTURE, uv);
	float flicker = 0.78 + 0.22 * sin(clock * 24.0 + uv.x * 80.0) * sin(clock * 39.0);
	sample_color.rgb *= mix(1.0, flicker + 0.13, plume);
	sample_color.rgb += engine_color * plume * (0.07 + 0.06 * sin(clock * 31.0));
	sample_color.a *= mix(1.0, flicker, plume);
	COLOR = sample_color * COLOR;
}
