
shader_type spatial;
render_mode cull_disabled;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;

uniform vec4 base_color : source_color = vec4(0.2, 0.3, 0.15, 1.0);
uniform vec4 tip_color : source_color = vec4(0.5, 0.7, 0.25, 1.0);

uniform float max_height = 1.0;

uniform float wind_strength = 0.5;
uniform float wind_speed = 0.8;
uniform float wind_frequency = 0.3;

global uniform vec3 player_pos;
uniform float player_radius = 7.0;
uniform float push_strength = 0.4;

uniform float wind_curve = 2.0;
uniform float push_curve = 1.5;

varying float vertex_height;


float get_wind(vec3 world_pos, float time) {
	float wave_1 = sin(world_pos.x * wind_frequency + time * wind_speed);	
	float wave_2 = cos(world_pos.z * wind_frequency * 0.7 + time * wind_speed * 0.8);
	
	return wave_1 * wave_2;
}


void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float height_mask = clamp(VERTEX.y / max_height, 0.0, 1.0);
	vertex_height = height_mask;
	
	float wind_mask = pow(height_mask, wind_curve);
	float wind = get_wind(world_pos, TIME) * wind_strength * wind_mask;
	vec3 wind_offset = vec3(wind, 0.0, wind * 0.5);
	
	vec3 direction = world_pos - player_pos;
	direction.y = 0.0;
	float distance_to_player = length(direction);
	vec3 push_offset = vec3(0.0);
	
	if (distance_to_player < player_radius && distance_to_player > 0.001) {
		float influence = 1.0 - distance_to_player / player_radius;
		influence = pow(influence, push_curve);
		push_offset = normalize(direction) * influence * push_strength * height_mask;
	}
	
	VERTEX += wind_offset + push_offset;
}


void fragment() {
	vec3 texture_color = texture(albedo_texture, UV).rgb;
	vec3 gradient = mix(base_color.rgb, tip_color.rgb, vertex_height);
	
	ALBEDO = texture_color * gradient;
}


//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
