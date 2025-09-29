extends Node

@onready var chunks_container_node: Node = self

enum TILE_SHAPE {
	NO_DATA, EMPTY, MARCH_ANG, MARCH_WEI, TESS_CUBE, TESS_RHOMBDO, CLIFF, POWDER, # BUBBLES? LIQUID?
}

class TChunk:
	var coords: Vector3i = Vector3i(0,0,0)
	var gen_seed: int = 0 # (typically the same for all chunks in a world.)
	
	var tiles_shapes: PackedByteArray = []
	var tiles_substs: PackedInt32Array = []
	#!!! structs data, tobjs data, gas/air/atmosphere data?...
	
	#!!! biome and related cached terrain data stuff?
	
	# Whether meshes are accurate to current chunk data, or are due for remeshing:
	var are_tiles_meshes_utd: bool = false
	#var are_structs_meshes_utd: bool = true
	#var are_tobj_meshes_utd: bool = true
	
	#var tiles_body_node: StaticBody3D = StaticBody3D.new()
	#var tiles_coll_shape: ConcavePolygonShape3D = ConcavePolygonShape3D.new()
	var tiles_rend_node: MeshInstance3D = MeshInstance3D.new() #!!! possibly one per shader used later?
	var tiles_rend_arraymesh: ArrayMesh = ArrayMesh.new() #ex. foliage shader, trans' subst shader, etc.
	
	func _init():
		tiles_shapes.resize(TCU.TCHUNK_T)
		tiles_shapes.fill(TILE_SHAPE.NO_DATA)
		tiles_substs.resize(TCU.TCHUNK_T)
		tiles_substs.fill(0)

# Get relative chunk and tile indices from tile position in central chunk + tile movement.
func get_tc27_c_i(init_tile_pos: Vector3i, relative_movement: Vector3i) -> int:
	var new_pos: Vector3i = Vector3i(init_tile_pos + relative_movement)
	var chunk_xyz: Vector3i = Vector3i(
		(new_pos.x/TCU.TCHUNK_L) if (new_pos.x >= 0) else ((new_pos.x-(TCU.TCHUNK_L-1))/TCU.TCHUNK_L),
		(new_pos.y/TCU.TCHUNK_L) if (new_pos.y >= 0) else ((new_pos.y-(TCU.TCHUNK_L-1))/TCU.TCHUNK_L),
		(new_pos.z/TCU.TCHUNK_L) if (new_pos.z >= 0) else ((new_pos.z-(TCU.TCHUNK_L-1))/TCU.TCHUNK_L),
	)
	chunk_xyz += Vector3i(1, 1, 1)
	return chunk_xyz.x + (3 * chunk_xyz.y) + (9 * chunk_xyz.z)
func get_tc27_t_i(init_tile_pos: Vector3i, relative_movement: Vector3i) -> int:
	return (
		posmod(init_tile_pos.x + relative_movement.x, TCU.TCHUNK_L) +
		posmod(init_tile_pos.y + relative_movement.y, TCU.TCHUNK_L) * TCU.TCHUNK_L +
		posmod(init_tile_pos.z + relative_movement.z, TCU.TCHUNK_L) * TCU.TCHUNK_L * TCU.TCHUNK_L
	)

# Swap between tile position (xyz in chunk, (0,0,0) is negatives corner) and index.
func t_i_from_pos(xyz: Vector3i) -> int:
	return xyz.x + (xyz.y * TCU.TCHUNK_L) + (xyz.z * TCU.TCHUNK_L * TCU.TCHUNK_L)
func t_pos_from_i(index: int) -> Vector3i:
	return Vector3i(
		posmod(index, TCU.TCHUNK_L), 
		posmod(index / TCU.TCHUNK_L, TCU.TCHUNK_L), 
		posmod(index / (TCU.TCHUNK_L * TCU.TCHUNK_L), TCU.TCHUNK_L),
	)

