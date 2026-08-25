shader_type spatial;
render_mode depth_prepass_alpha, cull_back;

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;

uniform float cutout_radius : hint_range(0.0,10.0) = 2.0;
uniform float cutout_feather : hint_range(0.0,5.0) = 1.0;

global uniform vec3 player_pos;

varying vec3 world_position;

void vertex(){
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment(){
	vec4 albedo_tex = texture(texture_albedo, UV);
	ALBEDO = albedo.rgb * albedo_text.rgb;
	
	float distance_to_player = distance(world_position, player_pos);
	
	float mask = smoothstep(cutout_radius + cutout_feather, distance_to_player);
	
	ALPHA = mask * albedo.a * albedo_tex.a
}
