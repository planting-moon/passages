shader_type spatial;
render_mode unshaded, cull_back, fog_disabled;

// A flat quad that looks like a deep, light-filled passage behind it
// (interior mapping). The quad faces local +Z; the virtual tunnel runs
// back along local -Z and gets brighter toward its far end.

uniform vec2 opening_size = vec2(1.1, 2.2);
uniform float depth = 3.0;
uniform vec3 light_color : source_color = vec3(1.0, 0.88, 0.68);
uniform float intensity = 1.0;

varying vec3 local_pos;
varying vec3 cam_local;

void vertex() {
	local_pos = VERTEX;
	cam_local = (inverse(MODEL_MATRIX) * vec4(CAMERA_POSITION_WORLD, 1.0)).xyz;
}

float safe(float v) {
	return abs(v) < 1e-5 ? 1e-5 : v;
}

void fragment() {
	vec3 dir = normalize(local_pos - cam_local);
	vec2 half_size = opening_size * 0.5;
	float tx = (sign(dir.x) * half_size.x - local_pos.x) / safe(dir.x);
	float ty = (sign(dir.y) * half_size.y - local_pos.y) / safe(dir.y);
	float tz = (-depth - local_pos.z) / safe(dir.z);
	float t = min(min(tx, ty), tz);
	vec3 hit = local_pos + dir * t;
	float d = clamp(-hit.z / depth, 0.0, 1.0);

	vec3 color;
	if (t == tz) {
		// Far end: blown-out light with a soft hotspot.
		vec2 q = hit.xy / half_size;
		float hotspot = 1.0 - smoothstep(0.0, 1.2, length(q * vec2(1.0, 0.6)));
		color = mix(light_color, vec3(1.0), 0.6) * (1.6 + hotspot * 0.6);
	} else {
		// Tunnel walls: dim near the opening, brightening into the light.
		float face = 1.0;
		if (t == ty) {
			face = dir.y < 0.0 ? 0.9 : 0.7;
		}
		float glow = mix(0.28, 1.5, pow(d, 1.6));
		color = mix(light_color, vec3(1.0), d * 0.45) * glow * face;
	}
	ALBEDO = color * intensity;
}