func tc_set_tiles_meshes_ood(tchunk_xyz: Vector3i) -> Error:
	if world_tc_xyz_to_i.has(tchunk_xyz):
		world_tchunks[world_tc_xyz_to_i[tchunk_xyz]].are_tiles_meshes_utd = false
		return OK
	else:
		return FAILED

func tc_set_tile(tchunk: TChunk, tile_xyz: Vector3i, tile_shape: int, tile_subst: Variant) -> Error:
	# Update tiles data:
	var tile_i: int = t_i_from_pos(tile_xyz)
	tchunk.tiles_shapes[tile_i] = tile_shape
	match typeof(tile_subst):
		TYPE_INT: 
			tchunk.tiles_substs[tile_i] = tile_subst
		TYPE_STRING:
			tchunk.tiles_substs[tile_i] = ChemCraft.subst_name_to_i.get(tile_subst, 0)
		_:
			push_error("Bad tile_subst param type, expected int (subst index) or String (subst name).")
			tchunk.tiles_substs[tile_i] = 0
	# Update meshes utd bool:
	const THRESH: int = 1 
		# The effective range in tile pos of tile-changing causing meshes to be ood, max is chunk length.
	if not world_tc_xyz_to_i.has(tchunk.coords):
		tchunk.are_tiles_meshes_utd = false
		return OK
	# (A balance between efficiency and code length; it could actually be made more egregious for speed.)
	if tile_xyz.x < THRESH: 
		tc_set_tiles_meshes_ood(tchunk.coords + Vector3i(-1,0,0))
		if tile_xyz.y < THRESH:
			tc_set_tiles_meshes_ood(tchunk.coords + Vector3i(-1,-1,0))
			if tile_xyz.z < THRESH:
				tc_set_tiles_meshes_ood(tchunk.coords + Vector3i(-1,-1,-1))
			if tile_xyz.z > TCU.TCHUNK_L - THRESH: 
				tc_set_tiles_meshes_ood(tchunk.coords + Vector3i(-1,-1,1))
		if tile_xyz.y > TCU.TCHUNK_L - THRESH: 
			tc_set_tiles_meshes_ood(tchunk.coords + Vector3i(-1,1,0))
			if tile_xyz.z < THRESH:
				tc_set_tiles_meshes_ood(tchunk.coords + Vector3i(-1,1,-1))
			if tile_xyz.z > TCU.TCHUNK_L - THRESH: 
				tc_set_tiles_meshes_ood(tchunk.coords + Vector3i(-1,1,1))
	if tile_xyz.x > TCU.TCHUNK_L - THRESH:
		tc_set_tiles_meshes_ood(tchunk.coords + Vector3i(1,0,0))
		if tile_xyz.y < THRESH:
			tc_set_tiles_meshes_ood(tchunk.coords + Vector3i(1,-1,0))
			if tile_xyz.z < THRESH:
				tc_set_tiles_meshes_ood(tchunk.coords + Vector3i(1,-1,-1))
			if tile_xyz.z > TCU.TCHUNK_L - THRESH: 
				tc_set_tiles_meshes_ood(tchunk.coords + Vector3i(1,-1,1))
		if tile_xyz.y > TCU.TCHUNK_L - THRESH: 
			tc_set_tiles_meshes_ood(tchunk.coords + Vector3i(1,1,0))
			if tile_xyz.z < THRESH:
				tc_set_tiles_meshes_ood(tchunk.coords + Vector3i(1,1,-1))
			if tile_xyz.z > TCU.TCHUNK_L - THRESH: 
				tc_set_tiles_meshes_ood(tchunk.coords + Vector3i(1,1,1))
	if tile_xyz.y < THRESH: 
		tc_set_tiles_meshes_ood(tchunk.coords + Vector3i(0,-1,0))
		if tile_xyz.z < THRESH:
			tc_set_tiles_meshes_ood(tchunk.coords + Vector3i(0,-1,-1))
		if tile_xyz.z > TCU.TCHUNK_L - THRESH: 
			tc_set_tiles_meshes_ood(tchunk.coords + Vector3i(0,-1,1))
	if tile_xyz.y > TCU.TCHUNK_L - THRESH:  
		tc_set_tiles_meshes_ood(tchunk.coords + Vector3i(0,1,0))
		if tile_xyz.z < THRESH:
			tc_set_tiles_meshes_ood(tchunk.coords + Vector3i(0,1,-1))
		if tile_xyz.z > TCU.TCHUNK_L - THRESH: 
			tc_set_tiles_meshes_ood(tchunk.coords + Vector3i(0,1,1))
	if tile_xyz.z < THRESH:
		tc_set_tiles_meshes_ood(tchunk.coords + Vector3i(0,0,-1))
	if tile_xyz.z > TCU.TCHUNK_L - THRESH: 
		tc_set_tiles_meshes_ood(tchunk.coords + Vector3i(0,0,1))
	return OK

