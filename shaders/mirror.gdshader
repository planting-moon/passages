shader_type spatial;
render_mode unshaded, cull_back, fog_disabled;

// Silvered walls, floor and ceiling. Each fragment follows the view ray through
// the maze analytically, bouncing until it lands on a light, the exit door or
// the player's figure, or dissolves into haze. The cost depends on the bounce
// count rather than the maze size, and needs no extra viewports.

// Enough to cross the largest maze diagonally (61 + 61 tiles).
const int MAX_CELL_STEPS = 128;

uniform sampler2D maze_map : filter_nearest, repeat_disable;
uniform vec2 maze_size;
uniform vec2 maze_origin;
uniform float cell_size = 3.0;
uniform float wall_height = 2.6;
uniform int max_bounces = 6;
// Silver loses a little light on every bounce, with a slight green cast.
uniform vec3 mirror_tint : source_color = vec3(0.9, 0.95, 0.92);
// Depth dissolves into pale haze, so the black figure always reads against it.
uniform float distance_fade = 0.035;
uniform vec3 haze_color : source_color = vec3(0.62, 0.68, 0.65);

uniform vec3 trim_color : source_color = vec3(0.03, 0.03, 0.035);
// Panel joins between mirrors; 0 leaves the glass seamless, 0.008 draws thin lines.
uniform float seam_width = 0.0;

// Optional orientation aids: wall trim bands and a thin floor line that follows
// the walls where the carpet border would be.
uniform bool show_guides = false;
uniform float baseboard_height = 0.14;
uniform float top_trim_height = 0.05;
uniform float border_width = 0.3;
uniform float etch_width = 0.012;

// Chalk X marks. chalk_cells flags the maze cells worth testing, so most
// surface hits skip the loop over marks.
uniform sampler2D chalk_cells : filter_nearest, repeat_disable;
uniform int chalk_count = 0;
uniform vec3 chalk_pos[32];
uniform vec3 chalk_right[32];
uniform vec3 chalk_up[32];
uniform vec3 chalk_color : source_color = vec3(0.95, 0.95, 0.88);
uniform vec2 chalk_arm = vec2(0.2, 0.035);

uniform float light_spacing = 2.0;
uniform vec3 light_color : source_color = vec3(1.0, 0.95, 0.85);
// Sizes match the square fixture in recessed_light.gdshader.
uniform float light_hole = 0.12;
uniform float light_trim_width = 0.028;
uniform vec3 light_trim_color : source_color = vec3(0.74, 0.74, 0.72);

uniform vec2 door_center;
uniform vec2 door_normal;
uniform vec2 door_size = vec2(1.1, 2.2);
uniform vec3 door_color : source_color = vec3(1.0, 0.88, 0.68);
uniform float door_intensity = 1.0;

// Figure pose: feet position, its local +X in world XZ, and walk swing.
uniform vec3 figure_pos;
uniform vec2 figure_right = vec2(1.0, 0.0);
uniform float figure_swing = 0.0;

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

float safe(float v) {
	return abs(v) < 1e-5 ? (v < 0.0 ? -1e-5 : 1e-5) : v;
}

bool is_wall(vec2 cell) {
	if (cell.x < 0.0 || cell.y < 0.0 || cell.x >= maze_size.x || cell.y >= maze_size.y) {
		return true;
	}
	return texelFetch(maze_map, ivec2(cell), 0).r > 0.5;
}

// Walks the maze grid from ro; returns the distance to a wall, or limit if the
// ray reaches the floor or ceiling first.
float trace_walls(vec3 ro, vec3 rd, float limit, out vec3 normal) {
	vec2 d = vec2(safe(rd.x), safe(rd.z));
	vec2 p = (ro.xz - maze_origin) / cell_size;
	vec2 cell = floor(p);
	vec2 dir = sign(d);
	vec2 delta = abs(cell_size / d);
	vec2 next = (cell + max(dir, vec2(0.0)) - p) * cell_size / d;
	normal = vec3(0.0);
	for (int i = 0; i < MAX_CELL_STEPS; i++) {
		float t;
		if (next.x < next.y) {
			t = next.x;
			next.x += delta.x;
			cell.x += dir.x;
			normal = vec3(-dir.x, 0.0, 0.0);
		} else {
			t = next.y;
			next.y += delta.y;
			cell.y += dir.y;
			normal = vec3(0.0, 0.0, -dir.y);
		}
		if (t >= limit) {
			break;
		}
		if (is_wall(cell)) {
			return t;
		}
	}
	normal = vec3(0.0);
	return limit;
}

