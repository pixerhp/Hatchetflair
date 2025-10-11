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

func tc_set_tiles(
	tchunk: TChunk, t_inds: PackedInt32Array, t_shapes: PackedByteArray, t_substs: PackedInt32Array,
	do_neighbor_tc_utd_checks: bool = true,
):
	if t_inds.is_empty():
		return
	if (not t_inds.size() == t_shapes.size()) or (not t_inds.size() == t_substs.size()):
		push_error("Argument arrays are of different lengths: ",
			t_inds.size(), " ", t_shapes.size(), " ", t_substs.size())
		return
	
	if not world_tchunks.has(tchunk.coords):
		for i: int in range(t_inds.size()):
			tchunk.tiles_shapes[t_inds[i]] = t_shapes[i]
			tchunk.tiles_substs[t_inds[i]] = t_substs[i]
		tchunk.are_tiles_meshes_utd = false
		return
	
	const THRESH: int = 1
	var set_tile_borders_tc_bits: int = 0b000000000_000010000_000000000
	var pos: Vector3i = Vector3i()
	for i: int in range(t_inds.size()):
		tchunk.tiles_shapes[t_inds[i]] = t_shapes[i]
		tchunk.tiles_substs[t_inds[i]] = t_substs[i]
		
		if not do_neighbor_tc_utd_checks:
			continue
		pos = Vector3i(
			i%TCU.TCHUNK_L, 
			(i/TCU.TCHUNK_L)%TCU.TCHUNK_L, 
			(i/(TCU.TCHUNK_L*TCU.TCHUNK_L))%TCU.TCHUNK_L,)
		set_tile_borders_tc_bits |= int(
			((0b1 << 0) if ((pos.x<THRESH)and(pos.y<THRESH)and(pos.z<THRESH)) else 0) | 
			((0b1 << 1) if ((pos.y<THRESH)and(pos.z<THRESH)) else 0) |
			((0b1 << 2) if ((pos.x>(TCU.TCHUNK_L-THRESH))and(pos.y<THRESH)and(pos.z<THRESH)) else 0) |
			((0b1 << 3) if ((pos.x<THRESH)and(pos.z<THRESH)) else 0) |
			((0b1 << 4) if ((pos.z<THRESH)) else 0) |
			((0b1 << 5) if ((pos.x>(TCU.TCHUNK_L-THRESH))and(pos.z<THRESH)) else 0) |
			((0b1 << 6) if ((pos.x<THRESH)and(pos.y>(TCU.TCHUNK_L-THRESH))and(pos.z<THRESH)) else 0) | 
			((0b1 << 7) if ((pos.y>(TCU.TCHUNK_L-THRESH))and(pos.z<THRESH)) else 0) | 
			((0b1 << 8) if ((pos.x>(TCU.TCHUNK_L-THRESH))and(pos.y>(TCU.TCHUNK_L-THRESH))and(pos.z<THRESH)) else 0) | 
			((0b1 << 9) if ((pos.x<THRESH)and(pos.y<THRESH)) else 0) | 
			((0b1 << 10) if ((pos.y<THRESH)) else 0) |
			((0b1 << 11) if ((pos.x>(TCU.TCHUNK_L-THRESH))and(pos.y<THRESH)) else 0) |
			((0b1 << 12) if ((pos.x<THRESH)) else 0) |
			# (13, the central chunk, is already accounted for with variable initialization)
			((0b1 << 14) if ((pos.x>(TCU.TCHUNK_L-THRESH))) else 0) |
			((0b1 << 15) if ((pos.x<THRESH)and(pos.y>(TCU.TCHUNK_L-THRESH))) else 0) | 
			((0b1 << 16) if ((pos.y>(TCU.TCHUNK_L-THRESH))) else 0) | 
			((0b1 << 17) if ((pos.x>(TCU.TCHUNK_L-THRESH))and(pos.y>(TCU.TCHUNK_L-THRESH))) else 0) | 
			((0b1 << 18) if ((pos.x<THRESH)and(pos.y<THRESH)and(pos.z>(TCU.TCHUNK_L-THRESH))) else 0) | 
			((0b1 << 19) if ((pos.y<THRESH)and(pos.z>(TCU.TCHUNK_L-THRESH))) else 0) |
			((0b1 << 20) if ((pos.x>(TCU.TCHUNK_L-THRESH))and(pos.y<THRESH)and(pos.z>(TCU.TCHUNK_L-THRESH))) else 0) |
			((0b1 << 21) if ((pos.x<THRESH)and(pos.z>(TCU.TCHUNK_L-THRESH))) else 0) |
			((0b1 << 22) if ((pos.z>(TCU.TCHUNK_L-THRESH))) else 0) |
			((0b1 << 23) if ((pos.x>(TCU.TCHUNK_L-THRESH))and(pos.z>(TCU.TCHUNK_L-THRESH))) else 0) |
			((0b1 << 24) if ((pos.x<THRESH)and(pos.y>(TCU.TCHUNK_L-THRESH))and(pos.z>(TCU.TCHUNK_L-THRESH))) else 0) | 
			((0b1 << 25) if ((pos.y>(TCU.TCHUNK_L-THRESH))and(pos.z>(TCU.TCHUNK_L-THRESH))) else 0) | 
			((0b1 << 26) if ((pos.x>(TCU.TCHUNK_L-THRESH))and(pos.y>(TCU.TCHUNK_L-THRESH))and(pos.z>(TCU.TCHUNK_L-THRESH))) else 0)
		)
	var tc_coords: Vector3i = Vector3i()
	for i: int in range(27):
		if (set_tile_borders_tc_bits & (0b1 << i)) == 0:
			continue
		tc_coords = Vector3i(((i%3)-1), (((i/3)%3)-1), (((i/9)%3)-1))
		if world_tchunks.has(tc_coords):
			world_tchunks[tc_coords].are_tiles_meshes_utd = false