func tc_fill_tile(tchunk: TChunk, tile_shape: int, tile_subst: Variant) -> Error:
	tchunk.tiles_shapes.fill(tile_shape)
	match typeof(tile_subst):
		TYPE_INT: 
			tchunk.tiles_substs.fill(tile_subst)
		TYPE_STRING:
			tchunk.tiles_substs.fill(ChemCraft.subst_name_to_i.get(tile_subst, 0))
		_:
			push_error("Bad tile_subst param type, expected int (subst index) or String (subst name).")
			tchunk.tiles_substs.fill(0)
	# Update meshes utd bool:
	if world_tc_xyz_to_i.has(tchunk.coords):
		for i in 27:
			tc_set_tiles_meshes_ood(tchunk.coords + Vector3i(((i%3)-1), (((i/3)%3)-1), (((i/9)%3)-1)))
	else:
		tchunk.are_tiles_meshes_utd = false
	return OK

func tc_unmesh(tchunk: TChunk):
	tchunk.tiles_rend_node.queue_free()
	tchunk.tiles_rend_node = MeshInstance3D.new()
	#tchunk.tiles_rend_mesh.queue_free() # (is this needed/useful here?)
	tchunk.tiles_rend_mesh = ArrayMesh.new()
	tchunk.are_tiles_meshes_utd = false

func get_tc27(tchunk_xyz: Vector3i) -> Array[TChunk]:
	var tc27: Array[TChunk] = []
	tc27.resize(27)
	for i in range(27):
		if world_tc_xyz_to_i.has(tchunk_xyz + Vector3i(((i%3)-1), (((i/3)%3)-1), (((i/9)%3)-1))):
			tc27[i] = world_tchunks[world_tc_xyz_to_i[
				tchunk_xyz + Vector3i(((i%3)-1), (((i/3)%3)-1), (((i/9)%3)-1))]]
		else:
			tc27[i] = TChunk.new()
	return tc27

