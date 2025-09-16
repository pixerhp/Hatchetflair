shader_type spatial;

uniform sampler2DArray albedos_textures;
uniform sampler2DArray normals_textures;
uniform sampler2DArray specials_textures;
varying flat float albedos_index;
varying flat float normals_index;
varying flat float specials_index;

void vertex() { // Called for every vertex the material is visible on.
	// bytes input format:
	// alb3 alb2 alb1 spe2
	// nor3 nor2 nor1 spe1
	albedos_index = (CUSTOM0.x*16777216.0) + (CUSTOM0.y*65536.0) + (CUSTOM0.z*256.0);
	normals_index = (CUSTOM1.x*16777216.0) + (CUSTOM1.y*65536.0) + (CUSTOM1.z*256.0);
	specials_index = (CUSTOM0.w*65536.0) + (CUSTOM1.w*256.0);
}

void fragment() { // Called for every pixel the material is visible on.
	//ALPHA_SCISSOR_THRESHOLD = 0.5;
	vec4 albtex_color = texture(albedos_textures, vec3(UV.xy, albedos_index));
	ALBEDO = albtex_color.rgb * COLOR.rgb;
	NORMAL_MAP = texture(normals_textures, vec3(UV.xy, normals_index)).rgb;
	vec4 special = texture(specials_textures, vec3(UV.xy, specials_index));
	METALLIC = special.r;
	ROUGHNESS = special.g;
}