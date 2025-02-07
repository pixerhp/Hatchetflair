@icon("res://assets/icons/godot_proj_icons/chunks_manager.png")
extends Node

signal chunk_manager_thread_ended

@onready var cm_node: Object = self

# Chunk data & data access:
var hzz_to_chunk_i: Dictionary = {}
var static_chunks: Array[WorldUtils.Chunk]
# !!! (Store groups of chunks which are used as dynamic/mobile here as well in the future.)

# Thread-related:
var mutex: Mutex
var semaphore: Semaphore
var cm_thread: Thread
var exit_thread: bool = false
# Threads data-exchange:
var in_instructions: Array = [] # main thread adds to it, cm thread reads from it and clears it.
var out_instructions: Array = [] # cm thread adds to it, main thread reads from it and clears it.

enum INSTRUCTION {
	SKIP, # skip this instruction, useful for skipping bad/incorrect instruction input.
	WAIT_FOR_MAIN_THREAD, # uses semaphore to pause this thread until the main thread continues it.
	IGNORE_PREVIOUS_INSTRUCTIONS, # when quitting/teleporting (etc,) prior chunk instructions may no longer be relavent.
	SAVE_ALL_LOADED_CHUNKS, # such as for autosaving, saving & quitting.
	#CLEAR_ALL_CHUNKS, # 
	PING_MAIN,
}
enum OUTSTRUCTION {
	WAITING_FOR_MAIN_THREAD, # !!! (NOT YET IMPLIMENTED RECIEVING-WISE ANYWHERE IN THE MAIN THREAD.)
	#ALL_LOADED_CHUNKS_SAVED,
	PING,
}

func _ready():
	mutex = Mutex.new()
	semaphore = Semaphore.new()
	exit_thread = false
	
	cm_thread = Thread.new()
	cm_thread.start(cm_thread_loop)
	
	#generate_temporary_testing_mesh()
	
	return

func _process(delta):
	# !!! process outstructions here (such as node tree accessing)
	
	if Globals.draw_debug_info_text:
		DebugDraw.add_text("")
		mutex.lock()
		DebugDraw.add_text("Static chunks stored in CM: " + str(static_chunks.size()))
		mutex.unlock()
	
	# !!! probably regularly give in-struction of player data (position, velocity) for chunk loading/unloading.
	
	return

#func generate_temporary_testing_mesh():
	## !!! Temporary experimental mesh stuff:
	#var mesh_instance_3d: MeshInstance3D = MeshInstance3D.new()
	#mesh_instance_3d.position = Vector3(0,0,0)
	#mesh_instance_3d.name = "0_0_0_mesh_1"
	#var array_mesh: ArrayMesh = ArrayMesh.new()
	#var surface_array: Array = []
	#surface_array.resize(Mesh.ARRAY_MAX)
	#
	## Try to have a mesh of two laterally adjacent cubes (no triangles needed where they touch,)
	## where one cube is metallic and the other isn't. 
	#var verts: PackedVector3Array = []
	#var uvs: PackedVector2Array = []
	#var normals: PackedVector3Array = []
	#var indices: PackedInt32Array = []
	#
	#
	#
	#
	#var rings = 50
	#var radial_segments = 50
	#var radius = 1
	#
	## Vertex indices.
	#var thisrow = 0
	#var prevrow = 0
	#var point = 0
#
	## Loop over rings.
	#for i in range(rings + 1):
		#var v = float(i) / rings
		#var w = sin(PI * v)
		#var y = cos(PI * v)
		#
		## Loop over segments in ring.
		#for j in range(radial_segments + 1):
			#var u = float(j) / radial_segments
			#var x = sin(u * PI * 2.0)
			#var z = cos(u * PI * 2.0)
			#var vert = Vector3(x * radius * w, y * radius, z * radius * w)
			#verts.append(vert)
			#normals.append(vert.normalized())
			#uvs.append(Vector2(u, v))
			#point += 1
			#
			## Create triangles in ring using indices.
			#if i > 0 and j > 0:
				#indices.append(prevrow + j - 1)
				#indices.append(prevrow + j)
				#indices.append(thisrow + j - 1)
				#
				#indices.append(prevrow + j)
				#indices.append(thisrow + j)
				#indices.append(thisrow + j - 1)
		#
		#prevrow = thisrow
		#thisrow = point
	#
	#
	#
	#surface_array[Mesh.ARRAY_VERTEX] = verts
	#surface_array[Mesh.ARRAY_TEX_UV] = uvs
	#surface_array[Mesh.ARRAY_NORMAL] = normals
	#surface_array[Mesh.ARRAY_INDEX] = indices
	#
	## No blendshapes, lods, or compression used.
	#array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	#
	## (For after the arraymesh is created:)
	#mesh_instance_3d.mesh = array_mesh
	#mesh_instance_3d.material_override = load("res://assets/render_materials/substance_shader_material.tres")
	#cm_node.add_child(mesh_instance_3d)