# Mesh stuff is generated using tc27 data, then assigned into tchunk to be used later.
func tc_meshify(tchunk: TChunk, tc27: Array[TChunk] = get_tc27(tchunk.coords)):
	if not tc27.size() == 27:
		push_error("Bad tc27 size, wasn't an array of 27 tchunks."); return;
	
	var surface: Dictionary = {
		"verts": PackedVector3Array(),
		"norms": PackedVector3Array(),
		"uvs": PackedVector2Array(),
		"colors": PackedColorArray(),
		"texinds_a": PackedByteArray(),
		"texinds_b": PackedByteArray(),
	}
	
	for i in range(TCU.TCHUNK_T):
		match tc27[13].tiles_shapes[i]:
			TILE_SHAPE.NO_DATA:
				push_error("Attempted to mesh an unloaded tile shape at chunk: ",
					str(tchunk.coords), " tile coords: ", t_pos_from_i(i))
				continue
			TILE_SHAPE.EMPTY: meshify_tile_empty(t_pos_from_i(i), tc27, surface)
			TILE_SHAPE.MARCH_ANG: meshify_tile_march_ang(t_pos_from_i(i), tc27, surface)
			TILE_SHAPE.TESS_CUBE: meshify_tile_tess_cube(t_pos_from_i(i), tc27, surface)
			TILE_SHAPE.TESS_RHOMBDO: meshify_tile_tess_rhombdo(t_pos_from_i(i), tc27, surface)
	
	var mesh_surface: Array = []
	mesh_surface.resize(Mesh.ARRAY_MAX)
	mesh_surface[Mesh.ARRAY_VERTEX] = surface.verts
	mesh_surface[Mesh.ARRAY_NORMAL] = surface.norms
	mesh_surface[Mesh.ARRAY_TEX_UV] = surface.uvs
	mesh_surface[Mesh.ARRAY_COLOR] = surface.colors
	mesh_surface[Mesh.ARRAY_CUSTOM0] = surface.texinds_a
	mesh_surface[Mesh.ARRAY_CUSTOM1] = surface.texinds_b
	
	var shader_material: ShaderMaterial = load("res://assets/substance_assets/opaq_subst_mat.tres")
	#shader_material.vertex_color_use_as_albedo = true
	shader_material.set_shader_parameter("albedos_textures", ChemCraft.albedos_texarray)
	shader_material.set_shader_parameter("normals_textures", ChemCraft.normals_texarray)
	shader_material.set_shader_parameter("specials_textures", ChemCraft.specials_texarray)
	
	var format = (
		Mesh.ARRAY_CUSTOM0 | Mesh.ARRAY_CUSTOM_RGBA8_UNORM |
		Mesh.ARRAY_CUSTOM1 | Mesh.ARRAY_CUSTOM_RGBA8_UNORM
	)
	
	if not surface.verts.is_empty():
		tchunk.tiles_rend_arraymesh.add_surface_from_arrays(
			Mesh.PRIMITIVE_TRIANGLES, 
			mesh_surface,
			[],
			{},
			format,)
		tchunk.tiles_rend_arraymesh.surface_set_material(0, shader_material)
	
	tchunk.tiles_rend_node.mesh = tchunk.tiles_rend_arraymesh

func meshify_tile_empty(tile_pos: Vector3i, tc27: Array[TChunk], surface_ref: Dictionary):
	# Check for and conditionally attempt to mesh marching cube sections.
	var neighbor_shapes: PackedByteArray = []
	neighbor_shapes.resize(6)
	for neighbor_i in range(6):
		neighbor_shapes[neighbor_i] = (
			tc27[get_tc27_c_i(tile_pos, TCU.ts_tess_cube_move[neighbor_i])
			].tiles_shapes[get_tc27_t_i(tile_pos, TCU.ts_tess_cube_move[neighbor_i])])
	for sect_i in range(8):
		if ((neighbor_shapes[sect_i%2] == TILE_SHAPE.MARCH_ANG) or
			(neighbor_shapes[((sect_i/2)%2)+2] == TILE_SHAPE.MARCH_ANG) or
			(neighbor_shapes[((sect_i/4)%2)+4] == TILE_SHAPE.MARCH_ANG)
		):
			meshify_tile_march_ang_section(tile_pos, sect_i, tc27, surface_ref)

func meshify_tile_march_ang(tile_pos: Vector3i, tc27: Array[TChunk], surface_ref: Dictionary):
	# No neighboring-tile-shapes check necessary, simply mesh all 8 associated marching cubes sections.
	for section_index in range(8):
		meshify_tile_march_ang_section(tile_pos, section_index, tc27, surface_ref)

