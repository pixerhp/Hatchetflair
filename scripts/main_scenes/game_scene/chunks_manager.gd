extends Node3D

const MAX_NEW_STATIC_CHUNKS_BATCH_SIZE = 64
var do_chunk_generating: bool = true
var new_static_chunks_queue: Array[Vector3i] = []
var new_chunks: Array[StaticBody3D] = [] # Used for giving other threads references to the new chunk nodes.
var static_chunk_prefab: PackedScene = preload("res://scenes/prefabs/terrain/chunk_static.tscn")
@onready var chunk_gen_thread: Thread = Thread.new()

var frame_num: int = 0


func _ready():
	for h in range(-3, 4):
		for x1 in range(-3, 4):
			for x2 in range(-3, 4):
				new_static_chunks_queue.append(Vector3i(h, x1, x2))
	new_static_chunks_queue.append(Vector3i(4, 0, 0))
	new_static_chunks_queue.append(Vector3i(5, 0, 0))
	new_static_chunks_queue.append(Vector3i(6, 0, 0))
	new_static_chunks_queue.append(Vector3i(7, 0, 0))
	new_static_chunks_queue.append(Vector3i(8, 0, 0))
	new_static_chunks_queue.append(Vector3i(8, 1, 0))
	new_static_chunks_queue.append(Vector3i(8, 2, 0))
	new_static_chunks_queue.append(Vector3i(8, 0, 1))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	frame_num += 1
	if frame_num < 30:
		print("frame: ", frame_num)
	if not do_chunk_generating:
		return
	if chunk_gen_thread.is_started() and not chunk_gen_thread.is_alive():
		chunk_gen_thread.wait_to_finish()
		new_chunks.clear()
		print("children after: ", self.get_child_count())
	if not chunk_gen_thread.is_started():
		determine_new_static_chunks()
	if not new_static_chunks_queue.is_empty():
		print("children before: ", self.get_child_count())
		if new_static_chunks_queue.size() > MAX_NEW_STATIC_CHUNKS_BATCH_SIZE:
			add_static_chunks(new_static_chunks_queue.slice(0, MAX_NEW_STATIC_CHUNKS_BATCH_SIZE).duplicate())
			new_static_chunks_queue = new_static_chunks_queue.slice(MAX_NEW_STATIC_CHUNKS_BATCH_SIZE)
		else:
			add_static_chunks(new_static_chunks_queue.duplicate())
			new_static_chunks_queue.clear()
	remove_chunks()
	return

func determine_new_static_chunks():
	pass
func add_static_chunks(chunk_coords_hzz_queue: Array[Vector3i]):
	if chunk_coords_hzz_queue.is_empty():
		return
	new_chunks.resize(chunk_coords_hzz_queue.size())
	for i in chunk_coords_hzz_queue.size():
		new_chunks[i] = static_chunk_prefab.instantiate()
		new_chunks[i].name = str(chunk_coords_hzz_queue[i])
		new_chunks[i].chunk_coords_hzz = chunk_coords_hzz_queue[i]
		new_chunks[i].position = Globals.swap_zyx_hzz_i(new_chunks[i].chunk_coords_hzz) * ChunkUtilities.STATIC_CHUNK_SIZE
		self.add_child(new_chunks[i])
	chunk_gen_thread.start(add_static_chunks_threadwork)
	return
func add_static_chunks_threadwork():
	for chunk in new_chunks:
		chunk.generate()

func determine_chunks_to_remove():
	pass
func remove_chunks():
	pass
