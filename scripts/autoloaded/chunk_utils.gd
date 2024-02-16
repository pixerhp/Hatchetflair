extends Node

# standard: (using godot xyz)
# for (-y -> +y):
# for (-z -> +z):
# for (-x -> +x):


# (a is unfinished...)
const rhomdomarch_indices_a: Array = []
# (b1 is FINISHED)
const rhomdomarch_indices_b1: Array[PackedByteArray] = [
	[],
	[0,3,2, 0,2,1, 0,1,3, 1,2,3],
	[],
	[1,2,3],
	[],
	[0,3,2],
	[],
	[],
	[],
	[0,1,3],
	[],
	[],
	[],
	[],
	[0,1,2],
	[],
	[],
	[0,2,1],
	[],
	[],
	[],
	[],
	[0,3,1],
	[],
	[],
	[],
	[0,2,3],
	[],
	[1,3,2],
	[],
	[0,2,3, 0,1,2, 0,3,1, 1,3,2],
	[],
]
# (b2 is unfinished...)
const rhomdomarch_indices_b2: Array = []


var a_neighbors: Array[PackedByteArray] = [
	
]
var a_mergable: Array[PackedByteArray] = [
	
]



func get_unoriented_marched_vertex_indices(
	# number of addtional vertices that the focused vertex is connected to.
	connections: int, 
	# lists of which connected vertices are considered 'neighbors' to other connected vertices.
	# The first list is the neighbors of the first connected vertex, the second list is for the second, etc.
	# Numbers in lists represent an index of a connections vertex, [3,...] refers to the fourth listed connection's vertex.
	neighbors: Array[PackedByteArray], 
	# list of where 4 neighboring vertices' midpoints fall along a plane (creating a quadragon.)
	# List them in any order which goes around the quadragon in a loop without intersecting.
	# [0,1,2,3] specifies to a quadragon made by the midpoints of the first 4 connections.
	quads: Array[PackedByteArray]
) -> Array[PackedByteArray]: # Array of arrays of 3 idices each, representing which connection midpoint triangles exist.
	if neighbors.size() != connections:
		push_error("Bad parameter input, neighbors array size does not equal number of connections.")
		return []
	
	# Prepare the output array, and return if bad input.
	var output_indices: Array[PackedByteArray] = []
	output_indices.resize(pow(2, connections + 1))
	if connections < 3:
		push_warning("Not enough connections (only ", connections, ") to be able to form a triangle.")
		return output_indices
	
	var midpoint_states: PackedByteArray = []
	midpoint_states.resize(connections)
	var triangle: PackedByteArray = []
	var triangles: Array[PackedByteArray] = []
	var active_midpoint_group: PackedByteArray = []
	
	# the focus vertex toggles every single combination, 
	# the first connection vertex every second combination, 
	# the second connection vertex every fourth combination, etc.
	for combination in output_indices.size():
		# Get the on/off state of each midpoint for the current combination:
		for i in midpoint_states.size():
			# XORs the state of the focus vertex and the state of a connection vertex.
			midpoint_states[i] = ((combination >> 0) & 1) ^ ((combination >> (i + 1)) & 1) # Note: ^ != pow()
		
		# (u) Form all possible midpoint triangles via used midpoints and connection neighbors:
		for midpoint_index in midpoint_states.size():
			if midpoint_states[midpoint_index] == 0:
				continue
			else:
				active_midpoint_group = [midpoint_index]
				for neighbor in neighbors[midpoint_index]:
					if midpoint_states[neighbor] == 1:
						active_midpoint_group.append(neighbor)
				#triangle = 
		
		# (u) Merge potentially overlapping triangles and form better ones as replacements.*
		# (*only works for fixing quadragons.)
		
		# (u) 
		
		
	
	
	
	
	return output_indices
