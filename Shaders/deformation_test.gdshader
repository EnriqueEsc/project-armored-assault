shader_type spatial;

uniform sampler2D buffer : filter_nearest, repeat_disable;
uniform sampler2D terrain_texture : source_color;

uniform int buffer_width = 1024;

void vertex() {
	int x = VERTEX_ID % buffer_width;
	int y = VERTEX_ID / buffer_width;

	ivec2 pixel_coord = ivec2(x, y);

	vec3 new_pos = texelFetch(buffer, pixel_coord, 0).rgb;

	VERTEX = new_pos;
}

void fragment() {
	ALBEDO = texture(terrain_texture, UV).rgb;
}
/*
shader_type spatial;

uniform vec3 impact_point;
uniform float radius = 2.0;
uniform float damage = 1.0;

float rand(vec2 point){
	return fract(sin(dot(point,vec2(12.9898,78.233))) * 42142.1242);
}

void vertex() {
	// Called for every vertex the material is visible on.
	
	vec3 vert_to_global = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float dist = distance(vert_to_global, impact_point);
	if (dist < radius){
		float factor = 1.0 - smoothstep(0.0, radius,dist);
		vec3 dir = normalize(vert_to_global - impact_point);
		vec3 local_dir = (inverse(MODEL_MATRIX) * vec4(dir,0.0)).xyz;
		
		VERTEX += local_dir * factor * damage;
	}
	
	/*
	if (VERTEX_ID % 2 == 0){
		if (sin(TIME) > 0.0){
			VERTEX.y = rand(vec2(float(VERTEX_ID) + TIME,VERTEX.x + TIME));
		}
	}
}
	*/
/*
void fragment() {
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
*/