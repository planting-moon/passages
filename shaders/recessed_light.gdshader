shader_type spatial;
render_mode cull_back;

// Recessed downlight drawn on a flat disc flush with the ceiling: a matte trim
// ring, and inside it a virtual cylindrical can (interior mapping) with a
// grooved baffle and a glowing bulb lens at the top. The disc faces local +Y;
// the can extends back along local -Y.

uniform float hole_radius = 0.12;
uniform float trim_width = 0.028;
uniform float depth = 0.09;
uniform vec3 trim_color : source_color = vec3(0.93, 0.92, 0.9);
uniform vec3 baffle_color : source_color = vec3(0.82, 0.8, 0.78);
uniform vec3 bulb_color : source_color = vec3(1.0, 0.92, 0.78);
uniform float bulb_intensity = 3.0;

varying vec3 local_pos;
varying vec3 cam_local;

void vertex() {
	local_pos = VERTEX;
	cam_local = (inverse(MODEL_MATRIX) * vec4(CAMERA_POSITION_WORLD, 1.0)).xyz;
}

void fragment() {
	float r = length(local_pos.xz);
	if (r > hole_radius + trim_width) {
		discard;
	}
	if (r > hole_radius) {
		float edge = smoothstep(0.0, 0.5, (r - hole_radius) / trim_width);
		ALBEDO = trim_color * mix(0.8, 1.0, edge);
		ROUGHNESS = 0.55;
	} else {
		vec3 dir = normalize(local_pos - cam_local);
		vec2 o = local_pos.xz;
		vec2 dv = dir.xz;
		float a = max(dot(dv, dv), 1e-6);
		float b = 2.0 * dot(o, dv);
		float c = dot(o, o) - hole_radius * hole_radius;
		float t_wall = (-b + sqrt(max(b * b - 4.0 * a * c, 0.0))) / (2.0 * a);
		float t_top = (-depth - local_pos.y) / min(dir.y, -1e-5);
		vec3 color;
		if (t_top <= t_wall) {
			float rr = length(o + dv * t_top) / hole_radius;
			float lens = 1.0 - smoothstep(0.55, 0.8, rr);
			color = mix(baffle_color * bulb_color * 0.9, bulb_color * bulb_intensity, lens);
		} else {
			float h = clamp(-(local_pos.y + dir.y * t_wall) / depth, 0.0, 1.0);
			float grooves = 0.82 + 0.18 * sin(h * depth * 520.0);
			color = baffle_color * bulb_color * mix(0.9, 1.9, h * h) * grooves;
		}
		ALBEDO = vec3(0.0);
		ROUGHNESS = 1.0;
		SPECULAR = 0.0;
		EMISSION = color;
	}
}
