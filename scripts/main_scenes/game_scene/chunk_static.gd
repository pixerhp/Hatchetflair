extends StaticBody3D

var chunk_coords_hzz: Vector3i = Vector3i.ZERO

# Loads the chunk's terrain and mesh. (Ran when the chunk is first loaded into the world.)
func generate():
	pass # Replace with function body.

@onready var test_player_cam := get_node("../../REMOVE_LATER_cam")
var distance_to_cam: float
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
				Color(0, 0, 0.125)
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
				Color(0.05,0.03125,0)
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
				Color(0.05, 0, 0.1125)
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
				Color(0, 0, 0.5)
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
				Color(0.2,0.125,0)
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
				Color(0.2, 0, 0.45)
			)
