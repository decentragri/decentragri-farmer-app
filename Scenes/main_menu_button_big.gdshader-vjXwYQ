shader_type canvas_item;

uniform float corner_radius = 20.0; // Radius in pixels
uniform sampler2D texture : source_color;

void fragment() {
	vec2 uv = UV;
	vec2 size = vec2(textureSize(texture, 0));
	vec2 pixel_pos = uv * size;

	// Calculate distance from the closest edge
	float min_x = min(pixel_pos.x, size.x - pixel_pos.x);
	float min_y = min(pixel_pos.y, size.y - pixel_pos.y);
	float min_dist = min(min_x, min_y);

	// If close to corner, calculate circular mask
	if (min_x < corner_radius && min_y < corner_radius) {
		vec2 corner_center = vec2(
			pixel_pos.x < size.x / 2.0 ? corner_radius : size.x - corner_radius,
			pixel_pos.y < size.y / 2.0 ? corner_radius : size.y - corner_radius
		);
		float dist_to_corner = distance(pixel_pos, corner_center);
		if (dist_to_corner > corner_radius) {
			discard;
		}
	}

	COLOR = texture(texture, uv) * COLOR;
}
