shader_type spatial;

// Carpet with a border band that follows the walls. The maze layout comes in
// as a one-pixel-per-cell map (white = wall); each fragment finds its distance
// to the nearest wall block among the 8 surrounding cells.

uniform sampler2D maze_map : filter_nearest, repeat_disable;
uniform vec2 maze_size;
uniform vec2 maze_origin;
uniform float cell_size = 3.0;
uniform float border_width = 0.3;
uniform vec3 field_color : source_color = vec3(0.55, 0.5, 0.44);
uniform vec3 border_color : source_color = vec3(0.35, 0.3, 0.26);
uniform float grain = 0.05;
uniform float roughness_value = 1.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

bool is_wall(vec2 cell) {
	if (cell.x < 0.0 || cell.y < 0.0 || cell.x >= maze_size.x || cell.y >= maze_size.y) {
		return true;
	}
	return texelFetch(maze_map, ivec2(cell), 0).r > 0.5;
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

void fragment() {
	vec2 p = world_pos.xz - maze_origin;
	vec2 cell = floor(p / cell_size);
	vec2 local = p - cell * cell_size;
	float d = 1e3;
	for (int dy = -1; dy <= 1; dy++) {
		for (int dx = -1; dx <= 1; dx++) {
			if (dx == 0 && dy == 0) {
				continue;
			}
			vec2 offset = vec2(float(dx), float(dy));
			if (is_wall(cell + offset)) {
				vec2 rmin = offset * cell_size;
				vec2 rmax = rmin + cell_size;
				vec2 q = max(max(rmin - local, local - rmax), vec2(0.0));
				// Chebyshev distance keeps the border's outer corners square.
				d = min(d, max(q.x, q.y));
			}
		}
	}
	float w = max(fwidth(d), 1e-4);
	float field = smoothstep(border_width - w, border_width + w, d);
	vec3 color = mix(border_color, field_color, field);
	float g = value_noise(world_pos.xz * 90.0) * 0.5 + value_noise(world_pos.xz * 24.0) * 0.5;
	color *= 1.0 + (g - 0.5) * grain * 2.0;
	ALBEDO = color;
	ROUGHNESS = roughness_value;
}