func tc_set_tiles_meshes_ood(tc_xyz: Vector3i) -> Error:
	if world_tchunks.has(tc_xyz):
		world_tchunks[tc_xyz].are_tiles_meshes_utd = false
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
	if not world_tchunks.has(tchunk.coords):
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
	if world_tchunks.has(tchunk.coords):
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

func get_tc27(tc_xyz: Vector3i) -> Array[TChunk]:
	var tc27: Array[TChunk] = []
	tc27.resize(27)
	for i in range(27):
		if world_tchunks.has(tc_xyz + Vector3i(((i%3)-1), (((i/3)%3)-1), (((i/9)%3)-1))):
			tc27[i] = world_tchunks[
				tc_xyz + Vector3i(((i%3)-1), (((i/3)%3)-1), (((i/9)%3)-1))]
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
	
	var tile_shape_indices: Array[PackedInt32Array] = []
	tile_shape_indices.resize(TILE_SHAPE.size())
	for i in range(TCU.TCHUNK_T):
		tile_shape_indices[tc27[13].tiles_shapes[i]].append(i)
		
		# !!! do cull checks here sortof, and then send that culling data into shape meshifys?
		
	
	if not tile_shape_indices[TILE_SHAPE.NO_DATA].is_empty():
		push_error("Found ", tile_shape_indices[TILE_SHAPE.NO_DATA].size(),
		" NO_DATA tiles_shapes while meshifying tchunk ", tchunk.coords)
	if tile_shape_indices[TILE_SHAPE.EMPTY].size() == TCU.TCHUNK_T:
		## !!! "whole chunk is air" optimization potential, revise later
		## note that you still have to march check on corners, edges(?), (and probably not but maybe faces?)
		pass
		#var just_air: int = 1
		#for i in range(27):
			#if i == 13:
				#continue
			#if tc27[i].tiles_shapes.count(TILE_SHAPE.EMPTY) == TCU.TCHUNK_T:
				#just_air += 1
			#else:
				#break
		#
		#if just_air == 27:
			#pass
	
	meshify_tiles_empty(surface, tc27, tile_shape_indices[TILE_SHAPE.EMPTY])
	meshify_march_ang_sections(surface, tc27, tile_shape_indices[TILE_SHAPE.MARCH_ANG])
	meshify_tiles_tess_cube(surface, tc27, tile_shape_indices[TILE_SHAPE.TESS_CUBE])
	meshify_tiles_tess_rhombdo(surface, tc27, tile_shape_indices[TILE_SHAPE.TESS_RHOMBDO])
	
	var mesh_surface: Array = []
	mesh_surface.resize(Mesh.ARRAY_MAX)
	mesh_surface[Mesh.ARRAY_VERTEX] = surface.verts
	mesh_surface[Mesh.ARRAY_NORMAL] = surface.norms
	mesh_surface[Mesh.ARRAY_TEX_UV] = surface.uvs
	mesh_surface[Mesh.ARRAY_COLOR] = surface.colors
	mesh_surface[Mesh.ARRAY_CUSTOM0] = surface.texinds_a
	mesh_surface[Mesh.ARRAY_CUSTOM1] = surface.texinds_b
	
	var shader_material: ShaderMaterial = preload("res://assets/substance_assets/opaq_subst_mat.tres")
	#shader_material.vertex_color_use_as_albedo = true
	shader_material.set_shader_parameter("albedos_textures", ChemCraft.albedos_texarray)
	shader_material.set_shader_parameter("normals_textures", ChemCraft.normals_texarray)
	shader_material.set_shader_parameter("specials_textures", ChemCraft.specials_texarray)
	
	var format = (
		Mesh.ARRAY_CUSTOM0 | Mesh.ARRAY_CUSTOM_RGBA8_UNORM |
		Mesh.ARRAY_CUSTOM1 | Mesh.ARRAY_CUSTOM_RGBA8_UNORM
	)
	
	if not surface.verts.is_empty():
		tchunk.tiles_rend_arraymesh.call_deferred("add_surface_from_arrays", 
			Mesh.PRIMITIVE_TRIANGLES, 
			mesh_surface,
			[],
			{},
			format,)
		tchunk.tiles_rend_arraymesh.call_deferred("surface_set_material", 0, shader_material)
	
	tchunk.tiles_rend_node.call_deferred("set", "mesh", tchunk.tiles_rend_arraymesh)
	tchunk.are_tiles_meshes_utd = true

