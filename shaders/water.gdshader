shader_type canvas_item;

uniform float time = 0.0;
uniform float wave_strength : hint_range(0.0, 4.0) = 1.5;
uniform float specular_intensity : hint_range(0.0, 1.0) = 0.25;
uniform float choppiness : hint_range(0.0, 3.0) = 0.0;
uniform float turbidity : hint_range(0.0, 1.0) = 0.0;
uniform float foam_density : hint_range(0.0, 2.0) = 1.0;

void vertex() {
	VERTEX.y += sin(VERTEX.x * 0.12 + time * 2.0) * wave_strength;
	VERTEX.x += cos(VERTEX.y * 0.18 + time * 1.4) * wave_strength * 0.25;
	// Secondary high-freq choppiness wave
	VERTEX.y += sin(VERTEX.x * 0.35 + time * 3.5) * choppiness * 0.6;
}

void fragment() {
	vec4 col = COLOR;

	// Specular highlight shifts across surface
	float spec_wave = sin(UV.x * 8.0 + time * 1.2) * sin(UV.x * 3.0 - time * 0.7);
	float spec = pow(max(0.0, spec_wave), 3.0) * specular_intensity;
	// Specular is brightest near surface
	spec *= smoothstep(0.4, 0.0, UV.y);
	col.rgb += vec3(spec);

	// Edge foam at water surface (UV.y near 0)
	float foam_noise = sin(UV.x * 20.0 + time * 3.0) * 0.5 + 0.5;
	float foam = smoothstep(0.12, 0.0, UV.y) * 0.2 * (0.6 + foam_noise * 0.4) * foam_density;
	col.rgb += vec3(foam);

	// Subtle depth darkening (increased by turbidity)
	float depth = smoothstep(0.5, 1.0, UV.y) * (0.12 + turbidity * 0.15);
	col.rgb -= vec3(depth);

	// Subtle caustic pattern underwater (dampened by turbidity)
	float caustic1 = sin(UV.x * 15.0 + UV.y * 8.0 + time * 1.5);
	float caustic2 = sin(UV.x * 12.0 - UV.y * 10.0 + time * 1.1);
	float caustic = pow(max(0.0, caustic1 * caustic2), 2.0) * 0.08 * (1.0 - turbidity * 0.8);
	caustic *= smoothstep(0.1, 0.4, UV.y); // Only below surface
	col.rgb += vec3(caustic * 0.5, caustic, caustic * 0.7);

	COLOR = col;
}
