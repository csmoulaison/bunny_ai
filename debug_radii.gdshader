shader_type spatial;

uniform vec3 eb_pos;

varying vec3 frag_world_pos;

void vertex() {
	frag_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 color = vec3(1., 0., 0.); // RED
	if(distance(frag_world_pos, eb_pos) < 5.0) {
        ALBEDO = vec3(1.0, 0.0, 0.0);
    } else {
		ALBEDO = vec3(1.0, 1.0, 1.0);
	}
}