#func get_tc27_c_i_3x3x3(tile_index: int) -> PackedInt32Array:
	#var result: PackedInt32Array = []
	#result.resize(27)
	#var new_pos: Vector3i = Vector3i()
	#for i in range(27):
		#new_pos = Vector3i(
			#((tile_index % TCU.TCHUNK_L) + ((i % 3) - 1)),
			#(((tile_index / TCU.TCHUNK_L) % TCU.TCHUNK_L) + (((i / 3) % 3) - 1)),
			#(((tile_index / (TCU.TCHUNK_L * TCU.TCHUNK_L)) % TCU.TCHUNK_L) + (((i / 9) % 3) - 1)), )
		#result[i] = (
			#(0 if (new_pos.x < 0) else (1 if (new_pos.x < TCU.TCHUNK_L) else 2)) +
			#(0 if (new_pos.y < 0) else (3 if (new_pos.y < TCU.TCHUNK_L) else 6)) +
			#(0 if (new_pos.z < 0) else (9 if (new_pos.z < TCU.TCHUNK_L) else 18)) )
	#return result
#
#func get_tc27_t_i_3x3x3(tile_index: int) -> PackedInt32Array:
	#var result: PackedInt32Array = []
	#result.resize(27)
	#for i in range(27):
		#result[i] = (
			#posmod((tile_index%TCU.TCHUNK_L)+((i%3)-1), TCU.TCHUNK_L) +
			#posmod(((tile_index/TCU.TCHUNK_L)%TCU.TCHUNK_L)+(((i/3)%3)-1), TCU.TCHUNK_L) +
			#posmod(((tile_index/(TCU.TCHUNK_L*TCU.TCHUNK_L))%TCU.TCHUNK_L)+(((i/9)%3)-1), TCU.TCHUNK_L) )
	#return result


# Calculates movewment-relative tc27 chunk indices in bulk:
func get_tc27_c_i_bulk(tile_indices: PackedInt32Array, movements: Array[Vector3i]) -> PackedInt32Array:
	var result: PackedInt32Array = []
	result.resize(tile_indices.size())
	var new_tile_pos: Vector3i = Vector3i()
	for i in range(tile_indices.size()):
		new_tile_pos = Vector3i(
			tile_indices[i] % TCU.TCHUNK_L,
			(tile_indices[i] / TCU.TCHUNK_L) % TCU.TCHUNK_L,
			(tile_indices[i] / (TCU.TCHUNK_L * TCU.TCHUNK_L)) % TCU.TCHUNK_L,
		) + movements[i]
		result[i] = (
			(0 if (new_tile_pos.x < 0) else (1 if (new_tile_pos.x < TCU.TCHUNK_L) else 2)) +
			(0 if (new_tile_pos.y < 0) else (3 if (new_tile_pos.y < TCU.TCHUNK_L) else 6)) +
			(0 if (new_tile_pos.z < 0) else (9 if (new_tile_pos.z < TCU.TCHUNK_L) else 18)) )
	return result

# Calculates movewment-relative tc27 tile indices in bulk:
func get_tc27_t_i_bulk(tile_indices: PackedInt32Array, movements: Array[Vector3i]) -> PackedInt32Array:
	var result: PackedInt32Array = []
	result.resize(tile_indices.size())
	for i in range(tile_indices.size()):
		result[i] = (
			posmod((tile_indices[i] % TCU.TCHUNK_L) + 
				movements[i].x, TCU.TCHUNK_L) +
			posmod(((tile_indices[i] / TCU.TCHUNK_L) % TCU.TCHUNK_L) + 
				movements[i].y, TCU.TCHUNK_L) * TCU.TCHUNK_L +
			posmod(((tile_indices[i] / (TCU.TCHUNK_L * TCU.TCHUNK_L)) % TCU.TCHUNK_L) + 
				movements[i].z, TCU.TCHUNK_L) * TCU.TCHUNK_L * TCU.TCHUNK_L)
	return result

func meshify_append_substance_data_bulk(
	surface_ref: Dictionary, subst_inds: PackedInt32Array, share_counts: PackedInt32Array = []
):
	if share_counts.is_empty():
		share_counts.resize(subst_inds.size())
		share_counts.fill(1)
	
	var texinds_a_group: PackedByteArray = []
	var texinds_b_group: PackedByteArray = []
	for i in range(subst_inds.size()):
		texinds_a_group.clear()
		texinds_b_group.clear()
		
		texinds_a_group.append((ChemCraft.SUBSTANCES[subst_inds[i]].albedo_ind & 0b111111110000000000000000)>>16)
		texinds_a_group.append((ChemCraft.SUBSTANCES[subst_inds[i]].albedo_ind & 0b000000001111111100000000)>>8)
		texinds_a_group.append(ChemCraft.SUBSTANCES[subst_inds[i]].albedo_ind & 0b000000000000000011111111)
		texinds_b_group.append((ChemCraft.SUBSTANCES[subst_inds[i]].normal_ind & 0b111111110000000000000000)>>16)
		texinds_b_group.append((ChemCraft.SUBSTANCES[subst_inds[i]].normal_ind & 0b000000001111111100000000)>>8)
		texinds_b_group.append(ChemCraft.SUBSTANCES[subst_inds[i]].normal_ind & 0b000000000000000011111111)
		texinds_a_group.append((ChemCraft.SUBSTANCES[subst_inds[i]].special_ind & 0b000000001111111100000000)>>8)
		texinds_b_group.append(ChemCraft.SUBSTANCES[subst_inds[i]].special_ind & 0b000000000000000011111111)
		
		for j in range(share_counts[i]):
			surface_ref.colors.append(ChemCraft.SUBSTANCES[subst_inds[i]].vert_color)
			surface_ref.texinds_a.append_array(texinds_a_group)
			surface_ref.texinds_b.append_array(texinds_b_group)

