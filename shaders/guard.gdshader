shader_type canvas_item;

uniform vec3 eye_color : source_color = vec3(1, 0, 0);
uniform float amount : hint_range(0.0, 1.0) = 0.0;

const float threshold = 0.5;

bool is_white(vec4 c) {
    return c.a > 0.5 && c.r > threshold && c.g > threshold && c.b > threshold;
}

void fragment() {
    vec4 c = texture(TEXTURE, UV);
    vec2 px = TEXTURE_PIXEL_SIZE;
	
	if (is_white(c)) {
    	c.rgb = mix(c.rgb, eye_color, amount);
	}
	
    COLOR = c;
}