func cm_thread_loop():
	
	# !!! Temporary testing:
	static_chunks.append(WorldUtils.Chunk.new(Vector3i(0,0,0)))
	hzz_to_chunk_i[Vector3i(0,0,0)] = 0
	static_chunks[hzz_to_chunk_i[Vector3i(0,0,0)]].generate_natural_terrain()
	determine_chunk_occupiednesses(Vector3i(0,0,0))
	
	
	while true:
		mutex.lock()
		var do_exit_thread: bool = exit_thread
		mutex.unlock()
		if do_exit_thread:
			break
		
		process_incoming_instructions()
		
		# for loop for doing other chunk stuff autonomously after already following provided instructions?
			# (regular chunk loading/unloading/lod-modifying, etc.)
		
	return

func process_incoming_instructions():
	# Read the global in-instructions array:
	mutex.lock()
	var in_insts: Array = in_instructions.duplicate()
	in_instructions.clear()
	mutex.unlock()
	
	# Get a list of what types of instructions there are to execute:
	var inst_enums: PackedInt32Array = []
	for in_inst in in_insts: # player data and other instructions.
		match typeof(in_inst):
			TYPE_INT: # a basic lone-instruction without any additional data.
				inst_enums.append(in_inst)
			TYPE_ARRAY: # an instruction as the first element of an array containing associated data.
				if in_inst.is_empty():
					push_error("Empty in-instruction array.")
					inst_enums.append(INSTRUCTION.SKIP)
				if not typeof(in_inst[0]) == TYPE_INT:
					push_error("First element of in-instruction array was not an instruction-enum.")
					inst_enums.append(INSTRUCTION.SKIP)
				inst_enums.append(in_inst[0])
			_:
				push_error("In-instruction's intruction-enum not found.")
				inst_enums.append(INSTRUCTION.SKIP)
	
	# Check for an "IGNORE_PREVIOUS_INSTRUCTIONS" instruction, and modify the instructions list accordingly.
	var ignore_previous_insts_index: int = inst_enums.rfind(INSTRUCTION.IGNORE_PREVIOUS_INSTRUCTIONS)
	if ignore_previous_insts_index != -1:
		if inst_enums.size() == ignore_previous_insts_index + 1:
			inst_enums.clear()
			in_insts.clear()
		else:
			inst_enums.slice(ignore_previous_insts_index + 1)
			in_insts.slice(ignore_previous_insts_index + 1)
	
	# !!! using for testing fixing "IGNORE_PREVIOUS_INSTRUCTIONS" instruction not actually working.
	#if inst_enums.size() > 0:
		#print(inst_enums)
	
	# Execute the list of instructions:
	for i in inst_enums.size():
		match inst_enums[i]:
			INSTRUCTION.WAIT_FOR_MAIN_THREAD:
				mutex.lock()
				out_instructions.append(OUTSTRUCTION.WAITING_FOR_MAIN_THREAD)
				mutex.unlock()
				semaphore.wait()
			INSTRUCTION.PING_MAIN:
				mutex.lock()
				out_instructions.append(OUTSTRUCTION.PING)
				mutex.unlock()
			INSTRUCTION.SAVE_ALL_LOADED_CHUNKS:
				# !!! Add file saving functionality
				pass
			_:
				push_error("Unknown/unsupported instruction-enum: ", inst_enums[i])
				continue
	return

func refresh_hzz_to_chunk_i():
	hzz_to_chunk_i.clear()
	for i in static_chunks.size():
		hzz_to_chunk_i[static_chunks[i].ccoords] = i
	return

# !!! probably combine with determining all other determinables (e.g. opacs).
	# this way, surrounding chunk data doesn't need to be re-fetched for every determinable array.
# !!! later on, you could update this to have only some of the chunk's tps update this (with bitshift int.)
func determine_chunk_occupiednesses(ccoord: Vector3i) -> Error:
	if not hzz_to_chunk_i.has(ccoord):
		push_error(
			"Attempted to determine tile occupiednesses for a static chunk which presumably isn't loaded: ",
			ccoord,
		)
		return FAILED
	
	# All of the chunk's + immediately surrounding tile data needed for calculations.
	var tile_shapes: PackedByteArray = []
	var tile_subs: PackedInt32Array = []
	# Determined information to update the chunk's data with:
	var chunk_occs: PackedByteArray = []
	
	# !!! get data of all chunk tiles + sorrounding chunks' tps' tiles.
	
	# !!! go tile-by-tile, checking for each scenario that would affect occ.
	
	# !!! set the actual chunk's occs to the calculated chunk_occs
	
	return OK

# (Call with the main thread to make the cm thread stop waiting.)
func unpause_cm_thread():
	semaphore.post()

func _on_pausemenu_saveandquit_pressed():
	mutex.lock()
	in_instructions.append_array([
		INSTRUCTION.IGNORE_PREVIOUS_INSTRUCTIONS, 
		INSTRUCTION.SAVE_ALL_LOADED_CHUNKS,
		INSTRUCTION.PING_MAIN,
	])
	mutex.unlock()
	
	var is_cm_done: bool = false
	while true:
		mutex.lock()
		if out_instructions.has(OUTSTRUCTION.PING):
			is_cm_done = true
		mutex.unlock()
		if is_cm_done:
			break
		else:
			# Wait 1/60th of a second:
			await get_tree().create_timer(0.0166).timeout
	
	mutex.lock()
	exit_thread = true
	mutex.unlock()
	cm_thread.wait_to_finish()
	
	chunk_manager_thread_ended.emit()
