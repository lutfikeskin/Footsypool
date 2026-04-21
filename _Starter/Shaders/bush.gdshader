shader_type canvas_item;

uniform sampler2D image : source_color;

void fragment() {
	COLOR = vec4(0.1, 0.1, 0.1, 1) + texture(image, UV);
}