# (Empty tiles typically don't mesh anything, but situationally might if they neighbor a marching tile.)
func meshify_tiles_empty(surface_ref: Dictionary, tc27: Array[TChunk], tile_indices: PackedInt32Array):
	if tile_indices.is_empty():
		return
	# Precalculate tc27_c_i and tc27_t_i in bulk:
	var rel_pos_inds: PackedInt32Array = []
	var rel_pos_moves: Array[Vector3i] = []
	for direction_i in range(6):
		rel_pos_inds.append_array(tile_indices)
		var moves_partial: Array[Vector3i] = []
		moves_partial.resize(tile_indices.size())
		moves_partial.fill([
			Vector3i(-1,0,0), Vector3i(1,0,0),
			Vector3i(0,-1,0), Vector3i(0,1,0), 
			Vector3i(0,0,-1), Vector3i(0,0,1),
		][direction_i])
		rel_pos_moves.append_array(moves_partial)
	var tc27_c_inds: PackedInt32Array = get_tc27_c_i_bulk(rel_pos_inds, rel_pos_moves)
	var tc27_t_inds: PackedInt32Array = get_tc27_t_i_bulk(rel_pos_inds, rel_pos_moves)
	rel_pos_inds.clear()
	rel_pos_moves.clear()
	
	var ang_sect_tile_indices: PackedInt32Array = []
	var sections_to_mesh_bits: PackedByteArray = []
	
	var neighbor_is_march_bits: int = 0b000000
	for t_ind_i: int in range(tile_indices.size()):
		# Get bitstates for whether each of the 6 neighboring tiles is a march shape:
		neighbor_is_march_bits = 0b000000
		for neighbor_i in range(6):
			neighbor_is_march_bits |= (
				int((tc27[tc27_c_inds[(neighbor_i * tile_indices.size()) + t_ind_i]
				].tiles_shapes[tc27_t_inds[(neighbor_i * tile_indices.size()) + t_ind_i]]
				) == TILE_SHAPE.MARCH_ANG) << neighbor_i
			)
		# (If no neighboring tiles are march shape, then it's known that there'll be no sections to mesh.)
		if neighbor_is_march_bits == 0b000000:
			continue
		# Get bitstates of which sections touch a neighboring marching tile:
		ang_sect_tile_indices.append(tile_indices[t_ind_i])
		sections_to_mesh_bits.append(0b00000000)
		for sect_i in range(8):
			sections_to_mesh_bits[-1] |= int(
				bool(neighbor_is_march_bits & (0b000001 << (sect_i % 2))) or
				bool(neighbor_is_march_bits & (0b000001 << (((sect_i / 2) % 2) + 2))) or
				bool(neighbor_is_march_bits & (0b000001 << (((sect_i / 4) % 2) + 4)))
			) << sect_i
	meshify_march_ang_sections(surface_ref, tc27, ang_sect_tile_indices, sections_to_mesh_bits)

