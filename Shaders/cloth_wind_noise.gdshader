shader_type spatial;
render_mode cull_disabled;

uniform vec4 cloth_color : source_color = vec4(0.8, 0.2, 0.2, 1.0);
uniform sampler2D cloth_texture : source_color, filter_linear_mipmap;

// Configuración de sujeción (0 = Mástil Izquierdo, 1 = Capa/Estandarte Arriba)
uniform int attachment_type : hint_range(0, 1) = 0;

// Parámetros de viento físicos
uniform float wind_speed = 6.0;
uniform float wind_strength = 0.2;
uniform float wave_frequency = 5.0;
uniform float speed_inertia = 0.0; 

// NUEVO: Control de Ruido Orgánico
uniform sampler2D wind_noise_tex : filter_linear_mipmap, repeat_enable;
uniform float noise_strength = 0.4;  // Qué tanto distorsiona el ruido la onda uniforme
uniform float noise_scale = 1.0;     // Escala del patrón de ruido en la tela

void vertex() {
    float mask = 0.0;
    float wave_axis = 0.0;
    
    // Seleccionar el tipo de sujeción dinámicamente
    if (attachment_type == 0) {
        mask = smoothstep(0.0, 0.2, UV.x);
        wave_axis = VERTEX.x;
    } else {
        mask = smoothstep(0.0, 0.2, UV.y);
        wave_axis = VERTEX.y;
    }
    
    // 1. Obtener el valor de la textura de ruido usando coordenadas del mundo/locales
    // Desplazamos las coordenadas del ruido con el tiempo para simular la ráfaga pasando a través de la tela
    vec2 noise_uv = VERTEX.xy * 0.2 * noise_scale;
    vec2 noise_scroll = vec2(TIME * (wind_speed * 0.1), TIME * (wind_speed * 0.05));
    float noise_value = texture(wind_noise_tex, noise_uv - noise_scroll).r;
    
    // 2. Onda principal sinusoidal
    float wave = sin(wave_axis * wave_frequency - TIME * wind_speed);
    
    // 3. Onda secundaria cruzada
    float cross_axis = (attachment_type == 0) ? VERTEX.y : VERTEX.x;
    float wave_noise = cos(cross_axis * (wave_frequency * 0.6) + TIME * (wind_speed * 0.7));
    
    // 4. COMBINACIÓN CON EL MULTIPLICADOR DE RUIDO
    // El ruido altera tanto la fase (tiempo) como la amplitud (fuerza) de la onda principal
    float final_movement = (wave + wave_noise * 0.3);
    
    // Multiplicamos e inyectamos el ruido de forma que rompa la simetría
    final_movement += (noise_value - 0.5) * noise_strength;
    
    // Aplicar transformaciones al eje Z local con su máscara
    VERTEX.y += final_movement * wind_strength * mask;
    
    // Mantener el efecto de inercia para capas
    VERTEX.y += speed_inertia * (mask * mask);
}

void fragment() {
    vec4 tex = texture(cloth_texture, UV);
    ALBEDO = tex.rgb * cloth_color.rgb;
    ROUGHNESS = 0.5;
    METALLIC = 0.0;
}
