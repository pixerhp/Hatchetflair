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
# Vertex Edges (using indices, ordered by midpoint positions)
const unit_rhombdo_edges: Array[PackedByteArray] = [
	[0,1], [0,2], [0,3], [0,4],
		
		[1,5], [1,6], [2,5], [3,6], [2,7], [3,8], [4,7], [4,8],
		
		[5,9], [6,9], [5,10], [6,11], [7,10], [8,11], [7,12], [8,12],
		
		[9,13], [10,13], [11,13], [12,13], 
]
# !!! add faces information to both the unit rhombdo and unit cube
const unit_rhombdo = [
	unit_rhombdo_verts,
	unit_rhombdo_edges,
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
const unit_cube_edges: Array[PackedByteArray] = [
	[0,1], [0,2], [1,3], [2,3],
	[0,4], [1,5], [2,6], [3,7],
	[4,5], [4,6], [5,7], [6,7],
]

const unit_cube = [
	unit_cube_verts,
	unit_cube_edges,
]


func get_marched_polyhedron_tri_indices_table(
	# Polyhedron's vertices:
	verts: Array[Vector3],
	# Polyhedron's edges, created out of vertices: (assumes the shape has at most 256 vertices.)
	edges: Array[PackedByteArray],
	# Polyhedron's faces, where the order of vertices specified defines the direction of the face's normal vector.
	# The vertex order should appear clockwise when the face's normal vector points towards the viewer perspective,
	# and counter clockwise when the face is facing away from the viewer's perspective.
	faces: Array[PackedByteArray],
	# Creative choice for result of quad ambiguities (if true bridge ons, if false bridge offs.)
	quad_ambiguity_bridge_type: bool,
) -> Array[PackedByteArray]:
	print("Generating triangle indices table (length: ", pow(2, verts.size()), ") for marched polyhedron with ", 
	verts.size(), " vertices and ", edges.size(), " vertex edges...")
	
	if verts.size() > 256:
		push_error("Provided geometry has too many vertices (has ", verts.size(), " when max is 256.)")
		return []
	if (verts.size() < 4) or (edges.size() < 6) or (faces.size() < 4):
		push_error("Provided geometry does not have enough vertices (has ", verts.size(), "/4), ", 
			"edges (has ", edges.size(), "/6), ", 
			"and/or faces (has ", faces.size(), "/4) to constitute a 3 dimensional polyhedron.")
		return []
	
	# !!! probably make the user input object vertex faces. think of blender how a shape with only vertices and edges could have faces pretty much anywhere, it's undeterminable without creative input
	
	# {u} determine active midpoints
	# {u} determine midpoint loops by making active midpoint connection on every main vertex face
	
	
	return []