# (Leave sections_bitstates blank if all sections of all indexed tiles are to be meshed.)
func meshify_march_ang_sections(
	surface_ref: Dictionary, tc27: Array[TChunk], 
	tile_indices: PackedInt32Array, sections_bitstates: PackedByteArray = PackedByteArray([])
):
	if tile_indices.is_empty():
		return
	if sections_bitstates.is_empty():
		sections_bitstates.resize(tile_indices.size())
		sections_bitstates.fill(0b11111111)
	
	# Precalculate tc27_c_i and tc27_t_i in bulk:
	var rel_pos_inds: PackedInt32Array = []
	var rel_pos_moves: Array[Vector3i] = []
	for t_ind_i: int in range(tile_indices.size()):
		if sections_bitstates[t_ind_i] == 0b00000000: continue
		for sect_i: int in range(8):
			if (sections_bitstates[t_ind_i] & (0b00000001 << sect_i)) == 0:
				continue
			for state_i: int in range(8):
				rel_pos_inds.append(tile_indices[t_ind_i])
				rel_pos_moves.append(Vector3i(
					((sect_i%2)-1) + (state_i%2), 
					(((sect_i/2)%2)-1) + ((state_i/2)%2), 
					(((sect_i/4)%2)-1) + ((state_i/4)%2)))
	var tc27_c_i: PackedInt32Array = get_tc27_c_i_bulk(rel_pos_inds, rel_pos_moves)
	var tc27_t_i: PackedInt32Array = get_tc27_t_i_bulk(rel_pos_inds, rel_pos_moves)
	rel_pos_inds.clear()
	rel_pos_moves.clear()
	
	# Calculate each section combination and append associated data to the surface_ref:
	var precalc_inds_i: int = 0
	var march_comb: int = 0b00000000
	var subst_inds: PackedInt32Array = []
	var subst_shares: PackedInt32Array = []
	for t_ind_i: int in range(tile_indices.size()):
		if sections_bitstates[t_ind_i] == 0b00000000:
			continue
		for sect_i: int in range(8):
			if (sections_bitstates[t_ind_i] & (0b00000001 << sect_i)) == 0:
				continue
			march_comb = 0b00000000
			for state_i: int in range(8):
				march_comb |= (int(
					tc27[tc27_c_i[precalc_inds_i]].tiles_shapes[tc27_t_i[precalc_inds_i]] 
					> TILE_SHAPE.EMPTY # "is solid?"
				) << state_i)
				precalc_inds_i += 1
			# Now that the section's march combination is known, append meshing data:
			subst_inds.append(tc27[13].tiles_substs[tile_indices[t_ind_i]])
			subst_shares.append(TCU.ts_march_ang_inds[march_comb][7-sect_i].size())
			for vert_i: int in range(TCU.ts_march_ang_inds[march_comb][7-sect_i].size()):
				surface_ref.verts.append(
					TCU.ts_march_ang_patt_verts[TCU.ts_march_ang_inds[march_comb][7-sect_i][vert_i]] +
					Vector3(sect_i%2,(sect_i/2)%2,(sect_i/4)%2) + 
					(Vector3( # (tile position from index)
						t_ind_i % TCU.TCHUNK_L,
						(t_ind_i / TCU.TCHUNK_L) % TCU.TCHUNK_L,
						(t_ind_i / (TCU.TCHUNK_L * TCU.TCHUNK_L)) % TCU.TCHUNK_L,
					) - TCU.TCHUNK_HS))
				if (vert_i % 3) == 0:
					surface_ref.norms.append(TCU.triangle_normal_vector(PackedVector3Array([
						TCU.ts_march_ang_patt_verts[TCU.ts_march_ang_inds[march_comb][7-sect_i][vert_i]], 
						TCU.ts_march_ang_patt_verts[TCU.ts_march_ang_inds[march_comb][7-sect_i][vert_i+1]], 
						TCU.ts_march_ang_patt_verts[TCU.ts_march_ang_inds[march_comb][7-sect_i][vert_i+2]], 
					])))
					surface_ref.norms.append(surface_ref.norms[-1]) 
					surface_ref.norms.append(surface_ref.norms[-2])
					surface_ref.uvs.append_array([Vector2(0,0), Vector2(1,0), Vector2(0,1)]) # !!! TEMP
	meshify_append_substance_data_bulk(surface_ref, subst_inds, subst_shares)

func meshify_tiles_tess_cube(surface_ref: Dictionary, tc27: Array[TChunk], tile_indices: PackedInt32Array):
	if tile_indices.is_empty():
		return
	# Precalculate tc27_c_i and tc27_t_i in bulk:
	var rel_pos_inds: PackedInt32Array = []
	var rel_pos_moves: Array[Vector3i] = []
	for direction_i in range(6):
		rel_pos_inds.append_array(tile_indices)
		var moves_partial: Array[Vector3i] = []
		moves_partial.resize(tile_indices.size())
		moves_partial.fill([
			Vector3i(-1,0,0), Vector3i(1,0,0),
			Vector3i(0,-1,0), Vector3i(0,1,0), 
			Vector3i(0,0,-1), Vector3i(0,0,1),
		][direction_i])
		rel_pos_moves.append_array(moves_partial)
	var tc27_c_inds: PackedInt32Array = get_tc27_c_i_bulk(rel_pos_inds, rel_pos_moves)
	var tc27_t_inds: PackedInt32Array = get_tc27_t_i_bulk(rel_pos_inds, rel_pos_moves)
	rel_pos_inds.clear()
	rel_pos_moves.clear()
	
	var subst_inds: PackedInt32Array = []
	var subst_shares: PackedInt32Array = []
	var subst_shares_in_tile: int = 0
	var tile_pos: Vector3 = Vector3()
	for t_ind_i: int in range(tile_indices.size()):
		subst_shares_in_tile = 0
		for face_i: int in range(6):
			match tc27[tc27_c_inds[t_ind_i + (tile_indices.size() * face_i)] # (Situationally cull face)
			].tiles_shapes[tc27_t_inds[t_ind_i + (tile_indices.size() * face_i)]]:
				TILE_SHAPE.TESS_CUBE, TILE_SHAPE.TESS_RHOMBDO: continue
				TILE_SHAPE.MARCH_ANG: pass # !!! do proper culling check later
			subst_shares_in_tile += 1
			tile_pos = Vector3(Vector3i(
				tile_indices[t_ind_i] % TCU.TCHUNK_L,
				(tile_indices[t_ind_i] / TCU.TCHUNK_L) % TCU.TCHUNK_L,
				(tile_indices[t_ind_i] / (TCU.TCHUNK_L * TCU.TCHUNK_L)) % TCU.TCHUNK_L,))
			surface_ref.verts.append_array([
				TCU.ts_tess_cube_verts[(4*face_i)+0] + tile_pos, 
				TCU.ts_tess_cube_verts[(4*face_i)+1] + tile_pos,
				TCU.ts_tess_cube_verts[(4*face_i)+2] + tile_pos, 
				TCU.ts_tess_cube_verts[(4*face_i)+1] + tile_pos,
				TCU.ts_tess_cube_verts[(4*face_i)+3] + tile_pos, 
				TCU.ts_tess_cube_verts[(4*face_i)+2] + tile_pos,])
			surface_ref.norms.append_array([
				Vector3(TCU.ts_tess_cube_move[face_i]), 
				Vector3(TCU.ts_tess_cube_move[face_i]),
				Vector3(TCU.ts_tess_cube_move[face_i]), 
				Vector3(TCU.ts_tess_cube_move[face_i]),
				Vector3(TCU.ts_tess_cube_move[face_i]), 
				Vector3(TCU.ts_tess_cube_move[face_i]),])
			surface_ref.uvs.append_array([
				Vector2(0,1), Vector2(0,0), Vector2(1,1), 
				Vector2(0,0), Vector2(1,0), Vector2(1,1),])
		if subst_shares_in_tile > 0:
			subst_inds.append(tc27[13].tiles_substs[tile_indices[t_ind_i]])
			subst_shares.append(subst_shares_in_tile * 6)
	meshify_append_substance_data_bulk(surface_ref, subst_inds, subst_shares)

