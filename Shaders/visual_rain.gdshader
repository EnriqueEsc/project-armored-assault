shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never;

uniform sampler2D rain_noise : filter_linear_mipmap, repeat_enable;
uniform vec3 rain_color : source_color = vec3(0.75, 0.82, 0.9);
uniform float rain_density : hint_range(0.0, 1.0) = 0.35;
uniform float rain_opacity : hint_range(0.0, 1.0) = 0.45;
uniform vec2 noise_scale = vec2(0.08, 0.08);
uniform vec2 noise_speed = vec2(0.015, 0.025);
uniform float noise_variation = 0.35;
varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 world_uv = world_pos.xz * noise_scale;
	vec2 uv_a = world_uv - TIME * noise_speed;
	vec2 uv_b = world_uv * 1.7 - TIME * noise_speed.yx * 0.7;
	
	float noise_a = texture(rain_noise, uv_a).r;
	float noise_b = texture(rain_noise, uv_b).r;
	float noise = mix(noise_a, noise_b, noise_variation);
	float alpha = noise * rain_density * rain_opacity;
	ALBEDO = rain_color;
	ALPHA = alpha;
}