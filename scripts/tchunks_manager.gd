extends Node

@onready var chunks_container_node: Node = self

# Lengths, totals, and sizes of chunk stuff in metrins.
const TCHUNK_L: int = 16
const TCHUNK_T: int = TCHUNK_L ** 3
const TCHUNK_S: Vector3i = Vector3i(TCHUNK_L, TCHUNK_L, TCHUNK_L)
const TCHUNK_HALF_S: Vector3 = Vector3(TCHUNK_S) / 2.0
const TCHUNK_PAD_L: int = 1
const TCHUNK_PAD_T: int = (TCHUNK_L + TCHUNK_PAD_L) ** 3
const TCHUNK_PAD_S: Vector3i = Vector3i(
	TCHUNK_L + TCHUNK_PAD_L, TCHUNK_L + TCHUNK_PAD_L, TCHUNK_L + TCHUNK_PAD_L,)

enum TILE_SHAPE {
	NO_DATA, EMPTY, TESS_CUBE, TESS_RHOMBDO, MARCH_CUBE,
}

class TChunk:
	static var blank_tc27: Array[TChunk] = []
	
	var tile_shapes: PackedByteArray = []
	var mesh_instance_node: MeshInstance3D = MeshInstance3D.new()
	var array_mesh: ArrayMesh = ArrayMesh.new()
	
	static func get_tc27_tchunk_i(cen_pos: Vector3i, rel_pos: Vector3i) -> int:
		var new_pos: Vector3i = Vector3i(cen_pos + rel_pos)
		var chunk_xyz: Vector3i = Vector3i(
			(new_pos.x/TCHUNK_L) if (new_pos.x >= 0) else ((new_pos.x-(TCHUNK_L-1))/TCHUNK_L),
			(new_pos.y/TCHUNK_L) if (new_pos.y >= 0) else ((new_pos.y-(TCHUNK_L-1))/TCHUNK_L),
			(new_pos.z/TCHUNK_L) if (new_pos.z >= 0) else ((new_pos.z-(TCHUNK_L-1))/TCHUNK_L),
		)
		chunk_xyz += Vector3i(1, 1, 1)
		return chunk_xyz.x + (3 * chunk_xyz.y) + (9 * chunk_xyz.z)
	static func get_tc27_tile_i(cen_pos: Vector3i, rel_pos: Vector3i) -> int:
		return (
			posmod(cen_pos.x + rel_pos.x, TCHUNK_L) +
			posmod(cen_pos.y + rel_pos.y, TCHUNK_L) * TCHUNK_L +
			posmod(cen_pos.z + rel_pos.z, TCHUNK_L) * TCHUNK_L * TCHUNK_L
		)
	
	func t_i_from_xyz(xyz: Vector3i) -> int:
		return xyz.x + (xyz.y * TCHUNK_L) + (xyz.z * TCHUNK_L * TCHUNK_L)
	func t_xyz_from_i(i: int) -> Vector3i:
		return Vector3i(
			posmod(i, TCHUNK_L), posmod(i / TCHUNK_L, TCHUNK_L), posmod(i / (TCHUNK_L * TCHUNK_L), TCHUNK_L),
		)
	
	func _init():
		tile_shapes.resize(TCHUNK_T)
		tile_shapes.fill(TILE_SHAPE.NO_DATA)
	func randomize_tiles():
		tile_shapes.fill(TILE_SHAPE.EMPTY)
		for i in range(TCHUNK_T):
			if randi_range(0, 36) == 0:
				tile_shapes[i] = TILE_SHAPE.TESS_CUBE
	
	func unmesh():
		mesh_instance_node.queue_free()
		mesh_instance_node = MeshInstance3D.new()
		array_mesh = ArrayMesh.new()
	
	func generate_mesh(tc_27: Array[TChunk] = blank_tc27):
		tc_27[13] = self # Set self as center of the 3x3x3 chunks.
		
		var surf_verts: PackedVector3Array = []
		var surf_inds: PackedInt32Array = []
		var surf_norms: PackedVector3Array = []
		
		for i in range(TCHUNK_T):
			match tile_shapes[i]:
				TILE_SHAPE.NO_DATA:
					push_error("Tried to mesh an unloaded tile shape.")
				TILE_SHAPE.EMPTY:
					continue
				TILE_SHAPE.TESS_CUBE:
					mesh_tess_cube(t_xyz_from_i(i), tc_27, surf_verts, surf_inds, surf_norms)
		
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
				TILE_SHAPE.MARCH_CUBE:
					# if {known that the cube would be covered} then 'continue'
					pass
				_: continue
			for k: int in range(4):
				verts_ref.append(Vector3(pos) + WU.mesh_tess_cube_verts[(4*j)+k])
				norms_ref.append(Vector3(WU.mesh_tess_cube_move[j]))
			inds_ref.append_array([
				verts_ref.size()-4, verts_ref.size()-3, verts_ref.size()-2,
				verts_ref.size()-3, verts_ref.size()-1, verts_ref.size()-2,
			])
		

func _init():
	assert(TCHUNK_PAD_L <= TCHUNK_L)
	TChunk.blank_tc27.resize(27)
	TChunk.blank_tc27.fill(TChunk.new())

func _ready():
	var test_chunk: TChunk = TChunk.new()
	#test_chunk.tile_shapes.fill(TILE_SHAPE.EMPTY)
	test_chunk.randomize_tiles()
	test_chunk.generate_mesh()
	add_child(test_chunk.mesh_instance_node)
