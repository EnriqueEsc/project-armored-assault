shader_type spatial;

render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

instance uniform vec4 light_color : source_color = vec4(1.0, 0.45, 0.08, 1.0);
uniform float intensity : hint_range(0.0, 5.0) = 1.0;
uniform float softness : hint_range(0.1, 8.0) = 2.5;

void fragment()
{
	vec2 p = UV - vec2(0.5);
	float dist = length(p) * 2.0;
	
	float glow = 1.0 - clamp(dist, 0.0, 1.0);
	glow = pow(glow, softness);
	
	ALBEDO = light_color.rgb;
	EMISSION = light_color.rgb * intensity * glow;
	ALPHA = glow * light_color.a;
}