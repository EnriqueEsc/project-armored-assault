
shader_type spatial;
render_mode cull_disabled, unshaded, blend_mix;

uniform vec4 base_color : source_color = vec4(1.0, 0.15, 0.01, 1.0);
uniform vec4 tip_color : source_color = vec4(1.0, 0.75, 0.05, 1.0);

uniform float max_height = 1.0;

uniform float wind_strength = 0.12;
uniform float wind_speed = 2.5;
uniform float wind_frequency = 2.0;

uniform float vertex_randomness = 0.08;
uniform float vertical_strength = 0.12;
uniform float flicker_speed = 4.0;

uniform float wind_curve = 1.5;

varying float height_mask;
varying float flame_variation;


float rand(vec3 point) {
	return fract(sin(dot(point, vec3(99.12412, 4.2515, 412.2215))) * 42142.1242);
}


void vertex() {
	float height = clamp(VERTEX.y / max_height, 0.0, 1.0);
	float mask = pow(height, wind_curve);
	float random_offset = rand(VERTEX) * 2.0 - 1.0;
	float wave = sin(TIME * wind_speed + VERTEX.y * wind_frequency + VERTEX.x * 2.0);
	float wind = wave * wind_strength * mask;
	float random_motion = sin(TIME * flicker_speed + random_offset * 20.0) * vertex_randomness * mask;
	float vertical_wave = sin(TIME * flicker_speed + VERTEX.x * 3.0 + random_offset * 5.0);
	float vertical_motion = vertical_wave * vertical_strength * mask;
	
	VERTEX.x += wind + random_motion;
	VERTEX.z += cos(TIME * wind_speed * 0.8 + VERTEX.y * 3.0) * wind_strength * 0.3 * mask;
	VERTEX.y += vertical_motion;
	
	height_mask = height;
	flame_variation = random_offset;
}


void fragment() {
	float gradient = clamp(height_mask, 0.0, 1.0);
	vec4 color = mix(base_color, tip_color, gradient);
	ALBEDO = color.rgb;
	ALPHA = color.a;
}
