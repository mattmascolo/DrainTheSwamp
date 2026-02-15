shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float time = 0.0;
uniform float scanline_strength : hint_range(0.0, 0.3) = 0.06;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.3;
uniform float saturation : hint_range(0.0, 1.5) = 1.0;
uniform float heat_shimmer_strength : hint_range(0.0, 1.0) = 0.0;
uniform float warmth : hint_range(-0.1, 0.1) = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;

	// Heat shimmer distortion (subtle wavy air)
	if (heat_shimmer_strength > 0.001) {
		float shimmer_x = sin(uv.y * 50.0 + time * 1.8) * 0.0008 * heat_shimmer_strength;
		float shimmer_y = cos(uv.x * 40.0 + time * 1.3) * 0.0004 * heat_shimmer_strength;
		uv += vec2(shimmer_x, shimmer_y);
	}

	vec4 col = texture(screen_texture, uv);

	// Saturation adjustment (world progression: desaturated early, vibrant late)
	float gray = dot(col.rgb, vec3(0.299, 0.587, 0.114));
	col.rgb = mix(vec3(gray), col.rgb, saturation);

	// Warm/cool color grading shift
	col.r += warmth;
	col.b -= warmth;

	// CRT scanlines (subtle darkening on alternating rows)
	float scanline = sin(FRAGCOORD.y * 3.14159265) * 0.5 + 0.5;
	col.rgb -= scanline_strength * (1.0 - scanline);

	// Vignette (darken edges)
	vec2 center = uv - 0.5;
	float dist = length(center);
	float vignette = smoothstep(0.4, 0.85, dist * 1.4);
	col.rgb *= 1.0 - vignette * vignette_strength;

	COLOR = col;
}