// Signed gap between a ray and a capsule; t is where along the ray it's closest.
float capsule_gap(vec3 ro, vec3 rd, vec3 a, vec3 b, float radius, out float t) {
	vec3 ba = b - a;
	vec3 w = ro - a;
	float k = dot(rd, ba);
	float c = dot(ba, ba);
	float d = dot(rd, w);
	float e = dot(ba, w);
	float s = clamp((e - k * d) / max(c - k * k, 1e-5), 0.0, 1.0);
	float along = max(k * s - d, 0.0);
	float gap = length(ro + rd * along - a - ba * s) - radius;
	t = along;
	return gap;
}

// Smallest gap between the ray and the figure's silhouette. Rays that clear a
// cylinder around the figure skip the limb tests, which is nearly all of them.
float figure_gap(vec3 ro, vec3 rd, out float t) {
	t = 1e5;
	vec3 o = ro - figure_pos;
	vec2 flat_dir = rd.xz;
	float flat_len = dot(flat_dir, flat_dir);
	float near = clamp(-dot(o.xz, flat_dir) / max(flat_len, 1e-5), 0.0, 1e4);
	if (length(o.xz + flat_dir * near) > 0.6) {
		return 1e5;
	}
	vec2 back = vec2(-figure_right.y, figure_right.x);
	vec3 lo = vec3(dot(o.xz, figure_right), o.y, dot(o.xz, back));
	vec3 ld = vec3(dot(rd.xz, figure_right), rd.y, dot(rd.xz, back));
	float s = figure_swing;
	float best = 1e5;
	float best_t = 1e5;
	float tt = 1e5;
	float g;
	// Head and neck.
	g = capsule_gap(lo, ld, vec3(0.0, 1.56, 0.0), vec3(0.0, 1.59, 0.0), 0.105, tt);
	if (g < best) { best = g; best_t = tt; }
	g = capsule_gap(lo, ld, vec3(0.0, 1.32, 0.0), vec3(0.0, 1.48, 0.0), 0.05, tt);
	if (g < best) { best = g; best_t = tt; }
	// Torso, shoulders and hips.
	g = capsule_gap(lo, ld, vec3(0.0, 1.0, 0.0), vec3(0.0, 1.3, 0.0), 0.17, tt);
	if (g < best) { best = g; best_t = tt; }
	g = capsule_gap(lo, ld, vec3(-0.17, 1.36, 0.0), vec3(0.17, 1.36, 0.0), 0.07, tt);
	if (g < best) { best = g; best_t = tt; }
	g = capsule_gap(lo, ld, vec3(-0.09, 0.95, 0.0), vec3(0.09, 0.95, 0.0), 0.1, tt);
	if (g < best) { best = g; best_t = tt; }
	// Arms and legs swing opposite each other.
	g = capsule_gap(lo, ld, vec3(-0.235, 1.36, 0.0), vec3(-0.27, 0.84, -s * 0.2), 0.055, tt);
	if (g < best) { best = g; best_t = tt; }
	g = capsule_gap(lo, ld, vec3(0.235, 1.36, 0.0), vec3(0.27, 0.84, s * 0.2), 0.055, tt);
	if (g < best) { best = g; best_t = tt; }
	g = capsule_gap(lo, ld, vec3(-0.095, 0.92, 0.0), vec3(-0.095, 0.05, s * 0.28), 0.085, tt);
	if (g < best) { best = g; best_t = tt; }
	g = capsule_gap(lo, ld, vec3(0.095, 0.92, 0.0), vec3(0.095, 0.05, -s * 0.28), 0.085, tt);
	if (g < best) { best = g; best_t = tt; }
	t = best_t;
	return best;
}

// Same wall distance as the border in carpet.gdshader.
float floor_etch(vec3 pos, float w) {
	if (!show_guides) {
		return 0.0;
	}
	vec2 p = pos.xz - maze_origin;
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
				d = min(d, max(q.x, q.y));
			}
		}
	}
	return 1.0 - smoothstep(etch_width, etch_width + w, abs(d - border_width));
}

float chalk_cover(vec3 pos, vec3 n, float w) {
	if (chalk_count == 0) {
		return 0.0;
	}
	vec2 cell = floor((pos.xz + n.xz * 0.05 - maze_origin) / cell_size);
	if (texelFetch(chalk_cells, ivec2(cell), 0).r < 0.5) {
		return 0.0;
	}
	float cover = 0.0;
	for (int i = 0; i < chalk_count; i++) {
		vec3 offset = pos - chalk_pos[i];
		vec3 mark_n = cross(chalk_right[i], chalk_up[i]);
		if (dot(mark_n, n) < 0.5 || abs(dot(offset, mark_n)) > 0.05) {
			continue;
		}
		float u = dot(offset, chalk_right[i]);
		float v = dot(offset, chalk_up[i]);
		// The two bars of the X, at +-45 degrees.
		vec2 q = abs(vec2(u + v, u - v)) * 0.7071;
		float d = min(max(q.x - chalk_arm.x, q.y - chalk_arm.y), max(q.y - chalk_arm.x, q.x - chalk_arm.y));
		cover = max(cover, 1.0 - smoothstep(-w, w, d));
	}
	return cover;
}

