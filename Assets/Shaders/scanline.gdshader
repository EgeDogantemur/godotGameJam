shader_type canvas_item;

uniform float line_count : hint_range(50.0, 500.0) = 200.0;
uniform float opacity : hint_range(0.0, 0.3) = 0.06;
uniform float scroll_speed : hint_range(0.0, 2.0) = 0.25;

void fragment() {
	float y = FRAGCOORD.y + TIME * scroll_speed * 100.0;
	float scanline = sin(y * 3.14159 * 2.0 / (1080.0 / line_count)) * 0.5 + 0.5;
	COLOR = vec4(0.0, 0.0, 0.0, scanline * opacity);
}
