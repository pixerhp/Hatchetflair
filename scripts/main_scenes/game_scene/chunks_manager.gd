@icon("res://assets/icons/godot_proj_icons/chunks_manager.png")
extends Node

signal chunks_manager_is_ready
signal chunks_manager_thread_ended

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

# Local understanding of outside data, only accessed/used by the chunks manager thread:
var player_ccoords: Vector3i = Vector3i(0,0,0) # in hzz
var player_velocity: Vector3 = Vector3(0,0,0) # in hzz

# Work quota functionality:
var work_quota: int = 20
var pause_work_quota: bool = false
const WORK_QUOTA_MIN: int = 1
const WORK_QUOTA_MAX: int = 200
# Used for dynamically adjusting the work quota number:
var updates_within_last_loop: int = 0
	# For counting the number of unique data updates contained within the last in-instructions read.
var loops_since_last_update: int = 0
	# For counting the number of thread while loops since the last data update from the main thread.


enum { # instruction sets:
	INCOMING,
	OUTGOING,
}
enum IN_INST { # list of incoming-type instructions:
	SKIP, # Doesn't do anything, useful for replacing a bad incoming instruction input.
	IGNORE_THE_FOLLOWING_INSTRUCTIONS, # Makes this and all following instructions array elements be ignored.
		# (Takes priority over IGNORE_THE_PREVIOUS_INSTRUCTIONS.)
	IGNORE_THE_PREVIOUS_INSTRUCTIONS, # Makes this and all prior instructions array elements be ignored.
	WAIT_FOR_MAIN_THREAD, # Uses the semaphore to pause this thread until the main thread manually continues it.
	GIVE_MAIN_THREAD_A_SIGNAL_TO_EMIT,
	REGULAR_DATA_UPDATE, # Recieved every main thread frame; has delta, player positions, etc.
	SAVE_ALL_LOADED_CHUNKS, # NYI, useful for autosaving + saving & quitting.
	#CLEAR_ALL_CHUNKS, # 
}
enum OUT_INST { # list of outgoing-type instructions:
	SKIP, # Doesn't do anything, useful for replacing a bad outgoing instruction input.
	IGNORE_THE_FOLLOWING_INSTRUCTIONS, # Makes this and all following instructions array elements be ignored.
		# (Takes priority over IGNORE_THE_PREVIOUS_INSTRUCTIONS.)
	IGNORE_THE_PREVIOUS_INSTRUCTIONS, # Makes this and all prior instruction array elements be ignored.
	WAITING_FOR_MAIN_THREAD,
	EMIT_RECIEVED_SIGNAL,
	#ALL_LOADED_CHUNKS_SAVED,
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
	process_instructions(OUTGOING)
	
	if Globals.draw_debug_info_text:
		DebugDraw.add_text("")
		mutex.lock()
		DebugDraw.add_text("Static chunks stored in CM: " + str(static_chunks.size()))
		mutex.unlock()
	
	# !!! later send player's ccoords (which account for my_origin_offset) and velocity.
	mutex.lock()
	in_instructions.append([
		IN_INST.REGULAR_DATA_UPDATE, 
		Vector3i(0,0,0), # player chunk-coords location.
		Vector3(0,0,0), # player velocity.
	])
	mutex.unlock()
	
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
	
	
	
	# !!! Temporary for testing:
	static_chunks.append(WorldUtils.Chunk.new(Vector3i(0,0,0)))
	hzz_to_chunk_i[Vector3i(0,0,0)] = 0
	static_chunks[hzz_to_chunk_i[Vector3i(0,0,0)]].generate_natural_terrain()
	determine_chunk_occupiednesses(Vector3i(0,0,0))
	
	
	
	loops_since_last_update = 0
	
	var do_exit_thread: bool = false
	var should_do_quota: bool = true
	while true:
		mutex.lock()
		do_exit_thread = exit_thread
		should_do_quota = not pause_work_quota
		mutex.unlock()
		
		if do_exit_thread:
			break
		
		updates_within_last_loop = 0
		loops_since_last_update += 1
		
		process_instructions(INCOMING)
		
