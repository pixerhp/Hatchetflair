extends Node

@onready var chunks_container_node: Node = self

# Lengths, totals, and sizes of chunk stuff in metrins.
const TCHUNK_L: int = 16
const TCHUNK_T: int = TCHUNK_L ** 3
const TCHUNK_S: Vector3i = Vector3i(TCHUNK_L, TCHUNK_L, TCHUNK_L)
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
		return chunk_xyz.x + (TCHUNK_L * chunk_xyz.y) + (TCHUNK_L * TCHUNK_L * chunk_xyz.z)
	static func get_tc27_tile_i(cen_pos: Vector3i, rel_pos: Vector3i) -> int:
		return (
			posmod(cen_pos.x + rel_pos.x, TCHUNK_L) +
			posmod(cen_pos.y + rel_pos.y, TCHUNK_L) * TCHUNK_L +
			posmod(cen_pos.z + rel_pos.z, TCHUNK_L) * TCHUNK_L * TCHUNK_L
		)
	
	func t_i_from_xyz(xyz: Vector3i, lengths: Vector3i = TCHUNK_S) -> int:
		return xyz.x + (xyz.y * lengths.y) + (xyz.z * lengths.z * lengths.z)
	func t_xyz_from_i(i: int, lengths: Vector3i = TCHUNK_S,) -> Vector3i:
		return Vector3i(
			posmod(i, lengths.x),
			posmod(i/lengths.x, lengths.y),
			posmod(i/(lengths.x * lengths.y), lengths.z),
		)
	
	func _init():
		tile_shapes.resize(TCHUNK_T)
		tile_shapes.fill(TILE_SHAPE.NO_DATA)
	func randomize_tiles():
		for i in range(TCHUNK_T):
			tile_shapes[i] = randi_range(0, 1)
	
	func unmesh():
		mesh_instance_node.queue_free()
		mesh_instance_node = MeshInstance3D.new()
		array_mesh = ArrayMesh.new()
	
	func generate_mesh(tc_27: Array[TChunk] = blank_tc27):
		tc_27[13] = self # Set self as center of the 3x3x3 chunks.
		print(tc_27)
		
		for i in range(TCHUNK_T):
			pass
		
		
		
		# Get all of the information needed, including data related to surrounding chunks.
		# For now though, all needed surrounding chunk tile shapes are simply assumed to be empty.
		var padded_shapes: PackedByteArray = []
		padded_shapes.resize((TCHUNK_L + 1) ** 3)
		padded_shapes.fill(TILE_SHAPE.EMPTY)
		for i in range(TCHUNK_T):
			padded_shapes[
				t_i_from_xyz(t_xyz_from_i(i) + Vector3i(1, 1, 1), TCHUNK_PAD_S)
			] = tile_shapes[i]
		
		var surf_verts: PackedVector3Array = []
		var surf_inds: PackedInt32Array = []
		
		# !!! (break stuff down into more functions?)
		
		var j: int = 0
		for z in range(1, TCHUNK_L + 1):
			for y in range(1, TCHUNK_L + 1):
				for x in range(1, TCHUNK_L + 1):
					j = t_i_from_xyz(Vector3i(x, y, z), TCHUNK_PAD_S)
					match padded_shapes[j]:
						TILE_SHAPE.EMPTY:
							continue
						TILE_SHAPE.TESS_CUBE:
							if padded_shapes[
								t_i_from_xyz(Vector3i(x - 1, y, z), TCHUNK_PAD_S)
							] == TILE_SHAPE.EMPTY:
								surf_verts.append(Vector3(x-1, y-1, z-0))
								surf_verts.append(Vector3(x-1, y-1, z-1))
								surf_verts.append(Vector3(x-1, y+0, z-0))
								surf_verts.append(Vector3(x-1, y+0, z-1))
								surf_inds.append_array([
									surf_verts.size() - 4,
									surf_verts.size() - 3,
									surf_verts.size() - 2,
									surf_verts.size() - 1,
									surf_verts.size() - 2,
									surf_verts.size() - 3,
								])
							#if padded_shapes[
								#t_i_from_xyz(Vector3i(x + 1, y, z), PADDED_CHUNK_SIZE)
							#] == TILE_SHAPE.EMPTY:
								#pass
							if padded_shapes[
								t_i_from_xyz(Vector3i(x, y - 1, z), TCHUNK_PAD_S)
							] == TILE_SHAPE.EMPTY:
								pass
							#if padded_shapes[
								#t_i_from_xyz(Vector3i(x, y + 1, z), PADDED_CHUNK_SIZE)
							#] == TILE_SHAPE.EMPTY:
								#pass
							if padded_shapes[
								t_i_from_xyz(Vector3i(x, y, z - 1), TCHUNK_PAD_S)
							] == TILE_SHAPE.EMPTY:
								pass
							#if padded_shapes[
								#t_i_from_xyz(Vector3i(x, y, z + 1), PADDED_CHUNK_SIZE)
							#] == TILE_SHAPE.EMPTY:
								#pass
		
		var mesh_surface: Array = []
		mesh_surface.resize(Mesh.ARRAY_MAX)
		mesh_surface[Mesh.ARRAY_VERTEX] = surf_verts
		mesh_surface[Mesh.ARRAY_INDEX] = surf_inds
		
		array_mesh.add_surface_from_arrays(
			Mesh.PRIMITIVE_TRIANGLES,
			mesh_surface,
		)
		mesh_instance_node.mesh = array_mesh

func _init():
	assert(TCHUNK_PAD_L <= TCHUNK_L)
	TChunk.blank_tc27.resize(27)
	TChunk.blank_tc27.fill(TChunk.new())

func _ready():
	var test_chunk: TChunk = TChunk.new()
	test_chunk.randomize_tiles()
	test_chunk.tile_shapes[0] = TILE_SHAPE.TESS_CUBE
	test_chunk.generate_mesh()
	test_chunk.mesh_instance_node.position += Vector3(-8, -8, -8)
	add_child(test_chunk.mesh_instance_node)
