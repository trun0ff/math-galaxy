shader_type canvas_item;
uniform sampler2D blurred_image : filter_linear, repeat_disable;
void fragment() {
	vec2 texel = 1.0 / vec2(textureSize(blurred_image, 0));
	vec4 blurred = vec4(0.0);
	float total = 0.0;
	for (int y = -2; y <= 2; y++) {
		for (int x = -2; x <= 2; x++) {
			float weight = (3.0 - abs(float(x))) * (3.0 - abs(float(y)));
			blurred += texture(blurred_image, clamp(UV + vec2(float(x), float(y)) * texel, vec2(0.0), vec2(1.0))) * weight;
			total += weight;
		}
	}
	COLOR = blurred / total * vec4(0.66, 0.71, 0.8, 1.0);
}
