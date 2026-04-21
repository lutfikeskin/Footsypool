
shader_type canvas_item;

render_mode world_vertex_coords;  // Defers the model-view transformation until after the vertex shader code runs
varying vec2 world_pos;  // Use vec3 instead for 3d shaders

void vertex() {
    world_pos = VERTEX;
}

void fragment() {
	COLOR = texture(TEXTURE, fract(world_pos * 0.005));
}
