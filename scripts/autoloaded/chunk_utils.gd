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
	# !!! Change var to const (and thus access the values differently) once related GDScript bug is fixed.
	# The bug (issue 88753, also see 67873) causes const Array[PackedByteArray] to act unpredictable and crashy.
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
	# !!! Change var to const (and thus access the values differently) once related GDScript bug is fixed.
	# The bug (issue 88753, also see 67873) causes const Array[PackedByteArray] to act unpredictable and crashy.
	var edges: Array[PackedByteArray] = [
		[0,1], [0,2], [0,3], [0,4],
		[1,5], [1,6], [2,5], [3,6], [2,7], [3,8], [4,7], [4,8],
		[5,9], [6,9], [5,10], [6,11], [7,10], [8,11], [7,12], [8,12],
		[9,13], [10,13], [11,13], [12,13], 
	]
	var faces: Array[PackedByteArray] = [
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
	# Creative choice for how quad midpoint-banding ambiguities should be solved.
	# 0 = Bridge Offs; 1 = Bridge Ons;
	# 2 = Dynamic. Attempt to find a combination with flat bands, secondly prioritizing more/smaller bands;
	# 3 = Random !!! NOT IMPLIMENTED
	quad_ambiguity_style: int,
	) -> Array[PackedByteArray]:
	
	print("Generating triangle indices table (length: ", pow(2, verts.size()), ") for marched polyhedron with ", 
		verts.size(), " vertices, ", edges.size(), " edges and ", faces.size(), " faces... ",
		"(quad bridge type = ", quad_ambiguity_style, ")")
	
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
	
	var table_size: int = int(pow(2, verts.size()))
	var percentage_statement_interval: int = max(10, min(16000, int(float(table_size)/10.0)))
	var vertex_states: PackedByteArray = []
	vertex_states.resize(verts.size())
	var edge_mid_states: PackedByteArray = []
	edge_mid_states.resize(edges.size())
	var mid_conns: Array[PackedByteArray] = []
	var active_mids_in_face: PackedByteArray = []
	var face_off_verts: PackedByteArray = []
	var face_on_verts: PackedByteArray = []
	var quad_ambiguities_to_test: PackedInt32Array = [] # (stores face indices)
	var mid_bandlets: Array[PackedByteArray] = []
	var mid_conn_banding_context: Array = []
	var mid_bands: Array[PackedByteArray] = []
	for combination in table_size:
		# Occasional percentage completion text:
		if (combination % percentage_statement_interval) == 0:
			print(100 * (float(combination) / pow(2, verts.size())), "% completed... (", combination, "/", table_size, ")")
		
		for index in verts.size():
			vertex_states[index] = (combination >> index) & 1
		for index in edges.size():
			edge_mid_states[index] = int(vertex_states[edges[index][0]] != vertex_states[edges[index][1]])
		
		mid_conns = []
		quad_ambiguities_to_test = []
		for face_index in faces.size():
			active_mids_in_face = []
			face_off_verts = []
			face_on_verts = []
			for edge_index in faces[face_index]:
				if edge_mid_states[edge_index] == int(true):
					active_mids_in_face.append(edge_index)
				if (quad_ambiguity_style == 0) or (quad_ambiguity_style == 1):
					for vert_index in edges[edge_index]:
						if (not face_off_verts.has(vert_index)) and (not face_on_verts.has(vert_index)):
							if vertex_states[vert_index] == int(false):
								face_off_verts.append(vert_index)
							else:
								face_on_verts.append(vert_index)
			match active_mids_in_face.size():
				0:
					continue
				2:
					mid_conns.append(active_mids_in_face.duplicate())
				4:
					match quad_ambiguity_style:
						0:
							mid_conns.append(PackedByteArray([]))
							mid_conns.append(PackedByteArray([]))
							for edge_index in active_mids_in_face:
								if (edges[edge_index][0] == face_on_verts[0]) or (edges[edge_index][1] == face_on_verts[0]):
									mid_conns[-2].append(edge_index)
								elif (edges[edge_index][0] == face_on_verts[1]) or (edges[edge_index][1] == face_on_verts[1]):
									mid_conns[-1].append(edge_index)
								else:
									push_error("Bad situation; off-verts: ", face_off_verts, " on verts: ", face_on_verts)
									return []
						1:
							mid_conns.append(PackedByteArray([]))
							mid_conns.append(PackedByteArray([]))
							for edge_index in active_mids_in_face:
								if (edges[edge_index][0] == face_off_verts[0]) or (edges[edge_index][1] == face_off_verts[0]):
									mid_conns[-2].append(edge_index)
								elif (edges[edge_index][0] == face_off_verts[1]) or (edges[edge_index][1] == face_off_verts[1]):
									mid_conns[-1].append(edge_index)
								else:
									push_error("Bad situation; off-verts: ", face_off_verts, " on verts: ", face_on_verts)
									return []
						2:
							quad_ambiguities_to_test.append(face_index)
						_:
							push_error("Unsupported quad midpoint-banding ambiguity solution style: ", quad_ambiguity_style)
							return []
					
					if not (mid_conns[-2].size() == 2) and (mid_conns[-1].size() == 2):
						push_error("Fix your code, you must've done something wrong.",
						" Ambiguity style: ", quad_ambiguity_style,
						" Combination: ", combination, 
						" Face off verts and on verts: ", face_off_verts, face_on_verts,
						" Mid' conn's: ", mid_conns[-2], mid_conns[-1])
				_:
					push_error("Unsupported number of active midpoints in single face: ", active_mids_in_face)
		
		# Form midpoint bands out of midpoint connections.
		mid_bandlets = []
		mid_bands = []
		match quad_ambiguity_style:
			0, 1:
				for conn_index in mid_conns.size():
					if (not mid_conns[conn_index].size() == 2) or (mid_conns[conn_index][0] == mid_conns[conn_index][1]):
						push_error("Bad midpoint connection. Connection in question: ", mid_conns[conn_index])
						return []
					
					# INFORMATION NEEDED:
					# list of which bandlets conn side 1 connects to the end of (and whether it's front vs back of each)
					# list of which bandlets conn side 2 connects to the end of (and whether it's front vs back of each)
					
					# Get a list of which bandlets each side of the conn' connect to, and which side of the bandlet they do at.
					mid_conn_banding_context = [[], []]
					for bandlet_index in mid_bandlets.size():
						if mid_conns[conn_index][0] == mid_bandlets[bandlet_index][0]:
							mid_conn_banding_context[0].append([bandlet_index, 0])
						if mid_conns[conn_index][0] == mid_bandlets[bandlet_index][mid_bandlets[bandlet_index].size() - 1]:
							mid_conn_banding_context[0].append([bandlet_index, 1])
						if mid_conns[conn_index][1] == mid_bandlets[bandlet_index][0]:
							mid_conn_banding_context[1].append([bandlet_index, 0])
						if mid_conns[conn_index][1] == mid_bandlets[bandlet_index][mid_bandlets[bandlet_index].size() - 1]:
							mid_conn_banding_context[1].append([bandlet_index, 1])
					
					# (untested but probably doesn't need to be) if neither connection side is found on any existing bandlets, create a new bandlet for it.
					if mid_conn_banding_context == [[], []]:
						mid_bandlets.append_array(mid_conns[conn_index])
						continue
					
					# (untested) if only one side connects to an existing bandlet: add onto that bandlet.
					if (mid_conn_banding_context[0].size() == 1) and (mid_conn_banding_context[1].size() == 0):
						if mid_conn_banding_context[0][1] == 0:
							mid_bandlets[mid_conn_banding_context[0][0]].insert(0, mid_conns[conn_index][1])
						else:
							mid_bandlets[mid_conn_banding_context[0][0]].append(mid_conns[conn_index][1])
						continue
					if (mid_conn_banding_context[0].size() == 0) and (mid_conn_banding_context[1].size() == 1):
						if mid_conn_banding_context[1][1] == 0:
							mid_bandlets[mid_conn_banding_context[1][0]].insert(0, mid_conns[conn_index][0])
						else:
							mid_bandlets[mid_conn_banding_context[1][0]].append(mid_conns[conn_index][0])
						continue
					
					# {u} if both connection sides are found on the ends of an existing bandlet, then that bandlet is now a complete and no longer needs to be checked.
					
					# {u} if each side connects to two different existing bandlets, connect the bandlets into one bigger bandlet.
					
					# {u} if any other situation (fits into 3+ bandlets, etc,) push an error.
					
				pass
			2:
				# !!!{u} 
				# probably first form longer connections out of non-quad-ambiguities, and then deal with them
				#for quad_amb_combination in int(pow(2, quad_ambiguities_to_test.size())):
					## something like this next here?:
					##vertex_states[index] = (combination >> index) & 1
					#pass
				pass
			_:
				pass
		
		
		# {u} form midpoint bands out of midpoint connections
		for conn in mid_conns:
			
			pass
		
		# {u} determine whether which if any midpoint bands have triangulation ambiguities.
		# (AKA whether all of the midpoints in a band fall along a plane.)
		
		# {u} triangulate midpoint bands+
		
		# {u} orient the triangles correctly
		# PLAN IDEA:
		# In a similar way as how the “are all of the vector3s coplanar” function works, 
		# by not having the abs(), check whether the distance from the trangle to a vector3 
		# is facing outwards from is positive or negative, you’ll know whether the triangle 
		# needs to be flipped based on that. (A distance of 0 means you picked a bad 
		# outwards-from point since it’s coplanar, and you need to revise how it’s picked.)
		
	
	print("100% completed!")
	# !!! (remember to make this return the completed tri indices table.)
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
	
	# Check whether the edges in a face actually connect to eachother in the order given:
	var n_of_disconnected_faces: int = 0
	var face_edge_indices: PackedByteArray = []
	for face in faces:
		face_edge_indices = []
		for index in face.size():
			if edges[face[index]].size() != 2:
				n_of_disconnected_faces += 1
				break
			if (
				(
					edges[face[(index-1)%face.size()]].has(edges[face[index]][0]) and 
					edges[face[(index+1)%face.size()]].has(edges[face[index]][1])
				) or
				(
					edges[face[(index-1)%face.size()]].has(edges[face[index]][1]) and 
					edges[face[(index+1)%face.size()]].has(edges[face[index]][0])
				)
			):
				continue
			else:
				n_of_disconnected_faces += 1
				break
	if n_of_disconnected_faces > 0:
		polyhedron_errors[1].append("Found " + str(n_of_disconnected_faces) + " instances of " + 
			"faces whose edges do not actually connect together in the given order.")
	
	# Determine whether the vertices that make up a face are actually coplanar (the face is flat.)
	var vertices_in_face: Array[Vector3]
	for face in faces:
		vertices_in_face = []
		for edge_index in face:
			for vertex_index in edges[edge_index]:
				if not vertices_in_face.has(verts[vertex_index]):
					vertices_in_face.append(verts[vertex_index])
		if not are_vector3s_coplanar(vertices_in_face, 0.0001):
			polyhedron_errors[1].append("Found that at least one face is not actually flat.")
			break
	
	# Check whether face polygons have more vertices than the allowed amount.
	if not max_face_gon_allowed == -1:
		var highest_face_gon: int = 0
		for face in faces:
			if face.size() > highest_face_gon:
				highest_face_gon = face.size()
		if highest_face_gon > max_face_gon_allowed:
			polyhedron_errors[1].append("At least 1 face found referencing more than allowed number of edges. " + 
				"(at least one face referenced " + str(highest_face_gon) + " out of max allowed " + str(max_face_gon_allowed) + ".)")
	
	return polyhedron_errors

func are_vector3s_coplanar(points: Array[Vector3], tolerance: float) -> bool:
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
