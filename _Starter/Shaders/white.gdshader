shader_type canvas_item;

uniform vec4 color: source_color = vec4(1, 1, 1, 1);

void fragment() {
	vec4 offset = texture(TEXTURE, UV);
	vec4 white = vec4(1, 1, 1, 1);
	// COLOR = white - (white - color) * COLOR;
	// COLOR = vec4(COLOR.rgb, offset.a);
	COLOR = vec4(COLOR.rgb, min(offset.a, offset.r));
}
