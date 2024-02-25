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

# Unit Polyhedron Formatting:
# edges list indices of vertices, and faces list indices of edges.

class unit_cube:
	const verts: Array[Vector3] = [
		Vector3(-0.5, -0.5, -0.5),
		Vector3(0.5, -0.5, -0.5),
		Vector3(-0.5, -0.5, 0.5),
		Vector3(0.5, -0.5, 0.5),
		Vector3(-0.5, 0.5, -0.5),
		Vector3(0.5, 0.5, -0.5),
		Vector3(-0.5, 0.5, 0.5),
		Vector3(0.5, 0.5, 0.5),
	]
	# !!! MAKE THESE CONSTANTS NOT VARIABLES ONCE THE RELATED GODOT BUGS ARE FIXED!!
	# (their uses will also be different, not requiring an instanciated cube class object to access them.)
	var edges: Array[PackedByteArray] = [
		[0,1], [0,2], [1,3], [2,3],
		[0,4], [1,5], [2,6], [3,7],
		[4,5], [4,6], [5,7], [6,7],
	]
	var faces: Array[PackedByteArray] = [
		[0,2,3,1],
		[0,4,8,5],
		[1,6,9,4],
		[2,5,10,7],
		[3,7,11,6],
		[8,9,11,10],
	]

class unit_rhombdo:
	# (Multiply y by sqrt(3)/2 to have rhombdos tesselate in cubes better.)
	const verts: Array[Vector3] = [
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
	const edges: Array[PackedByteArray] = [
		[0,1], [0,2], [0,3], [0,4],
		[1,5], [1,6], [2,5], [3,6], [2,7], [3,8], [4,7], [4,8],
		[5,9], [6,9], [5,10], [6,11], [7,10], [8,11], [7,12], [8,12],
		[9,13], [10,13], [11,13], [12,13], 
	]
	const faces: Array[PackedByteArray] = [
		
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
		verts.size(), " vertices, ", edges.size(), " edges and ", faces.size(), " faces... ",
		"(quad bridge type = ", int(quad_ambiguity_bridge_type), ")")
	
	# Collects warnings and fatal errors related to the input polyhedron information.
	var polyhedron_errors: Array[PackedStringArray]
	polyhedron_errors = get_polyhedron_errors(verts, edges, faces, 4)
	
	print("Polyhedron Warnings: (", polyhedron_errors[0].size(), ")")
	for warning_message in polyhedron_errors[0]:
		print("\t" + warning_message)
	print("Polyhedron Errors: (", polyhedron_errors[1].size(), ")")
	for error_message in polyhedron_errors[1]:
		print("\t" + error_message)
	
	if polyhedron_errors[1].size() > 0:
		print("Aborting triangle indices table generation due to polyhedron errors.")
	
	
	
	
	
	
	
	
	# Checks for errors and mistakes related to provided faces:
	if true:
		var too_many_edges_in_faces: bool = false
		var edges_used_by_faces: PackedByteArray = []
		edges_used_by_faces.resize(edges.size())
		edges_used_by_faces.fill(false)
		var faces_use_nonexistant_edges: bool = false
		for face in faces:
			if face.size() > 4:
				too_many_edges_in_faces = true
			for edge in face:
				if edge < edges.size():
					edges_used_by_faces[edge] = true
				else:
					faces_use_nonexistant_edges = true
		var number_of_edges_unused_by_faces: int = 0
		for edge_usedness in edges_used_by_faces:
			if edge_usedness == int(false):
				number_of_edges_unused_by_faces += 1
		if too_many_edges_in_faces:
			push_error("At least one face of the provided geometry had 5 or more edges, which is ",
				"not currently supported due to the complexity of created midpoint-banding ambiguities.")
		if number_of_edges_unused_by_faces > 0:
			push_warning(number_of_edges_unused_by_faces, " edges are unused by faces.")
		if faces_use_nonexistant_edges:
			push_error("At least one face of the provided geometry depended on unprovided edges.")
		if too_many_edges_in_faces or faces_use_nonexistant_edges:
			return []
	
	
	
	
	# {u} determine active midpoints
	# {u} determine midpoint loops by making active midpoint connection on every main vertex face
	
	
	return []

func get_polyhedron_errors(
	verts: Array[Vector3], 
	edges: Array[PackedByteArray], 
	faces: Array[PackedByteArray],
	max_face_gon_allowed: int = -1 #(use -1 for no limit)
	) -> Array[PackedStringArray]:
	
	var polyhedron_errors: Array[PackedStringArray] = [[],[]]
	
	if verts.size() > 256:
		polyhedron_errors[1].append("Too many vertices. (Limit is 256.)")
	if edges.size() > 256:
		polyhedron_errors[1].append("Too many edges. (Limit is 256.)")
	# (Faces don't currently have a reason to be limited.)
	
	if (verts.size() < 4):
		polyhedron_errors[1].append("Not enough vertices to constitute a 3 dimensional polyhedron. " +
			" (" + str(verts.size()) + "/4)")
	if (edges.size() < 6):
		polyhedron_errors[1].append("Not enough edges to constitute a 3 dimensional polyhedron. " +
			" (" + str(edges.size()) + "/6)")
	if (faces.size() < 4):
		polyhedron_errors[1].append("Not enough faces to constitute a 3 dimensional polyhedron."  +
			" (" + str(faces.size()) + "/4)")
	
	var bad_edges_count: int = 0
	for edge in edges:
		if edge.size() != 2:
			print("bad edge: ", edge, " size: ", edge.size())
			bad_edges_count += 1
	if bad_edges_count > 0:
		polyhedron_errors[1].append("Found " + str(bad_edges_count) + " instances of edges referencing a wrong number of vertices.")
	var bad_faces_count: int = 0
	for face in faces:
		if face.size() < 3:
			bad_faces_count += 1
	if bad_faces_count > 0:
		polyhedron_errors[1].append("Found " + str(bad_faces_count) + " instances of faces referencing too few vertices.")
	
	# Check for duplicate vertices, edges and faces.
	# (verts:)
	var duplicates_count: int = 0
	if verts.size() > 1:
		for index_a in range(0, verts.size() - 1):
			for index_b in range(index_a + 1, verts.size()):
				if verts[index_a] == verts[index_b]:
					duplicates_count += 1
		if duplicates_count > 0:
			polyhedron_errors[0].append("Found (roughly) " + str(duplicates_count) + " instances of duplicate vertices.")
	# (edges:)
	duplicates_count = 0
	if edges.size() > 1:
		var sorted_edge_a: PackedByteArray
		var sorted_edge_b: PackedByteArray
		for index_a in range(0, edges.size() - 1):
			for index_b in range(index_a + 1, edges.size()):
				sorted_edge_a = edges[index_a].duplicate()
				sorted_edge_a.sort()
				sorted_edge_b = edges[index_b].duplicate()
				sorted_edge_b.sort()
				if sorted_edge_a == sorted_edge_b:
					duplicates_count += 1
		if duplicates_count > 0:
			polyhedron_errors[0].append("Found (roughly) " + str(duplicates_count) + " instances of duplicate edges.")
	# (faces:)
	duplicates_count = 0
	if faces.size() > 1:
		var sorted_face_a: PackedByteArray = []
		var sorted_face_b: PackedByteArray = []
		for index_a in range(0, faces.size() - 1):
			for index_b in range(index_a + 1, faces.size()):
				sorted_face_a = faces[index_a].duplicate()
				sorted_face_a.sort()
				sorted_face_b = faces[index_b].duplicate()
				sorted_face_b.sort()
				if sorted_face_a == sorted_face_b:
					duplicates_count += 1
		if duplicates_count > 0:
			polyhedron_errors[0].append("Found (roughly) " + str(duplicates_count) + " instances of duplicate faces.")
	
	# Check whether any edges are left unused by all of the faces:
	var edges_used_states: PackedByteArray = []
	edges_used_states.resize(edges.size())
	edges_used_states.fill(int(false))
	for face in faces:
		for edge_index in face:
			edges_used_states[edge_index] = int(true)
	var edges_left_unused_by_faces: int = 0
	for state in edges_used_states:
		if state == int(false):
			edges_left_unused_by_faces += 1
	if edges_left_unused_by_faces > 0:
		polyhedron_errors[0].append(str(edges_left_unused_by_faces) + " edges were not used by any faces.")
	
	if not max_face_gon_allowed == -1:
		var highest_face_gon: int = 0
		for face in faces:
			if face.size() > highest_face_gon:
				highest_face_gon = face.size()
		if highest_face_gon > max_face_gon_allowed:
			polyhedron_errors[1].append("At least 1 face found referencing more than allowed number of edges. " + 
				"(at least one face referenced " + str(highest_face_gon) + " out of max allowed " + str(max_face_gon_allowed) + ".)")
	
	return polyhedron_errors
