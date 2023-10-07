extends Node

const UNIT_RHOMBDO_VERTS: Array[Vector3] = [
	Vector3(0, -0.5, 0),
	
	Vector3(0, -0.25, 0.5),
	Vector3(-0.5, -0.25, 0),
	Vector3(0.5, -0.25, 0),
	Vector3(0, -0.25, -0.5),
	
	Vector3(-0.5, 0, 0.5),
	Vector3(0.5, 0, 0.5),
	Vector3(-0.5, 0, -0.5),
	Vector3(0.5, 0, -0.5),
	
	Vector3(0, 0.25, 0.5),
	Vector3(-0.5, 0.25, 0),
	Vector3(0.5, 0.25, 0),
	Vector3(0, 0.25, -0.5),
	
	Vector3(0, 0.5, 0), ]
var UNIT_RHOMBDO_EDGES: Array[PackedByteArray] = [
	# standard edges:
	[0, 1], [0, 2], [0, 3], [0, 4],
	# tetra' edges:
	[1, 2], [1, 3], [2, 3], [2, 4], [3, 4],
	# standard edges:
	[1, 5], [1, 6], [2, 5], [3, 6], [2, 7], [3, 8], [4, 7], [4, 8],
	# tetra'd edges:
	[1, 9], [2, 9], [1, 11], [2, 10], [2, 11], [3, 11], [2, 12], [4, 11], [4, 12],
	# standard edges:
	[5, 9], [6, 9], [5, 10], [6, 11], [7, 10], [8, 11], [7, 12], [8, 12],
	# tetra'd edges:
	[9, 10], [9, 11], [10, 11], [10, 12], [11, 12],
	# standard edges:
	[9, 13], [10, 13], [11, 13], [12, 13], 
	]


func gen_unit_rhombdo_indices_table() -> Array[PackedByteArray]:
	return gen_indices_table(UNIT_RHOMBDO_VERTS, UNIT_RHOMBDO_EDGES)

# Note: All faces of the 3D shape must be triangles, meaning you may need to break it into tetrahedrons first.
# Note: edges should be an array of PackedByteArrays which have 2 elements each.
# 	(said two items are the indexes of inputed vertices from the function's previous argument.)
# 	ex: if the 2nd and 5th vertices are connected with an edge, edges should contain [1, 4].
# Note: The indices of the edges listed is the same as their associated midpoints as used in the output table.
# Note: Only works with up to 256 vertices and 256 edges. This limit can be increased by 
#	replacing PackedByteArray with int all over the place, but at the cost of larger memory costs.
func gen_indices_table(vertices: Array[Vector3], edges: Array[PackedByteArray]) -> Array[PackedByteArray]:
	if vertices.size() < 4:
		push_error("Not enough vertices to constitute a 3D shape. (Requires at least 4, was provided ", vertices.size(), ")")
		return []
	
	# Get a list of the object's faces. (Faces store edge indices, not vertex indices.)
	var faces: Array[PackedByteArray] = tris_formed_by_edges(edges)
	if faces.size() < 4:
		push_error("Found that the edges did not create enough triangular faces to constitute a 3D shape. ",
		"(Only found ", faces.size(), " triangle faces.)")
		return []
	
	var indices_table: Array[PackedByteArray] = []
	indices_table.resize(2 ** vertices.size())
	var vertex_states_bits: PackedByteArray = []
	vertex_states_bits.resize(vertices.size())
	var mids_used_in_face: PackedByteArray = []
	var midpoint_connections: Array[PackedByteArray] = []
	var mid_tris_awk: Array[PackedByteArray] = []
	var midpoint_triangles: Array[PackedByteArray] = []
	
	for vertex_combination in range(0, indices_table.size()):
		# Get the on/off state of each vertex from the current combination number.
		for vert_index in vertices.size():
			vertex_states_bits[vert_index] = (vertex_combination >> vert_index) & 1
		
		# Determine midpoint connections by checking each trianglular face.
		midpoint_connections.clear()
		for face in faces:
			for edge_index in face:
				if vertex_states_bits[edges[edge_index][0]] != vertex_states_bits[edges[edge_index][1]]:
					mids_used_in_face.append(edge_index)
			if mids_used_in_face.size() == 2:
				mids_used_in_face.sort()
				if not midpoint_connections.has(mids_used_in_face):
					midpoint_connections.append(mids_used_in_face.duplicate())
			mids_used_in_face.clear()
		
		# Find all triangles created by midpoint connections, and convert them to a more usable form.
		mid_tris_awk = tris_formed_by_edges(midpoint_connections)
		midpoint_triangles.clear()
		midpoint_triangles.resize(mid_tris_awk.size())
		for awkward_tri_index in range(mid_tris_awk.size()):
			for midpoint_conn_index in range(3):
				if not midpoint_triangles[awkward_tri_index].has(midpoint_connections[mid_tris_awk[awkward_tri_index][midpoint_conn_index]][0]):
					midpoint_triangles[awkward_tri_index].append(midpoint_connections[mid_tris_awk[awkward_tri_index][midpoint_conn_index]][0])
				if not midpoint_triangles[awkward_tri_index].has(midpoint_connections[mid_tris_awk[awkward_tri_index][midpoint_conn_index]][1]):
					midpoint_triangles[awkward_tri_index].append(midpoint_connections[mid_tris_awk[awkward_tri_index][midpoint_conn_index]][1])
		
		
		# (u) Reorder triangle indices such that the tri is drawn facing the correct direction.
		# !!! right now we're skipping that step!!!
		for triangle in midpoint_triangles:
			indices_table[vertex_combination].append_array(triangle)
	
	return indices_table

func tris_formed_by_edges(edges: Array[PackedByteArray]) -> Array[PackedByteArray]:
	# No triangles can be formed out of less-than-3 edges.
	if edges.size() < 3:
		return []
	
	var known_tris: Array[PackedByteArray] = []
	var potential_tri: PackedByteArray = []
	var breaking_flag: bool = false
	
	for edge_a in range(0, edges.size() - 2):
		for edge_b in range(edge_a + 1, edges.size() - 1):
			# If edge b is functionally the same as edge a, skip this edge b.
			if (edge_b == edge_a) or (edges[edge_b].has(edges[edge_a][0]) and edges[edge_b].has(edges[edge_a][1])):
				continue
			# If edges 1 and 2 share a vertex, search for a 3rd vertex that would complete the triangle.
			breaking_flag = false
			for v_a in range(2):
				for v_b in range(2):
					if edges[edge_a][v_a] == edges[edge_b][v_b]:
						for edge_c in range(edge_b + 1, edges.size()):
							# If a third edge which completes the tri is found, add the tri if it's not a repeat.
							if edges[edge_c].has(edges[edge_a][1 - v_a]) and edges[edge_c].has(edges[edge_b][1 - v_b]):
								potential_tri = [edge_a, edge_b, edge_c]
								potential_tri.sort()
								if not known_tris.has(potential_tri):
									known_tris.append(potential_tri)
								breaking_flag = true
								break
					if breaking_flag:
						break
				if breaking_flag:
					break
	
	return known_tris

func midpoint_indices_used(vertex_states_bits: PackedByteArray, edges: Array[PackedByteArray]) -> PackedByteArray:
	var midpoints_used: PackedByteArray = []
	for edge_index in edges.size():
		if vertex_states_bits[edges[edge_index][0]] != vertex_states_bits[edges[edge_index][1]]:
			midpoints_used.append(edge_index)
	return midpoints_used


# Write this function later, either here or in a math script.
#func midpoint_xyz(vertex1: [Vector3], vertex2: [Vector3]) -> Vector3:
