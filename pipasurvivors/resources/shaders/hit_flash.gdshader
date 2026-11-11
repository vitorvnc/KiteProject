shader_type canvas_item;

// Controla a intensidade do branco (0.0 = normal, 1.0 = branco total)
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	
	// Mistura a cor original com o branco puro baseado no flash_amount
	COLOR = mix(tex, vec4(1.0, 1.0, 1.0, tex.a), flash_amount);
}