func meshify_tiles_tess_rhombdo(surface_ref: Dictionary, tc27: Array[TChunk], tile_indices: PackedInt32Array):
	if tile_indices.is_empty():
		return
	# Precalculate tc27_c_i and tc27_t_i in bulk:
	var rel_pos_inds: PackedInt32Array = []
	var rel_pos_moves: Array[Vector3i] = []
	for direction_i in range(12):
		rel_pos_inds.append_array(tile_indices)
		var moves_partial: Array[Vector3i] = []
		moves_partial.resize(tile_indices.size())
		moves_partial.fill(TCU.ts_tess_rhombdo_move[direction_i])
		rel_pos_moves.append_array(moves_partial)
	var tc27_c_inds_face: PackedInt32Array = get_tc27_c_i_bulk(rel_pos_inds, rel_pos_moves)
	var tc27_t_inds_face: PackedInt32Array = get_tc27_t_i_bulk(rel_pos_inds, rel_pos_moves)
	rel_pos_inds.clear()
	rel_pos_moves.clear()
	for direction_i in range(24):
		rel_pos_inds.append_array(tile_indices)
		var moves_partial: Array[Vector3i] = []
		moves_partial.resize(tile_indices.size())
		moves_partial.fill(TCU.ts_tess_rhombdo_move[direction_i + 12])
		rel_pos_moves.append_array(moves_partial)
	var tc27_c_inds_tri: PackedInt32Array = get_tc27_c_i_bulk(rel_pos_inds, rel_pos_moves)
	var tc27_t_inds_tri: PackedInt32Array = get_tc27_t_i_bulk(rel_pos_inds, rel_pos_moves)
	rel_pos_inds.clear()
	rel_pos_moves.clear()
	
	var subst_inds: PackedInt32Array = []
	var subst_shares: PackedInt32Array = []
	var subst_shares_in_tile: int = 0
	var tile_pos: Vector3 = Vector3()
	for t_ind_i: int in range(tile_indices.size()):
		subst_shares_in_tile = 0
		for face_i in range(12):
			match tc27[tc27_c_inds_face[t_ind_i + (face_i * tile_indices.size())]
			].tiles_shapes[tc27_t_inds_face[t_ind_i + (face_i * tile_indices.size())]]:
				TILE_SHAPE.TESS_RHOMBDO: continue
			for tri_i in range(2):
				if tc27[tc27_c_inds_tri[t_ind_i + (((face_i*2) + tri_i) * tile_indices.size())]
				].tiles_shapes[tc27_t_inds_tri[t_ind_i + (((face_i*2) + tri_i) * tile_indices.size())]] in (
				PackedByteArray([TILE_SHAPE.TESS_CUBE, TILE_SHAPE.TESS_RHOMBDO])):
					continue
				subst_shares_in_tile += 1
				tile_pos = Vector3(Vector3i(
					tile_indices[t_ind_i] % TCU.TCHUNK_L,
					(tile_indices[t_ind_i] / TCU.TCHUNK_L) % TCU.TCHUNK_L,
					(tile_indices[t_ind_i] / (TCU.TCHUNK_L * TCU.TCHUNK_L)) % TCU.TCHUNK_L,))
				surface_ref.verts.append_array([
					[TCU.ts_tess_rhombdo_verts[(face_i * 4)] + tile_pos,
					TCU.ts_tess_rhombdo_verts[(face_i * 4) + 1] + tile_pos,
					TCU.ts_tess_rhombdo_verts[(face_i * 4) + 2] + tile_pos],
					[TCU.ts_tess_rhombdo_verts[(face_i * 4) + 1] + tile_pos,
					TCU.ts_tess_rhombdo_verts[(face_i * 4) + 3] + tile_pos,
					TCU.ts_tess_rhombdo_verts[(face_i * 4) + 2] + tile_pos],][tri_i])
				surface_ref.uvs.append_array([
					[Vector2(0,0), Vector2(1,0), Vector2(0,1)],
					[Vector2(1,0), Vector2(1,1), Vector2(0,1)],][tri_i])
				surface_ref.norms.append_array([
					TCU.ts_tess_rhombdo_norms[face_i], TCU.ts_tess_rhombdo_norms[face_i],
					TCU.ts_tess_rhombdo_norms[face_i],])
		if subst_shares_in_tile > 0:
			subst_inds.append(tc27[13].tiles_substs[tile_indices[t_ind_i]])
			subst_shares.append(subst_shares_in_tile * 3)
	meshify_append_substance_data_bulk(surface_ref, subst_inds, subst_shares)

