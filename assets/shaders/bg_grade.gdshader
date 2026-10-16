shader_type canvas_item;

// Acabamento único para todos os cenários (os pintados originais, os do Gutari e os feitos por
// código): um pouco de nitidez, a mesma saturação/contraste e uma vinheta suave. Nada animado.
uniform float sharpen : hint_range(0.0, 1.5) = 0.55;
uniform float saturation : hint_range(0.0, 2.0) = 0.9;
uniform float contrast : hint_range(0.5, 1.5) = 1.05;
uniform vec3 grade = vec3(1.0, 0.97, 1.02);
uniform float vignette : hint_range(0.0, 1.0) = 0.28;

varying vec4 v_modulate;

void vertex() {
	v_modulate = COLOR;
}

void fragment() {
	vec2 px = TEXTURE_PIXEL_SIZE * 1.5;
	vec3 c = texture(TEXTURE, UV).rgb;
	vec3 blur = (texture(TEXTURE, UV + vec2(px.x, 0.0)).rgb + texture(TEXTURE, UV - vec2(px.x, 0.0)).rgb
		+ texture(TEXTURE, UV + vec2(0.0, px.y)).rgb + texture(TEXTURE, UV - vec2(0.0, px.y)).rgb) * 0.25;
	c = c + (c - blur) * sharpen;
	float luma = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(luma), c, saturation);
	c = (c - 0.5) * contrast + 0.5;
	c *= grade;
	float d = distance(UV, vec2(0.5));
	c *= 1.0 - vignette * smoothstep(0.35, 0.85, d);
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0) * v_modulate;
}