		if should_do_quota:
			adjust_work_quota_size()
			do_work_quota()
	
	# If the while loop is broken out of:
	return

func process_instructions(instructions_set: int) -> Error:
	# Read and then clear the associated instructions array in a thread-safe way:
	var instructions: Array = []
	match instructions_set:
		INCOMING:
			mutex.lock()
			instructions = in_instructions.duplicate()
			in_instructions.clear()
			mutex.unlock()
		OUTGOING:
			mutex.lock()
			instructions = out_instructions.duplicate()
			out_instructions.clear()
			mutex.unlock()
		_:
			push_error(
				"Bad instruction-set input (neither incoming nor outgoing,) was: ", 
				instructions_set,
			)
			return FAILED
	
	# The rest of this function can be skipped if there are no instructions.
	if instructions.is_empty():
		return OK
	
	# Create a list of what kind of instruction (enum value) each element of the instructions array is:
	# (bad instructions will be replaced with the "SKIP" instruction.)
	var inst_enums: PackedInt32Array = []
	for i in instructions.size():
		match typeof(instructions[i]):
			TYPE_INT: # a simple lone instruction enum without any additional data.
				inst_enums.append(instructions[i])
			TYPE_ARRAY: # an array with various instruction-associated data, beginning with the instruction enum.
				if instructions[i].is_empty():
					push_error("Instructions entry is an empty array.")
					match instructions_set:
						INCOMING:
							inst_enums.append(IN_INST.SKIP)
						OUTGOING:
							inst_enums.append(OUT_INST.SKIP)
					continue
				elif not typeof(instructions[i][0]) == TYPE_INT:
					push_error("First element of instructions array was not an instruction enum.")
					match instructions_set:
						INCOMING:
							inst_enums.append(IN_INST.SKIP)
						OUTGOING:
							inst_enums.append(OUT_INST.SKIP)
					continue
				else: # the array format is OK.
					inst_enums.append(instructions[i][0])
					continue
			_:
				push_error("Instruction format not supported, its instruction enum was not found.")
				match instructions_set:
					INCOMING:
						inst_enums.append(IN_INST.SKIP)
					OUTGOING:
						inst_enums.append(OUT_INST.SKIP)
				continue
	
	var ignorance_index: int = -1
	
	# Check for a (the first) "IGNORE_THE_FOLLOWING_INSTRUCTIONS" instruction, and do accordingly.
	match instructions_set:
		INCOMING:
			ignorance_index = inst_enums.find(IN_INST.IGNORE_THE_FOLLOWING_INSTRUCTIONS)
		OUTGOING:
			ignorance_index = inst_enums.find(OUT_INST.IGNORE_THE_FOLLOWING_INSTRUCTIONS)
	if ignorance_index != -1:
		if ignorance_index == 0:
			# If the first instruction states to ignore all following instructions, then there's nothing to execute.
			return OK
		else:
			inst_enums = inst_enums.slice(0, ignorance_index)
			instructions = instructions.slice(0, ignorance_index)
	
	# Check for a (the last) "IGNORE_THE_PREVIOUS_INSTRUCTIONS" instruction, and do accordingly.
	match instructions_set:
		INCOMING:
			ignorance_index = inst_enums.rfind(IN_INST.IGNORE_THE_PREVIOUS_INSTRUCTIONS)
		OUTGOING:
			ignorance_index = inst_enums.rfind(OUT_INST.IGNORE_THE_PREVIOUS_INSTRUCTIONS)
	if ignorance_index != -1:
		if ignorance_index + 1 == inst_enums.size():
			# If the last instruction states to ignore all previous instructions, then there's nothing to execute.
			return OK
		else:
			inst_enums = inst_enums.slice(ignorance_index + 1)
			instructions = instructions.slice(ignorance_index + 1)
	