func meshify_tile_march_ang_section(
	tile_pos: Vector3i, sect: int, tc27: Array[TChunk], surface_ref: Dictionary
):
	var comb: int = 0b00000000
	var move: Vector3i = Vector3i()
	for state_i in range(8):
		move = Vector3i(
			((sect%2)-1)+(state_i%2), 
			(((sect/2)%2)-1)+((state_i/2)%2), 
			(((sect/4)%2)-1)+((state_i/4)%2))
		comb |= int( # cast false/true to 0/1
			tc27[get_tc27_c_i(tile_pos, move)
			].tiles_shapes[get_tc27_t_i(tile_pos, move)] > TILE_SHAPE.EMPTY # "is solid?"
			) << state_i # bitshift
	for i in range(TCU.ts_march_ang_inds[comb][7-sect].size()):
		surface_ref.verts.append(TCU.ts_march_ang_patt_verts[TCU.ts_march_ang_inds[comb][7-sect][i]]
			+ Vector3(sect%2,(sect/2)%2,(sect/4)%2) + (Vector3(tile_pos) - TCU.TCHUNK_HS))
		if i%3 == 0:
			surface_ref.norms.append(TCU.triangle_normal_vector(PackedVector3Array([
				TCU.ts_march_ang_patt_verts[TCU.ts_march_ang_inds[comb][7-sect][i]], 
				TCU.ts_march_ang_patt_verts[TCU.ts_march_ang_inds[comb][7-sect][i+1]], 
				TCU.ts_march_ang_patt_verts[TCU.ts_march_ang_inds[comb][7-sect][i+2]], 
			])))
			surface_ref.norms.append(surface_ref.norms[surface_ref.norms.size() - 1]) # (appends 2 more 
			surface_ref.norms.append(surface_ref.norms[surface_ref.norms.size() - 2]) #  of the same thing.)
			surface_ref.uvs.append_array([Vector2(0,0), Vector2(1,0), Vector2(0,1)])
				# !!! This way of doing uvs for march_ang is temporary and should be replaced later.
			meshify_append_substance_data(tc27[13].tiles_substs[t_i_from_pos(tile_pos)], 3, surface_ref)

func meshify_tile_tess_cube(tile_pos: Vector3i, tc27: Array[TChunk], surface_ref: Dictionary):
	for face_i: int in range(6):
		match tc27[get_tc27_c_i(tile_pos, TCU.ts_tess_cube_move[face_i])
		].tiles_shapes[get_tc27_t_i(tile_pos, TCU.ts_tess_cube_move[face_i])]:
			TILE_SHAPE.TESS_CUBE, TILE_SHAPE.TESS_RHOMBDO: continue # skip meshing if face is covered.
			TILE_SHAPE.NO_DATA, TILE_SHAPE.EMPTY, TILE_SHAPE.MARCH_ANG, _: pass
				# !!! check for cube face-covering from neighboring march_ang tiles later?
		surface_ref.verts.append_array([
			TCU.ts_tess_cube_verts[(4*face_i)+0] + Vector3(tile_pos), 
			TCU.ts_tess_cube_verts[(4*face_i)+1] + Vector3(tile_pos),
			TCU.ts_tess_cube_verts[(4*face_i)+2] + Vector3(tile_pos), 
			TCU.ts_tess_cube_verts[(4*face_i)+1] + Vector3(tile_pos),
			TCU.ts_tess_cube_verts[(4*face_i)+3] + Vector3(tile_pos), 
			TCU.ts_tess_cube_verts[(4*face_i)+2] + Vector3(tile_pos),])
		surface_ref.norms.append_array([
			Vector3(TCU.ts_tess_cube_move[face_i]), 
			Vector3(TCU.ts_tess_cube_move[face_i]),
			Vector3(TCU.ts_tess_cube_move[face_i]), 
			Vector3(TCU.ts_tess_cube_move[face_i]),
			Vector3(TCU.ts_tess_cube_move[face_i]), 
			Vector3(TCU.ts_tess_cube_move[face_i]),])
		surface_ref.uvs.append_array([
			Vector2(0,1), Vector2(0,0), Vector2(1,1),Vector2(0,0), Vector2(1,0), Vector2(1,1)])
		meshify_append_substance_data(tc27[13].tiles_substs[t_i_from_pos(tile_pos)], 6, surface_ref)

