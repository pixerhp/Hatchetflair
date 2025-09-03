shader_type spatial;

uniform sampler2DArray albedos_textures;
varying flat float albedos_index;
uniform sampler2DArray normals_textures;
varying flat float normals_index;
uniform sampler2DArray specials_textures;
varying flat float specials_index;

void vertex() {
	switch(int(CUSTOM0.x * 256.0)) {
		case 0:
			albedos_index = (CUSTOM0.y*16777216.0) + (CUSTOM0.z*65536.0) + (CUSTOM0.w*256.0);
			break;
		case 1:
			normals_index = (CUSTOM0.y*16777216.0) + (CUSTOM0.z*65536.0) + (CUSTOM0.w*256.0);
			break;
		case 2:
			specials_index = (CUSTOM0.y*16777216.0) + (CUSTOM0.z*65536.0) + (CUSTOM0.w*256.0);
			break;
		default:
			break;
	}
	
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	
	vec4 color = texture(albedos_textures, vec3(UV.xy, albedos_index));
	ALPHA = color.a;
	ALBEDO = color.rgb;
	NORMAL_MAP = texture(normals_textures, vec3(-UV.xy, normals_index)).rgb;
	vec4 special = texture(specials_textures, vec3(UV.xy, specials_index));
	METALLIC = special.r;
	ROUGHNESS = special.g;
}