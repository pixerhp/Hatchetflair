extends Node

@onready var chunks_container_node: Node = self

enum TILE_SHAPE {
	NO_DATA, EMPTY, MARCH_ANG, MARCH_WEI, TESS_CUBE, TESS_RHOMBDO, CLIFF, POWDER, # BUBBLES? LIQUID?
}

class TChunk:
	static var blank_tc27: Array[TChunk] = []
	
	var tc_coords: Vector3i = Vector3i(0,0,0)
	# var local_biome_data ?
	var tile_shapes: PackedByteArray = []
	var tile_substs: PackedInt32Array = []
	
	var is_mesh_accurate: bool = false
		# Does the mesh accurately reflect current data, or does it need to be remeshed?
	var mesh_instance_node: MeshInstance3D = MeshInstance3D.new()
	var array_mesh: ArrayMesh = ArrayMesh.new()
	
	static func get_tc27_tchunk_i(cen_pos: Vector3i, rel_pos: Vector3i) -> int:
		var new_pos: Vector3i = Vector3i(cen_pos + rel_pos)
		var chunk_xyz: Vector3i = Vector3i(
			(new_pos.x/TCU.TCHUNK_L) if (new_pos.x >= 0) else ((new_pos.x-(TCU.TCHUNK_L-1))/TCU.TCHUNK_L),
			(new_pos.y/TCU.TCHUNK_L) if (new_pos.y >= 0) else ((new_pos.y-(TCU.TCHUNK_L-1))/TCU.TCHUNK_L),
			(new_pos.z/TCU.TCHUNK_L) if (new_pos.z >= 0) else ((new_pos.z-(TCU.TCHUNK_L-1))/TCU.TCHUNK_L),
		)
		chunk_xyz += Vector3i(1, 1, 1)
		return chunk_xyz.x + (3 * chunk_xyz.y) + (9 * chunk_xyz.z)
	static func get_tc27_tile_i(cen_pos: Vector3i, rel_pos: Vector3i) -> int:
		return (
			posmod(cen_pos.x + rel_pos.x, TCU.TCHUNK_L) +
			posmod(cen_pos.y + rel_pos.y, TCU.TCHUNK_L) * TCU.TCHUNK_L +
			posmod(cen_pos.z + rel_pos.z, TCU.TCHUNK_L) * TCU.TCHUNK_L * TCU.TCHUNK_L
		)
	
	func t_i_from_xyz(xyz: Vector3i) -> int:
		return xyz.x + (xyz.y * TCU.TCHUNK_L) + (xyz.z * TCU.TCHUNK_L * TCU.TCHUNK_L)
	func t_xyz_from_i(i: int) -> Vector3i:
		return Vector3i(
			posmod(i, TCU.TCHUNK_L), posmod(i / TCU.TCHUNK_L, TCU.TCHUNK_L), posmod(i / (TCU.TCHUNK_L * TCU.TCHUNK_L), TCU.TCHUNK_L),
		)
	
	func _init():
		tile_shapes.resize(TCU.TCHUNK_T)
		tile_shapes.fill(TILE_SHAPE.NO_DATA)
		tile_substs.resize(TCU.TCHUNK_T)
		tile_shapes.fill(0)
	
	# !!! note that in the future, setting a tile in a chunk should make some surrounding chunks have to remesh.
	func set_tile(pos: Vector3i, shape: int, subst: Variant):
		var tile_index: int = t_i_from_xyz(pos)
		self.tile_shapes[tile_index] = shape
		match typeof(subst):
			TYPE_INT:
				self.tile_substs[tile_index] = subst
			TYPE_STRING:
				self.tile_substs[tile_index] = ChemCraft.subst_name_to_i.get(subst, 0)
			_:
				push_error("Bad subst parameter, int (subst index) or String (subst name) expected.")
				self.tile_substs[tile_index] = 0
		self.is_mesh_accurate = false
	
	func randomize_tiles():
		tile_shapes.fill(TILE_SHAPE.EMPTY)
		for i in range(TCU.TCHUNK_T):
			match randi_range(0, 16):
				0, 1:
					tile_shapes[i] = TILE_SHAPE.MARCH_ANG
				2:
					tile_shapes[i] = TILE_SHAPE.TESS_CUBE
				3:
					tile_shapes[i] = TILE_SHAPE.TESS_RHOMBDO
				_:
					tile_shapes[i] = TILE_SHAPE.EMPTY
	
	func unmesh():
		mesh_instance_node.queue_free()
		mesh_instance_node = MeshInstance3D.new()
		array_mesh = ArrayMesh.new()
	
	func generate_mesh(tc_27: Array[TChunk] = blank_tc27):
		tc_27[13] = self # Set self as center of the 3x3x3 chunks.
		var surf_verts: PackedVector3Array = []
		var surf_norms: PackedVector3Array = []
		var surf_uvs: PackedVector2Array = []
		var surf_colors: PackedColorArray = []
		var surf_texinds_a: PackedByteArray = []
		var surf_texinds_b: PackedByteArray = []
		
		for i in range(TCU.TCHUNK_T):
			match tile_shapes[i]:
				TILE_SHAPE.NO_DATA:
					push_error("Attempted to mesh an unloaded tile shape at chunk: ",
						str(tc_coords), " tile coords: ", t_xyz_from_i(i))
					continue
				TILE_SHAPE.EMPTY:
					mesh_empty(t_xyz_from_i(i), tc_27, 
					surf_verts, surf_norms, surf_uvs, surf_colors, surf_texinds_a, surf_texinds_b)
				TILE_SHAPE.MARCH_ANG:
					mesh_march_ang(t_xyz_from_i(i), tc_27, 
					surf_verts, surf_norms, surf_uvs, surf_colors, surf_texinds_a, surf_texinds_b)
				TILE_SHAPE.TESS_CUBE:
					mesh_tess_cube(t_xyz_from_i(i), tc_27, 
					surf_verts, surf_norms, surf_uvs, surf_colors, surf_texinds_a, surf_texinds_b)
				TILE_SHAPE.TESS_RHOMBDO:
					mesh_tess_rhombdo(t_xyz_from_i(i), tc_27, 
					surf_verts, surf_norms, surf_uvs, surf_colors, surf_texinds_a, surf_texinds_b)
		
		var mesh_surface: Array = []
		mesh_surface.resize(Mesh.ARRAY_MAX)
		mesh_surface[Mesh.ARRAY_VERTEX] = surf_verts
		mesh_surface[Mesh.ARRAY_NORMAL] = surf_norms
		mesh_surface[Mesh.ARRAY_TEX_UV] = surf_uvs
		mesh_surface[Mesh.ARRAY_COLOR] = surf_colors
		mesh_surface[Mesh.ARRAY_CUSTOM0] = surf_texinds_a
		mesh_surface[Mesh.ARRAY_CUSTOM1] = surf_texinds_b
		
		var shader_material: ShaderMaterial = load("res://assets/substance_assets/subst_mat.tres")
		#shader_material.vertex_color_use_as_albedo = true
		shader_material.set_shader_parameter("albedos_textures", ChemCraft.albedos_texarray)
		shader_material.set_shader_parameter("normals_textures", ChemCraft.normals_texarray)
		shader_material.set_shader_parameter("specials_textures", ChemCraft.specials_texarray)
		
		var format = (
			Mesh.ARRAY_CUSTOM0 | Mesh.ARRAY_CUSTOM_RGBA8_UNORM |
			Mesh.ARRAY_CUSTOM1 | Mesh.ARRAY_CUSTOM_RGBA8_UNORM
		)
		
		if not surf_verts.is_empty():
			array_mesh.add_surface_from_arrays(
				Mesh.PRIMITIVE_TRIANGLES, 
				mesh_surface,
				[],
				{},
				format,)
			array_mesh.surface_set_material(0, shader_material)
		
		mesh_instance_node.mesh = array_mesh
	
	func mesh_empty(
		pos: Vector3i, tc_27: Array[TChunk], 
		verts_ref: PackedVector3Array, norms_ref: PackedVector3Array,
		uvs_ref: PackedVector2Array, colors_ref: PackedColorArray,
		texinds_a_ref: PackedByteArray, texinds_b_ref: PackedByteArray, 
	):
		# Check for and conditionally attempt to mesh marching cube sections.
		var neighbor_shapes: PackedByteArray = []
		neighbor_shapes.resize(6)
		for i in range(6):
			neighbor_shapes[i] = (
				tc_27[get_tc27_tchunk_i(pos, TCU.ts_tess_cube_move[i])
				].tile_shapes[get_tc27_tile_i(pos,TCU.ts_tess_cube_move[i])])
		for i in range(8):
			if ((neighbor_shapes[i%2] == TILE_SHAPE.MARCH_ANG) or
				(neighbor_shapes[((i/2)%2)+2] == TILE_SHAPE.MARCH_ANG) or
				(neighbor_shapes[((i/4)%2)+4] == TILE_SHAPE.MARCH_ANG)
			):
				mesh_march_ang_sect(pos, i, tc_27, 
			verts_ref, norms_ref, uvs_ref, colors_ref, texinds_a_ref, texinds_b_ref)
	
	func mesh_march_ang(
		pos: Vector3i, tc_27: Array[TChunk], 
		verts_ref: PackedVector3Array, norms_ref: PackedVector3Array,
		uvs_ref: PackedVector2Array, colors_ref: PackedColorArray,
		texinds_a_ref: PackedByteArray, texinds_b_ref: PackedByteArray, 
	):
		for section in range(8):
			mesh_march_ang_sect(pos, section, tc_27, 
			verts_ref, norms_ref, uvs_ref, colors_ref, texinds_a_ref, texinds_b_ref)
	
	func mesh_march_ang_sect(
		pos: Vector3i, sect: int, tc_27: Array[TChunk], 
		verts_ref: PackedVector3Array, norms_ref: PackedVector3Array,
		uvs_ref: PackedVector2Array, colors_ref: PackedColorArray,
		texinds_a_ref: PackedByteArray, texinds_b_ref: PackedByteArray, 
	):
		var comb: int = 0b00000000
		var move: Vector3i = Vector3i()
		for state_i in range(8):
			move = Vector3i(((sect%2)-1)+(state_i%2), 
				(((sect/2)%2)-1)+((state_i/2)%2), 
				(((sect/4)%2)-1)+((state_i/4)%2))
			comb |= int( # cast false/true to 0/1
				tc_27[get_tc27_tchunk_i(pos, move)
				].tile_shapes[get_tc27_tile_i(pos, move)] > TILE_SHAPE.EMPTY # "is solid?"
				) << state_i # bitshift
		for i in range(TCU.ts_march_ang_inds[comb][7-sect].size()):
			verts_ref.append(TCU.ts_march_ang_patt_verts[TCU.ts_march_ang_inds[comb][7-sect][i]]
				+ Vector3(sect%2,(sect/2)%2,(sect/4)%2) + (Vector3(pos) - TCU.TCHUNK_HS))
			if i%3 == 0:
				norms_ref.append(TCU.triangle_normal_vector(PackedVector3Array([
					TCU.ts_march_ang_patt_verts[TCU.ts_march_ang_inds[comb][7-sect][i]], 
					TCU.ts_march_ang_patt_verts[TCU.ts_march_ang_inds[comb][7-sect][i+1]], 
					TCU.ts_march_ang_patt_verts[TCU.ts_march_ang_inds[comb][7-sect][i+2]], 
				])))
				norms_ref.append(norms_ref[norms_ref.size() - 1])
				norms_ref.append(norms_ref[norms_ref.size() - 2])
				uvs_ref.append_array([Vector2(0,0), Vector2(1,0), Vector2(0,1)])
				mesh_append_substance_data(tc_27[13].tile_substs[t_i_from_xyz(pos)], 3,
					colors_ref, texinds_a_ref, texinds_b_ref)
	
	func mesh_tess_cube(
		pos: Vector3i, tc_27: Array[TChunk], 
		verts_ref: PackedVector3Array, norms_ref: PackedVector3Array,
		uvs_ref: PackedVector2Array, colors_ref: PackedColorArray,
		texinds_a_ref: PackedByteArray, texinds_b_ref: PackedByteArray, 
	):
		for j: int in range(6):
			match tc_27[get_tc27_tchunk_i(pos, TCU.ts_tess_cube_move[j])
			].tile_shapes[get_tc27_tile_i(pos, TCU.ts_tess_cube_move[j])
			]:
				TILE_SHAPE.NO_DATA, TILE_SHAPE.EMPTY: pass
				TILE_SHAPE.MARCH_ANG:
					# if {known that the cube would be covered} then 'continue' else pass to face meshing
					pass
				TILE_SHAPE.TESS_CUBE, TILE_SHAPE.TESS_RHOMBDO, _: continue
			verts_ref.append_array([
				TCU.ts_tess_cube_verts[(4*j)+0] + Vector3(pos), TCU.ts_tess_cube_verts[(4*j)+1] + Vector3(pos),
				TCU.ts_tess_cube_verts[(4*j)+2] + Vector3(pos), TCU.ts_tess_cube_verts[(4*j)+1] + Vector3(pos),
				TCU.ts_tess_cube_verts[(4*j)+3] + Vector3(pos), TCU.ts_tess_cube_verts[(4*j)+2] + Vector3(pos),])
			norms_ref.append_array([
				Vector3(TCU.ts_tess_cube_move[j]), Vector3(TCU.ts_tess_cube_move[j]),
				Vector3(TCU.ts_tess_cube_move[j]), Vector3(TCU.ts_tess_cube_move[j]),
				Vector3(TCU.ts_tess_cube_move[j]), Vector3(TCU.ts_tess_cube_move[j]),])
			uvs_ref.append_array([Vector2(0,1), Vector2(0,0), Vector2(1,1),
				Vector2(0,0), Vector2(1,0), Vector2(1,1)])
			mesh_append_substance_data(tc_27[13].tile_substs[t_i_from_xyz(pos)], 6,
				colors_ref, texinds_a_ref, texinds_b_ref)
	
	func mesh_tess_rhombdo(
		pos: Vector3i, tc_27: Array[TChunk], 
		verts_ref: PackedVector3Array, norms_ref: PackedVector3Array,
		uvs_ref: PackedVector2Array, colors_ref: PackedColorArray,
		texinds_a_ref: PackedByteArray, texinds_b_ref: PackedByteArray, 
	):
		var tri_cull_bits: int = 0b11
		for j in range(12): # Check whether whole face should be culled:
			match tc_27[get_tc27_tchunk_i(pos, TCU.ts_tess_rhombdo_move[j])
			].tile_shapes[get_tc27_tile_i(pos, TCU.ts_tess_rhombdo_move[j])
			]:
				TILE_SHAPE.TESS_RHOMBDO:
					continue
			tri_cull_bits = 0b11 # Individually check whether the 2 face-triangles should be culled:
			for k in range(2):
				if tc_27[get_tc27_tchunk_i(pos, TCU.ts_tess_rhombdo_move[(2 * j) + k + 12])
				].tile_shapes[get_tc27_tile_i(pos, TCU.ts_tess_rhombdo_move[(2 * j) + k + 12])
				] in PackedInt32Array([TILE_SHAPE.TESS_CUBE, TILE_SHAPE.TESS_RHOMBDO]):
					tri_cull_bits -= 0b01 << k
			match tri_cull_bits:
				0b00:
					continue
				0b01:
					verts_ref.append_array([
						Vector3(pos) + TCU.ts_tess_rhombdo_verts[(j * 4)],
						Vector3(pos) + TCU.ts_tess_rhombdo_verts[(j * 4) + 1],
						Vector3(pos) + TCU.ts_tess_rhombdo_verts[(j * 4) + 2],])
					uvs_ref.append_array([Vector2(0,0), Vector2(1,0), Vector2(0,1)])
				0b10:
					verts_ref.append_array([
						Vector3(pos) + TCU.ts_tess_rhombdo_verts[(j * 4) + 1],
						Vector3(pos) + TCU.ts_tess_rhombdo_verts[(j * 4) + 3],
						Vector3(pos) + TCU.ts_tess_rhombdo_verts[(j * 4) + 2],])
					uvs_ref.append_array([Vector2(1,0), Vector2(1,1), Vector2(0,1)])
				0b11:
					verts_ref.append_array([
						Vector3(pos) + TCU.ts_tess_rhombdo_verts[(j * 4)],
						Vector3(pos) + TCU.ts_tess_rhombdo_verts[(j * 4) + 1],
						Vector3(pos) + TCU.ts_tess_rhombdo_verts[(j * 4) + 2],
						Vector3(pos) + TCU.ts_tess_rhombdo_verts[(j * 4) + 1],
						Vector3(pos) + TCU.ts_tess_rhombdo_verts[(j * 4) + 3],
						Vector3(pos) + TCU.ts_tess_rhombdo_verts[(j * 4) + 2],])
					uvs_ref.append_array([Vector2(0,0), Vector2(1,0), Vector2(0,1),
						Vector2(1,0), Vector2(1,1), Vector2(0,1)])
			match tri_cull_bits:
				0b01, 0b10:
					norms_ref.append_array([
						TCU.ts_tess_rhombdo_norms[j], TCU.ts_tess_rhombdo_norms[j],
						TCU.ts_tess_rhombdo_norms[j],])
					mesh_append_substance_data(tc_27[13].tile_substs[t_i_from_xyz(pos)], 3,
						colors_ref, texinds_a_ref, texinds_b_ref)
				0b11:
					norms_ref.append_array([
						TCU.ts_tess_rhombdo_norms[j], TCU.ts_tess_rhombdo_norms[j],
						TCU.ts_tess_rhombdo_norms[j], TCU.ts_tess_rhombdo_norms[j],
						TCU.ts_tess_rhombdo_norms[j], TCU.ts_tess_rhombdo_norms[j],])
					mesh_append_substance_data(tc_27[13].tile_substs[t_i_from_xyz(pos)], 6,
						colors_ref, texinds_a_ref, texinds_b_ref)
	
	func mesh_append_substance_data(
		subst_ind: int, num_of_verts_with_same_data: int,
		colors_ref: PackedColorArray,
		texinds_a_ref: PackedByteArray, texinds_b_ref: PackedByteArray,
	):
		colors_ref.append(ChemCraft.SUBSTANCES[subst_ind].vert_color)
		texinds_a_ref.append((ChemCraft.SUBSTANCES[subst_ind].albedo_ind & 0b111111110000000000000000) >> 16)
		texinds_a_ref.append((ChemCraft.SUBSTANCES[subst_ind].albedo_ind & 0b000000001111111100000000) >> 8)
		texinds_a_ref.append(ChemCraft.SUBSTANCES[subst_ind].albedo_ind & 0b000000000000000011111111)
		texinds_b_ref.append((ChemCraft.SUBSTANCES[subst_ind].normal_ind & 0b111111110000000000000000) >> 16)
		texinds_b_ref.append((ChemCraft.SUBSTANCES[subst_ind].normal_ind & 0b000000001111111100000000) >> 8)
		texinds_b_ref.append(ChemCraft.SUBSTANCES[subst_ind].normal_ind & 0b000000000000000011111111)
		texinds_a_ref.append((ChemCraft.SUBSTANCES[subst_ind].special_ind & 0b000000001111111100000000) >> 8)
		texinds_b_ref.append(ChemCraft.SUBSTANCES[subst_ind].special_ind & 0b000000000000000011111111)
		
		# Copy the data for each additional vertex which needs to use the same data:
		for i in range(0, num_of_verts_with_same_data - 1, 1):
			colors_ref.append(colors_ref[colors_ref.size() - 1])
			texinds_a_ref.append_array([
				texinds_a_ref[texinds_a_ref.size() - 4], texinds_a_ref[texinds_a_ref.size() - 3],
				texinds_a_ref[texinds_a_ref.size() - 2], texinds_a_ref[texinds_a_ref.size() - 1]])
			texinds_b_ref.append_array([
				texinds_b_ref[texinds_b_ref.size() - 4], texinds_b_ref[texinds_b_ref.size() - 3],
				texinds_b_ref[texinds_b_ref.size() - 2], texinds_b_ref[texinds_b_ref.size() - 1]])