func meshify_tile_tess_rhombdo(tile_pos: Vector3i, tc27: Array[TChunk], surface_ref: Dictionary):
	var tri_cull_bits: int = 0b11
	for face_i in range(12):
		# Check whether the whole face should be culled:
		match tc27[get_tc27_c_i(tile_pos, TCU.ts_tess_rhombdo_move[face_i])
		].tiles_shapes[get_tc27_t_i(tile_pos, TCU.ts_tess_rhombdo_move[face_i])]:
			TILE_SHAPE.TESS_RHOMBDO:
				continue
		# Check whether either of the 2 face-triangles should be culled, stored as bits:
		tri_cull_bits = 0b11 
		for tri_i in range(2):
			if tc27[get_tc27_c_i(tile_pos, TCU.ts_tess_rhombdo_move[(2 * face_i) + tri_i + 12])
			].tiles_shapes[get_tc27_t_i(tile_pos, TCU.ts_tess_rhombdo_move[(2 * face_i) + tri_i + 12])
			] in PackedInt32Array([TILE_SHAPE.TESS_CUBE, TILE_SHAPE.TESS_RHOMBDO]):
				tri_cull_bits -= 0b01 << tri_i
		match tri_cull_bits:
			0b00:
				continue
			0b01:
				surface_ref.verts.append_array([
					Vector3(tile_pos) + TCU.ts_tess_rhombdo_verts[(face_i * 4)],
					Vector3(tile_pos) + TCU.ts_tess_rhombdo_verts[(face_i * 4) + 1],
					Vector3(tile_pos) + TCU.ts_tess_rhombdo_verts[(face_i * 4) + 2],])
				surface_ref.uvs.append_array([Vector2(0,0), Vector2(1,0), Vector2(0,1)])
			0b10:
				surface_ref.verts.append_array([
					Vector3(tile_pos) + TCU.ts_tess_rhombdo_verts[(face_i * 4) + 1],
					Vector3(tile_pos) + TCU.ts_tess_rhombdo_verts[(face_i * 4) + 3],
					Vector3(tile_pos) + TCU.ts_tess_rhombdo_verts[(face_i * 4) + 2],])
				surface_ref.uvs.append_array([Vector2(1,0), Vector2(1,1), Vector2(0,1)])
			0b11:
				surface_ref.verts.append_array([
					Vector3(tile_pos) + TCU.ts_tess_rhombdo_verts[(face_i * 4)],
					Vector3(tile_pos) + TCU.ts_tess_rhombdo_verts[(face_i * 4) + 1],
					Vector3(tile_pos) + TCU.ts_tess_rhombdo_verts[(face_i * 4) + 2],
					Vector3(tile_pos) + TCU.ts_tess_rhombdo_verts[(face_i * 4) + 1],
					Vector3(tile_pos) + TCU.ts_tess_rhombdo_verts[(face_i * 4) + 3],
					Vector3(tile_pos) + TCU.ts_tess_rhombdo_verts[(face_i * 4) + 2],])
				surface_ref.uvs.append_array([Vector2(0,0), Vector2(1,0), Vector2(0,1),
					Vector2(1,0), Vector2(1,1), Vector2(0,1)])
		match tri_cull_bits:
			0b01, 0b10:
				surface_ref.norms.append_array([
					TCU.ts_tess_rhombdo_norms[face_i], TCU.ts_tess_rhombdo_norms[face_i],
					TCU.ts_tess_rhombdo_norms[face_i],])
				meshify_append_substance_data(tc27[13].tiles_substs[t_i_from_pos(tile_pos)], 3, surface_ref)
			0b11:
				surface_ref.norms.append_array([
					TCU.ts_tess_rhombdo_norms[face_i], TCU.ts_tess_rhombdo_norms[face_i],
					TCU.ts_tess_rhombdo_norms[face_i], TCU.ts_tess_rhombdo_norms[face_i],
					TCU.ts_tess_rhombdo_norms[face_i], TCU.ts_tess_rhombdo_norms[face_i],])
				meshify_append_substance_data(tc27[13].tiles_substs[t_i_from_pos(tile_pos)], 6, surface_ref)

