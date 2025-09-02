shader_type spatial;

uniform sampler2DArray albedo_textures;
uniform sampler2DArray normal_map_textures;
uniform sampler2DArray specials_textures;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec4 color = texture(albedo_textures, vec3(SCREEN_UV.xy, 0));
	ALPHA = color.a;
	ALBEDO = color.rgb;
	NORMAL_MAP = texture(normal_map_textures, vec3(SCREEN_UV.xy, 1)).rgb;
	vec4 special = texture(specials_textures, vec3(SCREEN_UV.xy, 1));
	METALLIC = special.r;
	ROUGHNESS = special.g;
}