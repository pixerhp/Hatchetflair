extends Node

# TODO Use WorkerThreadPool for chunk generation/meshing tasks, 
# render chunk meshes via interacting with RenderingServer directly from GDE instead of having mesh nodes, 
# use a filer thread for loading/saving chunks from files as well as other read/write operations.

# !!! [wide saving / autosaving] should probably be higher priority over chunk loading

var mutex: Mutex = Mutex.new()
var semaphore: Semaphore = Semaphore.new()
var filer_thread: Thread = Thread.new()
var workers_halt: bool = false

var chunk_load_batch_size: int = 8

func _ready():
	GDE.test_function()

func _process(delta):
	%Sun.rotation.y += 0.25 * delta

func _exit_tree():
	workers_halt = true
	if not (filer_thread == null):
		filer_thread.wait_to_finish()
	# TODO wait for all WorkerThreadPool tasks to finish.