func _init():
	TChunk.blank_tc27.resize(27)
	TChunk.blank_tc27.fill(TChunk.new())

func _ready():
	var test_chunk: TChunk = TChunk.new()
	test_chunk.tile_shapes.fill(TILE_SHAPE.EMPTY)
	test_chunk.tile_substs.fill(ChemCraft.subst_name_to_i.get("nothing", 0))
	#test_chunk.randomize_tiles()
	
	test_chunk.set_tile(Vector3i(0,0,0), TILE_SHAPE.TESS_CUBE, "plainite_black")
	test_chunk.set_tile(Vector3i(0,1,0), TILE_SHAPE.TESS_RHOMBDO, "test")
	test_chunk.set_tile(Vector3i(0,2,0), TILE_SHAPE.TESS_CUBE, "plainite_white")
	test_chunk.set_tile(Vector3i(2,1,0), TILE_SHAPE.TESS_RHOMBDO, "error")
	
	test_chunk.generate_mesh()
	add_child(test_chunk.mesh_instance_node)
	
	#generate_test_mesh()

func generate_test_mesh():
	var mesh_instance_node: MeshInstance3D = MeshInstance3D.new()
	var array_mesh: ArrayMesh = ArrayMesh.new()
	
	var mesh_surface: Array = []
	mesh_surface.resize(Mesh.ARRAY_MAX)
	mesh_surface[Mesh.ARRAY_VERTEX] = PackedVector3Array([
		Vector3(-16,0,16), Vector3(-16,0,-16), Vector3(16,0,16),
		Vector3(16,0,-16), Vector3(16,0,16), Vector3(-16,0,-16),
	])
	mesh_surface[Mesh.ARRAY_NORMAL] = PackedVector3Array([
		Vector3(0,1,0), Vector3(0,1,0), Vector3(0,1,0), 
		Vector3(0,1,0), Vector3(0,1,0), Vector3(0,1,0), 
	])
	mesh_surface[Mesh.ARRAY_COLOR] = PackedColorArray([
		Color.BLUE, Color.BLUE, Color.BLUE, 
		Color.YELLOW, Color.YELLOW, Color.YELLOW, 
	])
	mesh_surface[Mesh.ARRAY_TEX_UV] = PackedVector2Array([
		Vector2(0,1), Vector2(0,0), Vector2(1,1), 
		Vector2(1,0), Vector2(1,1), Vector2(0,0), 
	])
	mesh_surface[Mesh.ARRAY_CUSTOM0] = PackedByteArray([
		0b00000000, 0b00000000, 0b00000000, 0b00000000, 
		0b00000000, 0b00000000, 0b00000000, 0b00000000, 
		0b00000000, 0b00000000, 0b00000000, 0b00000000, 
		
		0b00000000, 0b00000000, 0b00000000, 0b00000000, 
		0b00000000, 0b00000000, 0b00000000, 0b00000000, 
		0b00000000, 0b00000000, 0b00000000, 0b00000000, 
	])
	mesh_surface[Mesh.ARRAY_CUSTOM1] = PackedByteArray([
		0b00000000, 0b00000000, 0b00000001, 0b00000000, 
		0b00000000, 0b00000000, 0b00000001, 0b00000000, 
		0b00000000, 0b00000000, 0b00000001, 0b00000000, 
		
		0b00000000, 0b00000000, 0b00000000, 0b00000001, 
		0b00000000, 0b00000000, 0b00000000, 0b00000001, 
		0b00000000, 0b00000000, 0b00000000, 0b00000001, 
	])
	
	var test_mat: ShaderMaterial = load("res://assets/substance_assets/subst_mat.tres")
	test_mat.set_shader_parameter("albedos_textures", ChemCraft.albedos_texarray)
	test_mat.set_shader_parameter("normals_textures", ChemCraft.normals_texarray)
	test_mat.set_shader_parameter("specials_textures", ChemCraft.specials_texarray)
	
	var format = (
		Mesh.ARRAY_CUSTOM0 | Mesh.ARRAY_CUSTOM_RGBA8_UNORM |
		Mesh.ARRAY_CUSTOM1 | Mesh.ARRAY_CUSTOM_RGBA8_UNORM
	)
	
	array_mesh.add_surface_from_arrays(
		Mesh.PRIMITIVE_TRIANGLES, 
		mesh_surface,
		[],
		{},
		format,
	)
	array_mesh.surface_set_material(0, test_mat)
	mesh_instance_node.mesh = array_mesh
	
	add_child(mesh_instance_node)
