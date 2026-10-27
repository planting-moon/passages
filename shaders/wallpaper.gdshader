shader_type spatial;

// Procedural, low-contrast wallpaper. Patterns are drawn in world space so they
// line up across neighbouring wall blocks and stay crisp at any resolution.
//
// 0 plain, 1 pinstripe, 2 dots, 3 lattice, 4 grid, 5 chevron,
// 6 plus marks, 7 scallop, 8 ticking bands

uniform vec3 paper_color : source_color = vec3(0.8, 0.75, 0.65);
uniform vec3 ink_color : source_color = vec3(0.7, 0.65, 0.56);
uniform int pattern = 0;
uniform float pattern_scale = 4.0;
uniform float line_width = 0.06;
uniform float grain = 0.025;
uniform float roughness_value = 0.85;

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

// Anti-aliased mask: 1 where d < edge.
float inside(float d, float edge) {
	float w = max(fwidth(d), 1e-4);
	return 1.0 - smoothstep(edge - w, edge + w, d);
}

// Distance to the nearest integer line.
float line_dist(float x) {
	return abs(fract(x + 0.5) - 0.5);
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
		u.y
	);
}

float pattern_mask(vec2 uv) {
	float hw = line_width * 0.5;
	if (pattern == 1) {
		return inside(line_dist(uv.x), hw);
	} else if (pattern == 2) {
		vec2 cell = uv;
		cell.x += 0.5 * mod(floor(cell.y), 2.0);
		return inside(length(fract(cell) - 0.5), line_width);
	} else if (pattern == 3) {
		return max(inside(line_dist(uv.x + uv.y), hw), inside(line_dist(uv.x - uv.y), hw));
	} else if (pattern == 4) {
		return max(inside(line_dist(uv.x), hw), inside(line_dist(uv.y), hw));
	} else if (pattern == 5) {
		float v = uv.y + abs(fract(uv.x) - 0.5);
		return inside(line_dist(v), hw);
	} else if (pattern == 6) {
		vec2 cell = uv;
		cell.x += 0.5 * mod(floor(cell.y), 2.0);
		vec2 p = abs(fract(cell) - 0.5);
		float arm = 0.12;
		float h = inside(p.y, hw) * inside(p.x, arm);
		float v = inside(p.x, hw) * inside(p.y, arm);
		return max(h, v);
	} else if (pattern == 7) {
		vec2 cell = uv;
		cell.x += 0.5 * mod(floor(cell.y), 2.0);
		vec2 f = fract(cell) - vec2(0.5, 0.0);
		return inside(abs(length(f) - 0.5), hw);
	} else if (pattern == 8) {
		float a = inside(line_dist(uv.y), hw);
		float b = inside(line_dist(uv.y + 0.18), hw * 0.4);
		return max(a, b);
	}
	return 0.0;
}

void fragment() {
	vec3 n = abs(world_normal);
	vec2 uv;
	if (n.y > 0.5) {
		uv = world_pos.xz;
	} else if (n.x > n.z) {
		uv = vec2(world_pos.z, world_pos.y);
	} else {
		uv = world_pos.xy;
	}
	float ink = pattern_mask(uv * pattern_scale);
	vec3 color = mix(paper_color, ink_color, ink);
	float g = value_noise(uv * 38.0) * 0.6 + value_noise(uv * 9.0) * 0.4;
	color *= 1.0 + (g - 0.5) * grain * 2.0;
	ALBEDO = color;
	ROUGHNESS = roughness_value;
}
