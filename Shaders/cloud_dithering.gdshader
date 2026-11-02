shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_disabled;

uniform sampler2D cloud_noise_tex : filter_linear_mipmap, repeat_enable;

uniform vec3 cloud_color : source_color = vec3(1.0);
uniform float cloud_density = 1.5;
uniform float shadow_opacity = 0.8;
uniform vec2 cloud_speed = vec2(0.02, 0.01);

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void fragment() {
	vec2 animated_uv = UV + (TIME * cloud_speed);
	float noise = texture(cloud_noise_tex, animated_uv).r;
	float clouds = pow(noise, cloud_density) * shadow_opacity;
	
	float dither = rand(FRAGCOORD.xy);
	
	if (clouds < dither) {
		discard;
	}
	
	ALBEDO = cloud_color;
	ALPHA = clouds;
}