@icon("res://assets/icons/project_icons/chunks_manager.png")
extends Node

signal chunks_manager_is_ready
signal chunks_manager_thread_ended

@onready var cm_node: Object = self

# Chunk data & associated:
var sc: WorldUtils.StaticChunksGroup = WorldUtils.StaticChunksGroup.new() # (static chunks group.)
var mcg: Array[WorldUtils.MobileChunksGroup] = [] # (mobile chunks groups.)
var mcg_id_to_i: Dictionary = {}
func refresh_mcg_id_to_i():
	mcg_id_to_i.clear()
	for i in mcg.size():
		mcg_id_to_i[mcg[i].identifier] = i
	return

# Thread-related:
var mutex: Mutex
var semaphore: Semaphore
var cm_thread: Thread
var exit_thread: bool = false
# Threads data-exchange arrays:
var in_instructions: Array = [] # main thread adds to it, cm thread reads from it and clears it.
var out_instructions: Array = [] # cm thread adds to it, main thread reads from it and clears it.

# Local cache of main thread / node tree data for use by the cm thread, updated each exchange:
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


enum INST_SET {
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
	process_instructions(INST_SET.OUTGOING)
	
	if Globals.draw_debug_info_text:
		DebugDraw.add_text("")
		mutex.lock()
		DebugDraw.add_text("Static chunks stored in CM: " + str(sc.chunks.size()))
		mutex.unlock()
	
	# !!! later send player's ccoords (which account for origin offset) and velocity.
	mutex.lock()
	in_instructions.append([
		IN_INST.REGULAR_DATA_UPDATE, 
		Vector3i(0,0,0), # player chunk-coords location.
		Vector3(0,0,0), # player velocity.
	])
	mutex.unlock()
	
	return

# !!! impermanent, eventually delete when no longer needed for reference/testing:
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
	randomize()
	
	
	## !!! Temporary for testing:
	#sc.chunks.append(WorldUtils.Chunk.new(-1, Vector3i(0,0,0)))
	#sc.cc_to_i[Vector3i(0,0,0)] = 0
	#sc.chunks[sc.cc_to_i[Vector3i(0,0,0)]].generate_natural_terrain()
	#calculate_chunk_determinables(Vector3i(0,0,0), true, true, true, true)
	
	
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
		
		process_instructions(INST_SET.INCOMING)
		
		if should_do_quota:
			adjust_work_quota_size()
			do_work_quota()
	
	# If the while loop is broken out of:
	return

func process_instructions(instructions_set: int) -> Error:
	# Read and then clear the associated instructions array in a thread-safe way:
	var instructions: Array = []
	match instructions_set:
		INST_SET.INCOMING:
			mutex.lock()
			instructions = in_instructions.duplicate()
			in_instructions.clear()
			mutex.unlock()
		INST_SET.OUTGOING:
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
						INST_SET.INCOMING:
							inst_enums.append(IN_INST.SKIP)
						INST_SET.OUTGOING:
							inst_enums.append(OUT_INST.SKIP)
					continue
				elif not typeof(instructions[i][0]) == TYPE_INT:
					push_error("First element of instructions array was not an instruction enum.")
					match instructions_set:
						INST_SET.INCOMING:
							inst_enums.append(IN_INST.SKIP)
						INST_SET.OUTGOING:
							inst_enums.append(OUT_INST.SKIP)
					continue
				else: # the array format is OK.
					inst_enums.append(instructions[i][0])
					continue
			_:
				push_error("Instruction format not supported, its instruction enum was not found.")
				match instructions_set:
					INST_SET.INCOMING:
						inst_enums.append(IN_INST.SKIP)
					INST_SET.OUTGOING:
						inst_enums.append(OUT_INST.SKIP)
				continue
	
	var ignorance_index: int = -1
	
	# Check for a (the first) "IGNORE_THE_FOLLOWING_INSTRUCTIONS" instruction, and do accordingly.
	match instructions_set:
		INST_SET.INCOMING:
			ignorance_index = inst_enums.find(IN_INST.IGNORE_THE_FOLLOWING_INSTRUCTIONS)
		INST_SET.OUTGOING:
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
		INST_SET.INCOMING:
			ignorance_index = inst_enums.rfind(IN_INST.IGNORE_THE_PREVIOUS_INSTRUCTIONS)
		INST_SET.OUTGOING:
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
		INST_SET.INCOMING:
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
						push_warning("(Saving chunk data to files functionality has not yet been implimented.)")
						continue
					_:
						push_error("Unknown/unsupported incoming-instruction enum: ", inst_enums[i])
						continue
		INST_SET.OUTGOING:
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

# (Call with the main thread to make the cm thread stop waiting.)
func unpause_cm_thread():
	semaphore.post()

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
					pass # (nothing needs to be done.)
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
	
