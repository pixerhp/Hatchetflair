extends Node

# TODO Use WorkerThreadPool for chunk generation/meshing tasks, 
# render chunk meshes via interacting with RenderingServer directly from GDE instead of having mesh nodes, 
# use a filer thread for loading/saving chunks from files as well as other read/write operations.

# !!! [wide saving / autosaving] should probably be higher priority over chunk loading

# !!! when changing the chunk load/unload radii, chunk_load_utils will need to be reinitialized.
# (to prevent thread conflicts without employing mutexes, wait for worker thread tasks using 
# chunk_load_utils to finish before reinitializing.)

# !!! the worker threads task list should be mutex protected, 
# so that a thread can add to the task list (gettings chunks to load/unload)
# in that case though, maybe also have a variable to intercept starting those tasks if you need to save first.

var mutex: Mutex = Mutex.new()
var semaphore: Semaphore = Semaphore.new()
var filer_thread: Thread = Thread.new()
var workers_halt: bool = false

var chunk_load_batch_size: int = 8

var chunk_onload_radius: float = 1.5
var chunk_offload_radius: float = 6.75

func _ready():
	GDE.initialize_chunk_load_utils(chunk_onload_radius, chunk_offload_radius)
	GDE.test_function()

func _process(delta):
	%Sun.rotation.y += 0.25 * delta

func _exit_tree():
	workers_halt = true
	if not (filer_thread == null):
		filer_thread.wait_to_finish()
	# TODO wait for all WorkerThreadPool tasks to finish.
