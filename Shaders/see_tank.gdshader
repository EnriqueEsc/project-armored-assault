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
	
	// --- EL TRUCO PARA EL MINIMAPA ---
	// Si PROJECTION_MATRIX[3][3] es 1.0 (Ortogonal), is_ortho será 1.0. 
	// Si es Perspectiva, será 0.0.
	float is_ortho = PROJECTION_MATRIX[3][3];
	
	// Mezclamos la máscara final. Si is_ortho es 1.0, forzamos la opacidad total (1.0).
	final_mask = mix(final_mask, 1.0, is_ortho);
	
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	ALPHA = final_mask * albedo.a * albedo_tex.a;
}



/*shader_type spatial;
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
*/

/*


shader_type spatial;
render_mode depth_prepass_alpha, depth_draw_opaque, cull_back;

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;

// Parámetros de la visión base
uniform float cutout_radius : hint_range(0.0, 10.0) = 2.0;
uniform float cutout_feather : hint_range(0.0, 5.0) = 1.0;

// Parámetros de la visión de apuntado
uniform float cone_distance : hint_range(0.0, 50.0) = 150.0; 
uniform float cone_angle : hint_range(0.0, 1.0) = 0.8;      
uniform float cone_feather : hint_range(0.0, 1.0) = 0.15;   

global uniform vec3 player_pos;
global uniform vec3 player_aim_dir;

varying vec3 world_position;

void vertex(){
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment(){
	vec4 albedo_tex = texture(texture_albedo, UV);
	
	// --- 1. PROYECCIONES EN PANTALLA ---
	vec3 player_view_pos = (VIEW_MATRIX * vec4(player_pos, 1.0)).xyz;
	
	vec3 target_pos = player_pos + (normalize(player_aim_dir) * cone_distance);
	vec3 target_view_pos = (VIEW_MATRIX * vec4(target_pos, 1.0)).xyz;
	
	
	// --- 2. CÁLCULO DEL CÍRCULO CENTRAL ---
	float dist_to_player_screen = distance(VERTEX.xy, player_view_pos.xy);
	float circle_mask = smoothstep(cutout_radius, cutout_radius + cutout_feather, dist_to_player_screen);
	
	
	// --- 3. CÁLCULO DEL CONO TÁCTICO ---
	float screen_cone_dist = distance(target_view_pos.xy, player_view_pos.xy);
	
	vec2 aim_diff = target_view_pos.xy - player_view_pos.xy;
	vec2 aim_view_dir = aim_diff / max(length(aim_diff), 0.0001);
	vec2 dir_to_frag_screen = (VERTEX.xy - player_view_pos.xy) / max(dist_to_player_screen, 0.0001);
	
	float dot_prod = dot(dir_to_frag_screen, aim_view_dir);
	
	float angular_mask = 1.0 - smoothstep(cone_angle - cone_feather, cone_angle, dot_prod);
	float distance_mask_cone = smoothstep(screen_cone_dist - cutout_feather * 2.0, screen_cone_dist, dist_to_player_screen);
	
	float cone_mask = max(angular_mask, distance_mask_cone);
	
	
	// --- 4. COMBINACIÓN DE GEOMETRÍAS ---
	float combined_shape_mask = min(circle_mask, cone_mask);
	
	
	// --- 5. REGLA DE PROFUNDIDAD RESTAURADA (EL FIX MÁGICO) ---
	float frag_dist_xz = distance(CAMERA_POSITION_WORLD.xz, world_position.xz);
	float player_dist_xz = distance(CAMERA_POSITION_WORLD.xz, player_pos.xz);
	
	// Volvemos a tu lógica original estricta: 
	// ÚNICAMENTE evaluamos la distancia de la cámara al jugador.
	// Si un muro está más lejos que el tanque, se vuelve sólido (1.0) sin importar el cono.
	float is_behind = smoothstep(player_dist_xz - 0.5, player_dist_xz, frag_dist_xz);
	
	// Aplicamos la protección de profundidad a nuestra figura combinada
	float final_mask = mix(combined_shape_mask, 1.0, is_behind);
	
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	ALPHA = final_mask * albedo.a * albedo_tex.a;
}


*/


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