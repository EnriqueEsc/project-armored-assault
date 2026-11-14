shader_type spatial;
render_mode cull_disabled, depth_draw_always;

uniform vec4 deep_water_color : source_color = vec4(0.0, 0.15, 0.3, 0.8);
uniform vec4 shallow_water_color : source_color = vec4(0.0, 0.5, 0.6, 0.5);
uniform float roughness : hint_range(0.0, 1.0) = 0.08;

uniform float wave_speed = 1.5;
uniform float wave_amplitude = 0.18;
uniform float wave_frequency = 0.8;
uniform vec2 surge_direction = vec2(1.0, 0.5);
uniform float surge_strength = 0.15;
uniform float surge_speed = 1.0;

uniform float shore_foam_depth = 0.25;
uniform float crest_foam_threshold = 0.4; 
uniform float foam_noise_scale = 2.0;      
uniform float foam_cutoff = 0.5;           
uniform vec4 foam_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

uniform sampler2D foam_noise_tex : filter_linear_mipmap, repeat_enable;

uniform float refraction_strength = 0.05;

uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

varying float wave_height;
varying vec3 vec_world_pos;

void vertex() {
	vec_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float surge = sin(TIME * surge_speed) * surge_strength;
	vec2 surge_offset = normalize(surge_direction) * surge;
	VERTEX.x += surge_offset.x;
	VERTEX.z += surge_offset.y;
	
	float wave1 = sin(vec_world_pos.x * wave_frequency + TIME * wave_speed);
	float wave2 = cos(vec_world_pos.z * wave_frequency * 0.8 + TIME * wave_speed * 1.2);
	float final_wave = (wave1 + wave2) * wave_amplitude;
	
	VERTEX.y += final_wave;
	
	wave_height = ((wave1 + wave2) * 0.5) * 0.5 + 0.5; 
}

void fragment() {
	
	vec2 refraction_offset = vec2(wave_height) * refraction_strength;
	vec2 distorted_screen_uv = SCREEN_UV + refraction_offset;
	
	float depth = textureLod(depth_texture, distorted_screen_uv, 0.0).r;
	vec4 upos = INV_PROJECTION_MATRIX * vec4(distorted_screen_uv * 2.0 - 1.0, depth, 1.0);
	vec3 pixel_world_pos = upos.xyz / upos.w;
	float water_depth = VERTEX.z - pixel_world_pos.z;
	
	float depth_blend = clamp(water_depth / 2.0, 0.0, 1.0);
	vec4 final_water_color = mix(shallow_water_color, deep_water_color, depth_blend);
	
	vec2 foam_uv = vec_world_pos.xz * 0.1 * foam_noise_scale;
	vec2 foam_scroll = vec2(TIME * wave_speed * 0.05);
	float noise_r = texture(foam_noise_tex, foam_uv + foam_scroll).r;
	float noise_g = texture(foam_noise_tex, foam_uv * 1.5 - foam_scroll * 0.8).g;
	float combined_noise = (noise_r + noise_g) * 0.5;
	
	float crest_area = smoothstep(crest_foam_threshold, 1.0, wave_height);
	float crest_foam = step(foam_cutoff, crest_area * combined_noise);
	
	float shore_area = 1.0 - smoothstep(0.0, shore_foam_depth, water_depth);
	shore_area = clamp(shore_area, 0.0, 1.0);
	float shore_foam = step(foam_cutoff * 0.7, shore_area * combined_noise);
	
	float total_foam = clamp(shore_foam + crest_foam, 0.0, 1.0);
	
	vec3 color_with_foam = mix(final_water_color.rgb, foam_color.rgb, total_foam);
	vec3 background_screen = textureLod(screen_texture, distorted_screen_uv, 0.0).rgb;
	vec3 water_transparency = mix(background_screen, color_with_foam, final_water_color.a + total_foam);
	
	ALBEDO = mix(water_transparency, foam_color.rgb, total_foam);
	ALPHA = 1.0;
	METALLIC = 0.0;
	ROUGHNESS = roughness;
	SPECULAR = 0.6;
}
