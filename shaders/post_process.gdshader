shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float time = 0.0;
uniform float scanline_strength : hint_range(0.0, 0.3) = 0.0;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.15;
uniform float saturation : hint_range(0.0, 1.5) = 1.0;
uniform float heat_shimmer_strength : hint_range(0.0, 1.0) = 0.0;
uniform float warmth : hint_range(-0.1, 0.1) = 0.0;
uniform float chromatic_aberration : hint_range(0.0, 3.0) = 0.5;
uniform float bloom_strength : hint_range(0.0, 1.0) = 0.15;
uniform float film_grain_strength : hint_range(0.0, 0.1) = 0.03;
uniform float night_factor : hint_range(0.0, 1.0) = 0.0;

// Simple hash for film grain noise
float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec2 uv = SCREEN_UV;

	// Heat shimmer distortion (subtle wavy air)
	if (heat_shimmer_strength > 0.001) {
		float shimmer_x = sin(uv.y * 50.0 + time * 1.8) * 0.0008 * heat_shimmer_strength;
		float shimmer_y = cos(uv.x * 40.0 + time * 1.3) * 0.0004 * heat_shimmer_strength;
		uv += vec2(shimmer_x, shimmer_y);
	}

	// Chromatic aberration (subtle RGB split at screen edges)
	vec4 col;
	if (chromatic_aberration > 0.01) {
		vec2 ca_dir = (uv - 0.5) * chromatic_aberration * 0.002;
		float r = texture(screen_texture, uv + ca_dir).r;
		float g = texture(screen_texture, uv).g;
		float b = texture(screen_texture, uv - ca_dir).b;
		col = vec4(r, g, b, 1.0);
	} else {
		col = texture(screen_texture, uv);
	}

	// Bloom approximation (bright areas glow)
	if (bloom_strength > 0.001) {
		vec2 texel = 1.0 / vec2(textureSize(screen_texture, 0));
		vec4 bloom_col = vec4(0.0);
		bloom_col += texture(screen_texture, uv + vec2(-texel.x, 0.0) * 2.0);
		bloom_col += texture(screen_texture, uv + vec2(texel.x, 0.0) * 2.0);
		bloom_col += texture(screen_texture, uv + vec2(0.0, -texel.y) * 2.0);
		bloom_col += texture(screen_texture, uv + vec2(0.0, texel.y) * 2.0);
		bloom_col *= 0.25;
		float bloom_lum = dot(bloom_col.rgb, vec3(0.299, 0.587, 0.114));
		float bloom_mask = smoothstep(0.6, 1.0, bloom_lum);
		col.rgb += bloom_col.rgb * bloom_mask * bloom_strength;
	}

	// Saturation adjustment (world progression: desaturated early, vibrant late)
	float gray = dot(col.rgb, vec3(0.299, 0.587, 0.114));
	col.rgb = mix(vec3(gray), col.rgb, saturation);

	// Warm/cool color grading shift
	col.r += warmth;
	col.b -= warmth;

	// Night blue shift (beyond CanvasModulate darkening)
	if (night_factor > 0.001) {
		col.rgb = mix(col.rgb, col.rgb * vec3(0.7, 0.75, 1.15), night_factor * 0.3);
	}

	// Film grain (animated noise overlay)
	if (film_grain_strength > 0.001) {
		float grain = hash(uv * vec2(640.0, 360.0) + vec2(time * 7.3, time * 3.7)) - 0.5;
		col.rgb += grain * film_grain_strength;
	}

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
