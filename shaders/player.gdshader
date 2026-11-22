shader_type canvas_item;
uniform float light_amount : hint_range(0.0, 1.0) = 0.0;
uniform float glow_strength : hint_range(0.0, 1.0) = 0.5;
uniform bool squint = false;
uniform vec4 shadow_cloak : source_color = vec4(0.08, 0.04, 0.12, 1.0);
uniform vec4 eye_glow : source_color = vec4(0.7, 0.85, 1.0, 1.0);

bool is_white(vec4 c) {
    return c.a > 0.5 && c.r > 0.9 && c.g > 0.9 && c.b > 0.9;
}

bool is_eye(sampler2D tex, vec2 uv, vec2 px) {
    if (!is_white(texture(tex, uv))) return false;
    if (squint && !is_white(texture(tex, uv + vec2(0.0, px.y)))) return false;
    return true;
}

void fragment() {
    vec4 c = texture(TEXTURE, UV);
    vec2 px = TEXTURE_PIXEL_SIZE;
    bool eye = is_eye(TEXTURE, UV, px);
    bool bottom_eye = is_white(c) && !eye;
    bool cloak = c.r > c.b + 0.05 && c.r > 0.12 && !is_white(c);

    float near = 0.0;
    if (is_eye(TEXTURE, UV + vec2(0.0, -px.y), px)) near += 1.0;
    if (is_eye(TEXTURE, UV + vec2(0.0, px.y), px)) near += 1.0;
    if (is_eye(TEXTURE, UV + vec2(-px.x, 0.0), px)) near += 1.0;
    if (is_eye(TEXTURE, UV + vec2(px.x, 0.0), px)) near += 1.0;
    float glow = clamp(near, 0.0, 1.0) * glow_strength * (1.0 - light_amount);

    if (eye) {
        c.rgb = mix(eye_glow.rgb * 1.3, c.rgb, light_amount);
    } else if (bottom_eye) {
        c.rgb = vec3(0.0);
        if (cloak) c.rgb = mix(shadow_cloak.rgb, c.rgb, light_amount);
        c.rgb += vec3(0.15) * light_amount;
        if (c.a > 0.0) c.rgb = mix(c.rgb, eye_glow.rgb, glow);
    } else {
        if (cloak) c.rgb = mix(shadow_cloak.rgb, c.rgb, light_amount);
        c.rgb += vec3(0.15) * light_amount;
        if (c.a > 0.0) c.rgb = mix(c.rgb, eye_glow.rgb, glow);
    }
    COLOR = c;
}