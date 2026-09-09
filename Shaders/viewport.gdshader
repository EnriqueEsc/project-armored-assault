shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(0.0, 1.0, 0.0, 1.0);
uniform float thickness : hint_range(1.0, 8.0) = 2.0;

void fragment() {
    vec4 center = texture(TEXTURE, UV);

    vec2 px = TEXTURE_PIXEL_SIZE * thickness;

    float around = 0.0;

    around = max(around, texture(TEXTURE, UV + vec2( px.x, 0.0)).a);
    around = max(around, texture(TEXTURE, UV + vec2(-px.x, 0.0)).a);
    around = max(around, texture(TEXTURE, UV + vec2(0.0,  px.y)).a);
    around = max(around, texture(TEXTURE, UV + vec2(0.0, -px.y)).a);

    float outline = around * (1.0 - center.a);

    COLOR = vec4(outline_color.rgb, outline * outline_color.a);
}