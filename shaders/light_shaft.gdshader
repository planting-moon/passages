shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled;

// Soft additive beam spilling out of the doorway. UV.y runs 0 at the door to
// 1 at the far end; faces seen edge-on fade out so the volume has no hard seams.

uniform vec3 light_color : source_color = vec3(1.0, 0.88, 0.68);
uniform float intensity = 0.12;

varying float along;

void vertex() {
	along = UV.y;
}

void fragment() {
	float facing = abs(dot(NORMAL, VIEW));
	float fade = 1.0 - along;
	fade *= fade;
	ALBEDO = light_color * intensity * fade * facing * facing;
}