func meshify_append_substance_data(
	subst_ind: int, num_verts_with_shared_subst: int,
	surface_ref: Dictionary,
	#surface_ref.colors: PackedColorArray,
	#surface_ref.texinds_a: PackedByteArray, surface_ref.texinds_b: PackedByteArray,
):
	surface_ref.colors.append(ChemCraft.SUBSTANCES[subst_ind].vert_color)
	surface_ref.texinds_a.append((ChemCraft.SUBSTANCES[subst_ind].albedo_ind & 0b111111110000000000000000)>>16)
	surface_ref.texinds_a.append((ChemCraft.SUBSTANCES[subst_ind].albedo_ind & 0b000000001111111100000000)>>8)
	surface_ref.texinds_a.append(ChemCraft.SUBSTANCES[subst_ind].albedo_ind & 0b000000000000000011111111)
	surface_ref.texinds_b.append((ChemCraft.SUBSTANCES[subst_ind].normal_ind & 0b111111110000000000000000)>>16)
	surface_ref.texinds_b.append((ChemCraft.SUBSTANCES[subst_ind].normal_ind & 0b000000001111111100000000)>>8)
	surface_ref.texinds_b.append(ChemCraft.SUBSTANCES[subst_ind].normal_ind & 0b000000000000000011111111)
	surface_ref.texinds_a.append((ChemCraft.SUBSTANCES[subst_ind].special_ind & 0b000000001111111100000000)>>8)
	surface_ref.texinds_b.append(ChemCraft.SUBSTANCES[subst_ind].special_ind & 0b000000000000000011111111)
	
	# Duplicate the determined data for each similar vertex, to avoid having to recalculate everything:
	for i in range(0, num_verts_with_shared_subst - 1, 1):
		surface_ref.colors.append(surface_ref.colors[surface_ref.colors.size() - 1])
		surface_ref.texinds_a.append_array([
			surface_ref.texinds_a[surface_ref.texinds_a.size() - 4], 
			surface_ref.texinds_a[surface_ref.texinds_a.size() - 3],
			surface_ref.texinds_a[surface_ref.texinds_a.size() - 2], 
			surface_ref.texinds_a[surface_ref.texinds_a.size() - 1]])
		surface_ref.texinds_b.append_array([
			surface_ref.texinds_b[surface_ref.texinds_b.size() - 4], 
			surface_ref.texinds_b[surface_ref.texinds_b.size() - 3],
			surface_ref.texinds_b[surface_ref.texinds_b.size() - 2], 
			surface_ref.texinds_b[surface_ref.texinds_b.size() - 1]])

func tc_generate(tchunk: TChunk):
	tc_fill_tile(tchunk, TILE_SHAPE.EMPTY, "nothing")
	
	tc_set_tile(tchunk, Vector3i(0,0,0), TILE_SHAPE.MARCH_ANG, "plainite_white")
	
	# Update meshes utd bool:
	if world_tc_xyz_to_i.has(tchunk.coords):
		for i in 27:
			tc_set_tiles_meshes_ood(Vector3i(((i%3)-1), (((i/3)%3)-1), (((i/9)%3)-1)))
	else:
		tchunk.are_tiles_meshes_utd = false

# All currently loaded world terrain chunks.
var world_tchunks: Array[TChunk] = []
var world_tc_xyz_to_i: Dictionary[Vector3i, int] = {}

func xyz_to_name(xyz: Vector3i) -> String:
	return str(xyz.x) + "_" + str(xyz.y) + "_" + str(xyz.z)

func name_to_xyz(node_name: String) -> Vector3i:
	var split_name: PackedStringArray = node_name.split("_", true, 3)
	if split_name.size() >= 3:
		return Vector3i(int(split_name[0]), int(split_name[1]), int(split_name[2]))
	else:
		return Vector3i(0,0,0)