func tc_generate(tchunk: TChunk):
	tc_fill_tile(tchunk, TILE_SHAPE.EMPTY, "nothing")
	
	tc_set_tile(tchunk, Vector3i(0,0,0), TILE_SHAPE.MARCH_ANG, "plainite_white")
	tc_set_tile(tchunk, Vector3i(2,0,0), TILE_SHAPE.TESS_CUBE, "plainite_white")
	tc_set_tile(tchunk, Vector3i(4,0,0), TILE_SHAPE.TESS_RHOMBDO, "plainite_white")
	
	# Update meshes utd bool:
	if world_tchunks.has(tchunk.coords):
		for i in 27:
			tc_set_tiles_meshes_ood(Vector3i(((i%3)-1), (((i/3)%3)-1), (((i/9)%3)-1)))
	else:
		tchunk.are_tiles_meshes_utd = false

# All currently loaded world terrain chunks.
var world_tchunks: Dictionary[Vector3i, TChunk] = {}

func xyz_to_name(xyz: Vector3i) -> String:
	return str(xyz.x) + "_" + str(xyz.y) + "_" + str(xyz.z)

func name_to_xyz(node_name: String) -> Vector3i:
	var split_name: PackedStringArray = node_name.split("_", true, 3)
	if split_name.size() >= 3:
		return Vector3i(int(split_name[0]), int(split_name[1]), int(split_name[2]))
	else:
		return Vector3i(0,0,0)

func load_tchunk(tc_xyz: Vector3i, 
	reload_if_existing: bool = true, load_data: bool = true, meshify: bool = true,
):
	if world_tchunks.has(tc_xyz):
		if reload_if_existing: 
			unload_tchunk(tc_xyz)
		else: 
			return
	world_tchunks[tc_xyz] = TChunk.new()
	world_tchunks[tc_xyz].coords = tc_xyz
	if not load_data:
		return
	# !!! check if chunk is saved in files and load that instead of generating if so.
	tc_generate(world_tchunks[tc_xyz])
	if not meshify:
		return
	remesh_tchunk(tc_xyz)

func unload_tchunk(tc_xyz: Vector3i):
	if not world_tchunks.has(tc_xyz): 
		return
	remove_tchunk_mesh_node(tc_xyz)
	world_tchunks.erase(tc_xyz)

func remesh_tchunk(tc_xyz: Vector3i):
	if not world_tchunks.has(tc_xyz):
		return
	tc_meshify(world_tchunks[tc_xyz])
	if not world_tchunks[tc_xyz].tiles_rend_node.name == xyz_to_name(tc_xyz) + "_tiles_rend_mesh":
		add_tchunk_mesh_node(tc_xyz)

func add_tchunk_mesh_node(tc_xyz: Vector3i):
	if not world_tchunks.has(tc_xyz):
		return
	if world_tchunks[tc_xyz].tiles_rend_node == null:
		return
	chunks_container_node.call_deferred("add_child", world_tchunks[tc_xyz].tiles_rend_node)
	world_tchunks[tc_xyz].tiles_rend_node.call_deferred("set", "position", Vector3(tc_xyz * 16))
	world_tchunks[tc_xyz].tiles_rend_node.call_deferred("set", "name", xyz_to_name(tc_xyz)+"_tiles_rend_mesh")

func remove_tchunk_mesh_node(tc_xyz: Vector3i):
	if not world_tchunks.has(tc_xyz):
		return
	if world_tchunks[tc_xyz].tiles_rend_node == null:
		return
	world_tchunks[tc_xyz].tiles_rend_node.call_deferred("queue_free")

func load_tchunks_around(load_tc_xyz: Vector3i, amount: int = 1):
	var load_count: int = 0
	# Prioritize loading the chunk that the player is in:
	if not world_tchunks.has(load_tc_xyz):
		load_tchunk(load_tc_xyz)
		load_count += 1
		if load_count >= amount:
			return
	var nearby_tc_xyzs: Array[Vector3i] = []
	nearby_tc_xyzs.resize(9**3)
	for i: int in range(9**3):
		nearby_tc_xyzs[i] = load_tc_xyz + Vector3i(((i%9)-4), (((i/9)%9)-4), (((i/81)%9)-4))
	nearby_tc_xyzs.sort_custom(load_tchunks_around_sort_method.bind(load_tc_xyz))
	for i in nearby_tc_xyzs.size():
		if not world_tchunks.has(nearby_tc_xyzs[i]):
			load_tchunk(nearby_tc_xyzs[i])
			load_count += 1
			if load_count >= amount:
				return

func load_tchunks_around_sort_method(a: Vector3i, b: Vector3i, t: Vector3i) -> bool:
	return a.distance_squared_to(t) < b.distance_squared_to(t)

func unload_tchunks_around(load_tc_xyz: Vector3i):
	const TC_UNLOAD_DISTANCE: float = 40
	for tc_xyz: Vector3i in world_tchunks.keys():
		if tc_xyz.distance_to(load_tc_xyz) > TC_UNLOAD_DISTANCE:
			unload_tchunk(tc_xyz)


