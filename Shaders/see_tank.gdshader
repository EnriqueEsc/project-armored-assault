shader_type spatial;
render_mode depth_prepass_alpha, depth_draw_opaque, cull_back;

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;

uniform float cutout_radius : hint_range(0.0, 10.0) = 2.0;
uniform float cutout_feather : hint_range(0.0, 5.0) = 1.0;

global uniform vec3 player_pos;

varying vec3 world_position;

void vertex(){
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment(){
	vec4 albedo_tex = texture(texture_albedo, UV);
	
	vec3 player_view_pos = (VIEW_MATRIX * vec4(player_pos, 1.0)).xyz;
	float distance_to_player_screen = distance(VERTEX.xy, player_view_pos.xy);
	float circle_mask = smoothstep(cutout_radius, cutout_radius + cutout_feather, distance_to_player_screen);
	
	float frag_dist_xz = distance(CAMERA_POSITION_WORLD.xz, world_position.xz);
	float player_dist_xz = distance(CAMERA_POSITION_WORLD.xz, player_pos.xz);
	
	float is_behind = smoothstep(player_dist_xz - 0.5, player_dist_xz, frag_dist_xz);
	
	float final_mask = mix(circle_mask, 1.0, is_behind);
	
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	ALPHA = final_mask * albedo.a * albedo_tex.a;
}

/*
shader_type spatial;
render_mode depth_draw_opaque, cull_back;

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;

uniform float cutout_radius : hint_range(0.0, 10.0) = 2.0;
uniform float cutout_feather : hint_range(0.0, 5.0) = 1.0;

global uniform vec3 player_pos;
varying vec3 world_position;

void vertex(){
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment(){
	vec4 albedo_tex = texture(texture_albedo, UV);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	
	vec3 player_view_pos = (VIEW_MATRIX * vec4(player_pos, 1.0)).xyz;
	float distance_to_player_screen = distance(VERTEX.xy, player_view_pos.xy);
	float circle_mask = smoothstep(cutout_radius, cutout_radius + cutout_feather, distance_to_player_screen);
	
	float frag_dist_xz = distance(CAMERA_POSITION_WORLD.xz, world_position.xz);
	float player_dist_xz = distance(CAMERA_POSITION_WORLD.xz, player_pos.xz);
	float is_behind = smoothstep(player_dist_xz - 0.5, player_dist_xz, frag_dist_xz);
	
	float final_mask = mix(circle_mask, 1.0, is_behind);
	
	const float DITHER_THRESHOLDS[16] = float[16](
		1.0/17.0,  9.0/17.0,  3.0/17.0, 11.0/17.0,
		13.0/17.0,  5.0/17.0, 15.0/17.0,  7.0/17.0,
		4.0/17.0, 12.0/17.0,  2.0/17.0, 10.0/17.0,
		16.0/17.0,  8.0/17.0, 14.0/17.0,  6.0/17.0
	);
	
	int index = (int(FRAGCOORD.x) % 4) + (int(FRAGCOORD.y) % 4) * 4;
	
	if (final_mask < DITHER_THRESHOLDS[index]) {
		discard;
	}
}
*/