@icon("res://assets/icons/godot_proj_icons/chunks_manager.png")
extends Node

# Chunk data & data access:
var hzz_to_chunk_i: Dictionary = {}
var static_chunks: Array[ChunkUtils.Chunk]

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
	#SAVE_ALL_LOADED_CHUNKS, # such as for autosaving, saving & quitting.
	#CLEAR_ALL_CHUNKS # 
}
enum OUTSTRUCTION {
	WAITING_FOR_MAIN_THREAD, # !!! (NOT YET IMPLIMENTED RECIEVING-WISE ANYWHERE IN THE MAIN THREAD.)
	#ALL_LOADED_CHUNKS_SAVED,
}


func _ready():
	mutex = Mutex.new()
	semaphore = Semaphore.new()
	exit_thread = false
	
	cm_thread = Thread.new()
	cm_thread.start(cm_thread_loop)

func cm_thread_loop():
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
	
	# Execute the list of instructions:
	for i in inst_enums.size():
		match inst_enums[i]:
			INSTRUCTION.WAIT_FOR_MAIN_THREAD:
				mutex.lock()
				out_instructions.append(OUTSTRUCTION.WAITING_FOR_MAIN_THREAD)
				mutex.unlock()
				semaphore.wait()
			_:
				push_error("Unknown/unsupported instruction-enum: ", inst_enums[i])
				continue
	return

# (Call with the main thread to make the cm thread stop waiting.)
func unpause_cm_thread():
	semaphore.post()


func refresh_hzz_to_chunk_i():
	hzz_to_chunk_i.clear()
	for i in static_chunks.size():
		hzz_to_chunk_i[static_chunks[i].ccoords] = i
	return