var tcmthread: Thread
var tcmthread_exit: bool = false
@onready var cam_node: Node = get_tree().current_scene.find_child("FlyCam")
var main_tcmt_mutex: Mutex
var cam_pos_main: Vector3 = Vector3(0,0,0)

func _ready():
	main_tcmt_mutex = Mutex.new()
	tcmthread = Thread.new()
	tcmthread.start(tcmthread_func)

func _physics_process(_delta):
	main_tcmt_mutex.lock()
	if not cam_node == null:
		cam_pos_main = cam_node.position
	main_tcmt_mutex.unlock()

func tcmthread_func():
	var load_pos: Vector3 = Vector3(0,0,0)
	var load_tc_xyz: Vector3i = Vector3i(0,0,0)
	
	#for i in 9**3:
		#load_tchunk(Vector3i(((i%9)-4), (((i/9)%9)-4), (((i/81)%9)-4)))
	#for i in 9**3:
		#remesh_tchunk(Vector3i(((i%9)-4), (((i/9)%9)-4), (((i/81)%9)-4)))
	
	while not tcmthread_exit:
		main_tcmt_mutex.unlock()
		
		main_tcmt_mutex.lock()
		load_pos = cam_pos_main
		main_tcmt_mutex.unlock()
		
		load_tc_xyz = Vector3i(floor((load_pos + TCU.TCHUNK_HS) / Vector3(TCU.TCHUNK_S)))
		unload_tchunks_around(load_tc_xyz)
		load_tchunks_around(load_tc_xyz, 8)
		
		main_tcmt_mutex.lock()
	main_tcmt_mutex.unlock()

func _exit_tree():
	main_tcmt_mutex.lock()
	tcmthread_exit = true
	main_tcmt_mutex.unlock()
	tcmthread.wait_to_finish()

func generate_test_mesh():
	var mesh_instance_node: MeshInstance3D = MeshInstance3D.new()
	var array_mesh: ArrayMesh = ArrayMesh.new()
	
	var mesh_surface: Array = []
	mesh_surface.resize(Mesh.ARRAY_MAX)
	mesh_surface[Mesh.ARRAY_VERTEX] = PackedVector3Array([
		Vector3(-16,0,16), Vector3(-16,0,-16), Vector3(16,0,16),
		Vector3(16,0,-16), Vector3(16,0,16), Vector3(-16,0,-16),])
	mesh_surface[Mesh.ARRAY_NORMAL] = PackedVector3Array([
		Vector3(0,1,0), Vector3(0,1,0), Vector3(0,1,0), 
		Vector3(0,1,0), Vector3(0,1,0), Vector3(0,1,0),])
	mesh_surface[Mesh.ARRAY_COLOR] = PackedColorArray([
		Color.CYAN, Color.BLUE, Color.MAGENTA, 
		Color.GREEN, Color.YELLOW, Color.RED,])
	mesh_surface[Mesh.ARRAY_TEX_UV] = PackedVector2Array([
		Vector2(0,1), Vector2(0,0), Vector2(1,1), 
		Vector2(1,0), Vector2(1,1), Vector2(0,0),])
	mesh_surface[Mesh.ARRAY_CUSTOM0] = PackedByteArray([
		0b00000000, 0b00000000, 0b00000000, 0b00000000, 
		0b00000000, 0b00000000, 0b00000000, 0b00000000, 
		0b00000000, 0b00000000, 0b00000000, 0b00000000, 
		0b00000000, 0b00000000, 0b00000000, 0b00000000, 
		0b00000000, 0b00000000, 0b00000000, 0b00000000, 
		0b00000000, 0b00000000, 0b00000000, 0b00000000,])
	mesh_surface[Mesh.ARRAY_CUSTOM1] = PackedByteArray([
		0b00000000, 0b00000000, 0b00000001, 0b00000000, 
		0b00000000, 0b00000000, 0b00000001, 0b00000000, 
		0b00000000, 0b00000000, 0b00000001, 0b00000000, 
		0b00000000, 0b00000000, 0b00000000, 0b00000001, 
		0b00000000, 0b00000000, 0b00000000, 0b00000001, 
		0b00000000, 0b00000000, 0b00000000, 0b00000001,])
	
	var test_mat: ShaderMaterial = load("res://assets/substance_assets/opaq_subst_mat.tres")
	test_mat.set_shader_parameter("albedos_textures", ChemCraft.albedos_texarray)
	test_mat.set_shader_parameter("normals_textures", ChemCraft.normals_texarray)
	test_mat.set_shader_parameter("specials_textures", ChemCraft.specials_texarray)
	
	var format = (
		Mesh.ARRAY_CUSTOM0 | Mesh.ARRAY_CUSTOM_RGBA8_UNORM |
		Mesh.ARRAY_CUSTOM1 | Mesh.ARRAY_CUSTOM_RGBA8_UNORM )
	
	array_mesh.add_surface_from_arrays(
		Mesh.PRIMITIVE_TRIANGLES, 
		mesh_surface,
		[],
		{},
		format,)
	array_mesh.surface_set_material(0, test_mat)
	mesh_instance_node.mesh = array_mesh
	
	add_child(mesh_instance_node)
