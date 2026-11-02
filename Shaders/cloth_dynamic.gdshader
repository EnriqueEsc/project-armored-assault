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

// NUEVO: Simula la inercia (para capas en movimiento). 
// Empuja la tela hacia atrás en el eje Z local simulando velocidad.
uniform float speed_inertia = 0.0; 

void vertex() {
    float mask = 0.0;
    float wave_axis = 0.0;
    
    // Seleccionar el tipo de sujeción dinámicamente
    if (attachment_type == 0) {
        // Mástil izquierdo: se mueve a lo largo de X, base fija en UV.x = 0
        mask = smoothstep(0.0, 0.2, UV.x);
        wave_axis = VERTEX.x;
    } else {
        // Capa/Estandarte: cuelga desde arriba, base fija en UV.y = 0 (o la parte superior de la textura)
        mask = smoothstep(0.0, 0.2, UV.y);
        wave_axis = VERTEX.z;
    }
    
    // Onda principal sinusoidal combinada con el tiempo
    float wave = sin(wave_axis * wave_frequency - TIME * wind_speed);
    
    // Onda secundaria cruzada para dar variabilidad orgánica y que no sea una lámina rígida
    float cross_axis = (attachment_type == 0) ? VERTEX.y : VERTEX.x;
    float wave_noise = cos(cross_axis * (wave_frequency * 0.6) + TIME * (wind_speed * 0.7));
    
    // Aplicar el movimiento en el eje Z local (perpendicular al plano de la tela)
    VERTEX.y += (wave + wave_noise * 0.3) * wind_strength * mask;
    
    // Efecto de inercia para la capa: si el personaje corre, la capa se levanta/empuja hacia atrás
    // Usamos el cuadrado de la máscara (mask * mask) para que la punta se levante mucho más que la base
    VERTEX.y += speed_inertia * (mask * mask);
}

void fragment() {
    vec4 tex = texture(cloth_texture, UV);
    ALBEDO = tex.rgb * cloth_color.rgb;
    ROUGHNESS = 0.5;
    METALLIC = 0.0;
}