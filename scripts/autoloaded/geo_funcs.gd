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