	# Ensure that the work quota stays within its allowed range:
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


# !!! revise this, it should probably go into ChunksGroup class and call FileManager for file loading.
# !!! eventually revise to work with calculating determinables for specific TPs 
# rather than always the whole chunk.
func calculate_chunk_determinables(
	ccoords: Vector3i, 
	calc_occs: bool, calc_flows: bool, calc_stabs: bool, calc_fopaqs: bool,
) -> Error:
	if (not calc_occs) and (not calc_flows) and (not calc_stabs) and (not calc_fopaqs):
		push_warning("No determinable types requested to be calculated.")
		return OK
	if not sc.cc_to_i.has(ccoords):
		push_error(
			"Attempted to determine tile occupiednesses for an unloaded static chunk: ", ccoords)
		return FAILED
	
	# Ensure all required data for calculations is stored in RAM:
	for i in (3**3):
		pass
		#ensure_chunk_tps_loaded(
			#ccoords + Vector3i(posmod(i/9, 3) - 1, posmod(i/3, 3) - 1, posmod(i, 3) - 1),
			#WorldUtils.CHUNK_VICINITY_TP_BITSTATES[i],
		#)
	
	
	# !!! get data of all chunk tiles + sorrounding chunks' tps' tiles.
	
	# !!! go tile-by-tile, checking for each scenario that would affect occ.
	
	# !!! set the actual chunk's occs to the calculated chunk_occs
	
	return OK


# !!! all below still need to be assessed for where they should be revised into:


# (Note: If only need to know whether *all* required chunk tps are loaded, then this func is faster for that.)
func is_chunk_tps_loaded(
	ccoords: Vector3i, 
	required_tps: PackedByteArray, 
	ignore_unloaded_if_atm: bool = true,
) -> bool:
	if not sc.cc_to_i.has(ccoords):
		return false
	
	var tps_states: PackedByteArray = sc.chunks[sc.cc_to_i[ccoords]].tp_is_loaded_bitstates.duplicate()
	if ignore_unloaded_if_atm:
		for i in 8:
			tps_states[i] |= sc.chunks[sc.cc_to_i[ccoords]].tp_is_atm_bitstates[i]
	
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
	if not sc.cc_to_i.has(ccoords):
		# The entire chunk isn't loaded, so inherently all of the required tps will need to be loaded.
		return required_tps
	
	var result: PackedByteArray = []
	result.resize(8)
	var tps_states: PackedByteArray = sc.chunks[sc.cc_to_i[ccoords]].tp_is_loaded_bitstates.duplicate()
	if ignore_unloaded_if_atm:
		for i in 8:
			tps_states[i] |= sc.chunks[sc.cc_to_i[ccoords]].tp_is_atm_bitstates[i]
	
	for i in 8:
		result[i] = required_tps[i] & (~ tps_states[i])
	return result

func load_static_chunk_data(
	ccoords: Vector3i,
	required_tps: PackedByteArray = [255,255,255,255,255,255,255,255],
	# !!! terrain objects, structures, etc?
) -> Error:
	# If a static chunk with provided ccoords doesn't already exist, instantiate it.
	if not sc.cc_to_i.has(ccoords):
		# !!! update this to work with the new StaticChunksGroup type
		#sc.chunks.append(WorldUtils.Chunk.new(-1, ccoords))
		#sc.cc_to_i[ccoords] = sc.chunks.size() - 1
		pass
	
	# !!! see if requested chunk data exists stored in files and load it if it does.
	
	# !!! for any terrrain data which was requested but isn't stored, generate it from scratch.
	
	return OK

func unload_static_chunk_data(ccoords: Vector3i) -> Error:
	if not sc.cc_to_i.has(ccoords):
		sc.refresh_cc_to_i()
		if sc.cc_to_i.has(ccoords):
			push_warning("sc.cc_to_i was originally found to be inaccurate.")
		else:
			push_error("No loaded static chunk with specified ccoords exists.")
			return FAILED
	
	# !!! Save all of the chunk to files.
	
	# Remove the chunk object and its associated data from RAM:
	clear_chunk(ccoords)
	
	return OK

# Clears chunks from memory, DOESN'T SAVE THEM TO FILES FIRST (use unload chunks funcs for that.)
func clear_chunk(ccoords: Vector3i) -> Error:
	if sc.cc_to_i.has(ccoords):
		sc.chunks.remove_at(sc.cc_to_i[ccoords])
		sc.refresh_cc_to_i()
		return OK
	else:
		sc.refresh_cc_to_i()
		if sc.cc_to_i.has(ccoords):
			push_warning("sc.cc_to_i was originally found to be inaccurate.")
			sc.chunks.remove_at(sc.cc_to_i[ccoords])
			sc.refresh_cc_to_i()
			return OK
		else:
			return FAILED
func clear_all_chunks(ccoords: Vector3i):
	sc.chunks.clear()
	sc.cc_to_i.clear()

# !!! (Consider the inefficiency of if several neighboring TPs are cleared in a row,
# that some chunks/TPs/variables get unnecessarily checked/updated repeatedly.)
# Properly clears a tp and updates both its and surounding tps' associated chunk variables.
func clear_static_chunk_terrain_piece(ccoords: Vector3i, tp_i: int) -> Error:
	# If the chunk is not found, then it cannot be appropriately modified.
	var chunk_i: int = sc.cc_to_i.get(ccoords, -1)
	if chunk_i == -1:
		push_error("Chunk not found stored in static chunks: ", ccoords)
		return FAILED
	
