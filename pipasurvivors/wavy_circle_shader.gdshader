shader_type canvas_item;
render_mode unshaded;

// Parâmetros ajustáveis
uniform float time = 0.0;
uniform float pulse_speed = 3.0;
uniform float glow_intensity = 1.0;
uniform float color_cycle_speed = 2.0;
uniform vec4 base_color : source_color = vec4(0.0, 0.8, 1.0, 1.0);

void fragment() {
	// Cor base da textura ou cor uniforme
	vec4 tex_color = texture(TEXTURE, UV);
	vec4 final_base_color = tex_color.a > 0.0 ? tex_color : base_color;

	// Efeito de pulsação
	float pulse = sin(time * pulse_speed) * 0.3 + 0.7;

	// Efeito de brilho/glow ao longo da linha
	float glow = sin(UV.x * 50.0 + time * 3.0) * 0.5 + 0.5;
	glow *= glow_intensity;

	// Ciclo de cores suave
	float hue_shift = sin(time * color_cycle_speed) * 0.1;
	vec3 shifted_color = final_base_color.rgb + vec3(hue_shift, hue_shift * 0.5, -hue_shift);

	// Combina todos os efeitos
	vec3 final_color = shifted_color * pulse + vec3(glow * 0.3);
	float alpha = final_base_color.a * (0.9 + glow * 0.2);

	COLOR = vec4(final_color, alpha);
}