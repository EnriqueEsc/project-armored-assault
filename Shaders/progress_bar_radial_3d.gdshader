shader_type spatial;

render_mode unshaded, blend_mix, depth_draw_never, depth_test_disabled, shadows_disabled, cull_disabled;


uniform sampler2D texture_albedo : source_color, filter_linear, repeat_disable;

uniform vec4 tint : source_color = vec4(1.0);

uniform float progress : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 uv_centered = UV - vec2(0.5);
	float angle = atan(uv_centered.x, -uv_centered.y);
	
	float normalized_angle = (angle + PI) / (2.0 * PI);
	
	vec4 texture_color = texture(texture_albedo, UV);
	
	ALBEDO = texture_color.rgb * tint.rgb;
	
	if (normalized_angle > progress){
		ALPHA = 0.0;
	} else{
		ALPHA = texture_color.a;
	}
}