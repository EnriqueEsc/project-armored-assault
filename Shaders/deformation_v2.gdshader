shader_type spatial;

uniform sampler2D buffer : filter_nearest, repeat_disable;
uniform sampler2D terrain_texture : source_color;

uniform int buffer_width = 1024;

varying float deformation;

void vertex() {
	int global_index = int(UV2.x);
	int x = global_index % buffer_width;
	int y = global_index / buffer_width;
	ivec2 pixel_coord = ivec2(x, y);
	vec3 new_pos = texelFetch(buffer, pixel_coord, 0).rgb;
	deformation = distance(VERTEX, new_pos);
	VERTEX = new_pos;
}

void fragment() {
	vec3 base = texture(terrain_texture, UV).rgb;
	if (deformation > 0.1)
		base.rgb = mix(base.rgb, vec3(0.2, 0.1, 0.0), deformation);
	ALBEDO = base;
}
