extends Node

@onready var chunks_container_node: Node = self

# Lengths, totals, and sizes of chunk stuff in metrins.

enum TILE_SHAPE {
	NO_DATA, EMPTY, ANG_MARCH, SMO_MARCH, TESS_CUBE, TESS_RHOMBDO, CLIFF,
}

class TChunk:
	static var blank_tc27: Array[TChunk] = []
	
	var tile_shapes: PackedByteArray = []
	var mesh_instance_node: MeshInstance3D = MeshInstance3D.new()
	var array_mesh: ArrayMesh = ArrayMesh.new()
	
	static func get_tc27_tchunk_i(cen_pos: Vector3i, rel_pos: Vector3i) -> int:
		var new_pos: Vector3i = Vector3i(cen_pos + rel_pos)
		var chunk_xyz: Vector3i = Vector3i(
			(new_pos.x/WU.TCHUNK_L) if (new_pos.x >= 0) else ((new_pos.x-(WU.TCHUNK_L-1))/WU.TCHUNK_L),
			(new_pos.y/WU.TCHUNK_L) if (new_pos.y >= 0) else ((new_pos.y-(WU.TCHUNK_L-1))/WU.TCHUNK_L),
			(new_pos.z/WU.TCHUNK_L) if (new_pos.z >= 0) else ((new_pos.z-(WU.TCHUNK_L-1))/WU.TCHUNK_L),
		)
		chunk_xyz += Vector3i(1, 1, 1)
		return chunk_xyz.x + (3 * chunk_xyz.y) + (9 * chunk_xyz.z)
	static func get_tc27_tile_i(cen_pos: Vector3i, rel_pos: Vector3i) -> int:
		return (
			posmod(cen_pos.x + rel_pos.x, WU.TCHUNK_L) +
			posmod(cen_pos.y + rel_pos.y, WU.TCHUNK_L) * WU.TCHUNK_L +
			posmod(cen_pos.z + rel_pos.z, WU.TCHUNK_L) * WU.TCHUNK_L * WU.TCHUNK_L
		)
	
	func t_i_from_xyz(xyz: Vector3i) -> int:
		return xyz.x + (xyz.y * WU.TCHUNK_L) + (xyz.z * WU.TCHUNK_L * WU.TCHUNK_L)
	func t_xyz_from_i(i: int) -> Vector3i:
		return Vector3i(
			posmod(i, WU.TCHUNK_L), posmod(i / WU.TCHUNK_L, WU.TCHUNK_L), posmod(i / (WU.TCHUNK_L * WU.TCHUNK_L), WU.TCHUNK_L),
		)
	
	func _init():
		tile_shapes.resize(WU.TCHUNK_T)
		tile_shapes.fill(TILE_SHAPE.NO_DATA)
	func randomize_tiles():
		tile_shapes.fill(TILE_SHAPE.EMPTY)
		for i in range(WU.TCHUNK_T):
			match randi_range(0, 6):
				0:
					tile_shapes[i] = TILE_SHAPE.TESS_CUBE
				1:
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
		var surf_inds: PackedInt32Array = []
		var surf_norms: PackedVector3Array = []
		
		for i in range(WU.TCHUNK_T):
			match tile_shapes[i]:
				TILE_SHAPE.NO_DATA:
					push_error("Attempted to mesh an unloaded tile shape.")
					continue
				TILE_SHAPE.EMPTY:
					continue
				TILE_SHAPE.TESS_CUBE:
					mesh_tess_cube(t_xyz_from_i(i), tc_27, surf_verts, surf_inds, surf_norms)
				TILE_SHAPE.TESS_RHOMBDO:
					mesh_tess_rhombdo(t_xyz_from_i(i), tc_27, surf_verts, surf_inds, surf_norms)
		
		var mesh_surface: Array = []
		mesh_surface.resize(Mesh.ARRAY_MAX)
		mesh_surface[Mesh.ARRAY_VERTEX] = surf_verts
		mesh_surface[Mesh.ARRAY_INDEX] = surf_inds
		mesh_surface[Mesh.ARRAY_NORMAL] = surf_norms
		
		array_mesh.add_surface_from_arrays(
			Mesh.PRIMITIVE_TRIANGLES,
			mesh_surface,
		)
		var test_mat: StandardMaterial3D = StandardMaterial3D.new()
		test_mat.albedo_color = Color.WHITE
		array_mesh.surface_set_material(0, test_mat)
		mesh_instance_node.mesh = array_mesh
	
	func mesh_tess_cube(
		pos: Vector3i, tc_27: Array[TChunk], 
		verts_ref: PackedVector3Array, inds_ref: PackedInt32Array, norms_ref: PackedVector3Array,
	):
		for j: int in range(6):
			match tc_27[get_tc27_tchunk_i(pos, WU.mesh_tess_cube_move[j])
			].tile_shapes[get_tc27_tile_i(pos, WU.mesh_tess_cube_move[j])
			]:
				TILE_SHAPE.NO_DATA, TILE_SHAPE.EMPTY: pass
				TILE_SHAPE.ANG_MARCH:
					# if {known that the cube would be covered} then 'continue' else pass to face meshing
					pass
				TILE_SHAPE.TESS_CUBE, TILE_SHAPE.TESS_RHOMBDO, _: continue
			for k: int in range(4):
				verts_ref.append(Vector3(pos) + WU.mesh_tess_cube_verts[(4*j)+k])
				norms_ref.append(Vector3(WU.mesh_tess_cube_move[j]))
			inds_ref.append_array([
				verts_ref.size()-4, verts_ref.size()-3, verts_ref.size()-2,
				verts_ref.size()-3, verts_ref.size()-1, verts_ref.size()-2,
			])
	
	func mesh_tess_rhombdo(
		pos: Vector3i, tc_27: Array[TChunk], 
		verts_ref: PackedVector3Array, inds_ref: PackedInt32Array, norms_ref: PackedVector3Array,
	):
		var tri_cull_data: int = 3
		for j in range(12): # Check whether whole face should be culled:
			match tc_27[get_tc27_tchunk_i(pos, WU.mesh_tess_rhombdo_move[j])
			].tile_shapes[get_tc27_tile_i(pos, WU.mesh_tess_rhombdo_move[j])
			]:
				TILE_SHAPE.TESS_RHOMBDO:
					continue
			tri_cull_data = 3 # Individually check whether the 2 face-triangles should be culled:
			for k in range(2):
				if tc_27[get_tc27_tchunk_i(pos, WU.mesh_tess_rhombdo_move[(2 * j) + k + 12])
				].tile_shapes[get_tc27_tile_i(pos, WU.mesh_tess_rhombdo_move[(2 * j) + k + 12])
				] in PackedInt32Array([TILE_SHAPE.TESS_CUBE, TILE_SHAPE.TESS_RHOMBDO]):
					tri_cull_data -= (k + 1)
			match tri_cull_data:
				0:
					continue
				1:
					verts_ref.append_array([
						Vector3(pos) + WU.mesh_tess_rhombdo_verts[(j * 4)],
						Vector3(pos) + WU.mesh_tess_rhombdo_verts[(j * 4) + 1],
						Vector3(pos) + WU.mesh_tess_rhombdo_verts[(j * 4) + 2],
					])
				2:
					verts_ref.append_array([
						Vector3(pos) + WU.mesh_tess_rhombdo_verts[(j * 4) + 1],
						Vector3(pos) + WU.mesh_tess_rhombdo_verts[(j * 4) + 3],
						Vector3(pos) + WU.mesh_tess_rhombdo_verts[(j * 4) + 2],
					])
				3:
					verts_ref.append_array([
						Vector3(pos) + WU.mesh_tess_rhombdo_verts[(j * 4)],
						Vector3(pos) + WU.mesh_tess_rhombdo_verts[(j * 4) + 1],
						Vector3(pos) + WU.mesh_tess_rhombdo_verts[(j * 4) + 2],
						Vector3(pos) + WU.mesh_tess_rhombdo_verts[(j * 4) + 3],
					])
			match tri_cull_data:
				1, 2:
					norms_ref.append_array([
						WU.mesh_tess_rhombdo_norms[j],
						WU.mesh_tess_rhombdo_norms[j],
						WU.mesh_tess_rhombdo_norms[j],
					])
					inds_ref.append_array([
						verts_ref.size()-3, verts_ref.size()-2, verts_ref.size()-1,
					])
				3:
					norms_ref.append_array([
						WU.mesh_tess_rhombdo_norms[j],
						WU.mesh_tess_rhombdo_norms[j],
						WU.mesh_tess_rhombdo_norms[j],
						WU.mesh_tess_rhombdo_norms[j],
					])
					inds_ref.append_array([
						verts_ref.size()-4, verts_ref.size()-3, verts_ref.size()-2,
						verts_ref.size()-3, verts_ref.size()-1, verts_ref.size()-2,
					])

func _init():
	TChunk.blank_tc27.resize(27)
	TChunk.blank_tc27.fill(TChunk.new())

func _ready():
	var test_chunk: TChunk = TChunk.new()
	test_chunk.randomize_tiles()
	
	test_chunk.generate_mesh()
	add_child(test_chunk.mesh_instance_node)
