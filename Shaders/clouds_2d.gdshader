shader_type canvas_item;

uniform sampler2D cloud_noise_tex : filter_linear, repeat_enable;

uniform vec4 cloud_color : source_color = vec4(0.0, 0.0, 0.0, 1.0); 
uniform float cloud_threshold : hint_range(0.0, 1.0) = 0.5;
uniform float cloud_softness : hint_range(0.0, 0.5) = 0.15;
uniform float time_offset = 0.0; 

void fragment() {
	//vec2 animated_uv = UV + vec2(time_offset, time_offset * 0.5);
	vec2 animated_uv = UV + vec2(TIME * 0.01, TIME * 0.01);
	
	float noise = texture(cloud_noise_tex, animated_uv).r;
	float clouds = smoothstep(cloud_threshold - cloud_softness, cloud_threshold + cloud_softness, noise);
	
	COLOR = vec4(cloud_color.rgb, clouds);
}
