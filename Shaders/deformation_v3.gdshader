shader_type spatial;

uniform bool use_deformation = true;
uniform sampler2D buffer : filter_nearest, repeat_disable;

uniform sampler2D texture_1 : source_color, repeat_enable;
uniform sampler2D texture_2 : source_color, repeat_enable;
uniform sampler2D texture_3 : source_color, repeat_enable;

uniform sampler2D splat_map : filter_linear, repeat_disable;

uniform int buffer_width = 1024;

uniform vec2 mask_uv_min = vec2(0.0);
uniform vec2 mask_uv_size = vec2(1.0);

varying float deformation;
varying vec2 splat_uv;

void vertex() {
	splat_uv = (UV - mask_uv_min) / mask_uv_size;
	deformation = 0.0;
	
	if (use_deformation) {
		int global_index = int(UV2.x);
		int x = global_index % buffer_width;
		int y = global_index / buffer_width;
		ivec2 pixel_coord = ivec2(x, y);
		vec3 new_pos = texelFetch(buffer, pixel_coord, 0).rgb;
		
		deformation = distance(VERTEX, new_pos);
		VERTEX = new_pos;
	}
}

void fragment() {
	vec3 weights = texture(splat_map, splat_uv).rgb;
	float total = weights.r + weights.g + weights.b;
	
	if (total < 0.001)
		weights = vec3(1.0, 0.0, 0.0);
	else 
		weights /= total;
	
	vec3 txt1 = texture(texture_1, UV).rgb;
	vec3 txt2 = texture(texture_2, UV).rgb;
	vec3 txt3 = texture(texture_3, UV).rgb;
	
	vec3 base = txt1 * weights.r + txt2 * weights.g + txt3 * weights.b;
		
	if (deformation > 0.1)
		base = mix(base, vec3(0.2, 0.1, 0.0), deformation);
	ALBEDO = base;
}
