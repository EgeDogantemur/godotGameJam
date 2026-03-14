shader_type canvas_item;

uniform float proximity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 danger_color : source_color = vec4(1.0, 0.05, 0.05, 1.0);

void fragment() {
	vec2 uv = UV;
	float vignette = length(uv - vec2(0.5)) * 2.0;
	float edge = smoothstep(0.5, 1.3, vignette);
	float pulse = 0.7 + 0.3 * sin(TIME * 5.0);
	float alpha = edge * proximity * pulse;
	COLOR = vec4(danger_color.rgb, alpha * 0.7);
}
