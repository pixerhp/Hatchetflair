extends StaticBody3D

var chunk_coords_hzz: Vector3i = Vector3i.ZERO

# Loads the chunk's terrain and mesh. (Ran when the chunk is first loaded into the world.)
func generate():
	pass

func _ready():
	if chunk_coords_hzz[0] == 0:
		find_child("LoadingWheel").queue_free()
		if (posmod(chunk_coords_hzz[1], 4) == 0) and (posmod(chunk_coords_hzz[2], 3) == 0):
			var new_child_mesh: MeshInstance3D = MeshInstance3D.new()
			var ramp: PrismMesh = PrismMesh.new()
			ramp.left_to_right = 0
			ramp.size = Vector3(16, 16 * 0.577350, 16)
			new_child_mesh.mesh = ramp
			new_child_mesh.position += Vector3(0, 8 * 0.577350, 0)
			add_child(new_child_mesh)
			var new_child_collision: CollisionShape3D = CollisionShape3D.new()
			new_child_collision.shape = ramp.create_convex_shape(true)
			new_child_collision.position += Vector3(0, 8 * 0.577350, 0)
			add_child(new_child_collision)
			
		elif (posmod(chunk_coords_hzz[1], 3) == 2) and (posmod(chunk_coords_hzz[2], 5) == 2):
			var new_child_mesh: MeshInstance3D = MeshInstance3D.new()
			var ramp: PrismMesh = PrismMesh.new()
			ramp.left_to_right = 0
			ramp.size = Vector3(16, 16 * 1.732050, 16)
			new_child_mesh.mesh = ramp
			new_child_mesh.position += Vector3(0, 8 * 1.732050, 0)
			add_child(new_child_mesh)
			var new_child_collision: CollisionShape3D = CollisionShape3D.new()
			new_child_collision.shape = ramp.create_convex_shape(true)
			new_child_collision.position += Vector3(0, 8 * 1.732050, 0)
			add_child(new_child_collision)
	else:
		find_child("LoadingWheel").queue_free()
		find_child("EarlyTestingPlaneMeshTop").queue_free()
		find_child("EarlyTestingPlaneMeshBottom").queue_free()
		find_child("EarlyTestingPlaneCollision").queue_free()
	

@onready var test_player_cam := get_node("../../REMOVE_LATER_cam")
var distance_to_cam: float
var testbool: bool = false
func _process(_delta):
	if Globals.draw_chunks_debug:
		distance_to_cam = self.position.distance_to(test_player_cam.position)
		if distance_to_cam > (4 * ChunkUtilities.STATIC_CHUNK_SIZE):
			pass
		elif distance_to_cam > (1.8 * ChunkUtilities.STATIC_CHUNK_SIZE):
			DebugDraw.draw_line_3d(
				self.position - Vector3(
					(ChunkUtilities.STATIC_CHUNK_SIZE / 2), 
					(ChunkUtilities.STATIC_CHUNK_SIZE / 2), 
					(ChunkUtilities.STATIC_CHUNK_SIZE / 2),
				), 
				self.position - Vector3(
					(-1 * ChunkUtilities.STATIC_CHUNK_SIZE / 2), 
					(ChunkUtilities.STATIC_CHUNK_SIZE / 2), 
					(ChunkUtilities.STATIC_CHUNK_SIZE / 2),
				),
				Color(0, 0.025, 0.025)
			)
			DebugDraw.draw_line_3d(
				self.position - Vector3(
					(ChunkUtilities.STATIC_CHUNK_SIZE / 2), 
					(ChunkUtilities.STATIC_CHUNK_SIZE / 2), 
					(ChunkUtilities.STATIC_CHUNK_SIZE / 2),
				), 
				self.position - Vector3(
					(ChunkUtilities.STATIC_CHUNK_SIZE / 2), 
					(-1 * ChunkUtilities.STATIC_CHUNK_SIZE / 2), 
					(ChunkUtilities.STATIC_CHUNK_SIZE / 2),
				),
				Color(0.025, 0.025, 0)
			)
			DebugDraw.draw_line_3d(
				self.position - Vector3(
					(ChunkUtilities.STATIC_CHUNK_SIZE / 2), 
					(ChunkUtilities.STATIC_CHUNK_SIZE / 2), 
					(ChunkUtilities.STATIC_CHUNK_SIZE / 2),
				), 
				self.position - Vector3(
					(ChunkUtilities.STATIC_CHUNK_SIZE / 2), 
					(ChunkUtilities.STATIC_CHUNK_SIZE / 2), 
					(-1 * ChunkUtilities.STATIC_CHUNK_SIZE / 2),
				),
				Color(0.025, 0, 0.025)
			)
		else:
			DebugDraw.draw_line_3d(
				self.position - Vector3(
					(ChunkUtilities.STATIC_CHUNK_SIZE / 2), 
					(ChunkUtilities.STATIC_CHUNK_SIZE / 2), 
					(ChunkUtilities.STATIC_CHUNK_SIZE / 2),
				), 
				self.position - Vector3(
					(-1 * ChunkUtilities.STATIC_CHUNK_SIZE / 2), 
					(ChunkUtilities.STATIC_CHUNK_SIZE / 2), 
					(ChunkUtilities.STATIC_CHUNK_SIZE / 2),
				),
				Color(0, 0.25, 0.25)
			)
			DebugDraw.draw_line_3d(
				self.position - Vector3(
					(ChunkUtilities.STATIC_CHUNK_SIZE / 2), 
					(ChunkUtilities.STATIC_CHUNK_SIZE / 2), 
					(ChunkUtilities.STATIC_CHUNK_SIZE / 2),
				), 
				self.position - Vector3(
					(ChunkUtilities.STATIC_CHUNK_SIZE / 2), 
					(-1 * ChunkUtilities.STATIC_CHUNK_SIZE / 2), 
					(ChunkUtilities.STATIC_CHUNK_SIZE / 2),
				),
				Color(0.25,0.25,0)
			)
			DebugDraw.draw_line_3d(
				self.position - Vector3(
					(ChunkUtilities.STATIC_CHUNK_SIZE / 2), 
					(ChunkUtilities.STATIC_CHUNK_SIZE / 2), 
					(ChunkUtilities.STATIC_CHUNK_SIZE / 2),
				), 
				self.position - Vector3(
					(ChunkUtilities.STATIC_CHUNK_SIZE / 2), 
					(ChunkUtilities.STATIC_CHUNK_SIZE / 2), 
					(-1 * ChunkUtilities.STATIC_CHUNK_SIZE / 2),
				),
				Color(0.25, 0, 0.25)
			)
