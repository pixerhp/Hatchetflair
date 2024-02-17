extends Node

# standard (using BLENDER xyz:)
# for (-z -> +z):
# for (-y -> +y):
# for (-x -> +x):

# (will end up mirrored across blender-y/godot-z)

# standard (using GODOT xyz:)
# for (-y -> +y):
# for (-z -> +z):
# for (-x -> +x):

# Vertex Positions (multiply y by sqrt(3)/2 to have rhombdos tesselate in cubes better.)
const unit_rhombdo_verts: Array[Vector3] = [
	Vector3(0, (-1.0/sqrt(3)), 0),
	
	Vector3(0, (-0.5/sqrt(3)), -0.5),
	Vector3(-0.5, (-0.5/sqrt(3)), 0),
	Vector3(0.5, (-0.5/sqrt(3)), 0),
	Vector3(0, (-0.5/sqrt(3)), 0.5),
	
	Vector3(-0.5, 0, -0.5),
	Vector3(0.5, 0, -0.5),
	Vector3(-0.5, 0, 0.5),
	Vector3(0.5, 0, 0.5),
	
	Vector3(0, (0.5/sqrt(3)), -0.5),
	Vector3(-0.5, (0.5/sqrt(3)), 0),
	Vector3(0.5, (0.5/sqrt(3)), 0),
	Vector3(0, (0.5/sqrt(3)), 0.5),
	
	Vector3(0, (1.0/sqrt(3)), 0),
]
# Vertex Connections (using indices, ordered by midpoint positions)
const unit_rhombdo_conns: Array[PackedByteArray] = [
	[0,1], [0,2], [0,3], [0,4],
		
		[1,5], [1,6], [2,5], [3,6], [2,7], [3,8], [4,7], [4,8],
		
		[5,9], [6,9], [5,10], [6,11], [7,10], [8,11], [7,12], [8,12],
		
		[9,13], [10,13], [11,13], [12,13], 
]
const unit_rhombdo = [
	unit_rhombdo_verts,
	unit_rhombdo_conns,
]

const unit_cube_verts: Array[Vector3] = [
	Vector3(-0.5, -0.5, -0.5),
	Vector3(0.5, -0.5, -0.5),
	Vector3(-0.5, -0.5, 0.5),
	Vector3(0.5, -0.5, 0.5),
	Vector3(-0.5, 0.5, -0.5),
	Vector3(0.5, 0.5, -0.5),
	Vector3(-0.5, 0.5, 0.5),
	Vector3(0.5, 0.5, 0.5),
]
const unit_cube_conns: Array[PackedByteArray] = [
	[0,1], [0,2], [1,3], [2,3],
	[0,4], [1,5], [2,6], [3,7],
	[4,5], [4,6], [5,7], [6,7],
]
const unit_cube = [
	unit_cube_verts,
	unit_cube_conns,
]


func get_marched_geo_tri_indices_table(
	# vertices of the polyhedron:
	verts: Array[Vector3],
	# vertex connections: (assumes no more than 256 vertices.)
	conns: Array[PackedByteArray],
	# creative choice for quad ambiguities: (choose to either bridge ons and gap offs, or the opposite.)
	bridge_quad_ambiguity_ons: bool,
) -> Array[PackedByteArray]:
	print("Generating triangle indices table (length: ", pow(2, verts.size()), ") for marched polyhedron with ", 
	verts.size(), " vertices and ", conns.size(), " vertex connections (aka edges)...")
	
	if (verts.size() < 4) or (conns.size() < 6):
		push_warning("Not enough vertices (", verts.size(), ") and/or connections (aka edges) (", 
			conns.size(), ") to constitute a 3 dimensional polyhedron.")
		var array: Array[PackedByteArray] = []
		array.resize(pow(2,verts.size()))
		return [array]
	
	
	return []
