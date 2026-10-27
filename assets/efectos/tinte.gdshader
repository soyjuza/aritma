// Pinta el sprite de un color (para que cada jefe se vea distinto).
shader_type canvas_item;
render_mode unshaded;

uniform vec4 tint : source_color = vec4(1.0);
uniform float amount = 0.85;

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	float g = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(mix(c.rgb, g * tint.rgb * 1.7, amount), c.a);
}
