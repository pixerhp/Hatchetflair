extends Node

# TODO Use WorkerThreadPool for chunk generation/meshing tasks, 
# render chunk meshes via interacting with RenderingServer directly from GDE instead of having mesh nodes, 
# use a filer thread for loading/saving chunks from files as well as other read/write operations.

var mutex: Mutex = Mutex.new()
var semaphore: Semaphore = Semaphore.new()
var filer_thread: Thread = Thread.new()

func _ready():
	pass

func _process(delta):
	%Sun.rotation.y += 0.25 * delta

func _exit_tree():
	if not (filer_thread == null):
		filer_thread.wait_to_finish()
	# !!! (remember to also wait for workerthreadpool tasks when that's a thing)
