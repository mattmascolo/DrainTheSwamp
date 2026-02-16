shader_type canvas_item;

uniform float noise_scale : hint_range(0.5, 4.0) = 1.5;
uniform float noise_strength : hint_range(0.0, 0.15) = 0.06;
uniform float striation_strength : hint_range(0.0, 0.1) = 0.03;

// Simple hash-based noise
float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec4 col = COLOR;

	// Procedural grain noise
	vec2 world_uv = FRAGCOORD.xy * noise_scale;
	float n = noise(world_uv * 0.15) * 2.0 - 1.0;
	col.rgb += n * noise_strength;

	// Horizontal striation bands
	float stria = sin(FRAGCOORD.y * 0.8) * 0.5 + 0.5;
	stria *= noise(vec2(FRAGCOORD.y * 0.3, 0.0));
	col.rgb -= stria * striation_strength;

	COLOR = col;
}
