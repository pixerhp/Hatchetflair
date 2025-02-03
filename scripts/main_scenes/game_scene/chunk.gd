# Delete/replace this script later.

extends StaticBody3D

var chunk_coords_hzz: Vector3i = Vector3i.ZERO
const tile_count: int = 16
var tile_shapes: PackedByteArray = []
var tile_occs: PackedByteArray = [] # short for "occupiednesses"
var tile_datas: Array = []


# Loads the chunk's terrain and mesh. (Ran when the chunk is first loaded into the world.)
func generate():
	preset_varaiables()
	generate_terrain()
	# determine biome from terrain contents?
	# generate mesh and collision?
	return

func preset_varaiables() -> void:
	tile_shapes.resize((tile_count / 2) + posmod(ChunkUtils3.CHUNK_WIDTH, 2))
	tile_shapes.fill((ChunkUtils3.TILE_SHAPE.BLANK << 4) + ChunkUtils3.TILE_SHAPE.BLANK)
		# each byte contains 2 distinct 4-bit values, except for the last one.
	tile_occs.resize((tile_count / 4) + (0 if posmod(ChunkUtils3.CHUNK_WIDTH, 4) == 0 else 1))
	tile_shapes.fill(
		(ChunkUtils3.TILE_OCC.EMPTY << 6) + 
		(ChunkUtils3.TILE_OCC.EMPTY << 4) +
		(ChunkUtils3.TILE_OCC.EMPTY << 2) +
		ChunkUtils3.TILE_OCC.EMPTY)
		# each byte contains 4 distinct 2-bit values, except for the last one.
	tile_datas.resize(tile_count)
	tile_datas.fill(ChemCraft.get_substance("air"))
	return

func generate_terrain() -> void:
	for h in ChunkUtils3.CHUNK_WIDTH:
		for z1 in ChunkUtils3.CHUNK_WIDTH:
			for z2 in ChunkUtils3.CHUNK_WIDTH:
				pass

func get_tilenum(h: int, z1: int, z2: int) -> int:
	return z2 + (ChunkUtils3.CHUNK_WIDTH * z1) + ((ChunkUtils3.CHUNK_WIDTH ** 2) * h)

func get_shape(tilenum: int) -> int:
	return (
		((tile_shapes[tilenum/2] & 0b11110000) >> 4) if (posmod(tilenum, 2) == 0)
		else (tile_shapes[tilenum/2] & 0b00001111)
	) 
func set_shape(tilenum: int, shape: int) -> void:
	tile_shapes[tilenum/2] = (
		((tile_shapes[tilenum/2] & 0b00001111) + ((shape & 0b00001111) << 4)) if (posmod(tilenum, 2) == 0)
		else ((tile_shapes[tilenum/2] & 0b11110000) + (shape & 0b00001111))
	)
	return
func get_occ(tilenum: int) -> int:
	return (
		((tile_occs[tilenum/4] & 0b11000000) >> 6) if (posmod(tilenum, 4) == 0)
		else ((tile_occs[tilenum/4] & 0b00110000) >> 4) if (posmod(tilenum, 4) == 1)
		else ((tile_occs[tilenum/4] & 0b00001100) >> 2) if (posmod(tilenum, 4) == 2)
		else ((tile_occs[tilenum/4] & 0b00000011))
	)
func set_occ(tilenum: int, occ: int):
	tile_shapes[tilenum/4] = (
		((tile_occs[tilenum/4] & 0b00111111) + ((occ & 0b00000011) << 6)) if (posmod(tilenum, 4) == 0)
		else ((tile_occs[tilenum/4] & 0b11001111) + ((occ & 0b00000011) << 4)) if (posmod(tilenum, 4) == 1)
		else ((tile_occs[tilenum/4] & 0b11110011) + ((occ & 0b00000011) << 2)) if (posmod(tilenum, 4) == 2)
		else ((tile_occs[tilenum/4] & 0b11111100) + (occ & 0b00000011))
	)
	return






# (Older code, you'll need to revise through it for updated concepts:)

func _ready():
	if chunk_coords_hzz[0] == 0:
		find_child("LoadingWheel").queue_free()
		if (posmod(chunk_coords_hzz[1], 2) == 0) and (posmod(chunk_coords_hzz[2], 4) == 0):
			var ramp_height_scaler: float = 1
			if bool(posmod(randi(), 2)):
				# For a 30 degree angle ramp:
				ramp_height_scaler = 0.577350
			else:
				# For a 60 degree angle ramp:
				ramp_height_scaler = 1.732050
			var ramp_mesh: MeshInstance3D = MeshInstance3D.new()
			ramp_mesh.mesh = PrismMesh.new()
			ramp_mesh.mesh.left_to_right = posmod(randi(), 2)
			ramp_mesh.mesh.size = Vector3(16, 16 * ramp_height_scaler, 16)
			ramp_mesh.position += Vector3(0, 8 * ramp_height_scaler, 0)
			add_child(ramp_mesh)
			var ramp_collision: CollisionShape3D = CollisionShape3D.new()
			ramp_collision.shape = ramp_mesh.mesh.create_convex_shape()
			ramp_collision.position += Vector3(0, 8 * ramp_height_scaler, 0)
			add_child(ramp_collision)
	else:
		find_child("LoadingWheel").queue_free()
		find_child("EarlyTestingPlaneMeshTop").queue_free()
		find_child("EarlyTestingPlaneMeshBottom").queue_free()
		find_child("EarlyTestingPlaneCollision").queue_free()
	

@onready var test_player_cam := get_node("../../REMOVE_LATER_cam")
var distance_to_cam: float
var testbool: bool = false
func _process(_delta):
	if Globals.draw_debug_chunk_borders:
		distance_to_cam = self.position.distance_to(test_player_cam.position)
		if distance_to_cam > (4 * ChunkUtils3.CHUNK_WIDTH):
			pass
		elif distance_to_cam > (1.8 * ChunkUtils3.CHUNK_WIDTH):
			DebugDraw.draw_chunk_corner(
				self.position,
				ChunkUtils3.CHUNK_WIDTH,
				[Color(0, 0.025, 0.025), Color(0.025, 0.025, 0), Color(0.025, 0, 0.025)],
				true
			)
		else:
			DebugDraw.draw_chunk_corner(
				self.position,
				ChunkUtils3.CHUNK_WIDTH,
				[Color(0, 0.25, 0.25), Color(0.25,0.25,0), Color(0.25, 0, 0.25)],
				true
			)
