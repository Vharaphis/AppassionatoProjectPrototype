shader_type spatial;

uniform vec3 base_color : source_color = vec3(0.30, 0.32, 0.36);
uniform vec3 line_color : source_color = vec3(0.20, 0.22, 0.26);
// Size of one grid cell, in meters.
uniform float cell_size = 2.0;
// Half width of the grid lines, as a fraction of a cell.
uniform float line_width = 0.015;

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Grid drawn in world space so it does not stretch when the arena is resized.
	vec2 coord = world_position.xz / cell_size;
	vec2 distance_to_line = abs(fract(coord - 0.5) - 0.5);
	vec2 aa = fwidth(coord);
	vec2 lines = 1.0 - smoothstep(vec2(line_width) - aa, vec2(line_width) + aa, distance_to_line);
	ALBEDO = mix(base_color, line_color, max(lines.x, lines.y));
	ROUGHNESS = 0.9;
}