float seam_cover(vec3 pos, vec3 n, float w) {
	if (seam_width <= 0.0) {
		return 0.0;
	}
	vec2 q = (pos.xz - maze_origin) / cell_size;
	vec2 d = abs(fract(q + 0.5) - 0.5) * cell_size;
	float e = abs(n.y) > 0.5 ? min(d.x, d.y) : (abs(n.x) > 0.5 ? d.y : d.x);
	return 1.0 - smoothstep(seam_width, seam_width + w, e);
}

void fragment() {
	vec3 n = normalize(world_normal);
	vec3 from_camera = world_pos - CAMERA_POSITION_WORLD;
	float travelled = length(from_camera);
	vec3 view = from_camera / travelled;
	// World-space size of a pixel per metre of path, for analytic edge softening.
	float px = length(fwidth(view));

	vec3 ro = world_pos + n * 0.002;
	vec3 rd = reflect(view, n);
	vec3 through = mirror_tint;
	vec3 light = vec3(0.0);
	float seam = seam_cover(world_pos, n, px * travelled);
	if (n.y > 0.5) {
		seam = max(seam, floor_etch(world_pos, px * travelled));
	}
	light += through * trim_color * seam;
	through *= 1.0 - seam;
	bool finished = false;

	for (int bounce = 0; bounce < max_bounces; bounce++) {
		float limit = rd.y > 0.0 ? (wall_height - ro.y) / safe(rd.y) : -ro.y / safe(rd.y);
		vec3 wall_n;
		float t = trace_walls(ro, rd, limit, wall_n);
		bool hit_wall = dot(wall_n, wall_n) > 0.5;

		float figure_t;
		float gap = figure_gap(ro, rd, figure_t);
		if (figure_t < t) {
			float w = max(px * (travelled + figure_t), 0.002);
			float cover = 1.0 - smoothstep(-w, w, gap);
			through *= 1.0 - cover;
			if (cover > 0.99) {
				finished = true;
				break;
			}
		}

		vec3 pos = ro + rd * t;
		travelled += t;
		float keep = exp(-t * distance_fade);
		light += through * haze_color * (1.0 - keep);
		through *= keep;
		float w = px * travelled;

		vec3 surface_n = wall_n;
		if (hit_wall) {
			vec2 door_offset = pos.xz - door_center;
			bool door_plane = dot(wall_n.xz, door_normal) > 0.5 && abs(dot(door_offset, door_normal)) < 0.02;
			if (door_plane) {
				float u = abs(door_offset.x * door_normal.y - door_offset.y * door_normal.x);
				if (u < door_size.x * 0.5 && pos.y < door_size.y) {
					light += through * door_color * 2.2 * door_intensity;
					finished = true;
					break;
				}
				if (u < door_size.x * 0.5 + 0.09 && pos.y < door_size.y + 0.09) {
					light += through * trim_color;
					finished = true;
					break;
				}
			}
			if (show_guides && (pos.y < baseboard_height || pos.y > wall_height - top_trim_height)) {
				light += through * trim_color;
				finished = true;
				break;
			}
		} else if (rd.y > 0.0) {
			surface_n = vec3(0.0, -1.0, 0.0);
			vec2 cell = floor((pos.xz - maze_origin) / cell_size);
			vec2 fixture = mod(cell, light_spacing);
			vec2 local = abs(pos.xz - (maze_origin + (cell + 0.5) * cell_size));
			float fixture_extent = max(local.x, local.y);
			if (fixture.x == 1.0 && fixture.y == 1.0 && fixture_extent < light_hole + light_trim_width) {
				light += through * (fixture_extent < light_hole ? light_color * 4.0 : light_trim_color);
				finished = true;
				break;
			}
		} else {
			surface_n = vec3(0.0, 1.0, 0.0);
		}
		float cover = seam_cover(pos, surface_n, w);
		if (surface_n.y > 0.5) {
			cover = max(cover, floor_etch(pos, w));
		}
		light += through * trim_color * cover;
		through *= 1.0 - cover;
		float chalk = chalk_cover(pos, surface_n, w);
		light += through * chalk_color * chalk;
		through *= (1.0 - chalk) * mirror_tint;
		ro = pos + surface_n * 0.002;
		rd = reflect(rd, surface_n);
	}
	if (!finished) {
		light += through * haze_color;
	}
	ALBEDO = light;
}