	# Clear the requested TerrainPiece:
	if sc.chunks[chunk_i].terrain_pieces.size() == 64:
		sc.chunks[chunk_i].terrain_pieces[posmod(tp_i, 64)] = WorldUtils.Chunk.TerrainPiece.new()
	else:
		push_error(
			"static chunk ", ccoords, " (index: ", chunk_i, ")" +
			" does not have its terrain_pieces array sized correctly (size is ", 
			sc.chunks[chunk_i].terrain_pieces.size(), " instead of 64)"
		)
	
	# Update associated chunks' TP-related variables (assumes correct chunk variable sizes,)
	# both for the specified and all immediately neighboring TPs (some which may be in neighboring chunks.)
	# If a neighboring TP is unloaded, then nothing is done with variables associated with it.
	var original_tp_coords: Vector3i = WorldUtils.tp_hzz_from_i(tp_i)
	for i in (3**3):
		var targ_tp_c: Vector3i = original_tp_coords + Vector3i(posmod(i/9,3)-1, posmod(i/3,3)-1, posmod(i,3)-1)
		var targ_chunk_ccoords: Vector3i = Vector3i(
			# Determines the chunk ccoords depending on if/how this neighboring TP's coords are OOB.
			((ccoords[0]-1) if (targ_tp_c[0]<0) else (ccoords[0])) if (targ_tp_c[0]<4) else (ccoords[0]+1), 
			((ccoords[1]-1) if (targ_tp_c[1]<0) else (ccoords[1])) if (targ_tp_c[1]<4) else (ccoords[1]+1),
			((ccoords[2]-1) if (targ_tp_c[2]<0) else (ccoords[2])) if (targ_tp_c[2]<4) else (ccoords[2]+1),
		)
		
		var targ_chunk_index: int = sc.cc_to_i.get(targ_chunk_ccoords, -1)
		if targ_chunk_index == -1:
			continue # Chunk is presumably unloaded, do nothing.
		else:
			targ_tp_c = Vector3i(posmod(targ_tp_c[0], 4), posmod(targ_tp_c[1], 4), posmod(targ_tp_c[2], 4))
			var t_tp_i: int = WorldUtils.tp_i_from_hzz(targ_tp_c)
			# Update chunk variables associated with impacted TP.
			# (If any associated variables are added/deleted later, then this part will need to be updated.)
			sc.chunks[targ_chunk_index].tp_is_loaded_bitstates[t_tp_i/8] &= ~ (1 << posmod(t_tp_i, 8))
			sc.chunks[targ_chunk_index].tp_is_atm_bitstates[t_tp_i/8] &= ~ (1 << posmod(t_tp_i, 8))
			for j in sc.chunks[targ_chunk_index].tp_determinables_uptodate.size():
				sc.chunks[targ_chunk_index].tp_determinables_uptodate[j][tp_i/8] &= (
					~ (0b00000001 << posmod(tp_i, 8))
				)
	return OK

# !!! MOVED TO CM because it clears tps, which changes is_determineables_uptodate, 
# which affects surrounding tps, including those of bordering chunks.
# !!! update bitstuff to use packed byte array
# (Can be done here as chunk terrain generation is not dependant on surrounding chunks' data.)
func generate_natural_terrain(
	group: int,
	ccoords: Vector3i,
	tps_to_generate: PackedByteArray = PackedByteArray([255, 255, 255, 255, 255, 255, 255, 255]),
	clear_all_tps: bool = false, 
	seed: int = WorldUtils.world_seed,
) -> Error:
	var chunk_i: int = -1
	if sc.cc_to_i.has(ccoords):
		# (Assumes that sc.cc_to_i is accurate.)
		chunk_i = sc.cc_to_i[ccoords]
		if clear_all_tps == true:
			sc.chunks[chunk_i].reset_terrain_pieces()
	else:
		pass
		# !!! update this to work with the new StaticChunksGroup type
		#chunk_i = sc.chunks.size()
		#sc.chunks.append(WorldUtils.Chunk.new(group, ccoords))
		#sc.cc_to_i[ccoords] = chunk_i
	
	if (tps_to_generate == PackedByteArray([255, 255, 255, 255, 255, 255, 255, 255])) or (clear_all_tps == true):
		pass
	else:
		pass
		# clear_static_chunk_terrain_piece for every tp to generate, mainly to update appropriate chunk vars
	
	
	
	
	
	
	
	
	#if terrain_pieces.size() != (4**3):
		#push_error("Chunk has ", terrain_pieces.size(), " terrain pieces (instead of 64).")
		#reset_terrain_pieces()
	#
	#for tp_i in (4**3):
		#if tps_to_generate[tp_i/8] & (0b1 << posmod(tp_i, 8)):
			#terrain_pieces[tp_i].clear_all_data()
			#
			## !!! write terrain generation testing code here
			#
		#elif also_clear_unrelated_tp_data:
			#terrain_pieces[tp_i].clear_all_data()
	
	return OK

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
