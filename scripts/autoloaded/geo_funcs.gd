extends Node


# Each edge (vertex connection) is an array of 2 ints, where the ints are vertex indices.
	# (For example, an edge [4,9] means that the 5th vertex and the 10th vertex form an edge together.)
# Each output triangle is an array of 3 ints, where the ints represent edge indices.
	# (For example, a triangle [2,3,5] means that the 3rd, 4th and 6th edges form a triangle together.)
func get_tris_formed_by_edges(edges: Array[PackedInt32Array]) -> Array[PackedInt32Array]:
	# No triangles can be formed with less than three edges.
	if edges.size() < 3:
		return []
	
	var triangles: Array[PackedInt32Array] = []
	var possible_tri: PackedInt32Array = []
	var breaking_flag: bool = false
	
	for edge1 in range(0, edges.size() - 2):
		for edge2 in range(edge1 + 1, edges.size() - 1):
			# If edge2 is functionally the same as edge1, skip this edge2.
			if (edge2 == edge1) or (edges[edge2].has(edges[edge1][0]) and edges[edge2].has(edges[edge1][1])):
				continue
			# If edges 1 and 2 share a vertex, search for a 3rd vertex that would complete the triangle.
			breaking_flag = false
			for v1 in range(2):
				for v2 in range(2):
					if edges[edge1][v1] == edges[edge2][v2]:
						for edge3 in range(edge2 + 1, edges.size()):
							# If a third edge which completes the tri is found, add the tri if it's not a repeat.
							if edges[edge3].has(edges[edge1][1 - v1]) and edges[edge3].has(edges[edge2][1 - v2]):
								possible_tri = [edge1, edge2, edge3]
								possible_tri.sort()
								if not triangles.has(possible_tri):
									triangles.append(possible_tri)
								breaking_flag = true
								break
					if breaking_flag:
						break
				if breaking_flag:
					break
	
	return triangles

enum TRI_ORIENTATION {
	CW,
	CCW,
	LINE, # between clockwise and counter-clockwise, for if a tri's vertices fall along a line.
}

# negative = clockwise, positive = counter-clockwise, 0 = along a line
# https://math.stackexchange.com/questions/1324179/how-to-tell-if-3-connected-points-are-connected-clockwise-or-counter-clockwise
func get_tri_orientation_2d(vertices: Array[Vector2]):
	var basis: float = Basis(
		Vector3(vertices[0].x,vertices[0].y,1),
		Vector3(vertices[1].x,vertices[1].y,1),
		Vector3(vertices[2].x,vertices[2].y,1),
	).determinant()
	if basis < 0:
		return TRI_ORIENTATION.CW
	elif basis > 0:
		return TRI_ORIENTATION.CCW
	else:
		return TRI_ORIENTATION.LINE

func are_vector3s_coplanar(points: Array[Vector3], tolerance: float) -> bool:
	# A set of only 3 or less points are guaranteed to be coplanar.
	if points.size() < 4:
		return true
	
	var triangle_normal_vector: Vector3 = (
		points[0].cross(points[1]) + 
		points[1].cross(points[2]) + 
		points[2].cross(points[0])
	).normalized()
	
	for index in range(3, points.size()):
		if abs(triangle_normal_vector.dot(points[index] - points[0])) > tolerance:
			return false
	
	return true


# Note: edges lists indices of vertices, and faces lists indices of edges.
class Polyhedron:
	var verts: Array[Vector3]
	var edges: Array[PackedInt32Array]
	var faces: Array[PackedInt32Array]
	
	func _init(
		in_verts: Array[Vector3],
		in_edges: Array[PackedInt32Array],
		in_faces: Array[PackedInt32Array],
	):
		verts = in_verts
		edges = in_edges
		faces = in_faces

# Defines a 1x1x1 cube centered at (0,0,0).
var UNIT_CUBE: Polyhedron = Polyhedron.new(
	[
		Vector3(-0.5, -0.5, -0.5),
		Vector3(0.5, -0.5, -0.5),
		Vector3(-0.5, -0.5, 0.5),
		Vector3(0.5, -0.5, 0.5),
		Vector3(-0.5, 0.5, -0.5),
		Vector3(0.5, 0.5, -0.5),
		Vector3(-0.5, 0.5, 0.5),
		Vector3(0.5, 0.5, 0.5),
	],
	[
		[0,1], [0,2], [1,3], [2,3],
		[0,4], [1,5], [2,6], [3,7],
		[4,5], [4,6], [5,7], [6,7],
	],
	[
		[0,2,3,1],
		[0,4,8,5],
		[1,6,9,4],
		[2,5,10,7],
		[3,7,11,6],
		[8,9,11,10],
	]
)

# Defines a regular rhombic dodecahedron centered at (0,0,0).
var UNIT_RHOMBDO: Polyhedron = Polyhedron.new(
	[ # !!! double-check whether these are the vertex locations of a perfect or scaled rhombdo.
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
	],
	[
		[0,1], [0,2], [0,3], [0,4],
		[1,5], [1,6], [2,5], [3,6], [2,7], [3,8], [4,7], [4,8],
		[5,9], [6,9], [5,10], [6,11], [7,10], [8,11], [7,12], [8,12],
		[9,13], [10,13], [11,13], [12,13], 
	],
	[
		[0,1,6,4],
		[0,5,7,2],
		[1,3,10,8],
		[2,9,11,3],
		[4,12,13,5],
		[6,8,16,14],
		[7,15,17,9],
		[10,11,19,18],
		[12,14,21,20],
		[13,20,22,15],
		[16,18,23,21],
		[17,22,23,19],
	],
)

# Maybe some day...
func generate_marched_polyhedron_indices_table(polyhedron: Polyhedron):
	return
