shader_type spatial;
render_mode cull_disabled, depth_draw_always;

uniform vec4 deep_water_color : source_color = vec4(0.0, 0.15, 0.3, 0.8);  
uniform vec4 shallow_water_color : source_color = vec4(0.0, 0.5, 0.6, 0.5); 
uniform float roughness : hint_range(0.0, 1.0) = 0.08;

uniform float wave_speed = 1.5;
uniform float wave_amplitude = 0.18;
uniform float wave_frequency = 0.8;

uniform vec2 surge_direction = vec2(1.0, 0.5);
uniform float surge_strength = 0.15;
uniform float surge_speed = 1.0;

uniform float shore_foam_depth = 0.25;  
uniform float crest_foam_threshold = 0.8; 
uniform vec4 foam_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

varying float wave_height;

void vertex() {
    vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    
    float surge = sin(TIME * surge_speed) * surge_strength;
    vec2 surge_offset = normalize(surge_direction) * surge;
    VERTEX.x += surge_offset.x;
    VERTEX.z += surge_offset.y;
    
    float wave1 = sin(world_pos.x * wave_frequency + TIME * wave_speed);
    float wave2 = cos(world_pos.z * wave_frequency * 0.8 + TIME * wave_speed * 1.2);
    float final_wave = (wave1 + wave2) * wave_amplitude;
    
    VERTEX.y += final_wave;
    
    wave_height = (wave1 + wave2) * 0.5; 
}

void fragment() {
    float depth = textureLod(depth_texture, SCREEN_UV, 0.0).r;
    
    vec4 upos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
    vec3 pixel_world_pos = upos.xyz / upos.w;
    
    float water_depth = VERTEX.z - pixel_world_pos.z;
    
    float depth_blend = clamp(water_depth / 2.0, 0.0, 1.0);
    vec4 final_water_color = mix(shallow_water_color, deep_water_color, depth_blend);
    
    
    
    float shore_foam = 1.0 - smoothstep(0.0, shore_foam_depth, water_depth);
    shore_foam = clamp(shore_foam, 0.0, 1.0);
    
    float total_foam = clamp(shore_foam , 0.0, 1.0);
    
    vec3 color_with_foam = mix(final_water_color.rgb, foam_color.rgb, total_foam);
    
    ALBEDO = color_with_foam;
    
    ALPHA = clamp(final_water_color.a + total_foam, 0.0, 1.0);
    
    METALLIC = 0.0;
    ROUGHNESS = roughness;
    SPECULAR = 0.6;
}