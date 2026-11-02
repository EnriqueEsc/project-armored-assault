shader_type spatial;
render_mode blend_mix, depth_prepass_alpha;

uniform sampler2D cloud_noise_tex : filter_linear_mipmap, repeat_enable;

uniform vec3 cloud_color : source_color = vec3(1.0);
uniform float cloud_threshold = 0.5;
uniform float cloud_softness = 0.15;

uniform vec2 cloud_speed = vec2(0.02, 0.01);

void fragment() {
	vec2 animated_uv = UV + (TIME * cloud_speed);
	
	float noise = texture(cloud_noise_tex, animated_uv).r;
	float clouds = smoothstep(cloud_threshold - cloud_softness, cloud_threshold + cloud_softness, noise);
	
	ALBEDO = cloud_color;
	ALPHA = clouds;
}