	# Execute the finalized list of instructions, in order of first to last:
	match instructions_set:
		INCOMING:
			for i in inst_enums.size():
				match inst_enums[i]:
					IN_INST.SKIP:
						continue
					IN_INST.WAIT_FOR_MAIN_THREAD:
						mutex.lock()
						out_instructions.append(OUT_INST.WAITING_FOR_MAIN_THREAD)
						mutex.unlock()
						semaphore.wait()
						continue
					IN_INST.GIVE_MAIN_THREAD_A_SIGNAL_TO_EMIT:
						if typeof(instructions[i][1]) == TYPE_SIGNAL:
							mutex.lock()
							out_instructions.append([OUT_INST.EMIT_RECIEVED_SIGNAL, instructions[i][1]])
							mutex.unlock()
						else:
							push_error("Expected associated Signal type.")
						continue
					IN_INST.REGULAR_DATA_UPDATE:
						updates_within_last_loop += 1
						loops_since_last_update = 0
						player_ccoords = instructions[i][1]
						player_velocity = instructions[i][2]
						continue
					IN_INST.SAVE_ALL_LOADED_CHUNKS:
						# !!! Add file saving functionality later!
						push_warning("(The functionality of saving chunk data to files has not yet been implimented.)")
						continue
					_:
						push_error("Unknown/unsupported incoming-instruction enum: ", inst_enums[i])
						continue
		OUTGOING:
			for i in inst_enums.size():
				match inst_enums[i]:
					OUT_INST.SKIP:
						continue
					OUT_INST.EMIT_RECIEVED_SIGNAL:
						if typeof(instructions[i][1]) == TYPE_SIGNAL:
							instructions[i][1].emit()
						else:
							push_error("Expected associated Signal type.")
						continue
					_:
						push_error("Unknown/unsupported outgoing-instruction enum: ", inst_enums[i])
						continue
	
	return OK

func adjust_work_quota_size():
	# Prevents weird should-be-impossible values (such as from int overflow.)
	if updates_within_last_loop < 0:
		updates_within_last_loop = 0
	if loops_since_last_update < 0:
		loops_since_last_update = 0
	
	# Adjust work quota:
	match loops_since_last_update:
		0: # Just recieved a data update this loop.
			match updates_within_last_loop:
				0:
					push_error("Anomolous impossible contradiction, ",
					"just received an update but 0 updates this loop.")
				1: # The CM thread is about the same speed as the main thread.
					pass
				2: # The CM thread may be slightly slow.
					work_quota -= 1
				_: # The CM thread is substantially too slow.
					work_quota = roundi(float(work_quota) / (float(updates_within_last_loop) - 1.5))
		1: # The CM thread may be slightly fast.
			work_quota += 1
		2: # The CM thread is at least twice as fast as the main thread.
			work_quota = roundi(float(work_quota) * 1.5)
		_: # Avoid compounding work-increases in case the main thread is just experiencing a lag spike.
			pass
	
	# Ensure that the work quota doesn't exceed its allowed range:
	if work_quota < WORK_QUOTA_MIN:
		work_quota = WORK_QUOTA_MIN
		return
	if work_quota > WORK_QUOTA_MAX:
		work_quota = WORK_QUOTA_MAX
		return
	return

func do_work_quota():
	var quota_remaining: int = work_quota
	
	# !!! code work quota things to do, like loading/unloading/re-lod-meshing chunks
	# !!! each thing done reduces quota_remaining, usually by 1 (but can be more for known expensive things.)
	
	
	# !!! pre while loop stuff which is always done, 
		# like ensuring the chunks immediately surrounding the player are loaded.
	
	#while quota_remaining > 0:
		#pass
	
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
	
	# For all of the chunk's + immediately surrounding tile data needed for calculations.
	var tile_shapes: PackedByteArray = []
	var tile_subs: PackedInt32Array = []
	# For generated new data which will replace the chunk's outdated data:
	var chunk_occs: PackedByteArray = []
	
	
	#ensure_load_static_chunk_data()
	
	# !!! get data of all chunk tiles + sorrounding chunks' tps' tiles.
	
	# !!! go tile-by-tile, checking for each scenario that would affect occ.
	
	# !!! set the actual chunk's occs to the calculated chunk_occs
	
