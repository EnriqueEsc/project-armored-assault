
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

uniform float distortion_strength : hint_range(0.0, 0.1) = 0.015;
uniform float transparency : hint_range(0.0, 1.0) = 0.9;
uniform float noise_scale = 8.0;
uniform float noise_speed = 0.5;

float noise(vec2 p) {
	return sin(p.x * noise_scale + TIME * noise_speed) * cos(p.y * noise_scale + TIME * noise_speed);
}

void fragment() {
	vec2 screen_uv = SCREEN_UV;
	vec2 distortion = vec2(noise(UV + vec2(0.0, 0.0)), noise(UV + vec2(4.2, 2.7)));
	vec3 background = texture(screen_texture,screen_uv + distortion * distortion_strength).rgb;
	ALBEDO = background;
	ALPHA = transparency;
}
