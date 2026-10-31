shader_type canvas_item;
uniform float clock = 0.0;
uniform vec3 engine_color : source_color = vec3(0.2, 0.8, 1.0);
void fragment() {
	vec2 uv = UV;
	// Restrict heat distortion to the two exhaust jets behind the hull.
	float plume = (1.0 - smoothstep(0.16, 0.25, uv.x)) * smoothstep(0.28, 0.35, uv.y) * (1.0 - smoothstep(0.61, 0.69, uv.y));
	uv.x += plume * (sin(uv.y * 130.0 + clock * 34.0) * 0.004 + sin(clock * 27.0) * 0.006);
	uv.y += plume * sin(uv.x * 150.0 - clock * 29.0) * 0.003;
	vec4 sample_color = texture(TEXTURE, uv);
	float flicker = 0.85 + 0.15 * sin(clock * 24.0 + uv.x * 80.0) * sin(clock * 39.0);
	sample_color.rgb *= mix(1.0, flicker + 0.13, plume);
	sample_color.rgb += engine_color * plume * (0.07 + 0.06 * sin(clock * 31.0));
	sample_color.a *= mix(1.0, flicker, plume);
	COLOR = sample_color * COLOR;
}
