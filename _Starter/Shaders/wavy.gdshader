shader_type canvas_item;

uniform float amount = 5.0;
uniform float frequency = 0.0;
uniform float speed = 5.0;
uniform bool flip = false;
uniform float world_amount = 1.0;

void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0, 1.0)).xyz;
	float phase = (frequency * world.x * world_amount) + (speed * TIME);
	VERTEX.x += (1.0 * float(!flip) - UV.y * UV.y) * amount * sin(phase);
}
