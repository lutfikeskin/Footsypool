shader_type canvas_item;

uniform float amount: hint_range(-5, 5) = 1.0;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec4 offset = texture(TEXTURE, UV);
	float ratio = SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;
	vec4 color = textureLod(SCREEN_TEXTURE, SCREEN_UV + vec2((-0.5 + offset.r) * 0.01, (-0.5 + offset.g) * 0.02) * amount, 0.0);
	COLOR = vec4(color.rgb, offset.a);
}