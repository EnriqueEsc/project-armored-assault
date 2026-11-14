shader_type spatial;
render_mode cull_disabled;

uniform vec4 cloth_color : source_color = vec4(0.8, 0.2, 0.2, 1.0);
uniform sampler2D cloth_texture : source_color, filter_linear_mipmap;

uniform int attachment_type : hint_range(0, 1) = 0;

uniform float wind_speed = 6.0;
uniform float wind_strength = 0.2;
uniform float wave_frequency = 5.0;

uniform float speed_inertia = 0.0; 

void vertex() {
	float mask = 0.0;
	float wave_axis = 0.0;
	
	if (attachment_type == 0) {
		mask = smoothstep(0.0, 0.2, UV.x);
		wave_axis = VERTEX.x;
	} else {
		mask = smoothstep(0.0, 0.2, UV.y);
		wave_axis = VERTEX.z;
	}
	  
	float wave = sin(wave_axis * wave_frequency - TIME * wind_speed);
	
	float cross_axis = (attachment_type == 0) ? VERTEX.y : VERTEX.x;
	float wave_noise = cos(cross_axis * (wave_frequency * 0.6) + TIME * (wind_speed * 0.7));
	
	VERTEX.y += (wave + wave_noise * 0.3) * wind_strength * mask;
	VERTEX.y += speed_inertia * (mask * mask);
}

void fragment() {
	vec4 tex = texture(cloth_texture, UV);
	ALBEDO = tex.rgb * cloth_color.rgb;
	ROUGHNESS = 0.5;
	METALLIC = 0.0;
}