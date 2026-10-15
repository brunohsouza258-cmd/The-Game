shader_type canvas_item;

// Fatias horizontais deslocadas, separação RGB e inversão: o "rosto errado" do terror.
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float invert : hint_range(0.0, 1.0) = 0.0;
uniform float seed = 0.0;

varying vec4 v_modulate;

void vertex() {
	v_modulate = COLOR;
}

void fragment() {
	vec2 uv = UV;
	float band = floor(uv.y * 28.0);
	float rnd = fract(sin(band * 12.9898 + seed * 4.1) * 43758.5453);
	float on = step(0.72, fract(rnd * 9.0 + seed));
	uv.x += (rnd - 0.5) * 0.16 * intensity * on;
	float split = 0.014 * intensity;
	vec4 t = texture(TEXTURE, uv);
	t.r = texture(TEXTURE, uv + vec2(split, 0.0)).r;
	t.b = texture(TEXTURE, uv - vec2(split, 0.0)).b;
	t.rgb = mix(t.rgb, vec3(1.0) - t.rgb, invert);
	COLOR = t * v_modulate;
}
