shader_type spatial;
render_mode cull_disabled;

uniform vec4 base_color : source_color = vec4(0.1,0.4,0.1,1.0);
uniform vec4 tip_color : source_color = vec4(0.4,0.8,0.2,1.0);
uniform float wind_strength = 0.2;
uniform float wind_speed = 2.0;
global uniform vec3 player_pos;
uniform float player_radius = 1.5;
uniform float push_strenght = 0.8;

float get_wind(vec3 world_pos, float time){
	return sin(world_pos.x * 0.5 + time * wind_speed) * cos(world_pos.z * 0.5 + time * wind_speed);
}

float rand(vec2 point){
	return fract(sin(dot(point,vec2(12.9898,78.233))) * 42142.1242);
}



void vertex() {
	vec3 player_view_pos = (VIEW_MATRIX * vec4(player_pos, 1.0)).xyz;
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
	float mask = UV.y;
	
	float wind = get_wind(world_pos.xyz, TIME) * wind_strength * mask;
	vec3 wind_offset = vec3(wind, 0.0,wind*0.5);
	
	vec3 push_offset = vec3(0.0);
	
	vec3 dir_to_gras = world_pos - player_pos;
	dir_to_gras.y = 0.0;
	
	float dist = length(dir_to_gras);
	
	if (dist < player_radius){
		float force = (1.0 - (dist / player_radius)) * push_strenght;
		push_offset = normalize(dir_to_gras) * force * mask;
	}
	
	VERTEX += wind_offset + push_offset;
	
	//VERTEX.x += wind;
	//VERTEX.z += wind * 0.5;
}

void fragment() {
	ALBEDO = mix(base_color.rgb, tip_color.rgb, UV.y);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
