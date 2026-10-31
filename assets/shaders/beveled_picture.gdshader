shader_type canvas_item;
uniform vec2 rect_size = vec2(192.0, 188.0);
uniform float corner_cut = 11.0;
varying vec2 local_position;
void vertex() { local_position = VERTEX; }
void fragment() {
	vec2 edge = min(local_position, rect_size - local_position);
	float mask = smoothstep(corner_cut - 0.7, corner_cut + 0.7, edge.x + edge.y);
	COLOR = texture(TEXTURE, UV) * COLOR;
	COLOR.a *= mask;
}