	return OK

# Ensures that certain chunks (specifically certain terrain pieces) either are or become loaded.
func ensure_chunk_tps_loaded(ccoords: Vector3i, tps_bitstates: PackedByteArray):
	var tps_to_load: PackedByteArray = determine_which_chunk_tps_need_loading(ccoords, tps_bitstates, true)
	if tps_to_load == PackedByteArray([0,0,0,0,0,0,0,0]):
		return
	else:
		load_static_chunk_data(ccoords, tps_to_load)

# (Note: If only need to know whether *all* required chunk tps are loaded, then this func is faster for that.)
func is_chunk_tps_loaded(
	ccoords: Vector3i, 
	required_tps: PackedByteArray, 
	ignore_unloaded_if_atm: bool = true,
) -> bool:
	if not hzz_to_chunk_i.has(ccoords):
		return false
	
	var tps_states: PackedByteArray = static_chunks[hzz_to_chunk_i[ccoords]].tp_is_loaded_bitstates.duplicate()
	if ignore_unloaded_if_atm:
		for i in 8:
			tps_states[i] |= static_chunks[hzz_to_chunk_i[ccoords]].tp_is_atm_bitstates[i]
	
	for i in 8:
		if (~ ((~ required_tps[i]) | (required_tps[i] & tps_states[i]))) == 0b00000000:
			continue
		else:
			return false
	
	return true

func determine_which_chunk_tps_need_loading(
	ccoords: Vector3i, 
	required_tps: PackedByteArray, 
	ignore_unloaded_if_atm: bool = true,
) -> PackedByteArray:
	if not hzz_to_chunk_i.has(ccoords):
		# The entire chunk isn't loaded, so inherently all of the required tps will need to be loaded.
		return required_tps
	
	var result: PackedByteArray = []
	result.resize(8)
	var tps_states: PackedByteArray = static_chunks[hzz_to_chunk_i[ccoords]].tp_is_loaded_bitstates.duplicate()
	if ignore_unloaded_if_atm:
		for i in 8:
			tps_states[i] |= static_chunks[hzz_to_chunk_i[ccoords]].tp_is_atm_bitstates[i]
	
	for i in 8:
		result[i] = required_tps[i] & (~ tps_states[i])
	return result

func load_static_chunk_data(
	ccoords: Vector3i,
	required_tps: PackedByteArray = [255,255,255,255,255,255,255,255],
	# !!! terrain objects, structures, etc?
) -> Error:
	if not hzz_to_chunk_i.has(ccoords):
		static_chunks.append(WorldUtils.Chunk.new(ccoords))
		hzz_to_chunk_i[ccoords] = static_chunks.size() - 1
	
	# !!! see if requested chunk data exists stored in files and load it if it does.
	
	# !!! for any terrrain data which was requested but isn't stored, generate it from scratch.
	
	return OK

func unload_static_chunk_data(ccoords: Vector3i) -> Error:
	if not hzz_to_chunk_i.has(ccoords):
		refresh_hzz_to_chunk_i()
		if hzz_to_chunk_i.has(ccoords):
			push_warning("hzz_to_chunk_i was originally found to be inaccurate.")
		else:
			push_error("No loaded static chunk with specified ccoords exists.")
			return FAILED
	
	# !!! Save all of the chunk to files.
	
	# Remove the chunk object and its associated data from RAM:
	static_chunks.remove_at(hzz_to_chunk_i[ccoords])
	refresh_hzz_to_chunk_i()
	
	return OK

# (Call with the main thread to make the cm thread stop waiting.)
func unpause_cm_thread():
	semaphore.post()

func _on_pausemenu_saveandquit_pressed():
	mutex.lock()
	in_instructions.append_array([
		IN_INST.IGNORE_THE_PREVIOUS_INSTRUCTIONS, 
		IN_INST.SAVE_ALL_LOADED_CHUNKS,
		[IN_INST.GIVE_MAIN_THREAD_A_SIGNAL_TO_EMIT, chunks_manager_is_ready],
		IN_INST.IGNORE_THE_FOLLOWING_INSTRUCTIONS,
	])
	mutex.unlock()
	
	await chunks_manager_is_ready
	
	mutex.lock()
	exit_thread = true
	mutex.unlock()
	cm_thread.wait_to_finish()
	
	chunks_manager_thread_ended.emit()
