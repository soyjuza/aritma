// Guardianes de la tumba: "stone" los vuelve piedra gris (estatua dormida) y "flash" los
// aclara (aviso antes de golpear, golpe recibido). Se ajustan desde guardian.gd.
shader_type canvas_item;

uniform float stone : hint_range(0.0, 1.0) = 0.0;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 stone_color : source_color = vec4(0.82, 0.84, 0.86, 1.0);

void fragment() {
	vec4 c = COLOR;
	float g = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 gray = stone_color.rgb * (0.35 + g * 1.5);
	c.rgb = mix(c.rgb, gray, stone);
	c.rgb = mix(c.rgb, vec3(1.0, 0.95, 0.85), flash * 0.65);
	COLOR = c;
}