func refresh_world_tc_xyz_to_i():
	world_tc_xyz_to_i.clear()
	for i in range(world_tchunks.size()):
		world_tc_xyz_to_i[world_tchunks[i].coords] = i
	if not world_tc_xyz_to_i.size() == world_tchunks.size():
		push_error("Some world tchunks have duplicate coords, which is unintended behavior.")

func load_tchunk(tchunk_xyz: Vector3i, load_data: bool = true, reload_if_existing: bool = true):
	if world_tc_xyz_to_i.has(tchunk_xyz):
		if reload_if_existing: unload_tchunk(tchunk_xyz)
		else: return
	world_tchunks.append(TChunk.new())
	world_tchunks[-1].coords = tchunk_xyz
	world_tc_xyz_to_i[tchunk_xyz] = world_tchunks.size() - 1
	if load_data:
		# !!! check if chunk is saved in files and load that instead of generating if so.
		tc_generate(world_tchunks[-1])

func unload_tchunk(xyz: Vector3i):
	if not world_tc_xyz_to_i.has(xyz): 
		return
	remove_tchunk_mesh_node(xyz)
	world_tchunks.remove_at(world_tc_xyz_to_i[xyz])
	world_tc_xyz_to_i.erase(xyz)

func remesh_tchunk(xyz: Vector3i):
	if not world_tc_xyz_to_i.has(xyz):
		return
	tc_meshify(world_tchunks[world_tc_xyz_to_i[xyz]])
	if not world_tchunks[world_tc_xyz_to_i[xyz]].tiles_rend_node.name == xyz_to_name(xyz) + "_tiles_rend_mesh":
		add_tchunk_mesh_node(xyz)

func add_tchunk_mesh_node(xyz: Vector3i):
	if not world_tc_xyz_to_i.has(xyz):
		return
	if world_tchunks[world_tc_xyz_to_i[xyz]].tiles_rend_node == null:
		return
	chunks_container_node.add_child(world_tchunks[world_tc_xyz_to_i[xyz]].tiles_rend_node)
	world_tchunks[world_tc_xyz_to_i[xyz]].tiles_rend_node.position = Vector3(xyz * 16)
	world_tchunks[world_tc_xyz_to_i[xyz]].tiles_rend_node.name = xyz_to_name(xyz) + "_tiles_rend_mesh"

func remove_tchunk_mesh_node(xyz: Vector3i):
	if not world_tc_xyz_to_i.has(xyz):
		return
	if world_tchunks[world_tc_xyz_to_i[xyz]].tiles_rend_node == null:
		return
	world_tchunks[world_tc_xyz_to_i[xyz]].tiles_rend_node.queue_free()



func _ready():
	var start_a = Time.get_ticks_msec()
	for i in 5**3:
		load_tchunk(Vector3i(((i%5)-2), (((i/5)%5)-2), (((i/25)%5)-2)))
	var start_b = Time.get_ticks_msec()
	for i in 5**3:
		remesh_tchunk(Vector3i(((i%5)-2), (((i/5)%5)-2), (((i/25)%5)-2)))
	print(start_b - start_a)
	print(Time.get_ticks_msec() - start_b)
	
	
	#tc_fill_tile(Vector3i(0,0,0), TILE_SHAPE.EMPTY, "nothing")
	#tc_set_tile(Vector3i(0,0,0), Vector3i(0,0,0), TILE_SHAPE.TESS_CUBE, "plainite_black")
	#tc_set_tile(Vector3i(0,0,0), Vector3i(0,1,0), TILE_SHAPE.TESS_RHOMBDO, "test")
	#tc_set_tile(Vector3i(0,0,0), Vector3i(0,2,0), TILE_SHAPE.TESS_CUBE, "plainite_white")
	#tc_set_tile(Vector3i(0,0,0), Vector3i(2,1,0), TILE_SHAPE.TESS_RHOMBDO, "error")
	
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
	
	var test_mat: ShaderMaterial = load("res://assets/substance_assets/opaq_subst_mat.tres")
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
